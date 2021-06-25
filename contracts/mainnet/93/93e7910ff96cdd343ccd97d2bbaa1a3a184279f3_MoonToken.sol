/**
 *Submitted for verification at Etherscan.io on 2021-06-25
*/

pragma solidity ^0.5.0;

contract MoonToken {
    string  public name = "BLUE MOON";
    string  public symbol = "MOON";
    uint256 public totalSupply;  
    uint8   public decimals = 18;
	address public owner;

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;

	mapping(address => bool) public hasMinted;

    // --- Math ---
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
    
    constructor() public {
        balances[msg.sender] = 100000000000000000000000000000;  // 100b tokens
        totalSupply = balances[msg.sender];
        owner = msg.sender;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] =sub( balances[msg.sender], _value );
        balances[_to] = add( balances[_to], _value );
        emit Transfer(msg.sender, _to, _value);
        return true;
    }


    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        balances[_from] = sub( balances[_from], _value );
        balances[_to] = add( balances[_to], _value) ;
        allowed[_from][msg.sender] = sub(allowed[_from][msg.sender] , _value );
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    // free tokens for first timer
    function mint(address receiver, uint amount) public {
        require(!hasMinted[receiver], "ONCE IN A BLUE MOON!");
        
        uint256 reward = 10000000000000000000000; // 10000 tokens
        balances[receiver] = add(balances[receiver], reward); //10 tokens
        totalSupply = add(totalSupply, reward);
		hasMinted[receiver] = true;       
    }    
}