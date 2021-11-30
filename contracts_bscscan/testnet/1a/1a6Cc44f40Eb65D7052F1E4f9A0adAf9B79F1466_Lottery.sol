/**
 *Submitted for verification at BscScan.com on 2021-11-30
*/

//SPDX-License-Identifier: UNLICENSED
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

    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
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


interface IBetConnex {
    function setHolderLastVictory( address _holder, uint _timeStamp) external;
    function getHolderLastVictory( address _holder) external view returns ( uint);
}



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

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */


/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */

/**
 * @dev String operations.
 */

contract Lottery is AccessControl {
    
    event StartLottery(uint indexed _lotteryID, LotteryStruct _lotteryGame, uint indexed _lotteryType);
    event BuyTicket(uint indexed _lotteryID, address indexed _buyer, uint _participationID, uint _timestamp, uint indexed _lotteryType);
    event FinishLottery(uint indexed _lotteryID, address indexed _winer, uint _timestamp, uint indexed _lotteryType);
    
    IERC20 public token;
    IUniswapV2Router02 public  uniswapV2Router;
    address public uniswapV2WBNBPair;
    address public MARKET_ADDR;  
    
    mapping(bytes32 => bool) private isStatActive;
    
    LotteryStruct[] public weeklyLotteries;
    LotteryStruct[] public megaLotteries;
    
    // struct of lottery.
    struct LotteryStruct {
        uint256 id;
        uint256 participationFee;
        uint256 startedAt;
        uint256 finishedAt;
        address[] participants;
        address winner;
        uint256 winningPrize;
        uint256 tickets;
        uint256 ticketsSold;
        uint256 totalCollection;
        bool isActive;
    }
    
    uint16 public weekLotteryMarketFee = 1000; //10%
    uint16 public megaLotteryMarketFee = 1000;
    
    uint256 public LAST_WEEKLY_LOTTERY_TIME = block.timestamp;
    uint256 public WEEK_LOTTERY_ON_EVERY = 1800; // one week
    
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant AUTH_ROLE = keccak256("AUTH_ROLE");
    bytes32 public constant IS_WEEK_ACTIVE = keccak256("IS_WEEK_ACTIVE");
    bytes32 public constant IS_MEGA_ACTIVE = keccak256("IS_MEGA_ACTIVE");
    
    constructor( address _market, IUniswapV2Router02 _router) {
        _setRoleAdmin( DEFAULT_ADMIN_ROLE, ADMIN_ROLE); // Setting owner role bytecode.
        _setupRole( ADMIN_ROLE, msg.sender); // Setting owner role.
        
        uniswapV2Router = _router;

        MARKET_ADDR = _market;
        isStatActive[IS_WEEK_ACTIVE] = true;
        isStatActive[IS_MEGA_ACTIVE] = true;
    }
    
    modifier isActive(bytes32 _lotteryClass) {
        require(isStatActive[_lotteryClass], "Lottery is !active");
        _;
    }

    receive() external payable {

    }
    
    function setToken( IERC20 _token) external onlyRole(getRoleAdmin(DEFAULT_ADMIN_ROLE)) {
        token = _token;
        _setupRole( AUTH_ROLE, address(_token));
    }
    
    function pauseWeekly() external onlyRole(getRoleAdmin(DEFAULT_ADMIN_ROLE)) {
        isStatActive[IS_WEEK_ACTIVE] = false;
    }
    
    function unpauseWeekly() external onlyRole(getRoleAdmin(DEFAULT_ADMIN_ROLE)) {
        isStatActive[IS_WEEK_ACTIVE] = true;
    }
    
    function pauseMega() external onlyRole(getRoleAdmin(DEFAULT_ADMIN_ROLE)) {
        isStatActive[IS_MEGA_ACTIVE] = false;
    }
    
    function unpauseMega() external onlyRole(getRoleAdmin(DEFAULT_ADMIN_ROLE)) {
        isStatActive[IS_MEGA_ACTIVE] = true;
    }
    
    function setWeekMarketFee( uint16 _feePercent) external onlyRole(getRoleAdmin(DEFAULT_ADMIN_ROLE)) { // 10 == 1000 percent
        weekLotteryMarketFee = _feePercent;
    }
    
    function setMegaMarketFee( uint16 _feePercent) external onlyRole(getRoleAdmin(DEFAULT_ADMIN_ROLE)) { // 10 == 1000 percent
        megaLotteryMarketFee = _feePercent;
    }
    
    function startWeeklyLottery( uint participationFee, uint _tickets) external onlyRole(getRoleAdmin(DEFAULT_ADMIN_ROLE)) isActive(IS_WEEK_ACTIVE) returns (LotteryStruct memory _lotteryGame) {
        require((LAST_WEEKLY_LOTTERY_TIME + WEEK_LOTTERY_ON_EVERY) < block.timestamp, "startWeeklyLottery : wait till current lottery ends");
        
        if(weeklyLotteries.length > 0) {
            uint _latestLotteryID = weeklyLotteries.length - 1;
            LotteryStruct memory prevLottery = weeklyLotteries[_latestLotteryID];
            require(!prevLottery.isActive, "startWeeklyLottery : prev Lottery game is not active");
        }

        LAST_WEEKLY_LOTTERY_TIME = block.timestamp;
        
        uint256 newGameId = weeklyLotteries.length;
        address[] memory _participantsList = new address[](_tickets);

        weeklyLotteries.push(
            LotteryStruct(
                newGameId, /*id*/
                participationFee, /*participationFee*/
                block.timestamp, /*startedAt*/
                0, /*finishedAt*/
                _participantsList, /*participants*/
                address(0), /*winner*/
                0, /*winningPrize*/
                _tickets, /*tickets*/
                0, /*ticketsSold*/
                0, /*totalCollection*/
                true /*isActive*/
            )
        );
        
        emit StartLottery(weeklyLotteries.length - 1, weeklyLotteries[weeklyLotteries.length - 1], 1);

        return weeklyLotteries[weeklyLotteries.length - 1];
    }
    
    function buyWeeklyLotteryTickets( address _ticketBuyer) external onlyRole(AUTH_ROLE) isActive(IS_WEEK_ACTIVE){
        require((LAST_WEEKLY_LOTTERY_TIME + WEEK_LOTTERY_ON_EVERY) > block.timestamp, "buyWeeklyLotteryTickets : exceed the buy period");
        
        uint _latestLotteryID = weeklyLotteries.length - 1;
        
        LotteryStruct storage _currentWeekLottery = weeklyLotteries[_latestLotteryID];
        require(_currentWeekLottery.tickets > 0,"buyWeeklyLotteryTickets : no available tickets to buy");
        require(_currentWeekLottery.isActive, "buyWeeklyLotteryTickets : lottery has been finalized");
        
        require(token.balanceOf(_ticketBuyer) >= _currentWeekLottery.participationFee, "buyWeeklyLotteryTickets : insufficient balance to participate");
        require(token.allowance(_ticketBuyer, address(this)) >= _currentWeekLottery.participationFee, "buyWeeklyLotteryTickets : insufficient allowance to participate");
        require(token.transferFrom(_ticketBuyer, address(this), _currentWeekLottery.participationFee), "buyWeeklyLotteryTickets : transferFrom failed");
        
        uint _ticketID = _currentWeekLottery.ticketsSold;

        _currentWeekLottery.tickets --;
        _currentWeekLottery.ticketsSold ++;
        _currentWeekLottery.totalCollection += _currentWeekLottery.participationFee;
        _currentWeekLottery.participants[_ticketID] = _ticketBuyer;
        
        emit BuyTicket(_latestLotteryID, _ticketBuyer, _currentWeekLottery.participants.length - 1, block.timestamp, 1);
    }

    function finishWeeklyLottery( uint256 _participantsIndex ) external onlyRole(getRoleAdmin(DEFAULT_ADMIN_ROLE)) isActive(IS_WEEK_ACTIVE) {
        require((LAST_WEEKLY_LOTTERY_TIME + WEEK_LOTTERY_ON_EVERY) < block.timestamp, "finishWeeklyLottery : exceed the buy period");
        uint _latestLotteryID = weeklyLotteries.length - 1;
        
        LotteryStruct storage lottery = weeklyLotteries[_latestLotteryID];
        require(lottery.isActive == true, "finishWeeklyLottery : Lottery game is not active");

        lottery.finishedAt = block.timestamp;
        lottery.isActive = false;
        
        address _winnerAddress = lottery.participants[_participantsIndex];
        
        if(_winnerAddress == address(0)) return;


         require(_winnerAddress != address(0), "finishWeeklyLottery : No participant available at given index");
        require((IBetConnex(address(token)).getHolderLastVictory(_winnerAddress) + 7200) < block.timestamp, "finishWeeklyLottery : winner has recent winning");
        uint _marketFee = lottery.totalCollection * weekLotteryMarketFee / 10**4;
        
        lottery.winner = _winnerAddress;
        lottery.winningPrize = lottery.totalCollection - _marketFee;

        IBetConnex(address(token)).setHolderLastVictory( _winnerAddress, block.timestamp);
        token.transfer(_winnerAddress, lottery.winningPrize);
        
        address _self = address(this);
        
        uint _balance = _self.balance;
        
        swapTokensForEth(_marketFee);
        
        uint _swappedETH = (_self.balance - _balance);
        payable(MARKET_ADDR).transfer(_swappedETH);
        
        emit FinishLottery(_latestLotteryID, _winnerAddress, block.timestamp, 1);        
    }

    function startMegaLottery( uint participationFee, uint _tickets) external onlyRole(getRoleAdmin(DEFAULT_ADMIN_ROLE)) isActive(IS_MEGA_ACTIVE) returns (LotteryStruct memory _lotteryGame) {
        
        if(megaLotteries.length > 0) {
            LotteryStruct memory _prevLottery = megaLotteries[megaLotteries.length -1];
            require(!_prevLottery.isActive, "startMegaLottery : previous lottery is not finalized");
        }
        
        uint256 newGameId = megaLotteries.length;
        address[] memory _participantsList = new address[](_tickets);

        megaLotteries.push(
            LotteryStruct(
                newGameId, /*id*/
                participationFee, /*participationFee*/
                block.timestamp, /*startedAt*/
                0, /*finishedAt*/
                _participantsList, /*participants*/
                address(0), /*winner*/
                0, /*winningPrize*/
                _tickets, /*tickets*/
                0, /*ticketsSold*/
                0, /*totalCollection*/
                true /*isActive*/
            )
        );
        
        emit StartLottery(megaLotteries.length - 1, megaLotteries[megaLotteries.length - 1], 2);

        return megaLotteries[megaLotteries.length - 1];
    }
    
    function buyMegaLotteryTickets( address _ticketBuyer) external onlyRole(AUTH_ROLE) isActive(IS_MEGA_ACTIVE) {
        
        uint _latestLotteryID = megaLotteries.length - 1;
        
        LotteryStruct storage _currentMegaLottery = megaLotteries[_latestLotteryID];
        require(_currentMegaLottery.tickets > 0, "buyMegaLotteryTickets : no available tickets");
        require(_currentMegaLottery.isActive, "buyMegaLotteryTickets : lottery has been finalized");
        
        require(token.balanceOf(_ticketBuyer) >= _currentMegaLottery.participationFee, "buyMegaLotteryTickets : insufficient balance available to buy ticket");
        require(token.allowance(_ticketBuyer, address(this)) >= _currentMegaLottery.participationFee, "buyMegaLotteryTickets : insufficient allowance");
        require(token.transferFrom(_ticketBuyer, address(this), _currentMegaLottery.participationFee), "buyMegaLotteryTickets : transferFrom failed");
        
        uint _ticketID = _currentMegaLottery.ticketsSold;

        _currentMegaLottery.tickets --;
        _currentMegaLottery.ticketsSold ++;
        _currentMegaLottery.totalCollection += _currentMegaLottery.participationFee;
        _currentMegaLottery.participants[_ticketID] = _ticketBuyer;   
        
        emit BuyTicket(_latestLotteryID, _ticketBuyer, _currentMegaLottery.participants.length - 1, block.timestamp, 2);
    }

    function finishMegaLottery( uint256 _participantsIndex ) external onlyRole(getRoleAdmin(DEFAULT_ADMIN_ROLE)) isActive(IS_MEGA_ACTIVE) {
        uint _lotteryID = megaLotteries.length - 1;
    
        LotteryStruct storage lottery = megaLotteries[_lotteryID];
        require(lottery.isActive == true, "finishMegaLottery : lottery game is not active");

        lottery.finishedAt = block.timestamp;
        lottery.isActive = false;
        
        address _winnerAddress = lottery.participants[_participantsIndex];

        if(_winnerAddress == address(0)) return;

        require(_winnerAddress != address(0), "finishMegaLottery : no participant available at given index");
        require((IBetConnex(address(token)).getHolderLastVictory(_winnerAddress) + 7200) < block.timestamp, "finishMegaLottery : winner has recent wining");
        uint _marketFee = lottery.totalCollection * megaLotteryMarketFee / 10**4;
        
        lottery.winner = _winnerAddress;
        lottery.winningPrize = lottery.totalCollection - _marketFee;

        IBetConnex(address(token)).setHolderLastVictory( _winnerAddress, block.timestamp);
        token.transfer(_winnerAddress, lottery.winningPrize);
        
        address _self = address(this);
        
        uint _balance = _self.balance;
        
        swapTokensForEth(_marketFee);
        
        uint _swappedETH = (_self.balance - _balance);
        payable(MARKET_ADDR).transfer(_swappedETH);
        
        emit FinishLottery(_lotteryID, _winnerAddress, block.timestamp, 2);        
    }

    function participantWeeklyList(uint256 _lotteryId)public view returns(address[] memory){
       return weeklyLotteries[_lotteryId].participants;
    }

     function participantMegaList(uint256 _lotteryId)public view returns(address[] memory){
       return megaLotteries[_lotteryId].participants;
    }


    
    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = uniswapV2Router.WETH();

        token.approve( address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }
    
}