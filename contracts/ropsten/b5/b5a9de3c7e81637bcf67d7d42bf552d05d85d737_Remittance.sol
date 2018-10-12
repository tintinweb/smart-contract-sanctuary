pragma solidity ^0.4.24; // Specify compiler version

// Init remittance contract
contract Remittance {
    uint withdrawalDelay = 60; // Time before withdrawal can be made

    struct Deposit {
        address Sender;
        uint256 Balance;
        uint256 Deadline;
        bytes32 PublicKey;
    }

    mapping (bytes32 => Deposit) Deposits; // Deposits by public key

    event deposited(address sender, bytes32 publicKey, uint amount); // Log deposit
    event attemptedClaim(address claimant, address claimAddress, bytes32 publicKey, uint amount); // Log claim
    event attemptedWithdrawal(address withdrawer, uint blockTime, uint amount); // Log withdrawal
    
    function deposit(bytes32 _publicKey) public payable {
        require(Deposits[_publicKey].Balance == 0, "Already deposit with public key"); // Check not existing
        Deposits[_publicKey] = Deposit(msg.sender, msg.value, block.number + withdrawalDelay, _publicKey); // Set deposit

        emit deposited(msg.sender, _publicKey, msg.value); // Send deposit event
    }

    function claim(bytes32 _publicKey, string _privatekey1, string _privatekey2) public {
        uint balance = Deposits[_publicKey].Balance; // Store balance

        emit attemptedClaim(msg.sender, Deposits[_publicKey].Sender, Deposits[_publicKey].PublicKey, Deposits[_publicKey].Balance);

        require(keccak256(abi.encodePacked(_privatekey1, _privatekey2)) == Deposits[_publicKey].PublicKey, "Invalid private keys.");
        require(msg.sender != Deposits[_publicKey].Sender, "Cannot claim own balance (request a withdrawal instead).");

        Deposits[_publicKey].Balance = 0; // Reset balance

        msg.sender.transfer(balance); // Transfer to specified claim address
    }

    function withdraw(bytes32 _publicKey) public {
        uint balance = Deposits[_publicKey].Balance; // Store balance

        emit attemptedWithdrawal(msg.sender, block.number, Deposits[_publicKey].Balance); // Send withdrawal event

        require(block.number >= Deposits[_publicKey].Deadline, "Balance is not yet eligible for withdrawal."); // Check is ready for withdrawal
        require(msg.sender == Deposits[_publicKey].Sender, "Non-owner cannot withdraw."); // Check owner is requesting withdrawal

        Deposits[_publicKey].Balance = 0; // Rest balance

        msg.sender.transfer(balance); // Transfer ether
    }
}