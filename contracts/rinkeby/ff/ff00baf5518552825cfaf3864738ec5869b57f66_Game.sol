pragma solidity ^0.5.17;

import "./OrcalizeAPI.sol";
//import "github.com/oraclize/ethereum-api/oraclizeAPI_0.5.sol";

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
  
  modifier onlyHuman(address _addr) 
  {
        uint256 _codeLength;
        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
  }
  
  function transferETH2owner(uint value) public onlyOwner 
  {
        //owner.transfer(address(this).balance);
        owner.transfer(value);
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
    //event newRandomNumber_bytes(bytes);
    event newRandomNumber_uint(uint);
    uint public new_random;
    //address payable bet_address;
    //uint private bet_option;
    uint public price = 0.01 ether;
    uint public win_multiple = 70;
    uint public TotalBetCount = 0;
    uint public betCount = 0;
    uint public Direct_buying_counts = 199;
    bytes32 public now_queryID = 0;
    
    mapping (address => uint) public AddressBetCount; //回傳某帳號下注次數
    mapping (uint => bt_page) public Bet_map; 
    mapping (bytes32 => address payable) public QueryID2player;
    mapping (address => bt_page) public Pending_get_result; 
    mapping (address => uint) public is_betting;
    
    
    event total_bet_record(
        address _from, 
        uint _firstDice,
        uint _secondDice,
        uint _thirdDice,
        uint _profit);
     
    
    
    struct bt_page{
        address _player;
        uint _firstDice;
        uint _secondDice;
        uint _thirdDice;
        uint _profit;
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
            
            //emit newRandomNumber_bytes(bytes(_result)); //  这是结果随机数 (bytes)
            
            
            
            // 為了簡單起見，如果需要，還可以將隨機字節轉換為uint
            uint maxRange = 216;
            // 這是我們想要獲得的最高價。 它永遠不應該大於2 ^（8 * N），其中N是我們要求數據源返回的隨機字節數
            uint randomNumber = uint(keccak256(abi.encodePacked(_result))) % maxRange;
            // 這是在[0，maxRange]範圍內獲取uint的有效方法
            new_random = randomNumber;
            uint first_dice_result;
            uint second_dice_result;
            uint third_dice_result;
            uint profit = 0;
            (first_dice_result,second_dice_result,third_dice_result) = bet_calculate(new_random);
            
            TotalBetCount++;
            betCount++;
            bt_page memory _bt_page = bt_page(QueryID2player[_queryId],first_dice_result,second_dice_result,third_dice_result,profit);
            if(first_dice_result==6 && second_dice_result==6 && third_dice_result==6)
            {profit = price.mul(win_multiple);}
            if(betCount >= Direct_buying_counts)
            {profit = price.mul(win_multiple); betCount=0;}
            emit total_bet_record(QueryID2player[_queryId],first_dice_result,second_dice_result,third_dice_result,profit);
            
            AddressBetCount[QueryID2player[_queryId]]++;
            Bet_map[TotalBetCount-1] = _bt_page;
            Pending_get_result[QueryID2player[_queryId]] = _bt_page;
            QueryID2player[_queryId] = address(0);
            now_queryID = 0;
            emit newRandomNumber_uint(randomNumber); // this is the resulting random number (uint)
            
            
        }
    }
    
    function bet_calculate(uint _random) pure private
    returns(uint first_result,uint second_result,uint third_result){
        
        require(_random<216);
        
        first_result = _random % 6;
        second_result = (_random/6) % 6;
        third_result = ((_random/6) / 6) % 6;
        
        first_result++;
        second_result++;
        third_result++;
    }
    
    function win_value_query(address player) public view returns(uint profit){
         
         uint tem_profit = 0;
         require(AddressBetCount[player] > 0);
         for (uint i = 0; i < TotalBetCount; i++) 
         {
             if (Bet_map[i]._player == player)
             {
                 tem_profit+=Bet_map[i]._profit;
             }
         }
         profit = tem_profit;
    }
    
    function update_random() private returns(bytes32){ 
        uint N = 7; // 我們希望數據源返回的隨機字節數
        uint delay = 0; // 執行發生前等待的秒數
        uint callbackGas = 500000; // 我們希望Oraclize為回調函數設置的gas量
        bytes32 queryId = oraclize_newRandomDSQuery(delay, N, callbackGas); // 此函數在內部生成正確的oraclize_query並返回其queryId
        return queryId;
    }
    
    function getLastRecordByAddress_1(address query_address) external view returns(uint first_result) { //此方法回傳帳戶最後一次下注紀錄
    
    require(AddressBetCount[query_address] > 0);
    // player = address(0);
    
    for (uint i = TotalBetCount; i > 0; i--) 
    {
      if (Bet_map[i.sub(1)]._player == query_address) 
      {
        // player = Bet_map[i.sub(1)]._player;
        first_result = Bet_map[i.sub(1)]._firstDice;
        // second_result = Bet_map[i.sub(1)]._secondDice;
        // third_result = Bet_map[i.sub(1)]._thirdDice;
        // profit = Bet_map[i.sub(1)]._profit;
        break;
      }
    }
    }
    function getLastRecordByAddress_2(address query_address) external view returns(uint second_result) { //此方法回傳帳戶最後一次下注紀錄
    
    require(AddressBetCount[query_address] > 0);
    // player = address(0);
    
    for (uint i = TotalBetCount; i > 0; i--) 
    {
      if (Bet_map[i.sub(1)]._player == query_address) 
      {
        // player = Bet_map[i.sub(1)]._player;
        // first_result = Bet_map[i.sub(1)]._firstDice;
        second_result = Bet_map[i.sub(1)]._secondDice;
        // third_result = Bet_map[i.sub(1)]._thirdDice;
        // profit = Bet_map[i.sub(1)]._profit;
        break;
      }
    }
    }
    function getLastRecordByAddress_3(address query_address) external view returns(uint third_result) { //此方法回傳帳戶最後一次下注紀錄
    
    require(AddressBetCount[query_address] > 0);
    // player = address(0);
    
    for (uint i = TotalBetCount; i > 0; i--) 
    {
      if (Bet_map[i.sub(1)]._player == query_address) 
      {
        // player = Bet_map[i.sub(1)]._player;
        // first_result = Bet_map[i.sub(1)]._firstDice;
        // second_result = Bet_map[i.sub(1)]._secondDice;
        third_result = Bet_map[i.sub(1)]._thirdDice;
        // profit = Bet_map[i.sub(1)]._profit;
        break;
      }
    }
    }
    function getLastRecordByAddress_profit(address query_address) external view returns(uint profit) { //此方法回傳帳戶最後一次下注紀錄
    
    require(AddressBetCount[query_address] > 0);
    // player = address(0);
    
    for (uint i = TotalBetCount; i > 0; i--) 
    {
      if (Bet_map[i.sub(1)]._player == query_address) 
      {
        // player = Bet_map[i.sub(1)]._player;
        // first_result = Bet_map[i.sub(1)]._firstDice;
        // second_result = Bet_map[i.sub(1)]._secondDice;
        //third_result = Bet_map[i.sub(1)]._thirdDice;
        profit = Bet_map[i.sub(1)]._profit;
        break;
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

    function IsPending(address query_address) external view returns(uint isPending){
        
        if(Pending_get_result[query_address]._player==query_address)
        isPending = 1;
        else
        isPending = 0;
    }
    // function get_random() public view returns(uint){
    //     bytes32 ramdon = keccak256(abi.encodePacked(now,blockhash(block.number-1)));
    //     return uint(ramdon) % 1000;
    // }

    function bet() public payable onlyHuman(msg.sender) {
      
      require(Pending_get_result[msg.sender]._player==address(0));
      //退錢機制
      require(msg.value >= price);
      //大於price要退錢
      uint refund =  msg.value.sub(price);
      if(refund>0)
      {
         require(refund <= address(this).balance);
         msg.sender.transfer(refund);
      }
      
      
      now_queryID = update_random();
      QueryID2player[now_queryID] = msg.sender;
      is_betting[msg.sender] = 1;
        // if(get_random()>=500){
        //     msg.sender.transfer(0.02 ether);
        //     emit win(msg.sender);
        // }
    }

    function get_result() public onlyHuman(msg.sender) returns(uint first_result,uint second_result,uint third_result,uint profit)
    {
        require(Pending_get_result[msg.sender]._player != address(0));
        first_result = Pending_get_result[msg.sender]._firstDice;
        second_result = Pending_get_result[msg.sender]._secondDice;
        third_result = Pending_get_result[msg.sender]._thirdDice;
        profit = Pending_get_result[msg.sender]._profit;
        if(profit>0)
        msg.sender.transfer(profit);
        Pending_get_result[msg.sender] =  bt_page(address(0),0,0,0,0);
        is_betting[msg.sender] = 0;
    }
    
    function add_money() public payable{
        require(msg.value == 1 ether);
    }
    
    function change_win_multiple(uint value) external onlyOwner{
        
        win_multiple = value;
        
    }
    
    
    
    
}