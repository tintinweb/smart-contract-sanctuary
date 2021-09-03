/**
 *Submitted for verification at Etherscan.io on 2021-09-03
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract HashMultisig {
	uint8 constant CONFIRMATIONS_NEEDED = 2;
	uint8 constant public METHOD_MINT_TOKENS = 1;
	uint8 constant public METHOD_TRANSFER_OWNERSHIP = 2;
	uint constant public DELAY = 600;

	address public token;
	address[] public owners;

	struct Transaction {
	    address initiator;
	    uint8 method;
	    address to;
	    uint amount;
	    uint timestamp;
	    address[] confirmations;
	    bool cancelled;
	    bool sent;
	}
	Transaction[] public transactions;

	event NewTransaction(uint indexed transactionId, address indexed initiator, uint8 indexed method, address to, uint amount, uint timeStamp);
	event TransactionConfirmation(uint indexed transactionId, address indexed sender, bool isFinal);
	event TransactionPush(uint indexed transactionId, address indexed sender);
	event TransactionCancel(uint indexed transactionId, address indexed sender);

    constructor(address _token, address _owner1, address _owner2, address _owner3) {
        token = _token;
        owners.push(_owner1);
        owners.push(_owner2);
        owners.push(_owner3);
    }

	function mintTokens(address _to, uint256 _amount) external onlyOwner {
	    _submitTransaction(METHOD_MINT_TOKENS, _to, _amount);
    }

	function transferOwnership(address _to) external onlyOwner {
        _submitTransaction(METHOD_TRANSFER_OWNERSHIP, _to, 0);
	}

	function confirmTransaction(uint _transactionId) external onlyOwner {
        require(transactions.length > _transactionId, "Non-existent transaction specified");
        require(transactions[_transactionId].cancelled == false, "Transaction is cancelled");
        require(transactions[_transactionId].confirmations.length < CONFIRMATIONS_NEEDED, "Transaction is already confirmed");
        for (uint8 i = 0; i < transactions[_transactionId].confirmations.length; i++) {
            if (transactions[_transactionId].confirmations[i] == msg.sender) {
                revert("You have already confirmed this transaction");
            }
        }
        transactions[_transactionId].confirmations.push(msg.sender);
        bool isFinal = false;
        if (transactions[_transactionId].confirmations.length >= CONFIRMATIONS_NEEDED) {
            isFinal = true;
            if (transactions[_transactionId].timestamp + DELAY < block.timestamp) {
                _pushTransaction(_transactionId);
            }
        }
        emit TransactionConfirmation(_transactionId, msg.sender, isFinal);
	}

	function pushTransaction(uint _transactionId) external onlyOwner {
	    require(transactions.length > _transactionId, "Non-existent transaction specified");
	    require(transactions[_transactionId].cancelled == false, "Transaction is cancelled");
	    require(transactions[_transactionId].sent == false, "Transaction is already sent");
	    require(transactions[_transactionId].confirmations.length >= CONFIRMATIONS_NEEDED, "Transaction is not confirmed");
	    require(transactions[_transactionId].timestamp + DELAY < block.timestamp, "Transaction is not ready for pushing");
	    _pushTransaction(_transactionId);
	}

	function cancelTransaction(uint _transactionId) external onlyOwner {
	    require(transactions.length > _transactionId, "Non-existent transaction specified");
	    require(transactions[_transactionId].cancelled == false, "Transaction is already cancelled");
	    require(transactions[_transactionId].sent == false, "Transaction is already sent");
	    transactions[_transactionId].cancelled = true;
	    emit TransactionCancel(_transactionId, msg.sender);
	}

	function _submitTransaction(uint8 _method, address _to, uint _amount) internal {
	    uint transactionId = transactions.length;
        address[] memory confirmations;
        transactions.push(Transaction(msg.sender, _method, _to, _amount, block.timestamp, confirmations, false, false));
        transactions[transactionId].confirmations.push(msg.sender);
        emit NewTransaction(transactionId, msg.sender, _method, _to, _amount, block.timestamp);
	}

	function _pushTransaction(uint _transactionId) internal {
	    if (transactions[_transactionId].method == METHOD_MINT_TOKENS) {
            _callTokenContract(abi.encodeWithSelector(
                bytes4(keccak256(bytes('mintTokens(address,uint256)'))),
                transactions[_transactionId].to,
                transactions[_transactionId].amount
            ));
        } else {
            _callTokenContract(abi.encodeWithSelector(
                bytes4(keccak256(bytes('transferOwnership(address)'))),
                transactions[_transactionId].to
            ));
        }
        transactions[_transactionId].sent = true;
        emit TransactionPush(_transactionId, msg.sender);
	}

	function _callTokenContract(bytes memory _callData) internal {
	    (bool success, bytes memory data) = token.call(_callData);
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "Token contract call failed"
        );
	}

	modifier onlyOwner() {
	    bool isOwner = false;
        for (uint8 i = 0; i < owners.length; i++) {
            if (owners[i] == msg.sender) {
                isOwner = true;
                break;
            }
        }
        require(isOwner == true, "Forbidden");
        _;
    }
}