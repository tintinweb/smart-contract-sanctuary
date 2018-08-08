pragma solidity ^0.4.8;
contract CryptoNumismat 
{
    address owner;

    string public standard = &#39;CryptoNumismat&#39;;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    struct Buy 
    {
        uint cardIndex;
        address seller;
        uint minValue;  // in wei
    }

    mapping (uint => Buy) public cardsForSale;
    mapping (address => bool) public admins;

    event Assign(uint indexed _cardIndex, address indexed _seller, uint256 _value);
    event Transfer(address indexed _from, address indexed _to, uint _cardIndex, uint256 _value);
    
    function CryptoNumismat() public payable 
    {
        owner = msg.sender;
        admins[owner] = true;
        
        totalSupply = 1000;                         // Update total supply
        name = "cryptonumismat";                    // Set the name for display purposes
        symbol = "$";                               // Set the symbol for display purposes
        decimals = 0;                               // Amount of decimals for display purposes
    }
    
    modifier onlyOwner() 
    {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyAdmins() 
    {
        require(admins[msg.sender]);
        _;
    }
    
    function setOwner(address _owner) onlyOwner() public 
    {
        owner = _owner;
    }
    
    function addAdmin(address _admin) onlyOwner() public
    {
        admins[_admin] = true;
    }
    
    function removeAdmin(address _admin) onlyOwner() public
    {
        delete admins[_admin];
    }
    
    function withdrawAll() onlyOwner() public 
    {
        owner.transfer(this.balance);
    }

    function withdrawAmount(uint256 _amount) onlyOwner() public 
    {
        require(_amount <= this.balance);
        
        owner.transfer(_amount);
    }

    function addCard(uint _cardIndex, uint256 _value) public onlyAdmins()
    {
        require(_cardIndex <= 1000);
        require(_cardIndex > 0);
        
        require(cardsForSale[_cardIndex].cardIndex != _cardIndex);
        
        address seller = msg.sender;
        uint256 _value2 = (_value * 1000000000);
        
        cardsForSale[_cardIndex] = Buy(_cardIndex, seller, _value2);
        Assign(_cardIndex, seller, _value2);
    }
    
    function displayCard(uint _cardIndex) public constant returns(uint, address, uint256) 
    {
        require(_cardIndex <= 1000);
        require(_cardIndex > 0);
        
        require (cardsForSale[_cardIndex].cardIndex == _cardIndex);
            
        return(cardsForSale[_cardIndex].cardIndex, 
        cardsForSale[_cardIndex].seller,
        cardsForSale[_cardIndex].minValue);
    }
    
    
    uint256 private limit1 = 0.05 ether;
    uint256 private limit2 = 0.5 ether;
    uint256 private limit3 = 5 ether;
    uint256 private limit4 = 50 ether;
    
    function calculateNextPrice(uint256 _startPrice) public constant returns (uint256 _finalPrice)
    {
        if (_startPrice < limit1)
            return _startPrice * 10 / 4;
        else if (_startPrice < limit2)
            return _startPrice * 10 / 5;
        else if (_startPrice < limit3)
            return _startPrice * 10 / 6;
        else if (_startPrice < limit4)
            return _startPrice * 10 / 7;
        else
            return _startPrice * 10 / 8;
    }
    
    function calculateDevCut(uint256 _startPrice) public constant returns (uint256 _cut)
    {
        if (_startPrice < limit2)
            return _startPrice * 5 / 100;
        else if (_startPrice < limit3)
            return _startPrice * 4 / 100;
        else if (_startPrice < limit4)
            return _startPrice * 3 / 100;
        else
            return _startPrice * 2 / 100;
    }
    
    function buy(uint _cardIndex) public payable
    {
        require(_cardIndex <= 1000);
        require(_cardIndex > 0);
        require(cardsForSale[_cardIndex].cardIndex == _cardIndex);
        require(cardsForSale[_cardIndex].seller != msg.sender);
        require(msg.sender != address(0));
        require(msg.sender != owner);
        require(cardsForSale[_cardIndex].minValue > 0);
        require(msg.value >= cardsForSale[_cardIndex].minValue);
        
        address _buyer = msg.sender;
        address _seller = cardsForSale[_cardIndex].seller;
        uint256 _price = cardsForSale[_cardIndex].minValue;
        uint256 _nextPrice = calculateNextPrice(_price);
        uint256 _totalPrice = _price - calculateDevCut(_price);
        uint256 _extra = msg.value - _price;
        
        cardsForSale[_cardIndex].seller = _buyer;
        cardsForSale[_cardIndex].minValue = _nextPrice;
        
        Transfer(_buyer, _seller, _cardIndex, _totalPrice);
        Assign(_cardIndex, _buyer, _nextPrice);////////////////////////////////
        
        _seller.transfer(_totalPrice);
        
        if (_extra > 0)
        {
            Transfer(_buyer, _buyer, _cardIndex, _extra);
            
            _buyer.transfer(_extra);
        }
    }
}