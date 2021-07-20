// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./AccessControlMixin.sol";
import "./IChildToken.sol";  
import "./NativeMetaTransaction.sol";  
import "./ContextMixin.sol";  


contract ChildMintableERC20 is
    ERC20,
    IChildToken,
    AccessControlMixin,
    NativeMetaTransaction,
    ContextMixin
{
    bytes32 public constant DEPOSITOR_ROLE = keccak256("DEPOSITOR_ROLE");

    constructor(
        string memory name_,
        string memory symbol_,
        address childChainManager_,
        address adminRole_
    ) ERC20(name_, symbol_) {
        _setupContractId("ChildMintableERC20");
        _setupRole(DEFAULT_ADMIN_ROLE, adminRole_);
        _setupRole(DEPOSITOR_ROLE, childChainManager_);
        _initializeEIP712(name_);
    }

    // This is to support Native meta transactions
    // never use msg.sender directly, use _msgSender() instead
    function _msgSender() 
        internal
        override
        view
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }

    /**
     * @notice called when token is deposited on root chain
     * @dev Should be callable only by ChildChainManager
     * Should handle deposit by minting the required amount for user
     * Make sure minting is done only by this function
     * @param user user address for whom deposit is being done
     * @param depositData abi encoded amount
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
     * @param amount amount of tokens to withdraw
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
     */
    function mint(address user, uint256 amount) public only(DEFAULT_ADMIN_ROLE) {
        _mint(user, amount);
    }
}