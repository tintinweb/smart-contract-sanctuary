pragma solidity ^0.4.24;
contract TokenHandler {
    function name() public view returns(string);
    function symbol() public view returns(string);
    function decimals() public view returns(uint);
    function totalSupply() public view returns(uint256);
    function balanceOf(address _who) public view returns(uint256);
    function allowance(address _owner, address _spender) public view returns(uint256);
    function transfer(address _to, uint256 _value) public returns(bool);
    function approve(address _spender, uint256 _value) public returns(bool);
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
}
contract WalletHandled {
    address public admin;
    address public seller;
    mapping(address => bool) accepted;
    event Deposited(address indexed _token, address indexed _from, uint256 _amount);
    event Sent(address indexed _token, address indexed _to, uint256 _amount);
    event AdminChanged(address indexed _lastAdmin, address indexed _newAdmin);
    event SellerChanged(address indexed _lastSeller, address indexed _newSeller);
    event TokenAdded(address indexed _token, string _name);
    event TokenRemoved(address indexed _token, string _name);
    constructor () public {
        admin = msg.sender;
        seller = msg.sender;
    }
    function () public payable {
        require(msg.data.length == 0 && msg.value >= (1 * 10 ** 9));
        emit Deposited(address(0), tx.origin, msg.value);
    }
    function deposit(address _token) public returns(bool) {
        require(accepted[_token]);
        TokenHandler token = TokenHandler(_token);
        uint256 amount = token.allowance(msg.sender, address(this));
        uint256 value = token.balanceOf(msg.sender);
        if (token.decimals() > 0) {
            require(amount >= (1 * 10 ** token.decimals()) && (1 * 10 ** token.decimals()) <= value);
        } else {
            require(amount > 0 && 0 < value);
        }
        if (value >= amount) {
            require(token.transferFrom(msg.sender, address(this), amount));
            emit Deposited(_token, msg.sender, amount);
        } else {
            require(token.transferFrom(msg.sender, address(this), value));
            emit Deposited(_token, msg.sender, value);
        }
        return true;
    }
    function authAccess() internal view returns(bool) {
        if (msg.sender != admin) {
            if (msg.sender != seller) {
                return false;
            } else {
                return true;
            }
        } else {
            return true;
        }
    }
    function withdraw(address _token, address _to, uint256 _amount) public returns(bool) {
        require(authAccess());
        require(_to != address(0) && address(this) != _to);
        uint256 value = address(this).balance;
        if (_token == address(0)) {
            require(_amount <= value);
            if (!_to.call.gas(100000).value(_amount)()) _to.transfer(_amount);
            emit Sent(address(0), _to, _amount);
        } else {
            require(accepted[_token]);
            TokenHandler token = TokenHandler(_token);
            value = token.balanceOf(address(this));
            require(_amount <= value);
            require(token.transfer(_to, _amount));
            emit Sent(_token, _to, _amount);
        }
        return true;
    }
    function updateAdmin(address _newAdmin) public returns(bool) {
        require(msg.sender == admin && _newAdmin != address(this) && address(0) != _newAdmin);
        admin = _newAdmin;
        emit AdminChanged(msg.sender, _newAdmin);
        return true;
    }
    function updateSeller(address _newSeller) public returns(bool) {
        require(msg.sender == seller && _newSeller != address(this) && address(0) != _newSeller);
        seller = _newSeller;
        emit SellerChanged(msg.sender, _newSeller);
        return true;
    }
    function acceptToken(address _token) public view returns(bool) {
        return accepted[_token];
    }
    function addToken(address _token) public returns(bool) {
        require(msg.sender == admin);
        require(!accepted[_token]);
        require(_token != address(0));
        accepted[_token] = true;
        emit TokenAdded(_token, TokenHandler(_token).name());
        return true;
    }
    function removeToken(address _token) public returns(bool) {
        require(authAccess());
        require(accepted[_token]);
        TokenHandler __token = TokenHandler(_token);
        uint256 _amount = __token.balanceOf(address(this));
        if (_amount > 0) {
            require(__token.transfer(tx.origin, _amount));
            emit Sent(_token, tx.origin, _amount);
        }
        accepted[_token] = false;
        emit TokenRemoved(_token, __token.name());
        return true;
    }
}