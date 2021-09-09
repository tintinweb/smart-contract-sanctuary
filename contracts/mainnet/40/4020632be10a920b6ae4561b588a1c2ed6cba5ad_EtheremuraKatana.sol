// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract EtheremuraKatana is ERC721Enumerable, Ownable{
    uint public constant MAX_NFTS = 9888;
	bool public paused = true;
	string _baseTokenURI = "https://api.etheremura.io/katana/";
	mapping(uint256 => bool) private _samurai;
	MAIN public constant MAIN_CONTRACT = MAIN(0x42074B47E57a0950F21443CCBab452Ab53890956);

    constructor() ERC721("Etheremura Katana", "Katana")  {
        
    }
    
    function mintKatana(address _to, uint _count) public {
        require(!paused, "Pause");
        require(_count <= 20, "Exceeds 20");
        require(totalSupply() + _count <= MAX_NFTS, "Max limit");
        require(totalSupply() < MAX_NFTS, "Sale end");
        require(getAvailableKatanasCount(msg.sender) >= _count, "No available katanas");
        
        uint tokenCount = MAIN_CONTRACT.balanceOf(msg.sender);
        require(tokenCount > 1, "No samurai");
        
        for(uint i = 0; i < tokenCount; i++){
            if(!_samurai[MAIN_CONTRACT.tokenOfOwnerByIndex(msg.sender, i)] && _count > 0){
                _samurai[MAIN_CONTRACT.tokenOfOwnerByIndex(msg.sender, i)] = true;
                _safeMint(_to, totalSupply());
                _count = _count - 1;
            }
        }
        
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
    
    function getAvailableKatanasCount(address _owner) public view returns(uint256) {
        uint tokenCount = MAIN_CONTRACT.balanceOf(_owner);
        uint256 _count;
        for(uint i = 0; i < tokenCount; i++){
            if(!_samurai[MAIN_CONTRACT.tokenOfOwnerByIndex(msg.sender, i)]){
                _count = _count + 1;
            }
        }
        return _count;
    }
    
    function isKatanaMinter(uint256 _tokenId) public view returns(bool) {
        return _samurai[_tokenId]; 
    }
    
    function pause(bool val) public onlyOwner {
        paused = val;
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
    
}

interface MAIN{
    function balanceOf(address account) external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}