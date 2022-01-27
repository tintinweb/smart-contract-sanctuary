/**
 *Submitted for verification at Etherscan.io on 2022-01-27
*/

pragma solidity ^0.4.25;

// import "hardhat/console.sol";

contract AnimalChess {

    using SafeMath for uint256;
    address owner;
    uint8 users_count = 0;
    mapping (address => bool) private Users;
    mapping(uint=>GameRoom) public GameList;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event RoomSend(uint GameRoomId , string PlayerName, address Player, uint BetAmount);
    event GameResult(
        uint GameRoomId,        // 房間ID
        address PlayerA,        // 玩家Ａ
        uint PlayerA_BetAmount, // 玩家Ａ押注金額
        uint[] PlayerA_Array,   // 玩家Ａ動物陣列 
        address PlayerB,        // 玩家Ｂ
        uint PlayerB_BetAmount, // 玩家Ｂ押注金額
        uint[] PlayerB_Array,   // 玩家Ｂ動物陣列
        string FinalResult      // 最後結果
        );

    constructor() public {
        owner = msg.sender;
    }

    struct GameRoom {
        address PlayA;       // 玩家Ａ
        uint[] PlayA_Array;  // 玩家Ａ上傳Array
        address PlayB;       // 玩家Ｂ
        uint[] PlayB_Array;  // 玩家Ｂ上傳Array
        uint amount;         // 押注總金額
        string Final_Result; // 最後結果
    }

    modifier onlyUsers() {
        require(msg.sender == owner || Users[msg.sender] == true);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function addUser(address _wallet) external onlyOwner {
        Users[_wallet] = true;
    }

    // 轉錢給贏家
    function transferEther(address winner_address, uint amo) public onlyUsers {
        winner_address.transfer(amo);
    }

    // 押注
    function sendEther(uint roomid) public payable {
        if(GameList[roomid].PlayA == address(0x0)) {
            GameList[roomid].PlayA = msg.sender;
            GameList[roomid].amount = msg.value;
            emit RoomSend(roomid, "PlayerA", msg.sender, msg.value);
        } else {
            GameList[roomid].PlayB = msg.sender;
            GameList[roomid].amount = GameList[roomid].amount.add(msg.value);
            emit RoomSend(roomid, "PlayerB", msg.sender, msg.value);
        }
    }

    // 上傳動物出場陣列
    function updatAnimalArray(uint roomid, address play1, address play2, uint[] play1_array, uint[] play2_array) public onlyUsers{
        
        uint _RoomId = roomid;
        address _PlayA = play1;
        address _PlayB = play2;
        uint[] memory _PlayA_Array = play1_array;
        uint[] memory _PlayB_Array = play2_array;

        if(_PlayA == GameList[_RoomId].PlayA || _PlayB == GameList[_RoomId].PlayA) {
            if(_PlayA == GameList[_RoomId].PlayA) {
                GameList[_RoomId].PlayA_Array = _PlayA_Array;
            } else if (_PlayB == GameList[_RoomId].PlayA) {
                GameList[_RoomId].PlayA_Array = _PlayB_Array;
            }
        }
        if(_PlayB == GameList[_RoomId].PlayB || _PlayA == GameList[_RoomId].PlayB) {
            if(_PlayA == GameList[_RoomId].PlayB) {
                GameList[_RoomId].PlayB_Array = _PlayA_Array;
            } else if (_PlayB == GameList[_RoomId].PlayB) {
                GameList[_RoomId].PlayB_Array = _PlayB_Array;
            } 
        }
        AnimalBattle(_RoomId);
    }

    // 動物對戰
    function AnimalBattle(uint roomid) internal {
        uint winA = 0; // A贏+1
        uint winB = 0; // B贏 +1
        uint draw = 0; // 平局+1
        uint amo = GameList[roomid].amount;
        for(uint i = 0; i <= GameList[roomid].PlayA_Array.length; i++) {
            if(i == GameList[roomid].PlayA_Array.length) {
                if(winA > winB) {
                    GameList[roomid].Final_Result = "PlayerA Win";
                    transferEther(GameList[roomid].PlayA, amo);
                    emit GameResult(
                        roomid,
                        GameList[roomid].PlayA,
                        amo / 2,
                        GameList[roomid].PlayA_Array,
                        GameList[roomid].PlayB,
                        amo / 2,
                        GameList[roomid].PlayB_Array,
                        GameList[roomid].Final_Result
                        );
                } else if (winA < winB) {
                    GameList[roomid].Final_Result = "PlayerB Win";
                    transferEther(GameList[roomid].PlayB, amo);
                    emit GameResult(
                        roomid,
                        GameList[roomid].PlayA,
                        amo / 2,
                        GameList[roomid].PlayA_Array,
                        GameList[roomid].PlayB,
                        amo / 2,
                        GameList[roomid].PlayB_Array,
                        GameList[roomid].Final_Result
                        );
                } else {
                    GameList[roomid].Final_Result = "Player Draw";
                    transferEther(GameList[roomid].PlayA, amo/2);
                    transferEther(GameList[roomid].PlayB, amo/2);
                    emit GameResult(
                        roomid,
                        GameList[roomid].PlayA,
                        amo / 2,
                        GameList[roomid].PlayA_Array,
                        GameList[roomid].PlayB,
                        amo / 2,
                        GameList[roomid].PlayB_Array,
                        GameList[roomid].Final_Result
                        );
                }
                break;
            }
            if(GameList[roomid].PlayA_Array[i] > GameList[roomid].PlayB_Array[i]) {
                winA++;
            } else if(GameList[roomid].PlayA_Array[i] < GameList[roomid].PlayB_Array[i]){
                winB++;
            } else {
                draw++;
            }
        }
    }

    // 查詢合約裡的總金額
    // function getBalance() public view returns(uint) {
    //     require(msg.sender == owner);
    //     return address(this).balance;
    // }
}

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}