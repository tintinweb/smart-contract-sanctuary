/**
 *Submitted for verification at BscScan.com on 2021-08-09
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () { }

    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

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

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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
}

interface Token {
    function transfer(address to, uint256 amount) external;
    function balanceOf(address account) view external returns (uint256);
}

contract PrivateSaleHoneyPad is Ownable {
    using SafeMath for uint256;

    Token public token;
    uint256 public privateSaleStartTimestamp;
    uint256 public privateSaleEndTimestamp;
    uint256 public hardCapEthAmount = 250 ether;
    uint256 public totalDepositedEthBalance;
    uint256 public minimumDepositEthAmount = 1 ether;
    uint256 public maximumDepositEthAmount = 30 ether;
    uint256 public tokenPerBNB = 750000000000;

    mapping(address => uint256) public deposits;

    mapping(address => uint256) public withdraws;
    mapping(address => bool) public whitelist;

    struct LastTx {
        uint256 tokenAmount;
        address buyer;
    }

    LastTx[3] lastTxList;

    constructor(
        Token _token
    ) {
        token = _token;

    }

    receive() payable external {
        deposit();
    }

    function reachedHardCap() view public returns (bool) {
        return hardCapEthAmount == totalDepositedEthBalance;
    }

    function tokenBalanceOfSender() view external returns (uint256) {
        return token.balanceOf(msg.sender);
    }

    function tokenBalanceOfContract() view external returns (uint256) {
        return token.balanceOf(address(this));
    }

    function deposit() public payable {
        require(whitelist[msg.sender] == true, "invalid withdraw address");
        require(!reachedHardCap(), "Hard Cap is already reached");
        require(privateSaleStartTimestamp > 0 && block.timestamp >= privateSaleStartTimestamp && block.timestamp <= privateSaleEndTimestamp, "presale is not active");
        uint256 take;
        uint256 sendBack;

        if (totalDepositedEthBalance.add(msg.value) > hardCapEthAmount) {
            take = hardCapEthAmount.sub(totalDepositedEthBalance);
            sendBack = totalDepositedEthBalance.add(msg.value).sub(hardCapEthAmount);
        } else {
            take = msg.value;
        }

        require(deposits[msg.sender].add(take) >= minimumDepositEthAmount && deposits[msg.sender].add(take) <= maximumDepositEthAmount, "Deposited balance is less or grater than allowed range");

        totalDepositedEthBalance = totalDepositedEthBalance.add(take);
        deposits[msg.sender] = deposits[msg.sender].add(take);
        emit Deposited(msg.sender, take);

        uint256 tokenAmount = take.mul(tokenPerBNB);
        token.transfer(msg.sender, tokenAmount);

        addLastTx(msg.sender, tokenAmount);

        if (sendBack > 0) {
            privateSaleEndTimestamp = block.timestamp;
            (bool success, ) = msg.sender.call{value: sendBack}('');
            require(success);
            emit SendBack(msg.sender, sendBack);
        }
    }

    function addLastTx(address buyer, uint256 amount) internal {
        LastTx memory ltx;
        ltx.buyer = buyer;
        ltx.tokenAmount = amount;

        lastTxList[0] = lastTxList[1];
        lastTxList[1] = lastTxList[2];
        lastTxList[2] = ltx;
    }

    function releaseFunds() external onlyOwner {
        require(block.timestamp >= privateSaleEndTimestamp, "Too soon");
        payable(msg.sender).transfer(address(this).balance);
        uint256 balanceOfThis = token.balanceOf(address(this));
        if (balanceOfThis > 0) {
            token.transfer(msg.sender, balanceOfThis);
        }
    }

    function addWhiteList(address payable _address) external onlyOwner {
        whitelist[_address] = true;
    }

    function removeWhiteList(address payable _address) external onlyOwner {
        whitelist[_address] = false;
    }

    function addWhiteListMulti(address[] calldata _addresses) external onlyOwner {
        require(_addresses.length <= 1000, "Provide less addresses in one function call");
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = true;
        }
    }

    function removeWhiteListMulti(address[] calldata _addresses) external onlyOwner {
        require(_addresses.length <= 1000, "Provide less addresses in one function call");
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = false;
        }
    }

    function recoverBEP20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        IBEP20(tokenAddress).transfer(this.owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    function getDepositAmount() public view returns (uint256) {
        return totalDepositedEthBalance;
    }

    function getLeftTimeAmount() public view returns (uint256) {
        if(block.timestamp > privateSaleEndTimestamp) {
            return 0;
        } else {
            return (privateSaleEndTimestamp - block.timestamp);
        }
    }

    function setMinDepositAmount(uint256 newValue) external onlyOwner {
        require(newValue < maximumDepositEthAmount, "Min value should be less than max value");
        emit UpdateMinDepositAmount(minimumDepositEthAmount, newValue);
        minimumDepositEthAmount = newValue;
    }

    function setMaxDepositAmount(uint256 newValue) external onlyOwner {
        require(newValue > minimumDepositEthAmount, "Max value should be greater than min value");
        emit UpdateMinDepositAmount(maximumDepositEthAmount, newValue);
        maximumDepositEthAmount = newValue;
    }

    function setTokenPerBNB(uint256 newValue) external onlyOwner {
        require(block.timestamp < privateSaleStartTimestamp, "Private sale already started");
        emit UpdateTokenPerBNB(tokenPerBNB, newValue);
        tokenPerBNB = newValue;
    }

    function setHardCapEthAmount(uint256 newValue) external onlyOwner {
        require(block.timestamp < privateSaleStartTimestamp, "Private sale already started");
        emit UpdateHardCapEthAmount(hardCapEthAmount, newValue);
        hardCapEthAmount = newValue;
    }

    function setPrivateSaleTime(uint256 start, uint256 end) external onlyOwner {
        require(privateSaleEndTimestamp == 0 && privateSaleStartTimestamp == 0, "Sale times cannot be changed after setting once");
        privateSaleStartTimestamp = start < block.timestamp ? block.timestamp : start;
        require(end > block.timestamp, "Sale End time should be grater than current time.");
        privateSaleEndTimestamp = end;
    }


    event UpdateMinDepositAmount(uint256 oldValue, uint256 newValue);
    event UpdateMaxDepositAmount(uint256 oldValue, uint256 newValue);
    event UpdateTokenPerBNB(uint256 oldValue, uint256 newValue);
    event UpdateHardCapEthAmount(uint256 oldValue, uint256 newValue);
    event Deposited(address indexed user, uint256 amount);
    event SendBack(address indexed user, uint256 amount);
    event Recovered(address token, uint256 amount);
}