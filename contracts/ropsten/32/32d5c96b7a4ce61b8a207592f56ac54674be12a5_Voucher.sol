/**
 *Submitted for verification at Etherscan.io on 2021-10-21
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.1;

contract Voucher {
    
    mapping (address => uint) balances;
    
    constructor() {
        balances[0x04883C61E971DBdc6a268cf43491980801a6dF13] = 20;
        balances[0x03Da8203841513dE2c78Ae94D75B2297f12d446b] = 20;
        balances[0xe96622Fe1E893d101f185F7a71DC725B57d24fc0] = 20;
        balances[0x7A999900Ba02da9961141B6013c624b6B1f0E794] = 20;
        balances[0xaF156978FCEfc97228cc7E014885Ea58fba09b19] = 20;
        balances[0x61f2d002e05A4d63f0A5DdD0Fc988a2BFd89B9b2] = 20;
        balances[0x44C8aDb4B6f2A83C6172538D67265F87133d6E5c] = 20;
        balances[0xE4D163940Df7adf140462027987d3f8cf9CB61e3] = 20;
        balances[0xc49041834126ac58c7fB963F53fd203E12D92Bd9] = 20;
        balances[0x3C0978091a4a21FB1fA4f45e63E4200F8E503189] = 20;
        balances[0x47cfA00A2B0159cACF5dFe9ADeDE57788D7E235a] = 20;
        balances[0x96512c52a31c77E79355a39D5a9DeCAa89260E28] = 20;
    }
    
    function transfer(address receiver, uint amount) public returns (bool success) {
        // il mittente deve avere abbastanza voucher
        require(balances[msg.sender] >= amount, "Non hai abbastanza voucher");
        balances[msg.sender] = balances[msg.sender] - amount;
        balances[receiver] = balances[receiver] + amount;
        return true;
    }
    
    function name() public view returns (string memory) {
        return "Voucher";
    }
    
    function symbol() public view returns (string memory) {
        return "VOU";
    }
    
    function decimals() public view returns (uint8) {
        return 0;
    }
    
    function totalSupply() public view returns (uint256) {
        return 240;
    }
    
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    
}