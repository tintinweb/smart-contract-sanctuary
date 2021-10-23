// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";

/**
 * @title Galaxiators
 * @author Roi Di Segni (aka Sheeeev66)
 * @author @redBonanza
 */

contract Galaxiators is ERC721 {

    // max amount you can mint in a single transaction
    uint8 public maxBatchMint;
    // max token supply 
    uint256 public maxSupply;
    // mint price in wei [ 10^(-18) Ether ] 
    
    uint256 public mintPriceInWei;
    // separate price for presale
    uint256 public presaleMintPriceInWei;
 
    // reservedTokens
    uint256 public reservedTokens;
    uint256 public reservedAirdrop;


    // tracks the token ID
    uint64 private _tokenId;

    // enables minting 
    bool mintingEnabled;
    // enables pre minting
    bool preMintingEnabled;
    // enabled airdrop
    bool airdropEnabled;

    // The address of the contract that can call the burn method
    address burningContract;

    // eligible for free minting
    mapping(address => uint256) private eligibleForAirdrop;
    // To enforce the pre mint phase
    mapping(address => bool) private preMintParticipant;

    event newGalaxiatorMinted(uint id, address to);

    constructor(
        string memory name_,
        string memory symbol_,
        uint64 _maxSupply,
        uint64 _mintPriceInWei,
        uint64 _presaleMintPriceInWei,
        uint16 _reservedTokens,
        uint8 _maxBatchMint
    )
    ERC721(name_, symbol_) {
        maxSupply = _maxSupply;
        mintPriceInWei = _mintPriceInWei;
        presaleMintPriceInWei = _presaleMintPriceInWei;
        reservedTokens = _reservedTokens;
        maxBatchMint = _maxBatchMint;
        reservedAirdrop = 0;
    }
 
    function setReservedTokens(uint256 _reservedTokens) external onlyOwner {
        reservedTokens = _reservedTokens;
    }
    function setBurningContractAddress(address _burningContract) external onlyOwner {
        burningContract = _burningContract;
    } 

    function withdraw(address payable _address) external onlyOwner {
        require(payable(_address).send(address(this).balance));
    }

    /**
     * @dev getter function for the current token supply
     */
    function getCurrentTokenSupply() external view returns(uint64) {
        return _tokenId;
    }

    /**
     * @dev toggles minting. disables pre Minting
     */
    function toggleMinting() external onlyOwner {
        mintingEnabled = !mintingEnabled;
        preMintingEnabled = false;
    }

    function toggleAirdrop() external onlyOwner {
        airdropEnabled = !airdropEnabled;
    }

    /**
     * @dev toggles pre minting
     */
    function togglePreMinting() external onlyOwner {
        preMintingEnabled = !preMintingEnabled;
    }

    function setPrice(uint256 price) public{
        mintPriceInWei = price;
    }

    function setPresalePrice(uint256 price) public{
        presaleMintPriceInWei = price;
    }

    /**
     * @dev gets the mint price in wei
     */
    function getMintPrice() external view returns(uint256) {
        return mintPriceInWei / 1e18;
    }

    function getPresaleMintPrice() external view returns(uint256) {
        return presaleMintPriceInWei / 1e18;
    }

    function getWhitelstedForPreMint(address _address) public view returns(bool) {
        return preMintParticipant[_address];
    }

    function getIfEligibleForAirdrop(address _address) public view returns(uint256) {
        return eligibleForAirdrop[_address];
    }

    /**
     * @dev enable an address to claim an airdrop
     */
    function addToAirdrop(address _address, uint256 amount) external onlyOwner {
        require((0 < amount) && (amount <= maxBatchMint), "Can't reserve this much for airdrop");
        require((reservedAirdrop + amount) <= reservedTokens, "This would exceed the reservedTokens");
        if (eligibleForAirdrop[_address] > 0) {
            reservedAirdrop -= eligibleForAirdrop[_address];
        }
        eligibleForAirdrop[_address] = amount;
        reservedAirdrop += amount;
    }

    /**
     * @dev disable an address from claiming an airdrop
     */
    function removeFromAirdrop(address _address) external onlyOwner {
        require(eligibleForAirdrop[_address] > 0, "Address is not on airdrop list!");
        reservedAirdrop -= eligibleForAirdrop[_address];
        eligibleForAirdrop[_address] = 0;
    }

    /**
     * @dev remove from pre mint whitelist
     */
    function removeFromPreMintWhitelist(address _address) external onlyOwner {
        require(!preMintParticipant[_address], "Address is not on the whitelist!");
        preMintParticipant[_address] = false;
    }

    /**
     * @dev adds to pre mint whitelist
     */
    function AddToPreMintWhitelist(address _address) external onlyOwner {
        require(!preMintParticipant[_address], "Address is already on the whitelist!");
        preMintParticipant[_address] = true;
    }

    /**
     * @dev Reserve tokens for activities
     */
    function reserveTokens(uint256 _tokenCount) public onlyOwner {
        require((_tokenId + _tokenCount) < maxSupply, "This would exceed the token supply");
        require(_tokenCount <= reservedTokens, "Can't reserve this much");
        uint256 i = 0;
        for (i = 0; i < _tokenCount; i++) {
            _mintGalaxiator();
        }
        reservedTokens -= _tokenCount;
    }

    /**
     * @dev allows someone to claim an airdrop
     * @notice this can only be called after minting was disabled
     * @notice only eligible people can call this function
     */
    function claimAirdrop() external {
        require(airdropEnabled, "Airdrop is not active!");
        require(eligibleForAirdrop[msg.sender] > 0, "Caller not eligible for airdrop!");
        require(eligibleForAirdrop[msg.sender] <= reservedTokens, "Airdrop amount exceeded reserved amount");
        require((eligibleForAirdrop[msg.sender] + _tokenId) < maxSupply, "");
        _batchMintFunctions(eligibleForAirdrop[msg.sender]);
        // subtract the amount of tokens minted
        reservedAirdrop -= eligibleForAirdrop[msg.sender];
        reservedTokens -= eligibleForAirdrop[msg.sender];
        eligibleForAirdrop[msg.sender] = 0;
    }

    /**
    *  @dev Mints a single token to a preMint participant 
    *  @dev presale price is different than the public sale price
    *  @dev afterwards, the address is removed from the list
    */
    function presaleMint() public payable {
        require(preMintingEnabled, "Presale not active!");
        require(preMintParticipant[msg.sender], "Caller not eligible for a presale");
        require((_tokenId + 1) < (maxSupply - reservedTokens), "Purchase will exceed the token supply!");
        require(msg.value == presaleMintPriceInWei, "Ether value sent is not correct");
        
        _mintGalaxiator();
        preMintParticipant[msg.sender] = false;
    }
    /**
    * @dev minting the token
    * @dev makes sure that no more than the max supply tokens are minted
    * @dev makes sure that at the correct ether amount is paid before minting
    * @dev makes sure that no more than (maxBatchMint) tokens are minted at once
    * @dev if it's in presale so only whitelisted people can mint
    * @param _tokenCount the amount of tokens to mint
    */
    function mint(uint8 _tokenCount) public payable {
        require(mintingEnabled, "Minting isn't active");
        require((_tokenCount <= maxBatchMint) && (_tokenCount != 0), "Invalid requested amount!");
        require((balanceOf(msg.sender) + _tokenCount) <= maxBatchMint, "Purchase would exceed max token per address");
        require(msg.value == (mintPriceInWei * _tokenCount), "Ether value sent is not correct");
        require((_tokenId + _tokenCount) <= (maxSupply - reservedTokens), "Purchase will exceed the token supply!");
        _batchMintFunctions(_tokenCount);
    }

    /**
    *  @dev loop unrolled to save some gas
    *  @dev maxBatchMint will always be 3/6/9
    */
    function _batchMintFunctions(uint _tokenCount) private {
        _mintGalaxiator();
        if (_tokenCount >= 2) {
            _mintGalaxiator();
            if (_tokenCount >= 3) {
                _mintGalaxiator();
                if (_tokenCount >= 4) {
                    _mintGalaxiator();
                    if (_tokenCount >= 5) {
                        _mintGalaxiator();
                        if (_tokenCount >= 6) {
                            _mintGalaxiator();
                            if (_tokenCount >= 7) {
                                _mintGalaxiator();
                                if (_tokenCount >= 8) {
                                    _mintGalaxiator();
                                    if (_tokenCount == 9) {
                                        _mintGalaxiator();
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    /**
    * Back side of the pod => https://galaxiators.mypinata.cloud/ipfs/QmXofxqroimeZ8AUDwWSskDB5m96FXC9KuC1drceZi2Bzg 
    */
    function _mintGalaxiator() private {
        uint64 id = _tokenId;
        _safeMint(msg.sender, id);
        emit newGalaxiatorMinted(id, msg.sender);
        _tokenId++;
    }

    function _burnGalaxiator(uint tokenId) public {
        require(msg.sender == burningContract, "This function can only be called a by a certain address!");
        _burn(tokenId);
    }

}