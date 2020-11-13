/* Copyright (C) 2020 PlotX.io

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

pragma solidity 0.5.7;

import "./ERC20.sol";
import "./SafeMath.sol";

contract PlotXToken is ERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) public lockedForGV;

    string public name = "PLOT";
    string public symbol = "PLOT";
    uint8 public decimals = 18;
    address public operator;

    modifier onlyOperator() {
        require(msg.sender == operator, "Not operator");
        _;
    }

    /**
     * @dev Initialize PLOT token
     * @param _initialSupply Initial token supply
     * @param _initialTokenHolder Initial token holder address
     */
    constructor(uint256 _initialSupply, address _initialTokenHolder) public {
        _mint(_initialTokenHolder, _initialSupply);
        operator = _initialTokenHolder;
    }

    /**
     * @dev change operator address
     * @param _newOperator address of new operator
     */
    function changeOperator(address _newOperator)
        public
        onlyOperator
        returns (bool)
    {
        require(_newOperator != address(0), "New operator cannot be 0 address");
        operator = _newOperator;
        return true;
    }

    /**
     * @dev burns an amount of the tokens of the message sender
     * account.
     * @param amount The amount that will be burnt.
     */
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    /**
     * @dev Burns a specific amount of tokens from the target address and decrements allowance
     * @param from address The address which you want to send tokens from
     * @param value uint256 The amount of token to be burned
     */
    function burnFrom(address from, uint256 value) public {
        _burnFrom(from, value);
    }

    /**
     * @dev function that mints an amount of the token and assigns it to
     * an account.
     * @param account The account that will receive the created tokens.
     * @param amount The amount that will be created.
     */
    function mint(address account, uint256 amount)
        public
        onlyOperator
        returns (bool)
    {
        _mint(account, amount);
        return true;
    }

    /**
     * @dev Transfer token for a specified address
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function transfer(address to, uint256 value) public returns (bool) {
        require(lockedForGV[msg.sender] < now, "Locked for governance"); // if not voted under governance
        _transfer(msg.sender, to, value);
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
    ) public returns (bool) {
        require(lockedForGV[from] < now, "Locked for governance"); // if not voted under governance
        _transferFrom(from, to, value);
        return true;
    }

    /**
     * @dev Lock the user's tokens
     * @param _of user's address.
     */
    function lockForGovernanceVote(address _of, uint256 _period)
        public
        onlyOperator
    {
        if (_period.add(now) > lockedForGV[_of])
            lockedForGV[_of] = _period.add(now);
    }

    function isLockedForGV(address _of) public view returns (bool) {
        return (lockedForGV[_of] > now);
    }
}
