// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "ERC20.sol";


contract KiboToken is ERC20 {
    
    /// @notice Address which may mint new tokens
    address public minter;

    /// @notice The timestamp after which minting may occur
    uint public mintingAllowedAfter;

    /// @notice Minimum time between mints
    uint32 public constant minimumTimeBetweenMints = 1 days * 365;

    /// @notice Cap on the percentage of totalSupply that can be minted at each mint
    uint8 public constant mintCap = 2;
    
    function safe96(uint n, string memory errorMessage) internal pure returns (uint96) {
        require(n < 2**96, errorMessage);
        return uint96(n);
    }
    
    /**
     * @notice Mint new tokens
     * @param dst The address of the destination account
     * @param rawAmount The number of tokens to be minted
     */
    function mint(address dst, uint rawAmount) external {
        require(msg.sender == minter, "KiboToken::mint: only the minter can mint");
        require(block.timestamp >= mintingAllowedAfter, "KiboToken::mint: minting not allowed yet");
        require(dst != address(0), "KiboToken::mint: cannot transfer to the zero address");

        // record the mint
        mintingAllowedAfter = block.timestamp + minimumTimeBetweenMints;

        // mint the amount
        uint96 amount = safe96(rawAmount, "KiboToken::mint: amount exceeds 96 bits");
        require(amount <= totalSupply() * mintCap / 100, "KiboToken::mint: exceeded mint cap");
        
        _mint(dst, amount);
    }
    
    constructor (address minter_, uint mintingAllowedAfter_) ERC20('KiboToken', 'KIBO')
    {
        require(mintingAllowedAfter_ >= block.timestamp, "KiboToken::constructor: minting can only begin after deployment");
        mintingAllowedAfter = mintingAllowedAfter_;
        minter = minter_;

        _mint(msg.sender, 30000000 * 10 ** uint(decimals()));
    }
}