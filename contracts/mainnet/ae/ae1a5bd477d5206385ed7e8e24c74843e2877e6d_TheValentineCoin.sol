pragma solidity ^0.4.18;

import "./Ownable.sol";
import "./CoinBase.sol";
import "./TheValentineCoinBase.sol";
import "./TheValentineCoinAdministration.sol";


contract TheValentineCoin is TheValentineCoinAdministration {
  uint256 public constant coinPrice = 33 finney;

  event ReservedCoin(address to);

  function () public payable {
    require(reservationActive == true);
    require(msg.value >= coinPrice);
    ReservedCoin(msg.sender);
  }

  function distributeCoin(uint256 coinId, address newCoinOwner, string coinEngraving) public onlyOwnerOrScript {
    if (bytes(coinEngraving).length != 0) {
      engravings[coinId] = coinEngraving;
    }
    _transfer(owner, newCoinOwner, coinId);
  }

  function destruct() public onlyOwner {
    selfdestruct(owner);
  }
}