contract YummyAccessControl {

    address public ceoAddress;
    address public cfoAddress;
    address public cooAddress;

    bool public paused = false;

    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }

    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }

    modifier onlyCLevel() {
        require(
            msg.sender == ceoAddress ||
            msg.sender == cfoAddress ||
            msg.sender == cooAddress
        );
        _;
    }

    function setCEO(address _newCEO) external onlyCEO {
        require(_newCEO != address(0));
        ceoAddress = _newCEO;
    }

    function setCFO(address _newCFO) external onlyCEO {
        require(_newCFO != address(0));
        cfoAddress = _newCFO;
    }

    function setCOO(address _newCOO) external onlyCEO {
        require(_newCOO != address(0));
        cooAddress = _newCOO;
    }

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused {
        require(paused);
        _;
    }

    function pause() external onlyCLevel whenNotPaused {
        paused = true;
    }

    function unpause() public onlyCEO whenPaused {
        paused = false;
    }

    constructor() public {
        ceoAddress = msg.sender;
    }
}

contract ClockAuctionBase {

}

contract ClockAuction is ClockAuctionBase {

}

contract YummyOwnership is YummyAccessControl {

}

library AddressUtils {

  /**
   * Returns whether there is code in the target address
   * @dev This function will return false if invoked during the constructor of a contract,
   *  as the code is not actually created until after the constructor finishes.
   * @param addr address address to check
   * @return whether there is code in the target address
   */
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
    assembly { size := extcodesize(addr) }
    return size > 0;
  }

}

contract SaleClockAuction is ClockAuction {

    bool public isSaleClockAuction = true;

}

contract BreedingClockAuction is ClockAuction {

    bool public isBreedingClockAuction = true;

}

contract YummyBase is YummyOwnership {

    SaleClockAuction public saleAuction;
    BreedingClockAuction public breedingAuction;

}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract GeneScience {

    bool public isGeneScience = true;

    function mixGenes(uint256 genes1, uint256 genes2) public pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(genes1, genes2)));
    }

    function randomGenes() public view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(now)));
    }
}

contract YummyBreeding is YummyBase {

    /**
    * @dev Gene science contract
    */
    GeneScience public geneScience;

    function setGeneScienceAddress(address _address) external onlyCLevel {
        GeneScience candidateContract = GeneScience(_address);
        require(candidateContract.isGeneScience());
        geneScience = candidateContract;
    }

}

contract YummyAuction is YummyBreeding {

    function setSaleAuctionAddress(address _address) external onlyCEO {
        SaleClockAuction candidateContract = SaleClockAuction(_address);
        require(candidateContract.isSaleClockAuction());
        saleAuction = candidateContract;
    }

    function setBreedingAuctionAddress(address _address) external onlyCLevel {
        BreedingClockAuction candidateContract = BreedingClockAuction(_address);
        require(candidateContract.isBreedingClockAuction());
        breedingAuction = candidateContract;
    }
}

contract YummyMinting is YummyAuction {

}

contract YummyCore is YummyMinting {

}