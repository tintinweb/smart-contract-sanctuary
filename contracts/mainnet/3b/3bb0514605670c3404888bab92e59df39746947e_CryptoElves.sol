// SPDX-License-Identifier: UNNLICENSED
pragma solidity 0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./ReentrancyGuard.sol";
contract CryptoElves is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    
    // Starts at 0 
    Counters.Counter ID;

    // Max supply 
    uint256 maxSupply = 5000;

    // Price Per Elf
    uint256 public price;
    uint256 public whitelistPrice;
    
    // The address to receive payment from sales
    address payable payee1; // Receives 80% of primary sales
    address payable payee2; // Receives 10% of primary sales
    address payable payee3; // Receives 10% of primary sales
    
    // Event to emit upon purchase 
    event mint(uint256 id, address mintFrom, address mintTo);
    

    // whitelist mapping
    mapping(address => bool) public whitelisted;

    // Initial NFT drop recipients
    address recipient = 0x5A2441b4f359FC5525a1F21C0aa65510eF96C80C;

    constructor(
        string memory name, 
        string memory symbol, 
        uint256 _price, 
        uint256 _wlPrice,
        address payable _payee1,
        address payable _payee2, 
        address payable _payee3
    ) 
    ERC721(name, symbol) 
    {
        payee1 = _payee1;
        payee2 = _payee2;
        payee3 = _payee3;
        price = _price; 
        whitelistPrice = _wlPrice;
        URI = "https://us-central1-crypto-elves.cloudfunctions.net/get-metadata?tokenid=";
        
        for(uint256 i = 0; i < 50; i++) {
            uint256 currID = Counters.current(ID);

            // Increment ID counter
            Counters.increment(ID);
            
            // Mint NFT to user wallet
            _mint(recipient, currID);
            emit mint(currID, address(this), recipient);
        }
    }
    
    function buy(uint256 amount) public payable nonReentrant {
        require(Counters.current(ID) + amount < maxSupply, "Not enough Elves left");
        if(!whitelisted[_msgSender()]) {
            require(msg.value == price * amount, "Incorrect amount of ETH sent");
            require(amount <= 10, "Maximum 10 per purchase");
        } else {
            require(msg.value == whitelistPrice, "Incorrect amount of ETH sent");
            require(amount >= 1, "Can only buy one at whitelist price");
            whitelisted[_msgSender()] = false;
        }
        
        uint256 tenPC = msg.value / 10;
        uint256 eightyPC = msg.value - (tenPC * 2);

        // Pay payees
        (bool success,) = payee1.call{value: eightyPC}("");
        require(success, "Transfer fail");

        (bool successs,) = payee2.call{value: tenPC}("");
        require(successs, "Transfer fail");

        (bool successss,) = payee3.call{value: tenPC}("");
        require(successss, "Transfer fail");
        
        for(uint256 i = 0; i < amount; i++) {
            uint256 currID = Counters.current(ID);
            
            // Increment ID counter
            Counters.increment(ID);
            
            // Mint NFT to user wallet
            _mint(_msgSender(), currID);
            emit mint(currID, address(this), _msgSender());
        }
    }

    function mintTo(uint amount, address _recipient) public onlyOwner {
        require(Counters.current(ID) + amount < maxSupply, "Not enough Elves left");
        
        for(uint256 i = 0; i < amount; i++) {
                uint256 currID = Counters.current(ID);

                // Increment ID counter
                Counters.increment(ID);
                
                // Mint NFT to user wallet
                _mint(_recipient, currID);
                emit mint(currID, address(this), _recipient);
        }
    }
    
    function changePrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    function changeWLPrice(uint256 newPrice) public onlyOwner {
        whitelistPrice = newPrice;
    }

    function totalSupply() public view returns(uint256) {
        return maxSupply; 
    }

    function changePayee1(address payable newPayee1) public onlyOwner {
        payee1 = newPayee1;
    }

    function changePayee2(address payable newPayee2) public onlyOwner {
        payee2 = newPayee2;
    }

    function changePayee3(address payable newPayee3) public onlyOwner {
        payee3 = newPayee3;
    }

    function withdraw() public onlyOwner{
        (bool success,) = _msgSender().call{value: address(this).balance}("");
        require(success, "Transfer fail");
    }

    function setURI(string memory _uri) public onlyOwner {
        URI = _uri;
    }

    function addToWhitelist(address whitelistedAddress) public onlyOwner {
        whitelisted[whitelistedAddress] = true;
    }
}