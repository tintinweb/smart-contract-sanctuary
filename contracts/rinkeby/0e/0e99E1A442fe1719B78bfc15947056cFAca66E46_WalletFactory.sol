pragma solidity ^0.8.9;

import "./MultisigWallet.sol";

contract WalletFactory {

    address[] wallets;
    mapping(address => address[]) ownerToWallets;

    function createWallet(uint8 _confirmationRate, address[] memory _owners) external returns(address) {
        address wallet = address(new MultisigWallet(_confirmationRate, _owners));

        for(uint32 i = 0; i < _owners.length; i++) {
            ownerToWallets[_owners[i]].push(wallet);
        }
        
        return wallet;
    }

    function getMyWallets() external view returns(address[] memory) {
        return ownerToWallets[msg.sender];
    } 
}

pragma solidity ^0.8.9;

contract MultisigWallet {
    struct TransactionRequest {
        bool isSpent;
        uint16 confirmations;
        address to;
        uint256 amount;
        mapping(address => bool) isConfirmed;
    }

    uint8 public confirmationRate;
    uint16 public ownersNumber;
    uint256 public requestIdCounter;
    mapping(address => bool) public owners;
    mapping(uint256 => TransactionRequest) public requests;
    mapping(uint256 => bool) public existingRequests;

    event TransactionRequestCreated(
        uint256 id,
        address indexed to,
        uint256 amount
    );
    event TransactionRequestProcessed(
        uint256 id,
        address indexed to,
        uint256 amount
    );

    constructor(uint8 _confirmationRate, address[] memory _owners) {
        confirmationRate = _confirmationRate;

        for (uint32 i = 0; i < _owners.length; i++) {
            owners[_owners[i]] = true;
        }

        ownersNumber = uint16(_owners.length);
    }

    modifier onlyOwners() {
        require(owners[msg.sender], "You are not an owner");
        _;
    }

    modifier requestExists(uint256 _requestId) {
        require(existingRequests[_requestId], "The request doesn't exist");
        _;
    }

    modifier requestIsNotSpent(uint256 _requestId) {
        require(
            !requests[_requestId].isSpent,
            "The request has been spent already"
        );
        _;
    }

    function createTransationRequest(address _to, uint256 _amount)
        external
        onlyOwners
    {
        TransactionRequest storage request = requests[requestIdCounter];
        request.to = _to;
        request.amount = _amount;
        request.isConfirmed[msg.sender] = true;
        request.confirmations++;

        emit TransactionRequestCreated(requestIdCounter, _to, _amount);

        existingRequests[requestIdCounter] = true;
        requestIdCounter++;
    }

    function confirm(uint256 _requestId)
        external
        onlyOwners
        requestExists(_requestId)
        requestIsNotSpent(_requestId)
    {
        TransactionRequest storage request = requests[_requestId];
        require(!request.isConfirmed[msg.sender], "You've already confirmed");

        request.isConfirmed[msg.sender] = true;
        request.confirmations++;
    }

    function revokeConfirmation(uint256 _requestId)
        external
        onlyOwners
        requestExists(_requestId)
        requestIsNotSpent(_requestId)
    {
        TransactionRequest storage request = requests[_requestId];
        require(request.isConfirmed[msg.sender], "You haven't confirmed yet");

        request.isConfirmed[msg.sender] = false;
        request.confirmations--;
    }

    function processRequest(uint256 _requestId)
        external
        onlyOwners
        requestExists(_requestId)
        requestIsNotSpent(_requestId)
    {
        TransactionRequest storage request = requests[_requestId];
        require(
            isSpendable(request),
            "The request doesn't have enough confirmation"
        );
        require(
            address(this).balance >= request.amount,
            "There is not enough money in the contract"
        );

        request.isSpent = true;

        payable(request.to).transfer(request.amount);

        emit TransactionRequestProcessed(
            _requestId,
            request.to,
            request.amount
        );
    }

    function isSpendable(TransactionRequest storage _request)
        private
        view
        returns (bool)
    {
        return confirmationRate < (_request.confirmations * 100) / ownersNumber;
    }

    function isRequestConfirmedBy(uint256 _requestId, address _by)
        external
        view
        returns (bool)
    {
        return requests[_requestId].isConfirmed[_by];
    }

    receive() external payable {}
}