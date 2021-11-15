pragma solidity ^0.8.3;

contract Suka {

  Cuka[] public contracts;
    
  function getContractCount() public view returns(uint contractCount)
  {
    return contracts.length;
  }


  function newCookie(uint256 time) public returns(Cuka newContract)
  {
    Cuka c = new Cuka(time);
    contracts.push(c);
    return c;
  }
}


contract Cuka {
    
uint256 public time;

constructor(uint256 stamp) { 
        time=stamp;      
} 
    
  function getFlavor() public pure returns (string memory flavor)
  {
    return "mmm ... chocolate chip";
  }    
}

