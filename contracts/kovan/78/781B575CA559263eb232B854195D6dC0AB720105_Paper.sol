// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import './ERC20.sol';
import './ERC20Snapshot.sol';
import './IERC721Enumerable.sol';
import './draft-ERC20Permit.sol';
import './ERC20Votes.sol';
import './Ownable.sol';

contract Paper is ERC20, ERC20Permit, ERC20Votes, ERC20Snapshot, Ownable {
    // Dope Wars Loot: https://etherscan.io/address/0x8707276DF042E89669d69A177d3DA7dC78bd8723
    IERC721Enumerable public loot;
    // DopeDAO timelock: https://etherscan.io/address/0xb57ab8767cae33be61ff15167134861865f7d22c
    address public timelock = 0xB57Ab8767CAe33bE61fF15167134861865F7D22C;

    // 8000 tokens number 1-8000
    uint256 public tokenIdStart = 1;
    uint256 public tokenIdEnd = 8000;

    // Give out 1bn of tokens, evenly split across each NFT
    uint256 public paperPerTokenId = (1000000000 * (10**decimals())) / tokenIdEnd;

    // track claimedTokens
    mapping(uint256 => bool) public claimedByTokenId;

    constructor(address dope) ERC20('Paper', 'PAPER') ERC20Permit('PAPER') {
        loot = IERC721Enumerable(dope);
        transferOwnership(timelock);
    }

    function snapshot() external onlyOwner {
        _snapshot();
    }

    /// @notice Claim Paper for a given Dope Wars Loot ID
    /// @param tokenId The tokenId of the Dope Wars Loot NFT
    function claimById(uint256 tokenId) external {
        // Follow the Checks-Effects-Interactions pattern to prevent reentrancy
        // attacks

        // Checks

        // Check that the msgSender owns the token that is being claimed
        require(_msgSender() == loot.ownerOf(tokenId), 'MUST_OWN_TOKEN_ID');

        // Further Checks, Effects, and Interactions are contained within the
        // _claim() function
        _claim(tokenId, _msgSender());
    }

    /// @notice Claim Paper for all tokens owned by the sender
    /// @notice This function will run out of gas if you have too much loot! If
    /// this is a concern, you should use claimRangeForOwner and claim Dope in
    /// batches.
    function claimAllForOwner() external {
        uint256 tokenBalanceOwner = loot.balanceOf(_msgSender());

        // Checks
        require(tokenBalanceOwner > 0, 'NO_TOKENS_OWNED');

        // i < tokenBalanceOwner because tokenBalanceOwner is 1-indexed
        for (uint256 i = 0; i < tokenBalanceOwner; i++) {
            // Further Checks, Effects, and Interactions are contained within
            // the _claim() function
            _claim(loot.tokenOfOwnerByIndex(_msgSender(), i), _msgSender());
        }
    }

    /// @notice Claim Paper for all tokens owned by the sender within a
    /// given range
    /// @notice This function is useful if you own too much DWL to claim all at
    /// once or if you want to leave some Paper unclaimed.
    function claimRangeForOwner(uint256 ownerIndexStart, uint256 ownerIndexEnd) external {
        uint256 tokenBalanceOwner = loot.balanceOf(_msgSender());

        // Checks
        require(tokenBalanceOwner > 0, 'NO_TOKENS_OWNED');

        // We use < for ownerIndexEnd and tokenBalanceOwner because
        // tokenOfOwnerByIndex is 0-indexed while the token balance is 1-indexed
        require(ownerIndexStart >= 0 && ownerIndexEnd < tokenBalanceOwner, 'INDEX_OUT_OF_RANGE');

        // i <= ownerIndexEnd because ownerIndexEnd is 0-indexed
        for (uint256 i = ownerIndexStart; i <= ownerIndexEnd; i++) {
            // Further Checks, Effects, and Interactions are contained within
            // the _claim() function
            _claim(loot.tokenOfOwnerByIndex(_msgSender(), i), _msgSender());
        }
    }

    /// @dev Internal function to mint Paper upon claiming
    function _claim(uint256 tokenId, address tokenOwner) internal {
        // Checks
        // Check that the token ID is in range
        // We use >= and <= to here because all of the token IDs are 0-indexed
        require(tokenId >= tokenIdStart && tokenId <= tokenIdEnd, 'TOKEN_ID_OUT_OF_RANGE');

        // Check that Paper have not already been claimed for a given tokenId
        require(!claimedByTokenId[tokenId], 'PAPER_CLAIMED_FOR_TOKEN_ID');

        // Effects

        // Mark that Paper has been claimed for the
        // given tokenId
        claimedByTokenId[tokenId] = true;

        // Interactions

        // Send Paper to the owner of the token ID
        _mint(tokenOwner, paperPerTokenId);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Snapshot) {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._burn(account, amount);
    }
}