/**
 *Submitted for verification at BscScan.com on 2021-11-24
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

    function mint(address _to, uint256 _amount) external;

    function burnFrom(address spender, uint256 amount) external;
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
    bytes32 public WITHDRAW_HASH;
    mapping(address => uint) public nonces;


    function initSign() internal {
        NAME = "KawaiiBridge";
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

        DEPOSIT_HASH = keccak256("Data(address _caller,uint256 _amount,uint256 nonce)");
        WITHDRAW_HASH = keccak256("Data(bytes adminSignedData,uint256 nonce)");
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

contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function initOwner() internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function owner() external view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract Signed {
    mapping(bytes32 => bool) public  permitDoubleSpending;

    function getSigner(bytes32 data, uint8 v, bytes32 r, bytes32 s) internal returns (address){
        require(!permitDoubleSpending[data], "Forbidden double spending");
        permitDoubleSpending[data] = true;
        return ecrecover(getEthSignedMessageHash(data), v, r, s);
    }
    //    FUNCTION internal
    function getEthSignedMessageHash(bytes32 _messageHash) internal pure returns (bytes32) {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    function checkPermitDoubleSpendingBatch(bytes32[] memory _datas) external view returns (bool[] memory){
        bool[] memory isChecks;
        for (uint256 i = 0; i < _datas.length; i++) {
            isChecks[i] = permitDoubleSpending[_datas[i]];
        }
        return isChecks;
    }

}


contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }

    function pause() external onlyOwner whenNotPaused {
        paused = true;
        Pause();
    }

    function unpause() external onlyOwner whenPaused {
        paused = false;
        Unpause();
    }
}

contract KawaiiBridge is SignData, Ownable, Pausable, Signed {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    struct UserData {
        uint256 totalDeposit;
        uint256 totalClaim;
        uint256 last;
    }

    struct ClaimLog {
        uint256 totalDepositBefore;
        uint256 totalClaimBefore;
        uint256 totalClaimAfter;
        uint256 amount;
        uint256 totalEarn;
        uint256 totalSpend;
    }

    bool public initialized;
    address public milkyToken;
    uint256 public limitWithdraw;
    uint256 public timeLimit;

    mapping(address => mapping(uint256 => ClaimLog)) public claimLogs;
    mapping(address => uint256) public nonceDeposits;
    mapping(address => uint256) public nonceClaims;
    mapping(address => UserData) public userDatas;
    mapping(address => mapping(uint256 => uint256)) public depositLogs;
    mapping(address => bool) public isSigner;

    event Deposit(address indexed user, uint256 indexed nonce, uint256 indexed amount);
    event Claim(address indexed user, uint256 indexed nonceClaim, uint256 totalDepositBefore, uint256 totalClaimBefore, uint256 amount, uint256 totalEarn, uint256 totalSpend);


    function setTokenMilky(address _milkyToken) public onlyOwner {
        milkyToken = _milkyToken;
        IBEP20(milkyToken).approve(address(this), uint256(- 1));
    }

    function setSigner(address _signer, bool _is) public onlyOwner {
        isSigner[_signer] = _is;
    }

    function setLimitWithdraw(uint256 _limitWithdraw) public onlyOwner {
        limitWithdraw = _limitWithdraw;
    }

    function init(address _milkyToken, uint256 _timeLimit, uint256 _limitWithdraw) public {
        require(initialized == false);
        milkyToken = _milkyToken;
        timeLimit = _timeLimit;
        limitWithdraw = _limitWithdraw;
        isSigner[msg.sender] = true;
        initSign();
        initOwner();
        IBEP20(milkyToken).approve(address(this), uint256(- 1));
        initialized = true;
    }

    function getDepositLogBatch(address user, uint256[] memory _nonces) public view returns (uint256[] memory){
        uint256[] memory _amounts = new uint256[](_nonces.length);
     
        for (uint256 i = 0; i < _nonces.length; i++) {
            _amounts[i] = depositLogs[user][_nonces[i]];
        }
        return _amounts;
    }

    function depositPermit(address _caller, uint256 _amount, uint8 v, bytes32 r, bytes32 s) public {
        verify(keccak256(abi.encode(DEPOSIT_HASH, _caller, _amount, nonces[_caller]++)), _caller, v, r, s);
        _deposit(_caller, _amount);
    }

    function _deposit(address _caller, uint256 _amount) internal whenNotPaused {
        IBEP20(milkyToken).safeTransferFrom(_caller, address(this), _amount);
        IBEP20(milkyToken).burnFrom(address(this), _amount);

        uint256 nonceDepositLast = nonceDeposits[_caller];
        userDatas[_caller].totalDeposit = userDatas[_caller].totalDeposit.add(_amount);
        depositLogs[_caller][nonceDepositLast] = _amount;
        nonceDeposits[_caller] = nonceDeposits[_caller].add(1);

        emit Deposit(_caller, nonceDepositLast, _amount);
    }

    function withdraw(bytes memory data) public {
        (address _caller,
        uint256 _amount,
        uint256 _totalDelivery,
        uint256 _totalCraft,
        bytes memory _adminSignedData,
        uint256 _timestamp,
        uint8 v,
        bytes32 r,
        bytes32 s) = abi.decode(data, (address, uint256, uint256, uint256, bytes, uint256, uint8, bytes32, bytes32));
        uint256 nonceClaim = nonceClaims[_caller]++;

        {
            uint256 nonce = nonces[_caller]++;
            verify(keccak256(abi.encode(WITHDRAW_HASH, keccak256(_adminSignedData), nonce)), _caller, v, r, s);
            (v, r, s) = abi.decode(_adminSignedData, (uint8, bytes32, bytes32));
            address signer = getSigner(
                keccak256(
                    abi.encode(address(this), this.withdraw.selector, nonceClaim, _amount, _totalDelivery, _totalCraft, _timestamp, nonce)
                ), v, r, s
            );
            require(isSigner[signer], "Forbidden");
        }

        require(userDatas[_caller].last.add(timeLimit) <= block.timestamp, "Exceed limit per withdrawal");
        uint256 totalClaimBefore = userDatas[_caller].totalClaim;
        uint256 totalDeposit = userDatas[_caller].totalDeposit;

        {
            uint256 totalEarn = totalDeposit.add(_totalDelivery);
            uint256 totalSpend = totalClaimBefore.add(_totalCraft);
            uint256 amountMax = totalEarn.sub(totalSpend);
            require(amountMax >= _amount, "Amount withdraw exceed the allowable amount");
            require(limitWithdraw >= _amount, "Exceed limit amount per withdrawal");
        }

        IBEP20(milkyToken).mint(address(this), _amount);
        IBEP20(milkyToken).safeTransfer(_caller, _amount);
        userDatas[_caller].last = block.timestamp;
        userDatas[_caller].totalClaim = totalClaimBefore.add(_amount);

        emit Claim(_caller, nonceClaim, totalDeposit, totalClaimBefore, _amount, _totalDelivery, _totalCraft);
    }

    function inCaseTokenStuck(address token, address to, uint256 amount) external onlyOwner {
        IBEP20(token).safeTransfer(to, amount);
    }
}