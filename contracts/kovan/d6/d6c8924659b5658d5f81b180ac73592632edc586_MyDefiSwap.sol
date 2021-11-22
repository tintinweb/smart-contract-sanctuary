/**
 *Submitted for verification at Etherscan.io on 2021-11-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.16 <0.9.0;
// use latest solidity version at time of writing, need not worry about overflow and underflow

interface IUniwap{
    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline)
        external
        returns (uint[] memory amounts);
        function WETH() external pure returns (address);
}


interface IERC20{
/**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

}
contract MyDefiSwap {
    IUniwap uniswap;
    
    constructor(address _uniswap){
        uniswap = IUniwap(_uniswap);
    }
    
    function swapExactTokensForETH(
        address token,
        uint amountIn,
        uint amountOutMin,
        uint deadline)
        external{
            IERC20(token).transferFrom(msg.sender,address(this),amountIn);
            address[] memory path = new address[](2);
            path[0] = token;
            path[1] = uniswap.WETH();
            IERC20(token).approve(address(uniswap),amountIn);
            uniswap.swapExactTokensForETH(
                amountIn,
                amountOutMin,
                path,
                msg.sender,
                deadline
                );
            }
    
}