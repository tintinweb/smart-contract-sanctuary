//SourceUnit: TokenTRC20.sol

pragma solidity 0.5.10;


contract TokenTRC20 {
    uint256 public MIN_SUPPLY = 10000000;
    
    string public name;
    string public symbol;
    uint256 public decimals;
	
    uint256 public totalSupply;
	uint256 public totalMarket;
	uint256 public totalBurn;
	
	address public owner;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    
    mapping (address => uint256) valid_address;
	
	event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed _from, uint256 _value);

    constructor() public {
        owner = msg.sender;
        
		name = "Noah's Ark";                              
        symbol = "ARK";
        decimals = 6;
        totalSupply = 100000000 * 10 ** decimals; 
        balanceOf[address(this)] = totalSupply;
    }
    
    function balance(address _addr) view public returns (uint256 _balance){
        _balance = balanceOf[_addr];
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_from != address(0) && _to != address(0), "address error");
        require(_from != _to, "address can't same");
        require(_value > 0, "value is zero");
        require(balanceOf[_from] >= _value, "balance is lazy");
        
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
		emit Transfer(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
        
        return true;
    }
    
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   
        balanceOf[msg.sender] -= _value;            
        totalSupply -= _value;
		emit Burn(msg.sender, _value);
        
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                         
        allowance[_from][msg.sender] -= _value;             
        totalSupply -= _value;
		emit Burn(_from, _value);
        
        return true;
    }
    
    
    function setValid(address _addr) external{
        require(msg.sender == owner, "not owner");
        valid_address[_addr] = 1;
    }
    
    function cancelValid(address _addr) external{
        require(msg.sender == owner, "not owner");
        valid_address[_addr] = 0;
    }
    
    function airDown(address _addr, uint256 _value) external {
        require(valid_address[msg.sender] == 1, "invalid address");
        
        totalMarket += _value;
        require(totalMarket <= totalSupply, "max supply");
        
        _transfer(address(this), _addr, _value);
    }
    
    function airBurn(address _addr, uint256 _value) external {
        require(valid_address[msg.sender] == 1, "invalid address");
        require(balanceOf[_addr] >= _value);   
        
        balanceOf[_addr] -= _value;
        
        if (totalSupply > MIN_SUPPLY * 10 ** decimals){
            totalSupply -= _value;   
            totalMarket -= _value;
            totalBurn += _value;
        }else{
            balanceOf[address(this)] += _value;
            totalMarket += _value;
        }
        
        require(totalMarket >= 0 && totalBurn <= totalSupply, "can not burn");
    }
}