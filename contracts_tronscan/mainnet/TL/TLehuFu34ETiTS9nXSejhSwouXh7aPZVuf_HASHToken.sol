//SourceUnit: HashTOken.sol

pragma solidity ^0.5.4;

contract HASHToken {
    string public constant name = "BZS Coin";
    string public constant symbol = "BZS";
    uint8 public constant decimals = 6;

    uint256 _totalSupply;

    address private owner;

    mapping (address => uint256) private balanceMap;

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
        require(sender == owner,"HASH:transfer from the  not owner address");
        require(sender != address(0), "HASH: transfer from the zero address");
        require(recipient != address(0), "HASH: transfer to the zero address");
        require(balanceMap[sender] >= amount, "HASH: transfer amount exceeds balance");
        balanceMap[sender] -= amount;
        balanceMap[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        require(allowanceMap[from][msg.sender] >= amount, "HASH: transfer amount exceeds allowance");
        allowanceMap[from][msg.sender] -= amount;
        _transfer(from, to, amount);
        return true;
    }

    function approve(address _spender, uint256 amount) public returns (bool) {
        require(amount == 0 || allowanceMap[msg.sender][_spender] == 0);
        allowanceMap[msg.sender][_spender] = amount;
        emit Approval(msg.sender, _spender, amount);
        return true;
    }


    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowanceMap[_owner][_spender];
    }

    function _burn(address from, uint256 amount) internal {
        require(balanceMap[from] >= amount, "HASH: burn amount exceeds balance");
        balanceMap[from] -= amount;
        _totalSupply -= amount;
        emit Transfer(from, address(0x0), amount);
    }

    function burn(uint256 amount) public returns (bool) {
        _burn(msg.sender, amount);
        return true;
    }

    function burnFrom(address from, uint256 amount) public returns (bool) {
        require(allowanceMap[from][msg.sender] >= amount, "HASH: burn amount exceeds allowance");
        allowanceMap[from][msg.sender] -= amount;
        _burn(from, amount);
        return true;
    }

    function destroy() public {
        require(msg.sender == owner, "HASH: access denied");
        selfdestruct(msg.sender);
    }
}