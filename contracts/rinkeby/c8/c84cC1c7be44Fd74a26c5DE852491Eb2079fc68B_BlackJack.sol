// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BlackJack {
    // Suit = index % 4, Number = index & 13. Ex.
    enum CardSuit {
        Diamond,
        Club,
        Heart,
        Spade
    }

    uint8[52] public deck;

    constructor() {
        for (uint8 i = 1; i < deck.length; i++) {
            deck[i] = i;
        }
    }

    function shuffle() public {
        bool[52] memory shuffleKeys;
        uint8[52] memory shuffledDeck;

        for (uint256 i = 0; i < 52; i++) {
            if (i % 2 == 0) shuffleKeys[i] = true;
            else shuffleKeys[i] = false;
        }

        // Split deck.

        uint8 k = 0;
        uint8 j = uint8(deck.length - 1);
        uint8 kStreak = 0;
        uint8 jStreak = 0;

        for (uint256 i = 0; i < shuffleKeys.length; i++) {
            if(kStreak >= 3) {
                kStreak = 0;
                shuffledDeck[i] = deck[j];
                j--;
                continue;
            }

            if(jStreak >= 3) {
                jStreak = 0;
                shuffledDeck[i] = deck[k];
                k++;
            }

            if (shuffleKeys[i]) {
                shuffledDeck[i] = deck[k];
                jStreak = 0;
                kStreak++;
                k++;
            } else {
                shuffledDeck[i] = deck[j];
                kStreak = 0;
                jStreak++;
                j--;
            }
        }

        deck = shuffledDeck;
    }
}