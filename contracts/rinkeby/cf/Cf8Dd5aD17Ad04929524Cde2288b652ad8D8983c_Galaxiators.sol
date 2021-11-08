// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";

/**
 * @title Galaxiators
 * @author @redBonanza
 * @author Roi Di Segni (aka Sheeeev66)
 */

contract Galaxiators is ERC721 {

    // max amount you can mint in a single transaction
    // and max amount per wallet
    uint256 public immutable maxBatchMint;
    // max token supply 
    uint256 public immutable maxSupply;
    
    // mint price for public sale
    uint256 public immutable mintPriceInWei;
    // separate price for presale
    uint256 public immutable preMintPriceInWei;
 
    // Total amount of reserved tokens
    uint256 public reservedTokens;

    // tracks the token ID
    uint64 private _tokenId;

    // Toggle minting (sale), preMinting (presale) and airdrop states
    bool mintingEnabled = false;
    bool preMintingEnabled = false;
    bool airdropEnabled = false;

    // The address of the contract that can call the burn method
    address burningContract;

    // keep track on who's eligible for airdrop (free token)
    mapping(address => bool) private _airdropList;
    // early birds that registered to the presale mint with discounted price
    // bool as it's limited to 1 per person.
    mapping(address => bool) private _preMintWhitelist;

    event newGalaxiatorMinted(uint id, address to);

    constructor(
        string memory name_,
        string memory symbol_,
        uint64 _maxSupply,
        uint64 _mintPriceInWei,
        uint64 _preMintPriceInWei,
        uint16 _reservedTokens,
        uint8 _maxBatchMint
    )
    ERC721(name_, symbol_) {
        maxSupply = _maxSupply;
        mintPriceInWei = _mintPriceInWei;
        preMintPriceInWei = _preMintPriceInWei;
        reservedTokens = _reservedTokens;
        maxBatchMint = _maxBatchMint;
    }
 
    function withdraw(address payable _address) external onlyOwner {
        require(payable(_address).send(address(this).balance));
    }

    /**
     * Toggling presale, sale and airdrop states
     */
    function togglePreMinting() external onlyOwner {
        preMintingEnabled = !preMintingEnabled;
    }

    function toggleMinting() external onlyOwner {
        mintingEnabled = !mintingEnabled;
    }

    function toggleAirdrop() external onlyOwner {
        airdropEnabled = !airdropEnabled;
    }


    /**
    *  Various getters
    */
    function getCurrentTokenSupply() external view returns(uint64) {
        return _tokenId;
    }

    function isWhitelisted(address _address) public view returns(bool) {
        return _preMintWhitelist[_address];
    }

    function isInAirdropList(address _address) public view returns(bool) {
        return _airdropList[_address];
    }

    /**
    *  Various setters
    */
    function setReservedTokens(uint256 _reservedTokens) external onlyOwner {
        reservedTokens = _reservedTokens;
    }
    function setBurningContractAddress(address _burningContract) external onlyOwner {
        burningContract = _burningContract;
    } 

    /**
     * @dev Adds addresses to the airdrop
     */
    function addToAirdrop(address[] calldata _addresses) external onlyOwner {
        for (uint i = 0; i < _addresses.length; i++) {
            _airdropList[_addresses[i]] = true;
        }
    }

    /**
     * @dev Removes addresses from the airdrop
     */
    function removeFromAirdrop(address[] calldata _addresses) external onlyOwner {
        for (uint i = 0; i < _addresses.length; i++) {
            _airdropList[_addresses[i]] = false;
        }
    }

    /**
     * @dev Adds addresses to the presale whitelist
     */
     function addToPreMintWhitelist(address[] calldata _addresses) external onlyOwner {
        for (uint i = 0; i < _addresses.length; i++) {
            _preMintWhitelist[_addresses[i]] = true;
        }
    }

    /**
     * @dev Removes addresses from the whitelist
     */
    function removeFromPreMintWhitelist(address[] calldata _addresses) external onlyOwner {
        for (uint i = 0; i < _addresses.length; i++) {
            _preMintWhitelist[_addresses[i]] = false;
        }
    }

    /**
    *   Minting functions
    */

    /**
     * @dev Reserve tokens for activities
     */
    function reserveTokens(uint256 _tokenCount) public onlyOwner {
        require((_tokenId + _tokenCount) <= maxSupply, "This would exceed the token supply");
        require(_tokenCount <= reservedTokens, "Can't reserve this much");
        _batchMintTokens(_tokenCount);
        reservedTokens -= _tokenCount;
    }

    /**
     * @dev allows pre-approved address to claim an airdrop
     */
    function claimAirdrop() external {
        require(airdropEnabled, "Airdrop is not active!");
        require(_airdropList[msg.sender], "Caller not eligible for airdrop!");
        require(reservedTokens > 0, "Airdrop will exceed the reserved amount!");
        require(_tokenId < maxSupply, "Airdrop will exceed the token supply!");
        _mintGalaxiator();

        // subtract from the reserved tokens
        reservedTokens--;
        _airdropList[msg.sender] = false;
    }

    /**
    *  @dev Mints a single token to a whitelisted address 
    *  @dev presale price is different than the public sale price
    *       afterwards, the address is removed from the list
    */
    function presaleMint() public payable {
        require(preMintingEnabled, "Presale not active!");
        require(_preMintWhitelist[msg.sender], "Caller not eligible for a presale");
        require(_tokenId < (maxSupply - reservedTokens), "Purchase will exceed the token supply!");
        require(msg.value == preMintPriceInWei, "Ether value sent is not correct");
        
        _mintGalaxiator();
        _preMintWhitelist[msg.sender] = false;
    }

    /**
    * @dev Mints new Glaxiator tokens!
    * @dev makes sure that no more than the max supply tokens are minted
    * @param _tokenCount the amount of tokens to mint
    */
    function mint(uint8 _tokenCount) public payable {
        require(mintingEnabled, "Minting isn't active");
        require((_tokenCount <= maxBatchMint) && (_tokenCount != 0), "Invalid requested amount!");
        require((balanceOf(msg.sender) + _tokenCount) <= maxBatchMint, "Purchase would exceed max tokens per address");
        require(msg.value == (mintPriceInWei * _tokenCount), "Ether value sent is not correct");
        require((_tokenId + _tokenCount) <= (maxSupply - reservedTokens), "Purchase will exceed the token supply!");
        _batchMintTokens(_tokenCount);
    }

    function _batchMintTokens(uint _tokenCount) private {
        uint256 i = 0;
        for (i = 0; i < _tokenCount; i++) {
            _mintGalaxiator();
        }
    }

    function _mintGalaxiator() private {
        uint64 id = _tokenId;
        _safeMint(msg.sender, id);
        emit newGalaxiatorMinted(id, msg.sender);
        _tokenId++;
    }

    function burnGalaxiator(uint tokenId) public {
        require(msg.sender == burningContract, "This function can only be called a by a certain address!");
        _burn(tokenId);
    }

}