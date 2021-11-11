// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import { ReentrancyGuard } from "../oz/security/ReentrancyGuard.sol";

/**
 @notice Non-upgradeable protocol manager contract that contains the protocol-level fees and whitelist
 */
contract ProtocolManager is ReentrancyGuard {

    /// -- CUSTOM ERRORS --

    error Unauthorized();
    error Invalid_FeeTooHigh();

    /// -- STATE VARIABLES --

    /// @notice Mapping of whitelisted addresses for each specific tag
    mapping(bytes => mapping(address => bool)) internal whitelist;
    /// @notice Determines if the whitelist is in active use or not
    bool internal useWhitelist;
    /// @notice Protocol-level fees for deposits represented with two decimals of precision up to 50% (5000)
    uint16 public depositFee;
    /// @notice Protocol-level fees for withdrawals represented with two decimals of precision up to 50% (5000)
    uint16 public withdrawalFee;
    /// @notice Protocol-level fees for performance fee (fee taken if position is profitable) with two decimals of precision up to 50% (5000)
    uint16 public performanceFee;
    /// @notice Protocol-level fees for management fee (fees taken regardless if position was profitable) with two decimals of precision up to 50% (5000)
    uint16 public managementFee;
    /// @notice Address of the admin
    address public admin;

    constructor(
        address _admin,
        uint16 _depositFee,
        uint16 _withdrawalFee,
        uint16 _performanceFee,
        uint16 _managementFee
    ) {
        admin = _admin;
        depositFee = _depositFee;
        withdrawalFee = _withdrawalFee;
        performanceFee = _performanceFee;
        managementFee = _managementFee;
    }

    /// -- EVENTS --

    event UseWhitelistModified(bool status);
    event WhitelistModified(bytes tag, address addr, bool status);
    event DepositFeeModified(uint16 fee);
    event WithdrawalFeeModified(uint16 fee);
    event PerformanceFeeModified(uint16 fee);
    event ManagementFeeModified(uint16 fee);
    event AdminModified(address newAdmin);

    /// -- MODIFIER & FUNCTIONS --

    modifier onlyAdmin {
        _onlyAdmin();
        _;
    }
    
    function modifyUseWhitelist(bool _status) external onlyAdmin {
        useWhitelist = _status;

        emit UseWhitelistModified(_status);
    }
    /// @notice Adds an address to the whitelist
    /// @dev Address added to the whitelist under the provider tag
    /// @param _tag is a bytes(string) representing the purpose of the address
    /// @param _add is an address being whitelisted
    function addToWhitelist(bytes memory _tag, address _add) external onlyAdmin {
        whitelist[_tag][_add] = true;

        emit WhitelistModified(_tag, _add, true);
    }
    /// @notice Removes an address from the whitelist
    /// @dev Address removed from the whitelist under the provided tag
    /// @param _tag is a bytes(string) representing the purpose of the address
    /// @param _remove is an address being removed from the whitelist
    function removeFromWhitelist(bytes memory _tag, address _remove) external onlyAdmin {
        whitelist[_tag][_remove] = false;

        emit WhitelistModified(_tag, _remove, false);
    }
    /// @notice Modifies the protocol-level deposit fee
    /// @dev Modifies the protocol-level deposit fee up to 5000 (50%)
    /// @param _fee uint16 value representing a % with two decimals of precision
    function modifyDepositFee(uint16 _fee) external onlyAdmin {
        if(_fee > 5000)
            revert Invalid_FeeTooHigh();
        
        depositFee = _fee;
        
        emit DepositFeeModified(_fee);
    }
    /// @notice Modifies the protocol-level withdrawal fee
    /// @dev Modifies the protocol-level withdrawal fee up to 5000 (50%)
    /// @param _fee uint16 value representing a % with two decimals of precision
    function modifyWithdrawalFee(uint16 _fee) external onlyAdmin {
        if(_fee > 5000)
            revert Invalid_FeeTooHigh();
        
        withdrawalFee = _fee;
        
        emit WithdrawalFeeModified(_fee);
    }
    /// @notice Modifies the protocol-level performance fee
    /// @dev Modifies the protocol-level performance fee up to 5000 (50%)
    /// @param _fee uint16 value representing a % with two decimals of precision
    function modifyPerformanceFee(uint16 _fee) external onlyAdmin {
        if(_fee > 5000)
            revert Invalid_FeeTooHigh();
        
        performanceFee = _fee;
        
        emit PerformanceFeeModified(_fee);
    }
    /// @notice Modifies the protocol-level management fee
    /// @dev Modifies the protocol-level management fee up to 5000 (50%)
    /// @param _fee uint16 value representing a % with two decimals of precision
    function modifyManagementFee(uint16 _fee) external onlyAdmin {
        if(_fee > 5000)
            revert Invalid_FeeTooHigh();
        
        managementFee = _fee;
        
        emit ManagementFeeModified(_fee);
    }
    /// @notice Checks if an address is whitelisted under a tag
    /// @dev Returns the whitelist status of an address under provided tag
    /// @param _tag is a bytes(string) value that specifies what the address is for
    /// @param _check is an address to check if it is whitelisted under the tag
    function isWhitelisted(bytes memory _tag, address _check) external view returns(bool) {
        return whitelist[_tag][_check] || !useWhitelist;
    }

    function _onlyAdmin() internal view {
        if(msg.sender != admin)
            revert Unauthorized();
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}