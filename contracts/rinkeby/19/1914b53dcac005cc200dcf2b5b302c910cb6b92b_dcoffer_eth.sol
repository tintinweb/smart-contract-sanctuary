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



contract dcoffer_eth{
    using SafeMath for uint;
    
    IERC20 deth  = IERC20(address(0x957B6EA1C56692Dfc3682a675B25C3aFdd6d7CB8));
    
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }  
    
    constructor()public {
        owner = msg.sender;
        totalCash = 1*10**18;
        
    }
    
     
    address public owner;
    uint totalSupply;
    uint totalBorrows;
    uint totalReserves;
    uint totalCash;
   
    
    
    function deposit()external payable{
        uint deth_amount = count_exchange(msg.value);
        deth.transfer(msg.sender,deth_amount);
        totalCash = totalCash.add(msg.value);
    }
    
    
    function count_exchange(uint eth_amont)private returns(uint){
        totalSupply = deth.totalSupply().sub(deth.balanceOf(address(this)));
        uint outShare = eth_amont.mul(totalSupply);
        uint balance = totalCash.add(totalBorrows).sub(totalReserves);
        uint deth_amount = outShare.div(balance);
        return deth_amount;
    }
    
    
    
    //---------------------------------------------view-------------------------------------------------------
    
   
    function get_totalSupply()public view returns(uint){
        uint outShare = deth.totalSupply().sub(deth.balanceOf(address(this)));
        return outShare;
    }
    
    
    function get_totalBorrows()public view returns(uint){
        return totalBorrows;
    }
    
    
    function get_totalReserves()public view returns(uint){
        return totalReserves;
    }
    
    
    function get_totalCash()public view returns(uint){
        return totalCash;
    }       
        
    
   
    
    
}