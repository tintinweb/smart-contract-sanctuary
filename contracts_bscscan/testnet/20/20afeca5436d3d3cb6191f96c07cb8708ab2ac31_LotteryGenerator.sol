/**
 *Submitted for verification at BscScan.com on 2021-10-25
*/

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT



abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
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


library IterableMapping {
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => string) name;
        mapping(address => string) Winnername;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
        mapping(address => bool) active;
    }

    function get(Map storage map, address key) public view returns (string memory) {
        return map.name[key];
    }

    function getIndexOfKey(Map storage map, address key) public view returns (int) {
        if(!map.active[key]) {
            return -1;
        }
        return int(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint index) public view returns (address) {
        return map.keys[index];
    }



    function size(Map storage map) public view returns (uint) {
        return map.keys.length;
    }

    function insert(Map storage map, address key, string memory name) public {
        if (map.inserted[key]) {
            map.name[key] = name;
        } else {
            map.inserted[key] = true;
            map.active[key] = true;
            map.name[key] = name;
            map.Winnername[key] = '';
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.active[key];
        delete map.name[key];

        uint index = map.indexOf[key];
        uint lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}




contract LotteryGenerator is Ownable {
     using SafeMath for uint256;
    
     Lottery public newLottery;
     address public Creator;
     address public activeLottery;
          
    
    address[] public lotteries;
    struct lottery{
        uint256 index;
        address manager;
        string  name;
        bool open;
    }
    mapping(address => lottery) lotteryStructs;
    
     // Events
    event LotteryCreated(
        address lotteryAddress
    );
    
     event WinnerDeclared(
        address lotteryAddress,
        string lotteryName,
        address winnerAddress,
        string winnerName,
        uint256 winnerPrize,
        uint256 drawnTime
        
    );
    
    // constructor
    constructor ()  {
        Creator = owner();
        
        
    }
    
    function createLottery(string memory name, address prizeToken,uint256 maxEntriesPerWallet, uint256 _drawnTime, uint256 _ethToParticipate) public {
        require(bytes(name).length > 0);
        require(msg.sender == Creator);
        require(block.timestamp.add(_drawnTime) > block.timestamp,'draw time cannot be before current time');
         
        
        newLottery = new Lottery(name, prizeToken, msg.sender, maxEntriesPerWallet, _drawnTime, _ethToParticipate);
        
        activeLottery = address(newLottery);
        lotteries.push(address(newLottery));
        
        lotteryStructs[address(newLottery)].index = lotteries.length  - 1;
        lotteryStructs[address(newLottery)].manager = msg.sender;
        lotteryStructs[address(newLottery)].name = name;
        lotteryStructs[address(newLottery)].open = true;
        

        // event
       emit LotteryCreated(address(newLottery));
    }
   

    function getLotteries() public view returns (address[] memory) {
        return lotteries;
    }

    function deleteLottery(address lotteryAddress) public onlyOwner {
        require(msg.sender == lotteryStructs[lotteryAddress].manager);
        uint indexToDelete = lotteryStructs[lotteryAddress].index;
        address lastAddress = lotteries[lotteries.length - 1];
        lotteries[indexToDelete] = lastAddress;
        
        lotteries.pop();
    }

   
}

contract Lottery {
     using SafeMath for uint256;
    
    // name of the lottery
    string public lotteryName;
    // Creator of the lottery contract
    address public manager;
    
    IUniswapV2Router02 public uniswapV2Router;
        
     address  public marketingWallet  = address(0x0F5a8a58b3C85871A256F1C1e09Fc5A3231a018d);
     address public prizeToken;
    // variables for players
    struct Player {
        string name;
        address walletAddress;
        uint256 entryCount;
        uint256 index;
        uint256 winningPrize;
        uint256 drawTimeStamp;
    }
    
    address[] public addressIndexes;
    mapping(address => Player) players;
    address[] public lotteryBag;

    // Variables for lottery information
    Player public winner;
    bool public isLotteryLive;
    uint256 public maxEntriesForPlayer;
    uint256 public ethToParticipate = 0.1*10**18; //0.1BNB ;
    uint256 public immutable marketingWalletFee = 20;
    uint256 public immutable prizePer = 80;
    uint256 public drawnTime;

    // constructor
    constructor (string memory name, address _prizeToken,address creator, uint256 maxEntriesPerWallet, uint256 _drawnTime, uint256 _ethToParticipate)  
    {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        uniswapV2Router = _uniswapV2Router;
    
        prizeToken = _prizeToken;
        
        isLotteryLive = true;
        
        manager = creator;
        lotteryName = name;
        maxEntriesForPlayer = maxEntriesPerWallet;
        ethToParticipate = _ethToParticipate;
        drawnTime = _drawnTime.mul(3600).add(block.timestamp);
        
    }

    function participate(string memory playerName) public payable {
        require(bytes(playerName).length > 0, "Player Name Required!");
        require(block.timestamp <= drawnTime,"lottery closed");
        require(isLotteryLive, "lottery is not started yet!");
        require(msg.value >= ethToParticipate,"Minimum 0.1 BNB Required!");
        

       uint256  calculateEnteries = msg.value.div(ethToParticipate);
       
       for(uint256 i=1; i<=calculateEnteries;i++)
       {
           require(players[msg.sender].entryCount < maxEntriesForPlayer,"Maximum 10 Enteries per address");
           
       if (isNewPlayer(msg.sender)) {
            players[msg.sender].entryCount = 1;
            players[msg.sender].name = playerName;
            addressIndexes.push(msg.sender);
            uint256 addressLegth = addressIndexes.length;
            players[msg.sender].index = addressLegth  - 1;
            players[msg.sender].winningPrize = 0;
            players[msg.sender].drawTimeStamp = 0;
        } else {
            players[msg.sender].entryCount += 1;
        }
        
        lotteryBag.push(msg.sender);
       }
    
        uint256 marketingFees = msg.value.mul(marketingWalletFee).div(100);
        (bool successOne,) = address(marketingWallet).call{value: marketingFees}("");
        
        uint256 poolPrize = msg.value.sub(marketingFees);
        (bool successTwo,) = address(this).call{value: poolPrize}("");
       
        
        // event
        if(successOne && successTwo)
        {
          emit PlayerParticipated(players[msg.sender].name, players[msg.sender].entryCount);
        }
    }

    function currentTimeStamp() public view returns (uint256){
        
        return block.timestamp;
    }

    function declareWinner() public restricted {
        
        require(lotteryBag.length > 0);
        require(block.timestamp >= drawnTime,"this is not drawn time yet");
        uint index = generateRandomNumber() % lotteryBag.length;
        
        uint256 poolPrize = address(this).balance;

        players[lotteryBag[index]].winningPrize = poolPrize;
        players[lotteryBag[index]].drawTimeStamp = block.timestamp;
        
        winner.name = players[lotteryBag[index]].name;
        winner.walletAddress = lotteryBag[index];
        winner.entryCount = players[lotteryBag[index]].entryCount;
        winner.winningPrize = players[lotteryBag[index]].winningPrize;
        winner.drawTimeStamp = players[lotteryBag[index]].drawTimeStamp;
        
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = prizeToken;


        // make the swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: poolPrize}(
            0, // accept any amount of Tokens
            path,
            msg.sender, // winner address
            block.timestamp.add(300)
        );
        
        
        // empty the lottery bag and indexAddresses
        lotteryBag = new address payable[](0);
        addressIndexes = new address[](0);

        // Mark the lottery inactive
        isLotteryLive = false;
    
        // event
        emit WinnerDeclared(winner.name, winner.entryCount);
    }
    

    function getPlayers() public view returns(address[] memory) {
        return addressIndexes;
    }

    function getPlayer(address playerAddress) public view returns (string memory, uint) {
        if (isNewPlayer(playerAddress)) {
            return ("", 0);
        }
        return (players[playerAddress].name, players[playerAddress].entryCount);
    }

    function getWinningPrice() public view returns (uint256) {
        uint256 marketFees = address(this).balance.mul(marketingWalletFee).div(100);
        uint256 prizePool =  address(this).balance.sub(marketFees);
        return prizePool;
    }

    // Private functions
    function isNewPlayer(address playerAddress) private view returns(bool) {
        if (addressIndexes.length == 0) {
            return true;
        }
        return (addressIndexes[players[playerAddress].index] != playerAddress);
    }
    
    function generateRandomNumber() private view returns(uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, lotteryBag)));
    }

    // Modifiers
    modifier restricted() {
        require(msg.sender == manager);
        _;
    }

    // Events
    event WinnerDeclared( string name, uint entryCount );
    event PlayerParticipated( string name, uint entryCount );
}