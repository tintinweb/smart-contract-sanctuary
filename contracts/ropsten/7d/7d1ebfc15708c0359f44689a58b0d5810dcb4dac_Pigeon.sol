/**
 *Submitted for verification at Etherscan.io on 2021-02-13
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.1;

abstract
contract OracleCallable {
    
    address private _oracleKey;
    
    event OracleKeyChanged( address indexed newOkey);
    
    constructor (address oracleKey) {
        _oracleKey = oracleKey;
        emit OracleKeyChanged(oracleKey);
    }    
    
    modifier onlyOracle() {
        require(_oracleKey == msg.sender, "Caller is not the oracle");
        _;
    }    
    
    function changeOracleKey(address newOKey) public onlyOracle {
        require(newOKey != address(0), "New oracle is the zero address");
        emit OracleKeyChanged(newOKey);
        _oracleKey = newOKey;
    }   
    
}

abstract
contract PigeonReceive is OracleCallable {
    
    event PigeonCallable (address oracleKey);
    
    event PigeonArrived (
         uint64  source_chain_id,    uint256 source_contract_id,     
         uint64  source_block_no,    uint64  source_confirmations,   uint256 source_txn_hash,
         uint256 source_topic0,      uint256 source_topic1,          uint256 source_topic2,
         uint256 source_topic3,      uint256 source_topic4,          uint256 source_topic5
    );

    constructor (address oracleKey) OracleCallable (oracleKey) 
    {
        emit PigeonCallable(oracleKey);
    }

    function pigeonArrive (
        uint64  source_chain_id,    uint256 source_contract_id,
        uint64  source_block_no,    uint64  source_confirmations,   uint256 source_txn_hash,
        uint256 topic0, uint256 topic1, uint256 topic2, uint256 topic3, uint256 topic4, uint256 topic5
    ) onlyOracle public virtual
    {
       emit PigeonArrived(
           source_chain_id, source_contract_id,
           source_block_no, source_confirmations, source_txn_hash,
           topic0, topic1, topic2, topic3, topic4, topic5);
    }
    
}

contract Pigeon is OracleCallable {

    event PigeonCostChanged(uint256 chain_id, uint256 cost);

    event PigeonCall(
        uint256 source_txn_hash, uint256 source_event_id,
        uint256 dest_chain_id,  uint256 dest_contract_id
    );

    mapping (uint256 => uint256) private _pigeonCost;
    
    uint64 private _thisChainId;

    constructor (uint64 thisChainId, address oracleKey) OracleCallable(oracleKey) {
        _thisChainId = thisChainId; 
    }
    
    function chainId() external view returns (uint64)
    {
        return _thisChainId;
    }

    function pigeonSend(
        uint256 source_txn_hash,    uint256 source_event_id,
        uint256 dest_chain_id,      uint256 dest_contract_id) external payable
    {
        require(_pigeonCost[dest_chain_id] != 0, "The network you are trying to call is not currently supported.");
        require(msg.value >= _pigeonCost[dest_chain_id], "Insufficient funds sent to use pigeon. Please check pigeonCost(chain_id).");
        emit PigeonCall(
            source_txn_hash,    source_event_id,
            dest_chain_id,      dest_contract_id
        );
    }
   
    function pigeonCost(uint256 dest_chain_id) external view returns (uint256 pigeon_call_cost)
    {
        require(_pigeonCost[dest_chain_id] != 0, "The network you are trying to call is not currently supported.");
        return _pigeonCost[dest_chain_id];
    }

    function setPigeonCost(uint256 dest_chain_id, uint256 cost) external onlyOracle
    {
        emit PigeonCostChanged(dest_chain_id, cost);
        _pigeonCost[dest_chain_id] = cost;
    }

}

contract ExampleEmitter
{
    
    event ExampleEvent(string examplearg1, uint256 examplearg2);
    
    function doEmit ( string calldata examplearg1 ,  uint256  examplearg2 ) public
    {
        emit ExampleEvent(examplearg1, examplearg2);
    }
}

contract ExampleReceiver is PigeonReceive
{
    
    uint256 _counter;
    
    constructor(address oracleKey) PigeonReceive(oracleKey)
    {
        _counter = 0;
        
    }
    
    function pigeonArrive (
        uint64  source_chain_id,    uint256 source_contract_id,
        uint64  source_block_no,    uint64  source_confirmations,   uint256 source_txn_hash,
        uint256 topic0, uint256 topic1, uint256 topic2, uint256 topic3, uint256 topic4, uint256 topic5) public onlyOracle
        override
    {
        super.pigeonArrive(source_chain_id, source_contract_id, source_block_no, source_confirmations, source_txn_hash,
        topic0, topic1, topic2, topic3, topic4, topic5);
        _counter++;
    }       
    
    function getCounter() view public returns (uint256)
    {
        return _counter;
    }
    

}