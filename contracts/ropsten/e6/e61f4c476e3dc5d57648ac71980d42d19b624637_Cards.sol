contract Cards{

    struct Card{
        string name;
        string mail;
        uint8  age;
        string urlImage;
        string hashImage;
    }
    
    Card[] cards;

    function addCard(string name, string mail, uint8 age, string urlImage, string hashImage) public {
        Card memory card = Card(name, mail, age, urlImage, hashImage);
        cards.push(card);
    }
    
    function getCard(uint8 num) public constant returns(string, string, uint8, string, string){
        require(num < cards.length);
        return (cards[num].name, cards[num].mail, cards[num].age, cards[num].urlImage, cards[num].hashImage);
    }
    
    function getSize() public constant returns(uint256){
        return cards.length;
    }
}