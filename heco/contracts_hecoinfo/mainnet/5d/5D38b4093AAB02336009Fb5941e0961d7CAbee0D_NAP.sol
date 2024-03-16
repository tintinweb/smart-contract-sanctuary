/**
 *Submitted for verification at hecoinfo.com on 2022-05-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

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
        mapping (bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) { // Equivalent to contains(set, value)
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
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

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
interface IXFFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    
    function blacklist(address _addr) external view returns (bool);

    function feeToSetter() external view returns (address);

    function feeToRate() external view returns (uint256);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    function setFeeToRate(uint256) external;

    function sortTokens(address tokenA, address tokenB) external pure returns (address token0, address token1);

    function pairFor(address tokenA, address tokenB) external view returns (address pair);

    function getReserves(address tokenA, address tokenB) external view returns (uint256 reserveA, uint256 reserveB);

    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) external pure returns (uint256 amountB);

    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) external view returns (uint256 amountOut);

    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut) external view returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}


interface IXFPair {
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

    function price(address token, uint256 baseDecimal) external view returns (uint256);

    function initialize(address, address) external;
}
// a library for performing overflow-safe math, updated with awesomeness from of DappHub (https://github.com/dapphub/ds-math)
library BoringMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {require((c = a + b) >= b, "BoringMath: Add Overflow");}
    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {require((c = a - b) <= a, "BoringMath: Underflow");}
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {require(b == 0 || (c = a * b)/b == a, "BoringMath: Mul Overflow");}
    function to128(uint256 a) internal pure returns (uint128 c) {
        require(a <= uint128(-1), "BoringMath: uint128 Overflow");
        c = uint128(a);
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
}

library BoringMath128 {
    function add(uint128 a, uint128 b) internal pure returns (uint128 c) {require((c = a + b) >= b, "BoringMath: Add Overflow");}
    function sub(uint128 a, uint128 b) internal pure returns (uint128 c) {require((c = a - b) <= a, "BoringMath: Underflow");}
}


library BoringERC20 {
    function safeSymbol(IERC20 token) internal view returns(string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x95d89b41));
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    function safeName(IERC20 token) internal view returns(string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x06fdde03));
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    function safeDecimals(IERC20 token) public view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x313ce567));
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    function safeTransfer(IERC20 token, address to, uint256 amount) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0xa9059cbb, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BentoBox: Transfer failed");
    }

    function safeTransferFrom(IERC20 token, address from, uint256 amount) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0x23b872dd, from, address(this), amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BentoBox: TransferFrom failed");
    }
}



// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol + Claimable.sol
// Edited by BoringCrypto

// T1 - T4: OK
contract BoringOwnableData {
    // V1 - V5: OK
    address public _owner;
    // V1 - V5: OK
    address public pendingOwner;
}

// T1 - T4: OK
contract BoringOwnable is BoringOwnableData {
    // E1: OK
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    // F1 - F9: OK
    // C1 - C21: OK
    function transferOwnership(address newOwner, bool direct, bool renounce) public onlyOwner {
        if (direct) {
            // Checks
            require(newOwner != address(0) || renounce, "Ownable: zero address");

            // Effects
            emit OwnershipTransferred(_owner, newOwner);
            _owner = newOwner;
            pendingOwner = newOwner;
        } else {
            // Effects
            pendingOwner = newOwner;
        }
    }

    // F1 - F9: OK
    // C1 - C21: OK
    function claimOwnership() public {
        address _pendingOwner = pendingOwner;

        // Checks
        require(msg.sender == _pendingOwner, "Ownable: caller != pending owner");

        // Effects
        emit OwnershipTransferred(_owner, _pendingOwner);
        _owner = _pendingOwner;
        pendingOwner = address(0);
    }

    // M1 - M5: OK
    // C1 - C21: OK
    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _;
    }
}

interface IDistribution {
    function affiliatedAmount() external view returns(uint256);
}

interface IStakingRewards {
    // Views
    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function getRewardForDuration() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    // Mutative

    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function getReward() external;

    function exit() external;
}

contract NAP is BoringOwnable {
    using BoringMath for uint256;
    using BoringERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private _settlementTokens;

    // V1 - V5: OK
    IXFFactory public  factory;

    // V1 - V5: OK
    address public  devAddress;

    // x%
    uint256 public ratedev;
    
    uint256 public precirculation;
    
    address public xf;
    
    address public distribution;
    
    mapping(address => bool) public whitelist;
    
    bool public initOnce;

    // V1 - V5: OK
    address public to;
    // V1 - V5: OK
    address public  wht;

    // V1 - V5: OK
    mapping(address => address) internal _bridges;

    // E1: OK
    event LogBridgeSet(address indexed token, address indexed bridge);
    // E1: OK
    event LogConvert(address indexed server, address indexed token0, address indexed token1, uint256 amount0, uint256 amount1, uint256 amountKNS, uint256 amountdev);

    function init(address _distribution,address _factory, address _xf, address _wht, address _devAddress,uint256 _precirculation) public {
        require(initOnce == false,"NAP:already initialize.");
        factory = IXFFactory(_factory);
        xf = _xf;
        distribution = _distribution;
        wht = _wht;
        devAddress = _devAddress;
        ratedev = 10;
        precirculation = _precirculation;
        
        // add husd,usdt to _settlementTokens
        EnumerableSet.add(_settlementTokens, 0x0298c2b32eaE4da002a15f36fdf7615BEa3DA047);
        EnumerableSet.add(_settlementTokens, 0xa71EdC38d189767582C38A3145b5873052c3e47a);
        
        // to is usdt
        to = 0xa71EdC38d189767582C38A3145b5873052c3e47a;
        _owner = msg.sender;
        initOnce = true;
    }

    function swapPrice(address _stoken,uint _amount) public view returns(uint256){
        uint256 allCirculation = precirculation.add(IDistribution(distribution).affiliatedAmount());
        
        uint256 _bu = IERC20(_stoken).balanceOf(address(this));
        return _bu.mul(_amount).div(allCirculation);
    }
    
    function swapPrices(address[] calldata _stoken,uint _amount) public view returns(uint256[5] memory p){
        uint256 allCirculation = precirculation.add(IDistribution(distribution).affiliatedAmount());
        
        uint256 _bu = IERC20(_stoken[0]).balanceOf(address(this));
        p[0] = _bu.mul(_amount).div(allCirculation);
        
        _bu = IERC20(_stoken[1]).balanceOf(address(this));
        p[1] = _bu.mul(_amount).div(allCirculation);
        
        _bu = IERC20(_stoken[2]).balanceOf(address(this));
        p[2] = _bu.mul(_amount).div(allCirculation);
        
        _bu = IERC20(_stoken[3]).balanceOf(address(this));
        p[3] = _bu.mul(_amount).div(allCirculation);
        
        _bu = IERC20(_stoken[4]).balanceOf(address(this));
        p[4] = _bu.mul(_amount).div(allCirculation);
    }
    
    function swap(uint256 _amount) public{
        require(_amount>0,"NAP: Invalid amount");
        IERC20(xf).transferFrom(msg.sender,0x0000000000000000000000000000000000000001,_amount);
        uint256 allCirculation = precirculation.add(IDistribution(distribution).affiliatedAmount());
        
        for(uint256 i = 0; i < getSettlementTokensLength();i++){
            uint256 _b = IERC20(getSettlementTokens(i)).balanceOf(address(this));
            IERC20(getSettlementTokens(i)).transfer(msg.sender, _b.mul(_amount).div(allCirculation));
        }
    }
    
    event Invest(address pool,address token,uint256 amount);
    
    function invest(address _token,address _pool,uint256 _amount) public onlyOwner{
        require(whitelist[_pool] == true,"NAP: Not in whitelist");
        require(_amount > 0,"NAP: Invalid amount");
        require(IERC20(_token).balanceOf(address(this)) > 0,"NAP: Not sufficient funds");
        
        IERC20(_token).approve(_pool, _amount);
        IStakingRewards(_pool).stake(_amount);
        
        emit Invest(_pool,_token,_amount);
    }
    
    function claimFromInvest(address _pool) public onlyOwner{
        IStakingRewards(_pool).getReward();
    }
    
    function exitFromInvest(address _pool) public onlyOwner{
        IStakingRewards(_pool).exit();
    }
    
    function setWhitelist(address pool,bool _isWhitelist) public onlyOwner{
        whitelist[pool] = _isWhitelist;
    }

    function setRateDEV(uint _rateDEV) external onlyOwner {
        require(_rateDEV <= 100, "NAP: Invalid _rateDEV");
        ratedev = _rateDEV;
    }
    
    function changetoToken(address _token) public onlyOwner {
        to = _token;
    }
    
    function addSettlementTokens(address _addToken) public onlyOwner returns (bool) {
        require(_addToken != address(0), "NAP: token is the zero address");
        return EnumerableSet.add(_settlementTokens, _addToken);
    }

    function delSettlementTokens(address _delToken) public onlyOwner returns (bool) {
        require(_delToken != address(0), "NAP: token is the zero address");
        return EnumerableSet.remove(_settlementTokens, _delToken);
    }

    function getSettlementTokensLength() public view returns (uint256) {
        return EnumerableSet.length(_settlementTokens);
    }

    function isSettlementToken(address _token) public view returns (bool) {
        return EnumerableSet.contains(_settlementTokens, _token);
    }

    function getSettlementTokens(uint256 _index) public view returns (address){
        require(_index <= getSettlementTokensLength() - 1, "NAP: index out of bounds");
        return EnumerableSet.at(_settlementTokens, _index);
    }


    // F1 - F10: OK
    // C1 - C24: OK
    function bridgeFor(address token) public view returns (address bridge) {
        bridge = _bridges[token];
        if (bridge == address(0)) {
            bridge = wht;
        }
    }

    // F1 - F10: OK
    // C1 - C24: OK
    function setBridge(address token, address bridge) external onlyOwner {
        // Checks
        require(token != to && token != wht && token != bridge, "NAP: Invalid bridge");

        // Effects
        _bridges[token] = bridge;
        emit LogBridgeSet(token, bridge);
    }

    // M1 - M5: OK
    // C1 - C24: OK
    // C6: It's not a fool proof solution, but it prevents flash loans, so here it's ok to use tx.origin
    modifier onlyEOA() {
        // Try to make flash-loan exploit harder to do.
        require(msg.sender == tx.origin, "NAP: must use EOA");
        _;
    }

    // F1 - F10: OK
    // F3: _convert is separate to save gas by only checking the 'onlyEOA' modifier once in case of convertMultiple
    // F6: There is an exploit to add lots of KNS to the bar, run convert, then remove the KNS again.
    //     As the size of the SushiBar has grown, this requires large amounts of funds and isn't super profitable anymore
    //     The onlyEOA modifier prevents this being done with a flash loan.
    // C1 - C24: OK
    function convert(address token0, address token1) external onlyEOA() {
        _convert(token0, token1);
    }

    // F1 - F10: OK, see convert
    // C1 - C24: OK
    // C3: Loop is under control of the caller
    function convertMultiple(address[] calldata token0, address[] calldata token1) external onlyEOA() {
        require(token0.length == token1.length);
        // TODO: This can be optimized a fair bit, but this is safer and simpler for now
        uint256 len = token0.length;
        for (uint256 i = 0; i < len; i++) {
            _convert(token0[i], token1[i]);
        }
    }
    
    // F1 - F10: OK
    // C1- C24: OK
    function removeLP(address token0, address token1) public onlyOwner returns(uint256 amount0, uint256 amount1){
        // Interactions
        // S1 - S4: OK
        IXFPair pair = IXFPair(factory.getPair(token0, token1));
        require(address(pair) != address(0), "NAP: Invalid pair");
        // balanceOf: S1 - S4: OK
        // transfer: X1 - X5: OK
        IERC20(address(pair)).safeTransfer(address(pair), pair.balanceOf(address(this)));
        // X1 - X5: OK
        (amount0, amount1) = pair.burn(address(this));
        
        if (token0 != pair.token0()) {
            (amount0, amount1) = (amount1, amount0);
        }
        
        IERC20(token0).safeTransfer(devAddress, amount0.mul(ratedev).div(100));
        IERC20(token1).safeTransfer(devAddress, amount1.mul(ratedev).div(100));
    }
    
    function sellToken2(address token0, address token1, uint256 amount0, uint256 amount1) public onlyOwner returns (uint256){
        uint256 toOut = _convertStep(token0, token1, amount0, amount1);
        return toOut;
    }
    
    function sellToken(address token, uint256 amountIn) public onlyOwner returns (uint256){
        uint256 toOut = _toToken(token, amountIn);
        return toOut;
    }

    function emWithdraw(address addr) public onlyOwner {
        uint256 amount = IERC20(to).balanceOf(address(this));
        require(amount > 0, "balance must > 0.");
        IERC20(to).safeTransfer(addr, amount);
    }

    // F1 - F10: OK
    // C1- C24: OK
    function _convert(address token0, address token1) internal {
        // Interactions
        // S1 - S4: OK
        IXFPair pair = IXFPair(factory.getPair(token0, token1));
        require(address(pair) != address(0), "NAP: Invalid pair");
        // balanceOf: S1 - S4: OK
        // transfer: X1 - X5: OK
        IERC20(address(pair)).safeTransfer(address(pair), pair.balanceOf(address(this)));
        // X1 - X5: OK
        (uint256 amount0, uint256 amount1) = pair.burn(address(this));
        if (token0 != pair.token0()) {
            (amount0, amount1) = (amount1, amount0);
        }
        uint256 toOut = _convertStep(token0, token1, amount0, amount1);
        IERC20(to).safeTransfer(devAddress, toOut.mul(ratedev).div(100));
        emit LogConvert(msg.sender, token0, token1, amount0, amount1, toOut, toOut.mul(ratedev).div(100));
    }

    // F1 - F10: OK
    // C1 - C24: OK
    // All safeTransfer, _swap, _toXF, _convertStep: X1 - X5: OK
    function _convertStep(address token0, address token1, uint256 amount0, uint256 amount1) internal returns (uint256 toOut) {
        // Interactions
        if (token0 == token1) {
            uint256 amount = amount0.add(amount1);
            if (token0 == to) {
                toOut = amount;
            } else if (token0 == wht) {
                toOut = _toToken(wht, amount);
            } else {
                address bridge = bridgeFor(token0);
                amount = _swap(token0, bridge, amount, address(this));
                toOut = _convertStep(bridge, bridge, amount, 0);
            }
        } else if (token0 == to) {// eg. XF - ETH
            toOut = _toToken(token1, amount1).add(amount0);
        } else if (token1 == to) {// eg. USDT - XF
            toOut = _toToken(token0, amount0).add(amount1);
        } else if (token0 == wht) {// eg. ETH - USDC
            toOut = _toToken(wht, _swap(token1, wht, amount1, address(this)).add(amount0));
        } else if (token1 == wht) {// eg. USDT - ETH
            toOut = _toToken(wht, _swap(token0, wht, amount0, address(this)).add(amount1));
        } else {// eg. MIC - USDT
            address bridge0 = bridgeFor(token0);
            address bridge1 = bridgeFor(token1);
            if (bridge0 == token1) {// eg. MIC - USDT - and bridgeFor(MIC) = USDT
                toOut = _convertStep(bridge0, token1,
                    _swap(token0, bridge0, amount0, address(this)),
                    amount1
                );
            } else if (bridge1 == token0) {// eg. WBTC - DSD - and bridgeFor(DSD) = WBTC
                toOut = _convertStep(token0, bridge1,
                    amount0,
                    _swap(token1, bridge1, amount1, address(this))
                );
            } else {
                toOut = _convertStep(bridge0, bridge1, // eg. USDT - DSD - and bridgeFor(DSD) = WBTC
                    _swap(token0, bridge0, amount0, address(this)),
                    _swap(token1, bridge1, amount1, address(this))
                );
            }
        }
    }

    // F1 - F10: OK
    // C1 - C24: OK
    // All safeTransfer, swap: X1 - X5: OK
    function _swap(address fromToken, address toToken, uint256 amountIn, address _to) internal returns (uint256 amountOut) {
        // Checks
        // X1 - X5: OK
        IXFPair pair = IXFPair(factory.getPair(fromToken, toToken));
        require(address(pair) != address(0), "NAP: Cannot convert");

        // Interactions
        // X1 - X5: OK
        (uint256 reserve0, uint256 reserve1,) = pair.getReserves();
        uint256 amountInWithFee = amountIn.mul(997);
        if (fromToken == pair.token0()) {
            amountOut = amountIn.mul(997).mul(reserve1) / reserve0.mul(1000).add(amountInWithFee);
            IERC20(fromToken).safeTransfer(address(pair), amountIn);
            pair.swap(0, amountOut, _to, new bytes(0));
            // TODO: Add maximum slippage?
        } else {
            amountOut = amountIn.mul(997).mul(reserve0) / reserve1.mul(1000).add(amountInWithFee);
            IERC20(fromToken).safeTransfer(address(pair), amountIn);
            pair.swap(amountOut, 0, _to, new bytes(0));
            // TODO: Add maximum slippage?
        }
    }

    // F1 - F10: OK
    // C1 - C24: OK
    function _toToken(address token, uint256 amountIn) internal returns (uint256 amountOut) {
        // X1 - X5: OK
        amountOut = _swap(token, to, amountIn, address(this));
    }
}