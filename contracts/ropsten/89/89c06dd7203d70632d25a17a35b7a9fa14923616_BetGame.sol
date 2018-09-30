pragma solidity ^0.4.0;
//import "https://github.com/pipermerriam/ethereum-string-utils/contracts/StringLib.sol";


contract BetGame {
    uint public  PoolBalance;
    bool public commitStage;
    bool public PreStage;
    uint public betCost;
    uint public betRange;
    uint public round = 0;
    uint public winningNumber;
    bytes32 public initSeed;
    uint [] public betNumbers;
   
   
    //GameInfo public gameinfo;
   
    
    
    
   
    struct GameInfo
    {
        uint  PoolBalance;
        bool  commitStage;
        bool  PreStage;
        uint  round;
        uint  winningNumber;
        bytes32 initSeed;
        uint []  betNumbers;
    }
    
    struct BetCollection
    {
       // uint number;
        address [] betAddress;
    }
    
    
    struct Player
    {
        address addr;
        bytes32[] secertBet;
     //  uint balance;
        uint[] betNumbers;
    }
    mapping(uint =>mapping(uint => BetCollection)) betCollection;
    mapping(address=>mapping (uint=>Player)) public players;
    mapping(address=>uint) public playerBalance;
    uint storedData;
    event FundTransfer(address backer, uint amount);
    
    address public owner;

    constructor () public
    {
        owner = msg.sender;
        PreStage=true;
        betCost=1 finney;
        betRange=3;
    }
    
     modifier onlyOwner 
    {
        require(msg.sender == owner);
        _;
    }
    
    
    
    function()public payable {
       // PoolBalance+=msg.value;
        playerBalance[msg.sender]+=msg.value;
        //return players[msg.sender].balance;
    }
    

    
    /*
    function GetGameInfo() public view returns(GameInfo)
    {
        return  GameInfo(PoolBalance,commitStage,PreStage,round,winningNumber,initSeed,betNumbers);
    }
    */
    function payForOther(address addr) payable public returns(uint)
    {
        playerBalance[addr]+=msg.value;
       // PoolBalance+=msg.value;
        return playerBalance[addr];
    }
    

    
    function commitStart(bytes32 init) public onlyOwner
    {

        require(PreStage);
        require(!commitStage);
        initSeed=init;
        commitStage=true;
       // PreStage=false;
        round++;
        winningNumber=0;
        delete betNumbers;
        //delete players;
   //     Player memory player = Player(); 
     //   players[round].push(player);

        
     }
     
     
     
  /*  function reveal(bytes32 init) public onlyOwner
    {

        require(PreStage);
        require(!commitStage);
        initSeed=init;
        commitStage=true;
        PreStage=false;

     }*/
    
    function SubmitSecretBet(bytes32 betNumber)public payable returns(bool) 
    {
        //require(msg.value>1 finney);
        require(commitStage);
        
       // require(betNumber<12);
       
    //    Player memory newplayer; 
  //      newplayer.addr=msg.sender;
          
//        players[msg.sender][round]=newplayer;
  /*     
        players[round].push(Player({
          addr: msg.sender,
          secertBet: new bytes32[],
          betNumber: new uint[]
          //dateAdded: now
        }));
*/
       
        players[msg.sender][round].secertBet.push(betNumber);
        players[msg.sender][round].addr=msg.sender;
        if(msg.value>0)
        {
            playerBalance[msg.sender]+=msg.value;
          //  PoolBalance+=msg.value;
        }
        require(playerBalance[msg.sender]>=betCost);
        playerBalance[msg.sender]-=betCost;
        PoolBalance+=betCost;
        PreStage=false;
        return true;
    }
    
    
    function revealStart() public onlyOwner
    {

       // require(PreStage);
        //require(PoolBalance);
        require(!PreStage);
        require(commitStage);
        
        commitStage=false;
    }
    
    
    
    
    function RevealBet (string code) public returns(bool)
    {
        require(!commitStage);
        require(!PreStage);

        
        
        string memory s = string(code);
        bool keybuyed;
        keybuyed=false;
        bytes32 key=keccak256(s);
        uint j;
        for(j=0;j<players[msg.sender][round].secertBet.length;j++)
        {
            if(key==players[msg.sender][round].secertBet[j])
            {
                keybuyed=true;
                break;
                
            }
        }
            //keybuyed=(key==players[msg.sender].secertBet[j] || buyed);
        
        require(keybuyed);
       
        bytes memory b;
        b= bytes(code);
        uint i;
        uint betNumber;
        for (i = 0; i < b.length; i++) 
        {
            uint c = uint(b[i]);
            if (c >= 48 && c <= 57) 
            {
                betNumber= betNumber * 10 + (c - 48);
            }
            else
            break;
            
        }
        
        bool buyed=false;
        
        for (uint k=0;k<players[msg.sender][round].betNumbers.length;k++)
        {
            if (betNumber==players[msg.sender][round].betNumbers[k])
            {
                buyed=true;
                break;
            }
        }
        
        require(!buyed);
        
        if (betNumber<=betRange && betNumber>0)
        //string memory bet=uint2str(betNumber);
        {
            players[msg.sender][round].betNumbers.push(betNumber);
            betCollection[betNumber][round].betAddress.push(msg.sender);
            betNumbers.push(betNumber);
            return true;
        }
        else
        {
            revert();
          //  playerBalance[msg.sender]+=betCost;
            return false;
        }
    }
    
    function revealWinner(string code) public onlyOwner returns(uint)
    {

       
        require(!commitStage);
        require(!PreStage);
        
        uint playerseed;
        bytes32 randHash;
        uint winnercount;
        require(keccak256(code)==initSeed);
        for(uint i=0;i<betNumbers.length;i++)
        {
            playerseed+=betNumbers[i];
        }
        randHash = keccak256(code, playerseed, block.number);
        winningNumber = uint(randHash) % betRange+1;
        winnercount=betCollection[winningNumber][round].betAddress.length;
        if (winnercount>0)
        {
            uint prize=PoolBalance/winnercount;
            for(uint j=0;j<winnercount;j++)
            {
               address winner= betCollection[winningNumber][round].betAddress[j];
               playerBalance[winner]+=prize;
               PoolBalance-=prize;
            }
        }
        
     //   address winningAddress[] = betCollection[winningNumber].address;
        commitStage=false;
        PreStage=true;
        return winningNumber;
    }
    
    function ViewMyBet()  public view returns(bytes32[],uint[])
    {
        return ViewtBet(msg.sender);
    }
    
    function ViewtBet(address addr)  public view returns(bytes32[],uint[])
    {
        return (players[addr][round].secertBet,players[addr][round].betNumbers);
    }
   
    function ViewBet2(address addr,uint n)  public view returns(uint)
    {
        return (players[addr][round].betNumbers[n]);
    }
   

 //   function getSecretBet(address playerAddress) public view returns (bytes32[]) {
 //       return players[playerAddress].secertBet;
 //   }
 
 
 
     function changeCost(uint cost) public onlyOwner
    {
        betCost=cost;
    }
    
    function changeBetRange(uint range) public onlyOwner
    {
        betRange=range;
    }
    
     function transferOwnership(address newOwner) onlyOwner public
    {
        owner = newOwner;
    }
    
    function withdraw (uint amount) public returns(bool)
    {
       
            require(amount > 0 && amount<=playerBalance[msg.sender]);
            
                msg.sender.transfer(amount);
                emit FundTransfer(msg.sender, amount);
                playerBalance[msg.sender]-=amount;
             //   PoolBalance-=amount;
    }
    
   // function getPlayerBalance(address playerAddress)public view returns(uint){
     //   return playerBalance[playerAddress];
    //}
    
    function getBalance()public view returns(uint){
        return playerBalance[msg.sender];
    }
    
 //   function getPoolBalance()public view returns(uint){
 //       return PoolBalance;
 //   }

     function uint2str(uint i) internal pure returns (string){
        if (i == 0) return "0";
        uint j = i;
        uint length;
        while (j != 0){
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint k = length - 1;
        while (i != 0){
            bstr[k--] = byte(48 + i % 10);
            i /= 10;
        }
      //  bytes32 a1= StringUtils.uintToBytes(1234);

        return string(bstr);
    }
     
    
    function ConvnertToSecret(uint8 betNumber,string code) public pure returns (bytes32,string){
        string memory bet=uint2str(betNumber);
        string memory s = string(abi.encodePacked(bet,code));
        return  (keccak256(s),s);
    }
    
    function self_destruct() onlyOwner public 
    {
         selfdestruct(owner);
    }
    
    
    
}