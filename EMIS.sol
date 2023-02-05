pragma solidity >=0.8.4;

import "./IdentityIdentifier.sol";

contract EMIS{
    struct User{
        address owner;
        address identity_identifier_addr;
        address content_identifier;
        address service_identifier;
        address geographicalLocation_identifier;
        address hyperbolicCoordinate_identifier;
        address IPv4Address_identifier;
        address domainName_identifier;
    }

    IdentityIdentifier immutable identity;
    uint public immutable identityPrice;

    constructor(IdentityIdentifier _identityIdentifier, uint _identityPrice){
        identity = _identityIdentifier;
        identityPrice = _identityPrice;
    }

    mapping(string => User) records;

    mapping(address =>mapping(address => bool)) operators;

    // 工具函数
    function isAuthorised(string calldata username) internal view returns(bool){
        address usernameOwner = usernameOwner(username);
        return usernameOwner == msg.sender ;
    }
    modifier authorised(string calldata username) {
        require(isAuthorised(username));
        _;
    }

// 用户名相关
    function registerUsername(string calldata username, address owner) public{
        records[username].owner = owner;
    }
    function usernameOwner(string calldata username) public view returns(address){
        return records[username].owner;
    }
    function setIdentityAddress(string calldata username,address identityAddress)public {
        records[username].identity_identifier_addr = identityAddress;
    }

// 身份标识相关设置
    // Identity身份标识首次注册
    // TODO：转账
    // Version 2.0
    function registerIdentityIdentifier(
        string calldata username
    )
        public
        payable
        authorised(username)
    {
        uint256 expiryTime = calculate(msg.value,identityPrice);
        payable(msg.sender).transfer(msg.value);
        // identity.registerIdentity(username,identityIdentifier,aboutMe,digest,singature,expiryTime);
        identity.registerIdentity(username,msg.sender,expiryTime);
    }


    // 更新aboutMe信息
    function updateAboutMe(string calldata username, string calldata aboutMe) public authorised(username){
        identity.setAboutMe(username,aboutMe);
    }
    
    // 身份标识续费：
    function renewal(string calldata username) public payable authorised(username){
        uint256 payTime = calculate(msg.value,identityPrice);
        payable(msg.sender).transfer(msg.value);
        identity.renewal(username,payTime);
    }

    function revoke(string calldata username) public authorised(username){
        identity.revoke(username);
    }


    function restart(string calldata username) public authorised(username){
        identity.restart(username);
    }

// 身份标识相关查询,只有username的Owner可以查看
    // 查询身份标识是否在有效期
    function isIdentityActive(string calldata username) public view returns(bool){
        return identity.isActive(username);
    }
    // 查询identity身份标识
    function getIdentity(string calldata username) public view returns(string memory){
        // return string(abi.encodePacked(IDENTITY_IDENTIFIER,":",identity.identityIdentifier()));
        return identity.identityIdentifier(username);
    }
    // 查询aboutMe信息
    function getAboutMe(string calldata username) public view returns(string memory){
        return identity.aboutMe(username);
    }
    // 查询digest信息
    function getDigest(string calldata username) public view returns(string memory){
        return identity.digest(username);
    }
    // 查询signature信息
    function getSignature(string calldata username) public view returns(string memory){
        return identity.signature(username);
    }
    // 查询ttl信息
    function getTTL(string calldata username) public view returns(uint256){
        return identity.ttl(username);
    }
    // 剩余有效期
    function remainTime(string calldata username) public view returns(uint){
        uint256 remainTime = getTTL(username) - block.timestamp;
        return remainTime/(60*60*24);
    }


    // 工具函数
    function calculate(uint _amout,uint _price) public returns(uint){
        uint expires = _amout / _price;
        return expires;
    }
    function blockTime() public view returns(uint){
        return block.timestamp;
    }

}