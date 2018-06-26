pragma solidity ^0.4.0;
contract Ownable{
    address owner;
    
    function Ownable() public{
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) public onlyOwner{
        owner = newOwner;
    }
}
contract BusinessCards is Ownable{

    struct BusinessCard{
        string name;
        string mail;
        uint8  age;
        string urlImage;
        string hashImage;
    }
    
    BusinessCard[] cards;

    function addCard(string name, string mail, uint8 age, string urlImage, string hashImage) public onlyOwner{
        require(cards.length < 8);
        BusinessCard memory card = BusinessCard(name,mail,age,urlImage,hashImage);
        cards.push(card);
    }
    
    function getCard(uint8 num) public constant returns(string,string,uint8,string,string){
        return (cards[num].name, cards[num].mail, cards[num].age, cards[num].urlImage, cards[num].hashImage);
    }
    
    function getSize() public constant returns(uint256){
        return cards.length;
    }
}