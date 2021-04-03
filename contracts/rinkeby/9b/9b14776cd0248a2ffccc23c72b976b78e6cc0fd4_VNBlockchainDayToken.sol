/**
 *Submitted for verification at Etherscan.io on 2021-04-03
*/

pragma solidity 0.6.12;


contract VNBlockchainDayToken {
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    address owner;
    string public name = "VNBlockchainDayToken";
    string public symbol = "VNB";
    uint8 public decimals = 2;

    uint256 public totalSupply;

    mapping (address=>uint256) public balances;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() public {
        owner = msg.sender;
    }

    function mint(address account, uint256 amount) onlyOwner() external {
        totalSupply = totalSupply + amount;
        balances[account] = balances[account] + amount;
        emit Transfer(address(0), account, amount);
    }

    function transfer(address recipient, uint256 amount) public returns (bool) { 
        require(balances[msg.sender] > amount, "Unsufficient");

        // Update balance
        balances[msg.sender] = balances[msg.sender] - amount;
        balances[recipient] = balances[recipient] + amount;

        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

   
}