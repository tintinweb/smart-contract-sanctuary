/**
 *Submitted for verification at snowtrace.io on 2021-12-01
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

contract Presale is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address public alphaTOKEN;
  address public DAOAddress;
  address public mim;

  uint256 public minYunanAmount;
  uint256 public maxYunanAmount;
  uint256 public yunanSalePrice;

  uint256 public minTrikuAmount;
  uint256 public maxTrikuAmount;
  uint256 public trikuSalePrice;

  uint256 public goalAmount;
  uint256 public soldAmount;
  uint256 public publicAllocation;
  uint256 public publicSalePrice;

  bool public openIdo = false;
  bool public publicSale = false;

  mapping(address => bool) public boughtTokens;
  mapping(address => bool) triku;
  mapping(address => bool) yunan;

  constructor(address payable _DAOAddress) {
    DAOAddress = _DAOAddress;
  }

  function whitelistUsers(address[] memory addresses, bool isTriku)
    public
    onlyOwner
  {
    for (uint256 i = 0; i < addresses.length; i++) {
      if (isTriku) {
        triku[addresses[i]] = true;
      } else {
        yunan[addresses[i]] = true;
      }
    }
  }

  function unwhitelistUsers(address[] memory addresses, bool isTriku)
    public
    onlyOwner
  {
    for (uint256 i = 0; i < addresses.length; i++) {
      if (isTriku) {
        triku[addresses[i]] = false;
      } else {
        yunan[addresses[i]] = false;
      }
    }
  }

  function setPresaleDetails(
    uint256 _minAmount,
    uint256 _maxAmount,
    uint256 _price,
    bool forTriku
  ) external onlyOwner {
    if (forTriku) {
      minTrikuAmount = _minAmount;
      maxTrikuAmount = _maxAmount;
      trikuSalePrice = _price;
    } else {
      minYunanAmount = _minAmount;
      maxYunanAmount = _maxAmount;
      yunanSalePrice = _price;
    }
  }

  function initialize(
    address _alphaTOKEN,
    address _mim,
    uint256 _goalAmount,
    uint256 _publicAllocation,
    uint256 _publicSalePrice
  ) external onlyOwner returns (bool) {
    alphaTOKEN = _alphaTOKEN;
    mim = _mim;
    goalAmount = _goalAmount;
    publicAllocation = _publicAllocation;
    publicSalePrice = _publicSalePrice;
    return true;
  }

  function setOpen(bool _open) external onlyOwner {
    openIdo = _open;
  }

  function isWhitelisted(address _user) public view returns (bool) {
    return triku[_user] || yunan[_user];
  }

  function getDetails (address _user) public view returns (uint256 minAmount, uint256 maxAmount, uint256 salePrice) {
    if (!isWhitelisted(_user)) {
      return (0, publicAllocation, publicSalePrice);
    } else if (triku[_user]) {
      return (minTrikuAmount, maxTrikuAmount, trikuSalePrice);
    } else {
      return (minYunanAmount, maxYunanAmount, yunanSalePrice);
    }
  }

  function togglePublicSale(bool _toggle) external onlyOwner {
    publicSale = _toggle;
  }

  function purchase(uint256 _val) external returns (bool) {
    require(openIdo == true, "IDO is closed");
    soldAmount = soldAmount.add(_val);
    require(soldAmount <= goalAmount, "The amount entered exceeds IDO Goal");
    require(
      boughtTokens[msg.sender] == false,
      "You've already participated to the IDO."
    );

    boughtTokens[msg.sender] = true;

    if (publicSale) {
      require(_val <= publicAllocation, "More than public sale allocation");
    } else {
      require(isWhitelisted(msg.sender) == true, "You're not Whitelisted");
      if (triku[msg.sender]) {
        require(_val >= minTrikuAmount, "Below minimum allocation");
        require(_val <= maxTrikuAmount, "More than allocation");
      } else {
        require(_val >= minYunanAmount, "Below minimum allocation");
        require(_val <= maxYunanAmount, "More than allocation");
      }
    }
    IERC20(mim).safeTransferFrom(msg.sender, address(this), _val);
    IERC20(mim).safeTransfer(DAOAddress, _val);
    uint256 _purchaseAmount = _calculateSaleQuote(_val);
    IERC20(alphaTOKEN).safeTransfer(msg.sender, _purchaseAmount);
    return true;
  }

  function _calculateSaleQuote(uint256 paymentAmount_)
    internal
    view
    returns (uint256)
  {
    uint256 salePrice = publicSale ? publicSalePrice : triku[msg.sender] ? trikuSalePrice : yunanSalePrice;
    return uint256(1e9).mul(paymentAmount_).div(salePrice);
  }

  function calculateSaleQuote(uint256 paymentAmount_)
    external
    view
    returns (uint256)
  {
    return _calculateSaleQuote(paymentAmount_);
  }
}