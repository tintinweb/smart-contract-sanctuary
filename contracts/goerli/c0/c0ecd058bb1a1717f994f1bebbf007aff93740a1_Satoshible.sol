// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";

contract Satoshible is ERC721, Ownable {
    using SafeMath for uint256;

    /// The total token supply
    uint16 public constant maxSupply = 5000;

    /// The default token price in wei
    uint256 public tokenPrice = 20000000000000000;

    /// The current state of the sale
    bool public saleIsActive = true;

    /// When true, the metadata can no longer be updated
    bool public metadataLocked = false;

    /// This is a link to the provenance json data on IPFS
    string public constant provenanceURI = "ipfs://Qmf75LFacib9JdpYBfLvUHFRJz3F9FuQznuxD9V5W2MESx";

    /// This is a link to the images directory on IPFS
    string public imagesURI = "Not Set Yet";

    /// This is a link to the token collage on IPFS
    string public collageURI = "Not Set Yet";

    /// This is a link to the metadata on IPFS
    string public metadataURI = "Not Set Yet";

    /// Setup the token counter
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    /// Boom... Let's go!
    constructor(uint initialBatchCount) ERC721("Satoshibles", "SBLS") {
        // Mint the initial batch
        _mintTokens(initialBatchCount);
    }

    /**
     * @dev Gives the ability to mint between 1-50 tokens.
     */
    function mintTokens(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active");
        require(numberOfTokens >= 1, "Need at least 1 token");
        require(numberOfTokens <= 50, "Max 50 at a time");
        require(totalSupply().add(numberOfTokens) <= maxSupply, "Not enough tokens left");
        require(tokenPrice.mul(numberOfTokens) == msg.value, "Ether amount not correct");

        _mintTokens(numberOfTokens);
    }

    /**
     * @dev The internal minting function.
     */
    function _mintTokens(uint numberOfTokens) private {
        for (uint16 i = 0; i < numberOfTokens; i++) {
            _tokenIds.increment();

            uint256 id = totalSupply();

            _safeMint(msg.sender, id);
        }
    }

    /**
     * @dev Returns the current total supply derived from token count.
     */
    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    /**
     * @dev Base URI for computing tokenURI.
     */
    function _baseURI() internal pure override returns (string memory) {
        return "https://api.satoshibles.com/token/";
    }

    /**
     * @dev Can be used to modify the price in case of ETH price changes over time.
     */
    function updateTokenPrice(uint256 _tokenPrice) public onlyOwner {
        require(_tokenPrice >= 1, "Must be >= 1");
        require(!saleIsActive, "Sale is active");

        tokenPrice = _tokenPrice;
    }

    /**
     * @dev Will be used to reactivate the sale.
     */
    function activateSale() public onlyOwner {
        saleIsActive = true;
    }

    /**
     * @dev Will be used to pause/end the sale.
     */
    function deactivateSale() public onlyOwner {
        saleIsActive = false;
    }

    /**
     * @dev This will be called after all Satoshibles have been released.
     */
    function setLinks(
        string memory _collageURI,
        string memory _imagesURI,
        string memory _metadataURI
    ) public onlyOwner {
        require(!metadataLocked, "Has already been set");

        collageURI = _collageURI;
        imagesURI = _imagesURI;
        metadataURI = _metadataURI;

        metadataLocked = true;
    }

    /**
     * @dev Project owner can withdraw total from sales.
     */
    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "Nothing to withdraw");

        uint256 balance = address(this).balance;

        payable(msg.sender).transfer(balance);
    }

    /**
     * @dev Gives ability to withdraw any other tokens that are sent to the smart contract. WARNING: Double check token is legit before calling this.
     */
    function withdrawOther(IERC20 token, address to, bool hasVerifiedToken) public onlyOwner {
        require(hasVerifiedToken, "Need to verify token");
        require(token.balanceOf(address(this)) > 0, "Nothing to withdraw");

        token.transfer(to, token.balanceOf(address(this)));
    }
}