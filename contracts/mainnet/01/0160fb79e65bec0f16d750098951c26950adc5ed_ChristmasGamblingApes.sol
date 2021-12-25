// SPDX-License-Identifier: MIT

import "./OpenZeppelinOwnableAndERC721.sol";

pragma solidity ^0.8.7;

/// @title Minting Contract for the Gambling Apes Christmas Collection
/// @author Doggo#8314
contract ChristmasGamblingApes is ERC721, Ownable {
    using Strings for uint;

    // Constructor

    constructor(ERC721 gamblingApes_, string memory baseURI_) ERC721("Christmas Gambling Apes","CGAPES") {
        gamblingApes = gamblingApes_;
        baseURI = baseURI_;
    }

    // Constants

    uint constant maxPerAddress = 3;
    uint constant ethCost = 0.21 ether;
    uint constant maxId = 777;


    // Storage Variables

    /// @notice Number of currently minted tokens
    uint public totalSupply = 0;

    string baseURI;

    /// @notice Current sale state (true = active, false = inactive)
    bool public saleState;
    bool metadataLocked = false;

    ERC721 gamblingApes;
    
    /// @notice Mapping of address to amount minted
    mapping(address => uint) public amountMinted;


    // Modifiers

    modifier publicMintChecks(uint amount) {
        require(msg.sender == tx.origin);                                                                     // Reentrancy / Botting check
        require(saleState,"Sale is not active!");                                                             // Sale status check
        require(gamblingApes.balanceOf(msg.sender) > 0, "You must own atleast one Gambling Ape to mint");     // GA holder check
        require(msg.value == ethCost * amount, "Invalid ether sent");                                         // Ether sent check
        require(amountMinted[msg.sender] + amount <= maxPerAddress, "Mint would exceed maximum per address"); // Max per address check
        require(totalSupply + amount <= maxId, "Mint would exceed supply");                                   // Max Supply check
        _;
    }


    // Minting

    /// @notice The function call will revert if the mint exceeds supply
    function publicMint(uint amount) external payable publicMintChecks(amount) {
        for(uint i = 0; i < amount; i++)
            _mint(msg.sender, ++totalSupply);
        amountMinted[msg.sender] += amount;
    }

    /// @notice (Owner Only) The function call will revert if the mint exceeds supply
    /// @param to Array of addresses to mint to (1 mint each)
    function adminMint(address[] memory to) external onlyOwner {
        require(totalSupply + to.length <= maxId, "Mint would exceed supply");
        for(uint i = 0; i < to.length; i++) {
            _mint(to[i], ++totalSupply);
        }
    }

    // View

    /// @notice The function call will revert if the tokenId does not exist
    /// @param tokenId The token ID to get the metadata URL of
    /// @return IPFS String that contains the token metadata
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(baseURI, tokenId.toString(),".json"));
    }

    // General Only Owner

    function adminSetGA(ERC721 gamblingApes_) external onlyOwner {
        gamblingApes = gamblingApes_;
    }

    /// @notice (Owner Only) Set the metadata baseURI
    function adminSetBaseURI(string memory baseURI_) external onlyOwner {
        require(!metadataLocked, "Metadata is locked");
        baseURI = baseURI_;
    }

    function adminLockBaseURI() external onlyOwner{
        metadataLocked = true;
    }

    /// @notice (Owner Only) Set sale state
    function adminSetSaleState(bool saleState_) external onlyOwner {
        saleState = saleState_;
    }

    address payable constant withdrawWallet = payable(0x9c27b19B2706c819458AE0fFaC4BebF5487644E0);

    /// @notice (Owner Only) Withdraw the current funds from the contract to a withdraw wallet
    function adminWithdraw() external onlyOwner {
        withdrawWallet.transfer(address(this).balance);
    }
}