/**
 *Submitted for verification at Etherscan.io on 2021-08-08
*/

pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

contract SaveData {
    uint256 public last_id = 0;
    struct Data {
        address writer;
        uint256 id_server;
        string name;
        string topic;
        string unit;
        string data;
    }
    
    event NewData (
        uint256 last_id,
        address writer,
        uint256 id_server,
        string name,
        string topic,
        string unit,
        string data
    );
    
    mapping (uint256 => Data) public dataMapping ;
    
    function addData(uint256 id_server, string memory name, string memory topic, string memory unit, string memory data) public {
        dataMapping[last_id].writer = msg.sender;
        dataMapping[last_id].id_server = id_server;
        dataMapping[last_id].name = name;
        dataMapping[last_id].topic = topic;
        dataMapping[last_id].unit = unit;
        dataMapping[last_id].data = data;

        emit NewData(last_id, msg.sender, id_server, name, topic, unit, data);
        
        last_id++;
    }
    
}