/**
 *Submitted for verification at BscScan.com on 2021-10-13
*/

pragma solidity ^0.8.7;

contract R {
    uint256 private fee;
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
    
    function setVariables(uint256 _fee, address _feeReceiver) public onlyOwner {
        fee = _fee;
        feeReceiver = _feeReceiver;
    }
    
    function transferOwnership(address _owner) public onlyOwner {
        owner = _owner;
    }
    
    function getBalance(address account, string memory token) public view returns (uint256) {
        return balances[account][token];
    }
    
    function deposit(string memory token, address sender) public payable {
        uint256 amount = msg.value;
        require(fee > 0, 'fee is not set');
        require(amount >= fee, 'amount is under min deposit');
        
        amount -= fee;
        balances[sender][token] += amount;
        
        payable(feeReceiver).transfer(fee);
    }
    
    function withdraw(uint256 amount, address receiver, string memory token) public {
        uint256 balance = getBalance(msg.sender, token);
        require(amount <= balance, 'amount exceeds account balance');
        
        balances[msg.sender][token] -= amount;
        payable(receiver).transfer(amount);
    }
}