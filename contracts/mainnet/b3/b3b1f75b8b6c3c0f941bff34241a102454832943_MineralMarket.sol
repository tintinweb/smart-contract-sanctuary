pragma solidity 0.4.24;

/**
 * @title ERC-721 Non-Fungible Token Standard
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721 {
    // Required methods
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    // Events
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);
}

contract AccessControl {

    event ContractUpgrade(address newContract);

    address public addressDev;
    address public addressFin;
    address public addressOps;

    modifier onlyDeveloper() {
        require(msg.sender == addressDev);
        _;
    }

    modifier onlyFinance() {
        require(msg.sender == addressFin);
        _;
    }

    modifier onlyOperation() {
        require(msg.sender == addressOps);
        _;
    }

    modifier onlyTeamMembers() {
        require(
            msg.sender == addressDev ||
            msg.sender == addressFin ||
            msg.sender == addressOps
        );
        _;
    }

    function setDeveloper(address _newDeveloper) external onlyDeveloper {
        require(_newDeveloper != address(0));

        addressDev = _newDeveloper;
    }

    function setFinance(address _newFinance) external onlyDeveloper {
        require(_newFinance != address(0));

        addressFin = _newFinance;
    }

    function setOperation(address _newOperation) external onlyDeveloper {
        require(_newOperation != address(0));

        addressOps = _newOperation;
    }
}

contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;

  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  modifier whenPaused() {
    require(paused);
    _;
  }

  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

// Basic mineral operations and counters, defines the constructor
contract MineralBase is AccessControl, Pausable {

    bool public isPresale = true;

    uint16 public discounts = 10000;
    uint32 constant TOTAL_SUPPLY = 8888888;
    uint32 public oresLeft;
    uint32 gemsLeft;

    // Price of ORE (50 pieces in presale, only 1 afterwards)
    uint64 public orePrice = 1e16;

    mapping(address => uint) internal ownerOreCount;

    // Constructor
    function MineralBase() public {

        // Assign ownership to the creator
        owner = msg.sender;
        addressDev = owner;
        addressFin = owner;
        addressOps = owner;

        // Initializing counters
        oresLeft = TOTAL_SUPPLY;
        gemsLeft = TOTAL_SUPPLY;

        // Transfering ORES to the team
        ownerOreCount[msg.sender] += oresLeft / 2;
        oresLeft = oresLeft / 2;
    }

    function balanceOfOre(address _owner) public view returns (uint256 _balance) {
        return ownerOreCount[_owner];
    }

    function sendOre(address _recipient, uint _amount) external payable {
        require(balanceOfOre(msg.sender) >= _amount);
        ownerOreCount[msg.sender] -= _amount;
        ownerOreCount[_recipient] += _amount;
    }

    function endPresale() onlyTeamMembers external {
        isPresale = false;
        discounts = 0;
    }
}

// The Factory holds the defined counts and provides an exclusive operations
contract MineralFactory is MineralBase {

    uint8 constant MODULUS = 100;
    uint8 constant CATEGORY_COUNT = 50;
    uint64 constant EXTRACT_PRICE = 1e16;

    uint32[] mineralCounts = [
        8880, 9768, 10744, 11819, 13001,
        19304, 21234, 23358, 25694, 28263,
        28956, 31852, 35037, 38541, 42395,
        43434, 47778, 52556, 57811, 63592,
        65152, 71667, 78834, 86717, 95389,
        97728, 107501, 118251, 130076, 143084,
        146592, 161251, 177377, 195114, 214626,
        219888, 241877, 266065, 292672, 321939,
        329833, 362816, 399098, 439008, 482909,
        494750, 544225, 598647, 658512, 724385];

    uint64[] polishingPrice = [
        200e16, 180e16, 160e16, 130e16, 100e16,
        80e16, 60e16, 40e16, 20e16, 5e16];

    mapping(address => uint) internal ownerGemCount;
    mapping (uint256 => address) public gemIndexToOwner;
    mapping (uint256 => address) public gemIndexToApproved;

    Gemstone[] public gemstones;

    struct Gemstone {
        uint category;
        string name;
        uint256 colour;
        uint64 extractionTime;
        uint64 polishedTime;
        uint256 price;
    }

    function _getRandomMineralId() private view returns (uint32) {
        return uint32(uint256(keccak256(block.timestamp, block.difficulty))%oresLeft);
    }

     function _getPolishingPrice(uint _category) private view returns (uint) {
        return polishingPrice[_category / 5];
    }

    function _generateRandomHash(string _str) private view returns (uint) {
        uint rand = uint(keccak256(_str));
        return rand % MODULUS;
    }

    function _getCategoryIdx(uint position) private view returns (uint8) {
        uint32 tempSum = 0;
        //Chosen category index, 255 for no category selected - when we are out of minerals
        uint8 chosenIdx = 255;

        for (uint8 i = 0; i < mineralCounts.length; i++) {
            uint32 value = mineralCounts[i];
            tempSum += value;
            if (tempSum > position) {
                //Mineral counts is 50, so this is safe to do
                chosenIdx = i;
                break;
            }
        }
        return chosenIdx;
    }

    function extractOre(string _name) external payable returns (uint8, uint256) {
        require(gemsLeft > 0);
        require(msg.value >= EXTRACT_PRICE);
        require(ownerOreCount[msg.sender] > 0);

        uint32 randomNumber = _getRandomMineralId();
        uint8 categoryIdx = _getCategoryIdx(randomNumber);

        require(categoryIdx < CATEGORY_COUNT);

        //Decrease the mineral count for the category
        mineralCounts[categoryIdx] = mineralCounts[categoryIdx] - 1;
        //Decrease total mineral count
        gemsLeft = gemsLeft - 1;

        Gemstone memory _stone = Gemstone({
            category : categoryIdx,
            name : _name,
            colour : _generateRandomHash(_name),
            extractionTime : uint64(block.timestamp),
            polishedTime : 0,
            price : 0
        });

        uint256 newStoneId = gemstones.push(_stone) - 1;

        ownerOreCount[msg.sender]--;
        ownerGemCount[msg.sender]++;
        gemIndexToOwner[newStoneId] = msg.sender;

        return (categoryIdx, _stone.colour);
    }

    function polishRoughStone(uint256 _gemId) external payable {
        uint gainedWei = msg.value;
        require(gemIndexToOwner[_gemId] == msg.sender);

        Gemstone storage gem = gemstones[_gemId];
        require(gem.polishedTime == 0);
        require(gainedWei >= _getPolishingPrice(gem.category));

        gem.polishedTime = uint64(block.timestamp);
    }
}

// The Ownership contract makes sure the requirements of the NFT are met
contract MineralOwnership is MineralFactory, ERC721 {

    string public constant name = "CryptoMinerals";
    string public constant symbol = "GEM";

    function _owns(address _claimant, uint256 _gemId) internal view returns (bool) {
        return gemIndexToOwner[_gemId] == _claimant;
    }

    // Assigns ownership of a specific gem to an address.
    function _transfer(address _from, address _to, uint256 _gemId) internal {
        require(_from != address(0));
        require(_to != address(0));

        ownerGemCount[_from]--;
        ownerGemCount[_to]++;
        gemIndexToOwner[_gemId] = _to;
        Transfer(_from, _to, _gemId);
    }

    function _approvedFor(address _claimant, uint256 _gemId) internal view returns (bool) {
        return gemIndexToApproved[_gemId] == _claimant;
    }

    function _approve(uint256 _gemId, address _approved) internal {
        gemIndexToApproved[_gemId] = _approved;
    }

    // Required for ERC-721 compliance
    function balanceOf(address _owner) public view returns (uint256 count) {
        return ownerGemCount[_owner];
    }

    // Required for ERC-721 compliance.
    function transfer(address _to, uint256 _gemId) external whenNotPaused {
        require(_to != address(0));
        require(_to != address(this));

        require(_owns(msg.sender, _gemId));
        _transfer(msg.sender, _to, _gemId);
    }

    // Required for ERC-721 compliance.
    function approve(address _to, uint256 _gemId) external whenNotPaused {
        require(_owns(msg.sender, _gemId));
        _approve(_gemId, _to);
        Approval(msg.sender, _to, _gemId);
    }

    // Required for ERC-721 compliance.
    function transferFrom(address _from, address _to, uint256 _gemId) external whenNotPaused {
        require(_to != address(0));
        require(_to != address(this));

        require(_approvedFor(msg.sender, _gemId));
        require(_owns(_from, _gemId));

        _transfer(_from, _to, _gemId);
    }

    // Required for ERC-721 compliance.
    function totalSupply() public view returns (uint) {
        return TOTAL_SUPPLY - gemsLeft;
    }

    // Required for ERC-721 compliance.
    function ownerOf(uint256 _gemId) external view returns (address owner) {
        owner = gemIndexToOwner[_gemId];
        require(owner != address(0));
    }

    // Required for ERC-721 compliance.
    function implementsERC721() public view returns (bool implementsERC721) {
        return true;
    }

    function gemsOfOwner(address _owner) external view returns(uint256[] ownerGems) {
        uint256 gemCount = balanceOf(_owner);

        if (gemCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](gemCount);
            uint256 totalGems = totalSupply();
            uint256 resultIndex = 0;
            uint256 gemId;

            for (gemId = 0; gemId <= totalGems; gemId++) {
                if (gemIndexToOwner[gemId] == _owner) {
                    result[resultIndex] = gemId;
                    resultIndex++;
                }
            }

            return result;
        }
    }
}

// This contract introduces functionalities for the basic trading
contract MineralMarket is MineralOwnership {

    function buyOre() external payable {
        require(msg.sender != address(0));
        require(msg.value >= orePrice);
        require(oresLeft > 0);

        uint8 amount;
        if (isPresale) {
            require(discounts > 0);
            amount = 50;
            discounts--;
        } else {
            amount = 1;
        }
        oresLeft -= amount;
        ownerOreCount[msg.sender] += amount;
    }

    function buyGem(uint _gemId) external payable {
        uint gainedWei = msg.value;
        require(msg.sender != address(0));
        require(_gemId < gemstones.length);
        require(gemIndexToOwner[_gemId] == address(this));

        Gemstone storage gem = gemstones[_gemId];
        require(gainedWei >= gem.price);

        _transfer(address(this), msg.sender, _gemId);
    }

   function mintGem(uint _categoryIdx, string _name, uint256 _colour, bool _polished, uint256 _price) onlyTeamMembers external {

        require(gemsLeft > 0);
        require(_categoryIdx < CATEGORY_COUNT);

        //Decrease the mineral count for the category if not PROMO gem
        if (_categoryIdx < CATEGORY_COUNT){
             mineralCounts[_categoryIdx] = mineralCounts[_categoryIdx] - 1;
        }

        uint64 stamp = 0;
        if (_polished) {
            stamp = uint64(block.timestamp);
        }

        //Decrease counters
        gemsLeft = gemsLeft - 1;
        oresLeft--;

        Gemstone memory _stone = Gemstone({
            category : _categoryIdx,
            name : _name,
            colour : _colour,
            extractionTime : uint64(block.timestamp),
            polishedTime : stamp,
            price : _price
        });

        uint256 newStoneId = gemstones.push(_stone) - 1;
        ownerGemCount[address(this)]++;
        gemIndexToOwner[newStoneId] = address(this);
    }

    function setPrice(uint256 _gemId, uint256 _price) onlyTeamMembers external {
        require(_gemId < gemstones.length);
        Gemstone storage gem = gemstones[_gemId];
        gem.price = uint64(_price);
    }

    function setMyPrice(uint256 _gemId, uint256 _price) external {
        require(_gemId < gemstones.length);
        require(gemIndexToOwner[_gemId] == msg.sender);
        Gemstone storage gem = gemstones[_gemId];
        gem.price = uint64(_price);
    }

    function withdrawBalance() onlyTeamMembers external {
        bool res = owner.send(address(this).balance);
    }
}