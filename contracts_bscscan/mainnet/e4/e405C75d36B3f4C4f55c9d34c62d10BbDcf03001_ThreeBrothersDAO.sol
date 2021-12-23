/**
 *Submitted for verification at BscScan.com on 2021-12-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.8.9;

/// Pooled funds with consensus based transaction execution
contract ThreeBrothersDAO {
    /// Holds transaction data
    struct TxData {
        address target;
        bytes data;
        uint value;
    }
    /// Holds signature data
    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }
	
    /// Event for the result of a transaction, if unsuccessful, then returnData is an ExecuteError type
	event ExecuteResult(uint indexed nonce, bool success, bytes returnData);
    /// Error definition forwarding the index of the call and the returned data in case of failure
    error ExecuteError(uint index, bytes returnData);
    
    /// EIP712 DOMAIN_SEPARATOR
    bytes32 public immutable DOMAIN_SEPARATOR;
    /// The TxData struct type hash
    /// Value is keccak256("TxData(address target,bytes data,uint256 value)")
    bytes32 constant TXDATA_TYPEHASH = 0xe8ed147e341da3d2d95542c5aa05c38958eb12d3eb36d9d4ce0494c056668f75;
    /// The transaction execution type hash
    /// Value is keccak256("Execute(uint256 chainId,uint256 nonce,uint256 gasPayment,uint256 msgValue,TxData[] txData)TxData(address target,bytes data,uint256 value)")
    bytes32 constant EXECUTE_TYPEHASH = 0x3a5ab4a7c009b00505bac20abc49d7857a3558d3eb20acb022eb1e572da85667;

    /// The nonce for the transactions
    uint public nonce;
    /// The chain ID on which the contract is deployed on
    uint immutable public chainId;
    /// The owners of the contract. Transactions must be signed by all of them
    address[] public controllers;
    
    /// gasPayment is optional payment for the contract deployer
    constructor(uint gasPayment) {
        uint256 id;
        assembly {
            id := chainid()
        }
        chainId = id;
        
        // Initialize the controllers
        controllers.push(0xBf6d7d86acAc8b3e897C5CF64A2430a185D5A2e1);
        controllers.push(0xb00b508760C927DE9d8F725db6B8B93681b69aD0);
        controllers.push(0x8A7351226433Dda20a62Ac9Dc994D5104F04c33f);

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("ThreeBrothersDAO")),
                keccak256(bytes("1")),
                id,
                address(this)
            )
        );
        if (gasPayment != 0) {
            payable(tx.origin).transfer(gasPayment);
        }
    }
    
    /// Executes one or more calls.
    /// _nonce: The nonce for the calls, must equal to nonce()
    /// _gasPayment: Optional payment for the consumed gas to the tx origin
    /// _txdata: The transaction datas
    /// _signatures: The signatures. Each signature at the given index must correspond to the controller at the same index
    /// Returns the result of the calls. If fails, returnData contains the ExecuteError of the failed call.
    function execute(
            uint _nonce, 
            uint _gasPayment, 
            TxData[] calldata _txdata, 
            Signature[] calldata _signatures
    ) external payable returns (bool success, bytes memory returnData) {
        require(_txdata.length > 0, "no transactions");
        require(controllers.length == _signatures.length, "sig length mismatch");
        require(nonce++ == _nonce, "nonce mismatch");
        
        bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    keccak256(abi.encode(EXECUTE_TYPEHASH, chainId, _nonce, _gasPayment, msg.value, encodeTxDataArray(_txdata)))
                )
            );
        for (uint i; i < _signatures.length; ++i) {
            address recoveredAddress = ecrecover(digest, _signatures[i].v, _signatures[i].r, _signatures[i].s);
            require(recoveredAddress == controllers[i], "invalid signature");
        }

        (success, returnData) = address(this).call(abi.encodeWithSelector(ThreeBrothersDAO.callTransactions.selector, _txdata));
        emit ExecuteResult(_nonce, success, returnData);
        
        if (_gasPayment != 0) {
			// Transfers the gas payment amount to the tx origin as a compensation for paying the transaction gas
			// Note that this MUST be after calling the transactions
			// as otherwise the tx origin could pass insufficient gas to the transaction
			// causing the calls to fail, but still receiving the gas payment
            payable(tx.origin).transfer(_gasPayment);
        }
    }

    /// Tests the execution of the argument transactions
    /// This function always reverts, and can be used to test if the transactions would succeed or not.
    function test(TxData[] calldata _txdata) external payable {
        require(_txdata.length > 0, "no transactions");
        if (_txdata.length == 1) {
            callTransaction(0, _txdata[0]);
        } else {
            for (uint i; i < _txdata.length; ++i) {
                callTransaction(i, _txdata[i]);
            }
        }
        revert("Success.");
    }

    /// Calls the argument transactions
    /// This function can only be called by this contract and is used to ensure that all contract calls succeed or none of them
    function callTransactions(TxData[] calldata _txdata) external {
        require(msg.sender == address(this), "invalid sender");
        for (uint i; i < _txdata.length; ++i) {
            callTransaction(i, _txdata[i]);
        }
    }

    /// Internal function that calls the given transaction and reverts with an appropriate ExecuteError if fails
    function callTransaction(uint index, TxData calldata txdata) internal {
		// No need to check if txdata.target == address(this)
		// As the transaction has been signed by the controllers
		// Therefore reentrancy to this contract permitted, although makes little sense
		// Only callTransactions() could be reentered, but transactions can be passed in execute() so not needed
        (bool success, bytes memory returndata) = txdata.target.call{ value: txdata.value }(txdata.data);
        if (!success) {
            revert ExecuteError(index, returndata);
        }
    }
    
    /// Hashes a TxData struct for EIP712
    function hashTxData(TxData calldata txdata) internal pure returns (bytes32 hash) {
        return keccak256(abi.encode(
            TXDATA_TYPEHASH,
            txdata.target,
            keccak256(txdata.data),
            txdata.value
        ));
    }
    /// Hashes a TxData array for EIP712
    function encodeTxDataArray(TxData[] calldata txdata) internal pure returns (bytes32 hash) {
        bytes memory concat;
        for (uint i; i < txdata.length; ++i) {
            concat = abi.encodePacked(concat, hashTxData(txdata[i]));
        }
        hash = keccak256(concat);
    }
    
    /// Allows receiving ETH
    receive() external payable {
    }
    
    /// Allows receiving ERC721 tokens
    function onERC721Received(address /*_operator*/, address /*_from*/, uint256 /*_tokenId*/, bytes calldata /*_data*/) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}