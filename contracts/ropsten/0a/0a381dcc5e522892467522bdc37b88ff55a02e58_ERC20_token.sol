/**
 *Submitted for verification at Etherscan.io on 2021-05-13
*/

pragma solidity >= 0.6.0;

contract ERC20_token {
    
    //mapping addresses of users (keys to integers)
    mapping(address=>uint256) public balances;
    address owner;
    uint256 _totalSupply;
    
    // Voucher creation balances
    constructor() public {
        balances[msg.sender] = 100; //creator
        owner = msg.sender; //address of contract owner in STORAGE
        _totalSupply = 100;
        
    }
    
    //create new tokens
    function mint(uint256 _value) public {
        require(msg.sender == owner); //you can create tokens only if you are the owner
        balances[msg.sender] += _value;
        _totalSupply += _value;
    }
    
    //function to transfer ownership
    function ownershipTransfer(address _to) public {
        require(msg.sender == owner); //only the owner can change ownership
        owner = _to;
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        
        
        //to avoid negative balances
        require(balances[msg.sender]>= _value, "Not enough funds");
        
        //transfer tokens from msg.sender to _to
        //same as python dictionary
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        return true;
    }
    
    
    //ERC20 DEFINITION
    function name() public pure returns (string memory) {
        return "PhDBlockToken";
    }
    
    function symbol() public pure returns (string memory) {
        return "PHD";
    }
    
    function decimals() public pure returns (uint8) {
        return 0;
    }
    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    
    
    //function to access users' balances
    //function getBalance(address _who) public {
    //    return balances[_who];
    //}
    
    
}