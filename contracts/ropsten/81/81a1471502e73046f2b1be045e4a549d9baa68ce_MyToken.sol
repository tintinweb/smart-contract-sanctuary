/**
 *Submitted for verification at Etherscan.io on 2021-11-14
*/

/// capped token.

pragma solidity 0.8.0;

interface IERC20 {
    function transfer(address _to, uint256 _amount) external returns(bool);
    function approve(address _spender, uint256 _amount) external returns(bool);
    function transferFrom(address _owner, address _recipient, uint256 _amount) external returns(bool);
    function allowance(address _owner, address _spender) external view returns(uint256);
    function balanceOf(address _account) external view returns(uint256);
    /*function name() external view returns(uint256);
    function symbol() external view returns(uint256);
    function totalSupply() external view returns(uint256);
    function decimals() external view returns(uint256); */
    event Transfer(address from, address to, uint256 amount);
    event Approval(address from, address spender, uint256 amount);
}
// current functionalities: 
// capped, timeBound, buyable, returnable
contract MyToken is IERC20{
    
    address public owner;
    string public constant name = "MYToken";
    string public constant symbol = "MTK";
    uint256 public constant decimals = 18;
    uint256 public totalSupply;
    
    // capped token + timeBound
    uint256 public cap;
    mapping(address => uint256) private timeLimit;
    // price per token
    uint256 public price;
    
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    // add address to manage price
    mapping(address => mapping(address => bool)) private delegatedAddresses;
    
    modifier onlyOwner(){
        require(msg.sender == owner, "onlyOwner can call");
        _;
    }
    
    constructor() public {
        owner = msg.sender;
        //totalSupply = 100 * (10 ** decimals);
        //_balances[owner] = totalSupply;
        _mint(msg.sender,100 * (10 ** decimals));
        //cap = totalSupply * 2;
        
        price = 1 ether;
        
    }
    
    // start
    function balanceOf(address _account) external override view returns(uint256){
        return _balances[_account];
    }
    function transfer(address _to, uint256 _amount) external override returns(bool){
        _transfer(msg.sender,_to, _amount);
    }
    function approve(address _spender, uint256 _amount) external override returns(bool){
        require(_balances[msg.sender] >= _amount, "approve: failed");
        _allowances[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }
    
    function transferFrom(address _owner, address _recipient, uint256 _amount) external override returns(bool){
        uint256 currentAllowance = _allowances[_owner][msg.sender];
        require(currentAllowance >= _amount, "transferFrom: failed");
        
        //decrease allowance
        _allowances[_owner][msg.sender] -= _amount;

        _transfer(_owner, _recipient, _amount);
        
        return true;
    }
    function allowance(address _owner, address _spender) external override view returns(uint256){
        return _allowances[_owner][_spender];
    }
    
    function _mint(address to, uint256 _amount) public onlyOwner returns(bool){
        //require(totalSupply + _amount <= cap, "mint: failed"); // 
        _balances[to] += _amount;
        totalSupply += _amount;
        return true;
    }
    function _burn(uint256 _amount) public returns(bool){
        require(_balances[msg.sender] >= _amount, "burn: failed"); // 
        _balances[msg.sender] -= _amount;
        totalSupply -= _amount;
        return true;
    }
    
    function _transfer(address _from, address _to, uint256 _amount) internal returns(bool){
        require(_from != address(0) && _to != address(0));
        require(_balances[_from] >= _amount, "transfer: failed");
        _balances[_from] -= _amount;
        _balances[_to] += _amount;
        emit Transfer(_from, _to, _amount);
        return true;
    }
    
    // timeBound account with timestamp
    function setTimeLimit(address account, uint256 timestamp) public returns(bool){
        timeLimit[account] = timestamp;
        return true;
    }
    
    function buyToken() public payable returns(bool){
        require(msg.value > 0 ether);
        // should be EOA
        require(msg.sender == tx.origin,"only EOA");
        uint256 units = 1 ether / price; // token units / price
        uint256 wei_units = msg.value * units;
        require(_balances[owner] >= wei_units);
        _transfer(owner, msg.sender, wei_units);
        return true;
    }
    function setPrice(uint256 _newPrice) external returns(bool){
        require(msg.sender == owner || delegatedAddresses[owner][msg.sender], "onlyOwner or delegatedAddresses can call");
        price = _newPrice;
        return true;
    }
    function setOwner(address _newOwner) external onlyOwner returns(bool){
        owner = _newOwner;
        return true;
    }
    function refund(uint256 _amount) public {
        require(_balances[msg.sender] >= _amount, "refund: Insufficient balance to refund");
        //units = 1 ether / price 
        //total = units * msg.value
        uint256 units =  _amount / 1 ether;
        uint256 total = units * price;
        require(address(this).balance >= total,"contract not have balance for refund");
        _burn(_amount);
        payable(msg.sender).transfer(total);
    }
    
    function delegateAddressForPricing(address _account) external onlyOwner returns(bool){
        delegatedAddresses[owner][_account] = true;
        return true;
    }
    
    fallback() external payable {
        buyToken();
    }
    
 }