// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/interfaces/IERC20.sol';
import './OKLGProduct.sol';

interface IERC20Decimals is IERC20 {
  function decimals() external view returns (uint8);
}

/**
 * @title OKLGAtomicSwapInstance
 * @dev This is the main contract that supports holding metadata for OKLG atomic inter and intrachain swapping
 */
contract OKLGAtomicSwapInstance is OKLGProduct {
  IERC20Decimals private _token;

  address public tokenOwner;
  address payable public oracleAddress;
  uint256 public maxSwapAmount;
  uint8 public targetTokenDecimals;
  uint256 public minimumGasForOperation = 2 * 10**15; // 2 finney (0.002 ETH)
  bool public isActive = true;

  struct Swap {
    bytes32 id;
    uint256 origTimestamp;
    uint256 currentTimestamp;
    bool isOutbound;
    bool isComplete;
    bool isRefunded;
    bool isSendGasFunded;
    address swapAddress;
    uint256 amount;
  }

  mapping(bytes32 => Swap) public swaps;
  mapping(address => Swap) public lastUserSwap;

  event ReceiveTokensFromSource(
    bytes32 indexed id,
    uint256 origTimestamp,
    address sender,
    uint256 amount
  );

  event SendTokensToDestination(
    bytes32 indexed id,
    address receiver,
    uint256 amount
  );

  event RefundTokensToSource(
    bytes32 indexed id,
    address sender,
    uint256 amount
  );

  event TokenOwnerUpdated(address previousOwner, address newOwner);

  constructor(
    address _costToken,
    address _spendAddress,
    address _oracleAddress,
    address _tokenOwner,
    address _tokenAddy,
    uint8 _targetTokenDecimals,
    uint256 _maxSwapAmount
  ) OKLGProduct(uint8(7), _costToken, _spendAddress) {
    oracleAddress = payable(_oracleAddress);
    tokenOwner = _tokenOwner;
    maxSwapAmount = _maxSwapAmount;
    targetTokenDecimals = _targetTokenDecimals;
    _token = IERC20Decimals(_tokenAddy);
  }

  function getSwapTokenAddress() external view returns (address) {
    return address(_token);
  }

  function setActiveState(bool _isActive) external {
    require(
      msg.sender == owner() || msg.sender == tokenOwner,
      'setActiveState user must be contract creator'
    );
    isActive = _isActive;
  }

  function setOracleAddress(address _oracleAddress) external onlyOwner {
    oracleAddress = payable(_oracleAddress);
    transferOwnership(oracleAddress);
  }

  function setTargetTokenDecimals(uint8 _decimals) external onlyOwner {
    targetTokenDecimals = _decimals;
  }

  function setTokenOwner(address newOwner) external {
    require(
      msg.sender == tokenOwner,
      'user must be current token owner to change it'
    );
    address previousOwner = tokenOwner;
    tokenOwner = newOwner;
    emit TokenOwnerUpdated(previousOwner, newOwner);
  }

  function withdrawTokens(uint256 _amount) external {
    require(
      msg.sender == tokenOwner,
      'withdrawTokens user must be token owner'
    );
    _token.transfer(msg.sender, _amount);
  }

  function setSwapCompletionStatus(bytes32 _id, bool _isComplete)
    external
    onlyOwner
  {
    swaps[_id].isComplete = _isComplete;
  }

  function setMinimumGasForOperation(uint256 _amountGas) external onlyOwner {
    minimumGasForOperation = _amountGas;
  }

  function receiveTokensFromSource(uint256 _amount)
    external
    payable
    returns (bytes32, uint256)
  {
    require(isActive, 'this atomic swap instance is not active');
    require(
      msg.value >= minimumGasForOperation,
      'you must also send enough gas to cover the target transaction'
    );
    require(
      maxSwapAmount == 0 || _amount <= maxSwapAmount,
      'trying to send more than maxSwapAmount'
    );

    _payForService(minimumGasForOperation);

    if (minimumGasForOperation > 0) {
      oracleAddress.call{ value: minimumGasForOperation }('');
    }
    _token.transferFrom(msg.sender, address(this), _amount);

    uint256 _ts = block.timestamp;
    bytes32 _id = sha256(abi.encodePacked(msg.sender, _ts, _amount));
    swaps[_id] = Swap({
      id: _id,
      origTimestamp: _ts,
      currentTimestamp: _ts,
      isOutbound: false,
      isComplete: false,
      isRefunded: false,
      isSendGasFunded: false,
      swapAddress: msg.sender,
      amount: _amount
    });
    lastUserSwap[msg.sender] = swaps[_id];
    emit ReceiveTokensFromSource(_id, _ts, msg.sender, _amount);
    return (_id, _ts);
  }

  function unsetLastUserSwap(address _addy) external onlyOwner {
    delete lastUserSwap[_addy];
  }

  // msg.sender must be the user who originally created the swap.
  // Otherwise, the unique identifier will not match from the originally
  // sending txn.
  //
  // NOTE: We're aware this function can be spoofed by creating a sha256 hash of msg.sender's address
  // and _origTimestamp, but it's important to note refundTokensFromSource and sendTokensToDestination
  // can only be executed by the owner/oracle. Therefore validation should be done by the oracle before
  // executing those and the only possibility of a vulnerability is if someone has compromised the oracle account.
  function fundSendToDestinationGas(
    bytes32 _id,
    uint256 _origTimestamp,
    uint256 _amount
  ) external payable {
    require(
      msg.value >= minimumGasForOperation,
      'you must send enough gas to cover the send transaction'
    );
    require(
      _id == sha256(abi.encodePacked(msg.sender, _origTimestamp, _amount)),
      "we don't recognize this swap"
    );
    if (minimumGasForOperation > 0) {
      oracleAddress.call{ value: minimumGasForOperation }('');
    }
    swaps[_id] = Swap({
      id: _id,
      origTimestamp: _origTimestamp,
      currentTimestamp: block.timestamp,
      isOutbound: true,
      isComplete: false,
      isRefunded: false,
      isSendGasFunded: true,
      swapAddress: msg.sender,
      amount: _amount
    });
  }

  // This must be called AFTER fundSendToDestinationGas has been executed
  // for this txn to fund this send operation
  function refundTokensFromSource(bytes32 _id) external {
    require(isActive, 'this atomic swap instance is not active');

    Swap storage swap = swaps[_id];

    _confirmSwapExistsGasFundedAndSenderValid(swap);
    swap.isRefunded = true;
    _token.transfer(swap.swapAddress, swap.amount);
    emit RefundTokensToSource(_id, swap.swapAddress, swap.amount);
  }

  // This must be called AFTER fundSendToDestinationGas has been executed
  // for this txn to fund this send operation
  function sendTokensToDestination(bytes32 _id) external returns (bytes32) {
    require(isActive, 'this atomic swap instance is not active');

    Swap storage swap = swaps[_id];

    _confirmSwapExistsGasFundedAndSenderValid(swap);

    // handle if this token and target chain token in bridge have different decimals
    // current decimals = 9 -- 100 tokens == 100000000000
    // target decimals = 18 -- 100 tokens == 100000000000000000000
    // to get current amount to transfer, need to multiply by ratio of 10^currentDecimals / 10^targetDecimals
    uint256 _swapAmount = swap.amount;
    if (targetTokenDecimals > 0) {
      _swapAmount =
        swap.amount *
        (10**_token.decimals() / 10**targetTokenDecimals);
    }
    _token.transfer(swap.swapAddress, _swapAmount);

    swap.currentTimestamp = block.timestamp;
    swap.isComplete = true;
    emit SendTokensToDestination(_id, swap.swapAddress, swap.amount);
    return _id;
  }

  function _confirmSwapExistsGasFundedAndSenderValid(Swap memory swap)
    private
    view
    onlyOwner
  {
    // functions that call this should only be called by the current owner
    // or oracle address as they will do the appropriate validation beforehand
    // to confirm the receiving swap is valid before sending tokens to the user.
    require(
      swap.origTimestamp > 0 && swap.amount > 0,
      'swap does not exist yet.'
    );
    // We're just validating here that the swap has not been
    // completed and gas has been funded before moving forward.
    require(
      !swap.isComplete && !swap.isRefunded && swap.isSendGasFunded,
      'swap has already been completed, refunded, or gas has not been funded'
    );
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/interfaces/IERC20.sol';
import './interfaces/IOKLGSpend.sol';
import './OKLGWithdrawable.sol';

/**
 * @title OKLGProduct
 * @dev Contract that every product developed in the OKLG ecosystem should implement
 */
contract OKLGProduct is OKLGWithdrawable {
  IERC20 private _token; // OKLG
  IOKLGSpend private _spend;

  uint8 public productID;

  constructor(
    uint8 _productID,
    address _tokenAddy,
    address _spendAddy
  ) {
    productID = _productID;
    _token = IERC20(_tokenAddy);
    _spend = IOKLGSpend(_spendAddy);
  }

  function setTokenAddy(address _tokenAddy) external onlyOwner {
    _token = IERC20(_tokenAddy);
  }

  function setSpendAddy(address _spendAddy) external onlyOwner {
    _spend = IOKLGSpend(_spendAddy);
  }

  function setProductID(uint8 _newId) external onlyOwner {
    productID = _newId;
  }

  function getTokenAddress() public view returns (address) {
    return address(_token);
  }

  function getSpendAddress() public view returns (address) {
    return address(_spend);
  }

  function _payForService(uint256 _weiToRemoveFromSpend) internal {
    _spend.spendOnProduct{ value: msg.value - _weiToRemoveFromSpend }(
      msg.sender,
      productID
    );
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title IOKLGSpend
 * @dev Logic for spending OKLG on products in the product ecosystem.
 */
interface IOKLGSpend {
  function spendOnProduct(address _payor, uint8 _product) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/interfaces/IERC20.sol';

/**
 * @title OKLGWithdrawable
 * @dev Supports being able to get tokens or ETH out of a contract with ease
 */
contract OKLGWithdrawable is Ownable {
  function withdrawTokens(address _tokenAddy, uint256 _amount)
    external
    onlyOwner
  {
    IERC20 _token = IERC20(_tokenAddy);
    _amount = _amount > 0 ? _amount : _token.balanceOf(address(this));
    require(_amount > 0, 'make sure there is a balance available to withdraw');
    _token.transfer(owner(), _amount);
  }

  function withdrawETH() external onlyOwner {
    payable(owner()).call{ value: address(this).balance }('');
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}