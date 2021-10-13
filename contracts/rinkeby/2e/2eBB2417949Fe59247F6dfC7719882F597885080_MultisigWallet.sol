pragma solidity ^0.8.9;

contract MultisigWallet {

    struct TransactionRequest {
        bool isSpent;
        uint16 confirmations;
        address to;
        uint amount;
        mapping(address => bool) isConfirmed;
    }

    uint8 public confirmationRate;
    uint16 public ownersNumber;
    uint public requestIdCounter;
    mapping(address => bool) public owners;
    mapping(uint => TransactionRequest) public requests;
    mapping(uint => bool) public existingRequests;

    event TransactionRequestCreated(uint id, address indexed to, uint amount);
    event TransactionRequestProcessed(uint id, address indexed to, uint amount);

    constructor(uint8 _confirmationRat, address[] memory _owners) {
        confirmationRate = _confirmationRat;

        for(uint i = 0; i< _owners.length; i++) {
            owners[_owners[i]] = true;
        }

        ownersNumber = uint16(_owners.length);
    }

    modifier onlyOwners() {
        require(owners[msg.sender], "You are not an owner");
        _;
    }

    modifier requestExists(uint _requestId) {
        require(existingRequests[_requestId], "The request doesn't exist");
        _;
    }

    modifier requestIsNotSpent(uint _requestId) {
        require(!requests[_requestId].isSpent, "The request has been spent already");
        _;
    }

    function createTransationRequest(address _to, uint _amount) external onlyOwners {
        TransactionRequest storage request = requests[requestIdCounter];
        request.to = _to;
        request.amount = _amount;
        request.isConfirmed[msg.sender] = true;
        request.confirmations++;

        emit TransactionRequestCreated(requestIdCounter, _to, _amount);

        existingRequests[requestIdCounter] = true;
        requestIdCounter++;
    }

    function confirm(uint _requestId) external onlyOwners requestExists(_requestId) requestIsNotSpent(_requestId) {
        TransactionRequest storage request = requests[_requestId];
        require(!request.isConfirmed[msg.sender], "You've already confirmed");

        request.isConfirmed[msg.sender] = true;
        request.confirmations++;
    }

    function revokeConfirmation(uint _requestId) external onlyOwners requestExists(_requestId) requestIsNotSpent(_requestId) {
        TransactionRequest storage request = requests[_requestId];
        require(request.isConfirmed[msg.sender], "You haven't confirmed yet");

        request.isConfirmed[msg.sender] = false;
        request.confirmations--;
    }

    function processRequest(uint _requestId) external onlyOwners requestExists(_requestId) requestIsNotSpent(_requestId) {
        TransactionRequest storage request = requests[_requestId];
        require(isSpendable(request), "The request doesn't have enough confirmation");
        require(address(this).balance >= request.amount, "There is not enough money in the contract");
        
        request.isSpent = true;

        payable(request.to).transfer(request.amount);

        emit TransactionRequestProcessed(_requestId, request.to, request.amount);
    }

    function isSpendable(TransactionRequest storage _request) private view returns(bool) {
        return confirmationRate < _request.confirmations * 100 / ownersNumber;
    }

    function isRequestConfirmedBy(uint _requestId, address _by) external view returns(bool){
        return requests[_requestId].isConfirmed[_by];
    }

    receive() external payable {

    }

}