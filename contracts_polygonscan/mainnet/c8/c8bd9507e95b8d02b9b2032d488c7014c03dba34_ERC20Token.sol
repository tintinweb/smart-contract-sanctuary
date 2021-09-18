/**
 *Submitted for verification at polygonscan.com on 2021-09-18
*/

pragma solidity >=0.8.0 <= 0.9.0;


contract ERC20Token {
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event TransferFrom(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address from, uint256 amount);
    event Mint(address to, uint256 amount);

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    uint256 public totalSupply;
    string public name;
    string public symbol;
    uint256 public decimals;
    
    address private owner;
    
    constructor (string memory _name, string memory _symbol,uint256 _decimals) {
        name = _name;
        symbol = _symbol;
        owner = msg.sender;
        decimals = _decimals;
        totalSupply = 1000000000000 * 10 ** decimals;
        balanceOf[msg.sender] = totalSupply;
    }
    
    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(balanceOf[msg.sender] - amount >= 0, "ERC20: transfer amount exceeds balance");
        require(msg.sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _transfer(msg.sender, recipient, amount);
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function approve(address spender, uint256 amount) public returns (bool) {
        require(msg.sender != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(balanceOf[msg.sender] - amount >= 0, "ERC20: transfer amount exceeds balance");
        require(sender != address(0), "ERC20: spender is a zero address");
        require(recipient != address(0), "ERC20: recipient is a zero address");
        require(amount <= allowance[sender][msg.sender]);     // Check allowance
        allowance[sender][msg.sender] -= amount;
        _transfer(sender, recipient, amount);
        emit TransferFrom(sender, recipient, amount);
        return true;
    }
    
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0), "ERC20: spender is a zero address");
        allowance[msg.sender][spender] = allowance[msg.sender][spender] + addedValue;
        return true;
    }
    
    function mint(address to, uint256 amount) onlyOwner public returns(bool) {
        require(to != address(0), "ERC20: mint to the zero address");
        require(amount + totalSupply <= 10**26, "TOTAL_SUPPLY_EXCEEDED");
        balanceOf[to] = balanceOf[to] + amount;
        totalSupply += amount;
        emit Mint(to, amount);
        return true;
    }
    
    function _burn(address account, uint256 amount) onlyOwner public  {
        require(account != address(0), "ERC20: burn from the zero address");
        require(totalSupply - amount >= 0, "TOTAL_SUPPLY_LESS_THAN_ZERO");
        balanceOf[account] = balanceOf[account] - amount;
        totalSupply = totalSupply - amount;
        emit Burn(account, amount);
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0), "ERC20: spender is a  zero address");
        require(allowance[msg.sender][spender] - subtractedValue >=0, "amount exceeds allowance");
        allowance[msg.sender][spender] = allowance[msg.sender][spender] - subtractedValue;
        return true;
    }
    
    function _transfer(address _from, address _to, uint _value) internal {
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }
    
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
}