// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

contract MultisigWallet {
    // events of sig
    event Deposit(address indexed sender, uint256 amount, uint256 balance);
    event SubmitTx(
        address indexed owner,
        uint256 indexed txIDX,
        address indexed to,
        uint256 value,
        bytes data
    );
    event ConfirmTx(address indexed owner, uint256 txIDX);
    event RevokeConfirmation(address indexed owner, uint256 txIDX);
    event ExecuteTx(address indexed owner, uint256 txIDX);

    // fields
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public numConfirmationRequired;

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 numConfirmation;
    }

    mapping(uint256 => mapping(address => bool)) public isConfirmed;

    Transaction[] public transactions;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "not the owner");
        _;
    }

    modifier txExists(uint256 _txIDX) {
        require(_txIDX < transactions.length, "tx not exists");
        _;
    }

    modifier notExecuted(uint256 _txIDX) {
        require(!transactions[_txIDX].executed, "tx already confirmed");
        _;
    }

    modifier notConfirmed(uint256 _txIDX) {
        require(!isConfirmed[_txIDX][msg.sender], "tx already confirmed");
        _;
    }

    constructor(address[] memory _owners, uint256 _numOfConfirmationsRequired) {
        require(_owners.length > 0, "owners requred");
        require(
            _numOfConfirmationsRequired > 0 &&
                _numOfConfirmationsRequired <= _owners.length,
            "invalid number of confirmations"
        );

        for (uint256 i = 0; i < _owners.length; ++i) {
            address owner = _owners[i];
            require(owner != address(0), "owner cannot be a dead address");
            require(!isOwner[owner], "owner duplicated");
            isOwner[owner] = true;
            owners.push(owner);
        }
        numConfirmationRequired = _numOfConfirmationsRequired;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function submitTransaction(
        address _to,
        uint256 _value,
        bytes memory _data
    ) public onlyOwner {
        uint256 txIDX = transactions.length;
        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                numConfirmation: 0
            })
        );
        emit SubmitTx(msg.sender, txIDX, _to, _value, _data);
    }

    function confirmTransaction(uint256 _txIDX)
        public
        onlyOwner
        txExists(_txIDX)
        notExecuted(_txIDX)
    {
        Transaction storage transaction = transactions[_txIDX];
        require(
            transaction.numConfirmation >= numConfirmationRequired,
            "cannot execute tx"
        );
        transaction.executed = true;
        (bool success, ) = payable(transaction.to).call{
            value: transaction.value
        }(transaction.data);
        require(success, "tx failed");
        emit ExecuteTx(msg.sender, _txIDX);
    }

    function revokeConfirmation(uint256 _txIDX)
        public
        onlyOwner
        txExists(_txIDX)
        notExecuted(_txIDX)
    {
        Transaction storage transaction = transactions[_txIDX];
        require(isConfirmed[_txIDX][msg.sender], "tx not confirmed");
        transaction.numConfirmation -= 1;
        isConfirmed[_txIDX][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txIDX);
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() public view returns (uint256) {
        return transactions.length;
    }

    function getTransaction(uint256 _txIDX)
        public
        view
        returns (
            address to,
            uint256 value,
            bytes memory data,
            bool executed,
            uint256 numConfirmation
        )
    {
        Transaction storage transaction = transactions[_txIDX];
        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.numConfirmation
        );
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1000
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}