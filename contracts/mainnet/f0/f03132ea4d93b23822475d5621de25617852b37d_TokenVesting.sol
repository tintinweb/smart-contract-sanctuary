pragma solidity ^0.4.18;

// File: zeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
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

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

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
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: zeppelin-solidity/contracts/token/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: contracts/TokenVesting.sol

/**
 * @title Vesting contract for SDT
 * @dev see https://send.sd/token
 */
contract TokenVesting is Ownable {
  using SafeMath for uint256;

  address public ico;
  bool public initialized;
  bool public active;
  ERC20Basic public token;
  mapping (address => TokenGrant[]) public grants;

  uint256 public circulatingSupply = 0;

  struct TokenGrant {
    uint256 value;
    uint256 claimed;
    uint256 vesting;
    uint256 start;
  }

  event NewTokenGrant (
    address indexed to,
    uint256 value,
    uint256 start,
    uint256 vesting
  );

  event NewTokenClaim (
    address indexed holder,
    uint256 value
  );

  modifier icoResticted() {
    require(msg.sender == ico);
    _;
  }

  modifier isActive() {
    require(active);
    _;
  }

  function TokenVesting() public {
    active = false;
  }

  function init(address _token, address _ico) public onlyOwner {
    token = ERC20Basic(_token);
    ico = _ico;
    initialized = true;
    active = true;
  }

  function stop() public isActive onlyOwner {
    active = false;
  }

  function resume() public onlyOwner {
    require(!active);
    require(initialized);
    active = true;
  }

  /**
  * @dev Grant vested tokens.
  * @notice Only for ICO contract address.
  * @param _to Addres to grant tokens to.
  * @param _value Number of tokens granted.
  * @param _vesting Vesting finish timestamp.
  * @param _start Vesting start timestamp.
  */
  function grantVestedTokens(
      address _to,
      uint256 _value,
      uint256 _start,
      uint256 _vesting
  ) public icoResticted isActive {
    require(_value > 0);
    require(_vesting > _start);
    require(grants[_to].length < 10);

    TokenGrant memory grant = TokenGrant(_value, 0, _vesting, _start);
    grants[_to].push(grant);

    NewTokenGrant(_to, _value, _start, _vesting);
  }

  /**
  * @dev Claim all vested tokens up to current date for myself
  */
  function claimTokens() public {
    claim(msg.sender);
  }

  /**
  * @dev Claim all vested tokens up to current date in behaviour of an user
  * @param _to address Addres to claim tokens
  */
  function claimTokensFor(address _to) public onlyOwner {
    claim(_to);
  }

  /**
  * @dev Get claimable tokens
  */
  function claimableTokens() public constant returns (uint256) {
    address _to = msg.sender;
    uint256 numberOfGrants = grants[_to].length;

    if (numberOfGrants == 0) {
      return 0;
    }

    uint256 claimable = 0;
    uint256 claimableFor = 0;
    for (uint256 i = 0; i < numberOfGrants; i++) {
      claimableFor = calculateVestedTokens(
        grants[_to][i].value,
        grants[_to][i].vesting,
        grants[_to][i].start,
        grants[_to][i].claimed
      );
      claimable = claimable.add(claimableFor);
    }
    return claimable;
  }

  /**
  * @dev Get all veted tokens
  */
  function totalVestedTokens() public constant returns (uint256) {
    address _to = msg.sender;
    uint256 numberOfGrants = grants[_to].length;

    if (numberOfGrants == 0) {
      return 0;
    }

    uint256 claimable = 0;
    for (uint256 i = 0; i < numberOfGrants; i++) {
      claimable = claimable.add(
        grants[_to][i].value.sub(grants[_to][i].claimed)
      );
    }
    return claimable;
  }

  /**
  * @dev Calculate vested claimable tokens on current time
  * @param _tokens Number of tokens granted
  * @param _vesting Vesting finish timestamp
  * @param _start Vesting start timestamp
  * @param _claimed Number of tokens already claimed
  */
  function calculateVestedTokens(
      uint256 _tokens,
      uint256 _vesting,
      uint256 _start,
      uint256 _claimed
  ) internal constant returns (uint256) {
    uint256 time = block.timestamp;

    if (time < _start) {
      return 0;
    }

    if (time >= _vesting) {
      return _tokens.sub(_claimed);
    }

    uint256 vestedTokens = _tokens.mul(time.sub(_start)).div(
      _vesting.sub(_start)
    );

    return vestedTokens.sub(_claimed);
  }

  /**
  * @dev Claim all vested tokens up to current date
  */
  function claim(address _to) internal {
    uint256 numberOfGrants = grants[_to].length;

    if (numberOfGrants == 0) {
      return;
    }

    uint256 claimable = 0;
    uint256 claimableFor = 0;
    for (uint256 i = 0; i < numberOfGrants; i++) {
      claimableFor = calculateVestedTokens(
        grants[_to][i].value,
        grants[_to][i].vesting,
        grants[_to][i].start,
        grants[_to][i].claimed
      );
      claimable = claimable.add(claimableFor);
      grants[_to][i].claimed = grants[_to][i].claimed.add(claimableFor);
    }

    token.transfer(_to, claimable);
    circulatingSupply += claimable;

    NewTokenClaim(_to, claimable);
  }
}