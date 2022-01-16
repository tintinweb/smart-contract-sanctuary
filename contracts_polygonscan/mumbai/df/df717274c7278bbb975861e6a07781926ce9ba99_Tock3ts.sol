// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";


contract Tock3ts is ERC721Enumerable, Ownable {

    using SafeMath for uint;

    event NewEventCreated(Event newEvent);
    event NewEventTock3tCreated(EventTock3t newEventTock3t);
    event NewSale(uint eventid, uint tock3tAmount);

    struct Event {
        uint id;
        string name;
        string description;
        uint startDate;
        uint endDate;
        string location;
        string[] images;
        uint saleStartDate;
        uint saleEndDate;
    }

    struct EventTock3t {
        uint id;
        uint eventId;
        string name;
        string description;
        uint maxSupply;
        uint tokenPrice;
        uint mintedSupply;
        string baseImageURI;
    }

    struct Tock3t {
        uint id;
        uint eventTock3tId;
        uint tokenNumber;
        bool revealed;
    }

    Event[] public events;
    EventTock3t[] public eventTock3ts;
    Tock3t[] public tock3ts;

    mapping(address => bool) isAddressRegistered;
    mapping(address => bool) isAddressVerified;

    mapping(uint => address) eventToOwner;

    mapping(uint => address) tokenToAddress;

    uint public registerPrice;
    uint public createEventPrice;
    uint public createEventTock3tPrice;

    constructor (uint _registerPrice, uint _createEventPrice, uint _createEventTock3tPrice) ERC721("tock3ts", "TOCK3T"){
        registerPrice = _registerPrice;
        createEventPrice = _createEventPrice;
        createEventTock3tPrice = _createEventTock3tPrice;
    }

    function createEvent(string memory _eventName, string memory _eventDescription, uint _eventStartDate,
        uint _eventEndDate, string memory _eventLocation, string[] memory _eventImages,
        uint _saleStartDate, uint _saleEndDate) public payable {
        require(createEventPrice <= msg.value, "tock3ts: insuficient payable amount.");
        require(isAddressVerified[msg.sender], "tock3ts: address not verified.");

        Event memory newEvent = Event(events.length + 1, _eventName, _eventDescription, _eventStartDate,
            _eventEndDate, _eventLocation, _eventImages, _saleStartDate, _saleEndDate);
        events.push(newEvent);
        eventToOwner[events.length] = msg.sender;
        emit NewEventCreated(newEvent);
    }

    function createEventTock3ts(uint _eventId, string[] memory _eTName, string[] memory _eTDescription,
        uint[] memory _eTMaxSupply, uint[] memory _eTTokenPrice, string[] memory _eTBaseImageURI) public payable {
        require(eventToOwner[_eventId] == msg.sender, "tock3ts: sender is not event owner");
        require(_eTName.length == _eTDescription.length && _eTDescription.length == _eTMaxSupply.length
        && _eTMaxSupply.length == _eTTokenPrice.length && _eTTokenPrice.length == _eTBaseImageURI.length,
            "tock3ts: array lengths do not coincide.");
        require(createEventTock3tPrice * _eTName.length <= msg.value, "tock3ts: insuficient payable amount.");

        for (uint i=0; i < _eTName.length; i++){
            EventTock3t memory eventTock3t = EventTock3t(eventTock3ts.length +1, _eventId, _eTName[i],
                _eTDescription[i], _eTMaxSupply[i], _eTTokenPrice[i], 0, _eTBaseImageURI[i]);
            eventTock3ts.push(eventTock3t);
            emit NewEventTock3tCreated(eventTock3t);
        }
    }

    function buyTok3ts(uint eventTock3tId, uint tock3tAmount) public payable{
        EventTock3t memory eventTock3t = _getEventTock3t(eventTock3tId);
        Event memory thisEvent = _getEvent(eventTock3t.eventId);
        require(eventTock3t.mintedSupply + tock3tAmount <= eventTock3t.maxSupply,
            "tock3ts: tock3t allocation exceeded.");
        require(eventTock3t.tokenPrice * tock3tAmount <= msg.value,
            "tock3ts: insuficient payable amount.");
        require(block.timestamp >= thisEvent.saleStartDate,
            "tock3ts: sale for this event has not started");
        require(block.timestamp < thisEvent.saleEndDate,
            "tock3ts: sale for this event has ended");

        for (uint i=0; i < tock3tAmount; i++){
            Tock3t memory tock3t;
            tock3t.id = tock3ts.length + 1;
            tock3t.eventTock3tId = eventTock3tId;
            tock3t.tokenNumber = eventTock3t.mintedSupply.add(1);
            tock3t.revealed = false;
            tock3ts.push(tock3t);
            _safeMint(msg.sender, tock3t.id);
            tokenToAddress[tock3t.id] = msg.sender;
        }
        payable(eventToOwner[thisEvent.id]).transfer((eventTock3t.tokenPrice * tock3tAmount) * 4 / 5);
        emit NewSale(eventTock3t.eventId, tock3tAmount);
    }

    function register() payable public {
        require(registerPrice <= msg.value, "tock3ts: insuficient payable amount.");

        isAddressRegistered[msg.sender] = true;
    }

    function verify(address addr) public onlyOwner{
        isAddressVerified[addr] = true;
        isAddressRegistered[addr] = false;
    }

    function bulkVerify(address[] memory addresses) public onlyOwner{
        for (uint i=0; i < addresses.length; i++){
            isAddressVerified[addresses[i]] = true;
            isAddressRegistered[addresses[i]] = false;
        }
    }

    function unverify(address addr) public onlyOwner{
        isAddressVerified[addr] = false;
    }

    function isVerified(address addr) public view returns (bool){
        return isAddressVerified[addr];
    }

    function isRegistered(address addr) public view returns (bool){
        return isAddressRegistered[addr];
    }

    function setRegisterPrice(uint _registerPrice) public onlyOwner{
        registerPrice = _registerPrice;
    }

    function setCreateEventPrice(uint _createEventPrice) public onlyOwner{
        createEventPrice = _createEventPrice;
    }

    function setCreateEventTock3tPrice(uint _createEventTock3tPrice) public onlyOwner{
        createEventTock3tPrice = _createEventTock3tPrice;
    }

    function transferEventOwnership(address _to, uint _eventId) public {
        require(eventToOwner[_eventId] == msg.sender, "tock3ts: sender is not owner of event");
        require(isAddressVerified[_to], "tock3ts: recipient address is not verified");

        eventToOwner[_eventId] = _to;
    }

    function withdraw() external onlyOwner{
        payable(msg.sender).transfer(address(this).balance);
    }

    function _getEvent(uint eventId) private view returns (Event memory){
        return events[eventId];
    }

    function _getEventTock3t(uint eventTock3tId) private view returns (EventTock3t memory){
        return eventTock3ts[eventTock3tId];
    }

    function _getTock3t(uint tock3tId) private view returns (Tock3t memory){
        return tock3ts[tock3tId];
    }

    function getRegisterPrice() public view returns (uint){
        return registerPrice;
    }

    function getCreateEventPrice() public view returns (uint){
        return createEventPrice;
    }

    function getCreateEventTock3tPrice() public view returns (uint){
        return createEventTock3tPrice;
    }

    function getEventTock3tPrice(uint eventTock3tId) public view returns (uint){
        return _getEventTock3t(eventTock3tId).tokenPrice;
    }

    function isRevealed(uint tokenId) public view returns (bool){
        return _getTock3t(tokenId).revealed;
    }

    function reveal(uint tokenId) public{
        require(tokenToAddress[tokenId] == msg.sender, "tock3ts: token is not owned by sender.");

        _getTock3t(tokenId).revealed = true;
    }

    // Overrides start
    function tokenURI(uint tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "tock3ts: cannot query non-existent token");

        return eventTock3ts[tock3ts[tokenId].eventTock3tId].baseImageURI;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721){
        require(_isApprovedOrOwner(_msgSender(), tokenId), "tock3ts: transfer caller is not owner nor approved");
        require(!isRevealed(tokenId), "tock3ts: tock3t is revealed");

        tokenToAddress[tokenId] = to;
        _transfer(from, to, tokenId);
    }
    //Overrides end
}