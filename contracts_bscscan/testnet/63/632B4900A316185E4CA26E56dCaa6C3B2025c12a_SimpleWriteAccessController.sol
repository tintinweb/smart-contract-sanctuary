pragma solidity ^0.6.0;

import "./Owned.sol";
import "./interfaces/AccessControllerInterface.sol";

/**
 * @title SimpleWriteAccessController
 * @notice Gives access to accounts explicitly added to an access list by the
 * controller's owner.
 * @dev does not make any special permissions for externally, see
 * SimpleReadAccessController for that.
 */
contract SimpleWriteAccessController is AccessControllerInterface, Owned {

    bool public checkEnabled;
    mapping(address => bool) internal accessList;

    event AddedAccess(address user);
    event RemovedAccess(address user);
    event CheckAccessEnabled();
    event CheckAccessDisabled();

    constructor()
    public
    {
        checkEnabled = true;
    }

    /**
     * @notice Returns the access of an address
     * @param _user The address to query
     */
    function hasAccess(
        address _user,
        bytes memory
    )
    public
    view
    virtual
    override
    returns (bool)
    {
        return accessList[_user] || !checkEnabled;
    }

    /**
     * @notice Adds an address to the access list
     * @param _user The address to add
     */
    function addAccess(address _user)
    external
    onlyOwner()
    {
        if (!accessList[_user]) {
            accessList[_user] = true;

            emit AddedAccess(_user);
        }
    }

    /**
     * @notice Removes an address from the access list
     * @param _user The address to remove
     */
    function removeAccess(address _user)
    external
    onlyOwner()
    {
        if (accessList[_user]) {
            accessList[_user] = false;

            emit RemovedAccess(_user);
        }
    }

    /**
     * @notice makes the access check enforced
     */
    function enableAccessCheck()
    external
    onlyOwner()
    {
        if (!checkEnabled) {
            checkEnabled = true;

            emit CheckAccessEnabled();
        }
    }

    /**
     * @notice makes the access check unenforced
     */
    function disableAccessCheck()
    external
    onlyOwner()
    {
        if (checkEnabled) {
            checkEnabled = false;

            emit CheckAccessDisabled();
        }
    }

    /**
     * @dev reverts if the caller does not have access
     */
    modifier checkAccess() {
        require(hasAccess(msg.sender, msg.data), "No access");
        _;
    }
}

pragma solidity ^0.6.0;

/**
 * @title The Owned contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract Owned {

    address payable public owner;
    address private pendingOwner;

    event OwnershipTransferRequested(
        address indexed from,
        address indexed to
    );
    event OwnershipTransferred(
        address indexed from,
        address indexed to
    );

    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Allows an owner to begin transferring ownership to a new address,
     * pending.
     */
    function transferOwnership(address _to)
    external
    onlyOwner()
    {
        pendingOwner = _to;

        emit OwnershipTransferRequested(owner, _to);
    }

    /**
     * @dev Allows an ownership transfer to be completed by the recipient.
     */
    function acceptOwnership()
    external
    {
        require(msg.sender == pendingOwner, "Must be proposed owner");

        address oldOwner = owner;
        owner = msg.sender;
        pendingOwner = address(0);

        emit OwnershipTransferred(oldOwner, msg.sender);
    }

    /**
     * @dev Reverts if called by anyone other than the contract owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only callable by owner");
        _;
    }

}

pragma solidity ^0.6.0;

interface AccessControllerInterface {
    function hasAccess(address user, bytes calldata data) external view returns (bool);
}