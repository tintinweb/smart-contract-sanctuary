//SPDX-License-Identifier: Unlicense
import {KissaBase} from "./KissaBase.sol";
import {IERC20} from "./IERC20.sol";
import {SafeERC20} from "./SafeERC20.sol";
import {IChildToken, AccessControlMixin, NativeMetaTransaction, ContextMixin} from "./BridgeHelpers.sol";

pragma solidity 0.8.4;

/* KISSA
 * 
 * By the Mittenz Team.
 *
 * Learn more at mittenz.tech. 
 *
 */


/**
 * @dev Implementation of KISSA as a non-mintable child token in Polygon Matic.
 *
 */
 contract KissaChild is
    KissaBase,
    IChildToken,
    AccessControlMixin,
    NativeMetaTransaction,
    ContextMixin
{
    using SafeERC20 for KissaBase;
    bytes32 public constant DEPOSITOR_ROLE = keccak256("DEPOSITOR_ROLE");

    // Max tokens mintable by admin role for launch.
    uint256 private _availableLaunchSupply = 4000000 * 10**18;

    constructor(
        address childChainManager
    ) KissaBase() {
        _setupContractId("Kissa");
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(DEPOSITOR_ROLE, childChainManager);
        _initializeEIP712("Kissa");
    }

    // This is to support Native meta transactions
    // never use msg.sender directly, use _msgSender() instead
    function _msgSender() internal override view returns (address payable sender)
    {
        return ContextMixin.msgSender();
    }

    /**
     * @notice called when token is deposited on root chain
     * @dev Should be callable only by ChildChainManager
     * Should handle deposit by minting the required amount for user
     * Make sure minting is done only by this function
     * @param user user address for whom deposit is being done
     * @param depositData abi encoded amount of KISSA
     *
     */
    function deposit(address user, bytes calldata depositData)
        external
        override
        only(DEPOSITOR_ROLE)
    {
        uint256 amount = abi.decode(depositData, (uint256));
        _mint(user, amount);
    }

    /**
     * @notice called when user wants to withdraw tokens back to root chain
     * @dev Should burn user's tokens. This transaction will be verified when exiting on root chain
     * @param amount amount of KISSA
     *
     */
    function withdraw(uint256 amount) external {
        _burn(_msgSender(), amount);
    }

    /**
     * @notice Example function to handle minting tokens on matic chain
     * @dev Minting can be done as per requirement,
     * This implementation allows only admin to mint tokens but it can be changed as per requirement
     * @param user user for whom tokens are being minted
     * @param amount amount of token to mint
     * @dev Function is only here to satisfy PoS mapping requirements. All Kissa tokens
     * are minted at launch or created by converting Mittenz. No more can be minted.
     */
    function mint(address user, uint256 amount) public only(DEFAULT_ADMIN_ROLE) {
        require(amount <= _availableLaunchSupply, "Amount exceeds launch supply limit.");
        _availableLaunchSupply -= amount;
        _mint(user, amount);
    }
}