pragma solidity ^0.8.3;

contract Suka {

  Cuka[] public contra;
    
  function getContractCount() public view returns(uint contractCount)
  {
    return contra.length;
  }


  function newCookie() public returns(Cuka newContract)
  {
    Cuka c = new Cuka();
    contra.push(c);
    return c;
  }
}


contract Cuka {
    
uint256 public heh;
//uint256 public lel;

constructor() { 
        heh=block.timestamp;  
      //  lel=leel;   
} 
    
  function getFlavor() public pure returns (string memory flavor)
  {
    return "mmm ... chocolate chip";
  }    
}

