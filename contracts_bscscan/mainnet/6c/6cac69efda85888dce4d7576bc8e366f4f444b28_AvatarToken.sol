/**
 *Submitted for verification at BscScan.com on 2022-01-12
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


/*
    @dev Context, Owner, Pausable
    
*/


/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// 
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    //function owner() public view returns (address) {
    //    return _owner;
    //}


    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "not owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
       emit OwnershipTransferred(_owner, address(0));
       _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
       require(newOwner != address(0), "zero address");
       emit OwnershipTransferred(_owner, newOwner);
       _owner = newOwner;
    }
}


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    
    //
    event Pause();
    event Unpause();

    bool public paused = false;


    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused, "paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused, "not paused");
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}




/**
* @title IBEP20 interface
*/
interface IBEP20 {

    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// Avatar Token
contract AvatarToken is Context, IBEP20, Ownable, Pausable {
    using SafeMath for uint256;

    // for tech
    struct TechInfo {
        uint launchTs;
        uint unlockPerYear;
        uint totalBal;
        uint unlockBal;
        address addr;
    }

    // events
    event AdjustBurnFeeRate(uint feeBasisPoints);
    event SetTechAddress(address indexed newAddr);
    event ExcludedFee(address account, bool bYes);

    uint256 private constant MAX_BURN_FEE_RATE_PER_TX = 500;  // The maximum fee cannot exceed 5%
    uint256 private constant MAX_UINT = 2**256 - 1;
    int private constant MAX_TECH_LOCK_YEARS = 8;
    uint256 private constant SECONDS_PER_DAY = 24 * 60 * 60;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    
    uint256 private _totalSupply;
    uint256 private _baseSupply;
    uint256 private _burnFeeRatePerTx = 20;

    mapping(address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;

    mapping (address => bool) private _excludedFees;

    // tech stake
    TechInfo public techInfo;

    //
    constructor() public {

        uint decimals_ = 18;
        _totalSupply = 3 * 10 ** 8 * 10 ** decimals_;                                   // 3 * 10**8
        _baseSupply = 3 * 10 ** 7 * 10 ** decimals_;                                    // 3 * 10**7

        // for tech
        techInfo.totalBal = _totalSupply.mul(12).div(100);                              // 12% shares for tech
        techInfo.unlockPerYear = techInfo.totalBal.mul(12).div(100);                    // 12% per year before the eighth year

        _name = "Avatar Token";
        _symbol = "ATAR";
        _decimals = uint8(decimals_);
        techInfo.launchTs = now;

        //exclude owner and this contract from fee
        _excludedFees[_msgSender()] = true;
        _excludedFees[address(this)] = true;

        // mint total Supply
        _balances[_owner] = _totalSupply;
        emit Transfer(address(0), _owner, _totalSupply);

        // 12% assigned to technology
        _balances[_owner] = _balances[_owner].sub(techInfo.totalBal);

        // The tech part is temporarily held by contract
        _balances[address(this)] = _balances[address(this)].add(techInfo.totalBal);
        emit Transfer(_owner, address(this), techInfo.totalBal);
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param user_ The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address user_) public override view returns (uint256) {
        return _balances[user_];
    }

    function totalSupply() public override view returns (uint) {
        return _totalSupply;
    }

    function baseSupply() public view returns (uint) {
        return _baseSupply;
    }

   /**
    * @dev Returns the bep token owner.
    */
    function getOwner() public override view returns (address) {
        return _owner;
    }

    /**
    * @dev Returns the token _decimals.
    */
    function decimals() public override view returns (uint8) {
        return _decimals;
    }

    /**
    * @dev Returns the token _symbol.
    */
    function symbol() public override view returns (string memory) {
        return _symbol;
    }

    /**
    * @dev Returns the token _name.
    */
    function name() public override view returns (string memory) {
        return _name;
    }

    //
    function setTechAddress(address addr_) public onlyOwner {
        require(addr_ != address(0));
        techInfo.addr = addr_;
        emit SetTechAddress(addr_);
    }

    // extract part of the tech
    function extractTech() public returns (bool) {

        require(techInfo.addr != address(0), "et1");
        require(techInfo.totalBal > techInfo.unlockBal, "et2");
        require(_balances[address(this)] > 0, "et3");

        uint _elapsed = 0;
        int _days = int((now - techInfo.launchTs) / SECONDS_PER_DAY);
        int _years = int(_days / 365);
        if ( _years < MAX_TECH_LOCK_YEARS ) {
            _elapsed = uint(_years) * techInfo.unlockPerYear;
        }
        else {
            _elapsed = techInfo.totalBal;
        }

        require(techInfo.unlockBal < _elapsed, "et5");

        uint _expect = _elapsed.sub(techInfo.unlockBal);
        techInfo.unlockBal = techInfo.unlockBal.add(_expect);

        _transferFrom(address(this), techInfo.addr, _expect, _expect);
        return true;
    }

    // transfer
    function transfer(address to_, uint value_) public override whenNotPaused returns (bool) {
        return _transferFromByBurnVer(_msgSender(), to_, value_);
    }

    // transferFrom
    function transferFrom(address from_, address to_, uint256 value_) public override whenNotPaused returns (bool) {
        require(value_ <= _allowed[from_][_msgSender()], "tf1");
        _transferFromByBurnVer(from_, to_, value_);
        if (_allowed[from_][_msgSender()] < MAX_UINT) {
            _allowed[from_][_msgSender()] = _allowed[from_][_msgSender()].sub(value_);
        }
        return true;
    }

    //
    function _transferFromByBurnVer(address from_, address to_, uint value_) internal returns (bool) {
        uint netArrived_ = value_;
        if ( !_excludedFees[from_] ) {
            uint fee_ = _calcFee(value_);
            if (fee_ > 0) {
                fee_ = _burnFee(from_, fee_);
            }
            netArrived_ = value_.sub(fee_);
        }
        _transferFrom(from_, to_, value_, netArrived_);
        return true;
    }

    /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of _msgSender().
    *
    * Beware that changing an allowance with this method brings the risk that someone may use both the old
    * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
    * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
    * @param spender_ The address which will spend the funds.
    * @param value_ The amount of tokens to be spent.
    */
    function approve(address spender_, uint256 value_) public override returns (bool) {
        require(spender_ != address(0), "a1");
        _allowed[_msgSender()][spender_] = value_;
        emit Approval(_msgSender(), spender_, value_);
        return true;
    }

    /**
    * @dev Function to check the amount of tokens that an own _allowed to a spender.
    * @param own_ address The address which owns the funds.
    * @param spender_ address The address which will spend the funds.
    * @return A uint256 specifying the amount of tokens still available for the spender.
    */
    function allowance(address own_, address spender_) public override view returns (uint256) {
        return _allowed[own_][spender_];
    }

    /**
    * approve should be called when _allowed[spender_] == 0. To increment
    * _allowed value is better to use this function to avoid 2 calls (and wait until
    * the first transaction is mined)
    * From MonolithDAO Token.sol
    */
    function increaseApproval(address spender_, uint addedValue_) public returns (bool) {
        _allowed[_msgSender()][spender_] = _allowed[_msgSender()][spender_].add(addedValue_);
        emit Approval(_msgSender(), spender_, _allowed[_msgSender()][spender_]);
        return true;
    }

    function decreaseApproval(address spender_, uint subtractedValue_) public returns (bool) {
        uint oldValue = _allowed[_msgSender()][spender_];
        if (subtractedValue_ > oldValue) {
            _allowed[_msgSender()][spender_] = 0;
        } else {
            _allowed[_msgSender()][spender_] = oldValue.sub(subtractedValue_);
        }
        emit Approval(_msgSender(), spender_, _allowed[_msgSender()][spender_]);
        return true;
    }

    // Mint a new amount_ of tokens
    // these tokens are deposited into the owner address
    //
    // @param _amount Number of tokens to be minted
    function mint(uint amount_) public onlyOwner {
        _balances[_owner] = _balances[_owner].add(amount_);
        _totalSupply = _totalSupply.add(amount_);
        emit Transfer(address(0), _owner, amount_);
    }

    // Burn tokens.
    // These tokens are burned from this contract
    // if the balance must be enough to cover the burn
    // or the call will fail.
    // @param _amount Number of tokens to be burned
    function burn(uint amount_) public onlyOwner {
        require(_totalSupply >= _baseSupply, "b1");
        require(amount_ < _totalSupply, "b2");
        require(amount_ < _balances[_owner], "b3");
        uint burned_ = amount_;
        if ( amount_ >= _balances[_owner] ) {
            burned_ = _balances[_owner];
        }
        if ((_totalSupply-burned_) < _baseSupply){
            burned_ = _totalSupply - _baseSupply;
        }
        _totalSupply = _totalSupply.sub(burned_);
        _balances[_owner] = _balances[_owner].sub(burned_);
        emit Transfer(_owner, address(0), burned_);
    }

    // 20, 10000
    function setBurnFeeRatePerTx(uint newRate_) public onlyOwner {
        require(newRate_ < MAX_BURN_FEE_RATE_PER_TX);
        _burnFeeRatePerTx = newRate_;
        emit AdjustBurnFeeRate(_burnFeeRatePerTx);
    }

    function getBurnFeeRatePerTx() public view returns (uint) {
        return _burnFeeRatePerTx;
    }

    function _calcFee(uint value_) private view returns (uint) {
        uint fee_ = (value_.mul(_burnFeeRatePerTx)).div(10000);
        return fee_;
    }

    function excludeFee(address account) external onlyOwner {
        _excludedFees[account] = true;
        emit ExcludedFee(account, true);
    }
    
    function includeFee(address account) external onlyOwner {
        _excludedFees[account] = false;
        emit ExcludedFee(account, false);
    }

    function isExcludedFee(address account) external view returns(bool) {
        return _excludedFees[account];
    }

    function _burnFee(address from_, uint fee_) private returns (uint) {

        if (_totalSupply <= _baseSupply)
            return 0;

        // total supply
        uint burnedFee_ = fee_;
        uint _newSupply = _totalSupply.sub(fee_);
        if (_newSupply < _baseSupply) {
            _newSupply = _baseSupply;
            burnedFee_ = _totalSupply.sub(_baseSupply);
        }
        _totalSupply = _newSupply;

        emit Transfer(from_, address(0), burnedFee_);
        return burnedFee_;
    }

    /**
    * @dev transfer token for a specified address
    * @param from_ The address to transfer from.
    * @param to_ The address to transfer to.
    * @param amount_ The amount to be transferred.
    * @param netArrived_ The amount to be net arrived for to_.
    */
    function _transferFrom(address from_, address to_, uint256 amount_, uint256 netArrived_) private returns (bool) {

        require(to_ != address(0), "_t1");
        require(amount_ <= _balances[from_], "_t2");

        // SafeMath.sub will throw if there is not enough balance.
        _balances[from_] = _balances[from_].sub(amount_);
        _balances[to_] = _balances[to_].add(netArrived_);

        emit Transfer(from_, to_, netArrived_);
        return true;
    }
}