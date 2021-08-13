/**
 *Submitted for verification at BscScan.com on 2021-08-12
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IBEP20 {
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
        return payable(account);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }
}

library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeBEP20: decreased allowance below zero"
        );
        callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function callOptionalReturn(IBEP20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeBEP20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeBEP20: low-level call failed");

        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeBEP20: BEP20 operation did not succeed"
            );
        }
    }
}

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
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
    mapping(address => uint256) public nonces;
    bytes32 public UNLOCK_TYPE_HASH;
    bytes32 public LOCK_TYPE_HASH;
    bytes32 public UPDATE_EPOCH_TYPE_HASH;

    constructor() {
        NAME = "RIFI BRIDGE LOCKER";
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(NAME)),
                keccak256(bytes("1")),
                chainId,
                this
            )
        );
        UNLOCK_TYPE_HASH = keccak256(
            "Data(address[] senders,address[] receivers,uint256[] amount,uint256 epoch,uint256 deadline,uint256 nonce)"
        );
        LOCK_TYPE_HASH = keccak256(
            "Data(address ethAddress,uint256 amount,uint256 deadline,uint256 nonce)"
        );
        UPDATE_EPOCH_TYPE_HASH = keccak256("Data(uint256 nonce)");
    }

    function verify(
        bytes32 data,
        address sender,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public view {
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, data)
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(
            recoveredAddress != address(0) && recoveredAddress == sender,
            "Invalid nonce"
        );
    }
}

contract RIFIChainBridge is Ownable, SignData {
    using SafeBEP20 for IBEP20;
    using Address for address;
    using SafeMath for uint256;

    struct BridgeUserData {
        uint256 timestamp;
        uint256 bridgeAmount;
    }

    struct BridgeData {
        address sender;
        address ethAddress;
        uint256 amount;
    }

    uint256 public MAX_DAILY_BRIDGE;
    uint256 public MAX_AMOUNT_BRIDGE;
    IBEP20 public rifi;
    mapping(address => bool) public unlockedRoles;

    uint256 public epochs;
    // etherEpoch => bool
    mapping(uint256 => bool) public isUnlocked;
    // epochs => index => BridgeData
    mapping(uint256 => BridgeData[]) public bridgeData;
    // user=> BridgeUserData
    mapping(address => BridgeUserData) public bridgeUserData;

    event Unlock(
        uint256 indexed receiveEpoch,
        address sender,
        address receiver,
        uint256 amount,
        uint256 indexed index
    );

    event Lock(
        address sender,
        address receiver,
        uint256 amount,
        uint256 indexed epoch
    );

    constructor(
        IBEP20 _rifi,
        uint256 _maxDailyAmount,
        uint256 _maxAmountInTx
    ) {
        rifi = _rifi;
        MAX_AMOUNT_BRIDGE = _maxAmountInTx;
        MAX_DAILY_BRIDGE = _maxDailyAmount;
        unlockedRoles[msg.sender] = true;
    }

    modifier ensure(uint256 deadline) {
        require(deadline > block.timestamp, "DEADLINE_OUT_OF_DATE");
        _;
    }

    function setDailyAmount(uint256 _amount) public onlyOwner {
        MAX_DAILY_BRIDGE = _amount;
    }

    function setMaxAmountInTx(uint256 _amount) public onlyOwner {
        MAX_AMOUNT_BRIDGE = _amount;
    }

    function setRifi(IBEP20 _rifi) public onlyOwner {
        rifi = _rifi;
    }

    function setUnlockRoles(address _user, bool _result) public onlyOwner {
        unlockedRoles[_user] = _result;
    }

    function getBridgeDataLength(uint256 epoch) public view returns (uint256) {
        return bridgeData[epoch].length;
    }

    function lockRifi(address ethAddress, uint256 amount) public {
        _lockRifi(msg.sender, ethAddress, amount);
    }

    function lockRifiPermit(
        address sender,
        address ethAddress,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public ensure(deadline) {
        verify(
            keccak256(
                abi.encode(
                    LOCK_TYPE_HASH,
                    ethAddress,
                    amount,
                    deadline,
                    nonces[sender]++
                )
            ),
            sender,
            v,
            r,
            s
        );
        _lockRifi(sender, ethAddress, amount);
    }

    function _lockRifi(
        address sender,
        address ethAddress,
        uint256 amount
    ) internal {
        uint256 timestamp = block.timestamp;
        BridgeUserData storage _bridgeUserData = bridgeUserData[sender];
        if (timestamp - _bridgeUserData.timestamp > 1 days) {
            _bridgeUserData.timestamp = timestamp;
            _bridgeUserData.bridgeAmount = amount;
        } else {
            _bridgeUserData.bridgeAmount = _bridgeUserData.bridgeAmount.add(
                amount
            );
        }
        require(amount <= MAX_AMOUNT_BRIDGE, "Exceed amount limit");
        require(
            _bridgeUserData.bridgeAmount <= MAX_DAILY_BRIDGE,
            "Exceed daily limit"
        );

        rifi.safeTransferFrom(sender, address(this), amount);
        BridgeData memory _bridgeData = BridgeData(sender, ethAddress, amount);
        bridgeData[epochs].push(_bridgeData);

        emit Lock(sender, ethAddress, amount, epochs);
    }

    function updateEpochPermit(
        address sender,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        verify(
            keccak256(abi.encode(UPDATE_EPOCH_TYPE_HASH, nonces[sender]++)),
            sender,
            v,
            r,
            s
        );
        _updateEpoch(sender);
    }

    function updateEpoch() public {
        _updateEpoch(msg.sender);
    }

    function _updateEpoch(address sender) internal {
        require(unlockedRoles[sender], "Forbidden");
        require(getBridgeDataLength(epochs) > 0, "getBridgeDataLength=0");
        epochs++;
    }

    function unlockRifiPermit(
        address[] memory senders,
        address[] memory receivers,
        uint256[] memory amounts,
        uint256 receiveEpoch,
        uint256 deadline,
        address sender,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external ensure(deadline) {
        verify(
            keccak256(
                abi.encode(
                    UNLOCK_TYPE_HASH,
                    receivers,
                    amounts,
                    receiveEpoch,
                    deadline,
                    nonces[sender]++
                )
            ),
            sender,
            v,
            r,
            s
        );
        _unlockRifi(senders, receivers, amounts, receiveEpoch, sender);
    }

    function unlockRifi(
        address[] memory senders,
        address[] memory receivers,
        uint256[] memory amounts,
        uint256 receiveEpoch
    ) external {
        _unlockRifi(senders, receivers, amounts, receiveEpoch, msg.sender);
    }

    function _unlockRifi(
        address[] memory senders,
        address[] memory receivers,
        uint256[] memory amounts,
        uint256 receiveEpoch,
        address sender
    ) internal {
        require(unlockedRoles[sender], "Forbidden");
        require(receivers.length == amounts.length, "Invalid data");
        require(isUnlocked[receiveEpoch] == false, "Unlocked");
        isUnlocked[receiveEpoch] = true;
        for (uint256 i = 0; i < receivers.length; i++) {
            rifi.safeTransfer(receivers[i], amounts[i]);
            emit Unlock(receiveEpoch, senders[i], receivers[i], amounts[i], i);
        }
    }

    function inCaseStuckToken(
        IBEP20 token,
        address to,
        uint256 amount
    ) public onlyOwner {
        token.safeTransfer(to, amount);
    }
}