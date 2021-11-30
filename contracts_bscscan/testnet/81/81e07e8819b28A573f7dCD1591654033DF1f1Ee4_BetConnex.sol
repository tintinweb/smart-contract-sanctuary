/**
 *Submitted for verification at BscScan.com on 2021-11-30
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

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

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IAccessControl {
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    function hasRole(bytes32 role, address account) external view returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;
}

abstract contract AccessControl is Context, IAccessControl {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(DEFAULT_ADMIN_ROLE)) {
        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(DEFAULT_ADMIN_ROLE)) {
        _revokeRole(role, account);
    }

    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    
    function toString(uint256 value) internal pure returns (string memory) {
    
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

interface Lottery {
    function buyWeeklyLotteryTickets( address _ticketBuyer) external;
    function buyMegaLotteryTickets( address _ticketBuyer) external;
}

contract ERC20 is IERC20, Context {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 internal _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(string memory __name, string memory __symbol) {
        _name = __name;
        _symbol = __symbol;
        _decimals = 18;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
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
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
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
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()] - amount
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
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
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] - subtractedValue
        );
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] -= amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

contract BetConnexCore is ERC20 {
    
    event StartLottery(uint indexed _lotteryID, LotteryStruct _lotteryGame, uint indexed _lotteryType);
    event FinishLottery(uint indexed _lotteryID, address[2] _winer, uint[2] _winingAmount, uint _timestamp, uint indexed _lotteryType);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
    
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant AUTH_ROLE = keccak256("AUTH_ROLE");
    bytes32 public constant BUY_ORDER = keccak256("BUY_ORDER");
    bytes32 public constant SELL_ORDER = keccak256("SELL_ORDER");
    
    // instance of an router
    IUniswapV2Router02 public  uniswapV2Router; // 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
    // instance of an lottery
    Lottery public lotteryLogic;
    // address of busd- wbnb pair
    address public  uniswapV2BUSDWBNBPair;
    // address of wbnb- BetConnexCore pair
    address public  uniswapV2WBNBPair;
    // BUSD address
    address public BUSD; // 0x8301f2213c0eed49a7e28ae4c3e91722919b8b47
    // market address
    address public MARKET_ADDR;  
    // dead address
    address public deadAddr = 0x000000000000000000000000000000000000dEaD;
    // Lp receiver address
    address lpReceiver;

    // limit of every cycle, cycle is a collection of 30 lotteries.
    uint8 public GAMES_PER_EPOCH = 30;
    // start time of lottery.
    uint public DAILY_LOTTERY_ON_EVERY = 1200; // one day
    // last lottery time.
    uint public LAST_LOTTERY_TIME;
    // price of oracle
    uint public oraclePrice;
    uint256 public CURRENT_EPOCH = 0;
    
    bool public inSwapForEth;
    bool public isSwitch = false;
    

    // struct of lottery info.
    struct LotteryStruct {
        uint256 id;
        uint256 participationFee;
        uint256 startedAt;
        uint256 finishedAt;
        uint256 participants;
        address winnerOne;
        address winnerTwo;
        uint256 epochId;
        uint256 winningOnePrize;
        uint256 winningTwoPrize;
        bool isActive;
    }
    
    // struct of epoch info.
    struct Epoch {
        uint256 totalFees;
        uint256 minParticipationFee;
        uint256 firstLotteryId;
        uint256 lastLotteryId;
    }
    
    // struct of user info.
    struct UserBalance {
        uint256 lastGameId;
        uint256 balance;
        uint256 at;
        uint256 lastVictory;
    }
    
    // epoch collection.
    Epoch[] public epochs;
   
    // lottery collection.
    LotteryStruct[] public dailyLotteries;
    // participant list.
    address [] public participants;
    // tax fee
    uint[7] public taxFee = [
        4 /*buy fee*/ ,
        10 /*sell fee*/ ,
        50 /*burn*/,
        50 /*market*/,
        30 /*auto pool*/,
        30 /*burn*/,
        40 /*market*/
    ];
    
    mapping(address => UserBalance) public balances; // user info 
    mapping(address => bool) public excludeFromLotteryParicipation; // exclude address from participating on lottery
    
    constructor() ERC20('BetConnex', 'BetConnex') {}


    receive() external payable{

    }

    modifier lockTheSwapForETH {
        inSwapForEth = true;
        _;
        inSwapForEth = false;
    }
    
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
    
    function _swapTokensForEth(uint256 tokenAmount) internal lockTheSwapForETH {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

      
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
        
    }
    
    function _calculateParticipationFee() internal view returns (uint256) {
        if(!isSwitch){
            address[] memory path = new address[](3);
            path[0] = BUSD;
            path[1] = uniswapV2Router.WETH();
            path[2] = address(this);
            
            uint256[] memory _participationFee = uniswapV2Router.getAmountsOut(2e18,path);
            return _participationFee[_participationFee.length -1];
        } else {
          return oraclePrice;  
        }
    }
    
    function _calculateBalanceAfterGames(
        uint256 _calculatedBalance,
        uint256 _fromGameId,
        uint256 _toGameId
    ) internal view returns(uint256) {
        for (uint256 i = _fromGameId; i <= _toGameId && _calculatedBalance > 0; i++) {
            LotteryStruct storage lottery = dailyLotteries[i];
            if (_calculatedBalance >= lottery.participationFee) {
                _calculatedBalance -= lottery.participationFee;
            }
          
        }
        return _calculatedBalance;
    }
    
    function _calcualteEpochBalance(
        uint256 _calculatedBalance,
        uint256 _epochFrom,
        uint256 _epochTo
    ) internal view returns( uint256) {
        
        for (uint256 i = _epochFrom; i <= _epochTo && _calculatedBalance > 0; i++) {
            if(_calculatedBalance >= epochs[i].totalFees)
                _calculatedBalance -= epochs[i].totalFees;            
        }
        
        return _calculatedBalance;
    }
    
}

contract BetConnex is BetConnexCore, AccessControl {
    
    constructor(
        uint _lastLotteryTime,
        IUniswapV2Router02 _router,
        address _BUSD,
        Lottery _lottery,
        address _market
    ) {
        
        _setRoleAdmin( DEFAULT_ADMIN_ROLE, ADMIN_ROLE); // Setting owner role bytecode.
        _setupRole( ADMIN_ROLE, msg.sender); // Setting owner role.
        _setupRole( AUTH_ROLE, address(_lottery));
        
        lpReceiver = msg.sender;
        
        LAST_LOTTERY_TIME = _lastLotteryTime;
        
        uniswapV2Router = _router;
        
        uniswapV2BUSDWBNBPair = IUniswapV2Factory(uniswapV2Router.factory()).getPair(uniswapV2Router.WETH(),_BUSD);
        
        lotteryLogic = _lottery;
       
        
        require(uniswapV2BUSDWBNBPair != address(0), "constructor : No available pool for BUSD-WBNB");
        
        BUSD = _BUSD;
        MARKET_ADDR = _market;
        
        uniswapV2WBNBPair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());
            
        _setupRole( BUY_ORDER, address(uniswapV2WBNBPair)); 
        _setupRole( SELL_ORDER, address(uniswapV2WBNBPair)); 
        
        excludeFromLotteryParicipation[lpReceiver] = true;
        excludeFromLotteryParicipation[address(lotteryLogic)] = true;
        excludeFromLotteryParicipation[address(uniswapV2Router)] = true;
        excludeFromLotteryParicipation[address(this)] = true;
        excludeFromLotteryParicipation[deadAddr] = true;
        excludeFromLotteryParicipation[address(uniswapV2WBNBPair)] = true;
        
        epochs.push(
            Epoch( 0 /*totalFees*/, 0 /*minParticipationFee*/, 0 /*firstGameId*/, 0 /*lastGameId*/ )
        );

        dailyLotteries.push(
            LotteryStruct(
                0 /*id*/, 0 /*participationFee*/, 0 /*startedAt*/, 0 /*finishedAt*/, 0 /*participants*/, address(0) /*winner one*/, address(0) /*winner two*/, 0 /*epochId*/, 0 /*winningOnePrize*/, 0 /*winningTwoPrize*/, false /*isActive*/
            )
        );
    }

    function mint(address account, uint256 amount) external onlyRole(getRoleAdmin(DEFAULT_ADMIN_ROLE)) {
        _mint(account, amount);
    }
    
    function setLPReceiver( address _lpReceiver) external onlyRole(getRoleAdmin(DEFAULT_ADMIN_ROLE)) {
        lpReceiver = _lpReceiver;
    }
    
    function setOraclePrice( uint _price) external onlyRole(getRoleAdmin(DEFAULT_ADMIN_ROLE)) {
        oraclePrice = _price;
    }
    
    function switchOracle( bool _stat) external onlyRole(getRoleAdmin(DEFAULT_ADMIN_ROLE)) {
        isSwitch = _stat;
    }
    
    function setTax( uint index, uint tax) external onlyRole(getRoleAdmin(DEFAULT_ADMIN_ROLE)) {
        require((index >= 0) && (index < taxFee.length));
        require(tax > 0);
        taxFee[index] = tax;
    }
    
    function setGamesPerEPOCH( uint8 _gamePerEpoch) external onlyRole(getRoleAdmin(DEFAULT_ADMIN_ROLE)){
        GAMES_PER_EPOCH = _gamePerEpoch;
    }
    
    function excludeAccFromLottery( address account) external onlyRole(getRoleAdmin(DEFAULT_ADMIN_ROLE)) {
        excludeFromLotteryParicipation[account] = true;
    }
    
    function includeAccToLottery( address account) external onlyRole(getRoleAdmin(DEFAULT_ADMIN_ROLE)) {
        excludeFromLotteryParicipation[account] = false;
        balances[account].lastGameId = dailyLotteries.length - 1;
    }
    
    function startLottery() external  returns (LotteryStruct memory _lotteryGame) {
        if((LAST_LOTTERY_TIME + DAILY_LOTTERY_ON_EVERY) <= block.timestamp) {
            
            LAST_LOTTERY_TIME = block.timestamp;
            
            LotteryStruct storage _lottery = dailyLotteries[dailyLotteries.length - 1];
            
            Epoch storage currentEpoch = epochs[epochs.length - 1];
    
            uint256 newGameId = dailyLotteries.length;
            uint256 participationFee = _calculateParticipationFee();
            
    
            if (newGameId - currentEpoch.firstLotteryId >= GAMES_PER_EPOCH) {
                currentEpoch.lastLotteryId = _lottery.id;
    
                epochs.push(
                    Epoch(
                        0,
                        participationFee,
                        newGameId,
                        0 
                    )
                );
    
                currentEpoch = epochs[epochs.length - 1];
                CURRENT_EPOCH = epochs.length - 1;
            } 
            
            dailyLotteries.push(
                LotteryStruct(
                    newGameId, participationFee,  block.timestamp, 0, 0, address(0), address(0), epochs.length - 1, 0, 0, true
                )
            );
            
            epochs[CURRENT_EPOCH].totalFees += participationFee;
            emit StartLottery(dailyLotteries.length - 1, dailyLotteries[dailyLotteries.length - 1], 0);
    
            return dailyLotteries[dailyLotteries.length - 1];
        }
    }

    function finishLottery( 
        uint256 _lotteryID,
        uint256 _participants,
        address[2] memory _winnerAddress,
        uint256[2] memory _winningPrizeValue,
        uint256 _marketingFeeValue 
    ) external onlyRole(getRoleAdmin(DEFAULT_ADMIN_ROLE)) returns (LotteryStruct memory finishedLotteryGame) {
        uint _latestLotteryID = dailyLotteries.length - 1;
        
        require(_lotteryID <= _latestLotteryID,"finishLottery : exceed lottery limit");
        
        LotteryStruct storage lottery = dailyLotteries[_lotteryID];
        
        require(lottery.isActive == true, "finishLottery : lottery game is not active");
        require((this.getHolderLastVictory(_winnerAddress[0]) + 7200) < block.timestamp, "finishLottery : winnerOne have recently won");
        require((this.getHolderLastVictory(_winnerAddress[1]) + 7200) < block.timestamp, "finishLottery : winnerTwo have recently won");

        lottery.participants = _participants;
        lottery.winnerOne = _winnerAddress[0];
        lottery.winnerTwo = _winnerAddress[1];
        lottery.winningOnePrize = _winningPrizeValue[0];
        lottery.winningTwoPrize = _winningPrizeValue[1];

        lottery.finishedAt = block.timestamp;
        lottery.isActive = false;

        uint256 winnerOneBalance = balanceOf(_winnerAddress[0]) + _winningPrizeValue[0];
        balances[_winnerAddress[0]].lastVictory = block.timestamp;
        updateBalance( _winnerAddress[0], winnerOneBalance);
        
        emit Transfer(address(this), _winnerAddress[0], _winningPrizeValue[0]);
        
        uint256 winnerTwoBalance = balanceOf(_winnerAddress[1]) + _winningPrizeValue[1];
        balances[_winnerAddress[1]].lastVictory = block.timestamp;
        updateBalance( _winnerAddress[1], winnerTwoBalance);

        emit Transfer(address(this), _winnerAddress[1], _winningPrizeValue[1]);
        
        address _self = address(this);
        updateBalance( _self, _marketingFeeValue);
        
        uint _balance = _self.balance;
        
        _swapTokensForEth(_marketingFeeValue);
        
        uint _swappedETH = _self.balance - _balance;

        payable(MARKET_ADDR).transfer(_swappedETH);

        
        emit FinishLottery( _lotteryID, _winnerAddress, _winningPrizeValue, block.timestamp, 0);
        return lottery;
    }
    
    function buyWeeklyTicket() external {
        lotteryLogic.buyWeeklyLotteryTickets( _msgSender());
    }
    
    function buyMegaTicket() external {
        lotteryLogic.buyMegaLotteryTickets( _msgSender());
    }
    
    function setHolderLastVictory( address _holder, uint _timeStamp) external onlyRole(AUTH_ROLE) {
        balances[_holder].lastVictory = _timeStamp;
    }
    
    function getHolderLastVictory( address _holder) external view returns ( uint) {
        return balances[_holder].lastVictory;
    }
 
    function _transfer( address sender, address recipient, uint256 amount) internal override(ERC20) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

      

        _beforeTokenTransfer(sender, recipient, amount);

    
        this.startLottery();
        
     
        uint256 senderBalance = balanceOf(sender) - amount;
         
        updateBalance(sender, senderBalance);

        if((balances[recipient].at == 0) && (amount > 0) && (!isContract(recipient)))
            participants.push(recipient);
        
     
      
        if((!inSwapForEth) && (!hasRole( AUTH_ROLE, sender)) && (sender != address(this)) && (recipient != address(this)) && (currentLPSupply() > 0)){
            amount = computeTax( sender, recipient, amount);
               
        }

        uint256 recipientBalance = balanceOf(recipient) + amount;
        updateBalance(recipient, recipientBalance);
    
        emit Transfer(sender, recipient, amount);
    }

    function currentLPSupply() private view returns (uint _lpSupply) {
        if(IUniswapV2Pair(uniswapV2WBNBPair).token0() == address(this)) {
            (_lpSupply,,) = IUniswapV2Pair(uniswapV2WBNBPair).getReserves();
        }
        else if(IUniswapV2Pair(uniswapV2WBNBPair).token1() == address(this)) {
            (, _lpSupply,) = IUniswapV2Pair(uniswapV2WBNBPair).getReserves();
        }
    }
    
    function computeTax( address sender, address recipient, uint256 amount) internal returns (uint _transferValue) {
        if(hasRole( SELL_ORDER,recipient)) { // sell order
            uint[3] memory _tValues;
            
            _tValues[0] = amount*taxFee[0]/100;
            _tValues[1] = _tValues[0] * taxFee[2]/100;
            updateBalance( deadAddr, (balanceOf(deadAddr) + _tValues[1]));
           
            _tValues[2] = _tValues[0] * taxFee[3]/100;
            updateBalance( MARKET_ADDR, (balanceOf(MARKET_ADDR) + _tValues[2]));
            
            _transferValue = amount - _tValues[0];
            
        }
        else if(hasRole( BUY_ORDER, sender)) {
             
             // buy order
            uint[4] memory _tValues;
            _tValues[0] = amount * taxFee[1]/100;
            
            _tValues[1] = _tValues[0] * taxFee[4]/100;
            updateBalance( lpReceiver, balanceOf(lpReceiver) + _tValues[1]);
            
            _tValues[2] = _tValues[0] * taxFee[5]/100;
            updateBalance( deadAddr, (balanceOf(deadAddr) + _tValues[2]));
            
            _tValues[3] = _tValues[0] * taxFee[6]/100;
            updateBalance( MARKET_ADDR, (balanceOf(MARKET_ADDR) + _tValues[3]));
            
            _transferValue = amount - _tValues[0];
        }
        else 
            _transferValue = amount;
    }
    
    function updateBalance( address account, uint amount) internal {
        LotteryStruct memory lottery = lastLottery();

        balances[account] = UserBalance(
            lottery.id,
            amount,
            block.timestamp,
            balances[account].lastVictory
        );
    }
    
    function _mint(address account, uint256 amount) internal override {
        require(account != address(0), "ERC20: mint to the zero address");

        uint256 balance = balanceOf(account) + amount;

        if ((balances[account].at == 0) && (amount > 0) && (!isContract(account))) {
            participants.push(account);
        }

        LotteryStruct memory lottery = lastLottery();

        balances[account].lastGameId = lottery.id;
        balances[account].balance = balance;
        balances[account].at = block.timestamp;
        
        _totalSupply += amount;

        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal override {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 balance = balanceOf(account) - amount;

        LotteryStruct memory lottery = lastLottery();

        balances[account].lastGameId = lottery.id;
        balances[account].balance = balance;
        balances[account].at = block.timestamp;
        
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }
    
    function balanceOf(address account) public view override returns (uint256) {
        UserBalance memory userBalance = balances[account];
        
        if ((dailyLotteries.length == 0) ||
            (userBalance.balance == 0) ||
            (excludeFromLotteryParicipation[account]))
        {
            return userBalance.balance;
        }

        uint _userEpochID = dailyLotteries[userBalance.lastGameId].epochId;
        uint _epochLastLotteryID = epochs[_userEpochID].lastLotteryId;

        uint256 calculatedBalance = userBalance.balance;

        if (_epochLastLotteryID > userBalance.lastGameId) {
            calculatedBalance = _calculateBalanceAfterGames(
                calculatedBalance,
                userBalance.lastGameId + 1,
                _epochLastLotteryID
            );
           
        }
        else if ((userBalance.lastGameId > 0 ) && (_epochLastLotteryID == 0) && (_userEpochID == CURRENT_EPOCH)) {
            calculatedBalance = _calculateBalanceAfterGames(
                calculatedBalance,
                userBalance.lastGameId + 1,
                dailyLotteries.length -1
            );
        }
        
        if(_userEpochID + 1 < epochs.length - 1) {
            if((_userEpochID + 1) < (epochs.length - 2))
            calculatedBalance = _calcualteEpochBalance(calculatedBalance, _userEpochID + 1, epochs.length - 2);
              
            Epoch memory _lastEpoch = epochs[epochs.length - 1];
            if(calculatedBalance >= _lastEpoch.totalFees){
                calculatedBalance = _calculateBalanceAfterGames(
                    calculatedBalance,
                    _lastEpoch.firstLotteryId,
                    dailyLotteries.length -1
                );
            }
        }

        return calculatedBalance;
    }

    function participantsCount() public view returns (uint256) {
        return participants.length;
    }

    function dailyLotteriesCount() public view returns (uint256) {
        return dailyLotteries.length;
    }

    function epochsCount() public view returns (uint256) {
        return epochs.length;
    }

    function lastLottery() public view returns (LotteryStruct memory lottery) {
        if (dailyLotteries.length == 0) {
            return LotteryStruct(0, 0, 0, 0, 0, address(0), address(0), 0, 0, 0, false);
        }

        return dailyLotteries[dailyLotteries.length - 1];
    }

    function lastEpoch() public view returns (Epoch memory epoch) {
        return epochs[epochs.length - 1];
    }

    function participantsBalances(uint256 from, uint256 count) public view returns (
        address [] memory participantAddresses,
        uint256 [] memory participantBalances
    ) {
        uint256 finalCount = from + count <= participants.length ? count : participants.length - from;

        participantAddresses = new address[](finalCount);
        participantBalances = new uint256[](finalCount);

        for (uint256 i = from; i < from + finalCount; i++) {
            participantAddresses[i - from] = participants[i];
            participantBalances[i - from] = balanceOf(participants[i]);
        }
    }
}