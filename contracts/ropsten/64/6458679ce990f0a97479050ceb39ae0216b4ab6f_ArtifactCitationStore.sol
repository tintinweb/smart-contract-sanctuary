pragma solidity ^0.4.24;

// Ownership
contract Owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
      require(msg.sender == owner);
      _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
      owner = newOwner;
    }
}

contract ArtifactCitationStore is Owned {
  struct Citing {
        uint length;
        mapping (uint => string) citingItems;
  }

  mapping (bytes32 => Citing) private citing;

  function cite(bytes32 citing_id, string citations) public onlyOwner {
    citing[citing_id].citingItems[citing[citing_id].length] = citations;
    citing[citing_id].length++;
  }

  function getCitationRecord(bytes32 citing_id, uint itemNumber) public constant returns (string citation) {
    return (
        citing[citing_id].citingItems[itemNumber]
    );
  }

  function getCitationRecordsLength(bytes32 citing_id) view public returns (uint) {
    return citing[citing_id].length;
  }
}