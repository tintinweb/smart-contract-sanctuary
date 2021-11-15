// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.6;


import "./SafeMath.sol";
import "./Context.sol";     
import "./IERC20.sol";      // Need this to withdraw certain tokens
import "./SafeERC20.sol";   // withdraw airdropped token




/*

HOW TO USE THE FAUCET SYSTEM




01. Send the Token to the Faucet Contract
02. Have the director of the faucet contract either initialize you as manager or the director can initialize the faucet himself.
03. Initialize Fuacet for Token - input address, amount (with decimals of token), and cooldown time (in second unix time)
04. Make sure that the Faucet Contract is excluded from Taxes and Transfer Restrictions
04. Enable Faucet








*/


contract Faucet is Context {







    //////////////////////////// USING STATEMENTS ////////////////////////////
    using SafeMath for uint256;
    using SafeERC20 for IERC20; // this is for IERC20 tokens that you can store in the airdrop contract
    //////////////////////////// USING STATEMENTS ////////////////////////////








    //////////////////////////// AIRDROP CONTRACT INFO VARS ////////////////////////////
    uint256 public releaseDateUnixTimeStamp = block.timestamp;     // Version 2 Release Date
    //////////////////////////// AIRDROP CONTRACT INFO VARS ////////////////////////////








    //////////////////////////// DEAD ADDRESSES ////////////////////////////
    address public deadAddressZero = 0x0000000000000000000000000000000000000000; 
    address public deadAddressOne = 0x0000000000000000000000000000000000000001; 
    address public deadAddressdEaD = 0x000000000000000000000000000000000000dEaD; 
    //////////////////////////// DEAD ADDRESSES ////////////////////////////











    //////////////////////////// ACCESS CONTROL VARS ////////////////////////////
    address public directorAccount = 0x8C7Ad6F014B46549875deAD0f69919d643a50bA3;      // CHANGEIT - get the right director account

    // This will keep track of who is the manager of a token. 
    // Managers can initialize faucets for a specific address
    mapping(address => address) public tokenAddressToManagerAddress;       
    //////////////////////////// ACCESS CONTROL VARS ////////////////////////////













    
    //////////////////////////// FAUCET VARS ////////////////////////////  
    mapping(address => bool) public isFaucetEnabled;    
    mapping(address => uint256) public amountToGiveForAddress;    
    mapping(address => uint256) public cooldownTimeForAddress;   
    mapping(address => bool) public isClaiming;     // reentrancy guard
    mapping(address => mapping(address => uint256)) public tokenAddressToUserAddressToClaimTime;    // when has the user claimed from the faucet, last - if 0, has not claimed
    //////////////////////////// FAUCET VARS ////////////////////////////  


















    //////////////////////////// EVENTS ////////////////////////////
    event InitilizationOfFaucet(address indexed tokenAddress, address indexed initializerAddress, uint256 currentBlockTime);
    event FaucetEnabled(address indexed tokenAddress, address indexed initializerAddress, uint256 currentBlockTime);
    event FaucetDisabled(address indexed tokenAddress, address indexed initializerAddress, uint256 currentBlockTime);
    event FaucetUsed(address indexed tokenAddress, address indexed claimer, uint256 amountGiven, uint256 currentBlockTime);

    event TransferedDirectorAccount(address indexed oldDirectorAccount, address indexed newDirectorAccount, uint256 currentBlockTime);
    event ManagerInitialized(address indexed tokenAddress, address indexed managerAddress, uint256 currentBlockTime);

    event ETHwithdrawnRecovered(address indexed claimerWalletOwner, uint256 indexed ethClaimedRecovered, uint256 currentBlockTime);
    event ERC20tokenWithdrawnRecovered(address indexed tokenAddress, address indexed claimerWalletOwner, uint256 indexed balanceClaimedRecovered, uint256 currentBlockTime);
    //////////////////////////// EVENTS ////////////////////////////




















    //////////////////////////// ACCESS CONTROL MODIFIERS ////////////////////////////
    modifier OnlyDirector() {
        require(directorAccount == _msgSender(), "Caller must be the Director");
        _;
    }

    modifier OnlyStaff(address tokenAddress) {
        address managerAddress = tokenAddressToManagerAddress[tokenAddress];
        require(managerAddress == _msgSender() || directorAccount == _msgSender(), "Caller must be Director or Manager");
        _;
    }
    //////////////////////////// ACCESS CONTROL MODIFIERS ////////////////////////////










    //////////////////////////// ACCESS CONTROL FUNCTIONS ////////////////////////////
    function TransferDirectorAccount(address newDirectorAccount) public virtual OnlyDirector() {
        address oldDirectorAccount = directorAccount;
        directorAccount = newDirectorAccount;
        emit TransferedDirectorAccount(oldDirectorAccount, newDirectorAccount, GetCurrentBlockTime());
    }

    function InitializeManagerForToken(address tokenAddress, address managerAddress) external OnlyDirector() { 
        tokenAddressToManagerAddress[tokenAddress] = managerAddress;
        emit ManagerInitialized(tokenAddress, managerAddress, GetCurrentBlockTime());
    }
    //////////////////////////// ACCESS CONTROL FUNCTIONS ////////////////////////////













    //////////////////////////// FAUCET FUNCTIONS ////////////////////////////  
    function InitializeFaucetForToken(address tokenAddress, uint256 amountToGivePerClaim, uint256 cooldownTimeBetweenClaims) external OnlyStaff(tokenAddress) { 

        // amount to give is including the decimal spaces
        require(amountToGivePerClaim > 0, "Amount to give per claim must be greater than 0");
        amountToGiveForAddress[tokenAddress] = amountToGivePerClaim;

        // if cooldownTime is set to 0 then there it is assumed that each address can only claim once.
        cooldownTimeForAddress[tokenAddress] = cooldownTimeBetweenClaims;

        emit InitilizationOfFaucet(tokenAddress, _msgSender(), GetCurrentBlockTime());
    }

    function EnableFaucet(address tokenAddress) public OnlyStaff(tokenAddress) {
        isFaucetEnabled[tokenAddress] = true;
        emit FaucetEnabled(tokenAddress, _msgSender(), GetCurrentBlockTime());
    }

    function DisableFaucet(address tokenAddress) public OnlyStaff(tokenAddress) {
        isFaucetEnabled[tokenAddress] = false;
        emit FaucetDisabled(tokenAddress, _msgSender(), GetCurrentBlockTime());
    }



    function FaucetClaim(address tokenAddress) public {    

        address claimer = _msgSender();

        require(!isClaiming[claimer], "Claim one at a time");
        isClaiming[claimer] = true;

        require(isFaucetEnabled[tokenAddress], "Faucet must be enabled. It is currently disabled. Contact the Director or the Manager of this Token.");  


        uint256 lastClaimTime = tokenAddressToUserAddressToClaimTime[tokenAddress][claimer];
        tokenAddressToUserAddressToClaimTime[tokenAddress][claimer] = GetCurrentBlockTime();        // set for reetrancy

        uint256 amountoToGive = amountToGiveForAddress[tokenAddress];

        uint256 cooldownTime = cooldownTimeForAddress[tokenAddress];

        if(cooldownTime != 0){
            require(GetCurrentBlockTime() > lastClaimTime.add(cooldownTime), "You must wait until the cooldown finishes to get more of the token.");
        }
        else{   // if the cool down time is zero, the the user can only claim once
            require(lastClaimTime == 0, "You can only claim this token once.");
        }

        // There needs to be enough token in the contract for the faucet to give
        require(CurrentFaucetTokenSupplyInContract(IERC20(tokenAddress)) >= amountoToGive,"Not enough Airdrop Token in Contract");   

        IERC20(tokenAddress).safeTransfer(PayableInputAddress(claimer), amountoToGive);

        emit FaucetUsed(tokenAddress, claimer, amountoToGive, GetCurrentBlockTime());

        isClaiming[claimer] = false;

    }

    function CurrentFaucetTokenSupplyInContract(IERC20 tokenAddress) public view returns (uint256) {
        return tokenAddress.balanceOf(address(this));
    }



    function isFaucetUsable(address tokenAddress, address userAddress) public view returns (bool) {

        uint256 cooldownTime = cooldownTimeForAddress[tokenAddress];
        uint256 lastClaimTime = tokenAddressToUserAddressToClaimTime[tokenAddress][userAddress];

        if(cooldownTime != 0){
            if(GetCurrentBlockTime() > lastClaimTime.add(cooldownTime)){
                return true;
            }
        }
        else{   // if the cool down time is zero, the the user can only claim once
            if(lastClaimTime == 0){
                return true;
            }
        }
        return false;
    }
    //////////////////////////// FAUCET FUNCTIONS ////////////////////////////  









































    //////////////////////////// RESCUE FUNCTIONS ////////////////////////////
    function RescueAllETHSentToContractAddress() external OnlyDirector()  {   
        uint256 balanceOfContract = address(this).balance;
        PayableInputAddress(directorAccount).transfer(balanceOfContract);
        emit ETHwithdrawnRecovered(directorAccount, balanceOfContract, GetCurrentBlockTime());
    }

    function RescueAmountETHSentToContractAddress(uint256 amountToRescue) external OnlyDirector()  {   
        PayableInputAddress(directorAccount).transfer(amountToRescue);
        emit ETHwithdrawnRecovered(directorAccount, amountToRescue, GetCurrentBlockTime());
    }

    function RescueAllTokenSentToContractAddressAsDirector(IERC20 tokenToWithdraw) external OnlyDirector() {
        uint256 balanceOfContract = tokenToWithdraw.balanceOf(address(this));
        tokenToWithdraw.safeTransfer(PayableInputAddress(directorAccount), balanceOfContract);
        emit ERC20tokenWithdrawnRecovered(address(tokenToWithdraw), directorAccount, balanceOfContract, GetCurrentBlockTime());
    }

    function RescueAmountTokenSentToContractAddressAsDirector(IERC20 tokenToWithdraw, uint256 amountToRescue) external OnlyDirector() {
        tokenToWithdraw.safeTransfer(PayableInputAddress(directorAccount), amountToRescue);
        emit ERC20tokenWithdrawnRecovered(address(tokenToWithdraw), directorAccount, amountToRescue, GetCurrentBlockTime());
    }

    function RescueAllTokenSentToContractAddressAsManager(IERC20 tokenToWithdraw) external OnlyStaff(address(tokenToWithdraw)) {
        address tokenAddress = address(tokenToWithdraw);
        address managerOfToken = tokenAddressToManagerAddress[tokenAddress];
        uint256 balanceOfContract = tokenToWithdraw.balanceOf(address(this));
        tokenToWithdraw.safeTransfer(PayableInputAddress(directorAccount), balanceOfContract);
        emit ERC20tokenWithdrawnRecovered(address(tokenToWithdraw), managerOfToken, balanceOfContract, GetCurrentBlockTime());
    }

    function RescueAmountTokenSentToContractAddressAsManager(IERC20 tokenToWithdraw, uint256 amountToRescue) external OnlyStaff(address(tokenToWithdraw)) {
        address tokenAddress = address(tokenToWithdraw);
        address managerOfToken = tokenAddressToManagerAddress[tokenAddress];
        tokenToWithdraw.safeTransfer(PayableInputAddress(directorAccount), amountToRescue);
        emit ERC20tokenWithdrawnRecovered(address(tokenToWithdraw), managerOfToken, amountToRescue, GetCurrentBlockTime());
    }
    //////////////////////////// RESCUE FUNCTIONS ////////////////////////////






















    //////////////////////////// MISC INFO FUNCTIONS ////////////////////////////  
    function PayableInputAddress(address inputAddress) internal pure returns (address payable) {   // gets the sender of the payable address
        address payable payableInAddress = payable(address(inputAddress));
        return payableInAddress;
    }

    function GetCurrentBlockTime() public view returns (uint256) {
        return block.timestamp;     // gets the current time and date in Unix timestamp
    }

    function GetCurrentBlockDifficulty() public view returns (uint256) {
        return block.difficulty;  
    }

    function GetCurrentBlockNumber() public view returns (uint256) {
        return block.number;      
    }

    function GetCurrentBlockStats() public view returns (uint256,uint256,uint256) {
        return (block.number, block.difficulty, block.timestamp);      
    }
    //////////////////////////// MISC INFO FUNCTIONS ////////////////////////////  









    receive() external payable { }      // oh it's payable alright
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;


interface IERC20 {

    // Functions
    
    function totalSupply() external view returns (uint256);     // Returns the amount of tokens in existence.

    function decimals() external view returns (uint8);  // Returns the token decimals.

    function symbol() external view returns (string memory); // Returns the token symbol.

    function name() external view returns (string memory); // Returns the token name.

    function getOwner() external view returns (address); // Returns the bep token owner.

    function balanceOf(address account) external view returns (uint256);   // Returns the amount of tokens owned by `account`
    
    function transfer(address recipient, uint256 amount) external returns (bool);  // transfer tokens to addr, Emits a {Transfer} event.

    function allowance(address _owner, address spender) external view returns (uint256); // Returns remaining tokens that spender is allowed during {approve} or {transferFrom} 

    function approve(address spender, uint256 amount) external returns (bool); // sets amount of allowance, emits approval event

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool); // move amount, then reduce allowance, emits a transfer event


    // Events

    event Transfer(address indexed from, address indexed to, uint256 value);    // emitted when value tokens moved, value can be zero

    event Approval(address indexed owner, address indexed spender, uint256 value);  // emits when allowance of spender for owner is set by a call to approve. value is new allowance

}

// SPDX-License-Identifier: MIT
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/utils/SafeERC20.sol
// this has been slightly modified to incorporate ERC20 naming conventions as well as inhereting contracts in different places

pragma solidity ^0.8.6;

import "./IERC20.sol";
import "./Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

