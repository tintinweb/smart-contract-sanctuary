pragma solidity ^0.4.24;

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

// File: contracts/ParadigmStake.sol

contract Token is IERC20 {}

contract ParadigmStake {
    using SafeMath for uint;

    uint public totalStaked = 0;
    mapping(address => uint) stakedBalances;
    Token public digm;

    event StakeMade(address staker, uint amount);
    event StakeRemoved(address staker, uint amount);

    constructor(address _digm) public {
        digm = Token(_digm);
    }

    function stake(uint amount) public {
        require(digm.balanceOf(msg.sender) >= amount, "Insufficient balance");
        require(digm.allowance(msg.sender, this) >= amount, "Insufficient approval");

        require(digm.transferFrom(msg.sender, this, amount), "Transfer failed");

        stakedBalances[msg.sender] = stakedBalances[msg.sender].add(amount);
        totalStaked = totalStaked.add(amount);
        emit StakeMade(msg.sender, amount);
    }

    function stakeFromTokenContract(address staker, uint amount) public fromToken {
        stakedBalances[staker] = stakedBalances[staker].add(amount);
        totalStaked = totalStaked.add(amount);
        emit StakeMade(staker, amount);
    }

    function removeStake(uint amount) public {
        require(stakedBalances[msg.sender] >= amount, "Insufficient balance");

        require(digm.transfer(msg.sender, amount), "Transfer failed");

        stakedBalances[msg.sender] = stakedBalances[msg.sender].sub(amount);
        totalStaked = totalStaked.sub(amount);
        emit StakeRemoved(msg.sender, amount);
    }

    function stakeFor(address a) public view returns (uint) {
        return stakedBalances[a];
    }

    modifier fromToken() {
        require(msg.sender == address(digm));
        _;
    }
}