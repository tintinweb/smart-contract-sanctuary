/**
 *Submitted for verification at Etherscan.io on 2021-12-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Vanilla ERC20 contract version 1.0
 *
 * @author unblocktechie
 */
contract VanillaERC20 {

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    /**
     * @dev initial private
     */
    string private _name;
    string private _symbol;
    uint8 constant _decimal = 18;
    address private _Owner;

    /**
     * @dev Total supply 
     */
    uint256 private _totalSupply;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed holder,
        address indexed spender,
        uint256 value
    );

    /**
	 * @dev Creates/deploys Vanilla ERC20 contract version 1.0
	 *
	 * @param name_ name of token
     * @param symbol_ symbol of token
     * @param own_ address of owner 
     * @param supply_ total supply
	 */
    constructor (string memory name_, string memory symbol_, address own_, uint256 supply_) {
        _name = name_;
        _symbol = symbol_;
        _Owner = own_;
        _totalSupply = supply_;
        _balances[_Owner] = _totalSupply;

        emit Transfer(address(0x0), _Owner, _totalSupply);

    }

    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the decimals of the token.
     */
    function decimals() external pure returns (uint8) {
        return _decimal;
    }

    /**
     * @dev Returns the address of contract owner.
     */
    function getOwner() external view returns (address) {
        return _Owner;
    }

    /**
     * @dev Returns the total supply of the token.
     */
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Returns the token balance of specific address.
     */
    function balanceOf(address _holder) external view returns (uint256) {
        return _balances[_holder];
    }

    /**
     * @dev Allows to transfer tokens 
     */
    function transfer(
        address recipient,
        uint256 amount
    )
        external
        returns (bool)
    {
        _transfer(
            msg.sender,
            recipient,
            amount
        );

        return true;
    }

    /**
     * @dev Returns approved balance to be spent by another address
     * by using transferFrom method
     */
    function allowance(
        address holder,
        address spender
    )
        external
        view
        returns (uint256)
    {
        return _allowances[holder][spender];
    }

    /**
     * @dev Sets the token allowance to another spender
     */
    function approve(
        address spender,
        uint256 amount
    )
        external
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            amount
        );

        return true;
    }

    /**
     * @dev Allows to transfer tokens on senders behalf
     * based on allowance approved for the executer
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    )
        external
        returns (bool)
    {
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);

        _transfer(
            sender,
            recipient,
            amount
        );
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * Emits a {Transfer} event.
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    )
        internal
        virtual
    {
        require(
            sender != address(0x0)
        );

        require(
            recipient != address(0x0)
        );

        _balances[sender] = _balances[sender] - amount;

        _balances[recipient] = _balances[recipient] + amount;

        emit Transfer(
            sender,
            recipient,
            amount
        );
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `holder`s tokens.
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `holder` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address holder,
        address spender,
        uint256 amount
    )
        internal
        virtual
    {
        require(
            holder != address(0x0)
        );

        require(
            spender != address(0x0)
        );

        _allowances[holder][spender] = amount;

        emit Approval(
            holder,
            spender,
            amount
        );
    }

}

/**
 * @title ERC20 token factory version 1.0
 *
 * @author unblocktechie
 */
contract ERC20TokenFactory {

    /**
     * @dev Create a VanillaERC20 contract
     *
     * @param name_ name of new ERC20 token
     * @param symbol_ symbol of new ERC20 token
     * @param supply_ Total supply of new ERC20 token
     */
    function createERC20ForArticle(
        string memory name_,
        string memory symbol_,
        uint256 supply_
    ) external {
        
        VanillaERC20 newERC20 = new VanillaERC20(name_, symbol_, msg.sender, supply_);
        
        newERC20.name();
    
    }

}