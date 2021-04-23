/**
 *Submitted for verification at Etherscan.io on 2021-04-23
*/

pragma solidity 0.8.0;


contract Coin {
    
    // The keyword "public" makes those variables
    // easily readable from outside.
    address public minter;
    mapping (address => uint) public balances;
    mapping (address => mapping(address => uint)) public allowance;
    mapping (address => bool) public Wallets;
    string public name = "Exclusive Token";
    string public symbol = "TTT";
    uint public decimals = 1;
    uint public initalSupply = 1;
    uint public newlyMinted;
    uint public totalSupply_;
    uint public extra = 2;
    

    
    
    // Events allow light clients to react to
    // changes efficiently.
    event Sent(address from, address to, uint amount);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    // This is the constructor whose code is
    // run only when the contract is created.
    
    constructor(){
        minter = msg.sender;
        balances[msg.sender] = initalSupply;
        totalSupply_ = initalSupply;
    }
    
    function setWallet(address _wallet) public {
        Wallets[_wallet]=true;
    }
    
    function contains(address _wallet) private view returns (bool){
        return Wallets[_wallet];
    }
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
    
    function mint(address receiver, uint amount) public {
        require(msg.sender == minter);
        require(amount < 1e60);
        balances[receiver] += amount;
        newlyMinted += amount;
        totalSupply_ += amount;
    }
    
    function send(address receiver, uint amount) public {
        require(amount <= balances[msg.sender], "Insufficient balance.");
        // check if receiver is apart of addresses in array
        require(contains(receiver) == false);
        uint augment_amount = amount + extra; 
        balances[msg.sender] -= amount;
        balances[receiver] += augment_amount;
        // if not push their address to array
        setWallet(receiver);
        emit Sent(msg.sender, receiver, augment_amount);
    }

    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;
    }
    
    function appove(address spender, uint value) public returns(bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
}