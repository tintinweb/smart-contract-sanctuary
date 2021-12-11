// SPDX-License-Identifier: UNNLICENSED
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./ReentrancyGuard.sol";
contract ShitOnAShingle is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    
    // Starts at 0 
    Counters.Counter ID;

    // Max supply 
    uint256 maxSupply = 10000;

    // Price Per Shit
    uint256 public pricePerShit;
    
    // The address to receive payment from sales
    address payable indecent; // 93% primary sales
    address payable bf; // 2% primary sales
    address payable tdb; // 5% primary sales

    // Initial NFT drop recipients
    address[] recipients = [
        0x304d832Beb46C7F2d7Fe5e3A0F65Bc9b7B886297,
        0x912F74C2Cd783cC417537D15cF3F18A9E96225b5,
        0xF4656Ba82Efff6ec0539d74Ee052EB46323B4046,
        0x7F9657Fb7565700Accc192B8e7e608Ad5794850c,
        0xE4508bE47D201847eAb75819740900f662657FAD,
        0x83852F3d50e90A211E37f563161249B44D8Ab5c7,
        0x93b7050eD06B217A4b226edcfc90134Cc7f8A4ce
    ];

    // Event to emit upon purchase 
    event mint(uint256 id, address mintFrom, address mintTo);
    
    constructor(
        string memory name, 
        string memory symbol, 
        uint256 price, 
        address payable _indecent,
        address payable _tdb,
        address payable _bf
    ) 
    ERC721(name, symbol) 
    {
        indecent = _indecent;
        tdb = _tdb;
        bf = _bf;

        URI = "https://us-central1-sos1-333819.cloudfunctions.net/get-ipfs-placeholder?tokenid=";

        pricePerShit = price;
        for(uint k = 0; k < 2; k++) {
            for(uint256 i = 0; i < recipients.length; i++) {
                uint256 currID = Counters.current(ID);

                // Increment ID counter
                Counters.increment(ID);
                
                // Mint NFT to user wallet
                _mint(recipients[i], currID);
                emit mint(currID, address(this), recipients[i]);
            }
        }
    }

    function mintTo(uint amount, address recipient) public onlyOwner {
        require(Counters.current(ID) + amount < maxSupply, "Not enough Shits left");
        
        for(uint256 i = 0; i < amount; i++) {
                uint256 currID = Counters.current(ID);

                // Increment ID counter
                Counters.increment(ID);
                
                // Mint NFT to user wallet
                _mint(recipient, currID);
                emit mint(currID, address(this), recipient);
        }
    }
    
    function buy(uint256 amount) public payable nonReentrant {
        require(Counters.current(ID) + amount < maxSupply, "Not enough Shits left");
        require(msg.value == pricePerShit * amount, "Incorrect amount of ETH sent");
        require(amount <= 10, "Maximum 10 per purchase");
        require(amount > 0, "Can't buy 0 shits");
        
        uint256 onePC = msg.value / 100;
        uint256 ninetyThreePC = (93 * onePC);
        uint256 fivePC = (5 * onePC);
        uint256 twoPC = (2 * onePC);

        // Pay payee
        (bool success,) = indecent.call{value: ninetyThreePC}("");
        require(success, "Transfer fail");

        (bool success3,) = tdb.call{value: fivePC}("");
        require(success3, "Transfer fail");

        (bool success2,) = bf.call{value: twoPC}("");
        require(success2, "Transfer fail");
        
        for(uint256 i = 0; i < amount; i++) {
            uint256 currID = Counters.current(ID);
            
            // Increment ID counter
            Counters.increment(ID);
            
            // Mint NFT to user wallet
            _mint(_msgSender(), currID);
            emit mint(currID, address(this), _msgSender());
        }
    }
    
    function changePrice(uint256 newPrice) public onlyOwner {
        pricePerShit = newPrice;
    }
    // Returns the current amount of NFTs minted
    function totalSupply() public view returns(uint256) {
        return maxSupply;
    }

    function changeIndecent(address payable newIndecent) public onlyOwner {
        indecent = newIndecent;
    }

    function changeBF(address payable newBF) public onlyOwner {
        bf = newBF;
    }

    function changeTDB(address payable newAddress) public onlyOwner {
        tdb = newAddress;
    }

    function withdraw() public onlyOwner{
        (bool success,) = _msgSender().call{value: address(this).balance}("");
        require(success, "Transfer fail");
    }

    function setURI(string memory _uri) public onlyOwner {
        URI = _uri;
    }
}