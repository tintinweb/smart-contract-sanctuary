/**
 *Submitted for verification at BscScan.com on 2021-11-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

library SafeMath
{
    function mul(uint256 a, uint256 b) internal pure returns (uint256)
    {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256)
    {
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256)
    {
        assert(b <= a);

        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256)
    {
        uint256 c = a + b;
        assert(c >= a);

        return c;
    }
}

contract OwnerHelper {
    address internal owner;
    mapping(address => bool) locked_;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner{
        require(msg.sender == owner);
        _;
    }

    modifier locked() {
        require(!locked_[msg.sender]);
        _;
    }

    modifier lockedSender(address from) {
        require(!locked_[from]);
        _;
    }

    constructor() public{
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function lock(address who_) public onlyOwner{
        locked_[who_] = true;
    }

    function unlock(address who_) public onlyOwner {
        locked_[who_] = false;
    }


}

//interface ERC20Interface {
//    event Burn(address indexed _burner, uint256 _value);
//
//    event Transfer(address indexed _from, address indexed _to, uint _value);
//
//    event Approval(address indexed _owner, address indexed _spender, uint _value);
//
//    function totalSupply() view external returns (uint _supply);
//
//    function balanceOf(address _who) external view returns (uint _value);
//
//    function transfer(address _to, uint256 _value) external returns (bool _success);
//
//    function approve(address _spender, uint256 _value) external returns (bool _success);
//
//    function allowance(address _owner, address _spender) external view returns (uint _allowance);
//
//    function decreaseAllowance(address _spender, uint256 _value) external returns(bool _success);
//
//    function increaseAllowance(address _spender, uint256 _value) external returns(bool _success);
//
//    function transferFrom(address _from, address _to, uint256 _value) external returns (bool _success);
//
//    function burn(uint256 _value) external;
//
//}

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    event Burn(address indexed _burner, uint256 _value);
}

contract BProtoLast is OwnerHelper, IBEP20 {
    using SafeMath for uint;

    string private _name;
    uint8 private _decimals;
    string private _symbol;

    uint256 private _totalSupply;

    mapping(address => uint) _balances;
    mapping(address => mapping(address => uint)) internal allowed;

    uint constant private E18 = 1000000000000000000;

    constructor() public {
        _name = "BProtoLast";
        _decimals = 18;
        _symbol = "BPROL";
        _totalSupply = 1100000000 * E18;
        _balances[msg.sender] = _totalSupply;

        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() override view public returns (uint){
        return _totalSupply;
    }

    function balanceOf(address _who) override view public returns(uint){
        return _balances[_who];
    }

    function transfer(address _to, uint _value) override public locked returns(bool){
        require(_balances[msg.sender] >= _value);

        _balances[msg.sender] = _balances[msg.sender].sub(_value);
        _balances[_to] = _balances[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function approve(address _spender, uint _value) override public returns(bool){
        require(_balances[msg.sender] >= _value);

        allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function allowance(address _owner, address _spender) override view public returns (uint){
        return allowed[_owner][_spender];
    }

    function decreaseAllowance(address _spender, uint256 _value) external returns(bool){
        require(_spender != address(0));
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].sub(_value);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);

        return true;
    }

    function increaseAllowance(address _spender, uint256 _value) external returns(bool){
        require(_spender != address(0));
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_value);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);

        return true;
    }


    function transferFrom(address _from, address _to, uint _value) override public lockedSender(_from) returns(bool){
        require(_to != address(0));
        require(_balances[_from] >= _value);
        require(allowed[_from][msg.sender] >= _value);

        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        _balances[_from] = _balances[_from].sub(_value);
        _balances[_to] = _balances[_to].add(_value);

        emit Transfer(_from, _to, _value);

        return true;
    }

    function burn(uint256 _value) public {
        require(_balances[msg.sender] >= _value);

        address burner = msg.sender;
        _balances[burner] = _balances[burner].sub(_value);
        _totalSupply = _totalSupply.sub(_value);

        emit Transfer(burner, address(0), _value);
        emit Burn(burner, _value);
    }

    function decimals() override public view returns(uint8){
        return _decimals;
    }

    function symbol() override public view returns (string memory){
        return _symbol;
    }

    function name() override public view returns(string memory){
        return _name;
    }

    function getOwner() override public view returns(address){
        return owner;
    }
}