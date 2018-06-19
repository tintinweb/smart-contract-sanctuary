pragma solidity ^0.4.18;


contract InterfaceContentCreatorUniverse {
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function priceOf(uint256 _tokenId) public view returns (uint256 price);
  function getNextPrice(uint price, uint _tokenId) public pure returns (uint);
  function lastSubTokenBuyerOf(uint tokenId) public view returns(address);
  function lastSubTokenCreatorOf(uint tokenId) public view returns(address);

  //
  function createCollectible(uint256 tokenId, uint256 _price, address creator, address owner) external ;
}

contract InterfaceYCC {
  function payForUpgrade(address user, uint price) external  returns (bool success);
  function mintCoinsForOldCollectibles(address to, uint256 amount, address universeOwner) external  returns (bool success);
  function tradePreToken(uint price, address buyer, address seller, uint burnPercent, address universeOwner) external;
  function payoutForMining(address user, uint amount) external;
  uint256 public totalSupply;
}

contract InterfaceMining {
  function createMineForToken(uint tokenId, uint level, uint xp, uint nextLevelBreak, uint blocknumber) external;
  function payoutMining(uint tokenId, address owner, address newOwner) external;
  function levelUpMining(uint tokenId) external;
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
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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

contract Owned {
  // The addresses of the accounts (or contracts) that can execute actions within each roles.
  address public ceoAddress;
  address public cooAddress;
  address private newCeoAddress;
  address private newCooAddress;


  function Owned() public {
      ceoAddress = msg.sender;
      cooAddress = msg.sender;
  }

  /*** ACCESS MODIFIERS ***/
  /// @dev Access modifier for CEO-only functionality
  modifier onlyCEO() {
    require(msg.sender == ceoAddress);
    _;
  }

  /// @dev Access modifier for COO-only functionality
  modifier onlyCOO() {
    require(msg.sender == cooAddress);
    _;
  }

  /// Access modifier for contract owner only functionality
  modifier onlyCLevel() {
    require(
      msg.sender == ceoAddress ||
      msg.sender == cooAddress
    );
    _;
  }

  /// @dev Assigns a new address to act as the CEO. Only available to the current CEO.
  /// @param _newCEO The address of the new CEO
  function setCEO(address _newCEO) public onlyCEO {
    require(_newCEO != address(0));
    newCeoAddress = _newCEO;
  }

  /// @dev Assigns a new address to act as the COO. Only available to the current COO.
  /// @param _newCOO The address of the new COO
  function setCOO(address _newCOO) public onlyCEO {
    require(_newCOO != address(0));
    newCooAddress = _newCOO;
  }

  function acceptCeoOwnership() public {
      require(msg.sender == newCeoAddress);
      require(address(0) != newCeoAddress);
      ceoAddress = newCeoAddress;
      newCeoAddress = address(0);
  }

  function acceptCooOwnership() public {
      require(msg.sender == newCooAddress);
      require(address(0) != newCooAddress);
      cooAddress = newCooAddress;
      newCooAddress = address(0);
  }

  mapping (address => bool) public youCollectContracts;
  function addYouCollectContract(address contractAddress, bool active) public onlyCOO {
    youCollectContracts[contractAddress] = active;
  }
  modifier onlyYCC() {
    require(youCollectContracts[msg.sender]);
    _;
  }

  InterfaceYCC ycc;
  InterfaceContentCreatorUniverse yct;
  InterfaceMining ycm;
  function setMainYouCollectContractAddresses(address yccContract, address yctContract, address ycmContract, address[] otherContracts) public onlyCOO {
    ycc = InterfaceYCC(yccContract);
    yct = InterfaceContentCreatorUniverse(yctContract);
    ycm = InterfaceMining(ycmContract);
    youCollectContracts[yccContract] = true;
    youCollectContracts[yctContract] = true;
    youCollectContracts[ycmContract] = true;
    for (uint16 index = 0; index < otherContracts.length; index++) {
      youCollectContracts[otherContracts[index]] = true;
    }
  }
  function setYccContractAddress(address yccContract) public onlyCOO {
    ycc = InterfaceYCC(yccContract);
    youCollectContracts[yccContract] = true;
  }
  function setYctContractAddress(address yctContract) public onlyCOO {
    yct = InterfaceContentCreatorUniverse(yctContract);
    youCollectContracts[yctContract] = true;
  }
  function setYcmContractAddress(address ycmContract) public onlyCOO {
    ycm = InterfaceMining(ycmContract);
    youCollectContracts[ycmContract] = true;
  }

}

contract TransferInterfaceERC721YC {
  function transferToken(address to, uint256 tokenId) public returns (bool success);
}
contract TransferInterfaceERC20 {
  function transfer(address to, uint tokens) public returns (bool success);
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ConsenSys/Tokens/blob/master/contracts/eip20/EIP20.sol
// ----------------------------------------------------------------------------
contract YouCollectBase is Owned {
  using SafeMath for uint256;

  event RedButton(uint value, uint totalSupply);

  // Payout
  function payout(address _to) public onlyCLevel {
    _payout(_to, this.balance);
  }
  function payout(address _to, uint amount) public onlyCLevel {
    if (amount>this.balance)
      amount = this.balance;
    _payout(_to, amount);
  }
  function _payout(address _to, uint amount) private {
    if (_to == address(0)) {
      ceoAddress.transfer(amount);
    } else {
      _to.transfer(amount);
    }
  }

  // ------------------------------------------------------------------------
  // Owner can transfer out any accidentally sent ERC20 tokens
  // ------------------------------------------------------------------------
  function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyCEO returns (bool success) {
      return TransferInterfaceERC20(tokenAddress).transfer(ceoAddress, tokens);
  }
}


contract InterfaceSpawn {
    uint public totalVotes;
    function getVotes(uint id) public view returns (uint _votes);
}

contract RocketsAndResources is YouCollectBase {
    InterfaceSpawn subcontinentDiscoveryVoting;

    event RocketLaunch(uint _rocketTokenId);
    event RocketAddFunds(uint _rocketTokenId, uint _res, uint _yccAmount, address _sender);
    event ResourcesDiscovered(uint _cityTokenId);
    event ResourcesTransfered(uint cityTokenId, uint _rocketTokenId, uint _res, uint _count);

    // ---------------------------
    // Configuration    
    bool public contractActive = false;

    uint discoveryCooldownMin = 1500;
    uint discoveryCooldownMax = 6000;
    uint discoveryPriceMin =  2000000000000000000000000;
    uint discoveryPriceMax = 25000000000000000000000000;

    uint rocketTravelTimeA = 10000;         // in resource-traveltime-formula A/x
    uint rocketTravelTimeMinBlocks = 24000; // added to traveltimes of resources
    uint rocketEarliestLaunchTime;
    // ---------------------------

    mapping (uint => uint) discoveryLastBlock;
    
    mapping (uint => uint[]) cityResourceRichness;  // eg [1, 6, 0, 0] --- gets added to resource-counts on discovery
    mapping (uint => uint[]) cityResourceCount;
    

    mapping (uint => uint[]) rocketResourceCount;
    mapping (uint => uint[]) rocketResourceYccFunds;
    mapping (uint => uint[]) rocketResourcePrices;

    mapping (uint => uint) rocketLaunchBlock;           // when owner launched the rocket
    mapping (uint => uint) rocketTravelTimeAtLaunch;    // when launched, we record the travel time (in case we change params in the formula)
    mapping (uint => uint) rocketTravelTimeIncrease;
    
    uint64 constant MAX_SUBCONTINENT_INDEX = 10000000000000;
    
    function RocketsAndResources() public {
        rocketEarliestLaunchTime = block.number + 36000; // earliest launch is 6 days after contract deploy
    }

    function setSubcontinentDiscoveryVotingContract(address spawnContract) public onlyCOO {
        subcontinentDiscoveryVoting = InterfaceSpawn(spawnContract);
    }

    function setContractActive(bool contractActive_) public onlyCOO {
        contractActive = contractActive_;
    }

    function setConfiguration(
        uint discoveryCooldownMin_,
        uint discoveryCooldownMax_,
        uint discoveryPriceMin_,
        uint discoveryPriceMax_,
        uint rocketEarliestLaunchTime_,
        uint rocketTravelTimeA_,
        uint rocketTravelTimeMinBlocks_
    ) public onlyYCC 
    {
        discoveryCooldownMin = discoveryCooldownMin_;
        discoveryCooldownMax = discoveryCooldownMax_;
        discoveryPriceMin = discoveryPriceMin_;
        discoveryPriceMax = discoveryPriceMax_;
        rocketEarliestLaunchTime = rocketEarliestLaunchTime_;
        rocketTravelTimeA = rocketTravelTimeA_;
        rocketTravelTimeMinBlocks = rocketTravelTimeMinBlocks_;
    }

    function setCityValues(uint[] cityTokenIds_, uint resourceLen_, uint[] resourceRichness_, uint[] resourceCounts_) public onlyYCC {
        uint len = cityTokenIds_.length;
        for (uint i = 0; i < len; i++) {
            uint city = cityTokenIds_[i];
            uint resourceBaseIdx = i * resourceLen_;
            cityResourceRichness[city] = new uint[](resourceLen_);
            cityResourceCount[city] = new uint[](resourceLen_);
            for (uint j = 0; j < resourceLen_; j++) {
                cityResourceRichness[city][j] = resourceRichness_[resourceBaseIdx + j];
                cityResourceCount[city][j] = resourceCounts_[resourceBaseIdx + j];
            }
        }
    }

    function setRocketValues(uint[] rocketTokenIds_, uint resourceLen_, uint[] resourceYccFunds_, uint[] resourcePrices_, uint[] resourceCounts_) public onlyYCC {
        uint len = rocketTokenIds_.length;
        for (uint i = 0; i < len; i++) {
            uint rocket = rocketTokenIds_[i];
            uint resourceBaseIdx = i * resourceLen_;
            rocketResourceCount[rocket] = new uint[](resourceLen_);
            rocketResourcePrices[rocket] = new uint[](resourceLen_);
            rocketResourceYccFunds[rocket] = new uint[](resourceLen_);
            for (uint j = 0; j < resourceLen_; j++) {
                rocketResourceCount[rocket][j] = resourceCounts_[resourceBaseIdx + j];
                rocketResourcePrices[rocket][j] = resourcePrices_[resourceBaseIdx + j];
                rocketResourceYccFunds[rocket][j] = resourceYccFunds_[resourceBaseIdx + j];
            }
        }
    }

    function getCityResources(uint cityTokenId_) public view returns (uint[] _resourceCounts) {
        _resourceCounts = cityResourceCount[cityTokenId_];
    }

    function getCityResourceRichness(uint cityTokenId_) public onlyYCC view returns (uint[] _resourceRichness) {
        _resourceRichness = cityResourceRichness[cityTokenId_];
    }

    function cityTransferResources(uint cityTokenId_, uint rocketTokenId_, uint res_, uint count_) public {
        require(contractActive);
        require(yct.ownerOf(cityTokenId_)==msg.sender);

        uint yccAmount = rocketResourcePrices[rocketTokenId_][res_] * count_;
        
        require(cityResourceCount[cityTokenId_][res_] >= count_);
        require(rocketResourceYccFunds[rocketTokenId_][res_] >= yccAmount);

        cityResourceCount[cityTokenId_][res_] -= count_;
        rocketResourceCount[rocketTokenId_][res_] += count_;
        rocketResourceYccFunds[rocketTokenId_][res_] -= yccAmount;

        ycc.payoutForMining(msg.sender, yccAmount);

        ResourcesTransfered(cityTokenId_, rocketTokenId_, res_, count_);
    }
    
    /*
        Resource Discovery
    */
    function discoveryCooldown(uint cityTokenId_) public view returns (uint _cooldownBlocks) {
        uint totalVotes = subcontinentDiscoveryVoting.totalVotes();
        if (totalVotes <= 0) 
            totalVotes = 1;
        uint range = discoveryCooldownMax-discoveryCooldownMin;
        uint subcontinentId = cityTokenId_ % MAX_SUBCONTINENT_INDEX;
        _cooldownBlocks = range - (subcontinentDiscoveryVoting.getVotes(subcontinentId).mul(range)).div(totalVotes) + discoveryCooldownMin;
    }
    function discoveryPrice(uint cityTokenId_) public view returns (uint _price) {
        uint totalVotes = subcontinentDiscoveryVoting.totalVotes();
        if (totalVotes <= 0) 
            totalVotes = 1;
        uint range = discoveryPriceMax-discoveryPriceMin;
        uint subcontinentId = cityTokenId_ % MAX_SUBCONTINENT_INDEX;
        _price = range - (subcontinentDiscoveryVoting.getVotes(subcontinentId).mul(range)).div(totalVotes) + discoveryPriceMin;
    }

    function discoveryBlocksUntilAllowed(uint cityTokenId_) public view returns (uint _blocks) {
        uint blockNextDiscoveryAllowed = discoveryLastBlock[cityTokenId_] + discoveryCooldown(cityTokenId_);
        if (block.number > blockNextDiscoveryAllowed) {
            _blocks = 0;
        } else {
            _blocks = blockNextDiscoveryAllowed - block.number;
        }
    }
    
    function discoverResources(uint cityTokenId_) public {
        require(contractActive);
        require(discoveryBlocksUntilAllowed(cityTokenId_) == 0);

        uint yccAmount = this.discoveryPrice(cityTokenId_);
        ycc.payForUpgrade(msg.sender, yccAmount);
        
        discoveryLastBlock[cityTokenId_] = block.number;
        
        uint resourceRichnessLen = cityResourceRichness[cityTokenId_].length;
        for (uint i = 0; i < resourceRichnessLen; i++) {
            cityResourceCount[cityTokenId_][i] += cityResourceRichness[cityTokenId_][i];
        }
        ResourcesDiscovered(cityTokenId_);
    }
    
    /*
        Rockets
    */
    function rocketTravelTimeByResource(uint rocketTokenId_, uint res_) public view returns (uint _blocks) {
        _blocks = rocketTravelTimeA * 6000 / rocketResourceCount[rocketTokenId_][res_];
    }
    function rocketTravelTime(uint rocketTokenId_) public view returns (uint _travelTimeBlocks) {
        _travelTimeBlocks = rocketTravelTimeMinBlocks + rocketTravelTimeIncrease[rocketTokenId_];
        
        uint resourceLen = rocketResourceCount[rocketTokenId_].length;
        for (uint i = 0; i < resourceLen; i++) {
            _travelTimeBlocks += rocketTravelTimeA * 6000 / rocketResourceCount[rocketTokenId_][i];
        }
    }
    function rocketBlocksUntilAllowedToLaunch() public view returns (uint _blocksUntilAllowed) {
        if (block.number > rocketEarliestLaunchTime) {
            _blocksUntilAllowed = 0;
        } else {
            _blocksUntilAllowed = rocketEarliestLaunchTime - block.number;
        }
    }
    function rocketIsLaunched(uint rocketTokenId_) public view returns (bool _isLaunched) { 
        _isLaunched = rocketLaunchBlock[rocketTokenId_] > 0;
    }
    function rocketArrivalTime(uint rocketTokenId_) public view returns (uint) {
        require(rocketLaunchBlock[rocketTokenId_] > 0);
        return rocketLaunchBlock[rocketTokenId_] + rocketTravelTimeAtLaunch[rocketTokenId_];
    }
    function increaseArrivalTime(uint rocketTokenId_, uint blocks) public onlyYCC {
        if (rocketLaunchBlock[rocketTokenId_] > 0)
            rocketTravelTimeAtLaunch[rocketTokenId_] = rocketTravelTimeAtLaunch[rocketTokenId_] + blocks;
        else
            rocketTravelTimeIncrease[rocketTokenId_] = rocketTravelTimeIncrease[rocketTokenId_] + blocks;
    }
    function decreaseArrivalTime(uint rocketTokenId_, uint blocks) public onlyYCC {
        if (rocketLaunchBlock[rocketTokenId_] > 0)
            rocketTravelTimeAtLaunch[rocketTokenId_] = rocketTravelTimeAtLaunch[rocketTokenId_] - blocks;
        else
            rocketTravelTimeIncrease[rocketTokenId_] = rocketTravelTimeIncrease[rocketTokenId_] - blocks;
    }
    function rocketTimeUntilMoon(uint rocketTokenId_) public view returns (uint _untilMoonBlocks) {
        uint arrivalTime = rocketArrivalTime(rocketTokenId_);
        if (block.number > arrivalTime) {
            _untilMoonBlocks = 0;
        } else {
            _untilMoonBlocks = arrivalTime - block.number;
        }
    }
    function rocketGetResourceValues(uint rocketTokenId_) public view returns (uint[] _yccAmounts, uint[] _resourcePrices, uint[] _resourceCounts) {
        _yccAmounts = rocketResourceYccFunds[rocketTokenId_];
        _resourcePrices = rocketResourcePrices[rocketTokenId_];
        _resourceCounts = rocketResourceCount[rocketTokenId_];
    }


    function rocketSetResourcePrice(uint rocketTokenId_, uint res_, uint yccPrice_) public {
        require(contractActive);
        require(yct.ownerOf(rocketTokenId_)==msg.sender);
        require(yccPrice_ > 0);
        rocketResourcePrices[rocketTokenId_][res_] = yccPrice_;
    }

    function rocketAddFunds(uint rocketTokenId_, uint res_, uint yccAmount_) public {
        require(contractActive);
        ycc.payForUpgrade(msg.sender, yccAmount_);
        rocketResourceYccFunds[rocketTokenId_][res_] += yccAmount_;

        RocketAddFunds(rocketTokenId_, res_, yccAmount_, msg.sender);
    }

    function rocketLaunch(uint rocketTokenId_) public {
        require(contractActive);
        require(block.number > rocketEarliestLaunchTime);
        require(yct.ownerOf(rocketTokenId_)==msg.sender);

        rocketLaunchBlock[rocketTokenId_] = block.number;
        rocketTravelTimeAtLaunch[rocketTokenId_] = rocketTravelTime(rocketTokenId_);

        RocketLaunch(rocketTokenId_);
    }
}