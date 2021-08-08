// contracts/RiotRacersCarAssets
// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./ERC721.sol";
import "./Ownable.sol";

contract RiotRacersCarAssets is ERC721, Ownable {

    using SafeMath for uint256;
    bool public hasSaleStarted = false;

    constructor(string memory baseURI) ERC721("RiotRacersCarAssets","RRCA")  {
        setBaseURI(baseURI);
    }
    
    function tokensOfOwner(address _owner) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }
    
   function mintCar(uint256 numCars) public onlyOwner {

        for (uint i = 0; i < numCars; i++) {
            uint mintIndex = totalSupply() + 1;
            _safeMint(msg.sender, mintIndex);
        }
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }
    
    function withdraw() public onlyOwner {
		uint balance = address(this).balance;
		msg.sender.transfer(balance);
    }

}