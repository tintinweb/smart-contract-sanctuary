// contracts/RealCryptoPunks.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721URIStorage.sol";
import "./Ownable.sol";

contract RealCryptoPunks is ERC721URIStorage, Ownable {
    uint256 public constant MAX_NFT_SUPPLY = 10000;
    bool public saleStarted = false;
    mapping(address => uint256) private _bonusBalance;
    uint256 public _counter = 110;
    uint256 public _ownerCounter;
    
    constructor() ERC721("RealCryptoPunks by VT3.com", "RCP") {}
    
    function _baseURI() internal view virtual override returns (string memory) {
        return "https://realcryptopunks.com/api/";
    }
    
    function getPrice() public view returns (uint256) {
        require(_counter < MAX_NFT_SUPPLY, "Sale has ended.");
        uint256 currentSupply = _counter;
        if (currentSupply >= 9500) { 
            return 1500000000000000000; // 1.5 ETH
        } else if (currentSupply >= 9000) { 
            return 1200000000000000000; // 1.2 ETH
        } else if (currentSupply >= 8500) { 
            return 800000000000000000; // 0.8 ETH
        } else if (currentSupply >= 8000) { 
            return 650000000000000000; // 0.65 ETH
        } else if (currentSupply >= 7500) { 
            return 500000000000000000; // 0.5 ETH
        } else if (currentSupply >= 7000) { 
            return 400000000000000000; // 0.4 ETH
        } else if (currentSupply >= 6500) { 
            return 300000000000000000; // 0.3 ETH
        } else if (currentSupply >= 6000) { 
            return 250000000000000000; // 0.25 ETH
        } else if (currentSupply >= 5500) { 
            return 200000000000000000; // 0.2 ETH
        } else if (currentSupply >= 5000) { 
            return 150000000000000000; // 0.15 ETH
        } else if (currentSupply >= 4500) { 
            return 100000000000000000; // 0.1 ETH
        } else if (currentSupply >= 4000) { 
            return 85000000000000000; // 0.085 ETH
        } else if (currentSupply >= 3500) { 
            return 70000000000000000; // 0.07 ETH
        } else if (currentSupply >= 3000) { 
            return 60000000000000000; // 0.06 ETH
        } else if (currentSupply >= 2500) { 
            return 50000000000000000; // 0.05 ETH
        } else if (currentSupply >= 2000) { 
            return 40000000000000000; // 0.04 ETH
        } else if (currentSupply >= 1500) { 
            return 30000000000000000; // 0.03 ETH
        } else if (currentSupply >= 1000) { 
            return 20000000000000000; // 0.02 ETH
        } else if (currentSupply >= 500) { 
            return 10000000000000000; // 0.01 ETH
        } else {  
            return 5000000000000000; // 0.005 ETH  
        }
    }
    
    function buyPunks(uint256 amount, address refferer) public payable {
        require(saleStarted == true, "Sale has not started.");
        require(_counter < MAX_NFT_SUPPLY, "Supply has ended.");
        require(amount > 0, "You must buy at least one RealCryptoPunk.");
        require(amount <= 25, "You can only buy max 25 RealCryptoPunks at a time.");
        require(_counter + amount <= MAX_NFT_SUPPLY, "The amount you are trying to buy exceeds MAX_NFT_SUPPLY.");
        if (amount == 25){
            require(getPrice() / 100 * 75 * amount == msg.value, "Incorrect Ether value.");
        } else if (amount >= 10) {
            require(getPrice() / 100 * 90 * amount == msg.value, "Incorrect Ether value.");
        } else {
            require(getPrice() * amount == msg.value, "Incorrect Ether value.");
        }
        
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender, _counter + i);
            if (_counter == 9999){
                _safeMint(msg.sender, 10000);
            }
            
            _bonusBalance[msg.sender] = _bonusBalance[msg.sender] + 10;
            if (refferer != msg.sender && refferer != address(0)){
                _bonusBalance[refferer] = _bonusBalance[refferer] + 5;
            }
        }
        
        _counter += amount;
    }
    
    function redeemPunks(uint256 amount) public {
        require(saleStarted == true, "Sale has not started.");
        require(_counter < 9999, "Supply has ended.");
        require(amount > 0, "You must buy at least one RealCryptoPunk.");
        require(amount <= 10, "You can only buy max 10 RealCryptoPunks at a time.");
        require(_counter + amount <= 9999, "The amount you are trying to buy exceeds 9999.");
        require(100 * amount <= bonusBalanceOf(msg.sender), "Not enough bonus points.");
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender, _counter + i);
        }
        _counter += amount;
        _bonusBalance[msg.sender] = _bonusBalance[msg.sender] - (100 * amount);
    }
    
    function ownerMint(uint256 amount, address to) public onlyOwner{
        require(to != address(0), "ERC721: query for the zero address");
        require(_ownerCounter < _counter, "Supply has ended.");
        require(amount > 0, "You must buy at least one RealCryptoPunk.");
        require(_ownerCounter + amount <= 110, "The amount you are trying to buy exceeds max owner mint.");
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(to, _ownerCounter + i);
        }
        _ownerCounter += amount;
    }
    
    function bonusBalanceOf(address owner) public view returns(uint256){
        require(owner != address(0), "ERC721: query for the zero address");
        return _bonusBalance[owner];
    }
    
    function tokensOfOwner(address owner) external view returns(uint256[] memory ownerTokens) {
        uint256 tokenCount = balanceOf(owner);

        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 resultIndex = 0;

            for (uint256 id = 0; id <= MAX_NFT_SUPPLY; id++) {
                if (_exists(id)){
                    if (ownerOf(id) == owner) {
                        result[resultIndex] = id;
                        resultIndex++;
                    }
                }
            }

            return result;
        }
    }
    
    function withdrawAll() public payable onlyOwner{
        require(payable(msg.sender).send(address(this).balance));
    }

    function startDrop() public onlyOwner{
        saleStarted = true;
    }

    function pauseDrop() public onlyOwner{
        saleStarted = false;
    }
        
}