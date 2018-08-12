/**
 * DragonKing game configuration contract
**/

pragma solidity ^0.4.23;


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


contract DragonKingConfig is Ownable {

  constructor(uint8 characterFee, uint8 eruptionThresholdInHours, uint8 percentageOfCharactersToKill, uint128[] charactersCosts) public {
		fee = characterFee;
    for (uint8 i = 0; i < charactersCosts.length; i++) {
      costs.push(uint128(charactersCosts[i]) * 1 finney);
      values.push(costs[i] - costs[i] / 100 * fee);
    }
    eruptionThreshold = uint256(eruptionThresholdInHours) * 60 * 60; // convert to seconds
    percentageToKill = percentageOfCharactersToKill;
    maxCharacters = 600;
    teleportPrice = 1000000000000000000;
    protectionPrice = 1000000000000000000;
    fightFactor = 4;
  }

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
}