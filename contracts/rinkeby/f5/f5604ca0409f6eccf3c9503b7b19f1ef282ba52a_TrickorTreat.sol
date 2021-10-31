//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract TrickorTreat is ERC721Enumerable, Ownable {

    using Strings for uint256;

    string _baseTokenURI;
    
    mapping (address => bool) public initalsale;
    uint256 public _price = 0.1 ether;
    phases public phase;

    enum phases {
        INIT,
        OPEN
    }

    

    constructor() ERC721("TrickorTreat", "ToT") {
        phase = phases.INIT;

    }

    
    function mint(uint256 num) external payable {
        uint256 supply = totalSupply();
        require( phase == phases.OPEN,                          "Phase is not open" );
        require( num == 1,                      "You can mint a maximum of 1 ToT" );
        require( supply + num <= 10,                 "Exceeds maximum ToT supply" );
        require( msg.value >= _price * num,             "Ether sent is not correct" );

        for(uint256 i = 1; i <= num; i++){
            _safeMint( msg.sender, supply + i );
        }
    }
    
    function walletOfOwner(address _walletOwner) external view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_walletOwner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_walletOwner, i);
        }
        return tokensId;
    }

    
    function setPrice(uint256 _newPrice) external onlyOwner() {
        _price = _newPrice;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory json = ".json";
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), json)) : "";
    }

    
  

    
    function changePhaseToOpen() external onlyOwner {
        require(phase == phases.INIT, 'phase must be in initial phase first');
        phase = phases.OPEN;
    }
    
    function withdrawAll() external onlyOwner {
        require(address(this).balance > 0);
        uint256 _all = address(this).balance;
        (bool status1, ) = payable(owner()).call{value: _all}("");
  
        require(status1 == true, 'withdraw failed');
    }
    
    fallback() external payable {
        revert('You sent ether to this contract without specifying a function');
    }
    receive() external payable {
        revert('You sent ether to this contract without specifying a function');
    }
}