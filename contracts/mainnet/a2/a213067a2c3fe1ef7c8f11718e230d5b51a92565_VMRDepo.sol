/**
 *Submitted for verification at Etherscan.io on 2021-02-07
*/

/**
 *Submitted for verification at Etherscan.io on 2020-12-07
*/

pragma solidity ^0.5.16;

/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private initializing;

    /**
     * @dev Modifier to use in the initializer function of a contract.
     */
    modifier initializer() {
        require(initializing || isConstructor() || !initialized);

        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            initializing = true;
            initialized = true;
        }

        _;

        if (isTopLevelCall) {
            initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}

contract ERC20Token
{
    function decimals() external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function approve(address spender, uint value) external;
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
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
        require(c >= a);

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
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    uint256 constant WAD = 10 ** 18;

    function wdiv(uint x, uint y) internal pure returns (uint256 z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

    function wmul(uint x, uint y) internal pure returns (uint256 z) {
        z = add(mul(x, y), WAD / 2) / WAD;
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
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
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
        require(b != 0);
        return a % b;
    }
}


/**
 * @dev Collection of functions related to the address type,
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}


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

    function safeTransfer(ERC20Token token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(ERC20Token token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(ERC20Token token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0));
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(ERC20Token token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(ERC20Token token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(ERC20Token token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract());

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success);

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)));
        }
    }
}


library UniversalERC20 {

    using SafeMath for uint256;
    using SafeERC20 for ERC20Token;

    ERC20Token private constant ZERO_ADDRESS = ERC20Token(0x0000000000000000000000000000000000000000);
    ERC20Token private constant ETH_ADDRESS = ERC20Token(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    function universalTransfer(ERC20Token token, address to, uint256 amount) internal {
        universalTransfer(token, to, amount, false);
    }

    function universalTransfer(ERC20Token token, address to, uint256 amount, bool mayFail) internal returns(bool) {
        if (amount == 0) {
            return true;
        }

        if (token == ZERO_ADDRESS || token == ETH_ADDRESS) {
            if (mayFail) {
                return address(uint160(to)).send(amount);
            } else {
                address(uint160(to)).transfer(amount);
                return true;
            }
        } else {
            token.safeTransfer(to, amount);
            return true;
        }
    }

    function universalApprove(ERC20Token token, address to, uint256 amount) internal {
        if (token != ZERO_ADDRESS && token != ETH_ADDRESS) {
            token.safeApprove(to, amount);
        }
    }

    function universalTransferFrom(ERC20Token token, address from, address to, uint256 amount) internal {
        if (amount == 0) {
            return;
        }

        if (token == ZERO_ADDRESS || token == ETH_ADDRESS) {
            require(from == msg.sender && msg.value >= amount, "msg.value is zero");
            if (to != address(this)) {
                address(uint160(to)).transfer(amount);
            }
            if (msg.value > amount) {
                msg.sender.transfer(uint256(msg.value).sub(amount));
            }
        } else {
            token.safeTransferFrom(from, to, amount);
        }
    }

    function universalBalanceOf(ERC20Token token, address who) internal view returns (uint256) {
        if (token == ZERO_ADDRESS || token == ETH_ADDRESS) {
            return who.balance;
        } else {
            return token.balanceOf(who);
        }
    }
}

contract Ownable {
    address payable public owner = msg.sender;
    address payable public newOwnerCandidate;

    modifier onlyOwner()
    {
        assert(msg.sender == owner);
        _;
    }

    function changeOwnerCandidate(address payable newOwner) public onlyOwner {
        newOwnerCandidate = newOwner;
    }

    function acceptOwner() public {
        require(msg.sender == newOwnerCandidate);
        owner = newOwnerCandidate;
    }
}

contract VMRDepo is Initializable
{
    using SafeMath for uint256;
    using UniversalERC20 for ERC20Token;

    //  = ERC20Token(0xeE1a71a00aa9771cBbb5a9816aF5bB43fa3c6810); // Kovan
    ERC20Token constant TokenVMR =  ERC20Token(0x063b98a414EAA1D4a5D4fC235a22db1427199024); // Mainnet

    address payable public owner;
    address payable public newOwnerCandidate;
    mapping(address => bool) public admins;

    uint256 constant delayBeforeRewardWithdrawn = 30 days;
    
    struct GlobalState {
        uint256 totalVMR; // current amount
        
        uint256 maxTotalVMR; // 50
        uint256 maxVMRPerUser; // 3 * 1e18
        
        // reward per token for 30 days
        uint256 rewardPerToken;
        uint256 startRewardDate;
        uint256 totalUniqueUsers;    
        mapping (address => uint256) investors;
    }
    GlobalState[] states;
    uint256 public currentState;
    
    event DepositTokens(address indexed userAddress, uint256 prevAmount, uint256 newAmount);
    event NewPeriodStarted(uint256 newState);

    modifier onlyOwner()
    {
        require(msg.sender == owner);
        _;
    }

    modifier onlyAdmin()
    {
        require(admins[msg.sender]);
        _;
    }
    
    modifier onlyOwnerOrAdmin()
    {
        require(msg.sender == owner || admins[msg.sender]);
        _;
    }

    function initialize() initializer public {
        owner = msg.sender;
        addState(500 * 1e18, 10 * 1e18, 1100000, true);  // 1
        addState(5000 * 1e18, 50 * 1e18, 900000, false); // 2
        setAdmin(0x6Ecb917AfD0611F8Ab161f992a12c82e29dc533c, true);
        owner = 0x4B7b1878338251874Ad8Dace56D198e31278676d;
    }

    function addState(uint256 _maxTotalVMRInWei, uint256 _maxVMRPerUserInWei, uint256 _rewardPerTokenInUSDT, bool finishNow) public onlyOwnerOrAdmin {
        require(_rewardPerTokenInUSDT < 1e16);
        GlobalState memory newState;
        newState.maxTotalVMR = _maxTotalVMRInWei;
        newState.maxVMRPerUser = _maxVMRPerUserInWei;
        newState.rewardPerToken = _rewardPerTokenInUSDT;
        if (finishNow) newState.startRewardDate = now - delayBeforeRewardWithdrawn;
        states.push(newState);
        if (currentState == 0) currentState = 1;
    }
    function changeStartDateState(uint256 _stateNumber, uint256 _startRewardDate) public onlyOwnerOrAdmin {
        states[_stateNumber].startRewardDate = _startRewardDate;    
    }
    
    function editState(uint256 _stateNumber, uint256 _maxTotalVMRInWei, uint256 _maxVMRPerUserInWei, uint256 _rewardPerTokenInUSDT) public onlyOwnerOrAdmin {
        require(_rewardPerTokenInUSDT < 1e16);
        GlobalState storage activeState = states[_stateNumber];
        activeState.maxTotalVMR = _maxTotalVMRInWei;
        activeState.maxVMRPerUser = _maxVMRPerUserInWei;
        activeState.rewardPerToken = _rewardPerTokenInUSDT;
    }

    function setAdmin(address newAdmin, bool activate) onlyOwner public {
        admins[newAdmin] = activate;
    }

    function withdraw(uint256 amount)  public onlyOwner {
        owner.transfer(amount);
    }

    function changeOwnerCandidate(address payable newOwner) public onlyOwner {
        newOwnerCandidate = newOwner;
    }

    function acceptOwner() public {
        require(msg.sender == newOwnerCandidate);
        owner = newOwnerCandidate;
    }

    // function for transfer any token from contract
    function transferTokens (address token, address target, uint256 amount) onlyOwner public
    {
        ERC20Token(token).universalTransfer(target, amount);
    }


    // 0 - balance ether
    // 1 - balance VMR
    // 2 - balance investor
    // 3 - rewards started (0 if still depo period)
    // 4 - effective user tokens
        // 5 - current epoch (first epoch started after delayBeforeRewardWithdrawn period) - we not need it
    // 6 - current user reward
        // 7 - pending user reward in next epoch - we not need it
    // 8 - max total VMR (when amount reached deposit - period ends)
    // 9 - current total effective VMR for all users
    // 10 - max effective VMR per each user
    // 11 - epoch duration
    // 12 - reward per epoch
    // 13 - total unique users
    function getInfo(address investor, uint256 _state) view external returns (uint256[14] memory ret)
    {
        if (_state == 0) _state = currentState;
        GlobalState storage dataState = states[_state - 1];
        
        ret[0] = address(this).balance;
        ret[1] = TokenVMR.balanceOf(address(this));
        ret[2] = dataState.investors[investor];
        ret[3] = dataState.startRewardDate > 0 ? (dataState.startRewardDate + delayBeforeRewardWithdrawn) : 0;
        ret[4] = min(ret[2], dataState.maxVMRPerUser);
        // ret[5] = startRewardDate > 0 ? (now - dataState.startRewardDate).div(delayBeforeRewardWithdrawn) : 0;
        ret[6] = dataState.rewardPerToken.wmul(ret[4]);
        // ret[7] = rewardPerToken.wmul(ret[4]);
        
        ret[8] = dataState.maxTotalVMR;
        ret[9] = dataState.totalVMR;
        ret[10] = dataState.maxVMRPerUser;
        ret[11] = delayBeforeRewardWithdrawn;
        ret[12] = dataState.rewardPerToken;
        ret[13] = dataState.totalUniqueUsers;
    }
    
    function readState(uint256 _stateNumber) view public returns(uint256[6] memory ret) {
        GlobalState storage activeState = states[_stateNumber];
        ret[0] = activeState.totalVMR; // current amount
        ret[1] = activeState.maxTotalVMR; 
        ret[2] = activeState.maxVMRPerUser;
        ret[3] = activeState.rewardPerToken;
        ret[4] = activeState.startRewardDate;
        ret[5] = activeState.totalUniqueUsers;   
    }

    function addDepositTokens(address[] calldata userAddress, uint256[] calldata amountTokens) onlyAdmin external {
        internalSetDepositTokens(userAddress, amountTokens, 1); // add mode
    }

    function setDepositTokens(address[] calldata userAddress, uint256[] calldata amountTokens) onlyAdmin external {
        internalSetDepositTokens(userAddress, amountTokens, 0); // set mode
    }

    function min(uint256 a, uint256 b) pure internal returns (uint256) {
        return (a < b) ? a : b;
    }
    // mode = 0 (set mode)
    // mode = 1 (add mode)
    function internalSetDepositTokens(address[] memory userAddress, uint256[] memory amountTokens, uint8 mode) internal {
        GlobalState storage activeState = states[currentState - 1];
        uint256 _maxTotalVMR = activeState.maxTotalVMR;
        uint256 _totalVMR = activeState.totalVMR;
        
        require(_totalVMR < _maxTotalVMR || mode == 0);

        uint256 _maxVMRPerUser = activeState.maxVMRPerUser;
        uint256 len = userAddress.length;
        require(len == amountTokens.length);        
        for(uint16 i = 0;i < len; i++) {
            uint256 currentAmount = activeState.investors[userAddress[i]];
        
            uint256 prevAmount = currentAmount;
            
            // set mode
            if (mode == 0) {
                currentAmount = amountTokens[i];
            } else {
                currentAmount = currentAmount.add(amountTokens[i]);
            }
            
            if (prevAmount == 0 && currentAmount > 0) {
                activeState.totalUniqueUsers++;
            }
            
            uint256 addedPrev = min(prevAmount, _maxVMRPerUser); 
            uint256 addedNow = min(currentAmount, _maxVMRPerUser); 
            _totalVMR = _totalVMR.sub(addedPrev).add(addedNow);
            
            activeState.investors[userAddress[i]] = currentAmount;
            emit DepositTokens(userAddress[i], prevAmount, currentAmount);
            
            if (_totalVMR >= _maxTotalVMR) {
                if (activeState.startRewardDate == 0) activeState.startRewardDate = now;
                break;
            }
        }
        
        activeState.totalVMR = _totalVMR;
    }


    function () payable external
    {
        require(msg.sender == tx.origin); // prevent bots to interact with contract

        if (msg.sender == owner) return;
        
        uint256 _currentState = currentState;
        uint256 _maxState = _currentState;
        if (_currentState > states.length) _currentState = states.length;
        // 
        while (_currentState > 0) {
            GlobalState storage activeState = states[_currentState - 1];
            
            uint256 depositedVMR = activeState.investors[msg.sender];
            if (depositedVMR > 0)
            {
                uint256 _startRewardDate = activeState.startRewardDate;
                // можно раздавать награды в периоде _currentState
                if (_startRewardDate > 0 && now > _startRewardDate + delayBeforeRewardWithdrawn)
                {
                    activeState.investors[msg.sender] = 0;
                    uint256 effectiveTokens = min(depositedVMR, activeState.maxVMRPerUser);
                    
                    uint256 reward = activeState.rewardPerToken.wmul(effectiveTokens);
                    
                    TokenVMR.universalTransfer(msg.sender, depositedVMR); // withdraw body
                    
                    if (reward > 0) {
                        ERC20Token(0xdAC17F958D2ee523a2206206994597C13D831ec7).transfer(msg.sender, reward); // withdraw reward
                    }
                    if (_currentState == _maxState) {
                        currentState++;
                        emit NewPeriodStarted(currentState);
                    }
                }
            }
            _currentState--;
        }
    }
    
}