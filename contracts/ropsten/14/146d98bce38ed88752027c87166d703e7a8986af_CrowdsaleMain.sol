pragma solidity ^0.4.18;


library SafeMath {
  function mul(uint a, uint b) internal pure  returns (uint) {
    uint c = a * b;
    require(a == 0 || c / a == b);
    return c;
  }
  function div(uint a, uint b) internal pure returns (uint) {
    require(b > 0);
    uint c = a / b;
    require(a == b * c + a % b);
    return c;
  }
  function sub(uint a, uint b) internal pure returns (uint) {
    require(b <= a);
    return a - b;
  }
  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    require(c >= a);
    return c;
  }
  function max64(uint64 a, uint64 b) internal  pure returns (uint64) {
    return a >= b ? a : b;
  }
  function min64(uint64 a, uint64 b) internal  pure returns (uint64) {
    return a < b ? a : b;
  }
  function max256(uint256 a, uint256 b) internal  pure returns (uint256) {
    return a >= b ? a : b;
  }
  function min256(uint256 a, uint256 b) internal  pure returns (uint256) {
    return a < b ? a : b;
  }
}

contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) public constant returns (uint);
  function transfer(address to, uint value) public;
  event Transfer(address indexed from, address indexed to, uint value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint);
  function transferFrom(address from, address to, uint value) public;
  function approve(address spender, uint value) public;
  event Approval(address indexed owner, address indexed spender, uint value);
}

contract BasicToken is ERC20Basic {
  
  using SafeMath for uint;
  
  mapping(address => uint) balances;

  function transfer(address _to, uint _value) public{
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }

  function balanceOf(address _owner) public constant returns (uint balance) {
    return balances[_owner];
  }
}


contract StandardToken is BasicToken, ERC20 {
  mapping (address => mapping (address => uint)) allowed;

  function transferFrom(address _from, address _to, uint _value) public {
    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
  }

  function approve(address _spender, uint _value) public{
    require((_value == 0) || (allowed[msg.sender][_spender] == 0)) ;
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

  function allowance(address _owner, address _spender) public constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }
}


contract Ownable {
    address public owner;

    function Ownable() public{
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) onlyOwner public{
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}




contract CrowdsaleMain is Ownable{
    
    using SafeMath for uint;

    struct Backer {
    uint weiReceived; 
    uint coinSent;
  }

  /*
  * Constants
  */

  /**
    * ICO Phases.
    *
    * - PreStart:   tokens are not yet sold/issued
    * - MainIco     new tokens sold/issued at the regular price
    * - AfterIco:   tokens are not sold/issued
    */
    enum Phases {PreStart,  MainIco, AfterIco}

  /* Maximum number of TTC to main ico sell */
  uint public constant MAIN_MAX_CAP = 250000000000000000000000000; // 250,000,000 IEI

  /* Minimum amount to invest */
  uint public constant MIN_INVEST_ETHER = 100 finney;

  /* Number of IEI per Ether */
  uint public constant MAIN_COIN_PER_ETHER_ICO = 10000000000000000000000; // 10,000 IEI

  /*
  * Variables
  */

  /* Crowdsale period */
  
  uint private mainStartTime = 1;        // 2018-10-10 20:00 AM (UTC + 08:00)
  uint private mainEndTime = 984 hours;  // 2018-11-10 20:00 AM (UTC + 08:00)
  

  /* IEI contract reference */
  StandardToken public coin;

  /*Maximum Ether for one address during pre ico or main ico */
  uint public maximumCoinsPerAddress = 20 ether;
    
  /* Multisig contract that will receive the Ether during main ico*/
  address public mainMultisigEther;
  /* Number of Ether received during main ico */
  uint public mainEtherReceived;
  /* Number of TTC sent to Ether contributors during main ico */
  uint public mainCoinSentToEther;

  /* Backers Ether indexed by their Ethereum address */
  mapping(address => Backer) public mainBackers;
  address[] internal mainReadyToSendAddress;


    /* Current Phase */
    Phases public phase = Phases.PreStart;

  /*
  * Modifiers
  */

  modifier respectTimeFrame() {
    require((now >= mainStartTime) && (now < mainEndTime ));
    _;
  }

  /*
   * Event
  */
  event LogReceivedETH(address addr, uint value);
  event LogCoinsEmited(address indexed from, uint amount);

  /*
   * Constructor
  */
  function CrowdsaleMain() public{
      mainMultisigEther = owner;
  }

  /**
  * Allow to set IEI address
  */
  function setIEIAddress(address _addr) onlyOwner public {
    require(_addr != address(0));
    coin = StandardToken(_addr);
  }

  /**
  * change main start time by owner
  */
  function changeMainStartTime(uint _timestamp) onlyOwner public {

    mainStartTime = _timestamp;
  }

  /**
  * change main stop time by owner
  */
  function changeMainEndTime(uint _timestamp) onlyOwner public {
    mainEndTime = _timestamp;

  }

  /**
   * Allow to change the team multisig address in the case of emergency.
   */
  function setMultisigMain(address _addr) onlyOwner public {
    require(_addr != address(0));
    mainMultisigEther = _addr;
  }

  /**
  * Allow to change the maximum Coin one address can buy during the ico
  */
  function setMaximumCoinsPerAddress(uint _cnt) onlyOwner public{
    maximumCoinsPerAddress = _cnt;
  }

  /* 
   * The fallback function corresponds to a donation in ETH
   */
  function() respectTimeFrame  payable public{
    receiveETH(msg.sender);
  }

  /*
   *  Receives a donation in Ether
  */
  function receiveETH(address _beneficiary) internal {
    require(msg.value >= MIN_INVEST_ETHER) ; 
    adjustPhaseBasedOnTime();
    uint coinToSend ;

    if (phase == Phases.MainIco){
      Backer storage mainBacker = mainBackers[_beneficiary];
      require(mainBacker.weiReceived.add(msg.value) <= maximumCoinsPerAddress);

      coinToSend = msg.value.mul(MAIN_COIN_PER_ETHER_ICO).div(1 ether);   
      require(coinToSend.add(mainCoinSentToEther) <= MAIN_MAX_CAP) ;

      mainBacker.coinSent = mainBacker.coinSent.add(coinToSend);
      mainBacker.weiReceived = mainBacker.weiReceived.add(msg.value);   
      mainReadyToSendAddress.push(_beneficiary);

      // Update the total wei collected during the crowdfunding
      mainEtherReceived = mainEtherReceived.add(msg.value); 
      mainCoinSentToEther = mainCoinSentToEther.add(coinToSend);
      
      coin.transfer(_beneficiary, coinToSend);
      LogCoinsEmited(_beneficiary, coinToSend);

      // Send events
      LogReceivedETH(_beneficiary, mainEtherReceived); 
    }
  }

  /*
  * Adjust phase base on time
  */
    function adjustPhaseBasedOnTime() internal {

        if (now < mainStartTime ) {
            if (phase != Phases.PreStart) {
                phase = Phases.PreStart;
            }
        } else if (now >= mainStartTime && now < mainEndTime) {
            if (phase != Phases.MainIco) {
                phase = Phases.MainIco;
            }
        }else {
          if (phase != Phases.AfterIco){
            phase = Phases.AfterIco;
          }
        }
    }

  /*  
   * Finalize the crowdsale
  */
  function finalize() onlyOwner public {
    adjustPhaseBasedOnTime();
    require(phase == Phases.AfterIco);
    require(this.balance > 0);
    require(mainMultisigEther.send(this.balance)) ; 
    uint remains = coin.balanceOf(this);
    if (remains > 0) { 
      coin.transfer(owner,remains);
    }
  }

  /**
   * Transfer remains to owner in case if impossible to do min invest
   */
  function getMainRemainCoins() onlyOwner public {
    uint mainRemains = MAIN_MAX_CAP - mainCoinSentToEther;
    Backer storage backer = mainBackers[owner];
    coin.transfer(owner, mainRemains); 
    backer.coinSent = backer.coinSent.add(mainRemains);
    mainCoinSentToEther = mainCoinSentToEther.add(mainRemains);

    LogCoinsEmited(this ,mainRemains);
    LogReceivedETH(owner, mainEtherReceived); 
  }

 
}