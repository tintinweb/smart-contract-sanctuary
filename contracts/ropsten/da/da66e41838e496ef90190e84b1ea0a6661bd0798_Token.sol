pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT

import "./SafeMath.sol";

/// @title Zoo token contract
/// @notice Based on the ERC-20 token standard as defined at https://eips.ethereum.org/EIPS/eip-20
/// @notice Added burn and redistribution from transfers to YieldFarm.
contract Token {

    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public totalSupply;
    address public yieldFarm;

    mapping(address => uint256) balances;                       // Records balances of addresses.
    mapping(address => mapping(address => uint256)) allowed;    // Records allowances for tokens.

    /// @notice Event records info about transfers.
    /// @param from - address sender.
    /// @param to - address recipient.
    /// @param value - amount of tokens transfered.
    event Transfer(address from, address to, uint256 value);

    /// @notice Event records info about approving transfers.
    /// @param owner - address owner of tokens.
    /// @param spender - address spender of tokens.
    /// @param value - amount of tokens allowed to spend.
    event Approval(address owner, address spender, uint256 value);

    /// @notice Contract constructor.
    /// @param _name - name of token.
    /// @param _symbol - symbol of token.
    /// @param _decimals - token decimals.
    /// @param _totalSupply - total supply amount.
    /// @param _yieldFarm - address of contract with rewards for stacking pool.
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _decimals,
        uint256 _totalSupply,
        address _yieldFarm
    ) public
    {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        yieldFarm = _yieldFarm;
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    /// @notice Getter to check the current balance of an address.
    /// @param _owner Address of owner.
    /// @return Balances of owner.
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    /// @notice Getter to check the amount of tokens that an owner allowed to a spender.
    /// @param _owner The address which owns the funds.
    /// @param _spender The address which will spend the funds.
    /// @return The amount of tokens still available for the spender.
    function allowance(
        address _owner,
        address _spender
    )
        public
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

    /// @notice Approve an address to spend the specified amount of tokens on behalf of msg.sender.
    /// @param _spender The address which will spend the tokens.
    /// @param _value The amount of tokens to be spent.
    /// @return Success boolean.
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /// @notice Function for transfering tokens.
    /// @notice Redistributes % of transfer - increases YieldFarm epoch value.
    /// @param _from - sender of tokens.
    /// @param _to - recipient of tokens.
    /// @param _value - amount of transfer.
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(balances[_from] >= _value, "Insufficient balance"); // Requires balance to be sufficient enough for transfer.
        balances[_from] = balances[_from].sub(_value);              // Decreases balances of sender.
        balances[_to] = balances[_to].add(_value);                  // Increases balances of recipient.
        
        burnFrom(_to, _value.mul(15).div(10000));                   // Burns % of tokens from transfered amount, currently burns 0.15%.
        
        uint256 basisPointToReward = 30;                               // Sets basis points to 0.3%.
        uint256 fee = _value.mul(basisPointToReward).div(10000);       // Calculates fee amount.
        balances[_to] = balances[_to].sub(fee);                     // Decreases amount of token sended for fee amount.
        balances[yieldFarm] = balances[yieldFarm].add(fee);       // Increases balances of YieldFarm for fee amount.

        emit Transfer(_from, _to, _value);                          // Records to Transfer event.
    }

    /// @notice Function for burning tokens.
    /// @param amount - amount of tokens to burn.
     function burn(uint256 amount) public {        
        burnFrom(msg.sender, amount);
    }

    /// @notice Internal function for burning tokens.
    /// @param from - Address of token owner.
    /// @param amount - Amount of tokens to burn.
    function burnFrom(address from, uint256 amount) internal {
        require(balances[from] >= amount, "ERC20: burn amount exceeds balance"); // Requires balance to be sufficient enough for burn.

        balances[from] = balances[from].sub(amount);                             // Decreases balances of owner for burn amount.
        totalSupply = totalSupply.sub(amount);                                   // Decreases total supply of tokens for amount.

        emit Transfer(from, address(0), amount);                                 // Records to Transfer event.
    }

    /// @notice Transfer tokens to a specified address.
    /// @param _to The address to transfer to.
    /// @param _value The amount to be transferred.
    /// @return Success boolean.
    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /// @notice Transfer tokens from one address to another.
    /// @param _from The address which you want to send tokens from.
    /// @param _to The address which you want to transfer to.
    /// @param _value The amount of tokens to be transferred.
    /// @return Success boolean.
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        public
        returns (bool)
    {
        require(allowed[_from][msg.sender] >= _value, "Insufficient allowance");    // Requires to be allowed for sending tokens.
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);        // Decreases amount of allowance for sended value.
        _transfer(_from, _to, _value);                                              // Calls _transfer function.
        return true;
    }

}