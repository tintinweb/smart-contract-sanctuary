/**
 *Submitted for verification at Etherscan.io on 2021-08-23
*/

pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/access/AccessControl.sol";

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

struct Transaction {
    address to_address;
    uint256 amount;
    uint256 confirmations;
    bool is_confirmed;
}

contract Migrator {
    
    bytes32 public constant CONFIRMER_ROLE = keccak256("CONFIRMER_ROLE");

    IERC20 public token;
    uint256 public required_confirmations;
    
    mapping(bytes32 => Transaction) public transactions;
    mapping(address => mapping(bytes32 => bool)) confirmations;
        
    event Confirm(bytes32 transaction_hash, address to_address, uint256 amount, address confirmer);
    event Transfer(address to_address, uint256 amount);

    
    constructor(IERC20 _token, uint256 _required_confirmations) {
        token = _token;
        required_confirmations = _required_confirmations;
    }
    
    function setRequiredConfirmations(uint256 _required_confirmations) public {
        // require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not an admin");
        
        required_confirmations = _required_confirmations;
    }

    
    function confirm(bytes32 transaction_hash, address to_address, uint256 amount) public {
        // require(hasRole(CONFIRMER_ROLE, msg.sender), "Caller is not a confirmer");
        
        if(transactions[transaction_hash].amount != 0) {
            require(transactions[transaction_hash].to_address == to_address, "Transaction address  is different");
            require(transactions[transaction_hash].amount == amount, "Transaction amount is different");
            require(confirmations[msg.sender][transaction_hash] == false, "Transaction has been confirmed before by this address");
            
            transactions[transaction_hash].confirmations = transactions[transaction_hash].confirmations + 1;

        } else {
            transactions[transaction_hash] = Transaction({
                to_address:to_address,
                amount: amount,
                confirmations: 1,
                is_confirmed: false
            });
        }
        confirmations[msg.sender][transaction_hash] = true;

        emit Confirm(transaction_hash, to_address, amount, msg.sender);
        
        if(
            transactions[transaction_hash].confirmations == required_confirmations &&
            transactions[transaction_hash].is_confirmed == false
        ) {
            transactions[transaction_hash].is_confirmed = true;
            token.transfer(to_address, amount);
            emit Transfer(to_address, amount);
        }
        

    }

}