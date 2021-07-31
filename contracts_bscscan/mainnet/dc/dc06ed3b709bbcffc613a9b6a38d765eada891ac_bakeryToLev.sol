/**
 *Submitted for verification at BscScan.com on 2021-07-31
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^ 0.8.6;
interface IBEP20 {
    function balanceOf(address account)external view returns(uint256);
    function transfer(address recipient, uint256 amount)external returns(bool);
}
interface IBakerySwapRouter {
    function swapExactBNBForTokens(
        uint256 amountOutMin,
        address[]calldata path,
        address to,
        uint256 deadline)external payable returns(uint256[]memory amounts);
    function getAmountsOut(uint256 amountIn, address[]calldata path)external view returns(uint256[]memory amounts);

}
interface IndexPool {
    function getIndexQuote(uint amount)external view returns(uint256);
    function sellIndex(uint amount, uint amountOutMin)external returns(uint);
}

contract bakeryToLev {
    address public owner;
    address constant bakery = 0xCDe540d7eAFE93aC5fE6233Bee57E1270D3E330F;
    address constant wbnb = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address constant li = 0x08Ba8CCc71D92055e4b370283AE07F773211Cc29;
    address constant si = 0xA9102b07f1F577D7c58E481a8CbdB2630637Ea48;
    uint constant gasFee = 5000000000000000;
    IBakerySwapRouter bakeryRouter = IBakerySwapRouter(bakery);
    constructor() {
        owner = msg.sender;
    }
    receive()external payable {}

    function check(uint payAmout, bool liOrSi)public view returns(uint, uint, uint){
        address[]memory path = new address[](2);
        address token = liOrSi ? li : si;
        path[0] = wbnb;
        path[1] = token;
        uint amountOur = bakeryRouter.getAmountsOut(
            payAmout,
            path)[1];
        uint amountIn = IndexPool(token).getIndexQuote(amountOur);    
        amountIn -= amountIn / 100;    
        require(amountIn > payAmout + gasFee, 'Not profit');
        uint profit = amountIn - payAmout;
        return (amountOur,amountIn,profit);
    }
    function start(bool liOrSi)public payable {
        address[]memory path = new address[](2);
        uint amountIn = msg.value;
        address token = liOrSi ? li : si;
        path[0] = wbnb;
        path[1] = token;
        (uint amountOur,,) = check(amountIn, liOrSi);
        bakeryRouter.swapExactBNBForTokens{value: amountIn}(
            amountOur,
            path,
            address(this),
            block.timestamp);
        uint tokenBalance = IBEP20(token).balanceOf(address(this));
        IndexPool(token).sellIndex(tokenBalance, 0);
        require(address(this).balance > amountIn + gasFee, 'Not profit');
        (bool success, ) = owner.call { value: address(this).balance}(new bytes(0));
        require(success, 'BNB transfer failed');
    }
    function extract(address token, uint256 amount, bool isBNB)public {
        if (isBNB) {
            (bool success, ) = owner.call { value: amount}(new bytes(0));
            require(success, 'BNB transfer failed');
        } else {
            IBEP20(token).transfer(owner, amount);
        }
    }
}