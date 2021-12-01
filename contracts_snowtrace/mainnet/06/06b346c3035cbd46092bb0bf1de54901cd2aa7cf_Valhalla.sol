/**
 *Submitted for verification at snowtrace.io on 2021-12-01
*/

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

contract MultiGov {

  address[] public governors; // Governor list. Always check map.

  uint public epoch; // action index

  mapping(uint=>uint) public votes; // epoch votes

  mapping(address=>bool) public governor; // Governors map

  mapping(address=>uint) public lastVoted; // Last epoch joined by governor

  uint public govCount; // Governors amount

  uint public voteThreshold; // % needed to activate dao

  mapping(address=>bool) public pendingGovernor; // The address pending to become the governor once accepted.

  /// @dev Initialize the smart contract, using msg.sender as the first governor.
  constructor() {
    governor[msg.sender] = true;
    govCount++;
    governors.push(msg.sender);
  }


  modifier onlyGov() {
    require(governor[msg.sender], 'not the governor');
    _;
  }

  modifier onlyDao() {
    require(msg.sender == address(this), 'not the DAO');
    _;
  }

  function voted() public view returns(bool){
      return votes[epoch]>govCount*voteThreshold/100;
  }

  function vote(uint _height) external onlyGov{
    require(epoch == _height, "proposal outdated");
    require(lastVoted[msg.sender]<epoch, "already voted");
    lastVoted[msg.sender] = epoch;
    votes[epoch]++;
  }


  function setThreshold(uint _threshold) external onlyDao{
    require(_threshold < 60, "bad parameters");
    voteThreshold = _threshold;
  }

  /// @dev Set the pending governor, which will be the governor once accepted.
  /// @param _pendingGovernor The address to become the pending governor.
  function setPendingGovernor(address _pendingGovernor) external onlyDao {
    pendingGovernor[_pendingGovernor] = true;
  }

  /// @dev Accept to become the new governor. Must be called by the pending governor.
  function acceptGovernor() external {
    require(pendingGovernor[msg.sender], 'not the pending governor');
    pendingGovernor[msg.sender] = false;
    governor[msg.sender] = true;
    governors.push(msg.sender);
    govCount++;
  }

  function removeGovernor(address _removed) external onlyDao{
      governor[_removed] = false;
      pendingGovernor[_removed] = false;
      govCount--;
  }
}

contract Valhalla is MultiGov{

  using Address for address;

  address[] public to;

  bytes[] public execute;

  uint public timelock;
    
  uint public whenAsked = type(uint).max;

  // @dev timelock modifier
  modifier underLock(){
      require(block.timestamp >= whenAsked + timelock, "locked");
      _;
  }

  /**
   * @dev Stores a list of timelocked actions
   * @param _addresses addresses to be called
   * @param _actions action per contract
   */
  function askCall(address[] memory _addresses, bytes[] memory _actions) external onlyGov{
      require(_addresses.length == _actions.length, "wrong length");
      epoch ++;
      to = _addresses;
      execute = _actions;
      whenAsked = block.timestamp;
  }
    
  /**
   * @dev Request a timelock change
   * @param _newTimelock selfexplainatory
   */
  function askChangeTimelock(uint _newTimelock) external onlyGov{
      require(_newTimelock < 7 days, "too long");
      whenAsked = block.timestamp;
      execute.push(abi.encode(_newTimelock));
  }

  /**
   * @dev Resets timelock
   */
  function reset() internal{
    delete(to);
    delete(execute);
    whenAsked = type(uint).max;
  }
    
  /**
   * @dev Excecute actions from askCall
   */
  function executeCalls() external onlyGov underLock{
      require(voted(), "proposal not approved");
      for(uint i; i<to.length; i++)
          to[i].functionCall(execute[i]);
      reset();
  }
    
  /**
   * @dev Excecute change timelock from askChangeTimelock
   */
  function executeNewTimeLock() external onlyGov underLock{
      require(voted(), "proposal not approved");
      require(to.length == 0 && execute.length == 1, "no timelock type");
      timelock = abi.decode(execute[0], (uint));
      reset();
  }
}