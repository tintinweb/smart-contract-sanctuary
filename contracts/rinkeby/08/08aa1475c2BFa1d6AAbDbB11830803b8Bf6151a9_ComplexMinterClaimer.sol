// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC721.sol";

/*

    complex claimer for complex core.
    this contract has functions mainly: set ERC721/cryptoPunk address for claim, claim (to complex minter core)
    this contract is not payable.

*/

interface IComplexMinterCore {
    function claimerMint(address to_) external;
    function availableTokensRemaining() external returns (uint);
}

interface ICryptoPunks {
    function punkIndexToAddress(uint256 punkId_) external returns (address);
}

contract ComplexMinterClaimer is Ownable {
    
    uint public claimSeries = 0;
    
    IComplexMinterCore minterCore;
    address public minterCoreAddress;
    
    // IERC721 ERC721ForClaim;
    bool public ERC721ClaimingEnabled = false;
    address public ERC721ClaimingAddress;
    uint public ERC721ClaimingMax = 0;
    uint public ERC721ClaimingCurrent = 0;
    
    // ICryptoPunks cryptoPunksForClaim;
    bool public cryptoPunkClaimingEnabled = false;
    address public cryptoPunkClaimingAddress;
    uint public cryptoPunkClaimingMax = 0;
    uint public cryptoPunkClaimingCurrent = 0;
    
    mapping(uint => mapping(uint => uint)) public seriesToERC721IdsUsedForClaiming;
    mapping(uint => mapping(uint => uint)) public seriesToCryptoPunkIdsUsedForClaiming;
    
    event Claim(address indexed to, uint indexed series, uint indexed tokenId);
    event ClaimWithPunk(address indexed to, uint indexed series, uint indexed tokenId);
    
    constructor () {}
    
    function initMinterCore(address address_) external onlyOwner {
        minterCoreAddress = address_;
        minterCore = IComplexMinterCore(minterCoreAddress);
    }
    function setClaimSeries(uint series_) external onlyOwner {
        claimSeries = series_;
    }
    /* ERC721 Claiming Config */
    function setERC721Claiming(bool bool_) external onlyOwner {
        ERC721ClaimingEnabled = bool_;
    }
    function setERC721ClaimingAddress(address address_) external onlyOwner {
        ERC721ClaimingAddress = address_;
    }
    function setERC721ClaimingMax(uint uint_) external onlyOwner {
        ERC721ClaimingMax = uint_;
    }
    function setERC721ClaimingCurrent(uint uint_) external onlyOwner {
        ERC721ClaimingCurrent = uint_; // this should generally never be used
    }
    function initERC721Claimer(uint series_, address ERC721Address_, uint claimingMax_, uint claimingCurrent_) external onlyOwner {
        claimSeries = series_;
        ERC721ClaimingAddress = ERC721Address_;
        ERC721ClaimingMax = claimingMax_;
        ERC721ClaimingCurrent = claimingCurrent_; // this should generally always be 0
        ERC721ClaimingEnabled = false; // this is to prevent accidentally initating the claimer with claiming already enabled
    }
    /* CryptoPunk Claiming Config */
    function setCryptoPunkClaiming(bool bool_) external onlyOwner {
        cryptoPunkClaimingEnabled = bool_;
    }
    function setCryptoPunkClaimingAddress(address address_) external onlyOwner {
        cryptoPunkClaimingAddress = address_;
    }
    function setCryptoPunkClaimingMax(uint uint_) external onlyOwner {
        cryptoPunkClaimingMax = uint_;
    }
    function setCryptoPunkClaimingCurrent(uint uint_) external onlyOwner {
        cryptoPunkClaimingCurrent = uint_; // this should generally never be used
    }
    function initCryptoPunkClaimer(uint series_, address cryptoPunkAddress_, uint claimingMax_, uint claimingCurrent_) external onlyOwner {
        claimSeries = series_;
        cryptoPunkClaimingAddress = cryptoPunkAddress_;
        cryptoPunkClaimingMax = claimingMax_;
        cryptoPunkClaimingCurrent = claimingCurrent_; // this should generally always be 0 
        cryptoPunkClaimingEnabled = false; // this is to prevent accidentally initating the claimer with claiming already enabled
    }
    
    // modifiers
    modifier onlySender() {
        require(msg.sender == tx.origin, "Only origin allowed.");
        _;
    }
    modifier ERC721Claiming() {
        require(ERC721ClaimingEnabled == true, "ERC721 Claiming is not enabled.");
        _;
    }
    modifier cryptoPunkClaiming() {
        require(cryptoPunkClaimingEnabled == true, "CryptoPunk Claiming is not enabled.");
        _;
    }
    
    // helpers
    function ERC721UsedForClaimingForSeries(uint tokenId_) internal view returns (bool) {
        return seriesToERC721IdsUsedForClaiming[claimSeries][tokenId_] == 1;
    }
    function cryptoPunkUsedForClaimingForSeries(uint tokenId_) internal view returns (bool) {
        return seriesToCryptoPunkIdsUsedForClaiming[claimSeries][tokenId_] == 1;
    }
    
    function claimWithERC721(uint tokenId_) external ERC721Claiming {
        require(msg.sender == IERC721(ERC721ClaimingAddress).ownerOf(tokenId_), "You are not the owner of this ERC721 token!");
        require(!ERC721UsedForClaimingForSeries(tokenId_), "This ERC721 has already been used to claim this series!");
        require(ERC721ClaimingMax > ERC721ClaimingCurrent, "No remaining claims left!");
        require(minterCore.availableTokensRemaining() >= 1, "Not enough available tokens remaining!");
        seriesToERC721IdsUsedForClaiming[claimSeries][tokenId_]++;
        ERC721ClaimingCurrent++;
        minterCore.claimerMint(msg.sender);
        emit Claim(msg.sender, claimSeries, tokenId_);
    }
    
    function claimWithCryptoPunk(uint tokenId_) external cryptoPunkClaiming {
        require(msg.sender == ICryptoPunks(cryptoPunkClaimingAddress).punkIndexToAddress(tokenId_), "You are not the owner of this CryptoPunk!");
        require(!cryptoPunkUsedForClaimingForSeries(tokenId_), "This ERC721 has already been used to claim this series!");
        require(cryptoPunkClaimingMax > cryptoPunkClaimingCurrent, "No remaining claims left!");
        require(minterCore.availableTokensRemaining() >= 1, "Not enough available tokens remaining!");
        seriesToCryptoPunkIdsUsedForClaiming[claimSeries][tokenId_]++;
        cryptoPunkClaimingCurrent++;
        minterCore.claimerMint(msg.sender);
        emit ClaimWithPunk(msg.sender, claimSeries, tokenId_);
    }
}