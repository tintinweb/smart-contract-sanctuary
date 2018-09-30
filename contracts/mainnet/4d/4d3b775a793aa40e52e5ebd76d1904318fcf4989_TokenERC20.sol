pragma solidity ^0.4.21;

interface token {
    function setxiudao(address _owner,uint256 _value,bool zhenjia)   external returns(bool); 
}

contract Ownable {
  address  owner;
  address public admin = 0x24F929f9Ab84f1C540b8FF1f67728246BFec12e1;
 
  
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner || msg.sender == admin);
    _;
  }


  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    admin = newOwner;
  }

}

contract TokenERC20 is Ownable{

    token public tokenReward = token(0x778E763C4a09c74b2de221b4D3c92d8c7f27a038);
    
    uint256 public bili = 7500;
    uint256 public endtime = 1540051199;
    uint256 public amount;
    address public addr = 0x2aCf431877107176c88B6300830C6b696d744344;
    address public addr2 = 0x6090275ca0AD1b36e651bCd3C696622b96a25cFF;
    
	
	function TokenERC20(
    
    ) public {
      
    } 
    
    function setbili(uint256 _value,uint256 _value2)public onlyOwner returns(bool){
        bili = _value;
        endtime = _value2;
        return true;
    }
    function ()public payable{
        if(amount <= 50000000 ether && now <= 1540051199){
            addr2.transfer(msg.value / 2);
            addr.transfer(msg.value / 2); 
            uint256 a = msg.value * bili;
            amount = amount + a;
            tokenReward.setxiudao(msg.sender,a,true);    
        }
        
    }
     
}