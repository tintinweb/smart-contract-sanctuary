pragma solidity ^0.4.23;

contract Hot {
    event CreateEvent(uint id, uint bid, string name, string link);
    
    event SupportEvent(uint id, uint bid);
    
    struct Record {
        uint index;
        uint bid;
        string name;
        string link;
    }

    address public owner;
    
    Record[] public records;

    constructor() public {
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
        records.push(Record(records.length,msg.value, _name, _link));
        emit CreateEvent(records.length-1, msg.value, _name, _link);
    }

    function supportRecord(uint _index) external payable {
        require(msg.value >= 0.001 ether);
        require(_index < records.length);
        records[_index].bid += msg.value;
        emit SupportEvent (_index, records[_index].bid);
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