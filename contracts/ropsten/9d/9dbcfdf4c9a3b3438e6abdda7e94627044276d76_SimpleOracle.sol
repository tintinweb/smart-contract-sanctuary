pragma solidity ^0.4.10;

contract SimpleOracle {
    // 储存response
    mapping(uint256 => bytes) responses;
    
    // 传出去的Query Event
    event QueryEvent(uint256 _id, bytes _query);
    
    // 使用者query功能
    function query(bytes _query) external returns (uint256) {
        // 计算一个query id
        uint256 id = uint256(sha3(block.number, now, _query, msg.sender));
        // 将id与_query传出去
        QueryEvent(id, _query);
        return id;
    }
    
    // Human Oracle 可以透过此函式将data回传
    function _queryCallback(uint256 _id, bytes _response) external {
        responses[_id] = _response;
    }
    
    // 使用者取得response
    function getResponse(uint256 _id) external constant returns (bytes) {
        return responses[_id];
    }
}