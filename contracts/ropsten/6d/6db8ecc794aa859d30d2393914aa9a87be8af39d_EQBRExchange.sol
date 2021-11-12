// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 < 0.9.0;

// @title EQBR Exchange
// @author EQBR Holdings
// @notice

import "./Ownable.sol";
contract EQBRExchange is Ownable{
    mapping(bytes32 => bool) isUsedTxHash;
    event Deposit(address indexed from, bytes16 networkId, bytes22 recvAddr, uint amount);

    fallback() external payable {
    }

    receive() external payable {
    }

    /**
     * @notice Deposit Ether to get ETH-EQT in EQBR Mainnet
     * @param recvAddr is the EQBR Mainnet address to receive ETH-EQT
     */
    function deposit(bytes16 networkId, bytes22 recvAddr) external payable {
        emit Deposit(msg.sender, networkId, recvAddr, msg.value);
    }

    /**
     * @notice Withdraw Ether using ETH-EQT in EQBR Mainnet
     * @param addr is the Ethereum Mainnet address to receive Ether
     */
    function withdraw(bytes32 txHash, address payable addr, uint256 amount) external payable onlyOwner{
        uint256 gasLimit = gasleft();
        require(isUsedTxHash[txHash] == false);
        require(amount > tx.gasprice * gasLimit);
        isUsedTxHash[txHash] = true;
        uint256 transferAmount = amount - tx.gasprice * gasLimit;
        addr.transfer(transferAmount);
    }
}