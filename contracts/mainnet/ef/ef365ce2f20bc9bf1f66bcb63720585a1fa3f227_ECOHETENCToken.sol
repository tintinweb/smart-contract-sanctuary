/**
 *Submitted for verification at Etherscan.io on 2021-02-10
*/

pragma solidity ^0.5.1;

library SafeMath{
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}




contract ECOHETENCToken{
    
    using SafeMath for uint256;
    mapping (address => uint256) public balanceOf;
    mapping (address => bool) private transferable;
    mapping(address => mapping (address => uint256)) allowed;
    mapping(address => bool) private admin;
    
    uint256 private _totalSupply=1100000000000000000000000000;
    string private _name= "ECO HETENC Token";
    string private _symbol= "HETENC";
    uint256 private _decimals = 18;
    bool internal _lockall = false;
    
    constructor () public {
	admin[address(0xf7F84640861Fe95c22Ede9c62f77CF3bC0967f86)] = true;
    balanceOf[address(0xf7F84640861Fe95c22Ede9c62f77CF3bC0967f86)] = _totalSupply;
        }

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

        
    function name() public view returns (string memory) {
        return _name;
    }
    
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function decimals() public view returns (uint256) {
        return _decimals;
    }
    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    function _transfer(address _from, address _to, uint256 _value) internal {
        
        require(_from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");
        require(balanceOf[_from]>=_value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        require(transfercheck(_from) == true);
        require(_lockall == false);
        balanceOf[_from] = balanceOf[_from].sub(_value,"ERC20: transfer amount exceeds balance");
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);

    }
    
    
    function transfer(address to, uint256 value) public {
        _transfer(msg.sender, to, value);
    }
    
    function transferFrom(address _from, uint256 amount) public {
         
       require(allowed[_from][msg.sender]>=amount);
       allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(amount);
       _transfer(_from,msg.sender,amount);
    }
    
    function transfercheck(address check) internal view returns(bool) {
        if (transferable[check]==false){
            return true;
        }
        return false;
    }
    
    function AllowenceCheck(address spender, address approver) public view returns (uint256){
        return allowed[approver][spender];
    }
    
    
    function approve(address spender, uint256 _value) public{
        require(balanceOf[msg.sender]>=_value);
        allowed[msg.sender][spender] = _value;
        emit Approval(msg.sender, spender, _value);
        
    }
    
    function increaseAllowence(address spender, uint256 _value) public{
        require(balanceOf[msg.sender]>=_value);
        allowed[msg.sender][spender] = allowed[msg.sender][spender].add(_value);
        emit Approval(msg.sender, spender, _value);
    }
    
    function decreaseAllowence(address spender, uint256 _value) public{
        require(balanceOf[msg.sender]>=_value);
        allowed[msg.sender][spender] = allowed[msg.sender][spender].sub(_value);
        emit Approval(msg.sender, spender, -_value);
    }

    function lock(address lockee) public {
        require(admin[msg.sender]==true);
        transferable[lockee] = true;
    }
    
    function unlock(address unlockee) public {
        require(admin[msg.sender]==true);
        transferable[unlockee] = false;
    }
    
    function lockcheck(address checkee) public view returns (bool){
        return transferable[checkee];
    }
    
    
    function _burn(address account, uint256 value) private {
        require(admin[account]==true);
        require(admin[msg.sender]==true);
        require(balanceOf[account]>=value);
        require(_totalSupply>=value);
        balanceOf[account] =balanceOf[account].sub(value);
        _totalSupply = _totalSupply.sub(value);
    }
    
    
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    function addadmin(address account) public{
        require(admin[msg.sender]==true);
        admin[account]=true;
    }

    function deleteadmin(address account) public{
        require(admin[msg.sender]==true);
        admin[account]=false;
    }

    function admincheck(address account) public view returns (bool){
        return admin[account];
    }
    
    function lockall(bool lockall) public {
        require(admin[msg.sender]==true);
        _lockall = lockall;
    }
    
    function lockallcheck() public view returns (bool){
        return _lockall;
    }
    
    
}