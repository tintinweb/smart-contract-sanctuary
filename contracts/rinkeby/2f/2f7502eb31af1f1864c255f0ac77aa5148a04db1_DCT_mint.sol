/**
 *Submitted for verification at Etherscan.io on 2021-10-27
*/

pragma solidity ^0.5.17;

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


 

contract ERC20Interface {
    function totalSupply() public returns (uint);
    function balanceOf(address tokenOwner) public returns (uint balance);
    function transfer(address to, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
}


contract USDTInterface{
    uint public _totalSupply;
    function totalSupply() public returns (uint);
    function balanceOf(address who) public returns (uint);
    function transfer(address to, uint value) public;
    function transferFrom(address from, address to, uint value) public;
}



contract DCT_mint {
    using SafeMath for uint;
    
    ERC20Interface DCT = ERC20Interface(address(0xD69d9e200BBbFE62c9306a62b776D91b9512224D));
    USDTInterface USDT = USDTInterface(address(0x015FF40F138dd03Dce1F72c38A7758C21B34F3fB));
    
    constructor()public{
       cash = 1000e6;    
       last_block = block.number;
    }
    
    
    uint public cash;
    uint public borrow;
    uint public reserve;
    uint public supply;
    uint public collateral_dct;
    
    uint constant_y = 50000;
    uint constant_k = 120000;
    uint exchange_rate = 900;
    uint reserve_factor = 200;
    uint fee = 10;
    uint utilization;
    
    
    uint public last_block;
    uint public proof;
    uint public year = 2102400;
    
    mapping(address=>uint)myCollateral;
    
    
    
    
    function mint(uint USDT_amount, address payee)public {
        last_supply();
        uint dct_price = get_price();
        uint dct_amount = uint(1e6).mul(USDT_amount).div(dct_price); 
        dct_amount = dct_amount.mul(exchange_rate).div(1000);
        
        cash = cash.add(USDT_amount);
        USDT.transferFrom(msg.sender,address(this),USDT_amount);
        DCT.transfer(payee,dct_amount);
    }
    
    
    
    function last_supply()private{
        supply = DCT.totalSupply().sub(DCT.balanceOf(address(this))).add(collateral_dct);
        mint_block();
    }
    
    
    function mint_block()private{
        proof = block.number.sub(last_block);
        last_block = block.number;
        set_utilization();
    }
    
    
    function set_utilization()private {
        utilization = uint(1e6).mul(borrow).div(borrow.add(cash));
        last_borrows();
    }
    
    
    
    function last_borrows()private{
        uint interest = constant_y.add(utilization.mul(constant_k).div(1e6));
        uint credit = borrow.mul(interest).mul(proof).div(year).div(1e6);
        uint reserve_fee = credit.mul(reserve_factor).div(1000);
        
        reserve = reserve.add(reserve_fee);
        borrow = borrow.add(credit).sub(reserve_fee); 
    }
    
    
    //--------borrow---------------------------------------
    
    
    function collateral(uint token_amount, address payee)external {
        require(DCT.balanceOf(msg.sender) >= token_amount);
        uint dct_price = uint(1e6).mul(cash.add(borrow).sub(reserve)).div(supply);
        uint borrow_usdt = token_amount.mul(dct_price).div(1e6);
        
        USDT.transfer(payee,borrow_usdt);
        DCT.transferFrom(msg.sender,address(this),token_amount);
        myCollateral[msg.sender] = myCollateral[msg.sender].add(token_amount);
        
        cash = cash.sub(borrow_usdt);
        borrow = borrow.add(borrow_usdt);
        collateral_dct = collateral_dct.add(token_amount);
        last_supply();
    }
    
    
    function repay(address debtor, uint repay_usdt)external{
        uint payable_usdt = get_payable(debtor);
        require(payable_usdt >= repay_usdt);
        
        uint dct_amount = repay_usdt.mul(collateral_dct).div(borrow);
        USDT.transferFrom(msg.sender,address(this),repay_usdt);
        DCT.transfer(msg.sender,dct_amount);
        myCollateral[debtor] = myCollateral[debtor].sub(dct_amount);
        
        cash = cash.add(repay_usdt);
        borrow = borrow.sub(repay_usdt);
        collateral_dct = collateral_dct.sub(dct_amount);
        last_supply();
        
    }
    
    
    
    
    
    //--------view---------------------------------------
    
    
    function get_price()public view returns(uint){
        uint dct_price = uint(1e6).mul(cash.add(borrow).sub(reserve)).div(supply);
        return dct_price;
    }
    
    function get_utilization()public view returns(uint){
        return utilization;
    }
    
    
    function get_payable(address debtor)public view returns(uint){
        uint DCTmortgage = myCollateral[debtor];
        uint payable_usdt = DCTmortgage.mul(borrow).div(collateral_dct);
        return payable_usdt;
    }
    
   
    
    
    
}