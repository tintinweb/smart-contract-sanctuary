/**
 *Submitted for verification at Etherscan.io on 2021-06-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

interface IUniswap {
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

}

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);

}

 contract TestAddLiquidity {
    
    address internal constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // Ropsten
    IUniswap public uniswap;
    
    mapping (address => mapping (address => uint256)) private _allowed;
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() public {
        uniswap = IUniswap(UNISWAP_ROUTER_ADDRESS);
    }
    
     /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) public returns (bool) {
      _approve(msg.sender, spender, value);
      return true;
    }

    /**
     * @dev Approve an address to spend another addresses' tokens.
     * @param owner The address that owns the tokens.
     * @param spender The address that will spend the tokens.
     * @param value The number of tokens that can be spent.
     */
    function _approve(address owner, address spender, uint256 value) internal {
      require(spender != address(0),"Invalid address");
      require(owner != address(0),"Invalid address");
      require(value > 0, "Invalid Amount");
      _allowed[owner][spender] = value;
      emit Approval(owner, spender, value);
    }
    
    function addLiq(address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline) external payable returns(bool) {
            
        IERC20(token).approve(msg.sender, 1000000000000000000000);
        //IERC20(token).transferFrom(msg.sender, address(this), 1000000000000000000);
        approve(UNISWAP_ROUTER_ADDRESS,amountTokenDesired);
        uniswap.addLiquidityETH{value: msg.value}(token, amountTokenDesired, amountTokenMin, amountETHMin,to,deadline);
        return true;
        }
}