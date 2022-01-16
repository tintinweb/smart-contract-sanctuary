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
        bool saleActive;
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
    mapping(uint => uint[]) eventToEventTock3ts;

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
        uint _eventEndDate, string memory _eventLocation, string[] memory _eventImages) public payable {
        require(createEventPrice <= msg.value, "tock3ts: insuficient payable amount.");
        require(isAddressVerified[msg.sender], "tock3ts: address not verified.");

        Event memory newEvent = Event(events.length, _eventName, _eventDescription, _eventStartDate,
            _eventEndDate, _eventLocation, _eventImages, false);
        eventToOwner[events.length] = msg.sender;
        events.push(newEvent);
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
            EventTock3t memory eventTock3t = EventTock3t(eventTock3ts.length, _eventId, _eTName[i],
                _eTDescription[i], _eTMaxSupply[i], _eTTokenPrice[i], 0, _eTBaseImageURI[i]);
            eventTock3ts.push(eventTock3t);
            eventToEventTock3ts[_eventId].push(eventTock3ts.length);
            emit NewEventTock3tCreated(eventTock3t);
        }
    }

    function buyTock3ts(uint eventTock3tId, uint tock3tAmount) public payable{
        EventTock3t memory thisEventTock3t = eventTock3ts[eventTock3tId];
        Event memory thisEvent = events[thisEventTock3t.eventId];
        require(thisEventTock3t.mintedSupply + tock3tAmount <= thisEventTock3t.maxSupply,
            "tock3ts: tock3t allocation exceeded.");
        require(thisEventTock3t.tokenPrice * tock3tAmount <= msg.value,
            "tock3ts: insuficient payable amount.");
        require(thisEvent.saleActive,
            "tock3ts: sale is not active");

        for (uint i=0; i < tock3tAmount; i++){
            Tock3t memory tock3t;
            tock3t.id = tock3ts.length;
            tock3t.eventTock3tId = eventTock3tId;
            tock3t.tokenNumber = thisEventTock3t.mintedSupply + 1;
            tock3t.revealed = false;
            tock3ts.push(tock3t);
            _safeMint(msg.sender, tock3t.id);
            tokenToAddress[tock3t.id] = msg.sender;
            thisEventTock3t.mintedSupply++;
        }
        uint refundExcess = msg.value - (thisEventTock3t.tokenPrice * tock3tAmount);
        payable(eventToOwner[thisEvent.id]).transfer((thisEventTock3t.tokenPrice * tock3tAmount) * 4 / 5);
        payable(msg.sender).transfer(refundExcess);
        emit NewSale(thisEventTock3t.eventId, tock3tAmount);
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
        return eventTock3ts[eventTock3tId].tokenPrice;
    }

    function isRevealed(uint tokenId) public view returns (bool){
        return tock3ts[tokenId].revealed;
    }

    function reveal(uint tokenId) public{
        require(tokenToAddress[tokenId] == msg.sender, "tock3ts: token is not owned by sender.");

        tock3ts[tokenId].revealed = true;
    }

    function toggleSaleStatus(uint eventId) public {
        require(eventToOwner[eventId] == msg.sender, "tock3ts: event is not owned by sender.");
        events[eventId].saleActive = !events[eventId].saleActive;
    }

    function getEventTock3tsByEvent(uint _eventId) public view returns(uint[] memory){
        return eventToEventTock3ts[_eventId];
    }

    function tenNextEvents() public view returns (uint[] memory){
        uint[] memory ids;
        uint counter;
        for (uint i=0; i < events.length && i < 10; i++){
            if (events[i].startDate > block.timestamp) {
                ids[counter] = i;
                counter++;
            }
        }
        return ids;
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

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override(ERC721) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "tock3ts: transfer caller is not owner nor approved");
        require(!isRevealed(tokenId), "tock3ts: tock3t is revealed");
        _safeTransfer(from, to, tokenId, _data);
    }
    //Overrides end
}