// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ReentrancyGuard.sol";


interface MecenasPool {

    function withdrawyield(uint _amount, uint _flag) external;
    function withdrawdonations(uint _amount) external;
}

interface ERC20 {

    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
}


contract MecenasMultisignWallet is ReentrancyGuard {

    address public constant EMPTY_ADDRESS = address(0);

    ERC20 public walletunderlying;
    MecenasPool public walletpool;

    address public owner;
    
    struct OwnerState {
        address thesigner;
        uint thestate;
    }

    OwnerState[] public owners;

    mapping(address => uint) public signers;
    mapping(address => uint) public signersindex;
    uint public threshold;
    uint public ownerscounter;

    struct Transaction {
        uint datecreation;
        address creator;
        uint transtype;
        uint amount;
        address to;
        uint signaturesCount;
        uint status;
        uint dateexecution;
        uint signthreshold;
}


    mapping (address => mapping(uint => uint)) public signatures;


    Transaction[] public pendingtransactions;

    event PendingTransactionAdded(address indexed from, uint _type, uint amount, address indexed to);
    event TransactionSigned(address indexed from, uint transactionid);
    event SignatureRevoked(address indexed from, uint transactionid);
    event TransactionDeleted(address indexed from, uint transactionid);
    event TransferUnderlying(uint transactionid, address indexed to, uint amount);
    event WithdrawUnderlying(uint transactionid, uint amount);
    event SignerAdded(uint transactionid, address indexed signer);
    event SignerRemoved(uint transactionid, address indexed signer);
    event ThresholdChanged(uint transactionid, uint numbersignature);


    constructor(address _owner, address _pooladdress, address _underlyingaddress) {
        require(_owner != EMPTY_ADDRESS);
        owner = _owner;
        signers[_owner] = 1;
        owners.push(OwnerState(_owner, 1));
        signersindex[_owner] = owners.length - 1;
        ownerscounter += 1;
        threshold = 1;
        walletpool = MecenasPool(_pooladdress);
        walletunderlying = ERC20(_underlyingaddress);
    }


    // this function adds a pending Transaction
    // _transyype 1 = whithdraw interest
    // _transyype 2 = whithdraw reserves
    // _transyype 3 = whithdraw donations
    // _transyype 4 = transfer underlying
    // _transyype 5 = add a new signer
    // _transyype 6 = change the threshold signatures
    // _transyype 7 = remove signer

    function addPendingTransaction(uint _transtype, uint _amount, address _to) external {
        require(signers[msg.sender] == 1);
        require(_amount > 0);
        require(_transtype == 1 || _transtype == 2 || _transtype == 3 || _transtype == 4 || _transtype == 5 
                || _transtype == 6 || _transtype == 7);

        if(_transtype == 4 || _transtype == 5 || _transtype == 7) {
            require(_to != EMPTY_ADDRESS);
        }

        if(_transtype == 5) {
            require(signers[_to] != 1);
        }

        if(_transtype == 6) {
            require(_amount > 0);
            require(_amount <= ownerscounter);
            require(_amount != threshold);
        }

        if(_transtype == 7) {
            require(signers[_to] == 1);
            require(ownerscounter > 1);
        }

        pendingtransactions.push(Transaction(block.timestamp, msg.sender, _transtype, _amount, address(_to), 0, 0, 0, threshold));

        uint idtransaction = pendingtransactions.length - 1;
        signTransaction(idtransaction);
    
        emit PendingTransactionAdded(msg.sender, _transtype, _amount, _to);
    }


    // this function signs a transaction and executes it if transaction threshold is reached

    function signTransaction(uint index) public nonReentrant {
            require(signers[msg.sender] == 1);
            require(index <= pendingtransactions.length - 1);
            require(signatures[msg.sender][index] == 0);
            require(pendingtransactions[index].signaturesCount < pendingtransactions[index].signthreshold);
            require(pendingtransactions[index].status == 0);
            
            pendingtransactions[index].signaturesCount += 1;
            signatures[msg.sender][index] = 1;

            if(pendingtransactions[index].signaturesCount == pendingtransactions[index].signthreshold) {

                if(pendingtransactions[index].transtype == 1 || pendingtransactions[index].transtype == 2) {
                    walletpool.withdrawyield(pendingtransactions[index].amount, pendingtransactions[index].transtype);
                    emit WithdrawUnderlying(index, pendingtransactions[index].amount);
                }

                if(pendingtransactions[index].transtype == 3) {
                    walletpool.withdrawdonations(pendingtransactions[index].amount);
                    emit WithdrawUnderlying(index, pendingtransactions[index].amount);
                }    
                    
                if(pendingtransactions[index].transtype == 4) {
                    require(walletunderlying.balanceOf(address(this)) >= pendingtransactions[index].amount); 
                    require(walletunderlying.transfer(pendingtransactions[index].to, pendingtransactions[index].amount) == true);
                    emit TransferUnderlying(index, pendingtransactions[index].to, pendingtransactions[index].amount);
                }
            
                if(pendingtransactions[index].transtype == 5) {
                    require(signers[pendingtransactions[index].to] != 1);
                    ownerscounter += 1;
                    
                    if(signers[pendingtransactions[index].to] == 0) {
                        owners.push(OwnerState(pendingtransactions[index].to, 1));
                        signersindex[pendingtransactions[index].to] = owners.length - 1;
                    }
                    
                    if(signers[pendingtransactions[index].to] == 2) {
                        uint theindex = signersindex[pendingtransactions[index].to];
                        owners[theindex].thestate = 1;
                    }

                    signers[pendingtransactions[index].to] = 1;
                
                    emit SignerAdded(index, pendingtransactions[index].to);
                }

                if(pendingtransactions[index].transtype == 6) {
                    require(pendingtransactions[index].amount > 0);
                    require(pendingtransactions[index].amount <= ownerscounter);
                    require(pendingtransactions[index].amount != threshold);

                    threshold = pendingtransactions[index].amount;
                
                    emit ThresholdChanged(index, pendingtransactions[index].amount);
                }

                if(pendingtransactions[index].transtype == 7) {
                    require(signers[pendingtransactions[index].to] == 1);
                    require(ownerscounter > 1);

                    signers[pendingtransactions[index].to] = 2;
                    ownerscounter -= 1;
                    uint theindex = signersindex[pendingtransactions[index].to];
                    owners[theindex].thestate = 2;

                    if(threshold > ownerscounter) {
                    threshold -= 1;
                    }
                
                    emit SignerRemoved(index, pendingtransactions[index].to);
                }    

                pendingtransactions[index].status = 1;
                pendingtransactions[index].dateexecution = block.timestamp;
            }    
    
        emit TransactionSigned(msg.sender, index);
    }


    // this function revokes a previous signature

    function revokeSignature(uint index) external nonReentrant {
        require(signers[msg.sender] == 1);
        require(index <= pendingtransactions.length - 1);
        require(pendingtransactions[index].status == 0);
        require(signatures[msg.sender][index] == 1);

        pendingtransactions[index].signaturesCount -= 1;
        signatures[msg.sender][index] = 0;

        emit SignatureRevoked(msg.sender, index);
}


    // this function removes a pending transaction

    function deleteTransaction(uint index) external nonReentrant {
        require(signers[msg.sender] == 1);
        require(index <= pendingtransactions.length - 1);
        require(pendingtransactions[index].status == 0);

        pendingtransactions[index].status = 2;
        pendingtransactions[index].dateexecution = block.timestamp;
    
        emit TransactionDeleted(msg.sender, index);
    }


    // this function returns an array of pending transactions

    function getPendingTransactions() external view returns (Transaction[] memory) {
        return pendingtransactions;
    }


    // this function returns the wallet balance of the underlying 

    function getBalanceWallet() external view returns (uint) {
        return walletunderlying.balanceOf(address(this));
    }


    // this function returns the length of the pending transactions array

    function getPendingTransactionsLength() external view returns (uint) {
        return pendingtransactions.length;
    }


    // this function returns an array of wallet owners 

    function getOwners() external view returns (OwnerState[] memory) {
    return owners;
    }
  
}