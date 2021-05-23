// SPDX-License-Identifier: MIT
pragma solidity 0.5.16;

import "./SafeMath.sol";
import "./Pausable.sol";

/// @title  Контракт токена
/// @notice Представляет собой токен стандарта ERC-20
/// Поддерживает функцию паузы работы с токеном
contract Token is Pausable{

    using SafeMath for uint256;

    string private _name; /// имя токена
    string private _symbol; /// символ токена

    address private owner;  /// адрес владельца
    address private _minter;  /// адрес эмитента

    uint256 private _totalSupply; /// число всех токенов
    uint8 private _decimals;  /// минимальная единица токена

    bool private _mintingFinished = false;  /// выпуск токена завершился

    /// @notice баланс адреса
    mapping (address => uint256) private balances;
    
    /// @notice разрешение на перевод от третьего лица
    mapping (address => mapping (address => uint256)) private _allowances;

    event Transfer(address indexed _from, address indexed _to, uint256 _value); 
    event Approval(address indexed _owner, address indexed _spender, uint256 _value); 

    constructor(string memory name_, string memory symbol_, uint8 decimals_) Pausable() public {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        owner = msg.sender;
        _minter = msg.sender; //only initial
    }

    /// @notice Можно выпускать токен
    modifier canMint() {
        require(!_mintingFinished);
        _;
    }
    
    /// @notice Может выполнять только владелец
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    /// @notice Получить баланс адреса
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];        
    }
    
    /// @notice Получить имя токена
    function name() public view returns (string memory) {
        return _name;
    }
    
     /// @notice Получить символ токена
    function symbol() public view returns (string memory) {
        return _symbol;
    }

     /// @notice Получить decimals
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /// @notice Получить общее число токенов
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /// @notice Получить адрес эмитента
    function minter() public view returns (address) {
        return _minter;
    }

    /// @notice Получить информацию о завершении эмиссии токена
    function mintingFinished() public view returns (bool) {
        return _mintingFinished;
    }
    
    /// @notice Получить информацию о разрешении на перевод токена от третьего лица
    /// @param  _owner владелец токенов
    /// @param  _spender третья сторона, которой был разрешен перевод от имени владельца
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        require(_owner != address(0));
        require(_spender != address(0));
        return _allowances[_owner][_spender];
    }

    /// @notice Передать роль эмитента
    /// @param  _to получатель роли эмитента
    function passMinterRole(address _to) public returns (bool success) {
        require(msg.sender == _minter, 'Error, only minter can pass minter role');
        _minter = _to;
        return true;
    }
    
    /// @notice Выпустить токен
    /// @param  _account владелец выпускаемых токенов
    /// @param  _amount  число выпускаемых токенов
    function mint(address _account, uint256 _amount) public canMint returns (bool success) {
        require(_account != address(0), "Mint to the zero address");
        require(_amount > 0, "Invalid amount");
        require(msg.sender == _minter, "Only minter allow to do this");
        _totalSupply += _amount;
        balances[_account] += _amount;
        
        emit Transfer(address(0), _account, _amount);
        return true;
    }

    /// @notice Остановить все операции с токеном
    function pause_token() public whenNotPaused returns (bool success) {
        require(msg.sender == owner, "Only owner can pause token");
        _pause();
        return true;
    }
    
    /// @notice Разрешить все операции с токеном
    function unpause_token() public whenPaused returns (bool success) {
        require(tx.origin == owner, "Only owner can unpause token");
        _unpause();
        return true;
    }
    
    /// @notice Сжечь токены
    /// @param  _amount  число сжигаемых токенов
    function burn(uint _amount) whenNotPaused public returns (bool success){
        require(_amount > 0, "Try to burn 0 amount of tokens");
        uint256 accountBalance = balances[msg.sender];
        require(accountBalance >= _amount, "Burn amount exceeds balance");
        balances[msg.sender] = accountBalance - _amount;
        _totalSupply -= _amount;

        return true;
    }

    /// @notice Перевести токены
    /// @param  _to адрес получателя
    /// @param  _value  число токенов для перевода
    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool result) {
        require(_to != address(0), "Transfer to empty address not allowed");
        require(balances[msg.sender] >= _value, "Not enough balance");
        require(_value > 0, "Number of tokens must be more then 0");

        balances[msg.sender] -= _value;
        balances[_to] += _value;
        
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /// @notice Перевести токены от имени третьего лица
    /// @param  _from адрес отправителя
    /// @param  _to адрес получателя
    /// @param  _amount  число токенов для перевода
    function transferFrom(address _from, address _to, uint256 _amount) public whenNotPaused returns (bool success) {
        require(_from != address(0));
        require(_to != address(0));
        require(_amount > 0);
        require(_allowances[_from][msg.sender] >= _amount, "Not enough allowance");
        require(balances[_from] >= _amount, "Not enough tokens to transfer");

        _allowances[_from][msg.sender] -= _amount;
        balances[_from] -= _amount;
        balances[_to] += _amount;
        return true;
    }

    /// @notice Разрешить перевеод от своего имени
    /// @param  _spender адрес для кого идет подтверждение
    /// @param  _value  число токенов для перевода
    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool success) {
        require(_spender != address(0), "Approve to empty address not allowed");
        require(_value > 0, "Number of tokens must be more then 0");
        require(balances[msg.sender] >= _value, "Not enough tokens to allow");
        _allowances[msg.sender][_spender] = _value;
        return true;
    }

    /// @notice Увеличить разрешение на перевод от своего имени
    /// @param  _to адрес для кого идет подтверждение
    /// @param  _amount число, на которое увеличивается разрешение
    function increaseAllowance(address _to, uint256 _amount) public whenNotPaused returns (bool success) {
        require(_to != address(0), "Allow to empty address not allowed");
        require(_amount > 0, "Number of tokens must be more then 0");
        require(balances[msg.sender] >= _allowances[msg.sender][_to].add(_amount), "Not enough tokens to allow after increase");
        
        _allowances[msg.sender][_to] += _amount;
        return true;
    }

    /// @notice Уменьшить разрешение на перевод от своего имени
    /// @param  _to адрес для кого идет подтверждение
    /// @param  _amount число, на которое увеличивается разрешение
    function decreaseAllowance(address _to, uint256 _amount) public whenNotPaused returns (bool success) {
        require(_to != address(0), "Allow to empty address not allowed");
        require(_amount > 0, "Number of tokens must be more then 0");
        require(_allowances[msg.sender][_to].sub(_amount) > 0, "Allowance after decrease become < 0");

        _allowances[msg.sender][_to] -= _amount;
        return true;
    }
    
    /// @notice Завершить эмиссию токена
    function finishMint() public canMint() returns (bool success) {
        require(tx.origin == owner, "Only owner can finish mint");
        _mintingFinished = true;
        return true;
    }
}