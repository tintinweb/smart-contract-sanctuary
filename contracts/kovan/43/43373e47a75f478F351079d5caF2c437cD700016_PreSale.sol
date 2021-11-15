// SPDX-License-Identifier: ISC

pragma solidity ^0.8.4;

import "../interfaces/IBollycoin.sol";
import "../interfaces/AggregatorV3Interface.sol";
import "../utils/Context.sol";
import "../security/ReentrancyGuard.sol";

/**
 * The contract accepts ethereum and sends the users equivalent Bollycoin.
 *
 * Requirements:
 * The contract will sell the tokens and settlement happens after a while.
 * Until then no tokens are needed to be transferred to the contract.
 *
 * Once the sale is over, the contract will be funded with the exact amount of tokens.
 * Users can claim to their required addresses at that point.
 *
 * Governor address controls the price, oracle and sale-cap.
 * this contract is temporary for usage during pre-sale and private sale of bollycoins.
 */

contract PreSale is Context, ReentrancyGuard {
    mapping(address => uint8) public whitelisted;

    AggregatorV3Interface internal ref;
    IBollycoin internal bolly;

    address private _governor;

    uint256 private _totalSold;
    /**
     * {_price} represents the price of each bollycoin.
     *
     * It is modifiable but it is fixed at $4
     * 
     * Representation:
     * 1 USD = 1 00 00 00 00
     * 8 Precision
     */
    uint256 private _price;

    /**
     * {_minPurchase} represents the minimum amount of bollycoins.
     *
     * Uses:
     * It will be used to set the initial sale minimum amount.
     * Later when the pre-sale is opened we reduce it.
     *
     * Representation:
     * 1 Bollycoin = 1 * 10 ** 18
     * 18 Precision
     */
    uint256 private _minPurchase;

    /**
     * {_saleCap} prevents the selling of tokens beyond certain limit.
     */
    uint256 private _saleCap;

    /**
     * @dev prevents bad actors from making restricted function calls.
     *
     * sanitary function to allow only governor to make function calls.
     */
    modifier onlyGovernor() {
        require(msgSender() == _governor,"AccessError: caller not governor");
        _;
    }
 
    /**
     * @dev sets the {ref} and {bolly} of the presale.
     *
     * ref - chainlink instance
     * bolly - bollycoin instance
     *
     * `caller` is set as the initial governor; 
     */
    constructor(address oracle, address contractAddress) {
        ref = AggregatorV3Interface(oracle);
        bolly = IBollycoin(contractAddress);
        _governor = msgSender();
    }

    /**
     * @dev is emitted when a purchase is made.
     */
    event Purchase(address indexed to, uint256 amount, uint256 price, uint256 ethers);
    /**
     * @dev returns the current sale price of bollycoins.
     *
     * returns in 8 precision.
     */

    function bollycoinPrice() public view returns (uint256) {
        return _price;
    }

    /**
     * @dev returns the total bollycoins sold so far.
     *
     * returns in 18 precision.
     */
    function totalSold() public view returns (uint256) {
        return _totalSold;
    }

    /**
     * @dev returns the sale cap for bollycoins.
     *
     * returns in 18 precision.
     */
    function saleCap() public view returns (uint256) {
        return _saleCap;
    }

    /**
     * @dev returns the minimum purchase value of bollycoins.
     *
     * returns in 18 precision.
     */
    function minimumPurchase() public view returns (uint256) {
        return _minPurchase;
    }
    
    /**
     * @dev send the equivalent value of bollycoins to the user's wallet.
     * 
     * caller should send `ETH` with transaction.
     *
     * Requirements:
     * `caller` should be whitelisted.
     * `msgValue` should not be less than the _minPurchase Value
     */
    function buyBollycoin() public payable virtual nonReentrant returns (bool) {
        uint256 bollycoins = resolve(msgValue());
        require(_totalSold + bollycoins <= _saleCap, "SaleError: sale cap reached.");
        require(bollycoins >= _minPurchase, "SaleError: less than minimum purchase value.");
        require(whitelisted[msgSender()] == 1, "AccessError: Wallet Not Whitelisted");

        _totalSold += bollycoins;
        bolly.transfer(msgSender(), bollycoins);
        payable(_governor).transfer(msgValue());
        
        emit Purchase(msgSender(), bollycoins, _price, msgValue());
        return true;
    }

    /**
     * @dev returns the exact value of input bollycoins in ETH.
     *
     * `caller` should send the {amount} of tokens in 18 precision.
     *
     * Requirement:
     * amount - amount of bollycoins in 18 precision.
     */
    function getEstimate(uint256 amount) public virtual view returns (uint256) {
        uint256 ethPrice = etherprice();
        uint256 purchasePrice = amount * _price;

        return purchasePrice / ethPrice;

        /** 
         * Test Calculation:
         *
         * amount = 1 * 10 ** 18
         * ethPrice  = 3000 * 10 ** 8
         * usdPrice = 4 * 10 ** 8
         *
         * estimate = (amount * usdPrice) / ethPrice 
         * estimate in 18 precision
         */
        
    }

    /**
     * @dev returns the equivalent bollycoins for the `ethers`
     */
    function resolve(uint256 ethers) internal virtual returns (uint256) {
        uint256 priceOfEth = etherprice();
        uint256 eqUsd = ethers * priceOfEth;

        return eqUsd / _price;
    }

    /**
     * @dev fetches the current price of ETH/USD from chainlink.
     *
     * returns the price as uint256 with 8 decimal precision.
     */
    function etherprice() internal virtual view returns (uint256) {
        (, int price, , , ) = ref.latestRoundData();
        return uint256(price);
    }

    /**
     * @dev allows the {_governor} to set the {_price} {_saleCap} {_minPurchase} of bollycoin.
     *
     * Initially price is set as $ 0.
     *
     * Requirements :
     * `caller` should be the current governor.
     */
    function updateSaleParams(
        uint256 newPrice_, 
        uint256 saleCap_, 
        uint256 minPurchase_
    ) public virtual onlyGovernor returns (bool) {
        _price = newPrice_;
        _saleCap = saleCap_;
        _minPurchase = minPurchase_;

        return true;
    }

    /**
     * @dev transfers the governance of the contract.
     *
     * Requirements :
     * `caller` should be the current governor.
     * `newGovernor` cannot be a zero address.
     */
    function transferGovernance(address newGovernor) public virtual onlyGovernor returns (bool) {
        require(newGovernor != address(0), "ERC20: zero address cannot govern");

        _governor = newGovernor;
        return true;
    }

    /**
     * @dev whitelists the address of the buyer.
     *
     * Only whitelisted addresses can be used to buy
     * bollycoins.
     */
    function whitelist(address user) public virtual onlyGovernor returns(bool) {
        require(user != address(0), "ERC20: zero address for whitelisting");

        whitelisted[user] = 1;
        return true;
    }

    /**
     * @dev to withdraw unsold tokens from the smart contract.
     *
     * Only governor can call this function.
     */
    function withdraw(uint256 amount) public virtual onlyGovernor nonReentrant returns(bool) {
        uint256 contractBalance = bolly.balanceOf(address(this));
        require(contractBalance >= amount, "ERC20: amount greater than balance");

        bolly.transfer(_governor, amount);
        return true;
    }

}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.4;

/**
 * Interface of Bollycoin ERC20 Token As in EIP
 */

interface IBollycoin {

    /**
     * @dev returns the name of the token
     */
    function name() external view returns(string memory);

    /**
     * @dev returns the symbol of the token
     */
    function symbol() external view returns(string memory);

    /**
     * @dev returns the decimal places of a token
     */
    function decimals() external view returns(uint8);
 
    /**
     * @dev returns the total tokens in existence
     */
    function totalSupply() external view returns(uint256);

    /**
     * @dev returns the tokens owned by `account`.
     */
    function balanceOf(address account) external view returns(uint256); 

    /**
     * @dev transfers the `amount` of tokens from caller's account
     * to the `recipient` account.
     *
     * returns boolean value indicating the operation status.
     *
     * Emits a {Transfer} event
     */
    function transfer(address recipient, uint256 amount) external returns(bool);

    /**
     * @dev returns the remaining number of tokens the `spender' can spend
     * on behalf of the owner.
     *
     * This value changes when {approve} or {transferFrom} is executed.
     */
    function allowance(address owner, address spender) external view returns(uint256);

    /**
     * @dev sets `amount` as the `allowance` of the `spender`.
     *
     * returns a boolean value indicating the operation status.
     */
    function approve(address spender, uint256 amount) external returns(bool);

    /**
     * @dev transfers the `amount` on behalf of `spender` to the `recipient` account.
     *
     * returns a boolean indicating the operation status.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address spender, address recipient, uint256 amount) external returns(bool);

    /**
     * @dev Emitted from tokens are moved from one account('from') to another account ('to)
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when allowance of a `spender` is set by the `owner`
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  /**
   * @dev will return the current price of the token pair
   * from chainlink contract address.
   */

  function latestRoundData() external view returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.4;

/**
 * Library Like Contract. Not Required for deployment
 */
abstract contract Context {

    function msgSender() internal view virtual returns(address) {
        return msg.sender;
    }

    function msgData() internal view virtual returns(bytes calldata) {
        this;
        return msg.data;
    }

    function msgValue() internal view virtual returns(uint256) {
        return msg.value;
    }

}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.4;

contract ReentrancyGuard {

  /// @dev counter to allow mutex lock with only one SSTORE operation
  uint256 private _guardCounter = 1;

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * If you mark a function `nonReentrant`, you should also
   * mark it `external`. Calling one `nonReentrant` function from
   * another is not supported. Instead, you can implement a
   * `private` function doing the actual work, and an `external`
   * wrapper marked as `nonReentrant`.
   */
  modifier nonReentrant() {
    _guardCounter += 1;
    uint256 localCounter = _guardCounter;
    _;
    require(localCounter == _guardCounter);
  }
}

