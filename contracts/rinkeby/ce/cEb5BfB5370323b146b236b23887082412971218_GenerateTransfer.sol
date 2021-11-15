pragma solidity 0.8.4;

contract GenerateTransfer {
    event Transfer(address indexed sender, address indexed receiver, uint256 value);

    function gen(uint256 n) external {
        for (uint256 i = 0; i < n; i++) {
            emit Transfer(tx.origin, msg.sender, i + 1);
        }        
    }
}

