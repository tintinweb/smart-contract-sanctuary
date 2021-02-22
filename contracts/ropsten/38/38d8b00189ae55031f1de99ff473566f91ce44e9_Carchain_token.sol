pragma solidity ^0.5.14;

//import "./IERC20.sol";
import "./safeMath.sol";

contract Carchain_token  {
    
    using SafeMath for uint256;
    
    event MintToken(address indexe,uint);
    event Transfer(address indexed _from,address indexed _to,uint _amount);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Burn(address,uint);
    
    string constant Name="CarchainNetworkCurrency";
    string constant Symbol="CarNC2";
    uint constant Decimals=6;
    uint constant initialSuply=1000000000;
    uint TotalSupply= initialSuply*10**Decimals;
    address ownerOfTotalSupply;
    
    constructor(address _ownerOfTotalSupply)public{
        ownerOfTotalSupply = _ownerOfTotalSupply;
        balanceOf[_ownerOfTotalSupply] = TotalSupply;
    }
    
    mapping(address=>uint)balanceOf;
    mapping(address=>mapping(address=>uint))Allowed;
    
    function balance(address _owner)public view returns(uint){
        return(balanceOf[_owner]);
    }
    
    function totalSupply() public view returns(uint256) {
        return TotalSupply;
    }
    
    function name()public pure returns(string memory){
        return Name;
    }
    
    function symbol()public pure returns(string memory){
        return Symbol;
    }
    
    function decimals()public pure returns(uint){
        return Decimals;
    }
    
     function _transfer(address _sender, address _recipient, uint _amount) internal  {
        require(_sender != address(0), "ERC20: transfer from the zero address");
        require(_recipient != address(0), "ERC20: transfer to the zero address");

        balanceOf[_sender] = balanceOf[_sender].sub(_amount, "ERC20: transfer amount exceeds balance");
        balanceOf[_recipient] = balanceOf[_recipient].add(_amount);
        emit Transfer(_sender, _recipient, _amount);
    }
    
    function transfer(address _recipient,uint _amount)public returns(bool success){
       _transfer(msg.sender, _recipient, _amount);
        return true;
    }
    
     function _approve(address _owner, address _spender, uint256 _amount) internal {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");

        Allowed[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }
    
    function approve(address _spender,uint _amount)public returns(bool success){
        _approve(msg.sender, _spender, _amount);
        return true;
    }
   
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return Allowed[tokenOwner][spender];
    }

    function increaseAllowance(address _spender, uint256 _addedValue) public  returns (bool success) {
        _approve(msg.sender, _spender, Allowed[msg.sender][_spender].add(_addedValue));
        return true;
    }
    
    function decreaseAllowance(address _spender, uint256 _subtractedValue) public  returns (bool success) {
        _approve(msg.sender, _spender, Allowed[msg.sender][_spender].sub(_subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    
    function transferFrom(address _sender,address _recipient,uint _amount)public returns(bool){
        _transfer(_sender, _recipient, _amount);
        _approve(_sender, msg.sender, Allowed[_sender][msg.sender].sub(_amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
        
   
}