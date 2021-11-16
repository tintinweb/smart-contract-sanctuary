// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";


abstract contract ContextMixin {
    function msgSender()
        internal
        view
        returns (address payable sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }
}

/**
 * @title ERC721Tradable
 */
contract yWhales is ContextMixin, ERC721Enumerable, Ownable {
    using SafeMath for uint256;

    address proxyRegistryAddress;
    string public baseURI;
    bool public saleActive;
    
    mapping(address => bool) whitelist;
    uint256 public whitelistedNumber = 0;

    //track who has OG whales
    mapping(address => bool) ogWhalesList;
    
    // holds the Whales
    struct Whale { 
      string name;
      uint256 quantity; // total
      uint256 unsoldQty; 
      uint price; // in  600 
      uint256 whaleId;
      bool transferable;
      bool saleable;
   }
   
    mapping (uint256 => Whale) public Whales;
    uint256 public WhalesStructs;

    //Tokens[tokenId] = whaleId
    mapping (uint256 => uint256) public Tokens;

    constructor() 
        ERC721('YWhales Crystal Poly Whales', "YWhalesPoly") {
        setBaseURI("https://one.ywhales.com/tokens/");
        saleActive = false;
        WhalesStructs = 0;
        addWhale('The YPO Whale', 999, 0, false, true);
        addWhale('The Nick', 50, 600 ether, true, true);
        addWhale('FOMO', 50, 600 ether, true, true);
        addWhale('Stephan', 50, 600 ether, true, true);
        addWhale('Gummy', 5, 600 ether, true, true);
        addWhale('Archie', 50, 600 ether, true, true);
        addWhale('Tupac', 5, 600 ether, true, true);
        addWhale('Bombay', 50, 600 ether, true, true);
        addWhale('Rare Pepe', 25, 600 ether, true, true);
        addWhale('The Rock', 50, 600 ether, true, true);
        addWhale('Ruby', 50, 600 ether, true, true);
        addWhale('Krug Rose', 50, 600 ether, true, true);
        addWhale('Lemon Drop', 50, 600 ether, true, true);
        addWhale('Chilli', 50, 600 ether, true, true);
        addWhale('Nehi', 50, 600 ether, true, true);
        addWhale('Rick', 50, 600 ether, true, true);
        addWhale('Solana', 50, 600 ether, true, true);
        addWhale('DeFi', 50, 600 ether, true, true);
        addWhale('Oz', 50, 600 ether, true, true);
        addWhale('Fendi', 50, 600 ether, true, true);
        addWhale('Hermes', 50, 600 ether, true, true);
        addWhale('Dolce', 50, 600 ether, true, true);
        addWhale('Bvlgari', 50, 600 ether, true, true);
        addWhale('DeFi Degen', 50, 600 ether, true, true);
        addWhale('Angra', 50, 600 ether, true, true);
        addWhale('The 68', 50, 600 ether, true, true);
        addWhale('Tamarillo', 50, 600 ether, true, true);
        addWhale('Barbara', 50, 600 ether, true, true);
        addWhale('David', 25, 600 ether, true, true);
        addWhale('Penny', 50, 600 ether, true, true);
        addWhale('Yin', 50, 600 ether, true, true);
        addWhale('Yang', 50, 600 ether, true, true);
        addWhale('Labyrinth', 50, 600 ether, true, true);
        addWhale('Bling', 50, 600 ether, true, true);
        addWhale('Mordor', 50, 600 ether, true, true);
        addWhale('Krakatoa', 50, 600 ether, true, true);
        addWhale('Topaz', 50, 600 ether, true, true);
        addWhale('Kat', 1, 3000 ether, true, true);
        addWhale('Cassia', 50, 600 ether, true, true);
        addWhale('Euro', 50, 600 ether, true, true);
        addWhale('Iridium', 50, 600 ether, true, true);
        addWhale('Obsidian', 50, 600 ether, true, true);
        addWhale('Blue Check', 50, 600 ether, true, true);
        addWhale('Agean', 50, 600 ether, true, true);
        addWhale('Barney', 50, 600 ether, true, true);
        addWhale('Graphine', 50, 600 ether, true, true);
        addWhale('Honey Baked', 50, 600 ether, true, true);
        addWhale('The Thing', 50, 600 ether, true, true);
        addWhale('The J', 50, 600 ether, true, true);
        addWhale('Stealth', 50, 600 ether, true, true);
        addWhale('Chewy', 50, 600 ether, true, true);
        addWhale('Purple Haze', 50, 600 ether, true, true);
        addWhale('Fruity Pebbles', 50, 600 ether, true, true);
        addWhale('The Man', 50, 600 ether, true, true);
        addWhale('The Yeti', 50, 600 ether, true, true);
        addWhale('Oasis', 50, 600 ether, true, true);
        addWhale('Oasis', 50, 600 ether, true, true);
        addWhale('People Eater', 100, 600 ether, true, false);
        addWhale('Burt', 100, 600 ether, true, false);
        addWhale('Titan', 100, 600 ether, true, false);
        addWhale('Rosey', 100, 600 ether, true, false);
        addWhale('Dreamsicle', 100, 600 ether, true, false);
        addWhale('Brunnera', 100, 600 ether, true, false);
        addWhale('Hypatia', 100, 600 ether, true, false);
    }
    
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        // baseURI + whaleId + .json
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, Strings.toString(Tokens[tokenId]), '.json')) : "";
    }
    
    // owner can add a new type of Whale
    function addWhale(string memory name, uint256 quantity, uint price, bool transferable, bool saleable) public onlyOwner {
        Whale memory whale = Whale(name, quantity, quantity, price, WhalesStructs.add(1), transferable, saleable);
        Whales[WhalesStructs.add(1)] = whale;
        WhalesStructs++;
    }


    // adding burning but onlOwner
    function burn(uint256 tokenId) public onlyOwner {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }


    // owner can add a new type of Whale
    function editWhale(string memory name, uint256 quantity, uint price, bool transferable, uint256 whaleId, bool saleable) public onlyOwner {
        //Whale memory whale = Whale(name, quantity, quanity, price, whaleId, transferable);

        uint soldQty = Whales[whaleId].quantity.sub(Whales[whaleId].unsoldQty);
        require(quantity >= soldQty, 'New quantity must be equal to or greater than quantity already sold.');
        Whales[whaleId].name = name;
        Whales[whaleId].price = price;
        Whales[whaleId].transferable = transferable;
        Whales[whaleId].saleable = saleable;
        Whales[whaleId].unsoldQty = quantity.sub(soldQty);
        Whales[whaleId].quantity = quantity;

    }

    function withdraw() public onlyOwner {
        // withdraw logic
        require(payable(msg.sender).send(address(this).balance));
    }


    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }

    function whitelistAddress(address[] calldata _add) public onlyOwner {
        for (uint i = 0; i < _add.length; i++) {
            whitelist[_add[i]] = true;
            whitelistedNumber++;
        }
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        //whaleId 1 is OG and not transferable
        require(Tokens[tokenId] > 1, 'Whale type not transferable.');
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        //whaleId 1 is OG and not transferable
        require(Tokens[tokenId] > 1, 'Whale type not transferable.');
        safeTransferFrom(from, to, tokenId, "");

    }

    // mint 6 random whales
    function mint6() public payable {
        require(whitelist[msg.sender], "Not whitelisted.");
        require(saleActive==true, "Sale is paused.");
        require(msg.value >= 3000 ether, 'Ether value is below 1ETH price');
        uint j = 0;
        for (uint i =600; i < WhalesStructs; i++) {
            if (Whales[i].saleable == true && Whales[i].unsoldQty > 0) {
                uint nextId = totalSupply().add(1);
                _mint(msg.sender, nextId);
                Tokens[nextId] = i;
                Whales[i].unsoldQty = Whales[i].unsoldQty.sub(1);
                j++;
            }
            if (j==6) {
                break;
            }
        }
    }



    /* public mint
     */
    function mint(uint256 quantity, uint whaleId) public payable {
        // mint whaleId; make sure quantity is avail
        // decrement qty avail   
        require(whitelist[msg.sender], "Not whitelisted.");
        require(saleActive==true, "Sale is paused.");
        require(Whales[whaleId].whaleId > 0, "Collection does not exist.");
        require(msg.value >= Whales[whaleId].price.mul(quantity), 'Ether value is below price');
        require(Whales[whaleId].saleable == true, 'Not for sale.');
        require(Whales[whaleId].unsoldQty.sub(quantity) >= 0, 'Quantity requested exceeds available quantity for sale.');
        require(whaleId > 1 || !ogWhalesList[msg.sender], 'You already own an OG Whale.');
        
        for (uint i = 0; i < quantity; i++) {
            // what is next tokenId
            uint nextId = totalSupply().add(1);
            
            // _mint(to, id, qty, data)
            _mint(msg.sender, nextId);
            
            Tokens[nextId] = whaleId;

            // reduce avail for sale
            Whales[whaleId].unsoldQty = Whales[whaleId].unsoldQty.sub(1);
        }
        
        //if whaleId = 1 (OG), whitelist
        if (whaleId==1 && !whitelist[msg.sender]) {
            whitelist[msg.sender] = true;
            whitelistedNumber++;
            ogWhalesList[msg.sender] = true;
        }
        
    }

        
    /* owner giveaway */    
    function giveaway(uint256 quantity, uint256 whaleId, address to)  onlyOwner public {
        // owner can send any whale to any address without payable
        require(saleActive==true, "Sale is paused.");
        require(Whales[whaleId].whaleId > 0, "Collection does not exist.");
        require(Whales[whaleId].unsoldQty.sub(quantity) >= 0, 'Quantity requested exceeds available quantity for sale.');
        
        for (uint i = 0; i < quantity; i++) {
            // what is next tokenId
            uint nextId = totalSupply().add(1);
            
            // _mint(to, id, qty, data)
            _mint(to, nextId);
            
            // update Cards struct
            Tokens[nextId] = whaleId;

            // reduce avail for sale
            Whales[whaleId].unsoldQty = Whales[whaleId].unsoldQty.sub(1);
            
            // OG whale? whitelist
            if (whaleId==1 && !whitelist[to]){
                whitelist[to] = true;
                whitelistedNumber++;
                ogWhalesList[to] = true;
            }
        }  
            
    }
        

    function toggleSaleActive() public virtual onlyOwner {
        // owner can turn sale on/off
        saleActive = !saleActive;
    }
        

/**
   * Override isApprovedForAll to auto-approve OS's proxy contract
   */
    function isApprovedForAll(
        address _owner,
        address _operator
    ) public override view returns (bool isOperator) {
      // if OpenSea's ERC721 Proxy Address is detected, auto-return true
        if (_operator == address(0x58807baD0B376efc12F5AD86aAc70E78ed67deaE)) {
            return true;
        }
        
        // otherwise, use the default ERC721.isApprovedForAll()
        return ERC721.isApprovedForAll(_owner, _operator);
    }
    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender()
        internal
        override
        view
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }
}

// @busymichael.eth