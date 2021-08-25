//SourceUnit: TxSale.sol

pragma solidity ^0.5.8;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external ;
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external;
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}

contract TxSale{
    
    using SafeMath for *;
    
    address public owner;
    IERC20 public txCoin;
    IERC20 public _usdt = IERC20(0xa614f803B6FD780986A42c78Ec9c7f77e6DeD13C);//USDT
    
    address public teamAddr;// get USDT
    uint256 public totalSaleTxAmount;
    uint256 public price;
    
    constructor(IERC20 txAddr,address tAddr,uint256 _price) public{
        txCoin = txAddr ;
        teamAddr = tAddr ; 
        owner = msg.sender;
        price = _price;
    }
    
    function BuyTx(uint256 amountUSDT) public {
        //100~1000
        require(amountUSDT >=300*1e6 && amountUSDT <= 3000*1e6,"amountUSDT not within 300-3000");
        //require(amountUSDT >=3*1e6 && amountUSDT <= 30*1e6,"amountUSDT not within 300-3000");
        
        uint256 canSaleUsdtAmount ;
        uint256 saleTx;
        uint256 totaltx = txCoin.balanceOf(address(this));
        canSaleUsdtAmount = totaltx.mul(price).div(1e8);
        
        if(amountUSDT < canSaleUsdtAmount){
            canSaleUsdtAmount = amountUSDT;
            saleTx = canSaleUsdtAmount.mul(1e8).div(price);
        }else{
            saleTx =totaltx;
        }
           
        _usdt.transferFrom(msg.sender,teamAddr,canSaleUsdtAmount);
        
        txCoin.transfer(msg.sender,saleTx);
        
        totalSaleTxAmount = totalSaleTxAmount.add(saleTx);
        
    }
    
    function txInfo() view public returns(uint256 _taltalSaleAmount,uint256 _leftAmount){
        _taltalSaleAmount = totalSaleTxAmount;
        _leftAmount = txCoin.balanceOf(address(this));
    }
    
    function withdrawTx(uint256 amount) public {
        require(msg.sender == owner,"only owner");
        txCoin.transfer(teamAddr,amount);
    }
    
    
    
    
    
}