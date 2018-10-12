pragma solidity ^0.4.18;

// DragonKingConfig v2.0 2e59d4

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: zeppelin-solidity/contracts/token/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: zeppelin-solidity/contracts/token/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/DragonKingConfig.sol

/**
 * DragonKing game configuration contract
**/

pragma solidity ^0.4.23;


contract DragonKingConfig is Ownable {

  struct PurchaseRequirement {
    address[] tokens;
    uint256[] amounts;
  }

  /**
   * creates Configuration for the DragonKing game
   * tokens array should be in the following order:
      0    1    2    3     4    5    6    7     8
     [tpt, ndc, skl, xper, mag, stg, dex, luck, gift]
  */
  constructor(uint8 characterFee, uint8 eruptionThresholdInHours, uint8 percentageOfCharactersToKill, uint128[] charactersCosts, address[] tokens) public {
    fee = characterFee;
    for (uint8 i = 0; i < charactersCosts.length; i++) {
      costs.push(uint128(charactersCosts[i]) * 1 finney);
      values.push(costs[i] - costs[i] / 100 * fee);
    }
    eruptionThreshold = uint256(eruptionThresholdInHours) * 60 * 60; // convert to seconds
    castleLootDistributionThreshold = 1 days; // once per day
    percentageToKill = percentageOfCharactersToKill;
    maxCharacters = 600;
    teleportPrice = 1000000000000000000;
    protectionPrice = 1000000000000000000;
    luckThreshold = 4200;
    fightFactor = 4;
    giftTokenAmount = 1000000000000000000;
    giftToken = ERC20(tokens[8]);
    // purchase requirements
    // knights
    purchaseRequirements[7].tokens = [tokens[5]]; // 5 STG
    purchaseRequirements[7].amounts = [250];
    purchaseRequirements[8].tokens = [tokens[5]]; // 5 STG
    purchaseRequirements[8].amounts = [5*(10**2)];
    purchaseRequirements[9].tokens = [tokens[5]]; // 10 STG
    purchaseRequirements[9].amounts = [10*(10**2)];
    purchaseRequirements[10].tokens = [tokens[5]]; // 20 STG
    purchaseRequirements[10].amounts = [20*(10**2)];
    purchaseRequirements[11].tokens = [tokens[5]]; // 50 STG
    purchaseRequirements[11].amounts = [50*(10**2)];
    // wizards
    purchaseRequirements[15].tokens = [tokens[2], tokens[3]]; // 5 SKL % 10 XPER
    purchaseRequirements[15].amounts = [25*(10**17), 5*(10**2)];
    purchaseRequirements[16].tokens = [tokens[2], tokens[3], tokens[4]]; // 5 SKL & 10 XPER & 2.5 MAG
    purchaseRequirements[16].amounts = [5*(10**18), 10*(10**2), 250];
    purchaseRequirements[17].tokens = [tokens[2], tokens[3], tokens[4]]; // 10 SKL & 20 XPER & 5 MAG
    purchaseRequirements[17].amounts = [10*(10**18), 20*(10**2), 5*(10**2)];
    purchaseRequirements[18].tokens = [tokens[2], tokens[3], tokens[4]]; // 25 SKL & 50 XP & 10 MAG
    purchaseRequirements[18].amounts = [25*(10**18), 50*(10**2), 10*(10**2)];
    purchaseRequirements[19].tokens = [tokens[2], tokens[3], tokens[4]]; // 50 SKL & 100 XP & 20 MAG
    purchaseRequirements[19].amounts = [50*(10**18), 100*(10**2), 20*(10**2)]; 
    purchaseRequirements[20].tokens = [tokens[2], tokens[3], tokens[4]]; // 100 SKL & 200 XP & 50 MAG 
    purchaseRequirements[20].amounts = [100*(10**18), 200*(10**2), 50*(10**2)];
    // archers
    purchaseRequirements[21].tokens = [tokens[2], tokens[3]]; // 2.5 SKL & 5 XPER
    purchaseRequirements[21].amounts = [25*(10**17), 5*(10**2)];
    purchaseRequirements[22].tokens = [tokens[2], tokens[3], tokens[6]]; // 5 SKL & 10 XPER & 2.5 DEX
    purchaseRequirements[22].amounts = [5*(10**18), 10*(10**2), 250];
    purchaseRequirements[23].tokens = [tokens[2], tokens[3], tokens[6]]; // 10 SKL & 20 XPER & 5 DEX
    purchaseRequirements[23].amounts = [10*(10**18), 20*(10**2), 5*(10**2)];
    purchaseRequirements[24].tokens = [tokens[2], tokens[3], tokens[6]]; // 25 SKL & 50 XP & 10 DEX
    purchaseRequirements[24].amounts = [25*(10**18), 50*(10**2), 10*(10**2)];
    purchaseRequirements[25].tokens = [tokens[2], tokens[3], tokens[6]]; // 50 SKL & 100 XP & 20 DEX
    purchaseRequirements[25].amounts = [50*(10**18), 100*(10**2), 20*(10**2)]; 
    purchaseRequirements[26].tokens = [tokens[2], tokens[3], tokens[6]]; // 100 SKL & 200 XP & 50 DEX 
    purchaseRequirements[26].amounts = [100*(10**18), 200*(10**2), 50*(10**2)];
  }

  /** the Gift token contract **/
  ERC20 public giftToken;
  /** amount of gift tokens to send **/
  uint256 public giftTokenAmount;
  /** purchase requirements for each type of character **/
  PurchaseRequirement[30] purchaseRequirements; 
  /** the cost of each character type */
  uint128[] public costs;
  /** the value of each character type (cost - fee), so it&#39;s not necessary to compute it each time*/
  uint128[] public values;
  /** the fee to be paid each time an character is bought in percent*/
  uint8 fee;
  /** The maximum of characters allowed in the game */
  uint16 public maxCharacters;
  /** the amount of time that should pass since last eruption **/
  uint256 public eruptionThreshold;
  /** the amount of time that should pass ince last castle loot distribution **/
  uint256 public castleLootDistributionThreshold;
  /** how many characters to kill in %, e.g. 20 will stand for 20%, should be < 100 **/
  uint8 public percentageToKill;
  /* Cooldown threshold */
  uint256 public constant CooldownThreshold = 1 days;
  /** fight factor, used to compute extra probability in fight **/
  uint8 public fightFactor;

  /** the price for teleportation*/
  uint256 public teleportPrice;
  /** the price for protection */
  uint256 public protectionPrice;
  /** the luck threshold */
  uint256 public luckThreshold;

  function hasEnoughTokensToPurchase(address buyer, uint8 characterType) external returns (bool canBuy) {
    for (uint256 i = 0; i < purchaseRequirements[characterType].tokens.length; i++) {
      if (ERC20(purchaseRequirements[characterType].tokens[i]).balanceOf(buyer) < purchaseRequirements[characterType].amounts[i]) {
        return false;
      }
    }
    return true;
  }


  function setPurchaseRequirements(uint8 characterType, address[] tokens, uint256[] amounts) external {
    purchaseRequirements[characterType].tokens = tokens;
    purchaseRequirements[characterType].amounts = amounts;
  } 

  function getPurchaseRequirements(uint8 characterType) view external returns (address[] tokens, uint256[] amounts) {
    tokens = purchaseRequirements[characterType].tokens;
    amounts = purchaseRequirements[characterType].amounts;
  }

  /**
   * sets the prices of the character types
   * @param prices the prices in finney
   * */
  function setPrices(uint16[] prices) external onlyOwner {
    for (uint8 i = 0; i < prices.length; i++) {
      costs[i] = uint128(prices[i]) * 1 finney;
      values[i] = costs[i] - costs[i] / 100 * fee;
    }
  }

  /**
   * sets the eruption threshold
   * @param _value the threshold in seconds, e.g. 24 hours = 25*60*60
   * */
  function setEruptionThreshold(uint256 _value) external onlyOwner {
    eruptionThreshold = _value;
  }

  /**
   * sets the castle loot distribution threshold
   * @param _value the threshold in seconds, e.g. 24 hours = 25*60*60
   * */
  function setCastleLootDistributionThreshold(uint256 _value) external onlyOwner {
    castleLootDistributionThreshold = _value;
  }

  /**
   * sets the fee
   * @param _value for the fee, e.g. 3% = 3
   * */
  function setFee(uint8 _value) external onlyOwner {
    fee = _value;
  }

  /**
   * sets the percentage of characters to kill on eruption
   * @param _value the percentage, e.g. 10% = 10
   * */
  function setPercentageToKill(uint8 _value) external onlyOwner {
    percentageToKill = _value;
  }

  /**
   * sets the maximum amount of characters allowed to be present in the game
   * @param _value characters limit, e.g 600
   * */
  function setMaxCharacters(uint16 _value) external onlyOwner {
    maxCharacters = _value;
  }

  /**
   * sets the fight factor
   * @param _value fight factor, e.g 4
   * */
  function setFightFactor(uint8 _value) external onlyOwner {
    fightFactor = _value;
  }

  /**
   * sets the teleport price
   * @param _value base amount of TPT to transfer on teleport, e.g 10e18
   * */
  function setTeleportPrice(uint256 _value) external onlyOwner {
    teleportPrice = _value;
  }

  /**
   * sets the protection price
   * @param _value base amount of NDC to transfer on protection, e.g 10e18
   * */
  function setProtectionPrice(uint256 _value) external onlyOwner {
    protectionPrice = _value;
  }

  /**
   * sets the luck threshold
   * @param _value the minimum amount of luck tokens required for the second roll
   * */
  function setLuckThreshold(uint256 _value) external onlyOwner {
    luckThreshold = _value;
  }

  /**
   * sets the amount of tokens to gift threshold
   * @param _value new value of the amount to gift
   * */
  function setGiftTokenAmount(uint256 _value) {
    giftTokenAmount = _value;
  }

  /**
   * sets the gift token address
   * @param _value new gift token address
   * */
  function setGiftToken(address _value) {
    giftToken = ERC20(_value);
  }


}