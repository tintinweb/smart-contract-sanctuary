// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Counters.sol";
import "./IERC2981.sol";
import "./ERC721.sol";

/**
 * @author Roi Di Segni (aka @sheeeev66)
 */

contract LazyAst is Ownable, ERC721, IERC2981 {

    // Public address of the royalty reciever:
    address private royaltyReciever;

    using Counters for Counters.Counter;
    using Strings for uint256;

    event NewLaMinted(uint id, uint dna, string ipfsCID);
    event Withdrawn(address _address, uint amount);
    
    // track token ID
    Counters.Counter private _tokenId;

    // mapping to store the IPFS CID for each token ID
    mapping(uint => string) private idToIpfs;

    constructor() ERC721("LazyAst", "LA") { }


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
        uint contractBal = address(this).balance;
        _address.transfer(contractBal);
        emit Withdrawn(_address, contractBal);
    }

    /**
     * @dev overriding this to return ipfs CID
     * The minting function on the contract is called after the metadata and art is generated.
     * The art will be stored on IPFS as well as the metadata.
     * The ipfs link to the art will be located inside the metadata.
     * When calling the minting function, you call it with the CID of the token that was generated.
     * Then that CID is assigned to the token ID 
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory ipfsCID = idToIpfs[tokenId];
        return string(abi.encodePacked("ipfs://", ipfsCID));
    }


    /**
     * @dev premint for team
     * @dev 100 will be minted for the team
     * @param _ipfsCID the CID of the metadata on IPFS
     * @notice the NFTs will be minted and sent to the callers address
     * @notice only the owner of the contract can call this function
     */
    function teamPreMint(string memory _ipfsCID) external onlyOwner {
        for (uint i=0; i < 100; i++) {
            _safeMint(msg.sender, _tokenId.current());
            idToIpfs[_tokenId.current()] = _ipfsCID;

            emit NewLaMinted(_tokenId.current(), _generateRandomDna(), _ipfsCID);
            _tokenId.increment();
        }
    }

    /**
     * @dev miniting the token
     * @dev makes sure that no more than 10K tokens are minted
     * @dev makes sure that at least 0.05 ether is paid before minting
     * @dev makes sure that no more than 20 tokens are minted at once
     * @param _tokenCount the ammount of tokens to mint
     * @param _ipfsCID the CID of the metadata on IPFS
     */
    function safeMintLa(uint _tokenCount,  string memory _ipfsCID) public payable {

        require(_tokenCount <= 20, "Can't mint more than 20 tokens at a time");
        require(msg.value >= 0.05 ether, "Ether value sent is not correct");

        for (uint i=0; i < _tokenCount; i++) {
            require(_tokenId.current() <= 9899, "No more tokens avalible");

            _safeMint(msg.sender, _tokenId.current());
            idToIpfs[_tokenId.current()] = _ipfsCID;

            emit NewLaMinted(_tokenId.current(), _generateRandomDna(), _ipfsCID);
            _tokenId.increment();
        }
    }
    
    /**
     * @dev Generates random number for the DNA by using the timestamp, block difficulty and the block number.
     * @return random DNA
     */
    function _generateRandomDna() private view returns (uint32) {
        uint rand = uint(keccak256(abi.encodePacked(block.difficulty, block.number)));
        return uint32(rand %  /* DNA modulus: 10 in the power of "dna digits" (in this case: 8) */ (10 ** 12) );
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
        return (royaltyReciever, (salePrice * 300) / 10000);
    }
    
    /**
     * @dev Sets the royalty recieving address to:
     * @param _address the address the royalties are sent to
     * @notice Setting the recieving address to the zero address will result in an error
     */
    function setRoyaltyRecieverTo(address _address) public onlyOwner {
        require(_address != address(0), "Cannot send royalties to the zero address");
        royaltyReciever = _address;
    }


}