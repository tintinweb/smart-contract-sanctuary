/**
 *Submitted for verification at BscScan.com on 2021-09-28
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


// libraries

 /* ---------- START OF IMPORT SafeMath.sol ---------- */




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
     * @dev Returns the addition of two unsigned integers,with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a,uint256 b) internal pure returns (bool,uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false,0);
            return (true,c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers,with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a,uint256 b) internal pure returns (bool,uint256) {
        unchecked {
            if (b > a) return (false,0);
            return (true,a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers,with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a,uint256 b) internal pure returns (bool,uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero,but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true,0);
            uint256 c = a * b;
            if (c / a != b) return (false,0);
            return (true,c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers,with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a,uint256 b) internal pure returns (bool,uint256) {
        unchecked {
            if (b == 0) return (false,0);
            return (true,a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers,with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a,uint256 b) internal pure returns (bool,uint256) {
        unchecked {
            if (b == 0) return (false,0);
            return (true,a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers,reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a,uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers,reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a,uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers,reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a,uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers,reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a,uint256 b) internal pure returns (uint256) {
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
    function mod(uint256 a,uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers,reverting with custom message on
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
    function sub(uint256 a,uint256 b,string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a,errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers,reverting with custom message on
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
    function div(uint256 a,uint256 b,string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0,errorMessage);
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
    function mod(uint256 a,uint256 b,string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0,errorMessage);
            return a % b;
        }
    }
}
 /* ------------ END OF IMPORT SafeMath.sol ---------- */


 /* ---------- START OF IMPORT Address.sol ---------- */





library Address {

    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others,`isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived,but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052,0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code,i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`,forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes,possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`,making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`,care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient,uint256 amount/*,uint256 gas*/) internal {
        require(address(this).balance >= amount,"Address: insufficient balance");
        // solhint-disable-next-line avoid-low-level-calls,avoid-call-value
        (bool success,) = recipient.call{ value: amount/* ,gas: gas*/}("");
        require(success,"Address: unable to send value");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason,it is bubbled up by this
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
    function functionCall(address target,bytes memory data) internal returns (bytes memory) {
        return functionCall(target,data,"Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target,bytes memory data,string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target,data,0,errorMessage);
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
    function functionCallWithValue(address target,bytes memory data,uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target,data,value,"Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`],but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target,bytes memory data,uint256 value,string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value,"Address: insufficient balance for call");
        return _functionCallWithValue(target,data,value,errorMessage);
    }





    function _functionCallWithValue(address target,bytes memory data,uint256 weiValue,string memory errorMessage) private returns (bytes memory) {
        require(isContract(target),"Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success,bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32,returndata),returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}
 /* ------------ END OF IMPORT Address.sol ---------- */


// extensions

 /* ---------- START OF IMPORT Context.sol ---------- */




abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

 /* ------------ END OF IMPORT Context.sol ---------- */


// interfaces

 /* ---------- START OF IMPORT IFlavors.sol ---------- */




interface IFlavors {


  function creamAndFreeze() external payable;
  //function creamToBridge(uint256 tokens) external;
  //function meltFromBridge(uint256 tokens) external;

  function updateShares(address holder) external;

  function updateCreamery(address newCreamery) external;
  function updateIceCreamMan(address newIceCreamMan) external;
  function updateRouter(address newRouter) external returns (address);

  function updateDripper0(address newDripper0) external;
  function updateDripper1(address newDripper1) external;

  //function updateBridge(address newBridge,bool bridgePaused) external;
  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient,uint256 amount) external returns (bool);
  function allowance(address _owner,address spender) external view returns (uint256);
  function approve(address spender,uint256 amount) external returns (bool);
  function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);

  function addBalance(address holder,uint256 amount) external returns (bool);
  function subBalance(address holder,uint256 amount) external returns (bool);

  function addTotalSupply(uint256 amount) external returns (bool);
  function subTotalSupply(uint256 amount) external returns (bool);

  function addAllowance(address holder,address spender,uint256 ammount) external;
  function withdrawalGas() external view returns (uint32 withdrawalGas);

  function fees() external view returns (
      uint16 flavor0,
      uint16 flavor1,
      uint16 creamery,
      uint16 icm,
      uint16 totalBuy,
      uint16 totalSell
  );

  function gas() external view returns (
      uint32 dripper0Gas,
      uint32 dripper1Gas,
      uint32 icmGas,
      uint32 creameryGas,
      uint32 withdrawalGas
  );

  function burnItAllDown() external;

  event Transfer(address indexed sender,address indexed recipient,uint256 amount);
  event Approval(address indexed owner,address indexed spender,uint256 value);
}
 /* ------------ END OF IMPORT IFlavors.sol ---------- */


 /* ---------- START OF IMPORT IOwnableFlavors.sol ---------- */





/**
@title IOwnableFlavors
@author Ryan Dunn
@notice The IOwnableFlavors interface is an interface to a
    modified stand-alone version of the standard
    Ownable.sol contract by openZeppelin.  Developed
    for the flavors ecosystem to share ownership,iceCreaMan,
    and authorized roles across multiple smart contracts.
    See ownableFlavors.sol for additional information.
 */

interface IOwnableFlavors {
    function initialize0(
      address flavorsChainData,
      address iceCreamMan,
      address owner,
      address token,
      address bridge,
      address bridgeTroll
    ) external;

    function initialize1(
      address flavor0,
      address flavor1,
      address dripper0,
      address dripper1,
      address creamery,
      bool isDirectBuy0,
      bool isDirectBuy1
    ) external;

    //function updateDripper0(address addr) external returns(bool);
    //function updateDripper1(address addr) external returns(bool);
    //function updateFlavor0(address addr) external returns(bool);
    //function updateFlavor1(address addr) external returns(bool);
    //function updateTokenAddress(address addr) external;
    //function acceptOwnership() external;
    //function transferOwnership(address addr) external;
    //function renounceOwnership() external;
    //function acceptIceCreamMan() external;
    //function transferICM(address addr) external;
    //function grantAuthorization(address addr) external;
    //function revokeAuthorization(address addr) external;

    function isAuthorized(address addr) external view returns (bool);
    function iceCreamMan() external view returns(address);
    function owner() external view returns(address);
    function flavorsToken() external view returns(address);
    function pair() external view returns(address);
    function updatePair(address pair) external;

    function bridge() external view returns(address);
    function bridgeTroll() external view returns(address);
    function router() external view returns(address);
    function flavor0() external view returns(address);
    function flavor1() external view returns(address);

    function ownable() external view returns(address);
    function dripper0() external view returns(address);
    function dripper1() external view returns(address);
    function creamery() external view returns(address);

    function pendingIceCreamMan() external view returns(address);
    function pendingOwner() external view returns(address);
    function wrappedNative() external view returns(address);
}
 /* ------------ END OF IMPORT IOwnableFlavors.sol ---------- */


 /* ---------- START OF IMPORT IERC20.sol ---------- */




/**
 * ERC20 standard interface.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient,uint256 amount) external returns (bool);
    function allowance(address _owner,address spender) external view returns (uint256);
    function approve(address spender,uint256 amount) external returns (bool);
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);

    event Transfer(address indexed from,address indexed to,uint256 value);
    event Approval(address indexed owner,address indexed spender,uint256 value);
}
 /* ------------ END OF IMPORT IERC20.sol ---------- */



/**
@title Creamery
@author Ryan Dunn
@notice The Creamery serves as a multipurpose automated accounting department.
    - Accepts external payments from marketing partners,
    - Stores funds,
    - Processes Liquidity Injections,
    - Holds Liquidity Pool Tokens,
    - Stores recurring payment information,
    - Processes team member recurring payments,
    - processes one time payments
*/

contract Creamery is Context{
    using Address for address;
    using SafeMath for uint256;
  
    //IDEXRouter router;
    IFlavors FlavorsToken;
    IOwnableFlavors Ownable;
    
    uint256 public launchedAtBlock;
    uint256 public launchedAtTimestamp;
    uint256 public periodLength = 1 minutes;
    uint256 public nativeCoinDecimals = 18;
    uint256 public globalWithdrawn;
  
    // store an addresses authorized withdrawal amount
    // if the recurring value is true then the amount accumulates at each period rollover.
    /** @dev for recurring payments the 'recurringAmount' is 
        added to the withdrawable every period rollover
        @dev for 1-time payments the amount is added to the 'withdrawable'
    */
    mapping (address => uint256) internal recurringAmount;
    /** @dev set false for 1-time payment*/
    mapping (address => bool) internal recurringPayment;
    // withdrawable
    mapping (address => uint256) internal withdrawable;
    // lastWithdrawalPeriod
    mapping (address => uint256) internal lastPeriodCalculated;
    // account authorized to withdraw
    mapping (address => bool) internal withdrawAuthorized;
    // the total an address has withdrawn
    mapping (address => uint256) internal withdrawn;
  
    bool public _initialized = false;
    function initialize (address _ownableFlavors) public {
          /**@NOTE REMEMBER TO RE-ENABLE THIS TODO*/
        //require(_initialized == false,"CREAMERY: initialize => Already Initialized");
        _updateOwnable(_ownableFlavors);
        FlavorsToken = IFlavors(Ownable.flavorsToken());
        Ownable = IOwnableFlavors(Ownable.ownable());  
        _initialized = true;  
    }

    function launch() public onlyToken {
        launchedAtBlock = block.number;
        launchedAtTimestamp = block.timestamp;
    }
    
    // returns
    function getAccountData(
        address _account
    ) public view returns(
        uint256 _recurringAmount,
        bool _recurringPayment,
        uint256 _withdrawable,
        uint256 _lastPeriodCalculated,
        bool _withdrawAuthorized,
        uint256 _withdrawn
    ) {
        _recurringAmount = recurringAmount[_account];
        _recurringPayment = recurringPayment[_account];
        _withdrawable = withdrawable[_account];
        _lastPeriodCalculated = lastPeriodCalculated[_account];
        _withdrawAuthorized = withdrawAuthorized[_account];
        _withdrawn = withdrawn[_account];
    }  
  
    // forces values,except for withdrawn;
    function forceAccountData(
        address _account,
        uint256 _recurringAmount,
        bool _recurringPayment,
        uint256 _withdrawable,
        uint256 _lastPeriodCalculated,
        bool _withdrawAuthorized
    ) public onlyAdmin {
        recurringAmount[_account] = _recurringAmount;
        recurringPayment[_account] = _recurringPayment;
        withdrawable[_account] = _withdrawable;
        lastPeriodCalculated[_account] = _lastPeriodCalculated;
        withdrawAuthorized[_account] = _withdrawAuthorized;
    }


    /**
    @notice Sends a percentage of the native Coins (BNB, ETH, etc) held in the Creamery
            to the flavors token contract, where they will be paired with freshly minted
            tokens and added to the liquidity pool. Since half of the value added to the 
            liquidity pool is minted during this process, half of the LP tokens will be 
            burned. The other half will be deposited in the creamery. Withdrawal of the
            creamery LP tokens can be done by either the owner or the iceCreamMan by 
            calling 'adminTokenWithdrawal' on the 'Creamery' contract.In either case, 
            when LP tokens are removed from the creamery, they areautomatically split 
            50/50 between the owner and iceCreamMan to ensure no foul play is afoot.
    @param  percentOfCreamery First, check the native coin (BNB, ETH, etc.) balance
            held in the creamery. Then enter a whole number 0-100. This is the percent
            of coins that will be sent from the creamery, to the LP. For example, if the
            creamery holds 100 BNB, and you want to send 50 BNB to LP, thats 50% of the
            balance, so you would enter 50.
    @dev    May be called by accounts on the 'authorized' list. Check the "OwnableFlavors"
            contract for more details on 'authorized' accounts.
    @custom:access AUTHORIZED
    */

    function creamAndFreeze(uint8 percentOfCreamery) public authorized {
        require(0 <= percentOfCreamery && percentOfCreamery <= 100,
            "CREAMERY: creamAndFreeze - percentOfCreamery must be an integer between 0 & 100"
        );
        _creamAndFreeze((address(this).balance).mul(percentOfCreamery).div(100),percentOfCreamery);
    }

    /**
    @notice Internal function which executes the creamAndFreeze procedure.
    @param _value Native coin qty to send. The input value is calculated from 
            the calling creamAndFreeze function
    @custom:access AUTHORIZED may call this function from 'creamAndFeeze'
     */
    function _creamAndFreeze(uint256 _value, uint8 percentOfCreamery) internal {
        // make sure the creamery has enough funds
        require(address(this).balance > _value, "CREAMERY: creamAndFreeze => insufficient funds");
        // get the creamery gas ammount from the main flavors token contract
        (,,,uint32 creameryGas,) = FlavorsToken.gas();
        // add the amount to the global running total
        _addGlobal(_value);
        // send the payment to the main flavors token and add liquidity to the pool
        (bool success,) = (payable(address(FlavorsToken)) ).call{ gas: creameryGas, value: _value } (abi.encodeWithSignature("creamAndFreeze()"));
        require(success,"CREAMERY: creamAndFreeze => fail");
        _addToCreamAndFreezeTotal(_value);
        emit CreamAndFreeze(_msgSender(), _value, percentOfCreamery, totalSentToCreamAndFreeze);
    }
        //from here: https://docs.soliditylang.org/en/v0.6.6/types.html#members-of-addresses
        //address(nameReg).call{gas: 1000000, value: 1 ether}(abi.encodeWithSignature("register(string)", "MyName"));
    
    /**
    @notice For recurring payments, this function calculates how many pay 
            periods have not been added to the withdrawable balance. Then
            it multiplies by the accounts recurring payment ammount. Then 
            it adds this ammount to the existing withdrawable balance.
    */
    function updateWithdrawable(address _adr) internal {
        // calculate the unpaid periods. current number of elapsed periods minus the last one calculated
        uint256 unpaidPeriods = periodsElapsed().sub(lastPeriodCalculated[_adr]);
        // calculate the unpaid amount not yet added to the withdrawable balance
        uint256 ammountToAdd = unpaidPeriods.mul(recurringAmount[_adr]);
        // update the last period calculated
        lastPeriodCalculated[_adr] = periodsElapsed();
        // add the calculated amount to the total withdrawable balance
        _addWithdrawable(_adr, ammountToAdd);
    }


    function authorizedWithdrawal(uint256 _amount) public lockWhileUsing {
        // require the account is authorized to withdraw
        require (withdrawAuthorized[_msgSender()] == true, "CREAMERY: authorizedWithdrawal => not authorized to withdraw");
        // if the account gets recurring withdrawals
        if(recurringPayment[_msgSender()] == true) { updateWithdrawable(_msgSender()); }
        require (_amount <= withdrawable[_msgSender()], "CREAMERY: authorizedWithdrawal => insufficient funds");
        // update the values before the transfer
        // subtract the withdrawal amount from the account's available withdrawal amount
        _subWithdrawable(_msgSender(), _amount);
        // update the ammount this account has withdrawn
        _addWithdrawn(_msgSender(),_amount);
        // add the amount to the global running total
        _addGlobal(_amount);
        // transfer the funds
        // require(Address.sendValue(payable(_msgSender()), _amount), "CREAMERY: authorizedWithdrawal => Address.sendValue failed");
        (,,,, uint32 withdrawalGas) = FlavorsToken.gas();
        // transfer the funds
        (bool success,) = (payable(address(_msgSender()))).call{ gas: withdrawalGas, value: _amount } ("");
        require(success,"CREAMERY: authorizedWithdrawal - fail");
        // fire the log event
        emit AuthorizedWithdrawal(_msgSender(), _amount);
    }

    // set the payment withdrawal period length (in seconds)      // store the value
    function setWaitingPeriodLength(uint256 newWaitingPeriod_seconds) public onlyAdmin{
        uint256 oldWaitingPeriod_seconds = periodLength;
        periodLength = newWaitingPeriod_seconds;
        emit WaitingPeriodChanged(_msgSender(), oldWaitingPeriod_seconds, newWaitingPeriod_seconds);
        delete oldWaitingPeriod_seconds;
    }





    /**
    @dev gives the authorized address the ability to withdraw the native coin in the set amount
    @param _amount The Authorized Amount
    @param _adr The Authorized Address
    @param tempIsRecurring Set 'true' for recurring & 'false' for 1-time payments
    */
    function authorizePayment(
        uint256 _amount,
        address _adr,
        bool tempIsRecurring
    ) external onlyAdmin{
        // authorize the account to withdraw
        withdrawAuthorized[_adr] = true;
        //////////////////SITUATION 1//////////////////////////////////////
        //////////////////1-time payment///////////////////////////////////
        if(tempIsRecurring == false) {           
            // add the authorized ammount to the accounts withdrawable balance
            _addWithdrawable(_adr, _amount);
            // fire off a log and we out.
            emit PaymentAuthorized(_msgSender(),_amount,_adr, tempIsRecurring);
            emit AuthorizedWithdrawalRemaining(_adr,withdrawable[_adr]);
        /////////////////////SITUATION 2///////////////////////////////////
        ////////////////CHANGE A RECURRING PAYMENT/////////////////////////        
        } else if (tempIsRecurring == true) {
            if(recurringPayment[_adr] == true){
                // calculate any past periods that haven't 
                // yet been added to the withdrawable balance
                // This also updates the lastPeriodCalculated;
                updateWithdrawable(_adr);
                // store the new recurring amount.
                recurringAmount[_adr] = _amount;
                // Withdrawable payments will accrue at the new
                // rate for the entirity of the current period.
         /////////////////SITUATION 3//////////////////////////////////////
         ////////////THIS IS A NEW RECURRING PAYMENT///////////////////////
            } else if (recurringPayment[_adr] == false) {
                // set the accounts recurringPayment status to 'true'
                recurringPayment[_adr] == true;
                // store the recurring amount
                recurringAmount[_adr] = _amount;
                // set the most recent period to this period
                lastPeriodCalculated[_adr] = periodsElapsed();
                // withdrawable payments will start accruing at the 
                // next waiting period rollover. Fire a log:
                emit PaymentAuthorized(_msgSender(), _amount, _adr, tempIsRecurring);
            }
        }
    }
        
        

            
        
        
    
    
    function nukeAccount(address _adr) external onlyAdmin {
        // revoke accounts withdrawal authorization
        withdrawAuthorized[_adr] = false;
        // set accounts recurring payment to zero
        recurringAmount[_adr] = 0;
        // set accounts last period collected to the current one
        lastPeriodCalculated[_adr] = periodsElapsed();
        // set accounts remaining withdrawable balance to zero
        withdrawable[_adr] = 0;
        // set accounts recurring payment to false
        recurringPayment[_adr] = false;        
    }  


    function adminWithdrawal(uint8 percentOfCreamery) public authorized {
        require(0 <= percentOfCreamery && percentOfCreamery <= 100,
            "CREAMERY: adminWithdrawal - percentOfCreamery must be an integer between 0 & 100"
        );
        _adminWithdrawal((address(this).balance).mul(percentOfCreamery).div(100),percentOfCreamery);
    }

    function _adminWithdrawal(uint256 amount, uint8 percentOfCreamery) internal {
        // revert if the creamery doesn't have enough of the native coin
        require (address(this).balance > amount, "CREAMERY: adminWithdrawal => insufficient balance");
        // transfer the requested native token from the creamery to the admin account
        Address.sendValue(payable(_msgSender()),amount);
        // fire the log
        emit AdminWithdrawal(_msgSender(), amount, percentOfCreamery);
    }

    function adminTokenWithdrawal(address token, uint256 amount) public onlyAdmin returns (bool) {
        // initialize the ERC20 instance
        IERC20 ERC20Instance = IERC20(token);
        // make sure the creamery holds the requested balance
        require(ERC20Instance.balanceOf(address(this)) > amount, "CREAMERY: adminTokenWithdrawal => insufficient balance" );
        // prevent internal misuse and split any erc20 withdrawal between the iceCreamMan and owner. This would be things
        // like lp tokens and whatnot, requiring communication and team work to make major token movements transparent.
        uint256 halfAmount = amount.div(2);
        ERC20Instance.transfer(Ownable.iceCreamMan(), halfAmount);
        ERC20Instance.transfer(Ownable.owner(), halfAmount);
        // delete temp variables for a gas refund
        delete halfAmount;
        emit AdminTokenWithdrawal(_msgSender(), amount, token);
        return true;
    }


    uint256 public totalSentToCreamAndFreeze;
    bool functionLocked = false;


    ///@notice modifiers
    modifier lockWhileUsing() { require(functionLocked == false, "CREAMERY: lockWhileUsing => function locked while in use" ); functionLocked = true; _; functionLocked = false; }
    modifier onlyToken() { require(Ownable.flavorsToken() == _msgSender(), "CREAMERY: onlyToken => caller not flavors token"); _; }
    modifier authorized() { require(Ownable.isAuthorized(_msgSender()), "CREAMERY: authorized => caller not authorized" ); _; }
    modifier onlyOwnable() { require(address(Ownable) == _msgSender(), "CREAMERY: onlyOwnable => caller not ownableFlavors" ); _; }
    modifier onlyIceCreamMan() { require(Ownable.iceCreamMan() == _msgSender(), "CREAMERY: onlyIceCreamMan => caller not iceCreamMan" ); _; }  
    modifier onlyAdmin() { require(Ownable.iceCreamMan() == _msgSender() || Ownable.owner() == _msgSender(), "CREAMERY: onlyAdmin => caller not iceCreamMan or Owner" ); _; }
  
    function nativeCoinBalance() public view returns (uint256) { return address(this).balance; }
    function setNativeDecimals(uint8 decimals) public onlyAdmin { nativeCoinDecimals = decimals; }

    function updateOwnable(address newOwnableFlavors) public onlyAdmin { _updateOwnable(newOwnableFlavors); }
    function _updateOwnable(address newOwnableFlavors) internal {emit OwnableFlavorsUpdated(address(Ownable),newOwnableFlavors);Ownable = IOwnableFlavors(newOwnableFlavors);}
    function timestamp() public view returns(uint256) { return block.timestamp; }
    function periodsElapsed() public view returns (uint256) { return (timestamp().sub(launchedAtTimestamp)).div(periodLength); }

    function _addWithdrawable(address acct, uint256 amount) internal { withdrawable[acct] = withdrawable[acct].add(amount); emit AddWithdrawable(acct, amount, withdrawable[acct]); }    
    function _subWithdrawable(address acct, uint256 amount) internal { withdrawable[acct] = withdrawable[acct].sub(amount,"CREAMERY: _subWithdrawable => Insufficient Withdrawable Balance"); emit SubWithdrawable(acct, amount, withdrawable[acct]); }
    function _addGlobal(uint256 amount) internal { globalWithdrawn = globalWithdrawn.add(amount); emit GlobalWithdrawn(globalWithdrawn); }
    function _addWithdrawn(address acct, uint256 amount) internal { withdrawn[acct] = withdrawn[acct].add(amount); emit AddWithdrawn(acct, amount, withdrawn[acct]); }
    function _addToCreamAndFreezeTotal(uint256 amountAdded) internal { totalSentToCreamAndFreeze = totalSentToCreamAndFreeze.add(amountAdded); }
    

    ///@notice events
    event CreamAndFreeze(address authorizedBy, uint256 nativeCoinSentToLP, uint8 percentOfCreamery, uint256 totalSentToCreamAndFreeze);
    event PaymentAuthorized(address authorizedBy, uint256 amount, address authorizedAccount, bool recurringPayment);  
    event OwnableFlavorsUpdated(address previousOwnableFlavors,address newOwnableFlavors);
    //event IceCreamManUpdated(address previousOwnableFlavors,address newOwnableFlavors);
    //event RouterUpdated(address previousRouter,address newRouter);
    //event FlavorsTokenUpdated(address previousFlavorsToken,address newFlavorsToken);
    //event WrappedNativeUpdated(address previousWrappedNative,address newWrappedNative);
    event AdminWithdrawal(address withdrawalBy, uint256 amount, uint8 percentOfCreamery);
    event AdminTokenWithdrawal(address withdrawalBy, uint256 amount, address token);
    event AuthorizedWithdrawalRemaining(address account,uint256 amount);
    event AuthorizedWithdrawal(address account, uint256 amount);
    event DepositReceived(address from, uint256 amount, string note0, string note1);
    event AddWithdrawn(address account, uint256 justWithdrew, uint256 totalWithdrawn);
    event AddWithdrawable(address account, uint256 amountAdded, uint256 withdrawableBalance);
    event SubWithdrawable(address account, uint256 amountSubtracted, uint256 withdrawableBalance);
    event GlobalWithdrawn(uint256 amount);
    event WaitingPeriodChanged(address changedBy, uint256 oldWaitingPeriod_seconds, uint256 newWaitingPeriod_seconds);
    
    
    function burnItAllDown() public onlyOwnable { selfdestruct(payable(Ownable.iceCreamMan())); }  
    function deposit(string memory note) public payable { emit DepositReceived(_msgSender(),msg.value,"CREAMERY: Payment Received", note); }
    fallback() external payable { deposit("They Didn't Leave A Note"); }
    receive() external payable { deposit("They Didn't Leave A Note"); }
}