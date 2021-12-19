// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Oracle {
    mapping(string => uint) private prices;
    address private owner;

    constructor(){
        owner=msg.sender;
    }

    function getOwner() public view returns (address){
        return owner;
    }

    function getPrice(string memory symbol) public view returns (uint) {
        return prices[symbol];
    }

    function setPrice(string memory symbol, uint price) public {
        require(msg.sender == owner,  "not allowed");
        prices[symbol] = price;
    }
    function setPrices(string[] memory symbolList, uint[] memory priceList) public {
        require(msg.sender == owner,  "not allowed");
        require(symbolList.length == priceList.length, "SymbolList and PriceList should be of same size");
        for (uint i = 0; i < symbolList.length; i++){
            setPrice(symbolList[i], priceList[i]);
        }
    }
}