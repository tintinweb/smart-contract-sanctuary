/**
 *Submitted for verification at Etherscan.io on 2021-06-14
*/

pragma solidity ^0.4.26;
  
      contract Token {
      
        string  internal _name = "Test Token";
        string  internal _symbol = "TTN";
        uint8   internal _decimals = 8;
        uint256 internal _totalSupply = 1100 * (10 ** uint256(_decimals));
        
        bool public isFreeze = false;
        
  
        address public owner = msg.sender;
        
        mapping (address => uint256) balances;
        mapping (address => mapping (address => uint256)) allowed;
      
        constructor() public {
          balances[msg.sender] = _totalSupply;
          emit Transfer(address (0),msg.sender, _totalSupply);
        }
        function name() public view returns (string memory) {
          return _name;
        }
        
        function symbol() public constant returns (string memory) {
          return _symbol;
        }
        
        function decimals() public constant returns (uint8 decimal) {
          return _decimals;
        }
        
        function totalSupply() public constant returns (uint256 total_Supply) {
          return _totalSupply;
        }
      
        function transfer(address _to, uint256 _value) public returns (bool success) {
          require(isFreeze == false,'The token transfer is frozen. Please contract with the token owner.');
          require(balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]);
          require(_to != 0x0);
          balances[msg.sender] -= _value;
          balances[_to] += _value;
          emit Transfer(msg.sender, _to, _value);
          return true;
        }
      
        function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
          require(isFreeze == false,'The token transfer is frozen. Please contract with the token owner.');
          require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
          balances[_to] += _value;
          balances[_from] -= _value;
          allowed[_from][msg.sender] -= _value;
          emit Transfer(_from, _to, _value);
          return true;
        }
  
        function balanceOf(address _owner) public constant returns (uint256 balance) {
          return balances[_owner];
        }
  
        function approve(address _spender, uint256 _value) public returns (bool success) {
          allowed[msg.sender][_spender] = _value;
          emit Approval(msg.sender, _spender, _value);
          return true;
        }
      
        function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
          return allowed[_owner][_spender];
        }
        
        function changeOwner(address _newOwner) public returns (bool success) {
            require(msg.sender==owner,'Only owner can do it.');
            owner = _newOwner;
            return true;
            
        }
        function _add(uint256 a, uint256 b) internal pure returns (uint256) {
          uint256 c = a + b;
          require(c >= a, "SafeMath: addition overflow");
          return c;
        }
        function burn(uint256 _value) public returns (bool success) {
          require(msg.sender != address(0), "ERC20: burn from the zero address");
          require(balances[msg.sender] >= _value);
          require(_value>0,"0 amount can't burn");
    
          _totalSupply = _totalSupply-_value;
          balances[msg.sender] = balances[msg.sender]-_value;
          emit Transfer(msg.sender, address (0), _value);
          return true;
        }
        function mint(uint256 _value) public returns (bool success){
          require(msg.sender==owner,'Only owner can do it.');
          _mint(_value);
          return true;
        }
        
        
        function _mint(uint256 _value) internal {
            _totalSupply = _add(_totalSupply,_value);
            balances[msg.sender] = _add(balances[msg.sender],_value);
            emit Transfer(address (0), msg.sender, _value);
        }
        function freeze() public returns (bool success) {
          require(msg.sender==owner && isFreeze == false);
          isFreeze = true;
          emit Freeze ();
          return true;
          
        }
        function unfreeze() public returns (bool success) {
            require(msg.sender==owner && isFreeze == true);
            isFreeze = false;
            emit Unfreeze ();
            return true;
            
        }
        
      event Transfer(address indexed _from, address indexed _to, uint256 _value);
      event Approval(address indexed _owner, address indexed _spender, uint256 _value);
      
        event Freeze ();
        event Unfreeze ();
        }