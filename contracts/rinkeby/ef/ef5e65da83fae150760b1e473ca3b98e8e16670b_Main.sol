pragma solidity ^0.4.26;
import "./oraclizeAPI_0.4.sol";

contract Main is usingOraclize{
    
    mapping (bytes32=>uint) public recordsChoice;
    mapping (bytes32=>address) public recordsPlayer;
    uint public new_random;
    bytes32 public queryId;
    event Roundrecords(address player,uint choice,string result);
    uint[4][4] rule;
    
    constructor() public payable{
        require(msg.value == 1 ether);
        oraclize_setProof(proofType_Ledger);
        rule[1][1] = 0;
        rule[1][2] = 1;
        rule[1][3] = 2;
        rule[2][1] = 2;
        rule[2][2] = 0;
        rule[2][3] = 1;
        rule[3][1] = 1;
        rule[3][2] = 2;
        rule[3][3] = 0;
    }
    
    
    
    function __callback(bytes32 _queryId, string _result, bytes _proof) public{
        if (msg.sender != oraclize_cbAddress()) revert();
        
        if (oraclize_randomDS_proofVerify__returnCode(_queryId, _result, _proof) != 0) {
            // 證明驗證失敗了，我們需要在這裡採取任何行動嗎？ （取決於案例）
        } else {
            //證明驗證已通過
            //現在我們知道隨機數是安全生成的，讓我們使用它。
            
            
            // 為了簡單起見，如果需要，還可以將隨機字節轉換為uint
            // 這是我們想要獲得的最高價。 它永遠不應該大於2 ^（8 * N），其中N是我們要求數據源返回的隨機字節數
            uint randomNumber = uint(keccak256(abi.encodePacked(_result))) % 3+1;
            // 這是在[0，maxRange]範圍內獲取uint的有效方法
            new_random = randomNumber;
            uint _choice = recordsChoice[_queryId];
            judge(_choice,new_random);
        }
    }
    
    function judge(uint _choice,uint _random) public{
        if (rule[_choice][_random] == 2){
            msg.sender.transfer(0.02 ether);
            emit Roundrecords(msg.sender,_choice,"win");
        }
        else if(rule[_choice][_random] == 1){
            emit Roundrecords(msg.sender,_choice,"Lose");
        }
        else{
            msg.sender.transfer(0.01 ether);
            emit Roundrecords(msg.sender,_choice,"tie");
        }
    }
    
    
    
    
    function StratNewRound(uint choice) public payable{
        require(msg.value == 0.01 ether);
        uint N = 7; // 我們希望數據源返回的隨機字節數
        uint delay = 0; // 執行發生前等待的秒數
        uint callbackGas = 200000; // 我們希望Oraclize為回調函數設置的gas量
        
        
        queryId = oraclize_newRandomDSQuery(delay, N, callbackGas);
        recordsPlayer[queryId] = msg.sender;
        recordsChoice[queryId] = choice;
    }
    
    
}