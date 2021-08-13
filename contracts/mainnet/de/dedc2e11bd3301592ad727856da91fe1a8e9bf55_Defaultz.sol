pragma solidity 0.8.6;

// SPDX-License-Identifier: MIT

import "./ERC721.sol";
import "./ERC721Burnable.sol";
import "./Counters.sol";

contract Defaultz is ERC721, ERC721Burnable {
    using Counters for Counters.Counter;

    mapping(address => bool) isAdmin;
    uint public totalSupply;
    uint public saleStart;

    uint private basePrice;
    string private baseURI;
    Counters.Counter public tokensCreated;

    constructor() ERC721("Defaultz", "DFT") {
        isAdmin[msg.sender] = true;
        totalSupply = 5555;
        basePrice = 1e16; // 0.01 ETH
        baseURI = "https://api.defaultz.club/";
        saleStart = 1628899200;
    }

    function mint(uint _qty) external payable {
        require(_qty > 0 && _qty <= 10, "quantity needs to be between 1-10");
        require(_qty + tokensCreated.current() <= totalSupply, "sold out");
        require(msg.value == _qty * this.currentPrice(), "insufficient payment");
        require(block.timestamp >= saleStart && saleStart != 0, "sale is not started");

        for(uint i = 0; i < _qty; i++) {
            _safeMint(msg.sender, tokensCreated.current());
            tokensCreated.increment();
        }

    }

    modifier onlyAdmin {
        require(isAdmin[msg.sender] == true, "not admin");
        _;
    }

    function addAdmin(address _newAdmin) external onlyAdmin {
        isAdmin[_newAdmin] = true;
    }

    function removeAdmin(address _adminAddress) external onlyAdmin {
        isAdmin[_adminAddress] = false;
    }

    function updateSaleStart(uint _newSaleStart) external onlyAdmin {
        saleStart = _newSaleStart;
    }

    function updateBaseURI(string memory _newURI) external onlyAdmin {
        baseURI = _newURI;
    }

    function withdrawBalance(uint _amount, address _to) external onlyAdmin {
        payable(_to).transfer(_amount);
    }

    // View functions
    function currentPrice() external view returns (uint _price) {
        uint sold = tokensCreated.current();
        uint stage = (sold - (sold % 1000)) / 1000;
        return stage == 0 ? basePrice : basePrice * stage;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

}