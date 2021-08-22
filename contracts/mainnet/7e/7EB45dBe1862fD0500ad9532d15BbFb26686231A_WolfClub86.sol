// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './ERC721Enumerable.sol';
import "./Ownable.sol";

contract WolfClub86 is ERC721Enumerable, Ownable {
    
    uint256 public tokenId;
    uint256 maxSupply = 10000;
    uint nonce = 0;
    string private tokenUri = "https://wolfclub86.herokuapp.com/api/token/";
    
    constructor() ERC721("WolfClub86", "WC86") {
        _owner = 0xe0ED3d79cA7FE5ff24B1184472C0A73B98653CA2;
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return tokenUri;
    }
    
    function updateTokenUri(string memory _newUri) external onlyOwner {
        tokenUri = _newUri;
    }
    
    receive() external payable{
        Mint(msg.value, 1);
    }
    
    function Mint(uint256 _amount, uint256 wolvesAmount) public payable {
        require(block.timestamp > 1629669600, "Minting is not opened yet");
        require(wolvesAmount > 0, "invalid wolves amount provided");
        require(wolvesAmount <= 20, "max wolves to be minted are 20");
        require(_amount == 40000000000000000 * wolvesAmount, "0.04 eths should be paid");
        require(tokenId+wolvesAmount <= maxSupply, "Max supply reached");
        for(uint256 wolf = 1; wolf <= wolvesAmount; wolf++)
        {
            uint256 _rn = getRandom();
            super._safeMint(msg.sender, _rn);
        }
        payable(owner()).transfer(msg.value);
    }
    
    function mintReservedT(uint256 _tokenId, address _receiver) public onlyOwner{
        require(_tokenId == 277 || _tokenId == 2325 || _tokenId == 2338, "Unreserved token Id provided");
        super._safeMint(_receiver, _tokenId);
    }
    
    function getRandom() private returns(uint){
        uint256 _rn = random(maxSupply);
        if(_rn == 277 || _rn == 2325 || _rn == 2338)
            getRandom();
        else if(_owners[_rn] != address(0))
            getRandom();
        return _rn;
    }
    
    function random(uint _maxRan) public returns (uint) {
       nonce += 1;
       uint randomNumber = uint(keccak256(abi.encodePacked(nonce, msg.sender, blockhash(block.number - 1)))) % _maxRan;
       return randomNumber;
    }
    
}