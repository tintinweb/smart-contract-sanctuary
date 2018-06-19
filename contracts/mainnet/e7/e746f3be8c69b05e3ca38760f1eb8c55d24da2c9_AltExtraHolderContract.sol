pragma solidity ^0.4.18;

contract TokenRecipient {
  function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; 
}

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

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

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

contract ExtraHolderContract is TokenRecipient {
  using SafeMath for uint;

  /// @notice Map of recipients parts of total received tokens
  /// @dev Should be in range of 1 to 10000 (1 is 0.01% and 10000 is 100%)
  mapping(address => uint) public shares;

  /// @notice Map of total values at moment of latest withdrawal per each recipient
  mapping(address => uint) public totalAtWithdrawal;

  /// @notice Address of the affilated token
  /// @dev Should be defined at construction and no way to change in future
  address public holdingToken;

  /// @notice Total amount of received token on smart-contract
  uint public totalReceived;

  /// @notice Construction method of Extra Holding contract
  /// @dev Arrays of recipients and their share parts should be equal and not empty
  /// @dev Sum of all shares should be exact equal to 10000
  /// @param _holdingToken is address of affilated contract
  /// @param _recipients is array of recipients
  /// @param _partions is array of recipients shares
  function ExtraHolderContract(
    address _holdingToken,
    address[] _recipients,
    uint[] _partions)
  public
  {
    require(_holdingToken != address(0x0));
    require(_recipients.length > 0);
    require(_recipients.length == _partions.length);

    uint ensureFullfield;

    for(uint index = 0; index < _recipients.length; index++) {
      // overflow check isn&#39;t required.. I suppose :D
      ensureFullfield = ensureFullfield + _partions[index];
      require(_partions[index] > 0);
      require(_recipients[index] != address(0x0));

      shares[_recipients[index]] = _partions[index];
    }

    holdingToken = _holdingToken;

    // Require to setup exact 100% sum of partions
    require(ensureFullfield == 10000);
  }

  /// @notice Method what should be called with external contract to receive tokens
  /// @dev Will be call automaticly with a customized transfer method of DefaultToken (based on DefaultToken.sol)
  /// @param _from is address of token sender
  /// @param _value is total amount of sending tokens
  /// @param _token is address of sending token
  /// @param _extraData ...
  function receiveApproval(
    address _from, 
    uint256 _value,
    address _token,
    bytes _extraData) public
  {
    _extraData;
    require(_token == holdingToken);

    // Take tokens of fail with exception
    ERC20(holdingToken).transferFrom(_from, address(this), _value);
    totalReceived = totalReceived.add(_value);
  }

  /// @notice Method to withdraw shared part of received tokens for providen address
  /// @dev Any address could fire method, but only for known recipient
  /// @param _recipient address of recipient who should receive withdrawed tokens
  function withdraw(
    address _recipient)
  public returns (bool) 
  {
    require(shares[_recipient] > 0);
    require(totalAtWithdrawal[_recipient] < totalReceived);

    uint left = totalReceived.sub(totalAtWithdrawal[_recipient]);
    uint share = left.mul(shares[_recipient]).div(10000);
    totalAtWithdrawal[_recipient] = totalReceived;
    ERC20(holdingToken).transfer(_recipient, share);
    return true;
  }
}

contract AltExtraHolderContract is ExtraHolderContract {
  address[] private altRecipients = [
    // Transfer two percent of all ALT tokens to bounty program participants on the day of tokens issue.
    // Final distribution will be done by our partner Bountyhive.io who will transfer coins from
    // the provided wallet to all bounty hunters community.
    address(0xd251D75064DacBC5FcCFca91Cb4721B163a159fc),
    // Transfer thirty eight percent of all ALT tokens for future Network Growth and Team and Advisors remunerations.
    address(0xAd089b3767cf58c7647Db2E8d9C049583bEA045A)
  ];
  uint[] private altPartions = [
    500,
    9500
  ];

  function AltExtraHolderContract(address _holdingToken)
    ExtraHolderContract(_holdingToken, altRecipients, altPartions)
    public
  {}
}