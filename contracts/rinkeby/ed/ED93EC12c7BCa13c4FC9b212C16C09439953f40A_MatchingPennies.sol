/**
 *Submitted for verification at Etherscan.io on 2021-10-21
*/

pragma solidity >0.4.23 <0.5.0;

contract MatchingPennies {

    struct Game {
        address playA; //玩家账户地址
        address playB;
        bytes32 encryptedA; //加密数据
        bytes32 encryptedB;
        uint valueA; //出的数字
        uint valueB;
        bool statusA; //是否验证过
        bool statusB;
        uint revealTimeA; //验证时间
        uint revealTimeB;
        bool gameStatus; // 游戏状态
        address winner; // 胜利玩家
        uint gameResult; // 1代表A赢 2代表B赢 3代表双方退款 4dai'b代表A退款  5代表B退款 
    }
    bool _notEntered = true;
    
    Game[] public games;
    
    constructor() public {}

    modifier nonReentrant() {
        require(_notEntered, "nonReentrant: re-entered");
        _notEntered = false;
        _;
        _notEntered = true;
    }
    function createGame(address _playA, address _playB) public returns (bool){
        require(_playA != _playB, "A different address is required");
        games.push(
            Game({
                playA: _playA,
                playB: _playB,
                encryptedA: bytes32(0),
                encryptedB: bytes32(0),
                valueA: 0,
                valueB: 0,
                statusA: false,
                statusB: false,
                revealTimeA: 0,
                revealTimeB: 0,
                gameStatus: true,
                winner: address(0),
                gameResult: 0
            }));
            
        return true;

    }
    
    function playGame(uint _gid, bytes32 _encrypted) payable public returns (bool){
        
        Game storage game = games[_gid];
        require(game.gameStatus, "The game is over");
        require(game.playA == msg.sender || game.playB == msg.sender, "You are not qualified to play");
        require(msg.value == 5 ether, "Insufficient margin");
        if (game.playA == msg.sender){
            require(game.encryptedA == bytes32(0),"You have sent out data");
            game.encryptedA = _encrypted;
        } else{
            require(game.encryptedB == bytes32(0),"You have sent out data");
            game.encryptedB = _encrypted;
        }
    }
    
    function exitGame(uint _gid) public nonReentrant returns(bool){
        Game storage game = games[_gid];
        require(game.gameStatus, "The game is over");
        require(game.playA == msg.sender || game.playB == msg.sender, "You don't have game rights");
        if (game.playA == msg.sender){
            require(game.encryptedA != bytes32(0) && game.encryptedB == bytes32(0),"The game cannot be stopped");
            game.gameStatus = false;
            game.gameResult = 4;
            game.playA.transfer(5 ether);
        } else{
            require(game.encryptedB != bytes32(0) && game.encryptedA == bytes32(0),"The game cannot be stopped");
            game.gameStatus = false;
            game.gameResult = 5;
            game.playA.transfer(5 ether);
        }
    }
    
    
    function reveal(uint _gid, uint _value, bytes32 _secret) public nonReentrant returns (bool){
        Game storage game = games[_gid];
        require(game.gameStatus, "The game is over");
        require(game.playA == msg.sender || game.playB == msg.sender, "You don't have game rights");
         if (game.playA == msg.sender){
            require(!game.statusA, "You have verified it");
            require(game.encryptedA == keccak256(abi.encodePacked(_value, _secret)), "Data error");
            game.statusA = true;
            game.valueA = _value;
            game.revealTimeA = block.timestamp;
            game.playA.transfer(4 ether);
            if(game.statusB){
                game.gameStatus = false;
                
                if(game.valueA != 0 &&  game.valueA != 1 && game.valueB != 0 && game.valueB != 1){
                    game.playA.transfer(1 ether);
                    game.playB.transfer(1 ether);
                    game.gameResult = 3;
                    return true;
                }
                
                if(game.valueA != 0 && game.valueA != 1){
                    game.playB.transfer(2 ether);
                    game.winner = game.playB;
                    game.gameResult = 2;
                    return true;
                }
                
                if(game.valueB != 0 && game.valueB != 1){
                    game.playA.transfer(2 ether);
                    game.winner = game.playA;
                    game.gameResult = 1;
                    return true;
                }
                
                if(game.valueA == game.valueB){
                    game.playB.transfer(2 ether);
                    game.winner = game.playB;
                    game.gameResult = 2;
                    return true;
                }else{
                    game.playA.transfer(2 ether);
                    game.winner = game.playA;
                    game.gameResult = 1;
                    return true;
                }
            }
        } else{
            require(!game.statusB, "You have verified it");
            require(game.encryptedB == keccak256(abi.encodePacked(_value, _secret)), "Data error");
            game.statusB = true;
            game.valueB = _value;
            game.revealTimeB = block.timestamp;
            game.playB.transfer(4 ether);
            if(game.statusA){
                game.gameStatus = false;
                
                if(game.valueA != 0 && game.valueA != 1 && game.valueB != 0  &&  game.valueB != 1){
                    game.playB.transfer(1 ether);
                    game.playA.transfer(1 ether);
                    game.gameResult = 3;
                    return true;
                }
                
                if(game.valueA != 0 && game.valueA != 1){
                    game.playB.transfer(2 ether);
                    game.winner = game.playB;
                    game.gameResult = 2;
                    return true;
                }
                
                if(game.valueB != 0 && game.valueB != 1){
                    game.playA.transfer(2 ether);
                    game.winner = game.playA;
                    game.gameResult = 1;
                    return true;
                }
                
                if(game.valueA == game.valueB){
                    game.playA.transfer(2 ether);
                    game.winner = game.playA;
                    game.gameResult = 1;
                    return true;
                }else{
                    game.playB.transfer(2 ether);
                    game.winner = game.playB;
                    game.gameResult = 2;
                    return true;
                }
            }
        }
        
    }
 
    function gamesLength() public view returns (uint){
        return games.length;
    }
    
    // 0x5B38Da6a701c568545dCfcB03FcB875f56beddC445dCfcB03FcB875f56beddC4  需要传入64位  
    function encryptedData(uint _value, bytes32 _secret) public pure returns (bytes32){
        return keccak256(abi.encodePacked(_value, _secret));
    }
    


}