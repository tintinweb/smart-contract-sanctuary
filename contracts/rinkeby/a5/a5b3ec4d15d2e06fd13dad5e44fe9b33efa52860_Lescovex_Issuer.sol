/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

// File: @openzeppelin/contracts/math/SafeMath.sol

/*
    SPDX-License-Identifier: 
    Copyright 2018, Vicent Nos, Enrique Santos & Mireia Puig

    License:
    https://creativecommons.org/licenses/by-nc-nd/4.0/legalcode

 */

pragma solidity ^0.7.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


pragma solidity ^0.7.0;

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/TokenRecipient.sol

pragma solidity ^0.7.6;

/*
    Copyright 2018, Vicent Nos, Enrique Santos & Mireia Puig
    
    License:
    https://creativecommons.org/licenses/by-nc-nd/4.0/legalcode

 */
interface TokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes memory _extraData) external ;
}

// File: contracts/LCX_ABT.sol

pragma solidity ^0.7.6;


contract Lescovex_ABT is Ownable {
    using SafeMath for uint256;
    // constant to simplify conversion of token amounts into integer form
    uint256 public tokenUnit = uint256(10)**decimals;

    mapping (address => uint256) public balances;

    mapping (address => uint256) public requestWithdraws;

    mapping (address => mapping (address => uint256)) internal allowed;

    mapping (address => timeHold) holded;

    struct timeHold{
        uint256[] amount;
        uint256[] time;
        uint256 length;
    }

    /* Public variables for the ERC20 token */
    string public constant standard = "ERC20 Lescovex ABT";
    uint8 public constant decimals = 8; // hardcoded to be a constant
    uint256 public totalSupply;
    string public name;
    string public symbol;
    string public description;
    uint256 public degradationTime;
    string public BCA;

    //Declare logging events
    event LogDeposit(address sender, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor(
        address _owner,
        string memory _name,
        string memory _symbol,
        string memory _description,
        string memory _BCA,
        uint256 _degradationTime,
        uint256 _initialSupply
    ) {
        totalSupply = _initialSupply; // Update total supply
        name = _name; // Set the name for display purposes
        symbol = _symbol; // Set the symbol for display purposes
        description = _description;
        //Set degradation time in case it has one different than 0.
        if (_degradationTime != 0) {
            degradationTime = block.timestamp.add(_degradationTime);
        } else {
            _degradationTime = 0;
        }
        transferOwnership(_owner);
        balances[_owner] = balances[_owner].add(totalSupply);
        BCA = _BCA;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }


    function transfer(address _to, uint256 _value) public returns (bool) {

        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);


        balances[_to] = balances[_to].add(_value);

        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);

        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /* Approve and then communicate the approved contract in a single tx */
    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) public returns (bool success) {
        TokenRecipient spender = TokenRecipient(_spender);

        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
            return true;
        }
    }
}

// File: contracts/LCX_CYC.sol

pragma solidity ^0.7.6;


contract Lescovex_CYC is Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) public balances;

    mapping(address => mapping(address => uint256)) internal allowed;

    /* Public variables for the ERC20 token */
    string public constant standard = "ERC20 Lescovex CYC";
    uint8 public constant decimals = 18; // hardcoded to be a constant
    uint256 public totalSupply;
    uint256 public degradationTime;
    string public name;
    string public symbol;
    string public description;

    //constant to simplify conversion of token amounts into integer form
    uint256 public tokenUnit = uint256(10)**decimals;

    //Declare logging events
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event LogDeposit(address sender, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor(
        address _owner,
        string memory _name,
        string memory _symbol,
        string memory _description,
        uint256 _degradationTime,
        uint256 _initialSupply
    ) {
        totalSupply = _initialSupply; // Update total supply
        name = _name; // Set the name for display purposes
        symbol = _symbol; // Set the symbol for display purposes
        description = _description;
        //Set degradation time in case it has one different than 0.
        if (_degradationTime != 0) {
            degradationTime = block.timestamp.add(_degradationTime);
        } else {
            _degradationTime = 0;
        }
        transferOwnership(_owner);
        balances[_owner] = balances[_owner].add(totalSupply);
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value)
        public
        returns (bool)
    {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);

        balances[_to] = balances[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);

        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value)
        public
        returns (bool)
    {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

    function increaseApproval(address _spender, uint256 _addedValue)
        public
        returns (bool)
    {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(
            _addedValue
        );
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint256 _subtractedValue)
        public
        returns (bool)
    {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /* Approve and then communicate the approved contract in a single tx */
    function approveAndCall(
        address _spender,
        uint256 _value,
        bytes memory _extraData
    ) public returns (bool success) {
        TokenRecipient spender = TokenRecipient(_spender);

        if (approve(_spender, _value)) {
            spender.receiveApproval(
                msg.sender,
                _value,
                address(this),
                _extraData
            );
            return true;
        }
    }
}

// File: contracts/LCX_ISC.sol

pragma solidity ^0.7.6;

contract Lescovex_ISC is Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) public balances;

    mapping (address => mapping (address => uint256)) internal allowed;

    mapping (address => timeHold) holded;

    struct timeHold{
        uint256[] amount;
        uint256[] time;
        uint256 length;
    }

    /* Public variables for the ERC20 token */
    string public constant standard = "ERC20 Lescovex ISC Income Smart Contract";
    uint8 public constant decimals = 8; // hardcoded to be a constant
    uint256 public holdMax = 100;
    uint256 public totalSupply;
    uint256 public holdTime;
    uint256 public degradationTime;
    string public name;
    string public symbol;
    string public description;

    //Declare logging events
    event LogDeposit(address sender, uint256 amount);
    event LogWithdrawal(address receiver, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    address contractAddr = address(this);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor(
        address _owner,
        string memory _name,
        string memory _symbol,
        string memory _description,
        uint256 _initialSupply,
        uint256 _degradationTime,
        uint256 _holdTime
    ) {
        totalSupply = _initialSupply; // Update total supply
        name = _name; // Set the name for display purposes
        symbol = _symbol; // Set the symbol for display purposes
        holdTime = _holdTime;
        description = _description;
        //Set degradation time in case it has one different than 0.
        if (_degradationTime != 0) {
            degradationTime = block.timestamp.add(_degradationTime);
        } else {
            _degradationTime = 0;
        }
        transferOwnership(_owner);
        balances[_owner] = balances[_owner].add(totalSupply);
    }

    function deposit() external payable onlyOwner returns (bool success) {
        //executes event to reflect the changes
        emit LogDeposit(msg.sender, msg.value);

        return true;
    }

    function withdrawReward() external {
        uint256 ethAmount =
            (holdedOf(msg.sender) * contractAddr.balance) / totalSupply;

        require(ethAmount > 0);

        //executes event to register the changes
        emit LogWithdrawal(msg.sender, ethAmount);

        delete holded[msg.sender];
        hold(msg.sender, balances[msg.sender]);
        //send eth to owner address
        msg.sender.transfer(ethAmount);
    }

    function withdraw(uint256 value) external onlyOwner {
        //send eth to owner address
        msg.sender.transfer(value);
        //executes event to register the changes
        emit LogWithdrawal(msg.sender, value);
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    //function created for testing reasons
    function holdedControl(address _owner) public view returns (uint256) {
        uint256 len = holded[_owner].length;
        return holded[_owner].amount[len-1];
    }
    //function created for testing reasons
    function holdedLength(address _owner) public view returns(uint256){
      uint256 len = holded[_owner].length;
      return len;
    }

    function holdedOf(address _owner) public view returns (uint256) {
        // Returns the valid holded amount of _owner (see function hold),
        // where valid means that the amount is holded more than requiredTime
        uint256 requiredTime = block.timestamp - holdTime;

        // Check of the initial values for the search loop.
        uint256 iValid = 0;                         // low index in test range
        uint256 iNotValid = holded[_owner].length;  // high index in test range
        if (iNotValid == 0                          // empty array of holds
        || holded[_owner].time[iValid] >= requiredTime) { // not any valid holds
            return 0;
        }

        // Binary search of the highest index with a valid hold time
        uint256 i = iNotValid / 2;  // index of pivot element to test
        while (i > iValid) {  // while there is a higher one valid
            if (holded[_owner].time[i] < requiredTime) {
                iValid = i;   // valid hold
            } else {
                iNotValid = i; // not valid hold
            }
            i = (iNotValid + iValid) / 2;
        }
        return holded[_owner].amount[iValid];
    }

    function hold(address _to, uint256 _value) internal {
        require(holded[_to].length < holdMax);
        // holded[_owner].amount[] is the accumulated sum of holded amounts,
        // sorted from oldest to newest.
        uint256 len = holded[_to].length;
        uint256 accumulatedValue = (len == 0 ) ?
            _value :
            _value + holded[_to].amount[len - 1];

        // records the accumulated holded amount
        holded[_to].amount.push(accumulatedValue);
        holded[_to].time.push(block.timestamp);
        holded[_to].length++;
    }

    function setHoldTime(uint256 _value) external onlyOwner{
      holdTime = _value;
    }

    function setHoldMax(uint256 _value) external onlyOwner{
      holdMax = _value;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);

        delete holded[msg.sender];
        hold(msg.sender,balances[msg.sender]);
        hold(_to,_value);

        balances[_to] = balances[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

        delete holded[_from];
        hold(_from,balances[_from]);
        hold(_to,_value);

        balances[_to] = balances[_to].add(_value);

        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /* Approve and then communicate the approved contract in a single tx */
    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) public returns (bool success) {
        TokenRecipient spender = TokenRecipient(_spender);

        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
            return true;
        }
    }
}

// File: contracts/LCX_Issuer.sol

pragma solidity ^0.7.6;

contract Lescovex_Issuer {
    /******************
    EVENTS
    ******************/
    event TokenCreated(
        string tokenType,
        address indexed tokenAddress,
        address indexed wallet
    );

    /******************
    PUBLIC FUNCTIONS
    ******************/
    function createABTToken(
        string memory _name,
        string memory _symbol,
        string memory _description,
        string memory _bca,
        uint256 _initialSupply,
        uint256 _degradationTime
    ) public returns (Lescovex_ABT) {
        Lescovex_ABT token =
            new Lescovex_ABT(
                msg.sender,
                _name,
                _symbol,
                _description,
                _bca,
                _degradationTime,
                _initialSupply
            );
        emit TokenCreated("ABT", address(token), msg.sender);
        return token;
    }

    function createISCToken(
        string memory _name,
        string memory _symbol,
        string memory _description,
        uint256 _initialSupply,
        uint256 _degradationTime,
        uint256 _holdTime
    ) public returns (Lescovex_ISC) {
        Lescovex_ISC token =
            new Lescovex_ISC(
                msg.sender,
                _name,
                _symbol,
                _description,
                _initialSupply,
                _degradationTime,
                _holdTime
            );
        emit TokenCreated("ISC", address(token), msg.sender);
        return token;
    }

    function createCYCToken(
        string memory _name,
        string memory _symbol,
        string memory _description,
        uint256 _degradationTime,
        uint256 _initialSupply
    ) public returns (Lescovex_CYC) {
        Lescovex_CYC token =
            new Lescovex_CYC(
                msg.sender,
                _name,
                _symbol,
                _description,
                _degradationTime,
                _initialSupply
            );
        emit TokenCreated("CYC", address(token), msg.sender);
        return token;
    }
}