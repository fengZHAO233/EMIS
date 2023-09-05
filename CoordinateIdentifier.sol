pragma solidity >=0.8.4;

contract LocationIdentifier{
    struct LocationInfo{
        string longitude;       // 经度
        string latitude;        // 纬度
        uint256 radius;
        uint256 ttl;
        uint256 registerTime;
        // string metadataFilePath;
    }

    address owner;
    address emis;
    mapping(string => LocationInfo) locationRecords;
    mapping(string => bool) revokedLocation;
    mapping(string => uint) remainTime;
    string private constant LOCATION_IDENTIFIER = "type3";

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
     * @dev Query whether the username's location identifier is in expiry date.
     * @param username The specified username.
     * @return True if username's location identifier is activc, false otherwise.
     */
    function isActive(string calldata username)
        public
        view
        returns(bool)
    {
        return locationRecords[username].ttl > block.timestamp;
    }

    /**
     * @dev Permits modifications only when the username is active.
     */
    modifier active(string calldata username)  {
        require(isActive(username));
        _;
    }

    /**
     * @dev Query whether the username's location identifier is revoked.
     * @param username The specified username.
     * @return True if username's location identifier is revoked.
     */
    function isRevoked(string calldata username)
        public 
        view 
        returns(bool)
    {
        return revokedLocation[username];
    }

    /**
     * @dev Permits modifications only when the username's location identifier is revoked.
     */
    modifier revoked(string calldata username){
        require(isRevoked(username));
        _;
    }

    /**
     * @dev Permits modifications only when the username's location identifier is not revoked.
     */
    modifier notRevoked(string calldata username){
        require(!isRevoked(username));
        _;
    }


    /**
     * @dev Register a location, set the username's owner and ttl.
     * @param username The name that user want to registry.
     * @param _longitude The _longitude of the location identifier.
     * @param _latitude The _latitude of the location identifier. 
     * @param expiryTime The time that user register.
     */
    function registerLocation(
        string calldata username,
        string calldata _longitude,
        string calldata _latitude,
        uint256 expiryTime
    // ) public OnlyEMIS{
    ) public {
        locationRecords[username].longitude = _longitude;
        locationRecords[username].latitude = _latitude;
        locationRecords[username].registerTime = block.timestamp;
        // If the location identifier is registered for the first time:
        // ttl: current block.timestamp + expiryTime
        if(locationRecords[username].ttl == 0){
            locationRecords[username].ttl = block.timestamp + expiryTime;
        }
        // If the location identifier is registered and within the validity period:
        // ttl: original ttl + expiryTime
        else if(locationRecords[username].ttl > block.timestamp){
            locationRecords[username].ttl += expiryTime;
        }
        // If the location identifier has expired:
        // ttl: current block.timestamp + expiryTime
        else{
            locationRecords[username].ttl = block.timestamp + expiryTime;
        }
    }


    /**
     * @dev Sets the location Identifier's contract address for the username.
     * @param username The specified username.
     * @param _longitude The address of the location identifier's contranct address.
     * @param _latitude The address of the location identifier's contranct address.
     */
    function setLocationIdentifier(string calldata username,string calldata _longitude,string calldata _latitude) public  
    // active(username) 
    {
        locationRecords[username].longitude = _longitude;
        locationRecords[username].latitude = _latitude;
    }

    /**
     * @dev Sets the location Identifier's contract address for the username.
     * @param username The specified username.
     * @param _longitude The address of the location identifier's contranct address.
     */
    function setlongitude(string calldata username,string calldata _longitude) public  
    // active(username) 
    {
        locationRecords[username].longitude = _longitude;
    }

    /**
     * @dev Sets the location Identifier's contract address for the username.
     * @param username The specified username.
     * @param _latitude The address of the location identifier's contranct address.
     */
    function setlatitude(string calldata username,string calldata _latitude) public  
    // active(username) 
    {
        locationRecords[username].latitude = _latitude;
    }

    function setRadius(string calldata username,uint256 _radius) public {
        locationRecords[username].radius = _radius;
    }

    /**
     * @dev Extend the use of the registered location identifier of the specified username according to payTime.
     * @param username The specified username.
     * @param payTime The time that user wants to extend.
     */
    function renewal(string calldata username,uint256 payTime) public 
    //  notRevoked(username)
     {
        // If the location identifier is registered for the first time:
        // ttl: current block.timestamp + expiryTime
        if(locationRecords[username].ttl == 0){
            locationRecords[username].ttl = block.timestamp + payTime;
        }
        // If the location identifier is registered and within the validity period:
        // ttl: original ttl + expiryTime
        else if(locationRecords[username].ttl > block.timestamp){
            locationRecords[username].ttl += payTime;
        }
        // If the location identifier has expired:
        // ttl: current block.timestamp + expiryTime
        else{
            locationRecords[username].ttl = block.timestamp + payTime;
        }
    }


    /**
     * @dev Returns the reamining time of the username's location identifier.
     * @param username The specified username.
     * @return remainTime of the username's location identifier.
     */
    function remainT(string calldata username) 
        public 
        view 
        returns(uint)
    {
        uint reaminTime = locationRecords[username].ttl-block.timestamp;
        return reaminTime;
    }

    /**
     * @dev Revoke the location identifier of the specified username and
            stop billing to keep the effective usage time.
     * @param username The specified username.
     */
    function revoke(string calldata username) public  notRevoked(username){
        revokedLocation[username] = true;
        remainTime[username] = locationRecords[username].ttl - block.timestamp;
        locationRecords[username].ttl = 0;
    }

    /**
     * @dev Restart the location identifier of the specified username that 
            is already revoked by revoke function and start billing again.
     * @param username The specified username.
     */
    function restart(string calldata username) public  revoked(username){
        revokedLocation[username] = false;
        locationRecords[username].ttl = block.timestamp + remainTime[username];
        remainTime[username] = 0;
    }

    /**
     * @dev Sets the ttl of username's location identifier to 0, it equals to delete the identifier.
     * @param username The specified username.
     */
    function deleteLocationIdentifier(string calldata username) public  notRevoked(username){
        locationRecords[username].ttl =0;
    }


    /**
     * @dev Returns the location identifier of the specified username.
     * @param username The specified username.
     * @return locationIdentifier The string of the username's location identifier.
     */
    function getLocationIdentifier(string calldata username) 
        public 
        view 
        returns(string memory)
    {
        return string(abi.encodePacked(
            LOCATION_IDENTIFIER,
            ":",
            "(",
            locationRecords[username].longitude,
            ",",
            locationRecords[username].latitude,
            ")"
            ));
    }


    /**
     * @dev Returns the resolved content identifier by Username.
     * @param username The specified username.
     * @return locationIdentifier The string of the username's content identifier.
     */
    function resolveLocationByUsername(string calldata username) 
        public 
        view 
        returns(string memory) 
    {
        return string(abi.encodePacked(locationRecords[username].longitude,locationRecords[username].latitude));
    }

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
     * @dev Returns the register time of the specified username's location identifier.
     * @param username The specified username.
     * @return timestamp The timestamp of registering username's location identifier.
     */
    function registerTime(string calldata username) 
        public 
        view 
        returns(uint256)
    {
        return locationRecords[username].registerTime;
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
        return locationRecords[username].ttl;
    }

    /**
     * @dev Returns the longitude of the specified username.
     * @param username The specified username.
     * @return longitude The longitude of the username.
     */
    function longitude(string calldata username) 
        public 
        view 
        returns(string memory)
    {
        return locationRecords[username].longitude;
    }

    /**
     * @dev Returns the latitude of the specified username.
     * @param username The specified username.
     * @return latitude The latitude of the username.
     */
    function latitude(string calldata username) 
        public 
        view 
        returns(string memory)
    {
        return locationRecords[username].latitude;
    }
    
    // /**
    //  * @dev Returns the metadata file path of the specified username.
    //  * @param username The specified username.
    //  * @return metadataFilePath The metadata file path of the username.
    //  */
    // function metadataFilePath(string calldata username)
    //     public
    //     view
    //     returns(string memory)
    // {
    //     return locationRecords[username].metadataFilePath;
    // }

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
