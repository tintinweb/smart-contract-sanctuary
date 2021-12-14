/**
 * @title TheNiftyWayGalaxy contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 * SPDX-License-Identifier: MIT
 */

pragma solidity ^0.8.9;
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./MerkleProof.sol";

contract TheNiftyWayGalaxy is ERC721, ERC721Enumerable, Ownable {

    // Whitelist Merkle Root
    bytes32 public whitelistMerkleroot;

    // Mapping from owner to nifties minted in pre-sale
    mapping(address => uint256) private _mintedPresale;

    // Mapping from owner to nifties minted in public sale
    mapping(address => uint256) private _mintedPublicsale;
    
    // Nifty price for public sale
    uint256 public constant niftySalePrice = 0.09 ether; // Should we use ether or wei?

    // Nifty price for public sale
    uint256 public constant niftyPresalePrice = 0.07 ether; // Should we use ether or wei?
    
    // Max Nifties quantity a user can mint at a time in pre-sale
    uint256 public constant MAX_PRESALE_MINT = 5;

    // Max Nifties quantity a user can mint at a time in publicsale
    uint256 public constant MAX_PUBLIC_MINT = 10;

    // Numbers of Nifties the team will keep
    uint256 public constant TEAM_NIFTIES = 222;

    // Numbers of Nifties the team will keep
    uint256 private constant AIRDROP_NIFTIES = 16;
    
    // Max TNWG supply
    uint256 public MAX_NIFTIES;

    // Max TNWG presale supply
    uint256 public MAX_PRESALE_NIFTIES = 1947;

    // Edition Lock
    bool public editionLock = false;

    // Public sale toggle
    bool public isSaleActive = false;

    // Presale toggle
    bool public isPresaleActive = false;

    // Indicates if team already got Nifties.
    bool public areNiftiesReserved = false;

    // Original provenance
    string public originalProvenance = "6cef215015bfbc000a33f23d8649a647fa83ca26e0e60fbbb51a681b14921da6";

    // Post-deterministic shuffle provenance
    string public finalProvenance;

    // Metadata base URI
    string public baseURI = "";

    /**
     * Smart contract constructor.
     * @param name Full collection name
     * @param symbol Collection symbol
     * @param maxNftSupply Max collection supply
     */
    constructor(string memory name, string memory symbol, uint256 maxNftSupply) ERC721(name, symbol) {
        MAX_NIFTIES = maxNftSupply;
        reserveAirdropNifties(AIRDROP_NIFTIES);
    }

    /**
    * Mints public sale Nifties.
    * @param numberOfTokens Number of tokens to be minted.
    */
    function mint(uint numberOfTokens) public payable {
        require(isSaleActive, "Sale has not started yet.");
        require(_mintedPublicsale[msg.sender] + numberOfTokens <= MAX_PUBLIC_MINT, "Can only mint 10 nifties per wallet in public sale CONTRACT");
        require(totalSupply() + numberOfTokens <= MAX_NIFTIES, "Purchase would exceed max supply of Nifties");
        require(niftySalePrice * numberOfTokens <= msg.value, "Ether value sent is not enough");
        
        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_NIFTIES) {
                _mintedPublicsale[msg.sender]++;
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    /**
     * Mints pre-sale Nifties if isPresaleActive is true.
     * @param proof Hashes needed to reconstruct the merkle root.
     * @param numberOfTokens Number of tokens to be minted.
     */
    function mintPresale( 
                            bytes32[] calldata proof,
                            uint256 numberOfTokens
                            )
    external payable
    {
        require(isPresaleActive, "Presale has not started yet.");
        require(!isSaleActive, "Public sale is active. You shouldn't mint here.");
        require(_verify(_leaf(msg.sender), proof), "Invalid proof / Not whitelisted");
        require(_mintedPresale[msg.sender] + numberOfTokens <= MAX_PRESALE_MINT, "Can only mint 5 nifties per wallet in presale");
        require(totalSupply() + numberOfTokens <= MAX_PRESALE_NIFTIES, "Purchase would exceed max supply of presale Nifties");
        require(niftyPresalePrice * numberOfTokens <= msg.value, "Ether value sent is not enough");
        
        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_PRESALE_NIFTIES) {
                _mintedPresale[msg.sender]++;
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    /**
     * Set Nifties aside for the Aidrop.
     * Only called once by the constructor
     * @param numberOfTokens Number of tokens to be minted.
     */
    function reserveAirdropNifties(uint numberOfTokens) internal{        
        uint supply = totalSupply();

        for (uint i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    /**
     * Set Nifties aside for the team.
     * Only can be called once after sale is active.
     * @param numberOfTokens Number of tokens to be minted.
     */
    function reserveTeamNifties(uint256 numberOfTokens) public onlyOwner{
        uint256 supply = totalSupply();
        require(!areNiftiesReserved, "Already reserved some Nifties for the team.");
        require(supply + TEAM_NIFTIES <= MAX_NIFTIES, "Purchase would exceed max supply of Nifties");    

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, supply + i);
        }

        areNiftiesReserved = true;
    }

    /**
     * Set provenance once it's calculated.
     * This function can be locked.
     * @param provenanceSelector Provenance selector.
     * @param newProvenance New provenance hash.
     */
    function setProvenanceHash(uint provenanceSelector, string memory newProvenance) public onlyOwner {
        require(!editionLock, "Provenance hash editing is locked.");

        if(provenanceSelector == 0){
            originalProvenance = newProvenance;
        }
        else{
            finalProvenance = newProvenance;
        }
    }

    /**
     * Set new baseURI.
     * @param newBaseURI New base URI.
     */
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        require(!editionLock, "Base URI editing is locked.");
        baseURI = newBaseURI;
    }

    /**
     * Set whitelist merkle root.
     * @param newRoot New whitelist merkle root.
     */
    function setMerkleroot(bytes32 newRoot) public onlyOwner {
        whitelistMerkleroot = newRoot;
    }

    /**
     * Sets editionLock and editionLock to true.
     */
    function setEditionLock() public onlyOwner{
        editionLock = true;
    }

    /**
     * Starts/stops pre-sale or public sale.
     * @param optionId If set to 0, inverts pre-sale value. 
     * If set to 1, inverts public sale value
     */
    function toggleSale(uint optionId) public onlyOwner{
        if(optionId == 0){
            isPresaleActive = !isPresaleActive;
        }else if(optionId == 1){
            isSaleActive = !isSaleActive;
        }
    }

    /**
     * Sets nex max supply
     * @param newMaxSupply New MAX_NIFTIES value
     * New value should be lower than totalSupply()
     * New value should be lower than MAX_NIFTIES
     */
    function setMaxSupply(uint newMaxSupply) public onlyOwner{
        require(newMaxSupply > totalSupply(), "New max supply is lower than current supply.");
        require(newMaxSupply < MAX_NIFTIES, "New max supply is greater than MAX_NIFTIES.");
        MAX_NIFTIES = newMaxSupply;
    }

    /**
     * Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`.
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * Transfers contract's ETH balance to the contract owner.
     */
    function withdrawMoney() public onlyOwner {
        address payable to = payable(msg.sender);
        to.transfer(address(this).balance);
    }

    /**
     * Withdraws money to the addres specified in the first parameter. 
     * @param to Receiver address.
     */
    function withdrawMoneyTo(address to) public onlyOwner{
        address payable payableTo = payable(to);
        payableTo.transfer(address(this).balance);
    }

    /**
     * Uses ERC721Enumerable _beforeTokenTransfer() implementation.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override(ERC721, ERC721Enumerable){
        ERC721Enumerable._beforeTokenTransfer(from, to, amount);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId;
    }

    /**
     * Generates a leaf node.
     * @param account Should be msg.sender address.
     */
    function _leaf(address account)
    internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(account));
    }
    
    /**
     * Verifies if the input leaf is part of the merkle tree.
     * @param leaf Merkle leaf node.
     * @param proof Hashes needed to reconstruct the merkle root.
     */
    function _verify(bytes32 leaf, bytes32[] memory proof)
    internal view returns (bool)
    {
        return MerkleProof.verify(proof, whitelistMerkleroot, leaf);
    }
}

// SHA256("Cheesy was here").toString()
// c492a5fc1c436167458dd6557cb06e85d440044abc1d89c5679619773e98765f

// SHA256("Sx Dx was here").toString()
// e7dbbf3a9a3fb3427f22b9e6c287dabe2b7ae42e4976185ae20f9bc7cab04cbc

// SHA256(ID).toString()
// bcb615c96e0565198e0cec38bcfb3d8fedade1d05998801d794f35ac396e41f1