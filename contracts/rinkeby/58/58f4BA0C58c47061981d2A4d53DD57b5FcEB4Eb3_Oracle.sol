// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;


contract Oracle  {
    uint256 price;

    constructor(
        uint256 _price
    )public{
        price = _price;
    }
    function updatePrice(uint256 _price)
        public

        returns(uint256)
      {
        price = _price;
        return price;
      }

    function getPrice()
        public
        view
        returns(uint256)
      {
        return price;
      }

}

