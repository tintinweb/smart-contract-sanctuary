/**
 *Submitted for verification at FtmScan.com on 2021-12-30
*/

pragma solidity ^0.8.0;

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        // Gas optimization: this is TKNaper than requiring 'a' not being zero, but the
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
     * `revert` opcode (which leaves remaining gas untouTKNd) while Solidity
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
     * `revert` opcode (which leaves remaining gas untouTKNd) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
     * opcode (which leaves remaining gas untouTKNd) while Solidity uses an
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
     * opcode (which leaves remaining gas untouTKNd) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract HauntedHouse is Ownable {
    using SafeMath for uint256;

    address public BASE;
    address public TOKEN;

    uint256 public minAlloc;
    uint256 public maxAlloc;
    uint256 public maxCap;
    uint256 public tokenPerBase;
    uint256 public totalSold = 0;

    bool public presaleActive = false;
    bool public publicActive = false;
    bool public claimActive = false;
    bool public refundActive = false;

    uint256 public whitelistSize = 0;

    mapping(address => bool) public whitelisted;
    mapping(address => uint256) public contributed;
    mapping(address => bool) public claimed;
    mapping(address => bool) public refunded;

    constructor(
        address _BASE,
        address _TOKEN,
        uint256 _minAlloc,
        uint256 _maxAlloc,
        uint256 _maxCap,
        uint256 _tokenPerBase
    ) {
        BASE = _BASE;
        TOKEN = _TOKEN;
        minAlloc = _minAlloc * 10**18;
        maxAlloc = _maxAlloc * 10**18;
        maxCap = _maxCap * 10**18;
        tokenPerBase = _tokenPerBase;
    }

    function changeBase(address _BASE) public onlyOwner {
        BASE = _BASE;
    }

    function changeToken(address _TOKEN) public onlyOwner {
        TOKEN = _TOKEN;
    }

    function changeMinAlloc(uint256 _minAlloc) public onlyOwner {
        minAlloc = _minAlloc * 10**18;
    }

    function changeMaxAlloc(uint256 _maxAlloc) public onlyOwner {
        maxAlloc = _maxAlloc * 10**18;
    }

    function changeMaxCap(uint256 _maxCap) public onlyOwner {
        maxCap = _maxCap * 10**18;
    }

    function changeTokenPerBase(uint256 _tokenPerBase) public onlyOwner {
        tokenPerBase = _tokenPerBase;
    }

    function togglePresale(bool value) external onlyOwner {
        presaleActive = value;
    }

    function togglePublic(bool value) external onlyOwner {
        publicActive = value;
    }

    function toggleClaim(bool value) external onlyOwner {
        claimActive = value;
    }

    function toggleRefund(bool value) external onlyOwner {
        refundActive = value;
    }

    function addToWhitelist(address[] memory addrs) external onlyOwner {
        for (uint256 i = 0; i < addrs.length; i++) {
            whitelisted[addrs[i]] = true;
        }
        whitelistSize += addrs.length;
    }

    function removeFromWhitelist(address[] memory addrs) external onlyOwner {
        for (uint256 i = 0; i < addrs.length; i++) {
            whitelisted[addrs[i]] = false;
        }
    }

    function withdraw() external onlyOwner {
        if (IERC20(BASE).balanceOf(address(this)) > 0) {
            IERC20(BASE).transfer(
                msg.sender,
                IERC20(BASE).balanceOf(address(this))
            );
        }

        if (IERC20(TOKEN).balanceOf(address(this)) > 0) {
            IERC20(TOKEN).transfer(
                msg.sender,
                IERC20(TOKEN).balanceOf(address(this))
            );
        }

        if (address(this).balance > 0) {
            payable(msg.sender).transfer(address(this).balance);
        }
    }

    function withdrawToken(address _token) external onlyOwner {
        if (IERC20(_token).balanceOf(address(this)) > 0) {
            IERC20(_token).transfer(
                msg.sender,
                IERC20(_token).balanceOf(address(this))
            );
        }
    }

    function contribute(uint256 amountOfTokens) external {
        uint256 amountOfBase = amountOfTokens.mul(tokenPerBase);

        require(
            presaleActive || publicActive,
            "CONTRIBUTE: Sale is not active yet."
        );
        require(
            amountOfTokens >= minAlloc,
            "CONTRIBUTE: Amount too low (min 200 $MIM)"
        );
        require(
            amountOfBase.add(contributed[msg.sender]) <= maxAlloc,
            "CONTRIBUTE: Amount too high (max 300 $MIM)"
        );
        require(
            amountOfBase.add(totalSold) <= maxCap,
            "CONTRIBUTE: Hard cap reached."
        );
        require(
            IERC20(BASE).balanceOf(msg.sender) >= amountOfBase,
            "CONTRIBUTE: $MIM balance is too low."
        );

        if (presaleActive && !publicActive) {
            require(whitelisted[msg.sender], "CONTRIBUTE: Not whitelisted.");
        }

        IERC20(BASE).transferFrom(msg.sender, address(this), amountOfBase);
        contributed[msg.sender] += amountOfBase;
        totalSold += amountOfBase;
    }

    function claim() external {
        require(claimActive, "CLAIM: Claiming is not active yet.");
        require(!claimed[msg.sender], "CLAIM: Already claimed.");

        uint256 amountOfTokens = contributed[msg.sender].div(tokenPerBase);

        IERC20(TOKEN).transfer(msg.sender, amountOfTokens);
        claimed[msg.sender] = true;
    }

    function refund() external {
        require(refundActive, "REFUND: Refunding is not active yet.");
        require(!refunded[msg.sender], "REFUND: Already refunded.");

        uint256 amountOfBase = contributed[msg.sender].div(tokenPerBase);

        IERC20(BASE).transfer(msg.sender, amountOfBase);
        refunded[msg.sender] = true;
    }

    function remainingAlloc(address user) external view returns (uint256) {
        return maxAlloc.sub(contributed[user]);
    }
}