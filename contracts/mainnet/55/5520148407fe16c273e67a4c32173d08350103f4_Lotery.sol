pragma solidity ^0.4.0;

interface Hash {
   
    function get() public returns (bytes32); 

}

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
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


contract StandardToken {

    using SafeMath for uint256;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    uint256 public totalSupply;
    mapping (address => mapping (address => uint256)) allowed;
    mapping(address => uint256) balances;

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }


    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));

        uint256 _allowance = allowed[_from][msg.sender];

        // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
        // require (_value <= _allowance);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     *
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /**
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     */
    /*function increaseApproval (address _spender, uint _addedValue)
    returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue)
    returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }*/

}



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
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

contract Lotery is Ownable {

  //event when gamer is buying a new ticket
  event TicketSelling(uint periodNumber, address indexed from, bytes32 hash, uint when);

  //event when period finished
  event PeriodFinished(uint periodNumber, address indexed winnerAddr, uint reward, bytes32 winnerHash, uint when);

  //event when any funds transferred
  event TransferBenefit(address indexed to, uint value);

  event JackPot(uint periodNumber, address winnerAddr, bytes32 winnerHash, uint value, uint when);


//current period of the game
  uint public currentPeriod;

  //if maxTicketAmount is not rised and maxPeriodDuration from period start is gone everyone can finish current round
  uint public maxPeriodDuration;

  uint public maxTicketAmount;

  //ticket price in this contract
  uint public ticketPrice;

  //part for owner
  uint public benefitPercents;

  //funds for owner
  uint public benefitFunds;

  //jackPot percents
  uint public jackPotPercents;

  uint public jackPotFunds;

  bytes32 public jackPotBestHash;


  //base game hash from other contract Hash
  bytes32 private baseHash;

  Hash private hashGenerator;

  //period struct
  struct period {
  uint number;
  uint startDate;
  bytes32 winnerHash;
  address winnerAddress;
  uint raised;
  uint ticketAmount;
  bool finished;
  uint reward;
  }

  //ticket struct
  struct ticket {
  uint number;
  address addr;
  bytes32 hash;
  }


  //ticket store
  mapping (uint => mapping (uint => ticket)) public tickets;

  //periods store
  mapping (uint => period) public periods;


  function Lotery(uint _maxPeriodDuration, uint _ticketPrice, uint _benefitPercents, uint _maxTicketAmount, address _hashAddr, uint _jackPotPercents) public {

    require(_maxPeriodDuration > 0 && _ticketPrice > 0 && _benefitPercents > 0 && _benefitPercents < 50 && _maxTicketAmount > 0 && _jackPotPercents > 0 && _jackPotPercents < 50);
    //set data in constructor
    maxPeriodDuration = _maxPeriodDuration;
    ticketPrice = _ticketPrice;
    benefitPercents = _benefitPercents;
    maxTicketAmount = _maxTicketAmount;
    jackPotPercents = _jackPotPercents;

    //get initial hash
    hashGenerator = Hash(_hashAddr);
    baseHash = hashGenerator.get();

    //start initial period
    periods[currentPeriod].number = currentPeriod;
    periods[currentPeriod].startDate = now;


  }



  //start new period
  function startNewPeriod() private {
    //if prev period finished
    require(periods[currentPeriod].finished);
    //init new period
    currentPeriod++;
    periods[currentPeriod].number = currentPeriod;
    periods[currentPeriod].startDate = now;

  }





  //buy ticket with specified round and passing string data
  function buyTicket(uint periodNumber, string data) payable public {

    //only with ticket price!
    require(msg.value == ticketPrice);
    //only if current ticketAmount < maxTicketAmount
    require(periods[periodNumber].ticketAmount < maxTicketAmount);
    //roundNumber is currentRound
    require(periodNumber == currentPeriod);

    processTicketBuying(data, msg.value, msg.sender);

  }


  //buy ticket with msg.data and currentRound when transaction happened
  function() payable public {

    //only with ticket price!
    require(msg.value == ticketPrice);
    //only if current ticketAmount < maxTicketAmount
    require(periods[currentPeriod].ticketAmount < maxTicketAmount);


    processTicketBuying(string(msg.data), msg.value, msg.sender);


  }

  function processTicketBuying(string data, uint value, address sender) private {


    //MAIN SECRET!
    //calc ticket hash from baseHash and user data
    //nobody knows baseHash
    bytes32 hash = sha256(data, baseHash);

    //update base hash for next tickets
    baseHash = sha256(hash, baseHash);

    //set winner if this is a best hash in round
    if (periods[currentPeriod].ticketAmount == 0 || (hash < periods[currentPeriod].winnerHash)) {
      periods[currentPeriod].winnerHash = hash;
      periods[currentPeriod].winnerAddress = sender;
    }

    //update tickets store
    tickets[currentPeriod][periods[currentPeriod].ticketAmount].number = periods[currentPeriod].ticketAmount;
    tickets[currentPeriod][periods[currentPeriod].ticketAmount].addr = sender;
    tickets[currentPeriod][periods[currentPeriod].ticketAmount].hash = hash;


    //update periods store
    periods[currentPeriod].ticketAmount++;
    periods[currentPeriod].raised += value;

    //call events
    TicketSelling(currentPeriod, sender, hash, now);

    //automatically finish and start new round if max ticket amount is raised
    if (periods[currentPeriod].ticketAmount >= maxTicketAmount) {
      finishRound();
    }

  }


  //finish round
  function finishRound() private {

    //only if not finished yet
    require(!periods[currentPeriod].finished);
    //only if ticketAmount >= maxTicketAmount
    require(periods[currentPeriod].ticketAmount >= maxTicketAmount);


    //calc reward for current winner with minus %

    uint fee = ((periods[currentPeriod].raised * benefitPercents) / 100);
    uint jack = ((periods[currentPeriod].raised * jackPotPercents) / 100);


    uint winnerReward = periods[currentPeriod].raised - fee - jack;

    //calc owner benefit
    benefitFunds += periods[currentPeriod].raised - winnerReward;


    //if first time
    if (jackPotBestHash == 0x0) {
      jackPotBestHash = periods[currentPeriod].winnerHash;
    }
    //all other times
    if (periods[currentPeriod].winnerHash < jackPotBestHash) {

      jackPotBestHash = periods[currentPeriod].winnerHash;


      if (jackPotFunds > 0) {
        winnerReward += jackPotFunds;
        JackPot(currentPeriod, periods[currentPeriod].winnerAddress, periods[currentPeriod].winnerHash, jackPotFunds, now);

      }

      jackPotFunds = 0;

    }

    //move jack to next round
    jackPotFunds += jack;

    //calc expected balance
    uint plannedBalance = this.balance - winnerReward;

    //send ether to winner
    periods[currentPeriod].winnerAddress.transfer(winnerReward);

    //update period data
    periods[currentPeriod].reward = winnerReward;
    periods[currentPeriod].finished = true;

    //call events
    PeriodFinished(currentPeriod, periods[currentPeriod].winnerAddress, winnerReward, periods[currentPeriod].winnerHash, now);

    //automatically start new period
    startNewPeriod();

    //check balance
    assert(this.balance == plannedBalance);
  }

  //benefit for owner
  function benefit() public onlyOwner {
    require(benefitFunds > 0);

    uint plannedBalance = this.balance - benefitFunds;
    owner.transfer(benefitFunds);
    benefitFunds = 0;

    TransferBenefit(owner, benefitFunds);
    assert(this.balance == plannedBalance);
  }

  //manually finish and restart round
  function finishRoundAndStartNew() public {
    //only if round has tickets
    require(periods[currentPeriod].ticketAmount > 0);
    //only if date is expired
    require(periods[currentPeriod].startDate + maxPeriodDuration < now);
    //restart round
    finishRound();
  }


}