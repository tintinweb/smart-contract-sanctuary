/**
 *Submitted for verification at Etherscan.io on 2021-05-21
*/

/**
 *Submitted for verification at Etherscan.io on 2021-05-21
*/

// File: @openzeppelin/contracts/GSN/Context.sol



pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
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
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/interfaces/IERC20Sumswap.sol

pragma solidity >=0.5.0;

interface IERC20Sumswap{
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

// File: @openzeppelin/contracts/math/SafeMath.sol



pragma solidity >=0.6.0 <0.8.0;

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
     *
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
     *
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
     *
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/interfaces/IAccessControl.sol

pragma solidity ^0.6.0;

interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);
}

// File: contracts/TokenIssue.sol

pragma solidity ^0.6.0;





interface ISumma {
    function issue(address addr, uint256 amount) external;
}

contract TokenIssueV2 is Ownable {

    using SafeMath for uint256;
    
    uint256 public constant INIT_MINE_SUPPLY = 0;
    
    uint256 public issuedAmount = INIT_MINE_SUPPLY;

    uint256 public constant MONTH_SECONDS = 225*24*30;

    bytes32 public constant TRANS_ROLE = keccak256("TRANS_ROLE");
    
     bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    // utc 2021-05-01
    //    uint256 public startIssueTime = 0;
    
    uint256 public startIssueTime = 0;

    address public summa;

    address public summaPri;

    uint256[] public issueInfo;
    
    uint256 public mintAmount;

    constructor(address _summa,address _summaPri) public {
        summa = _summa;
        summaPri = _summaPri;
        initialize();
    }

    function initialize() private {
        issueInfo.push(1000000*10**18);
        issueInfo.push(1000000*10**18);
        issueInfo.push(1000000*10**18);
        issueInfo.push(1000000*10**18);
        issueInfo.push(1000000*10**18);
        issueInfo.push(1000000*10**18);
        issueInfo.push(1000000*10**18);
        issueInfo.push(1000000*10**18);
        issueInfo.push(1000000*10**18);
        issueInfo.push(1000000*10**18);
    
    }
    function updateIssueInfo(uint8 _pid,uint256 _issueInfo) public onlyOwner{
         issueInfo[_pid] = _issueInfo;
    }
    function issueInfoLength() external view returns (uint256) {
        return issueInfo.length;
    }

    function currentCanIssueAmount() public view returns (uint256){
        uint256 currentTime = block.number;
        if (currentTime <= startIssueTime || startIssueTime <= 0) {
            return INIT_MINE_SUPPLY;
        }
        uint256 timeInterval = currentTime - startIssueTime;
        uint256 monthIndex = timeInterval.div(MONTH_SECONDS);
        if (monthIndex < 1) {
            return issueInfo[monthIndex].div(MONTH_SECONDS).mul(timeInterval).add(INIT_MINE_SUPPLY).sub(issuedAmount);
        } else if (monthIndex < issueInfo.length) {
            uint256 tempTotal = INIT_MINE_SUPPLY;
            for (uint256 j = 0; j < monthIndex; j++) {
                tempTotal = tempTotal.add(issueInfo[j]);
            }
            uint256 calcAmount = timeInterval.sub(monthIndex.mul(MONTH_SECONDS)).mul(issueInfo[monthIndex].div(MONTH_SECONDS)).add(tempTotal).sub(issuedAmount);
            return calcAmount.sub(issuedAmount);
        } else {
            return 0;
        }
    }

    function currentBlockCanIssueAmount() public view returns (uint256){
        uint256 currentTime = block.number;
        if (currentTime <= startIssueTime || startIssueTime <= 0) {
            return 0;
        }
        uint256 timeInterval = currentTime - startIssueTime;
        uint256 monthIndex = timeInterval.div(MONTH_SECONDS);
        if (monthIndex < 1) {
            return issueInfo[monthIndex].div(MONTH_SECONDS).sub(issuedAmount);
        } else if (monthIndex < issueInfo.length) {
            uint256 tempTotal = INIT_MINE_SUPPLY;
            for (uint256 j = 0; j < monthIndex; j++) {
                tempTotal = tempTotal.add(issueInfo[j]);
            }
            uint256 actualBlockIssue = issueInfo[monthIndex].div(MONTH_SECONDS);
            uint256 calcAmount = timeInterval.sub(monthIndex.mul(MONTH_SECONDS)).mul(issueInfo[monthIndex].div(MONTH_SECONDS)).add(tempTotal)
            .sub(issuedAmount);
            if (calcAmount > TOTAL_AMOUNT()) {
                return TOTAL_AMOUNT();
            }
            return actualBlockIssue;
        } else {
            return 0;
        }

    }
    function issueAnyOne() public {
        uint256 currentCanIssue = currentCanIssueAmount();
        if (currentCanIssue > 0) {
            issuedAmount = issuedAmount.add(currentCanIssue);
            _mintAmount(currentCanIssue);
        }
    }
    function _mintAmount(uint256 currentCanIssueAmount) private {
        require(currentCanIssueAmount <= IERC20Sumswap(summa).balanceOf(address(this)),"not enough,please check code");
        mintAmount = mintAmount+currentCanIssueAmount;
    }
    function TOTAL_AMOUNT() public view returns (uint256){
        return IERC20Sumswap(summa).balanceOf(address(this));
    }
    function withdrawETH() public onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    function setStart() public onlyOwner {
        if (startIssueTime <= 0) {
            startIssueTime = block.number;
        }
    }

    function transByContract(address to,uint256 amount) public{
        require(IAccessControl(summaPri).hasRole(TRANS_ROLE, _msgSender()), "Caller is not a transfer role");
        if(amount > mintAmount){
            issueAnyOne();
        }
        require(amount <= mintAmount,"not enough mintAmount,please check code");
        require(amount <= IERC20Sumswap(summa).balanceOf(address(this)),"not enough IERC20Sumswap,please check code");
        mintAmount = mintAmount-amount;
        IERC20Sumswap(summa).transfer(to,amount);
    }

    function withdrawToken(address addr) public onlyOwner {
        _safeTransfer(addr,_msgSender(),IERC20Sumswap(addr).balanceOf(address(this)));
    }
    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SumswapV2: TRANSFER_FAILED');
    }
    receive() external payable {
    }
}