/**
 *Submitted for verification at Etherscan.io on 2021-07-20
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

contract RTInterface{
    function set_recommender(address recommender, address user)public;
    function get_recommender(address user)public view returns(address);
}


contract USDTIER20 {
    function transfer(address to, uint value) public;
    function transferFrom(address from, address to, uint value) public;
}


contract IERC20 {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function transfer(address to, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
}



contract puluts{
    using SafeMath for uint;
    
    USDTIER20  usdt  = USDTIER20 (address(0xB2E260b8d730f177d7A9796146d2305D0922b0FB));
    IERC20  plt = IERC20(address(0x2AD000f0b2D767Faf1933c6d45BFbaDE9313f23e));
    RTInterface rt = RTInterface(address(0xDB59762a4A5dC7a619996E6A9894a5189f305a1b));
    
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }  
    
     
    address public owner;
    address public Winner;
    uint totalCash;
    uint token_supply;
    uint totalBorrows;
    uint collateral;
    
    
    mapping(uint=>mapping(uint=>uint)) rate_info; 
    mapping(address=>mapping(uint=>uint)) user_info;
    //1.deposit_usdt 2.get_dtoken 3.借的金額 4.應付金額 5.抵押枚數 6.清算條件 7.推薦獎金
    
    
    
    
    constructor()public {
        owner = msg.sender;
        totalCash = 1*10**6;
         
        rate_info[1][1] = 5*10**6;      //base_rate
        rate_info[1][2] = 12*10**6;     //markup_rate
        rate_info[1][3] = 30;           //fee_rate
        rate_info[1][4] = 800;          //collateral_rate
        rate_info[1][5] = 1080;         //Liquidat_rate
    
        
        
        rate_info[3][1]= 50;            //第一代獎金比例
        rate_info[3][2]= 35;            //第二代獎金比例
        rate_info[3][2]= 15;            //第三代獎金比例
        
        rate_info[4][1]= 400;           //保留比例
        rate_info[4][2]= 400;           //入池比例
        rate_info[4][3]= 40;            //樂透
        rate_info[4][4]= 60;            //stock
        
        rate_info[5][1]= 0;             //lottery 
        rate_info[5][2]= now.add(432000);//time
        
    }
 
    
    
    function deposit(uint amount ,address recommender)public {
        require(amount >= 1);
        
        uint usdt_amount = amount.mul(20*10**6);
        user_info[msg.sender][1] = user_info[msg.sender][1].add(usdt_amount);
        
        if(rt.get_recommender(msg.sender) == address(0x0)){
            rt.set_recommender(recommender,msg.sender);
        }
        
        
        //excnange rate
        uint totalBalances = count_totalBalances();
        uint circulating = usdt_amount.mul(token_supply);
        uint plt_amount = circulating.div(totalBalances);
        plt.transfer(msg.sender,plt_amount);
        
        uint rt_quota = usdt_amount.mul(rate_info[3][1].add(rate_info[3][1]).add(rate_info[3][1])).div(1000);
        uint rt_plt = rt_quota.mul(token_supply).div(totalBalances);
        ProfitSharing(rt_plt);
        
        
        uint inContract = usdt_amount.mul(rate_info[4][1].add(rate_info[4][2]).add(rate_info[4][3])).div(1000);
        usdt.transferFrom(msg.sender,address(this),inContract);
        
        uint stock = usdt_amount.mul(rate_info[4][4]).div(1000);
        usdt.transferFrom(msg.sender,owner,stock);
        
        uint cash = usdt_amount.mul(rate_info[4][1].add(rate_info[4][2])).div(1000);
        totalCash = totalCash.add(cash).add(rt_quota);
        
        if(now < rate_info[5][2]){
            uint lottery = usdt_amount.mul(rate_info[4][3]).div(1000);
            rate_info[5][1]= rate_info[5][1].add(lottery);
            Winner = msg.sender;
        }else{
           totalCash = totalCash.add(lottery);
        }
        
    }
 
    
    
    
    function claim(uint _usdt)public {
        
        //count excnange rate
        uint totalBalances = count_totalBalances();
        uint plt_amount = _usdt.mul(token_supply).div(totalBalances);
        require(plt.balanceOf(msg.sender) >= plt_amount);
       
            
        uint fee = _usdt.mul(rate_info[1][3]).div(1000);
        totalCash = totalCash.add(fee);
        uint usdt_amount = _usdt.sub(fee);
        
        
        usdt.transfer(msg.sender,usdt_amount);
        plt.transferFrom(msg.sender,address(this),plt_amount);
      
        totalCash = totalCash.sub(usdt_amount);
    }
    
    
    
    function count_totalBalances()private returns(uint){
        token_supply = plt.totalSupply().sub(plt.balanceOf(address(this))).add(collateral);
        uint totalBalances = totalCash.add(totalBorrows);
        return totalBalances;
    }
    
    
    
    
    function ProfitSharing(uint plt_amount)private {
        
        address MyRt = msg.sender;
        
        for(uint i=1; i<=3; i++){
            MyRt = rt.get_recommender(MyRt);
            uint profit = plt_amount.mul(rate_info[3][i]).div(1000);
            
            if(MyRt != address(0x0)){
                plt.transfer(MyRt,profit);
                user_info[MyRt][7] = user_info[MyRt][7].add(profit);
            }else{
                plt.transfer(owner,profit);
                user_info[owner][7] = user_info[owner][7].add(profit);
            }
            
        }
        
    }
     
    
    
    
    function Receivelotto()public {
        require(now>=rate_info[5][2]);
        require(msg.sender == Winner || msg.sender == owner);
        usdt.transfer(Winner,rate_info[5][1]);
        
        rate_info[5][1] = 0;
        rate_info[5][2] = now.add(432000);
    }
    
    
    
    
    
    
    function borrow(uint _usdt)public {
        //計算最高可借金額
        uint asset = plt.balanceOf(msg.sender);
        uint totalBalances = count_totalBalances();
        uint loanable = asset.mul(totalBalances).div(token_supply);
        loanable = loanable.mul(rate_info[1][4]).div(1000);
        require(loanable >= _usdt);
         
        //計算抵押的資產
        uint collateral_amount = _usdt.mul(token_supply).div(totalBalances);
        collateral_amount = collateral_amount.mul(1000).div(rate_info[1][4]); 
        user_info[msg.sender][5] =  user_info[msg.sender][5].add(collateral_amount);
        
        //計算清算線
        uint asset_price = collateral_amount.mul(totalBalances).div(token_supply);
        uint Liquidat_price = asset_price.mul(rate_info[1][5]).div(1000);
        user_info[msg.sender][6] = user_info[msg.sender][6].add(Liquidat_price);
        
        //計算應付
        uint total_repay = count_payable(_usdt);
        
        
        //平台變數調整
        totalCash = totalCash.sub(_usdt);
        totalBorrows = totalBorrows.add(total_repay);
        collateral = collateral.add(collateral_amount);
        usdt.transfer(msg.sender,_usdt);
        plt.transferFrom(msg.sender,address(this),collateral);
        
    }
    
    
    
    function count_borrow_APR()private view returns(uint){
         //-----------計算借款年利率------------
        uint markup_borrows = rate_info[1][2].mul(totalBorrows);        //markup_rate*totalBorrows
        uint totalBalances = totalCash.add(totalBorrows);               //totalCash+totalBorrows
        uint markup_utilization = markup_borrows.div(totalBalances);  
        uint borrow_APR = rate_info[1][1].add(markup_utilization);      //base_rate + markup_utilization
        return borrow_APR;
    }
    
    
    function count_payable(uint _usdt)private returns(uint){
        //-----------計算應付------------
        uint borrow_APR = count_borrow_APR();
        uint repay_interest = _usdt.mul(borrow_APR).div(10**8);     //應付利息
        uint total_repay = _usdt.add(repay_interest);               //應付利息及本金    
        user_info[msg.sender][3] = user_info[msg.sender][3].add(_usdt);
        user_info[msg.sender][4] = user_info[msg.sender][4].add(total_repay);
        return total_repay;
        
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
    
    
    
    function get_totalCash()public view returns(uint){
        return totalCash;
    }
    
    function get_borrows()public view returns(uint){
        return totalBorrows;
    }
    
    function get_collateral()public view returns(uint){
        return collateral;
    }
    
    
    function get_out_share()public view  returns(uint){
        uint _token_supply = plt.totalSupply().sub(plt.balanceOf(address(this))).add(collateral);
        return _token_supply;
    } 
    
    

    
    
    
    
}