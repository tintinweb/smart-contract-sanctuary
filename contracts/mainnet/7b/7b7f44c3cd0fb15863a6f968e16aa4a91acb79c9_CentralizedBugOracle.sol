pragma solidity ^0.4.24;


/// @title Abstract oracle contract - Functions to be implemented by oracles
contract Oracle {

    function isOutcomeSet() public view returns (bool);
    function getOutcome() public view returns (int);
}





/// @title Proxied - indicates that a contract will be proxied. Also defines storage requirements for Proxy.
/// @author Alan Lu - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="02636e636c42656c6d716b712c726f">[email&#160;protected]</a>>
contract Proxied {
    address public masterCopy;
}

/// @title Proxy - Generic proxy contract allows to execute all transactions applying the code of a master contract.
/// @author Stefan George - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="0271766764636c42656c6d716b712c726f">[email&#160;protected]</a>>
contract Proxy is Proxied {
    /// @dev Constructor function sets address of master copy contract.
    /// @param _masterCopy Master copy address.
    constructor(address _masterCopy)
        public
    {
        require(_masterCopy != 0);
        masterCopy = _masterCopy;
    }

    /// @dev Fallback function forwards all transactions and returns all received return data.
    function ()
        external
        payable
    {
        address _masterCopy = masterCopy;
        assembly {
            calldatacopy(0, 0, calldatasize())
            let success := delegatecall(not(0), _masterCopy, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch success
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}


contract CentralizedBugOracleData {
  event OwnerReplacement(address indexed newOwner);
  event OutcomeAssignment(int outcome);

  /*
   *  Storage
   */
  address public owner;
  bytes public ipfsHash;
  bool public isSet;
  int public outcome;
  address public maker;
  address public taker;

  /*
   *  Modifiers
   */
  modifier isOwner () {
      // Only owner is allowed to proceed
      require(msg.sender == owner);
      _;
  }
}

contract CentralizedBugOracleProxy is Proxy, CentralizedBugOracleData {

    /// @dev Constructor sets owner address and IPFS hash
    /// @param _ipfsHash Hash identifying off chain event description
    constructor(address proxied, address _owner, bytes _ipfsHash, address _maker, address _taker)
        public
        Proxy(proxied)
    {
        // Description hash cannot be null
        require(_ipfsHash.length == 46);
        owner = _owner;
        ipfsHash = _ipfsHash;
        maker = _maker;
        taker = _taker;
    }
}

contract CentralizedBugOracle is Proxied,Oracle, CentralizedBugOracleData{

  /// @dev Sets event outcome
  /// @param _outcome Event outcome
  function setOutcome(int _outcome)
      public
      isOwner
  {
      // Result is not set yet
      require(!isSet);
      _setOutcome(_outcome);
  }

  /// @dev Returns if winning outcome is set
  /// @return Is outcome set?
  function isOutcomeSet()
      public
      view
      returns (bool)
  {
      return isSet;
  }

  /// @dev Returns outcome
  /// @return Outcome
  function getOutcome()
      public
      view
      returns (int)
  {
      return outcome;
  }


  //@dev internal funcion to set the outcome sat
  function _setOutcome(int _outcome) internal {
    isSet = true;
    outcome = _outcome;
    emit OutcomeAssignment(_outcome);
  }


}