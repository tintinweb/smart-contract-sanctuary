//SourceUnit: BlackList.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./Utility.sol";

contract BlackList is Ownable {

    function getBlackListStatus(address _maker) external view returns (bool) {
        return isBlackListed[_maker];
    }

    mapping (address => bool) internal isBlackListed;

    function addBlackList (address _evilUser) public onlyOwner returns (bool) {
        isBlackListed[_evilUser] = true;
        emit AddedBlackList(_evilUser);
        return true;
    }

    function removeBlackList (address _clearedUser) public onlyOwner returns (bool) {
        isBlackListed[_clearedUser] = false;
        emit RemovedBlackList(_clearedUser);
        return true;
    }

    event AddedBlackList(address indexed _user);
    event RemovedBlackList(address indexed _user);
}

//SourceUnit: SafeMath.sol

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


//SourceUnit: Utility.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;


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
    function owner() public view returns (address) {
        return _owner;
    }


    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    //function renounceOwnership() public onlyOwner returns (bool) {
    //    emit OwnershipTransferred(_owner, address(0));
    //    _owner = address(0);
    //    return true;
    //}

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    //function transferOwnership(address newOwner) public onlyOwner returns (bool) {
    //    require(newOwner != address(0), "Ownable: new owner is the zero address");
    //    emit OwnershipTransferred(_owner, newOwner);
    //    _owner = newOwner;
    //    return true;
    //}
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
        require(!paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() onlyOwner whenNotPaused public returns (bool) {
        paused = true;
        emit Pause();
        return true;
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() onlyOwner whenPaused public returns (bool)  {
        paused = false;
        emit Unpause();
        return true;
    }
}


//SourceUnit: YYDSD.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./Utility.sol";
import "./BlackList.sol";

/**
* @title TRC20 interface
*/
interface TRC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address own, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed spender, uint256 value);
}

contract YYDSD is TRC20, Ownable, Pausable, BlackList {
    using SafeMath for uint256;

    // events
    event Mint(uint amount);
    event Burn(uint amount);
    event AdjustedFees(uint feeBasisPoints);
    event BurnFee(uint amount);
    event MiningPoolLiquify(address indexed mpAddr, uint addAmt_);
    event ChangedMPAddress(address indexed newAddr);
    event DestroyedBlackFunds(address indexed _blackListedUser, uint _balance);
    
    uint256 private constant MAX_SETTABLE_BASIS_POINTS = 500;
    uint256 private constant MAX_UINT = 2**256 - 1;

    string public name;
    string public symbol;
    uint8 public decimals;
    address public miningPoolAddress;
    uint256 public basisPointsRate = 50;

    uint256 private _totalSupply;
    uint256 private _baseSupply;
    
    mapping(address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;


    constructor() public {

        uint decimals_ = 6;
        _baseSupply = 21 * 10 ** 6 * 10 ** decimals_;          // 21 * 10**6
        _totalSupply = 2 * 10 ** 11 * 10 ** decimals_;         // 2 * 10**11

        name = "YYDSD DAO";
        symbol = "YYDSD";
        decimals = uint8(decimals_);

        _balances[_owner] = _totalSupply;

        // setMiningPoolAddress(miningPoolAddress_);
        
        emit Transfer(address(0), _owner, _totalSupply);
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

    // transfer() for fee version
    function transfer(address to_, uint value_) public override whenNotPaused returns (bool) {

        require(!isBlackListed[_msgSender()], "t1");
        require(!isBlackListed[to_], "t2");
        require(to_ != address(0), "t3");

        uint fee_ = _calcFee(value_);
        uint netArrived_ = value_.sub(fee_);

        _transfer(to_, value_, netArrived_);

        if (fee_ > 0) {
            _handleFee(_msgSender(), fee_);
        }

        return true;
    }

    // transferFrom() for fee version
    function transferFrom(address from_, address to_, uint256 value_) public override whenNotPaused returns (bool) {

        require(!isBlackListed[from_], "tf1");
        require(!isBlackListed[to_], "tf2");
        require(to_ != address(0), "tf3");

        require(value_ <= _balances[from_], "tf4");
        require(value_ <= _allowed[from_][_msgSender()], "tf5");

        uint fee_ = _calcFee(value_);
        uint netArrived_ = value_.sub(fee_);

        _balances[from_] = _balances[from_].sub(value_);
        _balances[to_] = _balances[to_].add(netArrived_);

        if (_allowed[from_][_msgSender()] < MAX_UINT) {
            _allowed[from_][_msgSender()] = _allowed[from_][_msgSender()].sub(value_);
        }

        emit Transfer(from_, to_, netArrived_);

        if (fee_ > 0) {
            _handleFee(from_, fee_);
        }

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


    // Mint a new amount of tokens
    // these tokens are deposited into the owner address
    //
    // @param _amount Number of tokens to be minted
    function mint(uint amount) public onlyOwner {

        _balances[_owner] = _balances[_owner].add(amount);
        _totalSupply = _totalSupply.add(amount);

        emit Mint(amount);
        emit Transfer(address(0), _owner, amount);
    }

    // Burn tokens.
    // These tokens are burned from this contract
    // if the balance must be enough to cover the burn
    // or the call will fail.
    // @param _amount Number of tokens to be burned
    function burn(uint amount) public onlyOwner {

        require(_totalSupply >= _baseSupply, "b1");

        uint burned_ = amount;
        if ( amount >= _balances[_owner] ) {
            burned_ = _balances[_owner];
        }
        if ((_totalSupply-burned_) < _baseSupply){
            burned_ = _totalSupply - _baseSupply;
        }
        _totalSupply = _totalSupply.sub(burned_);
        _balances[_owner] = _balances[_owner].sub(burned_);

        emit Burn(burned_);
        emit Transfer(_owner, address(0), burned_);
    }

    // 50, 10000
    function setFees(uint newBasisPoints) public onlyOwner {
        require(newBasisPoints < MAX_SETTABLE_BASIS_POINTS);
        basisPointsRate = newBasisPoints;
        emit AdjustedFees(basisPointsRate);
    }
    
    //
    function setMiningPoolAddress(address mpAddr_) public onlyOwner {

        require(mpAddr_ != address(0));

        miningPoolAddress = mpAddr_;

        emit ChangedMPAddress(mpAddr_);
    }

    
    // 
    function destroyBlackFunds(address blackListedUser_) public onlyOwner {

        require(isBlackListed[blackListedUser_]);

        uint dirtyFunds = balanceOf(blackListedUser_);

        _balances[blackListedUser_] = 0;

        if ( _totalSupply-dirtyFunds >= _baseSupply ) {
            _totalSupply = _totalSupply.sub(dirtyFunds);
        }
        else {
            _totalSupply = _baseSupply;
        }

        emit DestroyedBlackFunds(blackListedUser_, dirtyFunds);
    }

    //
    function _calcFee(uint value_) private view returns (uint) {
        uint fee_ = (value_.mul(basisPointsRate)).div(10000);
        return fee_;
    }

    function _handleFee(address from_, uint fee_) private {

        uint toBurn_ = (fee_.mul(50)).div(100);
        uint burned_ = _burnFee(toBurn_);
        uint toMiningPool_ = fee_.sub(burned_);

        if (toMiningPool_ > 0 && toMiningPool_ < fee_ && miningPoolAddress != address(0)) {
            _balances[miningPoolAddress] = _balances[miningPoolAddress].add(toMiningPool_);
            emit Transfer(address(0), miningPoolAddress, toMiningPool_);
            emit MiningPoolLiquify(miningPoolAddress, toMiningPool_);
        }
        
        emit Transfer(from_, address(0), fee_);
    }

    function _burnFee(uint fee) private returns (uint) {

        if (_totalSupply <= _baseSupply)
            return 0;

        uint _newSupply = _totalSupply.sub(fee);
        uint _burnedFee = fee;

        if (_newSupply < _baseSupply) {
            _burnedFee = _totalSupply.sub(_baseSupply);
            _newSupply = _baseSupply;
        }

        _totalSupply = _newSupply;
        emit BurnFee(_burnedFee);
        return _burnedFee;
    }

    /**
    * @dev transfer token for a specified address
    * @param to_ The address to transfer to.
    * @param amount_ The amount to be transferred.
    * @param netArrived_ The amount to be net arrived for to_.
    */
    function _transfer(address to_, uint256 amount_, uint256 netArrived_) private returns (bool) {

        require(to_ != address(0), "_t1");
        require(amount_ <= _balances[_msgSender()], "_t2");

        // SafeMath.sub will throw if there is not enough balance.
        _balances[_msgSender()] = _balances[_msgSender()].sub(amount_);
        _balances[to_] = _balances[to_].add(netArrived_);

        emit Transfer(_msgSender(), to_, netArrived_);
        return true;
    }
}