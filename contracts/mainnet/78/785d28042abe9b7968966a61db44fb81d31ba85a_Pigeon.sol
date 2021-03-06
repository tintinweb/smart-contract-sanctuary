/**
 *Submitted for verification at Etherscan.io on 2021-03-06
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.1;

abstract
contract OracleCallable {
    
    address private oracle_key_;
    
    event OracleKeyChanged(address indexed _oracle_key);
    
    constructor (address _oracle_key) {
        oracle_key_ = _oracle_key;
        emit OracleKeyChanged(_oracle_key);
    }    
    
    modifier onlyOracle() {
        require(oracle_key_ == msg.sender, "Caller is not the oracle");
        _;
    }    
    
    function changeOracleKeyInternal(address _oracle_key) internal
    {
        require(_oracle_key != address(0), "New oracle is the zero address");
        emit OracleKeyChanged(_oracle_key);
        oracle_key_ = _oracle_key;
    }
    
    function changeOracleKey(address _oracle_key) external onlyOracle returns (bool success) 
    {
        changeOracleKeyInternal(_oracle_key);
        return true;
    }   
    
    function getOracleKey() view public returns (address)
    {
        return oracle_key_;
    }
}


abstract
contract PigeonReceive is OracleCallable {
    
    event PigeonCallable (address _oracleKey);
    
    event PigeonArrived (
         uint256  _source_chain_id,    uint256 _source_contract_id,     
         uint256  _source_block_no,    uint256  _source_confirmations,   uint256 _source_txn_hash,
         uint256 _source_topic0,      uint256 _source_topic1,          uint256 _source_topic2,
         uint256 _source_topic3,      uint256 _source_topic4,          uint256 _source_topic5
    );

    constructor (address _oracleKey) OracleCallable (_oracleKey) 
    {
        emit PigeonCallable(_oracleKey);
    }

    function pigeonArrive (
        uint256  _source_chain_id,    uint256 _source_contract_id,
        uint256  _source_block_no,    uint256  _source_confirmations,   uint256 _source_txn_hash,
        uint256 _topic0, uint256 _topic1, uint256 _topic2, uint256 _topic3, uint256 _topic4, uint256 _topic5
    ) onlyOracle external virtual returns (bool success)
    {
        emit PigeonArrived(
           _source_chain_id, _source_contract_id,
           _source_block_no, _source_confirmations, _source_txn_hash,
           _topic0, _topic1, _topic2, _topic3, _topic4, _topic5);
        return true;
    }
    
}

abstract
contract PigeonInterface {
    event PigeonCall(
        uint256 _source_txn_hash, uint256 _source_event_id,
        uint256 _dest_chain_id,  uint256 _dest_contract_id
    );
    
    function pigeonSend(
        uint256 _source_txn_hash,    uint256 _source_event_id,
        uint256 _dest_chain_id,      uint256 _dest_contract_id) external virtual payable returns (bool success);
 
    function pigeonCost(uint256 _dest_chain_id) external view virtual returns (uint256 pigeon_call_cost);
   
    function setPigeonCosts(uint256[] memory _dest_chain_id, uint256[] memory _cost) external virtual returns (bool success);
    
    function chainId() external view virtual returns (uint256);
    
    function getPigeonOracleKey() view virtual external returns (address);

    function drain() external virtual returns (bool success);
}

contract Pigeon is OracleCallable, PigeonInterface {

    event PigeonCostChanged(uint256 _chain_id, uint256 _cost);

    mapping (uint256 => uint256) private pigeon_cost_;
    
    uint256 private chain_id_;

    constructor (uint256 _chain_id, address _oracle_key, uint256[] memory _dest_chain_ids, uint256[] memory _dest_chain_costs) OracleCallable(_oracle_key) {
        chain_id_ = _chain_id;
        for (uint i = 0; i < _dest_chain_ids.length; ++i)
            pigeon_cost_[_dest_chain_ids[i]] = _dest_chain_costs[i];
    }
    
    function chainId() external view override returns (uint256) 
    {
        return chain_id_;
    }

    function getPigeonOracleKey() view override external returns (address)
    {
        return getOracleKey();
    }

    function pigeonSend(
        uint256 _source_txn_hash,    uint256 _source_event_id,
        uint256 _dest_chain_id,      uint256 _dest_contract_id) external payable override returns (bool success)
    {

        require(pigeon_cost_[_dest_chain_id] != 0, "The network you are trying to call is not currently supported.");
        require(msg.value >= pigeon_cost_[_dest_chain_id], "Insufficient funds sent to use pigeon. Please check pigeonCost(chain_id).");
        payable(getOracleKey()).transfer(msg.value);
        emit PigeonCall(
            _source_txn_hash,    _source_event_id,
            _dest_chain_id,      _dest_contract_id
        );
        return true;
    }
   
    function pigeonCost(uint256 _dest_chain_id) external view override returns (uint256 pigeon_call_cost)
    {
        require(pigeon_cost_[_dest_chain_id] != 0, "The network you are trying to call is not currently supported.");
        return pigeon_cost_[_dest_chain_id];
    }


    function drain() external override onlyOracle returns (bool success)
    {
        payable(getOracleKey()).transfer(address(this).balance);
        return true;
    }

    function setPigeonCosts(uint256[] memory _dest_chain_id, uint256[] memory _cost) external override onlyOracle returns (bool success)
    {
        require(_dest_chain_id.length == _cost.length);
        for (uint i = 0; i < _dest_chain_id.length; ++i)
        {
            pigeon_cost_[_dest_chain_id[i]] = _cost[i];
            emit PigeonCostChanged(_dest_chain_id[i], _cost[i]);
        }
        return true;
    }
}



contract ExampleEmitter
{
    
    event ExampleEvent(string _example_arg_1, uint256 _example_arg_2);
    
    function doEmit( string calldata _example_arg_1, uint256  _example_arg_2 ) public
    {
        emit ExampleEvent(_example_arg_1, _example_arg_2);
    }
    
}


contract ExampleEmitterAndCaller
{
    
    event ExampleEvent(string _example_arg_1, uint256 _example_arg_2);
    
    function doEmit ( string calldata _example_arg_1 ,  uint256  _example_arg_2, address _pigeon, uint256 _dest_chain_id, uint256 _dest_contract_id) public payable
    {
        emit ExampleEvent(_example_arg_1, _example_arg_2);
        PigeonInterface(_pigeon).pigeonSend{
            value:PigeonInterface(_pigeon).pigeonCost(_dest_chain_id)
        }(0x0, 0x999d03e95f89232fcbca4ce488aaefdc6b6cf7fe3b2a6caa95e17bec4d0f45e9, _dest_chain_id, _dest_contract_id);
    }
    
}


contract ExampleReceiver is PigeonReceive
{
    
    uint256 counter_;
    
    constructor(address _oracle_key) PigeonReceive(_oracle_key)
    {
        counter_ = 0;
    }
    
    function pigeonArrive (
        uint256  _source_chain_id,    uint256 _source_contract_id,
        uint256  _source_block_no,    uint256  _source_confirmations,   uint256 _source_txn_hash,
        uint256 _topic0, uint256 _topic1, uint256 _topic2, uint256 _topic3, uint256 _topic4, uint256 _topic5) external onlyOracle
        override returns (bool success)
    {
        emit PigeonArrived(
           _source_chain_id, _source_contract_id,
           _source_block_no, _source_confirmations, _source_txn_hash,
           _topic0, _topic1, _topic2, _topic3, _topic4, _topic5);
        counter_++;
        return true;
    }       
    
    function getCounter() view public returns (uint256)
    {
        return counter_;
    }

}