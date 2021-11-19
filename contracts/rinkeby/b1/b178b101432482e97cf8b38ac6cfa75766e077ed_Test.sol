// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./Ownable.sol";
import "./ERC721EnumerableModified.sol";
import "./Strings.sol";

contract Test is Ownable, ERC721EnumerableModified {
    using Strings for uint256;
    uint256 public MAX_SUPPLY = 10150;

    bool public isActive = false;

    string private _baseTokenURI = "";

    mapping(address => uint256[]) private _balances;

    constructor() ERC721Modified("Basic Test", "TEST") {}

    //external
    fallback() external {}

    function mint(uint256 quantity) external {
        require(isActive, "Sale is not active");

        uint256 supply = totalSupply();
        require(supply + quantity <= MAX_SUPPLY, "Mint/order exceeds supply");
        for (uint256 i = 0; i < quantity; ++i) {
            _safeMint(msg.sender, supply++, "");
        }
    }

    function setActive(bool isActive_) public onlyOwner {
        if (isActive != isActive_) isActive = isActive_;
    }

    function setBaseURI(string calldata _newBaseURI) public onlyOwner {
        _baseTokenURI = _newBaseURI;
    }

    //external owner
    function setMaxSupply(uint256 maxSupply) public onlyOwner {
        if (MAX_SUPPLY != maxSupply) {
            require(
                maxSupply >= totalSupply(),
                "Specified supply is lower than current balance"
            );
            MAX_SUPPLY = maxSupply;
        }
    }

    //public
    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );
        return _balances[owner].length;
    }

    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        virtual
        override
        returns (uint256 tokenId)
    {
        require(
            index < this.balanceOf(owner),
            "ERC721Enumerable: owner index out of bounds"
        );
        return _balances[owner][index];
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return string(abi.encodePacked(_baseTokenURI, tokenId.toString()));
    }

    //internal
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        address zero = address(0);
        if (from != zero || to == zero) {
            //find this token and remove it
            uint256 length = _balances[from].length;
            for (uint256 i; i < length; ++i) {
                if (_balances[from][i] == tokenId) {
                    _balances[from][i] = _balances[from][length - 1];
                    _balances[from].pop();
                    break;
                }
            }
            delete length;
        }

        if (from == zero || to != zero) {
            _balances[to].push(tokenId);
        }
    }
}