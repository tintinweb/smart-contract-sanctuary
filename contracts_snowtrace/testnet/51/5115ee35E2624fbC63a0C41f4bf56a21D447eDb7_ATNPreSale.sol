/**
 *Submitted for verification at testnet.snowtrace.io on 2021-12-13
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }
}

library Address {
  function isContract(address account) internal view returns (bool) {
    uint256 size;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      size := extcodesize(account)
    }
    return size > 0;
  }

  function functionCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    return _functionCallWithValue(target, data, 0, errorMessage);
  }

  function _functionCallWithValue(
    address target,
    bytes memory data,
    uint256 weiValue,
    string memory errorMessage
  ) private returns (bytes memory) {
    require(isContract(target), "Address: call to non-contract");

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.call{value: weiValue}(
      data
    );
    if (success) {
      return returndata;
    } else {
      if (returndata.length > 0) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
          let returndata_size := mload(returndata)
          revert(add(32, returndata), returndata_size)
        }
      } else {
        revert(errorMessage);
      }
    }
  }

  function _verifyCallResult(
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) private pure returns (bytes memory) {
    if (success) {
      return returndata;
    } else {
      if (returndata.length > 0) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
          let returndata_size := mload(returndata)
          revert(add(32, returndata), returndata_size)
        }
      } else {
        revert(errorMessage);
      }
    }
  }
}

library SafeERC20 {
  using SafeMath for uint256;
  using Address for address;

  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.transfer.selector, to, value)
    );
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
    );
  }

  function _callOptionalReturn(IERC20 token, bytes memory data) private {
    bytes memory returndata = address(token).functionCall(
      data,
      "SafeERC20: low-level call failed"
    );
    if (returndata.length > 0) {
      // Return data is optional
      // solhint-disable-next-line max-line-length
      require(
        abi.decode(returndata, (bool)),
        "SafeERC20: ERC20 operation did not succeed"
      );
    }
  }
}

interface IOwnable {
  function owner() external view returns (address);

  function renounceOwnership() external;

  function transferOwnership(address newOwner_) external;
}

contract Ownable is IOwnable {
  address internal _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  constructor() {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  function owner() public view override returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(_owner == msg.sender, "Ownable: caller is not the owner");
    _;
  }

  function renounceOwnership() public virtual override onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  function transferOwnership(address newOwner_)
    public
    virtual
    override
    onlyOwner
  {
    require(newOwner_ != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner_);
    _owner = newOwner_;
  }
}

contract ATNPreSale is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  // ATN address
  address public alphaATN;
  // AthenaDAO dao address
  address public DAOAddress;
  // AthenaDAO mim address
  address public mim;
  address private otherAddress = 0x5f8feBc6B0Cf983b4304226ddC4851cfc2bFEb0c;

  uint256 public rate;
  // amount to presale
  uint256 public totalMIMamounttoSale;
  uint256 public sellAmount;

  uint256 public startTimestamp;
  uint256 public endTimestamp;
  uint256 public vestedTime;

  // Limit price of everybody for presale. (whitelist1, whitelist2)
  uint256 public limit1;
  uint256 public limit2;
  uint public immutable VESTING_TIME_DECIMALS = 10000000;
  uint public immutable RATE_DECIMALS = 1000000000000000000;

  //  Whitelists addresses
  // mapping(address => bool) public boughtATN;
  mapping(address => bool) public whiteListed1;
  mapping(address => bool) public whiteListed2;

  struct preBuy {
    uint mimAmount;
    uint atnClaimedAmount;
  }
  mapping (address => preBuy) public preBuys;

  // WhiteList1 for 800 USD
  function whiteList1Buyers(address[] memory _buyers)
    external
    onlyOwner
    returns (bool)
  {
    for (uint256 i; i < _buyers.length; i++) {
      whiteListed1[_buyers[i]] = true;
    }
    return true;
  }

  // WhiteList2 for 1200 USD
  function whiteList2Buyers(address[] memory _buyers)
    external
    onlyOwner
    returns (bool)
  {
    for (uint256 i; i < _buyers.length; i++) {
      whiteListed2[_buyers[i]] = true;
    }    
    return true;
  }

  function initialize(address _DAOAddress, address _alphaATN, address _mim, uint256 _totalMIMamounttoSale, uint256 _rate, uint256 _startTimestamp, uint256 _endTimestamp, uint256 _vestedTime) external onlyOwner returns (bool) {

    alphaATN = _alphaATN;
    mim = _mim;
    DAOAddress = _DAOAddress;

    rate = _rate;
    limit1 = 800;
    limit2 = 1200;
    sellAmount = 0;
    totalMIMamounttoSale = _totalMIMamounttoSale;

    startTimestamp = _startTimestamp;
    endTimestamp = _endTimestamp;
    vestedTime = _vestedTime;

    return true;
  }

  modifier onlyWhileOpen {
    require(block.timestamp >= startTimestamp && block.timestamp <= endTimestamp);
    _;
  }

  modifier onlyWhileClose {
    require(block.timestamp > endTimestamp);
    _;
  }

  function purchaseaATN(uint256 _val) external onlyWhileOpen returns (bool) {
    require(_val >= 0, "Below minimum allocation");
    require(
      (whiteListed1[msg.sender] == true && preBuys[msg.sender].mimAmount.add(_val) <= limit1) ||
        (whiteListed2[msg.sender] == true && preBuys[msg.sender].mimAmount.add(_val) <= limit2),
      "More than allocation"
    );
    sellAmount = sellAmount.add(_val);
    require(
      sellAmount <= totalMIMamounttoSale,
      "The amount entered exceeds Fundraise Goal"
    );

    IERC20(mim).safeTransferFrom(msg.sender, address(this), _val);
    IERC20(mim).safeTransfer(DAOAddress, _val.mul(8).div(10));
    IERC20(mim).safeTransfer(otherAddress, _val.mul(2).div(10));
    uint256 _purchaseAmount = _calculateSaleQuote(_val);
    preBuys[msg.sender].mimAmount = preBuys[msg.sender].mimAmount.add(_val);
    preBuys[msg.sender].atnClaimedAmount = preBuys[msg.sender].atnClaimedAmount.add(_purchaseAmount);
    IERC20(alphaATN).safeTransfer(msg.sender, _purchaseAmount);
    return true;
  }

  function _calculateSaleQuote(uint256 paymentAmount_)
    internal
    view
    returns (uint256)
  {
    return paymentAmount_.mul(rate).div(RATE_DECIMALS);
  }

  function calculateSaleQuote(uint256 paymentAmount_)
    external
    view
    returns (uint256)
  {
    return _calculateSaleQuote(paymentAmount_);
  }
}