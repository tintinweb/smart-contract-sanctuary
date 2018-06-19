pragma solidity ^0.4.19;

contract Ranking {
    event CreateEvent(uint id, uint bid, string name, string link);
    event SupportEvent(uint id, uint bid);
    
    struct Record {
        uint bid;
        string name;
        string link;
    }

    address public owner;
    Record[] public records;

    function Ranking() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function withdraw() external onlyOwner {
        owner.transfer(address(this).balance);
    }

    function updateRecordName(uint _id, string _name) external onlyOwner {
        require(_utfStringLength(_name) <= 20);
        require(_id < records.length);
        records[_id].name = _name;
    }

    function createRecord (string _name, string _link) external payable {
        require(msg.value >= 0.001 ether);
        require(_utfStringLength(_name) <= 20);
        require(_utfStringLength(_link) <= 50);
        uint id = records.push(Record(msg.value, _name, _link)) - 1;
        CreateEvent(id, msg.value, _name, _link);
    }

    function supportRecord(uint _id) external payable {
        require(msg.value >= 0.001 ether);
        require(_id < records.length);
        records[_id].bid += msg.value;
        SupportEvent (_id, records[_id].bid);
    }

    function listRecords () external view returns (uint[2][]) {
        uint[2][] memory result = new uint[2][](records.length);
        for (uint i = 0; i < records.length; i++) {
            result[i][0] = i;
            result[i][1] = records[i].bid;
        }
        return result;
    }
    
    function getRecordCount() external view returns (uint) {
        return records.length;
    }

    function _utfStringLength(string str) private pure returns (uint) {
        uint i = 0;
        uint l = 0;
        bytes memory string_rep = bytes(str);

        while (i<string_rep.length) {
            if (string_rep[i]>>7==0)
                i += 1;
            else if (string_rep[i]>>5==0x6)
                i += 2;
            else if (string_rep[i]>>4==0xE)
                i += 3;
            else if (string_rep[i]>>3==0x1E)
                i += 4;
            else
                //For safety
                i += 1;

            l++;
        }

        return l;
    }
}