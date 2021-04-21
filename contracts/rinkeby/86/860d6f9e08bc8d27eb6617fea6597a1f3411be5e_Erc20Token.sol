// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract Erc20Token is IERC20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowances;
    uint256 internal totalSupply_;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public inflationRate; // in 10**2
    uint256 private maximumSupply;
    uint256 public startTime;
    uint256 public lastTime;


    constructor(uint256 initialSupply, uint256 InfRate, uint256 mSupply) public {
        balances[mintAccessor] = initialSupply;
        totalSupply_ = initialSupply;
        emit Transfer(address(0), mintAccessor, initialSupply);
        inflationRate = InfRate;
        name = "Pallapay";
        symbol = "PALL";
        decimals = 8;
        maximumSupply = mSupply;
        startTime = block.timestamp;
        lastTime = block.timestamp;
    }


    /**
     * Transfer token from sender(caller) to '_to' account
     *
     * Requirements:
     *
     * - `_to` cannot be the zero address.
     * - the sender(caller) must have a balance of at least `_value`.
     */
    function transfer(address _to, uint256 _value) public override returns (bool) {
        require (_value <= balances[msg.sender], "transfer value should be smaller than your balance");
        require (_to != address(0));
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }


    /**
     * sender(caller) transfer '_value' token to '_to' address from '_from' address
     *
     * Requirements:
     *
     * - `_to` and `_from` cannot be the zero address.
     * - `_from` must have a balance of at least `_value` .
     * - the sender(caller) must have allowance for `_from`'s tokens of at least `_value`.
     */
    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool) {
        require (_from != address(0),"_from address is not valid");
        require (_to != address(0),"_to address is not valid");
        require(_value<=allowances[_from][msg.sender], "_value should be smaller than your allowance");
        require(_value<=balances[_from],"_value should be smaller than _from's balance");
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowances[_from][msg.sender] = allowances[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * change allowance of `_spender` to `_value` by sender(caller)
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address _spender, uint256 _value) public override returns (bool) {
        require (_spender != address(0),  "_spender is not valid address");
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
    * Atomically increases the allowance granted to `spender` by the sender(caller).
    * Emits an {Approval} event indicating the updated allowance.
    *
    * Requirements:
    *
    * - `spender` cannot be the zero address.
    */
    function increaseApproval(address _spender, uint _addedValue) public override returns (bool) {
        require (_spender != address(0),  "_spender is not valid address");
        allowances[msg.sender][_spender] = allowances[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowances[msg.sender][_spender]);
        return true;
    }

    /**
    * Atomically decreases the allowance granted to `spender` by the sender(caller).
    * Emits an {Approval} event indicating the updated allowance.
    *
    * Requirements:
    *
    * - `_spender` cannot be the zero address.
    * - `_spender` must have allowance for the caller of at least `_subtractedValue`.
    */
    function decreaseApproval(address _spender, uint _subtractedValue) public override returns (bool) {
        require (_spender != address(0),  "_spender is not valid address");
        uint oldValue = allowances[msg.sender][_spender];
        allowances[msg.sender][_spender] = _subtractedValue > oldValue ? 0 : oldValue.sub(_subtractedValue);
        emit Approval(msg.sender, _spender, allowances[msg.sender][_spender]);
        return true;
    }


    /**
    * Destroys `amount` tokens from `account`, reducing the
    * total supply.
    * Emits a {Transfer} event with `to` set to the zero address.
    *
    * Requirements:
    * - `amount` cannot be less than zero.
    * - `amount` cannot be more than sender(caller)'s balance.
    */
    function burn(uint256 amount) public {
        require(amount > 0, "amount cannot be less than zero");
        require(amount <= balances[msg.sender], "amount to burn is more than the caller's balance");
        balances[msg.sender] = balances[msg.sender].sub(amount);
        totalSupply_ = totalSupply_.sub(amount);
        emit Transfer(msg.sender, address(0), amount);
    }
    

    /**
    * sender(caller) create a 'value' token mint request.
    *
    * Requirement:
    * - sender(Caller) should be mintAccessorAddress
    */
    function mint(uint256 value) public {
        require(msg.sender == mintAccessor,"you are not permitted to create mint request!");
        
        if (block.timestamp.sub(lastTime) >= 366 days) {
            maximumSupply = maximumSupply.mul(10**4 + inflationRate).div(10**4);
            lastTime = block.timestamp;
        }

        require(totalSupply().add(value) <= maxSupply(), "mint value more than maxSupply is not allowed!");

        totalSupply_ = totalSupply_.add(value);
        balances[mintDest] = balances[mintDest].add(value);
        emit Transfer(address(0), mintDest, value);
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowances[_owner][_spender];
    }


    function maxSupply() public view returns(uint256) {
        return maximumSupply.add(maximumSupply.mul(inflationRate).mul(block.timestamp.sub(lastTime)).div(366 days).div(10**4));
    }
}