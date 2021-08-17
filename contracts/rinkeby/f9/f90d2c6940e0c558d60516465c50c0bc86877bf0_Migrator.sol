/**
 *Submitted for verification at Etherscan.io on 2021-08-17
*/

pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/access/AccessControl.sol";

interface IERC20 {


    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);


    function transfer(address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function mint(address account, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

}

struct Transaction {
    address from_address;
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
        
    event Confirm(bytes32 transaction_hash, address form_address, uint256 amount, address confirmer);
    event Mint(address form_address, uint256 amount);

    
    constructor(IERC20 _token, uint256 _required_confirmations) {
        token = _token;
        required_confirmations = _required_confirmations;
    }

    
    function confirm(bytes32 transaction_hash, address from_address, uint256 amount) public {
        // require(hasRole(CONFIRMER_ROLE, msg.sender), "Caller is not a confirmer");
        
        if(transactions[transaction_hash].amount != 0) {
            require(transactions[transaction_hash].from_address == from_address, "Transaction address  is different");
            require(transactions[transaction_hash].amount == amount, "Transaction amount is different");
            require(confirmations[msg.sender][transaction_hash] == false, "Transaction has been confirmed before by this address");
            
            transactions[transaction_hash].confirmations = transactions[transaction_hash].confirmations + 1;

        } else {
            transactions[transaction_hash] = Transaction({
                from_address:from_address,
                amount: amount,
                confirmations: 1,
                is_confirmed: false
            });
        }
        confirmations[msg.sender][transaction_hash] = true;

        emit Confirm(transaction_hash, from_address, amount, msg.sender);
        
        if(
            transactions[transaction_hash].confirmations == required_confirmations &&
            transactions[transaction_hash].is_confirmed == false
        ) {
            transactions[transaction_hash].is_confirmed = true;
            token.mint(from_address, amount);
            emit Mint(from_address, amount);
        }
        

    }

}