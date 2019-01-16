pragma solidity 0.4.24;

// File: contracts/EventRegistry.sol

contract EventRegistry {
    address[] verityEvents;
    mapping(address => bool) verityEventsMap;

    mapping(address => address[]) userEvents;

    event NewVerityEvent(address eventAddress);

    function registerEvent() public {
        verityEvents.push(msg.sender);
        verityEventsMap[msg.sender] = true;
        emit NewVerityEvent(msg.sender);
    }

    function getUserEvents() public view returns(address[]) {
        return userEvents[msg.sender];
    }

    function addEventToUser(address _user) external {
        require(verityEventsMap[msg.sender]);

        userEvents[_user].push(msg.sender);
    }

    function getEventsLength() public view returns(uint) {
        return verityEvents.length;
    }

    function getEventsByIds(uint[] _ids) public view returns(uint[], address[]) {
        address[] memory _events = new address[](_ids.length);

        for(uint i = 0; i < _ids.length; ++i) {
            _events[i] = verityEvents[_ids[i]];
        }

        return (_ids, _events);
    }

    function getUserEventsLength(address _user)
        public
        view
        returns(uint)
    {
        return userEvents[_user].length;
    }

    function getUserEventsByIds(address _user, uint[] _ids)
        public
        view
        returns(uint[], address[])
    {
        address[] memory _events = new address[](_ids.length);

        for(uint i = 0; i < _ids.length; ++i) {
            _events[i] = userEvents[_user][_ids[i]];
        }

        return (_ids, _events);
    }
}