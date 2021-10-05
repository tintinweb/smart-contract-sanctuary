// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./ERC721.sol";
import "./IERC2981.sol";
import "./Counters.sol";

/**
 * @author Roi Di Segni (aka @sheeeev66)
 */

contract Stickos is ERC721, IERC2981 {

    using Counters for Counters.Counter;
    using Strings for uint256;

    event NewMinted(uint id);
    event Withdrawn(address _address, uint amount);

    constructor() ERC721("Stickos", "STICKOS") { }


    function supportsInterface(bytes4 interfaceId) public view override(ERC721, IERC165) returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }


    /**
     * @dev withdraw contract balance to a wallet
     * @notice won't execute if it isn't the owner who is executing the command
     * @param _address the address to withdraw to
     */
    function withdraw(address payable _address) public onlyOwner {
        emit Withdrawn(_address, address(this).balance);
        _address.transfer(address(this).balance);
    }

    /**
     * @dev premint for team
     * @dev 20 will be minted for the team
     * @notice the NFTs will be minted and sent to the callers address
     * @notice only the owner of the contract can call this function
     * @notice enables pre minting
     */
    function freeMint() public {
        require(eligibleForFreeMint[msg.sender], "Team Mint Has already happened");
        require(_tokenId.current() < totalSupply, "Purchace will exeed max supply of tokens");

        _safeMint(msg.sender, _tokenId.current());

        emit NewMinted(_tokenId.current());
        _tokenId.increment();

        eligibleForFreeMint[msg.sender] = false;
    }

    /**
     * @dev pre minting the token (the number of pre mint participants will be minted)
     * @notice only eligable people can pre mint
     * @dev makes sure that no more than (maxBatchPreMint) tokens are minted at once
     * @param _tokenCount the ammount of tokens to mint
     */
    function preMint(uint _tokenCount) public payable {
        require(preMintParticipant[msg.sender], "Address not eligable for a pre mint");
        require(_tokenCount <= maxBatchPreMint, "Can not mint more than 5 tokens at a time");
        require(_tokenCount != 0, "You have to mint at least 1 token");
        require(msg.value >= mintPriceInWei, "Ether value sent is not correct"); 

        for (uint i=0; i < _tokenCount; i++) {
            _safeMint(msg.sender, _tokenId.current());

            emit NewMinted(_tokenId.current());
            _tokenId.increment();
        }
        
        preMintParticipant[msg.sender] = false;
    }

    /**
     * @dev miniting the token
     * @dev makes sure that no more than 10K tokens are minted
     * @dev makes sure that at least 0.05 ether is paid before minting
     * @dev makes sure that no more than (maxBatchMint) tokens are minted at once
     * @param _tokenCount the ammount of tokens to mint
     */
    function mint(uint _tokenCount) public payable {
        require(_tokenCount <= maxBatchMint, "Can not mint more than 5 tokens at a time");
        require(_tokenCount != 0, "You have to mint at least 1 token");
        require(_tokenId.current() + _tokenCount < totalSupply, "Purchace will exeed max supply of tokens");
        require(msg.value >= mintPriceInWei*_tokenCount, "Ether value sent is not correct"); 

        for (uint i=0; i < _tokenCount; i++) {
            _safeMint(msg.sender, _tokenId.current());

            emit NewMinted(_tokenId.current());
            _tokenId.increment();
        }
    }

    /**
     * @dev Royalty info for the exchange to read (using EIP-2981 royalty standard)
     * @param tokenId the token Id 
     * @param salePrice the price the NFT was sold for
     * @dev returns: send a percent of the sale price to the royalty recievers address
     * @notice this function is to be called by exchanges to get the royalty information
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view override returns (address receiver, uint256 royaltyAmount) {
        require(_exists(tokenId), "ERC2981RoyaltyStandard: Royalty info for nonexistent token");
        return (royaltyReceiver, (salePrice * royaltyPercentage) / 10000);
    }

}