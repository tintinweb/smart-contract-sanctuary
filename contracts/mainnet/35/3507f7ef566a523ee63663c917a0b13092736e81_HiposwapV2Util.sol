// File: contracts/libraries/SafeMath.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

// File: contracts/libraries/Math.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

// a library for performing various math operations

library Math {
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

// File: contracts/interfaces/IERC20.sol

pragma solidity >=0.5.0;

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

// File: contracts/interfaces/IHiposwapV1Callee.sol

pragma solidity >=0.5.0;

interface IHiposwapV1Callee {
    function hiposwapV1Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

// File: contracts/interfaces/IHiposwapV2Pair.sol

pragma solidity >=0.5.0;

interface IHiposwapV2Pair {
    

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
    event Sync(uint reserve0, uint reserve1);
    event _Maker(address indexed sender, address token, uint amount, uint time);

    
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function currentPoolId0() external view returns (uint);
    function currentPoolId1() external view returns (uint);
    function getMakerPool0(uint poolId) external view returns (uint _balance, uint _swapOut, uint _swapIn);
    function getMakerPool1(uint poolId) external view returns (uint _balance, uint _swapOut, uint _swapIn);
    function getReserves() external view returns (uint reserve0, uint reserve1);
    function getBalance() external view returns (uint _balance0, uint _balance1);
    function getMaker(address mkAddress) external view returns (uint,address,uint,uint);
    function getFees() external view returns (uint _fee0, uint _fee1);
    function getFeeAdmins() external view returns (uint _feeAdmin0, uint _feeAdmin1);
    function getAvgTimes() external view returns (uint _avgTime0, uint _avgTime1);
    function transferFeeAdmin(address to) external;
    function getFeePercents() external view returns (uint _feeAdminPercent, uint _feePercent, uint _totalPercent);
    function setFeePercents(uint _feeAdminPercent, uint _feePercent, uint _totalPercent) external;
    function getRemainPercent() external view returns (uint);
    function getTotalPercent() external view returns (uint);
    
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function order(address to) external returns (address token, uint amount);
    function retrieve(uint amount0, uint amount1, address sender, address to) external returns (uint, uint);
    function getAmountA(address to, uint amountB) external view returns(uint amountA, uint _amountB, uint rewardsB, uint remainA);
    function getAmountB(address to, uint amountA) external view returns(uint _amountA, uint amountB, uint rewardsB, uint remainA);

    function initialize(address, address) external;
}

// File: openzeppelin-solidity/contracts/GSN/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

// File: openzeppelin-solidity/contracts/access/Ownable.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
contract Ownable is Context {
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

// File: contracts/HiposwapV2Pair.sol

pragma solidity =0.6.6;







contract HiposwapV2Pair is IHiposwapV2Pair, Ownable {
    using SafeMath  for uint;
    
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));
    
    address public override factory;
    address public override token0;
    address public override token1;
    
    uint private fee0;
    uint private fee1;
    
    uint private feeAdmin0;
    uint private feeAdmin1;
    
    uint public totalWeightTime0;
    uint public totalWeightTime1;
    
    uint public totalTokens0;
    uint public totalTokens1;
    
    uint private avgTime0;
    uint private avgTime1;
    
    uint private reserve0;
    uint private reserve1;
    
    uint private feeAdminPercent = 5;
    uint private feePercent = 10;
    uint private totalPercent = 10000;
    
    struct MakerPool {
        uint balance; // remain tokenA
        uint swapOut; // swapped tokenA
        uint swapIn; // received tokenB
        uint createTime;
    }
    
    MakerPool[] public makerPools0;
    MakerPool[] public makerPools1;
    
    uint public override currentPoolId0;
    uint public override currentPoolId1;
    
    struct Maker {
        uint poolId;
        address token;
        uint amount;
        uint time;
    }
    mapping(address => Maker) private makers;
    
    uint public constant MINIMUM_SWITCH_POOL_TIME = 30 minutes;
    
    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'HiposwapV2Pair: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }
    
    function getReserves() public override view returns (uint _reserve0, uint _reserve1) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
    }
    
    function getFees() public override view returns (uint _fee0, uint _fee1) {
        _fee0 = fee0;
        _fee1 = fee1;
    }
    
    function getFeeAdmins() public override view returns (uint _feeAdmin0, uint _feeAdmin1) {
        _feeAdmin0 = feeAdmin0;
        _feeAdmin1 = feeAdmin1;
    }
    
    function getAvgTimes() public override view returns (uint _avgTime0, uint _avgTime1) {
        _avgTime0 = avgTime0;
        _avgTime1 = avgTime1;
    }
    
    function getFeePercents() public override view returns (uint _feeAdminPercent, uint _feePercent, uint _totalPercent) {
        _feeAdminPercent = feeAdminPercent;
        _feePercent = feePercent;
        _totalPercent = totalPercent;
    }
    
    function getRemainPercent() public override view returns (uint) {
        return totalPercent.sub(feeAdminPercent).sub(feePercent);
    }
    
    function getTotalPercent() external override view returns (uint) {
        return totalPercent;
    }
    
    function setFeePercents(uint _feeAdminPercent, uint _feePercent, uint _totalPercent) public override onlyOwner {
        require(_feeAdminPercent.add(_feePercent) < _totalPercent, "HiposwapV2Pair: INVALID_PARAM");
        feeAdminPercent = _feeAdminPercent;
        feePercent = _feePercent;
        totalPercent = _totalPercent;
    }
    
    function getBalance() public override view returns (uint _balance0, uint _balance1) {
        _balance0 = IERC20(token0).balanceOf(address(this));
        _balance1 = IERC20(token1).balanceOf(address(this));
    }
    
    function getMaker(address mkAddress) public override view returns (uint,address,uint,uint) {
        Maker memory m = makers[mkAddress];
        return (m.poolId, m.token, m.amount, m.time);
    }
    
    function getMakerPool0(uint poolId) public override view returns (uint _balance, uint _swapOut, uint _swapIn) {
        return _getMakerPool(true, poolId);
    }
    
    function getMakerPool1(uint poolId) public override view returns (uint _balance, uint _swapOut, uint _swapIn) {
        return _getMakerPool(false, poolId);
    }
    
    function _getMakerPool(bool left, uint poolId) private view returns (uint _balance, uint _swapOut, uint _swapIn) {
        MakerPool[] memory mps = left ? makerPools0 : makerPools1;
        if (mps.length > poolId) {
            MakerPool memory mp = mps[poolId];
            return (mp.balance, mp.swapOut, mp.swapIn);
        }
    }
    
    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'HiposwapV2Pair: TRANSFER_FAILED');
    }

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
    event Sync(uint reserve0, uint reserve1);
    event _Maker(address indexed sender, address token, uint amount, uint time);
    
    constructor() public {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1) external override {
        require(msg.sender == factory, 'HiposwapV2Pair: FORBIDDEN'); // sufficient check
        token0 = _token0;
        token1 = _token1;
    }
    
    function checkMakerPool(bool left) private {
        MakerPool[] storage mps = left ? makerPools0 : makerPools1;
        uint currentPoolId = left ? currentPoolId0 : currentPoolId1;
        if (mps.length > 0) {
            MakerPool storage mp = mps[currentPoolId];
            if (mp.swapOut > mp.balance.mul(9) && now > mp.createTime.add(MINIMUM_SWITCH_POOL_TIME)) {
                mps.push(MakerPool(0, 0, 0, now));
                if (left) {
                    currentPoolId0 = currentPoolId0.add(1);
                    mp.swapIn = mp.swapIn.add(fee1);
                    fee1 = 0;
                    totalWeightTime0 = 0;
                    totalTokens0 = 0;
                    avgTime0 = 0;
                } else {
                    currentPoolId1 = currentPoolId1.add(1);
                    mp.swapIn = mp.swapIn.add(fee0);
                    fee0 = 0;
                    totalWeightTime1 = 0;
                    totalTokens1 = 0;
                    avgTime1 = 0;
                }
            }
        } else {
            mps.push(MakerPool(0, 0, 0, now));
        }
    }
    
    function addFee(bool left, uint fee, uint feeAdmin) private {
        if (left) {
            fee1 = fee1.add(fee);
            feeAdmin1 = feeAdmin1.add(feeAdmin);
        } else {
            fee0 = fee0.add(fee);
            feeAdmin0 = feeAdmin0.add(feeAdmin);
        }
    }
    
    
    function checkAvgTime(bool left, uint time) private view returns (bool isChargeFee) {
        if (left) {
            if(avgTime0 > 0){
                isChargeFee = now < time.add(avgTime0);
            }
        } else {
            if(avgTime1 > 0){
                isChargeFee = now < time.add(avgTime1);
            }
        }
    }
    
    function updateAvgTime(bool left, uint time, uint amount) private {
        if(amount > 0 && now > time) {
            uint weight = (now - time).mul(amount);
            if (left) {
                uint _totalWeightTime0 = totalWeightTime0 + weight;
                if (_totalWeightTime0 >= totalWeightTime0) {
                    totalWeightTime0 = _totalWeightTime0;
                    totalTokens0 = totalTokens0.add(amount);
                    avgTime0 = totalWeightTime0 / totalTokens0;
                } else { // reset if overflow
                    totalWeightTime0 = 0;
                    totalTokens0 = 0;
                }
            } else {
                uint _totalWeightTime1 = totalWeightTime1 + weight;
                if (_totalWeightTime1 >= totalWeightTime1) {
                    totalWeightTime1 = _totalWeightTime1;
                    totalTokens1 = totalTokens1.add(amount);
                    avgTime1 = totalWeightTime1 / totalTokens1;
                } else { // reset if overflow
                    totalWeightTime1 = 0;
                    totalTokens1 = 0;
                }
            }
        }
    }
    
    function transferFeeAdmin(address to) external override onlyOwner{
        require(feeAdmin0 > 0 || feeAdmin1 > 0, "HiposwapV2Pair: EMPTY_ADMIN_FEES");
        if (feeAdmin0 > 0) {
            _safeTransfer(token0, to, feeAdmin0);
            feeAdmin0 = 0;
        }
        if (feeAdmin1 > 0) {
            _safeTransfer(token1, to, feeAdmin1);
            feeAdmin1 = 0;
        }
    }
    
    function order(address to) external override lock returns (address token, uint amount){
        uint amount0 = IERC20(token0).balanceOf(address(this)).sub(reserve0);
        uint amount1 = IERC20(token1).balanceOf(address(this)).sub(reserve1);
        require((amount0 > 0 && amount1 == 0) || (amount0 == 0 && amount1 > 0), "HiposwapV2Pair: INVALID_AMOUNT");
        bool left = amount0 > 0;
        checkMakerPool(left);
        Maker memory mk = makers[to];
        if(mk.amount > 0) {
            require(mk.token == token0 || mk.token == token1, "HiposwapV2Pair: INVALID_TOKEN");
            bool _left = mk.token == token0;
            uint _currentPoolId = _left ? currentPoolId0 : currentPoolId1;
            require(_currentPoolId >= mk.poolId, "HiposwapV2Pair: INVALID_POOL_ID");
            if(_currentPoolId > mk.poolId){
                deal(to);
                mk.amount = 0;
            }else{
                require(left == _left, "HiposwapV2Pair: ONLY_ONE_MAKER_ALLOWED");
            }
        }
        uint currentPoolId = left ? currentPoolId0 : currentPoolId1;
        amount = left ? amount0 : amount1;
        token = left ? token0 : token1;
        makers[to] = Maker(currentPoolId, token, mk.amount.add(amount), now);
        emit _Maker(to, token, amount, now);
        MakerPool storage mp = left ? makerPools0[currentPoolId] : makerPools1[currentPoolId];
        mp.balance = mp.balance.add(amount);
        (reserve0, reserve1) = getBalance();
    }
    
    function deal(address to) public {
        Maker storage mk = makers[to];
        require(mk.token == token0 || mk.token == token1, "HiposwapV2Pair: INVALID_TOKEN");
        bool left = mk.token == token0;
        MakerPool storage mp = left ? makerPools0[mk.poolId] : makerPools1[mk.poolId];
        (uint amountA, uint amountB) = (mk.amount, 0);
        if(mp.swapIn > 0 && mp.swapOut > 0){
            amountB = Math.min(mk.amount.mul(mp.swapIn) / mp.swapOut, mp.swapIn);
            uint swapOut = amountB.mul(mp.swapOut) / mp.swapIn;
            amountA = amountA.sub(swapOut);
            mp.swapIn = mp.swapIn.sub(amountB);
            mp.swapOut = mp.swapOut.sub(swapOut);
        }
        if (amountA > mp.balance) {
            // if swapOut, swapIn, balance = 3, 2, 0; mk.amount = 1; then amountB = 0, amountA = 1;
            uint dust = amountA.sub(mp.balance);
            addFee(!left, dust, 0);
            mp.swapOut = mp.swapOut.sub(dust);
            amountA = mp.balance;
        }
        mp.balance = mp.balance.sub(amountA);
        (uint amount0, uint amount1) = left ? (amountA, amountB) : (amountB, amountA);
        if(amount0 > 0){
            _safeTransfer(token0, to, amount0);
            reserve0 = IERC20(token0).balanceOf(address(this));
        }
        if(amount1 > 0){
            _safeTransfer(token1, to, amount1);
            reserve1 = IERC20(token1).balanceOf(address(this));
        }
        delete makers[to];
    }
    
    function retrieve(uint amount0, uint amount1, address sender, address to) external override lock onlyOwner returns (uint, uint){
        require(amount0 > 0 || amount1 > 0, "HiposwapV2Pair: INVALID_AMOUNT");
        Maker storage mk = makers[sender];
        require(mk.token == token0 || mk.token == token1, "HiposwapV2Pair: INVALID_TOKEN");
        bool left = mk.token == token0;
        
        MakerPool storage mp = left ? makerPools0[mk.poolId] : makerPools1[mk.poolId];
        (uint amountA, uint amountB) = left ? (amount0, amount1) : (amount1, amount0);
        
        bool isChargeFee = mk.poolId == (left ? currentPoolId0 : currentPoolId1) && checkAvgTime(left, mk.time);
        uint amountOrigin = mk.amount;
        if (amountA > 0) {
            uint amountAMax = Math.min(mk.amount, mp.balance);
            uint remain = getRemainPercent();
            amountAMax = isChargeFee ? amountAMax.mul(remain) / totalPercent : amountAMax; // 9985/10000
            require(amountA <= amountAMax, "HiposwapV2Pair: INSUFFICIENT_AMOUNT");
            if(isChargeFee){
                uint fee = amountA.mul(feePercent) / remain; // 10/9985
                uint feeAdmin = amountA.mul(feeAdminPercent) / remain; // = 5/9985
                amountA = amountA.add(fee).add(feeAdmin);
                addFee(!left, fee, feeAdmin);
            }
            mk.amount = mk.amount.sub(amountA);
            mp.balance = mp.balance.sub(amountA);
        }
        
        if (amountB > 0) {
            require(mp.swapIn > 0 && mp.swapOut > 0, "HiposwapV2Pair: INSUFFICIENT_SWAP_BALANCE");
            
            uint amountBMax = Math.min(mp.swapIn, mk.amount.mul(mp.swapIn) / mp.swapOut);
            amountBMax = isChargeFee ? amountBMax.mul(getRemainPercent()) / totalPercent : amountBMax; // 9985/10000
            require(amountB <= amountBMax, "HiposwapV2Pair: INSUFFICIENT_SWAP_AMOUNT");
            
            if(isChargeFee){
                uint fee = amountB.mul(feePercent) / getRemainPercent(); // 10/9985
                uint feeAdmin = amountB.mul(feeAdminPercent) / getRemainPercent(); // = 5/9985
                amountB = amountB.add(fee).add(feeAdmin);
                addFee(left, fee, feeAdmin);
            }else if (mk.poolId == (left ? currentPoolId0 : currentPoolId1)) {
                uint rewards = amountB.mul(feePercent) / totalPercent; // 10/10000
                if(left){
                    if (rewards > fee1) {
                        rewards = fee1;
                    }
                    {
                    uint _amount1 = amount1;
                    amount1 = _amount1.add(rewards);
                    fee1 = fee1.sub(rewards);
                    }
                }else{
                    if (rewards > fee0) {
                        rewards = fee0;
                    }
                    {// avoid stack too deep
                    uint _amount0 = amount0;
                    amount0 = _amount0.add(rewards);
                    fee0 = fee0.sub(rewards);
                    }
                }
            }
            uint _amountA = amountB.mul(mp.swapOut) / mp.swapIn;
            mp.swapIn = mp.swapIn.sub(amountB);
            mk.amount = mk.amount.sub(_amountA);
            mp.swapOut = mp.swapOut.sub(_amountA);
        }
        
        updateAvgTime(left, mk.time, amountOrigin.sub(mk.amount));
        
        if (mk.amount == 0) {
            delete makers[sender];
        }
        if(amount0 > 0){
            _safeTransfer(token0, to, amount0);
            reserve0 = IERC20(token0).balanceOf(address(this));
        }
        if(amount1 > 0){
            _safeTransfer(token1, to, amount1);
            reserve1 = IERC20(token1).balanceOf(address(this));
        }
        return (amount0, amount1);
    }
    
    function getMakerAndPool(address to) private view returns (Maker memory mk, MakerPool memory mp){
        mk = makers[to];
        require(mk.token == token0 || mk.token == token1, "HiposwapV2Pair: INVALID_TOKEN");
        bool left = mk.token == token0;
        uint poolId = mk.poolId;
        uint currentPoolId = left ? currentPoolId0 : currentPoolId1;
        require(poolId >= 0 && poolId <= currentPoolId, "HiposwapV2Pair: INVALID_POOL_ID");
        mp = left ? makerPools0[poolId] : makerPools1[poolId];
    }
    // amountB is exact
    function getAmountA(address to, uint amountB) external override view returns(uint amountA, uint _amountB, uint rewardsB, uint remainA){
        (Maker memory mk, MakerPool memory mp) = getMakerAndPool(to);
        bool left = mk.token == token0;
        uint currentPoolId = left ? currentPoolId0 : currentPoolId1;
        bool isChargeFee = mk.poolId == currentPoolId && checkAvgTime(left, mk.time);
        uint remain = getRemainPercent();
        if(amountB > 0){
            if(mp.swapIn > 0 && mp.swapOut > 0){
                uint mkAmount = isChargeFee ? mk.amount.mul(remain) / totalPercent : mk.amount; // 9985/10000
                uint swapIn = isChargeFee ? mp.swapIn.mul(remain) / totalPercent : mp.swapIn;
                uint amountBMax = Math.min(amountB, Math.min(swapIn, mkAmount.mul(mp.swapIn) / mp.swapOut));
                uint amountAMax = amountBMax.mul(mp.swapOut) / mp.swapIn;
                amountAMax = isChargeFee ? amountAMax.mul(totalPercent) / remain : amountAMax;
                mk.amount = mk.amount.sub(amountAMax);
                _amountB = amountBMax;
                if (!isChargeFee && mk.poolId == currentPoolId) {
                    uint tmp = _amountB; // avoid stack too deep
                    uint rewards = tmp.mul(feePercent) / totalPercent;
                    if(left){
                        if (rewards > fee1) {
                            rewards = fee1;
                        }
                    }else{
                        if (rewards > fee0) {
                            rewards = fee0;
                        }
                    }
                    rewardsB = rewards;
                }
            }
        }
        
        amountA = Math.min(mk.amount, mp.balance);
        remainA = mk.amount.sub(amountA);
        amountA = isChargeFee ? amountA.mul(remain) / totalPercent : amountA;
    }
    // amountA is exact
    function getAmountB(address to, uint amountA) external override view returns(uint _amountA, uint amountB, uint rewardsB, uint remainA){
        (Maker memory mk, MakerPool memory mp) = getMakerAndPool(to);
        bool left = mk.token == token0;
        uint currentPoolId = left ? currentPoolId0 : currentPoolId1;
        bool isChargeFee = mk.poolId == currentPoolId && checkAvgTime(left, mk.time);
        uint remain = getRemainPercent();
        if(amountA > 0){
            uint mkAmount = isChargeFee ? mk.amount.mul(remain) / totalPercent : mk.amount;
            uint mpBalance = isChargeFee ? mp.balance.mul(remain) / totalPercent : mp.balance;
            _amountA = Math.min(Math.min(amountA, mkAmount), mpBalance);
            if (_amountA == mkAmount) {
                mk.amount = 0;
            } else {
                mk.amount = mk.amount.sub(isChargeFee ? _amountA.mul(totalPercent) / remain : _amountA);
            }
        }
        if(mp.swapIn > 0 && mp.swapOut > 0){
            amountB = Math.min(mp.swapIn, mk.amount.mul(mp.swapIn) / mp.swapOut);
            mk.amount = mk.amount.sub(amountB.mul(mp.swapOut) / mp.swapIn);
            if (isChargeFee) {
                amountB = amountB.mul(remain) / totalPercent;
            } else if (mk.poolId == currentPoolId) {
                uint rewards = amountB.mul(feePercent) / totalPercent;
                if(left){
                    if (rewards > fee1) {
                        rewards = fee1;
                    }
                }else{
                    if (rewards > fee0) {
                        rewards = fee0;
                    }
                }
                rewardsB = rewards;
            }
        }
        remainA = mk.amount;
    }
    
    function _update(uint balance0, uint balance1) private {
        require(balance0 <= uint(-1) && balance1 <= uint(-1), 'HiposwapV2Pair: OVERFLOW');
        reserve0 = balance0;
        reserve1 = balance1;
        emit Sync(reserve0, reserve1);
    }
    
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external override lock {
        require(amount0Out > 0 || amount1Out > 0, 'HiposwapV2Pair: INSUFFICIENT_OUTPUT_AMOUNT');
        (uint _reserve0, uint _reserve1) = getReserves(); // gas savings
        require(amount0Out <= _reserve0 && amount1Out <= _reserve1, 'HiposwapV2Pair: INSUFFICIENT_LIQUIDITY');

        uint balance0;
        uint balance1;
        { // scope for _token{0,1}, avoids stack too deep errors
        address _token0 = token0;
        address _token1 = token1;
        require(to != _token0 && to != _token1, 'HiposwapV2Pair: INVALID_TO');
        if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
        if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
        if (data.length > 0) IHiposwapV1Callee(to).hiposwapV1Call(msg.sender, amount0Out, amount1Out, data);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));
        }
        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, 'HiposwapV2Pair: INSUFFICIENT_INPUT_AMOUNT');
        
        if (amount0In > 0) {
            uint fee = amount0In.mul(feePercent) / totalPercent; //  = 10/10000
            uint feeAdmin = amount0In.mul(feeAdminPercent) / totalPercent; // = 5/10000
            uint swapIn = amount0In.sub(fee).sub(feeAdmin);
            MakerPool storage mp = makerPools1[currentPoolId1];
            mp.swapIn = mp.swapIn.add(swapIn);
            mp.swapOut = mp.swapOut.add(amount1Out);
            mp.balance = mp.balance.sub(amount1Out);
            addFee(false, fee, feeAdmin);
        }
        if (amount1In >0) {
            uint fee = amount1In.mul(feePercent) / totalPercent; //  = 10/10000
            uint feeAdmin = amount1In.mul(feeAdminPercent) / totalPercent; // = 5/10000
            uint swapIn = amount1In.sub(fee).sub(feeAdmin);
            MakerPool storage mp = makerPools0[currentPoolId0];
            mp.swapIn = mp.swapIn.add(swapIn);
            mp.swapOut = mp.swapOut.add(amount0Out);
            mp.balance = mp.balance.sub(amount0Out);
            addFee(true, fee, feeAdmin);
        }

        _update(balance0, balance1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }
    
}

// File: contracts/interfaces/IHiposwapV2Util.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

interface IHiposwapV2Util {
    function pairCreationCode() external returns (bytes memory bytecode);
}

// File: contracts/HiposwapV2Util.sol

// SPDX-License-Identifier: MIT
pragma solidity =0.6.6;



contract HiposwapV2Util is IHiposwapV2Util {
    function pairCreationCode() external override returns (bytes memory bytecode){
        bytecode = type(HiposwapV2Pair).creationCode;
    }
}