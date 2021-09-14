/**
 *Submitted for verification at Etherscan.io on 2021-09-14
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

contract Game{

    struct User {
        string username;
        uint256[] cards;
    }


    mapping(address => User) users;
    mapping(uint256 => address) public cardToOwner;

    uint256 public cardsRemaining;
    uint256 public x;
    uint256 public y;

    event SignIn(address indexed addr, string username);
    event BuyCard(address indexed buyer, uint256 cardNumber);

    constructor (uint256 _x, uint256 _y) {
        x = _x;
        y = _y;
        cardsRemaining = x * y;
    }

    function signIn(string memory _username) public {
        require(bytes(users[msg.sender].username).length == 0, "you have signed in before");
        require(bytes(_username).length > 0, "set a username");

        users[msg.sender].username = _username;
        
        emit SignIn(msg.sender, _username);
    }


    function buyCards(uint256 numberOfCards) public {
        require(bytes(users[msg.sender].username).length > 0, "you have not sign in yet");
        require (numberOfCards > 0 , "buy some cards !!!");
        require(numberOfCards <= cardsRemaining, "not enough cards available. set lesser number.");
        require(numberOfCards <= 5, "you can only buy 5 cards.");


        //array of cards selected
        // uint256[5] memory tokenIds;

        //first card will be selected by random
        uint256 lastCard = randomCard();
        // tokenIds[0] = lastCard;
        emit BuyCard(msg.sender, lastCard);

 
        //other cards will be selected near to last card
        for(uint i=1; i < numberOfCards; i++){
            lastCard = randomSide(lastCard);
            // tokenIds[i] = lastCard;
            emit BuyCard(msg.sender, lastCard);
        }
        // return tokenIds;
    }


    function randomCard() public returns(uint256) {
        //request for a random index from existing cards
        uint256 randIndex = (randomHash() % cardsRemaining);

        //select from remaining cards
        uint256 counter = 0;
        uint256 selectedCard = 0;
        do {
            if (cardToOwner[selectedCard] == address(0)){
                counter ++;
            } 
            selectedCard ++;
        } while(counter <= randIndex);
        selectedCard --;


        User storage user = users[msg.sender];

        //make sure the card would not be selected again
        cardsRemaining --;
        cardToOwner[selectedCard] = msg.sender;
        user.cards.push(selectedCard);
    
        return selectedCard;
    }


    function randomSide(uint256 cardNum) public returns(uint256) {

        uint256[4] memory sidesAvailable;

        uint256 selectedCard;

        //available sides
        uint256 index = 0;
        //right side
        if (cardNum % x != x-1 && cardToOwner[cardNum + 1] == address(0)) {
            sidesAvailable[index] = cardNum + 1;
            index++;
        }
        //top side
        if (cardNum >= x && cardToOwner[cardNum - x] == address(0)) {
            sidesAvailable[index] = cardNum - x;
            index++;
        }
        //left side
        if (cardNum % x != 0 && cardToOwner[cardNum - 1] == address(0)) {
            sidesAvailable[index] = cardNum - 1;
            index++;
        }
        //bottom side
        if (cardNum < x*y - x && cardToOwner[cardNum + x] == address(0)) {
            sidesAvailable[index] = cardNum + x;
            index++;
        }


        if (index == 0){
            selectedCard = randomCard();
        } else if (index == 1) {
            selectedCard = sidesAvailable[0];
        } else {
            //request for a random index from available sides
            uint256 randIndex = (randomHash() % index);

            selectedCard = sidesAvailable[randIndex];
        }


        //make sure the card would not be selected again
        cardsRemaining --;
        cardToOwner[selectedCard] = msg.sender;        
        users[msg.sender].cards.push(selectedCard);

        
        
        return selectedCard;
    }


    function randomHash() public view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
    }











    //////////////////////user getter functions

    function getUserName() public view returns(string memory) {
        require(bytes(users[msg.sender].username).length > 0, "you have not signed in yet");
        return users[msg.sender].username;
    }
    function getUserCards() public view returns(uint256[] memory) {
        require(bytes(users[msg.sender].username).length > 0, "you have not signed in yet");
        return users[msg.sender].cards;
    }

}

contract Generator{

    Game game;

    function resetGameContract(uint256 set_x, uint256 set_y) public{
        game = new Game(set_x, set_y);
    }
    
    
    function _signIn(string memory _username) public{
        game.signIn(_username);
    }
    
    function _buyCards(uint256 _numberOfCards) public {
        game.buyCards(_numberOfCards);
    }
    
    function _remaining() public view returns(uint256) {
        return game.cardsRemaining();
    }
    
    function _x() public view returns(uint256) {
        return game.x();
    }
    
    function _y() public view returns(uint256) {
        return game.y();
    }
}