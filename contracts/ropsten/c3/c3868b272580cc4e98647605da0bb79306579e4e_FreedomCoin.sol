pragma solidity ^0.4.24;

contract Ownable {
    address public owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    
    constructor() public {
        owner = msg.sender;
    }
    
    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

}

contract FreedomCoin is Ownable {

    string public constant symbol = "FDC";
    string public constant name = "Freedom Coin";
    uint8 public constant decimals = 0;
    uint256 public totalSupply = 100000000;
    uint256 public rate = 5000000000000000000 wei;
    
    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    constructor() public{
      balances[owner] = totalSupply;
    }
    
    function () public payable {
        create(msg.sender);
    }

    function create(address beneficiary) public payable {
        require(beneficiary != address(0));

        uint256 amount = msg.value;
        
        uint256 token = (amount/rate);
        
        require(token <= balances[owner]);
        
        if(amount > 0){
            balances[beneficiary] += token;
            balances[owner] -= token;
        }
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }
    
    function balanceMaxSupply() public constant returns (uint256 balance) {
        return balances[owner];
    }
    
    function balanceEth(address _owner) public constant returns (uint256 balance) {
        return _owner.balance;
    }
    
    function collect(uint256 amount) onlyOwner public{
        msg.sender.transfer(amount);
    }

    function transfer(address _to, uint256 _amount) public returns (bool success) {
        require(_to != address(0));
        if (balances[msg.sender] >= _amount && _amount > 0) {
            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            emit Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        balances[newOwner] = balances[owner];
        balances[owner] = 0;
        owner = newOwner;
        emit OwnershipTransferred(owner, newOwner);
    }

}