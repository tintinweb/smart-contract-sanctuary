// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.4;

import "./Pika.sol";

contract PikaPolygon is Pika {
    address public constant childChainManager = 0xb5505a6d998549090530911180f38aC5130101c6;

    function initialize(
        uint256 _minSupply,
        uint256 _totalSupply,
        address _beneficiary,
        string calldata _name,
        string calldata _symbol,
        uint256 _initial_fee
    ) public override initializer {
        super.initialize(_minSupply, _totalSupply, _beneficiary, _name, _symbol, _initial_fee);
    }

    function router() public pure override returns (IUniswapV2Router) {
        return IUniswapV2Router(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
    }

    /**
     * @notice called when token is deposited on root chain
     * @dev Should be callable only by ChildChainManager
     * Should handle deposit by minting the required amount for user
     * Make sure minting is done only by this function
     * @param user user address for whom deposit is being done
     * @param depositData abi encoded amount
     */
    function deposit(address user, bytes calldata depositData) external {
        require(_msgSender() == childChainManager, "only child chain manager can deposit tokens");
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