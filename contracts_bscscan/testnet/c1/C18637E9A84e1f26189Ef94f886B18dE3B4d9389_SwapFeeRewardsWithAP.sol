// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "../libraries/AuraLibrary.sol";
import "../interfaces/IOracle.sol";
import "../interfaces/IAuraNFT.sol";
import "../interfaces/IAuraToken.sol";
import "../swaps/AuraFactory.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import '@rari-capital/solmate/src/utils/ReentrancyGuard.sol';
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// TODO - Add NatSpec comments to latter functions.

/**
 * @title Convert between Swap Reward Fees to Aura Points (ap/AP)
 */
contract SwapFeeRewardsWithAP is Ownable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet whitelist;

    IOracle public oracle;
    IAuraNFT public auraNFT;
    IAuraToken public auraToken;

    address public factory;
    address public router;
    address public market;
    address public auction;
    address public targetToken;
    address public targetAPToken;

    uint public maxMiningAmount = 100000000 ether;
    uint public maxMiningInPhase = 5000 ether;
    uint public maxAccruedAPInPhase = 5000 ether;

    uint public phase = 1;
    uint public phaseAP = 1; 
    
    uint public totalMined = 0;
    uint public totalAccruedAP = 0;

    uint public apWagerOnSwap = 1500;
    uint public apPercentMarket = 10000; // (div 10000)
    uint public apPercentAuction = 10000; // (div 10000)

    /*
     * Sets the upper limit of maximum AURA percentage of users' rewards.
     * Higher value -> higher max AURA percentage and more user choice.
     * 0   -> Rewards are [0]% AURA and [100]% AP. User has no choice.
     * 50  -> Rewards are [0, 50]% AURA and [0, 100]% AP. User has some choice.
     * 100 -> Rewards are [0, 100]% AURA and [0, 100]% AP. User has full choice.
     * Invariant: must be in range [0, 100].
     */
    uint public defaultRewardDistribution = 0; 

    struct PairsList {
        address pair;
        uint percentReward;
        bool isEnabled;
    }

    PairsList[] public pairsList;

    /* 
     * Fee distribution is a user setting for how that user wants their rewards distributed.
     * Assuming defaultRewardDistribution == 100, then:
     * 0   -> Rewards are distributed entirely in AURA.
     * 50  -> Rewards are 50% AURA and 50% AP.
     * 100 -> Rewards are distributed entirely in AP.
     * More generally, low values maximize AURA while high values maximize AP.
     * Invariant: rewardDistribution[user] <= defaultRewardDistribution.
     */
    mapping(address => uint) public rewardDistribution;

    mapping(address => uint) public pairOfPairIds;
    mapping(address => uint) public _balances;
    mapping(address => uint) public nonces;

    event NewAuraNFT(IAuraNFT auraNFT);
    event NewOracle(IOracle oracle);

    event Rewarded(address account, address input, address output, uint amount, uint quantity);
    event Withdraw(address user, uint amount);

    event NewPhase(uint phase);
    event NewPhaseAP(uint phaseAP);
    event NewRouter(address router);
    event NewMarket(address market);
    event NewAuction(address auction);
    event NewFactory(address factory);

    constructor(
        address _factory,
        address _router, 
        address _targetToken,
        address _targetAPToken,
        IOracle _oracle,
        IAuraNFT _auraNFT,
        IAuraToken _auraToken
    ) {
        require(
            _factory != address(0)
            && _router != address(0)
            && _targetToken != address(0)
            && _targetAPToken != address(0),
            "Address cannot be zero."
        );
        factory = _factory;
        router = _router;
        targetToken = _targetToken;
        targetAPToken = _targetAPToken;
        oracle = _oracle;
        auraNFT = _auraNFT;
        auraToken = _auraToken;
    }

    /* 
     * EXTERNAL CORE 
     *
     * These functions constitute this contract's core functionality. 
     */

    /**
     * @dev swap the `input` token for the `output` token and credit the result to `account`.
     */
    function swap(address account, address input, address output, uint amount) external returns(bool) {
        require (msg.sender == router, "Caller is not the router.");

        if (!whitelistContains(input) || !whitelistContains(output)) { return false; }

        address pair = pairFor(input, output);
        PairsList memory pool = pairsList[pairOfPairIds[pair]];
        if (!pool.isEnabled || pool.pair != pair) { return false; }

        uint swapFee = getSwapFee(input, output);
        (uint feeAmount, uint apAmount) = getSplitRewardAmounts(amount, account);
        feeAmount = feeAmount / swapFee;

        // Gets the quantity of AURA (targetToken) equivalent in value to quantity (feeAmount) of the input token (output).
        uint quantity = getQuantityOut(output, feeAmount, targetToken);
        if ((totalMined + quantity) <= maxMiningAmount && (totalMined + quantity) <= (phase * maxMiningInPhase)) {
            _balances[account] += quantity;
            emit Rewarded(account, input, output, amount, quantity);
        }

        apAmount = apAmount / apWagerOnSwap;
        accrueAuraPoints(account, output, apAmount);

        return true;
    }

    /**
     * @dev Withdraw AURA from the caller's contract balance to the caller's address.
     */
    function withdraw(uint8 v, bytes32 r, bytes32 s) external nonReentrant returns(bool) {
        require (totalMined < maxMiningAmount, "All tokens have been mined.");

        uint balance = _balances[msg.sender];
        require ((totalMined + balance) <= (phase * maxMiningInPhase), "All tokens in this phase have been mined.");
      
        // Verify the sender's signature.
        permit(msg.sender, balance, v, r, s);

        if (balance > 0) {
            _balances[msg.sender] -= balance;
            totalMined += balance;
            if (auraToken.transfer(msg.sender, balance)) {
                emit Withdraw(msg.sender, balance);
                return true;
            }
        }
        return false;
    }

    /* 
     * PUBLIC UTILS 
     * 
     * These utility functions are used within this contract but are useful and safe enough 
     * to expose to callers as well. 
     */

    /**
     * @dev Gets the quantity of `tokenOut` equivalent in value to `quantityIn` many `tokenIn`.
     */
    function getQuantityOut(address tokenIn, uint quantityIn, address tokenOut) public view returns(uint quantityOut) {
        if (tokenIn == tokenOut) {
            // If the tokenIn is the same as the tokenOut, then there's no exchange quantity to compute.
            // I.e. ETH -> ETH.
            quantityOut = quantityIn;
        } else if (getPair(tokenIn, tokenOut) != address(0) 
            && pairExists(tokenIn, tokenOut)) 
        {
            // If a direct exchange pair exists, then get the exchange quantity directly.
            // I.e. ETH -> BTC where a ETH -> BTC pair exists.
            quantityOut = IOracle(oracle).consult(tokenIn, quantityIn, tokenOut);
        } else {
            // Otherwise, try to find an intermediate exchange token
            // and compute the exchange quantity via that intermediate token.
            // I.e. ETH -> BTC where ETH -> BTC doesn't exist but ETH -> SOL -> BTC does.
            uint length = whitelistLength();
            for (uint i = 0; i < length; i++) {
                address intermediate = whitelistGet(i);
                if (getPair(tokenIn, intermediate) != address(0)
                    && getPair(intermediate, tokenOut) != address(0)
                    && pairExists(intermediate, tokenOut))
                {
                    uint interQuantity = IOracle(oracle).consult(tokenIn, quantityIn, intermediate);
                    quantityOut = IOracle(oracle).consult(intermediate, interQuantity, tokenOut);
                    break;
                }
            }
        }
    }

    /**
     * @return _pairExists is true if this exchange swaps between tokens `a` and `b` and false otherwise.
     */
    function pairExists(address a, address b) public view returns(bool _pairExists) {
        address pair = pairFor(a, b);
        uint pairId = pairOfPairIds[pair];
        // Prevent pairID index out of bounds.
        if (pairId >= pairsList.length) { return false; }
        PairsList memory pool = pairsList[pairId];
        _pairExists = (pool.pair == pair);
    }

    /**
     * @dev Convenience wrapper of AuraLibrary.pairFor().
     * @return pair created by joining tokens `a` and `b`.
     */
    function pairFor(address a, address b) public view returns(address pair) {
        pair = AuraLibrary.pairFor(factory, a, b);
    }
    
    /**
     * @dev Convenience wrapper of AuraFactory.getPair().
     * @return pair of tokens `a` and `b`. 
     */
    function getPair(address a, address b) public view returns(address pair) {
        pair = AuraFactory(factory).getPair(a, b);
    }

    /**
     * @dev Convenience wrapper of AuraLibrary.getSwapFee().
     * @return swapFee for swapping tokens `a` and `b`.
     */
    function getSwapFee(address a, address b) public view returns(uint swapFee) {
        swapFee = AuraLibrary.getSwapFee(factory, a, b);
    }

    /* 
     * EXTERNAL GETTERS 
     * 
     * These functions provide useful information to callers about this contract's state. 
     */

    /**
     * @return the number of swap pairs recognized by the exchange.
     */
    function getPairsListLength() external view returns(uint) {
        return pairsList.length;
    }

    /**
     * @return the earned but unwithdrawn AURA in `account`.
     */
    function getBalance(address account) external view returns(uint) {
        return _balances[account];
    }

    /**
     * @dev Return to the caller the token quantities in AURA, USD, and AP
     *      that `account` could withdraw.
     */
    function getPotentialRewardQuantities(address account, address input, address output, uint amount) 
        external
        view
        returns(
            uint inAURA,
            uint inUSD,
            uint inAP
        )
    {
        uint swapFee = getSwapFee(input, output); 
        address pair = pairFor(input, output);
        PairsList memory pool = pairsList[pairOfPairIds[pair]];

        if (pool.pair == pair && pool.isEnabled && whitelistContains(input) && whitelistContains(output)) {
            (uint feeAmount, uint apAmount) = getSplitRewardAmounts(amount, account);
            inAURA = getQuantityOut(output, feeAmount / swapFee, targetToken) * pool.percentReward / 100;
            inUSD = getQuantityOut(targetToken, inAURA, targetAPToken);
            inAP = getQuantityOut(output, apAmount / apWagerOnSwap, targetAPToken);
        }
    }

    /* 
     * EXTERNAL SETTERS 
     * 
     * Provide callers with functionality for setting contract state.
     */

    /**
     * @dev Accrue AP to AuraNFT `tokenId` equivalent in value to `quantityIn` of `tokenIn` modified
     *      by the market percent rate.
     */
    function accrueAPFromMarket(address account, address tokenIn, uint quantityIn) external {
        require(msg.sender == market, "Caller is not the market.");
        quantityIn = quantityIn * apPercentMarket / 10000;
        accrueAuraPoints(account, tokenIn, quantityIn);
    }
    
    /**
     * @dev Accrue AP to AuraNFT `tokenId` equivalent in value to `quantityIn` of `tokenIn` modified
     *      by the auction percent rate.
     */
    function accrueAPFromAuction(address account, address tokenIn, uint quantityIn) external {
        require(msg.sender == auction, "Caller is not the auction.");
        quantityIn = quantityIn * apPercentAuction / 10000;
        accrueAuraPoints(account, tokenIn, quantityIn);
    }

    function setRewardDistribution(uint _distribution) external {
        require(_distribution <= defaultRewardDistribution, "Invalid fee distribution.");
        rewardDistribution[msg.sender] = _distribution;
    }

    /* 
     * PRIVATE UTILS 
     * 
     * These functions are used within this contract but would be unsafe or useless
     * if exposed to callers.
     */

    /**
     * @dev verifies the spenders signature.
     */
    function permit(address spender, uint value, uint8 v, bytes32 r, bytes32 s) private {
        bytes32 message = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(spender, value, nonces[spender]++))));
        address recoveredAddress = ecrecover(message, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == spender, "Invalid signature.");
    }

    /**
     * @dev Accrue AP to AuraNFT `tokenId` equivalent in value to `quantityIn` of `tokenIn`.
     */
    function accrueAuraPoints(address account, address tokenIn, uint quantityIn) private {
        uint quantity = getQuantityOut(tokenIn, quantityIn, targetAPToken);
        if (quantity > 0) {
            totalAccruedAP += quantity;
            if (totalAccruedAP <= phaseAP * maxAccruedAPInPhase) {
                auraNFT.accrueAuraPoints(account, quantity);
            }
        }
    }

    /**
     * @return feeAmount due to the account.
     * @return apAmount due to the account.
     */
    function getSplitRewardAmounts(uint amount, address account) private view returns(uint feeAmount, uint apAmount) {
        feeAmount = amount * (defaultRewardDistribution - rewardDistribution[account]) / 100;
        apAmount = amount - feeAmount;
    }

    /* 
     * ONLY OWNER SETTERS 
     * 
     * These functions alter contract core data and are only available to the owner. 
     */

    function setDefaultRewardDistribution(uint _defaultRewardDistribution) external onlyOwner {
        defaultRewardDistribution = _defaultRewardDistribution;
    } 

    function setFactory(address _factory) external onlyOwner {
        require(_factory != address(0), "Factory is the zero address.");
        factory = _factory;
        emit NewFactory(_factory);
    }

    function setRouter(address _router) external onlyOwner {
        require(_router != address(0), "Router is the zero address.");
        router = _router;
        emit NewRouter(_router);
    }

    function setMarket(address _market) external onlyOwner {
        require(_market != address(0), "Market is the zero address.");
        market = _market;
        emit NewMarket(_market);
    }

    function setAuction(address _auction) external onlyOwner {
        require(_auction!= address(0), "Auction is the zero address.");
        auction = _auction;
        emit NewAuction(_auction);
    }

    function setPhase(uint _phase) external onlyOwner {
        phase = _phase;
        emit NewPhase(_phase);
    }

    function setPhaseAP(uint _phaseAP) external onlyOwner {
        phaseAP = _phaseAP;
        emit NewPhaseAP(_phaseAP);
    }

    function setOracle(IOracle _oracle) external onlyOwner {
        require(address(_oracle) != address(0), "Oracle is the zero address.");
        oracle = _oracle;
        emit NewOracle(_oracle);
    }

    function setAuraNFT(IAuraNFT _auraNFT) external onlyOwner {
        require(address(_auraNFT) != address(0), "AuraNFT is the zero address.");
        auraNFT = _auraNFT;
        emit NewAuraNFT(_auraNFT);
    }

    function addPair(uint _percentReward, address _pair) external onlyOwner {
        require(_pair != address(0), "`_pair` is the zero address.");
        pairsList.push(
            PairsList({
                pair: _pair,
                percentReward: _percentReward,
                isEnabled: true
            })
        );
        pairOfPairIds[_pair] = pairsList.length - 1;
    }

    function setPairPercentReward(uint _pairId, uint _percentReward) external onlyOwner {
        pairsList[_pairId].percentReward = _percentReward;
    }

    function setPairIsEnabled(uint _pairId, bool _isEnabled) external onlyOwner {
        pairsList[_pairId].isEnabled = _isEnabled;
    }

    function setAPReward(uint _apWagerOnSwap, uint _percentMarket, uint _percentAuction) external onlyOwner {
        apWagerOnSwap = _apWagerOnSwap;
        apPercentMarket = _percentMarket;
        apPercentAuction = _percentAuction;
    }

    /* 
     * WHITELIST 
     * 
     * This special group of utility functions are for interacting with the whitelist.
     */

    /**
     * @dev Add `token` to the whitelist.
     */
    function whitelistAdd(address token) public onlyOwner returns(bool) {
        require(token != address(0), "Zero address is invalid.");
        return EnumerableSet.add(whitelist, token);
    }

    /**
     * @dev Remove `token` from the whitelist.
     */
    function whitelistRemove(address token) public onlyOwner returns(bool) {
        require(token != address(0), "Zero address is invalid.");
        return EnumerableSet.remove(whitelist, token);
    }

    /**
     * @return true if the whitelist contains `token` and false otherwise.
     */
    function whitelistContains(address token) public view returns(bool) {
        return EnumerableSet.contains(whitelist, token);
    }

    /**
     * @return the number of whitelisted addresses.
     */
    function whitelistLength() public view returns(uint256) {
        return EnumerableSet.length(whitelist);
    }

    /**
     * @return the whitelisted address as `_index`.
     */
    function whitelistGet(uint _index) public view returns(address) {
        require(_index <= whitelistLength() - 1, "Index out of bounds.");
        return EnumerableSet.at(whitelist, _index);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import '../swaps/AuraPair.sol';

library AuraLibrary {

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'AuraLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'AuraLibrary: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint160(uint256(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'd9b35256579ff1901f04559c5e15fd3b5c397d5f5a7900722d7512602a987fa8' // init code hash
            )))));
    }

    function getSwapFee(address factory, address tokenA, address tokenB) internal view returns (uint swapFee) {
        swapFee = AuraPair(pairFor(factory, tokenA, tokenB)).swapFee();
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = AuraPair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'AuraLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'AuraLibrary: INSUFFICIENT_LIQUIDITY');
        amountB = amountA * reserveB / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, uint swapFee) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'AuraLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'AuraLibrary: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn * (uint(1000) - swapFee);
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut, uint swapFee) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'AuraLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'AuraLibrary: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn * amountOut * 1000;
        uint denominator = (reserveOut - amountOut) * (uint(1000) - swapFee);
        amountIn = (numerator / denominator) + 1;
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'AuraLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut, getSwapFee(factory, path[i], path[i + 1]));
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'AuraLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut, getSwapFee(factory, path[i - 1], path[i]));
        }
    }   
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IOracle {
    function consult(address tokenIn, uint amountIn, address tokenOut) external view returns(uint amountOut);
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

interface IAuraNFT {
    function accrueAuraPoints(address account, uint amount) external;
    function setIsStaked(uint tokenId, bool isStaked) external;
    function getAuraPoints(uint tokenId) external view returns(uint);
    function getInfoForStaking(uint tokenId) external view returns(address tokenOwner, bool isStaked, uint auraPoints);
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

interface IAuraToken {
    function mint(address to, uint amount) external returns(bool);
    function transfer(address recipient, uint amount) external returns(bool);
}

//SPDX-License-Identifier:MIT
pragma solidity >=0.8.0;

import './AuraPair.sol';
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

contract AuraFactory is IUniswapV2Factory {
    address public feeTo;
    address public feeToSetter;
    bytes32 public INIT_CODE_HASH = keccak256(abi.encodePacked(type(AuraPair).creationCode));

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    constructor(address _feeToSetter) {
        feeToSetter = _feeToSetter;
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, 'Aura: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'Aura: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'Aura: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(AuraPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        AuraPair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, 'Aura: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'Aura: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }

    function setDevFee(address _pair, uint8 _devFee) external {
        require(msg.sender == feeToSetter, 'Aura: FORBIDDEN');
        require(_devFee > 0, 'Aura: FORBIDDEN_FEE');
        AuraPair(_pair).setDevFee(_devFee);
    }
    
    function setSwapFee(address _pair, uint32 _swapFee) external {
        require(msg.sender == feeToSetter, 'Aura: FORBIDDEN');
        AuraPair(_pair).setSwapFee(_swapFee);
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private reentrancyStatus = 1;

    modifier nonReentrant() {
        require(reentrancyStatus == 1, "REENTRANCY");

        reentrancyStatus = 2;

        _;

        reentrancyStatus = 1;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../tokens/AuraLP.sol";
import "../libraries/UQ112x112.sol";
import "../libraries/ExtraMath.sol";
import "../interfaces/IAuraCallee.sol";
import '@uniswap/lib/contracts/libraries/TransferHelper.sol';
import "@rari-capital/solmate/src/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

contract AuraPair is AuraLP, ReentrancyGuard {
    using UQ112x112 for uint224;

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

    uint    public constant MINIMUM_LIQUIDITY = 10**3;
    uint112 public constant MAX_UINT112 = type(uint112).max;

    address public factory;
    address public token0;
    address public token1;

    uint112 private reserve0;           // uses single storage slot, accessible via getReserves
    uint112 private reserve1;           // uses single storage slot, accessible via getReserves
    uint32  private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint public price0CumulativeLast;
    uint public price1CumulativeLast;
    uint public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event
    
    uint32 public swapFee = 2; // uses 0.2% default
    uint32 public devFee  = 5; // uses 0.5% default from swap fee

    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    constructor() {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, 'Aura FORBIDDEN'); // sufficient check
        token0 = _token0;
        token1 = _token1;
    }

    function setSwapFee(uint32 _swapFee) external {
        require(_swapFee > 0, "AuraPair: lower then 0");
        require(msg.sender == factory, 'AuraPair: FORBIDDEN');
        require(_swapFee <= 1000, 'AuraPair: FORBIDDEN_FEE');
        swapFee = _swapFee;
    }
    
    function setDevFee(uint32 _devFee) external {
        require(_devFee > 0, "AuraPair: lower then 0");
        require(msg.sender == factory, 'AuraPair: FORBIDDEN');
        require(_devFee <= 500, 'AuraPair: FORBIDDEN_FEE');
        devFee = _devFee;
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) private {
        require(balance0 <= type(uint112).max && balance1 <= MAX_UINT112, 'Aura: OVERFLOW');
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            price0CumulativeLast += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    // if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)
    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
        address feeTo = IUniswapV2Factory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint _kLast = kLast; // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                uint rootK = ExtraMath.sqrt(uint(_reserve0) * _reserve1);
                uint rootKLast = ExtraMath.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint numerator = totalSupply * (rootK - rootKLast);
                    uint denominator = rootK * devFee + rootKLast;
                    uint liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) public nonReentrant returns (uint liquidity) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        uint amount0 = balance0 - _reserve0;
        uint amount1 = balance1 - _reserve1;

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            liquidity = ExtraMath.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
           _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min(amount0 * _totalSupply / _reserve0, amount1 * _totalSupply / _reserve1);
        }
        require(liquidity > 0, 'Aura INSUFFICIENT_LIQUIDITY_MINTED');
        _mint(to, liquidity);

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0) * reserve1; // reserve0 and reserve1 are up-to-date
        emit Mint(msg.sender, amount0, amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external nonReentrant returns (uint amount0, uint amount1) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        address _token0 = token0;                                // gas savings
        address _token1 = token1;                                // gas savings
        uint balance0 = IERC20(_token0).balanceOf(address(this));
        uint balance1 = IERC20(_token1).balanceOf(address(this));
        uint liquidity = balanceOf[address(this)];

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = liquidity * balance0 / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity * balance1 / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, 'Aura INSUFFICIENT_LIQUIDITY_BURNED');
        _burn(address(this), liquidity);
        TransferHelper.safeTransfer(_token0, to, amount0);
        TransferHelper.safeTransfer(_token1, to, amount1);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0) * reserve1; // reserve0 and reserve1 are up-to-date
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external nonReentrant {
        require(amount0Out > 0 || amount1Out > 0, 'Aura INSUFFICIENT_OUTPUT_AMOUNT');
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'Aura INSUFFICIENT_LIQUIDITY');

        uint balance0;
        uint balance1;
        { // scope for _token{0,1}, avoids stack too deep errors
            address _token0 = token0;
            address _token1 = token1;
            require(to != _token0 && to != _token1, 'Aura INVALID_TO');
            if (amount0Out > 0) TransferHelper.safeTransfer(_token0, to, amount0Out);
            if (amount1Out > 0) TransferHelper.safeTransfer(_token1, to, amount1Out);
            if (data.length > 0) IAuraCallee(to).AuraCall(msg.sender, amount0Out, amount1Out, data);
            balance0 = IERC20(_token0).balanceOf(address(this));
            balance1 = IERC20(_token1).balanceOf(address(this));
        }

        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, 'Aura INSUFFICIENT_INPUT_AMOUNT');
        { // scope for reserve{0,1}Adjusted, avoids stack too deep errors
            uint _swapFee = swapFee;
            uint balance0Adjusted = balance0 * (1000) - (amount0In * _swapFee);
            uint balance1Adjusted = balance1 * (1000) - (amount1In * _swapFee);
            require(balance0Adjusted * balance1Adjusted >= uint(_reserve0) * (_reserve1) * (1000**2), 'Aura K');
        }

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // force balances to match reserves
    function skim(address to) external nonReentrant {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        TransferHelper.safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)) - reserve0);
        TransferHelper.safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)) - reserve1);
    }

    // force reserves to match balances
    function sync() external nonReentrant {
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), reserve0, reserve1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@rari-capital/solmate/src/tokens/ERC20.sol";

contract AuraLP is ERC20 {
    constructor () ERC20(/*name=*/'Aura LPs', /*symbol=*/'AURA-LP', /*decimals=*/18) {}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

// NOTE: Taken from https://github.com/Uniswap/v2-core/blob/master/contracts/libraries/UQ112x112.sol
// with only two changes:
// * MIT License
// * solidity version >= 0.8.0

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))

// range: [0, 2**112 - 1]
// resolution: 1 / 2**112

library UQ112x112 {
    uint224 constant Q112 = 2**112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

// Library when openzepplin Math is not enough
library ExtraMath {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IAuraCallee {
    function AuraCall(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                              EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
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