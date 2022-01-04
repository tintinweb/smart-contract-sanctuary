// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC721Receiver.sol";
import "./IERC721.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./Ownable.sol";

abstract contract IImpishSpiral is IERC721 {
    uint256 public _tokenIdCounter;
}
abstract contract IRandomWalkNFT is IERC721 {
    uint256 public nextTokenId;
}

abstract contract ISpiralBits is IERC20 {
    function mintSpiralBits(address to, uint256 amount) public virtual;
}

abstract contract IStakingContract {
    uint256 public totalStaked;
}

contract RWNFTStaking is IERC721Receiver, ReentrancyGuard, Ownable {
    // How many spiral bits per second are awarded to a staked spiral
    // 0.0167 SPIRALBITS per second. (1 SPIRALBIT per 60 seconds)
    uint256 constant public SPIRALBITS_PER_SECOND = 0.0167 ether;

    // We're staking this NFT in this contract
    IRandomWalkNFT public randomWalkNFT;

    // The token that is being issued for staking
    ISpiralBits public spiralbits;

    // The other NFT contract - To calculate bonuses
    IImpishSpiral public impishspiral;
    IStakingContract public spiralStaking;

    // Total number of NFTs staked in this contract
    uint256 public totalStaked;

    constructor(address _impishspiral, address _spiralbits, address _rwnft) {
        impishspiral = IImpishSpiral(_impishspiral);
        spiralbits = ISpiralBits(_spiralbits);
        
        randomWalkNFT = IRandomWalkNFT(_rwnft);
    }

    bool public paused = false;

    // Pause is a one-way function. Can't unpause it. 
    function pause() public onlyOwner {
        paused = true;
    }

    modifier notPaused() {
        require(!paused, "Paused");
        _;
    }

    function setSpiralStakingContract(address _spiralStaking) external onlyOwner {
        require(spiralStaking == IStakingContract(address(0)), "alreadyset");
        spiralStaking = IStakingContract(_spiralStaking);
    }

    function _claimSpiralBits(address owner) internal {
        // Claim all the spiralbits so far
        uint256 spiralBitsToClaim = claimsPending(owner);
        
        stakedNFTs[owner].claimedSpiralBits += uint128(spiralBitsToClaim);
        stakedNFTs[owner].lastClaimTime = uint64(block.timestamp);
    }

    function claimsPending(address owner) public view returns (uint256) {
        uint256 spiralBitsToClaim = stakedNFTs[owner].numNFTsStaked * 
                    uint256(uint64(block.timestamp) - stakedNFTs[owner].lastClaimTime) * 
                    SPIRALBITS_PER_SECOND;

        return spiralBitsToClaim;
    }
    
    function claimsPendingTotal(address owner) public view returns (uint256) {
        return claimsPending(owner) + stakedNFTs[owner].claimedSpiralBits;
    }

    function currentBonusInBips() public view returns (uint256) {
        return 100 * 100 * spiralStaking.totalStaked() / impishspiral._tokenIdCounter();
    }

    // Stake a list of Spiral tokenIDs. The msg.sender needs to own the tokenIds, and the tokens
    // are staked with msg.sender as the owner
    function stakeNFTs(uint32[] calldata tokenIds) external notPaused {
        stakeNFTsForOwner(tokenIds, msg.sender);
    }

    // Stake the NFTs and make them withdrawable by the owner. The msg.sender still needs to own
    // the NFTs that are being staked.
    // This is used by aggregator contracts.
    function stakeNFTsForOwner(uint32[] calldata tokenIds, address owner) public nonReentrant notPaused {
        require(tokenIds.length > 0, "NoTokens");
        // Claim any SPIRALBITS outstanding for this owner
        _claimSpiralBits(owner);

        totalStaked += tokenIds.length;
        for (uint32 i; i < tokenIds.length; i++) {
            uint256 tokenId = uint256(tokenIds[i]);
            require(randomWalkNFT.ownerOf(tokenId) == msg.sender, "DontOwnToken");

            // Add the spiral to staked owner list to keep track of staked tokens
            _addTokenToOwnerEnumeration(owner, tokenId);
            stakedTokenOwners[tokenId].owner = owner;

            // Add this spiral to the staked struct
            stakedNFTs[owner].numNFTsStaked += 1;

            // Transfer the actual NFT to this staking contract.
            randomWalkNFT.safeTransferFrom(msg.sender, address(this), tokenId);
        }
    }

    // Unstake a spiral. If withdraw is true, then SPIRALBITS are also claimed and sent
    function unstakeNFTs(uint32[] calldata tokenIds, bool withdraw) external nonReentrant {
        // Claim any SPIRALBITS outstanding for this owner
        _claimSpiralBits(msg.sender);

        for (uint32 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = uint256(tokenIds[i]);
            require(randomWalkNFT.ownerOf(tokenId) == address(this), "NotStaked");
            require(stakedTokenOwners[tokenId].owner == msg.sender, "NotYours");

            // Remove the spiral -> staked owner list to keep track of staked tokens
             _removeTokenFromOwnerEnumeration(msg.sender, tokenId);

            // Remove this spiral from the staked struct
            stakedNFTs[msg.sender].numNFTsStaked -= 1;
            
            // Transfer the NFT out
            randomWalkNFT.safeTransferFrom(address(this), msg.sender, tokenId);
        }
        totalStaked -= tokenIds.length;

        if (withdraw) {
            uint256 spiralBitsToMint = stakedNFTs[msg.sender].claimedSpiralBits;
            stakedNFTs[msg.sender].claimedSpiralBits = 0;

            uint256 bonus = spiralBitsToMint * currentBonusInBips() / 10000;

            // Mint and send the new spiral bits to the owners
            spiralbits.mintSpiralBits(msg.sender, spiralBitsToMint + bonus);
        }
    }

    // =========
    // Keep track of staked NFTs
    // =========
    struct StakedNFTs {
        uint32 numNFTsStaked;       // Number of NFTs staked by this owner
        uint64 lastClaimTime;       // Last timestamp that the rewards were accumulated into claimedSpiralBits
        uint128 claimedSpiralBits;  // Already claimed (but not withdrawn) spiralBits before lastClaimTime
        mapping(uint256 => uint256) ownedTokens; // index => tokenId
    }

    struct TokenIdInfo {
        uint256 ownedTokensIndex;
        address owner;
    }

    // Mapping of Spiral TokenID => Address that staked it.
    mapping(uint256 => TokenIdInfo) public stakedTokenOwners;

    // Address that staked the token => Token Accounting
    mapping(address => StakedNFTs) public stakedNFTs;
    
    // Returns a list of token Ids owned by _owner.
    function walletOfOwner(address _owner) public view
        returns (uint256[] memory) {
        uint256 tokenCount = stakedNFTs[_owner].numNFTsStaked;

        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        }

        uint256[] memory result = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            result[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return result;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual returns (uint256) {
        require(index < stakedNFTs[owner].numNFTsStaked, "ERC721Enumerable: owner index out of bounds");
        return stakedNFTs[owner].ownedTokens[index];
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param owner address representing the owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address owner, uint256 tokenId) private {
        uint256 length = stakedNFTs[owner].numNFTsStaked;
        stakedNFTs[owner].ownedTokens[length] = tokenId;
        stakedTokenOwners[tokenId].ownedTokensIndex = length;
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = stakedNFTs[from].numNFTsStaked - 1;
        uint256 tokenIndex = stakedTokenOwners[tokenId].ownedTokensIndex;

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = stakedNFTs[from].ownedTokens[lastTokenIndex];

            stakedNFTs[from].ownedTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            stakedTokenOwners[lastTokenId].ownedTokensIndex = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete stakedTokenOwners[tokenId];
        delete stakedNFTs[from].ownedTokens[lastTokenIndex];
    }

    // Function that marks this contract can accept incoming NFT transfers
    function onERC721Received(address, address, uint256 , bytes calldata) public view returns(bytes4) {
        // Only accept NFT transfers from RandomWalkNFT
        require(msg.sender == address(randomWalkNFT), "NFT not recognized");

        // Return this value to accept the NFT
        return IERC721Receiver.onERC721Received.selector;
    }
}