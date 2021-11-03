/**
 *Submitted for verification at Etherscan.io on 2021-11-03
*/

// File: Token-Distribution/contracts/interfaces/IIvestor.sol


pragma solidity ^0.8.8;


// 投资接口合约
interface IIvestor {
    // 冻结
    function Frozen() external returns (bool flag);

    // 解冻
    function UnFrozen() external returns (bool flag);

    // 修改收益地址
    function transferAddress(address addr) external returns (bool flag);

    // 领取收益
    function Claim() external returns (bool flag);

    // 领取倒计时
    function TimeToClaim() external view returns (uint256 time);

    // 判断是否为投资者
    function ExistInvestor(address addr) external view returns (bool flag);

    // 可领取金额
    function CanClaimAmount() external view returns (uint256 amount);

    // 剩余领取金额
    function LeftClaimAmount() external view returns (uint256 amount);

    // 已领取金额
    function ReceivedClaimAmount() external view returns (uint256 amount);


    // 新投资者
    event NEW_INVESTOR(uint256 id, address token, address claimAddr, uint256 perAmt, uint256 perTime, uint256 sumCount);

    // 冻结
    event FROZEN(uint256 id);

    // 解冻
    event UNFROZEN(uint256 id);

    // 修改收益地址
    event TRANSFER_ADDRESS(uint256 id, address _old, address _new);

    // 领取收益
    event CLAIM(uint256 id, address token, address claimAddress, uint256 amount, uint256 timestamp);
}

// File: Token-Distribution/contracts/libraries/SafeMath.sol


pragma solidity ^0.8.8;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
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

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: Token-Distribution/contracts/interfaces/IERC20.sol


pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// File: Token-Distribution/contracts/utils/Context.sol


pragma solidity 0.8.8;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () { }

    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: Token-Distribution/contracts/utils/Ownable.sol


pragma solidity 0.8.8;



/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address payable private _owner;
    address public ZERO = address(0x0);
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address payable msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = payable(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address payable newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address payable newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    // 提现操作
    function withdraw_token(address token) external onlyOwner {
        IERC20 _token = IERC20(token);

        uint256 amount = _token.balanceOf(address(this));
        _token.transfer(_owner, amount);
    }

    //存入一些ether用于后面的测试
    function  deposit_eth() external payable{}
    function withdraw_eth() external onlyOwner payable {
        _owner.transfer(address(this).balance);
    }

}
// File: Token-Distribution/contracts/model/Investor.sol


pragma solidity ^0.8.8;




// 投资者合约
contract Investor is Ownable, IIvestor {

    using SafeMath for uint256;

    // 初始ID
    uint256 public id;

    // 领取地址
    address payable public claimAddress;

    // Token合约
    IERC20 public claimContract;

    // 解锁总金额
    uint256 public sumAmount;

    // 解锁期限
    uint256 public sumCount;

    // 每期时长
    uint256 public perTime;

    // 每期数量
    uint256 public perAmount;

    // 投资状态 默认为 true, false为冻结状态
    bool public status;

    // 初始时间
    uint256 public initTime;

    // 领取详情 timestamp => claimed
    mapping(uint256 => bool) public claimDetails;

    // 金额详情 timestamp => amount
    mapping(uint256 => uint256) public amountDetails;

    modifier noFrozen(){
        require(status == true, "Already Frozen");
        _;
    }

    // called once by the factory at time of deployment
    function initialize(uint256 _id, address _claimContract, address payable _claimAddress, uint256 _sumAmount, uint256 _sumCount, uint256 _perTime) external onlyOwner {
        require(id == 0, "Already Initialized");

        id = _id;
        claimAddress = _claimAddress;
        claimContract = IERC20(_claimContract);
        sumAmount = _sumAmount;
        sumCount = _sumCount;
        perTime = _perTime;
        perAmount = sumAmount.div(sumCount);
        status = true;
        initTime = block.timestamp;

        for (uint256 i = 0; i < sumCount; i++) {
            // 默认情况为未领取
            claimDetails[block.timestamp + block.timestamp * i] = false;

            // 每期金额
            amountDetails[block.timestamp + block.timestamp * i] = perAmount;
        }

        emit NEW_INVESTOR(id, address(claimContract), claimAddress, perAmount, perTime, sumCount);
    }

    // 冻结
    function Frozen() external onlyOwner noFrozen returns (bool flag) {
        status = false;
        emit FROZEN(id);
        return true;
    }

    // 解冻
    function UnFrozen() external onlyOwner returns (bool flag) {
        status = true;
        emit UNFROZEN(id);
        return true;
    }

    // 修改收益地址
    function transferAddress(address addr) external onlyOwner noFrozen returns (bool flag) {
        require(addr != address(0x0), "ADDRESS NOT IS ZERO");
        emit TRANSFER_ADDRESS(id, claimAddress, addr);

        claimAddress = payable(addr);
        return true;
    }

    // 领取收益
    function Claim() external onlyOwner noFrozen returns (bool flag) {
        require(claimAddress != ZERO, "ADDRESS NOT IS ZERO");
        uint256 claimAmt = 0;
        for(uint256 i = 0; i < sumCount; i++) {
            uint256 t = initTime + perTime * i;

            // 已领取忽略
            if (claimDetails[t] == true) {
                continue;
            }

            // 未到领取时间 跳出
            if (block.timestamp < t) {
                break;
            }

            // 设置领取状态
            claimDetails[t] = true;
            claimAmt = claimAmt.add(amountDetails[t]);
        }

        if (claimAmt == 0){
            return false;
        }
        claimContract.transfer(claimAddress, claimAmt);
        emit CLAIM(id, address(claimContract), claimAddress, claimAmt, block.timestamp);
        return true;
    }

    // 领取倒计时
    function TimeToClaim() public view returns (uint256 time) {
        for(uint256 i = 0; i < sumCount; i++) {
            uint256 t = initTime + perTime * i;
            // 已领取忽略
            if (claimDetails[t] == true) {
                continue;
            }
            // 未到领取时间 返回倒计时
            if (block.timestamp < t) {
                return t - block.timestamp;
            }
            // 已到倒计时 返回0
            return 0;
        }
    }

    // 判断是否为投资者
    function ExistInvestor(address addr) public view returns (bool flag) {
        return addr == claimAddress;
    }

    // 可领取金额
    function CanClaimAmount() public view returns (uint256 amount) {
        for(uint256 i = 0; i < sumCount; i++) {
            uint256 t = initTime + perTime * i;
            // 已领取忽略
            if (claimDetails[t] == true) {
                continue;
            }
            // 未到领取时间 结束
            if (block.timestamp < t) {
                break;
            }
            // 已到倒计时 进行累加
            amount = amount + amountDetails[t];
        }
        return amount;
    }

    // 剩余领取金额
    function LeftClaimAmount() public view returns (uint256 amount) {
        uint256 claimAmt = ReceivedClaimAmount();
        return sumAmount - claimAmt;
    }

    // 已领取金额
    function ReceivedClaimAmount() public view returns (uint256 amount) {
        for(uint256 i = 0; i < sumCount; i++) {
            uint256 t = initTime + perTime * i;
            // 已领取累加
            if (claimDetails[t] == true) {
                amount = amount + amountDetails[t];
            } else {
                break;
            }
        }
        return amount;
    }

}