/**
 *Submitted for verification at Etherscan.io on 2021-07-10
*/

pragma solidity ^0.4.17 ~ 0.4.24;




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



contract USDTIER20 {
    uint public _totalSupply;
    function totalSupply() public constant returns (uint);
    function balanceOf(address who) public constant returns (uint);
    function transfer(address to, uint value) public;
    function allowance(address owner, address spender) public constant returns (uint);
    function transferFrom(address from, address to, uint value) public;
    function approve(address spender, uint value) public;
}


contract IERC20 {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
}


contract decoffer_USDT{
    using SafeMath for uint;
    
    USDTIER20  usdt  = USDTIER20 (address(0x0C413871eE38312d5d3e1AF3A15E2A1e48DCF878));
    IERC20 dusdt = IERC20(address(0x3a7Bc91F0264Ac3a7937aB50527359A0953512e8));
    
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }  
    
     
    address public owner;
    uint totalCash;
    uint token_supply;
    
    
    mapping(uint=>mapping(uint=>uint)) rate_info; 
    mapping(address=>mapping(uint=>uint)) user_info;
    //2.get_deth 3.借的金額 4.應付金額 
    mapping(address=>bool)public authorize;
    
    
    constructor()public {
        owner = msg.sender;
        totalCash = 1*10**6;
        
        rate_info[1][1] = 5*10**6;    //base_rate
        rate_info[1][2] = 12*10**6;   //markup_rate
        rate_info[1][3] = 150;          //reserves_rate
        
        rate_info[2][1]= 0;             //totalBorrows
        rate_info[2][2]= 0;             //totalReserves
    }
    
    
    
    function deposit(uint usdt_amount)public {
        require(usdt_amount > 0);
        
        //count excnange rate
        uint stock = count_stock();
        uint circulating = usdt_amount.mul(token_supply);
        uint dusdt_amount = circulating.div(stock);
        
        usdt.transferFrom(msg.sender,address(this),usdt_amount); 
        dusdt.transfer(msg.sender,dusdt_amount);
        
        user_info[msg.sender][2] = user_info[msg.sender][2].add(usdt_amount);
        totalCash = totalCash.add(usdt_amount);
    }
    
    
    
    function withdraw()public {
        require(dusdt.balanceOf(msg.sender)>= user_info[msg.sender][2]);
        
        //count excnange rate
        uint stock = count_stock();
        uint circulating = user_info[msg.sender][2].mul(stock);
        uint usdt_amount = circulating.div(token_supply);
        
        usdt.transfer(msg.sender,usdt_amount);
        dusdt.transferFrom(msg.sender,address(this),user_info[msg.sender][2]);
        
        user_info[msg.sender][2] = 0;
        totalCash = totalCash.sub(usdt_amount);
        
    }
    
    
    function count_stock()private returns(uint){
        token_supply = dusdt.totalSupply().sub(dusdt.balanceOf(address(this)));
        uint totalBorrows = rate_info[2][1];
        uint totalReserves = rate_info[2][2];
        uint stock = totalCash.add(totalBorrows).sub(totalReserves);
        return stock;
    }
    
    
    
    
    
    
    function borrow(uint _usdt, address user)public {
        require(authorize[msg.sender] == true);
        
        //-----------計算借款年利率------------
        uint markup_borrows = rate_info[1][2].mul(rate_info[2][1]); //markup_rate*totalBorrows
        uint CashBorrows = totalCash.add(rate_info[2][1]);          //totalCash+totalBorrows
        uint markup_utilization = markup_borrows.div(CashBorrows);  
        uint borrow_APR = rate_info[1][1].add(markup_utilization);  //base_rate + markup_utilization
        
        
        //-----------計算應付------------
        uint repay_interest = _usdt.mul(borrow_APR).div(10**8);     //應付利息
        uint total_repay = _usdt.add(repay_interest);               //應付利息及本金    
        user_info[user][3] = user_info[user][3].add(_usdt);
        user_info[user][4] = user_info[user][4].add(total_repay);
        
        
        //-----------平台變數調整------------
        totalCash = totalCash.sub(_usdt);
        
        uint reserves = repay_interest.mul(rate_info[1][3]).div(1000); // repay_interest*reserves_rate/1000
        uint borrows = total_repay.sub(reserves);
        
        rate_info[2][1] =  rate_info[2][1].add(borrows);
        rate_info[2][2] =  rate_info[2][2].add(reserves);
        usdt.transfer(user,_usdt);
    }
    
    
    
    
    
    

    
    
    function set_parameter(uint p1, uint p2, uint p3)public onlyOwner{
        rate_info[p1][p2] = p3;
    }
    
    function get_parameter(uint p1, uint p2)public view returns(uint p3){
        return rate_info[p1][p2];
    }
    
    function GetUserInfo(address user, uint p1)public view returns(uint){
        return user_info[user][p1];
    }
    
    
    //----------------view-----------------------------
    
    
    
    function get_balance()public view returns(uint){
        return totalCash;
    }
    
    
    
    function get_out_share()public view  returns(uint){
        uint _token_supply = dusdt.totalSupply().sub(dusdt.balanceOf(address(this)));
        return _token_supply;
    } 
    
    
   
    
    
    //------------------authorize----------------------------
    
    
    function authorization(address user,bool status )public onlyOwner{
        authorize[user] = status;
    }
    
    
    function get_authorization(address user)public view returns(bool){
        return authorize[user];
    }
    
    
    
    
    
    
}