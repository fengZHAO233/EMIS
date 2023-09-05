pragma solidity >=0.8.4;

contract ServiceIdentifier{
    struct ServiceInfo{
        string serviceIdentifier;
        uint256 ttl;
        uint256 registerTime;
        string metadataFilePath;
    }

    address owner;
    address emis;
    mapping(string => ServiceInfo) serviceRecords;
    mapping(string => bool) revokedService;
    mapping(string => uint) remainTime;
    string private constant SERVICE_IDENTIFIER = "type2";

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
     * @dev Query whether the username's service identifier is in expiry date.
     * @param username The specified username.
     * @return True if username's service identifier is activc, false otherwise.
     */
    function isActive(string calldata username)
        public
        view
        returns(bool)
    {
        return serviceRecords[username].ttl > block.timestamp;
    }

    /**
     * @dev Permits modifications only when the username is active.
     */
    modifier active(string calldata username)  {
        require(isActive(username));
        _;
    }

    /**
     * @dev Query whether the username's service identifier is revoked.
     * @param username The specified username.
     * @return True if username's service identifier is revoked.
     */
    function isRevoked(string calldata username)
        public 
        view 
        returns(bool)
    {
        return revokedService[username];
    }

    /**
     * @dev Permits modifications only when the username's service identifier is revoked.
     */
    modifier revoked(string calldata username){
        require(isRevoked(username));
        _;
    }

    /**
     * @dev Permits modifications only when the username's service identifier is not revoked.
     */
    modifier notRevoked(string calldata username){
        require(!isRevoked(username));
        _;
    }


    /**
     * @dev Register a serviceIdentifier, set the username's owner and ttl.
     * @param username The name that user want to registry.
     * @param _serviceIdentifier The identifier of the service.
     * @param expiryTime The time that user register.
     */
    function registerService(
        string calldata username,
        string calldata _serviceIdentifier,
        uint256 expiryTime
    // ) public OnlyEMIS{
    ) public {
        serviceRecords[username].serviceIdentifier = _serviceIdentifier;
        serviceRecords[username].registerTime = block.timestamp;
        // If the service identifier is registered for the first time:
        // ttl: current block.timestamp + expiryTime
        if(serviceRecords[username].ttl == 0){
            serviceRecords[username].ttl = block.timestamp + expiryTime;
        }
        // If the service identifier is registered and within the validity period:
        // ttl: original ttl + expiryTime
        else if(serviceRecords[username].ttl > block.timestamp){
            serviceRecords[username].ttl += expiryTime;
        }
        // If the service identifier has expired:
        // ttl: current block.timestamp + expiryTime
        else{
            serviceRecords[username].ttl = block.timestamp + expiryTime;
        }
    }


    /**
     * @dev Sets the service Identifier's contract address for the username.
     * @param username The specified username.
     * @param _serviceIdentifier The address of the service identifier's contranct address.
     */
    function setserviceIdentifier(string calldata username,string calldata _serviceIdentifier) public  active(username) {
        serviceRecords[username].serviceIdentifier = _serviceIdentifier;
    }

    /**
     * @dev Extend the use of the registered service identifier of the specified username according to payTime.
     * @param username The specified username.
     * @param payTime The time that user wants to extend.
     */
    function renewal(string calldata username,uint256 payTime) public  notRevoked(username){
        // If the service identifier is registered for the first time:
        // ttl: current block.timestamp + expiryTime
        if(serviceRecords[username].ttl == 0){
            serviceRecords[username].ttl = block.timestamp + payTime;
        }
        // If the service identifier is registered and within the validity period:
        // ttl: original ttl + expiryTime
        else if(serviceRecords[username].ttl > block.timestamp){
            serviceRecords[username].ttl += payTime;
        }
        // If the service identifier has expired:
        // ttl: current block.timestamp + expiryTime
        else{
            serviceRecords[username].ttl = block.timestamp + payTime;
        }
    }


    /**
     * @dev Returns the reamining time of the username's service identifier.
     * @param username The specified username.
     * @return remainTime of the username's service identifier.
     */
    function remainT(string calldata username) 
        public 
        view 
        returns(uint)
    {
        uint reaminTime = serviceRecords[username].ttl-block.timestamp;
        return reaminTime;
    }

    /**
     * @dev Revoke the service identifier of the specified username and
            stop billing to keep the effective usage time.
     * @param username The specified username.
     */
    function revoke(string calldata username) public  notRevoked(username){
        revokedService[username] = true;
        remainTime[username] = serviceRecords[username].ttl - block.timestamp;
        serviceRecords[username].ttl = 0;
    }

    /**
     * @dev Restart the service identifier of the specified username that 
            is already revoked by revoke function and start billing again.
     * @param username The specified username.
     */
    function restart(string calldata username) public  revoked(username){
        revokedService[username] = false;
        serviceRecords[username].ttl = block.timestamp + remainTime[username];
        remainTime[username] = 0;
    }

    /**
     * @dev Sets the ttl of username's service identifier to 0, it equals to delete the identifier.
     * @param username The specified username.
     */
    function deleteserviceIdentifier(string calldata username) public  notRevoked(username){
        serviceRecords[username].ttl =0;
    }


    /**
     * @dev Returns the service identifier of the specified username.
     * @param username The specified username.
     * @return serviceIdentifier The string of the username's service identifier.
     */
    function serviceIdentifier(string calldata username) 
        public 
        view 
        returns(string memory)
    {
        return string(abi.encodePacked(SERVICE_IDENTIFIER,":",serviceRecords[username].serviceIdentifier));
    }




    /*Service标识空间中，resolveContentByUsername与serviceIdentifier返回值一致

    // /**
    //  * @dev Returns the resolved content identifier by Username.
    //  * @param username The specified username.
    //  * @return serviceIdentifier The string of the username's content identifier.
    //  */
    // function resolveContentByUsername(string calldata username) 
    //     public 
    //     view 
    //     returns(string memory) 
    // {
    //     return string(abi.encodePacked("0x",serviceRecords[username].serviceIdentifier));
    // }

    // /**
    //  * @dev Returns the resolved content identifier by identifierContent.
    //  * @param identifierContent The identifier's content.
    //  * @return result The string of the username's content identifier.
    //  */
    // function resolvecontentByIdentifier(string calldata identifierContent) 
    //     public 
    //     view 
    //     returns(string memory result) 
    // {
    //     result = string(abi.encodePacked("0x",identifierContent));
    //     return result;
    // }


    /**
     * @dev Returns the register time of the specified username's service identifier.
     * @param username The specified username.
     * @return timestamp The timestamp of registering username's service identifier.
     */
    function registerTime(string calldata username) 
        public 
        view 
        returns(uint256)
    {
        return serviceRecords[username].registerTime;
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
        return serviceRecords[username].ttl;
    }

    
    /**
     * @dev Returns the metadata file path of the specified username.
     * @param username The specified username.
     * @return metadataFilePath The metadata file path of the username.
     */
    function metadataFilePath(string calldata username)
        public
        view
        returns(string memory)
    {
        return serviceRecords[username].metadataFilePath;
    }

//     /**
//      * @dev Transfer an address to string.
//      * @param x The address that want to be transfered.
//      * @return string of the address
//      */
//     function toString(address x) 
//         public 
//         pure 
//         returns(string memory)
//     {
//         return toString(abi.encodePacked(x));
//     }

//     /**
//      * @dev Transfer the bytes data to string.
//      * @param data The bytes that want to be transfered.
//      * @return string of the data
//      */
//     function toString(bytes memory data) 
//         public 
//         pure 
//         returns(string memory) 
//     {
//         bytes memory alphabet = "0123456789abcdef";
//         bytes memory str = new bytes(2 + data.length * 2);
//         // str[0] = "0";
//         // str[1] = "x";
//         for (uint i = 0; i < data.length; i++) {
//             str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
//             str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
//         }
//         return string(str);
//     }
}
