pragma solidity ^0.4.24;

// File: libs/EC.sol

contract EC {

    uint256 constant public gx = 0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798;
    uint256 constant public gy = 0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8;
    uint256 constant public n = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;
    uint256 constant public a = 0;
    uint256 constant public b = 7;

    function _jAdd(
        uint256 x1, uint256 z1,
        uint256 x2, uint256 z2)
        public 
        pure
        returns(uint256 x3, uint256 z3)
    {
        (x3, z3) = (
            addmod(
                mulmod(z2, x1, n),
                mulmod(x2, z1, n),
                n
            ),
            mulmod(z1, z2, n)
        );
    }

    function _jSub(
        uint256 x1, uint256 z1,
        uint256 x2, uint256 z2)
        public 
        pure
        returns(uint256 x3, uint256 z3)
    {
        (x3, z3) = (
            addmod(
                mulmod(z2, x1, n),
                mulmod(n - x2, z1, n),
                n
            ),
            mulmod(z1, z2, n)
        );
    }

    function _jMul(
        uint256 x1, uint256 z1,
        uint256 x2, uint256 z2)
        public 
        pure
        returns(uint256 x3, uint256 z3)
    {
        (x3, z3) = (
            mulmod(x1, x2, n),
            mulmod(z1, z2, n)
        );
    }

    function _jDiv(
        uint256 x1, uint256 z1,
        uint256 x2, uint256 z2) 
        public 
        pure
        returns(uint256 x3, uint256 z3)
    {
        (x3, z3) = (
            mulmod(x1, z2, n),
            mulmod(z1, x2, n)
        );
    }

    function _inverse(uint256 val) public pure
        returns(uint256 invVal)
    {
        uint256 t = 0;
        uint256 newT = 1;
        uint256 r = n;
        uint256 newR = val;
        uint256 q;
        while (newR != 0) {
            q = r / newR;

            (t, newT) = (newT, addmod(t, (n - mulmod(q, newT, n)), n));
            (r, newR) = (newR, r - q * newR );
        }

        return t;
    }

    function _ecAdd(
        uint256 x1, uint256 y1, uint256 z1,
        uint256 x2, uint256 y2, uint256 z2) 
        public 
        pure
        returns(uint256 x3, uint256 y3, uint256 z3)
    {
        uint256 lx;
        uint256 lz;
        uint256 da;
        uint256 db;

        if (x1 == 0 && y1 == 0) {
            return (x2, y2, z2);
        }

        if (x2 == 0 && y2 == 0) {
            return (x1, y1, z1);
        }

        if (x1 == x2 && y1 == y2) {
            (lx, lz) = _jMul(x1, z1, x1, z1);
            (lx, lz) = _jMul(lx, lz, 3, 1);
            (lx, lz) = _jAdd(lx, lz, a, 1);

            (da,db) = _jMul(y1, z1, 2, 1);
        } else {
            (lx, lz) = _jSub(y2, z2, y1, z1);
            (da, db) = _jSub(x2, z2, x1, z1);
        }

        (lx, lz) = _jDiv(lx, lz, da, db);

        (x3, da) = _jMul(lx, lz, lx, lz);
        (x3, da) = _jSub(x3, da, x1, z1);
        (x3, da) = _jSub(x3, da, x2, z2);

        (y3, db) = _jSub(x1, z1, x3, da);
        (y3, db) = _jMul(y3, db, lx, lz);
        (y3, db) = _jSub(y3, db, y1, z1);

        if (da != db) {
            x3 = mulmod(x3, db, n);
            y3 = mulmod(y3, da, n);
            z3 = mulmod(da, db, n);
        } else {
            z3 = da;
        }
    }

    function _ecDouble(uint256 x1, uint256 y1, uint256 z1) public pure
        returns(uint256 x3, uint256 y3, uint256 z3)
    {
        (x3, y3, z3) = _ecAdd(x1, y1, z1, x1, y1, z1);
    }

    function _ecMul(uint256 d, uint256 x1, uint256 y1, uint256 z1) public pure
        returns(uint256 x3, uint256 y3, uint256 z3)
    {
        uint256 remaining = d;
        uint256 px = x1;
        uint256 py = y1;
        uint256 pz = z1;
        uint256 acx = 0;
        uint256 acy = 0;
        uint256 acz = 1;

        if (d == 0) {
            return (0, 0, 1);
        }

        while (remaining != 0) {
            if ((remaining & 1) != 0) {
                (acx,acy,acz) = _ecAdd(acx, acy, acz, px, py, pz);
            }
            remaining = remaining / 2;
            (px, py, pz) = _ecDouble(px, py, pz);
        }

        (x3, y3, z3) = (acx, acy, acz);
    }

    function ecadd(
        uint256 x1, uint256 y1,
        uint256 x2, uint256 y2)
        public
        pure
        returns(uint256 x3, uint256 y3)
    {
        uint256 z;
        (x3, y3, z) = _ecAdd(x1, y1, 1, x2, y2, 1);
        z = _inverse(z);
        x3 = mulmod(x3, z, n);
        y3 = mulmod(y3, z, n);
    }

    function ecmul(uint256 x1, uint256 y1, uint256 scalar) public pure
        returns(uint256 x2, uint256 y2)
    {
        uint256 z;
        (x2, y2, z) = _ecMul(scalar, x1, y1, 1);
        z = _inverse(z);
        x2 = mulmod(x2, z, n);
        y2 = mulmod(y2, z, n);
    }

    function ecmulVerify(uint256 x1, uint256 y1, uint256 scalar, uint256 qx, uint256 qy) public pure
        returns(bool)
    {
        uint256 m = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;
        address signer = ecrecover(0, y1 % 2 != 0 ? 28 : 27, bytes32(x1), bytes32(mulmod(scalar, x1, m)));
        address xyAddress = address(uint256(keccak256(abi.encodePacked(qx, qy))) & 0x00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return xyAddress == signer;
    }

    function publicKey(uint256 privKey) public pure
        returns(uint256 qx, uint256 qy)
    {
        return ecmul(gx, gy, privKey);
    }

    function publicKeyVerify(uint256 privKey, uint256 x, uint256 y) public pure
        returns(bool)
    {
        return ecmulVerify(gx, gy, privKey, x, y);
    }

    function deriveKey(uint256 privKey, uint256 pubX, uint256 pubY) public pure
        returns(uint256 qx, uint256 qy)
    {
        uint256 z;
        (qx, qy, z) = _ecMul(privKey, pubX, pubY, 1);
        z = _inverse(z);
        qx = mulmod(qx, z, n);
        qy = mulmod(qy, z, n);
    }
}

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// File: contracts/Upgradable.sol

contract IUpgradable {
    function startUpgrade() public;
    function endUpgrade() public;
}

contract Upgradable is Ownable {
    struct UpgradableState {
        bool isUpgrading;
        address prevVersion;
        address nextVersion;
    }

    UpgradableState public upgradableState;

    event Initialized(address indexed prevVersion);
    event Upgrading(address indexed nextVersion);
    event Upgraded(address indexed nextVersion);

    modifier isLastestVersion {
        require(!upgradableState.isUpgrading);
        require(upgradableState.nextVersion == address(0));
        _;
    }

    modifier onlyOwnerOrigin {
        require(tx.origin == owner);
        _;
    }

    constructor(address _prevVersion) public {
        if (_prevVersion != address(0)) {
            require(msg.sender == Ownable(_prevVersion).owner());
            upgradableState.isUpgrading = true;
            upgradableState.prevVersion = _prevVersion;
            IUpgradable(_prevVersion).startUpgrade();
        } else {
            emit Initialized(_prevVersion);
        }
    }

    function startUpgrade() public onlyOwnerOrigin {
        require(msg.sender != owner);
        require(!upgradableState.isUpgrading);
        require(upgradableState.nextVersion == 0);
        upgradableState.isUpgrading = true;
        upgradableState.nextVersion = msg.sender;
        emit Upgrading(msg.sender);
    }

    //function upgrade(uint index, uint size) public onlyOwner {}

    function endUpgrade() public onlyOwnerOrigin {
        require(upgradableState.isUpgrading);
        upgradableState.isUpgrading = false;
        if (msg.sender != owner) {
            require(upgradableState.nextVersion == msg.sender);
            emit Upgraded(upgradableState.nextVersion);
        } 
        else  {
            if (upgradableState.prevVersion != address(0)) {
                Upgradable(upgradableState.prevVersion).endUpgrade();
            }
            emit Initialized(upgradableState.prevVersion);
        }
    }
}

// File: contracts/VanityLib.sol

contract VanityLib {
    uint constant m = 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f;

    function lengthOfCommonPrefix(bytes32 a, bytes32 b) public pure returns(uint) {
        for (uint i = 0; i < 32; i++) {
            if (a[i] != b[i] || a[i] == 0) {
                return i;
            }
        }
        return 0;
    }
    
    function bytesToBytes32(bytes source) public pure returns(bytes32 result) {
        assembly {
            result := mload(add(source, 32))
        }
    }

    /* Converts given number to base58, limited by 32 symbols */
    function toBase58Checked(uint256 _value, byte appCode) public pure returns(bytes32) {
        string memory letters = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";
        bytes memory alphabet = bytes(letters);
        uint8 base = 58;
        uint8 len = 0;
        uint256 remainder = 0;
        bool needBreak = false;
        bytes memory bytesReversed = bytes(new string(32));
        
        for (uint8 i = 0; true; i++) {
            if (_value < base) {
                needBreak = true;
            }
            remainder = _value % base;
            _value = uint256(_value / base);
            if (len == 32) {
                for (uint j = 0; j < len - 1; j++) {
                    bytesReversed[j] = bytesReversed[j + 1];
                }
                len--;
            }
            bytesReversed[len] = alphabet[remainder];
            len++;
            if (needBreak) {
                break;
            }
        }
        
        // Reverse
        bytes memory result = bytes(new string(32));
        result[0] = appCode;
        for (i = 0; i < 31; i++) {
            result[i + 1] = bytesReversed[len - 1 - i];
        }
        
        return bytesToBytes32(result);
    }

    // Create BTC Address: https://en.bitcoin.it/wiki/Technical_background_of_version_1_Bitcoin_addresses#How_to_create_Bitcoin_Address
    function createBtcAddressHex(uint256 publicXPoint, uint256 publicYPoint) public pure returns(uint256) {
        bytes20 publicKeyPart = ripemd160(abi.encodePacked(sha256(abi.encodePacked(byte(0x04), publicXPoint, publicYPoint))));
        bytes32 publicKeyCheckCode = sha256(abi.encodePacked(sha256(abi.encodePacked(byte(0x00), publicKeyPart))));
        
        bytes memory publicKey = new bytes(32);
        for (uint i = 0; i < 7; i++) {
            publicKey[i] = 0x00;
        }
        publicKey[7] = 0x00; // Main Network
        for (uint j = 0; j < 20; j++) {
            publicKey[j + 8] = publicKeyPart[j];
        }
        publicKey[28] = publicKeyCheckCode[0];
        publicKey[29] = publicKeyCheckCode[1];
        publicKey[30] = publicKeyCheckCode[2];
        publicKey[31] = publicKeyCheckCode[3];
        
        return uint256(bytesToBytes32(publicKey));
    }
    
    function createBtcAddress(uint256 publicXPoint, uint256 publicYPoint) public pure returns(bytes32) {
        return toBase58Checked(createBtcAddressHex(publicXPoint, publicYPoint), "1");
    }

    function complexityForBtcAddressPrefix(bytes prefix) public pure returns(uint) {
        return complexityForBtcAddressPrefixWithLength(prefix, prefix.length);
    }

    // https://bitcoin.stackexchange.com/questions/48586
    function complexityForBtcAddressPrefixWithLength(bytes prefix, uint length) public pure returns(uint) {
        require(prefix.length >= length);
        
        uint8[128] memory unbase58 = [
            255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 
            255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
            255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 
            255, 0, 1, 2, 3, 4, 5, 6, 7, 8, 255, 255, 255, 255, 255, 255, 
            255, 9, 10, 11, 12, 13, 14, 15, 16, 255, 17, 18, 19, 20, 21, 255, 
            22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 255, 255, 255, 255, 255,
            255, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 255, 44, 45, 46,
            47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 255, 255, 255, 255, 255
        ];

        uint leadingOnes = countBtcAddressLeadingOnes(prefix, length);

        uint256 prefixValue = 0;
        uint256 prefix1 = 1;
        for (uint i = 0; i < length; i++) {
            uint index = uint(prefix[i]);
            require(index != 255);
            prefixValue = prefixValue * 58 + unbase58[index];
            prefix1 *= 58;
        }

        uint256 top = (uint256(1) << (200 - 8*leadingOnes));
        uint256 total = 0;
        uint256 prefixMin = prefixValue;
        uint256 diff = 0;
        for (uint digits = 1; prefix1/58 < (1 << 192); digits++) {
            prefix1 *= 58;
            prefixMin *= 58;
            prefixValue = prefixValue * 58 + 57;

            diff = 0;
            if (prefixValue >= top) {
                diff += prefixValue - top;
            }
            if (prefixMin < (top >> 8)) {
                diff += (top >> 8) - prefixMin;
            }
            
            if ((58 ** digits) >= diff) {
                total += (58 ** digits) - diff;
            }
        }

        if (prefixMin == 0) { // if prefix is contains only ones: 111111
            total = (58 ** (digits - 1)) - diff;
        }

        return (1 << 192) / total;
    }

    function countBtcAddressLeadingOnes(bytes prefix, uint length) public pure returns(uint) {
        uint leadingOnes = 1;
        for (uint j = 0; j < length && prefix[j] == 49; j++) {
            leadingOnes = j + 1;
        }
        return leadingOnes;
    }

    function isValidBicoinAddressPrefix(bytes prefixArg) public pure returns(bool) {
        if (prefixArg.length < 5) {
            return false;
        }
        if (prefixArg[0] != "1" && prefixArg[0] != "3") {
            return false;
        }
        
        for (uint i = 0; i < prefixArg.length; i++) {
            byte ch = prefixArg[i];
            if (ch == "0" || ch == "O" || ch == "I" || ch == "l") {
                return false;
            }
            if (!((ch >= "1" && ch <= "9") || (ch >= "a" && ch <= "z") || (ch >= "A" && ch <= "Z"))) {
                return false;
            }
        }

        return true;
    }

    function isValidPublicKey(uint256 x, uint256 y) public pure returns(bool) {
        return (mulmod(y, y, m) == addmod(mulmod(x, mulmod(x, x, m), m), 7, m));
    }

}

// File: zeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: zeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: zeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: contracts/TaskRegister.sol

contract TaskRegister is Upgradable, VanityLib {
    using SafeMath for uint256;

    enum TaskType {
        BITCOIN_ADDRESS_PREFIX
    }

    struct Task {
        TaskType taskType;
        uint256 taskId;
        address creator;
        address referrer;
        uint256 reward;
        bytes32 data;
        uint256 dataLength;
        uint256 requestPublicXPoint;
        uint256 requestPublicYPoint;
        uint256 answerPrivateKey;
    }

    EC public ec;
    uint256 public nextTaskId = 1;
    uint256 public totalReward;
    uint256 constant public MAX_PERCENT = 1000000;
    uint256 public serviceFee; // 1% == 10000, 100% == 1000000
    uint256 public referrerFee; // Calculated from service fee, 50% == 500000
    
    Task[] public tasks;
    Task[] public completedTasks;
    mapping(uint256 => uint) public indexOfTaskId; // Starting from 1

    event TaskCreated(uint256 indexed taskId);
    event TaskSolved(uint256 indexed taskId, uint256 reward);
    event TaskPayed(uint256 indexed taskId, uint256 value);

    constructor(address _ec, address _prevVersion) public Upgradable(_prevVersion) {
        ec = EC(_ec);
    }

    function setServiceFee(uint256 _serviceFee) public onlyOwner {
        require(_serviceFee <= 20000); // 2% of reward
        serviceFee = _serviceFee;
    }

    function setReferrerFee(uint256 _referrerFee) public onlyOwner {
        require(_referrerFee <= 500000); // 50% of serviceFee
        referrerFee = _referrerFee;
    }

    function upgrade(uint _size) public onlyOwner {
        require(upgradableState.isUpgrading);
        require(upgradableState.prevVersion != 0);

        // Migrate some vars
        nextTaskId = TaskRegister(upgradableState.prevVersion).nextTaskId();
        totalReward = TaskRegister(upgradableState.prevVersion).totalReward();
        serviceFee = TaskRegister(upgradableState.prevVersion).serviceFee();
        referrerFee = TaskRegister(upgradableState.prevVersion).referrerFee();
        
        uint index = tasks.length;
        uint tasksCount = TaskRegister(upgradableState.prevVersion).tasksCount();

        // Migrate tasks

        for (uint i = index; i < index + _size && i < tasksCount; i++) {
            tasks.push(Task(TaskType.BITCOIN_ADDRESS_PREFIX,0,0,0,0,bytes32(0),0,0,0,0));
        }

        for (uint j = index; j < index + _size && j < tasksCount; j++) {
            (
                tasks[j].taskType,
                tasks[j].taskId,
                tasks[j].creator,
                tasks[j].referrer,
                ,//tasks[j].reward,
                ,//tasks[j].data,
                ,//tasks[j].dataLength, 
                ,//tasks[j].requestPublicXPoint, 
                ,//tasks[j].requestPublicYPoint,
                 //tasks[j].answerPrivateKey
            ) = TaskRegister(upgradableState.prevVersion).tasks(j);
            indexOfTaskId[tasks[j].taskId] = j + 1;
        }

        for (j = index; j < index + _size && j < tasksCount; j++) {
            (
                ,//tasks[j].taskType,
                ,//tasks[j].taskId,
                ,//tasks[j].creator,
                ,//tasks[j].referrer,
                tasks[j].reward,
                tasks[j].data,
                tasks[j].dataLength, 
                tasks[j].requestPublicXPoint, 
                ,//tasks[j].requestPublicYPoint,
                 //tasks[j].answerPrivateKey
            ) = TaskRegister(upgradableState.prevVersion).tasks(j);
        }

        for (j = index; j < index + _size && j < tasksCount; j++) {
            (
                ,//tasks[j].taskType,
                ,//tasks[j].taskId,
                ,//tasks[j].creator,
                ,//tasks[j].referrer,
                ,//tasks[j].reward,
                ,//tasks[j].data,
                ,//tasks[j].dataLength, 
                ,//tasks[j].requestPublicXPoint, 
                tasks[j].requestPublicYPoint,
                tasks[j].answerPrivateKey
            ) = TaskRegister(upgradableState.prevVersion).tasks(j);
        }
    }
    
    function endUpgrade() public {
        super.endUpgrade();
    }

    function tasksCount() public view returns(uint) {
        return tasks.length;
    }

    function completedTasksCount() public view returns(uint) {
        return completedTasks.length;
    }

    function payForTask(uint256 _taskId) payable public isLastestVersion {
        if (msg.value > 0) {
            Task storage task = tasks[safeIndexOfTaskId(_taskId)];
            task.reward = task.reward.add(msg.value);
            totalReward = totalReward.add(msg.value);
            emit TaskPayed(_taskId, msg.value);
        }
    }

    function safeIndexOfTaskId(uint _taskId) public view returns(uint) {
        return indexOfTaskId[_taskId].sub(1);
    }
    
    function createBitcoinAddressPrefixTask(
        bytes prefix,
        uint256 requestPublicXPoint,
        uint256 requestPublicYPoint,
        address referrer
    )
        payable
        public
        isLastestVersion
    {
        require(prefix.length > 5);
        require(prefix[0] == "1");
        require(prefix[1] != "1"); // Do not support multiple 1s yet
        require(isValidBicoinAddressPrefix(prefix));
        require(isValidPublicKey(requestPublicXPoint, requestPublicYPoint));

        bytes32 data;
        assembly {
            data := mload(add(prefix, 32))
        }
        
        Task memory task = Task({
            taskType: TaskType.BITCOIN_ADDRESS_PREFIX,
            taskId: nextTaskId++,
            creator: msg.sender,
            referrer: referrer,
            reward: 0,
            data: data,
            dataLength: prefix.length,
            requestPublicXPoint: requestPublicXPoint,
            requestPublicYPoint: requestPublicYPoint,
            answerPrivateKey: 0
        });

        indexOfTaskId[task.taskId] = tasks.push(task); // incremented to avoid 0 index
        emit TaskCreated(task.taskId);
        payForTask(task.taskId);
    }
    
    function solveTask(uint _taskId, uint256 _answerPrivateKey, uint256 publicXPoint, uint256 publicYPoint) public isLastestVersion {
        uint taskIndex = safeIndexOfTaskId(_taskId);
        Task storage task = tasks[taskIndex];
        require(task.answerPrivateKey == 0, "solveTask: task is already solved");

        // Require private key to be part of address to prevent front-running attack
        require(_answerPrivateKey >> 128 == uint256(msg.sender) >> 32, "solveTask: this solution does not match miner address");

        if (task.taskType == TaskType.BITCOIN_ADDRESS_PREFIX) {
            ///(publicXPoint, publicYPoint) = ec.publicKey(_answerPrivateKey);
            require(ec.publicKeyVerify(_answerPrivateKey, publicXPoint, publicYPoint));
            (publicXPoint, publicYPoint) = ec.ecadd(
                task.requestPublicXPoint,
                task.requestPublicYPoint,
                publicXPoint,
                publicYPoint
            );

            require(isValidPublicKey(publicXPoint, publicYPoint));
            
            bytes32 btcAddress = createBtcAddress(publicXPoint, publicYPoint);
            uint prefixLength = lengthOfCommonPrefix(btcAddress, task.data);
            require(prefixLength == task.dataLength);
            
            task.answerPrivateKey = _answerPrivateKey;
        } else {
            revert();
        }

        uint256 minerReward = task.reward.mul(MAX_PERCENT - serviceFee).div(MAX_PERCENT); // 1% fee
        msg.sender.transfer(minerReward);
        totalReward = totalReward.sub(minerReward);

        if (task.referrer != 0) {
            uint256 referrerReward = task.reward.mul(serviceFee).mul(referrerFee).div(MAX_PERCENT).div(MAX_PERCENT); // 50% of service fee
            task.referrer.transfer(referrerReward);
            totalReward = totalReward.sub(referrerReward);
        }

        _completeTask(_taskId, taskIndex);
        emit TaskSolved(_taskId, minerReward);
    }

    function _completeTask(uint _taskId, uint _index) internal {
        completedTasks.push(tasks[_index]);
        if (_index < tasks.length - 1) { // if not latest
            tasks[_index] = tasks[tasks.length - 1];
            indexOfTaskId[tasks[_index].taskId] = _index + 1;
        }
        tasks.length -= 1;
        delete indexOfTaskId[_taskId];
    }

    function claim(ERC20Basic _token, address _to) public onlyOwner {
        if (_token == address(0)) {
            _to.transfer(address(this).balance - totalReward);
        } else {
            _token.transfer(_to, _token.balanceOf(this));
        }
    }

}