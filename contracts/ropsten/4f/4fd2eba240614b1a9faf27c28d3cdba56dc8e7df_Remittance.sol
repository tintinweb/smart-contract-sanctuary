pragma solidity ^0.4.24; // Specify compiler version

// Init remittance contract
contract Remittance {
    mapping (address => uint256) balances; // Balance of each address
    mapping (address => uint256) balanceMaturity; // Last time balance was updated
    mapping (address => bytes32) publicKeys; // Public key associated with each address

    event deposited(address sender, bytes32 publicKey, uint amount); // Log deposit
    event attemptedClaim(address claimant, address claimAddress, bytes32 publicKey, uint amount); // Log claim
    event attemptedWithdrawal(address withdrawer, uint balanceMaturity, uint amount); // Log withdrawal
    
    function deposit(string privatekey1, string privatekey2) public payable {
        balances[msg.sender] = msg.value; // Set user balance
        balanceMaturity[msg.sender] = block.number; // Set updated time

        publicKeys[msg.sender] = keccak256(abi.encodePacked(privatekey1, privatekey2)); // Generate public key

        emit deposited(msg.sender, publicKeys[msg.sender], msg.value); // Send deposit event
    }

    function claim(address claimAddress, string privatekey1, string privatekey2) public payable {
        uint balance = balances[claimAddress]; // Store balance

        emit attemptedClaim(msg.sender, claimAddress, publicKeys[claimAddress], balance); // Send claim event

        require(keccak256(abi.encodePacked(privatekey1, privatekey2)) == publicKeys[claimAddress], "Invalid private keys."); // Check for matching privatekeys
        require(msg.sender != claimAddress, "Cannot claim own balance (request a withdrawal instead)."); // Check that claimant isn&#39;t issuer

        balances[claimAddress] = 0; // Reset balance
        balanceMaturity[claimAddress] = block.number; // Rest maturity

        msg.sender.transfer(balance); // Transfer to specified claim address
    }

    function withdraw() public payable {
        uint balance = balances[msg.sender]; // Store balance

        emit attemptedWithdrawal(msg.sender, balanceMaturity[msg.sender], balances[msg.sender]); // Send withdrawal event

        require((block.number - balanceMaturity[msg.sender]) > 60, "Balance is not yet eligible for withdrawal."); // Check balance is mature enough for a withdrawal

        balances[msg.sender] = 0; // Rest balance
        balanceMaturity[msg.sender] = block.number; // Reset maturity

        msg.sender.transfer(balance); // Transfer ether
    }
}