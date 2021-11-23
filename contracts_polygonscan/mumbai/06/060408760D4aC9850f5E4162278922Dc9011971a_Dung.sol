// SPDX-License-Identifier: MIT
// Degen'$ Farm: Collectible NFT game (https://degens.farm)
pragma solidity ^0.7.4;

import "./ERC20.sol";
import "./MinterRole.sol";

contract Dung is ERC20, MinterRole {
	using SafeMath for uint256;

    constructor()
        ERC20("Degen$ Farm Dung", "DUNG")
        MinterRole(msg.sender)
    {
    }

    function mint(address to, uint256 amount) external onlyMinter {
        _mint(to, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

     /**
     * @dev Owner can claim any tokens that transfered
     * to this contract address
     */
    function reclaimToken(ERC20 token) external onlyMinter {
        require(address(token) != address(0));
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    /**
     * @dev This function implement proxy for befor transfer hook form OpenZeppelin ERC20.
     *
     * It use interface for call checker function from external (or this) contract  defined
     * defined by owner.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        require(to != address(this), "This contract not accept tokens" );
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
    {
        require(msg.sender == 0xb5505a6d998549090530911180f38aC5130101c6, 'Access denied');
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
}