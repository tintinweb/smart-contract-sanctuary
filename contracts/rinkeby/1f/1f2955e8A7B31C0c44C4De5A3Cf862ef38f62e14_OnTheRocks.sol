/**
 *Submitted for verification at Etherscan.io on 2021-08-29
*/

/**
 *Submitted for verification at Etherscan.io on 2021-08-26
*/

pragma solidity ^0.8.0;

abstract contract EtherRock {
    function buyRock (uint rockNumber) virtual public payable;
    function sellRock (uint rockNumber, uint price) virtual public;
    function giftRock (uint rockNumber, address receiver) virtual public;
    
    struct Rock {
        address owner;
        bool currentlyForSale;
        uint price;
        uint timesSold;
    }
    
    mapping (uint => Rock) public rocks;
    
}

contract OnTheRocks {
  //rinkeby
  EtherRock allRocks = EtherRock(0xBC0dAA15d70d35f257450197c129A220fb1F2955); 
  //mainnet
  //EtherRock(0x37504AE0282f5f334ED29b4548646f887977b7cC);

  function sweepRange(uint256[] memory rangeRocks, uint256 price, uint256 newPrice) public payable {
    for (uint i=0; i < rangeRocks.length; i++){
        allRocks.buyRock{value:price}(rangeRocks[i]);
        allRocks.sellRock(rangeRocks[i], newPrice);
        allRocks.giftRock(rangeRocks[i], msg.sender);
    }
  }

  function safeBuy(uint256 id) public payable {
    allRocks.buyRock{value:msg.value}(id);
    allRocks.sellRock(id, type(uint256).max);
    allRocks.giftRock(id, msg.sender);
  }
  
    function viewRockRange(uint256 startId, uint256 endId)
        public
        view
        virtual
        returns (address[] memory , bool[] memory , uint[] memory , uint[] memory )
    {

        address[] memory rockOwners;
        bool[] memory rocksCurrentlyForSale;
        uint[] memory rocksPrice;
        uint[] memory rocksTimesSold;
        
        for (uint256 i = startId; i < (endId + 1); ++i) {
            (address owner, bool currentlyForSale, uint price, uint timesSold) = allRocks.rocks(i);
            rockOwners[i] = owner;
            rocksCurrentlyForSale[i] = currentlyForSale;
            rocksPrice[i] = price;
            rocksTimesSold[i] = timesSold;
        }

        return (rockOwners, rocksCurrentlyForSale, rocksPrice, rocksTimesSold);
    }
}