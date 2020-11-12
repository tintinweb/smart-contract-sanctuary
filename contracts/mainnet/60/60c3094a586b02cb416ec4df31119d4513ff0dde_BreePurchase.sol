// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// ----------------------------------------------------------------------------
abstract contract IERC20 {
    function totalSupply() external virtual view returns (uint256);
    function balanceOf(address tokenOwner) external virtual view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) external virtual view returns (uint256 remaining);
    function transfer(address to, uint256 tokens) external virtual returns (bool success);
    function approve(address spender, uint256 tokens) external virtual returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) external virtual returns (bool success);
    function burnFrom(address account, uint256 amount) public virtual;
    
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

contract BreePurchase{

    address constant private SBREE_TOKEN_ADDRESS = 0x25377ddb16c79C93B0CBf46809C8dE8765f03FCd;
    address constant private BREE_TOKEN_ADDRESS = 0x4639cd8cd52EC1CF2E496a606ce28D8AfB1C792F;
    
    event TOKENSPURCHASED(address indexed _purchaser, uint256 indexed _tokens);
    
    function purchase(address assetAddress, uint256 amountAsset) public{
        require(assetAddress == SBREE_TOKEN_ADDRESS, "NOT ACCEPTED: Unaccepted payment asset provided");
        require(IERC20(BREE_TOKEN_ADDRESS).balanceOf(address(this)) >= amountAsset, "Balance: Insufficient liquidity");
        _purchase(assetAddress, amountAsset);
    }
    
    function _purchase(address assetAddress, uint256 assetAmount) internal{
        // burn the received tokens
        IERC20(assetAddress).burnFrom(msg.sender, assetAmount);
        
        // send tokens to the purchaser
        IERC20(BREE_TOKEN_ADDRESS).transfer(msg.sender, assetAmount);
        
        emit TOKENSPURCHASED(msg.sender, assetAmount);
    }
}