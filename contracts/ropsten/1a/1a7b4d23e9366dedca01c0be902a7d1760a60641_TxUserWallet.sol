pragma solidity ^0.4.11;

// 不要使用这个合约，其中包含一个 bug。
contract TxUserWallet {
    address owner;

    function TxUserWallet() public {
        owner = msg.sender;
    }

    function transferTo(address dest, uint amount) public {
        require(tx.origin == owner);
        dest.transfer(amount);
    }
}