// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./Counters.sol";
import "./ERC721.sol";


/**
 * @author Roi Di Segni (aka @sheeeev66)
 */

contract TierOneFighters is ERC721 {

    using Counters for Counters.Counter;
    using Strings for uint256;

    // token ID tracker
    Counters.Counter internal _tokenId;

    // Total token Supply
    uint private totalSupply;

    // Mint Price
    uint private mintPriceInWei;

    // Launch (when true its launched)
    bool private launched;

    event NewTeirOneFytMinted(uint id, uint8 tier, uint character);
    event Withdrawn(address _address, uint amount);
    event NewMintPrice(uint oldMintPrice, uint newMintPrice);

    constructor() ERC721("FightersNFT", "FYT") { }

    /**
     * @dev withdraw contract balance to a wallet
     * @notice won't execute if it isn't the owner who is executing the command
     * @param _address the address to withdraw to
     */
    function withdraw(address payable _address) public onlyOwner {
        require(address(this).balance > 0, "Contract balance is empty");
        emit Withdrawn(_address, address(this).balance);
        _address.transfer(address(this).balance);
    }

    /**
     * @dev Launch toggle
     */
    function toggleLaunch() external onlyOwner {
        launched = !launched;
    }

    /**
     * @dev updates the mint price
     */
    function updateMintPrice(uint _newMintPriceInWei) external onlyOwner {
        require(_newMintPriceInWei == mintPriceInWei, "The entered price is the current price");
        emit NewMintPrice(mintPriceInWei, _newMintPriceInWei);
        mintPriceInWei = _newMintPriceInWei;
    }

    /**
     * @dev miniting the token
     * @dev makes sure that no more than 10K tokens are minted
     * @dev makes sure that ether is paid before minting
     */
    function mintTeirOneFighter() public payable {
        require(launched, "Project hasn't launched yet");
        require(_tokenId.current() < totalSupply, "Purchace will exeed max supply of tokens");
        require(msg.value == mintPriceInWei, "Ether value sent is not correct");
        uint32 charId = (uint32(_tokenId.current()) / 8); // if this doesn't work, try subtracting the remainder before deviding by 8.
        
        _safeMint(msg.sender, _tokenId.current());
        
        emit NewTeirOneFytMinted(_tokenId.current(), 1, charId);
        _tokenId.increment();
    }

    /**
     * @dev get if the caller owns an NFT
     */
    function isTokenHolder() external view returns(bool) {
        return balanceOf(msg.sender) > 0;
    }

}