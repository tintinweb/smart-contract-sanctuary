//SourceUnit: BZBCoin.sol

pragma solidity ^0.5.4;

/*
 * 代币合约
 */

contract BZBCoin {
    string public constant name = "BZBCOIN";
    string public constant symbol = "BZB";
    uint8 public constant decimals = 6;

    uint256 _totalSupply;
    //管理员账户地址
    address private owner;
    //账户余额映射
    mapping (address => uint256) private balanceMap;
    //授权余额映射
    mapping (address => mapping (address => uint256)) private allowanceMap;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(
        address _owner,
        uint256 initialSupply
    ) public {
        owner = _owner;
        _totalSupply = initialSupply * 10**uint256(decimals);
        balanceMap[owner] = _totalSupply;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balanceMap[_owner];
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "BZB: transfer from the zero address");
        require(recipient != address(0), "BZB: transfer to the zero address");
        require(balanceMap[sender] >= amount, "BZB: transfer amount exceeds balance");
        balanceMap[sender] -= amount;
        balanceMap[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        require(allowanceMap[from][msg.sender] >= amount, "BZB: transfer amount exceeds allowance");
        allowanceMap[from][msg.sender] -= amount;
        _transfer(from, to, amount);
        return true;
    }

    function approve(address _spender, uint256 amount) public returns (bool) {
        allowanceMap[msg.sender][_spender] = amount;
        emit Approval(msg.sender, _spender, amount);
        return true;
    }

    function _approve(address _owner, address _spender, uint256 amount) internal {
        require(_owner != address(0), "BZB: approve from the zero address");
        require(_spender != address(0), "BZB: approve to the zero address");

        allowanceMap[_owner][_spender] = amount;
        emit Approval(_owner, _spender, amount);
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, allowanceMap[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(allowanceMap[msg.sender][spender] >= subtractedValue, "BZB: decreased allowance below zero");
        _approve(msg.sender, spender, allowanceMap[msg.sender][spender] - subtractedValue);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowanceMap[_owner][_spender];
    }

    function _burn(address from, uint256 amount) public {
        require(balanceMap[from] >= amount, "BZB: burn amount exceeds balance");
        balanceMap[from] -= amount;
        _totalSupply -= amount;
        emit Transfer(from, address(0x0), amount);
    }

    function burn(uint256 amount) public returns (bool) {
        _burn(msg.sender, amount);
        return true;
    }

    function burnFrom(address from, uint256 amount) public returns (bool) {
        require(allowanceMap[from][msg.sender] >= amount, "BZB: burn amount exceeds allowance");
        allowanceMap[from][msg.sender] -= amount;
        _burn(from, amount);
        return true;
    }

    function destroy() public {
        require(msg.sender == owner, "BZB: access denied");
        selfdestruct(msg.sender);
    }
}