/**
 *Submitted for verification at Etherscan.io on 2021-08-14
*/

/**
 *Submitted for verification at Etherscan.io on 2019-05-30
*/

pragma solidity ^0.5.7;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value)
        external returns (bool);

    function transferFrom(address from, address to, uint256 value)
        external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
        external view returns (uint256);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

/* Copyright (C) 2017 NexusMutual.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */







contract NXMToken is IERC20 {
    using SafeMath for uint256;

    event WhiteListed(address indexed member);

    event BlackListed(address indexed member);

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    mapping (address => bool) public whiteListed;

    mapping(address => uint) public isLockedForMV;

    uint256 private _totalSupply;

    string public name = "NNM";
    string public symbol = "NNM";
    uint8 public decimals = 18;
    address public operator;

    modifier canTransfer(address _to) {
        require(whiteListed[_to]);
        _;
    }

    modifier onlyOperator() {
        if (operator != address(0))
            require(msg.sender == operator);
        _;
    }

    constructor(address _founderAddress, uint _initialSupply) public {
        _mint(_founderAddress, _initialSupply);
    }

    /**
    * @dev Total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param owner The address to query the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    /**
    * @dev Function to check the amount of tokens that an owner allowed to a spender.
    * @param owner address The address which owns the funds.
    * @param spender address The address which will spend the funds.
    * @return A uint256 specifying the amount of tokens still available for the spender.
    */
    function allowance(
        address owner,
        address spender
    )
        public
        view
        returns (uint256)
    {
        return _allowed[owner][spender];
    }

    /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    * Beware that changing an allowance with this method brings the risk that someone may use both the old
    * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
    * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
    * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    * @param spender The address which will spend the funds.
    * @param value The amount of tokens to be spent.
    */
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
    * @dev Increase the amount of tokens that an owner allowed to a spender.
    * approve should be called when allowed_[_spender] == 0. To increment
    * allowed value is better to use this function to avoid 2 calls (and wait until
    * the first transaction is mined)
    * From MonolithDAO Token.sol
    * @param spender The address which will spend the funds.
    * @param addedValue The amount of tokens to increase the allowance by.
    */
    function increaseAllowance(
        address spender,
        uint256 addedValue
    )
        public
        returns (bool)
    {
        require(spender != address(0));

        _allowed[msg.sender][spender] = (
        _allowed[msg.sender][spender].add(addedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    /**
    * @dev Decrease the amount of tokens that an owner allowed to a spender.
    * approve should be called when allowed_[_spender] == 0. To decrement
    * allowed value is better to use this function to avoid 2 calls (and wait until
    * the first transaction is mined)
    * From MonolithDAO Token.sol
    * @param spender The address which will spend the funds.
    * @param subtractedValue The amount of tokens to decrease the allowance by.
    */
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    )
        public
        returns (bool)
    {
        require(spender != address(0));

        _allowed[msg.sender][spender] = (
        _allowed[msg.sender][spender].sub(subtractedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    /**
    * @dev Adds a user to whitelist
    * @param _member address to add to whitelist
    */
    function addToWhiteList(address _member) public onlyOperator returns (bool) {
        whiteListed[_member] = true;
        emit WhiteListed(_member);
        return true;
    }

    /**
    * @dev removes a user from whitelist
    * @param _member address to remove from whitelist
    */
    function removeFromWhiteList(address _member) public onlyOperator returns (bool) {
        whiteListed[_member] = false;
        emit BlackListed(_member);
        return true;
    }

    /**
    * @dev change operator address 
    * @param _newOperator address of new operator
    */
    function changeOperator(address _newOperator) public onlyOperator returns (bool) {
        operator = _newOperator;
        return true;
    }

    /**
    * @dev burns an amount of the tokens of the message sender
    * account.
    * @param amount The amount that will be burnt.
    */
    function burn(uint256 amount) public returns (bool) {
        _burn(msg.sender, amount);
        return true;
    }

    /**
    * @dev Burns a specific amount of tokens from the target address and decrements allowance
    * @param from address The address which you want to send tokens from
    * @param value uint256 The amount of token to be burned
    */
    function burnFrom(address from, uint256 value) public returns (bool) {
        _burnFrom(from, value);
        return true;
    }

    /**
    * @dev function that mints an amount of the token and assigns it to
    * an account.
    * @param account The account that will receive the created tokens.
    * @param amount The amount that will be created.
    */
    function mint(address account, uint256 amount) public onlyOperator {
        _mint(account, amount);
    }

    /**
    * @dev Transfer token for a specified address
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function transfer(address to, uint256 value) public canTransfer(to) returns (bool) {

        require(isLockedForMV[msg.sender] < now); // if not voted under governance
        require(value <= _balances[msg.sender]);
        _transfer(to, value); 
        return true;
    }

    /**
    * @dev Transfer tokens to the operator from the specified address
    * @param from The address to transfer from.
    * @param value The amount to be transferred.
    */
    function operatorTransfer(address from, uint256 value) public onlyOperator returns (bool) {
        require(value <= _balances[from]);
        _transferFrom(from, operator, value);
        return true;
    }

    /**
    * @dev Transfer tokens from one address to another
    * @param from address The address which you want to send tokens from
    * @param to address The address which you want to transfer to
    * @param value uint256 the amount of tokens to be transferred
    */
    function transferFrom(
        address from,
        address to,
        uint256 value
    )
        public
        canTransfer(to)
        returns (bool)
    {
        require(isLockedForMV[from] < now); // if not voted under governance
        require(value <= _balances[from]);
        require(value <= _allowed[from][msg.sender]);
        _transferFrom(from, to, value);
        return true;
    }

    /**
     * @dev Lock the user's tokens 
     * @param _of user's address.
     */
    function lockForMemberVote(address _of, uint _days) public onlyOperator {
        if (_days.add(now) > isLockedForMV[_of])
            isLockedForMV[_of] = _days.add(now);
    }

    /**
    * @dev Transfer token for a specified address
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function _transfer(address to, uint256 value) internal {
        _balances[msg.sender] = _balances[msg.sender].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(msg.sender, to, value);
    }

    /**
    * @dev Transfer tokens from one address to another
    * @param from address The address which you want to send tokens from
    * @param to address The address which you want to transfer to
    * @param value uint256 the amount of tokens to be transferred
    */
    function _transferFrom(
        address from,
        address to,
        uint256 value
    )
        internal
    {
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        emit Transfer(from, to, value);
    }

    /**
    * @dev Internal function that mints an amount of the token and assigns it to
    * an account. This encapsulates the modification of balances such that the
    * proper events are emitted.
    * @param account The account that will receive the created tokens.
    * @param amount The amount that will be created.
    */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0));
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
    * @dev Internal function that burns an amount of the token of a given
    * account.
    * @param account The account whose tokens will be burnt.
    * @param amount The amount that will be burnt.
    */
    function _burn(address account, uint256 amount) internal {
        require(amount <= _balances[account]);

        _totalSupply = _totalSupply.sub(amount);
        _balances[account] = _balances[account].sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
    * @dev Internal function that burns an amount of the token of a given
    * account, deducting from the sender's allowance for said account. Uses the
    * internal burn function.
    * @param account The account whose tokens will be burnt.
    * @param value The amount that will be burnt.
    */
    function _burnFrom(address account, uint256 value) internal {
        require(value <= _allowed[account][msg.sender]);

        // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
        // this function needs to emit an event with the updated approval.
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
        value);
        _burn(account, value);
    }
}