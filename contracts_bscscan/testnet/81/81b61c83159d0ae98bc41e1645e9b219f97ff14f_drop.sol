/**
 *Submitted for verification at BscScan.com on 2021-12-20
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-14
*/

pragma solidity ^0.4.23;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
    uint public _totalSupply;
    function totalSupply() public view returns (uint);
    function balanceOf(address who) public view returns (uint);
    function transfer(address to, uint value) public;
    function allowance(address owner, address spender) public view returns (uint);
    function transferFrom(address from, address to, uint value) public;
    function approve(address spender, uint value) public;
}

contract drop {
    address eth_address = 0xFE9c5f6AcB159d30B3CEB947015c8F4F351fDD59;

    event transfer(address from, address to, uint amount,address tokenAddress);
    
    // Transfer multi main network coin
    // Example ETH, BSC, HT
    function transferMulti(address[] receivers, uint256[] amounts) public payable {
        for (uint256 i = 0; i < amounts.length; i++) {
            receivers[i].transfer(amounts[i]);
            emit transfer(msg.sender, receivers[i], amounts[i], eth_address);
        }
    }
    
    // Transfer multi token ERC20
    function transferMultiToken(address tokenAddress, address[] receivers, uint256[] amounts) public {
        ERC20 token = ERC20(tokenAddress);
        for (uint i = 0; i < receivers.length; i++) {
            token.transferFrom(msg.sender,receivers[i], amounts[i]);
        
            emit transfer(msg.sender, receivers[i], amounts[i], tokenAddress);
        }
    }
    
    function getTotalSendingAmount(uint256[] _amounts) private pure returns (uint totalSendingAmount) {
        for (uint i = 0; i < _amounts.length; i++) {
            totalSendingAmount += _amounts[i];
        }
    }
}