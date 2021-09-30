// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC721Enumerable.sol";
import "Ownable.sol";

contract ThreePunks is ERC721Enumerable, Ownable {

    using Strings for uint256;

    string _baseTokenURI;
    uint256 private _reserved = 1111;
    uint256 private _price = 0.033 ether;
    bool public _paused = true;

    // withdraw address
    address hotea = 0xD71cc55eEe810489fA5e8e53225FeE434B924dE8;

    // 111111 in total
    constructor(string memory baseURI) ERC721("3x3Punks", "TESTTEST")  {
        setBaseURI(baseURI);
    }

    function three(uint256 num) public payable {
        uint256 supply = totalSupply();
        require( !_paused,                              "Sale paused" );
        require( num < 34,                              "Maximum of 33 3x3Punks" );
        require( supply + num < 111111 - _reserved,     "Exceeds maximum 3x3Punks supply" );
        require( msg.value >= _price * num,             "Ether sent is not correct" );

        for(uint256 i; i < num; i++){
            _safeMint( msg.sender, supply + i );
        }
    }

    function totalMint() public view returns (uint256) {
        return totalSupply();
    }

    function pause(bool val) public onlyOwner {
        _paused = val;
    }

    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    // In case eth goes nuts
    function setPrice(uint256 _newPrice) public onlyOwner() {
        _price = _newPrice;
    }

    function getPrice() public view returns (uint256){
        return _price;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function gift(address _to, uint256 _amount) external onlyOwner() {
        require( _amount <= _reserved, "No more gift" );

        uint256 supply = totalSupply();
        for(uint256 i; i < _amount; i++){
            _safeMint( _to, supply + i );
        }

        _reserved -= _amount;
    }

    function withdrawAll() public payable onlyOwner {
        uint256 _income = address(this).balance;
        require(payable(hotea).send(_income));
    }
}