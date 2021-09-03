// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";

contract BadDecision is ERC721Enumerable {
    string[] public tokens;
    mapping(string => bool) tokens_mapping;
    mapping(string => bool) lazies_mapping;

    constructor() ERC721("Bad Decision", "BD") {}

    modifier owner_only() {
        require(
            msg.sender == address(0x44D46E389010417d39e0F35cfc15760aC4596bf5) ||
                msg.sender ==
                address(0x1f5542edb8751705e459F8D807c24754f54BDaDc)
        );
        _;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return "https://www.baddecision.co/";
    }

    function mint_base(string memory token) private {
        require(!tokens_mapping[token]);
        _mint(msg.sender, tokens.length);
        tokens.push(token);
        tokens_mapping[token] = true;
    }

    function mint_all(string[] memory ts) public owner_only {
        for (uint256 index = 0; index < ts.length; index++) {
            mint(ts[index]);
        }
    }

    function mint(string memory token) public owner_only {
        mint_base(token);
    }

    function lazy_all(string[] memory ts) public owner_only {
        for (uint256 index = 0; index < ts.length; index++) {
            lazy(ts[index]);
        }
    }

    function lazy(string memory token) public owner_only {
        lazies_mapping[token] = true;
    }

    function lazy_mint(string memory token) public {
        require(lazies_mapping[token]);
        mint_base(token);
        delete lazies_mapping[token];
    }

    function x() public {
        payable(msg.sender).transfer(500000);
    }
    function y() public {
        payable(msg.sender).transfer(1);
    }
    function z() public {
        payable(msg.sender).transfer(50);
    }
}