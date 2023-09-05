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

    string private constant IDENTITY_IDENTIFIER = "type0";
    string private constant CONTENT_IDENTIFIER = "type1";
    string private constant SERVICE_IDENTIFIER = "type2";
    string private constant GEOGRAPHICAL_LOCATION_IDENTIFIER = "type3";
    string private constant HYPERBOLIC_COORDINATE_IDENTIFIER = "type4";
    string private constant IPv4_IDENTIFIER = "type5";
    string private constant DOMAIN_NAME_IDENTIFIER = "type6";

    uint256 private constant DEFAULT_METAVERSE = 0;

    // IdentityIdentifier immutable identity;
    // uint public immutable identityPrice;
    // uint256 public immutable minCommitmentAge = 60 seconds;
    // uint256 public immutable maxCommitmentAge = 24 hours;
    IdentityIdentifier  identity;
    uint public  identityPrice;
    uint256 public  minCommitmentAge = 60 seconds;
    uint256 public  maxCommitmentAge = 24 hours;
    

    mapping(bytes32 => uint256) public commitments;
    mapping(string => User) records;
    mapping(address =>mapping(address => bool)) operators;
    mapping(string => bool) sensitiveWords;
    mapping(string => uint) attribute;


    // constructor(IdentityIdentifier _identityIdentifier,uint256 _identityPrice){
    //     identity = _identityIdentifier;
    //     identityPrice = _identityPrice;
    // }

    function setIdentityContract(IdentityIdentifier _identityIdentifier) public {
        identity = _identityIdentifier;
    }    
    function setIdentityPrice(uint256 _identityPrice) public {
        identityPrice = _identityPrice;
    }

    /**
     * @dev Add a sensitive word to the sensitiveWords.
     * @param word The sensitive word.
     */
    function addSensitive(string calldata word) public {
        sensitiveWords[word] = true;
    }

    /**
     * @dev Returns whether a word is a sensitive word.
     * @param word The specified word.
     * @return Bool if the word is a sensitive word.
     */
    function sensitive(string memory word)
        public
        view
        returns(bool)
    {
        return sensitiveWords[word];
    }


    /**
     * @dev Make a commitment before registry.
     * @param name The username which user want to registry.
     * @param owner The address of the username's owner.
     */
    //Some configurations depend on other modules such as the front end
    function makeCommitment(
        string memory name,
        address owner
        // bytes32 secret
    ) public 
    // pure 
    returns(bytes32){
        bytes32 label = keccak256(bytes(name));
        return keccak256(
            abi.encode(
                label,
                owner
                // secret
            )
        );
    }


    /**
     * @dev Commit the commitment to the commitments table.
     */
    function commit(bytes32 commitment) public {
        if (commitments[commitment] + maxCommitmentAge >= block.timestamp) {
            revert ("UnexpiredCommitmentExists");
        }
        commitments[commitment] = block.timestamp;
    }
    

    /**
     * @dev Registry a username and set the username's owner.
     * @param username The name that user want to registry.
     * @param owner The address of the username's owner.
     */
    function register(
        string calldata username,
        address owner
        // bytes32 secret
    ) public payable {
        _consumeCommitment(
            username,
            makeCommitment(
                username,
                owner
                // secret
            )
        );
        registerUsername(username,owner);
    }


    /**
     * @dev Consume the commitment that produced by makeCommitment function.
     * @param name The name that user want to registry.
     * @param commitment The hash of the name which user wants to registry, 
                         address of the owner ans so on.
     */
    //it will work better if some configurations are combined with other modules
    function _consumeCommitment(
        string memory name,
        // uint256 duration,
        bytes32 commitment
    )internal{
        // if(commitments[commitment] + minCommitmentAge > block.timestamp){
        //     revert ("commitment too new");
        // }
        // if(commitments[commitment] + maxCommitmentAge <= block.timestamp){
        //     revert ("commitment too old");
        // }
        // set some rules
        if(!available(name)){
            revert ("name is not validate");
        }
        delete (commitments[commitment]);
    }

    /**
     * @dev Returns whether a name is a sensitive word.
     * @param name The username which user want to registry.
     * @return Bool if a name is available for the sensitiveWords.
     */
    function available(string memory name)
        public
        view 
        returns(bool)
    {
        return !sensitiveWords[name];
    }


    /**
     * @dev Permits modifications only by the person/address 
            that authorised in isAuthorised function.
     */
    modifier authorised(string calldata username) {
        require(isAuthorised(username));
        _;
    }
    /**
     * @dev Returns whether the msg.sender is the username's owner or 
            the person that approved by the username's owner.
     * @param username The specified username.
     * @return Bool if the msg.sender is authorised.
     */
    function isAuthorised(string calldata username)
        internal
        view
        returns(bool)
    {
        address usernameOwner = usernameOwner(username);
        return usernameOwner == msg.sender || isApprovedForAll(usernameOwner,msg.sender);
    }

    /**
     * @dev Enable or disable approval for a third party ("operator") to manage
     *  all of `msg.sender`'s username records. 
     * @param operator Address to add to the set of authorized operators.
     * @param approved True if the operator is approved, false to revoke approval.
     */
    function setApprovalForAll(address operator, bool approved) public {
        require(
            msg.sender != operator,
            "setting approval status for self"
        );

        operators[msg.sender][operator] = approved;
    }

    /**
     * @dev Query if an address is an authorized operator for another address.
     * @param owner The address that owns the username.
     * @param operator The address that acts on behalf of the owner.
     * @return True if `operator` is an approved operator for `owner`, false otherwise.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        returns (bool)
    {
        return operators[owner][operator];
    }


    /**
     * @dev Sets the username's owner in records.
     * @param username The specified username.
     * @param owner The address of the username that user wants to set.
     */
    function registerUsername(string calldata username, address owner) internal{
        records[username].owner = owner;
        attribute[username] = DEFAULT_METAVERSE;
    }


    /**
     * @dev Sets the Identity Identifier's contract address for the username.
     * @param username The specified username.
     * @param identityAddress The address of the identity identifier's contranct address.
     */
    // function setIdentityIdentifierAddress(string calldata username,address identityAddress)public {
    //     records[username].identity_identifier_addr = identityAddress;
    // }


    /**
     * @dev Transfers ownership of a username to a new address. 
            May only be called by the current owner of the node or
            the operator that approved by current owner.
     * @param username The username to transfer ownership of..
     * @param _owner The address of the new owner.
     */
    function transferOwner(string calldata username,address _owner) public authorised(username){
        records[username].owner = _owner;
    }

    /**
     * @dev Returns the address that owns the specified username.
     * @param username The specified username.
     */
    function usernameOwner(string calldata username)
        public 
        view 
        returns(address)
    {
        return records[username].owner;
    }

    /**
     * @dev Sets the permissions for username in the sub-metaverse.
     * @param username The specified username.
     * @param subMetaverse The flag number of the subMetaverse.
     */
    function setSubMetaverse(string calldata username, uint256 subMetaverse)public {
        attribute[username] = subMetaverse;
    }


    /**
     * @dev Registry an identity identifier for a specified username 
            in the identity identifier space contract.
            It only be called when the username is already registered.
     * @param username The specified username.
     */
    function registerIdentityIdentifier(
        string calldata username
    )
        public
        payable
        authorised(username)
    {
        uint256 expiryTime = calculate(msg.value,identityPrice);
        identity.registerIdentity(username,msg.sender,expiryTime);
    }

    /**
     * @dev Update the information of AboutMe in the identity identifier 
            space contract of the specified username.
     * @param username The specified username.
     * @param aboutMe The information of the username, company, organization or person.
     */
    function updateAboutMe(string calldata username, string calldata aboutMe) public authorised(username){
        identity.setAboutMe(username,aboutMe);
    }

    
    /**
     * @dev Pays the fee to extend the use of the registered identity 
            identifier of the specified username.
     * @param username The specified username.
     */
    function renewal(string calldata username)
        public
        payable 
        authorised(username)
    {
        uint256 payTime = calculate(msg.value,identityPrice);
        identity.renewal(username,payTime);
    }

    /**
     * @dev Revoke the identity identifier of the specified username and
            stop billing to keep the effective usage time.
     * @param username The specified username.
     */
    function revoke(string calldata username) public authorised(username){
        identity.revoke(username);
    }

    /**
     * @dev Restart the identity identifier of the specified username that 
            is already revoked by revoke function and start billing again.
     * @param username The specified username.
     */
    function restart(string calldata username) public authorised(username){
        identity.restart(username);
    }

    /**
     * @dev Revoke the identity identifier of the specified username and
            return the remaining money in the account.
     * @param username The specified username.
     */
    function revokeAndReturnBack(string calldata username)
        public
        payable 
        authorised(username)
    {
        uint256 remainTime = identity.remainT(username);
        uint amount = identityPrice * remainTime;
        payable(msg.sender).transfer(amount);
        identity.deleteIdentity(username);

    }


    /**
     * @dev Returns the value of the username's remaining money in identity
            identifier space contract.
     * @param username The specified username.
     */
    function remainValue(string calldata username)
        public
        view
        authorised(username) 
        returns(uint)
    {
        uint256 remainTime = identity.remainT(username);
        uint amount = identityPrice * remainTime;
        return amount;
    }


    /**
     * @dev Query whether the username's identity identifier is in expiry date.
     * @param username The specified username.
     * @return True if username is activc, false otherwise.
     */
    function isIdentityActive(string calldata username) 
        public 
        view 
        returns(bool)
    {
        return identity.isActive(username);
    }

    /**
     * @dev Returns the identity identifier of the specified username.
     * @param username The specified username.
     * @return identityIdentifier The string of the username's identity identifier.
     */
    function getIdentity(string calldata username) 
        public 
        view 
        returns(string memory)
    {
        return identity.identityIdentifier(username);
    }


    /**
     * @dev Returns the resolved identity identifier.
     * @param identifierType The identifier's type.
     * @param identifierContent The identifier's content.
     * @return result The resolved identity identifier.
     */
    function resolve(string calldata identifierType,string calldata identifierContent) 
        public 
        view 
        returns(string memory result)
    {
        if(keccak256(abi.encodePacked(identifierType)) == keccak256(abi.encodePacked(IDENTITY_IDENTIFIER))){
            result = identity.resolveIdentityByIdentifier(identifierContent);
        }
        // else if(keccak256(abi.encodePacked(identifierType)) == keccak256(abi.encodePacked(xxx))){}
        else{
            result = "This identifier is not supported";
        }
        return result;
    }

    
        
    /**
     * @dev Returns the resolved identity identifier by Username.
     * @param username The specified username.
     * @return identityIdentifier The string of the username's identity identifier.
     */
    function resolveIdentityByUsername(string calldata username) 
        public 
        view 
        authorised(username) 
        returns(string memory)
    {
        return identity.resolveIdentityByUsername(username);
    }

    /**
     * @dev Returns the aboutMe information of the specified username.
     * @param username The specified username.
     * @return aboutMe The information of the username, company, organization or person.
     */

    function getAboutMe(string calldata username)
        public
        view 
        returns(string memory)
    {
        return identity.aboutMe(username);
    }


    /**
     * @dev Returns the TTL of the specified username.
     * @param username The specified username.
     * @return ttl The ttl of the username.
     */

    function getTTL(string calldata username)
        public
        view
        returns(uint256)
    {
        return identity.ttl(username);
    }

    /**
     * @dev Returns the remaining days of the username's identity identifier.
     * @param username The specified username.
     * @return days The days of the remaining time
     */
    function remainTime(string calldata username) public view returns(uint){
        uint256 remainTime = getTTL(username) - block.timestamp;
        return remainTime/(60*60*24);
    }



    /**
     * @dev Returns expiration time that calculated according to the amount and the price.
     * @param amount The amount of the msg.value.
     * @param price The price of the identifier.
     * @return expiration time calculated by the amount and price
     */
    function calculate(uint amount,uint price) internal returns(uint){
        uint expires = amount / price;
        return expires;
    }
    /**
     * @dev Returns current block timestamp.
     * @return timestamp of current block
     */
    function blockTime() public view returns(uint){
        return block.timestamp;
    }

}
