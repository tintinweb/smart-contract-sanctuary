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
    bool public useVoucherEnabled = true;
    
    mapping(address => uint8) public buyCount;
    mapping(uint => bool) public voucherUsed;
    
    IERC721Enumerable public voucherToken;

    constructor(string memory initialBaseURI, IERC721Enumerable token) ERC721("Plupppppy Token", "PPPNFT") {
        baseURI = initialBaseURI;
        voucherToken = token;
    }

    /*
    function mint(address _to, uint256 _tokenId) external onlyOwner {
        require(super.totalSupply() + 1 <= supplyLimit);
        super._mint(_to, _tokenId);
    }
    */
    
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function toggleSalesEnabled() public onlyOwner {
        salesEnabled = !salesEnabled;
    }

    function toggleUseVoucherEnabled() public onlyOwner {
        useVoucherEnabled = !useVoucherEnabled;
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
    
    function reserveTokens() public onlyOwner {
        require(totalSupply() + 20 <= supplyLimit, 'Exceeds supply limit');
        require((buyCount[msg.sender] + 20) <= buyLimitPerAccount, 'Exceeds buy limit');

        buyCount[msg.sender] = buyCount[msg.sender] + 20;

        for (uint i = 0; i < 20; i++) {
            super._mint(msg.sender, totalSupply());
        }
    }
    
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
    
    function getVouchers(address user) public view returns (uint[] memory vouchers) {
        uint userBalance = voucherToken.balanceOf(user);
        require(userBalance > 0, 'No vouchers');
        vouchers = new uint[](userBalance);
        
        for (uint i = 0; i < userBalance; i++) {
            vouchers[i] = voucherToken.tokenOfOwnerByIndex(user, i);
        }
    }
    
    function claimFreeTokens() public {
        require(useVoucherEnabled, 'Unable to get free tokens now');
        uint[] memory vouchers = getVouchers(msg.sender);

        for (uint i = 0; i < vouchers.length; i++) {
            if (!voucherUsed[vouchers[i]] && totalSupply() < supplyLimit) {
                voucherUsed[vouchers[i]] = true;
                super._mint(msg.sender, totalSupply());
            }
        } 
    }
}