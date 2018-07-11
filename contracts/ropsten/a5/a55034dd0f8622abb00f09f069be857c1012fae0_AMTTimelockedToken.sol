pragma solidity ^0.4.24;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of &quot;user permissions&quot;.
 */
contract Ownable {
  address public owner;

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
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

contract AMTTimelockedToken is Ownable {
  using SafeERC20 for ERC20Basic;
  using SafeMath for uint256;

  uint8 public constant decimals = 18; // solium-disable-line uppercase

  // ERC20 basic token contract being held
  ERC20Basic token;

  // totalTokenAmounts of each beneficiary
  uint256 public constant MANAGE_CAP = 1 * (10 ** 8) * (10 ** uint256(decimals));
  uint256 public constant DEVELOP_CAP = 2 * (10 ** 8) * (10 ** uint256(decimals));
  uint256 public constant MARKET_CAP = 1 * (10 ** 8) * (10 ** uint256(decimals));
  uint256 public constant FINANCE_CAP = 6 * (10 ** 7) * (10 ** uint256(decimals));

  // perRoundTokenAmounts of each beneficiary
  uint256 public constant MANAGE_CAP_PER_ROUND = 2 * (10 ** 7) * (10 ** uint256(decimals));
  uint256 public constant DEVELOP_CAP_PER_ROUND = 4 * (10 ** 7) * (10 ** uint256(decimals));
  uint256 public constant MARKET_CAP_PER_ROUND = 2 * (10 ** 7) * (10 ** uint256(decimals));
  uint256 public constant FINANCE_CAP_PER_ROUND = 12 * (10 ** 6) * (10 ** uint256(decimals));

  // releasedToken of each beneficiary
  mapping (address => uint256) releasedTokens;

  // beneficiaries of tokens after they are released
  address beneficiary_manage;
  address beneficiary_develop;
  address beneficiary_market;
  address beneficiary_finance;

  // timestamps when token release is enabled
  uint256 release_time_first_round;
  uint256 release_time_second_round;
  uint256 release_time_third_round;
  uint256 release_time_forth_round;
  uint256 release_time_fifth_round;

  /**
   * @dev Constructor that gives msg.sender all of existing tokens.
   */
  constructor(
    ERC20Basic _token,
    address _beneficiary_manage,
    address _beneficiary_develop,
    address _beneficiary_market,
    address _beneficiary_finance,
    uint256 _release_time_first_round,
    uint256 _release_time_second_round,
    uint256 _release_time_third_round,
    uint256 _release_time_forth_round,
    uint256 _release_time_fifth_round
  ) public {
    token = _token;
    beneficiary_manage = _beneficiary_manage;
    beneficiary_develop = _beneficiary_develop;
    beneficiary_market = _beneficiary_market;
    beneficiary_finance = _beneficiary_finance;

    release_time_first_round = _release_time_first_round;
    release_time_second_round = _release_time_second_round;
    release_time_third_round = _release_time_third_round;
    release_time_forth_round = _release_time_forth_round;
    release_time_fifth_round = _release_time_fifth_round;

  }

  function getTokenContract() public view returns (ERC20Basic) {
    return token;
  }

  function getBeneficiaryManage() public view returns (address) {
    return beneficiary_manage;
  }

  function getBeneficiaryDevelop() public view returns (address) {
    return beneficiary_develop;
  }

  function getBeneficiaryMarket() public view returns (address) {
    return beneficiary_market;
  }

  function getBeneficiaryFinance() public view returns (address) {
    return beneficiary_finance;
  }

  function getFirstRoundReleaseTime() public view returns (uint256) {
    return release_time_first_round;
  }

  function getSecondRoundReleaseTime() public view returns (uint256) {
    return release_time_second_round;
  }

  function getThirdRoundReleaseTime() public view returns (uint256) {
    return release_time_third_round;
  }

  function getForthRoundReleaseTime() public view returns (uint256) {
    return release_time_forth_round;
  }

  function getFifthRoundReleaseTime() public view returns (uint256) {
    return release_time_fifth_round;
  }
  
  /**
  * @dev Gets the releasedToken of the specified address.
  * @param _owner The address to query the the releasedToken of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function releasedTokenOf(address _owner) public view returns (uint256) {
    return releasedTokens[_owner];
  }

  function validReleasedToken(uint256 _round) internal onlyOwner {

    uint256 tmpbfm = releasedTokens[beneficiary_manage];
    uint256 tmpbfd = releasedTokens[beneficiary_develop];
    uint256 tmpbfma = releasedTokens[beneficiary_market];
    uint256 tmpbff = releasedTokens[beneficiary_finance];

    require(tmpbfm < MANAGE_CAP_PER_ROUND.mul(_round));
    require(tmpbfm.add(MANAGE_CAP_PER_ROUND) <= MANAGE_CAP_PER_ROUND.mul(_round));

    require(tmpbfd < DEVELOP_CAP_PER_ROUND.mul(_round));
    require(tmpbfd.add(DEVELOP_CAP_PER_ROUND) <= DEVELOP_CAP_PER_ROUND.mul(_round));

    require(tmpbfma < MANAGE_CAP_PER_ROUND.mul(_round));
    require(tmpbfma.add(MARKET_CAP_PER_ROUND) <= MARKET_CAP_PER_ROUND.mul(_round));

    require(tmpbff < FINANCE_CAP_PER_ROUND.mul(_round));
    require(tmpbff.add(FINANCE_CAP_PER_ROUND) <= FINANCE_CAP_PER_ROUND.mul(_round));

    uint256 totalRoundCap = MANAGE_CAP_PER_ROUND.add(DEVELOP_CAP_PER_ROUND).add(MARKET_CAP_PER_ROUND).add(FINANCE_CAP_PER_ROUND);
    require(token.balanceOf(this) >= totalRoundCap);

    token.safeTransfer(beneficiary_manage, MANAGE_CAP_PER_ROUND);
    releasedTokens[beneficiary_manage] = releasedTokens[beneficiary_manage].add(MANAGE_CAP_PER_ROUND);

    token.safeTransfer(beneficiary_develop, DEVELOP_CAP_PER_ROUND);
    releasedTokens[beneficiary_develop] = releasedTokens[beneficiary_develop].add(DEVELOP_CAP_PER_ROUND);

    token.safeTransfer(beneficiary_market, MARKET_CAP_PER_ROUND);
    releasedTokens[beneficiary_market] = releasedTokens[beneficiary_market].add(MARKET_CAP_PER_ROUND);

    token.safeTransfer(beneficiary_finance, FINANCE_CAP_PER_ROUND);
    releasedTokens[beneficiary_finance] = releasedTokens[beneficiary_finance].add(FINANCE_CAP_PER_ROUND);
  }

  /**
   * @notice Transfers tokens held by timelock to beneficiaries.
   */
  function releaseToken() public onlyOwner {

    if (block.timestamp >= release_time_fifth_round) {

      validReleasedToken(5);
      return;

    }else if (block.timestamp >= release_time_forth_round) {

      validReleasedToken(4);
      return;

    }else if (block.timestamp >= release_time_third_round) {

      validReleasedToken(3);
      return;

    }else if (block.timestamp >= release_time_second_round) {

      validReleasedToken(2);
      return;

    }else if (block.timestamp >= release_time_first_round) {

      validReleasedToken(1);
      return;

    }

  }
}