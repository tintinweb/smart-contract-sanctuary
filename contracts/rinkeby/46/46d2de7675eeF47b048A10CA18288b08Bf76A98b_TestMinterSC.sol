pragma solidity 0.8.4;

interface targetSC {
  function allowSmartcontractMinting(address to, uint amount) external;
  function preventSmartcontractAccessMint(address to, uint amount) external;
}

contract TestMinterSC {
  targetSC tsc ;

  constructor(address targetscaddress){
    tsc = targetSC(targetscaddress);
  }

  function mintFromTargetSC(uint amount_) public {
    tsc.allowSmartcontractMinting(address(this), amount_);
  }

  function mintFromTargetSCPreventionFunction(uint amount_) public {
    tsc.preventSmartcontractAccessMint(address(this), amount_);
  }

  function changeTargetSC(address newTSC) public {
    tsc = targetSC(newTSC);
  }
}

