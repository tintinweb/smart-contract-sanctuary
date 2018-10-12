pragma solidity ^0.4.24; // Specify compiler version

// Init remittance contract
contract Remittance {
    uint withdrawalDelay = 60; // Time before withdrawal can be made

    struct Deposit {
        address Sender;
        uint256 Balance;
        uint256 Deadline;
        bytes32 PublicKey;
        address Claimant;
        string PrivateKey1;
    }

    mapping (bytes32 => Deposit) Deposits; // Deposits by public key

    event deposited(address sender, bytes32 publicKey, uint amount); // Log deposit
    event claimed(address claimant, address claimAddress, bytes32 publicKey, uint amount); // Log claim
    event withdrew(address withdrawer, uint blockTime, uint amount); // Log withdrawal
    
    function deposit(bytes32 _publicKey) public payable {
        require(Deposits[_publicKey].Balance == 0, "Already deposit with public key"); // Check not existing
        Deposits[_publicKey] = Deposit(msg.sender, msg.value, block.number + withdrawalDelay, _publicKey, 0, ""); // Set deposit

        emit deposited(msg.sender, _publicKey, msg.value); // Send deposit event
    }

    function claim(bytes32 _publicKey, string _privateKey1) public {
        require(msg.sender != Deposits[_publicKey].Sender, "Cannot claim own balance (request a withdrawal instead)."); // Check isn&#39;t issuer

        Deposits[_publicKey].Claimant = msg.sender; // Set claimant
        Deposits[_publicKey].PrivateKey1 = _privateKey1; // Set private key 1
    }

    function approveClaim(bytes32 _publicKey, string _privateKey2) public {
        require(Deposits[_publicKey].Claimant != msg.sender, "Cannot approve own claim."); // Check isn&#39;t claimant
        require(Deposits[_publicKey].Sender == msg.sender, "Issuer must approve all claims."); // Check is issuer
        require(keccak256(abi.encodePacked(Deposits[_publicKey].PrivateKey1, _privateKey2)) == Deposits[_publicKey].PublicKey, "Invalid private keys.");

        uint balance = Deposits[_publicKey].Balance; // Store balance

        emit claimed(msg.sender, Deposits[_publicKey].Sender, Deposits[_publicKey].PublicKey, Deposits[_publicKey].Balance);

        Deposits[_publicKey].Balance = 0; // Reset balance

        msg.sender.transfer(balance); // Transfer to specified claim address
    }

    function withdraw(bytes32 _publicKey) public {
        uint balance = Deposits[_publicKey].Balance; // Store balance

        require(block.number >= Deposits[_publicKey].Deadline, "Balance is not yet eligible for withdrawal."); // Check is ready for withdrawal
        require(msg.sender == Deposits[_publicKey].Sender, "Non-owner cannot withdraw."); // Check owner is requesting withdrawal

        emit withdrew(msg.sender, block.number, Deposits[_publicKey].Balance); // Send withdrawal event

        Deposits[_publicKey].Balance = 0; // Rest balance

        msg.sender.transfer(balance); // Transfer ether
    }
}