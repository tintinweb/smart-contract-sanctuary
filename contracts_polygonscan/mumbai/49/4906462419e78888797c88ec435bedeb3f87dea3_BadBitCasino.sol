/**
 *Submitted for verification at polygonscan.com on 2021-07-12
*/

// File: original_contracts/Utils/IOracleProvider.sol

pragma solidity 0.5.17;


interface IOracleProvider {

    enum DATASOURCE {_, RANDOM_GAMBLING, RANDOM_NON_GAMBLING, DELAY}

    function isWhitelisted(address account) external view returns(bool);

    function delayQuery(
        uint256 delay,
        uint256 gasLimit
    )
        external
        returns(bytes32);

    function randomNumberQueryGambling(
        uint256 nBytes,
        uint256 value,
        uint256 customGasLimit
    )
        external
        returns(bytes32);

    function randomNumberQueryNonGambling(
        uint256 nBytes,
        uint256 customGasLimit
    )
        external
        returns(bytes32);

    function isCbAddress(address account) external view returns(bool);

    //This is for backward compatibility with provable
    function getPrice(
        DATASOURCE datasource,
        bytes32 data
    )
        external
        view
        returns(uint256);
}

// File: original_contracts/Utils/IOracleUser.sol

pragma solidity 0.5.17;


interface IOracleUser {

    function callback(bytes32 myid, string calldata result) external;
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

// File: original_contracts/Utils/ITokenTransferProxy.sol

pragma solidity 0.5.17;


interface ITokenTransferProxy {
    function transferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    )
        external;
}

// File: openzeppelin-solidity/contracts/utils/Address.sol

pragma solidity ^0.5.5;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.5.0;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: original_contracts/Global/GameInterface.sol

pragma solidity ^0.5.0;


contract GameInterface {

    uint public commissionEarned;
    uint public totalFundsLostByPlayers;

    function finalizeBet(address _user, uint _betId) public returns(uint profit, uint totalWon);
    function canFinalizeBet(address _user, uint _betId) public view returns (bool success);
    function getUserProfitForFinishedBet(address _user, uint _betId) public view returns(uint);
    function getTotalBets(address _user) public view returns(uint);
    function getPossibleWinnings(uint _chance, uint _amount) public view returns(uint);
    function getBetInfo(address _user, uint _betId) public view returns(uint amount, bool finalized, bool won, bool bonus);
    function emergencyWithdraw(address _sender) public;
    function getMaxWinnableAmount() public view returns(uint256);
    function validatePayload(bytes calldata payload) external view returns(bool);
}

// File: original_contracts/Global/IBadBitSettings.sol

pragma solidity 0.5.17;


interface IBadBitSettings {

    function isGameAddress(address game) external view returns(bool);

    function isOperatorAddress(address operator) external view returns(bool);

    function BETS_ALLOWED() external view returns(bool);

    function BIG_WIN_THRESHOLD() external view returns(uint256);

    function ORACLIZE_GAS_LIMIT() external view returns(uint256);

    function USE_BLOCKHASH_RANDOM_SEED() external view returns(bool);

    function AFFILIATE_REWARD_PERCENTAGE() external view returns(uint256);

    function HOUSE_EDGE() external view returns(uint256);

    function tokenWinChanceRewardForLevel(uint256 index) external view returns(uint256);

    function bonusBalanceRewardForLevel(uint256 index) external view returns(uint256);

    function SWEEPSTAKES_COMMISSION() external view returns(uint256);

    function deployer() external view returns(address);

    function getGames() external view returns(address[] memory);
}

// File: original_contracts/Global/IBadBitCasino.sol

pragma solidity ^0.5.0;

contract IBadBitCasino {
    function add(address _user, uint _amount) external returns(bool);
	function placeBet(address _user, uint _betId, uint _amount, bool bonus) public;
	function getCurrentBalance(address _user) public view returns(uint);
	function sendEthToGame(uint _amount) public;
	function _finalizeLastBets(address _user) public;
	function getExtraTokenWinChanceForPlayer(address _user) public view returns (uint);
}

// File: original_contracts/Token/IBadBitDistributor.sol

pragma solidity ^0.5.0;

contract IBadBitDistributor{
	function sendTokens(address _user, uint _amount) public;
	function getStandardLot() public view returns(uint);
	function shouldWinTokens(bytes32 _hash, address _user, uint betSize, uint[] memory _chances) public view returns (bool);
	function winTokens(address _user) public;
}

// File: original_contracts/Utils/EIP712Base.sol

pragma solidity 0.5.17;


contract EIP712Base {

    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    bytes32 private constant EIP712_DOMAIN_TYPEHASH = keccak256(bytes("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"));

    bytes32 private domainSeperator;

    constructor(string memory name, string memory version, uint256 chainid) public {
      
      domainSeperator = keccak256(abi.encode(
			  EIP712_DOMAIN_TYPEHASH,
			  keccak256(bytes(name)),
			  keccak256(bytes(version)),
			  chainid,
			  address(this)
		  ));
    }

    /**
    * Accept message hash and returns hash message in EIP712 compatible form
    * So that it can be used to recover signer from signature signed using EIP712 formatted data
    * https://eips.ethereum.org/EIPS/eip-712
    * "\\x19" makes the encoding deterministic
    * "\\x01" is the version byte to make it compatible to EIP-191
    */
    function toTypedMessageHash(bytes32 messageHash) internal view returns(bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeperator, messageHash));
    }

}

// File: original_contracts/Utils/EIP712MetaTransaction.sol

pragma solidity 0.5.17;



contract EIP712MetaTransaction is EIP712Base {
    using SafeMath for uint256;
    bytes32 private constant META_TRANSACTION_TYPEHASH = keccak256(
        bytes(
            "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
        )
    );

    event MetaTransactionExecuted(
        address userAddress,
        address payable relayerAddress,
        bytes functionSignature
    );
    mapping(address => uint256) nonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    constructor(string memory name, string memory version, uint256 chainid)
        public
        EIP712Base(name, version, chainid)
    {}

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable returns (bytes memory) {
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });
        require(
            verify(userAddress, metaTx, sigR, sigS, sigV),
            "Signer and signature do not match"
        );
        // Append userAddress and relayer address at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );

        require(success, "Function call not successfull");
        nonces[userAddress] = nonces[userAddress].add(1);
        emit MetaTransactionExecuted(
            userAddress,
            msg.sender,
            functionSignature
        );
        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    META_TRANSACTION_TYPEHASH,
                    metaTx.nonce,
                    metaTx.from,
                    keccak256(metaTx.functionSignature)
                )
            );
    }

    function getNonce(address user) public view returns (uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(
        address signer,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        return
            signer ==
            ecrecover(
                toTypedMessageHash(hashMetaTransaction(metaTx)),
                sigV,
                sigR,
                sigS
            );
    }

    function _msgSender() internal view returns (address payable sender) {
        if(msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }
}

// File: original_contracts/Global/BadBitWallet.sol

pragma solidity ^0.5.0;










contract BadBitWallet is EIP712MetaTransaction {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct Withdrawal {
        uint withdrawalTimestamp;
        uint amount;
    }

    /**
    * @dev All user addresses that have had at least one bet in any of the games
    */
    address[] public users;
    /**
    * @dev Balances for each user address
    */
    mapping(address => uint) public userBalances;
    /**
    * @dev Bonus balances for each user address
    */
    mapping(address => uint) public userBonusBalances;
    /**
    * @dev All user withdrawals
    */
    mapping(address => Withdrawal[]) public userWithdrawals;
    /**
    * @dev Total contract balance belonging to the users
    */
    uint public totalPlayerBalances;
    /**
    * @dev All funds sent directly to the wallet contract
    */
    uint public totalFundsSentByOwner;

    //Address of WETH Token
    IERC20 public weth;

    IBadBitSettings public settings;
    IBadBitDistributor public distributor;
    ITokenTransferProxy public tokenProxy;

    event UserWithdrawal(address indexed user, uint indexed timestamp);

    modifier onlyGames() {
        require (settings.isGameAddress(_msgSender()));
        _;
    }

    modifier onlyOperators() {
        require (settings.isOperatorAddress(_msgSender()));
        _;
    }

    constructor(
        address _settings,
        address _weth,
        address _tokenProxy,
        uint256 chainid
    )
        public
        EIP712MetaTransaction("BadBit.Games", "0.1", chainid)
    {
        settings = IBadBitSettings(_settings);
        weth = IERC20(_weth);
        tokenProxy = ITokenTransferProxy(_tokenProxy);

    }

    function setDistributor(address _distributorAddress) public onlyOperators {
        distributor = IBadBitDistributor(_distributorAddress);
    }

    /**
    * @dev Allows users to add balance to their account
    */
    function topUp(uint256 amount) external {

        tokenProxy.transferFrom(
            address(weth),
            _msgSender(),
            address(this),
            amount
        );

        _add(_msgSender(), amount);
    }

    /**
    * @dev Subtract amount from user's balance
    * @param _user address of user
    * @param _amount uint representing value in Wei to be subtracted
    */
    function _subtract(address _user, uint _amount) internal returns(bool) {

        if (userBalances[_user] < _amount) return false;

        userBalances[_user] = userBalances[_user].sub(_amount);
        totalPlayerBalances = totalPlayerBalances.sub(_amount);

        return true;
    }

    /**
    * @dev Add given amount to the user's balance
    * @param _user address of user
    * @param _amount uint representing value in Wei to be added
    */
    function add(address _user, uint _amount) public onlyGames returns(bool) {

        tokenProxy.transferFrom(
            address(weth),
            _user,
            address(this),
            _amount
        );
        return _add(_user, _amount);
    }

    /**
    * @dev Add given amount to the user's balance
    * @param _user address of user
    * @param _amount uint representing value in Wei to be added
    */
    function _add(address _user, uint _amount) internal returns(bool) {
        if (_amount == 0) return false;

        userBalances[_user] = userBalances[_user].add(_amount);
        totalPlayerBalances = totalPlayerBalances.add(_amount);

        require(totalPlayerBalances <= weth.balanceOf(address(this)));

        return true;
    }

    /**
    * @dev Add given bonus amount to the user's balance
    * @dev Only operators can add bonus amount
    * @param _user address of user
    * @param _amount uint representing value in Wei to be added
    */
    function addBonus(
        address _user,
        uint _amount
    )
        public
        onlyOperators
        returns(bool)
    {
        return _addBonus(_user, _amount);
    }

    function addBonuses(
        address[] memory _users,
        uint[] memory _amounts
    )
        public
        onlyOperators
        returns(bool)
    {
        require(_users.length == _amounts.length);

        for(uint i = 0; i < _users.length; i++) {
            _addBonus(_users[i], _amounts[i]);
        }

        return true;
    }

    /**
    * @dev Add given bonus amount to the user's balance
    * @dev Only operators can add bonus amount
    * @param _user address of user
    * @param _amount uint representing value in Wei to be added
    */
    function _addBonus(address _user, uint _amount) internal returns(bool) {
        if (_amount == 0) return false;

        userBonusBalances[_user] = userBonusBalances[_user].add(_amount);

        return true;
    }

    /**
    * @dev Subtract bonus amount from user's balance
    * @param _user address of user
    * @param _amount uint representing value in Wei to be subtracted
    */
    function subtractBonus(
        address _user,
        uint _amount
    )
        public
        onlyGames
        returns(bool)
    {
        return _subtractBonus(_user, _amount);
    }

    /**
    * @dev Subtract bonus amount from user's balance
    * @param _user address of user
    * @param _amount uint representing value in Wei to be subtracted
    */
    function _subtractBonus(
        address _user,
        uint _amount
    )
        internal
        returns(bool)
    {

        if (userBonusBalances[_user] < _amount) return false;

        userBonusBalances[_user] = userBonusBalances[_user].sub(_amount);

        return true;
    }

    /**
    * @dev Allows users to make withdrawals
    * @param _user address of user which ETH should be sent to
    * @param _amount Amount to be withdrawn
    */
    function withdraw(address _user, uint _amount) public {
        // Any game can implement its own withdrawal method
        require(_user == _msgSender());

        IBadBitCasino(address(this))._finalizeLastBets(_user);

        // @dev This will not pass if _amount is bigger than available balance
        userBalances[_user] = userBalances[_user].sub(_amount);
        totalPlayerBalances = totalPlayerBalances.sub(_amount);

        uint _timestamp = now;
        userWithdrawals[_user].push(Withdrawal({
            withdrawalTimestamp: _timestamp,
            amount: _amount
        }));

        weth.transfer(_user, _amount);

        emit UserWithdrawal(_user, _timestamp);
    }

    /**
    * @dev This method will be used by casino to give user all his contract balance back
    * in case of emergency shutdown
    * @param _user address of the user
    */
    function _withdrawalByCasino(address _user) internal {

        uint256 _amount = userBalances[_user];
        userBalances[_user] = 0;
        totalPlayerBalances = totalPlayerBalances.sub(_amount);

        uint _timestamp = now;
        userWithdrawals[_user].push(Withdrawal({
            withdrawalTimestamp: _timestamp,
            amount: _amount
        }));

        weth.transfer(_user, _amount);

        emit UserWithdrawal(_user, _timestamp);
    }

    function getNumberOfUserWithdrawals(
        address _user
    )
        public
        view
        returns(uint)
    {
        return userWithdrawals[_user].length;
    }

    function addAmountByDistributor(address _user, uint _amount) public {
        require(_msgSender() == address(distributor));

        _add(_user, _amount);
    }
}

// File: original_contracts/Token/IBadBitAffiliateToken.sol

pragma solidity 0.5.17;


interface IBadBitAffiliateToken {

    function addressToAffiliateTokenId(address account) external view returns(uint256);

    function addBalance(uint tokenId, uint amount) external returns(uint);

    function ownerOf(uint256 tokenId) external view returns (address);

    function substractBalance(uint tokenId, uint amount) external returns(uint difference);
}

// File: original_contracts/Global/BadBitCasino.sol

pragma solidity ^0.5.0;










contract BadBitCasino is BadBitWallet, IOracleUser {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    enum PaymentMethod { ETH, ContractBalance, BonusBalance }

    struct Bet {
        address game;
        uint betId;
    }

    struct DonBet {
        address game;
        address sender;
        uint amount;
        bool won;
        bool finalized;
    }

    /**
    * @dev keep total funds spent on oraclize
    */
    uint public totalFundsSpentOnOraclize;
    /**
    * @dev keep total commission earned for DoN games and sweepstakes
    */
    uint public commissionEarned;

    /**
    * @dev keep how many ether has been paid out as profit to all players
    */
    uint public totalPlayerProfits;

    /**
    * @dev keep how many ethers is lost by all players
    */
    uint public totalFundsLostByPlayers;
    /**
    * @dev keep track of all funds sent directly to contract
    */
    uint public totalFundsSentByOwner;

    /**
    * @dev keep track of all funds earned by affiliate token holders
    */
    uint public totalFundsSpentOnAffiliates;

    /**
    * @dev keep track of all funds that have been transfered from revenue pool to initial deposit pool
    */
    uint public totalFundsTransferredToDepositPool;

    /**
    * @dev keep how much ether has been won by each player (this includes the original bet amount)
    */
    mapping(address => uint) public totalWinningsForPlayer;
    /**
    * @dev keep current level for each player
    */
    mapping(address => uint) public playerLevel;
    /**
    * @dev keep amount of cumulative ETH won required for each level
    */
    uint[] public amountRequiredForLevel;
    /**
    * @dev Holds all bets of user with specific address
    */
    mapping(address => Bet[]) public bets;
    /**
    * @dev Keeps track of sender for queryId when playing doubleOrNothing
    */
    mapping(bytes32 => DonBet) public donBets;
    /**
    * @dev All users that played game
    */
    address[] public users;
    /**
    * @dev Mapping that keep first unfinalized bet for user
    */
    mapping(address => uint) public firstUnfinalizedBet;
    /**
    * @dev Tracks last won amount per games for each user
    */
    mapping(address => mapping(address => uint)) public lastWonAmountPerGame;

    IOracleProvider public oracleProvider;
    IBadBitAffiliateToken public affiliateToken;

    IERC20 public weth;
    ITokenTransferProxy public tokenProxy;

    event BigWin(address indexed user, address indexed game, uint amount);
    event DoubleOrNothingPlayed(bytes32 queryId, address indexed user, uint indexed betId, address indexed game);
    event DoubleOrNothingFinished(bytes32 indexed queryId, address indexed user, bool won, uint tokensWon);
    event AffiliateRevenueChanged(address indexed playerAddress, address indexed affiliateAddress, uint amount, bool isPositive);
    event BetPlaced(address indexed game, address indexed user, uint amountWagered, bool isBonus);
    event BetFinalized(address indexed game, address indexed user, uint grossWinnings, bool isBonus);

    modifier onlyGames() {
        require (settings.isGameAddress(_msgSender()));
        _;
    }

    modifier onlyOperators() {
        require (settings.isOperatorAddress(_msgSender()));
        _;
    }

    constructor(address _settings, address _oracleProvider, address _affiliateToken, address _weth, address _tokenProxy, uint256 chainid) BadBitWallet(_settings, _weth, _tokenProxy, chainid) public {

        oracleProvider = IOracleProvider(_oracleProvider);
        affiliateToken = IBadBitAffiliateToken(_affiliateToken);
        weth = IERC20(_weth);
        tokenProxy = ITokenTransferProxy(_tokenProxy);
    }

    function setOracleProvider(address _oracleProvider) external onlyOperators {
        oracleProvider = IOracleProvider(_oracleProvider);
    }

    function setAffiliateToken(address _affiliateToken) external onlyOperators {
        affiliateToken = IBadBitAffiliateToken(_affiliateToken);
    }

    function fillAmountRequiredForLevel() public {
        amountRequiredForLevel = [0, 3 ether, 9 ether, 18 ether, 30 ether,
            45 ether, 63 ether, 84 ether, 108 ether, 135 ether, 165 ether,
            198 ether, 234 ether, 273 ether, 315 ether, 360 ether, 408 ether,
            459 ether, 513 ether, 570 ether, 630 ether, 693 ether, 759 ether,
            828 ether, 900 ether, 975 ether, 1053 ether, 1134 ether, 1218 ether,
            1305 ether, 1395 ether, 1488 ether, 1584 ether, 1683 ether, 1785 ether,
            1890 ether, 1998 ether, 2109 ether, 2223 ether, 2340 ether, 2460 ether,
            2583 ether, 2709 ether, 2838 ether, 2970 ether, 3105 ether, 3243 ether,
            3384 ether, 3528 ether, 3675 ether, 3825 ether, 3978 ether, 4134 ether,
            4293 ether, 4455 ether, 4620 ether, 4788 ether, 4959 ether, 5133 ether,
            5310 ether, 5490 ether, 5673 ether, 5859 ether, 6048 ether, 6240 ether,
            6435 ether, 6633 ether, 6834 ether, 7038 ether, 7245 ether, 7455 ether,
            7668 ether, 7884 ether, 8103 ether, 8325 ether, 8550 ether, 8778 ether,
            9009 ether, 9243 ether, 9480 ether, 9720 ether, 9963 ether, 10209 ether,
            10458 ether, 10710 ether, 10965 ether, 11223 ether, 11484 ether,
            11748 ether, 12015 ether, 12285 ether, 12558 ether, 12834 ether,
            13113 ether, 13395 ether, 13680 ether, 13968 ether, 14259 ether,
            14553 ether, 14850 ether, 15150 ether];
    }

    function placeBet(address _user, uint _betId, uint _amount, bool bonus) public onlyGames {
        require(settings.BETS_ALLOWED());

        if (bets[_user].length == 0) {
            users.push(_user);
        }

        _finalizeLastBets(_user);

        if (bonus) {
            require(_subtractBonus(_user, _amount));
        } else {
            require(_subtract(_user, _amount));
        }

        bets[_user].push(Bet({
                game: _msgSender(),
                betId: _betId
            }));

        // if bets needs to be finalzied, we don't do anything, but if all bets are finalized, we move pointer to new bet
        // check firstUnfinalizedBet[_user] != bets[_user].length - 1 because if that is the case we can't get state of bet from the game contract
        // as it still hasn't been written there
        if (firstUnfinalizedBet[_user] != bets[_user].length - 1 && !needToUpdateBetsForUser(_user)) {
            firstUnfinalizedBet[_user] = bets[_user].length - 1;
        }

        emit BetPlaced(_msgSender(), _user, _amount, bonus);
    }

    function _finalizeLastBets(address _user) public {
        uint count = bets[_user].length;

        if (count > 0 && needToUpdateBetsForUser(_user)) {
            uint starting = firstUnfinalizedBet[_user];

            for (uint i=starting; i<count; i++) {

                Bet memory betObject = bets[_user][i];
                uint amountWagered;
                bool finalized;
                bool isBonus;
                uint profit = 0;
                uint totalWon = 0;
                (amountWagered, finalized, , isBonus) = GameInterface(betObject.game).getBetInfo(_user, betObject.betId);

                if (!finalized) {
                    if (GameInterface(betObject.game).canFinalizeBet(_user, betObject.betId)) {
                        (profit, totalWon) = GameInterface(betObject.game).finalizeBet(_user, betObject.betId);

                        if (totalWon > 0) {
                            require(_add(_user, totalWon));
                            totalPlayerProfits += isBonus ? totalWon : profit;
                            totalWinningsForPlayer[_user] += totalWon;
                            updatePlayerLevelIfNeeded(_user);
                            lastWonAmountPerGame[betObject.game][_user] = totalWon;

                            if (totalWon > settings.BIG_WIN_THRESHOLD()) {
                                emit BigWin(_user, betObject.game, totalWon);
                            }
                        }

                        if(isBonus) {
                            decreaseAffiliateRevenue(totalWon, _user);
                        } else {
                            if (profit > 0) {
                                decreaseAffiliateRevenue(profit, _user);
                            } else {
                                increaseAffiliateRevenue(amountWagered.sub(totalWon), _user);
                            }
                        }
                    } else {
                        if (starting == firstUnfinalizedBet[_user]) {
                            bool isFirstFinalized;
                            // inside this if so we don't call this all the time if not needed
                            (, isFirstFinalized, ,) = GameInterface(bets[_user][starting].game).getBetInfo(_user, bets[_user][starting].betId);

                            if (isFirstFinalized) {
                                firstUnfinalizedBet[_user] = i;
                            }
                        }
                    }

                    emit BetFinalized(betObject.game, _user, totalWon, isBonus);
                }
            }
        }
    }

    /**
    * @dev Allows owner to finalizeLastBets for array of addresses
    * @dev This is added because owner can't withdraw ether without all bets updated
    */
    function finalizeLastBetsForAddresses(address[] memory _addresses) public onlyOperators {
        for (uint i=0; i<_addresses.length; i++) {
            _finalizeLastBets(_addresses[i]);
        }
    }

    function placeBetForDoubleOrNothing(address _game, uint _amount) public {
        require(settings.BETS_ALLOWED());
        address sender = _msgSender();
        _finalizeLastBets(sender);

        // needs to be after finalizeLastBets is executed
        require(lastWonAmountPerGame[_game][sender] >= _amount);

        uint gasLimit = settings.ORACLIZE_GAS_LIMIT();

        uint256 maxWinnableAmount = getMaxWinnableAmount(_game);
        uint256 price = settings.USE_BLOCKHASH_RANDOM_SEED() ? oracleProvider.getPrice(IOracleProvider.DATASOURCE.DELAY, bytes32("0x")) : oracleProvider.getPrice(IOracleProvider.DATASOURCE.RANDOM_GAMBLING, bytes32(maxWinnableAmount));
        weth.approve(address(oracleProvider), price);
        bytes32 queryId = settings.USE_BLOCKHASH_RANDOM_SEED() ? oracleProvider.delayQuery(0, gasLimit) : oracleProvider.randomNumberQueryGambling(8, maxWinnableAmount, gasLimit);

        totalFundsSpentOnOraclize += price;

        donBets[queryId] = DonBet({
            game: _game,
            sender: sender,
            amount: _amount,
            won: false,
            finalized: false
        });

        require(_subtract(sender, _amount));

        emit DoubleOrNothingPlayed(queryId, sender, GameInterface(_game).getTotalBets(sender) - 1, _game);
        emit BetPlaced(address(0), sender, _amount, false);
    }

    function getMaxWinnableAmount(address game) public view returns(uint256) {

        uint256 gameMaxWinnableAmount = GameInterface(game).getMaxWinnableAmount();

        uint256 amount = gameMaxWinnableAmount.mul(2);

        return amount;
    }

    function callback(bytes32 myid, string memory result) public {
        address sender = _msgSender();
        if (!oracleProvider.isCbAddress(sender) && !settings.isOperatorAddress(sender)) revert();

        // @dev Oraclize sometimes rebroadcast transactions, so we need to make sure thats not the case
        require(!donBets[myid].finalized);
        require(settings.USE_BLOCKHASH_RANDOM_SEED() || bytes(result)[0] != 0);

        uint randomNumber;

        if(settings.isOperatorAddress(sender) || settings.USE_BLOCKHASH_RANDOM_SEED()) {
            randomNumber = uint224(uint(blockhash(block.number - 1)).mod(100));
        } else {
            randomNumber = uint224(uint(keccak256(abi.encodePacked(result))).mod(100));
        }

        uint wonAmount = 0;

        // @dev this means user won
        if (randomNumber < 50) {
            commissionEarned += getCommission(donBets[myid].amount);
            uint winnings = getPossibleWinnings(donBets[myid].amount);
            wonAmount = donBets[myid].amount + winnings;

            totalWinningsForPlayer[donBets[myid].sender] += winnings;
            totalPlayerProfits += winnings;
            updatePlayerLevelIfNeeded(donBets[myid].sender);

            require(_add(donBets[myid].sender, wonAmount));
            lastWonAmountPerGame[donBets[myid].game][donBets[myid].sender] = wonAmount;
            donBets[myid].won = true;

            decreaseAffiliateRevenue(winnings, donBets[myid].sender);
        } else {
            totalFundsLostByPlayers += donBets[myid].amount;
            increaseAffiliateRevenue(donBets[myid].amount, donBets[myid].sender);
        }

        uint tokensWon = 0;

        uint[] memory chances = new uint[](1);
        chances[0] = 50;

        if (distributor.shouldWinTokens(keccak256(abi.encodePacked(result)), donBets[myid].sender, donBets[myid].amount, chances)) {
            distributor.winTokens(donBets[myid].sender);
            tokensWon = distributor.getStandardLot();
        }

        emit DoubleOrNothingFinished(myid, donBets[myid].sender, randomNumber < 50, tokensWon);
        emit BetFinalized(address(0), donBets[myid].sender, wonAmount, false);

        donBets[myid].finalized = true;
    }

    function increaseAffiliateRevenue(uint amount, address _user) internal {
        uint tokenId = affiliateToken.addressToAffiliateTokenId(_user);

        if(tokenId == 0) {
            return;
        }

        uint rewardAmount = (amount * settings.AFFILIATE_REWARD_PERCENTAGE()) / 10000;
        totalFundsSpentOnAffiliates += affiliateToken.addBalance(tokenId, rewardAmount);

        emit AffiliateRevenueChanged(_user, affiliateToken.ownerOf(tokenId), rewardAmount, true);
    }

    function decreaseAffiliateRevenue(uint amount, address _user) internal {
        uint tokenId = affiliateToken.addressToAffiliateTokenId(_user);

        if(tokenId == 0) {
            return;
        }

        uint decreaseAmount = (amount * settings.AFFILIATE_REWARD_PERCENTAGE()) / 10000;
        totalFundsSpentOnAffiliates = totalFundsSpentOnAffiliates.sub(affiliateToken.substractBalance(tokenId, decreaseAmount));

        emit AffiliateRevenueChanged(_user, affiliateToken.ownerOf(tokenId), decreaseAmount, false);
    }

    function resetFundsSpentOnAffiliates() public {
        require(_msgSender() == address(distributor));

        totalFundsSpentOnAffiliates = 0;
    }

    /**
    * @dev Calculate current user balance, taking into account unfinalized bets
    * @param _user address of the user
    * @return returns uint representing user balance in wei
    */
    function getCurrentBalance(address _user) public view returns(uint) {
        uint balance = userBalances[_user];
        uint count = bets[_user].length;

        if (count == 0) {
            return balance;
        }

        if (needToUpdateBetsForUser(_user)) {
            uint starting = firstUnfinalizedBet[_user];

            for (uint i=starting; i<count; i++) {
                Bet memory betObject = bets[_user][i];
                (uint amount, bool finalized, ,) = GameInterface(betObject.game).getBetInfo(_user, betObject.betId);

                if (!finalized) {
                    uint winnings = GameInterface(betObject.game).getUserProfitForFinishedBet(_user, betObject.betId);

                    if(winnings > 0) {
                        balance = balance + amount + winnings;
                    }
                }
            }
        }

        return balance;
    }

    /**
    * @dev Calculate house commission for the double or nothing bet
    * @param _amount represents amount that is played for bet
    * @return returns uint of house commission
    */
    function getCommission(uint _amount) public view returns(uint) {
        uint commission = settings.HOUSE_EDGE().mul(2);

       // divide by 100000 because of decimal places
        return commission < 100000 ? (_amount).mul(commission).div(100000) : _amount;
    }

    /**
    * @dev Calculate possible winning with specific chance and amount
    * @param _amount represents amount that is played for bet
    * @return returns uint of players profit with specific chance and amount
    */
    function getPossibleWinnings(uint _amount) public view returns(uint) {
        uint commission = settings.HOUSE_EDGE().mul(2);
        // using 100000 because we keep house edge with three decimals, and that is 100 * 1000
        return commission < 100000 ? _amount.mul(100000-commission).div(100000) : 0;
    }

    function getExtraTokenWinChanceForPlayer(address _user) public view returns (uint){
        return settings.tokenWinChanceRewardForLevel(playerLevel[_user]);
    }

    function needToUpdateBetsForUser(address _user) public view returns(bool) {
        Bet memory betObject = bets[_user][firstUnfinalizedBet[_user]];
        (, bool finalized, ,) = GameInterface(betObject.game).getBetInfo(_user, betObject.betId);

        return (!finalized);
    }

    function updatePlayerLevelIfNeeded(address _user) public {
        uint currentPlayerLevel = playerLevel[_user];

        while(currentPlayerLevel < amountRequiredForLevel.length - 1 && totalWinningsForPlayer[_user] >= amountRequiredForLevel[currentPlayerLevel+1]) {
            currentPlayerLevel++;

            // Add player reward for the current level
            _addBonus(_user, settings.bonusBalanceRewardForLevel(currentPlayerLevel));
        }

        playerLevel[_user] = currentPlayerLevel;
    }

    function sendEthToGame(uint _amount) public onlyGames {
        totalFundsSpentOnOraclize += _amount;
        weth.transfer(_msgSender(), _amount);
    }

    //This function will allow operator to pull al funds to the deployer address
    //User funds will not be sent. Use this in case of emergency
    // Please ensure that you finalize all bets before calling this method
    function emergencyShutDownWithdrawFunds() public onlyOperators {
        uint256 currBalance = weth.balanceOf(address(this));
        require(
            currBalance >= totalPlayerBalances,
            "Does not have enough funds to return to players"
        );

        weth.transfer(
            settings.deployer(),
            currBalance.sub(totalPlayerBalances)
        );

        address[] memory games = settings.getGames();

        for(uint i = 0; i < games.length; i++) {
            if(games[i] != address(this)) {
                GameInterface(games[i]).emergencyWithdraw(settings.deployer());
            }
        }
    }

    function emergencyShutdown(
        address[] memory _addresses,
        bool transferToOperator
    )
        public
        onlyOperators
    {
        for (uint i = 0; i < _addresses.length; i++) {
            _finalizeLastBets(_addresses[i]);
            _withdrawalByCasino(_addresses[i]);
        }

        if(transferToOperator && totalPlayerBalances == 0) {
            uint256 balance = weth.balanceOf(address(this));
            weth.transfer(settings.deployer(), balance);

            address[] memory games = settings.getGames();

            for(uint i = 0; i < games.length; i++) {
                if(games[i] != address(this)) {
                    GameInterface(games[i]).emergencyWithdraw(settings.deployer());
                }
            }
        }
    }

    function transferFundsToDepositPool(
        address _receiver,
        uint _amount
    )
        public
    {
        require(_msgSender() == address(distributor));

        weth.transfer(_receiver, _amount);
        totalFundsTransferredToDepositPool = _amount;
    }

    /**
    * @dev Checks for number of bets user played
    * @param _user address of user
    * @return returns uint representing number of total bets played by user
    */
    function getTotalBets(address _user) public view returns(uint) {
        return bets[_user].length;
    }

    function getUsers() public view returns(address[] memory) {
        return users;
    }

    /**
    * @dev Allows anyone to just send ether to contract
    * This function will be used instead of fallback method
    */
    function addFunds(uint256 amount) external {

        require(totalFundsTransferredToDepositPool == 0, "Can not add more funds directly");

        tokenProxy.transferFrom(
            address(weth),
            _msgSender(),
            address(this),
            amount
        );

        totalFundsSentByOwner = totalFundsSentByOwner.add(amount);
    }
}