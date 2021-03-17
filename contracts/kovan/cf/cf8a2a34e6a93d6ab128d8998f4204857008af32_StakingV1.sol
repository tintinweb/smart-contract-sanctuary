/**
 *Submitted for verification at Etherscan.io on 2021-03-16
*/

pragma solidity ^0.6.12;

library Math {
 
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
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

interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


library Address {
    
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

pragma solidity ^0.6.12;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() public {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }
    
    function safeMultiTransfer(IERC20 token, address[] memory to, uint256[] memory values) internal {
        require(to.length == values.length, "Different number of recipients than values");
        for (uint i = 0; i < to.length; i++) {
            callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to[i], values[i]));
        }
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    
    function safeMultiTransferFrom(IERC20 token, address from, address[] memory to, uint256[] memory values) internal {
        require(to.length == values.length, "Different number of recipients than values");
        for (uint i = 0; i < to.length; i++) {
            callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to[i], values[i]));
        }
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}


interface IHC {
    function changeFee(uint _fee) external;
    function changeCollector(address payable _collector, bool _set) external returns (bool);
}




contract StakingV1 is Ownable {
    using SafeMath for uint;
    using SafeERC20 for IERC20;
    
    bool isInitialized = false;
    address public hPAR;
    //bool public hparSet = false;
    address public hedgeyCallsFactory;
    address public hedgeyPutsFactory;
    bool factorySet = false;
    address payable public weth;
    uint public s = 0; //index or number of stakers
    uint public currentPeriod = 0;
    uint public minPeriodTime = 0;//3600; //one hour min times between periods of allocations
    address[] public feeTokens; //just the addresses of any token we have collected in fees - all ERC20 fees only 
    mapping(address => address) public tokenAddresses;
    
    
    constructor(address _hPAR, address payable _weth) public {
        hPAR = _hPAR;
        weth = _weth;
    }
    
    struct Period {
        uint start;
        uint end;
    }
    
    mapping(uint => Period) public periods; //way for us to access the periods which are really just a start and an end time
    
    struct Staker {
        address payable owner;
        uint amount;
        uint timeIn;
        uint timeOut;
        bool isStaking;
        mapping(address => uint) rewards; //lookup by the token address to get the rewards a staker can redeem
    }
    
    mapping(address => bool) public whitelist; //whitelist any hedgey contracts - only collect fees from them
    
    mapping(uint => Staker) public stakers; //use the index s to lookup staker and their info
    
    
    //mapping(address => uint) public tokenBalances; //just helps us receive tokens and confirm the amounts match
    
    struct CurrentFee {
        uint feesCollected;
    }
    
    mapping(address => mapping(uint => CurrentFee)) public currentFees;
    
    receive() external payable {    
    }
    
    /************************* Administration type FUNCTIONS *************************************************************************/
    
    //this function is set by the owner right after deployment simply to assign the factory addresses - since the staking contract should be set first
    function setFactories(address _hedgeyCallsFactory, address _hedgeyPutsFactory) public onlyOwner {
        require(!factorySet, "hedgeyStake: factory has already been set");
        hedgeyCallsFactory = _hedgeyCallsFactory;
        hedgeyPutsFactory = _hedgeyPutsFactory;
        factorySet = true;
    }
    
    
    //initialize function that just kicks off the first period
    function initialize() public onlyOwner returns (bool) {
        require(!isInitialized, "already initialized");
        Period storage p = periods[0];
        p.start = block.timestamp;
        p.end = 0;
        isInitialized = true;
        return isInitialized;
    }
    
    
    //function to add new hedgey options pairs as they are produced by the factories
    function addWhitelist(address hedgey) external {
        require(msg.sender == hedgeyCallsFactory || msg.sender == hedgeyPutsFactory, "hedgeyStake: only factory can whitelist");
        whitelist[hedgey] = true;
    }
    
    //function for adding hedgey options pairs before this contract is deployed
    function manualWhiteList(address[] memory hedgey) external onlyOwner {
        for (uint i; i < hedgey.length; i++) {
            whitelist[hedgey[i]] = true;
        }
    }
    
    function changeFee(address hedgey, uint newFee) external onlyOwner {
        IHC(hedgey).changeFee(newFee);
    }
    
    function changeCollector(address hedgey, address payable _newCollector, bool _set) external onlyOwner returns (bool success) {
        success = IHC(hedgey).changeCollector(_newCollector, _set);
    }
    
    
    //function to put a time stamp on the fees received for calculation and alloctions
    //need some requirements to confirm that the amount sent into the contract has changed by the same
    function receiveFee(uint amt, address token) external {
        require(whitelist[msg.sender], "hedgeyStake: you are not a whitelisted address to send fees");
        CurrentFee storage c = currentFees[token][currentPeriod]; //setup c with the token address and current currentPeriod
        //then all we do is add the amt to the currentFee struct
        c.feesCollected += amt;
        //tokenBalances[token] = IERC20(token).balanceOf(address(this)); //tells our contract how much it has so we cant overspend
        if (tokenAddresses[token] == address(0)) {
            tokenAddresses[token] = token;
            feeTokens.push(token);
        }
    }
    
    /****************************** STAKER and USER SPECIFIC METHODS   ****************************************************************************/
    
    //function for someone to stake their hpar tokens
    function stake(uint amt) public {
        require(IERC20(hPAR).balanceOf(msg.sender) >= amt, "you dont have enough hpar");
        SafeERC20.safeTransferFrom(IERC20(hPAR), msg.sender, address(this), amt); //pulls in the staked hPAR
        //now we setup the new staker struct
        stakers[s++] = Staker(msg.sender, amt, block.timestamp, 0, true); //sets up our initial staker metrics
        emit newStaker(amt, msg.sender);
    }
    
    //function to unstake - doesn't automatically pull your fees though - you still gotta do that separately because they may not have been allocated yet
    function unStake(uint _s) public returns (bool) {
        Staker storage st = stakers[_s];
        require(msg.sender == st.owner, "you dont own this");
        require(st.isStaking, "you already unstaked bruh");
        st.timeOut = block.timestamp;
        st.isStaking = false;
        SafeERC20.safeTransfer(IERC20(hPAR), msg.sender, st.amount);
        st.amount = 0;
        emit unStaked(msg.sender);
    }
    
    function getRewards(uint _s, address token) public view returns (uint _rewards) {
        Staker storage st = stakers[_s];
        _rewards = st.rewards[token];
    }
    
    function pullRewards(uint _s, address token) public payable {
        Staker storage st = stakers[_s];
        require(msg.sender == st.owner, "you dont own this bad boi");
        uint _rewards = st.rewards[token];
        st.rewards[token] = 0; //resets this back to 0
        bool isWeth = (token == weth);
        withdrawPymt(isWeth, token, msg.sender, _rewards);
        //tokenBalances[token] = IERC20(token).balanceOf(address(this)); //update the balances known to the contract
    }
    
    
    function pullAllRewards(uint _s) public payable {
        Staker storage st = stakers[_s];
        require(msg.sender == st.owner, "you dont own this");
        for (uint i = 0; i < feeTokens.length; i++) {
            pullRewards(_s, feeTokens[i]); //runs the pull tokens for each of them
        }
    }
    
    
    /************************* INTERNAL WETH HANDLERS *******************************************************************************/
    
    function withdrawPymt(bool _isWeth, address _token, address payable to, uint _amt) internal {
        if (_isWeth && (!Address.isContract(to))) {
            //if the address is ta contract - then we should actually just send WETH out to the contract
            IWETH(weth).withdraw(_amt);
            to.transfer(_amt);
        } else {
            SafeERC20.safeTransfer(IERC20(_token), to, _amt);
        }
    }

    
    
    /*****************************************  INTERNAL CALCULATION AND ALLOCATION FUNCTIONS      ***********************************/
    
    
    function calcStakerTimes(uint _s, uint _period) public view returns (uint timeRewards) {
        Staker storage st = stakers[_s];
        Period storage p = periods[_period];
        uint timerate;
        //calculate how long staker has been staking during the period
        if (st.timeIn <= p.start && st.isStaking) {
            //we know they were in before the period began and are still staking
            timerate = p.end.sub(p.start); //full period time 
            
        } else if (st.timeIn <= p.start && st.timeOut >= p.start) {
            timerate = st.timeOut.sub(p.start); //pulls their stub ownership piece
        } else {
            timerate = 0;
        }
        timeRewards = timerate.mul(st.amount);
    }
    
    function calcTotalTimeRewards(uint _period) public view returns (uint) {
        uint totalTimeRewards;
        for (uint i = 0; i < s; i++) {
            Staker storage st = stakers[i]; //gets our stakers
            uint _timeRewards = calcStakerTimes(i, _period); //gets our time rewards
            totalTimeRewards += _timeRewards; //sum em all up
        }
        return totalTimeRewards;
    }
    
    //function changes the state of an individual staker
    function allocateStakerTime(uint _s, uint _period) public view returns (uint) {
        uint _totalTimeRewards = calcTotalTimeRewards(_period);
        uint _timeRewards = calcStakerTimes(_s, _period); //gets the time they staked
        Staker storage st = stakers[_s];//gets our stakers
        //update our staker for their ownership level
        uint timeStaked = _timeRewards.mul(1e5).div(_totalTimeRewards); //this goes to 5 decimals of precision
        //st.periodRate[_period] = timeStaked;
        return timeStaked;
    }
    
    
    //function that calculates individual token rewards for a given staker
    function tokenRewardCalc(address token, uint _s, uint _period) internal returns (uint) {
        CurrentFee storage c = currentFees[token][_period];
        Staker storage st = stakers[_s];
        Period storage p = periods[_period];
        //gets our additional rewards ownership with a 10 decimal precision
        uint _timeStaked = allocateStakerTime(_s, _period);
        uint _fees = c.feesCollected;
        uint _rewards = _timeStaked.mul(_fees).div(1e5); //multiply the time percentage by the fees and remove the decimal precision factor
        //add these rewards to the stakers balances
        st.rewards[token] += _rewards;
        return _rewards;
    }
    
    
    //this function has to be called to update the tokens allocated to each staker. 
    //can be called by anyone at anytime - there are no external movements - just allocating tokens to people based on their stake pro rata amounts
    function allocateRewards() public returns (bool) {
        //require some stuff & use ReentrancyGuard
        require(isInitialized, "not initialized yet");
        Period storage p = periods[currentPeriod];
        //check if we've reached the minimum
        require(block.timestamp.sub(p.start) >= minPeriodTime, "hasnt been an hour yet since last allocation");
        //end the current period so that we can run and evaluate everything
        p.end = block.timestamp;
        for (uint j = 0; j < feeTokens.length; j++) {
            uint totalRewardsAllocated;
            address _token = feeTokens[j];
            CurrentFee storage c = currentFees[_token][currentPeriod];
            for (uint i = 0; i < s; i++) {
                uint _rewards = tokenRewardCalc(_token, i, currentPeriod); //calculates rewards and allocates for current period
                totalRewardsAllocated += _rewards;
            }
            require(totalRewardsAllocated <= c.feesCollected, "somehow there are more rewards than fees collected");
            require(totalRewardsAllocated <= IERC20(_token).balanceOf(address(this)), "somehow more rewards than the balance in this contract");
        }
        emit rewardsAllocated(currentPeriod);
        currentPeriod++;
        periods[currentPeriod] = Period(block.timestamp, 0); //resets the period for the next one
        return true;
    }
    
    //Events*********************************************************************************
    event rewardsAllocated(uint _period);
    event newStaker(uint _amount, address _staker);
    event unStaked(address _staker);
    
}