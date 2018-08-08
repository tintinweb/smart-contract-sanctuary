pragma solidity ^0.4.0;

// *NOT* GOO, just test ERC20 so i can verify EtherDelta works before launch.

interface ERC20 {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Goo is ERC20 {
    
    string public constant name  = "ProofOfDev";
    string public constant symbol = "DevToken";
    uint8 public constant decimals = 0;
    uint256 private roughSupply;
    
    // Balances for each player
    mapping(address => uint256) private gooBalance;
    mapping(address => uint256) private lastGooSaveTime;
    mapping(address => mapping(address => uint256)) private allowed;
    
    // Constructor
    function Goo() public payable {
        roughSupply = 1;
        gooBalance[msg.sender] = 1;
         lastGooSaveTime[msg.sender] = block.timestamp;
    }
    
    function totalSupply() public constant returns(uint256) {
        return roughSupply; // Stored goo (rough supply as it ignores earned/unclaimed goo)
    }
    
    function balanceOf(address player) public constant returns(uint256) {
        return gooBalance[player] + balanceOfUnclaimedGoo(player);
    }
    
    function balanceOfUnclaimedGoo(address player) internal constant returns (uint256) {
        uint256 lastSave = lastGooSaveTime[player];
        if (lastSave > 0 && lastSave < block.timestamp) {
            return (1000 * (block.timestamp - lastSave)) / 100;
        }
        return 0;
    }
    
    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(amount <= gooBalance[msg.sender]);
        
        gooBalance[msg.sender] -= amount;
        gooBalance[recipient] += amount;
        
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function transferFrom(address player, address recipient, uint256 amount) public returns (bool) {
        require(amount <= allowed[player][msg.sender] && amount <= gooBalance[player]);
        
        gooBalance[player] -= amount;
        gooBalance[recipient] += amount;
        allowed[player][msg.sender] -= amount;
        
        emit Transfer(player, recipient, amount);
        return true;
    }
    
    function approve(address approvee, uint256 amount) public returns (bool){
        allowed[msg.sender][approvee] = amount;
        emit Approval(msg.sender, approvee, amount);
        return true;
    }
    
    function allowance(address player, address approvee) public constant returns(uint256){
        return allowed[player][approvee];
    }
    
}