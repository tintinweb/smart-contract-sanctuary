// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract HedgehogsInSocks is ERC721Enumerable, Ownable {
    uint public constant MAX_HEDGEHOGS = 7777;
	string _baseTokenURI = "https://api.hedgehogsinsocks.com/";
	bool public paused = true;
	uint[7] public happyHedgehogs = [0,0,0,0,0,0,0];

    constructor() ERC721("HedgehogsInSocks", "HEDGEHOGS")  {
        for(uint i = 0; i < 77; i++){
            _safeMint(_msgSender(), totalSupply());
        }
    }

    function mintHedgehogs(address _to, uint _count) public payable {
        if(msg.sender != owner()){
            require(!paused, "Pause");
        }
        require(totalSupply() + _count <= MAX_HEDGEHOGS, "Max limit");
        require(totalSupply() < MAX_HEDGEHOGS, "Sale end");
        if(totalSupply() <= 854 ){
            require(_count <= 3, "Exceeds 3");
        }else{
            require(_count <= 20, "Exceeds 20");
        }
        require(msg.value >= price(_count), "Value below price");

        for(uint i = 0; i < _count; i++){
            _safeMint(_to, totalSupply());
        }
    }

    function price(uint _count) public view returns (uint256) {
        if(totalSupply() <= 777 ){
            return 0; // free 777
        }else{
            return 21000000000000000 * _count; // 0.021 ETH
        }
    }
    
    function selectHappyHedgehogs(uint _index) public onlyOwner {
        require(MAX_HEDGEHOGS == totalSupply() , "Sale not end");
        require(happyHedgehogs[_index] == 0, "Already selected");
        uint256 max = MAX_HEDGEHOGS - 1;
        uint256 randomHash = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)));
        randomHash = randomHash % max;
        address _happyOwner = ownerOf(randomHash);
        require(payable(_happyOwner).send(3300000000000000000));
        happyHedgehogs[_index] = randomHash;
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
        require(payable(_msgSender()).send(address(this).balance));
    }
}