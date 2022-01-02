/**
 *Submitted for verification at Etherscan.io on 2022-01-02
*/

pragma solidity ^0.4.16;

contract CoinTest {
    address public minter;

    mapping(address => uint256) public balances;

    event Sent(address from, address to, uint256 amount);

    function CoinTest() public {
        minter = msg.sender;
    }

    function mint(address recevier, uint256 amount) public {
        if (msg.sender != minter) {
            return;
        } else {
            balances[recevier] += amount;
        }
    }

    function send(address recevier, uint256 amount) public {
        if (balances[msg.sender] < amount) {
            return;
        } else {
            balances[msg.sender] -= amount;
            balances[recevier] += amount;
            Sent(msg.sender, recevier, amount);
        }
    }
}