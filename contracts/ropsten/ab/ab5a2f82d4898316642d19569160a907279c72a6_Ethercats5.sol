// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract Ethercats5 is ERC721Enumerable, Ownable {
    uint public constant MAX_CATS = 10;
	string _baseTokenURI = "https://api.ethercats5.io/";
	bool public paused = true;

    constructor(address _to, uint _count) ERC721("Ethercats5", "ECATS5")  {
        for(uint i = 0; i < _count; i++){
            _safeMint(_to, totalSupply());
        }
    }

    function mintCats(address _to, uint _count) public payable {
        require(!paused, "Pause");
        require(_count <= 2, "Exceeds 2");
        require(msg.value >= price(_count), "Value below price");
        require(totalSupply() + _count <= MAX_CATS, "Max limit");
        require(totalSupply() < MAX_CATS, "Sale end");

        for(uint i = 0; i < _count; i++){
            _safeMint(_to, totalSupply());
        }
    }
    
    function price(uint _count) public pure returns (uint256) {
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
        require(payable(msg.sender).send(address(this).balance));
    }

}