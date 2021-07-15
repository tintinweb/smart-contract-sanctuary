/**
 *Submitted for verification at Etherscan.io on 2021-07-14
*/

// This example code is designed to quickly deploy an example contract using Remix.
// This example code is designed to quickly deploy an example contract using Remix.
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

// //import "https://raw.githubusercontent.com/smartcontractkit/chainlink/master/evm-contracts/src/v0.6/ChainlinkClient.sol";


// contract APIConsumer is ChainlinkClient {
  
//     uint256 public volume;
//     address owner;
//     address private oracle;
//     bytes32 private jobId;
//     uint256 private fee;
    
//     /**
//      * Network: Kovan
//      * Chainlink - 0x2f90A6D021db21e1B2A077c5a37B3C7E75D15b7e
//      * Chainlink - 29fa9aa13bf1468788b7cc4a500a45b8
//      * Fee: 0.1 LINKa
//      */
//     constructor() public {
//         setPublicChainlinkToken();
//         oracle = 0xAA1DC356dc4B18f30C347798FD5379F3D77ABC5b;
//         jobId = "c7dd72ca14b44f0c9b6cfcd4b7ec0a2c";
//         fee = 0.1 * 10 ** 18; // 0.1 LINK
//         owner = msg.sender;
//     }
//     /**
//      * Create a Chainlink request to retrieve API response, find the target
//      * data, then multiply by 1000000000000000000 (to remove decimal places from data).
//      ************************************************************************************
//      *                                    STOP!                                         * 
//      *         THIS FUNCTION WILL FAIL IF THIS CONTRACT DOES NOT OWN LINK               *
//      *         ----------------------------------------------------------               *
//      *         Learn how to obtain testnet LINK and fund this contract:                 *
//      *         ------- https://docs.chain.link/docs/acquire-link --------               *
//      *         ---- https://docs.chain.link/docs/fund-your-contract -----               *
//      *                                                                                  *
//      ************************************************************************************/
//     function requestVolumeData() public returns (bytes32 requestId) 
//     {
//         Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        
//         request.add("get", "https://apd1hf9jf9.execute-api.eu-central-1.amazonaws.com/day");
        
//         request.add("path", "SLA");
        
//         int timesAmount = 1;
//         request.addInt("times", timesAmount);
        
//         return sendChainlinkRequestTo(oracle, request, fee);
//     }
//     function fulfill(bytes32 _requestId, uint256 _volume) public recordChainlinkFulfillment(_requestId)
//     {
//         volume = _volume;
//     }
//     function providesla()public view returns(uint256)
//      {
//          return(volume);
//      }
//     /**
//      * Withdraw LINK from this contract
//      * 
//      * NOTE: DO NOT USE THIS IN PRODUCTION AS IT CAN BE CALLED BY ANY ADDRESS.
//      * THIS IS PURELY FOR EXAMPLE PURPOSES ONLY.
//      */
//     function withdrawLink() external {
//         LinkTokenInterface linkToken = LinkTokenInterface(chainlinkTokenAddress());
//         require(linkToken.transfer(msg.sender, linkToken.balanceOf(address(this))), "Unable to transfer");
//     }
// }
// library Address {
//     /**
//      * @dev Returns true if `account` is a contract.
//      *
//      * [IMPORTANT]
//      * ====
//      * It is unsafe to assume that an address for which this function returns
//      * false is an externally-owned account (EOA) and not a contract.
//      *
//      * Among others, `isContract` will return false for the following
//      * types of addresses:
//      *
//      *  - an externally-owned account
//      *  - a contract in construction
//      *  - an address where a contract will be created
//      *  - an address where a contract lived, but was destroyed
//      * ====
//      */
//     function isContract(address account) internal view returns (bool) {
//         // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
//         // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
//         // for accounts without code, i.e. `keccak256('')`
//         bytes32 codehash;
//         bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
//         // solhint-disable-next-line no-inline-assembly
//         assembly { codehash := extcodehash(account) }
//         return (codehash != accountHash && codehash != 0x0);
//     }

//     /**
//      * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
//      * `recipient`, forwarding all available gas and reverting on errors.
//      *
//      * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
//      * of certain opcodes, possibly making contracts go over the 2300 gas limit
//      * imposed by `transfer`, making them unable to receive funds via
//      * `transfer`. {sendValue} removes this limitation.
//      *
//      * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
//      *
//      * IMPORTANT: because control is transferred to `recipient`, care must be
//      * taken to not create reentrancy vulnerabilities. Consider using
//      * {ReentrancyGuard} or the
//      * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
//      */
//     function sendValue(address payable recipient, uint256 amount) internal {
//         require(address(this).balance >= amount, "Address: insufficient balance");

//         // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
//         (bool success, ) = recipient.call{ value: amount }("");
//         require(success, "Address: unable to send value, recipient may have reverted");
//     }

//     /**
//      * @dev Performs a Solidity function call using a low level `call`. A
//      * plain`call` is an unsafe replacement for a function call: use this
//      * function instead.
//      *
//      * If `target` reverts with a revert reason, it is bubbled up by this
//      * function (like regular Solidity function calls).
//      *
//      * Returns the raw returned data. To convert to the expected return value,
//      * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
//      *
//      * Requirements:
//      *
//      * - `target` must be a contract.
//      * - calling `target` with `data` must not revert.
//      *
//      * _Available since v3.1._
//      */
//     function functionCall(address target, bytes memory data) internal returns (bytes memory) {
//       return functionCall(target, data, "Address: low-level call failed");
//     }

//     /**
//      * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
//      * `errorMessage` as a fallback revert reason when `target` reverts.
//      *
//      * _Available since v3.1._
//      */
//     function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
//         return _functionCallWithValue(target, data, 0, errorMessage);
//     }

//     /**
//      * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
//      * but also transferring `value` wei to `target`.
//      *
//      * Requirements:
//      *
//      * - the calling contract must have an ETH balance of at least `value`.
//      * - the called Solidity function must be `payable`.
//      *
//      * _Available since v3.1._
//      */
//     function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
//         return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
//     }

//     /**
//      * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
//      * with `errorMessage` as a fallback revert reason when `target` reverts.
//      *
//      * _Available since v3.1._
//      */
//     function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
//         require(address(this).balance >= value, "Address: insufficient balance for call");
//         return _functionCallWithValue(target, data, value, errorMessage);
//     }

//     function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
//         require(isContract(target), "Address: call to non-contract");

//         // solhint-disable-next-line avoid-low-level-calls
//         (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
//         if (success) {
//             return returndata;
//         } else {
//             // Look for revert reason and bubble it up if present
//             if (returndata.length > 0) {
//                 // The easiest way to bubble the revert reason is using memory via assembly

//                 // solhint-disable-next-line no-inline-assembly
//                 assembly {
//                     let returndata_size := mload(returndata)
//                     revert(add(32, returndata), returndata_size)
//                 }
//             } else {
//                 revert(errorMessage);
//             }
//         }
//     }
// }

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
// is APIConsumer
contract PROVIDER_CUSTOMER{
    using SafeMath for uint256;
    // using Address for address;
    address payable public  provider;
    address payable public  customer;
    uint256 public SLA;
    uint256 public contractcreationtime;
    uint256 public contractendtime;
    uint256 public customercheckpoint;
    uint256 public price;
    bool internal first = false;
    bool internal second = false;
    bool internal third = false;
    bool internal forth = false;
    bool internal fifth = false;
    event PROVIDEURL(string  URL);
    constructor(address payable _provider,address payable _customer)public{
        provider = _provider;
        customer = _customer;
        contractcreationtime =  block.timestamp;
        contractendtime = block.timestamp + 30 days;
    }
    function depositforproviderer() public payable returns(bool success){
        require(msg.sender == provider , "its only accessable by the provider");
        price = msg.value;
        return true;
    }
    function calimforCustomer() public returns(bool success){
        require(msg.sender == customer , "its only accessable by the customer");
        require(block.timestamp > (customercheckpoint + 86400)," u can only access once in a day");
        customercheckpoint = block.timestamp;
        uint256 check =  providesla();
        if(check==99 && !first)
        {
            customer.transfer((price.mul(1)).div(100));
            first  = true;
            return true;
        }else if(check==98 && !second)
        {
            customer.transfer((price.mul(2)).div(100));
            second = true;
            return true;
        }else if(check == 97 && !third)
        {
            customer.transfer((price.mul(3)).div(100));
            third = true;
            return true;
        }else if(check == 96 && !forth)
        {
            customer.transfer((price.mul(4)).div(100));
            forth = true;
            return true;
        }
        else if (check <= 95 && !fifth)
        {
            customer.transfer((price.mul(5)).div(100));
            fifth = true;
            return true;
        }else
        {
            return false;
        }
    }
    function providesla() internal view returns(uint256){
        return SLA;
    }
    function AccessURL() public {
        require(msg.sender == customer , "its only accessable by the customer");
        emit PROVIDEURL("here is your url");
        if(block.timestamp > contractendtime)
        {
            killcontract();
        }
    }
    function killcontract() internal {
        selfdestruct(provider);
    }
    
}