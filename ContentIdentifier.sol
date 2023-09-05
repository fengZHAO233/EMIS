pragma solidity >=0.8.4;

contract Content{
    struct ContentInfo{
        string contentIdentifier;  //层级化的标识
        uint256 ttl;
        uint256 registerTime;
        // string metaFilePath;
    }

    // username/身份标识 => ContentInfo
    mapping(string => ContentInfo) contentRecords;
    // contentIdentifier => metafilePath
    mapping(string => string) metaFilePathRecords;
    // todo：标识是否过期检查：contentIdentifier => bool

    mapping(string => bool) revokedContent;
    mapping(string => uint) remainTime;
    string private constant CONTENT_IDENTIFIER = "type1";

    // 通过内容标识获取它的元数据文件地址
    function getMetaFilePath(string calldata _contentIdentifier) public view returns(string memory){
        return metaFilePathRecords[_contentIdentifier];
    }

    /**
     * @dev Query whether the username's content identifier is in expiry date.
     * @param username The specified username.
     * @return True if username's content identifier is activc, false otherwise.
     */
    function isActive(string calldata username)
        public
        view
        returns(bool)
    {
        return contentRecords[username].ttl > block.timestamp;
    }

    /**
     * @dev Permits modifications only when the username is active.
     */
    // modifier active(string calldata username)  {
    //     require(isActive(username));
    //     _;
    // }

    /**
     * @dev Query whether the username's content identifier is revoked.
     * @param username The specified username.
     * @return True if username's content identifier is revoked.
     */
    function isRevoked(string calldata username)
        public 
        view 
        returns(bool)
    {
        return revokedContent[username];
    }

    /**
     * @dev Permits modifications only when the username's content identifier is revoked.
     */
    modifier revoked(string calldata username){
        require(isRevoked(username));
        _;
    }

    /**
     * @dev Permits modifications only when the username's content identifier is not revoked.
     */
    modifier notRevoked(string calldata username){
        require(!isRevoked(username));
        _;
    }



    /**
     * @dev Register a contentIdentifier, set the username's owner and ttl.
     * @param username The name that user want to registry.
     * @param _contentIdentifier The identifier of the content.
     * @param expiryTime The time that user register.
     */
    function registerContent(
        string calldata username,
        string calldata _contentIdentifier,
        string calldata _metaFilePath,
        uint256 expiryTime
    // ) public OnlyEMIS{
    ) public {
        contentRecords[username].contentIdentifier = _contentIdentifier;
        contentRecords[username].registerTime = block.timestamp;
        metaFilePathRecords[_contentIdentifier] = _metaFilePath;    //  contentIdentifier => metafilePath
        // If the content identifier is registered for the first time:
        // ttl: current block.timestamp + expiryTime
        if(contentRecords[username].ttl == 0){
            contentRecords[username].ttl = block.timestamp + expiryTime;
        }
        // If the content identifier is registered and within the validity period:
        // ttl: original ttl + expiryTime
        else if(contentRecords[username].ttl > block.timestamp){
            contentRecords[username].ttl += expiryTime;
        }
        // If the content identifier has expired:
        // ttl: current block.timestamp + expiryTime
        else{
            contentRecords[username].ttl = block.timestamp + expiryTime;
        }
    }



    /**
     * @dev Sets the content Identifier's contract address for the username.
     * @param username The specified username.
     * @param _contentIdentifier The address of the content identifier's contranct address.
     */
    function setcontentIdentifier(string calldata username,string calldata _contentIdentifier) public 
    //  active(username) 
    {
        contentRecords[username].contentIdentifier = _contentIdentifier;
    }

    function setMetaFilePath(string calldata _contentIdentifier, string calldata _metaFilePath) public{
        metaFilePathRecords[_contentIdentifier] = _metaFilePath;
    }

    /**
     * @dev Extend the use of the registered content identifier of the specified username according to payTime.
     * @param username The specified username.
     * @param payTime The time that user wants to extend.
     */
    function renewal(string calldata username,uint256 payTime) public  notRevoked(username){
        // If the content identifier is registered for the first time:
        // ttl: current block.timestamp + expiryTime
        if(contentRecords[username].ttl == 0){
            contentRecords[username].ttl = block.timestamp + payTime;
        }
        // If the content identifier is registered and within the validity period:
        // ttl: original ttl + expiryTime
        else if(contentRecords[username].ttl > block.timestamp){
            contentRecords[username].ttl += payTime;
        }
        // If the content identifier has expired:
        // ttl: current block.timestamp + expiryTime
        else{
            contentRecords[username].ttl = block.timestamp + payTime;
        }
    }

    /**
     * @dev Returns the reamining time of the username's content identifier.
     * @param username The specified username.
     * @return remainTime of the username's content identifier.
     */
    function remainT(string calldata username) 
        public 
        view 
        returns(uint)
    {
        uint reaminTime = contentRecords[username].ttl-block.timestamp;
        return reaminTime;
    }

    /**
     * @dev Revoke the content identifier of the specified username and
            stop billing to keep the effective usage time.
     * @param username The specified username.
     */
    function revoke(string calldata username) public  notRevoked(username){
        revokedContent[username] = true;
        remainTime[username] = contentRecords[username].ttl - block.timestamp;
        contentRecords[username].ttl = 0;
    }

    /**
     * @dev Restart the content identifier of the specified username that 
            is already revoked by revoke function and start billing again.
     * @param username The specified username.
     */
    function restart(string calldata username) public  revoked(username){
        revokedContent[username] = false;
        contentRecords[username].ttl = block.timestamp + remainTime[username];
        remainTime[username] = 0;
    }

    /**
     * @dev Sets the ttl of username's content identifier to 0, it equals to delete the identifier.
     * @param username The specified username.
     */
    function deleteContentIdentifier(string calldata username) public  notRevoked(username){
        contentRecords[username].ttl =0;
    }

// todo: username和内容标识是一对多的关系，一个用户发布多个资源时，需要设置查询条件
// 目前是一对一的关系，后注册的内容标识会覆盖前面的
    /**
     * @dev Returns the content identifier of the specified username.
     * @param username The specified username.
     * @return contentIdentifier The string of the username's content identifier.
     */
    function contentIdentifier(string calldata username) 
        public 
        view 
        returns(string memory)
    {
        return string(abi.encodePacked(CONTENT_IDENTIFIER,":",contentRecords[username].contentIdentifier));
    }
    

    /**
     * @dev Returns the register time of the specified username's content identifier.
     * @param username The specified username.
     * @return timestamp The timestamp of registering username's content identifier.
     */
    function registerTime(string calldata username) 
        public 
        view 
        returns(uint256)
    {
        return contentRecords[username].registerTime;
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
        return contentRecords[username].ttl;
    }
}
