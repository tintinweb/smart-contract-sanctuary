/**
 *Submitted for verification at BscScan.com on 2021-12-01
*/

//SPDX-License-Identifier: UNLICENSED
//Check before deployment: Hardcoded token contract address, pair address

pragma solidity =0.8.10;

interface UNIV2Sync {
    function sync() external;
}

interface IToken{
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IWETH {
    function deposit() external payable;
    function balanceOf(address _owner) external returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool);
    function withdraw(uint256 _amount) external;
}

contract fundLiquidity{

    address public token;
    address public pair;
    address public wethContract;
    uint256 public tokenAmount;
    uint256 public weiAmount;
    
    constructor() {
        token = 0x0c768c78450D3F864ab983908E8BD7D5AdA814BC; //mainnet
        pair = 0xD6ac71C58478368f2d1Aa720Dc03c523ED1329E8; //mainnet
        wethContract = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; //mainnet
    }

    receive() external payable {
       revert();
    }
    
    function fundLiquidityOfficial(uint amt) public payable {
        require(msg.sender == tx.origin); //no automated arbitrage
        //tokenAmount= IToken(token).balanceOf(msg.sender);
        tokenAmount= amt;
        IToken(token).transferFrom(msg.sender,pair,tokenAmount);
        uint256 amountETH = address(this).balance;
        IWETH(wethContract).deposit{value : amountETH}();
        uint256 amountWETH =  IWETH(wethContract).balanceOf(address(this));
        IWETH(wethContract).transfer(pair, amountWETH);
        UNIV2Sync(pair).sync(); //important to avoid skim
    }
}