/**
 *Submitted for verification at Etherscan.io on 2021-09-12
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

// import "./playcards.sol";

 

contract GamePlay{
    
    // PlayCards public NFT;
    
    uint256 public loginFee;
    uint256 public cardFee;

    mapping (uint256 => bool) public cardNumberUsed;
    mapping (address => string) public users;
    mapping(address => uint256) internal balances;
    
    //it is for test
    mapping (uint256 => string) public ownerOfCard;
        
    uint256 x = 3;
    uint256 y = 4;
    uint256 public cardsRemaining = x * y;
    
    uint256 public test = 0;
    uint256[12] public testA = [30,30,30,30,30,30,30,30,30,30,30,30];
    
    

    constructor(){
        cardNumberUsed[x*y] = true;
        
        setFee(1, 1);
        // NFT = new PlayCards("play cards", "pc", "https://my-json-server.typicode.com/loutus/PlayCards/Tokens/", 54);
    }

    function AllOwners() public view returns(string[12] memory){
        string[12] memory tempReturn;
        for(uint i = 0 ; i < x*y ; i++){
            tempReturn[i] = ownerOfCard[i];
        }
        return tempReturn;
    }

    function AllCardsUsed() public view returns(bool[12] memory){
        bool[12] memory tempReturn;
        for(uint i = 0 ; i < x*y ; i++){
            tempReturn[i] = cardNumberUsed[i];
        }
        return tempReturn;
    }
    
    function seeAllTestA() public view returns(uint[12] memory){
        uint[12] memory tempReturn;
        for(uint i = 0 ; i < x*y ; i++){
            tempReturn[i] = testA[i];
        }
        return tempReturn;
    }


    function setFee(uint256 _loginFee, uint256 _cardFee) public{
        loginFee = _loginFee;
        cardFee = _cardFee;
    }

    function login(string memory username) public{
        //check login fee
        
        //every person just one entrance
        require(bytes(users[msg.sender]).length == 0 , "you have login before");
        
        require(bytes(username).length > 0, "enter your name");
        
        //set username
        users[msg.sender] = username;
    }

    function buyCards(uint256 numberOfCards) public {
        require (numberOfCards > 0 , "buy some cards !!!");
        require(numberOfCards <= cardsRemaining, "there is no enough cards available. set lesser number.");
        require(bytes(users[msg.sender]).length != 0 , "you have to login first.");

        //array of cards selected
        uint256[] memory tokenIds;

        //first card will be selected by random
        uint256 lastCard = getRandomCard();
        tokenIds[0] = lastCard;

        //other cards will be selected near to last card
        for(uint i=1; i < numberOfCards; i++){
            lastCard = getNearCard(lastCard);
            tokenIds[i] = lastCard;
        }

        //mint the cards to address 
        // NFT.mint(msg.sender, tokenIds);
    }
    
    function getRandomCard() public returns(uint256){

        //request for a random number
        uint256 randomIndex = random() % cardsRemaining;

        //select the random card from remaining cards
        uint256 counter = 0;
        uint256 randomCard = 0;
        do {
            if (! cardNumberUsed[randomCard]){
                counter++;
            }
            randomCard++;
        }while(counter < randomIndex);

        //make sure the card would not be selected again
        cardNumberUsed[randomCard] = true;
        cardsRemaining --;
        
        //user gets the card
        balances[msg.sender] ++;
        ownerOfCard[randomCard] = users[msg.sender];
        
        return randomCard;
    }
    
    function getNearCard(uint256 lastCard) public returns (uint256) {
        uint256[4] memory cardsAvailable = nearCards(lastCard);
        uint256 numberOfEmptyCard = 0;
        for(uint i=0; i<4; i++){
            if (cardsAvailable[i] != x*y){
                numberOfEmptyCard++;
            }
        }
        if(numberOfEmptyCard > 0){
            uint256 randomIndex = uint256 (random()) % numberOfEmptyCard;
            uint256 i = 0;
            uint256 randomCard = 0;
            while(i <= randomIndex){
                if (cardsAvailable[randomCard] != x*y){
                    i++;
                }
                randomCard++;
            }
            randomCard--;
            testA[test] = cardsAvailable[randomCard];
            test++;
            // mint cardsAvailable[randomCard]
            cardNumberUsed[cardsAvailable[randomCard]] = true;
            ownerOfCard[cardsAvailable[randomCard]] = users[msg.sender];
            cardsRemaining--;
            return cardsAvailable[randomCard];
        }else{
            
            return getRandomCard();
        }
    }
    
    function nearCards(uint256 lastCard) public view returns (uint256[4] memory) {
        
        uint256[4] memory cardsAvailable ;
        
        cardsAvailable[0] = x*y;
        cardsAvailable[1] = x*y;
        cardsAvailable[2] = x*y;
        cardsAvailable[3] = x*y;

        if (cardNumberUsed[rightSide(lastCard)] == false){
            cardsAvailable[0] = rightSide(lastCard);
        }
        if (cardNumberUsed[topSide(lastCard)] == false){
            cardsAvailable[1] = topSide(lastCard);
        }
        if (cardNumberUsed[leftSide(lastCard)] == false){
            cardsAvailable[2] = leftSide(lastCard);
        }
        if (cardNumberUsed[bottomSide(lastCard)] == false){
            cardsAvailable[3] = bottomSide(lastCard);
        }

        return cardsAvailable;
    }
    
    
    function rightSide(uint256 _card) public view returns(uint256){
        if (_card % x != x-1){
            return _card + 1;
        }else{
            return x*y;
        }
    }
    
    function topSide(uint256 _card) public view returns(uint256){
        if (_card >= x){
            return _card - x;
        }else{
            return x*y;
        }
    }

    function leftSide(uint256 _card) public view returns(uint256){
        if (_card % x != 0){
            return _card - 1;
        }else{
            return x*y;
        }
    }

    function bottomSide(uint256 _card) public view returns(uint256){
        if (_card < x*y - x){
            return _card + x;
        }else{
            return x*y;
        }
    }




    function random() public view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
    }
    
//     function balanceOf(address owner) public view returns(uint256){
//         return NFT.balanceOf(owner);
//     }
}