/**
 *Submitted for verification at Etherscan.io on 2021-08-15
*/

pragma solidity ^0.6.0;

interface IERC20 {
    
    function totalSupply() external view returns (uint256);
    
    function balanceOf(address account) external view returns (uint256);
   
    function transfer(address recipient, uint256 amount) external returns (bool);
    
    //function allowance(address owner, address spender) external view returns (uint256);
   
    //function approve(address spender, uint256 amount) external returns (bool);
    
    //function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
  
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract MatToken is IERC20 {
    
    string public constant name = "Matellio Inc";
    string public constant symbol = "MAT";
    uint8 public constant decimals = 0;
    
    mapping (address => uint256) balances;
 
    mapping (address => mapping(address=>uint256)) allowed;
    
    uint256 _totalSupply = 2000 wei;
    address admin;
    
    constructor() public {
        balances[msg.sender] = _totalSupply;
        admin = msg.sender;
    }
    
    
    
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address tokenOwner) public view override returns (uint256) {
        return balances[tokenOwner];
    }
    
    function transfer(address receiver, uint256 numTokens) public override returns (bool) {
        require(numTokens<=balances[msg.sender]);
        balances[msg.sender] -= numTokens;
        balances[receiver] += numTokens;
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }
    
    modifier onlyAdmin{
        require(msg.sender==admin, "Only Admin can mint this function");
        _;
    }
    
    function mint(uint256 _qty) public onlyAdmin returns(uint256) {
        _totalSupply += _qty;
        balances[msg.sender] += _qty;
        return _totalSupply;
    }
    
    function burn(uint256 _qty) public onlyAdmin returns(uint256) {
        require(balances[msg.sender] >= _qty);
        _totalSupply -= _qty;
        balances[msg.sender] -= _qty;
        return _totalSupply;
    }
    
    function allowance(address _owner, address _spender) public view returns(uint256 remainings){
        return allowed[_owner][_spender];
    }
    
    function approve(address _spender, uint256 _value) public returns (bool seccess){
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true; 
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        uint256 allowanceX = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowanceX >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        //if(allowance < MAX_UINT256){
            allowed[_from][msg.sender] -= _value;
        //}*/
        emit Transfer(_from, _to, _value);
        return true;
    }
}