/* Oh Welcome! Take a cup of coffee 旦~
                                           __                             __
 /'\_/`\                                  /\ \                           /\ \
/\      \     ___     ___     ____     __ \ \ \___       __      __      \_\ \
\ \ \__\ \   / __`\  / __`\  /',__\  /'__`\\ \  _ `\   /'__`\  /'__`\    /'_` \
 \ \ \_/\ \ /\ \L\ \/\ \L\ \/\__, `\/\  __/ \ \ \ \ \ /\  __/ /\ \L\.\_ /\ \L\ \
  \ \_\\ \_\\ \____/\ \____/\/\____/\ \____\ \ \_\ \_\\ \____\\ \__/.\_\\ \___,_\
   \/_/ \/_/ \/___/  \/___/  \/___/  \/____/  \/_/\/_/ \/____/ \/__/\/_/ \/__,_ /
 __  __
/\ \/\ \            __
\ \ \ \ \     ___  /\_\     ___     ___
 \ \ \ \ \  /' _ `\\/\ \   / __`\ /' _ `\
  \ \ \_\ \ /\ \/\ \\ \ \ /\ \L\ \/\ \/\ \
   \ \_____\\ \_\ \_\\ \_\\ \____/\ \_\ \_\
    \/_____/ \/_/\/_/ \/_/ \/___/  \/_/\/_/
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";

/**
 * @title MooseheadUnion contract
 * We are Mooseheads! The Only 1e4 Mooseheads among 5e17! ᒡ◯ᵔ◯ᒢ
 */
contract MooseheadUnion is ERC721, ERC721Enumerable, Ownable {

    using Strings for uint256;

    uint256 public constant MAX_TOKENS = 10000;
    uint256 public constant PRICE = 0.06 ether; // Price of one moosehead! Constant!

    string private _baseTokenURI = "ipfs://QmdcNp364CygHAydaPK58MCUQCRxsiUyVfBvS1Tmie1ph2/";
    string private _baseContractURI = "ipfs://QmdcNp364CygHAydaPK58MCUQCRxsiUyVfBvS1Tmie1ph2/contract";
    bool public saleIsActive;

    constructor() ERC721("MooseheadUnion", "MOOS")  {
        saleIsActive = false;
        setBaseURI(_baseTokenURI);
        setContractURI(_baseContractURI);
    }

    function mint(uint256 num) public payable {
        uint256 supply = totalSupply();
        require(saleIsActive, "Sale is not active");
        require(num > 0, "Minting 0");
        require(num <= 20, "Max of 20 is allowed");
        require(supply + num <= MAX_TOKENS, "Passing max supply");
        require(msg.value >= PRICE * num, "Ether sent is not correct");

        for(uint256 i = 0; i < num; i++){
            uint256 mintIndex = totalSupply();
            if (totalSupply() < MAX_TOKENS) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function withdraw() onlyOwner public {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /*
    * @dev Reserve 10 tokens for gifts & roadmap
    */
    function reserveTokens() public onlyOwner {
        uint256 supply = totalSupply();
        for (uint256 i = 0; i < 10; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    /*
    * @dev openSea contract metadata
    */
    function setContractURI(string memory contURI) public onlyOwner {
		_baseContractURI = contURI;
	}

    function contractURI() public view returns (string memory) {
		return _baseContractURI;
	}

    /*
    * @dev Needed below function to resolve conflicting fns in ERC721 and ERC721Enumerable
    */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /*
    * @dev Needed below function to resolve conflicting fns in ERC721 and ERC721Enumerable
    */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }
}