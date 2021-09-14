/**
 *Submitted for verification at BscScan.com on 2021-09-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

contract Token {
    // Variables
    string  public name = " Energy Weapon Star";
    string  public symbol = "EWS";
    uint256 public totalSupply = 1000000000000000000000000000; // 1 million tokens
    uint8   public decimals = 20;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) private _allowances;

    // Eventos
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor() {
        balanceOf[msg.sender] = totalSupply;
    }

    /**
     * @notice Función que permite hacer una transferencia.
     * @param _to Dirección del destinatario.
     * @param _value Cantidad de tokens a transferir.
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    /**
     * @notice Función que permite ver cuanta cantidad de tokens tiene permiso para gastar una dirección.
     * @param _owner Dirección de la persona que da permiso a gastar sus tokens.
     * @param _spender Dirección a la que se le da permiso para gastar los tokens.
     */
    function allowance(address _owner, address _spender) public view virtual returns (uint256) {
        return _allowances[_owner][_spender];
    }

    /**
     * @notice Función que incrementa el allowance.
     * @param _spender Dirección a la que se le da permiso para gastar tokens.
     * @param _addedValue Cantidad de tokens que das permiso para que gasten.
     */
    function increaseAllowance(address _spender, uint256 _addedValue) public virtual returns (bool) {
        _approve(msg.sender, _spender, _allowances[msg.sender][_spender] + _addedValue);

        return true;
    }

    /**
     * @notice Función que disminuye el allowance.
     * @param _spender Dirección a la que se le quita permiso para gastar tokens.
     * @param _subtractedValue Cantidad de tokens que se van a disminuir de la cantidad permitida para gastar.
     */
    function decreaseAllowance(address _spender, uint256 _subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][_spender];
        require(currentAllowance >= _subtractedValue, "ERC20: decreased allowance below zero");

        unchecked {
            _approve(msg.sender, _spender, currentAllowance - _subtractedValue);
        }

        return true;
    }

    /**
     * @notice Función que llama a la función interna _approve.
     * @param _spender Dirección de la cuenta a la que le das permiso para gastar tus tokens.
     * @param _value Cantidad de tokens que das permiso para que gasten.
     */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        _approve(msg.sender, _spender, _value);

        return true;
    }

    /**
     * @notice Función interna que permite aprobar a otra cuenta a gastar tus tokens.
     * @param _owner Dirección de la cuenta que da permiso para gastar sus tokens.
     * @param _spender Dirección de la cuenta a la que le das permiso para gastar tus tokens.
     * @param _amount Cantidad de tokens que das permiso para que gasten.
     */
    function _approve(address _owner, address _spender, uint256 _amount) internal virtual {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");

        _allowances[_owner][_spender] = _amount;

        emit Approval(_owner, _spender, _amount);
    }

    /**
     * @notice Función que permite hacer una transferencia desde una dirección.
     * @param _from Dirección del emisor.
     * @param _to Dirección del destinatario.
     * @param _value Cantidad de tokens a transferir.
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[_from]);
        require(_value <= _allowances[_from][msg.sender]);

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        _allowances[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);

        return true;
    }

    /**
     * @notice Función pública que permite quemar tokens.
     * @param _amount Cantidad de tokens que se van a quemar.
     */
    function burn(uint256 _amount) public virtual {
        _burn(msg.sender, _amount);
    }

    /**
     * @notice Función interna que permite quemar tokens.
     * @param _account Dirección desde la que se van a quemar los tokens.
     * @param _amount Cantidad de tokens que se van a quemar.
     */
    function _burn(address _account, uint256 _amount) internal virtual {
        require(_account != address(0), 'No puede ser la direccion cero.');
        require(balanceOf[_account] >= _amount, 'La cuenta debe tener los tokens suficientes.');

        balanceOf[_account] -= _amount;
        totalSupply -= _amount;

        emit Transfer(_account, address(0), _amount);
    }
}