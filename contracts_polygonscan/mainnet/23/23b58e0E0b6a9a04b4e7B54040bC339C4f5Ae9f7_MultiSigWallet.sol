pragma solidity 0.7.5;

import './TransferHelper.sol';

contract MultiSigWallet{
    modifier isManager{
        require(
            msg.sender == m1 ||msg.sender == m2 ||msg.sender == m3 ||msg.sender == m4 ||msg.sender == m5);
        _;
    }

    address m1 = address(0x1E04694Ed719850c6461922b6A99aeEEC7678152);
    address m2 = address(0x4808AD72f3D048D79081b22059D3f6DCC880bb25);
    address m3 = address(0xEd418ce6DbCD845F372Ca0361cb61c7146873D93);
    address m4 = address(0xB8CB756218e2f119ac13EA864682A30b90CdF53c);
    address m5 = address(0xbCFBf305584980a3ef301695EcFB68eBfB69247e);

    uint constant MIN_SIGNATURES = 3;
    uint private transactionIdx;
    
    struct Transaction {
        address from;
        address to;
        uint amount;
        address token;
        bool isToken;
        uint8 signatureCount;
        mapping (address => uint8) signatures;
    }
    
    mapping (uint => Transaction) private transactions;
    uint[] public pendingTransactions;
    
    
    event TransferFundsMatic(address to, uint amount);

    event TransferFundsToken(address to, uint amount,address token);

    event TransactionMaticCreated(
        address from,
        address to,
        uint amount,
        uint transactionId
        );

     event TransactionTokenCreated(
        address from,
        address to,
        address token,
        uint amount,
        uint transactionId
        );

    fallback () payable external {}
    receive () payable external {}

    function pendingTransactionsLen() public  view returns(uint){
        return pendingTransactions.length;
    }

    function transferMaticTo(address to,  uint amount) isManager public payable {
        require(address(this).balance >= amount);
        uint transactionId = transactionIdx++;
        
        transactions[transactionId].from = address(this);
        transactions[transactionId].to = to;
        transactions[transactionId].amount = amount;
        transactions[transactionId].isToken = false;
        transactions[transactionId].signatureCount = 1;
        transactions[transactionId].signatures[msg.sender] = 1;
        pendingTransactions.push(transactionId);
        emit TransactionMaticCreated(address(this), to, amount, transactionId);
    }

    function transferTokenTo(address to,  uint amount,address token) isManager public payable {
        
        uint transactionId = transactionIdx++;
        transactions[transactionId].from = address(this);
        transactions[transactionId].to = to;
        transactions[transactionId].amount = amount;
        transactions[transactionId].isToken = true;
        transactions[transactionId].token = token;
        transactions[transactionId].signatures[msg.sender] = 1;
        transactions[transactionId].signatureCount = 1;

        pendingTransactions.push(transactionId);
        emit TransactionTokenCreated(address(this), to, token, amount, transactionId);
    }


    function getTransactionInfo(uint id)  external view returns(address from,address to,uint amount,address token){
        
        return (transactions[id].from,transactions[id].to,transactions[id].amount,transactions[id].token);
    }
    
    function signTransaction(uint transactionId) public isManager{
        Transaction storage transaction = transactions[transactionId];

        assert(transaction.from != address(0x0000000000000000000000000000000000000000));
        
        require(msg.sender != transaction.from);
        require(transaction.signatures[msg.sender]!=1);
        transaction.signatures[msg.sender] = 1;
        transaction.signatureCount++;
        
        if(transaction.signatureCount >= MIN_SIGNATURES){
            if (transaction.isToken) {
                TransferHelper.safeTransfer(transaction.token, transaction.to, transaction.amount);
                emit TransferFundsToken(transaction.to, transaction.amount,transaction.token);
                deleteTransactions(transactionId);
            }else{
                require(address(this).balance >= transaction.amount);
                TransferHelper.safeTransferETH(transaction.to, transaction.amount);
                emit TransferFundsMatic(transaction.to, transaction.amount);
                deleteTransactions(transactionId);
            }
        }
    }
    
    function deleteTransactions(uint transacionId) public isManager{
        uint8 replace = 0;
        for(uint i = 0; i< pendingTransactions.length; i++){
            if(1==replace){
                pendingTransactions[i-1] = pendingTransactions[i];
            }else if(transacionId == pendingTransactions[i]){
                replace = 1;
            }
        } 
        pendingTransactions.pop();
        
        delete transactions[transacionId];
    }
    

}

pragma solidity 0.7.5;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}