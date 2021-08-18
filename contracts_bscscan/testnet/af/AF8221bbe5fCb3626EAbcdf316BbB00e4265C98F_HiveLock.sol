/**
 *Submitted for verification at BscScan.com on 2021-08-18
*/

// SPDX-License-Identifier: Unlicensed
/********************************************************************************************
/        \_____/        \_____/        \____█/        \_____/        \_____/        \_____/
\        /     \        /     \        /   █▓█        /     \        /     \        /     \ 
 \      /       \      /       \      /   █   █      /       \      /       \      /       \
  >----<         >----<         >----<   █     █----<         >----<         >----<         >
 /      \       /      \       /      \██       ██   \       /      \       /      \       /
/        \_____/        \_____/      ██           ██  \_____/        \_____/        \_____/
\        /     \        /     \   ██▓               ▓██     \        /     \        /     \
 \      /       \      /       ██▓                     ▓██   \      /       \      /       \
  >----<         >----<   ███▓▓   RUGPULL BUSTER PROJECT  ▓▓███----<         >----<         >
 /      \       /     ███▓‗‗‗‗‗‗‗‗‗‗‗‗‗‗‗‗‗‗‗‗‗‗‗‗‗‗‗‗‗‗‗‗‗‗‗‗‗▓███ \       /      \       /
/        \_██__█████▓▓  ║                                       ║  ▓▓█████_/ ██     \_____/
\        / ███▓▓        ║ █ █ █ █   █ ███     █   ░█░  ███ █  █ ║         ▓▓███     /     \
 \      /  █            ║ █ █ █ █   █ █       █  ░█ █░ █   █ █  ║             █    /       \
  >----<   █            ║ ███ █ █   █ ██      █  █   █ █   ██   ║             █---<         >
 /      \  █            ║ █ █ █  █░█  █       █  ░█ █░ █   █ █  ║             █    \       /
/        \_█            ║ █ █ █   █   ███     ███ ░█░  ███ █  █ ║             █     \_____/
\        / █            ║‗‗‗‗‗‗‗‗‗‗‗‗‗‗‗‗‗‗‗‗‗‗‗‗‗‗‗‗‗‗‗‗‗‗‗‗‗‗‗║             █     /     \
 \      /  █                                                                  █    /       \
  >----<   █                                                                  █---<         >
 /      \  █                                                                 ██    \       /
/        \_██                             █████                             ██      \_____/
\        /  ██                         ███     ███                          ██      /     \
 \      /   ██                       ██           ██                       ██      /       \
  >----<     ██                      █▓           ▓█                       ██>----<         >
 /      \    ██                    ███████████████████                    ██/      \       /
/        \____██                   ███████████████████                   ██/        \_____/
\        /     ██                  ███████████████████                  ██ \        /     \
 \      /       █                  ████████░░░████████                  █   \      /       \
  >----<         █                 █████████░█████████                 █     >----<         >
 /      \       / ██               ████████░░░████████               ██     /      \       /
/        \_____/    ██             ███████████████████             ██\_____/        \_____/
\        /     \      ██           ███████████████████           ██  /     \        /     \
 \      /       \      /▓██                                   ██▓   /       \      /       \
  >----<         >----<    ▓██                             ██▓>----<         >----<         >
 /      \       /      \      ▓███                     ███▓  /      \       /      \       /
/        \_____/        \_____/   ▓███             ███▓_____/        \_____/        \_____/
\        /     \        /     \       ▓███     ███▓   /     \        /     \        /     \
 \      /       \      /       \      /   ▓███▓      /       \      /       \      /       \
  >----<         >----<         >----<         >----<         >----<         >----<         >
 /      \       /      \       /      \       /      \       /      \       /      \       /
/        \_____/        \     /        \_____/        \_____/        \     /        \_____/
*********************************************************************************************/
pragma solidity ^0.8.4;
/********************************************************************************************/
/*                                      Interfaces                                          */
/********************************************************************************************/
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
/********************************************************************************************/
/*                                      Libraries                                           */
/********************************************************************************************/
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }
    
    // sends ETH or an erc20 token
    function safeTransferBaseToken(address token, address payable to, uint value, bool isERC20) internal {
        if (!isERC20) {
            to.transfer(value);
        } else {
            (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
            require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
        }
    }
}
/********************************************************************************************/
/*                              Absctract Contracts                                         */
/********************************************************************************************/
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
/********************************************************************************************/
/* HIVELock :: Token Time Lock of Launchpad Phase of RugPull Buster Project                 */
/********************************************************************************************/
contract HiveLock is Context{                                                               //
    using SafeMath for uint256;                                                             // Safe math operations utility library                                                              // address utility library
                                                                                            //
    /*      structs         */                                                              //
    struct LockType {                                                                       // token lock type struct
        uint256 regular;                                                                    // regular[0]: all amount is  released after unlock timestamp
        uint256 linear;                                                                     // linear [1]: withdrawable amount increase linearly from start to end
        uint256 complex;                                                                    // complex[2]: regular to a middle timestamp then linear to end
    }                                                                                       //
    struct TokenLock {                                                                      // token lock struct
        uint256 lockType;                                                                   // Lock Type(regular.linear,complex)
        address token;                                                                      // address of the token
        uint256 amount;                                                                     // amount to be locked
        uint256 withdrawn;                                                                  // withdrawn amount
        uint256 lockTimestamp;                                                              // timestamp of when it is locked
        uint256 linearStart;                                                                // timestamp of linear mode(when applicable)
        uint256 unlockTimestamp;                                                            // timestamp of when it is unlocked and available to withdraw
        address owner;                                                                      // Owner of the lock >> who can withdraw
        bool processed;                                                                     // flag indicating if the tokens are locked or unlocked
    }                                                                                       //
    struct Authorize {                                                                      // Multi-Sig Authorization struct
        address[] sigs;                                                                     // authorized signature address array
        address newDevWallet;                                                               //
        bool processed;                                                                     // flag to validate the auth request
    }                                                                                       //
                                                                                            //
    /*          events      */                                                              //
    event MultiSigApprove(uint256 reqID, uint256 cntApprove, address admin, address newDevWallet, uint256 unlockTimestamp);
    event DevWalletChanged(address oldWallet, address newWallet, uint256 unlockTimestamp);  //
    event TokenLocked(uint256 LockID, address token, uint256 amount, address Owner, uint256 unlockTimestamp);
    event TokenLockAmountExtended(uint256 LockID, address token, uint256 orgAmount, uint256 newAmount);
    event TokenLockUnlocTimestampkExtended(uint256 LockID, address token, uint256 orgUnlockTimestamp, uint256 newUnlockTimestamp);
    event TokenLockOwnerChanged(uint256 LockID, address token, address orgOwner, address newOwner, uint256 timestamp);
    event TokenUnlocked(uint256 LockID, address token, uint256 withdrawn, uint256 totalAmount, address to, uint256 timestamp);
                                                                                            //
    /*  mappings/Arrays     */                                                              //
    mapping(uint256 => TokenLock) public tokenLockID;                                       // mapping of LockID to TokenLock struct
    mapping(address => uint256[]) public tokenLockAddr;                                     // mapping of token to LockID(s)
    mapping(address => uint256[]) public tokenLockOwner;                                    // mapping of Owner to LockID(s)
    mapping(uint256 => Authorize) public multiSigReq;                                       // Multi Signature Auth Requests
    mapping (address => bool) public admins;                                                // admin array/mapping
                                                                                            //
    /*      constants       */                                                              //
    address payable public immutable HVE;                                                   // address of Hive Token >> for Fee distribution to community
    uint256 public constant MIN_LOCK_PERIOD = 1 days;                                      // Minimum Period to lock a token
    uint256 public constant LOCK_FEE = 2e17;                                                // Token Locking Fee >> 0.2BNB
                                                                                            //
    /*      variables       */                                                              //
    uint256 public  idxLockID ;                                                             // incremental LockID counter
    address payable public devWallet;                                                       // address of Owner >> fee collection
    LockType public lockType;                                                               // instaniation of LockType struct
                                                                                            //
    /*      modifiers       */                                                              //
    modifier onlyAdmin() {                                                                  // tag to methods where restricted to only admin to call
        require(admins[_msgSender()], 'HiveLock: caller is not an admin');                  // revert if caller is not the dev wallet
        _;                                                                                  // process the method if no revert
    }                                                                                       //
                                                                                            //
    /****************************************************************************************/
    /*                          Constructor method                                          */
    /****************************************************************************************/
    constructor(address hve) {                                                              //
        HVE = payable(hve);                                                                 // Init HiveToken address
        idxLockID = 0;                                                                      // init LockID incremental variable
        devWallet = payable(_msgSender());                                                  // Define the Owner as the contract creator
        admins[0x96D82296ef04e42Ae3a1dE611445d3EE9486d5C3]= true;                           // Admin Wallet1
        admins[0x6756183E14ad778818f05A3aF692C2F4b6C7fDE7]= true;                           // Admin Wallet2
        admins[0x9230Aa3C6c01cc8760710613091d8a1d601BFb82]= true;                           // Admin Wallet3
        admins[0x25115631eE867BCf44CF8Cf003EaF6078198138E]= true;                           // Admin Wallet4
        admins[0x103F078eA413bd6Aaab96Fa1B687f36b3f3d0543]= true;                           // Admin Wallet5
        lockType = LockType({regular:0, linear:1, complex:3});                              // define LockType(s)
    }                                                                                       //
                                                                                            //
    /****************************************************************************************/
    /*                       Public/External Methods                                        */
    /****************************************************************************************/
    //////////////////////////////////////////////////////////////////////////////////////////
    /* fallback, to recieve ETH  << msg.data empty                                          */
    /* ACCESS           : None/public                                                       */
    //////////////////////////////////////////////////////////////////////////////////////////
    receive() external payable {}                                                           //
    //////////////////////////////////////////////////////////////////////////////////////////
    /* fallback, to recieve ETH  << msg.data not empty                                      */
    /* ACCESS           : None/public                                                       */
    //////////////////////////////////////////////////////////////////////////////////////////
    fallback() external payable {}                                                          //
    //////////////////////////////////////////////////////////////////////////////////////////
    /* Change the dev wallet address << protected by multiSig                               */
    /* ACCESS           : only defined admins                                               */
    /* PARAMETERS       :-                                                                  */
    /*   _devaddr       : new devwallet address                                             */
    /*   reqID          : MultiSig Request Identifier                                       */
    /* RETURNS          :-                                                                  */
    /*   cntAuth        : MultiSig Auth Count                                               */
    /*   status         : Success Status                                                    */
    //////////////////////////////////////////////////////////////////////////////////////////    
    function setDevWallet(address payable _devaddr, uint256 reqID) external onlyAdmin returns(uint256 cntAuth,bool status){
        require(reqID > 0, 'HiveLock: Invalid MultiSig ReqID');                             // revert if a wrong Multisig ReqID
        require(_devaddr != address(0), 'HiveLock: Invalid wallet address');                // revert if an invalid address
        if(authorize(reqID, _devaddr)){                                                     // validate if the method authorized by 3 designated addresses
            address oldWallet = devWallet;                                                  // store the old address
            devWallet = _devaddr;                                                           // update the dev wallet address
            emit DevWalletChanged(oldWallet, devWallet, block.timestamp);                   // emit the event
            return (multiSigReq[reqID].sigs.length, true);                                  // return success
        }                                                                                   //
        return (multiSigReq[reqID].sigs.length, false);                                     // return just the approval count
    }                                                                                       //
    //////////////////////////////////////////////////////////////////////////////////////////
    /* Method for locking a given amount of token for a specific period of time             */
    /* ACCESS           : None/Public                                                       */
    /* PARAMETERS       :-                                                                  */
    /*   token          : token address                                                     */
    /*   amount         : token amount                                                      */
    /*   unlockTimestamp: time stamp of when tokens can be  withdrawn                       */
    /* RETURNS          :-                                                                  */
    /*   lockID         : created lock identifier                                           */
    //////////////////////////////////////////////////////////////////////////////////////////
    function lockToken(address token, uint256 amount, uint256 unlockTimestamp, uint256 _lockType, uint256 _linearStart) external payable returns (uint256 ) {
        require(token != address(0), 'HiveLock: Invalid token address');                    // revert if invalid input token adddress
        require(amount > 0, 'HiveLock: token amount must be non-zero');                     // revert if invlaid input amount
        // validate the minimum lock period is met                                          //
        require(unlockTimestamp - block.timestamp >= MIN_LOCK_PERIOD, 'HiveLock: Lock Period can not be less than 30days');
        require(_lockType >= 0 && _lockType <= 3, 'HiveLock: Invalid LockType');            // revert if invlaid lock type
        if(_lockType == lockType.complex)                                                   // check if complex lock type >> revert if invalid linear start timestamp
            require(_linearStart > block.timestamp && _linearStart < unlockTimestamp, 'HiveLock: Complex Lock with invalid linear start');
        if(token != HVE)                                                                    // execlude the governance token(HVE) from fee scheme
            require(msg.value == LOCK_FEE, 'HiveLock: Locking Fee(0.2BNB) is not met');     // revert if the exact lock_fee is not sent
                                                                                            //
        idxLockID ++;                                                                       // increment the lockID >> new lockID
        // init linear start >> 0:(regular,linear), _linearstart:complex                    //
        uint256 linearStart = (_lockType == lockType.regular || _lockType == lockType.linear)? 0 : _linearStart;
        uint256 balance = IERC20(token).balanceOf(address(this));                           // get current balance of the token
        TransferHelper.safeTransferFrom(token, _msgSender(), address(this), amount);        // transfer tokens on behalf on the owner to the contract address
        uint256 actAmount = IERC20(token).balanceOf(address(this)).sub(balance);            // get actual received tokens(exclude fee/tax)
        TokenLock memory tokenLock = TokenLock(_lockType, token, actAmount, 0, block.timestamp, linearStart, unlockTimestamp, _msgSender(), false);
        tokenLockID[idxLockID] =  tokenLock;                                                // push the TokenLock struct into ID mapping
        tokenLockAddr[token].push(idxLockID);                                               // push lockID into the token mapping
        tokenLockOwner[_msgSender()].push(idxLockID);                                       // push lockID into the owner mapping
        // distribute fee between dev and community(HiveToken)                              //
        if(token != HVE){                                                                   // exclude gov token of locking fees
            devWallet.transfer(1e17);                                                       // send the dev half the fees and the other half to distribution
            (bool success,) = HVE.call{value: 1e17}("");                                    // Hive contract modifies storage so a low level call is required for gas
            require(success);                                                               // ensure ETH transfer success
        }                                                                                   //
        emit TokenLocked(idxLockID, token, actAmount, _msgSender(), unlockTimestamp);       // emit lock event
        return idxLockID;                                                                   // return lockID
    }                                                                                       //
    //////////////////////////////////////////////////////////////////////////////////////////
    /* Method for extending amount or unlock timestamp of a specific lock                   */
    /* ACCESS           : Only lock owner                                                   */
    /* PARAMETERS       :-                                                                  */
    /*   lockID         : lock identifier                                                   */
    /*   extraAmount    : amount to be added to existing                                    */
    /*   newTimestamp   : a later time stamp of the current unlock timestamp                */
    /* RETURNS          :-                                                                  */
    /*   bool           : Success Status                                                    */
    //////////////////////////////////////////////////////////////////////////////////////////
    function extendLock(uint256 lockID, uint256 extraAmount, uint256 newTimestamp) external payable returns (bool ) {
        require(lockID > 0 && lockID <= idxLockID, 'HiveLock: Invalid lockID');             // revert if invalid lockID
        require(!tokenLockID[lockID].processed, 'HiveLock: already processed');             // revert if lock is processed
        require(extraAmount > 0 || newTimestamp > tokenLockID[lockID].unlockTimestamp, 'HiveLock: No changes to process');
        require(tokenLockID[lockID].owner == _msgSender(), 'HiveLock: sender must be the owner of the lock');
        if(tokenLockID[lockID].token != HVE)                                                // exclude HiveToken from fees
            require(msg.value == LOCK_FEE, 'HiveLock: Lock Extension Fee(0.2BNB) is not met');
        // adding more tokens to the lock                                                   //
        if(extraAmount > 0){                                                                // is amount to be added
            address token = tokenLockID[lockID].token;                                      // get token address 
            uint256 balance = IERC20(token).balanceOf(address(this));                       // get current balance of the token
            TransferHelper.safeTransferFrom(token, _msgSender(), address(this), extraAmount);
            uint256 actExtraAmount = IERC20(token).balanceOf(address(this)).sub(balance);   // get actual received tokens(exclude fee/tax)
            uint256 orgAmount = tokenLockID[lockID].amount;                                 // capture original amount for event data
            tokenLockID[lockID].amount = tokenLockID[lockID].amount.add(actExtraAmount);    // update the locked amount
            emit TokenLockAmountExtended(lockID, tokenLockID[lockID].token, orgAmount, tokenLockID[lockID].amount);
        }                                                                                   //
        // extending the unlock date                                                        //
        if(newTimestamp > tokenLockID[lockID].unlockTimestamp){                             // is unlockTimestamp to be exteneded?
            uint256 orgUnlock = tokenLockID[lockID].unlockTimestamp;                        // capture original unlock timestamp for event data
            tokenLockID[lockID].unlockTimestamp = newTimestamp;                             // update unlock timestamp
            emit TokenLockUnlocTimestampkExtended(lockID, tokenLockID[lockID].token, orgUnlock, tokenLockID[lockID].unlockTimestamp);
        }                                                                                   //
        // distribute fee between dev and community(HiveToken)                              //
        if(tokenLockID[lockID].token != HVE){                                               // exclude hive token from fees
            devWallet.transfer(1e17);                                                       // send half the fees to dev and the other to distribution
            (bool success,) = HVE.call{value: 1e17}("");                                    // Hive contract modifies storage so a low level call is required for gas
            require(success);                                                               // ensure ETH transfer success
        }                                                                                   //
        return true;                                                                        // successful return
    }                                                                                       //
    //////////////////////////////////////////////////////////////////////////////////////////
    /* Method for changing lock owner                                                       */
    /* ACCESS           : Only current lock owner                                           */
    /* PARAMETERS       :-                                                                  */
    /*   lockID         : lock identifier                                                   */
    /*   newOwner       : new owner address                                                 */
    /* RETURNS          :-                                                                  */
    /*   bool           : Success Status                                                    */
    //////////////////////////////////////////////////////////////////////////////////////////
    function setLockOwner(uint256 lockID, address newOwner) external returns (bool success) {
        require(_msgSender() != newOwner, 'HiveLock: Sender can not be new owner');         // revert if trying to set the old owner
        require(lockID > 0 && lockID <= idxLockID, 'HiveLock: Invalid lockID');             // revert if invalid lockID
        require(!tokenLockID[lockID].processed, 'HiveLock: already processed');             // revert if lock is processed
        // revert if the sender is not the current owner                                    //
        require(tokenLockID[lockID].owner == _msgSender(), 'HiveLock: sender must be the owner of the lock');
        tokenLockID[lockID].owner = newOwner;                                               // set the new owner
                                                                                            //
        removeOwnerLock(_msgSender() , lockID);                                             // delete the lockID from old owner mapping
        tokenLockOwner[newOwner].push(lockID);                                              // push the lockID into the new owner mapping
        // emit the owner change event                                                      //
        emit TokenLockOwnerChanged(lockID, tokenLockID[lockID].token, _msgSender(), newOwner, block.timestamp);
        return true;                                                                        // successful return
    }                                                                                       //
    //////////////////////////////////////////////////////////////////////////////////////////
    /* Method for unlocking tokens when the eadline is met                                  */
    /* ACCESS           : only lock owner                                                   */
    /* PARAMETERS       :-                                                                  */
    /*   lockID         : lock identifier                                                   */
    /*   to             : optional address to transfer tokens to                            */
    /* RETURNS          :-                                                                  */
    /*   bool           : Success Status                                                    */
    //////////////////////////////////////////////////////////////////////////////////////////
    function unlockToken(uint256 lockID, address to) external returns (bool success) {      //
        require(lockID > 0 && lockID <= idxLockID, 'HiveLock: Invalid lockID');             // revert if invalid lockID
        require(tokenLockID[lockID].owner == _msgSender(), 'HiveLock: sender must be the owner of the lock');
        require(!tokenLockID[lockID].processed, 'HiveLock: already processed');             // revert if lock is processed
        if(to == address(0))                                                                // check if to parameter is invalid
            to = _msgSender();                                                              // if invalid >> point to msg sender
        uint256 withdrawAmount = calcWithdrawAmount(tokenLockID[lockID]);                   // calc the amount that can be withdrawn
        uint256 balance = IERC20(tokenLockID[lockID].token).balanceOf(address(this));       // get current balance of the token
        require(balance >= withdrawAmount, 'HiveLock: Insufficient balance');               // revert in fo no balance covering the withdraw
        TransferHelper.safeTransfer(tokenLockID[lockID].token, to, withdrawAmount);         // transfer the tokens back to the owner
        tokenLockID[lockID].withdrawn = tokenLockID[lockID].withdrawn.add(withdrawAmount);  // ccumulate withdrawn amounts
        if(tokenLockID[lockID].withdrawn == tokenLockID[lockID].amount)                     // is all tokens withdrawn?
            tokenLockID[lockID].processed = true;                                           // mark the lock as processed
        // emit the unlock event                                                            //
        emit TokenUnlocked(lockID, tokenLockID[lockID].token, withdrawAmount, tokenLockID[lockID].amount, to, block.timestamp);
        return true;                                                                        // return scuccess
    }                                                                                       //
    //////////////////////////////////////////////////////////////////////////////////////////
    /* Method for displaying a specific lockID details                                      */
    /* ACCESS           : None/Public                                                       */
    /* PARAMETERS       :-                                                                  */
    /*   lockID         : lock identifier                                                   */
    /* RETURNS          :-                                                                  */
    /*   struct         : TokenLock details struct                                          */
    //////////////////////////////////////////////////////////////////////////////////////////
    function getTokenLock(uint256 lockID) external view returns (TokenLock memory) {        //
        require(lockID > 0 && lockID <= idxLockID, 'HiveLock: Invalid lockID');             // revert if invalid lockID
        return tokenLockID[lockID];                                                         // return the details struct if the supplied lockID
    }                                                                                       //
    //////////////////////////////////////////////////////////////////////////////////////////
    /* Method for enumeration of all Owner locks                                            */
    /* ACCESS           : None/Public                                                       */
    /* PARAMETERS       :-                                                                  */
    /*   owner          : Owner address                                                     */
    /* RETURNS          :-                                                                  */
    /*   array          : array of lockID(s)                                                */
    //////////////////////////////////////////////////////////////////////////////////////////
    function enumAllOwnerLocks(address Owner) external view returns (uint256[] memory) {    //
        uint cnt = 0;                                                                       // cnt of elements for the dynamic array instaniation
        for (uint i = 0; i < tokenLockOwner[Owner].length; i++){                            // loop through the lock identifier array
            uint256 lockID = tokenLockOwner[Owner][i];                                      // get the lockID
            if(lockID != 0 ){                                                               // if not deleted
                cnt++;                                                                      // increment the count
            }                                                                               //
        }                                                                                   //
        uint256[] memory locks = new uint256[](cnt);                                        // instaniate the lock array
        uint idx = 0;                                                                       // init lock array indexer
        for (uint i = 0; i < tokenLockOwner[Owner].length; i++){                            // loop through the lock identifier array
            uint256 lockID = tokenLockOwner[Owner][i];                                      // get the lockID
            if(lockID != 0 ){                                                               // if not deleted
                locks[idx] = lockID;                                                        // push lockID
                idx++;                                                                      // increment array index
            }                                                                               //
        }                                                                                   //
        return locks;                                                                       // return all lock array of the owner
    }                                                                                       //
    //////////////////////////////////////////////////////////////////////////////////////////
    /* Method for enumeration of Active Owner locks                                         */
    /* ACCESS           : None/Public                                                       */
    /* PARAMETERS       :-                                                                  */
    /*   owner          : Owner address                                                     */
    /* RETURNS          :-                                                                  */
    /*   array          : array of lockID(s)                                                */
    //////////////////////////////////////////////////////////////////////////////////////////
    function enumActiveOwnerLocks(address Owner) external view returns (uint256[] memory) { //
        uint cnt = 0;                                                                       // cnt of elements for the dynamic array instaniation
        for (uint i = 0; i < tokenLockOwner[Owner].length; i++){                            // loop through the lock identifier array
            uint256 lockID = tokenLockOwner[Owner][i];                                      // get the lockID
            if(lockID != 0 && !tokenLockID[lockID].processed){                              // if not deleted and not processed
                cnt++;                                                                      // increment the count
            }                                                                               //
        }                                                                                   //
        uint256[] memory locks = new uint256[](cnt);                                        // instaniate the lock array
        uint idx = 0;                                                                       // init lock array indexer
        for (uint i = 0; i < tokenLockOwner[Owner].length; i++){                            // loop through the lock identifier array
            uint256 lockID = tokenLockOwner[Owner][i];                                      // get the lockID
            if(lockID != 0 && !tokenLockID[lockID].processed){                              // if not deleted and not processed
                locks[idx] = lockID;                                                        // push lockID
                idx++;                                                                      // increment array index
            }                                                                               //
        }                                                                                   //
        return locks;                                                                       // return active lock array of the owner
    }                                                                                       //
    //////////////////////////////////////////////////////////////////////////////////////////
    /* Method for enumeration of Processed Owner locks                                      */
    /* ACCESS           : None/Public                                                       */
    /* PARAMETERS       :-                                                                  */
    /*   owner          : Owner address                                                     */
    /* RETURNS          :-                                                                  */
    /*   array          : array of lockID(s)                                                */
    //////////////////////////////////////////////////////////////////////////////////////////
    function enumProcessedOwnerLocks(address Owner) external view returns (uint256[] memory) {
        uint cnt = 0;                                                                       // cnt of elements for the dynamic array instaniation
        for (uint i = 0; i < tokenLockOwner[Owner].length; i++){                            // loop through the lock identifier array
            uint256 lockID = tokenLockOwner[Owner][i];                                      // get the lockID
            if(lockID != 0 && tokenLockID[lockID].processed){                               // if not deleted and processed
                cnt++;                                                                      // increment the count
            }                                                                               //
        }                                                                                   //
        uint256[] memory locks = new uint256[](cnt);                                        // instaniate the lock array
        uint idx = 0;                                                                       // init lock array indexer
        for (uint i = 0; i < tokenLockOwner[Owner].length; i++){                            // loop through the lock identifier array
            uint256 lockID = tokenLockOwner[Owner][i];                                      // get the lockID
            if(lockID != 0 && tokenLockID[lockID].processed){                               // if not deleted and processed
                locks[idx] = lockID;                                                        // push lockID
                idx++;                                                                      // increment array index
            }                                                                               //
        }                                                                                   //
        return locks;                                                                       // return processed lock array of the owner
    }                                                                                       //
    //////////////////////////////////////////////////////////////////////////////////////////
    /* Method for enumeration of all token locks                                            */
    /* ACCESS           : None/Public                                                       */
    /* PARAMETERS       :-                                                                  */
    /*   token          : token address                                                     */
    /* RETURNS          :-                                                                  */
    /*   array          : array of lockID(s)                                                */
    //////////////////////////////////////////////////////////////////////////////////////////
    function enumAllTokenLocks(address token) external view returns (uint256[] memory) {    //
        uint cnt = 0;                                                                       // cnt of elements for the dynamic array instaniation
        for (uint i = 0; i < tokenLockAddr[token].length; i++){                             // loop through the lock identifier array
            uint256 lockID = tokenLockAddr[token][i];                                       // get the lockID
            if(lockID != 0){                                                                // if not deleted
                cnt++;                                                                      // increment the count
            }                                                                               //
        }                                                                                   //
        uint256[] memory locks = new uint256[](cnt);                                        // instaniate the lock array
        uint idx = 0;                                                                       // init lock array indexer
        for (uint i = 0; i < tokenLockAddr[token].length; i++){                             // loop through the lock identifier array
            uint256 lockID = tokenLockAddr[token][i];                                       // get the lockID
            if(lockID != 0){                                                                // if not deleted
                locks[idx] = lockID;                                                        // push lockID
                idx++;                                                                      // increment array index
            }                                                                               //
        }                                                                                   //
        return locks;                                                                       // return all lock array of the token
    }                                                                                       //
    //////////////////////////////////////////////////////////////////////////////////////////
    /* Method for enumeration of Active token locks                                         */
    /* ACCESS           : None/Public                                                       */
    /* PARAMETERS       :-                                                                  */
    /*   token          : token address                                                     */
    /* RETURNS          :-                                                                  */
    /*   array          : array of lockID(s)                                                */
    //////////////////////////////////////////////////////////////////////////////////////////
    function enumActiveTokenLocks(address token) external view returns (uint256[] memory) { //
        uint cnt = 0;                                                                       // cnt of elements for the dynamic array instaniation
        for (uint i = 0; i < tokenLockAddr[token].length; i++){                             // loop through the lock identifier array
            uint256 lockID = tokenLockAddr[token][i];                                       // get the lockID
            if(lockID != 0 && !tokenLockID[lockID].processed){                              // if not deleted and not processed
                cnt++;                                                                      // increment the count
            }                                                                               //
        }                                                                                   //
        uint256[] memory locks = new uint256[](cnt);                                        // instaniate the lock array
        uint idx = 0;                                                                       // init lock array indexer
        for (uint i = 0; i < tokenLockAddr[token].length; i++){                             // loop through the lock identifier array
            uint256 lockID = tokenLockAddr[token][i];                                       // get the lockID
            if(lockID != 0 && !tokenLockID[lockID].processed){                              // if not deleted and not processed
                locks[idx] = lockID;                                                        // push lockID
                idx++;                                                                      // increment array index
            }                                                                               //
        }                                                                                   //
        return locks;                                                                       // return active lock array of the token
    }                                                                                       //
    //////////////////////////////////////////////////////////////////////////////////////////
    /* Method for enumeration of Processed token locks                                      */
    /* ACCESS           : None/Public                                                       */
    /* PARAMETERS       :-                                                                  */
    /*   token          : token address                                                     */
    /* RETURNS          :-                                                                  */
    /*   array          : array of lockID(s)                                                */
    //////////////////////////////////////////////////////////////////////////////////////////
    function enumProcessedTokenLocks(address token) external view returns (uint256[] memory) {
        uint cnt = 0;                                                                       // cnt of elements for the dynamic array instaniation
        for (uint i = 0; i < tokenLockAddr[token].length; i++){                             // loop through the lock identifier array
            uint256 lockID = tokenLockAddr[token][i];                                       // get the lockID
            if(lockID != 0 && tokenLockID[lockID].processed){                               // if not deleted and processed
                cnt++;                                                                      // increment the count
            }                                                                               //
        }                                                                                   //
        uint256[] memory locks = new uint256[](cnt);                                        // instaniate the lock array
        uint idx = 0;                                                                       // init lock array indexer
        for (uint i = 0; i < tokenLockAddr[token].length; i++){                             // loop through the lock identifier array
            uint256 lockID = tokenLockAddr[token][i];                                       // get the lockID
            if(lockID != 0 && tokenLockID[lockID].processed){                               // if not deleted and processed
                locks[idx] = lockID;                                                        // push lockID
                idx++;                                                                      // increment array index
            }                                                                               //
        }                                                                                   //
        return locks;                                                                       // return processed lock array of the token
    }                                                                                       //
    /****************************************************************************************/
    /*                              Internal Methods                                        */
    /****************************************************************************************/
    //////////////////////////////////////////////////////////////////////////////////////////
    /* check/update multi-sig method authorization                                          */
    /* PARAMETERS       :-                                                                  */
    /*   reqID          : Multi-Seg Request Identifier                                      */
    /* RETURNS          :-                                                                  */
    /*   bool           : Success Status                                                    */
    //////////////////////////////////////////////////////////////////////////////////////////
    function authorize(uint reqID, address newWallet) internal returns(bool){               //
        require(!multiSigReq[reqID].processed, 'HIVELock: Request Already Processed' );     // revert if auth request is processed
        for (uint i = 0; i < multiSigReq[reqID].sigs.length; i++) {                         // ensure the sender has not already approved
            require(_msgSender() != multiSigReq[reqID].sigs[i], 'HIVELock: Already Signed the Request' );
        }                                                                                   //
        if(multiSigReq[reqID].newDevWallet == address(0))                                   // is first vote?
            multiSigReq[reqID].newDevWallet = newWallet;                                    // set the wallet under voting
        else if(multiSigReq[reqID].newDevWallet != newWallet)                               // ensure voting for the same wallet
            revert('HiveLock: MultiSig invalid param');                                     // revert on wrong input devWallet
        multiSigReq[reqID].sigs.push(_msgSender());                                         // increment no of approvals
        emit MultiSigApprove(reqID, multiSigReq[reqID].sigs.length, _msgSender(), newWallet, block.timestamp);
        if(multiSigReq[reqID].sigs.length >= 3)                                             // minimum of 3 wallets approvals needed to auth
            return true;                                                                    // authorized
        else                                                                                //
            return false;                                                                   // need more approvals
    }                                                                                       //
    //////////////////////////////////////////////////////////////////////////////////////////
    /* calculate the amount of token that can be withdrawn according to lock type           */
    /* PARAMETERS       :-                                                                  */
    /*   TokenLock      : token lock struct                                                 */
    /* RETURNS          :-                                                                  */
    /*   amount         : amount available to withdraw                                      */
    //////////////////////////////////////////////////////////////////////////////////////////
    function calcWithdrawAmount(TokenLock memory lock) internal view returns(uint256 amount){
        if(lock.lockType == lockType.regular){                                              // regular lock:: revert if unlockTimestamp is not met
            require(block.timestamp > lock.unlockTimestamp, 'HIVELock: UnlockTimestamp is not met' );
            amount = lock.amount;                                                           // all amount is available since unlock timestamp has passed
        } else if(lock.lockType == lockType.linear){                                        // linear lock::
            if(block.timestamp > lock.unlockTimestamp){                                     // have the final unocktimestamp passed?
                amount = lock.amount.sub(lock.withdrawn);                                   // all remaining tokens are avilable
            } else {                                                                        // still in linear mode
                uint grossAmount = lock.amount.mul(block.timestamp.sub(lock.lockTimestamp)).div(lock.unlockTimestamp.sub(lock.lockTimestamp));
                amount = grossAmount.sub(lock.withdrawn);                                   // avilable is difference between linear value and alreeady withdrawn
            }                                                                               //
        } else {                                                                            // complex lock::
            if(block.timestamp > lock.unlockTimestamp){                                     // have the final unocktimestamp passed?
                amount = lock.amount.sub(lock.withdrawn);                                   // all remaining tokens are avilable
            } else if(block.timestamp > lock.linearStart) {                                 // in linear mode
                uint grossAmount = lock.amount.mul(block.timestamp.sub(lock.linearStart)).div(lock.unlockTimestamp.sub(lock.linearStart));
                amount = grossAmount.sub(lock.withdrawn);                                   // avilable is difference between linear value and alreeady withdrawn
            } else {                                                                        // still in regular mode
                revert('HiveLock:: still in regular mode period');                          // revert as no tokens avail
            }                                                                               //
        }                                                                                   //
    }                                                                                       //
    //////////////////////////////////////////////////////////////////////////////////////////
    /* Method for removing an array item and resizing the array                             */
    /* PARAMETERS       :-                                                                  */
    /*   arr            : array to be processed                                             */
    /*   item           : array item to be removed                                          */
    /* RETURNS          : void                                                              */
    //////////////////////////////////////////////////////////////////////////////////////////
    function removeOwnerLock(address owner, uint256 lockID) internal  {                     //
        for (uint i = 0; i < tokenLockOwner[owner].length; i++){                            // loop through locks
            if(tokenLockOwner[owner][i] == lockID){                                         // check for a match
                delete tokenLockOwner[owner][i];                                            // delete the array element
                break;                                                                      // abort the loop
            }                                                                               //
        }                                                                                   //
    }                                                                                       //
}                                                                                           //