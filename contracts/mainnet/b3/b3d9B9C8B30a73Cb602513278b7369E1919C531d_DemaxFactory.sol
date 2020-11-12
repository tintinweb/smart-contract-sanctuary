// Dependency file: contracts/libraries/SafeMath.sol

// pragma solidity >=0.5.0;

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

// Dependency file: contracts/libraries/ConfigNames.sol

// pragma solidity >=0.5.16;

library ConfigNames {
    bytes32 public constant PRODUCE_DGAS_RATE = bytes32('PRODUCE_DGAS_RATE');
    bytes32 public constant SWAP_FEE_PERCENT = bytes32('SWAP_FEE_PERCENT');
    bytes32 public constant LIST_DGAS_AMOUNT = bytes32('LIST_DGAS_AMOUNT');
    bytes32 public constant UNSTAKE_DURATION = bytes32('UNSTAKE_DURATION');
    bytes32 public constant REMOVE_LIQUIDITY_DURATION = bytes32('REMOVE_LIQUIDITY_DURATION');
    bytes32 public constant TOKEN_TO_DGAS_PAIR_MIN_PERCENT = bytes32('TOKEN_TO_DGAS_PAIR_MIN_PERCENT');
    bytes32 public constant LIST_TOKEN_FAILURE_BURN_PRECENT = bytes32('LIST_TOKEN_FAILURE_BURN_PRECENT');
    bytes32 public constant LIST_TOKEN_SUCCESS_BURN_PRECENT = bytes32('LIST_TOKEN_SUCCESS_BURN_PRECENT');
    bytes32 public constant PROPOSAL_DGAS_AMOUNT = bytes32('PROPOSAL_DGAS_AMOUNT');
    bytes32 public constant VOTE_DURATION = bytes32('VOTE_DURATION');
    bytes32 public constant VOTE_REWARD_PERCENT = bytes32('VOTE_REWARD_PERCENT');
    bytes32 public constant TOKEN_PENGDING_SWITCH = bytes32('TOKEN_PENGDING_SWITCH');
    bytes32 public constant TOKEN_PENGDING_TIME = bytes32('TOKEN_PENGDING_TIME');
}
// Dependency file: contracts/modules/BaseMintField.sol

// pragma solidity >=0.6.6;
// import '../libraries/SafeMath.sol';

contract BaseMintField {
    using SafeMath for uint;
    struct Productivity {
        uint product;           // user's productivity
        uint total;             // total productivity
        uint block;             // record's block number
        uint user;              // accumulated products
        uint global;            // global accumulated products
    }

    Productivity private global;
    mapping(address => Productivity)    private users;

    event AmountPerBlockChanged (uint oldValue, uint newValue);
    event ProductivityIncreased (address indexed user, uint value);
    event ProductivityDecreased (address indexed user, uint value);

    uint private unlocked = 1;

    modifier lock() {
        require(unlocked == 1, 'Locked');
        unlocked = 0;
        _;
        unlocked = 1;
    }


    // compute productivity returns total productivity of a user.
    function _computeProductivity(Productivity memory user) private view returns (uint) {
        uint blocks = block.number.sub(user.block);
        return user.product + user.total.mul(blocks);
    }

    // update users' productivity by value with boolean value indicating increase  or decrease.
    function _updateProductivity(Productivity storage user, uint value, bool increase) private {
        user.product      = _computeProductivity(user);
        global.product    = _computeProductivity(global);

        require(global.product <= uint(-1), 'BaseMintField: GLOBAL_PRODUCT_OVERFLOW');

        user.block      = block.number;
        global.block    = block.number;
        if(increase) {
            user.total   = user.total.add(value);
            global.total = global.total.add(value);
        }
        else {
            require(user.total >= value, 'BaseMintField: INVALID_DECREASE_USER_POWER');
            require(global.total >= value, 'BaseMintField: INVALID_DECREASE_GLOBAL_POWER');
            user.total   = user.total.sub(value);
            global.total = global.total.sub(value);
        }
    }

    function _increaseProductivity(address user, uint value) internal returns (bool) {
        require(value > 0, 'BaseMintField: PRODUCTIVITY_VALUE_MUST_BE_GREATER_THAN_ZERO');
        Productivity storage product        = users[user];
        _updateProductivity(product, value, true);
        emit ProductivityIncreased(user, value);
        return true;
    }


    function _decreaseProductivity(address user, uint value) internal returns (bool) {
        Productivity storage product = users[user];
        require(value > 0 && product.total >= value, 'BaseMintField: INSUFFICIENT_PRODUCTIVITY');
        _updateProductivity(product, value, false);
        emit ProductivityDecreased(user, value);
        return true;
    }
 
    function _updateProductValue() internal returns (bool) {
        Productivity storage product = users[msg.sender];
        
        product.user  = _computeProductivity(product);
        product.global = _computeProductivity(global);
        
        return true;
    }

    function _computeUserPercentage() internal view returns (uint numerator, uint denominator) {
        Productivity memory product    = users[msg.sender];
        
        uint userProduct     = _computeProductivity(product);
        uint globalProduct   = _computeProductivity(global);

        numerator          = userProduct.sub(product.user);
        denominator        = globalProduct.sub(product.global);
    }
    
}
// Dependency file: contracts/interfaces/IDemaxCallee.sol

// pragma solidity >=0.5.0;

interface IDemaxCallee {
    function demaxCall(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

// Dependency file: contracts/interfaces/IDgas.sol

// pragma solidity >=0.5.0;

interface IDgas {
    function amountPerBlock() external view returns (uint);
    function changeAmountPerBlock(uint value) external returns (bool);
    function getProductivity(address user) external view returns (uint, uint);
    function increaseProductivity(address user, uint value) external returns (bool);
    function decreaseProductivity(address user, uint value) external returns (bool);
    function take() external view returns (uint);
    function takes() external view returns (uint, uint);
    function mint() external returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function upgradeImpl(address _newImpl) external;
    function upgradeGovernance(address _newGovernor) external;
}
// Dependency file: contracts/interfaces/IDemaxFactory.sol

// pragma solidity >=0.5.0;

interface IDemaxFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function contractCodeHash() external view returns (bytes32);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function isPair(address pair) external view returns (bool);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function playerPairs(address player, uint index) external view returns (address pair);
    function getPlayerPairCount(address player) external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);
    function addPlayerPair(address player, address _pair) external returns (bool);
}

// Dependency file: contracts/interfaces/IERC20.sol

// pragma solidity >=0.5.0;

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

// Dependency file: contracts/libraries/UQ112x112.sol

// pragma solidity >=0.5.0;

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

// Dependency file: contracts/libraries/Math.sol

// pragma solidity >=0.5.0;

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

// Dependency file: contracts/interfaces/IDemaxConfig.sol

// pragma solidity >=0.5.0;

interface IDemaxConfig {
    function governor() external view returns (address);
    function PERCENT_DENOMINATOR() external view returns (uint);
    function getConfig(bytes32 _name) external view returns (uint minValue, uint maxValue, uint maxSpan, uint value, uint enable);
    function getConfigValue(bytes32 _name) external view returns (uint);
    function changeConfigValue(bytes32 _name, uint _value) external returns (bool);
    function checkToken(address _token) external view returns(bool);
    function checkPair(address tokenA, address tokenB) external view returns (bool);
    function listToken(address _token) external returns (bool);
    function getDefaultListTokens() external returns (address[] memory);
    function platform() external view returns  (address);
}
// Dependency file: contracts/DemaxPair.sol

// pragma solidity >=0.6.6;

// import './libraries/Math.sol';
// import './libraries/UQ112x112.sol';
// import './interfaces/IERC20.sol';
// import './interfaces/IDemaxFactory.sol';
// import './interfaces/IDgas.sol';
// import './interfaces/IDemaxCallee.sol';
// import './interfaces/IDemaxConfig.sol';
// import './modules/BaseMintField.sol';
// import './libraries/ConfigNames.sol';

contract DemaxPair is BaseMintField {
    uint256 public version = 1;
    using SafeMath for uint256;
    using UQ112x112 for uint224;

    uint256 public constant MINIMUM_LIQUIDITY = 10**3;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    address public FACTORY;
    address public CONFIG;
    address public DGAS;
    address public token0;
    address public token1;

    uint112 private reserve0; // uses single storage slot, accessible via getReserves
    uint112 private reserve1; // uses single storage slot, accessible via getReserves
    uint32 private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;

    uint256 public totalReward;
    uint256 public remainReward;
    mapping(address => uint256) public lastReward;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    event Mint(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, address indexed to, uint256 value);
    event MintDGAS(address indexed player, uint256 pariMint, uint256 userMint);
    mapping(address => uint256) public lastMintBlock;

    function _mint(address to, uint256 value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Mint(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Burn(from, address(0), value);
    }

    function getReserves()
        public
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        )
    {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function _safeTransfer(
        address token,
        address to,
        uint256 value
    ) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'DEMAX PAIR : TRANSFER_FAILED');
    }

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    constructor() public {
        FACTORY = msg.sender;
    }

    modifier onlyPlatform {
        address platform = IDemaxConfig(CONFIG).platform();
        require(msg.sender == platform, 'DEMAX PAIR : FORBIDDEN');
        _;
    }

    // called once by the factory at time of deployment
    function initialize(
        address _token0,
        address _token1,
        address _config,
        address _dgas
    ) external {
        require(msg.sender == FACTORY, 'DEMAX PAIR : FORBIDDEN');
        token0 = _token0;
        token1 = _token1;
        CONFIG = _config;
        DGAS = _dgas;
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(
        uint256 balance0,
        uint256 balance1,
        uint112 _reserve0,
        uint112 _reserve1
    ) private {
        require(balance0 <= uint112(-1) && balance1 <= uint112(-1), 'DEMAX PAIR : OVERFLOW');
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            price0CumulativeLast += uint256(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            price1CumulativeLast += uint256(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    // this low-level function should be called from a contract which performs // important safety checks
    function mint(address to) external onlyPlatform lock returns (uint256 liquidity) {
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        uint256 balance0 = _balanceOf(token0, address(this));
        uint256 balance1 = _balanceOf(token1, address(this));
        uint256 amount0 = balance0.sub(_reserve0);
        uint256 amount1 = balance1.sub(_reserve1);
        uint256 _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
            _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
        }
        require(liquidity > 0, 'DEMAX PAIR : INSUFFICIENT_LIQUIDITY_MINTED');
        _mint(to, liquidity);
        _increaseProductivity(to, liquidity);
        lastMintBlock[to] = block.number;
        _update(balance0, balance1, _reserve0, _reserve1);
        emit Mint(msg.sender, amount0, amount1);
    }

    // this low-level function should be called from a contract which performs // important safety checks
    function burn(
        address from,
        address to,
        uint256 amount
    ) external onlyPlatform lock returns (uint256 amount0, uint256 amount1) {
        require(
            block.number >=
                lastMintBlock[from] + IDemaxConfig(CONFIG).getConfigValue(ConfigNames.REMOVE_LIQUIDITY_DURATION),
            'DEMAX PLATFORM : REMOVE LIQUIDITY DURATION FAIL'
        );
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        uint256 balance0 = _balanceOf(_token0, address(this));
        uint256 balance1 = _balanceOf(_token1, address(this));
        require(balanceOf[from] >= amount, 'DEMAX PAIR : INSUFFICIENT_LIQUIDITY_AMOUNT');

        uint256 _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = amount.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = amount.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, 'DEMAX PAIR : INSUFFICIENT_LIQUIDITY_BURNED');
        _burn(from, amount);
        _decreaseProductivity(from, amount);

        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        balance0 = _balanceOf(_token0, address(this));
        balance1 = _balanceOf(_token1, address(this));
        _update(balance0, balance1, _reserve0, _reserve1);

        emit Burn(msg.sender, amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs // important safety checks
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external onlyPlatform lock {
        require(amount0Out > 0 || amount1Out > 0, 'DEMAX PAIR : INSUFFICIENT_OUTPUT_AMOUNT');
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'DEMAX PAIR :  INSUFFICIENT_LIQUIDITY');
        uint256 balance0;
        uint256 balance1;
        {
            address _token0 = token0;
            address _token1 = token1;
            require(to != _token0 && to != _token1, 'DEMAX PAIR : INVALID_TO');
            if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out);
            if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out);
            if (data.length > 0) IDemaxCallee(to).demaxCall(msg.sender, amount0Out, amount1Out, data);
            balance0 = _balanceOf(_token0, address(this));
            balance1 = _balanceOf(_token1, address(this));
        }
        uint256 amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint256 amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        uint256 _amount0Out = amount0Out;
        uint256 _amount1Out = amount1Out;
        require(amount0In > 0 || amount1In > 0, 'DEMAX PAIR : INSUFFICIENT_INPUT_AMOUNT');
        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, _amount0Out, _amount1Out, to);
    }

    function swapFee(
        uint256 amount,
        address token,
        address to
    ) external onlyPlatform {
        if (amount == 0 || token == to) return;
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves();
        require(to != token0 && to != token1, 'DEMAX PAIR : INVALID_TO');
        _safeTransfer(token, to, amount);
        uint256 balance0 = _balanceOf(token0, address(this));
        uint256 balance1 = _balanceOf(token1, address(this));
        _update(balance0, balance1, _reserve0, _reserve1);
    }

    function queryReward() external view returns (uint256 rewardAmount, uint256 blockNumber) {
        (uint256 numerator, uint256 denominator) = _computeUserPercentage();
        if (denominator > 0) {
            uint256 deltaReward = totalReward.add(IDgas(DGAS).take()).sub(lastReward[msg.sender]);
            rewardAmount = deltaReward.mul(numerator) / denominator;
        }
        blockNumber = block.number;
    }

    function mintReward() external lock returns (uint256 userReward) {
        (uint256 numerator, uint256 denominator) = _computeUserPercentage();
        require(numerator > 0 && denominator > 0, 'DEMAX PAIR : INVALID_REWARD_AMOUNT');

        uint256 pairReward = IDgas(DGAS).mint();
        totalReward = totalReward.add(pairReward);
        uint256 deltaReward = totalReward.sub(lastReward[msg.sender]);
        userReward = deltaReward.mul(numerator) / denominator;
        _safeTransfer(DGAS, msg.sender, userReward);
        _updateProductValue();
        remainReward = remainReward.add(pairReward).sub(userReward);
        lastReward[msg.sender] = totalReward;
        emit MintDGAS(msg.sender, remainReward, userReward);
    }

    function skim(address to) external lock {
        address _token0 = token0;
        address _token1 = token1;
        _safeTransfer(_token0, to, _balanceOf(_token0, address(this)).sub(reserve0));
        _safeTransfer(_token1, to, _balanceOf(_token0, address(this)).sub(reserve1));
    }

    function getDGASReserve() public view returns (uint256) {
        return _balanceOf(DGAS, address(this));
    }

    function _balanceOf(address token, address owner) internal view returns (uint256) {
        if (token == DGAS && owner == address(this)) {
            return IERC20(token).balanceOf(owner).sub(remainReward);
        } else {
            return IERC20(token).balanceOf(owner);
        }
    }

    // force reserves to match balances
    function sync() external lock {
        _update(_balanceOf(token0, address(this)), _balanceOf(token1, address(this)), reserve0, reserve1);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.6;

// import './DemaxPair.sol';
// import './interfaces/IDemaxConfig.sol';

contract DemaxFactory {
    uint256 public version = 1;
    address public DGAS;
    address public CONFIG;
    mapping(address => mapping(address => address)) public getPair;
    mapping(address => bool) public isPair;
    address[] public allPairs;

    mapping(address => address[]) public playerPairs;
    mapping(address => mapping(address => bool)) isAddPlayerPair;

    bytes32 public contractCodeHash;
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    constructor(address _DGAS, address _CONFIG) public {
        DGAS = _DGAS;
        CONFIG = _CONFIG;
    }

    function getPlayerPairCount(address player) external view returns (uint256) {
        address[] storage existAddress = playerPairs[player];
        if (existAddress.length == 0) return 0;
        return existAddress.length;
    }

    function addPlayerPair(address _player, address _pair) external returns (bool) {
        require(msg.sender == IDemaxConfig(CONFIG).platform(), 'DEMAX FACTORY: PERMISSION');
        if (isAddPlayerPair[_player][_pair] == false) {
            isAddPlayerPair[_player][_pair] = true;
            playerPairs[_player].push(_pair);
        }
        return true;
    }

    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, 'DEMAX FACTORY: IDENTICAL_ADDRESSES');
        require(
            IDemaxConfig(CONFIG).checkToken(tokenA) && IDemaxConfig(CONFIG).checkToken(tokenB),
            'DEMAX FACTORY: NOT LIST'
        );
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'DEMAX FACTORY: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'DEMAX FACTORY: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(DemaxPair).creationCode;
        if (uint256(contractCodeHash) == 0) {
            contractCodeHash = keccak256(bytecode);
        }
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        isPair[pair] = true;
        DemaxPair(pair).initialize(token0, token1, CONFIG, DGAS);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }
}