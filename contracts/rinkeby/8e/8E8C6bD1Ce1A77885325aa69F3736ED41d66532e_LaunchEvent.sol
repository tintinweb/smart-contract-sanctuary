// SPDX-License-Identifier: None

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "./interfaces/IJoeFactory.sol";
import "./interfaces/IJoePair.sol";
import "./interfaces/IJoeRouter02.sol";
import "./interfaces/IRocketJoeFactory.sol";
import "./interfaces/IRocketJoeToken.sol";
import "./interfaces/IWAVAX.sol";

/// @title Rocket Joe Launch Event
/// @author Trader Joe
/// @notice A liquidity launch contract enabling price discovery and token distribution at secondary market listing price
contract LaunchEvent is Ownable {
    /// @notice The phases the launch event can be in
    /// @dev Should these have more semantic names: Bid, Cancel, Withdraw
    enum Phase {
        NotStarted,
        PhaseOne,
        PhaseTwo,
        PhaseThree
    }

    struct UserInfo {
        /// @notice How much AVAX user can deposit for this launch event
        /// @dev Can be increased by burning more rJOE, but will always be
        /// smaller than `maxAllocation`
        uint256 allocation;
        /// @notice How much AVAX user has deposited for this launch event
        uint256 balance;
        /// @notice Whether user has withdrawn the LP
        bool hasWithdrawnPair;
        /// @notice Whether user has withdrawn the issuing token incentives
        bool hasWithdrawnIncentives;
    }

    /// @notice Issuer of sale tokens
    address public issuer;

    /// @notice The start time of phase 1
    uint256 public auctionStart;

    uint256 public PHASE_ONE_DURATION;
    uint256 public PHASE_ONE_NO_FEE_DURATION;
    uint256 public PHASE_TWO_DURATION;

    /// @dev Amount of tokens used as incentives for locking up LPs during phase 3,
    /// in parts per 1e18 and expressed as an additional percentage to the tokens for auction.
    /// E.g. if tokenIncentivesPercent = 5e16 (5%), and issuer sends 105 000 tokens,
    /// then 105 000 * 1e18 / (1e18 + 5e16) = 5 000 tokens are used for incentives
    uint256 public tokenIncentivesPercent;

    /// @notice Floor price in AVAX per token (can be 0)
    /// @dev floorPrice is scaled to 1e18
    uint256 public floorPrice;

    /// @notice Timelock duration post phase 3 when can user withdraw their LP tokens
    uint256 public userTimelock;

    /// @notice Timelock duration post phase 3 When can issuer withdraw their LP tokens
    uint256 public issuerTimelock;

    /// @notice The max withdraw penalty during phase 1, in parts per 1e18
    /// e.g. max penalty of 50% `maxWithdrawPenalty`= 5e17
    uint256 public maxWithdrawPenalty;

    /// @notice The fixed withdraw penalty during phase 2, in parts per 1e18
    /// e.g. fixed penalty of 20% `fixedWithdrawPenalty = 2e17`
    uint256 public fixedWithdrawPenalty;

    IRocketJoeToken public rJoe;
    uint256 public rJoePerAvax;
    IWAVAX private WAVAX;
    IERC20Metadata public token;

    IJoeRouter02 private router;
    IJoeFactory private factory;
    IRocketJoeFactory public rocketJoeFactory;

    bool private initialized;
    bool public stopped;

    uint256 public maxAllocation;

    mapping(address => UserInfo) public getUserInfo;

    /// @dev The address of the JoePair, set after createLiquidityPool is called
    IJoePair public pair;

    /// @dev The total amount of wavax that was sent to the router to create the initial liquidity pair.
    /// Used to calculate the amount of LP to send based on the user's participation in the launch event
    uint256 private wavaxAllocated;

    /// @dev The exact supply of LP minted when creating the initial liquidity pair.
    uint256 private lpSupply;

    /// @dev Used to know how many issuing tokens will be sent to JoeRouter to create the initial
    /// liquidity pair. If floor price is not met, we will send fewer issuing tokens and `tokenReserve`
    /// will keep track of the leftover amount. It's then used to calculate the number of tokens needed
    /// to be sent to both issuer and users (if there are leftovers and every token is sent to the pair,
    /// tokenReserve will be equal to 0)
    uint256 private tokenReserve;

    /// @dev Keeps track of amount of token incentives that needs to be kept by contract in order to send the right
    /// amounts to issuer and users
    uint256 private tokenIncentivesBalance;
    /// @dev Total incentives for users for locking their LPs for an additional period of time after the pair is created
    uint256 private tokenIncentivesForUsers;
    /// @dev The share refunded to the issuer. Users receive 5% of the token that were sent to the Router.
    /// If the floor price is not met, the incentives still needs to be 5% of the value sent to the Router, so there
    /// will be an excess of tokens returned to the issuer if he calls `withdrawIncentives()`
    uint256 private tokenIncentiveIssuerRefund;

    /// @dev wavaxReserve is the exact amount of WAVAX that needs to be kept inside the contract in order to send everyone's
    /// WAVAX. If there is some excess (because someone sent token directly to the contract), the
    /// penaltyCollector can collect the excess using `skim()`
    uint256 private wavaxReserve;

    event IssuingTokenDeposited(address indexed token, uint256 amount);

    event UserParticipated(
        address indexed user,
        uint256 avaxAmount,
        uint256 rJoeAmount
    );

    event UserWithdrawn(address indexed user, uint256 avaxAmount);

    event LiquidityPoolCreated(
        address indexed pair,
        address indexed token0,
        address indexed token1,
        uint256 amount0,
        uint256 amount1
    );

    event UserLiquidityWithdrawn(
        address indexed user,
        address indexed pair,
        uint256 amount
    );

    event IssuerLiquidityWithdrawn(
        address indexed issuer,
        address indexed pair,
        uint256 amount
    );

    event Stopped();

    event AvaxEmergencyWithdraw(address indexed user, uint256 amount);

    event TokenEmergencyWithdraw(address indexed user, uint256 amount);

    /// @notice Receive AVAX from the WAVAX contract
    /// @dev Needed for withdrawing from WAVAX contract
    receive() external payable {
        require(
            msg.sender == address(WAVAX),
            "LaunchEvent: you can't send AVAX directly to this contract"
        );
    }

    /// @notice Modifier which ensures contract is in a defined phase
    modifier atPhase(Phase _phase) {
        _atPhase(_phase);
        _;
    }

    /// @notice Modifier which ensures the caller's timelock to withdraw has elapsed
    modifier timelockElapsed() {
        uint256 phase3Start = auctionStart +
            PHASE_ONE_DURATION +
            PHASE_TWO_DURATION;
        require(
            block.timestamp > phase3Start + userTimelock,
            "LaunchEvent: can't withdraw before user's timelock"
        );
        if (msg.sender == issuer) {
            require(
                block.timestamp > phase3Start + issuerTimelock,
                "LaunchEvent: can't withdraw before issuer's timelock"
            );
        }
        _;
    }

    /// @notice Ensures launch event is stopped/running
    modifier isStopped(bool _stopped) {
        if (_stopped) {
            require(stopped, "LaunchEvent: is still running");
        } else {
            require(!stopped, "LaunchEvent: stopped");
        }
        _;
    }

    /// @notice Initialise the launch event with needed paramaters
    /// @param _issuer Address of the token issuer
    /// @param _auctionStart The start time of the auction
    /// @param _token The contract address of auctioned token
    /// @param _tokenIncentivesPercent The token incentives percent, in part per 1e18, e.g 5e16 is 5% of incentives
    /// @param _floorPrice The minimum price the token is sold at
    /// @param _maxWithdrawPenalty The max withdraw penalty during phase 1, in parts per 1e18
    /// @param _fixedWithdrawPenalty The fixed withdraw penalty during phase 2, in parts per 1e18
    /// @param _maxAllocation The maximum amount of AVAX depositable
    /// @param _userTimelock The time a user must wait after auction ends to withdraw liquidity
    /// @param _issuerTimelock The time the issuer must wait after auction ends to withdraw liquidity
    /// @dev This function is called by the factory immediately after it creates the contract instance
    function initialize(
        address _issuer,
        uint256 _auctionStart,
        address _token,
        uint256 _tokenIncentivesPercent,
        uint256 _floorPrice,
        uint256 _maxWithdrawPenalty,
        uint256 _fixedWithdrawPenalty,
        uint256 _maxAllocation,
        uint256 _userTimelock,
        uint256 _issuerTimelock
    ) external atPhase(Phase.NotStarted) {
        require(!initialized, "LaunchEvent: already initialized");

        rocketJoeFactory = IRocketJoeFactory(msg.sender);
        WAVAX = IWAVAX(rocketJoeFactory.wavax());
        router = IJoeRouter02(rocketJoeFactory.router());
        factory = IJoeFactory(rocketJoeFactory.factory());
        rJoe = IRocketJoeToken(rocketJoeFactory.rJoe());
        rJoePerAvax = rocketJoeFactory.rJoePerAvax();

        require(
            _maxWithdrawPenalty <= 5e17,
            "LaunchEvent: maxWithdrawPenalty too big"
        ); // 50%
        require(
            _fixedWithdrawPenalty <= 5e17,
            "LaunchEvent: fixedWithdrawPenalty too big"
        ); // 50%
        require(
            _userTimelock <= 7 days,
            "LaunchEvent: can't lock user LP for more than 7 days"
        );
        require(
            _issuerTimelock > _userTimelock,
            "LaunchEvent: issuer can't withdraw before users"
        );
        require(
            _auctionStart > block.timestamp,
            "LaunchEvent: start of phase 1 cannot be in the past"
        );

        issuer = _issuer;

        auctionStart = _auctionStart;
        PHASE_ONE_DURATION = rocketJoeFactory.PHASE_ONE_DURATION();
        PHASE_ONE_NO_FEE_DURATION = rocketJoeFactory.PHASE_ONE_NO_FEE_DURATION();
        PHASE_TWO_DURATION = rocketJoeFactory.PHASE_TWO_DURATION();

        token = IERC20Metadata(_token);
        uint256 balance = token.balanceOf(address(this));

        tokenIncentivesPercent = _tokenIncentivesPercent;

        /// We do this math because `tokenIncentivesForUsers + tokenReserve = tokenSent`
        /// and `tokenIncentivesForUsers = tokenReserve * 0.05` (i.e. incentives are 5% of reserves for issuing).
        /// E.g. if issuer sends 105e18 tokens, `tokenReserve = 100e18` and `tokenIncentives = 5e18`
        tokenReserve = (balance * 1e18) / (1e18 + _tokenIncentivesPercent);
        tokenIncentivesForUsers = balance - tokenReserve;
        tokenIncentivesBalance = tokenIncentivesForUsers;

        floorPrice = _floorPrice;

        maxWithdrawPenalty = _maxWithdrawPenalty;
        fixedWithdrawPenalty = _fixedWithdrawPenalty;

        maxAllocation = _maxAllocation;

        userTimelock = _userTimelock;
        issuerTimelock = _issuerTimelock;
        initialized = true;
    }

    /// @notice The current phase the auction is in
    function currentPhase() public view returns (Phase) {
        if (block.timestamp < auctionStart || auctionStart == 0) {
            return Phase.NotStarted;
        } else if (block.timestamp < auctionStart + PHASE_ONE_DURATION) {
            return Phase.PhaseOne;
        } else if (
            block.timestamp <
            auctionStart + PHASE_ONE_DURATION + PHASE_TWO_DURATION
        ) {
            return Phase.PhaseTwo;
        }
        return Phase.PhaseThree;
    }

    /// @notice Deposits AVAX and burns rJoe
    /// @dev Checks are done in the `_depositWAVAX` function
    function depositAVAX()
        external
        payable
        isStopped(false)
        atPhase(Phase.PhaseOne)
    {
        require(msg.sender != issuer, "LaunchEvent: issuer cannot participate");
        require(
            msg.value > 0,
            "LaunchEvent: expected non-zero AVAX to deposit"
        );

        UserInfo storage user = getUserInfo[msg.sender];
        uint256 newAllocation = user.balance + msg.value;
        require(
            newAllocation <= maxAllocation,
            "LaunchEvent: amount exceeds max allocation"
        );

        uint256 rJoeNeeded;
        // check if additional allocation is required.
        if (newAllocation > user.allocation) {
            // Burn tokens and update allocation.
            rJoeNeeded = getRJoeAmount(newAllocation - user.allocation);
            // Set allocation to the current balance as it's impossible
            // to buy more allocation without sending AVAX too
            user.allocation = newAllocation;
        }

        user.balance = newAllocation;
        wavaxReserve += msg.value;

        if (rJoeNeeded > 0) {
            rJoe.burnFrom(msg.sender, rJoeNeeded);
        }

        WAVAX.deposit{value: msg.value}();

        emit UserParticipated(msg.sender, msg.value, rJoeNeeded);
    }

    /// @notice Withdraw AVAX, only permitted during phase 1 and 2
    /// @param _amount The amount of AVAX to withdraw
    function withdrawAVAX(uint256 _amount) public isStopped(false) {
        Phase _currentPhase = currentPhase();
        require(
            _currentPhase == Phase.PhaseOne || _currentPhase == Phase.PhaseTwo,
            "LaunchEvent: unable to withdraw"
        );
        require(_amount > 0, "LaunchEvent: invalid withdraw amount");
        UserInfo storage user = getUserInfo[msg.sender];
        require(
            user.balance >= _amount,
            "LaunchEvent: withdrawn amount exceeds balance"
        );
        user.balance -= _amount;

        uint256 feeAmount = (_amount * getPenalty()) / 1e18;
        uint256 amountMinusFee = _amount - feeAmount;

        wavaxReserve -= _amount;

        WAVAX.withdraw(_amount);
        _safeTransferAVAX(msg.sender, amountMinusFee);
        if (feeAmount > 0) {
            _safeTransferAVAX(rocketJoeFactory.penaltyCollector(), feeAmount);
        }
    }

    /// @notice Create the JoePair
    /// @dev Can only be called once after phase 3 has started
    function createPair() external isStopped(false) atPhase(Phase.PhaseThree) {
        (address wavaxAddress, address tokenAddress) = (
            address(WAVAX),
            address(token)
        );
        require(
            factory.getPair(wavaxAddress, tokenAddress) == address(0),
            "LaunchEvent: pair already created"
        );
        require(wavaxReserve > 0, "LaunchEvent: no wavax balance");

        uint256 tokenAllocated = tokenReserve;

        // Adjust the amount of tokens sent to the pool if floor price not met
        if (floorPrice > (wavaxReserve * 1e18) / tokenAllocated) {
            tokenAllocated = (wavaxReserve * 10**token.decimals()) / floorPrice;
            tokenIncentivesForUsers =
                (tokenIncentivesForUsers * tokenAllocated) /
                tokenReserve;
            tokenIncentiveIssuerRefund =
                tokenIncentivesBalance -
                tokenIncentivesForUsers;
        }

        WAVAX.approve(address(router), wavaxReserve);
        token.approve(address(router), tokenAllocated);

        /// We can't trust the output cause of reflect tokens
        (, , lpSupply) = router.addLiquidity(
            wavaxAddress, // tokenA
            tokenAddress, // tokenB
            wavaxReserve, // amountADesired
            tokenAllocated, // amountBDesired
            wavaxReserve, // amountAMin
            tokenAllocated, // amountBMin
            address(this), // to
            block.timestamp // deadline
        );

        pair = IJoePair(factory.getPair(tokenAddress, wavaxAddress));
        wavaxAllocated = wavaxReserve;
        wavaxReserve = 0;

        tokenReserve -= tokenAllocated;

        emit LiquidityPoolCreated(
            address(pair),
            tokenAddress,
            wavaxAddress,
            tokenAllocated,
            wavaxAllocated
        );
    }

    /// @notice Withdraw liquidity pool tokens
    function withdrawLiquidity()
        external
        isStopped(false)
        atPhase(Phase.PhaseThree)
        timelockElapsed
    {
        require(address(pair) != address(0), "LaunchEvent: pair not created");

        UserInfo storage user = getUserInfo[msg.sender];
        require(
            !user.hasWithdrawnPair,
            "LaunchEvent: liquidity already withdrawn"
        );

        uint256 balance = pairBalance(msg.sender);
        user.hasWithdrawnPair = true;

        if (msg.sender == issuer) {
            balance = lpSupply / 2;

            emit IssuerLiquidityWithdrawn(msg.sender, address(pair), balance);

            if (tokenReserve > 0) {
                uint256 amount = tokenReserve;
                tokenReserve = 0;
                token.transfer(msg.sender, amount);
            }
        } else {
            emit UserLiquidityWithdrawn(msg.sender, address(pair), balance);
        }

        pair.transfer(msg.sender, balance);
    }

    /// @notice Withdraw incentives tokens
    function withdrawIncentives() external isStopped(false) {
        require(address(pair) != address(0), "LaunchEvent: pair not created");

        UserInfo storage user = getUserInfo[msg.sender];
        require(
            !user.hasWithdrawnIncentives,
            "LaunchEvent: incentives already withdrawn"
        );

        user.hasWithdrawnIncentives = true;
        uint256 amount;

        if (msg.sender == issuer) {
            amount = tokenIncentiveIssuerRefund;
        } else {
            amount = (user.balance * tokenIncentivesForUsers) / wavaxAllocated;
        }

        require(amount > 0, "LaunchEvent: caller has no incentive to claim");

        tokenIncentivesBalance -= amount;

        token.transfer(msg.sender, amount);
    }

    /// @notice Withdraw AVAX if launch has been cancelled
    function emergencyWithdraw() external isStopped(true) {
        if (msg.sender != issuer) {
            UserInfo storage user = getUserInfo[msg.sender];
            require(
                user.balance > 0,
                "LaunchEvent: expected user to have non-zero balance to perform emergency withdraw"
            );

            uint256 balance = user.balance;
            user.balance = 0;
            wavaxReserve -= balance;
            WAVAX.withdraw(balance);

            _safeTransferAVAX(msg.sender, balance);

            emit AvaxEmergencyWithdraw(msg.sender, balance);
        } else {
            uint256 balance = tokenReserve + tokenIncentivesBalance;
            tokenReserve = 0;
            tokenIncentivesBalance = 0;
            token.transfer(issuer, balance);
            emit TokenEmergencyWithdraw(msg.sender, balance);
        }
    }

    /// @notice Stops the launch event and allows participants withdraw deposits
    function allowEmergencyWithdraw() external {
        require(
            msg.sender == Ownable(address(rocketJoeFactory)).owner(),
            "LaunchEvent: caller is not RocketJoeFactory owner"
        );
        stopped = true;
        emit Stopped();
    }

    /// @notice Force balances to match tokens that were deposited, but not sent directly to the contract.
    /// Any excess tokens are sent to the penaltyCollector
    function skim() external {
        address penaltyCollector = rocketJoeFactory.penaltyCollector();

        uint256 excessToken = token.balanceOf(address(this)) -
            tokenReserve -
            tokenIncentivesBalance;
        if (excessToken > 0) {
            token.transfer(penaltyCollector, excessToken);
        }

        uint256 excessWavax = WAVAX.balanceOf(address(this)) - wavaxReserve;
        if (excessWavax > 0) {
            WAVAX.transfer(penaltyCollector, excessWavax);
        }

        uint256 excessAvax = address(this).balance;
        if (excessAvax > 0) _safeTransferAVAX(penaltyCollector, excessAvax);
    }

    /// @notice Returns the current penalty for early withdrawal
    /// @return The penalty to apply to a withdrawal amount
    function getPenalty() public view returns (uint256) {
        uint256 timeElapsed = block.timestamp - auctionStart;
        if (timeElapsed < PHASE_ONE_NO_FEE_DURATION) {
            return 0;
        } else if (timeElapsed < PHASE_ONE_DURATION) {
            return
                ((timeElapsed - PHASE_ONE_NO_FEE_DURATION) *
                    maxWithdrawPenalty) /
                uint256(PHASE_ONE_DURATION - PHASE_ONE_NO_FEE_DURATION);
        }
        return fixedWithdrawPenalty;
    }

    /// @notice Returns the current balance of the pool
    /// @return The balances of WAVAX and issued token held by the launch contract
    function getReserves() external view returns (uint256, uint256) {
        return (wavaxReserve, tokenReserve + tokenIncentivesBalance);
    }

    /// @notice Get the rJOE amount needed to deposit AVAX
    /// @param _avaxAmount The amount of AVAX to deposit
    /// @return The amount of rJOE needed
    function getRJoeAmount(uint256 _avaxAmount) public view returns (uint256) {
        return _avaxAmount * rJoePerAvax;
    }

    /// @notice The total amount of liquidity pool tokens the user can withdraw
    /// @param _user The address of the user to check
    function pairBalance(address _user) public view returns (uint256) {
        UserInfo memory user = getUserInfo[_user];
        if (wavaxAllocated == 0 || user.hasWithdrawnPair) {
            return 0;
        }
        return (user.balance * lpSupply) / wavaxAllocated / 2;
    }

    /// @dev Bytecode size optimization for the `atPhase` modifier.
    /// This works becuase internal functions are not in-lined in modifiers
    function _atPhase(Phase _phase) internal view {
        if (_phase == Phase.NotStarted) {
            require(
                currentPhase() == Phase.NotStarted,
                "LaunchEvent: not in not started"
            );
        } else if (_phase == Phase.PhaseOne) {
            require(
                currentPhase() == Phase.PhaseOne,
                "LaunchEvent: not in phase one"
            );
        } else if (_phase == Phase.PhaseTwo) {
            require(
                currentPhase() == Phase.PhaseTwo,
                "LaunchEvent: not in phase two"
            );
        } else if (_phase == Phase.PhaseThree) {
            require(
                currentPhase() == Phase.PhaseThree,
                "LaunchEvent: not in phase three"
            );
        } else {
            revert("LaunchEvent: unknown state");
        }
    }

    /// @notice Send AVAX
    /// @param _to The receiving address
    /// @param _value The amount of AVAX to send
    /// @dev Will revert on failure
    function _safeTransferAVAX(address _to, uint256 _value) internal {
        (bool success, ) = _to.call{value: _value}(new bytes(0));
        require(success, "LaunchEvent: avax transfer failed");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

interface IJoeFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    function setMigrator(address) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

interface IJoePair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

import "./IJoeRouter01.sol";

interface IJoeRouter02 is IJoeRouter01 {
    function removeLiquidityAVAXSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountAVAX);

    function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountAVAX);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

interface IRocketJoeFactory {
    event RJLaunchEventCreated(
        address indexed issuer,
        address indexed token,
        uint256 phaseOneStartTime,
        uint256 phaseTwoStartTime,
        uint256 phaseThreeStartTime,
        address rJoe,
        uint256 rJoePerAvax
    );
    event SetRJoe(address indexed token);
    event SetPenaltyCollector(address indexed collector);
    event SetRouter(address indexed router);
    event SetFactory(address indexed factory);
    event SetRJoePerAvax(uint256 rJoePerAvax);

    function eventImplementation() external view returns (address);

    function penaltyCollector() external view returns (address);

    function wavax() external view returns (address);

    function rJoePerAvax() external view returns (uint256);

    function router() external view returns (address);

    function factory() external view returns (address);

    function rJoe() external view returns (address);

    function PHASE_ONE_DURATION() external view returns (uint256);

    function PHASE_ONE_NO_FEE_DURATION() external view returns (uint256);

    function PHASE_TWO_DURATION() external view returns (uint256);

    function getRJLaunchEvent(address token)
        external
        view
        returns (address launchEvent);

    function isRJLaunchEvent(address token) external view returns (bool);

    function allRJLaunchEvents(uint256) external view returns (address pair);

    function numLaunchEvents() external view returns (uint256);

    function createRJLaunchEvent(
        address _issuer,
        uint256 _phaseOneStartTime,
        address _token,
        uint256 _tokenAmount,
        uint256 _tokenIncentivesPercent,
        uint256 _floorPrice,
        uint256 _maxWithdrawPenalty,
        uint256 _fixedWithdrawPenalty,
        uint256 _maxAllocation,
        uint256 _userTimelock,
        uint256 _issuerTimelock
    ) external returns (address pair);

    function setPenaltyCollector(address) external;

    function setRouter(address) external;

    function setFactory(address) external;

    function setRJoe(address) external;

    function setRJoePerAvax(uint256) external;

    function setPhaseDuration(uint256, uint256) external;

    function setPhaseOneNoFeeDuration(uint256) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IRocketJoeToken {
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
     * @dev Destroys `amount` tokens from `from`.
     *
     * See {ERC20-_burn}.
     */
    function burnFrom(address from, uint256 amount) external;

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

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

interface IWAVAX {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;

    function balanceOf(address account) external returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

interface IJoeRouter01 {
    function factory() external pure returns (address);

    function WAVAX() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityAVAX(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountAVAX,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAX(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAXWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function swapExactTokensForTokens(
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

    function swapExactAVAXForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactAVAX(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForAVAX(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapAVAXForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}