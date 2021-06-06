pragma solidity 0.6.12;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
    external
    returns (bool);

    function allowance(address owner, address spender)
    external
    view
    returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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


        bytes32 accountHash
        = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
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

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0), "SafeERC20: approve from non-zero to non-zero allowance");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
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

contract SignData {
    bytes32 public DOMAIN_SEPARATOR;
    string public NAME;
    mapping(address => uint) public nonces;
    bytes32 public UNLOCK_TYPE_HASH;
    bytes32 public LOCK_TYPE_HASH;
    bytes32 public UPDATE_EPOCH_TYPE_HASH;

    constructor() public {
        NAME = "ORAI LOCKER";
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
        UNLOCK_TYPE_HASH = keccak256("Data(address[] receives,uint256[] amount,uint256 epoch,uint256 deadline,uint256 nonce)");
        LOCK_TYPE_HASH = keccak256("Data(address bscAddress,uint256 amount,uint256 deadline,uint256 nonce)");
        UPDATE_EPOCH_TYPE_HASH = keccak256("Data(uint256 nonce)");
    }

    function verify(bytes32 data, address sender, uint8 v, bytes32 r, bytes32 s) public {
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

contract ETHToBSCLocker is Ownable, SignData {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    uint256 public epochs;
    uint256 public MAX_AMOUNT_SWAP;
    uint256 public MAX_DAILY_SWAP;
    IERC20 public orai;
    mapping(address => bool) public  unlockedRoles;

    //etherEpoch=> bool
    mapping(uint256 => bool) public  isUnlocked;

    struct SwapUserData {
        uint256 timestamp;
        uint256 swapAmount;
    }

    struct SwapData {
        address sender;
        address bscAddress;
        uint256 amount;
    }

    // epochs => index =>SwapData
    mapping(uint256 => SwapData[]) public swapData;

    //user=> SwapUserData
    mapping(address => SwapUserData) public swapUserData;

    constructor(IERC20 _orai, uint256 _maxDailyAmount, uint256 _maxAmountInTx) public {
        orai = _orai;
        MAX_AMOUNT_SWAP = _maxAmountInTx;
        MAX_DAILY_SWAP = _maxDailyAmount;
        unlockedRoles[msg.sender] = true;
    }

    function setOrai(IERC20 _orai) public onlyOwner {
        orai = _orai;
    }

    function getSwapDataLength(uint256 epoch) public view returns (uint256){
        return swapData[epoch].length;
    }

    function setDailyAmount(uint256 _amount) public onlyOwner {
        MAX_DAILY_SWAP = _amount;
    }

    function setMaxAmountInTx(uint256 _amount) public onlyOwner {
        MAX_AMOUNT_SWAP = _amount;
    }

    function lockOrai(address ethAddress, uint256 amount) public {
        _lockOrai(msg.sender, ethAddress, amount);
    }

    function lockOraiPermit(address sender, address bscAddress, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
        verify(keccak256(abi.encode(LOCK_TYPE_HASH, bscAddress, amount, deadline, nonces[sender]++)), sender, v, r, s);
        _lockOrai(sender, bscAddress, amount);
    }

    function _updateEpoch(address sender) internal {
        require(unlockedRoles[sender], "Forbidden");
        require(getSwapDataLength(epochs) > 0, "getSwapDataLength=0");
        epochs++;
    }

    function updateEpochPermit(address sender, uint8 v, bytes32 r, bytes32 s) public {
        verify(keccak256(abi.encode(UPDATE_EPOCH_TYPE_HASH, nonces[sender]++)), sender, v, r, s);
        _updateEpoch(sender);
    }

    function updateEpoch() public {
        _updateEpoch(msg.sender);
    }

    function _lockOrai(address sender, address bscAddress, uint256 amount) internal {
        uint256 timestamp = block.timestamp;
        SwapUserData storage _swapUserData = swapUserData[sender];
        if (timestamp - _swapUserData.timestamp > 1 days) {
            _swapUserData.timestamp = timestamp;
            _swapUserData.swapAmount = amount;
        } else {
            _swapUserData.swapAmount = _swapUserData.swapAmount.add(amount);
        }
        require(amount <= MAX_AMOUNT_SWAP, "Exceed amount limit");
        require(_swapUserData.swapAmount <= MAX_DAILY_SWAP, "Exceed daily limit");

        orai.safeTransferFrom(sender, address(this), amount);
        SwapData memory _swapData = SwapData(sender, bscAddress, amount);
        swapData[epochs].push(_swapData);
    }

    event Unlock(uint256 indexed ethEpoch, address receiver, uint256 amount, uint256 indexed bscIndex);

    function unlockOraiPermit(address[] memory receives, uint256[] memory amounts, uint256 ethEpoch, uint256 deadline, address sender, uint8 v, bytes32 r, bytes32 s) external {
        verify(keccak256(abi.encode(UNLOCK_TYPE_HASH, receives, amounts, ethEpoch, deadline, nonces[sender]++)), sender, v, r, s);
        _unlockOrai(receives, amounts, ethEpoch, sender);
    }

    function unlockOrai(address[] memory receives, uint256[] memory amounts, uint256 ethEpoch) external {
        _unlockOrai(receives, amounts, ethEpoch, msg.sender);
    }

    function _unlockOrai(address[] memory receives, uint256[] memory amounts, uint256 ethEpoch, address sender) internal {
        require(unlockedRoles[sender], "Forbidden");
        require(receives.length == amounts.length, "Invalid data");
        require(isUnlocked[ethEpoch] == false, "Unlocked");
        isUnlocked[ethEpoch] = true;
        for (uint256 i = 0; i < receives.length; i++) {
            orai.safeTransfer(receives[i], amounts[i]);
            emit Unlock(ethEpoch, receives[i], amounts[i], i);
        }
    }

    function inCaseStuckToken(IERC20 token, address to, uint256 amount) public onlyOwner {
        token.safeTransfer(to, amount);
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}