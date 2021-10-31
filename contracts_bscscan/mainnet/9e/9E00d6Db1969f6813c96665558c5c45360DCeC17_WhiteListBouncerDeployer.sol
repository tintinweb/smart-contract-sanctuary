pragma solidity ^0.5.16;

import "../WhiteListBouncer.sol";

contract WhiteListBouncerDeployer {
    function deploy(address _comptroller, address _admin) external returns (address) {
        WhiteListBouncer whitelistBouncer = new WhiteListBouncer(_comptroller, _admin);

        return address(whitelistBouncer);
    }
}

pragma solidity ^0.5.16;

import "./IBouncer.sol";
import "../IComptrollerPeripheral.sol";

contract WhiteListBouncer is IBouncer, IComptrollerPeripheral {
    bytes32 constant public WhiteListBouncerContractHash = keccak256("WhiteListBouncer");
    address public admin;
    address public comptroller;

    mapping(address => bool) public whitelist;

    event WhitelistedAddressAdded(address addr);
    event WhitelistedAddressRemoved(address addr);

    constructor(address _comptroller, address _admin) public {
        comptroller = _comptroller;

        admin = _admin;

        contractNameHash = WhiteListBouncerContractHash;
    }

    /**
     * @notice Periphery hook. Does nothing at the moment.
     */
    function connect(bytes calldata params) external {

    }

    /**
     * @notice Periphery hook. Does nothing at the moment.
     */
    function retire(bytes calldata params) external {

    }

    function isAccountApproved(address account) external view returns (bool) {
        return whitelist[account];
    }

    // @notice Adds the given account to the whitelist
    // @param account The account to add
    function approveAccount(address account) external {
        require(isAdmin(), "only admin can approve account");
        approveAccountInternal(account);
    }

    // @notice Adds the given account to the whitelist
    // @param accounts The accounts to add
    function approveAccounts(address[] calldata accounts) external {
        require(isAdmin(), "only admin can approve accounts");
        for (uint256 i =0; i < accounts.length; i++) {
            approveAccountInternal(accounts[i]);
        }
    }

    // @notice Removes the given account from the whitelist
    // @param account The account to remove
    function denyAccount(address account) external {
        require(isAdmin(), "only admin can set deny account");
        denyAccountInternal(account);
    }

    // @notice Removes the given account from the whitelist
    // @param accounts The accounts to remove
    function denyAccounts(address[] calldata accounts) external {
        require(isAdmin(), "only admin can set deny accounts");
        for (uint256 i =0; i < accounts.length; i++) {
            denyAccountInternal(accounts[i]);
        }
    }

    // @notice Adds the account to the whitelist if it is not there yet,
    // @param account The account to add
    function approveAccountInternal(address account) internal {
        if (!whitelist[account]) {
            whitelist[account] = true;
            emit WhitelistedAddressAdded(account);
        }
    }

    // @notice Removes the account to the whitelist if it is there,
    // @param account The account to remove
    function denyAccountInternal(address account) internal {
        if (whitelist[account]) {
            whitelist[account] = false;
            emit WhitelistedAddressRemoved(account);
        }
    }

    /**
         * @notice Checks caller is admin
         */
    function isAdmin() internal view returns (bool) {
        return msg.sender == admin;
    }
}

pragma solidity ^0.5.16;

contract IBouncer {
    bool public isBouncer = true;
    bytes32 public contractNameHash;

    function isAccountApproved(address account) external view returns (bool);
}

pragma solidity ^0.5.16;

interface IComptrollerPeripheral {
    /**
     * Called when the contract is connected to the comptroller
     */
    function connect(bytes calldata params) external;

    /**
     * Called when the contract is disconnected from the comptroller
     */
    function retire(bytes calldata params) external;
}