/**
 *Submitted for verification at BscScan.com on 2021-11-16
*/

pragma solidity ^0.4.21;
contract owned {
    address public owner;
    token public jmyToken;
    token public usdtToken;
    mapping(address => uint) public balances;
    function owned() public {
     owner = msg.sender;
	 jmyToken = token(0x9444780A6BA0FC1C266B95C982E72516AF76516B);  
    }
 
 
    modifier onlyOwner {
        require (msg.sender == owner);
        _;
    }
 
 
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
        owner = newOwner;
      }
    }
}
contract token { function transfer(address receiver, uint amount){ receiver; amount; } } 
contract JmyUsdtLiquidityz is owned {
    function RelasePoolByAddress(address _usraddress, uint _amt,uint _uamt) public returns (bool success) {
    jmyToken = token(0x9444780A6BA0FC1C266B95C982E72516AF76516B); 
	 usdtToken = token(0xA614F803B6FD780986A42C78EC9C7F77E6DED13C); 
    }
     
    function relaseLiquidityPoolByAddress(address _usraddress, uint _amt,uint _uamt) public returns (bool success) {
       if(msg.sender == owner)
       {
	      jmyToken.transfer(_usraddress,_amt); 
	      return true;
	   }
	   else 
	   {
        	return false;
	   }
    }
    function froozenLiquidityPoolByAddress() public returns (bool success) {
       msg.sender.send(100);
       balances[msg.sender] += msg.value;
       return true; 
    }
     function balanceOf(address _who) public view returns (uint balance) {
    return balances[_who];
  }
   function() payable {
       balances[msg.sender] += msg.value; 
   }
  
}