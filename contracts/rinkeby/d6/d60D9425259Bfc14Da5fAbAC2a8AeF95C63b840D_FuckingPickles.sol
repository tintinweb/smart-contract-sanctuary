// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract FuckingPickles is ERC721Enumerable, Ownable {
    uint public constant MAX_PICKLES = 10000;
	string _baseTokenURI;
	bool public paused = true;

    uint256 goldenPickle = 0;

    // Truth.　
    constructor(string memory baseURI) ERC721("FuckingPickles", "FUCKINGPICKLES")  {
        setBaseURI(baseURI);
    }

    modifier saleIsOpen{
        require(totalSupply() < MAX_PICKLES, "Sale end");
        _;
    }

    function mintMyPickle(address _to, uint _count) public payable saleIsOpen {
        if(msg.sender != owner()){
            require(!paused, "Pause");
        }
        require(totalSupply() + _count <= MAX_PICKLES, "Max limit");
        require(totalSupply() < MAX_PICKLES, "Sale end");
        require(_count <= 20, "Exceeds 20");
        require(msg.value >= price(_count), "Value below price");

        for(uint i = 0; i < _count; i++){
            _safeMint(_to, totalSupply());
        }
    }

    function price(uint _count) public view returns (uint256) {
        uint _id = totalSupply();
        // free 1000
        if(_id <= 1000 ){
            return 0;
        }
        
        return 10000000000000000 * _count; // 0.01 ETH
    }

    function selectGoldenPickle() public onlyOwner {

        require(goldenPickle == 0, "GoldenPickle already minted");

        uint256 max = MAX_PICKLES - 1;
        uint256 sell = totalSupply() - 1;
        uint256 randomHash = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)));

        randomHash = randomHash % max;

        if (randomHash >= 5 && randomHash <= sell){
            goldenPickle =  randomHash;
        }
    }

    function getGoldenPickle() public view returns (uint256){
        if(msg.sender != owner()){
            require (block.timestamp > 1624755600, "Not yet");
        }
        return goldenPickle;
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