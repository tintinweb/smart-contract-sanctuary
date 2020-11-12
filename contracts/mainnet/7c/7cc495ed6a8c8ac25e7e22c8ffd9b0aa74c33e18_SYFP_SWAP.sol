pragma solidity ^0.6.0;
// SPDX-License-Identifier: UNLICENSED
// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// ----------------------------------------------------------------------------
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address tokenOwner) external view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) external view returns (uint256 remaining);
    function transfer(address to, uint256 tokens) external returns (bool success);
    function approve(address spender, uint256 tokens) external returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) external returns (bool success);
    function burnTokens(uint256 _amount) external;
    function _transfer(address to, uint256 tokens) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}


contract SYFP_SWAP{
    address YFP_address = 0x96d62cdCD1cc49cb6eE99c867CB8812bea86B9FA;
    address SYFP_address = 0xC11396e14990ebE98a09F8639a082C03Eb9dB55a;
    
    function SWAP(uint256 _tokens) public{
        require(IERC20(YFP_address).transferFrom(address(msg.sender), address(this), _tokens), "Transfer of funds failed!");
        IERC20(YFP_address).transfer(address(0), _tokens);
       
        require(IERC20(SYFP_address)._transfer(msg.sender, _tokens), "SYFP Tokens Not available");
    }
   
}