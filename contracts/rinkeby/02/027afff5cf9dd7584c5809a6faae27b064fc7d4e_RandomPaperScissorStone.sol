//請使用 Rinkeby 測試網測試，不能用單機 VM 測試

//pragma solidity ^0.4.11;
pragma solidity ^0.5.4;

// import "github.com/oraclize/ethereum-api/oraclizeAPI_0.4.sol";
import "./oraclizeAPI.sol";

contract RandomPaperScissorStone is usingOraclize {
    
    event newRandomNumber_bytes(bytes);
    event newRandomNumber_uint(uint);
    event setResult(string);

    uint public times;
    string public result;
    
    address payable public Player;
    mapping (uint => uint) public thisPlayerChoice;
    mapping (uint => address) public thisPlayer;
    mapping (bytes32 => address payable) public queryIdPlayer;
    
    uint public contractResult;
    
    constructor() payable public {
        oraclize_setProof(proofType_Ledger); // 在構造函數中設置Ledger真實性證明
        times = 0;
    }
    
     // 結果準備好後，Oraclize調用回調函數
     // oraclize_randomDS_proofVerify修飾符可防止無效證明執行此功能代碼：
     //證明有效性在鏈上完全驗證
    function __callback(bytes32 _queryId, string memory _result, bytes memory _proof)public
    { 
        uint yourSet;
        uint resultState = 3;
        
        // 如果我們成功達到這一點，就意味著附加的真實性證明已經過去了！
        if (msg.sender != oraclize_cbAddress()) revert();
        
        if (oraclize_randomDS_proofVerify__returnCode(_queryId, _result, _proof) != 0)
        {
            // 證明驗證失敗了，我們需要在這裡採取任何行動嗎？ （取決於案例）
        } 
        else 
        {
            //證明驗證已通過
            //現在我們知道隨機數是安全生成的，讓我們使用它。
            
            emit newRandomNumber_bytes(bytes(_result)); //  这是结果随机数 (bytes)
            
            uint randomNumber = (uint(keccak256(abi.encodePacked(_result))) % 3) + 1;
            
            contractResult = randomNumber;
            
            yourSet = thisPlayerChoice[times];
            
            // 1: scissor, 2: rock, 3: paper
            if(yourSet == contractResult)
            {
                result = "Tie";
                resultState = 3;
                emit setResult(result);
            }
            else if(yourSet == 1 && contractResult == 2)
            {
                result = "Lose";
                resultState = 2;
                emit setResult(result);
            }
            else if(yourSet == 1 && contractResult == 3)
            {
                result = "Win";
                resultState = 1;
                emit setResult(result);
            }
            else if(yourSet == 2 && contractResult == 1)
            {
                result = "Win";
                resultState = 1;
                emit setResult(result);
            }
            else if(yourSet == 2 && contractResult == 3)
            {
                result = "Lose";
                resultState = 2;
                emit setResult(result);
            }
            else if(yourSet == 3 && contractResult == 1)
            {
                result = "Lose";
                resultState = 2;
                emit setResult(result);
            }
            else if(yourSet == 3 && contractResult == 2)
            {
                result = "Win";
                resultState = 1;
                emit setResult(result);
            }
            
            if(resultState == 1)
            {
                Player.transfer(0.02 ether);
            }
            else if(resultState == 3)
            {
                Player.transfer(0.01 ether);
            }
        }
    }
    
    function StartBet(uint yourSet) payable public
    { 
        require(msg.value == 0.01 ether, "玩一次 0.01 eth");
        require(yourSet > 0 && yourSet < 4, "重新猜拳");
        
        uint N = 7; // 我們希望數據源返回的隨機字節數
        uint delay = 0; // 執行發生前等待的秒數
        uint callbackGas = 200000; // 我們希望Oraclize為回調函數設置的gas
        
        bytes32 queryId;
        
        Player = msg.sender;
        times++;
        thisPlayerChoice[times] = yourSet;
        thisPlayer[times] = Player;
        
        queryId = oraclize_newRandomDSQuery(delay, N, callbackGas); // 此函數在內部生成正確的oraclize_query並返回其queryId
        queryIdPlayer[queryId] = Player;
    }
    
}