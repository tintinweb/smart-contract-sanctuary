/**
 *Submitted for verification at Etherscan.io on 2021-03-15
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

contract TokenIssue is Ownable {

    using SafeMath for uint256;

    uint256 public constant INIT_MINE_SUPPLY = 32000000 * 10 ** 18;

    uint256 public issuedAmount = INIT_MINE_SUPPLY;

    uint256 public surplusAmount = 2.88 * 10 ** 8 * 10 ** 18;

    uint256 public TOTAL_AMOUNT = 3.2 * 10 ** 8 * 10 ** 18;

    uint256 public constant MONTH_SECONDS = 225 * 24 * 30;

    bytes32 public constant TRANS_ROLE = keccak256("TRANS_ROLE");

    // utc 2021-05-01
    //    uint256 public startIssueTime = 0;
    uint256 public startIssueTime = 0;

    address public summa;

    address public summaPri;

    uint256[] public issueInfo;

    constructor(address _summa,address _summaPri) public {
        summa = _summa;
        summaPri = _summaPri;
        initialize();
    }

    function initialize() private {
        issueInfo.push(1920000 * 10 ** 18);
        issueInfo.push(2035200 * 10 ** 18);
        issueInfo.push(2157312.0000000005 * 10 ** 18);
        issueInfo.push(2286750.72 * 10 ** 18);
        issueInfo.push(2423955.763200001 * 10 ** 18);
        issueInfo.push(2569393.108992 * 10 ** 18);
        issueInfo.push(2723556.6955315205 * 10 ** 18);
        issueInfo.push(2886970.0972634126 * 10 ** 18);
        issueInfo.push(3060188.303099217 * 10 ** 18);
        issueInfo.push(3243799.6012851703 * 10 ** 18);
        issueInfo.push(3438427.577362281 * 10 ** 18);
        issueInfo.push(3644733.232004018 * 10 ** 18);
        issueInfo.push(2575611.4839495043 * 10 ** 18);
        issueInfo.push(2678635.943307485 * 10 ** 18);
        issueInfo.push(2785781.3810397848 * 10 ** 18);
        issueInfo.push(2897212.636281376 * 10 ** 18);
        issueInfo.push(3013101.141732631 * 10 ** 18);
        issueInfo.push(3133625.187401936 * 10 ** 18);
        issueInfo.push(3258970.1948980135 * 10 ** 18);
        issueInfo.push(3389329.0026939344 * 10 ** 18);
        issueInfo.push(3524902.1628016927 * 10 ** 18);
        issueInfo.push(3665898.24931376 * 10 ** 18);
        issueInfo.push(3812534.17928631 * 10 ** 18);
        issueInfo.push(3965035.546457763 * 10 ** 18);
        issueInfo.push(2061818.484158036 * 10 ** 18);
        issueInfo.push(2103054.8538411967 * 10 ** 18);
        issueInfo.push(2145115.9509180207 * 10 ** 18);
        issueInfo.push(2188018.269936382 * 10 ** 18);
        issueInfo.push(2231778.6353351087 * 10 ** 18);
        issueInfo.push(2276414.208041811 * 10 ** 18);
        issueInfo.push(2321942.4922026475 * 10 ** 18);
        issueInfo.push(2368381.3420467 * 10 ** 18);
        issueInfo.push(2415748.9688876346 * 10 ** 18);
        issueInfo.push(2464063.948265387 * 10 ** 18);
        issueInfo.push(2513345.227230695 * 10 ** 18);
        issueInfo.push(2563612.131775309 * 10 ** 18);
        issueInfo.push(2614884.3744108155 * 10 ** 18);
        issueInfo.push(2667182.061899032 * 10 ** 18);
        issueInfo.push(2720525.703137012 * 10 ** 18);
        issueInfo.push(2774936.2171997526 * 10 ** 18);
        issueInfo.push(2830434.941543747 * 10 ** 18);
        issueInfo.push(2887043.6403746223 * 10 ** 18);
        issueInfo.push(2944784.513182115 * 10 ** 18);
        issueInfo.push(3003680.2034457573 * 10 ** 18);
        issueInfo.push(3063753.807514673 * 10 ** 18);
        issueInfo.push(3125028.883664966 * 10 ** 18);
        issueInfo.push(3187529.461338266 * 10 ** 18);
        issueInfo.push(3251280.0505650314 * 10 ** 18);
        issueInfo.push(1658152.825788165 * 10 ** 18);
        issueInfo.push(1674734.3540460467 * 10 ** 18);
        issueInfo.push(1691481.6975865073 * 10 ** 18);
        issueInfo.push(1708396.5145623726 * 10 ** 18);
        issueInfo.push(1725480.479707996 * 10 ** 18);
        issueInfo.push(1742735.2845050762 * 10 ** 18);
        issueInfo.push(1760162.6373501269 * 10 ** 18);
        issueInfo.push(1777764.263723628 * 10 ** 18);
        issueInfo.push(1795541.9063608644 * 10 ** 18);
        issueInfo.push(1813497.3254244728 * 10 ** 18);
        issueInfo.push(1831632.2986787176 * 10 ** 18);
        issueInfo.push(1849948.621665505 * 10 ** 18);
        issueInfo.push(1868448.10788216 * 10 ** 18);
        issueInfo.push(1887132.5889609817 * 10 ** 18);
        issueInfo.push(1906003.9148505912 * 10 ** 18);
        issueInfo.push(1925063.9539990975 * 10 ** 18);
        issueInfo.push(1944314.5935390887 * 10 ** 18);
        issueInfo.push(1963757.7394744793 * 10 ** 18);
        issueInfo.push(1983395.316869224 * 10 ** 18);
        issueInfo.push(2003229.2700379163 * 10 ** 18);
        issueInfo.push(2023261.5627382956 * 10 ** 18);
        issueInfo.push(2043494.1783656788 * 10 ** 18);
        issueInfo.push(2063929.1201493354 * 10 ** 18);
        issueInfo.push(2084568.4113508288 * 10 ** 18);
        issueInfo.push(2105414.0954643367 * 10 ** 18);
        issueInfo.push(2126468.23641898 * 10 ** 18);
        issueInfo.push(2147732.91878317 * 10 ** 18);
        issueInfo.push(2169210.247971002 * 10 ** 18);
        issueInfo.push(2190902.350450712 * 10 ** 18);
        issueInfo.push(2212811.373955219 * 10 ** 18);
        issueInfo.push(2234939.4876947715 * 10 ** 18);
        issueInfo.push(2257288.882571719 * 10 ** 18);
        issueInfo.push(2279861.7713974365 * 10 ** 18);
        issueInfo.push(2302660.389111411 * 10 ** 18);
        issueInfo.push(2325686.9930025246 * 10 ** 18);
        issueInfo.push(2348943.8629325503 * 10 ** 18);
        issueInfo.push(1897946.6412495002 * 10 ** 18);
        issueInfo.push(1913130.2143794964 * 10 ** 18);
        issueInfo.push(1928435.2560945326 * 10 ** 18);
        issueInfo.push(1943862.7381432885 * 10 ** 18);
        issueInfo.push(1959413.6400484347 * 10 ** 18);
        issueInfo.push(1975088.9491688225 * 10 ** 18);
        issueInfo.push(1990889.6607621727 * 10 ** 18);
        issueInfo.push(2006816.7780482706 * 10 ** 18);
        issueInfo.push(2022871.3122726567 * 10 ** 18);
        issueInfo.push(2039054.282770838 * 10 ** 18);
        issueInfo.push(2055366.7170330046 * 10 ** 18);
        issueInfo.push(2071809.6507692689 * 10 ** 18);
        issueInfo.push(2088384.1279754227 * 10 ** 18);
        issueInfo.push(2105091.200999226 * 10 ** 18);
        issueInfo.push(2121931.93060722 * 10 ** 18);
        issueInfo.push(2138907.386052078 * 10 ** 18);
        issueInfo.push(2156018.645140494 * 10 ** 18);
        issueInfo.push(2173266.794301619 * 10 ** 18);
        issueInfo.push(2190652.928656032 * 10 ** 18);
        issueInfo.push(2208178.15208528 * 10 ** 18);
        issueInfo.push(2225843.5773019614 * 10 ** 18);
        issueInfo.push(2243650.3259203774 * 10 ** 18);
        issueInfo.push(2261599.528527741 * 10 ** 18);
        issueInfo.push(2279692.324755963 * 10 ** 18);
        issueInfo.push(2297929.86335401 * 10 ** 18);
        issueInfo.push(2316313.302260842 * 10 ** 18);
        issueInfo.push(2334843.8086789288 * 10 ** 18);
        issueInfo.push(2353522.559148361 * 10 ** 18);
        issueInfo.push(2372350.7396215475 * 10 ** 18);
        issueInfo.push(2391329.54553852 * 10 ** 18);
        issueInfo.push(2410460.1819028277 * 10 ** 18);
        issueInfo.push(2429743.8633580506 * 10 ** 18);
        issueInfo.push(2449181.8142649154 * 10 ** 18);
        issueInfo.push(2468775.2687790347 * 10 ** 18);
        issueInfo.push(2488525.470929267 * 10 ** 18);
        issueInfo.push(2508433.674696701 * 10 ** 18);
        issueInfo.push(2528501.1440942744 * 10 ** 18);
        issueInfo.push(2548729.153247029 * 10 ** 18);
    }

    function issueInfoLength() external view returns (uint256) {
        return issueInfo.length;
    }

    function currentCanIssueAmount() public view returns (uint256){
        uint256 currentTime = block.number;
        if (currentTime <= startIssueTime || startIssueTime <= 0) {
            return INIT_MINE_SUPPLY.sub(issuedAmount);
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
            uint256 calcAmount = timeInterval.sub(monthIndex.mul(MONTH_SECONDS)).mul(issueInfo[monthIndex].div(MONTH_SECONDS)).add(tempTotal);
            if (calcAmount > TOTAL_AMOUNT) {
                return TOTAL_AMOUNT.sub(issuedAmount);
            }
            return calcAmount.sub(issuedAmount);
        } else {
            return TOTAL_AMOUNT.sub(issuedAmount);
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
            return issueInfo[monthIndex].div(MONTH_SECONDS);
        } else if (monthIndex < issueInfo.length) {
            uint256 tempTotal = INIT_MINE_SUPPLY;
            for (uint256 j = 0; j < monthIndex; j++) {
                tempTotal = tempTotal.add(issueInfo[j]);
            }
            uint256 actualBlockIssue = issueInfo[monthIndex].div(MONTH_SECONDS);
            uint256 calcAmount = timeInterval.sub(monthIndex.mul(MONTH_SECONDS)).mul(issueInfo[monthIndex].div(MONTH_SECONDS)).add(tempTotal);
            if (calcAmount > TOTAL_AMOUNT) {
                if (calcAmount.sub(TOTAL_AMOUNT) <= actualBlockIssue) {
                    return actualBlockIssue.sub(calcAmount.sub(TOTAL_AMOUNT));
                }
                return 0;
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
            surplusAmount = surplusAmount.sub(currentCanIssue);
            ISumma(summa).issue(address(this), currentCanIssue);
        }
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
        if(amount > IERC20Sumswap(summa).balanceOf(address(this))){
            issueAnyOne();
        }
        require(amount <= IERC20Sumswap(summa).balanceOf(address(this)),"not enough,please check code");
        IERC20Sumswap(summa).transfer(to,amount);
    }

    function withdrawToken(address addr) public onlyOwner {
        IERC20Sumswap(addr).transfer(_msgSender(), IERC20Sumswap(addr).balanceOf(address(this)));
    }

    receive() external payable {
    }
}