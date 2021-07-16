// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./ERC721.sol";
import "./Ownable.sol";

contract FullNFT is ERC721Enumerable, Ownable {

    string public baseURI = "";
    uint public supplyLimit = 10000;
    uint public tokenPrice = 400000000000000000; // 0.4 ether
    uint public buyLimitPerAccount = 20;
    bool public salesEnabled = true;
    uint public useVoucherDeadline = 1627743600000;
    uint public freeTokensLeft = 2500;
    
    uint public startingIndex = 0; // Map token to monkey
    bool public startingIndexIsSet = false;
    
    mapping(address => uint8) public buyCount;
    mapping(uint => bool) public monkeyVoucherUsed;
    mapping(uint => bool) public dogVoucherUsed;
    mapping(uint => bool) public pickleVoucherUsed;
    
    IERC721Enumerable public monkeyVoucherToken;
    IERC721Enumerable public dogVoucherToken;
    IERC721Enumerable public pickleVoucherToken;

    constructor(string memory initialBaseURI, IERC721Enumerable monkeyToken, IERC721Enumerable dogToken, IERC721Enumerable pickleToken) ERC721("DuckDuckB Token", "DDBNFT") {
        baseURI = initialBaseURI;
        monkeyVoucherToken = monkeyToken;
        dogVoucherToken = dogToken;
        pickleVoucherToken = pickleToken;
        
        // Reserve first 30 tokens to contract owner
        for (uint i = 0; i < 30; i++) {
            super._mint(msg.sender, totalSupply());
        }
    }
    
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function setUseVoucherDeadline(uint newUseVoucherDeadline) public onlyOwner {
        useVoucherDeadline = newUseVoucherDeadline;
    }

    function setFreeTokensLeft(uint newFreeTokensLeft) public onlyOwner {
        freeTokensLeft = newFreeTokensLeft;
    }

    function toggleSalesEnabled() public onlyOwner {
        salesEnabled = !salesEnabled;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    
    /*
    function mintMultiple(address[] memory to, uint256[] memory tokenId) public onlyOwner returns (bool) {
        require(super.totalSupply() + to.length <= supplyLimit);
        for (uint i = 0; i < to.length; i++) {
            _mint(to[i], tokenId[i]);
        }
        return true;
    }
    */
    
    function mintTokens(uint8 numberOfTokens) public payable {
        require(salesEnabled, 'Unable to buy tokens now');
        require((buyCount[msg.sender] + numberOfTokens) <= buyLimitPerAccount, 'Exceed buy limit');
        require(totalSupply() + numberOfTokens <= supplyLimit, 'Exceeds supply limit');
        require(msg.value >= numberOfTokens * tokenPrice, 'Not enough money');
        
        buyCount[msg.sender] = buyCount[msg.sender] + numberOfTokens;

        for (uint i = 0; i < numberOfTokens; i++) {
            super._mint(msg.sender, totalSupply());
        }
    }
    
    function withdraw() public onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
    
    /*
    function reserveTokens() public onlyOwner {
        require(totalSupply() + 20 <= supplyLimit, 'Exceeds supply limit');
        require((buyCount[msg.sender] + 20) <= buyLimitPerAccount, 'Exceeds buy limit');

        buyCount[msg.sender] = buyCount[msg.sender] + 20;

        for (uint i = 0; i < 20; i++) {
            super._mint(msg.sender, totalSupply());
        }
    }
    */
    
    function getAllTokensBelongToUser(address user) public view returns (uint[] memory tokens) {
        uint ownedCount = balanceOf(user);
        tokens = new uint[](ownedCount);
        for (uint i = 0 ; i < ownedCount; i++) {
            tokens[i] = tokenOfOwnerByIndex(user, i);
        }
    }

    function getUserBuyCount(address user) public view returns (uint8) {
        return buyCount[user];
    }
    
    function getUnusedMonkeyVouchers(address user) public view returns (uint[] memory filteredVouchers) {
        uint userBalance = monkeyVoucherToken.balanceOf(user);
        if (userBalance > 0) {
            uint[] memory vouchers = new uint[](userBalance);
            uint counter;
            uint tmp;
            
            for (uint i = 0; i < userBalance; i++) {
                tmp = monkeyVoucherToken.tokenOfOwnerByIndex(user, i);
                if (!monkeyVoucherUsed[tmp]) {
                    vouchers[counter] = tmp;
                    counter = counter + 1;
                }
            }
            
            filteredVouchers = new uint[](counter);
            for (uint i = 0; i < counter; i++) {
                filteredVouchers[i] = vouchers[i];
            }
        }
    }

    function getUnusedDogVouchers(address user) public view returns (uint[] memory filteredVouchers) {
        uint userBalance = dogVoucherToken.balanceOf(user);
        if (userBalance > 0) {
            uint[] memory vouchers = new uint[](userBalance);
            uint counter;
            uint tmp;
            
            for (uint i = 0; i < userBalance; i++) {
                tmp = dogVoucherToken.tokenOfOwnerByIndex(user, i);
                if (!dogVoucherUsed[tmp]) {
                    vouchers[counter] = tmp;
                    counter = counter + 1;
                }
            }
            
            filteredVouchers = new uint[](counter);
            for (uint i = 0; i < counter; i++) {
                filteredVouchers[i] = vouchers[i];
            }
        }
    }

    function getUnusedPickleVouchers(address user) public view returns (uint[] memory filteredVouchers) {
        uint userBalance = pickleVoucherToken.balanceOf(user);
        if (userBalance > 0) {
            uint[] memory vouchers = new uint[](userBalance);
            uint counter;
            uint tmp;

            for (uint i = 0; i < userBalance; i++) {
                tmp = pickleVoucherToken.tokenOfOwnerByIndex(user, i);
                if (!pickleVoucherUsed[tmp]) {
                    vouchers[counter] = tmp;
                    counter = counter + 1;
                }
            }
            
            filteredVouchers = new uint[](counter);
            for (uint i = 0; i < counter; i++) {
                filteredVouchers[i] = vouchers[i];
            }
        }
    }
    
    function claimFreeTokensByMonkey() public returns (uint) {
        require(block.timestamp < useVoucherDeadline, 'Unable to get free tokens now');
        uint[] memory vouchers = getUnusedMonkeyVouchers(msg.sender);

        uint tokenClaimed = 0;
        
        for (uint i = 0; i < vouchers.length; i++) {
            if ((totalSupply() < supplyLimit) && (freeTokensLeft > 0)) {
                monkeyVoucherUsed[vouchers[i]] = true;
                freeTokensLeft = freeTokensLeft - 1;
                tokenClaimed = tokenClaimed + 1;
                super._mint(msg.sender, totalSupply());
            }
        }
        return tokenClaimed;
    }
    
    function claimFreeTokensByDog() public returns (uint) {
        require(block.timestamp < useVoucherDeadline, 'Unable to get free tokens now');
        uint[] memory vouchers = getUnusedDogVouchers(msg.sender);

        uint tokenClaimed = 0;

        for (uint i = 0; i < vouchers.length; i++) {
            if ((totalSupply() < supplyLimit) && (freeTokensLeft > 0)) {
                dogVoucherUsed[vouchers[i]] = true;
                freeTokensLeft = freeTokensLeft - 1;
                tokenClaimed = tokenClaimed + 1;
                super._mint(msg.sender, totalSupply());
            }
        } 
        return tokenClaimed;
    }
    
    function claimFreeTokensByPickle() public returns (uint) {
        require(block.timestamp < useVoucherDeadline, 'Unable to get free tokens now');
        uint[] memory vouchers = getUnusedPickleVouchers(msg.sender);

        uint tokenClaimed = 0;

        for (uint i = 0; i < vouchers.length; i++) {
            if ((totalSupply() < supplyLimit) && (freeTokensLeft > 0)) {
                pickleVoucherUsed[vouchers[i]] = true;
                freeTokensLeft = freeTokensLeft - 1;
                tokenClaimed = tokenClaimed + 1;
                super._mint(msg.sender, totalSupply());
            }
        } 
        return tokenClaimed;
    }
    
    function claimFreeTokens() public returns (uint) {
        return claimFreeTokensByMonkey() + claimFreeTokensByDog() + claimFreeTokensByPickle();
    }
    
    function setStartingIndex() public onlyOwner {
        require(startingIndexIsSet == false, "Starting index is already set");
        require(totalSupply() == supplyLimit || salesEnabled == false, "Can't reveal starting index now");
        // Random number generation
        startingIndex = uint(keccak256(abi.encode(blockhash(block.number - 1), totalSupply(), freeTokensLeft, block.timestamp, block.difficulty))) % supplyLimit;
        startingIndexIsSet = true;
    }
}