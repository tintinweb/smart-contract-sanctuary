pragma solidity ^0.4.16;



/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}



/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}



/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) returns (bool) {
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
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) returns (bool) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
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
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev modifier to allow actions only when the contract IS paused
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev modifier to allow actions only when the contract IS NOT paused
   */
  modifier whenPaused {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused returns (bool) {
    paused = true;
    Pause();
    return true;
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused returns (bool) {
    paused = false;
    Unpause();
    return true;
  }
}


contract Hgt is StandardToken, Pausable {

    string public name = "HelloGold Token";
    string public symbol = "HGT";
    uint256 public decimals = 18;

}

contract Hgs {
    struct CsAction {
      bool        passedKYC;
      bool        blocked;
    }


    /* This creates an array with all balances */
    mapping (address => CsAction) public permissions;
    mapping (address => uint256)  public deposits;
}

contract HelloGoldRound1Point5 is Ownable {

    using SafeMath for uint256;
    bool    public  started;
    uint256 public  startTime = 1505995200; // September 21, 2017 8:00:00 PM GMT+08:00
    uint256 public  endTime = 1507204800;  // October 5, 2017 8:00:00 PM GMT+08:00
    uint256 public  weiRaised;
    uint256 public  lastSaleInHGT = 170000000 * 10 ** 8 ;
    uint256 public  hgtSold;
    uint256 public  r15Backers;

    uint256 public  rate = 12489 * 10 ** 8;
    Hgs     public  hgs = Hgs(0x574FB6d9d090042A04D0D12a4E87217f8303A5ca);
    Hgt     public  hgt = Hgt(0xba2184520A1cC49a6159c57e61E1844E085615B6);
    address public  multisig = 0xC03281aF336e2C25B41FF893A0e6cE1a932B23AF; // who gets the ether
    address public  reserves = 0xC03281aF336e2C25B41FF893A0e6cE1a932B23AF; // who has the HGT pool

//////   //    /////     BIG BLOODY REMINDER   The code below is for testing purposes
//   //  //   //   //    BIG BLOODY REMINDER   If you are not the developer of this code
/////    //   //         BIG BLOODY REMINDER   And you can see this, SHOUT coz it should 
//  ///  //   //  ///    BIG BLOODY REMINDER   Not be here in production and all hell will
//  ///  //   //   //    BIG BLOODY REMINDER   Break loose, the gates of hell will open and
//////   //    //////    BIG BLOODY REMINDER   Winged monstors and daemons will roam free  

    // bool testing = true;

    // function testingOnly() {
    //     if (!testing)
    //         return;
    //     hgs = Hgs(0x5aB936795ECEeF9D34198d3AAEe1bA32b8f34B6b);
    //     hgt = Hgt(0x38738A39d1EbdA813237C34122677a5925454ec8);
    //     multisig = 0x3D1F6Cd19d58767E3680c4D60D0b3355331F7b46;
    //     reserves = 0x1bdc4085d0222F459B92fa23FfA570f493e6E763;
    // }


//////   //    /////     BIG BLOODY REMINDER   The code above is for testing purposes
//   //  //   //   //    BIG BLOODY REMINDER   If you are not the developer of this code
/////    //   //         BIG BLOODY REMINDER   And you can see this, SHOUT coz it should 
//  ///  //   //  ///    BIG BLOODY REMINDER   Not be here in production and all hell will
//  ///  //   //   //    BIG BLOODY REMINDER   Break loose, the gates of hell will open and
//////   //    //////    BIG BLOODY REMINDER   Winged monstors and daemons will roam free  




    mapping (address => uint256) public deposits;
    mapping (address => bool) public upgraded;
    mapping (address => uint256) public upgradeHGT;

    modifier validPurchase() {
        bool passedKYC;
        bool blocked;
        require (msg.value >= 1 finney);
        require (started || (now > startTime));
        require (now <= endTime);
        require (hgtSold < lastSaleInHGT);
        (passedKYC,blocked) = hgs.permissions(msg.sender); 
        require (passedKYC);
        require (!blocked);


        _;
    }

 
    function HelloGoldRound1Point5() {
        // handle the guy who had three proxy accounts
        deposits[0xA3f59EbC3bf8Fa664Ce12e2f841Fe6556289F053] = 30 ether; // so sum balance = 40 ether
        upgraded[0xA3f59EbC3bf8Fa664Ce12e2f841Fe6556289F053] = true;
        upgraded[0x00f07DA332aa7751F9170430F6e4b354568c5B40] = true;
        upgraded[0x938CdFb9B756A5b6c8f3fBA535EC17700edD4c15] = true;
        upgraded[0xa6a777ed720746FBE7b6b908584CD3D533d307D3] = true;

        // testingOnly(); // removing this allows me to keep the BIG COMMENTS to see if Robin ever hears about it :-p
    }

    function reCap(uint256 newCap) onlyOwner {
        lastSaleInHGT = newCap;
    }

    function startAndSetStopTime(uint256 period) onlyOwner {
        started = true;
        if (period == 0)
            endTime = now + 2 weeks;
        else
            endTime = now + period;
    }

    // Need to check cases
    //  1   already upgraded
    //  2   first deposit (no R1)
    //  3   R1 < 10, first R1.5 takes over 10 ether
    //  4   R1 <= 10, second R1.5 takes over 10 ether
    function upgradeOnePointZeroBalances() internal {
    // 1
        if (upgraded[msg.sender]) {
            log0("account already upgraded");
            return;
        }
    // 2
        uint256 deposited = hgs.deposits(msg.sender);
        if (deposited == 0)
            return;
    // 3
        deposited = deposited.add(deposits[msg.sender]);
        if (deposited.add(msg.value) < 10 ether)
            return;
    // 4
        uint256 hgtBalance = hgt.balanceOf(msg.sender);
        uint256 upgradedAmount = deposited.mul(rate).div(1 ether);
        if (hgtBalance < upgradedAmount) {
            uint256 diff = upgradedAmount.sub(hgtBalance);
            hgt.transferFrom(reserves,msg.sender,diff);
            hgtSold = hgtSold.add(diff);
            upgradeHGT[msg.sender] = upgradeHGT[msg.sender].add(diff);
            log0("upgraded R1 to 20%");
        }
        upgraded[msg.sender] = true;
    }

    function () payable validPurchase {
        if (deposits[msg.sender] == 0)
            r15Backers++;
        upgradeOnePointZeroBalances();
        deposits[msg.sender] = deposits[msg.sender].add(msg.value);
        
        buyTokens(msg.sender,msg.value);
    }

    function buyTokens(address recipient, uint256 valueInWei) internal {
        uint256 numberOfTokens = valueInWei.mul(rate).div(1 ether);
        weiRaised = weiRaised.add(valueInWei);
        require(hgt.transferFrom(reserves,recipient,numberOfTokens));
        hgtSold = hgtSold.add(numberOfTokens);
        multisig.transfer(msg.value);
    }

    function emergencyERC20Drain( ERC20 token, uint amount ) onlyOwner {
        token.transfer(owner, amount);
    }

}