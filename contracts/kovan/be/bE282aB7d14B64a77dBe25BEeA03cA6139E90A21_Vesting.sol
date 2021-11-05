/**
 *Submitted for verification at Etherscan.io on 2021-11-05
*/

//SPDX-License-Identifier: MIT

library Address {

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

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

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

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

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

pragma solidity ^0.8.0;

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.8.0;

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }


    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.8.0;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity ^0.8.0;
abstract contract Pausable is Context {

    event Paused(address account);
    event Unpaused(address account);
    bool private _paused;

    constructor() {
        _paused = false;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}


//-------------------------==
pragma solidity ^0.8.0;

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

//--------------------==
abstract contract Core is Ownable, Pausable {

    using SafeERC20 for IERC20;

    IERC20 token;

    struct Schedule {
        uint32 duration;            // Duration of the vesting schedule, with respect to the grant start date, in days.
        uint32 cliff;               // Duration of the cliff, with respect to the grant start date, in days.
        bool isValid;               // true if schedule was created
        string name;                // Name of the schedule
    }

    struct UserGrant {
        uint256 start;              // Epoch time on which the grant start
        bool isRevocable;           // Grant can be revoked
        bool wasRevoked;            // Grant is revoked
        bool isValid;               // true if the grant was created
        uint256 scheduleIndex;      // schedule index
        uint256 amount;             // amount of grated tokens
        uint256 revokeDate;         // when was the grant revoked
        uint256 blockNumber;        // block number at the start of the schedule
    }

    Schedule[] public schedules;
    mapping(address => UserGrant) public grants;

    event VestingScheduleCreated(uint32 duration, uint32 cliff, string name);
    event UserGranted(address user, uint256 amount, string schedule);
    event UserGrantRevoked(address user);
    event TokensClaimed(address user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount, uint256 newBalance);

     /*
     * @notice use withdraw founds from the contract
     */
    function withdraw(uint256 _amount) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        require(balance >= _amount, "withdraw: Not enough founds");

        token.transfer(msg.sender, _amount);

        emit Withdraw(msg.sender, _amount, balance - _amount);
    }

    /*
     * @notice use it to pause the contract
     */
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /*
     * @notice use it to unpause the contract
     */
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

}

//------------------------==
pragma solidity ^0.8.5;

contract Vesting is Core {

    constructor(address _tokenAddress) {
        token = IERC20(_tokenAddress);
    }

    /* @notice add a vesting schedule to the contract
     * @param _duration Duration in days with respect to the grant start date
     * @param _cliff Time from grant in days. In this period of time the user will not be vesting
     * @param _name Schedule name
     */
    function addSchedule(
        uint32 _duration,
        uint32 _cliff,
        string memory _name)
    external onlyOwner {

        require(_duration > 0,
            "Invalid Schedule, Schedule should last at least one day"
        );

        require(_cliff < _duration,
            "Invalid Schedule, Cliff period should be inferior to schedule duration"
        );

        bytes memory nameB = bytes(_name);
        require(nameB.length > 0, "Invalid Schedule, name must not be empty");

        Schedule memory schedule = Schedule(
            _duration,
            _cliff,
            true,
            _name
        );

        schedules.push(schedule);

        emit VestingScheduleCreated(_duration, _cliff, _name);
    }

    /* @notice get the list of schedules
     * @return array of schedules
     */
    function getSchedules() external view returns(Schedule[] memory) {
        return schedules;
    }

    /* @notice add a user to a vesting schedule
     * @param _user beneficiary of the vesting
     * @param _scheduleIndex reference to the vesting schedule
     * @param _revocable flag that indicates if this grant can be revoked
     * @param _amount total of tokens granted to the user
     */
    function grant(
        address _user,
        uint256 _scheduleIndex,
        bool _revocable,
        uint256 _amount
    ) external onlyOwner {

        require (_user != address(0), "Invalid user address");

        require(_scheduleIndex < schedules.length, "Invalid schedule");
        Schedule memory schedule = schedules[_scheduleIndex];
        require(schedule.isValid, "Invalid schedule");

        // check if the user has a grant
        require(!grants[_user].isValid, "User already granted");

        require(_amount > 0, "Granted tokens must be greater than zero");

        grants[_user] = UserGrant(
            block.timestamp,
            _revocable,
            false,
            true,
            _scheduleIndex,
            _amount,
            0,
            block.number
        );

        emit UserGranted(_user, _amount, schedule.name);
    }

    /* @notice revoke vesting schedule to user
     * @param _user beneficiary of the vesting
     */
    function revoke(address _user) external onlyOwner {
        require(grants[_user].isValid, "Invalid grant");
        require(grants[_user].isRevocable, "This grant can't be revoked");
        require(!grants[_user].wasRevoked, "This grant is already revoked");

        grants[_user].wasRevoked = true;
        grants[_user].revokeDate = block.timestamp;

        emit UserGrantRevoked(_user);
    }

    /* @notice how many tokens are vested for the user
     * @return amount of vested tokens
     */
    function getAvailableAmount() public view whenNotPaused
    returns (uint256 vestedTokens) {
        UserGrant memory _grant = grants[msg.sender];

        require(_grant.isValid, "Account has no grant");
        require(!_grant.wasRevoked, "Account grant was revoked");

        Schedule memory _schedule = schedules[_grant.scheduleIndex];
        uint256 vestingDate = _grant.start + (_schedule.cliff * 1 days);
        uint256 blockPassed = block.number - _grant.blockNumber;
        uint256 blocksPerDay;

        // has the vesting schedule begun?
        if (vestingDate > block.timestamp || blockPassed == 0) {
            return uint256(0);
        }

        // is the vesting schedule over?
        if (block.timestamp > vestingDate + (_schedule.duration * 1 days)) {
            return _grant.amount;
        }

        /*
         *   schedule is running, calculate tokens
         *   If not a single days have passed use defaults
         */
        uint256 daysPassed = (block.timestamp - _grant.start) / 1 days;
        if (daysPassed == 0) {
            blocksPerDay = 6200;
        } else {
            blocksPerDay = blockPassed / daysPassed;
        }

        uint256 estimatedTotalBlocks = blocksPerDay * _schedule.duration;
        uint256 tokensPerBlock = _grant.amount / estimatedTotalBlocks;

        return tokensPerBlock * blockPassed;
    }

    /* @notice transfer vested tokens to the user wallet
     */
    function claim() external whenNotPaused {
        uint256 amount = getAvailableAmount();

        require(amount > 0, "Account is not vesting");

        token.transfer(msg.sender, amount);

        emit TokensClaimed(msg.sender, amount);
    }

    /* @notice get the sender schedule
     */
    function getUserSchedule() external view whenNotPaused returns (
            uint256 _start,
            uint256 _amount,
            uint32 _duration,
            uint32 cliff,
            string memory name
        ) {

         UserGrant memory _grant = grants[msg.sender];

        require(_grant.isValid, "Account has no grant");
        require(!_grant.wasRevoked, "Account grant was revoked");

        Schedule memory _schedule = schedules[_grant.scheduleIndex];

        return (
            _grant.start,
            _grant.amount,
            _schedule.duration,
            _schedule.cliff,
            _schedule.name
        );
    }

    /* @notice get block data for testing
     */
    function getBlockchainDataA() external view returns (
            uint256 blockTimestamp,
            uint256 blockNumber,
            bool isPaused
        ) {
        return (block.timestamp, block.number,paused());
    }
}