/**
 *Submitted for verification at polygonscan.com on 2021-12-04
*/

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

contract Crowdsale is Ownable {
  uint256 public constant PRECISION_DECIMALS = 100000;

  IERC20 public denaris;

  bool public isOpen;
  bool public claimable;
  uint256 public tokensSold;

  uint256[] public prices;
  uint256[] public minAmounts;
  address[] public paymentMethods;

  mapping(address => uint256) public purchased;

  constructor(
    IERC20 _denaris,
    address[] memory _paymentMethods,
    uint256[] memory _minAmounts,
    uint256[] memory _prices
  ) {
    require(_paymentMethods.length == _prices.length, "Payment methods & prices length mismatch");
    require(_minAmounts.length == _prices.length, "Min amounts & prices length mismatch");

    denaris = _denaris;
    paymentMethods = _paymentMethods;
    minAmounts = _minAmounts;
    prices = _prices;
  }

  function buy(uint256 _paymentMethodId, uint256 _amount) public {
    require(_paymentMethodId < paymentMethods.length, "Invalid paymentMethodId");
    require(isOpen, "Crowdsale is not open");
    require(_amount >= minAmounts[_paymentMethodId], "Amount is below minimum amount");

    address paymentMethod = paymentMethods[_paymentMethodId];

    uint256 tokenBalance = denaris.balanceOf(address(this));
    require(tokenBalance > tokensSold, "Tokens sold out");

    uint256 tokensBeingPurchased = getPurchasedTokensByPaymentToken(_paymentMethodId, _amount);

    if (tokensSold + tokensBeingPurchased > tokenBalance) {
      uint256 overflowAmount = (tokensSold + tokensBeingPurchased) - tokenBalance;
      tokensBeingPurchased -= overflowAmount;

      uint256 refundAmount = getRequiredPaymentTokenByPurchasedTokens(_paymentMethodId, overflowAmount);
      _amount = _amount - refundAmount;
    }

    IERC20(paymentMethod).transferFrom(msg.sender, address(this), _amount);
    purchased[msg.sender] += tokensBeingPurchased;
    tokensSold += tokensBeingPurchased;
  }

  function claim() public {
    require(claimable, "Crowdsale not finalized");
    uint256 claimableAmount = purchased[msg.sender];
    purchased[msg.sender] = 0;
    denaris.transfer(msg.sender, claimableAmount);
  }

  function withdraw(
    address _token,
    address _to,
    uint256 _amount
  ) public onlyOwner {
    IERC20(_token).transfer(_to, _amount);
  }

  function setOpen(bool _open) public onlyOwner {
    isOpen = _open;
  }

  function setClaimable(bool _claimable) public onlyOwner {
    claimable = _claimable;
  }

  function setMinAmounts(uint256[] memory _minAmounts) public onlyOwner {
    minAmounts = _minAmounts;
  }

  function setPrices(uint256[] memory _prices) public onlyOwner {
    prices = _prices;
  }

  function getAllPrices() public view returns (uint256[] memory) {
    return prices;
  }

  function getAllMinAmounts() public view returns (uint256[] memory) {
    return minAmounts;
  }

  function getPurchasedTokensByPaymentToken(uint256 _paymentMethodId, uint256 _paymentToken)
    public
    view
    returns (uint256)
  {
    uint256 price = prices[_paymentMethodId];
    uint256 purchasedTokens = (_paymentToken * 10**18) / price;
    return purchasedTokens;
  }

  function getRequiredPaymentTokenByPurchasedTokens(uint256 _paymentMethodId, uint256 tokenAmount)
    public
    view
    returns (uint256)
  {
    uint256 price = prices[_paymentMethodId];
    return (tokenAmount * price) / 10**18;
  }
}