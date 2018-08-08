pragma solidity 0.4.24;

interface IMintableToken {
    function mint(address _to, uint256 _amount) public returns (bool);
}

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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract Pausable is Ownable {
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
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

contract preICO is Ownable, Pausable {
    event Approved(address _address, uint _tokensAmount);
    event Declined(address _address, uint _tokensAmount);
    event weiReceived(address _address, uint _weiAmount);
    event RateChanged(uint _newRate);

    uint public constant startTime = 1529431200; // June, 19. 07:00 PM (UTC)
    uint public endTime = 1532973600; // July, 30. 07:00 PM (UTC)
    uint public rate;
    uint public tokensHardCap = 10000000 * 1 ether; // 10 million tokens

    uint public tokensMintedDuringPreICO = 0;
    uint public tokensToMintInHold = 0;

    mapping(address=>uint) public tokensHoldMap;

    IMintableToken public DXC;

    function preICO(address _DXC) {
        DXC = IMintableToken(_DXC);
    }

    /**
    * @dev Handles incoming eth transfers
    * and mints tokens to msg.sender
    */
    function () payable ongoingPreICO whenNotPaused {
        uint tokensToMint = msg.value * rate;
        tokensHoldMap[msg.sender] = SafeMath.add(tokensHoldMap[msg.sender], tokensToMint);
        tokensToMintInHold = SafeMath.add(tokensToMintInHold, tokensToMint);
        weiReceived(msg.sender, msg.value);
    }

    /**
    * @dev Approves token minting for specified investor
    * @param _address Address of investor in `holdMap`
    */
    function approve(address _address) public onlyOwner capWasNotReached(_address) {
        uint tokensAmount = tokensHoldMap[_address];
        tokensHoldMap[_address] = 0;
        tokensMintedDuringPreICO = SafeMath.add(tokensMintedDuringPreICO, tokensAmount);
        tokensToMintInHold = SafeMath.sub(tokensToMintInHold, tokensAmount);
        Approved(_address, tokensAmount);

        DXC.mint(_address, tokensAmount);
    }

    /**
    * @dev Declines token minting for specified investor
    * @param _address Address of investor in `holdMap`
    */
    function decline(address _address) public onlyOwner {
        tokensToMintInHold = SafeMath.sub(tokensToMintInHold, tokensHoldMap[_address]);
        Declined(_address, tokensHoldMap[_address]);

        tokensHoldMap[_address] = 0;
    }

    /**
    * @dev Sets rate if it was not set earlier
    * @param _rate preICO wei to tokens rate
    */
    function setRate(uint _rate) public onlyOwner {
        rate = _rate;

        RateChanged(_rate);
    }

    /**
    * @dev Transfer specified amount of wei the owner
    * @param _weiToWithdraw Amount of wei to transfer
    */
    function withdraw(uint _weiToWithdraw) public onlyOwner {
        msg.sender.transfer(_weiToWithdraw);
    }

    /**
    * @dev Increases end time by specified amount of seconds
    * @param _secondsToIncrease Amount of second to increase end time
    */
    function increaseDuration(uint _secondsToIncrease) public onlyOwner {
        endTime = SafeMath.add(endTime, _secondsToIncrease);
    }

    /**
    * @dev Throws if crowdsale time is not started or finished
    */
    modifier ongoingPreICO {
        require(now >= startTime && now <= endTime);
        _;
    }

    /**
    * @dev Throws if preICO hard cap will be exceeded after minting
    */
    modifier capWasNotReached(address _address) {
        require(SafeMath.add(tokensMintedDuringPreICO, tokensHoldMap[_address]) <= tokensHardCap);
        _;
    }
}