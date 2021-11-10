/**
 *Submitted for verification at BscScan.com on 2021-11-10
*/

pragma solidity 0.6.12;

interface IBEP20 {
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

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

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

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {codehash := extcodehash(account)}
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success,) = recipient.call{value : amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }


    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }


    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }


    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value : weiValue}(data);
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

library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IBEP20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IBEP20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
    * @dev Deprecated. This function has issues similar to the ones found in
    * {IBEP20-approve}, and its usage is discouraged.
    *
    * Whenever possible, use {safeIncreaseAllowance} and
    * {safeDecreaseAllowance} instead.
    */
    function safeApprove(IBEP20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeBEP20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
    * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
    * on the return value: the return value is optional (but if data is returned, it must not be false).
    * @param token The token targeted by the call.
    * @param data The call data (encoded using abi.encode or one of its variants).
    */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeBEP20: low-level call failed");
        if (returndata.length > 0) {// Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
    }
}


contract SignData {
    bytes32 public DOMAIN_SEPARATOR;
    string public NAME;
    bytes32 public DEPOSIT_HASH;
    mapping(address => uint) public nonces;


    constructor() internal {
        NAME = "KawaiiFarmingLock";
        uint chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(NAME)),
                keccak256(bytes('1')),
                chainId,
                this
            )
        );

        DEPOSIT_HASH = keccak256("Data(uint256 _amount,address sender,uint256 nonce)");
    }

    function verify(bytes32 data, address sender, uint8 v, bytes32 r, bytes32 s) internal view {
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                data
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == sender, "Invalid nonce");
    }
}

contract KawaiiFarmingLock is SignData {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    address public ownerPool;
    address public kawaiiToken;

    struct EpochData {
        uint256 start;
        uint256 end;
        uint256 rewardPerSecond;
    }

    struct UserData {
        uint256 amount;
        uint256 epoch;
        uint256 rewardPending;
    }

    uint256 public epochNow;

    mapping(address => UserData) public userDatas;
    mapping(uint256 => EpochData) public epochConfigs;

    event Deposit(address user, uint256 epoch, uint256 amount);
    event Withdraw(address user, uint256 epoch, uint256 amount);

    constructor (address _kawaiiToken, address _ownerPool) public {
        kawaiiToken = _kawaiiToken;
        ownerPool = _ownerPool;
    }
    modifier onlyOwner(){
        require(msg.sender == ownerPool, "ONLY_OWNER");
        _;
    }

    function setTokenKawaii(address _kawaiiToken) public onlyOwner {
        kawaiiToken = _kawaiiToken;
    }

    function setEpoch(uint256 _epoch, uint256 _start, uint256 _end, uint256 _rewardPerSecond) public onlyOwner {
        if (_epoch != epochNow) {
            require(_start > block.timestamp, "start must bigger time now");
            require(_end > _start, "end must bigger start");
            require(epochConfigs[epochNow].end < block.timestamp, 'cannot create new');
            epochNow = _epoch;
            epochConfigs[_epoch] = EpochData(_start, _end, _rewardPerSecond);
        } else {
            epochConfigs[epochNow] = EpochData(_start, _end, _rewardPerSecond);
        }
    }

    function depositPermit(address sender, uint256 _amount, uint8 v, bytes32 r, bytes32 s) external {
        verify(keccak256(abi.encode(DEPOSIT_HASH, _amount, sender, nonces[sender]++)), sender, v, r, s);
        _deposit(sender, _amount);
    }

    function deposit(uint256 amount) public {
        _deposit(msg.sender, amount);
    }

    function _deposit(address _caller, uint256 amount) internal {
        EpochData memory epochNowConfig = epochConfigs[epochNow];
        UserData storage userData = userDatas[_caller];

        require(block.timestamp < epochNowConfig.start, "time stake already end");
        IBEP20(kawaiiToken).safeTransferFrom(_caller, address(this), amount);

        if (userData.epoch != epochNow) {
            EpochData memory userEpochConfig = epochConfigs[userData.epoch];
            require(userEpochConfig.end <= block.timestamp, 'Not yet due for withdrawal');
            (uint256 rewardPending,) = pending(_caller);
            userData.rewardPending = userData.rewardPending.add(rewardPending).add(userData.amount);
            userData.amount = 0;
        }

        userData.epoch = epochNow;
        userData.amount = userData.amount.add(amount);

        emit Deposit(_caller, epochNow, amount);
    }

    function pending(address _caller) public view returns (uint256, uint256) {
        UserData memory userData = userDatas[_caller];
        EpochData memory userEpochConfig = epochConfigs[userData.epoch];

        if (block.timestamp <= userEpochConfig.start) {
            return (0, block.timestamp);
        } else if (block.timestamp > userEpochConfig.end) {
            return (userEpochConfig.end.sub(userEpochConfig.start).mul(userEpochConfig.rewardPerSecond).mul(userData.amount).div(1e12), block.timestamp);
        } else {
            return (block.timestamp.sub(userEpochConfig.start).mul(userEpochConfig.rewardPerSecond).mul(userData.amount).div(1e12), block.timestamp);
        }
    }

    function withdrawAll(address _caller) public {
        UserData storage userData = userDatas[_caller];
        EpochData memory epochUser = epochConfigs[userData.epoch];
        require(block.timestamp >= epochUser.end, "tokens are locked");
        require(userData.amount != 0, "not amount locked");

        (uint256 reward,) = pending(_caller);
        uint256 amount = userData.amount;
        uint256 totalAmount = reward.add(amount);

        IBEP20(kawaiiToken).safeTransfer(_caller, totalAmount);

        userData.epoch = epochNow;
        userData.amount = 0;
        userData.rewardPending = 0;
        emit Withdraw(_caller, userData.epoch, totalAmount);
    }

    function setOwner(address _owner) public onlyOwner {
        require(_owner != address(0), "!accPerShare 0");
        ownerPool = _owner;
    }

    function inCaseTokenStuck(address token, address to, uint256 amount) external onlyOwner {
        IBEP20(token).safeTransfer(to, amount);
    }
}