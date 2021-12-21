/**
 *Submitted for verification at BscScan.com on 2021-12-21
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

contract ImbueToken {    
    struct EventDetail {
        uint _index;
        address _owner;
        string _name;
        uint _date_time;
        string _description;
        uint _price;
        bool _isDone;
    }

    mapping(uint => mapping(address => bool)) _purchased_persons;
    mapping(uint => EventDetail) public _events;
    uint public _event_count = 0;

    event eventAdded(address who);
    event purchaseDone(bool);
    function addEvent(string memory name, uint datetime, string memory description, uint price) public {
        _events[_event_count] = EventDetail(_event_count, msg.sender, name, datetime, description, price, false);
        _event_count++;
        emit eventAdded(msg.sender);
    }
    function getUpcomingEvents() public view returns(EventDetail[] memory){
        uint _upcoming_events_count = 0;
        for(uint i = 0; i < _event_count; i++)
            if(!_events[i]._isDone)
                _upcoming_events_count++;
        EventDetail[] memory _upcoming_events = new EventDetail[](_upcoming_events_count);
        uint _index = 0;
        for(uint i = 0; i < _event_count; i++){
            
            if(!_events[i]._isDone){
                _upcoming_events[_index] = _events[i];
                _index++;
            }
        }
        return _upcoming_events;
    }
    function addPerson(uint eventIndex) external payable {
        require(msg.value >= _events[eventIndex]._price, "error occured!");
        _purchased_persons[eventIndex][msg.sender] = true;
        // payable(ma)
        emit purchaseDone(true);
    }
    function isPurchased(uint eventIndex) public view returns(bool){
        require(_purchased_persons[eventIndex][msg.sender], "error occured!");
        return true;
    }
    function setEventDone(uint eventIndex) public {
        require(_events[eventIndex]._owner == msg.sender);
        _events[eventIndex]._isDone = true;
    }
}