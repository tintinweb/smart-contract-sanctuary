pragma solidity ^0.4.2;

contract ERC721 {
    function isERC721() public pure returns (bool b);
    function implementsERC721() public pure returns (bool b);
    function name() public pure returns (string name);
    function symbol() public pure returns (string symbol);
    function totalSupply() public view returns (uint256 totalSupply);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) public view returns (address owner);
    function approve(address _to, uint256 _tokenId) public;
    function takeOwnership(uint256 _tokenId) public;
    function transferFrom(address _from, address _to, uint256 _tokenId) public;
    function transfer(address _to, uint256 _tokenId) public;
    function tokenOfOwnerByIndex(address _owner, uint256 _index) constant returns (uint tokenId);
    function tokenMetadata(uint256 _tokenId) constant returns (string infoUrl);

    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
}

contract HumanityCard is ERC721 {

    ///////////////////////////////////////////////////////////////
    /// Modifiers

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    event Mined(address indexed owner, uint16 human);

    ///////////////////////////////////////////////////////////////
    /// Structures

    struct Human {
        string name;
        uint8 max;
        uint mined;
    }

    struct Card {
        uint16 human;
        address owner;
        uint indexUser;
    }

    struct SellOrder {
        address seller;
        uint card;
        uint price;
    }

    ///////////////////////////////////////////////////////////////
    /// Constants

    string constant NAME = "HumanityCards";
    string constant SYMBOL = "HCX";

    ///////////////////////////////////////////////////////////////
    /// Attributes

    address owner;
    uint cardPrice;
    uint humanNumber;
    Human[] humanArray;
    uint cardNumber;
    uint cardMined;
    Card[] cardArray;
    mapping (address => uint256) cardCount;
    mapping (uint256 => address) approveMap;
    SellOrder[] sellOrderList;

    // Index of the card for the user
    mapping (address => mapping (uint => uint)) indexCard;

    ///////////////////////////////////////////////////////////////
    /// Constructor

    function HumanityCard() public {
        owner = msg.sender;
        cardPrice = 1 finney;
        humanNumber = 0;
        cardNumber = 0;
        cardMined = 0;
    }

    ///////////////////////////////////////////////////////////////
    /// Admin functions

    function addHuman(string name, uint8 max) public onlyOwner {
        Human memory newHuman = Human(name, max, 0);
        humanArray.push(newHuman);
        humanNumber += 1;
        cardNumber += max;
    }

    // Used only if ether price increase (decrease the price card)
    function changeCardPrice(uint newPrice) public onlyOwner {
        cardPrice = newPrice;
    }

    ///////////////////////////////////////////////////////////////
    /// Implementation ERC721

    function isERC721() public pure returns (bool b) {
        return true;
    }

    function implementsERC721() public pure returns (bool b) {
        return true;
    }

    function name() public pure returns (string _name) {
        return NAME;
    }

    function symbol() public pure returns (string _symbol) {
        return SYMBOL;
    }

    function totalSupply() public view returns (uint256 _totalSupply) {
        return cardMined;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return cardCount[_owner];
    }

    function ownerOf(uint256 _tokenId) public view returns (address _owner) {
        require(_tokenId < cardMined);
        Card c = cardArray[_tokenId];
        return c.owner;
    }

    function approve(address _to, uint256 _tokenId) public {
        require(msg.sender == ownerOf(_tokenId));
        require(msg.sender != _to);
        approveMap[_tokenId] = _to;
        Approval(msg.sender, _to, _tokenId);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public {
        require(_tokenId < cardMined);
        require(_from == ownerOf(_tokenId));
        require(_from != _to);
        require(approveMap[_tokenId] == _to);

        cardCount[_from] -= 1;

        // Change the indexCard of _from
        indexCard[_from][cardArray[_tokenId].indexUser] = indexCard[_from][cardCount[_from]];
        cardArray[indexCard[_from][cardCount[_from]]].indexUser = cardArray[_tokenId].indexUser;

        // This card is the last one for the new owner
        cardArray[_tokenId].indexUser = cardCount[_to];
        indexCard[_to][cardCount[_to]] = _tokenId;

        cardArray[_tokenId].owner = _to;
        cardCount[_to] += 1;
        Transfer(_from, _to, _tokenId);
    }

    function takeOwnership(uint256 _tokenId) public {
        require(_tokenId < cardMined);
        address oldOwner = ownerOf(_tokenId);
        address newOwner = msg.sender;
        require(newOwner != oldOwner);
        require(approveMap[_tokenId] == msg.sender);

        cardCount[oldOwner] -= 1;

        // Change the indexCard of _from
        indexCard[oldOwner][cardArray[_tokenId].indexUser] = indexCard[oldOwner][cardCount[oldOwner]];
        cardArray[indexCard[oldOwner][cardCount[oldOwner]]].indexUser = cardArray[_tokenId].indexUser;

        // This card is the last one for the new owner
        cardArray[_tokenId].indexUser = cardCount[newOwner];
        indexCard[newOwner][cardCount[newOwner]] = _tokenId;

        cardArray[_tokenId].owner = newOwner;
        cardCount[newOwner] += 1;
        Transfer(oldOwner, newOwner, _tokenId);
    }

    function transfer(address _to, uint256 _tokenId) public {
        require(_tokenId < cardMined);
        address oldOwner = msg.sender;
        address newOwner = _to;
        require(oldOwner == ownerOf(_tokenId));
        require(oldOwner != newOwner);
        require(newOwner != address(0));

        cardCount[oldOwner] -= 1;

        // Change the indexCard of _from
        indexCard[oldOwner][cardArray[_tokenId].indexUser] = indexCard[oldOwner][cardCount[oldOwner]];
        cardArray[indexCard[oldOwner][cardCount[oldOwner]]].indexUser = cardArray[_tokenId].indexUser;

        // This card is the last one for the new owner
        cardArray[_tokenId].indexUser = cardCount[newOwner];
        indexCard[newOwner][cardCount[newOwner]] = _tokenId;

        cardArray[_tokenId].owner = newOwner;
        cardCount[newOwner] += 1;
        Transfer(oldOwner, newOwner, _tokenId);
    }

    function tokenOfOwnerByIndex(address _owner, uint256 _index) constant returns (uint tokenId) {
        require(_index < cardCount[_owner]);

        return indexCard[_owner][_index];
    }

    // For this case the only metadata is the name of the human
    function tokenMetadata(uint256 _tokenId) constant returns (string infoUrl) {
        require(_tokenId < cardMined);

        uint16 humanId = cardArray[_tokenId].human;
        return humanArray[humanId].name;
    }

    ///////////////////////////////////////////////////////////////
    /// HumanityCard functions

    // Mine a new card
    function mineCard() public payable returns(bool success) {
        require(msg.value == cardPrice);
        require(cardMined < cardNumber);

        int remaining = (int)(cardNumber - cardMined);

        // Choosing the card
        int numero = int(keccak256(block.timestamp))%remaining;
        if(numero < 0) {
            numero *= -1;
        }
        uint16 chosenOne = 0;
        while (numero >= 0) {
            numero -= (int)(humanArray[chosenOne].max-humanArray[chosenOne].mined);
            if (numero >= 0) {
                chosenOne += 1;
            }
        }

        // Adding the card to the user
        address newOwner = msg.sender;
        Card memory newCard = Card(chosenOne, newOwner, cardCount[newOwner]);
        cardArray.push(newCard);

        // This card is the last one
        indexCard[newOwner][cardCount[newOwner]] = cardMined;
        cardCount[newOwner] += 1;

        // Updating cards informations
        cardMined += 1;
        humanArray[chosenOne].mined += 1;

        // Sending the fund to the owner
        if(!owner.send(cardPrice)) {
           revert();
        }

         Mined(newOwner, chosenOne);

        return true;
    }

    // Sale functions
    function createSellOrder(uint256 _tokenId, uint price) public {
        require(_tokenId < cardMined);
        require(msg.sender == ownerOf(_tokenId));

        SellOrder memory newOrder = SellOrder(msg.sender, _tokenId, price);
        sellOrderList.push(newOrder);

        cardArray[_tokenId].owner = address(0);
        cardCount[msg.sender] -= 1;

        // Change the indexCard of sender
        indexCard[msg.sender][cardArray[_tokenId].indexUser] = indexCard[msg.sender][cardCount[msg.sender]];
        cardArray[indexCard[msg.sender][cardCount[msg.sender]]].indexUser = cardArray[_tokenId].indexUser;
    }

    function processSellOrder(uint id, uint256 _tokenId) payable public {
        require(id < sellOrderList.length);

        SellOrder memory order = sellOrderList[id];
        require(order.card == _tokenId);
        require(msg.value == order.price);
        require(msg.sender != order.seller);

        // Sending fund to the seller
        if(!order.seller.send(msg.value)) {
           revert();
        }

        // Adding card to the buyer
        cardArray[_tokenId].owner = msg.sender;

        // This card is the last one for the new owner
        cardArray[_tokenId].indexUser = cardCount[msg.sender];
        indexCard[msg.sender][cardCount[msg.sender]] = _tokenId;

        cardCount[msg.sender] += 1;

        // Update list
        sellOrderList[id] = sellOrderList[sellOrderList.length-1];
        delete sellOrderList[sellOrderList.length-1];
        sellOrderList.length--;
    }

    function cancelSellOrder(uint id, uint256 _tokenId) public {
        require(id < sellOrderList.length);

        SellOrder memory order = sellOrderList[id];
        require(order.seller == msg.sender);
        require(order.card == _tokenId);

        // Give back card to seller
        cardArray[_tokenId].owner = msg.sender;

        // This card is the last one for the new owner
        cardArray[_tokenId].indexUser = cardCount[msg.sender];
        indexCard[msg.sender][cardCount[msg.sender]] = _tokenId;

        cardCount[msg.sender] += 1;

        // Update list
        sellOrderList[id] = sellOrderList[sellOrderList.length-1];
        delete sellOrderList[sellOrderList.length-1];
        sellOrderList.length--;
    }

    function getSellOrder(uint id) public view returns(address seller, uint card, uint price) {
        require(id < sellOrderList.length);

        SellOrder memory ret = sellOrderList[id];
        return(ret.seller, ret.card, ret.price);
    }

    function getNbSellOrder() public view returns(uint nb) {
        return sellOrderList.length;
    }


    // Get functions
    function getOwner() public view returns(address ret) {
        return owner;
    }

    function getCardPrice() public view returns(uint ret) {
        return cardPrice;
    }

    function getHumanNumber() public view returns(uint ret) {
        return humanNumber;
    }

    function getHumanInfo(uint i) public view returns(string name, uint8 max, uint mined) {
        require(i < humanNumber);
        Human memory h = humanArray[i];
        return (h.name, h.max, h.mined);
    }

    function getCardNumber() public view returns(uint ret) {
        return cardNumber;
    }

    function getCardInfo(uint256 _tokenId) public view returns(uint16 human, address owner) {
        require(_tokenId < cardMined);
        Card memory c = cardArray[_tokenId];
        return (c.human, c.owner);
    }
}