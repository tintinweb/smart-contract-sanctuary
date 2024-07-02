/**
 *Submitted for verification at cronoscan.com on 2022-06-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract DragonWallet {
    uint256 private constant DRAGON_MULTISIG_VERSION = 1;
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public numConfirmationsRequired;

    struct Transaction {
        address to;
        uint256 value;
        uint256 txtype;
        uint256 vote;
        uint256 time;
        address createdby;
        string message;
        bytes data;
        bool executed;
        uint256 numConfirmations;
    }

    mapping(uint256 => mapping(address => bool)) public isConfirmed;

    Transaction[] public transactions;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "Request Not From A Owner");
        _;
    }

    modifier txExists(uint256 _txIndex) {
        require(_txIndex < transactions.length, "Invalid TXID");
        _;
    }

    modifier notExecuted(uint256 _txIndex) {
        require(
            !transactions[_txIndex].executed,
            "Transaction Already Executed"
        );
        _;
    }

    modifier notConfirmed(uint256 _txIndex) {
        require(
            !isConfirmed[_txIndex][msg.sender],
            "Transaction Already Confirmed"
        );
        _;
    }
    address public dragonaddress;
    uint256 public createTime;

    constructor(address[] memory _owners, uint256 _numConfirmationsRequired) {
        require(_owners.length > 0, "Need Owners To Setup");

        require(
            _numConfirmationsRequired > 0 &&
                _numConfirmationsRequired <= _owners.length,
            "invalid number of required confirmations"
        );

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }
        dragonaddress = address(this);
        numConfirmationsRequired = _numConfirmationsRequired;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function submitTransaction(
        address _to,
        uint256 _value,
        uint256 _txtype,
        uint256 _vote,
        string memory _message,
        bytes memory _data
    ) public onlyOwner {
        uint256 txIndex = transactions.length;
        createTime = block.timestamp;
        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                txtype: _txtype,
                vote: _vote,
                time: createTime,
                createdby: msg.sender,
                message: _message,
                data: _data,
                executed: false,
                numConfirmations: 0
            })
        );

        emit SubmitTransaction(
            msg.sender,
            txIndex,
            _to,
            _value,
            _txtype,
            _vote,
            _message,
            _data
        );
    }

    function confirmTransaction(uint256 _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;
        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    function removeTransaction(uint256 _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        require(
            transaction.numConfirmations == 0,
            "Another Owner Already Confirmed"
        );
        require(msg.sender == transaction.createdby, "You Don't Have Access!");
        for (uint256 i = _txIndex; i < transactions.length - 1; i++) {
            transactions[i] = transactions[i + 1];
        }
        transactions.pop();
        emit RemoveTransaction(msg.sender, _txIndex);
    }

    function executeTransaction(uint256 _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "cannot execute tx"
        );
        transaction.executed = true;
        if (transaction.txtype == 1) {
            require(!isOwner[transaction.to], "owner not unique");
            isOwner[transaction.to] = true;
            owners.push(transaction.to);
            emit ExecuteTransaction(msg.sender, _txIndex);
        } else if (transaction.txtype == 2) {
            require(isOwner[transaction.to], "owner exist");
            isOwner[transaction.to] = false;
            require(transaction.vote < owners.length, "index out of bound");
            for (uint256 i = transaction.vote; i < owners.length - 1; i++) {
                owners[i] = owners[i + 1];
            }
            owners.pop();
            emit ExecuteTransaction(msg.sender, _txIndex);
        } else if (transaction.txtype == 3) {
            require(transaction.vote <= owners.length, "Invalid Vote Count");
            numConfirmationsRequired = transaction.vote;
            emit ExecuteTransaction(msg.sender, _txIndex);
        } else if (transaction.txtype == 4) {
            (bool success, ) = transaction.to.call(transaction.data);
            require(success, "tx failed");
            emit ExecuteTransaction(msg.sender, _txIndex);
        } else {
            (bool success, ) = transaction.to.call{value: transaction.value}(
                transaction.data
            );
            require(success, "tx failed");
            emit ExecuteTransaction(msg.sender, _txIndex);
        }
    }

    function revokeConfirmation(uint256 _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        require(isConfirmed[_txIndex][msg.sender], "tx not confirmed");
        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;
        emit RevokeConfirmation(msg.sender, _txIndex);
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() public view returns (uint256) {
        return transactions.length;
    }

    function balanceOf() public view returns (uint256) {
        return address(this).balance;
    }

    function getTransaction(uint256 _txIndex)
        public
        view
        returns (
            address to,
            uint256 value,
            address createdby,
            uint256 txtype,
            uint256 time,
            string memory message,
            bytes memory data,
            bool executed,
            uint256 numConfirmations
        )
    {
        Transaction storage transaction = transactions[_txIndex];
        return (
            transaction.to,
            transaction.value,
            transaction.createdby,
            transaction.txtype,
            transaction.time,
            transaction.message,
            transaction.data,
            transaction.executed,
            transaction.numConfirmations
        );
    }

    event Deposit(address indexed sender, uint256 amount, uint256 balance);
    event SubmitTransaction(
        address indexed owner,
        uint256 indexed txIndex,
        address indexed to,
        uint256 value,
        uint256 txtype,
        uint256 vote,
        string message,
        bytes data
    );

    event ConfirmTransaction(address indexed owner, uint256 indexed txIndex);
    event RemoveTransaction(address indexed owner, uint256 indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint256 indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint256 indexed txIndex);
}

contract DragonWalletSummoners {
    uint256 private constant DRAGON_SUMMONER_VERSION = 1;
    DragonWallet[] public dragonwallets;
    struct DragonOwner {
        address summoner;
        address dragonsafe;
    }

    mapping(address => DragonOwner) public DragonOwners;

    function summonDragon(address[] memory _summoner, uint256 _votes) public {
        DragonWallet dragonwallet = new DragonWallet(_summoner, _votes);
        DragonOwners[msg.sender] = DragonOwner(
            msg.sender,
            dragonwallet.dragonaddress()
        );
        dragonwallets.push(dragonwallet);
    }

    function getDragonWallet(uint256 _index)
        public
        view
        returns (address dragonaddress)
    {
        DragonWallet dragonwallet = dragonwallets[_index];
        return (dragonwallet.dragonaddress());
    }
}