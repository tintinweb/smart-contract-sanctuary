/**
 *Submitted for verification at Etherscan.io on 2021-12-01
*/

///SPDX-License-Identifier: SPDX-License

pragma solidity 0.7.4;


contract ObjectsOfCity {
    
    uint256 public houses = 1; // number of houses
    uint256 public hotels = 0;  // number of hotels
    uint256 public coins = 100;  // number of coins
    uint256 internal collect;  // to save the calculation result 
    
    uint256 immutable profitHouse = 2; // profit of house
    uint256 immutable profitHotel = 75; // profit of hotel
    uint256 public immutable priceHouse = 50; // price for house
    uint256 public immutable priceHotel = 1500; // price for hotel
    uint256 public immutable spaceFlight = 100000; // price for space flight
    uint256 internal boostUp = 2; // multiplier factor
    bool public boost = false; // trigger for multiplying coins
    
    
    modifier noCoinsHouse() {
        require(coins >= priceHouse, "ERROR: No coins, to buy");
        _;
    }
    
    modifier noCoinsHotel() {
        require(coins >= priceHotel, "ERROR: No coins, to buy");
        _;
    }
    
    modifier fewHotels() {
        require(hotels >= 20, "Few hotels to use the Bank");
        _;
    }
    
    modifier noCoinsForFly() {
        require(coins >= spaceFlight, "No coins for fly");
        _;
    }
    
}


contract City is ObjectsOfCity {
    
    function buyHouse() public noCoinsHouse {
        houses +=1; // buying a house
        coins -= priceHouse; // house price write-off
    }
    
    function buyHotels() public noCoinsHotel {
        hotels +=1; // buying a hotel
        coins -= priceHotel; // hotel price write-off
    }
    
    function collectCoins() public {
        if(boost != true) {
            collect = houses * profitHouse + hotels * profitHotel; // formula to collect
            coins += collect; // account plus the result of formula
        }       
        else {
            collect = (houses * profitHouse + hotels * profitHotel) * boostUp; // formula to collect if you have a <boost up>
            coins += collect; // account plus the result of formula with boost up
        }
    }
    
    function balanceMultiplication() public fewHotels {
        coins *= 2; // account multiplying on 2
    }
    
    function sendIntoSpace() public noCoinsForFly {
        coins -= spaceFlight; // flight price write-off
        boost = true; // trigger ON
        boostUp += 1; // multiplier increase
    }
}