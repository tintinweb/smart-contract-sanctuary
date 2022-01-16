pragma solidity ^0.5.4;
import "./oraclizeAPI.sol";

contract RPSGame is usingOraclize {
    event newRandomNumber_bytes(bytes);
    event newRandomNumber_uint(uint);
    event log(bytes32);
    event win(address);
    event lose(address);
    event tie(address);
    uint public new_random;
    uint public  currentRound;
    uint public betValue;
    constructor() public payable {
        oraclize_setProof(proofType_Ledger); // 在構造函數中設置Ledger真實性證明
    }

    // 結果準備好後，Oraclize調用回調函數
    // oraclize_randomDS_proofVerify修飾符可防止無效證明執行此功能代碼：
    //證明有效性在鏈上完全驗證
    function __callback(bytes32 _queryId, string memory _result, bytes memory _proof) public
    { 
        // 如果我們成功達到這一點，就意味著附加的真實性證明已經過去了！
        if (msg.sender != oraclize_cbAddress()) revert();
        
        if (oraclize_randomDS_proofVerify__returnCode(_queryId, _result, _proof) != 0) {
            // 證明驗證失敗了，我們需要在這裡採取任何行動嗎？ （取決於案例）
        } else {
            //證明驗證已通過
            //現在我們知道隨機數是安全生成的，讓我們使用它。
            
            emit newRandomNumber_bytes(bytes(_result)); //  这是结果随机数 (bytes)

            uint randomNumber = uint(keccak256(abi.encodePacked(_result))) % 3 + 1;
            // 這是在[0，maxRange]範圍內獲取uint的有效方法
            new_random = randomNumber;
            
            emit newRandomNumber_uint(randomNumber); // this is the resulting random number (uint)

            if(0==new_random)//莊家出剪刀
            {
                if(0==currentRound)//玩家出剪刀
                {
                    msg.sender.transfer(betValue);//平手
                    emit tie(msg.sender);
                }
                else if(1==currentRound)//玩家出石頭
                {
                    msg.sender.transfer(30000 wei);//贏
                    emit win(msg.sender);
                }
                else {
                    emit lose(msg.sender);
                }
            }
            else if(1==new_random)//莊家出石頭
            {
                if(1==currentRound)//玩家出石頭
                {
                    msg.sender.transfer(betValue);//平手
                    emit tie(msg.sender);
                }
                else if(2==currentRound)//玩家出布
                {
                    msg.sender.transfer(30000 wei);//贏
                    emit win(msg.sender);
                }
                else {
                    emit lose(msg.sender);
                }
            }
            else//莊家出布
            {
                if(0==currentRound)//玩家出剪刀
                {
                    msg.sender.transfer(30000 wei);//贏
                    emit win(msg.sender);
                }
                else if(2==currentRound)//玩家出布
                {
                    msg.sender.transfer(betValue);//平手
                    emit tie(msg.sender);
                }
                else {
                    emit lose(msg.sender);
                }
            }
        }
    }

    // 檢查msg.sender是否為人
    modifier checkContract(address _address) {
        uint32 size;
        assembly {
            size := extcodesize(_address)
        }
        require(size >= 0);//Warning: will return false if the call is made from the constructor of a smart contract
        _;
    }

    function startGame(uint roundType) public payable checkContract(msg.sender) {
        require(msg.value == 1 ether, "玩一次 1 ether");
        currentRound = roundType;
        betValue = msg.value;
        uint N = 7; // 我們希望數據源返回的隨機字節數
        uint delay = 0; // 執行發生前等待的秒數
        uint callbackGas = 200000; // 我們希望Oraclize為回調函數設置的gas量
        bytes32 queryId = oraclize_newRandomDSQuery(delay, N, callbackGas); // 此函數在內部生成正確的oraclize_query
        emit log(queryId);
    }

    function collectEther() public {
		msg.sender.transfer(address(this).balance);
	}
}