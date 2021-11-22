/**
 *Submitted for verification at BscScan.com on 2021-11-21
*/

pragma solidity ^0.5.5;

contract Randomizer {
  function getRandomNumber(uint256 seed) external returns (uint256 value){}
}
contract MyCoin {
  function totalSupply() public view  returns (uint256 supply){}
  function balanceOf(address _owner) public view  returns (uint256 balance){}
  function transfer(address _to, uint256 _value)  external returns (bool success){}
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){}
  function approve(address _spender, uint256 _value) public returns (bool success){}
  function allowance(address _owner, address _spender) public returns (uint256 remaining){}

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  uint public decimals;
  string public name;
  address public owner;
}

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
contract MyNFT {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function mint(address to, 
                uint256 resistenceLevel, // Attribute 1
                uint256 flushLevel, // Attribute 2
                uint256 productionLevel// Attribute 3
                ) external returns (uint256) {}
    function balanceOf(address owner) public view returns (uint256 balance){}
    function ownerOf(uint256 tokenId) public view returns (address owner){}
    function safeTransferFrom(address from, address to, uint256 tokenId) public{}
    function transferFrom(address from, address to, uint256 tokenId) public{}
    function approve(address to, uint256 tokenId) public{}
    function getApproved(uint256 tokenId) public view returns (address operator){}
    
    function setApprovalForAll(address operator, bool _approved) public{}
    function isApprovedForAll(address owner, address operator) public view returns (bool){}
    
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public{}
    function tokensOfOwner(address owner) public view returns (uint256[] memory) {}
    
    function GetMushroomLevel(uint256 tokenId, uint256 attr) public view returns (uint256 level) {}
    function GetMushConfigurations(uint256 tokenId) public view returns (uint256 resistenceLevel, uint256 flushLevel, uint256 productionLevel) {}
    function AddMushroomLevel(uint256 tokenId, uint256 attr)  public  returns (uint256 newLevel) {}
}


contract Governance {

    address public _governance;

    constructor() public {
        _governance = tx.origin;
    }

    event GovernanceTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyGovernance {
        require(msg.sender == _governance, "not governance");
        _;
    }

    function setGovernance(address governance)  public  onlyGovernance
    {
        require(governance != address(0), "new governance the zero address");
        emit GovernanceTransferred(_governance, governance);
        _governance = governance;
    }


}

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract GameController is Governance {
    using SafeMath for uint256;
    
    MyNFT nftContract;
    MyCoin coinContract;
    Randomizer randomizerContract;

    uint256[] public productionPerLevel = [0, 50,60,70,80,90,100];
    uint256[] public flushPerLevel = [0,5,6,7,8,9,10];
    uint256[] public resistencePerLevel = [0,650,700,750,800,850,900];
    uint256[] public upgradeChancePerLevel = [0,150,60,25,10,4];
    uint256[] public upgradeCostPerLevel = [0,150,175,200,225,250];

    function setPerLevel(
        uint256[] memory _productionPerLevel, 
        uint256[] memory _flushPerLevel, 
        uint256[] memory _resistencePerLevel, 
        uint256[] memory _upgradeChancePerLevel, 
        uint256[] memory _upgradeCostPerLevel) public {
            productionPerLevel = _productionPerLevel;
            flushPerLevel = _flushPerLevel;
            resistencePerLevel = _resistencePerLevel;
            upgradeChancePerLevel = _upgradeChancePerLevel;
            upgradeCostPerLevel = _upgradeCostPerLevel; 
    }

    uint256 public maxLevel = 6;
    uint256 public dryInterval = 15 hours;// (60 * 60 * 24) * 15; // 15 days   
    uint256 public flushInterval = 1 hours;//  (60 * 60 * 24) * 1; // 1 days
    uint256 public contaminationInterval = 2 hours;//  (60 * 60 * 24) * 2; // 2 days
    uint256 public mushBulkPrice = 140000000000000000000; // 14 coin (7$)
    uint256 public mushDryedPrice = 10000000000000000000; // 1 coin -> 50dm (5$) -> 35$ - 45% = 19.25$ - 7$ = 12.75$
    uint256 public newMushroomPrice = 1500000000000000000000; // 150 coin (15$)
    uint256 public upgradePrice = 10000000000000000000; // 150 coin (15$)


    bool public bulkCreationActive = true;
    bool public sellDryPackActive = true;
    bool public upgradeMushActive = true;

    function setMaxLevel(uint256 _maxLevel) external onlyGovernance {
        maxLevel = _maxLevel;
    }

    event BuyNewMushroomWithCoinEvent (uint256 tokenId);
    function BuyNewMushroomWithCoin() external {
        require(coinContract.balanceOf(msg.sender) >= newMushroomPrice, "Not enough coin");
        require(coinContract.transferFrom(msg.sender, address(this), newMushroomPrice), "Error on payment");
        emit BuyNewMushroomWithCoinEvent(nftContract.mint(msg.sender,1,1,1));
    }
    

    function setPrices(uint256 _mushDryedPrice, uint256 _mushBulkPrice, uint256 _mushroomPrice, uint256 _upgradePrice) external onlyGovernance {
        mushDryedPrice = _mushDryedPrice;
        mushBulkPrice = _mushBulkPrice;
        newMushroomPrice = _mushroomPrice;
        upgradePrice = _upgradePrice;
    }

    function setDryInterval(uint256 interval) external onlyGovernance  {
        dryInterval = interval;
    }

    function setFlushInterval(uint256 interval) external onlyGovernance  {
        flushInterval = interval;
    }

    function transferNFTToDexOwner(uint256 tokenId) external onlyGovernance {
        nftContract.transferFrom(address(this), msg.sender, tokenId );
    }

    function transferCoinToDexOwner(uint256 amount) external onlyGovernance {
        uint256 bal = getCoinBalance();
        require(bal > 0, "Coin balance is 0");
        require(bal >= amount, "Coin balance is not enougth");
        coinContract.transfer(msg.sender, amount);
    }
    
    function transferBNBToDexOwner() external onlyGovernance {
        uint256 bal = address(this).balance;
        require(bal > 0, "BNB balance is 0");
        msg.sender.transfer(address(this).balance);
    }

    function SetCoinTokenAddress(address tokenAddress) external onlyGovernance {
        coinContract = MyCoin(tokenAddress);
    }

    function SetNFTTokenAddress(address tokenAddress) external onlyGovernance {
        nftContract = MyNFT(tokenAddress);
    }

    function SetRandomizerAddress(address tokenAddress) external onlyGovernance {
        randomizerContract = Randomizer(tokenAddress);
    }

    function getCoinBalance() public view returns (uint256) {
        return coinContract.balanceOf(msg.sender);
    }

    event UpgradeMushroomEvent (uint256 tokenId, uint256 attribute, uint256 level, bool isUpgraded);
    function UpgradeMushroom(uint256 tokenId, uint256 attribute)external returns (uint256){
        require(upgradeMushActive, "Upgrade mush is not active");
        require(nftContract.ownerOf(tokenId) == msg.sender, "Not your mushroom");

        uint256 mushLevel = nftContract.GetMushroomLevel(tokenId, attribute);

        require(coinContract.balanceOf(msg.sender) >= upgradePrice * upgradeCostPerLevel[mushLevel] , "Not enough coin");
        require(mushLevel < maxLevel, "Max level reached");
        require(coinContract.transferFrom(msg.sender, address(this), upgradePrice * upgradeCostPerLevel[mushLevel] ), "Error on payment");
        
        uint256 currentChance = upgradeChancePerLevel[mushLevel];
        uint256 roll = randomizerContract.getRandomNumber(currentChance + tokenId + mushLevel);
        bool success = roll <= currentChance;
        if(success) {
            mushLevel = nftContract.AddMushroomLevel(tokenId, attribute);
        }
        emit UpgradeMushroomEvent(tokenId, attribute, mushLevel, success);
        return mushLevel;
    }
    

    mapping(address => MushDryedPack[]) public _mushDryedPacks;

    struct MushDryedPack{
        uint256 count;
        uint256 dryDate;
    }

    function getMushDryedPack(uint256 index) public view returns (uint256, uint256){
        require(index < _mushDryedPacks[msg.sender].length, "Index out of range");
        return (_mushDryedPacks[msg.sender][index].count, _mushDryedPacks[msg.sender][index].dryDate);
    }
    function getMushDryedPacksCount() public view returns (uint256) {
        return _mushDryedPacks[msg.sender].length;
    }


    function getMushDryedPacks(uint256 index) public view returns (uint256 count, uint256 dryDate) {
        return (
            _mushDryedPacks[msg.sender][index].count, 
            _mushDryedPacks[msg.sender][index].dryDate
            );
    }

    function CreateNewDryPack(uint256 count) internal {
        _mushDryedPacks[msg.sender].push(MushDryedPack(count, now + dryInterval));
    }

    event SellDryedPackEvent (uint256 index, uint256 count, uint256 fee, uint256 value);
    function SellDryedPack(uint256 index) external {
        require(sellDryPackActive, "Sell dry pack is not active");
        require(index < _mushDryedPacks[msg.sender].length, "Index invalid");
        require(_mushDryedPacks[msg.sender][index].count > 0, "Insuficient dryed packs");
        uint256 valueToReceive = _mushDryedPacks[msg.sender][index].count * mushDryedPrice;
        uint256 fee = 0;
        if(_mushDryedPacks[msg.sender][index].dryDate > now){
            uint256 dryDateProportion = (_mushDryedPacks[msg.sender][index].dryDate - now) / dryInterval;
            fee = (((valueToReceive * 100) * dryDateProportion) / 100);
            require(fee < valueToReceive, "Error on fee value");
            valueToReceive = valueToReceive - fee;
        }
        require(coinContract.balanceOf(address(this)) >= valueToReceive, "Insuficient coins on plataform");
        coinContract.transferFrom(address(this), msg.sender, valueToReceive);
        _mushDryedPacks[msg.sender][index].count = 0;
        emit SellDryedPackEvent(index, _mushDryedPacks[msg.sender][index].count, fee, valueToReceive);
        //_mushDryedPacks[msg.sender].pop(index);
    }



    mapping(uint256 => MushBulk) public _bulks;    


    struct MushBulk {
        uint256 flushCount; // Numero de colheitas que ainda podem ser realizadas
        uint256 nextHarvest; //Depois dessa data você pode colher e após a colheita é atualizado esse valor com 1 dia
        uint256 contaminationTime; //Depois dessa data o bulk precisa ser refeito
    }

    event StartBulkEvent (uint256 tokenId, uint256 flushCount, uint256 nextHarvest, uint256 contaminationTime);
    function StartBulk(uint256 tokenId) external returns (bool) {
        require(bulkCreationActive, "Bulk creation is not active");
        require(nftContract.ownerOf(tokenId) == msg.sender, "Not your mushroom");
        require(coinContract.balanceOf(msg.sender) >= mushBulkPrice, "Not enough coin");
        require(coinContract.transferFrom(msg.sender, address(this), mushBulkPrice), "Error on payment");
        _bulks[tokenId] = MushBulk(
            flushPerLevel[nftContract.GetMushroomLevel(tokenId, 2)],
            now + flushInterval,
            now + contaminationInterval
        );
        emit StartBulkEvent(tokenId, _bulks[tokenId].flushCount, _bulks[tokenId].nextHarvest, _bulks[tokenId].contaminationTime);
        return true;
    }


    function GetBulk(uint256 tokenId) public view returns (uint256, uint256, uint256) {
        return (
            _bulks[tokenId].flushCount,
             _bulks[tokenId].nextHarvest,
              _bulks[tokenId].contaminationTime
              );
    }

    function BulkIsDied(uint256 tokenId) public view returns (bool) {
        return (
            _bulks[tokenId].contaminationTime <= now
        );
    }

    function BulkCanHarvest(uint256 tokenId) public view returns (bool) {
        return (
            _bulks[tokenId].nextHarvest <= now &&
            _bulks[tokenId].flushCount > 0
        );
    }

    event BulkHarvestEvent (uint256 tokenId, uint256 roll, uint256 chance, uint256 count, bool success);
    function BulkHarvest(uint256 tokenId) external returns (bool) {
        require(nftContract.ownerOf(tokenId) == msg.sender, "Only owner can harvest bulk");
        require(!BulkIsDied(tokenId), "Bulk is died");
        require(BulkCanHarvest(tokenId), "Bulk can't harvest");
        _bulks[tokenId].flushCount--;
        _bulks[tokenId].nextHarvest = now + flushInterval;
        _bulks[tokenId].contaminationTime = now + contaminationInterval;
        uint256 roll = randomizerContract.getRandomNumber(_bulks[tokenId].nextHarvest+_bulks[tokenId].flushCount);
        bool success = roll <= resistencePerLevel[nftContract.GetMushroomLevel(tokenId, 1)];
        uint256 production = 0;
        if(success){
            production = productionPerLevel[nftContract.GetMushroomLevel(tokenId, 3)];
            CreateNewDryPack(production);
        }
        emit BulkHarvestEvent (tokenId, roll, resistencePerLevel[nftContract.GetMushroomLevel(tokenId, 1)], production, success);
        return success;
    }

}