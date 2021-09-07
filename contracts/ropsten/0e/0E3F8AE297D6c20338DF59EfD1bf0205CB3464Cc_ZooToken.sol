pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT

/// @title interface of Zoo functions contract.
interface IZooFunctions {
	
	/// @notice Function for choosing winner in battle.
	/// @param votesForA - amount of votes for 1st candidate.
	/// @param votesForB - amount of votes for 2nd candidate.
	/// @param random - generated random number.
	/// @return bool - returns true if 1st candidate wins.
	function decideWins(uint votesForA, uint votesForB, uint random) external view returns (bool);

	/// @notice Function for calculcate transfer fee from Zoo token.
	/// @param amount - amount of transfer.
	/// @return fee amount.
	function computeFeeForTransfer(address from, address to, uint amount) external view returns (uint);

	/// @notice Function for calculating burn fee amount from transfer of Zoo token.
	/// @param amount - amount of transfer.
	/// @return burn fee amount.
	function computeBurnValueForTransfer(address from, address to, uint amount) external view returns (uint);

	/// @notice Function for calculating voting with Dai in vote battles.
	/// @param amount - amount of dai used for vote.
	/// @return votes - final amount of votes after calculating.
	function computeVotesByDai(uint amount) external view returns (uint);

	/// @notice Function for calculating voting with Zoo in vote battles.
	/// @param amount - amount of Zoo used for vote.
	/// @return votes - final amount of votes after calculating.
	function computeVotesByZoo(uint amount) external view returns (uint);
}

pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT

import "./IZooFunctions.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Contract ZooGovernance.
/// @notice Contract for Zoo Dao vote proposals.
contract ZooGovernance is Ownable {

	using SafeMath for uint;
	
	struct Voting
	{
		uint startDate;
		uint votesFor;
		uint votesAgainst;
		bool isUsed;
	}

	address public zooFunctions;                    // Address of contract with Zoo functions.
	IERC20 public zooToken;

	uint public quorum = 10 ** 6 * 18;              // 1 m of zoo as quorum.
	uint public votingDuration = 14 days;           // Duration of vote proposal.
	mapping (address => Voting) public votings;
	mapping (address => mapping (address => uint)) public locked;

	/// @notice Contract constructor.
	constructor (address _zoo)
	{
		zooToken = IERC20(_zoo);
	}

	/// @notice Function to set default zoo functions contract.
	/// @param baseZooFunctions - address of deployed BaseZooFunctions contract.
	function init(address baseZooFunctions) external onlyOwner {

		zooFunctions = baseZooFunctions;

		renounceOwnership();            // Sets owner to zero address.
	}

    /// @notice Function for vote for changing Zoo fuctions.
    /// @param newZooFunctions - address of new Zoo functions contract.
    /// @param value - amount of votes.
    /// @param isFor - bool for voting for or against.
	function changeZooFunctionsContract(address newZooFunctions, uint value, bool isFor) external
	{
		require(votings[newZooFunctions].startDate + votingDuration < block.timestamp);

		zooToken.transferFrom(msg.sender, address(this), value);

		if (isFor)
		{
			votings[newZooFunctions].votesFor += value;
		}
		else
		{
			votings[newZooFunctions].votesAgainst += value;
		}

		locked[msg.sender][newZooFunctions] += value;
	}
    
    /// @notice Function - for unlocking Zoo tokens used in votes.
    /// @param zooFunctionsContract - address of Zoo functions contract.
	function unlock(address zooFunctionsContract) external
	{
		require(votings[zooFunctionsContract].startDate + votingDuration > block.timestamp);

		zooToken.transfer(msg.sender, locked[msg.sender][zooFunctionsContract]);
		locked[msg.sender][zooFunctionsContract] = 0;
	}

    /// @notice Function for calculating result of vote.
    /// @param zooFunctionsContract - address of Zoo functions contract.
	function tryToWin(address zooFunctionsContract) external
	{
		require(!votings[zooFunctionsContract].isUsed);
		uint votesFor = votings[zooFunctionsContract].votesFor;
		uint votesAgainst = votings[zooFunctionsContract].votesAgainst;

		uint totalVoted = votesFor + votesAgainst;
		require(totalVoted > quorum);

		require(3 * votesFor > totalVoted * 2);

		votings[zooFunctionsContract].isUsed = true;
		zooFunctions = zooFunctionsContract;
	}
}

pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IZooFunctions.sol";
import "./ZooGovernance.sol";

/// @title Zoo token contract
/// @notice Based on the ERC-20 token standard as defined at https://eips.ethereum.org/EIPS/eip-20
/// @notice Added burn and redistribution from transfers to YieldFarm.
contract ZooToken is Ownable {

    using SafeMath for uint256;

    string public name;                                         // Contract name.
    string public symbol;                                       // Contract symbol.
    uint256 public decimals;                                    // Token decimals.
    uint256 public totalSupply;                                 // Token total supply.
    address public yieldFarm;                                   // Address of yield farm contract.

    ZooGovernance public zooGovernance;                         // Governance contract.

    mapping(address => uint256) balances;                       // Records balances.
    mapping(address => mapping(address => uint256)) allowed;    // Records allowances for tokens.

    /// @notice Event records info about transfers.
    /// @param from - address sender.
    /// @param to - address recipient.
    /// @param value - amount of tokens transfered.
    event Transfer(address from, address to, uint256 value);

    /// @notice Event records info about approved tokens.
    /// @param owner - address owner of tokens.
    /// @param spender - address spender of tokens.
    /// @param value - amount of tokens allowed to spend.
    event Approval(address owner, address spender, uint256 value);

    /// @notice Event records address of initiated governance contract.
    /// @param ZooGovernance - address of governance contract.
    event Inited(address ZooGovernance);

    /// @notice Contract constructor.
    /// @param _name - name of token.
    /// @param _symbol - symbol of token.
    /// @param _decimals - token decimals.
    /// @param _totalSupply - total supply amount.
    /// @param _yieldFarm - address of contract for yield farming with Zoo.
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _decimals,
        uint256 _totalSupply,
        address _yieldFarm
    )
    {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        yieldFarm = _yieldFarm;
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    /// @notice Function to initiate address of governance contract.
    /// @param _zooGovernance - address of zoo governance contract.
    function init(address _zooGovernance) external onlyOwner
    {
        zooGovernance = ZooGovernance(_zooGovernance);

        renounceOwnership();            // Sets owner to zero address.

        emit Inited(_zooGovernance);                // Records governance address to event.
    }
    
    /// @notice Function to check the current balance of an address.
    /// @param _owner Address of owner.
    /// @return Balances of owner.
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    /// @notice Function to check the amount of tokens that an owner allowed to a spender.
    /// @param _owner The address which owns the funds.
    /// @param _spender The address which will spend the funds.
    /// @return The amount of tokens available for the spender.
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

    /// @notice Function to approve an address to spend the specified amount of msg.sender's tokens.
    /// @param _spender The address which will spend the tokens.
    /// @param _value The amount of tokens allowed to be spent.
    /// @return Success boolean.
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);        // Records in Approval event.

        return true;
    }

    /// @param _from - sender of tokens.
    /// @param _to - recipient of tokens.
    /// @param _value - amount of transfer.
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(balances[_from] >= _value, "Insufficient balance"); // Requires balance to be sufficient enough for transfer.
        balances[_from] = balances[_from].sub(_value);              // Decreases balances of sender.
        balances[_to] = balances[_to].add(_value);                  // Increases balances of recipient.
        
        IZooFunctions zooFunctions = IZooFunctions(zooGovernance.zooFunctions());      // Calls ZooFunctions contracts.
        uint burnValue = zooFunctions.computeBurnValueForTransfer(_from, _to, _value); // Sets burn value.
        burnFrom(_to, burnValue);                                   // Burns % of tokens from transfered amount, currently burns 0.15%.
        
        uint fee = zooFunctions.computeFeeForTransfer(_from, _to, _value);             // Sets amount of fee.
        balances[_to] = balances[_to].sub(fee);                                        // Decreases amount of token sended for fee amount.
        balances[yieldFarm] = balances[yieldFarm].add(fee);                            // Increases balances of YieldFarm for fee amount.

        // old fee:
        //burnFrom(_to, _value.mul(15).div(10000));                 // Decreases amount of token sended for burn amount, currently burns 0.15%.
        //uint256 basisPointToReward = 30;                          // Sets basis points amount.
        //uint256 fee = _value.mul(basisPointToReward).div(10000);  // Calculates fee amount.
        //balances[_to] = balances[_to].sub(fee);                   // Decreases amount of token sended for fee amount.
        //balances[yieldFarm] = balances[yieldFarm].add(fee);       // Increases balances of YieldFarm for fee amount.

        emit Transfer(_from, _to, _value);                          // Records transfer to Transfer event.
        emit Transfer(_from, yieldFarm, fee);                       // Records fee to Transfer event.
    }

    /// @notice Function for burning tokens.
    /// @param amount - amount of tokens to burn.
     function burn(uint256 amount) public {        
        burnFrom(msg.sender, amount);
    }

    /// @param from - Address of token owner.
    /// @param amount - Amount of tokens to burn.
    function burnFrom(address from, uint256 amount) internal {
        require(balances[from] >= amount, "ERC20: burn amount exceeds balance"); // Requires balance to be sufficient enough for burn.

        balances[from] = balances[from].sub(amount);                             // Decreases balances of owner for burn amount.
        totalSupply = totalSupply.sub(amount);                                   // Decreases total supply of tokens for amount.

        emit Transfer(from, address(0), amount);                                 // Records to Transfer event.
    }

    /// @notice Function for transfering tokens to a specified address.
    /// @param _to The address of recipient.
    /// @param _value The amount of tokens to be transfered.
    /// @return Success boolean.
    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /// @notice Function for transfering tokens from one specified address to another.
    /// @param _from The address which you want to send tokens from.
    /// @param _to The address recipient.
    /// @param _value The amount of tokens to be transfered.
    /// @return Success boolean.
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        public
        returns (bool)
    {
        require(allowed[_from][msg.sender] >= _value, "Insufficient allowance"); // Requires allowance for sufficient amount of tokens to send.
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);     // Decreases amount of allowed tokens for sended value.

        _transfer(_from, _to, _value);                                           // Calls _transfer function.
        return true;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../GSN/Context.sol";
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

// SPDX-License-Identifier: MIT

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}