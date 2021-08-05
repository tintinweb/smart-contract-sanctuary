/**
 *Submitted for verification at Etherscan.io on 2021-08-04
*/

pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }
    
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

contract Contribut is Ownable {
    struct EventData {
        string eventName;
        address depositToken;
        uint256 depositTotal;
        uint256 hardCap;
        uint256 maxContribut;
        uint256 minContribut;
        uint256 FCFSTimer;
        address[] users;
        address owner;
        bool active;
    }
    mapping(uint256 => EventData) public eventList;
    uint256 public eventNonce;
    
    struct ContributionData {
        uint256 eventId;
        uint256 depositAmount;
    }
    mapping(address => ContributionData[]) public userList;

    struct UserData {
        address user;
        uint256 depositAmount;
    }

    event Published(uint256 eventId, string eventName, address depositToken, uint256 hardCap, uint256 maxContribut, uint256 minContribut, uint256 FCFSTimer, address owner, bool active);
    event Close(uint256 eventId, address depositToken, uint256 depositTotal);
    event Contribution(uint256 eventId, address user, uint256 depositAmount);
    event Vested(uint256 eventId, address user, address tokenAddress, uint256 amount);

    receive() external payable {}

    function RecoverERC20(address _tokenAddress) public onlyOwner {
        uint256 balance = IERC20(_tokenAddress).balanceOf(address(this));
        TransferHelper.safeTransfer(_tokenAddress, owner(), balance);
    }

    function RecoverETH() public onlyOwner() {
        address owner = owner();
        payable(owner).transfer(address(this).balance);
    }

    function SetEvent(string calldata _eventName, address _depositToken, uint256 _hardCap, uint256 _maxContribut, uint256 _minContribut, uint256 _FCFSTimer) external onlyOwner {
        require(_hardCap >= _maxContribut, "Invalid hardCap");
        require(_maxContribut >= _minContribut, "Invalid minContribut");
        require(_depositToken != address(0), "Invalid depositToken");
        address[] memory users;
        eventList[eventNonce] = EventData({
            eventName : _eventName,
            depositToken : _depositToken,
            depositTotal : 0,
            hardCap : _hardCap,
            maxContribut : _maxContribut,
            minContribut : _minContribut,
            FCFSTimer : _FCFSTimer,
            users : users,
            owner : msg.sender,
            active : true
        });
        emit Published(eventNonce, _eventName, _depositToken, _hardCap, _maxContribut, _minContribut, _FCFSTimer, msg.sender, true);
        eventNonce++;
    }

    function CloseEvent(uint256 _eventId) external onlyOwner {
        require(_eventId < eventNonce, "Invalid EventId");
        require(eventList[_eventId].active, "Event is not active");
        require(eventList[_eventId].hardCap == eventList[_eventId].depositTotal, "Not reached hardCap");
        
        TransferHelper.safeTransfer(eventList[_eventId].depositToken, msg.sender, eventList[_eventId].depositTotal);
        eventList[_eventId].active = false;
        emit Close(_eventId, eventList[_eventId].depositToken, eventList[_eventId].depositTotal);
    }

    function SetVested(uint256 _eventId, address _tokenAddress, uint256 _amount) external onlyOwner {
        require(_eventId < eventNonce, "Invalid EventId");
        require(eventList[_eventId].active == false, "Event is active");
        
        uint256 preBalance = IERC20(_tokenAddress).balanceOf(address(this));
        TransferHelper.safeTransferFrom(_tokenAddress, msg.sender, address(this), _amount);
        UserData[] memory data = getEventData(_eventId);

        uint256 balance = IERC20(_tokenAddress).balanceOf(address(this)) - preBalance;
        for (uint256 i = 0; i < data.length; i++) {
            uint256 vestedBalance = balance * 1e18 * data[i].depositAmount / eventList[_eventId].depositTotal / 1e18;
            if (vestedBalance > 0) {
                TransferHelper.safeTransfer(_tokenAddress, data[i].user, vestedBalance);
                emit Vested(_eventId, data[i].user, _tokenAddress, vestedBalance);
            }
        }
        balance = IERC20(_tokenAddress).balanceOf(address(this));
        if (balance > preBalance) {
            TransferHelper.safeTransfer(_tokenAddress, msg.sender, balance - preBalance);
        }
    }

    function Deposit(uint256 _eventId, uint256 _depositAmount) external {
        require(_eventId < eventNonce, "Invalid EventId");
        require(eventList[_eventId].active, "Event is not active");
        require(eventList[_eventId].FCFSTimer < block.timestamp || eventList[_eventId].maxContribut >= _depositAmount, "Deposit is high");
        require(eventList[_eventId].minContribut <= _depositAmount, "Deposit is low");
        require(eventList[_eventId].hardCap >= eventList[_eventId].depositTotal + _depositAmount, "It is beyond hardCap");
        bool flag = false;
        ContributionData[] storage data = userList[msg.sender];
        for (uint256 i = 0; i < data.length; i++) {
            if (data[i].eventId ==  _eventId) {
                data[i].depositAmount += _depositAmount;
                require(eventList[_eventId].FCFSTimer < block.timestamp || eventList[_eventId].maxContribut >= data[i].depositAmount, "Deposit is high");
                eventList[_eventId].depositTotal += _depositAmount;
                TransferHelper.safeTransferFrom(eventList[_eventId].depositToken, msg.sender, address(this), _depositAmount);
                emit Contribution(_eventId, msg.sender, data[i].depositAmount);
                flag = true;
                break;
            }
        }
        if (!flag) {
            data.push(
                ContributionData({
                    eventId : _eventId,
                    depositAmount : _depositAmount
                })
            );
            eventList[_eventId].depositTotal += _depositAmount;
            TransferHelper.safeTransferFrom(eventList[_eventId].depositToken, msg.sender, address(this), _depositAmount);
            emit Contribution(_eventId, msg.sender, _depositAmount);
            address[] storage users = eventList[_eventId].users;
            users.push(msg.sender);
            eventList[_eventId].users = users;
        }
        userList[msg.sender] = data;
    }

    function Refund(uint256 _eventId, uint256 _refundAmount) external {
        require(_eventId < eventNonce, "Invalid EventId");
        require(eventList[_eventId].active, "Event is not active");
        ContributionData[] storage data = userList[msg.sender];
        for (uint256 i = 0; i < data.length; i++) {
            if (data[i].eventId ==  _eventId) {
                require(data[i].depositAmount >= _refundAmount, "Contributions are insufficient");
                data[i].depositAmount -= _refundAmount;
                eventList[_eventId].depositTotal -= _refundAmount;
                TransferHelper.safeTransfer(eventList[_eventId].depositToken, msg.sender, _refundAmount);
                emit Contribution(_eventId, msg.sender, data[i].depositAmount);
                userList[msg.sender] = data;
                break;
            }
        }
    }

    function getUserData(address _user, uint256 _eventId) public view returns (uint256 _depositAmount) {
        ContributionData[] memory data = userList[_user];
        for (uint256 i = 0; i < data.length; i++) {
            if (data[i].eventId ==  _eventId) {
                return data[i].depositAmount;
            }
        }
    }

    function getUserAllData(address _user) public view returns (ContributionData[] memory _userAllData) {
        return userList[_user];
    }
    
    function getEventData(uint256 _eventId) public view returns (UserData[] memory _userData) {
        address[] memory users = eventList[_eventId].users;
        UserData[] memory data = new UserData[](users.length);
        for (uint256 i = 0; i < users.length; i++) {
            data[i].user = users[i];
            data[i].depositAmount = getUserData(users[i], _eventId);
        }
        return data;
    }

}