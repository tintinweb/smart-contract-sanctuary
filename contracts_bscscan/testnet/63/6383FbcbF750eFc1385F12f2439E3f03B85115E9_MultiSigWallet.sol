/**
 *Submitted for verification at BscScan.com on 2021-10-04
*/

/**
 *Submitted for verification at Etherscan.io on 2021-10-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract AbcToken {
    string  public name = "ABC Token";
    string  public symbol = "ABC";
    string  public standard = "ABC Token v1.0";
    uint256 public totalSupply;

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor () {
        balanceOf[msg.sender] = 100000000;
        totalSupply = 100000000;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

/*

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

*/
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[_from]);
//        require(_value <= allowance[_from][msg.sender]);

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

//        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);

        return true;
    }
}

contract MultiSigWallet {
    
    AbcToken public abcToken = new AbcToken();
    
    event Deposit(address indexed sender, uint amount);
    event Submit(uint indexed txId);
    event Confirm(address indexed owner, uint indexed txId);
    event Revoke(address indexed owner, uint indexed txId);
    event Execute(uint indexed txId);

    address[5] public owners;
    mapping(address => bool) public isOwner;
    uint8 constant SIG_NEEDED = 2;

    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
    }

    // mapping from tx index => owner => bool
    mapping(uint => mapping(address => bool)) public confirmations;
    Transaction[] public transactions;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    modifier txExists(uint _txId) {
        require(_txId < transactions.length, "tx does not exist");
        _;
    }

    modifier notExecuted(uint _txId) {
        require(!transactions[_txId].executed, "tx already executed");
        _;
    }

    modifier notConfirmed(uint _txId) {
        require(!confirmations[_txId][msg.sender], "tx already confirmed");
        _;
    }

    constructor(){
        owners[0] = 0x77771887eC56443BE7944c6adbA28d1f90b96901; // ROMAN
        owners[1] = 0x7256C897736F66fD01D3c32EA08101f90C487777; // ARTHUR
        owners[2] = 0xE3eE31304b5Df5Cb82f6bCd16531783818146f21; // TEST 1
        owners[3] = 0x0E99C8005615Ef22441b43bd91AbDE583f9DceFC; // TEST 2
        owners[4] = 0x076f6E5286E422413652E4058582f602D3A4de26; // TEST 3 
        
        isOwner[0x77771887eC56443BE7944c6adbA28d1f90b96901] = true;
        isOwner[0x7256C897736F66fD01D3c32EA08101f90C487777] = true;
        isOwner[0xE3eE31304b5Df5Cb82f6bCd16531783818146f21] = true;
        isOwner[0x0E99C8005615Ef22441b43bd91AbDE583f9DceFC] = true;
        isOwner[0x076f6E5286E422413652E4058582f602D3A4de26] = true;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function submit(
        address _to,
        uint _value,
        bytes calldata _data
    ) external onlyOwner {
        uint txId = transactions.length;
        transactions.push(Transaction({to: _to, value: _value, data: _data, executed: false}));
        emit Submit(txId);
    }

    function confirm(uint _txId) external onlyOwner txExists(_txId) notExecuted(_txId) notConfirmed(_txId) {
        confirmations[_txId][msg.sender] = true;
        emit Confirm(msg.sender, _txId);
    }

    function _getConfirmationCount(uint _txId) private view returns (uint) {
        uint count = 0;
        for (uint i = 0; i < owners.length; i++) {
            if (confirmations[_txId][owners[i]]) {
                count += 1;
            }
        }
        return count;
    }
/*
    function execute(uint _txId) external onlyOwner txExists(_txId) notExecuted(_txId) {
        Transaction storage transaction = transactions[_txId];
        require(_getConfirmationCount(_txId) >= SIG_NEEDED, "confirmations < required");

        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value / 100}(transaction.data);
        require(success, "tx failed");

        emit Execute(_txId);
    }
*/

    function execute(uint _txId) external onlyOwner txExists(_txId) notExecuted(_txId) {
        Transaction storage transaction = transactions[_txId];
        require(_getConfirmationCount(_txId) >= SIG_NEEDED, "confirmations < required");

        transaction.executed = true;

//        (bool success, ) = transaction.to.call{value: transaction.value / 100}(transaction.data);
        bool success = abcToken.transferFrom(address(this), transaction.to, transaction.value);
        require(success, "tx failed");

        emit Execute(_txId);
    }

    function revoke(uint _txId) external onlyOwner txExists(_txId) notExecuted(_txId) {
        require(confirmations[_txId][msg.sender], "tx not confirmed");
        confirmations[_txId][msg.sender] = false;
        emit Revoke(msg.sender, _txId);
    }
}