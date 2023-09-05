pragma solidity >=0.8.4;

contract IdentityIdentifier{
    struct UserInfo{
        string identityIdentifier;
        string aboutMe;
        uint256 ttl;
        uint256 registerTime;
    }

    address owner;
    address emis;
    mapping(string => UserInfo) identityRecords;
    mapping(string => bool) revokedUser;
    mapping(string => uint) remainTime;
    string private constant IDENTITY_IDENTIFIER = "type0";

    constructor(){
        owner = msg.sender;
    }

    /**
     * @dev Permits modifications only owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Sets EMIS contract address.
     * @param emisAddr Emis contract address.
     */
    function setEMISAddr(address emisAddr) public onlyOwner{
        emis = emisAddr;
    }

    /**
     * @dev Permits modifications only emis contract.
     */
    // modifier OnlyEMIS(){
    //     require((msg.sender == emis)||(msg.sender == owner));
    //     _;
    // }

    /**
     * @dev Query whether the username's identity identifier is in expiry date.
     * @param username The specified username.
     * @return True if username's identity identifier is activc, false otherwise.
     */
    function isActive(string calldata username)
        public
        view
        returns(bool)
    {
        return identityRecords[username].ttl > block.timestamp;
    }

    /**
     * @dev Permits modifications only when the username is active.
     */
    modifier active(string calldata username)  {
        require(isActive(username));
        _;
    }

    /**
     * @dev Query whether the username's identity identifier is revoked.
     * @param username The specified username.
     * @return True if username's identity identifier is revoked.
     */
    function isRevoked(string calldata username)
        public 
        view 
        returns(bool)
    {
        return revokedUser[username];
    }

    /**
     * @dev Permits modifications only when the username's identity identifier is revoked.
     */
    modifier revoked(string calldata username){
        require(isRevoked(username));
        _;
    }

    /**
     * @dev Permits modifications only when the username's identity identifier is not revoked.
     */
    modifier notRevoked(string calldata username){
        require(!isRevoked(username));
        _;
    }

    /**
     * @dev Register a username, set the username's owner and ttl.
     * @param username The name that user want to registry.
     * @param uOwner The address of the identity identifier's owner.
     * @param expiryTime The time that user register.
     */
    function registerIdentity(
        string calldata username,
        address uOwner,
        uint256 expiryTime
    // ) public OnlyEMIS{
    ) public {
        identityRecords[username].identityIdentifier = toString(uOwner);
        identityRecords[username].registerTime = block.timestamp;
        // If the identity identifier is registered for the first time:
        // ttl: current block.timestamp + expiryTime
        if(identityRecords[username].ttl == 0){
            identityRecords[username].ttl = block.timestamp + expiryTime;
        }
        // If the identity identifier is registered and within the validity period:
        // ttl: original ttl + expiryTime
        else if(identityRecords[username].ttl > block.timestamp){
            identityRecords[username].ttl += expiryTime;
        }
        // If the identity identifier has expired:
        // ttl: current block.timestamp + expiryTime
        else{
            identityRecords[username].ttl = block.timestamp + expiryTime;
        }
    }

    /**
     * @dev Sets the Identity Identifier's contract address for the username.
     * @param username The specified username.
     * @param _identityIdentifier The address of the identity identifier's contranct address.
     */
    function setIdentityIdentifier(string calldata username,string calldata _identityIdentifier) public  active(username) {
        identityRecords[username].identityIdentifier = _identityIdentifier;
    }
    /**
     * @dev Update the information of AboutMe in the identity identifier 
            space contract of the specified username.
     * @param username The specified username.
     * @param _aboutMe The information of the username, company, organization or person.
     */
    function setAboutMe(string calldata username,string calldata _aboutMe) public  active(username) {
        identityRecords[username].aboutMe = _aboutMe;
    }

    /**
     * @dev Extend the use of the registered identity identifier of the specified username according to payTime.
     * @param username The specified username.
     * @param payTime The time that user wants to extend.
     */
    function renewal(string calldata username,uint256 payTime) public  notRevoked(username){
        // If the identity identifier is registered for the first time:
        // ttl: current block.timestamp + expiryTime
        if(identityRecords[username].ttl == 0){
            identityRecords[username].ttl = block.timestamp + payTime;
        }
        // If the identity identifier is registered and within the validity period:
        // ttl: original ttl + expiryTime
        else if(identityRecords[username].ttl > block.timestamp){
            identityRecords[username].ttl += payTime;
        }
        // If the identity identifier has expired:
        // ttl: current block.timestamp + expiryTime
        else{
            identityRecords[username].ttl = block.timestamp + payTime;
        }
    }


    /**
     * @dev Returns the reamining time of the username's identity identifier.
     * @param username The specified username.
     * @return remainTime of the username's identity identifier.
     */
    function remainT(string calldata username) 
        public 
        view 
        returns(uint)
    {
        uint reaminTime = identityRecords[username].ttl-block.timestamp; 
        return reaminTime;
    }

    /**
     * @dev Revoke the identity identifier of the specified username and
            stop billing to keep the effective usage time.
     * @param username The specified username.
     */
    function revoke(string calldata username) public  notRevoked(username){
        revokedUser[username] = true;
        remainTime[username] = identityRecords[username].ttl - block.timestamp;
        identityRecords[username].ttl = 0;
    }

    /**
     * @dev Restart the identity identifier of the specified username that 
            is already revoked by revoke function and start billing again.
     * @param username The specified username.
     */
    function restart(string calldata username) public  revoked(username){
        revokedUser[username] = false;
        identityRecords[username].ttl = block.timestamp + remainTime[username];
        remainTime[username] = 0;
    }

    /**
     * @dev Sets the ttl of username's identity identifier to 0, it equals to delete the identifier.
     * @param username The specified username.
     */
    function deleteIdentity(string calldata username) public  notRevoked(username){
        identityRecords[username].ttl =0;
    }


    /**
     * @dev Returns the identity identifier of the specified username.
     * @param username The specified username.
     * @return identityIdentifier The string of the username's identity identifier.
     */
    function identityIdentifier(string calldata username) 
        public 
        view 
        returns(string memory)
    {
        return string(abi.encodePacked(IDENTITY_IDENTIFIER,":",identityRecords[username].identityIdentifier));
    }

    /**
     * @dev Returns the resolved identity identifier by Username.
     * @param username The specified username.
     * @return identityIdentifier The string of the username's identity identifier.
     */
    function resolveIdentityByUsername(string calldata username) 
        public 
        view 
        returns(string memory) 
    {
        return string(abi.encodePacked("0x",identityRecords[username].identityIdentifier));
    }

    /**
     * @dev Returns the resolved identity identifier by identifierContent.
     * @param identifierContent The identifier's content.
     * @return result The string of the username's identity identifier.
     */
    function resolveIdentityByIdentifier(string calldata identifierContent) 
        public 
        view 
        returns(string memory result) 
    {
        result = string(abi.encodePacked("0x",identifierContent));
        return result;
    }


    /**
     * @dev Returns the aboutMe information of the specified username.
     * @param username The specified username.
     * @return aboutMe The information of the username, company, organization or person.
     */
    function aboutMe(string calldata username) 
        public
        view 
        returns(string memory)
    {
        return identityRecords[username].aboutMe;
    }


    /**
     * @dev Returns the register time of the specified username's identity identifier.
     * @param username The specified username.
     * @return timestamp The timestamp of registering username's identity identifier.
     */
    function registerTime(string calldata username) 
        public 
        view 
        returns(uint256)
    {
        return identityRecords[username].registerTime;
    }


    /**
     * @dev Returns the TTL of the specified username.
     * @param username The specified username.
     * @return ttl The ttl of the username.
     */
    function ttl(string calldata username) 
        public 
        view 
        returns(uint256)
    {
        return identityRecords[username].ttl;
    }

    

    /**
     * @dev Transfer an address to string.
     * @param x The address that want to be transfered.
     * @return string of the address
     */
    function toString(address x) 
        public 
        pure 
        returns(string memory)
    {
        return toString(abi.encodePacked(x));
    }

    /**
     * @dev Transfer the bytes data to string.
     * @param data The bytes that want to be transfered.
     * @return string of the data
     */
    function toString(bytes memory data) 
        public 
        pure 
        returns(string memory) 
    {
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
}
