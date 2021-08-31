//"SPDX-License-Identifier: MIT"
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "./interfaces/IUniswapV2Router.sol";

contract BaseContract is Context, Ownable {
    // For MainNet
    // address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    // address internal constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    // address internal constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    // address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    // For Kovan
    address internal constant WETH = 0x02822e968856186a20fEc2C824D4B174D0b70502;
    address internal constant DAI = 0x04DF6e4121c27713ED22341E7c7Df330F56f289B;
    address internal constant WBTC = 0x1C8E3Bcb3378a443CC591f154c5CE0EBb4dA9648;
    address internal constant USDC = 0xc2569dd7d0fd715B054fBf16E75B001E5c0C1115;

    IUniswapV2Router internal immutable uniswapRouter =
        IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    address internal ddToken;

    modifier whenStartup() {
        require(ddToken != address(0), "DFM-Contracts: not set up DD token");
        _;
    }

    function setupDD(address _dd) public onlyOwner {
        ddToken = _dd;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC20F is Context, Ownable, IERC20Metadata {
    bool private _paused;

    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint256 private _fee;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 fee_
    ) {
        _name = name_;
        _symbol = symbol_;
        _fee = fee_;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "DDToken: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "DDToken: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function setFeePercentage(uint256 fee_) public onlyOwner {
        require(fee_ > 0 && fee_ < 1000, "DDToken: fee percentage must be less than 10%");
        _fee = fee_;
    }

    function calculateFee(uint256 amount) public view returns (uint256, uint256) {
        require(amount > 10000, "DDToken: transfer amount is too small");

        uint256 receiveal = amount;
        uint256 fee = amount * _fee / 10000;

        unchecked {
            receiveal = amount - fee;
        }

        return (receiveal, fee);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal whenNotPaused returns (uint256) {
        require(sender != address(0), "DDToken: transfer from the zero address");
        require(recipient != address(0), "DDToken: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "DDToken: transfer amount exceeds balance"
        );
        unchecked {
            _balances[sender] = senderBalance - amount;
        }

        uint256 receiveal;
        uint256 fee;

        (receiveal, fee) = calculateFee(amount);

        _balances[recipient] += receiveal;

        emit Transfer(sender, recipient, receiveal);

        return fee;
    }

    function _mint(address account, uint256 amount) internal whenNotPaused {
        require(account != address(0), "DDToken: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal whenNotPaused {
        require(account != address(0), "DDToken: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "DDToken: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal whenNotPaused {
        require(owner != address(0), "DDToken: approve from the zero address");
        require(spender != address(0), "DDToken: approve to the zero address");

        _allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    function paused() public view returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    function pause() public onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function unpause() public onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    event Paused(address account);
    event Unpaused(address account);
}

//"SPDX-License-Identifier: MIT"
pragma solidity ^0.8.4;

import "./BaseContract.sol";
import "./ERC20F.sol";

contract RewardsContract is BaseContract {
    uint256 private dfmStartTime;

    uint256 private totalStakes;
    mapping(address => uint256[3]) private stakes;
    mapping(address => uint256[3]) private credits;
    mapping(address => uint256[7]) private bundles;
    
    uint256 public currentRoundId;
    struct Round {
        uint256 id;
        uint256 voters;
        uint256 votes;
        uint256 transfered;
        bool active;
        bool closed;
    }
    mapping(uint256 => Round) rounds;
    mapping(uint256 => mapping(address => uint256)) private votesPerRound;
    
    uint256 private shareForNextRound;
    uint16 private percentageForNextRound = 200; // 20%

    uint256 private unstakeFee;
    uint256 private breakVoteFee;
    uint256 private castVoteFee;
    
    // for distribution every 6 hours
    mapping(uint256 => uint256) private totalVotes;
    mapping(uint256 => mapping(address => uint256)) private votes;
    mapping(uint256 => address[]) private voters;
    mapping(address => uint256) private distributions;
    uint256 private allowedDistribution;
    uint256 private currentPeriod;
    uint256 private distedPeriod;


    modifier whenDfmAlive() {
        require(dfmStartTime > 0, "DFM-Dfm: has not yet opened");
        _;
    }

    function setDfmStartTime(uint256 _dfmStartTime) external onlyOwner {
        dfmStartTime = _dfmStartTime;
    }

    function setNextPercentageForRound(uint16 _percentageForNextRound)
        public
        onlyOwner
    {
        require(
            _percentageForNextRound <= 500,
            "DFM-Rewards: exceeds the limit 50%"
        );
        percentageForNextRound = _percentageForNextRound;
    }

    function stake(uint256 amount, uint256 period)
        public
        whenStartup
        whenDfmAlive
        returns (uint256)
    {
        address sender = _msgSender();
        IERC20(ddToken).transferFrom(sender, address(this), amount);

        (uint256 ramount, ) = ERC20F(ddToken).calculateFee(amount);
        period = period == 0 ? 1 : (period > 100 ? 100 : period);
        stakes[sender][0] += ramount;
        stakes[sender][1] = period;
        stakes[sender][2] = block.timestamp;
        totalStakes += ramount;

        return _calcDailyCredits(sender);
    }

    function unstake(uint256 amount)
        public
        whenStartup
        whenDfmAlive
        returns (uint256)
    {
        address sender = _msgSender();
        require(
            stakes[sender][0] >= amount,
            "DFM-Rewards: exceeds the staked amount"
        );

        uint256 fee = (amount *
            (stakes[sender][1] -
                (block.timestamp - stakes[sender][2]) /
                (86400 * 30))) / 100;
        stakes[sender][0] -= amount;
        totalStakes -= amount;

        IERC20(ddToken).transfer(sender, amount - fee);
        unstakeFee += fee;

        return _calcDailyCredits(sender);
    }

    function breakVote(uint256 amount, uint8 unit) public returns (bool) {
        address sender = _msgSender();
        require(
            unit > 0 && unit <= 6 && bundles[sender][unit] > amount,
            "DFM-Rewards: unit or amount exceeds range"
        );

        uint256 fee = (amount * 2) / 10;
        bundles[sender][unit - 1] += (amount - fee) * 1000;

        fee *= 1000**unit;
        credits[sender][0] -= fee;
        breakVoteFee += fee;

        return true;
    }

    function createRound() public onlyOwner returns (uint256) {
        currentRoundId++;
        return currentRoundId;
    }

    function castVote(uint256 credit)
        public
        whenDfmAlive
        returns (bool)
    {
        Round memory round = rounds[currentRoundId];
        require(!round.closed, "DFM-Rewards: can't cast vote to closed round");

        address sender = _msgSender();
        require(
            credit > 0 && credits[sender][0] > credit,
            "DFM-Rewards: credit exceeds range"
        );
        credits[sender][0] -= credit;

        currentPeriod = (block.timestamp - dfmStartTime) / 21600;
        if (votes[currentPeriod][sender] == 0) {
            voters[currentPeriod].push(sender);
        }
        votes[currentPeriod][sender] += credit;
        totalVotes[currentPeriod] += credit;

        if (round.active == false) {
            round = Round({id:currentRoundId, votes:credit, voters:1, transfered:0, active:true, closed:false});
        } else {
            round.voters++;
            round.votes += credit;
        }
        rounds[currentRoundId] = round;
        votesPerRound[currentRoundId][sender] += credit;        

        uint256 fee = (credit * 2) / 10;
        credit -= fee;
        castVoteFee += fee;

        uint256 forNextRound = (credit * percentageForNextRound) / 1000;
        credit -= forNextRound;
        shareForNextRound += forNextRound;
        
        for (uint8 i = 0; i < bundles[sender].length; i++) {
            if (credit == 0) {
                break;
            }
            uint256 unit = 1000**i;
            uint256 bundle = (credit % (unit * 1000)) / unit;
            bundles[sender][i] -= bundle;
            credit -= bundle * unit;
        }

        return true;
    }

    function concludeRound() public onlyOwner {
        Round memory round = rounds[currentRoundId];
        require(round.closed, "DFM-Rewards: already closed round");

        round.closed = true;
        round.transfered = shareForNextRound;
        shareForNextRound = 0;
    }

    // must be called from scheduled service every 6 hour since the DFM was setup
    function distribute() public onlyOwner whenStartup whenDfmAlive {
        uint256 prevPeriod = currentPeriod - 21600;
        if (distedPeriod == prevPeriod) {
            return;
        }
        distedPeriod = prevPeriod;

        uint256 total = IERC20(ddToken).balanceOf(address(this)) -
            totalStakes -
            unstakeFee -
            allowedDistribution;
        if (total == 0) {
            return;
        }

        if (totalVotes[prevPeriod] > 0) {
            for (uint256 i = 0; i < voters[prevPeriod].length; i++) {
                uint256 share = (total *
                    votes[prevPeriod][voters[prevPeriod][i]]) /
                    totalVotes[prevPeriod];
                distributions[voters[prevPeriod][i]] += share;
                allowedDistribution += share;
            }
        }
    }

    function distributionOf() public view returns (uint256) {
        return distributions[_msgSender()];
    }

    function claim(uint256 amount) public returns (bool) {
        address sender = _msgSender();
        require(
            distributions[sender] > amount,
            "DFM-Rwd: claim exceeds the distribution"
        );
        allowedDistribution -= amount;
        distributions[sender] -= amount;
        IERC20(ddToken).transfer(sender, amount);
        return true;
    }

    function _calcDailyCredits(address sender)
        private
        returns (uint256 dailyCredits)
    {
        dailyCredits =
            stakes[sender][0] *
            (
                stakes[sender][1] * 30 >
                    ((block.timestamp - stakes[sender][2]) / 86400)
                    ? stakes[sender][1]
                    : 1
            );

        uint256 newly = credits[sender][1] *
            (
                credits[sender][2] == 0
                    ? 0
                    : ((block.timestamp - credits[sender][2]) / 86400)
            );
        credits[sender][0] += newly;
        credits[sender][1] = dailyCredits;
        credits[sender][2] = block.timestamp;

        for (uint8 i = 0; i < bundles[sender].length; i++) {
            if (newly == 0) {
                break;
            }
            uint256 unit = 1000**i;
            uint256 bundle = (newly % (unit * 1000)) / unit;
            bundles[sender][i] += bundle;
            newly -= bundle * unit;
        }
    }
}

//"SPDX-License-Identifier: MIT"
pragma solidity ^0.8.4;

interface IUniswapV2Router {
    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);
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

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
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