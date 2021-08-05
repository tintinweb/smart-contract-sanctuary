//請使用 Rinkeby 測試網測試，不能用單機 VM 測試

pragma solidity ^0.5.17;

import "./OraclizeAPI.sol";
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
contract Ownable {
  address payable owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  
  modifier onlySender(address _from) 
  {
      require(msg.sender == _from);
      _;
      
  }
  
  function transferETH2owner() public onlyOwner 
  {
        owner.transfer(address(this).balance);
  }
  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address payable newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}
contract Game is usingOraclize,Ownable {
    
    using SafeMath for uint;
    event newRandomNumber_bytes(bytes);
    event newRandomNumber_uint(uint);
    uint public new_random;
    //address payable bet_address;
    uint private bet_option;//0:剪刀 1:石頭 2:布
    uint public price = 0.01 ether;
    uint public win_value = 0.029 ether;
    uint public TotalBetCount = 0;
    mapping (address => uint) public AddressBetCount; //回傳某帳號下注次數
    mapping (uint => bt_page) public Bet_map; 
    mapping (bytes32 => address payable) QueryID2player;
    
    event bet_record(address _from, uint _playerbet, uint _dealerbet, uint _result);
    //0:剪刀 1:石頭 2:布
    //0:Lose 1:Win 2:deal 
    
    
    struct bt_page{
        address _player;
        uint _playerbet;
        uint _dealerbet;
        uint _result;
    }
    
    constructor() payable public {
        require(msg.value == 1 ether);
        oraclize_setProof(proofType_Ledger); // 在構造函數中設置Ledger真實性證明
        update_random(); //在合同創建時，我們立即要求N個隨機字節！
        
    }
    
     // 結果準備好後，Oraclize調用回調函數
     // oraclize_randomDS_proofVerify修飾符可防止無效證明執行此功能代碼：
     //證明有效性在鏈上完全驗證
    function __callback(bytes32 _queryId, string memory _result, bytes memory _proof)public
    { 
        require(QueryID2player[_queryId] != address(0));
        // 如果我們成功達到這一點，就意味著附加的真實性證明已經過去了！
        if (msg.sender != oraclize_cbAddress()) revert();
        
        if (oraclize_randomDS_proofVerify__returnCode(_queryId, _result, _proof) != 0) {
            // 證明驗證失敗了，我們需要在這裡採取任何行動嗎？ （取決於案例）
        } else 
        {
            //證明驗證已通過
            //現在我們知道隨機數是安全生成的，讓我們使用它。
            
            emit newRandomNumber_bytes(bytes(_result)); //  这是结果随机数 (bytes)
            
            
            
            // 為了簡單起見，如果需要，還可以將隨機字節轉換為uint
            uint maxRange = 3;
            // 這是我們想要獲得的最高價。 它永遠不應該大於2 ^（8 * N），其中N是我們要求數據源返回的隨機字節數
            uint randomNumber = uint(keccak256(abi.encodePacked(_result))) % maxRange;
            // 這是在[0，maxRange]範圍內獲取uint的有效方法
            new_random = randomNumber;
            uint bet_result = bet_calculate(QueryID2player[_queryId],bet_option,new_random);
            emit bet_record(QueryID2player[_queryId],bet_option,new_random,bet_result);
            
            AddressBetCount[QueryID2player[_queryId]]++;
            Bet_map[TotalBetCount] = bt_page(QueryID2player[_queryId],bet_option,new_random,bet_result);
            QueryID2player[_queryId] = address(0);
            TotalBetCount++;
            
            emit newRandomNumber_uint(randomNumber); // this is the resulting random number (uint)
            
            
        }
    }
    
    function bet_calculate(address payable _player,uint _player_option,uint _dealer_option) private returns(uint result){
        
        
        if(0==_dealer_option)//莊家出剪刀
            {
                if(0==_player_option)//玩家出剪刀
                {
                    _player.transfer(price);//平手
                    return 2;
                }
                else if(1==_player_option)//玩家出石頭
                {
                    _player.transfer(win_value);//贏
                    return 1;
                }
                else//玩家出布
                {
                    //輸
                    return 0;
                }
            }
            else if(1==_dealer_option)//莊家出石頭
            {
                if(0==_player_option)//玩家出剪刀
                {
                    //輸
                    return 0;
                }
                else if(1==_player_option)//玩家出石頭
                {
                    _player.transfer(price);//平手
                    return 2;
                }
                else//玩家出布
                {
                    _player.transfer(win_value);//贏
                    return 1;
                }
            }
            else//莊家出布
            {
                if(0==_player_option)//玩家出剪刀
                {
                    _player.transfer(win_value);//贏
                    return 1;
                }
                else if(1==_player_option)//玩家出石頭
                {
                    //輸
                    return 0;
                }
                else//玩家出布
                {
                    _player.transfer(price);//平手
                    return 2;
                }
            }
        
    }
    
    function win_value_query(address player) public view returns(bool isWin,uint value){
         
         uint wincount = 0;
         uint losecount = 0 ;
         require(AddressBetCount[player] > 0);
         for (uint i = 0; i < TotalBetCount; i++) 
         {
             if (Bet_map[i]._player == player)
             {
                 if (Bet_map[i]._result == 1) 
                 {
                     wincount = wincount.add(1);
                 }
                 else if(Bet_map[i]._result == 0)
                 {
                     losecount = losecount.add(1);
                 }
             }
         }
         if(wincount>losecount)
         {
             value = wincount.sub(losecount) * win_value.sub(price);
             isWin = true;
         }
         else if(wincount<losecount)
         {
             value = losecount.sub(wincount) * price;
             isWin = false;
         }
         else
         {
             value = 0;
             isWin = true;
         }
    }
    
    function update_random() private returns(bytes32){ 
        uint N = 7; // 我們希望數據源返回的隨機字節數
        uint delay = 0; // 執行發生前等待的秒數
        uint callbackGas = 500000; // 我們希望Oraclize為回調函數設置的gas量
        bytes32 queryId = oraclize_newRandomDSQuery(delay, N, callbackGas); // 此函數在內部生成正確的oraclize_query並返回其queryId
        return queryId;
    }
    
    function getLastRecordByAddress(address query_address) external view returns(address player,uint playerbet,uint dealerbet,uint result) { //此方法回傳帳戶最後一次下注紀錄
    
    require(AddressBetCount[query_address] > 0);
    player = address(0);
    playerbet = 0;
    dealerbet = 0;
    result = 0;
    for (uint i = TotalBetCount; i > 0; i--) 
    {
      if (Bet_map[i.sub(1)]._player == query_address) 
      {
        player = Bet_map[i.sub(1)]._player;
        playerbet = Bet_map[i.sub(1)]._playerbet;
        dealerbet = Bet_map[i.sub(1)]._dealerbet;
        result = Bet_map[i.sub(1)]._result;
        //return (Bet_map[i.sub(1)]._player,Bet_map[i.sub(1)]._playerbet,Bet_map[i.sub(1)]._dealerbet,Bet_map[i.sub(1)]._result);
      }
    }
    }

    function getAllBetIndexByAddress(address query_address) external view returns(uint[] memory) { //此方法回傳帳戶all下注紀錄
    
        uint[] memory index_array = new uint[](AddressBetCount[query_address]);
        uint count = 0;
        for (uint i = 0; i < TotalBetCount; i++) 
        {
           if (Bet_map[i]._player == query_address) 
           {
             index_array[count] = i;
             count = count.add(1);
           }
        }
        return index_array;
   }

    // function get_random() public view returns(uint){
    //     bytes32 ramdon = keccak256(abi.encodePacked(now,blockhash(block.number-1)));
    //     return uint(ramdon) % 1000;
    // }

    function bet(uint options) public payable {
      
      
      require(options<3);
      //require(address(0)==bet_address);
      
      //退錢機制
      require(msg.value >= price);
      //大於price要退錢
      uint refund =  msg.value.sub(price);
      if(refund>0)
      {
         require(refund <= address(this).balance);
         msg.sender.transfer(refund);
      }
      
      
      bet_option = options;
      bytes32 _queryID = update_random();
      QueryID2player[_queryID] = msg.sender;
        // if(get_random()>=500){
        //     msg.sender.transfer(0.02 ether);
        //     emit win(msg.sender);
        // }
    }

    function add_money() public payable{
        require(msg.value == 1 ether);
    }
    
    
    
}