/**
 *Submitted for verification at Etherscan.io on 2021-06-14
*/

pragma solidity ^0.8.5;



/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

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
    function allowance(address owner, address spender) external view returns (uint256);

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
}

contract ICO is IERC20 {
    address _owner;
    uint256 private _tokens = 10000000;
    uint256 private _tokensToOwner = 3000000;
    uint8 private _decimals = 4;
    uint8 private _decimalsBase = 18;
    uint256 private _priceInWeiPerUnit = 100000000000;

    bool private _icoEnd = false;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    constructor() {
        _owner = msg.sender;
        _balances[_owner] = _tokensToOwner;
        _balances[address(this)] = _tokens - _tokensToOwner;

        emit Transfer(address(0), _owner, _balances[_owner]);
        emit Transfer(address(0), address(this), _balances[address(this)]);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(_icoEnd || ((sender == address(this) ) || (sender == _owner)), "ICO: no transfers till ico end");
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount <= _balances[sender], "ICO: token more than balance");

        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function name() external view returns (string memory) {
        return 'ic';
    }

    function symbol() external view returns (string memory) {
        return 'ICO';
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _tokens;
    }

    function balanceOf(address owner) external view override returns (uint256 balance) {
        return _balances[owner];
    }

    function transfer(address to, uint256 value) external override returns (bool success) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function buy(uint256 count) external payable {
        require(!_icoEnd, "ICO: end");

        uint256 units = msg.value / _priceInWeiPerUnit;

        require(units >= count, "ICO: want more tokens than value");
        require(_balances[address(this)] >= units, "ICO: less token than free");

        _transfer(address(this), msg.sender, units);
    }

    function _icoEnds() external {
        require(msg.sender != _owner, "Not a owner");
        _icoEnd = true;
    }

    function withdraw() external {
        require(_icoEnd, "ICO: not end");

        payable(_owner).transfer(address(this).balance);
    }

    function leftOnContract() external view returns (uint256) {
        return _balances[address(this)];
    }
}