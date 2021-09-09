/**
 *Submitted for verification at Etherscan.io on 2021-09-08
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

contract game{


    struct User {
        bool signIn;
        string username;
        uint256[] cards;
    }

    struct Card {
        bool selected;
        address owner;
        uint256[] sideCards;
    }


    uint256 cardsRemaining;

    string[] _allUsers;
    
    //test
    Card[] _allcards;

    mapping(address => User) users;
    mapping(uint256 => Card) cards;


    constructor(){
        cardsRemaining = 10;
        //test
        for(uint i = 0; i < cardsRemaining; i++) {
            _allcards.push(cards[i]);
        }
    }

    function signIn(string memory _username) public {
        User storage user = users[msg.sender];

        require(!user.signIn, "you have signed in before");
        require(bytes(_username).length > 0, "set a username");

        user.signIn = true;
        user.username = _username;
        _allUsers.push(_username);
    }

    function buyCard(uint256 cardNumber) public {
        User storage user = users[msg.sender];
        Card storage card = cards[cardNumber];

        require(user.signIn, "you have not sign in yet");
        require(cardsRemaining > 0, "all cards assigned");
        require(!card.selected, "card hase been selected before");

        user.cards.push(cardNumber);
        card.selected = true;
        card.owner = msg.sender;
        
        _allcards[cardNumber] = card;
    }
    
















    //////////////////////user getter functions

    function getAllUsernames() public view returns(string[] memory) {
        return _allUsers;
    }
    function getUserName() public view returns(string memory) {
        require(users[msg.sender].signIn == true, "you have not signed in yet");
        return users[msg.sender].username;
    }
    function getUserCards() public view returns(uint256[] memory) {
        require(users[msg.sender].signIn == true, "you have not signed in yet");
        return users[msg.sender].cards;
    }



    /////////////////////card getter functions
    function getAllCards() public view returns(Card[] memory) {
        return _allcards;
    }
    function getCardOwner(uint256 cardNumber) public view returns(address) {
        return cards[cardNumber].owner;
    }
    function cardHasSelected(uint256 cardNumber) public view returns(bool) {
        return cards[cardNumber].selected;
    }
    function getCardSides(uint256 cardNumber) public view returns(uint256[] memory) {
        return cards[cardNumber].sideCards;
    }
}