/**
 *Submitted for verification at Etherscan.io on 2021-07-14
*/

pragma solidity >= 0.6.0;

contract BridgedToken {
    
    mapping(address=>uint256) public balances;
    address owner;
    uint256 _totalSupply;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
    function name() public pure returns (string memory) {
        return "Bridged Wonderful Token";
    }
    
    function symbol() public pure returns (string memory) {
        return "BWOT";
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
    
    constructor() {
        //balances[msg.sender] = 100;
        //_totalSupply = 100;
        owner = msg.sender;
    }

    
    function mint(uint256 _value, address _user) public {
        require(msg.sender == owner);
        balances[_user] += _value;
        _totalSupply += _value;
    }
    
    function transfer(address _to, uint256 _value) public returns (bool) {
        
        require(balances[msg.sender] >= _value, "Not enough funds");
        // transfer tokens from msg.sender to _to
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    
}