// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract Dex is Ownable {
  event BuyToken(address tokenAddr, address account, uint256 amount, uint256 cost);
  event SellToken(address tokenAddr, address account, uint256 amount, uint256 cost);
  event Deposit(address depositer, uint256 amount);
  event Withdraw(address _tokenAddr, uint256 amount);
  event AddNewToken(address _tokenAddr);
  event RemoveToken(address _tokenAddr);

  mapping(address => bool) public supportedTokenAddr;
  mapping(address => address) public tokenToPriceAddr;

  modifier supportsToken(address _tokenAddr) {
    require(supportedTokenAddr[_tokenAddr] == true, "Dex: This token is not supported");
    _;
  }

  receive() external payable {
    emit Deposit(msg.sender, msg.value);
  }

  constructor(address[] memory _tokenAddr, address[] memory _tokenPriceAddr) {
    for (uint256 i = 0; i < _tokenAddr.length; i++) {
      supportedTokenAddr[_tokenAddr[i]] = true;
      tokenToPriceAddr[_tokenAddr[i]] = _tokenPriceAddr[i];
      emit AddNewToken(_tokenAddr[i]);
    }
  }

  function getPrice(address _tokenAddr) public view supportsToken(_tokenAddr) returns (uint256) {
    AggregatorV3Interface priceFeed = AggregatorV3Interface(tokenToPriceAddr[_tokenAddr]);
    (, int256 price, , , ) = priceFeed.latestRoundData();
    return uint256(price);
  }

  function buyToken(address _tokenAddr) external payable supportsToken(_tokenAddr) {
    IERC20 token = IERC20(_tokenAddr);
    uint256 amount = msg.value * 10**18 / getPrice(_tokenAddr);
    require(token.balanceOf(address(this)) >= amount, "Dex: Token sold out");
    token.transfer(msg.sender, amount);
    emit BuyToken(_tokenAddr, msg.sender, amount, msg.value);
  }

  function sellToken(address _tokenAddr, uint256 _value) external supportsToken(_tokenAddr) {
    IERC20 token = IERC20(_tokenAddr);
    uint256 amount = (_value * getPrice(_tokenAddr)) / 10**18;
    require(address(this).balance >= amount, "Dex: Cannot afford this token");
    token.transferFrom(msg.sender, address(this), _value);
    (bool success, ) = payable(msg.sender).call{ value: amount }("");
    require(success, "Dex: ETH transfer unsuccessful!");
    emit SellToken(_tokenAddr, msg.sender, amount, _value);
  }

  function withdrawToken(address _tokenAddr, uint256 _amount) external onlyOwner supportsToken(_tokenAddr) {
    IERC20 token = IERC20(_tokenAddr);
    token.transfer(msg.sender, _amount);
    emit Withdraw(_tokenAddr, _amount);
  }

  function withdrawEth(uint256 _amount) external onlyOwner {
    require(_amount >= address(this).balance, "Dex: Insufficient Eth balance");
    (bool success, ) = payable(msg.sender).call{ value: _amount }("");
    require(success, "Dex: ETH transfer unsuccessful!");
    emit Withdraw(address(0), _amount);
  }

  function addNewToken(address _tokenAddr, address _tokenPriceAddr) external onlyOwner {
    require(supportedTokenAddr[_tokenAddr] == false, "Dex: This token is already supported");
    supportedTokenAddr[_tokenAddr] = true;
    tokenToPriceAddr[_tokenAddr] = _tokenPriceAddr;
    emit AddNewToken(_tokenAddr);
  }

  function removeToken(address _tokenAddr) external onlyOwner supportsToken(_tokenAddr) {
    delete supportedTokenAddr[_tokenAddr];
    delete tokenToPriceAddr[_tokenAddr];
    emit RemoveToken(_tokenAddr);
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

