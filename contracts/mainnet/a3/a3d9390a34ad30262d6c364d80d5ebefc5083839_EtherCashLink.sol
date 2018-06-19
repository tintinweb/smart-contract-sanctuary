pragma solidity ^0.4.18;


contract EtherCashLink {


    struct Payment {
        bool paid;
        bytes32 verification;
        uint amount;
        bool exists;
        address sender;
    }

    mapping(bytes32 => Payment) public payments;
    

    event GotPaid(address sender, address receiver, uint amount, bytes32 verification); // Event
    event LinkCreated(address sender, uint amount, bytes32 verification); // Event

    modifier onlyIfValidCode(string _passcode) {
        require(keccak256(_passcode) == payments[keccak256(_passcode)].verification);
        _;
    }

    modifier onlyIfNotPaid(string _passcode) {
        require(!payments[keccak256(_passcode)].paid);
        _;
    }

    function createLink(bytes32 _verification) public payable {
        require(!payments[_verification].exists);
        require(msg.value > 0);
        var newPayment = payments[_verification];
        newPayment.paid = false;
        newPayment.verification = _verification;
        newPayment.amount = msg.value;
        newPayment.exists = true;
        newPayment.sender = msg.sender;
        emit LinkCreated(newPayment.sender, newPayment.amount,  newPayment.verification);

    }

    function getPaid(string _passcode, address _receiver) 
        onlyIfValidCode(_passcode) 
        onlyIfNotPaid(_passcode) 
        public returns (bool) {
        payments[keccak256(_passcode)].paid = true;
        _receiver.transfer(payments[keccak256(_passcode)].amount);
        return true;
        emit GotPaid(payments[keccak256(_passcode)].sender, _receiver,payments[keccak256(_passcode)].amount, payments[keccak256(_passcode)].verification);
    }
    
    function wasPaid(bytes32 _verification) public view returns (bool) {
        return (payments[_verification].paid);
    }

   
}