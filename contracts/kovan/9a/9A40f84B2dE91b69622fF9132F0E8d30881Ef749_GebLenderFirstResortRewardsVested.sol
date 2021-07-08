/**
 *Submitted for verification at Etherscan.io on 2021-07-08
*/

/// GebLenderFirstResortRewardsVested.sol

// Copyright (C) 2021 Reflexer Labs, INC
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.6.7;

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

    constructor () internal {
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

abstract contract TokenLike {
    function decimals() virtual public view returns (uint8);
    function totalSupply() virtual public view returns (uint256);
    function balanceOf(address) virtual public view returns (uint256);
    function mint(address, uint) virtual public;
    function burn(address, uint) virtual public;
    function approve(address, uint256) virtual external returns (bool);
    function transfer(address, uint256) virtual external returns (bool);
    function transferFrom(address,address,uint256) virtual external returns (bool);
}
abstract contract AuctionHouseLike {
    function activeStakedTokenAuctions() virtual public view returns (uint256);
    function startAuction(uint256, uint256) virtual external returns (uint256);
}
abstract contract AccountingEngineLike {
    function debtAuctionBidSize() virtual public view returns (uint256);
    function unqueuedUnauctionedDebt() virtual public view returns (uint256);
}
abstract contract SAFEEngineLike {
    function coinBalance(address) virtual public view returns (uint256);
    function debtBalance(address) virtual public view returns (uint256);
}
abstract contract RewardDripperLike {
    function dripReward() virtual external;
    function dripReward(address) virtual external;
    function rewardPerBlock() virtual external view returns (uint256);
    function rewardToken() virtual external view returns (TokenLike);
}
abstract contract StakingRewardsEscrowLike {
    function escrowRewards(address, uint256) virtual external;
}

// Stores tokens, owned by GebLenderFirstResortRewardsVested
contract TokenPool {
    TokenLike public token;
    address   public owner;

    constructor(address token_) public {
        token = TokenLike(token_);
        owner = msg.sender;
    }

    // @notice Transfers tokens from the pool (callable by owner only)
    function transfer(address to, uint256 wad) public returns (bool) {
        require(msg.sender == owner, "unauthorized");
        return token.transfer(to, wad);
    }

    // @notice Returns token balance of the pool
    function balance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }
}

contract GebLenderFirstResortRewardsVested is ReentrancyGuard {
    // --- Auth ---
    mapping (address => uint) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) virtual external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) virtual external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "GebLenderFirstResortRewardsVested/account-not-authorized");
        _;
    }

    // --- Structs ---
    struct ExitRequest {
        // Exit window deadline
        uint256 deadline;
        // Ancestor amount queued for exit
        uint256 lockedAmount;
    }

    // --- Variables ---
    // Flag that allows/blocks joining
    bool      public canJoin;
    // Flag that indicates whether canPrintProtocolTokens can ignore auctioning ancestor tokens
    bool      public bypassAuctions;
    // Whether the contract allows forced exits or not
    bool      public forcedExit;
    // Last block when a reward was pulled
    uint256   public lastRewardBlock;
    // The current delay enforced on an exit
    uint256   public exitDelay;
    // Min maount of ancestor tokens that must remain in the contract and not be auctioned
    uint256   public minStakedTokensToKeep;
    // Max number of auctions that can be active at a time
    uint256   public maxConcurrentAuctions;
    // Amount of ancestor tokens to auction at a time
    uint256   public tokensToAuction;
    // Initial amount of system coins to request in exchange for tokensToAuction
    uint256   public systemCoinsToRequest;
    // Amount of rewards per share accumulated (total, see rewardDebt for more info)
    uint256   public accTokensPerShare;
    // Balance of the rewards token in this contract since last update
    uint256   public rewardsBalance;
    // Staked Supply (== sum of all staked balances)
    uint256   public stakedSupply;
    // Percentage of claimed rewards that will be vested
    uint256   public percentageVested;
    // Whether the escrow is paused or not
    uint256   public escrowPaused;

    // Balances (not affected by slashing)
    mapping(address => uint256)    public descendantBalanceOf;
    // Exit data
    mapping(address => ExitRequest) public exitRequests;
    // The amount of tokens inneligible for claiming rewards (see formula below)
    mapping(address => uint256)    internal rewardDebt;
    // Pending reward = (descendant.balanceOf(user) * accTokensPerShare) - rewardDebt[user]

    // The token being deposited in the pool
    TokenPool                public ancestorPool;
    // The token used to pay rewards
    TokenPool                public rewardPool;
    // Descendant token
    TokenLike                public descendant;
    // Auction house for staked tokens
    AuctionHouseLike         public auctionHouse;
    // Accounting engine contract
    AccountingEngineLike     public accountingEngine;
    // The safe engine contract
    SAFEEngineLike           public safeEngine;
    // Contract that drips rewards
    RewardDripperLike        public rewardDripper;
    // Escrow for rewards
    StakingRewardsEscrowLike public escrow;

    // Max delay that can be enforced for an exit
    uint256 public immutable MAX_DELAY;

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event ModifyParameters(bytes32 indexed parameter, uint256 data);
    event ModifyParameters(bytes32 indexed parameter, address data);
    event ToggleJoin(bool canJoin);
    event ToggleBypassAuctions(bool bypassAuctions);
    event ToggleForcedExit(bool forcedExit);
    event AuctionAncestorTokens(address auctionHouse, uint256 amountAuctioned, uint256 amountRequested);
    event RequestExit(address indexed account, uint256 deadline, uint256 amount);
    event Join(address indexed account, uint256 price, uint256 amount);
    event Exit(address indexed account, uint256 price, uint256 amount);
    event RewardsPaid(address account, uint256 amount);
    event EscrowRewards(address escrow, address who, uint256 amount);
    event PoolUpdated(uint256 accTokensPerShare, uint256 stakedSupply);
    event FailEscrowRewards(bytes revertReason);

    constructor(
      address ancestor_,
      address descendant_,
      address rewardToken_,
      address auctionHouse_,
      address accountingEngine_,
      address safeEngine_,
      address rewardDripper_,
      address escrow_,
      uint256 maxDelay_,
      uint256 exitDelay_,
      uint256 minStakedTokensToKeep_,
      uint256 tokensToAuction_,
      uint256 systemCoinsToRequest_,
      uint256 percentageVested_
    ) public {
        require(maxDelay_ > 0, "GebLenderFirstResortRewardsVested/null-max-delay");
        require(exitDelay_ <= maxDelay_, "GebLenderFirstResortRewardsVested/invalid-exit-delay");
        require(minStakedTokensToKeep_ > 0, "GebLenderFirstResortRewardsVested/null-min-staked-tokens");
        require(tokensToAuction_ > 0, "GebLenderFirstResortRewardsVested/null-tokens-to-auction");
        require(systemCoinsToRequest_ > 0, "GebLenderFirstResortRewardsVested/null-sys-coins-to-request");
        require(auctionHouse_ != address(0), "GebLenderFirstResortRewardsVested/null-auction-house");
        require(accountingEngine_ != address(0), "GebLenderFirstResortRewardsVested/null-accounting-engine");
        require(safeEngine_ != address(0), "GebLenderFirstResortRewardsVested/null-safe-engine");
        require(rewardDripper_ != address(0), "GebLenderFirstResortRewardsVested/null-reward-dripper");
        require(escrow_ != address(0), "GebLenderFirstResortRewardsVested/null-escrow");
        require(percentageVested_ < 100, "GebLenderFirstResortRewardsVested/invalid-percentage-vested");
        require(descendant_ != address(0), "GebLenderFirstResortRewardsVested/null-descendant");

        authorizedAccounts[msg.sender] = 1;
        canJoin                        = true;
        maxConcurrentAuctions          = uint(-1);

        MAX_DELAY                      = maxDelay_;

        exitDelay                      = exitDelay_;

        minStakedTokensToKeep          = minStakedTokensToKeep_;
        tokensToAuction                = tokensToAuction_;
        systemCoinsToRequest           = systemCoinsToRequest_;
        percentageVested               = percentageVested_;

        auctionHouse                   = AuctionHouseLike(auctionHouse_);
        accountingEngine               = AccountingEngineLike(accountingEngine_);
        safeEngine                     = SAFEEngineLike(safeEngine_);
        rewardDripper                  = RewardDripperLike(rewardDripper_);
        escrow                         = StakingRewardsEscrowLike(escrow_);
        descendant                     = TokenLike(descendant_);

        ancestorPool                   = new TokenPool(ancestor_);
        rewardPool                     = new TokenPool(rewardToken_);

        lastRewardBlock                = block.number;

        require(ancestorPool.token().decimals() == 18, "GebLenderFirstResortRewardsVested/ancestor-decimal-mismatch");
        require(descendant.decimals() == 18, "GebLenderFirstResortRewardsVested/descendant-decimal-mismatch");

        emit AddAuthorization(msg.sender);
    }

    // --- Boolean Logic ---
    function both(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := and(x, y)}
    }
    function either(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := or(x, y)}
    }

    // --- Math ---
    uint256 public constant WAD = 10 ** 18;
    uint256 public constant RAY = 10 ** 27;

    function addition(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "GebLenderFirstResortRewardsVested/add-overflow");
    }
    function subtract(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "GebLenderFirstResortRewardsVested/sub-underflow");
    }
    function multiply(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "GebLenderFirstResortRewardsVested/mul-overflow");
    }
    function wdivide(uint x, uint y) internal pure returns (uint z) {
        require(y > 0, "GebLenderFirstResortRewardsVested/wdiv-by-zero");
        z = multiply(x, WAD) / y;
    }
    function wmultiply(uint x, uint y) internal pure returns (uint z) {
        z = multiply(x, y) / WAD;
    }

    // --- Administration ---
    /*
    * @notify Switch between allowing and disallowing joins
    */
    function toggleJoin() external isAuthorized {
        canJoin = !canJoin;
        emit ToggleJoin(canJoin);
    }
    /*
    * @notify Switch between ignoring and taking into account auctions in canPrintProtocolTokens
    */
    function toggleBypassAuctions() external isAuthorized {
        bypassAuctions = !bypassAuctions;
        emit ToggleBypassAuctions(bypassAuctions);
    }
    /*
    * @notify Switch between allowing exits when the system is underwater or blocking them
    */
    function toggleForcedExit() external isAuthorized {
        forcedExit = !forcedExit;
        emit ToggleForcedExit(forcedExit);
    }
    /*
    * @notify Modify an uint256 parameter
    * @param parameter The name of the parameter to modify
    * @param data New value for the parameter
    */
    function modifyParameters(bytes32 parameter, uint256 data) external isAuthorized {
        if (parameter == "exitDelay") {
          require(data <= MAX_DELAY, "GebLenderFirstResortRewardsVested/invalid-exit-delay");
          exitDelay = data;
        }
        else if (parameter == "minStakedTokensToKeep") {
          require(data > 0, "GebLenderFirstResortRewardsVested/null-min-staked-tokens");
          minStakedTokensToKeep = data;
        }
        else if (parameter == "tokensToAuction") {
          require(data > 0, "GebLenderFirstResortRewardsVested/invalid-tokens-to-auction");
          tokensToAuction = data;
        }
        else if (parameter == "systemCoinsToRequest") {
          require(data > 0, "GebLenderFirstResortRewardsVested/invalid-sys-coins-to-request");
          systemCoinsToRequest = data;
        }
        else if (parameter == "maxConcurrentAuctions") {
          require(data > 1, "GebLenderFirstResortRewardsVested/invalid-max-concurrent-auctions");
          maxConcurrentAuctions = data;
        }
        else if (parameter == "escrowPaused") {
          require(data <= 1, "GebLenderFirstResortRewardsVested/invalid-escrow-paused");
          escrowPaused = data;
        }
        else if (parameter == "percentageVested") {
          require(data < 100, "GebLenderFirstResortRewardsVested/invalid-percentage-vested");
          percentageVested = data;
        }
        else revert("GebLenderFirstResortRewardsVested/modify-unrecognized-param");
        emit ModifyParameters(parameter, data);
    }
    /*
    * @notify Modify an address parameter
    * @param parameter The name of the parameter to modify
    * @param data New value for the parameter
    */
    function modifyParameters(bytes32 parameter, address data) external isAuthorized {
        require(data != address(0), "GebLenderFirstResortRewardsVested/null-data");

        if (parameter == "auctionHouse") {
          auctionHouse = AuctionHouseLike(data);
        }
        else if (parameter == "accountingEngine") {
          accountingEngine = AccountingEngineLike(data);
        }
        else if (parameter == "rewardDripper") {
          rewardDripper = RewardDripperLike(data);
        }
        else if (parameter == "escrow") {
          escrow = StakingRewardsEscrowLike(data);
        }
        else revert("GebLenderFirstResortRewardsVested/modify-unrecognized-param");
        emit ModifyParameters(parameter, data);
    }

    // --- Getters ---
    /*
    * @notify Return the ancestor token balance for this contract
    */
    function depositedAncestor() public view returns (uint256) {
        return ancestorPool.balance();
    }
    /*
    * @notify Returns how many ancestor tokens are offered for one descendant token
    */
    function ancestorPerDescendant() public view returns (uint256) {
        return stakedSupply == 0 ? WAD : wdivide(depositedAncestor(), stakedSupply);
    }
    /*
    * @notify Returns how many descendant tokens are offered for one ancestor token
    */
    function descendantPerAncestor() public view returns (uint256) {
        return stakedSupply == 0 ? WAD : wdivide(stakedSupply, depositedAncestor());
    }
    /*
    * @notify Given a custom amount of ancestor tokens, it returns the corresponding amount of descendant tokens to mint when someone joins
    * @param wad The amount of ancestor tokens to compute the descendant tokens for
    */
    function joinPrice(uint256 wad) public view returns (uint256) {
        return wmultiply(wad, descendantPerAncestor());
    }
    /*
    * @notify Given a custom amount of descendant tokens, it returns the corresponding amount of ancestor tokens to send when someone exits
    * @param wad The amount of descendant tokens to compute the ancestor tokens for
    */
    function exitPrice(uint256 wad) public view returns (uint256) {
        return wmultiply(wad, ancestorPerDescendant());
    }

    /*
    * @notice Returns whether the protocol is underwater or not
    */
    function protocolUnderwater() public view returns (bool) {
        uint256 unqueuedUnauctionedDebt = accountingEngine.unqueuedUnauctionedDebt();

        return both(
          accountingEngine.debtAuctionBidSize() <= unqueuedUnauctionedDebt,
          safeEngine.coinBalance(address(accountingEngine)) < unqueuedUnauctionedDebt
        );
    }

    /*
    * @notice Burn descendant tokens in exchange for getting ancestor tokens from this contract
    * @return Whether the pool can auction ancestor tokens
    */
    function canAuctionTokens() public view returns (bool) {
        return both(
          both(protocolUnderwater(), addition(minStakedTokensToKeep, tokensToAuction) <= depositedAncestor()),
          auctionHouse.activeStakedTokenAuctions() < maxConcurrentAuctions
        );
    }

    /*
    * @notice Returns whether the system can mint new ancestor tokens
    */
    function canPrintProtocolTokens() public view returns (bool) {
        return both(
          !canAuctionTokens(),
          either(auctionHouse.activeStakedTokenAuctions() == 0, bypassAuctions)
        );
    }

    /*
    * @notice Returns unclaimed rewards for a given user
    */
    function pendingRewards(address user) public view returns (uint256) {
        uint accTokensPerShare_ = accTokensPerShare;
        if (block.number > lastRewardBlock && stakedSupply != 0) {
            uint increaseInBalance = (block.number - lastRewardBlock) * rewardDripper.rewardPerBlock();
            accTokensPerShare_ = addition(accTokensPerShare_, multiply(increaseInBalance, RAY) / stakedSupply);
        }
        return subtract(multiply(descendantBalanceOf[user], accTokensPerShare_) / RAY, rewardDebt[user]);
    }

    /*
    * @notice Returns rewards earned per block for each token deposited (WAD)
    */
    function rewardRate() public view returns (uint256) {
        return (rewardDripper.rewardPerBlock() * WAD) / stakedSupply;
    }

    // --- Core Logic ---
    /*
    * @notify Updates the pool and pays rewards (if any)
    * @dev Must be included in deposits and withdrawals
    */
    modifier payRewards() {
        updatePool();

        if (descendantBalanceOf[msg.sender] > 0 && rewardPool.balance() > 0) {
            // Pays the reward
            uint256 pending = subtract(multiply(descendantBalanceOf[msg.sender], accTokensPerShare) / RAY, rewardDebt[msg.sender]);

            uint256 vested;
            if (both(address(escrow) != address(0), escrowPaused == 0)) {
              vested = multiply(pending, percentageVested) / 100;

              try escrow.escrowRewards(msg.sender, vested) {
                rewardPool.transfer(address(escrow), vested);
                emit EscrowRewards(address(escrow), msg.sender, vested);
              } catch(bytes memory revertReason) {
                emit FailEscrowRewards(revertReason);
              }
            }

            rewardPool.transfer(msg.sender, subtract(pending, vested));
            rewardsBalance = rewardPool.balance();

            emit RewardsPaid(msg.sender, pending);
        }
        _;

        rewardDebt[msg.sender] = multiply(descendantBalanceOf[msg.sender], accTokensPerShare) / RAY;
    }

    /*
    * @notify Pays outstanding rewards to msg.sender
    */
    function getRewards() external nonReentrant payRewards {}

    /*
    * @notify Pull funds from the dripper
    */
    function pullFunds() public {
        rewardDripper.dripReward(address(rewardPool));
    }

    /*
    * @notify Updates pool data
    */
    function updatePool() public {
        if (block.number <= lastRewardBlock) return;
        lastRewardBlock = block.number;
        if (stakedSupply == 0) return;

        pullFunds();
        uint256 increaseInBalance = subtract(rewardPool.balance(), rewardsBalance);
        rewardsBalance = addition(rewardsBalance, increaseInBalance);

        // Updates distribution info
        accTokensPerShare = addition(accTokensPerShare, multiply(increaseInBalance, RAY) / stakedSupply);
        emit PoolUpdated(accTokensPerShare, stakedSupply);
    }

    /*
    * @notify Create a new auction that sells ancestor tokens in exchange for system coins
    */
    function auctionAncestorTokens() external nonReentrant {
        require(canAuctionTokens(), "GebLenderFirstResortRewardsVested/cannot-auction-tokens");

        ancestorPool.transfer(address(this), tokensToAuction);
        ancestorPool.token().approve(address(auctionHouse), tokensToAuction);
        auctionHouse.startAuction(tokensToAuction, systemCoinsToRequest);
        updatePool();

        emit AuctionAncestorTokens(address(auctionHouse), tokensToAuction, systemCoinsToRequest);
    }

    /*
    * @notify Join ancestor tokens
    * @param wad The amount of ancestor tokens to join
    */
    function join(uint256 wad) external nonReentrant payRewards {
        require(both(canJoin, !protocolUnderwater()), "GebLenderFirstResortRewardsVested/join-not-allowed");
        require(wad > 0, "GebLenderFirstResortRewardsVested/null-ancestor-to-join");
        uint256 price = joinPrice(wad);
        require(price > 0, "GebLenderFirstResortRewardsVested/null-join-price");

        require(ancestorPool.token().transferFrom(msg.sender, address(ancestorPool), wad), "GebLenderFirstResortRewardsVested/could-not-transfer-ancestor");
        descendant.mint(msg.sender, price);

        descendantBalanceOf[msg.sender] = addition(descendantBalanceOf[msg.sender], price);
        stakedSupply = addition(stakedSupply, price);

        emit Join(msg.sender, price, wad);
    }
    /*
    * @notice Request an exit for a specific amount of ancestor tokens
    * @param wad The amount of tokens to exit
    */
    function requestExit(uint wad) external nonReentrant payRewards {
        require(wad > 0, "GebLenderFirstResortRewardsVested/null-amount-to-exit");

        exitRequests[msg.sender].deadline      = addition(now, exitDelay);
        exitRequests[msg.sender].lockedAmount  = addition(exitRequests[msg.sender].lockedAmount, wad);

        descendantBalanceOf[msg.sender] = subtract(descendantBalanceOf[msg.sender], wad);
        descendant.burn(msg.sender, wad);

        emit RequestExit(msg.sender, exitRequests[msg.sender].deadline, wad);
    }
    /*
    * @notify Exit ancestor tokens
    */
    function exit() external nonReentrant {
        require(both(now >= exitRequests[msg.sender].deadline, exitRequests[msg.sender].lockedAmount > 0), "GebLenderFirstResortRewardsVested/wait-more");
        require(either(!protocolUnderwater(), forcedExit), "GebLenderFirstResortRewardsVested/exit-not-allowed");

        uint256 price = exitPrice(exitRequests[msg.sender].lockedAmount);
        stakedSupply  = subtract(stakedSupply, exitRequests[msg.sender].lockedAmount);
        require(ancestorPool.transfer(msg.sender, price), "GebLenderFirstResortRewardsVested/could-not-transfer-ancestor");
        emit Exit(msg.sender, price, exitRequests[msg.sender].lockedAmount);
        delete exitRequests[msg.sender];
    }
}