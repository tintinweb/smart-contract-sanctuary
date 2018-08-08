pragma solidity ^0.4.18;

/// @title ERC20 interface
contract ERC20 {
    function balanceOf(address guy) public view returns (uint);
    function transfer(address dst, uint wad) public returns (bool);
}

/// @title Manages access privileges.
contract AccessControl {
    
    event accessGranted(address user, uint8 access);
    
    // The addresses of the accounts (or contracts) that can execute actions within each roles.
    mapping(address => mapping(uint8 => bool)) accessRights;

    // @dev Keeps track whether the contract is paused. When that is true, most actions are blocked
    bool public paused = false;

    /// @dev Grants admin (1) access to deployer of the contract
    constructor() public {
        accessRights[msg.sender][1] = true;
        emit accessGranted(msg.sender, 1);
    }

    /// @dev Provides access to a determined transaction
    /// @param _user - user that will be granted the access right
    /// @param _transaction - transaction that will be granted to user
    function grantAccess(address _user, uint8 _transaction) public canAccess(1) {
        require(_user != address(0));
        accessRights[_user][_transaction] = true;
        emit accessGranted(_user, _transaction);
    }

    /// @dev Revokes access to a determined transaction
    /// @param _user - user that will have the access revoked
    /// @param _transaction - transaction that will be revoked
    function revokeAccess(address _user, uint8 _transaction) public canAccess(1) {
        require(_user != address(0));
        accessRights[_user][_transaction] = false;
    }

    /// @dev Check if user has access to a determined transaction
    /// @param _user - user
    /// @param _transaction - transaction
    function hasAccess(address _user, uint8 _transaction) public view returns (bool) {
        require(_user != address(0));
        return accessRights[_user][_transaction];
    }

    /// @dev Access modifier
    /// @param _transaction - transaction
    modifier canAccess(uint8 _transaction) {
        require(accessRights[msg.sender][_transaction]);
        _;
    }

    /// @dev Drains all Eth
    function withdrawBalance() external canAccess(2) {
        msg.sender.transfer(address(this).balance);
    }

    /// @dev Drains any ERC20 token accidentally sent to contract
    function withdrawTokens(address tokenContract) external canAccess(2) {
        ERC20 tc = ERC20(tokenContract);
        tc.transfer(msg.sender, tc.balanceOf(this));
    }

    /// @dev Modifier to allow actions only when the contract IS NOT paused
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /// @dev Modifier to allow actions only when the contract IS paused
    modifier whenPaused {
        require(paused);
        _;
    }

    /// @dev Called by any "C-level" role to pause the contract. Used only when
    ///  a bug or exploit is detected and we need to limit damage.
    function pause() public canAccess(1) whenNotPaused {
        paused = true;
    }

    /// @dev Unpauses the smart contract.
    function unpause() public canAccess(1) whenPaused {
        paused = false;
    }
}


/// @title Contract BizancioCertificate, prints the certificates
contract BizancioCertificate is AccessControl {

    struct Certificate {
        string name;
        string email;
        string course;
        string dates;
        uint16 courseHours;
        bool valid;
    }
    
    mapping (bytes32 => Certificate) public certificates;
    event logPrintedCertificate(bytes32 contractAddress, string _name, string email, string _course, string _dates, uint16 _hours);

    function printCertificate (string _name, string _email, string _course, uint16 _hours, string _dates) public canAccess(3) whenNotPaused returns (bytes32 _certificateAddress) {

        // creates certificate smart contract
        bytes32 certificateAddress = keccak256(block.number, now, msg.data);

        // create certificate data
        certificates[certificateAddress] = Certificate(_name, _email, _course, _dates, _hours, true);
        
        // creates the event, to be used to query all the certificates
        emit logPrintedCertificate(certificateAddress, _name, _email, _course, _dates, _hours);

        return certificateAddress;
    }
    
    // @dev Invalidates a deployed certificate
    function invalidateCertificate(bytes32 _certificateAddress) external canAccess(3) {
        certificates[_certificateAddress].valid = false;
    }

}