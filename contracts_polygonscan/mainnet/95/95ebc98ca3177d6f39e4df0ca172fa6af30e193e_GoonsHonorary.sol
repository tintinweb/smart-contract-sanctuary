// contracts/GoonsHonorary
// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./ERC721.sol";
import "./Ownable.sol";

contract GoonsHonorary is ERC721, Ownable {

    using SafeMath for uint256;

	uint public constant MAX_GOONS = 100;

	string public GOONS_PROVENANCE = "";

    constructor(string memory baseURI) ERC721("GoonsHonorary","GOONSHONOR")  {
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

	function mintHonoraryGoons(uint256 numGoons) public payable onlyOwner {
        require(totalSupply() < MAX_GOONS, "Max Goons supply reached");
        require(totalSupply().add(numGoons) <= MAX_GOONS, "Exceeds MAX_GOONS");

        for (uint i = 0; i < numGoons; i++) {
            uint mintIndex = totalSupply() + 1;
            _safeMint(msg.sender, mintIndex);
        }
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

	/*
    * Set provenance once it's calculated
    */
    function setProvenanceHash(string memory _hash) public onlyOwner {
        GOONS_PROVENANCE = _hash;
    }
    
    function withdraw() public onlyOwner {
		uint balance = address(this).balance;
		msg.sender.transfer(balance);
    }

}