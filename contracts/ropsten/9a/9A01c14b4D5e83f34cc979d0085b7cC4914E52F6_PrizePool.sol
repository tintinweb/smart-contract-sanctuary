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

contract PrizePool is Ownable {
    using SafeMath for uint256;
    IERC20 public cue;
    mapping (address => uint256) public balances;
    struct Game {
        uint256 table_id;
        address [] players;
        string status;
        string game_level;
        uint256 game_type;
        uint256 max_players;
    }
    uint256 private land_fee;
    uint256 private eskillz_fee;
    uint256 private prize1;
    uint256 private prize2;
    uint256 private prize3;
    event Deposit(address player, uint256 amount, uint256 game_id);
    mapping (uint256 => Game) private game_list;
    mapping (uint256 => uint256) private deposited_balances;
    uint256 public game_count = 0;
    constructor (address addr) public { cue = IERC20(addr); land_fee = 0; eskillz_fee = 0; prize1 = 50; prize2 = 30; prize3 = 20;}

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
        balances[msg.sender] = balances[msg.sender].add(amount);
        deposited_balances[game_id] = deposited_balances[game_id].add(amount);
        //require(cue.balanceOf(msg.sender) >= amount,"balance is low");
        cue.transferFrom(msg.sender, address(this), amount);
        emit Deposit(msg.sender, amount, game_id);
    }
    
    function startGame(uint256 game_id) public {
        require(game_list[game_id].players.length>1, "players need to join this game to start.");
        game_list[game_id].status = "started";
    }

    function finishGame(uint256 game_id, address[] memory players) public {
        game_list[game_id].status = "finished";

    }
    function getGame(uint256 game_id) public view returns (uint256, address[] memory, string memory, uint256, uint256) {
        return (game_list[game_id].table_id, game_list[game_id].players, game_list[game_id].status, game_list[game_id].game_type, game_list[game_id].max_players);
    }
    function depositedAmount(uint256 game_id) public view returns(uint256) {
        return deposited_balances[game_id];
    }
    function setLandFee(uint256 _fee) public {
        land_fee = _fee;
    }
    function setESkillzFee(uint256 _fee) public {
        eskillz_fee = _fee;
    }
    function setPrizeDistribution(uint256 _prize1, uint256 _prize2, uint256 _prize3) public {
        require(_prize1>=0&&_prize1<=100, "Prize distribution should be between 0-100");
        require(_prize2>=0&&_prize2<=100, "Prize distribution should be between 0-100");
        require(_prize3>=0&&_prize3<=100, "Prize distribution should be between 0-100");
        prize1 = _prize1;
        prize2 = _prize2;
        prize3 = _prize3;
    }
    function getPrizeDistribution() public view returns(uint256, uint256, uint256) {
        return(prize1, prize2, prize3);
    }
}