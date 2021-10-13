/**
 *Submitted for verification at Etherscan.io on 2021-10-13
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >0.5.99 <0.8.0;
pragma experimental ABIEncoderV2;

contract systemDocument {
    /***************Modifier************** */

    modifier onlyOwnerOrg() {
        require(
            ownerOrg == msg.sender,
            "Only  Organitation Owner can call this function"
        );
        _;
    }

    //**************Struct*************** */

    struct Area {
        uint256 id;
        // bool editable;
        address ownerArea;
        string name;
        string description;
        uint256 state_id;
        uint256[] idEvents;
    }

    // name= Verificado mean= El documento esta verificado
    struct State {
        uint256 id;
        string name;
        string mean;
    }
    // mapping (uint256=>string) Reason;
    struct Document {
        //hash
        string idHash;
        uint256 state_id;
        uint256 event_id;
        //date of expired timestamp
        uint256 expiration;
        string reasonState;
        //new Version of document
        string newDocument;
    }

    struct Event {
        uint256 id;
        string name;
        string description;
        uint256 state_id;
        string startEvent;
        string endEvent;
        //Propietario que puede hacer cambios al evento
        uint256 area_id;
        //storage idhash
        string[] idDocuments;
    }
    //*************************  ************* */
    // only one organitation   for avoid that use a smart contract for  upload many files
    string private organitaton;

    address private ownerOrg;
    //all states
    State[] private states;
    //one owner many areas
    mapping(address => uint256[]) public ownerArea;
    //all areas
    Area[] private areas;
    //all events
    Event[] private events;
    // hash => document
    mapping(string => Document) private documents;

    /**************** Methods ***************** */
    constructor() {
        ownerOrg = msg.sender;
        uint256[] memory idEvents;
        //La primer area todos las areas borradas hacen referencia a este
        Area memory zero = Area(0, address(this), "null", "null", 1, idEvents);
        areas.push(zero);

        State memory _state = State(0, "deleted", "deleted");
        State memory _state2 = State(1, "actived", "actived");
        State memory _state3 = State(2, "expired", "expired");

        states.push(_state);
        states.push(_state2);
        states.push(_state3);
        string[] memory str;
        Event memory _event = Event(0, "null", "null", 0, "", "", zero.id, str);
        events.push(_event);
    }

    /*********************Organitation************************* */
    function setOrganitation(string memory org) public payable onlyOwnerOrg {
        organitaton = org;
    }

    function editOwnerOrg(address newOwner) public payable onlyOwnerOrg {
        ownerOrg = newOwner;
    }

    /******************State************************ */

    function addState(string memory name, string memory mean)
        public
        payable
        onlyOwnerOrg
        returns (uint256)
    {
        uint256 id = states.length;
        State memory newState = State(id, name, mean);
        states.push(newState);
        return id;
    }

    function editState(uint256 id,string memory name,string memory mean)
        public
        payable
        onlyOwnerOrg
        returns (
            uint256,
            string memory,
            string memory
        )
    {
        require((states.length > id) && (id > 1));
        (states[id].name = name);
        (states[id].mean = mean);
        return (id, states[id].name, states[id].mean);
    }

    /***************Area************************* */
    function addArea(address _ownerArea,string memory _name,string memory _description) public payable onlyOwnerOrg {
        uint256 _id = areas.length;
        uint256[] memory _events;
        Area memory _newOwner =
            Area(_id, _ownerArea, _name, _description, 1, _events);

        areas.push(_newOwner);
        ownerArea[_ownerArea].push(_id);
    }

    function editArea(uint256 _id_area,string memory _name,string memory _description,uint256 _id_state) public payable {
        require(
            (ownerOrg == msg.sender) ||
                (areas[_id_area].ownerArea == msg.sender)
        );

      
        if (bytes(_name).length > 0) {
            areas[_id_area].name = _name;
        }

        if (bytes(_description).length > 0) {
            areas[_id_area].description = _description;
        }
        if (_id_state < states.length) {
            areas[_id_area].state_id = _id_state;
        }
    }

    function changeOwnerArea(uint256 _id_area, address _newOwner)
        public
        payable
        onlyOwnerOrg
    {
        require((areas.length > _id_area) && (_id_area > 0));
        //get oldest owner
        address _oldOwner = areas[_id_area].ownerArea;
        //changue oldest area_id by 0
        for (uint256 index = 0; index < ownerArea[_oldOwner].length; index++) {
            if (ownerArea[_oldOwner][index] == _id_area) {
                ownerArea[_oldOwner][index] = 0;
                break;
            }
        }

        ownerArea[_newOwner].push(_id_area);
        areas[_id_area].ownerArea = _newOwner;
    }

    /********************Event***************************** */

    function addEventFull(uint256 _area_id,string memory name,string memory description,string memory _startDate,string memory _endDate) public payable returns (uint256 id) {
        require(
            (areas[_area_id].ownerArea == msg.sender) ||
                (ownerOrg == msg.sender)
        );

        uint256 _id = events.length;
        string[] memory _document;

        Event memory evento =
            Event(
                _id,
                name,
                description,
                1, //state active
                _startDate,
                _endDate,
                _area_id,
                _document
            );

        events.push(evento);

        areas[_area_id].idEvents.push(_id);

        return _id;
    }

    function editEventFull(uint256 _event_id,string memory name,string memory description,string memory _startDate,string memory _endDate,uint256 area_id,uint256 state_id) public payable returns (uint256 id) {
        require(
            (areas[events[_event_id].area_id].ownerArea == msg.sender) ||
                (ownerOrg == msg.sender)
        );
        require((state_id < states.length));
        require((area_id < areas.length));
        require(events[_event_id].idDocuments.length == 0);

        if (bytes(name).length > 0) {
            events[_event_id].name = name;
        }
        if (bytes(description).length > 0) {
            events[_event_id].description = description;
        }

        if (bytes(_startDate).length > 0) {
            events[_event_id].startEvent = _startDate;
        }
        if (bytes(_endDate).length > 0) {
            events[_event_id].endEvent = _endDate;
        }

        events[_event_id].state_id = state_id;

        if (events[_event_id].area_id != area_id) {
            uint256 leng = areas[events[_event_id].area_id].idEvents.length;
            for (uint256 i = 0; i < leng; i++) {
                if (
                    areas[events[_event_id].area_id].idEvents[i] ==
                    events[_event_id].area_id
                ) {
                    areas[events[_event_id].area_id].idEvents[i] = 0;
                    break;
                }
            }
            areas[area_id].idEvents.push(_event_id);
            events[_event_id].area_id = area_id;
        }

        return _event_id;
    }

    //**********************Document********************************************8 */
    function addDocumentEvent(string memory _idHash,uint256 _event_id,uint256 _state_id,string memory _reasonState,uint256  _expiration) public payable {
        require(
            (areas[events[_event_id].area_id].ownerArea == msg.sender) ||
                (msg.sender == ownerOrg)
        );
        require((states.length > _state_id) && (_state_id > 0));
        //only idHash not exists
        require(bytes(documents[_idHash].idHash).length == 0);

        Document memory _newDocument =
            Document(_idHash, _state_id, _event_id,_expiration, _reasonState, "");
        documents[_idHash] = _newDocument;
        events[_event_id].idDocuments.push(_idHash);
    }

    function addAllDocumentsEvent(string[] memory hashid,uint256 _event_id,uint256 _state_id,string memory _reasonState,uint256  _expiration) public payable {
        require(
            (areas[events[_event_id].area_id].ownerArea == msg.sender) ||
                (msg.sender == ownerOrg)
        );
        require((states.length > _state_id) && (_state_id > 0));
        //only idHash not exists
        require(hashid.length > 0);
        bytes memory tempEmptyStringTest;
        for (uint256 i = 0; i < hashid.length; i++) {
            tempEmptyStringTest = bytes(documents[hashid[i]].idHash);
            if (tempEmptyStringTest.length == 0) {
                Document memory _newDocument =
                    Document(hashid[i], _state_id, _event_id,_expiration, _reasonState, "");
                documents[hashid[i]] = _newDocument;
                events[_event_id].idDocuments.push(hashid[i]);
            }
        }
    }

    function editAllDocumentsEvent(string[] memory hashid,uint256 _event_id,uint256 _state_id,string memory _reasonState,uint256 _expiration) public payable {
        require(
            (areas[events[_event_id].area_id].ownerArea == msg.sender) ||
                (msg.sender == ownerOrg)
        );

        require((states.length > _state_id));
        //only idHash not exists
        require(hashid.length > 0);
        uint256 c = 0;
        string[] memory hashidFiltro = new string[](hashid.length);

        for (uint256 i = 0; i < hashid.length; i++) {
            if (bytes(documents[hashid[i]].idHash).length > 0) {
                if (
                    areas[events[documents[hashid[i]].event_id].area_id].ownerArea ==
                    msg.sender
                ) {
                    hashidFiltro[c] = hashid[i];
                    c++;
                }
            }
        }
        hashid = new string[](c);

        for (uint256 i = 0; i < hashid.length; i++) {
            hashid[i] = hashidFiltro[i];
        }

        for (uint256 i = 0; i < hashid.length; i++) {
            //add only not exists

            string memory hashAux;
            //delete  passed event
            for (
                uint256 j = 0;
                j < events[documents[hashid[i]].event_id].idDocuments.length;
                j++
            ) {
                hashAux = events[documents[hashid[i]].event_id].idDocuments[j];

                if (keccak256(bytes(hashAux)) == keccak256(bytes(hashid[i]))) {
                    events[documents[hashid[i]].event_id].idDocuments[j] = "";
                    break;
                }
            }

            documents[hashid[i]].event_id = _event_id;
            events[_event_id].idDocuments.push(hashid[i]);

            documents[hashid[i]].state_id = _state_id;

            documents[hashid[i]].reasonState = _reasonState;
            documents[hashid[i]].expiration = _expiration;
        }
    }

    //change state_id and reason of the state
    function changeStateDocument(string memory _idHash,uint256 _state_id,string memory _reasonState) public payable {
        require(
            (areas[events[documents[_idHash].event_id].area_id].ownerArea ==
                msg.sender) || (msg.sender == ownerOrg)
        );
        require((states.length > _state_id));
        //only idHash not exists
        require(bytes(documents[_idHash].idHash).length != 0);

        documents[_idHash].reasonState = _reasonState;
        documents[_idHash].state_id = _state_id;
    }

    //mando valores para la version vieja, asi modifico si quiero. por ejemplo cambiar el estado o cambiar la razon del estado,
    function newVersionDocument(string memory _idHash_old,string memory _idHash_new) public payable {
        require(bytes(documents[_idHash_old].idHash).length > 0);
        require(bytes(documents[_idHash_new].idHash).length > 0);
        require(keccak256(bytes(_idHash_old)) != keccak256(bytes(_idHash_new)));
        documents[_idHash_old].newDocument = _idHash_new;
    }

    /********************Getters of attributes****************************** */

    function getOrganitation() public view returns (string memory) {
        return organitaton;
    }

    function getOwnerOrg() public view returns (address) {
        return ownerOrg;
    }

    function getState(uint256 _id)public view returns (uint256 id,string memory name,string memory mean)
    {
        return (states[_id].id, states[_id].name, states[_id].mean);
    }

    function getLengthStates() public view returns (uint256) {
        return states.length;
    }

    function getAreaOfOwner(address _id, uint256 _area_index) public view returns (uint256)
    {
        return ownerArea[_id][_area_index];
    }

    function getLengthAreaOfOwner(address _id) public view returns (uint256) {
        return ownerArea[_id].length;
    }

    function getArea(uint256 _id) public view  returns ( uint256 id,address owner,string memory name,string memory description,uint256 state_id,uint256 cantEvents)
    {
        return (
            areas[_id].id,
            areas[_id].ownerArea,
            areas[_id].name,
            areas[_id].description,
            areas[_id].state_id,
            areas[_id].idEvents.length
        );
    }

    function getLengthAreas() public view returns (uint256) {
        return areas.length;
    }

    function getLengthEventsOfArea(uint256 _id_area) public view returns (uint256)
    {
        return areas[_id_area].idEvents.length;
    }

    function getEventOfArea(uint256 _id_area, uint256 _id_event_index) public view returns (uint256)
    {
        return areas[_id_area].idEvents[_id_event_index];
    }

    function getAllEventsOfArea(uint256 _id_area) public view returns (uint256[] memory)
    {
        return areas[_id_area].idEvents;
    }

    function getEvent(uint256 _id) public view returns (uint256 id,string memory name,string memory description,uint256 state_id,uint256 area_id,string memory startEvent,string memory endEvent)
    {
        return (
            _id,
            events[_id].name,
            events[_id].description,
            events[_id].state_id,
            events[_id].area_id,
            events[_id].startEvent,
            events[_id].endEvent
        );
    }

    function getCantDocumentEvent(uint256 _id) public view returns (uint256) {
        return (events[_id].idDocuments.length);
    }

    function getLengthEvents() public view returns (uint256) {
        return events.length;
    }

    function getDocument(string memory _idHash) public view returns (string memory idHash,uint256 state_id,uint256 event_id,string memory reasonState,uint256 expiration,string memory newDocument)
    {
        return (
            documents[_idHash].idHash,
            documents[_idHash].state_id,
            documents[_idHash].event_id,
            documents[_idHash].reasonState,
            documents[_idHash].expiration,
            documents[_idHash].newDocument
        );
    }

    function getDocumentsOfEvent(uint256 _id_event) public view returns (string[] memory)
    {
        return events[_id_event].idDocuments;
    }

    function checkDocument(string memory _idHash) public view returns (bool) {
        return bytes(documents[_idHash].idHash).length > 0 ? true : false;
    }

    function checkDocuments(string[] memory idHashes) public view returns (bool[] memory)
    {
        bool[] memory checks = new bool[](idHashes.length);
        for (uint256 i = 0; i < idHashes.length; i++) {
            checks[i] = bytes(documents[idHashes[i]].idHash).length > 0;
        }
        return checks;
    }
}