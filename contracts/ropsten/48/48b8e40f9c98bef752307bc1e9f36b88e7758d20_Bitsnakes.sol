pragma solidity ^0.4.24;

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
    address wallet;
    uint percentage;
  }
  
  beneficiary[] public beneficiaries;

  mapping (address => uint256) public availableBalance;

  uint256 public inGameBalances;
  uint256 public beneficiariesBalance;
  uint256 public depositFee = 50;
  uint256 public inGameAmount = 0.001 ether;
  uint256 public inGameFee = 50;
  address[] public players;
  bool public gameIsOngoing;
  
  event Deposit(address indexed from, uint256 amount, uint256 feeUsed, uint256 timestamp);
  event Withdraw(address indexed from, uint256 amount, uint256 timestamp);
  event Game(bool isOngoing);
  event PlayerJoined(address indexed from, uint256 playerNumber);


  constructor() public {
    beneficiaries.push(beneficiary({
      wallet:0x0Ec793B3F6ECf6FC2D371F7e2000337A1CB47dA6,
      percentage:20
    }));

    beneficiaries.push(beneficiary({
      wallet:0x0Ec793B3F6ECf6FC2D371F7e2000337A1CB47dA6,
      percentage:20
    }));

    beneficiaries.push(beneficiary({
      wallet:0x0Ec793B3F6ECf6FC2D371F7e2000337A1CB47dA6,
      percentage:60
    }));

  }

  function deposit() payable public whenNotPaused {
    uint256 amount = msg.value;
    uint256 feeAmount = amount.mul(depositFee).div(100);
    uint256 userAmount = amount - feeAmount;
    availableBalance[msg.sender] = availableBalance[msg.sender].add(userAmount);
    beneficiariesBalance = beneficiariesBalance.add(feeAmount);
    emit Deposit(msg.sender, amount, depositFee, now);
  }

  /*Send funds to the contract address so it can process the deposit*/
  function () payable public {
    deposit();
  }

  function withdraw(uint256 amount) public whenNotPaused {
    availableBalance[msg.sender] = availableBalance[msg.sender].sub(amount);
    msg.sender.transfer(amount);
    emit Withdraw(msg.sender, amount, now);    
  }

  function joinGame() public whenNotPaused {
    uint256 feeAmount = inGameAmount.mul(inGameFee).div(100);
    uint256 userAmount = inGameAmount - feeAmount;
    availableBalance[msg.sender] = availableBalance[msg.sender].sub(userAmount);
    inGameBalances = inGameBalances.add(userAmount);
    beneficiariesBalance = beneficiariesBalance.add(feeAmount);
    players.push(msg.sender);
    emit PlayerJoined(msg.sender, players.length);

    if(players.length==20){
      gameIsOngoing = true;
      emit Game(true);
    }
  }

  function distributeBalances(address[] _players, uint256[] _amounts) onlyOwner public {
    require(_players.length==_amounts.length);
    for(uint256 i = 0; i<_players.length; i++){
      inGameBalances.sub(_amounts[i]);
      availableBalance[_players[i]] = availableBalance[_players[i]].add(_amounts[i]);
    }
  }

  function endRound() onlyOwner public {
    gameIsOngoing = false;
    players.length = 0;
    emit Game(false);
  }

  function transferToBeneficiaries() public {
    for(uint256 i = 0; i<beneficiaries.length; i++){
      beneficiaries[i].wallet.transfer(beneficiariesBalance.mul(beneficiaries[i].percentage).div(100));
    }
    beneficiariesBalance = 0;
  }

  function changeDepositFee(uint256 newFee) onlyOwner public {
    depositFee = newFee;
  }

  function changeInGameFee(uint256 newFee) onlyOwner public {
    inGameFee = newFee;
  }

  function getPlayers() public view returns(address[]) {
    return players;
  }

  function totalPlayers() public view returns(uint) {
    return players.length;
  }

  function isPlaying(address player) public view returns (bool) {
    for(uint256 i = 0; i<players.length; i++){
      if(players[i]==player){
        return true;
      }
    }
    return false;
  }





}