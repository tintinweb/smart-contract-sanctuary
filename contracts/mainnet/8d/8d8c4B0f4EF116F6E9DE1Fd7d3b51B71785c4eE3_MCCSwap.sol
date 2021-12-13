// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/**
 * @title MCCSwap
 * @dev Swap MCC for ETH/OKLG on ETH
 */
contract MCCSwap is Ownable {
  IERC20 private mccV1 = IERC20(0x1a7981D87E3b6a95c1516EB820E223fE979896b3);
  IERC20 private mccV2 = IERC20(0x1454232149A0dC51e612b471fE6d3393e60D09Ad);
  IERC20 private mccV3 = IERC20(0x1454232149A0dC51e612b471fE6d3393e60D09Ad);

  AggregatorV3Interface internal priceFeed;

  mapping(address => bool) public v1WasSwapped;
  mapping(address => uint256) public v1SnapshotBalances;
  mapping(address => bool) public v2WasSwapped;
  mapping(address => uint256) public v2AirdropAmounts;
  mapping(address => uint256) public v2SnapshotBalances;

  uint256 public v2AirdropETHPool;
  uint256 public v2TotalAirdropped = 842714586113970000000;

  /**
   * Aggregator: ETH/USD
   */
  constructor() {
    // https://github.com/pcaversaccio/chainlink-price-feed/blob/main/README.md
    priceFeed = AggregatorV3Interface(
      0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
    );
  }

  function swap() external {
    swapV1ForV3();
    swapV2ForETH();
  }

  function swapV1ForV3() public {
    require(!v1WasSwapped[msg.sender], 'already swapped V1 for V3');

    uint256 _amountV3ToReceive = v1SnapshotBalances[msg.sender];
    require(_amountV3ToReceive > 0, 'you did not have any V1 tokens');
    require(
      mccV3.balanceOf(address(this)) >= _amountV3ToReceive,
      'not enough V3 liquidity to complete swap'
    );
    v1WasSwapped[msg.sender] = true;
    mccV3.transfer(msg.sender, _amountV3ToReceive);
  }

  function swapV2ForETH() public {
    require(!v2WasSwapped[msg.sender], 'already swapped V2 for ETH');

    // 1. check and compensate for airdropped V2 tokens
    uint256 mccV2AirdroppedAmount = v2AirdropAmounts[msg.sender];
    if (mccV2AirdroppedAmount > 0) {
      msg.sender.call{
        value: (v2AirdropETHPool * mccV2AirdroppedAmount) / v2TotalAirdropped
      }('');
    }

    // 2. check and compensate for currently held V2 tokens
    uint256 mccV2Balance = mccV2.balanceOf(msg.sender);
    if (mccV2Balance > 0) {
      mccV2.transferFrom(msg.sender, address(this), mccV2Balance);
    }

    uint256 mccV2SnapshotBal = v2SnapshotBalances[msg.sender];
    if (mccV2SnapshotBal > 0) {
      uint256 weiToTransfer = getUserOwedETHFromV2(mccV2SnapshotBal);
      require(
        address(this).balance >= weiToTransfer,
        'not enough ETH liquidity to execute swap'
      );
      msg.sender.call{ value: weiToTransfer }('');
    }

    v2WasSwapped[msg.sender] = true;
  }

  function getUserOwedETHFromV2(uint256 v2Balance)
    public
    view
    returns (uint256)
  {
    // Creates a USD balance with 18 decimals
    // MCC has 9 decimals, so need to add 9 decimals to get USD balance to 18
    // Refund Rate = MCC * $0.00000825 * 30%
    uint256 balanceInUSD = (((v2Balance * 10**9 * 825) / 10**8) * 3) / 10;

    // adding back 18 decimals to get returned value in wei
    return (10**18 * balanceInUSD) / getLatestETHPrice();
  }

  /**
   * Returns the latest ETH/USD price with returned value at 18 decimals
   * https://docs.chain.link/docs/get-the-latest-price/
   */
  function getLatestETHPrice() public view returns (uint256) {
    uint8 decimals = priceFeed.decimals();
    (, int256 price, , , ) = priceFeed.latestRoundData();
    return uint256(price) * (10**18 / 10**decimals);
  }

  function setV1WasSwapped(address _wallet, bool _didSwap) external onlyOwner {
    v1WasSwapped[_wallet] = _didSwap;
  }

  function setV2WasSwapped(address _wallet, bool _didSwap) external onlyOwner {
    v2WasSwapped[_wallet] = _didSwap;
  }

  function addETHToV2AirdropPool() external payable onlyOwner {
    require(msg.value > 0, 'must sent some ETH to add to pool');
    v2AirdropETHPool += msg.value;
    payable(address(this)).call{ value: msg.value }('');
  }

  function removeETHFromV2AirdropPool() external onlyOwner {
    require(v2AirdropETHPool > 0, 'Need ETH in the pool to remove it');

    uint256 _finalAmount = address(this).balance < v2AirdropETHPool
      ? address(this).balance
      : v2AirdropETHPool;
    if (_finalAmount > 0) {
      payable(owner()).call{ value: _finalAmount }('');
    }
    v2AirdropETHPool = 0;
  }

  function seedV1Balances(address[] memory _wallets, uint256[] memory _amounts)
    external
    onlyOwner
  {
    require(
      _wallets.length == _amounts.length,
      'must be same number of wallets and amounts'
    );
    for (uint256 _i = 0; _i < _wallets.length; _i++) {
      v1SnapshotBalances[_wallets[_i]] = _amounts[_i];
    }
  }

  function seedV2AirdropAmounts(
    address[] memory _wallets,
    uint256[] memory _amounts
  ) external onlyOwner {
    require(
      _wallets.length == _amounts.length,
      'must be same number of wallets and amounts'
    );
    for (uint256 _i = 0; _i < _wallets.length; _i++) {
      v2AirdropAmounts[_wallets[_i]] = _amounts[_i];
    }
  }

  function seedV2Balances(address[] memory _wallets, uint256[] memory _amounts)
    external
    onlyOwner
  {
    require(
      _wallets.length == _amounts.length,
      'must be same number of wallets and amounts'
    );
    for (uint256 _i = 0; _i < _wallets.length; _i++) {
      v2SnapshotBalances[_wallets[_i]] = _amounts[_i];
    }
  }

  function withdrawTokens(address _tokenAddy, uint256 _amount)
    external
    onlyOwner
  {
    IERC20 _token = IERC20(_tokenAddy);
    _amount = _amount > 0 ? _amount : _token.balanceOf(address(this));
    require(_amount > 0, 'make sure there is a balance available to withdraw');
    _token.transfer(owner(), _amount);
  }

  function withdrawETH(uint256 _amount) external onlyOwner {
    _amount = _amount > 0 ? _amount : address(this).balance;
    require(_amount > 0, 'make sure there is ETH available to withdraw');
    payable(owner()).send(_amount);
  }

  function setMCCV3(address v3) external onlyOwner {
    mccV3 = IERC20(v3);
  }

  // to recieve ETH from external wallets
  receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

/*
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