pragma solidity ^0.4.0;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
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
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract VanityLib {
    uint constant m = 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f;

    function lengthOfCommonPrefix(bytes a, bytes b) public pure returns(uint) {
        uint len = (a.length <= b.length) ? a.length : b.length;
        for (uint i = 0; i < len; i++) {
            if (a[i] != b[i]) {
                return i;
            }
        }
        return len;
    }
    
    function lengthOfCommonPrefix32(bytes32 a, bytes b) public pure returns(uint) {
        for (uint i = 0; i < b.length; i++) {
            if (a[i] != b[i]) {
                return i;
            }
        }
        return b.length;
    }

    function lengthOfCommonPrefix3232(bytes32 a, bytes32 b) public pure returns(uint) {
        for (uint i = 0; i < 32; i++) {
            if (a[i] != b[i] || a[i] == 0) {
                return i;
            }
        }
        return 0;
    }
    
    function equalBytesToBytes(bytes a, bytes b) public pure returns (bool) {
        if (a.length != b.length) {
            return false;
        }
        for (uint i = 0; i < a.length; i++) {
            if (a[i] != b[i]) {
                return false;
            }
        }
        return true;
    }
    
    function equalBytes32ToBytes(bytes32 a, bytes b) public pure returns (bool) {
        for (uint i = 0; i < b.length; i++) {
            if (a[i] != b[i]) {
                return false;
            }
        }
        return true;
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
        bytes20 publicKeyPart = ripemd160(sha256(byte(0x04), publicXPoint, publicYPoint));
        bytes32 publicKeyCheckCode = sha256(sha256(byte(0x00), publicKeyPart));
        
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

    // https://github.com/stonecoldpat/anonymousvoting/blob/master/LocalCrypto.sol
    function invmod(uint256 a, uint256 p) public pure returns (uint256) {
        int t1 = 0;
        int t2 = 1;
        uint r1 = p;
        uint r2 = a;
        uint q;
        while (r2 != 0) {
            q = r1 / r2;
            (t1, t2, r1, r2) = (t2, t1 - int(q) * t2, r2, r1 - q * r2);
        }

        return t1 < 0 ? p - uint(-t1) : uint(t1);
    }
    
    // https://github.com/stonecoldpat/anonymousvoting/blob/master/LocalCrypto.sol
    function submod(uint a, uint b, uint p) public pure returns (uint) {
        return addmod(a, p - b, p);
    }

    // https://en.wikipedia.org/wiki/Elliptic_curve_point_multiplication#Point_addition
    // https://github.com/bellaj/Blockchain/blob/6bffb47afae6a2a70903a26d215484cf8ff03859/ecdsa_bitcoin.pdf
    // https://math.stackexchange.com/questions/2198139/elliptic-curve-formulas-for-point-addition
    function addXY(uint x1, uint y1, uint x2, uint y2) public pure returns(uint x3, uint y3) {
        uint anti = invmod(submod(x1, x2, m), m);
        uint alpha = mulmod(submod(y1, y2, m), anti, m);
        x3 = submod(submod(mulmod(alpha, alpha, m), x1, m), x2, m);
        y3 = submod(mulmod(alpha, submod(x2, x3, m), m), y2, m);
        
        // x3 = bytes32(mul_mod(uint(x3), uint(y3), m)); == 1!!!!
        
        // https://github.com/jbaylina/ecsol/blob/master/ec.sol
        // x3 = addmod(mulmod(y2, x1, m), mulmod(x2, y1, m), m);
        // y3 = mulmod(y1, y2, m);
    }

    function doubleXY(uint x1, uint y1) public pure returns(uint x2, uint y2) {
        uint anti = invmod(addmod(y1, y1, m), m);
        uint alpha = mulmod(addmod(addmod(mulmod(x1, x1, m), mulmod(x1, x1, m), m), mulmod(x1, x1, m), m), anti, m);
        x2 = submod(mulmod(alpha, alpha, m), addmod(x1, x1, m), m);
        y2 = submod(mulmod(alpha, submod(x1, x2, m), m), y1, m);
    }

    function mulXY(uint x1, uint y1, uint privateKey) public pure returns(uint x2, uint y2) {
        bool addition = false;
        for (uint i = 0; i < 256; i++) {
            if (((privateKey >> i) & 1) == 1) {
                if (addition) {
                    (x2, y2) = addXY(x1, y1, x2, y2);
                } else {
                    (x2, y2) = (x1, y1);
                    addition = true;
                }
            }
            (x1,y1) = doubleXY(x1, y1);
        }
    }

    function bitcoinPublicKey(uint256 privateKey) public pure returns(uint, uint) {
        uint256 gx = 0x79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798;
        uint256 gy = 0x483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8;
        return mulXY(gx, gy, privateKey);
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

    function Upgradable(address _prevVersion) public {
        if (_prevVersion != address(0)) {
            require(msg.sender == Ownable(_prevVersion).owner());
            upgradableState.isUpgrading = true;
            upgradableState.prevVersion = _prevVersion;
            IUpgradable(_prevVersion).startUpgrade();
        } else {
            Initialized(_prevVersion);
        }
    }

    function startUpgrade() public onlyOwnerOrigin {
        require(msg.sender != owner);
        require(!upgradableState.isUpgrading);
        require(upgradableState.nextVersion == 0);
        upgradableState.isUpgrading = true;
        upgradableState.nextVersion = msg.sender;
        Upgrading(msg.sender);
    }

    //function upgrade(uint index, uint size) public onlyOwner {}

    function endUpgrade() public onlyOwnerOrigin {
        require(upgradableState.isUpgrading);
        upgradableState.isUpgrading = false;
        if (msg.sender != owner) {
            require(upgradableState.nextVersion == msg.sender);
            Upgraded(upgradableState.nextVersion);
        } 
        else  {
            if (upgradableState.prevVersion != address(0)) {
                Upgradable(upgradableState.prevVersion).endUpgrade();
            }
            Initialized(upgradableState.prevVersion);
        }
    }

}

contract IEC {

    function _inverse(uint256 a) public constant 
        returns(uint256 invA);

    function _ecAdd(uint256 x1,uint256 y1,uint256 z1,
                    uint256 x2,uint256 y2,uint256 z2) public constant
        returns(uint256 x3,uint256 y3,uint256 z3);

    function _ecDouble(uint256 x1,uint256 y1,uint256 z1) public constant
        returns(uint256 x3,uint256 y3,uint256 z3);

    function _ecMul(uint256 d, uint256 x1,uint256 y1,uint256 z1) public constant
        returns(uint256 x3,uint256 y3,uint256 z3);

    function publicKey(uint256 privKey) public constant
        returns(uint256 qx, uint256 qy);

    function deriveKey(uint256 privKey, uint256 pubX, uint256 pubY) public constant
        returns(uint256 qx, uint256 qy);

}

contract TaskRegister is Upgradable, VanityLib {

    enum TaskType {
        BITCOIN_ADDRESS_PREFIX
    }

    struct Task {
        TaskType taskType;
        uint256 taskId;
        address creator;
        uint256 reward;
        bytes32 data;
        uint256 dataLength;
        uint256 requestPublicXPoint;
        uint256 requestPublicYPoint;
        uint256 answerPrivateKey;
    }

    IEC public ec;
    ERC20 public token;
    uint256 public nextTaskId = 1;
    uint256 public totalReward;
    
    Task[] public tasks;
    Task[] public completedTasks;
    mapping(uint256 => uint) public indexOfTaskId; // Starting from 1
    event TaskCreated(uint256 indexed taskId);
    event TaskSolved(uint256 indexed taskId);
    event TaskPayed(uint256 indexed taskId);

    function TaskRegister(address _ec, address _token, address _prevVersion) public Upgradable(_prevVersion) {
        ec = IEC(_ec);
        token = ERC20(_token);
    }

    function upgrade(uint size) public onlyOwner {
        require(upgradableState.isUpgrading);
        require(upgradableState.prevVersion != 0);

        // Migrate some vars
        nextTaskId = TaskRegister(upgradableState.prevVersion).nextTaskId();
        totalReward = TaskRegister(upgradableState.prevVersion).totalReward();

        uint index = tasks.length;
        uint tasksCount = TaskRegister(upgradableState.prevVersion).tasksCount();

        // Migrate tasks

        for (uint i = index; i < index + size && i < tasksCount; i++) {
            tasks.push(Task(TaskType.BITCOIN_ADDRESS_PREFIX,0,0,0,bytes32(0),0,0,0,0));
        }

        for (uint j = index; j < index + size && j < tasksCount; j++) {
            (
                tasks[j].taskType,
                tasks[j].taskId,
                tasks[j].creator,
                tasks[j].reward,
                tasks[j].data,
                ,//tasks[j].dataLength, 
                ,//tasks[j].requestPublicXPoint, 
                ,//tasks[j].requestPublicYPoint,
                 //tasks[j].answerPrivateKey
            ) = TaskRegister(upgradableState.prevVersion).tasks(j);
            indexOfTaskId[tasks[j].taskId] = j + 1;
        }

        for (uint k = index; k < index + size && k < tasksCount; k++) {
            (
                ,//tasks[k].taskType,
                ,//tasks[k].taskId,
                ,//tasks[k].creator,
                ,//tasks[k].reward,
                ,//tasks[k].data,
                tasks[k].dataLength, 
                tasks[k].requestPublicXPoint, 
                tasks[k].requestPublicYPoint,
                tasks[k].answerPrivateKey
            ) = TaskRegister(upgradableState.prevVersion).tasks(k);
        }
    }
    
    function endUpgrade() public {
        super.endUpgrade();
        
        if (upgradableState.nextVersion != 0) {
            token.transfer(upgradableState.nextVersion, token.balanceOf(this));
        }
    }

    function tasksCount() public constant returns(uint) {
        return tasks.length;
    }

    function completedTasksCount() public constant returns(uint) {
        return completedTasks.length;
    }

    function payForTask(uint256 taskId, uint256 reward) public isLastestVersion {
        require(reward > 0);
        uint index = safeIndexOfTaskId(taskId);
        token.transferFrom(tx.origin, this, reward);
        tasks[index].reward += reward;
        totalReward += reward;
        TaskPayed(taskId);
    }

    function safeIndexOfTaskId(uint taskId) public constant returns(uint) {
        uint index = indexOfTaskId[taskId];
        require(index > 0);
        return index - 1;
    }
    
    function createBitcoinAddressPrefixTask(bytes prefix, uint256 reward, uint256 requestPublicXPoint, uint256 requestPublicYPoint) public isLastestVersion {
        require(prefix.length > 5);
        require(prefix[0] == "1");
        require(prefix[1] != "1"); // Do not support multiple 1s yet
        require(isValidBicoinAddressPrefix(prefix));
        require(isValidPublicKey(requestPublicXPoint, requestPublicYPoint));
        if (reward > 0) {
            token.transferFrom(tx.origin, this, reward);
        }

        bytes32 data;
        assembly {
            data := mload(add(prefix, 32))
        }
        
        Task memory task = Task({
            taskType: TaskType.BITCOIN_ADDRESS_PREFIX,
            taskId: nextTaskId,
            creator: tx.origin,
            reward: reward,
            data: data,
            dataLength: prefix.length,
            requestPublicXPoint: requestPublicXPoint,
            requestPublicYPoint: requestPublicYPoint,
            answerPrivateKey: 0
        });
        tasks.push(task);
        indexOfTaskId[nextTaskId] = tasks.length; // incremented to avoid 0 index
        TaskCreated(nextTaskId);
        nextTaskId++;
    }
    
    function solveTask(uint taskId, uint256 answerPrivateKey) public isLastestVersion {
        uint taskIndex = safeIndexOfTaskId(taskId);
        Task storage task = tasks[taskIndex];

        // Require private key to be part of address to prevent front-running attack
        bytes32 answerPrivateKeyBytes = bytes32(answerPrivateKey);
        bytes32 senderAddressBytes = bytes32(uint256(msg.sender) << 96);
        for (uint i = 0; i < 16; i++) {
            require(answerPrivateKeyBytes[i] == senderAddressBytes[i]);
        }

        if (task.taskType == TaskType.BITCOIN_ADDRESS_PREFIX) {
            uint256 answerPublicXPoint;
            uint256 answerPublicYPoint;
            uint256 publicXPoint;
            uint256 publicYPoint;
            uint256 z;
            (answerPublicXPoint, answerPublicYPoint) = ec.publicKey(answerPrivateKey);
            (publicXPoint, publicYPoint, z) = ec._ecAdd(
                task.requestPublicXPoint,
                task.requestPublicYPoint,
                1,
                answerPublicXPoint,
                answerPublicYPoint,
                1
            );

            uint256 m = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;
            z = ec._inverse(z);
            publicXPoint = mulmod(publicXPoint, z, m);
            publicYPoint = mulmod(publicYPoint, z, m);
            require(isValidPublicKey(publicXPoint, publicYPoint));
            
            bytes32 btcAddress = createBtcAddress(publicXPoint, publicYPoint);
            uint prefixLength = lengthOfCommonPrefix3232(btcAddress, task.data);
            require(prefixLength == task.dataLength);
            
            task.answerPrivateKey = answerPrivateKey;
        }

        token.transfer(msg.sender, task.reward);
        totalReward -= task.reward;

        completeTask(taskId, taskIndex);
        TaskSolved(taskId);
    }

    function completeTask(uint taskId, uint index) internal {
        completedTasks.push(tasks[index]);
        if (index < tasks.length - 1) { // if not latest
            tasks[index] = tasks[tasks.length - 1];
            indexOfTaskId[tasks[index].taskId] = index + 1;
        }
        tasks.length -= 1;
        delete indexOfTaskId[taskId];
    }

    function recoverLost(ERC20Basic _token, address loser) public onlyOwner {
        uint256 amount = _token.balanceOf(this);
        if (_token == token) {
            amount -= totalReward;
        }
        _token.transfer(loser, _token.balanceOf(this));
    }

}