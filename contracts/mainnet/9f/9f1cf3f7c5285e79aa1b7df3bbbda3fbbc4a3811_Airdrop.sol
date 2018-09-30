pragma solidity ^0.4.21;


contract owned {

    mapping (address => bool) internal owners;
    
    constructor() public{
        owners[msg.sender] = true;
    }

    modifier onlyOwner {
        require(owners[msg.sender] == true);
        _;
    }

    function addOwner(address _newOwner) onlyOwner public{
        owners[_newOwner] = true;
    }
    
    function removeOwner(address _oldOwner) onlyOwner public{
        owners[_oldOwner] = false;
    }
}


contract ContractConn{
    function transfer(address _to, uint _value) public returns (bool success);
}

contract Airdrop is owned{
    
   constructor()  public payable{
         
   }
    
  function deposit() payable public{
  }
  
  function doAirdrop(address _tokenAddr, address[] _dests, uint256[] _values) onlyOwner public {
    ContractConn usb = ContractConn(_tokenAddr);
    uint256 i = 0;
    while (i < _dests.length) {
        usb.transfer(_dests[i], _values[i]);
        i += 1;
    }
  }
  
  function extract(address _tokenAddr,address _to,uint256 _value) onlyOwner  public{
      ContractConn usb = ContractConn(_tokenAddr);
      usb.transfer(_to,_value);
  }
  
  function extractEth(uint256 _value) onlyOwner  public{
      msg.sender.transfer(_value);
  }
  
}