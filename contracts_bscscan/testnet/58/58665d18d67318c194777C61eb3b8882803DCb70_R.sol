/**
 *Submitted for verification at BscScan.com on 2021-10-11
*/

pragma solidity ^0.8.7;

contract R {
    uint256 private fee;
    uint256 private minDeposit;
    address private feeReceiver; 
    address private owner;
    mapping (address => mapping (string => uint256)) private balances;
    
    constructor () {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(owner == msg.sender, 'caller is not the owner');
        _;
    }
    
    function setVariables(uint256 _fee, uint256 _minDeposit, address _feeReceiver) public onlyOwner {
        fee = _fee;
        minDeposit = _minDeposit;
        feeReceiver = _feeReceiver;
    }
    
    function transferOwnership(address _owner) public onlyOwner {
        owner = _owner;
    }
    
    function getBalance(address account, string memory token) public view returns (uint256) {
        return balances[account][token];
    }
    
    function deposit(string memory token) public payable {
        uint256 amount = msg.value;
        require(minDeposit > 0, 'minimum deposit not set');
        require(amount >= minDeposit, 'amount is under min deposit');
        
        uint256 feeAmount = amount / 100000 * fee;
        amount -= feeAmount;
        balances[msg.sender][token] += amount;
        
        payable(feeReceiver).transfer(feeAmount);
    }
    
    function withdraw(uint256 amount, address receiver, string memory token) public {
        uint256 balance = getBalance(msg.sender, token);
        require(amount <= balance, 'amount exceeds account balance');
        
        balances[msg.sender][token] -= amount;
        payable(receiver).transfer(amount);
    }
}