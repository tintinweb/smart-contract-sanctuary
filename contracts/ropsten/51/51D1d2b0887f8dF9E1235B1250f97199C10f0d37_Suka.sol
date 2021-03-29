pragma solidity ^0.8.3;

contract Suka {

  Cuka[] public contra;
    
  function getContractCount() public view returns(uint contractCount)
  {
    return contra.length;
  }


  function newCookie(uint256 time) public returns(Cuka newContract)
  {
    Cuka c = new Cuka(time);
    contra.push(c);
    return c;
  }
}


contract Cuka {
    
uint256 public heh;
uint256 public lel;

constructor(uint256 leel) { 
        heh=block.timestamp;  
        lel=leel;   
} 
    
  function getFlavor() public pure returns (string memory flavor)
  {
    return "mmm ... chocolate chip";
  }    
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}