// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./ThetanHero.sol";

contract MinterFactory is Ownable {
    // NFT contract
    ThetanHero public erc721;
    bool public publicMintAllowed;
    uint256 private lastMintID;
    uint256 public maxGenesis;

    event TokenMinted(
        address contractAddress,
        address to,
        uint256 indexed tokenId
    );

    function initialization(ThetanHero _erc721, uint256 _maxGenesis)
        external
        onlyOwner
    {
        erc721 = _erc721;
        lastMintID = 0;
        maxGenesis = _maxGenesis;
    }

    /**
     * @dev mint function to distribute thetan NFT to user
     */
    function mintGenesisTo(address to) external {
        require(publicMintAllowed || _msgSender() == owner());
        require(lastMintID < maxGenesis);
        uint256 tokenId;
        if (lastMintID == 0) {
            tokenId = 0;
        } else {
            tokenId = lastMintID + 1;
        }
        erc721.mintGenesis(to, tokenId);
        lastMintID = lastMintID + 1;

        emit TokenMinted(address(erc721), to, tokenId);
    }

    function setMaxGenesis(uint256 _maxGenesis) public onlyOwner {
        maxGenesis = _maxGenesis;
    }

    /**
     * @dev function to allow user mint items
     */
    function allowPublicMint() public onlyOwner {
        publicMintAllowed = true;
    }
}