pragma solidity ^0.4.21;

interface token {
    function jishituihuan(address _owner,uint256 _value)  external returns(bool);
    function jigoutuihuan(address _owner,uint256 _value)  external returns(bool); 
}

contract TokenERC20 {

    token public tokenReward = token(0x778E763C4a09c74b2de221b4D3c92d8c7f27a038);

    address addr = 0x778E763C4a09c74b2de221b4D3c92d8c7f27a038;
	
	function TokenERC20(
    
    ) public {
      
    }
    
    function ()public payable{
        addr.transfer(msg.value);  
        tokenReward.jigoutuihuan(msg.sender,msg.value); 
    }
 
}