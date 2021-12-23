/**
 *Submitted for verification at Etherscan.io on 2021-12-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// chainlink aggregator for price feeds
interface AggregatorV3Interface {
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

// custom errors
error NotOwner(address requestor);
error UnexpectedData();
error NotEnoughFunds(address sender, uint deposit, uint priceperday);


/**
 * @title EqualCheats Payment Processor
 * @dev Accept ETH payments and emit events for purchasing packages on equalcheats.
 */
contract ECPaymentProcessor {
    event PaymentRecieved(address sender, uint days_authorized, uint cheatid);

    address private owner;
    AggregatorV3Interface private priceFeed;

    // uin128 to save gas on deployment
    uint128 CheatID; 
    uint128 Price; //since this is only 8 decimals, and i expect it will never be a large number, we can get away with this

    modifier onlyOwner() {
        if(msg.sender != owner) {
            revert NotOwner({requestor: msg.sender});
        }
        _;
    }

    //rinkeby: 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
    //cheatID, 100000000, 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419 (one dollar per day)
    constructor(uint128 cheat, uint128 price, address aggregatorInterface) {
        owner = msg.sender;
        CheatID = cheat;
        Price = price;
        priceFeed = AggregatorV3Interface(aggregatorInterface); // Mainnet ETH / USD feed
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    //eth cost in USD, 8 decimal places. Ex: 394934000000 means $3,949.34
    function getEthPrice() public view returns (int) {
        (
             , 
            int price,
             ,
             ,
             
        ) = priceFeed.latestRoundData();
        return price;
    }
    function getPriceInWei() public view returns (uint) {
        return (Price * 10**18) / uint(getEthPrice());
    }

    receive() external payable {

        //1. make sure deposit was large enough for at least one day
        uint price_in_wei = getPriceInWei();
        if( msg.value < price_in_wei) {
            revert NotEnoughFunds({sender: msg.sender, deposit: msg.value, priceperday: price_in_wei});
        }

        //2. determine how many days to authorize
        uint num_days =  msg.value / price_in_wei;
        uint remainder_wei =  msg.value % price_in_wei;

        //3. emit authorization
        emit PaymentRecieved(msg.sender, num_days, CheatID);

        //4. refund excess funds
        if(remainder_wei > 0)
        {
            payable(msg.sender).transfer(remainder_wei); //refund any dust 
        }
    }
    fallback() external payable {
        //msg.data empty
        revert UnexpectedData();
    }
}