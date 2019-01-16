pragma solidity ^0.5.0;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */

 library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);
    uint256 c = a / b;
    return c;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a && c >= b);
    return c;
  }
}



contract owned { //Contract used to only allow the owner to call some functions
	address public owner;

	constructor() public {
    owner = msg.sender;
  }

	modifier onlyOwner {
	  require(msg.sender == owner);
	  _;
	}

	function transferOwnership(address newOwner) onlyOwner public {
	  owner = newOwner;
	}
}



contract Pausable is owned {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}



contract Bitsnakes is owned, Pausable {
  using SafeMath for uint256;

  struct beneficiary{
    address payable wallet;
    uint percentage;
  }

  beneficiary[] public beneficiaries;

  uint256 public beneficiariesBalance;
  uint256 public depositFee = 50;
  uint256 public usersBalance;

  mapping (address => uint256) public availableBalance;

  event Deposit(address indexed from, uint256 amount, uint256 feeUsed, uint256 timestamp);
  event PlayersRewarded(uint256 totalPlayers);


  constructor() public {
    beneficiaries.push(beneficiary({
      wallet:0x0Ec793B3F6ECf6FC2D371F7e2000337A1CB47dA6,
      percentage:20
    }));

    beneficiaries.push(beneficiary({
      wallet:0xC2628b4e40013c926B281FBef189D28a2A180eeE,
      percentage:20
    }));

    beneficiaries.push(beneficiary({
      wallet:0xE0dfA056a7F5FB76e0d184AA017D6Fee0cE21b09,
      percentage:60
    }));

  }


  function deposit() payable public whenNotPaused {
    uint256 amount = msg.value;
    uint256 feeAmount = amount.mul(depositFee).div(100);
    uint256 userAmount = amount.sub(feeAmount);
    availableBalance[msg.sender] = availableBalance[msg.sender].add(userAmount);
    usersBalance = usersBalance.add(userAmount);
    beneficiariesBalance = beneficiariesBalance.add(feeAmount);
    emit Deposit(msg.sender, amount, depositFee, now);
  }


  /*Send funds to the contract address so it can process the deposit*/
  function () external payable  {
    deposit();
  }


  function rewardPlayers(address payable[] memory players, uint256[] memory inGameFeeAmounts, uint256[] memory rewardAmounts) onlyOwner public {
    require(players.length==inGameFeeAmounts.length && players.length==rewardAmounts.length);
    for(uint256 i = 0; i<players.length; i++){
      usersBalance = usersBalance.sub(inGameFeeAmounts[i]);
      availableBalance[players[i]] = availableBalance[players[i]].sub(inGameFeeAmounts[i]);
      players[i].transfer(rewardAmounts[i]);
    }
    emit PlayersRewarded(players.length);
  }


  function transferToBeneficiaries() public whenNotPaused {
    uint256 amount = beneficiariesBalance;
    beneficiariesBalance = 0;
    for(uint256 i = 0; i<beneficiaries.length; i++){
      beneficiaries[i].wallet.transfer(amount.mul(beneficiaries[i].percentage).div(100));
    }
  }


  function changeDepositFee(uint256 newFee) onlyOwner public {
    depositFee = newFee;
  }






}