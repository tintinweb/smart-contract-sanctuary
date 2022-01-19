pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function initializeOwnable(address __owner) internal {
        _owner = __owner;
        emit OwnershipTransferred(address(0), __owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
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

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);
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

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
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

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


contract SignData {
    bytes32 public DOMAIN_SEPARATOR;
    string public NAME;
    bytes32 public DATA_HASH;
    mapping(address => uint) public nonces;


    function initSigndata() internal {
        NAME = "KawaiiShareRevenueV2";
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

        DATA_HASH = keccak256("Data(uint256 amount,uint256 nonce)");
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

contract RevenueShareV2 is Ownable, SignData {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct LockInfo {
        bool isClaim;
        uint224 expired;
        uint256 amount;
    }

    struct UserInfo {
        uint256 totalLock;
        uint256 accUserShare;
        uint256 pendingReward;
        LockInfo[] lockInfo;
    }

    address public kawaiiToken;
    bool public initialized;
    uint32 public lockDuration;
    uint256 currentRevenueShareReward;
    uint256 currentRevenueShareTimestamp;
    // per second (*10**12)
    uint256 public rewardRate;
    uint256 public poolAccShare;
    uint256 public totalLockedAmount;
    mapping(address => UserInfo) public userInfo;

    event Deposit(address indexed user, uint256 indexed amount, uint256 indexed expired, uint256 index);
    event Withdraw(address indexed user, uint256 indexed amount, uint256 indexed index, uint256 time);
    event Claim(address indexed user, uint256 indexed poolAccShare);
    event SetReward(uint256 indexed amount, uint256 indexed timestamp, uint256 indexed rewardPerShare, uint256 poolAccShare);

    modifier initializer(){
        require(!initialized, "Already initialized");
        initialized = true;
        _;
    }
    function initialize(address _kawaiiToken, uint256 _rewardRate, uint32 _lockDuration) public initializer {
        initializeOwnable(msg.sender);
        initSigndata();
        kawaiiToken = _kawaiiToken;
        rewardRate = _rewardRate;
        lockDuration = _lockDuration;
    }

    function setTokenKawaii(address _kawaiiToken) public onlyOwner {
        kawaiiToken = _kawaiiToken;
    }

    function setLockDuration(uint32 _lockDuration) public onlyOwner {
        lockDuration = _lockDuration;
    }

    function _deposit(uint256 amount, address sender) internal {
        IERC20(kawaiiToken).safeTransferFrom(sender, address(this), amount);
        UserInfo storage user = userInfo[sender];
        user.pendingReward = pendingRevenueReward(sender);
        user.accUserShare = poolAccShare;
        user.totalLock = user.totalLock.add(amount);
        require(amount > 0, "amount zero");
        uint256 expired = block.timestamp.add(lockDuration);
        LockInfo memory lockInfo = LockInfo({isClaim : false, expired : uint224(expired), amount : amount});
        user.lockInfo.push(lockInfo);
        totalLockedAmount = totalLockedAmount.add(amount);

        emit Deposit(sender, amount, expired, user.lockInfo.length);
    }

    function depositPermit(uint256 amount, address sender, uint8 v, bytes32 r, bytes32 s) public {
        verify(keccak256(abi.encode(DATA_HASH, amount, nonces[sender]++)), sender, v, r, s);
        _deposit(amount, sender);
    }

    function deposit(uint256 amount) public {
        _deposit(amount, msg.sender);
    }

    function claimShareRevenue(address _to) public {
        uint256 a = pendingRevenueReward(_to);
        IERC20(kawaiiToken).safeTransfer(_to, a);
        userInfo[_to].pendingReward = 0;
        userInfo[_to].accUserShare = poolAccShare;

        emit Claim(_to, poolAccShare);
    }

    function _withdraw(uint256 index, address sender) internal {
        LockInfo storage user = userInfo[sender].lockInfo[index];
        require(userInfo[sender].lockInfo.length >= index, "Invalid index");
        require(user.isClaim == false, "claimed");
        require(block.timestamp >= user.expired, "too early");

        userInfo[sender].pendingReward = pendingRevenueReward(sender);
        userInfo[sender].accUserShare = poolAccShare;

        uint256 totalReward = block.timestamp.sub(user.expired).add(lockDuration).mul(user.amount).mul(rewardRate).div(10 ** 12);
        IERC20(kawaiiToken).safeTransfer(sender, totalReward.add(user.amount));
        userInfo[sender].totalLock = userInfo[sender].totalLock.sub(user.amount);
        user.isClaim = true;
        totalLockedAmount = totalLockedAmount.sub(user.amount);
        emit Withdraw(sender, user.amount, index, block.timestamp);
    }


    function withdrawPermit(uint256 index, address sender, uint8 v, bytes32 r, bytes32 s) public {
        verify(keccak256(abi.encode(DATA_HASH, index, nonces[sender]++)), sender, v, r, s);
        _withdraw(index, sender);
    }

    function withdraw(uint256 index) public {
        _withdraw(index, msg.sender);
    }


    function setReward(uint256 amountReward) public onlyOwner {
        require(amountReward > 0, "amount zero");
        IERC20(kawaiiToken).safeTransferFrom(msg.sender, address(this), amountReward);
        uint256 rewardPerShare = amountReward.mul(10 ** 18).div(totalLockedAmount);
        poolAccShare = poolAccShare.add(rewardPerShare);
        currentRevenueShareReward = amountReward;
        currentRevenueShareTimestamp = block.timestamp;
        emit SetReward(amountReward, block.timestamp, rewardPerShare, poolAccShare);
    }

    function pendingRevenueReward(address sender) public view returns (uint256) {
        return poolAccShare
        .sub(userInfo[sender].accUserShare)
        .mul(userInfo[sender].totalLock)
        .div(10 ** 18)
        .add(userInfo[sender].pendingReward);
    }

    function getLockInfo(address user) public view returns (LockInfo[] memory) {
        return userInfo[user].lockInfo;
    }

    function getLockInfoLength(address user) public view returns (uint256) {
        return userInfo[user].lockInfo.length;
    }

    function getLockInfoAt(address user, uint256 index) public view returns (LockInfo memory) {
        return userInfo[user].lockInfo[index];
    }

    function inCaseTokenStuck(address token, address to, uint256 amount) public onlyOwner {
        IERC20(token).safeTransfer(to, amount);
    }
}