/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.7;

// contract Card
// {
//     enum Suit {Heart, Diamond, Shape, Club, Jocker}
//     Suit public suit;

//     enum Rank {Two, Three, Four, Five, Six, Seven, Eight, Nine, Ten, Jack, Queen, King, Ace, Jocker}
//     Rank public rank;

//     function equal(Card card) returns (bool)
//     {
//         return suit == card.suit && rank == card.rank;
//     }
// }

// contract Card
// {
//     enum Suit {Heart, Diamond, Shape, Club, Jocker}
//     Suit public suit;

//     enum Rank {Two, Three, Four, Five, Six, Seven, Eight, Nine, Ten, Jack, Queen, King, Ace, Jocker}
//     Rank public rank;

//     function equal(Card card) returns (bool)
//     {
//         return suit == card.suit() && rank == card.rank();
//     }



// }


contract test {
   enum Suit{ SPADES, HEARTS, DIAMOND }
   Suit choice;
   Suit constant defaultChoice = Suit.SPADES;

   Suit firstCard = Suit.SPADES;
   Suit secondCard = Suit.SPADES;

   function setHearts() public {
      choice = Suit.HEARTS;
   }

   function getChoice() public view returns (Suit) {
      return choice;
   }

   function getDefaultChoice() public pure returns (uint) {
      return uint(defaultChoice);
   }


    function drawFirstCard() public {
        firstCard = Suit.SPADES;
    }

    function drawSecondCard() public {
        secondCard = Suit.HEARTS;
    }


}