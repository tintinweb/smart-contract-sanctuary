/**
 *Submitted for verification at BscScan.com on 2021-10-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

interface IStdReference {
    /// A structure returned whenever someone requests for standard reference data.
    struct ReferenceData {
        uint256 rate; // base/quote exchange rate, multiplied by 1e18.
        uint256 lastUpdatedBase; // UNIX epoch of the last time when base price gets updated.
        uint256 lastUpdatedQuote; // UNIX epoch of the last time when quote price gets updated.
    }

    /// Returns the price data for the given base/quote pair. Revert if not available.
    function getReferenceData(string memory _base, string memory _quote)
        external
        view
        returns (ReferenceData memory);

    /// Similar to getReferenceData, but with multiple base/quote pairs at once.
    function getReferenceDataBulk(string[] memory _bases, string[] memory _quotes)
        external
        view
        returns (ReferenceData[] memory);
}




abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}



abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        require(initialOwner != address(0), "Owner cannot be a zero address");
        _setOwner(initialOwner);
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
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


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


contract Lottery is Context, Ownable {
    using Address for address;

    IStdReference ref = IStdReference(0xDA7a001b254CD22e46d3eAB04d937489c93174C3);


    uint256 public _gasPrice = 10000000000; // gas price in wei;

    uint256 public _gasUsage = 25000; // gas usage per 1 transfer;


    uint256 public _price = 1000; // participate price in RUB;

    address[2] _serviceWallets = [
                                    0x7d26B5DD3459Af9aF19D559857c4E77fc14cd7b3,
                                    0x04e88A2ccF503F494F18d452a7eB92Ee016bF723
                                  ];

    bool public _serviceRewarded;

    bool public _isRunning;

    uint256 private lotteryId;

    uint256 public _startTime;

    uint256 MAX_MEMBERS = 3;

    uint256 period = 60 * 10; 

    address[] public _members;

    mapping (uint256 => mapping (address => bool)) private _isMember;

    event Reward(address indexed to, uint256 value);

    event Refund(address indexed to, uint256 value);


    constructor(address cOwner) Ownable (cOwner) {
        _isRunning = true;
        lotteryId = 1;

    }


    function setPrice(uint256 newprice) public onlyOwner {
        require(newprice > 0, "Price cannot be zero");
        _price = newprice;

    }


    function setGasPrice(uint256 newprice) public onlyOwner {
        require(newprice > 0, "Gas price cannot be zero");
        _gasPrice = newprice;

    }


    function setGasUsage(uint256 _gas) public onlyOwner {
        require(_gas > 0, "Gas usage cannot be zero ");
        _gasUsage = _gas;

    }


    function increaseTime(uint256 addTime) public onlyOwner {
        require((_isRunning && block.timestamp < _startTime), "Lottery is not running. Cannot add more time.");
        require(addTime > 0, "Additional time must not be zero");
        _startTime = _startTime + addTime;

    }


    function getMembers()public view returns( address  [] memory){
        return _members;
    }


    function getExchangeRate() public view returns (uint256){
        IStdReference.ReferenceData memory data = ref.getReferenceData("RUB","BNB");
        return data.rate;
    }



    receive() external payable {
      require(_msgSender() != address(0), "Zero address prohibited");
      require(!_msgSender().isContract(), "Contracts are not allowed to participate");
      require(!_isMember[lotteryId][_msgSender()],"User already participates");
      require(_isRunning, "Lottery is not active");
      require(_members.length < MAX_MEMBERS, "Lottery is full");
      uint256 rate = getExchangeRate();
      require(msg.value >= _price * rate, "Invalid amount of BNB to participate");

      _isMember[lotteryId][_msgSender()] = true;
      _members.push(_msgSender());
      if (_members.length == 1) {
        _startTime = block.timestamp;
      } else if (_members.length == MAX_MEMBERS) {
        _isRunning = false;
      }

      payable(owner()).transfer(_gasPrice * _gasUsage);

      uint256 change = msg.value - _price * rate;
      if (change > 0) {
        payable(_msgSender()).transfer(change);
      }

    }

    function lotteryStatus() public view returns (uint8) {
      if (!_isRunning) {
        return 2; // lottery filled
      } else if (_startTime > 0 &&_startTime + period < block.timestamp && _members.length < MAX_MEMBERS) {
        return 1; // lottery expired
      } else {
        return 0; // lottery running
      }
    }


    function restart() public onlyOwner {
      require(!_isRunning, "Lottery is already running");
      uint256 contractBalance = address(this).balance;
      if (contractBalance > 0 ) {
        payable(owner()).transfer(contractBalance);
      }
      delete _members;
      _isRunning = true;
      lotteryId += 1;
      _startTime = 0;
      _serviceRewarded = false;
    }


    function disable() public onlyOwner {
      require(_isRunning, "Lottery is already stopped");
      _isRunning = false;
    }


    function ownersReward() public onlyOwner {
      require(!_isRunning, "Lottery is running, service reward is unavailable");
      require(_members.length == MAX_MEMBERS, "Lottery wasn't completely filled, service reward is unavailable");
      require(!_serviceRewarded, "Service reward was already withdrawn");
      uint256 contractBalance = address(this).balance;
      uint256 amount = contractBalance / 20;
      payable(_serviceWallets[0]).transfer(amount);
      payable(_serviceWallets[1]).transfer(amount);
      _serviceRewarded = true;
    }


    function distribute(address payable[] memory recepients, uint256 amount) public onlyOwner {
      require(amount > 0, "Invalid amount");
      require(recepients.length > 0, "No recepients specified");
      for (uint256 i = 0; i < recepients.length; i++) {
        recepients[i].transfer(amount);
        if (_members.length == MAX_MEMBERS) {
           emit Reward(recepients[i], amount);
        } else {
           emit Refund(recepients[i], amount);
        }

      }

    }

}