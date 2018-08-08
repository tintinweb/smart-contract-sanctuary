pragma solidity ^0.4.15;

/**
 * @title MultiSigStub  
 * @author Ricardo Guilherme Schmidt (Status Research & Development GmbH)
 * @dev Contract that delegates calls to a library to build a full MultiSigWallet that is cheap to create. 
 */
contract MultiSigStub {

    address[] public owners;
    address[] public tokens;
    mapping (uint => Transaction) public transactions;
    mapping (uint => mapping (address => bool)) public confirmations;
    uint public transactionCount;

    struct Transaction {
        address destination;
        uint value;
        bytes data;
        bool executed;
    }
    
    function MultiSigStub(address[] _owners, uint256 _required) {
        //bytes4 sig = bytes4(sha3("constructor(address[],uint256)"));
        bytes4 sig = 0x36756a23;
        uint argarraysize = (2 + _owners.length);
        uint argsize = (1 + argarraysize) * 32;
        uint size = 4 + argsize;
        bytes32 mData = _malloc(size);

        assembly {
            mstore(mData, sig)
            codecopy(add(mData, 0x4), sub(codesize, argsize), argsize)
        }
        _delegatecall(mData, size);
    }
    
    modifier delegated {
        uint size = msg.data.length;
        bytes32 mData = _malloc(size);

        assembly {
            calldatacopy(mData, 0x0, size)
        }

        bytes32 mResult = _delegatecall(mData, size);
        _;
        assembly {
            return(mResult, 0x20)
        }
    }
    
    function()
        payable
        delegated
    {

    }

    function submitTransaction(address destination, uint value, bytes data)
        public
        delegated
        returns (uint)
    {
        
    }
    
    function confirmTransaction(uint transactionId)
        public
        delegated
    {
        
    }
    
    function watch(address _tokenAddr)
        public
        delegated
    {
        
    }
    
    function setMyTokenList(address[] _tokenList)  
        public
        delegated
    {

    }
    /// @dev Returns the confirmation status of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Confirmation status.
    function isConfirmed(uint transactionId)
        public
        constant
        delegated
        returns (bool)
    {

    }
    
    /*
    * Web3 call functions
    */
    function tokenBalances(address tokenAddress) 
        public
        constant 
        delegated 
        returns (uint)
    {

    }


    /// @dev Returns number of confirmations of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Number of confirmations.
    function getConfirmationCount(uint transactionId)
        public
        constant
        delegated
        returns (uint)
    {

    }

    /// @dev Returns total number of transactions after filters are applied.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @return Total number of transactions after filters are applied.
    function getTransactionCount(bool pending, bool executed)
        public
        constant
        delegated
        returns (uint)
    {

    }

    /// @dev Returns list of owners.
    /// @return List of owner addresses.
    function getOwners()
        public
        constant
        returns (address[])
    {
        return owners;
    }

    /// @dev Returns list of tokens.
    /// @return List of token addresses.
    function getTokenList()
        public
        constant
        returns (address[])
    {
        return tokens;
    }

    /// @dev Returns array with owner addresses, which confirmed transaction.
    /// @param transactionId Transaction ID.
    /// @return Returns array of owner addresses.
    function getConfirmations(uint transactionId)
        public
        constant
        returns (address[] _confirmations)
    {
        address[] memory confirmationsTemp = new address[](owners.length);
        uint count = 0;
        uint i;
        for (i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]]) {
                confirmationsTemp[count] = owners[i];
                count += 1;
            }
        }
        _confirmations = new address[](count);
        for (i = 0; i < count; i++) {
            _confirmations[i] = confirmationsTemp[i];
        }
    }

    /// @dev Returns list of transaction IDs in defined range.
    /// @param from Index start position of transaction array.
    /// @param to Index end position of transaction array.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @return Returns array of transaction IDs.
    function getTransactionIds(uint from, uint to, bool pending, bool executed)
        public
        constant
        returns (uint[] _transactionIds)
    {
        uint[] memory transactionIdsTemp = new uint[](transactionCount);
        uint count = 0;
        uint i;
        for (i = 0; i < transactionCount; i++) {
            if (pending && !transactions[i].executed || executed && transactions[i].executed) {
                transactionIdsTemp[count] = i;
                count += 1;
            }
        }
        _transactionIds = new uint[](to - from);
        for (i = from; i < to; i++) {
            _transactionIds[i - from] = transactionIdsTemp[i];
        }
    }


    function _malloc(uint size) 
        private 
        returns(bytes32 mData) 
    {
        assembly {
            mData := mload(0x40)
            mstore(0x40, add(mData, size))
        }
    }

    function _delegatecall(bytes32 mData, uint size) 
        private 
        returns(bytes32 mResult) 
    {
        address target = 0xc0FFeEE61948d8993864a73a099c0E38D887d3F4; //Multinetwork
        mResult = _malloc(32);
        bool failed;

        assembly {
            failed := iszero(delegatecall(sub(gas, 10000), target, mData, size, mResult, 0x20))
        }

        assert(!failed);
    }
    
}

contract MultiSigFactory {
    
    event Create(address indexed caller, address createdContract);

    function create(address[] owners, uint256 required) returns (address wallet){
        wallet = new MultiSigStub(owners, required); 
        Create(msg.sender, wallet);
    }
    
}