/**
 *Submitted for verification at BscScan.com on 2021-10-29
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
    
    int256 constant private INT256_MIN = -2**255;

    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
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
    * @dev Multiplies two signed integers, reverts on overflow.
    */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == INT256_MIN)); // This is the only case of overflow not detected by the check below

        int256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Integer division of two signed integers truncating the quotient, reverts on division by zero.
    */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0); // Solidity only automatically asserts when dividing by 0
        require(!(b == -1 && a == INT256_MIN)); // This is the only case of overflow

        int256 c = a / b;

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Subtracts two signed integers, reverts on overflow.
    */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Adds two signed integers, reverts on overflow.
    */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address _owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract FantasyArenaToken is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;
    string public symbol;
    string public  name;
    uint8 public decimals;

    address public owner;
    address public marketingWallet;
    uint256 public taxPercentage;
    bool public isTradingEnabled;
    
    mapping (address => bool) public admins;
    mapping (address => bool) public fantasyArenaContracts;
    mapping (address => bool) public blacklist;
    mapping (address => bool) public excludedFromTax;

    modifier onlyOwner() {
        require(msg.sender == owner, "no permissions");
        _;
    }
    
    modifier onlyAdmin() {
        require(admins[msg.sender], "no permissions");
        _;
    }
    
    modifier tradingEnabled() {
        require(isTradingEnabled || _isAlwaysAllowed(), "trading not enabled");
        _;
    }

    /**
    * @dev Public functions to make the contract accesible
    */
    constructor () {
        owner = msg.sender;
        symbol = "FASY";
        name = "Fantasy Arena Token";
        decimals = 18;
        
        taxPercentage = 9;
        marketingWallet = 0xBC79476f2647C0c5485b0923F97f299De8f7AFeD;
        excludedFromTax[owner] = true;
        excludedFromTax[marketingWallet] = true;
        
        _totalSupply = _totalSupply.add(400000000 * 10 ** decimals);
        _balances[owner] = _balances[owner].add(_totalSupply);
        emit Transfer(address(0), owner, _totalSupply);
    }

    /**
    * @dev Total number of tokens in existence
    */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public override view returns (uint256) {
        return _balances[_owner];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address spender) public override view returns (uint256) {
        return _allowed[_owner][spender];
    }

    /**
    * @dev Transfer token for a specified address
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function transfer(address to, uint256 value) public override tradingEnabled returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
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
    function approve(address spender, uint256 value) public override tradingEnabled returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another.
     * Note that while this function emits an Approval event, this is not required as per the specification,
     * and other compliant implementations may not emit the event.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 value) public override tradingEnabled returns (bool) {
        _deductAllowance(from, value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) public tradingEnabled returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public tradingEnabled returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }




    // Admin methods

    function burn(address account, uint256 value) public onlyOwner {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    function changeOwner(address who) public onlyOwner {
        require(who != address(0), "cannot be zero address");
        owner = who;
    }
    
    function removeBnb() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner).transfer(balance);
    }
    
    function transferTokens(address token, address to) public onlyOwner returns(bool _sent){
        require(token != address(this), "You cannot remove the native token");
        uint256 balance = IERC20(token).balanceOf(address(this));
        _sent = IERC20(token).transfer(to, balance);
    }

    function setMarketingWallet(address who) public onlyOwner {
        require(who != address(0), "cannot be zero address");
        marketingWallet = who;
    }

    function setTradingEnabled(bool enabled) public onlyAdmin {
        isTradingEnabled = enabled;
    }
    
    function setTaxPercentage(uint256 _taxPercentage) public onlyAdmin {
        taxPercentage = _taxPercentage; 
    }
    
    function setExcludedFromTax(address who, bool enabled) public onlyAdmin {
        excludedFromTax[who] = enabled;
    }
    
    function setIsBlacklisted(address who, bool enabled) public onlyAdmin {
        blacklist[who] = enabled;
    } 
    

    


    // Private methods
    
    /**
    * @dev Transfer token for a specified addresses
    * @param from The address to transfer from.
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function _transfer(address from, address to, uint256 value) private {
        require(to != address(0), "cannot be zero address");
        require(blacklist[from] == false && blacklist[to] == false, "blacklisted wallet");

        uint256 taxAmount = 0;
        _balances[from] = _balances[from].sub(value);
        if (_isExcludedFromTax(from) == false && _isExcludedFromTax(to) == false) {
            taxAmount = value.mul(taxPercentage).div(100);
        }
        _balances[to] = _balances[to].add(value.sub(taxAmount));
        _balances[marketingWallet] = _balances[marketingWallet].add(taxAmount);
        emit Transfer(from, to, value);
    }
    
    function _isAlwaysAllowed() private view returns (bool) {
        return msg.sender == owner || msg.sender == marketingWallet || _isFantasyArenaContract(msg.sender);
    }
    
    function _isExcludedFromTax(address who) private view returns (bool) {
        return excludedFromTax[who] || _isFantasyArenaContract(who);
    }
    
    function _isFantasyArenaContract(address who) private view returns (bool) {
        return fantasyArenaContracts[who];
    }
    
    function _deductAllowance(address from, uint256 value) private {
        if (_isFantasyArenaContract(from)) {
            return;
        }
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    }
}