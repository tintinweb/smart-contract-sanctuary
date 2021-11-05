pragma solidity ^0.5.17;

/**
 * Copyright (C) 2018, 2019, 2020 Ethernity HODL UG
 *
 * This file is part of ETHERNITY PoX SC.
 *
 * ETHERNITY PoE SC is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */


import "./EthernityStorage.sol";
import "./Models.sol";

contract EthernityImplementationV1 is EthernityStorage {
    event _addDPRequestEV(address indexed _from, uint _rowNumber);
    event _addDORequestEV(address indexed _from, uint _rowNumber);
    event _placeOrderEV(address indexed _from, uint _orderNumber);

    function _addDPRequest(
        uint8 _cpuRequest,
        uint8 _memRequest,
        uint8 _storageRequest,
        uint8 _bandwidthRequest,
        uint16 _duration,
        uint8 _minPrice,
        string memory  _metadata1,
        string memory _metadata2,
        string memory _metadata3,
        string memory _metadata4
    ) public onlyDelegate returns (uint _rowNumber)
    {
        //validate cpu
        require(
            _cpuRequest > 0 && _cpuRequest <= MAX_CPU,
            "cpuRequest is invalid");
        //validate memory
        require(
            _memRequest > 0 && _memRequest <= MAX_MEMORY,
            "memRequest is invalid");
        //validate _bandwidthRequest
        require(
            _bandwidthRequest > 0 && _bandwidthRequest <= MAX_BANDWIDTH,
            "bandwidthRequest is invalid");
        //validate memory
        require(
            _storageRequest > 0 && _storageRequest <= MAX_STORAGE,
            "storageRequest is invalid");


        usersDPRequests[msg.sender].push(dpRequestsList.length);
        _rowNumber = dpRequestsList.push(Models.DPRequest({
            dproc: msg.sender,
            cpuRequest : _cpuRequest,
            memoryRequest : _memRequest,
            storageRequest : _storageRequest,
            bandwidthRequest : _bandwidthRequest,
            duration : _duration,
            minPrice : _minPrice,
            createdAt : uint32(now),
            price : 0,
            metadataSize : 0,
            status : Models.RequestStatus.AVAILABLE,
            Metadata1 : _metadata1,
            Metadata2 : _metadata2,
            Metadata3 : _metadata3,
            Metadata4 : _metadata4
            })) - 1;

        emit _addDPRequestEV(msg.sender, _rowNumber);
        return _rowNumber;
    }

    function _getDPRequestsCount() public view onlyDelegate returns (uint256 _length) {

        return dpRequestsList.length;
    }

    function _getDPRequest(uint256 _requestListItem) public view onlyDelegate returns (
        address dproc,
        uint8 cpuRequest,
        uint8 memoryRequest,
        uint8 storageRequest,
        uint8 bandwidthRequest,
        uint16 duration,
        uint8 minPrice,
        uint status)
    {

        require(
            _requestListItem >= 0 && _requestListItem < dpRequestsList.length,
            "Invalid index provided."
        );
        dproc = dpRequestsList[_requestListItem].dproc;
        status = uint(dpRequestsList[_requestListItem].status);

        return (
        dproc,
        dpRequestsList[_requestListItem].cpuRequest,
        dpRequestsList[_requestListItem].memoryRequest,
        dpRequestsList[_requestListItem].storageRequest,
        dpRequestsList[_requestListItem].bandwidthRequest,
        dpRequestsList[_requestListItem].duration,
        dpRequestsList[_requestListItem].minPrice,
        status
        );
    }

    function _getDPRequestMetadata(uint256 _requestListItem) public view onlyDelegate returns (
        address dproc,
        string memory metadata1,
        string memory metadata2,
        string memory metadata3,
        string memory metadata4)
    {
        require(
            _requestListItem >= 0 && _requestListItem < dpRequestsList.length,
            "invalid request index");

        Models.DPRequest storage request = dpRequestsList[_requestListItem];

        return (
        request.dproc,
        request.Metadata1,
        request.Metadata2,
        request.Metadata3,
        request.Metadata4
        );
    }



    function _cancelDPRequest(uint256 _requestListItem) public onlyDelegate {
        require(
            _requestListItem >= 0 && _requestListItem < dpRequestsList.length,
            "invalid request index");
        require(
            msg.sender == dpRequestsList[_requestListItem].dproc,
            "only delegated processor can modify this");

        Models.DPRequest storage request = dpRequestsList[_requestListItem];
        require(
            request.status == Models.RequestStatus.AVAILABLE,
            "Only available status can be canceled");

        request.status = Models.RequestStatus.CANCELED;
    }

    function _getMyDPRequests() public view onlyDelegate returns (uint256[] memory req){

        return usersDPRequests[msg.sender];
    }

    /**
    ** metadata storage part
    */
    function _addMetadataToDPRequest(uint256 _requestListItem, string memory _key, string memory _value) public onlyDelegate returns (uint _rowNumber){

        require(
            _requestListItem >= 0 && _requestListItem < dpRequestsList.length,
            "invalid request index");

        require(
            msg.sender == dpRequestsList[_requestListItem].dproc,
            "only the delegated processor can modify this");

        Models.DPRequest storage request = dpRequestsList[_requestListItem];
        request.metadata[request.metadataSize].key = _key;
        request.metadata[request.metadataSize].value = _value;
        request.metadataSize++;

        return request.metadataSize - 1;
    }

    function _getMetadataCountForDPRequest(uint256 _requestListItem) public view onlyDelegate returns (uint256 _length){
        require(
            _requestListItem >= 0 && _requestListItem < dpRequestsList.length,
            "invalid request index");

        return dpRequestsList[_requestListItem].metadataSize;
    }

    function _getMetadataValueForDPRequest(uint256 _requestListItem, uint256 _metadataItem) onlyDelegate
    public view returns (
        string memory key,
        string memory value
    ){
        require(
            _requestListItem >= 0 && _requestListItem < dpRequestsList.length,
            "invalid request index");
        require(
            _metadataItem >= 0 && _metadataItem < dpRequestsList[_requestListItem].metadataSize,
            "invalid metadataItem index");

        return (
        dpRequestsList[_requestListItem].metadata[_metadataItem].key,
        dpRequestsList[_requestListItem].metadata[_metadataItem].value
        );
    }

    /**
    * region data owner requests
    */

    function _addDORequest(
        uint8 _cpuRequest,
        uint8 _memRequest,
        uint8 _storageRequest,
        uint8 _bandwidthRequest,
        uint16 _duration,
        uint8 _instances,
        uint8 _maxPrice,
        string memory _metadata1,
        string memory _metadata2,
        string memory _metadata3,
        string memory _metadata4
    ) public onlyDelegate returns (uint _rowNumber)
    {

        require(
            _instances > 0 && _instances <= MAX_INSTANCES,
            "instance is invalid");

        require(
            _cpuRequest > 0 && _cpuRequest <= MAX_CPU,
            "cpuRequest is invalid");

        require(
            _memRequest > 0 && _memRequest <= MAX_MEMORY,
            "memRequest is invalid");

        require(
            _bandwidthRequest > 0 && _bandwidthRequest <= MAX_BANDWIDTH,
            "bandwidthRequest is invalid");

        require(
            _storageRequest > 0 && _storageRequest <= MAX_STORAGE,
            "storageRequest is invalid");

        usersDORequests[msg.sender].push(doRequestsList.length);
         _rowNumber = doRequestsList.push(Models.DORequest({
            downer : msg.sender,
            cpuRequest : _cpuRequest,
            memoryRequest : _memRequest,
            storageRequest : _storageRequest,
            bandwidthRequest : _bandwidthRequest,
            duration : _duration,
            instances : _instances,
            bookedInstances : 0,
            createdAt : uint32(now),
            maxPrice : _maxPrice,
            tokens : _maxPrice * _instances * _duration,
            metadataSize : 0,
            status : Models.RequestStatus.AVAILABLE,
            Metadata1 : _metadata1,
            Metadata2 : _metadata2,
            Metadata3 : _metadata3,
            Metadata4 : _metadata4
            })) - 1;
        emit _addDORequestEV(msg.sender, _rowNumber);
        return _rowNumber;
    }

    function _getDORequestsCount() public view onlyDelegate returns (uint256 _length) {

        return doRequestsList.length;
    }


    function _getDORequest(uint256 _requestListItem) public view onlyDelegate returns (
        address downer,
        uint8 cpuRequest,
        uint8 memoryRequest,
        uint8 storageRequest,
        uint8 bandwidthRequest,
        uint16 duration,
        uint8 maxPrice,
        uint status)
    {

        require(
            _requestListItem >= 0 && _requestListItem < doRequestsList.length,
            "invalid request index");

        downer = doRequestsList[_requestListItem].downer;
        status = uint(doRequestsList[_requestListItem].status);
        return (
        downer,
        doRequestsList[_requestListItem].cpuRequest,
        doRequestsList[_requestListItem].memoryRequest,
        doRequestsList[_requestListItem].storageRequest,
        doRequestsList[_requestListItem].bandwidthRequest,
        doRequestsList[_requestListItem].duration,
        doRequestsList[_requestListItem].maxPrice,
        status
        );
    }

    function _getDORequestMetadata(uint256 _requestListItem) public view onlyDelegate returns (
        address downer,
        string memory metadata1,
        string memory metadata2,
        string memory metadata3,
        string memory metadata4)
    {
        require(
            _requestListItem >= 0 && _requestListItem < doRequestsList.length,
            "invalid request index");

        downer = doRequestsList[_requestListItem].downer;
        return (
        downer,
        doRequestsList[_requestListItem].Metadata1,
        doRequestsList[_requestListItem].Metadata2,
        doRequestsList[_requestListItem].Metadata3,
        doRequestsList[_requestListItem].Metadata4
        );
    }

    function _cancelDORequest(uint256 _requestListItem) public onlyDelegate{
        require(
            _requestListItem >= 0 && _requestListItem < doRequestsList.length,
            "invalid request index");
        require(
            msg.sender == doRequestsList[_requestListItem].downer,
            "only data owner can modify this");

        Models.DORequest storage request = doRequestsList[_requestListItem];
        require(
            request.status == Models.RequestStatus.AVAILABLE && request.bookedInstances == 0,
            "Only available status can be canceled");

        request.status = Models.RequestStatus.CANCELED;
    }

    function _getMyDORequests() public view onlyDelegate returns (uint256[] memory req){

        return usersDORequests[msg.sender];
    }

    function _addMetadataToRequest(uint256 _requestListItem, string memory _key, string memory _value) public onlyDelegate returns (uint _rowNumber){

        require(
            _requestListItem >= 0 && _requestListItem < doRequestsList.length,
            "invalid request index");

        require(
            msg.sender == doRequestsList[_requestListItem].downer,
            "only data owner can modify this");

        Models.DORequest storage request = doRequestsList[_requestListItem];
        request.metadata[request.metadataSize].key = _key;
        request.metadata[request.metadataSize].value = _value;
        request.metadataSize++;

        return request.metadataSize - 1;
    }

    function _getMetadataCountForRequest(uint256 _requestListItem) public view onlyDelegate returns (uint256 _length){
        require(
            _requestListItem >= 0 && _requestListItem < doRequestsList.length,
            "invalid request index");

        return doRequestsList[_requestListItem].metadataSize;
    }

    function _getMetadataValueForRequest(uint256 _requestListItem, uint256 _metadataItem) onlyDelegate
    public view returns (
        string memory key,
        string memory value
    ){
        require(
            _requestListItem >= 0 && _requestListItem < doRequestsList.length,
            "invalid request index");
        require(
            _metadataItem >= 0 && _metadataItem < doRequestsList[_requestListItem].metadataSize,
            "invalid metadataItem index");

        return (
        doRequestsList[_requestListItem].metadata[_metadataItem].key,
        doRequestsList[_requestListItem].metadata[_metadataItem].value
        );
    }


    /**
    * order region
    */

    function _placeOrder(uint256 _doRequestItem, uint256 _dpRequestItem) public onlyDelegate returns (uint _orderNumber){
        require(
            _doRequestItem >= 0 && _doRequestItem < doRequestsList.length,
            "invalid do request index");

        require(
            _dpRequestItem >= 0 && _dpRequestItem < dpRequestsList.length,
            "invalid dp request index");

        Models.DORequest storage doRequest = doRequestsList[_doRequestItem];
        require(
            doRequest.status == Models.RequestStatus.AVAILABLE,
            "Only available status can be requested");
        Models.DPRequest storage dpRequest = dpRequestsList[_dpRequestItem];
        require(
            dpRequest.status == Models.RequestStatus.AVAILABLE,
            "Only available status can be requested");

        require(
            dpRequest.dproc == msg.sender || doRequest.downer == msg.sender,
            "Only data/process owner or delegated processsor can place this order");

        address placedBy;
        if (dpRequest.dproc == msg.sender)
            placedBy = dpRequest.dproc;
        else
            placedBy = doRequest.downer;

        doRequest.bookedInstances = doRequest.bookedInstances + 1;
        if (doRequest.bookedInstances == doRequest.instances)
            doRequest.status = Models.RequestStatus.BOOKED;

        dpRequest.status = Models.RequestStatus.BOOKED;

        usersOrders[dpRequest.dproc].push(orders.length);
        usersOrders[doRequest.downer].push(orders.length);

        _orderNumber = orders.push(Models.Order({
            instance : doRequest.bookedInstances,
            dproc : dpRequest.dproc,
            downer : doRequest.downer,
            placedBy : placedBy,
            processor : address(0),
            dpRequest : _dpRequestItem,
            doRequest : _doRequestItem,
            timeout : uint32(now),
            metadataSize : 0,
            status : Models.OrderStatus.OPEN,
            price : 0,
            result : ''
            })) - 1;

        emit _placeOrderEV(msg.sender, _orderNumber);
        return _orderNumber;

    }

    function _getOrdersCount() public view onlyDelegate returns (uint256 _length) {

        return orders.length;
    }

    function _getMyDOOrders() public view onlyDelegate returns (uint256[] memory req){

        return usersOrders[msg.sender];
    }


    function _getOrder(uint256 _orderItem) public onlyDelegate view returns (
        address downer,
        address dproc,
        uint doRequest,
        uint dpRequest,
        uint status)
    {
        require(
            _orderItem >= 0 && _orderItem < doRequestsList.length,
            "invalid request index");

        return (
        orders[_orderItem].downer,
        orders[_orderItem].dproc,
        orders[_orderItem].doRequest,
        orders[_orderItem].dpRequest,
        uint(orders[_orderItem].status)
        );
    }


    /**
    * orders can be processed only after being approved
    * by other part(do/dp)
    */
    function _approveOrder(uint256 _orderItem) public onlyDelegate returns (bool success){
        require(
            _orderItem >= 0 && _orderItem < orders.length,
            "invalid order index");

        Models.Order storage order = orders[_orderItem];

        require(
            msg.sender == order.downer || msg.sender == order.dproc,
            "only data owner or data processor can approve this");

        require(
            msg.sender != order.placedBy,
            "the other party should approve");

        require(
            order.status == Models.OrderStatus.OPEN,
            "only open orders can be approved"
        );

        order.status = Models.OrderStatus.PROCESSING;
        return true;
    }

    /**
    * add processor address by data processor
    */
    function _addProcessorToOrder(uint256 _orderItem, address processor) public onlyDelegate returns (bool success){
        require(
            _orderItem >= 0 && _orderItem < orders.length,
            "invalid order index");

        Models.Order storage order = orders[_orderItem];

        require(
            msg.sender == order.dproc,
            "only data processor can add a processor");

        require(
            order.status == Models.OrderStatus.PROCESSING,
            "only open orders can be approved"
        );

        order.processor = processor;
        return true;
    }

    /**
    * add result to order
    */
    function _addResultToOrder(uint256 _orderItem, string memory _result) public onlyDelegate returns (bool success){
        require(
            _orderItem >= 0 && _orderItem < orders.length,
            "invalid order index");

        Models.Order storage order = orders[_orderItem];

        require(
            msg.sender == order.processor,
            "only processor can add a result");

        require(
            order.status == Models.OrderStatus.PROCESSING,
            "only open orders can be approved"
        );


        order.result = _result;
        order.status = Models.OrderStatus.CLOSED;
        return true;
    }

    /**
    * get result from order
    */
    function _getResultFromOrder(uint256 _orderItem) public view onlyDelegate returns (string memory _Result){
        require(
            _orderItem >= 0 && _orderItem < orders.length,
            "invalid order index");

        Models.Order storage order = orders[_orderItem];

        require(
            msg.sender == order.downer,
            "only owner can read the results");

        require(
            order.status == Models.OrderStatus.CLOSED,
            "only closed orders have the result"
        );

        return order.result;
    }


    function _addToSeedRound(address addr) public onlyOwner returns (bool){
        lockTime[addr] = twoYears;
        return true;
    }

    function _addToPrivateSaleRound(address addr) public onlyOwner returns (bool){
        lockTime[addr] = twoYears;
        return true;
    }

    function _addToPresaleRound(address addr) public onlyOwner returns (bool){
        lockTime[addr] = oneYear;
        return true;
    }

    function _addToPublicOneRound(address addr) public onlyOwner returns (bool){
        lockTime[addr] =  oneYear;
        return true;
    }

    function _addToPublicTwoRound(address addr) public onlyOwner returns (bool){
        lockTime[addr] =  sixMonths;
        return true;
    }

    function _removeLockoutTimestamp(address addr) public onlyOwner returns (bool){
        lockTime[addr] = 0;
        return true;
    }

    function _getLockoutTimestamp(address addr) public view returns (uint128){
        return lockTime[addr] + baseLockDate;
    }

    function _setBaseLockTimestamp(uint128 timestamp) public returns (bool) {
        baseLockDate = timestamp;
        return true;
    }

    function _getBaseLockTimestamp() public view returns (uint128) {
        return baseLockDate;
    }

    function _isAddressLocked(address addr) internal view returns (bool){
        if(msg.sender == owner) return false;
        if(baseLockDate > block.timestamp) return true;
        if(_getLockoutTimestamp(addr) > block.timestamp) return true;
        return false;
    }

    function transfer(address to, uint tokens) public returns (bool success){
        if(_isAddressLocked(msg.sender)) revert();
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success){
        if(_isAddressLocked(msg.sender)) revert();
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function approve(address spender, uint tokens) public returns (bool success){
        if(_isAddressLocked(msg.sender)) revert();
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success){
        if(_isAddressLocked(msg.sender)) revert();allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }
}