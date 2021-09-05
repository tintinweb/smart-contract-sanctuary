/**
 *Submitted for verification at Etherscan.io on 2021-09-05
*/

pragma solidity 0.5.16;

contract myToken {
    address public minter;
    mapping (address => uint) public balances;
    mapping(address => uint) public deposits;
    uint public totalDeposits = 0;
    
    event Sent(address from, address to, uint amount);
    
    constructor() public {
        minter = msg.sender;
    }
    function mint(address receiver, uint amount) public {
        require(msg.sender == minter);
        balances[receiver] += amount;
    }
    function send(address receiver, uint amount) public {
        require(amount <= balances[msg.sender], "Insufficient Balance");
        balances[msg.sender] -= amount;
        balances[receiver] += amount;
        emit Sent(msg.sender, receiver, amount);
    }
    function name() external pure returns (string memory){
        return "AdoboSwap";
    }
    function symbol()  external pure returns (string memory){
        return "ADS";
        
    }
    function decimal() external pure returns (uint8){
        return 18;
    }
        function deposit() public payable{
        deposits[msg.sender] = deposits[msg.sender] + msg.value;
        totalDeposits = totalDeposits + msg.value;
    }
    function withdraw(uint amount) public{
        if(deposits[msg.sender] >= amount){
            msg.sender.transfer (amount);
            
            deposits[msg.sender] = deposits[msg.sender] - amount;
            totalDeposits = totalDeposits - amount;
        }
    }
}