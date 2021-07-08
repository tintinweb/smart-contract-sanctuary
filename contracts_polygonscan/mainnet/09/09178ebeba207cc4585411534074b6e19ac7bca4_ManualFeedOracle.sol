/**
 *Submitted for verification at polygonscan.com on 2021-07-08
*/

// File: contracts/interfaces/IOracle.sol

/* Copyright (C) 2020 PlotX.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity 0.5.7;

contract IOracle {
  
  function getSettlementPrice(uint256 _marketSettleTime, uint80 _roundId) external view returns(uint256 _value, uint256 _roundIdUsed);

  function getLatestPrice() external view returns(uint256 _value);
}

// File: contracts/oracles/ManualFeedOracle.sol

/* Copyright (C) 2020 PlotX.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity 0.5.7;


contract ManualFeedOracle is IOracle {

  event PriceUpdated(uint256 index, uint256 price, uint256 updatedOn);

  address public authorizedAddres;
  address public multiSigWallet;
  string public currencyName;

  struct FeedData {
    uint256 price;
    uint256 postedOn;
  }

  mapping(uint256 => uint256) public settlementPrice; // Settlement time to price

  FeedData[] public feedData;

  modifier OnlyAuthorized() {
    require(msg.sender == authorizedAddres);
    _;
  }

  /**
  * @param _authorized Authorized address to post prices 
  */
  constructor(address _authorized, address _multiSigWallet, string memory _currencyName) public {
    require(authorizedAddres == address(0));
    authorizedAddres = _authorized;
    multiSigWallet = _multiSigWallet;
    currencyName = _currencyName;
  }

  /**
  * @dev Update authorized address to post price
  */
  function changeAuthorizedAddress(address _newAuth) external OnlyAuthorized {
    require(_newAuth != address(0));
    authorizedAddres = _newAuth;
  }

  /**
  * @dev Post the latest price of currency
  */
  function postPrice(uint256 _price) external OnlyAuthorized {
    if(feedData.length > 0) {
      require(feedData[feedData.length - 1].postedOn < now);
    }
    feedData.push(FeedData(_price, now));
    emit PriceUpdated(feedData.length - 1, _price, now);
  }

  /**
  * @dev Post the latest price of currency
  */
  function postHistoricalPrices(uint256 _price, uint256 _timeStamp) external OnlyAuthorized {
    if(feedData.length > 0) {
      require(feedData[feedData.length - 1].postedOn < _timeStamp);
    }
    feedData.push(FeedData(_price, _timeStamp));
    emit PriceUpdated(feedData.length - 1, _price, _timeStamp);
  }

  /**
  * @dev Post the settlement price of currency
  */
  function postSettlementPrice(uint256 _marketSettleTime, uint256 _price) external {
    require(msg.sender == multiSigWallet);
    require(_marketSettleTime > 0 && _price > 0, "Invalid arguments");
    require(now >= _marketSettleTime);
    settlementPrice[_marketSettleTime] = _price;
    emit PriceUpdated(0, _price, _marketSettleTime);
  }

  /**
  * @dev Get price of the asset at given time and nearest roundId
  */
  function getSettlementPrice(uint256 _marketSettleTime, uint80 _roundId) external view returns(uint256 _value, uint256 roundId) {
    require(settlementPrice[_marketSettleTime] > 0, "Price not yet posted for settlement");
    return (settlementPrice[_marketSettleTime], 0);
  }

  /**
  * @dev Get the latest price of currency
  */
  function getLatestPrice() external view returns(uint256 _value) {
    return feedData[feedData.length - 1].price;
  }

  /**
  * @dev Get the latest round data
  */
  function getLatestRoundData() external view returns(uint256 _roundId, uint256 _postedOn, uint256 _price) {
    _roundId = feedData.length - 1;
    return (_roundId, feedData[_roundId].postedOn, feedData[_roundId].price);
  }

}