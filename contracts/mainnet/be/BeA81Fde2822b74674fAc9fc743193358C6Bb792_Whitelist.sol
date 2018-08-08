pragma solidity 0.4.21;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function Ownable() public {
        owner = msg.sender;
    }
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

/**
 * @title Authorizable
 * @dev The Authorizable contract has authorized addresses, and provides basic authorization control
 * functions, this simplifies the implementation of "multiple user permissions".
 */
contract Authorizable is Ownable {
    
    mapping(address => bool) public authorized;
    event AuthorizationSet(address indexed addressAuthorized, bool indexed authorization);

    /**
     * @dev The Authorizable constructor sets the first `authorized` of the contract to the sender
     * account.
     */
    function Authorizable() public {
        authorize(msg.sender);
    }

    /**
     * @dev Throws if called by any account other than the authorized.
     */
    modifier onlyAuthorized() {
        require(authorized[msg.sender]);
        _;
    }

    /**
     * @dev Allows 
     * @param _address The address to change authorization.
     */
    function authorize(address _address) public onlyOwner {
        require(!authorized[_address]);
        emit AuthorizationSet(_address, true);
        authorized[_address] = true;
    }
    /**
     * @dev Disallows
     * @param _address The address to change authorization.
     */
    function deauthorize(address _address) public onlyOwner {
        require(authorized[_address]);
        emit AuthorizationSet(_address, false);
        authorized[_address] = false;
    }
}

/**
 * @title Whitelist interface
 */
contract Whitelist is Authorizable {
    mapping(address => bool) whitelisted;
    event AddToWhitelist(address _beneficiary);
    event RemoveFromWhitelist(address _beneficiary);
   
    function Whitelist() public {
        addToWhitelist(msg.sender);
    }
    
    
    modifier onlyWhitelisted() {
        require(isWhitelisted(msg.sender));
        _;
    }

    function isWhitelisted(address _address) public view returns (bool) {
        return whitelisted[_address];
    }

 
    function addToWhitelist(address _beneficiary) public onlyAuthorized {
        require(!whitelisted[_beneficiary]);
        emit AddToWhitelist(_beneficiary);
        whitelisted[_beneficiary] = true;
    }
    
    function removeFromWhitelist(address _beneficiary) public onlyAuthorized {
        require(whitelisted[_beneficiary]);
        emit RemoveFromWhitelist(_beneficiary);
        whitelisted[_beneficiary] = false;
    }
}