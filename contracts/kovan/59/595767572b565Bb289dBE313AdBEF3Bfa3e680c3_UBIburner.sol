/**
 *Submitted for verification at Etherscan.io on 2021-08-20
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

/**
 * @title UniswapV2Router Interface
 * @dev See https://uniswap.org/docs/v2/smart-contracts/router02/#swapexactethfortokens. This will allow us to import swapExactETHForTokens function into our contract and the getAmountsOut function to calculate the token amount we will swap
 */
interface IUniswapV2Router {
    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);
}

/**
 * @title UBI Interface
 * @dev See https://github.com/DemocracyEarth/ubi/blob/master/contracts/UBI.sol This will allow us to see the UBI balance of our contract (burned UBI)
 */
interface IUBI {
    function balanceOf(address _owner) external view returns (uint256);
}

contract UBIburner {
    
    event Received(address indexed from, uint256 amount);
    event Burned(address indexed burner, uint256 amount);
    
    /// @dev address of the uniswap v2 router
    address private constant UNISWAP_V2_ROUTER =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    /// @dev address of WETH token. In Uniswap v2 there are no more direct ETH pairs, all ETH must be converted to WETH first.
    address private constant WETH = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;

    /// @dev address of UBI token.
    address private constant UBI = 0xDdAdE19B13833d1bF52c1fe1352d41A8DD9fE8C9;

    /// @dev An array of token addresses. Any swap needs to have a starting and end path, path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity.
    address[] path = [WETH, UBI];
    
    /** @dev buy UBI with a specific amount of ETH contract balance and freezes on this contract.
     *  @param _amount The ETH contract balance amount to use.
     *  @param _deadline Unix timestamp after which the transaction will revert.
     */
    function burnUBI(uint256 _amount, uint256 _deadline) external {
        IUniswapV2Router(UNISWAP_V2_ROUTER).swapExactETHForTokens{
            value: _amount
        }(1, path, address(this), _deadline);
        emit Burned(msg.sender, _amount);
    }

    /** @dev calculate the minimum UBI amount from swapping the ETH contract balance.
     *  @return The minimum amount of output token that must be received.
     */
    function getAmountOutMin() external view returns (uint256) {
        if (address(this).balance == 0) return 0;
        uint256[] memory amountOutMins = IUniswapV2Router(UNISWAP_V2_ROUTER)
            .getAmountsOut(address(this).balance, path);
        return amountOutMins[1];
    }

    /** @dev UBI contract balance (burned UBI).
     *  @return The amount of UBI burned.
     */
    function UBIburned() external view returns (uint256) {
        return IUBI(UBI).balanceOf(address(this));
    }

    /// @dev allow the contract to receive ETH
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}