pragma solidity ^0.4.18;

contract CreditHydraToken {

  mapping (address => string) public ipfs_hash_of_uport_informations;

  // Minter State
  address public oracleAddress;

  // Modifiers
  modifier onlyOracle {
    if (msg.sender != oracleAddress) revert();
    _;
  }

  // Constructor
  function CreditHydraToken() public {
    oracleAddress = msg.sender;
  }

  // transfer owner
  function transferOracle(address _newOracle) public onlyOracle {
    oracleAddress = _newOracle;
  }

  // update uport ipfs hash
  function updateUportInfo( string _uport_ipfs_hash ) public returns (bool success) {
    ipfs_hash_of_uport_informations[msg.sender] = _uport_ipfs_hash;
    return true;
  }

  // update uport ipfs hash
  function updateUportInfoFromOracle( string _uport_ipfs_hash, address _address ) public onlyOracle returns (bool success) {
    ipfs_hash_of_uport_informations[_address] = _uport_ipfs_hash;
    return true;
  }

  // retrieve uport information
  function retrieveUportInfo() constant public returns (string ipfs_hash_of_uport_information ) {
    return ipfs_hash_of_uport_informations[msg.sender];
  }

  // kill contract itself
  function kill() onlyOracle public {
      selfdestruct(oracleAddress);
  }

  // fallback for ether
  function() payable public {
    revert();
  }
}