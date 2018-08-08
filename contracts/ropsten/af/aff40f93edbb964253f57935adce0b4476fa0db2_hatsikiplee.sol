pragma solidity ^0.4.20;


contract hatsikiplee {
    string public constant name = "Hatsikidee";
    string public constant symbol = "Hatsi";
    uint8 public constant decimals = 1; 
    uint256 public totalSupply = 0;
    address public owner = 0x5372260584003e8Ae3a24E9dF09fa96037a04c2b;
    
    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint tokens);
    
    function() public payable {
        uint256 hatsi = msg.value * 100000 / 0.1 ether;
        this.tokensDrukker(msg.sender, hatsi);
    } 
    
    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor(uint256 initialSupply) public {
        tokensDrukker(msg.sender, initialSupply);
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);           // Check if the sender has enough
        require(balanceOf[_to] + _value >= balanceOf[_to]); // Check for overflows
        balanceOf[msg.sender] -= _value;                    // Subtract from the sender
        balanceOf[_to] += _value; // Add the same to the recipient
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function tokensDrukker(address _to, uint256 _value) public returns (bool success) {
        require(msg.sender == owner || msg.sender == address(this));
        balanceOf[_to] += _value;
        emit Transfer(0x0, _to, _value);
        totalSupply += _value;
        return true;
    }
}