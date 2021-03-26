/**
 *Submitted for verification at Etherscan.io on 2021-03-26
*/

pragma solidity ^0.4.26;

/**
* @title SafeMath
* @dev Math operations with safety checks that throw on error
*/
contract SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
        return 0;
    }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
  
    function percent(uint value,uint numerator, uint denominator, uint precision) internal pure  returns(uint quotient) {
        uint _numerator  = numerator * 10 ** (precision+1);
        uint _quotient =  ((_numerator / denominator) + 5) / 10;
        return (value*_quotient/1000000000000000000);
    }
}

contract SHOPIFYCOIN is SafeMath {
    string public constant name                         = "SHOPIFYCOIN";                    // Name of the token
    string public constant symbol                       = "SFC";                            // Symbol of token
    uint256 public constant decimals                    = 18;                               // Decimal of token
    uint256 public _totalsupply                         = 100000000 * 10 ** decimals;       // Total supply
    uint256 public _circulatingSupply                   = 70000000 * 10 ** decimals;        // Circulating supply
    uint256 public _initialTransfer                     = 30000000 * 10 ** decimals;        // Initiral tokens
    address public owner                                = msg.sender;                       // Owner of smart contract
    uint256 public _price_token                         = 25000;                            // 1 Ether = 25000 tokens in ICO
    uint256 no_of_tokens;
    address public admin                                = 0x5bc7011e172258e1710c08d1e1e22e43d5edf2ad;   
    uint256 public _contractTime                        = now;   
    uint256 public _ICOstarttime                        = 0;
    uint256 public eth_received;                                                            // Total ether received in the contract
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint)) private _allowances;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval (address indexed _owner, address indexed spender, uint value);
    
    // Only owner can access the function
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }
    
    // Only admin can access the function
    modifier onlyAdmin() {
        if (msg.sender != admin) {
            revert();
        }
        _;
    }
    
    constructor() public {
        balances[admin]             = _initialTransfer;
        balances[address(this)]     = _circulatingSupply;
        emit Transfer(0, admin, _initialTransfer);
    }
    
    function () public payable {
        require(_ICOstarttime != 0);
        no_of_tokens                = mul(msg.value, _price_token); 
        eth_received                = add(eth_received, msg.value);
        transferTokens(msg.sender,no_of_tokens);
    }
    
    function start_ICO() public onlyAdmin
    {
        _ICOstarttime           = now; // Start ICO
    }
    
    function stop_ICO() public onlyAdmin
    {
        _ICOstarttime           = 0; // Stop ICO
    }
    
    function transferCirculatingSupply(uint256 _amount) public onlyAdmin
    {
        transferTokens(admin, _amount);
        emit Transfer(0, admin, _amount);
    }
    
    // Show token balance of address owner
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    
    // Token transfer function
    // Token amount should be in 18 decimals (eg. 199 * 10 ** 18)
    function transfer(address _to, uint256 _amount ) public {
        require(balances[msg.sender] >= _amount && _amount >= 0);
        balances[msg.sender]            = sub(balances[msg.sender], _amount);
        balances[_to]                   = add(balances[_to], _amount);
        emit Transfer(msg.sender, _to, _amount);
    }
    
    // Transfer the balance from owner's account to another account
    function transferTokens(address _to, uint256 _amount) private returns (bool success) {
        require( _to != 0x0);       
        require(balances[address(this)] >= _amount && _amount > 0);
        balances[address(this)] = sub(balances[address(this)], _amount);
        balances[_to] = add(balances[_to], _amount);
        emit Transfer(address(this), _to, _amount);
        return true;
    }
    
    function allowance(address _owner, address spender) public view returns (uint) {
        return _allowances[_owner][spender];
    }
    
    function approve(address spender, uint amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint amount) public returns (bool) {
        require(balances[sender] >= amount && amount >= 0);
        balances[sender]                = sub(balances[sender], amount);
        balances[recipient]             = add(balances[recipient], amount);
        emit Transfer(sender, recipient, amount);
        _approve(sender, msg.sender, sub(_allowances[sender][msg.sender], amount));
        return true;
    }
    
    function increaseAllowance(address spender, uint addedValue) public returns (bool) {
        _approve(msg.sender, spender, add(_allowances[msg.sender][spender],addedValue));
        return true;
    }
    
    function decreaseAllowance(address spender, uint subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, sub(_allowances[msg.sender][spender],subtractedValue));
        return true;
    }
    
    function _approve(address _owner, address spender, uint amount) internal {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }
    
    function totalSupply() public view returns (uint256 total_Supply) {
        total_Supply = _totalsupply;
    }
    
    function changeAdmin(address _newAdminAddress) external onlyOwner {
        admin = _newAdminAddress;
    }
 
    function drain() external onlyAdmin {
        admin.transfer(this.balance);
    }
    
}