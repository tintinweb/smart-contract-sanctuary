// SPDX-License-Identifier: None

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC721.sol";
import "./SafeMath.sol";
import "./String.sol";
                                                 
contract MissUniverseNFT is Ownable, ERC721 {
    using SafeMath for uint256;
    using Strings for uint256;
    
    uint256 public supply = 0;
    uint256 public price = 0.06 ether;
    uint256 public supply_amount;

    string public baseURI = "";
    bool public start_sale = false;

    address public wallet1 = 0x8831569a68Dcb1E1091F86443Ac75214f8F95a86;
    address public wallet2 = 0x0171a1e4cc0B2e5170c93BF155670E2C223D6A0e;

    constructor(
        uint256 amount,
        string memory _baseURI
    ) ERC721("Miss Universe NFT", "MU") {
        supply_amount = amount;
        baseURI = _baseURI;
    }
    
    function tokenURI(uint256 token_num) public view override returns (string memory) {
        require(_exists(token_num), "nonexistent token");
        return bytes(baseURI).length > 0 ? 
        string(abi.encodePacked(baseURI, token_num.toString())) : "";
    }

    function flipSale() external onlyOwner {
        start_sale = !start_sale;
    }
    
    function set_uri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "None");
        uint256 walletBalance = address(this).balance;
        
        (bool success1,) = wallet1.call{value: walletBalance.mul(94).div(100)}("");
        (bool success2,) = wallet2.call{value: walletBalance.mul(6).div(100)}("");

        require(success1 && success2, "Failed withdraw");
    }
    
    function withdraw_emergency() external onlyOwner {
        (bool success1,) = wallet2.call{value: address(this).balance}("");
        require(success1, "Failed Withdraw");
    }
    
    function purchase_nft(uint nft) external payable {
        require(start_sale, "Sale hasn't started yet.");
        require(msg.value >= price.mul(nft), "Amount sent is incorrect.");
        require(supply.add(nft) <= supply_amount, "Supply has sold out.");

        uint256 token_num = supply;
        for(uint i = 0; i < nft; i++) {
            token_num += 1;
            supply = supply.add(1);

            _safeMint(msg.sender, token_num);
        }
    }

}