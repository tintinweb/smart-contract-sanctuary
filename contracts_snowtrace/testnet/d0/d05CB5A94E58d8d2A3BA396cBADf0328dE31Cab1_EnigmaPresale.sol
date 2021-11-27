// SPDX-License-Identifier: MIT
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

contract EnigmaPresale is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  IERC20 public alphaENIGM;
  IERC20 public baseToken;
  address payable public presaleWallet;

  uint256 public minAmount;
  uint256 public maxAmount;
  uint256 public salePrice;
  uint256 public mintedAmount;

  bool public openSale;

  mapping(address => uint256) public claimed;
  address[] public whitelistedAddresses;

  function whitelistUsers(address[] calldata _users) public onlyOwner {
    delete whitelistedAddresses;
    whitelistedAddresses = _users;
  }

  function isWhitelisted(address _user) public view returns (bool) {
    for (uint i = 0; i < whitelistedAddresses.length; i++) {
      if (whitelistedAddresses[i] == _user) {
          return true;
      }
    }
    return false;
  }
  

  function initialize(
    address payable _presaleWallet,
    address _alphaENIGM,
    address _baseToken,
    uint256 _minAmount,
    uint256 _maxAmount,
    uint256 _salePrice
  ) external onlyOwner returns (bool) {
    require(openSale == false, "Sales are ongoing.");

    alphaENIGM = IERC20(_alphaENIGM);
    baseToken = IERC20(_baseToken);
    salePrice = _salePrice;
    presaleWallet = _presaleWallet;
    minAmount = _minAmount;
    maxAmount = _maxAmount;
    return true;
  }

  function toggleSale(bool _openSale) external onlyOwner {
    openSale = _openSale;
  }

  function purchaseaENIGM(uint256 amount) external returns (bool) {
    require(baseToken.allowance(msg.sender, address(this)) >= amount,"Base token allowance too low.");
    require(amount + claimed[msg.sender] >= minAmount, "Below minimum allocation");
    require(amount + claimed[msg.sender] <= maxAmount, "More than allocation");
    require(openSale == true, "Sales are closed.");
    require(isWhitelisted(msg.sender), "Not whitelisted");
    claimed[msg.sender] = claimed[msg.sender] + amount;

    mintedAmount = mintedAmount.add(amount);
    uint256 _purchaseAmount = _calculateSaleQuote(amount);
    alphaENIGM.safeTransfer(msg.sender, _purchaseAmount);
    baseToken.safeTransferFrom(msg.sender, presaleWallet, amount);
    return true;
  }

  function sendRemainingTokens() external onlyOwner returns (bool) {
    require(openSale == true, "Sales are closed.");

    alphaENIGM.safeTransfer(
      msg.sender,
      alphaENIGM.balanceOf(address(this))
    );
    return true;
  }

  function _calculateSaleQuote(uint256 paymentAmount_)
    internal
    view
    returns (uint256)
  {
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