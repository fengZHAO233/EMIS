pragma solidity >=0.8.4;

// import "./EMIS.sol";

contract IdentityIdentifier{
    struct UserInfo{
        // address owner;
        string identityIdentifier;
        // bytes identityIdentifier;
        string aboutMe;// 可选
        // string hashIdentityIdentifier;
        string digest;
        uint256 ttl;
        uint256 registerTime;
        string signature;
    }

    // EMIS immutable emis;
    // mapping(address => UserInfo) identityRecords;
    mapping(string => UserInfo) identityRecords;
    mapping(string => bool) revokedUser;
    mapping(string => uint) remainTime;
    string private constant IDENTITY_IDENTIFIER = "type0";

    function isActive(string calldata username) public view returns(bool){
        return identityRecords[username].ttl > block.timestamp;
    }
    modifier active(string calldata username)  {
        require(isActive(username));
        _;
    }


    // 撤销 /激活
    function isRevoked(string calldata username)public view returns(bool){
        return revokedUser[username];
    }
    modifier revoked(string calldata username){
        require(isRevoked(username));
        _;
    }
    modifier notRevoked(string calldata username){
        require(!isRevoked(username));
        _;
    }
    
    function revoke(string calldata username) public notRevoked(username){
        revokedUser[username] = true;
        remainTime[username] = identityRecords[username].ttl - block.timestamp;
        identityRecords[username].ttl = 0;
    }
    function restart(string calldata username) public revoked(username){
        revokedUser[username] = false;
        identityRecords[username].ttl = block.timestamp + remainTime[username];
        remainTime[username] = 0;
    }



    // Version 2.0
    function registerIdentity(
        string calldata username,
        address uOwner,
        uint256 expiryTime
        ) public
    {
        identityRecords[username].identityIdentifier = toString(uOwner);
        identityRecords[username].registerTime = block.timestamp;
        // 如果身份标识是第一次被注册：
        // ttl: 当前时间 + 缴费时长
        if(identityRecords[username].ttl == 0){
            identityRecords[username].ttl = block.timestamp + expiryTime;
        }
        // 如果身份标识已被注册且在有效期内
        // ttl: 注册到期时间 + 缴费时长
        else if(identityRecords[username].ttl > block.timestamp){
            identityRecords[username].ttl += expiryTime;
        }
        // 身份标识已过期
        // ttl: 当前时间 + 缴费时长
        else{
            identityRecords[username].ttl = block.timestamp + expiryTime;
        }
    }

    function toString(address x) public pure returns(string memory){
        return toString(abi.encodePacked(x));
    }
    function toString(bytes memory data) public pure returns(string memory) {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + data.length * 2);
        // str[0] = "0";
        // str[1] = "x";
        for (uint i = 0; i < data.length; i++) {
            str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }

    // 设置
    function setIdentityIdentifier(string calldata username,string calldata _identityIdentifier) public active(username) {
        identityRecords[username].identityIdentifier = _identityIdentifier;
    }
    function setAboutMe(string calldata username,string calldata _aboutMe) public active(username) {
        identityRecords[username].aboutMe = _aboutMe;
    }
    function setDigest(string calldata username,string calldata _digest) public active(username) {
        identityRecords[username].digest = _digest;
    }
    function setSignature(string calldata username,string calldata _signature) public active(username) {
        identityRecords[username].signature = _signature;
    }
    function renewal(string calldata username,uint256 payTime) public active(username){
        // 如果身份标识是第一次被注册：
        // ttl: 当前时间 + 缴费时长
        if(identityRecords[username].ttl == 0){
            identityRecords[username].ttl = block.timestamp + payTime;
        }
        // 如果身份标识已被注册且在有效期内
        // ttl: 注册到期时间 + 缴费时长
        else if(identityRecords[username].ttl > block.timestamp){
            identityRecords[username].ttl += payTime;
        }
        // 身份标识已过期
        // ttl: 当前时间 + 缴费时长
        else{
            identityRecords[username].ttl = block.timestamp + payTime;
        }
    }

    // 查询

    function identityIdentifier(string calldata username) public view returns(string memory){
        // return identityRecords[msg.sender].identityIdentifier;
        return string(abi.encodePacked(IDENTITY_IDENTIFIER,":",identityRecords[username].identityIdentifier));
    }
    function aboutMe(string calldata username) public view returns(string memory){
        return identityRecords[username].aboutMe;
    }
    function digest(string calldata username) public view returns(string memory){
        return identityRecords[username].digest;
    }
    function signature(string calldata username) public view returns(string memory){
        return identityRecords[username].signature;
    }
    function registerTime(string calldata username) public view returns(uint256){
        return identityRecords[username].registerTime;
    }
    function ttl(string calldata username) public view returns(uint256){
        return identityRecords[username].ttl;
    }    

}