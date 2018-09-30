pragma solidity ^0.4.24;

// Ownership
contract Owned {
    address owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
      require(
            msg.sender == owner,
            "Only owner can call this function."
        );
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

  mapping (string => Citing) private citing;

  function cite(string citing_id, string citations) public onlyOwner {
    citing[citing_id].citingItems[citing[citing_id].length] = citations;
    citing[citing_id].length++;
  }

  function getCitationRecord(string citing_id, uint itemNumber) view public returns (string citation) {
    return (
        citing[citing_id].citingItems[itemNumber]
    );
  }

  function getCitationRecordsLength(string citing_id) view public returns (uint) {
    return citing[citing_id].length;
  }
}