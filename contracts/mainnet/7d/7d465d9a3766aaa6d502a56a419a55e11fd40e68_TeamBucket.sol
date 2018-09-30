pragma solidity ^0.4.25;

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

/// @title Role based access control mixin for Rasmart Platform
/// @author Abha Mai <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="fe939f979f9c969fc6ccbe99939f9792d09d9193">[email&#160;protected]</a>>
/// @dev Ignore DRY approach to achieve readability
contract RBACMixin {
  /// @notice Constant string message to throw on lack of access
  string constant FORBIDDEN = "Haven&#39;t enough right to access";
  /// @notice Public map of owners
  mapping (address => bool) public owners;
  /// @notice Public map of minters
  mapping (address => bool) public minters;

  /// @notice The event indicates the addition of a new owner
  /// @param who is address of added owner
  event AddOwner(address indexed who);
  /// @notice The event indicates the deletion of an owner
  /// @param who is address of deleted owner
  event DeleteOwner(address indexed who);

  /// @notice The event indicates the addition of a new minter
  /// @param who is address of added minter
  event AddMinter(address indexed who);
  /// @notice The event indicates the deletion of a minter
  /// @param who is address of deleted minter
  event DeleteMinter(address indexed who);

  constructor () public {
    _setOwner(msg.sender, true);
  }

  /// @notice The functional modifier rejects the interaction of senders who are not owners
  modifier onlyOwner() {
    require(isOwner(msg.sender), FORBIDDEN);
    _;
  }

  /// @notice Functional modifier for rejecting the interaction of senders that are not minters
  modifier onlyMinter() {
    require(isMinter(msg.sender), FORBIDDEN);
    _;
  }

  /// @notice Look up for the owner role on providen address
  /// @param _who is address to look up
  /// @return A boolean of owner role
  function isOwner(address _who) public view returns (bool) {
    return owners[_who];
  }

  /// @notice Look up for the minter role on providen address
  /// @param _who is address to look up
  /// @return A boolean of minter role
  function isMinter(address _who) public view returns (bool) {
    return minters[_who];
  }

  /// @notice Adds the owner role to provided address
  /// @dev Requires owner role to interact
  /// @param _who is address to add role
  /// @return A boolean that indicates if the operation was successful.
  function addOwner(address _who) public onlyOwner returns (bool) {
    _setOwner(_who, true);
  }

  /// @notice Deletes the owner role to provided address
  /// @dev Requires owner role to interact
  /// @param _who is address to delete role
  /// @return A boolean that indicates if the operation was successful.
  function deleteOwner(address _who) public onlyOwner returns (bool) {
    _setOwner(_who, false);
  }

  /// @notice Adds the minter role to provided address
  /// @dev Requires owner role to interact
  /// @param _who is address to add role
  /// @return A boolean that indicates if the operation was successful.
  function addMinter(address _who) public onlyOwner returns (bool) {
    _setMinter(_who, true);
  }

  /// @notice Deletes the minter role to provided address
  /// @dev Requires owner role to interact
  /// @param _who is address to delete role
  /// @return A boolean that indicates if the operation was successful.
  function deleteMinter(address _who) public onlyOwner returns (bool) {
    _setMinter(_who, false);
  }

  /// @notice Changes the owner role to provided address
  /// @param _who is address to change role
  /// @param _flag is next role status after success
  /// @return A boolean that indicates if the operation was successful.
  function _setOwner(address _who, bool _flag) private returns (bool) {
    require(owners[_who] != _flag);
    owners[_who] = _flag;
    if (_flag) {
      emit AddOwner(_who);
    } else {
      emit DeleteOwner(_who);
    }
    return true;
  }

  /// @notice Changes the minter role to provided address
  /// @param _who is address to change role
  /// @param _flag is next role status after success
  /// @return A boolean that indicates if the operation was successful.
  function _setMinter(address _who, bool _flag) private returns (bool) {
    require(minters[_who] != _flag);
    minters[_who] = _flag;
    if (_flag) {
      emit AddMinter(_who);
    } else {
      emit DeleteMinter(_who);
    }
    return true;
  }
}

interface IMintableToken {
  function mint(address _to, uint256 _amount) external returns (bool);
}


/// @title Very simplified implementation of Token Bucket Algorithm to secure token minting
/// @author Abha Mai <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="e489858d85868c85dcd6a48389858d88ca878b89">[email&#160;protected]</a>>
/// @notice Works with tokens implemented Mintable interface
/// @dev Transfer ownership/minting role to contract and execute mint over TeamBucket proxy to secure
contract TeamBucket is RBACMixin, IMintableToken {
  using SafeMath for uint;

  /// @notice Limit maximum amount of available for minting tokens when bucket is full
  /// @dev Should be enough to mint tokens with proper speed but less enough to prevent overminting in case of losing pkey
  uint256 public size;
  /// @notice Bucket refill rate
  /// @dev Tokens per second (based on block.timestamp). Amount without decimals (in smallest part of token)
  uint256 public rate;
  /// @notice Stored time of latest minting
  /// @dev Each successful call of minting function will update field with call timestamp
  uint256 public lastMintTime;
  /// @notice Left tokens in bucket on time of latest minting
  uint256 public leftOnLastMint;

  /// @notice Reference of Mintable token
  /// @dev Setup in contructor phase and never change in future
  IMintableToken public token;

  /// @notice Token Bucket leak event fires on each minting
  /// @param to is address of target tokens holder
  /// @param left is amount of tokens available in bucket after leak
  event Leak(address indexed to, uint256 left);

  /// @param _token is address of Mintable token
  /// @param _size initial size of token bucket
  /// @param _rate initial refill rate (tokens/sec)
  constructor (address _token, uint256 _size, uint256 _rate) public {
    token = IMintableToken(_token);
    size = _size;
    rate = _rate;
    leftOnLastMint = _size;
  }

  /// @notice Change size of bucket
  /// @dev Require owner role to call
  /// @param _size is new size of bucket
  /// @return A boolean that indicates if the operation was successful.
  function setSize(uint256 _size) public onlyOwner returns (bool) {
    size = _size;
    return true;
  }

  /// @notice Change refill rate of bucket
  /// @dev Require owner role to call
  /// @param _rate is new refill rate of bucket
  /// @return A boolean that indicates if the operation was successful.
  function setRate(uint256 _rate) public onlyOwner returns (bool) {
    rate = _rate;
    return true;
  }

  /// @notice Change size and refill rate of bucket
  /// @dev Require owner role to call
  /// @param _size is new size of bucket
  /// @param _rate is new refill rate of bucket
  /// @return A boolean that indicates if the operation was successful.
  function setSizeAndRate(uint256 _size, uint256 _rate) public onlyOwner returns (bool) {
    return setSize(_size) && setRate(_rate);
  }

  /// @notice Function to mint tokens
  /// @param _to The address that will receive the minted tokens.
  /// @param _amount The amount of tokens to mint.
  /// @return A boolean that indicates if the operation was successful.
  function mint(address _to, uint256 _amount) public onlyMinter returns (bool) {
    uint256 available = availableTokens();
    require(_amount <= available);
    leftOnLastMint = available.sub(_amount);
    lastMintTime = now; // solium-disable-line security/no-block-members
    require(token.mint(_to, _amount));
    return true;
  }

  /// @notice Function to calculate and get available in bucket tokens
  /// @return An amount of available tokens in bucket
  function availableTokens() public view returns (uint) {
     // solium-disable-next-line security/no-block-members
    uint256 timeAfterMint = now.sub(lastMintTime);
    uint256 refillAmount = rate.mul(timeAfterMint).add(leftOnLastMint);
    return size < refillAmount ? size : refillAmount;
  }
}