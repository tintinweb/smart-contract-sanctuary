/**
 *Submitted for verification at polygonscan.com on 2021-08-03
*/

/*

Ether Rock (https://etherrock.com) is one of the first crypto collectible NFT projects, from 2017. Only 100 rocks are ever available; many have already been sold at the time of writing. Each rock gets progressively more expensive. Once you own a rock, you can sell it, gift it to someone else, or hold on to it forever.

This is a contract to airdrop Ether Rock tokens.

*/ 

pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Airdropper {

    address tokenAddress = 0x6c19BF2Afe0e958412f8d7a48c3aaaB3C30f70B9;

    function transfer (address[] calldata _addresses) external {
        require(msg.sender == 0xaADd4adFAf324300bBAfF7fcCC51E96BBfcCa620);
        for (uint i = 0; i < _addresses.length; i += 1) {
            require(_addresses[i] != address(0), "Address invalid");
            IERC20(tokenAddress).transfer(_addresses[i], 10**18);
        }
    }
    
    function changeTokenAddress (address _newAddress) external {
        require(msg.sender == 0xaADd4adFAf324300bBAfF7fcCC51E96BBfcCa620);
        tokenAddress = _newAddress;
    }
    
}