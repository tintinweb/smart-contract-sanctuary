// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./PaymentSplitter.sol";

/**
 * @title Galaxiators
 * @author Roi Di Segni (aka Sheeeev66)
 */

contract Galaxiators is ERC721, PaymentSplitter {

    // The address of the contract that can call the burn method
    address callerContract;

    // max amount you can mint in a single transaction
    uint8 maxBatchMint;

    // reserve
    uint16 reserve;

    // max pre mint supply
    uint64 maxPreMintSupply;

    // max token supply 
    uint64 maxSupply;

    // mint price in wei [ 10^(-18) Ether ] 
    uint64 private mintPriceInWei;

    // enables minting 
    bool mintingEnabled;

    // enables pre minting
    bool preMintingEnabled;

    // tracks the token ID
    uint64 private _tokenId;

    // eligible for free minting
    mapping(address => bool) private eligibleForAirdrop;

    // To enforce the pre mint phase
    mapping(address => bool) private preMintParticipant;

    event newGalaxiatorMinted(uint id);

    constructor(address[] memory payees, uint256[] memory shares_)
    ERC721("Galaxiators", "GLX")
    PaymentSplitter(payees, shares_) { }

    modifier mintFunction(uint8 _tokenCount, uint64 _maxSupply) {
        require(_tokenCount <= maxBatchMint && _tokenCount != 0, "Invalid requested amount!");
        require(msg.value == mintPriceInWei * _tokenCount, "Ether value sent is not correct");
        require(_tokenId + _tokenCount <= _maxSupply, "Purchace will exceed the token supply!");
        _;
    }

    /**
     * @dev getter function for the current token supply
     */
    function getCurrentTokenSupply() external view returns(uint64) {
        return _tokenId;
    }

    /**
     * @dev toggles minting. desables pre Minting
     */
    function toggleMinting() external onlyOwner {
        mintingEnabled = !mintingEnabled;
        preMintingEnabled = false;
    }

    /**
     * @dev toggles pre minting
     */
    function togglePreMinting() external onlyOwner {
        preMintingEnabled = !preMintingEnabled;
    }
    
    /**
     * @dev setter function for a new drop
     * @notice if you use this function to fix an error, so reduce the max supply to the last amount
     * @param _maxBatchMint - the maximum amount someone can batch mint
     * @param _supplyToAdd - the amount of tokens to add to the supply
     */
    function setNewDrop(uint8 _maxBatchMint, uint64 _supplyToAdd, uint64 _mintPriceInWei, uint16 _reserve, uint64 _maxPreMintSupply) external onlyOwner {
        uint64 previousSupply = maxSupply;
        require(_tokenId == previousSupply);
        require(_maxBatchMint > 0 || _maxBatchMint <= 9, "Max batch mint needs to be between 1 to 9!");
        if (previousSupply != 0) {
            maxPreMintSupply = previousSupply + _maxPreMintSupply;
        } else {
            maxPreMintSupply = _maxPreMintSupply;
        }
        maxSupply += _supplyToAdd;
        maxBatchMint = _maxBatchMint;
        mintPriceInWei = _mintPriceInWei;
        reserve = _reserve;
        mintingEnabled = false;
    }

    /**
     * @dev remove from max supply
     */
    function removeFromMaxSupply(uint64 _amountToRemove) external onlyOwner {
        maxSupply -= _amountToRemove;
        require(maxSupply >= _tokenId, "Removed more tokens than possible!");
    }

    /**
     * @dev gets the mint price in wei
     */
    function getMintPrice() external view returns(uint64) {
        return mintPriceInWei / 10**18;
    }

    function getWhitelstedForPreMint(address _address) public view returns(bool) {
        return preMintParticipant[_address];
    }

    /**
     * @dev enable an address to clame an airdrop
     */
    function addToAirdrop(address _address) external onlyOwner {
        eligibleForAirdrop[_address] = true;
    }

    /**
     * @dev disable an address to claim an airdrop
     */
    function removeFromAirdrop(address _address) external onlyOwner {
        eligibleForAirdrop[_address] = false;
    }

    /**
     * @dev remove from pre mint whitelist
     */
    function removeFromPreMintWhitelist(address _address) external onlyOwner {
        preMintParticipant[_address] = false;
    }

    /**
     * @dev adds to pre mint whitelist
     */
    function AddToPreMintWhitelist(address _address) external onlyOwner {
        preMintParticipant[_address] = true;
    }

    /**
     * @dev allows someone to claim an airdrop
     * @notice this can only be called after minting was disabled
     * @notice only eligible people can call this function
     */
    function claimAirdrop() external {
        require(eligibleForAirdrop[msg.sender], "Caller not eligable for a pre mint!");
        require(
            !mintingEnabled && !preMintingEnabled && _tokenId >= (maxSupply - reserve),
            "Sale is not over!"
        );
        _mintGalaxiator();
        eligibleForAirdrop[msg.sender] = false;
    }

    /**
     * @dev pre minting the token
     * @notice This gets enabled when minting is desabled
     * @notice only eligable people can pre mint
     * @dev makes sure that no more than (maxBatchPreMint) tokens are minted at once  
     * @param _tokenCount the ammount of tokens to mint
     */
    function preMint(uint8 _tokenCount) public payable mintFunction(_tokenCount, maxPreMintSupply) {
        require(preMintingEnabled, "Pre mint phase is over!");
        require(preMintParticipant[msg.sender], "Caller not eligable for a pre mint");
        
        _batchMintFunctions(_tokenCount);
        preMintParticipant[msg.sender] = false;
    }

            /**
            * @dev miniting the token
            * @dev makes sure that no more than the max supply tokens are minted
            * @dev makes sure that at the correct ether amount is paid before minting
            * @dev makes sure that no more than (maxBatchMint) tokens are minted at once
            * @param _tokenCount the ammount of tokens to mint
            */
            function mint(uint8 _tokenCount) public payable mintFunction(_tokenCount, maxSupply - reserve) {    
                require(mintingEnabled, "Public sale is not live!");

                _batchMintFunctions(_tokenCount);
            }

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
            
            function _mintGalaxiator() private {
                uint64 id = _tokenId;
                _safeMint(msg.sender, id);
                emit newGalaxiatorMinted(id);
                _tokenId++;
            }

    function _burnGalaxiator(uint tokenId) public {
        require(msg.sender == callerContract, "This function can only be called a by a certain address!");
        _burn(tokenId);
    }


//////////////////// payment splitting ////////////////////

}