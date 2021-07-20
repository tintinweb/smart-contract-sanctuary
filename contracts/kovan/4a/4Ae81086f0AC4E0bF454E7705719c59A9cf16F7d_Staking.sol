// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./interface.sol";

contract LessLibrary is Ownable {
    PresaleInfo[] private presaleAddresses; // track all presales created

    uint256 private minInvestorBalance = 1000 * 1e18;
    uint256 private votingTime = 3 days; //three days
    //uint256 private votingTime = 300;
    uint256 private minStakeTime = 1 days; //one day
    uint256 private minUnstakeTime = 6 days; //six days

    address private factoryAddress;

    uint256 private minVoterBalance = 500 * 1e18; // minimum number of  tokens to hold to vote
    uint256 private minCreatorStakedBalance = 8000 * 1e18; // minimum number of tokens to hold to launch rocket

    uint8 private feePercent = 2;
    uint32 private usdtFee = 1 * 1e6;

    address private uniswapRouter; // uniswapV2 Router
    address private tether;

    address payable private lessVault;
    address private devAddress;
    IStaking public safeStakingPool;

    mapping(address => bool) private isPresale;
    mapping(bytes => bool) public usedSignature;

    struct PresaleInfo {
        bytes32 title;
        address presaleAddress;
        string description;
        bool isCertified;
    }

    modifier onlyDev() {
        require(owner() == msg.sender || msg.sender == devAddress, "onlyDev");
        _;
    }

    modifier onlyPresale() {
        require(isPresale[msg.sender], "Not presale");
        _;
    }

    modifier onlyFactory() {
        require(factoryAddress == msg.sender, "onlyFactory");
        _;
    }

    constructor(address _dev, address payable _vault, address _uniswapRouter, address _tether) {
        require(_dev != address(0));
        require(_vault != address(0));
        devAddress = _dev;
        lessVault = _vault;
        uniswapRouter = _uniswapRouter;
        tether = _tether;
    }

    function setFactoryAddress(address _factory) external onlyDev {
        require(_factory != address(0));
        factoryAddress = _factory;
    }

    function setUsdtFee(uint32 _newAmount) external onlyDev {
        require(_newAmount > 0, "0 amt");
        usdtFee = _newAmount;
    }

    function getUsdtFee() external view onlyFactory returns(uint256, address) {
        return (usdtFee, tether);
    }

    function setTetherAddress(address _newAddress) external onlyDev {
        require(_newAddress != address(0), "0 addr");
        tether = _newAddress;
    }

    function setMinStakeTime(uint256 _new) external onlyDev {
        minStakeTime = _new;
    }

    function setMinUnstakeTime(uint256 _new) external onlyDev {
        minUnstakeTime = _new;
    }

    function addPresaleAddress(address _presale, bytes32 _title, string memory _description, bool _type)
        external
        onlyFactory
        returns (uint256)
    {
        presaleAddresses.push(PresaleInfo(_title, _presale, _description, _type));
        isPresale[_presale] = true;
        //uint256 _id = presaleAddresses.length - 1;
        //forAllPoolsSearch[_id] = PresaleInfo(_title, _presale, _description, _type);
        return presaleAddresses.length - 1;
    }

    function getPresalesCount() external view returns (uint256) {
        return presaleAddresses.length;
    }

    function getPresaleAddress(uint256 id) external view returns (address) {
        return presaleAddresses[id].presaleAddress;
    }

    function setPresaleAddress(uint256 id, address _newAddress)
        external
        onlyDev
    {
        presaleAddresses[id].presaleAddress = _newAddress;
    }

    function changeDev(address _newDev) external onlyDev {
        require(_newDev != address(0), "Wrong new address");
        devAddress = _newDev;
    }

    function setVotingTime(uint256 _newVotingTime) external onlyDev {
        require(_newVotingTime > 0, "Wrong new time");
        votingTime = _newVotingTime;
    }

    function setStakingAddress(address _staking) external onlyDev {
        require(_staking != address(0));
        safeStakingPool = IStaking(_staking);
    }

    function getVotingTime() public view returns(uint256){
        return votingTime;
    }

    function getMinInvestorBalance() external view returns (uint256) {
        return minInvestorBalance;
    }

    function getMinUnstakeTime() external view returns (uint256) {
        return minUnstakeTime;
    }

    function getDev() external view onlyFactory returns (address) {
        return devAddress;
    }

    function getMinVoterBalance() external view returns (uint256) {
        return minVoterBalance;
    }

    function getMinYesVotesThreshold() external view returns (uint256) {
        uint256 stakedAmount = safeStakingPool.getOverallBalanceInLess();
        return stakedAmount / 10;
    }

    function getFactoryAddress() external view returns (address) {
        return factoryAddress;
    }

    function getMinCreatorStakedBalance() external view returns (uint256) {
        return minCreatorStakedBalance;
    }

    function getStakedSafeBalance(address sender)
        public
        view
        returns (uint256)
    {
        uint256 balance;
        uint256 lastStakedTimestamp;
        (balance, lastStakedTimestamp, ) = safeStakingPool.getStakedInfo(sender);

        if (lastStakedTimestamp + minStakeTime <= block.timestamp) {
            return balance;
        }
        return 0;
    }

    function getUniswapRouter() external view returns (address) {
        return uniswapRouter;
    }

    function setUniswapRouter(address _uniswapRouter) external onlyDev {
        uniswapRouter = _uniswapRouter;
    }

    function calculateFee(uint256 amount) external view onlyPresale returns(uint256){
        return amount * feePercent / 100;
    }

    function getVaultAddress() external view onlyPresale returns(address payable){
        return lessVault;
    }

    function getArrForSearch() external view returns(PresaleInfo[] memory) {
        return presaleAddresses;
    }
    
    function _verifySigner(bytes memory data, bytes memory signature)
        public
        view
        returns (bool)
    {
        IPresaleFactory presaleFactory = IPresaleFactory(payable(factoryAddress));
        address messageSigner =
            ECDSA.recover(keccak256(data), signature);
        require(
            presaleFactory.isSigner(messageSigner),
            "Unauthorised signer"
        );
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./LessLibrary.sol";
import "./interface.sol";

contract Staking is Ownable, ReentrancyGuard {
    ERC20Burnable public lessToken;
    ERC20Burnable public lpToken;
    LessLibrary public safeLibrary;
 
    uint256 public minDaysStake;
    uint16 public penaltyDistributed = 5; //100% = 1000
    uint16 public penaltyBurned = 5; //100% = 1000
    uint256 public lessPerLp = 300; //1 LP = 300 LESS

    uint256 public stakeIdLast;

    uint256 public allLp;
    uint256 public allLess;
    uint256 public totalLpRewards;
    uint256 public totalLessRewards;
    
    mapping(address => AccountInfo) private accountInfos;
    
    struct AccountInfo {
        uint256 balance;
        uint256 lastStakedTimestamp;
        uint256 lastUnstakedTimestamp;
    }

    struct StakeItem {
        uint256 stakeId;
        uint256 startTime;
        uint256 stakedLp;
        uint256 stakedLess;
        // uint256 lpEarned;
        // uint256 lessEarned;
        uint256 lpRewardsWithdrawn;
        uint256 lessRewardsWithdrawn;
    }

    event Staked(
        address staker,
        uint256 stakeId,
        uint256 startTime,
        uint256 stakedLp,
        uint256 stakedLess
    );

    struct Unstake {
        address staker;
        uint256 stakeId;
        uint256 unstakeTime;
        uint256 unstakedLp;
        uint256 unstakedLess;
        uint256 lpRewards;
        uint256 lessRewards;
        bool isUnstakedEarlier;
        bool isUnstakedFully;
    }

    event Unstaked(Unstake);

    enum BalanceType {
        Less,
        Lp,
        Both
    }

    mapping(address => StakeItem[]) public stakeList;

    modifier onlyDev() {
        require(
            msg.sender == safeLibrary.getFactoryAddress() ||
                msg.sender == safeLibrary.owner() ||
                msg.sender == safeLibrary.getDev(),
            "Only Dev"
        );
        _;
    }


    constructor(ERC20Burnable _lp, ERC20Burnable _less, address _safeLibrary) {
        lessToken = _less;
        lpToken = _lp;
        safeLibrary = LessLibrary(_safeLibrary);

        minDaysStake = safeLibrary.getMinUnstakeTime();
    }

    function getStakedInfo(address _sender) public view returns(uint256, uint256, uint256) {
        return (accountInfos[_sender].balance, 
                accountInfos[_sender].lastStakedTimestamp,
                accountInfos[_sender].lastUnstakedTimestamp);
    }

    /**
     * @dev stake tokens
     * @param lpAmount Amount of staked LP tokens
     * @param lessAmount Amount of staked Less tokens
     */

    function stake(uint256 lpAmount, uint256 lessAmount) external nonReentrant  {
        require(lpAmount > 0 || lessAmount > 0, "Error: zero staked tokens");
        if (lpAmount > 0) {
            require(
                lpToken.transferFrom(_msgSender(), address(this), lpAmount),
                "Error: LP token tranfer failed"
            );
        }
        if (lessAmount > 0) {
            require(
                lessToken.transferFrom(_msgSender(), address(this), lessAmount),
                "Error: Less token tranfer failed"
            );
        }
        allLp += lpAmount;
        allLess += lessAmount;
        AccountInfo storage account = accountInfos[_msgSender()];

        account.balance += lessAmount + getLpInLess(lpAmount);

        if (account.lastUnstakedTimestamp == 0) {
            account.lastUnstakedTimestamp = block.timestamp;
        }

        account.lastStakedTimestamp = block.timestamp;

        stakeList[_msgSender()].push(
            StakeItem(stakeIdLast, block.timestamp, lpAmount, lessAmount, 0, 0)
        );

        emit Staked(
            _msgSender(),
            stakeIdLast++,
            block.timestamp,
            lpAmount,
            lessAmount
        );
    }

    function setLibraryAddress(address _newInfo) external onlyDev {
        safeLibrary = LessLibrary(_newInfo);
    }

    /**
     * @dev unstake tokens without penalty. Only for owner
     * @param lpAmount Amount of unstaked LP tokens
     * @param lessAmount Amount of unstaked Less tokens
     * @param lpRewards Amount of withdrawing rewards in LP
     * @param lessRewards Amount of withdrawing rewards in Less
     * @param _stakeId id of the unstaked pool
     */

    function unstakeWithoutPenalty(
        uint256 lpAmount,
        uint256 lessAmount,
        uint256 lpRewards,
        uint256 lessRewards,
        uint256 _stakeId
    ) external onlyOwner {
        _unstake(lpAmount, lessAmount, lpRewards, lessRewards, _stakeId, true);
    }

    /**
     * @dev unstake tokens
     * @param lpAmount Amount of unstaked LP tokens
     * @param lessAmount Amount of unstaked Less tokens
     * @param lpRewards Amount of withdrawing rewards in LP
     * @param lessRewards Amount of withdrawing rewards in Less
     * @param _stakeId id of the unstaked pool
     */

    function unstake(
        uint256 lpAmount,
        uint256 lessAmount,
        uint256 lpRewards,
        uint256 lessRewards,
        uint256 _stakeId
    ) external {
        _unstake(lpAmount, lessAmount, lpRewards, lessRewards, _stakeId, false);
    }

    struct UnstakeItem {
           uint256 unstakedLp;
           uint256 unstakedLess;
           uint256 lpRewardsAmount;
           uint256 lessRewardsAmount;
        }

    struct PenaltyItem {
        uint256 lpToBurn;
        uint256 lessToBurn;
        uint256 lpToDist;
        uint256 lessToDist;
    }
    struct AmountItem {
        uint256 lpAmount;
        uint256 lessAmount;
        uint256 lpRewardsAmount;
        uint256 lessRewardsAmount;
    }

    function _unstake(
        uint256 lpAmount,
        uint256 lessAmount,
        uint256 lpRewardsAmount,
        uint256 lessRewardsAmount,
        uint256 _stakeId,
        bool isWithoutPenalty
    ) internal nonReentrant {
        address staker = _msgSender();
        require(stakeList[staker].length > 0, "Error: you haven't stakes");

        AmountItem memory amountItem = AmountItem(lpAmount, lessAmount, lpRewardsAmount, lessRewardsAmount);
        

        uint256 index = _getStakeIndexById(staker, _stakeId);
        require(index != ~uint256(0), "Error: no such stake");
        StakeItem storage deposit = stakeList[staker][index];

        uint256 stakeLessRewards = deposit.stakedLess * amountItem.lessRewardsAmount / allLess;
        uint256 stakeLpRewards = deposit.stakedLp * amountItem.lpRewardsAmount / allLp;

        require(amountItem.lpAmount > 0 || amountItem.lessAmount > 0, "Error: you unstake nothing");
        require(
            amountItem.lpAmount <= deposit.stakedLp,
            "Error: insufficient LP token balance"
        );
        require(
            amountItem.lessAmount <= deposit.stakedLess,
            "Error: insufficient Less token balance"
        );
        require(
            amountItem.lpRewardsAmount <= (stakeLpRewards - deposit.lpRewardsWithdrawn),
            "Error: insufficient LP token rewards"
        );
        require(
            amountItem.lessRewardsAmount <= (stakeLessRewards - deposit.lessRewardsWithdrawn),
            "Error: insufficient Less token rewards"
        );

        
        UnstakeItem memory unstakeItem = UnstakeItem(amountItem.lpAmount, amountItem.lessAmount, amountItem.lpRewardsAmount, amountItem.lessRewardsAmount);

        

        bool isUnstakedEarlier = block.timestamp - deposit.startTime <
            minDaysStake;
        if (isUnstakedEarlier && !isWithoutPenalty) {
            PenaltyItem memory penaltyItem = PenaltyItem(0,0,0,0);
            penaltyItem.lpToBurn = unstakeItem.unstakedLp * penaltyBurned / 1000;
            penaltyItem.lessToBurn = unstakeItem.unstakedLess * penaltyBurned / 1000;
            penaltyItem.lpToDist = unstakeItem.unstakedLp * penaltyDistributed / 1000;
            penaltyItem.lessToDist = unstakeItem.unstakedLess * penaltyDistributed / 1000;

            unstakeItem.unstakedLp -= penaltyItem.lpToBurn + penaltyItem.lpToDist;
            unstakeItem.unstakedLess -= penaltyItem.lessToBurn + penaltyItem.lessToDist;

            burnPenalty(penaltyItem.lpToBurn, penaltyItem.lessToBurn);
            distributePenalty(penaltyItem.lpToDist, penaltyItem.lessToDist);
        }
        uint256 tranferedLp = unstakeItem.unstakedLp + unstakeItem.lpRewardsAmount;
        uint256 tranferedLess = unstakeItem.unstakedLess + unstakeItem.lessRewardsAmount;

        require(
            lpToken.transfer(staker, tranferedLp),
            "Error: LP transfer failed"
        );
        require(
            lessToken.transfer(staker, tranferedLess),
            "Error: Less transfer failed"
        );

        allLp -= unstakeItem.unstakedLp;
        allLess -= unstakeItem.unstakedLess;
        deposit.stakedLp -= amountItem.lpAmount;
        deposit.stakedLess -= amountItem.lessAmount;
        deposit.lpRewardsWithdrawn += unstakeItem.lpRewardsAmount;
        deposit.lessRewardsWithdrawn += unstakeItem.lessRewardsAmount;
        totalLessRewards -= unstakeItem.lessRewardsAmount;
        totalLpRewards -= unstakeItem.lpRewardsAmount;

        AccountInfo storage account = accountInfos[_msgSender()];

        account.balance -= amountItem.lessAmount + getLpInLess(amountItem.lpAmount);

        account.lastStakedTimestamp = block.timestamp;
        

        if (account.balance == 0) {
            account.lastUnstakedTimestamp = 0;
            account.lastStakedTimestamp = 0;
        }

        bool isStakeEmpty = deposit.stakedLp == 0 &&
            deposit.stakedLess == 0 &&
            deposit.lpRewardsWithdrawn == stakeLpRewards &&
            deposit.lessRewardsWithdrawn == stakeLessRewards;

        if (isStakeEmpty) {
            removeStake(staker, index);
        }

        emit Unstaked(
            Unstake(
                staker,
                deposit.stakeId,
                block.timestamp,
                unstakeItem.unstakedLp,
                unstakeItem.unstakedLess,
                unstakeItem.lpRewardsAmount,
                unstakeItem.lessRewardsAmount,
                isUnstakedEarlier,
                isStakeEmpty
            )
        );
    }

    /**
     * @dev destribute penalty among all stakers proportional their stake sum.
     * @param lp LP token penalty
     * @param less Less token penalty
     */
     

    function distributePenalty(uint256 lp, uint256 less) internal {
        totalLessRewards += less;
        totalLpRewards += lp;
    }
    

    /**
     * @dev burn penalty.
     * @param lp LP token penalty
     * @param less Less token penalty
     */

    function burnPenalty(uint256 lp, uint256 less) internal {
        if (lp > 0) {
            lpToken.burn(lp);
            allLp -= lp;
        }
        if (less > 0) {
            lessToken.burn(less);
            allLess -= less;
        }
    }

    /**
     * @dev return full LP balance of staker.
     * @param staker staker address
     */

    function getLpBalanceByAddress(address staker)
        public
        view
        returns (uint256)
    {
        return _getBalanceByAddress(staker, BalanceType.Lp);
    }

    /**
     * @dev return full Less balance of staker.
     * @param staker staker address
     */
    function getLessBalanceByAddress(address staker)
        public
        view
        returns (uint256)
    {
        return _getBalanceByAddress(staker, BalanceType.Less);
    }

    /**
     * @dev return full balance of staker converted to Less.
     * @param staker staker address
     */
    function getOverallBalanceInLessByAddress(address staker)
        public
        view
        returns (uint256)
    {
        return _getBalanceByAddress(staker, BalanceType.Both);
    }

    /**
     * @dev return sum of LP converted in Less
     * @param _amount amount of converted LP
     */
    function getLpInLess(uint256 _amount) public view returns (uint256) {
        return _amount * lessPerLp;
    }

    /**
     * @dev return num of all LP on the contract
     */
    function getOverallLP() public view returns (uint256) {
        return allLp;
    }

    /**
     * @dev return num of all Less on the contract
     */
    function getOverallLess() public view returns (uint256) {
        return allLess;
    }

    /**
     * @dev return full contract balance converted in Less
     */
    function getOverallBalanceInLess() public view returns (uint256) {
        return allLess + allLp * lessPerLp;
    }

    /**
     * @dev set num of Less per one LP
     */

    function setLessInLP(uint256 amount) public onlyOwner {
        lessPerLp = amount;
    }

    /**
     * @dev set minimum days of stake for unstake without penalty
     */

    function setMinDaysStake(uint256 _minDaysStake) public onlyOwner {
        minDaysStake = _minDaysStake;
    }

    /**
     * @dev set penalty percent
     */
    function setPenalty(uint16 distributed, uint16 burned) public onlyOwner {
        penaltyDistributed = distributed;
        penaltyBurned = burned;
    }

    /**
     * @dev return index of stake by id
     * @param staker staker address
     * @param stakeId of stake pool
     */

    function _getStakeIndexById(address staker, uint256 stakeId)
        internal
        view
        returns (uint256)
    {
        StakeItem[] memory stakes = stakeList[staker];
        require(stakes.length > 0, "Error: user havn't stakes");
        for (uint256 i = 0; i < stakes.length; i++) {
            if (stakes[i].stakeId == stakeId) return i;
        }
        return ~uint256(0);
    }

    /**
     * @dev support function for get balance of address
     * @param staker staker address
     * @param balanceType type of balance
     */

    function _getBalanceByAddress(address staker, BalanceType balanceType)
        internal
        view
        returns (uint256 balance)
    {
        StakeItem[] memory deposits = stakeList[staker];
        if (deposits.length > 0) {
            for (uint256 i = 0; i < deposits.length; i++) {
                if (balanceType == BalanceType.Lp)
                    balance += deposits[i].stakedLp;
                else if (balanceType == BalanceType.Less)
                    balance += deposits[i].stakedLess;
                else
                    balance += deposits[i].stakedLess + getLpInLess(deposits[i].stakedLp);
            }
        }
    }

    /**
     * @dev remove stake from stakeList by index
     * @param staker staker address
     * @param index of stake pool
     */

    function removeStake(address staker, uint256 index) internal {
        require(stakeList[staker].length != 0);
        if (stakeList[staker].length == 1) {
            stakeList[staker].pop();
        } else {
            stakeList[staker][index] = stakeList[staker][
                stakeList[staker].length
            ];
            stakeList[staker].pop();
        }
    }

    function setLp(address _lp) external onlyOwner {
        lpToken = ERC20Burnable(_lp);
    }

    function setLess(address _less) external onlyOwner {
        lessToken = ERC20Burnable(_less);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapV2Router02 {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (
        uint amountA, 
        uint amountB, 
        uint liquidity
    );

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (
        uint amountToken, 
        uint amountETH, 
        uint liquidity
    );

    function getAmountsIn(uint amountOut, address[] memory path) external view returns (uint[] memory amounts);

    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}

interface IUniswapV2Factory02 {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
    function approve(address guy, uint wad) external returns (bool);
}

interface IPresaleFactory {
    function isSigner(address _address) external view returns (bool);
}

interface IStaking {
    function getStakedInfo(address _sender) external view returns(uint256, uint256, uint256);
    function getOverallBalanceInLess() external view returns(uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor () {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        _approve(account, _msgSender(), currentAllowance - amount);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
        } else if (signature.length == 64) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let vs := mload(add(signature, 0x40))
                r := mload(add(signature, 0x20))
                s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
                v := add(shr(255, vs), 27)
            }
        } else {
            revert("ECDSA: invalid signature length");
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 1
  },
  "evmVersion": "berlin",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}