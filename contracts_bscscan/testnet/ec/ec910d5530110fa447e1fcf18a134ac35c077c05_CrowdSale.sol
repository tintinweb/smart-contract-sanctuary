/**
 *Submitted for verification at BscScan.com on 2021-12-11
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.6.12;

//import "https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
// pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

interface IBEP20 {

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = now + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(now > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}
// BNB 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE 0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526
//
// BUSD 0xcBb98864Ef56E9042e7d2efef76141f15731B82f 0x9331b55D9830EF609A2aBCfAc0FBCE050A52fdEa
// 
// BETH 0x2A3796273d47c4eD363b361D3AEFb7F7E2A13782 0x143db3CEEfbdfe5631aDD3E50f7614B6ba708BA7
// WBNB 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE 0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526
// BXRP 0x93A67D414896A280bF8FFB3b389fE3686E014fda 0x4046332373C24Aed1dC8bAd489A04E187833B28d
contract CrowdSale is Context, Ownable {

    using SafeMath for uint256;
    using Address for address;

    // The token being sold
    IBEP20 public _freeToken;

    // 
    AggregatorV3Interface internal priceFeed;
    // AggregatorV3Interface internal priceBNBUSDFeed;
    // AggregatorV3Interface internal priceETHUSDFeed;
    // AggregatorV3Interface internal priceBUSDUSDFeed;
    // AggregatorV3Interface internal priceXRPUSDFeed;
    
    mapping(address => address) internal priceFeeder;
    
    // Address where funds are collected
    address public _wallet;

    uint public currentPhase;

    // 10 Phase
    uint256[10] phaseTokenAllocation = [180527139246600060000000000, 361054278493200100000000000, 4429811996795019500000000, 495967882359921600000000000, 535123172239584300000000000, 566173287125009400000000000, 591898303846270300000000000, 613857342918720500000000000, 633012229330244100000000000, 649998040515966900000000000];
    uint256[10] phaseWisePrice = [830900, 1830900, 2830900, 3830900, 4830900, 5830900, 6830900, 7830900, 8830900, 9830900];

    // //struct LiveSale {
    uint256 tokenAlloted;
    uint256 tokenPrice;

    // uint256 PhaseStartTime;
    // uint256 PhaseEndTime;
    uint256 public totalSoldToken;
    uint256 public tokenPhase;

    struct Phase {
        uint256 _startTime;
        uint256 _endTime;
        uint256 _soldToken;
    }

    mapping(uint256 => Phase) internal soldTokenOnEachPhase;

    // FREETOKER : 0x642703fFfcD6F040A0889843C1c31756849eDe84
    constructor (IBEP20 _freeToker, address _wallet) public {
        
        _wallet = _wallet;
        _freeToken = _freeToker;
        
        //    
        // CHAINLINK - USD PRICE FEEDE
        // TESTNET
        // priceBNBUSDFeed = AggregatorV3Interface(0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526);
        // priceETHUSDFeed = AggregatorV3Interface(0x143db3CEEfbdfe5631aDD3E50f7614B6ba708BA7);
        // priceBUSDUSDFeed = AggregatorV3Interface(0x9331b55D9830EF609A2aBCfAc0FBCE050A52fdEa);
        // priceXRPUSDFeed = AggregatorV3Interface(0x4046332373C24Aed1dC8bAd489A04E187833B28d);

        ///MAINNET
        // priceBNBUSDFeed = AggregatorV3Interface(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE);
        // priceETHUSDFeed = AggregatorV3Interface(0x2A3796273d47c4eD363b361D3AEFb7F7E2A13782);
        // priceBUSDUSDFeed = AggregatorV3Interface(0xcBb98864Ef56E9042e7d2efef76141f15731B82f);
        // priceXRPUSDFeed = AggregatorV3Interface(0x93A67D414896A280bF8FFB3b389fE3686E014fda);


        // DEV UNIT TESTING
        //priceFeeder[0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE] = 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE; 
        //priceFeeder[0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE] = 0x2A3796273d47c4eD363b361D3AEFb7F7E2A13782;
        priceFeeder[0x67c718DE55f09e24caf5C826e1E25Ff1dc98bB41] = 0x9331b55D9830EF609A2aBCfAc0FBCE050A52fdEa;
        priceFeeder[0x8860fEE0c8561bF592C0e3db5eB97545af110dc5] = 0x4046332373C24Aed1dC8bAd489A04E187833B28d;

        tokenPhase = 0;

        Phase storage phase = soldTokenOnEachPhase[tokenPhase];
        phase._startTime = block.timestamp;

        soldTokenOnEachPhase[tokenPhase] = phase;

        launchSale(phaseWisePrice[tokenPhase]);

    }

    function buyToken(address _purchaseTokenAddress, uint256 _amount) public {
        //
        require( IBEP20(_purchaseTokenAddress).allowance(_msgSender(), address(this)) >= _amount, "Error: Invalid Purchase");

        priceFeed = AggregatorV3Interface(priceFeeder[_purchaseTokenAddress]);

        uint256 priceInUSD = uint256(getLatestPrice(priceFeed));

        uint256 buyingAmount = ( priceInUSD / tokenPrice ) * 1_000_000_000_000_000_000;

        IBEP20(_purchaseTokenAddress).transferFrom(_msgSender(), _wallet, _amount);     // Pay

        IBEP20(_freeToken).transferFrom(_wallet, _msgSender(), buyingAmount);               // Recieve

        totalSoldToken = totalSoldToken.add(buyingAmount);

        if(totalSoldToken >= phaseTokenAllocation[tokenPhase] ) {
           
            Phase storage phase = soldTokenOnEachPhase[tokenPhase];
            phase._endTime = block.timestamp;
            phase._soldToken = totalSoldToken;

            soldTokenOnEachPhase[tokenPhase] = phase;

            totalSoldToken = 0;
            tokenPhase = tokenPhase + 1;

            launchSale(phaseWisePrice[tokenPhase]);
        }

    }

    //
    fallback() external payable { 
        
        uint256 sendBNB = msg.value;
        require(sendBNB > 0, "Error: Invalid purchase");

        priceFeed = AggregatorV3Interface(priceFeeder[0x67c718DE55f09e24caf5C826e1E25Ff1dc98bB41]);     // WBNB/USD Price Chainlink Testing

        uint256 priceInUSD = uint256(getLatestPrice(priceFeed)).mul(sendBNB);

        uint256 buyingAmount = priceInUSD.div(tokenPrice).mul(1_000_000_000_000_000_000);

        IBEP20(_freeToken).transferFrom(_wallet, _msgSender(), buyingAmount);               // Recieve

        // This forwards all available gas. Be sure to check the return value!
        (bool success, ) = _wallet.call.value(sendBNB)("");
        require(success, "Transfer failed.");

        totalSoldToken = totalSoldToken.add(priceInUSD);

        if(totalSoldToken >= phaseTokenAllocation[tokenPhase] ) {
   
            Phase storage phase = soldTokenOnEachPhase[tokenPhase];
            phase._endTime = block.timestamp;
            phase._soldToken = totalSoldToken;

            soldTokenOnEachPhase[tokenPhase] = phase;

            totalSoldToken = 0;
            tokenPhase = tokenPhase + 1;

            launchSale(phaseWisePrice[tokenPhase]);
        }
    
    }

    function launchSale(uint256 _tokenPrice) internal {
        tokenPrice = _tokenPrice;
    }

    // buyTokenBNH() external payable {
    //     emit Received(msg.sender, msg.value);
    // }

    /**
     * Returns the latest USD price 
     */
    function getLatestPrice(AggregatorV3Interface _priceFeed) public view returns (int) {
        (
            uint80 roundID,
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = _priceFeed.latestRoundData();

        return price;
    }

    function getPhase(uint256 _phaseId) public view returns (uint256, uint256, uint256) {
        Phase storage phase = soldTokenOnEachPhase[tokenPhase];

        return(phase._startTime, phase._endTime, phase._soldToken);
    }

}