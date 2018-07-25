pragma solidity ^0.4.24;

// File: contracts/simple-version/InterfaceErc1202.sol

/**
 * - Single issue
 * - Single selection
 *
 * Discussion:
 *   1. Each address has a weight determined by other input decided by the actual implementation
 *      which is suggested to be set upon the initialization
 *   2. Is there certain naming convention to follow?
 */
interface InterfaceErc1202 {

    // Vote with an option. The caller needs to handle success or not
    function vote(uint option) external returns (bool success);
    function setStatus(bool isOpen) external returns (bool success);

    function ballotOf(address addr) external view returns (uint option);
    function weightOf(address addr) external view returns (uint weight);

    function getStatus() external view returns (bool isOpen);

    function weightedVoteCountsOf(uint option) external view returns (uint count);
    function winningOption() external view returns (uint option);

    event OnVote(address indexed _from, uint _value);
    event OnStatusChange(bool newIsOpen);
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: openzeppelin-solidity/contracts/token/ERC20/BasicToken.sol

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

// File: contracts/simple-version/TokenVote1202.sol

/**
  A simplest (frozen) token vote interface.
  (1) single issue
  (2) only TRUE or FALSE
  (3) no voting time limit, and ok to change vote
  (4) each address has a weight equal to the Token held by given address at the time of token construction.
  It makes assumption that during the time of voting, the holding state of the token contract, i.e. the balanceOf
  is being frozen.
 */
contract TokenVote1202 is InterfaceErc1202 {
    uint[] internal options;
    bool internal isOpen;
    mapping (address => uint256) internal weights;
    mapping (uint => uint256) internal weightedVoteCounts;
    mapping (address => uint) internal  ballots;

    /**
        tokenContract: address to a smart contract of the OpenZeppelin BasicToken or
                       any ERC-basic token supporting accessing to balances
     */
    constructor(
        address _tokenAddr, uint[] _options,
        address[] qualifiedVoters) public {
        require(_options.length >= 2);
        options = _options;
        BasicToken token = BasicToken(_tokenAddr);

        // We realize the ERC20 will need to be extended to support snapshoting the weights/balances.
        for (uint i = 0; i < qualifiedVoters.length; i++) {
            address voter = qualifiedVoters[i];
            // weights[voter] = token.balanceOf(voter);
        }
    }

    /* Send coins */
    function vote(uint option) external returns (bool success) {
        require(isOpen);
        // TODO check if option is valid

        uint256 weight = weights[msg.sender];
        weightedVoteCounts[option] += weight;  // initial value is zero
        ballots[msg.sender] = option;
        emit OnVote(msg.sender, option);
        return true;
    }

    function setStatus(bool isOpen_) external returns (bool success) {
        isOpen = isOpen_;
        emit OnStatusChange(isOpen_);
        return true;
    }

    function ballotOf(address addr) external view returns (uint option) {
        return ballots[addr];
    }

    function weightOf(address addr) external view returns (uint weight) {
        return weights[addr];
    }

    function getStatus() external view returns (bool isOpen_) {
        return isOpen;
    }

    function weightedVoteCountsOf(uint option) external view returns (uint count) {
        return weightedVoteCounts[option];
    }

    function winningOption() external view returns (uint option) {
        uint currentWiningOptionIndex = 0;
        for (uint i = 1; i <= options.length; i++) {
            if (weightedVoteCounts[options[i]] >= weightedVoteCounts[options[currentWiningOptionIndex]]) {
                currentWiningOptionIndex = i;
            }
        }
        return options[currentWiningOptionIndex];
    }

    event OnVote(address indexed _from, uint _value);
    event OnStatusChange(bool newIsOpen);

}