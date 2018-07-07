pragma solidity ^0.4.24;

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

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    require(token.approve(spender, value));
  }
}

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

/**
 * @title TokenTimelock
 * @dev TokenTimelock is a token holder contract that will allow a
 * beneficiary to extract the tokens after a given release time
 */
contract TokenTimelock {
  using SafeERC20 for ERC20Basic;
  using SafeMath for uint256;

  // ERC20 basic token contract being held
  ERC20Basic public token;

  // beneficiary of tokens after they are released
  address public beneficiary_team;
  address public beneficiary_manage;
  address public beneficiary_finance;

  // releasedToken of each beneficiary
  mapping (address => uint256) releasedTokens;

  // timestamp when token release is enabled
  uint256 public releaseTime_start = 1530795600;
  uint256 public releaseTime_mid = 1530795900;
  uint256 public releaseTime_end =  1530796200;

  // initial count
  uint256 public count;
  constructor(
    ERC20Basic _token,
    address _beneficiary_team,
    address _beneficiary_manage,
    address _beneficiary_finance,
    uint256 _releaseTime_start,
    uint256 _releaseTime_mid,
    uint256 _releaseTime_end
  )
    public
  {
    // solium-disable-next-line security/no-block-members
    token = _token; 

    beneficiary_team = _beneficiary_team;
    beneficiary_manage = _beneficiary_manage;
    beneficiary_finance = _beneficiary_finance;

    releaseTime_start = _releaseTime_start;
    releaseTime_mid = _releaseTime_mid;
    releaseTime_end =  _releaseTime_end;

    count = 0;
  }

  /**
   * @notice Transfers tokens held by timelock to beneficiaries.
   */
  function releaseStart() public {
    // solium-disable-next-line security/no-block-members
    require(block.timestamp >= releaseTime_start);
    require(count == 0);

    uint256 amount = token.balanceOf(this);
    require(amount > 0);
    token.safeTransfer(beneficiary_team, 1*10**18);
    releasedTokens[beneficiary_team] = releasedTokens[beneficiary_team].add(1*10**18);
    token.safeTransfer(beneficiary_manage, 1*10**18);
    releasedTokens[beneficiary_manage] = releasedTokens[beneficiary_manage].add(1*10**18);
    token.safeTransfer(beneficiary_team, 1*10**18);
    releasedTokens[beneficiary_finance] = releasedTokens[beneficiary_finance].add(1*10**18);

    count = count.add(1);
  }

  function releaseMid() public {
    // solium-disable-next-line security/no-block-members
    require(block.timestamp >= releaseTime_mid);
    require(count == 1);

    uint256 amount = token.balanceOf(this);
    require(amount > 0);
    token.safeTransfer(beneficiary_team, 1*10**18);
    releasedTokens[beneficiary_team] = releasedTokens[beneficiary_team].add(1*10**18);
    token.safeTransfer(beneficiary_manage, 1*10**18);
    releasedTokens[beneficiary_manage] = releasedTokens[beneficiary_manage].add(1*10**18);
    token.safeTransfer(beneficiary_team, 1*10**18);
    releasedTokens[beneficiary_finance] = releasedTokens[beneficiary_finance].add(1*10**18);

    count = count.add(1);
  }

  function releaseEnd() public {
    // solium-disable-next-line security/no-block-members
    require(block.timestamp >= releaseTime_end);
    require(count == 2);

    uint256 amount = token.balanceOf(this);
    require(amount > 0);
    token.safeTransfer(beneficiary_team, 1*10**18);
    releasedTokens[beneficiary_team] = releasedTokens[beneficiary_team].add(1*10**18);
    token.safeTransfer(beneficiary_manage, 1*10**18);
    releasedTokens[beneficiary_manage] = releasedTokens[beneficiary_manage].add(1*10**18);
    token.safeTransfer(beneficiary_team, 1*10**18);
    releasedTokens[beneficiary_finance] = releasedTokens[beneficiary_finance].add(1*10**18);

    count = count.add(1);
  }
}