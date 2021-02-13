/**
 *Submitted for verification at Etherscan.io on 2021-02-13
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.1;

abstract contract OracleCallable {
    
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
contract PhoneReceive is OracleCallable {
    
    event PhoneCallable (address oracleKey);
    
    event PhoneRung (
         uint64  source_chain_id,    uint256 source_contract_id,     
         uint64  source_block_no,    uint64  source_confirmations,   uint256 source_txn_hash,
         uint256 source_topic0,      uint256 source_topic1,          uint256 source_topic2,
         uint256 source_topic3,      uint256 source_topic4,          uint256 source_topic5
    );

    constructor (address oracleKey) OracleCallable (oracleKey) 
    {
        emit PhoneCallable(oracleKey);
    }

    function phoneRing (
        uint64  source_chain_id,    uint256 source_contract_id,
        uint64  source_block_no,    uint64  source_confirmations,   uint256 source_txn_hash,
        uint256 topic0, uint256 topic1, uint256 topic2, uint256 topic3, uint256 topic4, uint256 topic5
    ) onlyOracle public virtual
    {
       emit PhoneRung(
           source_chain_id, source_contract_id,
           source_block_no, source_confirmations, source_txn_hash,
           topic0, topic1, topic2, topic3, topic4, topic5);
    }
    
}

abstract
contract PhoneHangup is OracleCallable {

    event PhoneHangupable (address oracleKey);
    
    event PhoneHungup (
        uint64  rung_chain_id,      uint256 rung_contract_id,
        uint64  rung_block_no,      uint64  rung_confirmations,     uint256 rung_txn_hash,
        uint256 source_contract_id, uint256 source_event_id,
        uint64  source_block_no,    uint64  source_confirmations,   uint256 source_txn_hash
    );

    constructor (address oracleKey) OracleCallable (oracleKey) 
    {
        emit PhoneHangupable(oracleKey);
    }

    function phoneHangup (
        uint64  rung_chain_id,      uint256 rung_contract_id,
        uint64  rung_block_no,      uint64  rung_confirmations,     uint256 rung_txn_hash,
        uint256 source_contract_id, uint256 source_event_id,
        uint64  source_block_no,    uint64  source_confirmations,   uint256 source_txn_hash
    ) external onlyOracle 
    {
        emit PhoneHungup (
            rung_chain_id,      rung_contract_id,
            rung_block_no,      rung_confirmations,     rung_txn_hash,  
            source_contract_id, source_event_id,
            source_block_no,    source_confirmations,   source_txn_hash                                                                       
        );
    }
    
}

contract Phone is OracleCallable {

    event PhoneCostChanged(uint64 chain_id, uint256 cost);

    event PhoneCall(
        uint256 source_contract_id, uint256 source_event_id,
        uint64  dest_chain_id,      uint256 dest_contract_id,
        bool    callback_requested, uint256 callback_contract_id        
    );

    mapping (uint64 => uint256) private _phoneCost;
    
    uint64 private _thisChainId;

    constructor (uint64 thisChainId, address oracleKey) OracleCallable(oracleKey) {
        _thisChainId = thisChainId; 
    }
    
    function chainId() external view returns (uint64)
    {
        return _thisChainId;
    }

    function phoneDial(
        uint256 source_contract_id, uint256 source_event_id,
        uint64  dest_chain_id,      uint256 dest_contract_id,
        bool    callback_requested, uint256 callback_contract_id
    ) external payable
    {
        require(_phoneCost[dest_chain_id] != 0, "The network you are trying to call is not currently supported.");
        require(msg.value >= _phoneCost[dest_chain_id], "Insufficient funds sent to use phone. Please check phoneCost(chain_id).");
        emit PhoneCall(
            source_contract_id, source_event_id,
            dest_chain_id,      dest_contract_id,
            callback_requested, callback_contract_id
        );
    }
   
    function phoneCost(uint64 dest_chain_id) external view returns (uint256 phone_call_cost)
    {
        require(_phoneCost[dest_chain_id] != 0, "The network you are trying to call is not currently supported.");
        return _phoneCost[dest_chain_id];
    }

    function setPhoneCost(uint64 dest_chain_id, uint256 cost) external onlyOracle
    {
        emit PhoneCostChanged(dest_chain_id, cost);
        _phoneCost[dest_chain_id] = cost;
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

contract ExampleReceiver is PhoneReceive
{
    
    uint256 _counter;
    
    constructor(address oracleKey) PhoneReceive(oracleKey)
    {
        _counter = 0;
        
    }
    function phoneRing (
        uint64  source_chain_id,    uint256 source_contract_id,
        uint64  source_block_no,    uint64  source_confirmations,   uint256 source_txn_hash,
        uint256 topic0, uint256 topic1, uint256 topic2, uint256 topic3, uint256 topic4, uint256 topic5) public onlyOracle
        override
    {
        super.phoneRing(source_chain_id, source_contract_id, source_block_no, source_confirmations, source_txn_hash,
        topic0, topic1, topic2, topic3, topic4, topic5);
        _counter++;
    }       
    
    function getCounter() view public returns (uint256)
    {
        return _counter;
    }
    

}