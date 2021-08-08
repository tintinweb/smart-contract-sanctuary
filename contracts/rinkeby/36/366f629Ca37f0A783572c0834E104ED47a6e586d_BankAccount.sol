pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract BankAccount is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    constructor() ERC721("BankAccount", "BANK") payable {}

    event AccountCreated(address owner, uint beneficiary, uint accountNumber);

    event DepositMade(uint beneficiary, uint deposit, uint balance);
    
    event WithdrawalMade(uint beneficiary, uint withdrawal, uint balance);

    struct Account {
        uint beneficiary;
        uint accountNumber;
        uint balance;
    }

    Account[] public accounts;

    mapping (uint => uint) public beneficiaryToAccount;

    modifier onlyOwnerOf(uint _beneficiary) {
        require(ERC721.ownerOf(beneficiaryToAccount[_beneficiary]) == msg.sender, "You are not the owner");
            _;
    }

    function createAccount(uint _beneficiary) public returns (uint) {
        _tokenIds.increment();
        require (beneficiaryToAccount[_beneficiary] == 0, "Account already exists for that beneficiary");
        address _owner = msg.sender;
        _safeMint(_owner, _tokenIds.current());
        accounts.push(Account(_beneficiary, _tokenIds.current(), 0));
        beneficiaryToAccount[_beneficiary] = _tokenIds.current();
        emit AccountCreated(_owner, _beneficiary, _tokenIds.current()); 
        return _tokenIds.current();
    }

    function deposit(uint _beneficiary) public payable {
        require (beneficiaryToAccount[_beneficiary] != 0, "Beneficiary doesn't have an account");
        Account storage targetAccount = accounts[beneficiaryToAccount[_beneficiary] - 1];
        targetAccount.balance += msg.value;
        emit DepositMade(_beneficiary, msg.value, targetAccount.balance);
    }

    function withdraw(uint _beneficiary, uint _amount) public onlyOwnerOf(_beneficiary) {
        Account storage targetAccount = accounts[beneficiaryToAccount[_beneficiary] - 1];
        require(targetAccount.balance >= _amount, "Insufficient funds");
        targetAccount.balance = targetAccount.balance - _amount;
        payable(msg.sender).transfer(_amount);
        emit WithdrawalMade(_beneficiary, _amount, targetAccount.balance);
    }
}