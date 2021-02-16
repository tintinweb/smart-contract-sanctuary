// SPDX-License-Identifier: Unlicense

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./Lists.sol";
import "./Rewards.sol";

/**
 * @title A Liquidity Game
 * @notice Implementation of a game which rewards the top half of liquidity providers.
 * 
 * Users interact with the contract through three public state-changing functions, which are different paths to the same goal:
 * lock Token-ETH LP tokens into the system, and track metrics around those LP locks.
 * 
 *   1. `provideLiquidity` accepts Tokens and ETH, and adds them to the Uniswap Pair, which creates fresh LP tokens
 *   2. `depositLP` accepts existing Token-ETH LP tokens
 *   3. `purchaseTokensAndDepositLP` accepts ETH, market buys a small amount of Tokens on Uniswap, then mints new Tokens,
 *      and finally adds Tokens and ETH to the Uniswap Pair, which creates fresh LP tokens
 * 
 * Each user has a score, which can only increase over time as they interact with the contract, because the only action is to
 * add more liquidity. A user's score is simply the total amount of LP tokens that they've locked into the system, via the
 * three functions listed above.
 * 
 * The system keeps track of two equally-sized, sorted lists. Each entry in the list contains a user's address and their current score.
 * Every time a score is created or updated, the lists are re-balanced and re-sorted. See `Lists.sol` for the implementation.
 * 
 * When the game is over, the system sucks as much liquidity out of the Uniswap Pair as possible, and then distributes the 
 * collected Ether to all participants. The amount of Ether reward that any given user receives is dependent on a few factors:
 *
 *   1. how much liquidity they've added to the system
 *   2. how much liquidity everyone else has added to the system
 *   3. which list they're on ("top half of all scores" list, or "bottom half of all scores" list)
 * 
 * At a high level, this is how the rewards are collected (liquidity is removed):
 * 
 *   1. Call Uniswap Router's `removeLiquidityETH` with all of the LP tokens that this system controls, sending all
 *      rewards (Tokens and Ether) back here.
 *   2. For all of the Tokens that now belong to the system, call Uniswap Router's `swapExactTokensForETH`, which
 *      forces out more ETH that may have existed in liquidity (due to people manually adding liquidity and not
 *      playing this game).
 *   3. Now the system contains a bag of Ether, which are used for rewards.
 * 
 * At a high level, calculating the rewards for any given user at any given time works like this:
 * 
 *   1. If the game is not over, then the reward calculation logic "pretends" that the game is ending at that moment,
 *      and performs read-only logic on the above process. So, from the point of view of the caller, it makes no difference
 *      if the game is over or not when calculating rewards for an account. The only difference is that DURING gameplay,
 *      a user's calculated rewared will change every time score state changes, but once the game is over a user's rewards
 *      become fixed. So, we can assume we know the "total Ether for rewards" for the rest of this calculation.
 *   2. Initially, the Total Ether Rewards are split between the "winning list" and the "losing list" (denoted in code as
 *      "positive list" and "negative list"). That initial split is completely determined by the relative total scores of
 *      the two lists. For example, if the sum of all scores in the Positive List is 70, and the sum of all scores in the
 *      Negative List is 30, (total score of 100 between the two lists) and the total Ether rewards are 10 ETH, then
 *      70 / 100 * 10 ETH = 7 ETH belong to the Positive List and 30 / 100 * 10 ETH = 3 ETH belong to the Negative List.
 *   3. Next, an owner-defined percentage of the Negative List rewards is TAKEN from the Negative List and GIVEN to the
 *      Positive List. For example (continuing from above example), if that owner-defined percentage is 50%, then
 *      3 ETH * 0.5 = 1.5 ETH will be subtracted from the Negative List (leaving that list with 3 ETH - 1.5 ETH = 1.5 ETH),
 *      and added to the Positive List (leaving that list with 7 ETH + 1.5 ETH = 8.5 ETH).
 *   4. Finally, a user's reward is calculated as their percentage of their lists's total score, multiplied by the rewards
 *      that belong to that list. For example (continuing from the above example), if a user is on the Positive List with a
 *      score of 14, then they account for 14 / 70 = 20% of that list, so they'll receive 8.5 ETH * 0.2 = 1.7 ETH as reward.
 *      If a user is on the Negative List with a score of 3, then they account for 3 / 30 = 10% of that list, so they'll
 *      receive 1.5 ETH * 0.1 = 0.15 ETH as reward.
 *
 * @dev Inherits from the `Lists` contract, which houses all implementation of the two weighted, sorted list management
 */
contract Game is Lists, ERC20, Ownable {
    using SafeMath for uint256;

    uint256 constant MAX_MARKET_PURCHASE = 10**18 / 2; // 50%

    /**
     * @notice The timestamp at which the game is over. No more score-increasing functions are callable after this time.
     */
    uint256 public immutable endTime;

    bool private _distributed;
    uint256 private _totalRewards;

    /**
     * @notice Tracks whether or not an account has claimed their rewards.
     */
    mapping(address => bool) public claimedRewards;

    /**
     * @notice Addresses of the Uniswap Factory and Router
     */
    IUniswapV2Factory public immutable uniswapV2Factory;
    IUniswapV2Router02 public immutable uniswapV2Router;

    // Used to calculate the fraction of rewards that are taken from the negative list, and given to positive list
    // Note: the "_negativeWeight" value is used as the numerator in a calculation with the denominator equaling 10e18
    uint256 private _negativeWeight;

    // Used to determine how much input Ether is used to market-buy Token on Uniswap
    // Note: the "marketPurchase" value is used as the numerator in a calculation with the denominator equaling 10e18
    uint256 public marketPurchase;

    /**
     * @notice Instance of the contract where all value (ETH / Tokens) is held
     */
    Rewards public rewards;

    // Minimum acceptable values for deposit
    uint256 public minEthers;
    uint256 public minLpTokens;

    event ProvidedLiquidity(address indexed account, address indexed forAccount, uint256 scoreIncrease, uint256 newScore, uint256 newPayout);
    event DepositedLP(address indexed account, address indexed forAccount, uint256 scoreIncrease, uint256 newScore, uint256 newPayout);
    event PurchasedGameTokensAndDepositedLP(address indexed account, address indexed forAccount, uint256 scoreIncrease, uint256 newScore, uint256 newPayout);
    event SplitAdjusted(uint256 newNegativeWeight);
    event MarketPurchaseAdjusted(uint256 newMarketPurchase);
    event MinEthersAdjusted(uint256 newMinEthers);
    event MinLpTokensAdjusted(uint256 newMinLpTokens);

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialMint,
        address mintOwner,
        IUniswapV2Router02 _uniswapV2Router,
        uint256 _endTime,
        uint256 negativeWeight,
        uint256 _marketPurchase,
        uint256 _minEthers,
        uint256 _minLpTokens
    ) ERC20(_name, _symbol) {
        require(marketPurchase <= MAX_MARKET_PURCHASE, "Game: attemping to set purchase percentage > 50%");
        require(negativeWeight <= 10**18, "Game: attemping to set split weigth > 100%");
        require(_endTime > block.timestamp, "Game: attemping to set endTime value less than or equal to now");

        // mint the initial set of tokens
        _mint(mintOwner, _initialMint * (uint256(10)**decimals()));

        // save (and derive) the uniswap router and factory addresses
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Factory = IUniswapV2Factory(_uniswapV2Router.factory());

        // save the rest of the initial contract state variables
        endTime = _endTime;
        _negativeWeight = negativeWeight;
        marketPurchase = _marketPurchase;

        // deploy an instance of the Rewards contract, making this contract it's "owner"
        rewards = new Rewards(address(this), _uniswapV2Router, _endTime);

        minEthers = _minEthers;
        minLpTokens = _minLpTokens;

        // MAX_UINT256 approval
        _approve(address(rewards), address(_uniswapV2Router), 2**256 - 1); 
    }

    /**
     * @notice reverts if there is not yet an existing Uniswap pair for this Token and Ether
     */
    modifier pairExists() {
        require(getUniswapPair() != address(0), "Game::pairExists: pair has not been created");
        _;
    }

    /**
     * @notice reverts if the endTime has passed, which indicates that the game is over
     */
    modifier active() {
        require(endTime > block.timestamp, "Game::active: game is over! distribute and claim your rewards");
        _;
    }

    /**
     * @notice reverts if the endTime has not passed, which indicates that the game is still being played
     */
    modifier over() {
        require(endTime <= block.timestamp, "Game::over: game is still active");
        _;
    }

    /**
     * @notice Accept any amount of Token and Ether, add as much liquidity to Uniswap as possible, refund any leftovers
     * @param tokenAmount the amount of Tokens to attempt to add as liquidity
     * @param account the account which should receive points
     * @dev Payable function accepts Ether input, will attempt to add all of it as liquidity
     * @dev Requires that the user has previously `approve`d Token transfers for this contract
     * @return scoreIncrease the delta between an account's old score, and their score after this function is complete
     * @return newScore the account's new score, after increasing it
     * @return newPayout the account's new payout amount
     */
    function provideLiquidity(uint256 tokenAmount, address account) pairExists active public payable returns (uint256 scoreIncrease, uint256 newScore, uint256 newPayout) {
        // send `tokenAmount` number of tokens from msg.sender to the `rewards` contract
        _transfer(msg.sender, address(rewards), tokenAmount);

        // add as much liquidity to Uniswap Pair as possible
        // function returns with the actual amount of Tokens and Eth added, since it safely adds liquidity at the current price ratio
        // the `addLiquidityETH` call is proxied to the `rewards` contract, which is where the new LP tokens will belong to
        (uint256 amountTokenAdded, uint256 amountEthAdded, uint256 liquidity) = rewards.addLiquidityETH{ value: msg.value }(tokenAmount);

        // since there will likely be a small amount of either Tokens or Ether leftover, refund that back to the msg.sender
        refund(msg.sender, tokenAmount, msg.value, amountTokenAdded, amountEthAdded);

        // an account's score is directly calculated by the amount of liquidity tokens they've created for the game
        scoreIncrease = liquidity;
        newScore = addScore(account, scoreIncrease);

        // get the updated reward payout information for the account
        newPayout = getAccountRewards(account);

        emit ProvidedLiquidity(msg.sender, account, scoreIncrease, newScore, newPayout);
    }

    /**
     * @notice Accept any amount of Uniswap Token-ETH LP tokens
     * @param tokenAmount the amount of Uniswap Token-ETH LP tokens to take control of
     * @param account the account which should receive points
     * @dev Requires that the user has `approve`d this contract to be able to spend their Uniswap Token-ETH LP tokens
     * @return scoreIncrease the delta between an account's old score, and their score after this function is complete
     * @return newScore the account's new score, after increasing it
     * @return newPayout the account's new payout amount
     */
    function depositLP(uint256 tokenAmount, address account) pairExists active public returns (uint256 scoreIncrease, uint256 newScore, uint256 newPayout) {
        require(tokenAmount >= minLpTokens, "Game::depositLP: LP token amount below minimum");

        // grab the Uniswap pair address and cast it into an IUniswapV2Pair instance...
        IUniswapV2Pair pair = IUniswapV2Pair(getUniswapPair());
        // ...so that we can `transferFrom` the tokens to the `rewards` contract
        pair.transferFrom(msg.sender, address(rewards), tokenAmount);

        // an account's score is directly calculated by the amount of liquidity tokens they've given to the game
        scoreIncrease = tokenAmount;
        newScore = addScore(account, scoreIncrease);

        // get the updated reward payout information for the account
        newPayout = getAccountRewards(account);

        emit DepositedLP(msg.sender, account, scoreIncrease, newScore, newPayout);
    }

    /**
     * @notice Accept any amount of Ether, market buy some Tokens, mint more Tokens, add liquidity
     * @param account the account which should receive points
     * @param minTokensToPurchased The minimum amount of GAME tokens that must be received from the ETH->GAME purchase
     * @dev Payable function accepts Ether input
     * @return scoreIncrease the delta between an account's old score, and their score after this function is complete
     * @return newScore the account's new score, after increasing it
     * @return newPayout the account's new payout amount
     */
    function purchaseTokensAndDepositLP(address account, uint256 minTokensToPurchased) pairExists active public payable returns (uint256 scoreIncrease, uint256 newScore, uint256 newPayout) {
        require(msg.value >= minEthers, "Game::purchaseTokensAndDepositLP: ETH amount below minimum");

        // of the Ether passed in, calculate a small piece of it to be used for market buying tokens on Uniswap
        // we do this beacuse we want to have the optics of continued market buying
        uint256 ethForMarket = msg.value.mul(marketPurchase).div(10**18);
        uint256 ethForLiquidity = msg.value.sub(ethForMarket);

        // use the Ether reserved for the market buy, to do a market buy
        // hold onto the number of tokens that were purchased
        // these tokens that were purchased, belong to the `rewards` contract
        uint256 tokensPurchased = rewards.swapExactETHForTokens{ value: ethForMarket }(minTokensToPurchased);

        // get a quote for the number of tokens that are currently "equivalent" to the remaining Ether
        IUniswapV2Pair pair = IUniswapV2Pair(getUniswapPair());
        (uint112 _reserve0, uint112 _reserve1,) = pair.getReserves();
        uint256 tokensForLiquidity = uniswapV2Router.quote(
            ethForLiquidity,
            pair.token0() == uniswapV2Router.WETH() ? _reserve0 : _reserve1,
            pair.token1() == uniswapV2Router.WETH() ? _reserve0 : _reserve1
        );

        // calculate the "difference" -- that is, the amount of tokens that the `rewards` contract needs
        // which are equal to the token number we just calculated
        if (tokensForLiquidity > tokensPurchased) {
            // (stack too deep, so did an inline calculation to determine `tokensToMint`, the second argument of _mint)
            // mint those tokens and give them to the `rewards` contract (which also contains the Tokens received from the above swap)
            _mint(address(rewards), tokensForLiquidity.sub(tokensPurchased));
        } else if (tokensForLiquidity < tokensPurchased) {
            // Use `tokensPurchased` for liquidity if it's greater than `tokensForLiquidity`
            tokensForLiquidity = tokensPurchased;
        }

        // add as much liquidity to Uniswap Pair as possible
        // function returns with the actual amount of Tokens and Eth added, since it safely adds liquidity at the current price ratio
        // the `addLiquidityETH` call is proxied to the `rewards` contract, which is where the new LP tokens will belong to
        (uint256 amountTokenAdded, uint256 amountEthAdded, uint256 liquidity) = rewards.addLiquidityETH{ value: ethForLiquidity }(tokensForLiquidity);

        // since there will likely be a small amount of either Tokens or Ether leftover, refund that back to the msg.sender
        refund(msg.sender, tokensForLiquidity, ethForLiquidity, amountTokenAdded, amountEthAdded);

        // an account's score is directly calculated by the amount of liquidity tokens they've created for the game
        scoreIncrease = liquidity;
        newScore = addScore(account, scoreIncrease);

        // get the updated reward payout information for the account
        newPayout = getAccountRewards(account);

        emit PurchasedGameTokensAndDepositedLP(msg.sender, account, scoreIncrease, newScore, newPayout);
    }

    /**
     * @notice Perform simple subtractions to determine if there is any leftover Tokens and Ether, and transfers that value to the specified account
     * @dev The SafeMath subtractions in here are safe, since it's not possible for `amount...Added` to be greater than `...amount`
     * @dev There is an assumption that this function is called after adding liquidity, and not all of the input value was used
     * @param to the account to send refunded Tokens or Ether to
     * @param tokenAmount the amount of Tokens that were attempted to be added to liquidity
     * @param ethAmount the amount of Ether that were attempted to be added to liquidity
     * @param amountTokenAdded the amount of Tokens that were actually added to liquidity
     * @param amountEthAdded the amount of Ether that were actually added to liquidity
     */    
    function refund(address payable to, uint256 tokenAmount, uint256 ethAmount, uint256 amountTokenAdded, uint256 amountEthAdded) private {
        // calculate if there is any "leftover" Tokens
        uint256 leftoverToken = tokenAmount.sub(amountTokenAdded);
        if (leftoverToken > 0) {
            // transfer the leftover Tokens from the `rewards` contract (where they exist) to `to`
            _transfer(address(rewards), to, leftoverToken);
        }

        // calculate if there is any "leftover" Ether
        uint256 leftoverEth = ethAmount.sub(amountEthAdded);
        if (leftoverEth > 0) {
            // transfer the leftover Ether from the `rewards` contract (where they exist) to `to`
            rewards.sendEther(to, leftoverEth);
        }
    }

    /**
     * @notice Executed one time, by anyone, only after the game is over
     * @dev Does everything it can do to suck all liquidity out of Uniswap, which is then used as rewards for users
     */
    function distribute() over public {
        // revert if this function has already been called (see last line in this function)
        require(_distributed == false, "Game::distribute: rewards have already been distributed");
        
        // set the flag which will cause this function to revert if called a second time
        _distributed = true;

        // grab the Uniswap Token-ETH pair
        IUniswapV2Pair pair = IUniswapV2Pair(getUniswapPair());

        // if any Uniswap Token-ETH LP tokens exist on this contract (accidently sent), send them to the `rewards` contract
        uint256 myLPBalance = pair.balanceOf(address(this));
        if (myLPBalance > 0) {
            pair.transfer(address(rewards), myLPBalance);
        }

        // get the Token-ETH LP token balance of `rewards`, and remove all of that liquidity
        // the resultant Ether and Tokens will belong to the `rewards` contract
        uint256 liquidityBalance = pair.balanceOf(address(rewards));
        rewards.removeLiquidityETH(pair, liquidityBalance);

        // if any Tokens belong to this contract, send them to the `rewards` contract
        uint256 myTokenBalance = balanceOf(address(this));
        if (myTokenBalance > 0) {
            _transfer(address(this), address(rewards), myTokenBalance);
        }

        // get the Tokens balance of the `rewards` contract
        uint256 rewardsTokenBalance = balanceOf(address(rewards));

        // swap all of the `rewards` contract's Token balance into any more Ether that might be in the Uniswap pair
        rewards.swapExactTokensForETH(rewardsTokenBalance);

        // store the Ether balance of the `rewards` contract, so that we can calulcate individual rewards later
        _totalRewards = address(rewards).balance;
    }

    /**
     * @notice Allows an account to claim their rewards, after the game is over
     * @param account the address which has Ether to claim
     */
    function claim(address payable account) over external {
        // helper logic -- if the game is over and someone is attemping to claim rewards,
        // but `distribute` has not yet been called, then call it
        if (!_distributed) {
            distribute();
        }

        // revert if the given account has already claimed their rewards
        require(claimedRewards[account] == false, "Game::claim: this account has already claimed rewards");

        // set the flag indicating that rewards have been claimed for the given account
        claimedRewards[account] = true;

        // get the amount of Ether rewards for the given account
        uint256 accountRewards = getAccountRewards(account);

        // send those Ether rewards to the account, proxied through the `rewards` contract
        // which is where the Ether resides
        rewards.sendEther(account, accountRewards);
    }

    /**
     * @notice Get the total amount of rewards that the game is paying out.
     * @return the total amount of rewards that the game is paying out.
     * @dev If the game is over, the rewards are known and static
     * @dev If the game is ongoing, we can calculate what the rewards will be if the game ended right now.
     */
    function getTotalRewards() public view returns (uint256) {
        // if the game is over and we've sucked liquidity and distributed Ether to the `rewards` contract,
        // then we know the total amount of rewards already.
        if (_distributed) {
            return _totalRewards;
        }

        // if a pair hasn't been created yet, (contract was deployed but game is not fully set up),
        // return 0
        IUniswapV2Pair pair = IUniswapV2Pair(getUniswapPair());
        if (address(pair) == address(0)) {
            return 0;
        }

        // if there is no liquidity in the Uniswap Token-ETH pool, return 0
        uint256 totalLpSupply = pair.totalSupply();
        if (totalLpSupply == 0) {
            return 0;
        }

        // otherwise, calculate how much Ether we'd be able to suck out of the pool right now (but don't do it)

        // figure out how much Ether and how much Tokens exist in the pair pools
        (uint112 _reserve0, uint112 _reserve1,) = pair.getReserves();
        uint256 wethReserves = pair.token0() == uniswapV2Router.WETH() ? _reserve0 : _reserve1;
        uint256 gameTokenReserves = pair.token1() == uniswapV2Router.WETH() ? _reserve0 : _reserve1;

        // figure out the "percentage" (solidity, lol) of LP tokens that the `rewards` contract holds
        uint256 rewardsLpShare = (pair.balanceOf(address(rewards)).add(pair.balanceOf(address(this)))).mul(10**18).div(totalLpSupply);

        // use that percentage to calculate how much Tokens and Eth from the pools that the `rewards` contract _doesn't_ "control"
        uint256 pairWethRemaining = wethReserves.sub(rewardsLpShare.mul(wethReserves).div(10**18));
        uint256 pairGameTokenRemaining = gameTokenReserves.sub(rewardsLpShare.mul(gameTokenReserves).div(10**18));

        // calculate how many Tokens the `rewards` contract "controls" (both from liquidity, and that it directly owns,
        // and also include Tokens that this contract owns because during distribution we'll send those to `rewards` if they exist)
        uint256 rewardsGameTokenTotal = gameTokenReserves.sub(pairGameTokenRemaining).add(balanceOf(address(rewards))).add(balanceOf(address(this)));
        
        // if any of our main variables are 0, return 0, otherwise `getAmountsOut` will revert
        if (rewardsGameTokenTotal == 0 || pairGameTokenRemaining == 0 || pairWethRemaining == 0) {
            return 0;
        }

        // Use Uniswap's `getAmountOut` to figure out how much Ether we'd get if we attempted to swap all of our controlled
        // Tokens for the Ether in the contract, "after pulling liquidity". Then, add in the Ether that we would have pulled
        // from liquidity initially. Then, add in any Ether that the `rewards` contract currently has.
        // Return it.
        return uniswapV2Router.getAmountOut(rewardsGameTokenTotal, pairGameTokenRemaining, pairWethRemaining).add(wethReserves.sub(pairWethRemaining)).add(address(rewards).balance);
    }

    /**
     * @notice Get the total amount of Ether rewards that belong to (will be distributed to) the negative (losing) list
     * @return etherAmount the amount of Ether that belongs to the negative list
     */
    function getNegativeRewards() public view returns (uint256 etherAmount) {
        // get the total score, which is the sum of the scores of the two lists
        uint256 totalScore = getPositiveListTotalScore().add(getNegativeListTotalScore());

        // if the total score is 0, then there are no players, and early exit with 0
        if (totalScore == 0) {
            etherAmount = 0;
        } else {
            // how much of the total score, does the negative list contribute
            uint256 negativePercentage = getNegativeListTotalScore().mul(10**18).div(totalScore);

            // of that correctly-weighted percentage, reduce it by our defined factor
            // THIS IS WHERE THE WINNERS WIN, AND THE LOSERS LOSE
            uint256 negativeSlice = negativePercentage.mul(_negativeWeight).div(10**18);

            // calculate the negative list rewards by taking newly calculated "negative slice" fraction of the total rewards
            etherAmount = getTotalRewards().mul(negativeSlice).div(10**18);
        }
    }

    /**
     * @notice Get the total amount of Ether rewards that belong to (will be distributed to) the positive (winning) list
     * @return etherAmount the amount of Ether that belongs to the positive list
     */
    function getPositiveRewards() public view returns (uint256 etherAmount) {
        // get the total amount of Ether rewards
        uint256 totalRewards = getTotalRewards();

        // get the amount of rewards that belong to the negative list
        uint negativeRewards = getNegativeRewards();

        // the positive list rewards is then total minus negative
        etherAmount = totalRewards.sub(negativeRewards);
    }

    /**
     * @notice Given an account, returns the rewards that account will receive at any given moment, if the game ended at that moment
     * @param account the address of the account that we're interested in
     * @return etherAmount the amount of Ether which will be rewarded to the account
     */
    function getAccountRewards(address account) public view returns (uint256 etherAmount) {
        // check if the account is on the positive list or the negative list or neither
        if (getIsOnPositive(account)) {
            // an account's score is calculated as their score percentage of their list's total reward
            etherAmount = getAccountScore(account).mul(getPositiveRewards()).div(getPositiveListTotalScore());
        } else if (getIsOnNegative(account)) {
            // an account's score is calculated as their score percentage of their list's total reward
            etherAmount = getAccountScore(account).mul(getNegativeRewards()).div(getNegativeListTotalScore());
        } else {
            // if this account isn't on either list (they haven't played), return 0
            etherAmount = 0;
        }
    }

    /**
     * @notice Get the address of the Uniswap Token-ETH pair contract
     * @return pair the address of the Uniswap Token-ETH pair contract, returns 0x0 if the pair hasn't yet been created
     */
    function getUniswapPair() public view returns (address pair) {
        pair = uniswapV2Factory.getPair(address(this), uniswapV2Router.WETH());
    }

    /**
     * @notice Owner function to recover any unclaimed Ether, only callable once 90 days have passed since the game ended
     * @param to address to send the Ether to
     * @param amount the amount of Ether to send
     * @dev this call is proxied to the `rewards` contract, since that's where the Ether lives
     */
    function recoverEther(address payable to, uint256 amount) onlyOwner public {
        // revert if the game hasn't been over for at least 90 days
        require(block.timestamp > endTime.add(90 days), "Game::recoverEther: it has not been 90 days since the game ended");

        // proxy the call down to the `rewards` contract
        rewards.sendEther(to, amount);
    }

    /**
     * @notice Owner function to recover any token held by the Game and/or Rewards contracts, only callable once 90 days have passed since the game ended
     * @param to address to send the tokens to
     */
    function recoverToken(address token, address to) onlyOwner public {
        // revert if the game hasn't been over for at least 90 days
        require(block.timestamp > endTime.add(90 days), "Game::recoverToken: it has not been 90 days since the game ended");

        // Drain tokens from Rewards contract (if there is any)
        rewards.recoverToken(token);

        uint256 myBalance = IERC20(token).balanceOf(address(this));
        if (myBalance > 0) {
            IERC20(token).transfer(to, myBalance);
        }
    }

    /**
     * @notice Owner function to adjust the numbers used to calculate how much reward to "take" from the losing list (negative) and "give" to the winning list (positive)
     * @dev Only executable while the game is active
     * @param negativeWeight a multiplier number
     */
    function adjustSplitWeight(uint256 negativeWeight) active onlyOwner public {
        require(negativeWeight <= 10**18, "Game::adjustSplitWeight: attemping to set split weigth > 100%");

        _negativeWeight = negativeWeight;

        emit SplitAdjusted(negativeWeight);
    }

    /**
     * @notice Owner function to adjust the numbers used to calculate how much of the input Ether to `purchaseTokensAndDepositLP` will be used for market buying Tokens on Uniswap.
     * @dev if the number is above "50%", a subtraction underflow occurs and reverts the public function, so check for that here when setting the values
     * @param _marketPurchase a multiplier number
     */
    function adjustMarketPurchase(uint256 _marketPurchase) onlyOwner public {
        // revert if the input number is less than half of our constant divisor
        require(_marketPurchase <= MAX_MARKET_PURCHASE, "Game::adjustMarketPurchase: attemping to set purchase percentage > 50%");
        marketPurchase = _marketPurchase;

        emit MarketPurchaseAdjusted(_marketPurchase);
    }

    /**
     * @notice Owner function to adjust the min Ethers accepted to deposit
     * @dev Only executable while the game is active
     * @param _minEthers a multiplier number
     */
    function adjustMinEthers(uint256 _minEthers) active onlyOwner public {
        minEthers = _minEthers;

        emit MinEthersAdjusted(minEthers);
    }

    /**
     * @notice Owner function to adjust the min LP tokens accepted to deposit
     * @dev Only executable while the game is active
     * @param _minLpTokens a multiplier number
     */
    function adjustMinLpTokens(uint256 _minLpTokens) active onlyOwner public {
        minLpTokens = _minLpTokens;

        emit MinLpTokensAdjusted(minLpTokens);
    }
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "solidity-linked-list/contracts/StructuredLinkedList.sol";

/**
 * @title Lists implements two equal length, sorted lists
 * @notice This contract has a single "internal" (to be called from an inheriting contract) state-changing function, which accepts an account and a score.
 * The implementation details deal with either adding this account to the correct list, in the correct spot, if it's a new account
 * OR increasing the score of the account, and making sure it ends up in the correct list, in the correct spot, if the account is already on a list.
 * The two lists will always either have equal length, or the "positive" list will have a length one greater than the "negative" list.
 * The two lists will always be sorted (descending), according the account's score. Each entry in each list is effectively a tuple of (account, score).
 * The last score of the "postive" list will always be >= the first score of the "negative" list.
 * A plethora of public view functions expose various details about accounts, scores, and lists.
 * @dev We leverage a StructuredLinkedList library to achieve the sorted lists.
 */
contract Lists {
    using SafeMath for uint256;
    using StructuredLinkedList for StructuredLinkedList.List;

    // mapping of accounts, to their total current scores
    mapping(address => uint256) private _accountScores;
    
    // mapping of accounts, to a boolean indicating if they exist on the "positive" list
    mapping(address => bool) private _accountOnPositive;

    // this block of variables is everything needed to track one list (the "positive" list)
    uint256 private _positiveTicker; // unique node id incrementer (each item in the list stored as a simple integer)
    mapping(uint256 => address) private _positiveNodes; // mapping of node id to account
    mapping(address => uint256) private _positiveNodesPrime; // mapping of account to node id
    StructuredLinkedList.List private _positiveList; // instance of the StructuredLinkedList, which includes functions for push, pop, insert, etc
    uint256 private _positiveListTotalScore; // total score of the list

    // this block of variables is everything needed to track one list (the "negative" list)
    uint256 private _negativeTicker; // unique node id incrementer (each item in the list stored as a simple integer)
    mapping(uint256 => address) private _negativeNodes; // mapping of node id to account
    mapping(address => uint256) private _negativeNodesPrime; // mapping of account to node id
    StructuredLinkedList.List private _negativeList; // instance of the StructuredLinkedList, which includes functions for push, pop, insert, etc
    uint256 private _negativeListTotalScore; // total score of the list

    event AddedToPositiveList(address indexed account, uint256 score);
    event AddedToNegativeList(address indexed account, uint256 score);
    event RemovedFromPositiveList(address indexed account);
    event RemovedFromNegativeList(address indexed account);

    /**
     * @notice Given a list, a mapping of nodes, and a value, figure out and return the node that should come right before it (the value)
     * @param list the list to operate on (either the positive or negative list)
     * @param _nodes the mapping of nodes => addresses, used to help determine scores necessary for sorting comparisons
     * @param _value the new value that we need to figure out where it belongs in the given list
     * @dev Re-implementation of a function included in the library, but tweaked for implementing a "descending" list
     * https://github.com/vittominacori/solidity-linked-list/blob/4124595810e508edbb0125b72a79d6b8e1e30573/contracts/StructuredLinkedList.sol#L126
     */
    function getSortedSpot(StructuredLinkedList.List storage list, mapping(uint256 => address) storage _nodes, uint256 _value) private view returns (uint256) {
        if (list.sizeOf() == 0) {
            return 0;
        }

        // grab the last node on the list (node with smallest score)
        uint256 prev;
        (, prev) = list.getAdjacent(0, false);

        // while our new value is still greater than or equal to the score of the current node...
        while ((prev != 0) && ((_value < _accountScores[_nodes[prev]]) != true)) {
            // ...move to the next (larger) node (score)
            prev = list.list[prev][false];
        }
        
        // return the first node that has a score greater than or equal to our input value
        return prev;
    }

    /**
     * @notice removes the bottom node (lowest score) from the "positive" list
     * @return nodeAccount the account of the removed node
     * @return nodeScore the score of the removed node
     */
    function takeBottomOffPositive() private returns (address nodeAccount, uint256 nodeScore) {
        // use linked list functionality to pop the back (bottom) of the positive list, returning its node id
        uint256 nodeId = _positiveList.popBack();

        // get and return the account for that node id
        nodeAccount = _positiveNodes[nodeId];

        // get and return the score for that account
        nodeScore = _accountScores[nodeAccount];

        // delete this account and score from the "positive" mapping structures
        delete _positiveNodes[nodeId];
        delete _positiveNodesPrime[nodeAccount];

        // decrease the "positive list" score
        _positiveListTotalScore = _positiveListTotalScore.sub(nodeScore);

        emit RemovedFromPositiveList(nodeAccount);
    }

    /**
     * @notice removes the top node (highest score) from the "negative" list
     * @return nodeAccount the account of the removed node
     * @return nodeScore the score of the removed node
     */
    function takeTopOffNegative() private returns (address nodeAccount, uint256 nodeScore) {
        // use linked list functionality to pop the front (top) of the negative list, returning its node id
        uint256 nodeId = _negativeList.popFront();

        // get and return the account for that node id
        nodeAccount = _negativeNodes[nodeId];

        // get and return the score for that account
        nodeScore = _accountScores[nodeAccount];

        // delete this account and score from the "negative" mapping structures
        delete _negativeNodes[nodeId];
        delete _negativeNodesPrime[nodeAccount];

        // decrease the "negative list" score
        _negativeListTotalScore = _negativeListTotalScore.sub(nodeScore);

        emit RemovedFromNegativeList(nodeAccount);
    }

    /**
     * @notice Given an account and score, insert that "tuple" into the positive list in the correctly sorted spot
     * @param nodeAccount the account to add to the list
     * @param nodeScore the score to add to the list
     */
    function pushIntoPositive(address nodeAccount, uint256 nodeScore) private {
        // find the position (node id) of the node that should come directly before the new node that we'll create
        uint256 position = getSortedSpot(_positiveList, _positiveNodes, nodeScore);

        // increase our node id counter to get a fresh node id
        _positiveTicker = _positiveTicker.add(1);

        // insert the new node id into the list at the correct location
        _positiveList.insertAfter(position, _positiveTicker);

        // link the new node id to the input account and score
        _positiveNodes[_positiveTicker] = nodeAccount;
        _positiveNodesPrime[nodeAccount] = _positiveTicker;

        // set the mapping structure to indicate that this account exists on the positive list
        _accountOnPositive[nodeAccount] = true;

        // increase the total positive list score
        _positiveListTotalScore = _positiveListTotalScore.add(nodeScore);

        emit AddedToPositiveList(nodeAccount, nodeScore);
    }

    /**
     * @notice Given an account and score, insert that "tuple" into the negative list in the correctly sorted spot
     * @param nodeAccount the account to add to the list
     * @param nodeScore the score to add to the list
     */
    function pushIntoNegative(address nodeAccount, uint256 nodeScore) private {
        // find the position (node id) of the node that should come directly before the new node that we'll create
        uint256 position = getSortedSpot(_negativeList, _negativeNodes, nodeScore);

        // increase our node id counter to get a fresh node id
        _negativeTicker = _negativeTicker.add(1);

        // insert the new node id into the list at the correct location
        _negativeList.insertAfter(position, _negativeTicker);

        // link the new node id to the input account and score
        _negativeNodes[_negativeTicker] = nodeAccount;
        _negativeNodesPrime[nodeAccount] = _negativeTicker;

        // set the mapping structure to indicate that this account does not exist on the positive list
        _accountOnPositive[nodeAccount] = false;

        // increase the total negative list score
        _negativeListTotalScore = _negativeListTotalScore.add(nodeScore);

        emit AddedToNegativeList(nodeAccount, nodeScore);
    }
    
    /**
     * @notice Takes an account address, and an "increase", and performs all of the logic necessary to:
     * 1) either: add this account to the proper list, if it's a new account
     * 2) or: update the account by adding the score increase to their existing score
     * 3) rearrange the lists so that they are properly sorted
     * 4) rearrange the lists so that they are properly balanced
     * @param account the address that has a score increase
     * @param increase the increase score amount
     * @return newScore the new total score for the account
     */
    function addScore(address account, uint256 increase) internal returns (uint256 newScore) {
        // grab the account's current score
        uint256 currentScore = _accountScores[account];

        // calculate their new score
        newScore = currentScore.add(increase);

        // update the score mapping with their new score
        _accountScores[account] = newScore;

        // if the account's current score is not 0, then we know they exist on a list already.
        // we want to remove them from whatever list they're currently on
        if (currentScore != 0) {
            // if they're on the positive list...
            if (_accountOnPositive[account] == true) {
                // grab their node id, given their account
                uint256 nodeId = _positiveNodesPrime[account];

                // remove that node from the linked list
                _positiveList.remove(nodeId);

                // unlink the node id from their account and score
                delete _positiveNodes[nodeId];
                delete _positiveNodesPrime[account];

                // decrease the "positive list" score
                _positiveListTotalScore = _positiveListTotalScore.sub(currentScore);

                emit RemovedFromPositiveList(account);
            // else they must be on the negative list...
            } else {
                // grab their node id, given their account
                uint256 nodeId = _negativeNodesPrime[account];

                // remove that node from the linked list
                _negativeList.remove(nodeId);

                // unlink the node id from their account and score
                delete _negativeNodes[nodeId];
                delete _negativeNodesPrime[account];

                // decrease the "positive list" score
                _negativeListTotalScore = _negativeListTotalScore.sub(currentScore);

                emit RemovedFromNegativeList(account);
            }
        }
        // now, whether the account is new or existing, we are in the same place:
        // the two lists and all associated list-level data structures have no
        // knowledge of the account or score

        // optimistically push the account/score into the positive list
        pushIntoPositive(account, newScore);

        // if the positive list size is too big (two+ more items than negative list)...
        if (_positiveList.size.sub(1) > _negativeList.size) {
            // remove the lowest account/score from the positive list
            (address lastPositiveNodeAccount, uint256 lastPositiveNodeScore) = takeBottomOffPositive();

            // push that account/score into the negative list
            pushIntoNegative(lastPositiveNodeAccount, lastPositiveNodeScore);
        }

        // read the the bottom of the positive list, and the top of the negative list
        (, uint256 firstNegativeNodeId) = _negativeList.getNextNode(0);        
        (, uint256 lastPositiveNodeId) = _positiveList.getPreviousNode(0);

        // if the score of the bottom of the positive list is less than the score of the top of the negative list, we need to flip them
        if (_accountScores[_negativeNodes[firstNegativeNodeId]] > _accountScores[_positiveNodes[lastPositiveNodeId]]) {
            // take the bottom off the positive list (smaller score)
            (address lastPositiveNodeAccount, uint256 lastPositiveNodeScore) = takeBottomOffPositive();

            // take the top off the negative list (larger score)
            (address firstNegativeNodeAccount, uint256 firstNegativeNodeScore) = takeTopOffNegative();

            // push the smaller score into the negative list
            pushIntoNegative(lastPositiveNodeAccount, lastPositiveNodeScore);

            // push the larger score into the positive list
            pushIntoPositive(firstNegativeNodeAccount, firstNegativeNodeScore);
        }
    }

    /**
     * @notice given a node id, returns a bool indicating if there is a following node on the positive list, and that node id if applicable
     * @param id the node id to check
     * @return exists bool indicating if there is a node following the input node on the positive list
     * @return nextId the id of the next node on the positive list, if it exists
     */
    function getNextPositiveNode(uint256 id) public view returns (bool exists, uint256 nextId) {
        (exists, nextId) = _positiveList.getNextNode(id);
    }

    /**
     * @notice iven a node id, returns a bool indicating if there is a following node on the negative list, and that node id if applicable
     * @param id the node id to check
     * @return exists bool indicating if there is a node following the input node on the negative list
     * @return nextId the id of the next node on the negative list, if it exists
     */
    function getNextNegativeNode(uint256 id) public view returns (bool exists, uint256 nextId) {
        (exists, nextId) = _negativeList.getNextNode(id);
    }

    /**
     * @notice given a node id, returns the address associated with that id on the positive list
     * @param id the node id to check
     * @return account address of the account associated with the node id on the positive list
     */
    function getPositiveAddress(uint256 id) public view returns (address account) {
        account = _positiveNodes[id];
    }

    /**
     * @notice given a node id, returns the address associated with that id on the negative list
     * @param id the node id to check
     * @return account address of the account associated with the node id on the negative list
     */
    function getNegativeAddress(uint256 id) public view returns (address account) {
        account = _negativeNodes[id];
    }

    /**
     * @notice returns the score of a given account
     * @param account the account to check
     * @return score the score of the account
     */
    function getAccountScore(address account) public view returns (uint256 score) {
        score = _accountScores[account];
    }

    /**
     * @notice given an account, returns true if that account exists on the positive list, false otherwise
     * @param account the account to check
     * @return positive true if account exists on positive list, false otherwise
     */
    function getIsOnPositive(address account) public view returns (bool positive) {
        positive = _accountOnPositive[account];
    }

    /**
     * @notice given an account, returns true if that account exists on the negative list, false otherwise
     * @param account the account to check
     * @return negative true if account exists on negative list, false otherwise
     * @dev merely checking !_accountOnPositive[account] is not enough, since every single address is false by default,
     * need to check that the given account has a score, as well
     */
    function getIsOnNegative(address account) public view returns (bool negative) {
        negative = !_accountOnPositive[account] && _accountScores[account] > 0;
    }

    /**
     * @notice returns the size of the positive list
     * @return size size of the positive list
     */
    function getPositiveListSize() public view returns (uint256 size) {
        size = _positiveList.size;
    }

    /**
     * @notice returns the size of the negative list
     * @return size size of the negative list
     */
    function getNegativeListSize() public view returns (uint256 size) {
        size = _negativeList.size;
    }

    /**
     * @notice returns the total score of the positive list
     * @return score total score of the positive list
     */
    function getPositiveListTotalScore() public view returns (uint256 score) {
        score = _positiveListTotalScore;
    }

    /**
     * @notice returns the total score of the negative list
     * @return score total score of the negative list
     */
    function getNegativeListTotalScore() public view returns (uint256 score) {
        score = _negativeListTotalScore;
    }
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

/**
 * @title Rewards is for holding all value (Tokens and Ether) in the Game System 
 * @notice All functions are only callable by the creator, which is the Game contract,
 * with a notable exception being the payable Ether fallback function, because the Uniswap Router
 * will be sending Ether here
 * @dev This contract needs to exist, and be its own instance, because a Uniswap Pair will not
 * swap tokens _to_ the contract which is one of it's own tokens. For this reason, we need to initiate
 * swaps from a different address; hence, this contract exists.
 */
contract Rewards {
    /**
     * @notice contract address of the main Game token contract
     */
    address public game;

    /**
     * @notice Addresses of the Uniswap and Router
     */
    IUniswapV2Router02 public immutable uniswapV2Router;

    // used for a safety check in the payable receive function
    // once the game is over, no more Ether can be deposited from anyone except Uniswap router
    uint256 private _endTime;

    constructor(address _game, IUniswapV2Router02 router, uint256 endTime) {
        game = _game;
        uniswapV2Router = router;
        _endTime = endTime;
    }

    /**
     * @notice reverts if the msg.sender is not the Game contract address
     */
    modifier onlyGame() {
        require(msg.sender == game, "Rewards::onlyGame: msg.sender must be the Game contract");
        _;
    }

    /**
     * @notice Accept an amount of Tokens, some Ether, and add them to liquidity on the Token-ETH pair.
     * The tokens must have already been transfered to this contract. The Ether is payable, so attached to the function call.
     * Only callable by the Game address.
     * @param tokenAmount a number of tokens to be added as liquidity
     * @return amountToken the amount of tokens which were successfully added to liquidity; will be <= the input `tokenAmount`
     * @return amountETH the amount of Ether which were successfully added to liquidity; will be <= the input msg.value
     * @return liquidity the number of Token-ETH LP tokens which were created and transfered to this contract
     * @dev any remaining Tokens or Ether which weren't added to liquidity, are refunded to this contract
     */
    function addLiquidityETH(uint256 tokenAmount) onlyGame public payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity) {
        // there are no limits on the expected amount of liquidity which are added, simply send all of the input Tokens and Ether
        (amountToken, amountETH, liquidity) = uniswapV2Router.addLiquidityETH{ value: msg.value }(game, tokenAmount, 0, 0, address(this), block.timestamp);
    }

    /**
     * @notice Accept a Pair address, and an amount of liquidity tokens, and removes that liquidity from the Token-ETH pair
     * Only callable by the Game address.
     * @param pair address of the Uniswap Pair that we're removing liquidity from (in practice, will always be the Token-ETH pair address)
     * @param liquidityBalance the amount of LP tokens to remove from liquidity
     * @dev The pair address is needed to approve token transfer for the Uniswap router, since this contract holds the LP tokens
     * @dev This contract is the recipient of removed Tokens and Ether
     */
    function removeLiquidityETH(IUniswapV2Pair pair, uint256 liquidityBalance) onlyGame public {
        // approve the Uniswap router to be able to transfer LP tokens of this contract
        pair.approve(address(uniswapV2Router), liquidityBalance);

        // no limits on the min amounts of Tokens or ETH which are removed
        uniswapV2Router.removeLiquidityETH(game, liquidityBalance, 0, 0, address(this), block.timestamp);
    }

    /**
     * @notice Accepts payable Ether, and swaps all of it for Tokens
     * Only callable by the Game address.
     * @return amount the amount of Tokens which were acquired from the swap
     * @dev This contract is the recipient of acquired Tokens
     */
    function swapExactETHForTokens(uint256 amountOutMin) onlyGame public payable returns (uint256 amount) {
        // build the WETH -> Token path
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = game;

        // no limits on the amount of Tokens which are received
        uint256[] memory amounts = uniswapV2Router.swapExactETHForTokens{ value: msg.value }(amountOutMin, path, address(this), block.timestamp);
        amount = amounts[1];
    }

    /**
     * @notice Accepts an amount of Tokens, and swaps all of them for Ether
     * Only callable by the Game address.
     * @param amountToken the number of tokens to swap for Ether
     * @dev This contract is the recipient of acquired Ether
     */
    function swapExactTokensForETH(uint256 amountToken) onlyGame public {
        // build the Token -> WETH path
        address[] memory path = new address[](2);
        path[0] = game;
        path[1] = uniswapV2Router.WETH();

        uint256 amountsOut = uniswapV2Router.getAmountsOut(amountToken, path)[1];

        // Don't call swap if there's no ETHs to receive
        if (amountsOut == 0) {
            return;
        }

        // no limits on the amount of Ether which are received
        uniswapV2Router.swapExactTokensForETH(amountToken, 0, path, address(this), block.timestamp);
    }

    /**
     * @notice Accepts and address and an Ether value, and transfers that much Ether to the address
     * Only callable by the Game address.
     * @param to payable address that the Ether should be sent to
     * @param amount the amount of Ether to send
     * @dev the Ether needs to already belong to this contract, it's not passed through this function
     */
    function sendEther(address payable to, uint256 amount) onlyGame public {
        to.transfer(amount);
    }

    /**
     * @notice Sends all balance of a given token to the game contract - used to recover locked non-game related tokens
     * Only callable by the Game address.
     * @param token an address of the token contract
     */
    function recoverToken(address token) onlyGame external {
        uint256 myBalance = IERC20(token).balanceOf(address(this));
        if (myBalance > 0) {
            IERC20(token).transfer(game, myBalance);
        }
    }

    /**
     * @notice The fallback function for this contract to accept Ether
     */
    receive() external payable {
        // if the msg.sender is the Uniswap Router address, always accept the Ether
        if (msg.sender != address(uniswapV2Router)) {
            // Otherwise, only accept Ether from anyone else during the actual gameplay
            require(_endTime > block.timestamp, "Rewards::receive: game is over! no more depositing into the rewards contract");
        }
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../GSN/Context.sol";
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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
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

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
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

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
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
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
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

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.5.0;

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

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

interface  IStructureInterface {
    function getValue(uint256 _id) external view returns (uint256);
}

/**
 * @title StructuredLinkedList
 * @author Vittorio Minacori (https://github.com/vittominacori)
 * @dev An utility library for using sorted linked list data structures in your Solidity project.
 */
library StructuredLinkedList {

    uint256 private constant _NULL = 0;
    uint256 private constant _HEAD = 0;

    bool private constant _PREV = false;
    bool private constant _NEXT = true;

    struct List {
        uint256 size;
        mapping(uint256 => mapping(bool => uint256)) list;
    }

    /**
     * @dev Checks if the list exists
     * @param self stored linked list from contract
     * @return bool true if list exists, false otherwise
     */
    function listExists(List storage self) internal view returns (bool) {
        // if the head nodes previous or next pointers both point to itself, then there are no items in the list
        if (self.list[_HEAD][_PREV] != _HEAD || self.list[_HEAD][_NEXT] != _HEAD) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Checks if the node exists
     * @param self stored linked list from contract
     * @param _node a node to search for
     * @return bool true if node exists, false otherwise
     */
    function nodeExists(List storage self, uint256 _node) internal view returns (bool) {
        if (self.list[_node][_PREV] == _HEAD && self.list[_node][_NEXT] == _HEAD) {
            if (self.list[_HEAD][_NEXT] == _node) {
                return true;
            } else {
                return false;
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Returns the number of elements in the list
     * @param self stored linked list from contract
     * @return uint256
     */
    function sizeOf(List storage self) internal view returns (uint256) {
        return self.size;
    }

    /**
     * @dev Returns the links of a node as a tuple
     * @param self stored linked list from contract
     * @param _node id of the node to get
     * @return bool, uint256, uint256 true if node exists or false otherwise, previous node, next node
     */
    function getNode(List storage self, uint256 _node) internal view returns (bool, uint256, uint256) {
        if (!nodeExists(self, _node)) {
            return (false, 0, 0);
        } else {
            return (true, self.list[_node][_PREV], self.list[_node][_NEXT]);
        }
    }

    /**
     * @dev Returns the link of a node `_node` in direction `_direction`.
     * @param self stored linked list from contract
     * @param _node id of the node to step from
     * @param _direction direction to step in
     * @return bool, uint256 true if node exists or false otherwise, node in _direction
     */
    function getAdjacent(List storage self, uint256 _node, bool _direction) internal view returns (bool, uint256) {
        if (!nodeExists(self, _node)) {
            return (false, 0);
        } else {
            return (true, self.list[_node][_direction]);
        }
    }

    /**
     * @dev Returns the link of a node `_node` in direction `_NEXT`.
     * @param self stored linked list from contract
     * @param _node id of the node to step from
     * @return bool, uint256 true if node exists or false otherwise, next node
     */
    function getNextNode(List storage self, uint256 _node) internal view returns (bool, uint256) {
        return getAdjacent(self, _node, _NEXT);
    }

    /**
     * @dev Returns the link of a node `_node` in direction `_PREV`.
     * @param self stored linked list from contract
     * @param _node id of the node to step from
     * @return bool, uint256 true if node exists or false otherwise, previous node
     */
    function getPreviousNode(List storage self, uint256 _node) internal view returns (bool, uint256) {
        return getAdjacent(self, _node, _PREV);
    }

    /**
     * @dev Can be used before `insert` to build an ordered list.
     * @dev Get the node and then `insertBefore` or `insertAfter` basing on your list order.
     * @dev If you want to order basing on other than `structure.getValue()` override this function
     * @param self stored linked list from contract
     * @param _structure the structure instance
     * @param _value value to seek
     * @return uint256 next node with a value less than _value
     */
    function getSortedSpot(List storage self, address _structure, uint256 _value) internal view returns (uint256) {
        if (sizeOf(self) == 0) {
            return 0;
        }

        uint256 next;
        (, next) = getAdjacent(self, _HEAD, _NEXT);
        while ((next != 0) && ((_value < IStructureInterface(_structure).getValue(next)) != _NEXT)) {
            next = self.list[next][_NEXT];
        }
        return next;
    }

    /**
     * @dev Insert node `_new` beside existing node `_node` in direction `_NEXT`.
     * @param self stored linked list from contract
     * @param _node existing node
     * @param _new  new node to insert
     * @return bool true if success, false otherwise
     */
    function insertAfter(List storage self, uint256 _node, uint256 _new) internal returns (bool) {
        return _insert(self, _node, _new, _NEXT);
    }

    /**
     * @dev Insert node `_new` beside existing node `_node` in direction `_PREV`.
     * @param self stored linked list from contract
     * @param _node existing node
     * @param _new  new node to insert
     * @return bool true if success, false otherwise
     */
    function insertBefore(List storage self, uint256 _node, uint256 _new) internal returns (bool) {
        return _insert(self, _node, _new, _PREV);
    }

    /**
     * @dev Removes an entry from the linked list
     * @param self stored linked list from contract
     * @param _node node to remove from the list
     * @return uint256 the removed node
     */
    function remove(List storage self, uint256 _node) internal returns (uint256) {
        if ((_node == _NULL) || (!nodeExists(self, _node))) {
            return 0;
        }
        _createLink(self, self.list[_node][_PREV], self.list[_node][_NEXT], _NEXT);
        delete self.list[_node][_PREV];
        delete self.list[_node][_NEXT];

        self.size -= 1; // NOT: SafeMath library should be used here to decrement.

        return _node;
    }

    /**
     * @dev Pushes an entry to the head of the linked list
     * @param self stored linked list from contract
     * @param _node new entry to push to the head
     * @return bool true if success, false otherwise
     */
    function pushFront(List storage self, uint256 _node) internal returns (bool) {
        return _push(self, _node, _NEXT);
    }

    /**
     * @dev Pushes an entry to the tail of the linked list
     * @param self stored linked list from contract
     * @param _node new entry to push to the tail
     * @return bool true if success, false otherwise
     */
    function pushBack(List storage self, uint256 _node) internal returns (bool) {
        return _push(self, _node, _PREV);
    }

    /**
     * @dev Pops the first entry from the head of the linked list
     * @param self stored linked list from contract
     * @return uint256 the removed node
     */
    function popFront(List storage self) internal returns (uint256) {
        return _pop(self, _NEXT);
    }

    /**
     * @dev Pops the first entry from the tail of the linked list
     * @param self stored linked list from contract
     * @return uint256 the removed node
     */
    function popBack(List storage self) internal returns (uint256) {
        return _pop(self, _PREV);
    }

    /**
     * @dev Pushes an entry to the head of the linked list
     * @param self stored linked list from contract
     * @param _node new entry to push to the head
     * @param _direction push to the head (_NEXT) or tail (_PREV)
     * @return bool true if success, false otherwise
     */
    function _push(List storage self, uint256 _node, bool _direction) private returns (bool) {
        return _insert(self, _HEAD, _node, _direction);
    }

    /**
     * @dev Pops the first entry from the linked list
     * @param self stored linked list from contract
     * @param _direction pop from the head (_NEXT) or the tail (_PREV)
     * @return uint256 the removed node
     */
    function _pop(List storage self, bool _direction) private returns (uint256) {
        uint256 adj;
        (, adj) = getAdjacent(self, _HEAD, _direction);
        return remove(self, adj);
    }

    /**
     * @dev Insert node `_new` beside existing node `_node` in direction `_direction`.
     * @param self stored linked list from contract
     * @param _node existing node
     * @param _new  new node to insert
     * @param _direction direction to insert node in
     * @return bool true if success, false otherwise
     */
    function _insert(List storage self, uint256 _node, uint256 _new, bool _direction) private returns (bool) {
        if (!nodeExists(self, _new) && nodeExists(self, _node)) {
            uint256 c = self.list[_node][_direction];
            _createLink(self, _node, _new, _direction);
            _createLink(self, _new, c, _direction);

            self.size += 1; // NOT: SafeMath library should be used here to increment.

            return true;
        }

        return false;
    }

    /**
     * @dev Creates a bidirectional link between two nodes on direction `_direction`
     * @param self stored linked list from contract
     * @param _node existing node
     * @param _link node to link to in the _direction
     * @param _direction direction to insert node in
     */
    function _createLink(List storage self, uint256 _node, uint256 _link, bool _direction) private {
        self.list[_link][!_direction] = _node;
        self.list[_node][_direction] = _link;
    }
}