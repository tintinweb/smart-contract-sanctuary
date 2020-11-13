/**
 *Submitted for verification at Etherscan.io on 2020-09-25
*/

pragma solidity ^0.5.17;

/**
 * Math operations with safety checks
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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function mint(address account, uint256 amount) external;

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity ^0.5.5;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;

            bytes32 accountHash
         = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != 0x0 && codehash != accountHash);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account)
        internal
        pure
        returns (address payable)
    {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }
}

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.5.0;

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
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
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}



contract VampTokenSale is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    IERC20 public usdt = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    address public collector = 0x45a6b8BdfC1FAa745720165e0B172A3D6D4EC897;
    string public name = "VAMP Presale";

    IERC20 public VAMP = IERC20(0xb2C822a1b923E06Dbd193d2cFc7ad15388EA09DD);
    address public beneficiary;

    uint256 public hardCap;
    uint256 public softCap;
    uint256 public tokensPerUSDT;
    uint256 public purchaseLimitStageOne = 500 * 1e6;
    uint256 public purchaseLimitStageTwo = 2000 * 1e6;
    uint256 public purchaseLimitStageThree = 10000 * 1e6;

    uint256 public tokensSold = 0;
    uint256 public usdtRaised = 0;
    uint256 public investorCount = 0;
    uint256 public weiRefunded = 0;
    uint256 public minAmount = 1 * 1e6;
    uint256 public maxAmount = 10000 * 1e6;

    uint256 public startTime;
    uint256 public endTime;
    uint256 public stageOne = 2 hours;
    uint256 public stageTwo = 4 hours;
    uint256 public timeHardCapReached;

    bool public softCapReached = false;
    bool public crowdsaleFinished = false;
   // address[] public whitelistAddress;
    mapping(address => uint256) sold;
    mapping(address => uint256) whitelistAmount;
    mapping(address => bool) whitelistedAddress;
    mapping(address => uint256) tokensAlreadyBought;

    event GoalReached(uint256 amountRaised);
    event HardCapReached(uint256 hardcap);
    event NewContribution(
        address indexed holder,
        uint256 tokenAmount,
        uint256 etherAmount
    );
    event Refunded(address indexed holder, uint256 amount);

    modifier onlyAfter(uint256 time) {
        require(now >= time);
        _;
    }

    modifier onlyBefore(uint256 time) {
        require(now <= time);
        _;
    }

      modifier claimEnabled() {
        require(block.timestamp.add(1 hours) >= timeHardCapReached);
        _;
    }

    constructor ( // in token-wei. i.e. number of presale tokens * 10^18
        uint256 _startTime // start time (unix time, in seconds since 1970-01-01)
       // address[] memory whitelistAddresses // presale duration in hours
    ) public {
        hardCap = 550000 * 1e6;
        tokensPerUSDT = 10000000000000;
        startTime = _startTime;
        endTime = _startTime + 48 hours;
        timeHardCapReached = endTime;
       // whitelistAddress = whitelistAddresses;
    }

    function() payable external {
        revert("not purchased by eth");
        // doPurchase(msg.sender);
    }
    function canClaim() public view returns (bool){
         if(block.timestamp.add(1 hours) >= timeHardCapReached){
             return true;
         } else {
             return false;
         }
    }

  /*  function refund() external onlyAfter(endTime) {
        require(!softCapReached);
        uint256 balance = sold[msg.sender];
        require(balance > 0);
        uint256 refund = balance / tokensPerUSDT;
        msg.sender.transfer(refund);
        delete sold[msg.sender];
        weiRefunded = weiRefunded.add(refund);
        token.refundPresale(msg.sender, balance);
        Refunded(msg.sender, refund);
    }*/
    
    function addWhiteListedAddresses(address[] memory _addresses) public onlyOwner {
        require(_addresses.length > 0);
        for (uint i = 0; i < _addresses.length; i++) {
         whitelistedAddress[_addresses[i]] = true;
    }
    }
    
    function isWhitelisted(address _address) public view returns (bool) {
        if(whitelistedAddress[_address]) {
            return true;
        } else {
            return false;
        }
    }
    function simulatebuy(uint256 amount) public view returns (uint256) {
          uint256 tokens = amount * tokensPerUSDT;
          return tokens;
    }
    
    function tokensBought(address _address) public view returns (uint256) {
        return tokensAlreadyBought[_address];
    }
    
    function tokensAlreadySold() public view returns (uint256) {
        return tokensSold;
    }
    
    function raisedUSDT() public view returns (uint256) {
        return usdtRaised;
    }
    function usdtDeposited(address _address) public view returns (uint256) {
        return whitelistAmount[_address].add(sold[_address]);
    }
    
    function getStage() public view returns (uint256) {
         if (block.timestamp <= startTime.add(stageOne)) {
             return 1;
         } else if(block.timestamp >= startTime.add(stageOne) &&
            block.timestamp <= startTime.add(stageTwo)) {
                return 2;
            } else {
                return 3;
            }
    }
    

    function withdrawTokens() public onlyOwner onlyAfter(timeHardCapReached) {
        VAMP.safeTransfer(collector, VAMP.balanceOf(address(this)));
    }

    function claimTokens() public claimEnabled() {
        
        if(tokensAlreadyBought[msg.sender] > 0){
        VAMP.safeTransfer(msg.sender,tokensAlreadyBought[msg.sender]);
        tokensAlreadyBought[msg.sender]= 0;
        } else {
            revert("No tokens to claim");
        }
       
    }

    function purchase(uint256 amount) public {
        require(amount > minAmount,"Must be more than minumum amount 1USDT");
        require(amount <= maxAmount,"Must be smaller than max amount 10k usdt");
      doPurchase(amount);
    }
     function doPurchase(uint256 amount)
        private
        onlyAfter(startTime)
        onlyBefore(endTime)
    {
        assert(crowdsaleFinished == false);

        require(usdtRaised.add(amount) <= hardCap,"cant deposit without triggering hardcap");
        if (block.timestamp <= startTime.add(stageOne) && isWhitelisted(msg.sender)) {
            //first 2 hours
            uint256 tokens = amount * tokensPerUSDT;
            require(
                amount <= purchaseLimitStageOne,
                "Over purchase limit in stage one"
            );
            require(
                whitelistAmount[msg.sender].add(amount) <= purchaseLimitStageOne,
                "can't purchase more than allowed amount stage one"
            );
            usdt.safeTransferFrom(msg.sender, collector, amount);
            whitelistAmount[msg.sender] = whitelistAmount[msg.sender].add(
                amount
            );
            usdtRaised = usdtRaised.add(amount);
            tokensSold = tokensSold.add(tokens);
            tokensAlreadyBought[msg.sender] = tokensAlreadyBought[msg.sender].add(tokens);
        } else if (
            block.timestamp >= startTime.add(stageOne) &&
            block.timestamp <= startTime.add(stageTwo)
        ) {
            //first 2 - 4 hours

            uint256 tokens = amount * tokensPerUSDT;
            require(
                amount <= purchaseLimitStageTwo,
                "Over purchase limit in stage two"
            );
            require(
                sold[msg.sender].add(amount) <=
                    purchaseLimitStageTwo,
                "can't purchase more than allowed amount stage two"
            );
            sold[msg.sender] = sold[msg.sender].add(amount);
            usdt.safeTransferFrom(msg.sender, collector, amount);
            usdtRaised = usdtRaised.add(amount);
            tokensSold = tokensSold.add(tokens);
            tokensAlreadyBought[msg.sender] = tokensAlreadyBought[msg.sender].add(tokens);
        } else if (block.timestamp > startTime.add(stageTwo)) {
            //4 - 48 hours
             uint256 tokens = amount * tokensPerUSDT;
             require(
                amount <= purchaseLimitStageThree,
                "Over purchase limit in stage three"
            );
               require(
                sold[msg.sender].add(amount) <=
                    purchaseLimitStageThree,
                "can't purchase more than allowed amount stage three"
            );
            sold[msg.sender] = sold[msg.sender].add(amount);
            usdt.safeTransferFrom(msg.sender, collector, amount);
            usdtRaised = usdtRaised.add(amount);
            tokensSold = tokensSold.add(tokens);
            tokensAlreadyBought[msg.sender] = tokensAlreadyBought[msg.sender].add(tokens);
        }
         if (usdtRaised == hardCap) {
          timeHardCapReached = block.timestamp;
          crowdsaleFinished = true;
          emit HardCapReached(timeHardCapReached);
        }

    }
}