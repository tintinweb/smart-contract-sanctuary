pragma solidity ^0.4.24;

contract PixelFactory {
    address public contractOwner;
    uint    public startPrice = 0.1 ether;
    bool    public isInGame = false;
    uint    public finishTime;
    
    uint    public lastWinnerId;
    address public lastWinnerAddress;

    constructor() public {
        contractOwner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == contractOwner);
        _;
    }

    struct Pixel {
        uint price;
    }

    Pixel[] public pixels;

    mapping(uint => address) pixelToOwner;
    mapping(address => string) ownerToUsername;

    /** ACCOUNT FUNCTIONS **/
    event Username(string username);
    
    function setUsername(string username) public {
        ownerToUsername[msg.sender] = username;
        emit Username(username);
    }
    
    function getUsername() public view returns(string) {
        return ownerToUsername[msg.sender];
    }

    /** GAME FUNCTIONS **/
    // this function is triggered manually by owner after all pixels sold
    function startGame() public onlyOwner {
        require(isInGame == false);
        isInGame = true;
        finishTime = 86400 + now;
    }
    
    function sendOwnerCommission() public payable onlyOwner {
        contractOwner.transfer(msg.value);
    } 
     
    function _sendWinnerJackpot(address winner) private {
        uint jackpot = 10 ether;
        winner.transfer(jackpot);
    } 
    
    // this function is called to calculate countdown on the front side
    function getFinishTime() public view returns(uint) {
        return finishTime;
    }
    
    function getLastWinner() public view returns(uint id, address addr) {
        id = lastWinnerId;
        addr = lastWinnerAddress;
    }
    
    function _rand(uint min, uint max) private view returns(uint) {
        return uint(keccak256(abi.encodePacked(now)))%(min+max)-min;
    }
    
    // this function is triggered manually by owner to finish game after countdown stops
    function finisGame() public onlyOwner {
        require(isInGame == true);
        isInGame = false;
        finishTime = 0;

        // get winner id
        uint winnerId = _rand(0, 399);
        lastWinnerId = winnerId;
        
        // get winner address
        address winnerAddress = pixelToOwner[winnerId];
        lastWinnerAddress = winnerAddress;
        
        // transfer jackpot amount to winner
        _sendWinnerJackpot(winnerAddress);
        
        // reset pixels
        delete pixels;
    }
    
    /** PIXEL FUNCTIONS **/
    function createPixels(uint amount) public onlyOwner {
        // it can be max 400 pixels
        require(pixels.length + amount <= 400);
        
        // P.S. creating 400 pixels in one time is costing too much gas that&#39;s why we are using amount
        
        // system is creating pixels
        for(uint i=0; i<amount; i++) {
            uint id = pixels.push(Pixel(startPrice)) - 1;
            pixelToOwner[id] = msg.sender;
        }
    }

    function getAllPixels() public view returns(uint[], uint[], address[]) {
        uint[]    memory id           = new uint[](pixels.length);
        uint[]    memory price        = new uint[](pixels.length);
        address[] memory owner        = new address[](pixels.length);

        for (uint i = 0; i < pixels.length; i++) {
            Pixel storage pixel = pixels[i];
            
            id[i]           = i;
            price[i]        = pixel.price;
            owner[i]        = pixelToOwner[i];
        }

        return (id, price, owner);
    }

    function _checkPixelIdExists(uint id) private constant returns(bool) {
        if(id < pixels.length) return true;
        return false;
    }

    function _transfer(address to, uint id) private {
        pixelToOwner[id] = to;
    }

    function buy(uint id) external payable {
        // checking pixel id exists before buying
        require(_checkPixelIdExists(id) == true);

        // preparing pixel data
        Pixel storage pixel = pixels[id];
        uint currentPrice = pixel.price;
        address currentOwner = pixelToOwner[id];
        address newOwner = msg.sender;
        
        // cheking buyer is sending correct price for pixel
        require(currentPrice == msg.value);
        
        // cheking buyer is not at the same time owner of pixel 
        require(currentOwner != msg.sender);

        // calculating new price of pixel
        uint newPrice = currentPrice * 2;
        pixel.price = newPrice;

        // transfering money to current owner if current is not contractOwner, otherweise pot is collected in contract address
        if(currentOwner != contractOwner) {
            currentOwner.transfer(msg.value);
        }
        
        // transfering pixel to new owner
        _transfer(newOwner, id);
    }
}