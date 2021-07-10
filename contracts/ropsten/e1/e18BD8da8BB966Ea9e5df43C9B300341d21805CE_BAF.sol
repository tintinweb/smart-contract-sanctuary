/**
 *Submitted for verification at Etherscan.io on 2021-07-10
*/

// transfer from


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC20 {
    
    function totalSupply() external view returns (uint256);
    
    function balanceof(address account) external view returns (uint256);
    
    function transfer(address recepient,uint256 amount) external returns (bool);
    
    function approve(address spender, uint256 amount) external returns (bool);
    
    function allowance(address owner, address spender) external view returns (uint256);
    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    function transferownership(address transferowner) external returns (bool);

    
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
}



library SafeMath

{

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}




contract ERC20 is IERC20 {
    using SafeMath for uint256;
    
    string private _name;
    string private _symbol;
    uint256 private _totalSupply;
     uint8 private _decimals;    
     address private _owner;

     

    mapping (address => uint256) _balances;
    
    mapping(address => mapping (address => uint)) _allowances;
   constructor(string memory tokenname,string memory tokensymol,address owner ){
        _name = tokenname;
        _symbol = tokensymol;
        _decimals = 18;
        _owner = owner;
    }
    
    
    
    function name() public view returns(string memory){
        return _name;
    }
    
    function symbol() public view returns(string memory){
        return _symbol;
    }
    
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }
    
        function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "Error ERC20: mint to the zero address");

       // _beforeTokenTransfer(address(0), account, amount);



        //assigning total _totalSupply
        // assigning amount

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
       // emit Transfer(address(0), account, amount);
    }
    
    function totalSupply() public view virtual override returns(uint256){
        return _totalSupply;
    }
    
    function balanceof(address account) public view virtual override returns(uint256){
        return _balances[account];
    }
    
    function transfer(address recepient,uint256 amount) public override virtual returns(bool) {
        
        _transfer(msg.sender, recepient, amount);
        return true;
    }
    
    function _transfer(address sender,address recipient, uint256 amount) internal virtual  
    {
        //require(recipient != address(0),"Address cannot be empty ");
        //require(balanceof(recipient) >= amount, "Amount In sufficient");
        
        require(sender != address(0), "Error : ERC20: transfer from the zero address");
        require(recipient != address(0), "Error : ERC20: transfer to the zero address");
        
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender,recipient,amount);
        
    }    function transferownership(address transferowner) public override virtual onlyowner()  returns(bool) {
        require(transferowner != address(0), "transfer address should not be zero");
        _transfer(msg.sender,transferowner,_balances[msg.sender]);
        _owner = transferowner;
        return true;
        
    }
    
    
    
    
    //aprove - spender and amount he can spend

        function approve(address spender, uint256 amount) public virtual override returns (bool) {
        require(_balances[msg.sender] >= amount, "donesn't have enough amount in wallet to approve  ");
        _approve(msg.sender, spender, amount);
        return true;
    }
    
    
        function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");



        // don't use below
        // below willl keep on adding the allowance
        // _allowances[owner][spender] = _allowances[owner][spender].add(amount);

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    
        function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    
        function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        
        //spender - to whome 
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "error - ERC20: transfer amount exceeds allowance. you don't have enough alowance"));
        return true;
    }
    
        modifier onlyowner(){
        // modifier whic can be restricted to any functonality to be used only by owner
        require(_owner == msg.sender,"only owner is authorized");
        _;
    }
    
}



contract BAF is ERC20 {
    
    constructor() ERC20("BAF Chain","BAF",msg.sender){
        
       _mint(msg.sender,1000000 * (10 ** uint256(decimals())));
        
    }
    
}