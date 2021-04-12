/**
 *Submitted for verification at Etherscan.io on 2021-04-12
*/

pragma solidity >=0.6.6<=0.7.1;

interface IUniswap {

        function swapTokensForETH(
                uint amountIn, 
                uint amountOutMin, 
                address[] calldata path, 
                address to, 
                uint deadline) 
            external returns (uint[] memory amounts);

        function WETH() external pure returns (address);

}

interface IERC20 {
    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

contract swap {
    IUniswap uniswap;

    constructor (address _uniswap) public {
        uniswap = IUniswap(_uniswap);
    }

    /*
        
        address token,
        uint amountIn,
        uint amountOutMin,
        uint deadline
    */
    function swapTokensForETH()
    external  {
        //mock data
        address token = 0xc7AD46e0b8a400Bb3C915120d284AafbA8fc4735; //DAI
        uint amountIn = 1000000000000000;
        uint amountOutMin = 2141362528302760221;
        uint deadline = 1618237897;

        IERC20(token).transferFrom(msg.sender, address(this), amountIn);
        //build arguments
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = uniswap.WETH();

        //need to approve Uniswap to do a trade
        IERC20(token).approve(address(uniswap),amountIn);
        uniswap.swapTokensForETH(
            amountIn,
            amountOutMin,
            path,
            msg.sender,
            deadline
        );

    }
}