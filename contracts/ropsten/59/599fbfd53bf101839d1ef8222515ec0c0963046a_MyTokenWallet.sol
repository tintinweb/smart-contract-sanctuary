pragma solidity ^0.4.24;
contract TokenFace {
    function decimals() public view returns(uint);
    function name() public view returns(string);
    function totalSupply() public view returns (uint256);
    function balanceOf(address _who) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function allowance(address _owner, address _spender) public view returns (uint256);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    function approve(address _spender, uint256 _value) public returns (bool);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
contract MyTokenWallet {
    address public admin;
    mapping(address => bool) accepted;
    event AdminChanged(address indexed _lastAdmin, address indexed _newAdmin);
    event Deposit(address indexed _token, address indexed _from, uint256 _amount);
    event Withdraw(address indexed _token, address indexed _to, uint256 _amount);
    event TokenAdded(address indexed _token, string _name);
    event TokenRemoved(address indexed _token, string _name);
    constructor () public {
        admin = msg.sender;
        emit AdminChanged(address(0), msg.sender);
    }
    function changeAdmin(address addr) public returns(bool) {
        require(addr != address(0) && addr != address(this) && msg.sender == admin);
        admin = addr;
        emit AdminChanged(msg.sender, addr);
        return true;
    }
    function addToken(address tokenAddr) public returns(bool) {
        require(tokenAddr != address(0) && msg.sender == admin);
        require(!accepted[tokenAddr]);
        accepted[tokenAddr] = true;
        emit TokenAdded(tokenAddr, TokenFace(tokenAddr).name());
        return true;
    }
    function removeToken(address tokenAddr) public returns(bool) {
        require(msg.sender == admin);
        require(accepted[tokenAddr]);
        TokenFace token = TokenFace(tokenAddr);
        uint256 value = token.balanceOf(address(this));
        if (value > 0) {
            if (!token.transfer(tx.origin, value)) {
                revert();
            } else {
                emit Withdraw(tokenAddr, tx.origin, value);
            }
        }
        accepted[tokenAddr] = false;
        emit TokenRemoved(tokenAddr, token.name());
        return true;
    }
    function acceptToken(address tokenAddr) public view returns(bool) {
        return accepted[tokenAddr];
    }
    function () public payable {
        require(msg.data.length == 0 && msg.value >= (1 * 10 ** 9));
        emit Deposit(address(0), msg.sender, msg.value);
    }
    function deposit(address tokenAddr) public returns(bool) {
        require(accepted[tokenAddr]);
        TokenFace token = TokenFace(tokenAddr);
        uint256 amount = token.allowance(msg.sender, address(this));
        require(amount >= (1 * 10 ** token.decimals()) && amount <= token.balanceOf(msg.sender));
        require(token.transferFrom(msg.sender, address(this), amount));
        emit Deposit(tokenAddr, msg.sender, amount);
        return true;
    }
    function withdraw(address tokenAddr, address to, uint256 value) public returns(bool) {
        require(msg.sender == admin);
        require(value > 0);
        uint256 maxValue = address(this).balance;
        if (tokenAddr != address(0)) {
            require(accepted[tokenAddr]);
            TokenFace token = TokenFace(tokenAddr);
            maxValue = token.balanceOf(address(this));
            require(value <= maxValue);
            token.transfer(to, value);
        } else {
            require(value <= maxValue);
            if (!to.call.gas(100000).value(value)()) to.transfer(value);
        }
        emit Withdraw(tokenAddr, to, value);
        return true;
    }
}