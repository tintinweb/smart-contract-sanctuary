pragma solidity ^0.4.13;

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract TradeProfile{
    using SafeMath for uint256;

    address public InvestContractAddress;
    address public owner;
    bool public isActive;
    uint256 public periodLength;
    uint256 public maxMarginDeposit;
    uint256 public minMarginDeposit;
    uint256 public rewardPercentage;
    mapping(address => uint256) investBalances;
    mapping(address => uint256) startTime;
    mapping(address => address) oracle;

    /**
    * @dev Gets the invest balance of the specified follower.
    * @param _follower address The follower to query the the invest balance of.
    * @return uint256 representing the amount invested by the passed follower.
    */
    function investBalanceOf(address _follower) public view returns (uint256) {
        return investBalances[_follower];
    }

    /**
    * @dev Gets the start time of the specified follower.
    * @param _follower address The follower to query the the start time of.
    * @return uint256 representing the start time of the follow trade.
    */
    function startTimeOf(address _follower) public view returns (uint256) {
        return startTime[_follower];
    }

    /**
    * @dev Gets the oracle of the specified follower.
    * @param _follower address The follower to query the the oracle of.
    * @return address representing the oracle of the follow trade.
    */
    function oracleOf(address _follower) public view returns (address) {
        return oracle[_follower];
    }

    /**
    * @dev Increase the invest balance of the specified follower.
    * @param _follower address The follower.
    * @param _amount uint256 The amount of margin to put into this follow trade.
    * @param _oracle address The oracle which has the authority to report the outcome of the follow trade.
    */
    function follow(address _follower, uint256 _amount, address _oracle) public returns (bool) {
        require(isActive);
        require(msg.sender == InvestContractAddress);

        investBalances[_follower] = investBalances[_follower].add(_amount);
        require(minMarginDeposit <= investBalances[_follower] && investBalances[_follower] <= maxMarginDeposit);

        if(startTime[_follower] == 0) {
            startTime[_follower] = now;
            oracle[_follower] = _oracle;
        }
    
        return true;
    }

    /**
    * @notice Clear a following trade
    * @param _follower address The follower of this trader.
    * @param _oracle address The oracle which has the authority to report the outcome of the follow trade.
    * @param _profitAmount int256 The profit made in this follow trade.
    */
    function clear(
        address _follower,
        address _oracle,
        int256 _profitAmount
    )
        public
        returns (uint256 amountToTrader, uint256 amountToFollower)
    {
        require(msg.sender == InvestContractAddress);
        require(_oracle == oracle[_follower]);

        uint256 balance = investBalances[_follower];

        delete investBalances[_follower];
        delete startTime[_follower];
        delete oracle[_follower];

        if(_profitAmount <= 0) {
            amountToTrader = 0;
        }
        else {
            amountToTrader = uint256(_profitAmount) * rewardPercentage / 100;
            if(amountToTrader > balance) {
                amountToTrader = balance;
            }
        }
        amountToFollower = balance - amountToTrader;
    }

    function close() public returns (bool) {
        require(isActive);
        require(msg.sender == InvestContractAddress);
        isActive = false;
        return true;
    }

    constructor(address _owner, uint256 _periodLength, uint256 _maxMarginDeposit, uint256 _minMarginDeposit, uint256 _rewardPercentage) public {
        InvestContractAddress = msg.sender;
        owner = _owner;
        periodLength = _periodLength;
        maxMarginDeposit = _maxMarginDeposit;
        minMarginDeposit = _minMarginDeposit;
        rewardPercentage = _rewardPercentage;
        isActive = true;
    }
}