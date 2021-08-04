/**
 *Submitted for verification at Etherscan.io on 2021-08-04
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



interface IERC20 {
    function totalSupply() public view returns (uint supply);
    function balanceOf( address who ) public view returns (uint value);
    function transfer( address to, uint value) public returns (bool ok);
    function transferFrom( address from, address to, uint value) public returns (bool ok);
}



interface USDTERC20 {
    function totalSupply() public constant returns (uint);
    function balanceOf(address who) public constant returns (uint);
    function transfer(address to, uint value) public;
    function transferFrom(address from, address to, uint value) public;
}



contract dcoffer{
    using SafeMath for uint;
    
    IERC20 dusdt   = IERC20(address(0x9A07B78aa3674de7936F5e469B59c354822BEd7B));
    USDTERC20 usdt = USDTERC20(address(0x4B0ecf5232FFA413050404E5845FAF5332DE1C5D));
    
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }  
    
    constructor()public {
        owner = msg.sender;
        totalCash = 1*10**6;
        
    }
    
     
    address public owner;
    uint totalSupply;
    uint totalBorrows;
    uint totalReserves;
    uint totalCash;
   
    
    
    function deposit(uint usdt_amont)external{
        uint dusdt_amount = count_exchange(usdt_amont);
        
        dusdt.transfer(msg.sender,dusdt_amount);
        usdt.transferFrom(msg.sender,address(this),usdt_amont);
        totalCash = totalCash.add(usdt_amont);
    }
    
    
    function count_exchange(uint usdt_amont)private returns(uint){
        totalSupply = dusdt.totalSupply().sub(dusdt.balanceOf(address(this)));
        uint outShare = usdt_amont.mul(totalSupply);
        uint balance = totalCash.add(totalBorrows).sub(totalReserves);
        uint dusdt_amount = outShare.div(balance);
        return dusdt_amount;
    }
    
   
    
    
        
    
    
    
    
    
    
    
    
    
}