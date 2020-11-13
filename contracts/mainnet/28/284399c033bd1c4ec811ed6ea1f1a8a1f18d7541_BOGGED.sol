/*
 *
 *
 *               BOGGED
 *      https://views.farm/bogged
 *        
 *
 */

pragma solidity ^0.5.2;

interface IERC20 {
    function totalSupply() external view returns(uint256);

    function balanceOf(address who) external view returns(uint256);

    function allowance(address owner, address spender) external view returns(uint256);

    function transfer(address to, uint256 value) external returns(bool);

    function approve(address spender, uint256 value) external returns(bool);

    function transferFrom(address from, address to, uint256 value) external returns(bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        require(b > 0);
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    function ceil(uint256 a, uint256 m) internal pure returns(uint256) {
        uint256 c = add(a, m);
        uint256 d = sub(c, 1);
        return mul(div(d, m), m);
    }
}

contract ERC20Detailed is IERC20 {

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    function name() public view returns(string memory) {
        return _name;
    }

    function symbol() public view returns(string memory) {
        return _symbol;
    }

    function decimals() public view returns(uint8) {
        return _decimals;
    }
}

contract BOGGED is ERC20Detailed {

    using SafeMath for uint256;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply = 100000 * 1e18;

    /// @note The base percent for the burn amount.
    uint256 public basePercent = 320;

    constructor() public ERC20Detailed("BOGGED", "BOGGED", 18) {
        _mint(msg.sender, _totalSupply);
    }

    /// @return Total number of tokens in circulation
    function totalSupply() public view returns(uint256) {
        return _totalSupply;
    }

    /**
     * @notice Get the number of tokens held by the `owner`
     * @param owner The address of the account to get the balance of
     * @return The number of tokens held
     */
    function balanceOf(address owner) public view returns(uint256) {
        return _balances[owner];
    }

    /**
     * @notice Get the number of tokens `spender` is approved to spend on behalf of `owner`
     * @param owner The address of the account holding the funds
     * @param spender The address of the account spending the funds
     * @return The number of tokens approved
     */
    function allowance(address owner, address spender) public view returns(uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @notice Find the number of tokens to burn from `value`. Approximated at 0.3125%.
     * @param value The value to find the burn amount from
     * @return The found burn amount
     */
    function findBurnAmount(uint256 value) public view returns(uint256) {
        //Allow transfers of 0.000000000000000001
        if (value == 1) {
            return 0;
        }
        uint256 roundValue = value.ceil(basePercent);
        //Gas optimized
        uint256 burnAmount = roundValue.mul(100).div(32000);
        return burnAmount;
    }

    /**
     * @notice Transfer `value` minus `findBurnAmount(value)` tokens from `msg.sender` to `to`, 
     * while subtracting `findBurnAmount(value)` tokens from `_totalSupply`. This performs a transfer with an approximated fee of 0.3125%
     * @param to The address of the destination account
     * @param value The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address to, uint256 value) public returns(bool) {
        require(to != address(0));

        uint256 tokensToBurn = findBurnAmount(value);
        uint256 tokensToTransfer = value.sub(tokensToBurn);

        _balances[msg.sender] = _balances[msg.sender].sub(value);
        _balances[to] = _balances[to].add(tokensToTransfer);

        _totalSupply = _totalSupply.sub(tokensToBurn);

        emit Transfer(msg.sender, to, tokensToTransfer);
        emit Transfer(msg.sender, address(0), tokensToBurn);
        return true;
    }

    /**
     * @notice Approve `spender` to transfer up to `value` from `from`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param value The number of tokens that are approved
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint256 value) public returns(bool) {
        require(spender != address(0));
        _allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * @notice Transfer `value` minus `findBurnAmount(value)` tokens from `from` to `to`, 
     * while subtracting `findBurnAmount(value)` tokens from `_totalSupply`. This performs a transfer with an approximated fee of 0.3125%
     * @param from The address of the source account
     * @param to The address of the destination account
     * @param value The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(address from, address to, uint256 value) public returns(bool) {
        require(value <= _allowances[from][msg.sender]);
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);

        uint256 tokensToBurn = findBurnAmount(value);
        uint256 tokensToTransfer = value.sub(tokensToBurn);

        _balances[to] = _balances[to].add(tokensToTransfer);
        _totalSupply = _totalSupply.sub(tokensToBurn);

        _allowances[from][msg.sender] = _allowances[from][msg.sender].sub(value);

        emit Transfer(from, to, tokensToTransfer);
        emit Transfer(from, address(0), tokensToBurn);

        return true;
    }

    /**
     * @notice Increase allowance of `spender` by 'addedValue'
     * @param spender The address of the account which may transfer tokens
     * @param addedValue Value to be added onto the existing allowance amount
     * @return Whether or not the allowance increase succeeded
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns(bool) {
        require(spender != address(0));
        _allowances[msg.sender][spender] = (_allowances[msg.sender][spender].add(addedValue));
        emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);
        return true;
    }

    /**
     * @notice Decrease allowance of `spender` by 'subtractedValue'
     * @param spender The address of the account which may transfer tokens
     * @param subtractedValue Value to be subtracted onto the existing allowance amount
     * @return Whether or not the allowance decrease succeeded
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns(bool) {
        require(spender != address(0));
        _allowances[msg.sender][spender] = (_allowances[msg.sender][spender].sub(subtractedValue));
        emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);
        return true;
    }

    function _mint(address account, uint256 amount) internal {
        require(amount != 0);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @notice Burn `amount` of tokens from `msg.sender` by sending them to `address(0)`
     * @param amount The amount of tokens to burn
     */
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(amount != 0);
        _totalSupply = _totalSupply.sub(amount);
        _balances[account] = _balances[account].sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @notice Burn `amount` of tokens from `account` by sending them to `address(0)`
     * @param amount The amount of tokens to burn
     */
    function burnFrom(address account, uint256 amount) external {
        require(amount <= _allowances[account][msg.sender]);
        _allowances[account][msg.sender] = _allowances[account][msg.sender].sub(amount);
        _burn(account, amount);
    }
}