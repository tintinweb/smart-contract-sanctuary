// Partial License: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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

pragma solidity ^0.6.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.6.0;
contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.6.0;
library SafeMath {
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


pragma solidity 0.6.6;

contract ESkillzStraightBet is Ownable {
    using SafeMath for uint256;
    IERC20 public cue;
    mapping(uint256 => mapping (address => uint256))  private balances;
    struct Game {
        uint256 table_id;
        address [] players;
        string status;
        string game_level;
        uint256 game_type;
        uint256 max_players;
    }
    uint256 private a_fee; // Amatuer table fee.
    uint256 private p_fee; // Professional table fee.
    uint256 private c_fee; // Championship table fee.
    uint256 private eskillz_fee;

    event Deposit(address player, uint256 amount, uint256 game_id);
    mapping (uint256 => Game) private game_list;
    mapping (uint256 => uint256) private bet_amount;
    uint256 public game_count = 0;
    constructor (address addr) public { cue = IERC20(addr); a_fee = 0; p_fee = 0; c_fee = 0; eskillz_fee = 0;}

    function createGame(uint256 game_type, string memory game_level, uint256 amount, uint256 max_players ) public {
        require(max_players > 1, "max players should be bigger than 1");
        Game memory new_game = Game({ table_id: game_count, players: new address[](0), status: "created", game_level: game_level, game_type: game_type, max_players:max_players});
        game_list[game_count] = new_game;
        joinGame(amount, game_count);
        game_count++;
    }
    
    function joinGame(uint256 amount, uint256 game_id) public {
        require(amount>0, "betting amount should be bigger than zero");
        require(game_count>=game_id, "this game is not created!");
        require(keccak256(abi.encodePacked((game_list[game_id].status)))== keccak256(abi.encodePacked(("created"))), "this game already started or finished");
        require(game_list[game_id].players.length<game_list[game_id].max_players, "already filled all players");
        game_list[game_id].players.push(msg.sender);
        balances[game_id][msg.sender] = balances[game_id][msg.sender].add(amount);
        bet_amount[game_id] = bet_amount[game_id].add(amount);
        //require(cue.balanceOf(msg.sender) >= amount,"balance is low");
        cue.transferFrom(msg.sender, address(this), amount);
        emit Deposit(msg.sender, amount, game_id);
    }
    
    function startGame(uint256 game_id) public {
        require(game_list[game_id].players.length>1, "more players need to join this game to start.");
        game_list[game_id].status = "started";
    }

    function finishGame(uint256 game_id, address winner) public {
        game_list[game_id].status = "finished";
        cue.transfer(winner, bet_amount[game_id]);
    }
    function getGame(uint256 game_id) public view returns (uint256, address[] memory, string memory, uint256, uint256) {
        return (game_list[game_id].table_id, game_list[game_id].players, game_list[game_id].status, game_list[game_id].game_type, game_list[game_id].max_players);
    }
    function totalBetAmountOnGame(uint256 game_id) public view returns(uint256) {
        return bet_amount[game_id];
    }
    function getTableFee() public view returns(uint256, uint256, uint256) {
        return (a_fee,p_fee,c_fee);
    }
    function setTableFee(uint256 _aFee, uint256 _pFee, uint256 _cFee) public {
        a_fee = _aFee; p_fee = _pFee; c_fee = _cFee;
    }
    function getESkillzFee() public view returns(uint256) {
        return eskillz_fee;
    }
    function setESkillzFee(uint256 _fee) public {
        eskillz_fee = _fee;
    }
}