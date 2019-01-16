pragma solidity ^0.4.24;

contract VizDataContract {
   struct Incident {
        bytes32 uploadedBy;
        uint timestamp;
        uint status;
        bytes32 tag_id;
        uint size;
        uint latitude;
        uint longitude;
        bytes32 noteuuid;

    }

    mapping (bytes32 => Incident) public incidents;
    bytes32[] public incidentuuids;

    function getIncidentByUUId(bytes32 uuid) public constant returns (bytes32 uploadedBy, uint timestamp, uint status) {
return(incidents[uuid].uploadedBy,incidents[uuid].timestamp, incidents[uuid].status);
    }

    function createIncident(bytes32 uuid, bytes32 uploadedBy, uint timestamp, uint status,bytes32 tag_id,uint size,uint latitude,uint longitude,bytes32 noteuuid) public returns(bool success) {
        incidents[uuid].uploadedBy = uploadedBy;
        incidents[uuid].timestamp = timestamp;
        incidents[uuid].status = status;
        incidents[uuid].tag_id = tag_id;
        incidents[uuid].size = size;
        incidents[uuid].latitude = latitude;
        incidents[uuid].longitude = longitude;
        incidents[uuid].noteuuid=noteuuid;
        incidentuuids.push(uuid);
        return true;
    }
}