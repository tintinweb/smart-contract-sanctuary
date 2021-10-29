pragma solidity 0.5.16;


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

contract Context {

    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != 0x0 && codehash != accountHash);
    }

    function toPayable(address account)
    internal
    pure
    returns (address payable)
    {
        return address(uint160(account));
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-call-value
        (bool success,) = recipient.call.value(amount)("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }
}

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IBEP20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IBEP20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IBEP20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0), "SafeBEP20: approve from non-zero to non-zero allowance");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeBEP20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function callOptionalReturn(IBEP20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeBEP20: call to non-contract");
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeBEP20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
    }
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function initOnwerable(address owner) internal {
        _owner = owner;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract SignData {
    bytes32 public DOMAIN_SEPARATOR;
    string public NAME;
    bytes32 public DATA_HASH;
    mapping(address => uint) public nonces;


    function initSigndata() internal {
        NAME = "KawaiiShareRevenue";
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

        DATA_HASH = keccak256("Data(uint256 _amount,uint256 nonce)");
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

contract RevenueShare is Ownable, SignData {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    struct Reward {
        uint256 reward;
        uint256 rewardPerShare; //reward before update balance.
        uint256 epochs; // block.timestamp when update.
    }

    struct User {
        uint256 epochIndex;
        uint256 depositedAmount;
        uint256 pendingReward;
    }

    // The input token vault!
    IBEP20 public kwt;
    uint256 public start;
    uint256 public end;

    uint256 public totalDeposit;
    uint256 public rewardLength;
    uint256 public depositDuration = 24 * 3600;
    // epochs => index
    mapping(uint256 => Reward) public rewards;
    mapping(address => User) public userInfo;
    bool public initialized;

    modifier validDepositTime(){
        require(block.timestamp >= start && block.timestamp <= end, "!deposit");
        _;
    }

    modifier validWithdrawTime(){
        require(block.timestamp > end, "!withdraw");
        _;
    }

    function initialize(uint256 _depositDuration, IBEP20 _kwt, address admin) public {
        require(initialized == false, "!init");
        initOnwerable(admin);
        initSigndata();
        depositDuration = _depositDuration;
        kwt = _kwt;
        initialized = true;
    }

    function setDepositDuration(uint256 _duration) public onlyOwner {
        depositDuration = _duration;
    }

    function updateStartEnd(uint256 _start, uint256 _end) public onlyOwner {
        start = _start;
        end = _end;
    }

    function addReward(uint256 _rewardAmount, uint256 _timestamp, uint256 _start) public onlyOwner {
        kwt.safeTransferFrom(msg.sender, address(this), _rewardAmount);
        start = _start;
        end = _start.add(depositDuration);
        uint256 rewardPerShare = 0;
        if (totalDeposit != 0) rewardPerShare = _rewardAmount.mul(1e6).div(totalDeposit);
        rewards[rewardLength] = Reward({reward : _rewardAmount, rewardPerShare : rewardPerShare, epochs : _timestamp});
        rewardLength = rewardLength + 1;
    }

    function setReward(uint256 _rewardAmount, uint256 _rewardPerShare, uint256 _timestamp) public onlyOwner {
        rewards[rewardLength] = Reward({reward : _rewardAmount, rewardPerShare : _rewardPerShare, epochs : _timestamp});
    }

    function userReward(address user) public view returns (uint256){
        User memory user = userInfo[user];
        uint256 increasedReward = 0;

        //after add reward
        for (uint256 i = user.epochIndex; i < rewardLength - 1; i++) {
            increasedReward = rewards[i].rewardPerShare.mul(user.depositedAmount).div(1e6).add(increasedReward);
        }
        return user.pendingReward.add(increasedReward);

    }


    function updateReward(address caller) internal {
        User memory user = userInfo[caller];
        uint256 increasedReward = 0;
        for (uint256 i = user.epochIndex; i < rewardLength; i++) {
            increasedReward = rewards[i].rewardPerShare.mul(user.depositedAmount).div(1e6).add(increasedReward);
        }
        if (increasedReward > 0) {
            userInfo[caller].pendingReward = user.pendingReward.add(increasedReward);
            userInfo[caller].epochIndex = rewardLength;
        }
    }

    function deposit(uint256 _amount, address sender, uint8 v, bytes32 r, bytes32 s) validDepositTime public {
        verify(keccak256(abi.encode(DATA_HASH, _amount, nonces[sender]++)), sender, v, r, s);

        kwt.safeTransferFrom(sender, address(this), _amount);

        User memory user = userInfo[sender];
        uint256 increasedReward = 0;

        //after add reward
        for (uint256 i = user.epochIndex; i < rewardLength - 1; i++) {
            increasedReward = rewards[i].rewardPerShare.mul(user.depositedAmount).div(1e6).add(increasedReward);
        }
        if (increasedReward > 0) {
            userInfo[sender].pendingReward = user.pendingReward.add(increasedReward);
            userInfo[sender].epochIndex = rewardLength - 1;
        }

        totalDeposit = totalDeposit.add(_amount);
        rewards[rewardLength - 1].rewardPerShare = rewards[rewardLength - 1].reward.mul(1e6).div(totalDeposit);
        userInfo[sender].depositedAmount = userInfo[sender].depositedAmount.add(_amount);
    }

    function withdraw(uint256 _amount, address sender, uint8 v, bytes32 r, bytes32 s) validWithdrawTime public {
        verify(keccak256(abi.encode(DATA_HASH, _amount, nonces[sender]++)), sender, v, r, s);
        updateReward(sender);
        totalDeposit = totalDeposit.sub(_amount);
        require(userInfo[sender].depositedAmount >= _amount, "Invalid amount");
        userInfo[sender].depositedAmount = userInfo[sender].depositedAmount.sub(_amount);
        kwt.safeTransfer(sender, _amount);
    }

    function claim(address caller) external {
        updateReward(caller);
        uint256 reward = userInfo[caller].pendingReward;
        userInfo[caller].pendingReward = 0;
        kwt.safeTransfer(caller, reward);
    }

    function inCaseTokenStuck(IBEP20 token, address to, uint256 amount) external onlyOwner {
        IBEP20(token).safeTransfer(to, amount);
    }
}