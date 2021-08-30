// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";

contract PlayCards is ERC721, Ownable {

    string private _baseTokenURI;
    uint256 public _totalSupply;
    uint256 public _initialValue;

    mapping(address => uint256) public earnings;


    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        uint256 totalSupply
    ) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;
        _totalSupply = totalSupply;
    }


    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }


    function _beforeTokenTransfer(uint256 tokenId) internal virtual override {
        require(tokenId <= _totalSupply, "there are only 54 play cards!");
    }

    function mint(address to, uint256 tokenId) public onlyOwner{
        _safeMint(to, tokenId);
    }

    function setInitialValue(uint256 initialValue_) public onlyOwner {
        _initialValue = initialValue_;
    }


    function getCard(uint256 tokenId) public payable{
        require(msg.value >= _initialValue, "you have to pay at least equal to existing initial value");
        _safeMint(_msgSender(), tokenId);
        earnings[owner()] += msg.value;
    }

    function withdraw() public onlyOwner {
        uint256 amount = earnings[_msgSender()];
        earnings[_msgSender()] = 0;
        address payable reciever = payable(_msgSender());
        reciever.transfer(amount);
    }
}