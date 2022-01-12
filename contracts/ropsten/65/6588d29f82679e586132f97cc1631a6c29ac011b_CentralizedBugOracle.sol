/**
 *Submitted for verification at Etherscan.io on 2022-01-11
*/

pragma solidity ^0.4.24;


 
contract Oracle {

    function isOutcomeSet() public view returns (bool);
    function getOutcome() public view returns (int);
}





 
 
contract Proxied {
    address public masterCopy;
}

 
 
contract Proxy is Proxied {
     
     
    constructor(address _masterCopy)
        public
    {
        require(_masterCopy != 0);
        masterCopy = _masterCopy;
    }

     
    function ()
        external
        payable
    {
        address _masterCopy = masterCopy;
        assembly {
            calldatacopy(0, 0, calldatasize())
            let success := delegatecall(not(0), _masterCopy, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
        }
    }
}


contract CentralizedBugOracleData {
  event OwnerReplacement(address indexed newOwner);
  event OutcomeAssignment(int outcome);

   
  address public owner;
  bytes public ipfsHash;
  bool public isSet;
  int public outcome;
  address public maker;
  address public taker;

   
  modifier isOwner () {
       
      require(msg.sender == owner);
      _;
  }
}

contract CentralizedBugOracleProxy is Proxy, CentralizedBugOracleData {

     
     
    constructor(address proxied, address _owner, bytes _ipfsHash, address _maker, address _taker)
        public
        Proxy(proxied)
    {
         
        require(_ipfsHash.length == 46);
        owner = _owner;
        ipfsHash = _ipfsHash;
        maker = _maker;
        taker = _taker;
    }
}

contract CentralizedBugOracle is Proxied,Oracle, CentralizedBugOracleData{

   
   
  function setOutcome(int _outcome)
      public
      isOwner
  {
       
      require(!isSet);
      _setOutcome(_outcome);
  }

   
   
  function isOutcomeSet()
      public
      view
      returns (bool)
  {
      return isSet;
  }

   
   
  function getOutcome()
      public
      view
      returns (int)
  {
      return outcome;
  }


   
  function _setOutcome(int _outcome) internal {
    isSet = true;
    outcome = _outcome;
    emit OutcomeAssignment(_outcome);
  }


}