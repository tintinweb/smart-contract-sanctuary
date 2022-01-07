// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "AggregatorV3Interface.sol";
import "Ownable.sol";

contract DailyPowerContract is Ownable {
    uint256 public price;
    uint256 public volume;
    address payable public buyer;
    address payable public seller;
    uint256 public date;
    uint256 public buyerFundEthAmount;
    uint256 public sellerFundEthAmount;
    bool buyerFunded = false;
    bool sellerFunded = false;
    AggregatorV3Interface internal cadUsdPriceFeed;
    AggregatorV3Interface internal ethUsdPriceFeed;
    enum CONTRACT_STATE {
        CREATED,
        CALCULATED_FUNDING,
        PARTIALLY_FUNDED,
        FULLY_FUNDED,
        SETTLED_PRICE_ADDED,
        CALCULATED_RETURNS,
        CLOSED
    }
    CONTRACT_STATE public contract_state;
    uint256 public settledPrice;
    address payable public winner;
    uint256 public winningsCadAmount;
    uint256 public winningsEthAmount;
    uint256 public buyerRefundEthAmount;
    uint256 public sellerRefundEthAmount;
    uint256 public priceCap = 100000;

    constructor(
        address _cadUsdPriceFeedAddress,
        address _ethUsdPriceFeedAddress,
        uint256 _price,
        uint256 _volume,
        address _buyer,
        address _seller,
        uint256 _date
    ) {
        price = _price; // in cents/MWh
        volume = _volume; // in KWh
        buyer = payable(_buyer);
        seller = payable(_seller);
        date = _date;
        cadUsdPriceFeed = AggregatorV3Interface(_cadUsdPriceFeedAddress);
        ethUsdPriceFeed = AggregatorV3Interface(_ethUsdPriceFeedAddress);
        contract_state = CONTRACT_STATE.CREATED;
    }

    function createContract() public onlyOwner {}

    function calculateFundingAmounts() public onlyOwner {
        // 10,000 cents/MWh * 1,000 KWh * 24
        // convert CAD to USD

        //buyer price
        uint256 buyerAmountCad = ((price * volume * 24) / 1000 / 100) *
            (10**18); // usign 24 hours for now, but need to account for daylight savings days with 23 or 25 hours
        (, int256 latestCadToUsdPrice, , , ) = cadUsdPriceFeed
            .latestRoundData();

        //seller price
        uint256 sellerAmountCad = (((priceCap - price) * volume * 24) /
            1000 /
            100) * (10**18);

        //convert usd to cad
        uint256 latestUsdToCadPrice = (1 * 10**16) /
            uint256(latestCadToUsdPrice); // invert the conversion rate
        uint256 adjustedCadToUsdPrice = uint256(latestUsdToCadPrice) * 10**10; // 18 decimals
        //buyer cad to usd
        uint256 buyerUsdAmount = (buyerAmountCad * 10**18) /
            adjustedCadToUsdPrice;
        //seller cad to usd
        uint256 sellerUsdAmount = (sellerAmountCad * 10**18) /
            adjustedCadToUsdPrice;

        // convert usd to eth
        (, int256 latestPrice, , , ) = ethUsdPriceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(latestPrice) * 10**10; // 18 decimals
        // buyer usd to eth
        uint256 buyerEthAmount = (buyerUsdAmount * 10**18) / adjustedPrice;
        //seller usd to eth
        uint256 sellerEthAmount = (sellerUsdAmount * 10**18) / adjustedPrice;

        buyerFundEthAmount = buyerEthAmount;
        sellerFundEthAmount = sellerEthAmount;

        // calculate seller funding amount, which would be based on a price of 1000 minus the agreed upon price (100 in our example)

        contract_state = CONTRACT_STATE.CALCULATED_FUNDING;
    }

    function addBuyerFunds() public payable {
        require(
            contract_state == CONTRACT_STATE.CALCULATED_FUNDING ||
                contract_state == CONTRACT_STATE.PARTIALLY_FUNDED
        );
        require(buyerFunded == false);
        require(
            msg.value == buyerFundEthAmount,
            "Not the correct amount of ETH!"
        );
        require(
            msg.sender == buyer
        );

        buyerFunded = true;
        if (sellerFunded) {
            contract_state = CONTRACT_STATE.FULLY_FUNDED;
        } else {
            contract_state = CONTRACT_STATE.PARTIALLY_FUNDED;
        }
    }

    function addSellerFunds() public payable {
        require(
            contract_state == CONTRACT_STATE.CALCULATED_FUNDING ||
                contract_state == CONTRACT_STATE.PARTIALLY_FUNDED
        );
        require(sellerFunded == false);
        require(
            msg.value == sellerFundEthAmount,
            "Not the correct amount of ETH!"
        );
        require(
            msg.sender == seller
        );

        sellerFunded = true;
        if (buyerFunded) {
            contract_state = CONTRACT_STATE.FULLY_FUNDED;
        } else {
            contract_state = CONTRACT_STATE.PARTIALLY_FUNDED;
        }
    }

    function setSettledPrice(uint256 settled_price) public onlyOwner {
        require(contract_state == CONTRACT_STATE.FULLY_FUNDED);
        settledPrice = settled_price;
        contract_state = CONTRACT_STATE.SETTLED_PRICE_ADDED;
    }

    function calculateSettlementAmounts() public onlyOwner {
        require(contract_state == CONTRACT_STATE.SETTLED_PRICE_ADDED);
        uint256 priceDelta = settledPrice - price;

        winningsCadAmount = (priceDelta * volume * 24) / 1000 / 100;
        uint256 winningsAmountCadAdjusted = winningsCadAmount * (10**18);

        (, int256 latestCadToUsdPrice, , , ) = cadUsdPriceFeed
            .latestRoundData();

        //convert usd to cad
        uint256 latestUsdToCadPrice = (1 * 10**16) /
            uint256(latestCadToUsdPrice); // invert the conversion rate
        uint256 adjustedCadToUsdPrice = uint256(latestUsdToCadPrice) * 10**10; // 18 decimals

        //buyer cad to usd
        uint256 winningsUsdAmount = (winningsAmountCadAdjusted * 10**18) /
            adjustedCadToUsdPrice;

        // convert usd to eth
        (, int256 latestPrice, , , ) = ethUsdPriceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(latestPrice) * 10**10; // 18 decimals

        // buyer usd to eth
        winningsEthAmount = (winningsUsdAmount * 10**18) / adjustedPrice;

        if (settledPrice > price) {
            winner = buyer;
            buyerRefundEthAmount = buyerFundEthAmount + winningsEthAmount;
            sellerRefundEthAmount = sellerFundEthAmount - winningsEthAmount;
        }
        if (settledPrice < price) {
            winner = seller;
            buyerRefundEthAmount = buyerFundEthAmount - winningsEthAmount;
            sellerRefundEthAmount = sellerFundEthAmount + winningsEthAmount;
        }

        contract_state = CONTRACT_STATE.CALCULATED_RETURNS;
    }

    function distrubuteFunds() public onlyOwner {
        require(contract_state == CONTRACT_STATE.CALCULATED_RETURNS);
        buyer.transfer(buyerRefundEthAmount);
        seller.transfer(sellerRefundEthAmount);
        contract_state = CONTRACT_STATE.CLOSED;
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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