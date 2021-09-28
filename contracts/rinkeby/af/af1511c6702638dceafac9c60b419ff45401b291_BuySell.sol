/**
 *Submitted for verification at Etherscan.io on 2021-09-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor() {
        _setOwner(_msgSender());
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }
    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


interface IERC20{
    function approve(address _spender, uint256 _value) external returns (bool);
}

interface IUniswapV2Router02 {
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}


contract BuySell  is Ownable {

    struct OrderPair{
        uint id;
        address token;
        uint buy_amount;
        uint get_token_amount;
        uint sell_amount;

    }

    address public usdt_token;
    IUniswapV2Router02 public uniswapV2Router;

    OrderPair[] public order_pairs;
    
    constructor(){

    }
    

    function length() external view returns (uint){
        return order_pairs.length;
    }

    function set(address _usdt_token,address _uniswapV2Router ) external onlyOwner  {
        usdt_token = _usdt_token;
        uniswapV2Router = IUniswapV2Router02(_uniswapV2Router);
    }

    function approve(address token,address _spender, uint256 _value) public onlyOwner  returns (bool){
        return IERC20(token).approve(_spender,_value);
    }

    function buy(address token,uint buy_amount) external onlyOwner  {
        address[] memory path = new address[](2);
        path[0] = usdt_token;
        path[1] = token;

        uint[] memory amounts = uniswapV2Router.getAmountsOut(buy_amount, path);

        uniswapV2Router.swapExactTokensForTokens(buy_amount,0,path,address(this),block.timestamp);

        order_pairs.push(OrderPair(order_pairs.length,token,buy_amount,amounts[1],0));
    }

    function sell(uint id) external onlyOwner {
        require(id < order_pairs.length,"not find this id");
        OrderPair storage order_pair = order_pairs[id];

        require(order_pair.sell_amount == 0,"had sell");

        address[] memory path = new address[](2);
        path[0] = order_pair.token;
        path[1] = usdt_token;

        uint[] memory amounts = uniswapV2Router.getAmountsOut( order_pair.get_token_amount, path);
        uniswapV2Router.swapExactTokensForTokens(order_pair.get_token_amount,0,path,address(this),block.timestamp);

        order_pairs[id].sell_amount=amounts[1];
    }

}