/**
 *Submitted for verification at Etherscan.io on 2022-01-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

/**
 * @title SharedWalletRepository
 */
contract SharedWalletRepository {
    SharedWallet[] public wallets;

    mapping(uint => mapping(address => uint)) balances;
    mapping(uint => mapping(address => uint)) isMember;
    mapping(uint => Transaction[]) transactions;
    mapping(uint => mapping(address => bool)) approvals;

    struct SharedWallet {
        uint minDeposit;
        uint balance;
        uint numTransactions;
        address[] members;
    }

    struct Transaction {
        uint walletId;
        address requester;
        string description;
        address payable destination;
        uint value;
        uint numApprovals;
        bool approved;
    }

    event WalletCreated(uint walletId);
    event WalletJoined(uint walletId, address member);
    event WalletFunded(uint walletId, address member);
    event WalletLeft(uint walletId, address member);
    event TransactionRequested(uint walletId, address requester, string description, address destination, uint value);
    event TransactionApproved(uint walletId, uint transactionId, address member);
    event TransactionSent(uint walletId, uint transactionId);

    function createWallet(uint _minDeposit) public returns(uint _walletId) {
        SharedWallet memory _wallet;
        _wallet.minDeposit = _minDeposit;
        _wallet.balance = 0;
        wallets.push(_wallet);
        _walletId = wallets.length - 1;
        emit WalletCreated(_walletId);
    }

    function joinWallet(uint _walletId) payable public {
        SharedWallet storage _wallet = wallets[_walletId];
        require(msg.value >= _wallet.minDeposit, "Transaction value below wallet minimum deposit");
        require(isMember[_walletId][msg.sender] == 0, "Address is already a member");
        balances[_walletId][msg.sender] = msg.value;
        _wallet.balance += msg.value;
        _wallet.members.push(msg.sender);
        isMember[_walletId][msg.sender] = _wallet.members.length;
        emit WalletJoined(_walletId, msg.sender);
    }

    function fundWallet(uint _walletId) payable public {
        SharedWallet storage _wallet = wallets[_walletId];
        require(isMember[_walletId][msg.sender] > 0, "Address is not a member");
        balances[_walletId][msg.sender] += msg.value;
        _wallet.balance += msg.value;
        emit WalletFunded(_walletId, msg.sender);
    }

    function leaveWallet(uint _walletId) public {
        SharedWallet storage _wallet = wallets[_walletId];
        require(isMember[_walletId][msg.sender] > 0, "Address is not a member");
        uint refundValue = balances[_walletId][msg.sender];
        balances[_walletId][msg.sender] = 0;
        uint _memberId = isMember[_walletId][msg.sender];
        delete isMember[_walletId][msg.sender];
        _wallet.members[_memberId] = _wallet.members[_wallet.members.length - 1];
        _wallet.members.pop();
        _wallet.balance -= refundValue;

        payable(msg.sender).transfer(refundValue);
        emit WalletLeft(_walletId, msg.sender);
    }

    function requestTransaction(uint _walletId, string memory _description, address payable _destination, uint _value) public {
        require(isMember[_walletId][msg.sender] > 0, "Address is not a member");
        Transaction memory _transaction = Transaction(
            _walletId, msg.sender, _description, _destination, _value, 0, false
        );
        transactions[_walletId].push(_transaction);
        emit TransactionRequested(_walletId, msg.sender, _description, _destination, _value);
    }

    function approveTransaction(uint _walletId, uint _transactionId) public {
        SharedWallet memory _wallet = wallets[_walletId];
        require(isMember[_walletId][msg.sender] > 0, "Address is not a member");
        Transaction storage _transaction = transactions[_walletId][_transactionId];
        require(approvals[_transactionId][msg.sender] == false, "Transaction already approved by member");
        approvals[_transactionId][msg.sender] = true;
        _transaction.numApprovals += 1;
        emit TransactionApproved(_walletId, _transactionId, msg.sender);
        
        if(_transaction.numApprovals > (_wallet.members.length / 2)) {
            _transaction.approved = true;
            sendTransaction(_walletId, _transaction);
            emit TransactionSent(_walletId, _transactionId);
        }
    }

    function sendTransaction(uint _walletId, Transaction memory _transaction) private {
        SharedWallet storage _wallet = wallets[_walletId];
        require(_wallet.balance >= _transaction.value, "Wallet balance too low to send transaction");
        uint _splitValue = _transaction.value / _wallet.members.length;
        for (uint i = 0; i < _wallet.members.length; i++) {
            address _member = _wallet.members[i];
            require(balances[_walletId][_member] >= _splitValue);
            balances[_walletId][_member] -= _splitValue;
        }
        _wallet.balance -= _transaction.value;
        _transaction.destination.transfer(_transaction.value);
    }

    function getWallet(uint _walletId) public view returns (SharedWallet memory) {
        return wallets[_walletId];
    }

    function balanceOf(uint _walletId, address _member) public view returns (uint) {
        return balances[_walletId][_member];
    }

    function isWalletMember(uint _walletId, address _member) public view returns (bool) {
        return isMember[_walletId][_member] > 0;
    }

    function getTransaction(uint _walletId, uint _transactionId) public view returns (Transaction memory) {
        return transactions[_walletId][_transactionId];
    }

    function getApproval(uint _transactionId, address _member) public view returns (bool) {
        return approvals[_transactionId][_member];
    }
}