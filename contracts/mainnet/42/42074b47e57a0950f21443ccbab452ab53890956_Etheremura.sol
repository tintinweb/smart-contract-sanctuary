// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract Etheremura is ERC721Enumerable, Ownable {
    uint public constant MAX_SAMURAI = 9888;
    uint _reservedForVT3 = 450;
	string _baseTokenURI = "https://api.etheremura.io/";
	bool public paused = true;
	
	 // withdraw addresses
    address address1 = 0x0712b7151b557CBb8BCe4A9390186A64b34FEbED;
    address address2 = 0xd6DB94763588f0E608370ba2EEbCE4836731E4D1;

    constructor(address _to, uint _count) ERC721("Etheremura", "SAMURAI")  {
        for(uint i = 0; i < _count; i++){
            _safeMint(_to, totalSupply());
        }
    }

    function mintSamurai(address _to, uint _count) public payable {
        require(!paused, "Pause");
        require(_count <= 20, "Exceeds 20");
        require(msg.value >= price(_count), "Value below price");
        require(totalSupply() + _count <= MAX_SAMURAI, "Max limit");
        require(totalSupply() < MAX_SAMURAI, "Sale end");

        for(uint i = 0; i < _count; i++){
            _safeMint(_to, totalSupply());
        }
    }
    
    function vt3PoolReserve(address _to, uint _count) public onlyOwner{
        require(totalSupply() + _count <= MAX_SAMURAI, "Max limit");
        require(_reservedForVT3 != 0, "Max limit reserved");
        require(_reservedForVT3 >= _count, "Max limit reserved");
        require(totalSupply() < MAX_SAMURAI, "Sale end");

        for(uint i = 0; i < _count; i++){
            _safeMint(_to, totalSupply());
        }
        
        _reservedForVT3 = _reservedForVT3 - _count;
    }
    
    function price(uint _count) public view returns (uint256) {
        return _count * 80000000000000000;
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function walletOfOwner(address _owner) external view returns(uint256[] memory) {
        uint tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint i = 0; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }
    
    function pause(bool val) public onlyOwner {
        paused = val;
    }

    function withdrawAll() public payable onlyOwner {
        uint256 address1_balance = address(this).balance / 100 * 40;
        uint256 address2_balance = address(this).balance / 100 * 60;
        require(payable(address1).send(address1_balance));
        require(payable(address2).send(address2_balance));
    }
}