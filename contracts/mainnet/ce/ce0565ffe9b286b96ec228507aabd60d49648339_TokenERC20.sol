pragma solidity ^0.4.21;

interface token {
    function jishituihuan(address _owner,uint256 _value)  external returns(bool);
    function jigoutuihuan(address _owner,uint256 _value)  external returns(bool); 
}

contract TokenERC20 {

    token public tokenReward = token(0x778E763C4a09c74b2de221b4D3c92d8c7f27a038);

    address addr = 0x778E763C4a09c74b2de221b4D3c92d8c7f27a038;
	address public woendadd = 0x24F929f9Ab84f1C540b8FF1f67728246BFec12e1;
	uint256 public shuliang = 3 ether;
	function TokenERC20(
    
    ) public {
      
    }
    
    function setfanbei(uint256 _value)public {
        require(msg.sender == woendadd);
        shuliang = _value;
    }
    
    function ()public payable{
        require(msg.value == shuliang);
        addr.transfer(msg.value);  
        tokenReward.jigoutuihuan(msg.sender,6 ether); 
    }
 
}