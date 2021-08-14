// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import { IChildToken } from "./IChildToken.sol";
import { BRLCTokenUpgradeable } from "./BRLCTokenUpgradeable.sol";

/**
 * @title MaticBRLCTokenUpgradeable
 * @dev An MaticBRLCTokenUpgradeable is an ERC20 implementation which represents L1 asset,
 * minting and burning on deposits and withdrawals.
 */
contract MaticBRLCTokenUpgradeable is BRLCTokenUpgradeable, IChildToken {
    address public childChainManager;

    function initialize(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address childChainManager_
    ) public initializer {
        __MaticBRLCTokenUpgradeable_init(name_, symbol_, decimals_, childChainManager_);
    }

    function __MaticBRLCTokenUpgradeable_init(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address childChainManager_
    ) internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __PausableEx_init_unchained();
        __Blacklistable_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
        __BRLCToken_init_unchained(decimals_);
        __MaticBRLCTokenUpgradeable_init_unchained(childChainManager_);
    }

    function __MaticBRLCTokenUpgradeable_init_unchained(address childChainManager_) internal initializer {
        childChainManager = childChainManager_;
    }

    modifier onlyChildChainManager {
        require(_msgSender() == childChainManager, "Only L2 ChildChainManager can deposit");
        _;
    }

    /**
     * @notice Called when token is deposited on root chain
     * @dev Should be callable only by ChildChainManager
     * Should handle deposit by minting the required amount for user
     * Minting is done only by this function
     * @param account user address for whom deposit is being done
     * @param depositData abi encoded amount
     */
    function deposit(address account, bytes calldata depositData)
        external
        override
        onlyChildChainManager
    {
        uint256 amount = abi.decode(depositData, (uint256));
        _mint(account, amount);
        emit Deposit(account, amount);
    }

    /**
     * @notice Called when user wants to withdraw tokens back to root chain
     * @dev Should burn user's tokens. This transaction will be verified when exiting on root chain
     * @param amount amount of tokens to withdraw
     */
    function withdraw(uint256 amount) external override {
        _burn(_msgSender(), amount);
        emit Withdraw(_msgSender(), amount);
    }
}