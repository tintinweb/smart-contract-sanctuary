pragma solidity 0.6.6;

import "./Ownable.sol";
import "./libs/SafeMath.sol";
import "./libs/EnumerableSet.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IOracle.sol";

interface IBSWFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function INIT_CODE_HASH() external pure returns (bytes32);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    function setDevFee(address pair, uint8 _devFee) external;

    function setSwapFee(address pair, uint32 swapFee) external;
}

interface IBSWPair {
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

    function swapFee() external view returns (uint32);

    function devFee() external view returns (uint32);

    function mint(address to) external returns (uint liquidity);

    function burn(address to) external returns (uint amount0, uint amount1);

    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;

    function setSwapFee(uint32) external;

    function setDevFee(uint32) external;
}

interface IBswToken is IERC20 {
    function mint(address to, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external override returns (bool);
}

interface IBiswapNFT {
    function accrueRB(address user, uint amount) external;
    function tokenFreeze(uint tokenId) external;
    function tokenUnfreeze(uint tokenId) external;
    function getRB(uint tokenId) external view returns(uint);
    function getInfoForStaking(uint tokenId) external view returns(address tokenOwner, bool stakeFreeze, uint robiBoost);
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() public {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}


contract SwapFeeRewardWithRB is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private _whitelist;

    address public factory;
    address public router;
    address public market;
    address public auction;
    bytes32 public INIT_CODE_HASH;
    uint256 public maxMiningAmount = 100000000 ether;
    uint256 public maxMiningInPhase = 5000 ether;
    uint public maxAccruedRBInPhase = 5000 ether;

    uint public currentPhase = 1;
    uint public currentPhaseRB = 1;
    uint256 public totalMined = 0;
    uint public totalAccruedRB = 0;
    uint public rbWagerOnSwap = 1500; //Wager of RB
    uint public rbPercentMarket = 10000; // (div 10000)
    uint public rbPercentAuction = 10000; // (div 10000)
    IBswToken public bswToken;
    IOracle public oracle;
    IBiswapNFT public biswapNFT;
    address public targetToken;
    address public targetRBToken;
    uint public defaultFeeDistribution = 90;

    mapping(address => uint) public nonces;
    mapping(address => uint256) private _balances;
    mapping(address => uint256) public pairOfPid;

    //percent of distribution between feeReward and robiBoost [0, 90] 0 => 90% feeReward and 10% robiBoost; 90 => 100% robiBoost
    //calculate: defaultFeeDistribution (90) - feeDistibution = feeReward
    mapping(address => uint) public feeDistribution;

    struct PairsList {
        address pair;
        uint256 percentReward;
        bool enabled;
    }

    PairsList[] public pairsList;

    event Withdraw(address userAddress, uint256 amount);
    event Rewarded(address account, address input, address output, uint256 amount, uint256 quantity);
    //BNF-01, SFR-01
    event NewRouter(address);
    event NewFactory(address);
    event NewMarket(address);
    event NewPhase(uint);
    event NewPhaseRB(uint);
    event NewAuction(address);
    event NewBiswapNFT(IBiswapNFT);
    event NewOracle(IOracle);

    modifier onlyRouter() {
        require(msg.sender == router, "SwapFeeReward: caller is not the router");
        _;
    }

    modifier onlyMarket() {
        require(msg.sender == market, "SwapFeeReward: caller is not the market");
        _;
    }

    modifier onlyAuction() {
        require(msg.sender == auction, "SwapFeeReward: caller is not the auction");
        _;
    }

    constructor(
        address _factory,
        address _router,
        bytes32 _INIT_CODE_HASH,
        IBswToken _bswToken,
        IOracle _Oracle,
        IBiswapNFT _biswapNFT,
        address _targetToken,
        address _targetRBToken

    ) public {
        //SFR-03
        require(
            _factory != address(0)
            && _router != address(0)
            && _targetToken != address(0)
            && _targetRBToken != address(0),
            "Address can not be zero"
        );
        factory = _factory;
        router = _router;
        INIT_CODE_HASH = _INIT_CODE_HASH;
        bswToken = _bswToken;
        oracle = _Oracle;
        targetToken = _targetToken;
        biswapNFT = _biswapNFT;
        targetRBToken = _targetRBToken;
    }

    function sortTokens(address tokenA, address tokenB) public pure returns (address token0, address token1) {
        require(tokenA != tokenB, "BSWSwapFactory: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "BSWSwapFactory: ZERO_ADDRESS");
    }

    function pairFor(address tokenA, address tokenB) public view returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                INIT_CODE_HASH
            ))));
    }

    function getSwapFee(address tokenA, address tokenB) internal view returns (uint swapFee) {
        //SFR-05
        swapFee = uint(1000).sub(IBSWPair(pairFor(tokenA, tokenB)).swapFee());
        //        swapFee = uint(10000).sub(10); //TODO del in prod!!!
    }

    function setPhase(uint _newPhase) public onlyOwner returns (bool){
        currentPhase = _newPhase;
        //BNF-01, SFR-01
        emit NewPhase(_newPhase);
        return true;
    }

    function setPhaseRB(uint _newPhase) public onlyOwner returns (bool){
        currentPhaseRB = _newPhase;
        //BNF-01, SFR-01
        emit NewPhaseRB(_newPhase);
        return true;
    }

    function checkPairExist(address tokenA, address tokenB) public view returns (bool) {
        address pair = pairFor(tokenA, tokenB);
        PairsList storage pool = pairsList[pairOfPid[pair]];
        if (pool.pair != pair) {
            return false;
        }
        return true;
    }

    function feeCalculate(address account, address input, address output, uint256 amount)
    public
    view
    returns(
        uint feeReturnInBSW,
        uint feeReturnInUSD,
        uint robiBoostAccrue
    )
    {

        uint256 pairFee = getSwapFee(input, output);
        address pair = pairFor(input, output);
        PairsList memory pool = pairsList[pairOfPid[pair]];
        if (pool.pair != pair || pool.enabled == false || !isWhitelist(input) || !isWhitelist(output)) {
            feeReturnInBSW = 0;
            feeReturnInUSD = 0;
            robiBoostAccrue = 0;
        } else {
            (uint feeAmount, uint rbAmount) = calcAmounts(amount, account);
            uint256 fee = feeAmount.div(pairFee);
            uint256 quantity = getQuantity(output, fee, targetToken);
            feeReturnInBSW = quantity.mul(pool.percentReward).div(100);
            robiBoostAccrue = getQuantity(output, rbAmount.div(rbWagerOnSwap), targetRBToken);
            feeReturnInUSD = getQuantity(targetToken, feeReturnInBSW, targetRBToken);
        }
    }

    function swap(address account, address input, address output, uint256 amount) public onlyRouter returns (bool) {
        if (!isWhitelist(input) || !isWhitelist(output)) {
            return false;
        }
        address pair = pairFor(input, output);
        PairsList memory pool = pairsList[pairOfPid[pair]];
        if (pool.pair != pair || pool.enabled == false) {
            return false;
        }
        uint256 pairFee = getSwapFee(input, output);
        (uint feeAmount, uint rbAmount) = calcAmounts(amount, account);
        uint256 fee = feeAmount.div(pairFee);
        rbAmount = rbAmount.div(rbWagerOnSwap);
        //SFR-05
        _accrueRB(account, output, rbAmount);

        uint256 quantity = getQuantity(output, fee, targetToken);
        quantity = quantity.mul(pool.percentReward).div(100);
        if (maxMiningAmount >= totalMined.add(quantity)) {
            if (totalMined.add(quantity) <= currentPhase.mul(maxMiningInPhase)) {
                _balances[account] = _balances[account].add(quantity);
                emit Rewarded(account, input, output, amount, quantity);
            }
        }
        return true;
    }

    function calcAmounts(uint amount, address account) internal view returns(uint feeAmount, uint rbAmount){
        feeAmount = amount.mul(defaultFeeDistribution.sub(feeDistribution[account])).div(100);
        rbAmount = amount.sub(feeAmount);
    }

    function accrueRBFromMarket(address account, address fromToken, uint amount) public onlyMarket {
        //SFR-05
        amount = amount.mul(rbPercentMarket).div(10000);
        _accrueRB(account, fromToken, amount);
    }

    function accrueRBFromAuction(address account, address fromToken, uint amount) public onlyAuction {
        //SFR-05
        amount = amount.mul(rbPercentAuction).div(10000);
        _accrueRB(account, fromToken, amount);
    }

    //SFR-05
    function _accrueRB(address account, address output, uint amount) private {
        uint quantity = getQuantity(output, amount, targetRBToken);
        if (quantity > 0) {
            //SFR-06
            totalAccruedRB = totalAccruedRB.add(quantity);
            if(totalAccruedRB <= currentPhaseRB.mul(maxAccruedRBInPhase)){
                biswapNFT.accrueRB(account, quantity);
            }
        }
    }

    function rewardBalance(address account) public view returns (uint256){
        return _balances[account];
    }

    function permit(address spender, uint value, uint8 v, bytes32 r, bytes32 s) private {
        bytes32 message = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(spender, value, nonces[spender]++))));
        address recoveredAddress = ecrecover(message, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == spender, "SwapFeeReward: INVALID_SIGNATURE");
    }

    //BNF-02, SCN-01, SFR-02
    function withdraw(uint8 v, bytes32 r, bytes32 s) public nonReentrant returns (bool){
        require(maxMiningAmount > totalMined, "SwapFeeReward: Mined all tokens");
        uint256 balance = _balances[msg.sender];
        require(totalMined.add(balance) <= currentPhase.mul(maxMiningInPhase), "SwapFeeReward: Mined all tokens in this phase");
        permit(msg.sender, balance, v, r, s);
        if (balance > 0) {
            _balances[msg.sender] = _balances[msg.sender].sub(balance);
            totalMined = totalMined.add(balance);
            //SFR-04
            if(bswToken.transfer(msg.sender, balance)){
                emit Withdraw(msg.sender, balance);
                return true;
            }
        }
        return false;
    }

    function getQuantity(address outputToken, uint256 outputAmount, address anchorToken) public view returns (uint256) {
        uint256 quantity = 0;
        if (outputToken == anchorToken) {
            quantity = outputAmount;
        } else if (IBSWFactory(factory).getPair(outputToken, anchorToken) != address(0) && checkPairExist(outputToken, anchorToken)) {
            quantity = IOracle(oracle).consult(outputToken, outputAmount, anchorToken);
        } else {
            uint256 length = getWhitelistLength();
            for (uint256 index = 0; index < length; index++) {
                address intermediate = getWhitelist(index);
                if (IBSWFactory(factory).getPair(outputToken, intermediate) != address(0) && IBSWFactory(factory).getPair(intermediate, anchorToken) != address(0) && checkPairExist(intermediate, anchorToken)) {
                    uint256 interQuantity = IOracle(oracle).consult(outputToken, outputAmount, intermediate);
                    quantity = IOracle(oracle).consult(intermediate, interQuantity, anchorToken);
                    break;
                }
            }
        }
        return quantity;
    }

    function addWhitelist(address _addToken) public onlyOwner returns (bool) {
        require(_addToken != address(0), "SwapMining: token is the zero address");
        return EnumerableSet.add(_whitelist, _addToken);
    }

    function delWhitelist(address _delToken) public onlyOwner returns (bool) {
        require(_delToken != address(0), "SwapMining: token is the zero address");
        return EnumerableSet.remove(_whitelist, _delToken);
    }

    function getWhitelistLength() public view returns (uint256) {
        return EnumerableSet.length(_whitelist);
    }

    function isWhitelist(address _token) public view returns (bool) {
        return EnumerableSet.contains(_whitelist, _token);
    }

    function getWhitelist(uint256 _index) public view returns (address){
        //SFR-06
        require(_index <= getWhitelistLength().sub(1), "SwapMining: index out of bounds");
        return EnumerableSet.at(_whitelist, _index);
    }

    function setRouter(address newRouter) public onlyOwner {
        require(newRouter != address(0), "SwapMining: new router is the zero address");
        router = newRouter;
        //BNF-01, SFR-01
        emit NewRouter(newRouter);
    }

    function setMarket(address _market) public onlyOwner {
        require(_market != address(0), "SwapMining: new market is the zero address");
        market = _market;
        //BNF-01, SFR-01
        emit NewMarket(_market);
    }

    function setAuction(address _auction) public onlyOwner {
        require(_auction != address(0), "SwapMining: new auction is the zero address");
        auction = _auction;
        //BNF-01, SFR-01
        emit NewAuction(_auction);
    }

    function setBiswapNFT(IBiswapNFT _biswapNFT) public onlyOwner {
        require(address(_biswapNFT) != address(0), "SwapMining: new biswapNFT is the zero address");
        biswapNFT = _biswapNFT;
        //BNF-01, SFR-01
        emit NewBiswapNFT(_biswapNFT);
    }

    function setOracle(IOracle _oracle) public onlyOwner {
        require(address(_oracle) != address(0), "SwapMining: new oracle is the zero address");
        oracle = _oracle;
        //BNF-01, SFR-01
        emit NewOracle(_oracle);
    }

    function setFactory(address _factory) public onlyOwner {
        require(_factory != address(0), "SwapMining: new factory is the zero address");
        factory = _factory;
        //BNF-01, SFR-01
        emit NewFactory(_factory);
    }

    function setInitCodeHash(bytes32 _INIT_CODE_HASH) public onlyOwner {
        INIT_CODE_HASH = _INIT_CODE_HASH;
    }

    function pairsListLength() public view returns (uint256) {
        return pairsList.length;
    }

    function addPair(uint256 _percentReward, address _pair) public onlyOwner {
        require(_pair != address(0), "_pair is the zero address");
        pairsList.push(
            PairsList({
        pair : _pair,
        percentReward : _percentReward,
        enabled : true
        })
        );
        //SFR-06
        pairOfPid[_pair] = pairsListLength().sub(1);

    }

    function setPair(uint256 _pid, uint256 _percentReward) public onlyOwner {
        pairsList[_pid].percentReward = _percentReward;
    }

    function setPairEnabled(uint256 _pid, bool _enabled) public onlyOwner {
        pairsList[_pid].enabled = _enabled;
    }

    function setRobiBoostReward(uint _rbWagerOnSwap, uint _percentMarket, uint _percentAuction) public onlyOwner {
        rbWagerOnSwap = _rbWagerOnSwap;
        rbPercentMarket = _percentMarket;
        rbPercentAuction = _percentAuction;
    }

    function setFeeDistribution(uint newDistribution) public {
        require(newDistribution <= defaultFeeDistribution, "Wrong fee distribution");
        feeDistribution[msg.sender] = newDistribution;
    }

}

pragma solidity =0.6.6;
contract Ownable {
    address private _owner;

    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function isOwner(address account) public view returns (bool) {
        return account == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }


    modifier onlyOwner() {
        require(isOwner(msg.sender), "Ownable: caller is not the owner");
        _;
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}

pragma solidity 0.6.6;
library SafeMath {
    uint256 constant WAD = 10 ** 18;
    uint256 constant RAY = 10 ** 27;

    function wad() public pure returns (uint256) {
        return WAD;
    }

    function ray() public pure returns (uint256) {
        return RAY;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

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

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a <= b ? a : b;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function sqrt(uint256 a) internal pure returns (uint256 b) {
        if (a > 3) {
            b = a;
            uint256 x = a / 2 + 1;
            while (x < b) {
                b = x;
                x = (a / x + x) / 2;
            }
        } else if (a != 0) {
            b = 1;
        }
    }

    function wmul(uint256 a, uint256 b) internal pure returns (uint256) {
        return mul(a, b) / WAD;
    }

    function wmulRound(uint256 a, uint256 b) internal pure returns (uint256) {
        return add(mul(a, b), WAD / 2) / WAD;
    }

    function rmul(uint256 a, uint256 b) internal pure returns (uint256) {
        return mul(a, b) / RAY;
    }

    function rmulRound(uint256 a, uint256 b) internal pure returns (uint256) {
        return add(mul(a, b), RAY / 2) / RAY;
    }

    function wdiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(mul(a, WAD), b);
    }

    function wdivRound(uint256 a, uint256 b) internal pure returns (uint256) {
        return add(mul(a, WAD), b / 2) / b;
    }

    function rdiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(mul(a, RAY), b);
    }

    function rdivRound(uint256 a, uint256 b) internal pure returns (uint256) {
        return add(mul(a, RAY), b / 2) / b;
    }

    function wpow(uint256 x, uint256 n) internal pure returns (uint256) {
        uint256 result = WAD;
        while (n > 0) {
            if (n % 2 != 0) {
                result = wmul(result, x);
            }
            x = wmul(x, x);
            n /= 2;
        }
        return result;
    }

    function rpow(uint256 x, uint256 n) internal pure returns (uint256) {
        uint256 result = RAY;
        while (n > 0) {
            if (n % 2 != 0) {
                result = rmul(result, x);
            }
            x = rmul(x, x);
            n /= 2;
        }
        return result;
    }
}

pragma solidity 0.6.6;
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

        if (valueIndex != 0) {// Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1;
            // All indexes are 1-based

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
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
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
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
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
        return address(uint256(_at(set._inner, index)));
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
}

pragma solidity 0.6.6;
interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(address from, address to, uint value) external returns (bool);
}

pragma solidity 0.6.6;
interface IOracle {
    function consult(address tokenIn, uint amountIn, address tokenOut) external view returns (uint amountOut);
}