// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";

/**
* @dev interface to allow gas tokens to be burned from the wrapper
*/
interface IFreeUp {
    function freeUpTo(uint256 value) external returns (uint256 freed);
    function freeFromUpTo(address from, uint256 value) external returns (uint256 freed);
}

/**
* @dev interface to allow gsve to be burned for upgrades
*/
interface IToken {
    function burnFrom(address account, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}


/**
* @dev The v1 smart wrapper is the core gas saving feature
* it can interact with other smart contracts
* it burns gas to save on the transaction fee
* only the owner/deployer of the smart contract can interact with it
* only the owner can send tokens from the address (smart contract)
* only the owner can withdraw tokens of any type, and this goes directly to the owner.
*/
contract GSVESmartWrapper {
    using Address for address;
    address private _owner;

    constructor () public {
        init(msg.sender);
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     * also sets the GSVE token reference
     */
    function init (address initialOwner) public {
        require(_owner == address(0), "This contract is already owned");
        _owner = initialOwner;
        emit OwnershipTransferred(address(0), initialOwner);
    }

    /**
    * @dev allow the contract to recieve funds. 
    * This will be needed for dApps that check balances before enabling transaction creation.
    */
    receive() external payable{}

    /**
    * @dev GSVE moddifier that burns gas tokens if the sender wants to burn them
    * burning them if the sender wants to burn them
    */
    modifier discountGas(address gasToken, uint256 tokenFreeValue, bool sender) {
        if(gasToken != address(0)){
            uint256 gasStart = gasleft();
            _;
            uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;

            if(tokenFreeValue == 0 || gasSpent < 48000){
                return;
            }

            if(sender){
                IFreeUp(gasToken).freeFromUpTo(msg.sender, (gasSpent + 16000) / tokenFreeValue);
            }
            else{
                IFreeUp(gasToken).freeUpTo((gasSpent + 16000) / tokenFreeValue);
            }
        }
        else {
            _;
        }
    }
    
    /**
    * @dev the wrapTransaction function interacts with other smart contracts on the users behalf
    * this wrapper works for any smart contract
    * as long as the dApp/smart contract the wrapper is interacting with has the correct approvals for balances within this wrapper
    * if the function requires a payment, this is handled too and sent from the wrapper balance.
    */
    function wrapTransaction(bytes calldata data, address contractAddress, uint256 value, address gasToken, uint256 tokenFreeValue, bool sender) external discountGas(gasToken, tokenFreeValue, sender) payable onlyOwner{
        if(!contractAddress.isContract()){
            return;
        }

        if(value > 0){
            contractAddress.functionCallWithValue(data, value, "GS: Error forwarding transaction");
        }
        else{
            contractAddress.functionCall(data, "GS: Error forwarding transaction");
        }
    }

    /**
    * @dev function that the user can trigger to withdraw the entire balance of their wrapper back to themselves.
    */
    function withdrawBalance() public onlyOwner{
        owner().call{value: address(this).balance, gas:gasleft()}("");
    }

    /**
    * @dev function that the user can trigger to withdraw an entire token balance from the wrapper to themselves
    */
    function withdrawTokenBalance(address token) external onlyOwner{
        IToken tokenContract = IToken(token);
        uint256 balance = tokenContract.balanceOf(address(this));
        tokenContract.transfer(owner(), balance);
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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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