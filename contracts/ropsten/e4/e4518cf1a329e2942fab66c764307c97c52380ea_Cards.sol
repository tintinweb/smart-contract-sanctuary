contract Cards{

    struct Card{
        string name;
        uint8  age;
        string info;
        string imageUrl;
        string imageHash;
    }
    
    Card[] cards;

    function addCard(string name, uint8 age, string info, string imageUrl, string imageHash) public {
        Card memory card = Card(name, age, info, imageUrl, imageHash);
        cards.push(card);
    }
    
    function getCard(uint8 num) public constant returns(string, uint8, string, string, string){
        require(num < cards.length);
        return (cards[num].name, cards[num].age, cards[num].info, cards[num].imageUrl, cards[num].imageHash);
    }
    
    function getSize() public constant returns(uint256){
        return cards.length;
    }
}