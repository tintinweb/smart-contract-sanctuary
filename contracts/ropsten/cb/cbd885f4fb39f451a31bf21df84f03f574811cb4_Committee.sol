pragma solidity ^0.4.23;

contract owned {
    address public owner;

  constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract TokenERC20 {
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    // This generates a public event on the blockchain that will notify clients
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
     constructor(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value > balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` in behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }

    /**
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender&#39;s allowance
        totalSupply -= _value;                              // Update totalSupply
        emit Burn(_from, _value);
        return true;
    }
}

/******************************************/
/*       ADVANCED TOKEN STARTS HERE       */
/******************************************/

contract MyAdvancedToken is owned, TokenERC20 {

    uint256 public sellPrice;
    uint256 public buyPrice;

    mapping (address => bool) public frozenAccount;

    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);

    /* Initializes contract with initial supply tokens to the creator of the contract */
   constructor(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) TokenERC20(initialSupply, tokenName, tokenSymbol) public {}

    /* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead
        require (balanceOf[_from] >= _value);               // Check if the sender has enough
        require (balanceOf[_to] + _value >= balanceOf[_to]); // Check for overflows
        require(!frozenAccount[_from]);                     // Check if sender is frozen
        require(!frozenAccount[_to]);                       // Check if recipient is frozen
        balanceOf[_from] -= _value;                         // Subtract from the sender
        balanceOf[_to] += _value;                           // Add the same to the recipient
        emit Transfer(_from, _to, _value);
    }

    /// @notice Create `mintedAmount` tokens and send it to `target`
    /// @param target Address to receive the tokens
    /// @param mintedAmount the amount of tokens it will receive
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        emit Transfer(0, this, mintedAmount);
        emit Transfer(this, target, mintedAmount);
    }

    /// @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
    /// @param target Address to be frozen
    /// @param freeze either to freeze it or not
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

    /// @notice Allow users to buy tokens for `newBuyPrice` eth and sell tokens for `newSellPrice` eth
    /// @param newSellPrice Price the users can sell to the contract
    /// @param newBuyPrice Price users can buy from the contract
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

    /// @notice Buy tokens from contract by sending ether
    function buy() payable public {
        uint amount = msg.value / buyPrice;               // calculates the amount
        _transfer(this, msg.sender, amount);              // makes the transfers
    }

    /// @notice Sell `amount` tokens to contract
    /// @param amount amount of tokens to be sold
    function sell(uint256 amount) public {
        address myAddress = this;
        require(myAddress.balance >= amount * sellPrice);      // checks if the contract has enough ether to buy
        _transfer(msg.sender, this, amount);              // makes the transfers
        msg.sender.transfer(amount * sellPrice);          // sends ether to the seller. It&#39;s important to do this last to avoid recursion attacks
    }
}
contract PickNumber is MyAdvancedToken{
    //建構子透過TOKEN函式
     constructor (
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) MyAdvancedToken(initialSupply, tokenName, tokenSymbol) public {}
    //PickNumber事件
    event PickNumberEvent(uint choosenumber, uint amount);
    //giveWinner事件
    event giveWinnerEvent(address[] winner,uint winprize);
    event resetEvent();
    //0~100數字量
    uint[101] public number;
    //玩家列表
    address[] public playerlist;
    //投注數字總量
    uint public totalnum;
    //開獎冷卻
    uint givewinnercooldown= 10 seconds ;
    uint public givewinner_readytime;
    uint payforwinfee= 0.0001 ether;
    uint public start=0;
    //數字 對應 其擁有者(陣列)
    mapping(uint=>address[])public  NumToOwner;
    //擁有者所 對應數字(陣列)
    mapping(address=>uint[])public  OwnerToNum;
    //擁有者 對應 擁有不重複數字量
    mapping(address=>uint) public   OwnerCount;
    //擁有者 對應 數字 對應 數字量
    mapping(address=> mapping(uint=>uint))public OwnerNumCount;
    //玩家 對應 參加與否
    mapping (address=> bool)public joining;
    /*
        檢查該數字是否被該玩家選過
        選過則回傳True
    */
    function Checkpick(uint _number ,address _address) public view returns(bool){
        uint[] memory temp;
        temp=OwnerToNum[_address];
        for(uint j=0;j<temp.length;j++){
            if(_number==temp[j])
             return true;
        }
    }
    /*
        參加遊戲
       每一輪只能參加一次
       初始token 100
       將玩家加入 playerlist
    */
    function joingame  () public {
        require(!joining[msg.sender]);
        joining[msg.sender]=true;
        if(start==0)
            _triggergivewinner_cooldowntime();
        _transfer(owner,msg.sender,100);
        playerlist.push(msg.sender);
        start=1;
    }
     function payfortoken()public payable{
        require(joining[msg.sender]);
        require(msg.value>=payforwinfee);
        _transfer(owner,msg.sender,10000);
    }
    /*
        選擇數字介於0~100 擁有TOKEN大於下注量 下注量>0
        先檢查數字是否被選過
        沒有則OwnerCount++
              NumToOwner[_choosenumber]加入choosenumber
              OwnerToNum[玩家]加入玩家
        OnwerNumCount[玩家][_choosenumber]加入數字量
        將_amount轉給合約
        totalnum+上_amount.
        觸發PickNumberevent
    */
    function PickYourNumber(uint _choosenumber ,uint _amount) public {
        require(_choosenumber>0&&_choosenumber<=100);
        require(balanceOf[msg.sender]>_amount);
        require(_amount>0);
        require(joining[msg.sender]);
        uint temp =balanceOf[address(this)];
        _transfer(msg.sender,address(this),_amount);
        uint temp2= balanceOf[address(this)];
        require(temp2>=temp+_amount);
        bool check=((Checkpick(_choosenumber,msg.sender)));
        number[_choosenumber]+=_amount;
        if(check==false){
            OwnerCount[msg.sender]++;}
        if(check==false){
            NumToOwner[_choosenumber].push(msg.sender);}
        if(check==false){
            OwnerToNum[msg.sender].push(_choosenumber);}
        OwnerNumCount[msg.sender][_choosenumber]+=_amount;
        totalnum+=_amount;
        emit PickNumberEvent(_choosenumber,_amount);
        
        
    }
    /*
        回傳玩家選所選擇之數字(陣列)與
                          數字量(陣列)
    */
    function getNumberPick()public view returns(uint[],uint[]){
     uint[] memory temp;
     uint[] memory  result=new uint[](OwnerCount[msg.sender]);
     temp=OwnerToNum[msg.sender];
        for(uint j=0; j<temp.length;j++){
         result[j]= OwnerNumCount[msg.sender][temp[j]];
        }
      return(temp,result);
    }
    /*
        獲得最後得獎號碼
        將number數字與數字量做加權
        再將num*2/3得到最後數字
    */
  
    function getWinnumber()public view returns(uint){
        uint total;
        uint num;
        uint winnummber;
        for(uint i=0;i<101;i++){
          total+= number[i]*i;
        }
        num=total/totalnum;
        winnummber=num*2/3;
        return winnummber;
    }
    /*
        回傳擁有勝利數字之擁有者(陣列)
    */
    function getWinner() public view returns(address[]){
        address[] memory winlist;
        uint winnernum=getWinnumber();
       winlist=NumToOwner[winnernum];
       return winlist;
    }
    /*
        回傳合約所獲得之TOKEN
    */
    function getWinprize()public view returns(uint){
    return  balanceOf[address(this)];
    }
    /*
        觸發派獎冷卻
    */
function _triggergivewinner_cooldowntime() internal  {
        givewinner_readytime=uint32(now + givewinnercooldown); 
  }
  /*
    回傳玩家所擁有之TOKEN
  */
  function getYourToken()public view returns(uint){
      return balanceOf[msg.sender];
  }
  /*
    回傳冷卻是否完成
  */
  function givewinnerReady()public view returns (bool){
      return(givewinner_readytime<=now);            
  }
  function getcooldowntime()public view returns (uint){
      return(givewinner_readytime-now);            
  }
  /*
    發獎給得獎者
    將總獎金平分給winnerlist中的玩家
  */
  function givewinner()public onlyOwner{
       require(givewinnerReady());
       uint winnerprize=getWinprize();
       address[] memory winnerlist =getWinner();
       uint winnercount=winnerlist.length;
       uint winnernumber=getWinnumber();
       uint num_count=number[winnernumber];
       uint averageprize=winnerprize/num_count;
       require(winnerprize>=totalnum);
       require(winnercount!=0);
       for(uint i=0;i<winnercount;i++){
         uint winner_numcount= OwnerNumCount[winnerlist[i]][winnernumber];
           _transfer(address(this),winnerlist[i],averageprize*winner_numcount-1);
       }
       _triggergivewinner_cooldowntime();
       emit giveWinnerEvent(winnerlist,averageprize-1);
       reset();
    }
    /*
        將所有值重製
    */
   function reset() public onlyOwner{
        address[] memory temp;
        uint[]   memory temp1;
        uint[] memory result;
        address[] memory temp2;
        for(uint i=0;i<101;i++){
            number[i]=0;
            NumToOwner[i]=temp;
        }
        totalnum=0;
        _transfer(address(this),owner,balanceOf[address(this)]);
        uint playercount=playerlist.length;
        for(uint j=0;j<playercount;j++){
             result=OwnerToNum[playerlist[j]]; 
             for(uint k=0;k<result.length;k++){
                OwnerNumCount[playerlist[j]][result[k]]=0;
             }
            OwnerCount[playerlist[j]]=0;
            OwnerToNum[playerlist[j]]=temp1;
            joining[playerlist[j]]=false;
        }
        start=0;
        playerlist=temp2;
        emit resetEvent();
    }

}
contract Committee is PickNumber{
   constructor (
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) PickNumber(initialSupply, tokenName, tokenSymbol) public {}

event C_giveWinnerEvent(address[] winner,uint winprize,uint winnumber);

address[] public Committeelist;
 function C_joingame  () public {
        require(!joining[msg.sender]);
        joining[msg.sender]=true;
        if(start==0)
            _triggergivewinner_cooldowntime();
        _transfer(owner,msg.sender,100);
        playerlist.push(msg.sender);
        Committeelist.push(msg.sender);
        start=1;
    }
    
        //取得獲獎數字,將玩家所有下注之數字加總(包含Comittee)+上block的info
        //相加取hash在%101
     function C_getWinnumber()public view returns(uint){ 
        uint total;
        uint winnumber;
        for(uint i=0;i<101;i++){
          total+= number[i]*i;
        }
        uint n;
        uint d;
        (n,d)=C_getBlockinfo();
        winnumber=uint(keccak256(total+n+d))%101;
        return winnumber;
    }
        //取得得獎者
        function C_getWinner() public view returns(address[]){
        address[] memory winlist;
        uint winnernum=C_getWinnumber();
       winlist=NumToOwner[winnernum];
       return winlist;
    }
    //獲得blockinfo time,number,difficulty
    function C_getBlockinfo()public view returns(uint,uint){
        uint number;
        uint diff;
       number=block.number;
       diff=uint(block.difficulty);
       return (number,diff);
    }
    //派獎
    function C_givewinner()onlyOwner public  {
       require(givewinnerReady());
       uint winnerprize=getWinprize();
       address[] memory winnerlist =C_getWinner();
       uint winnercount=winnerlist.length;
       uint winnernumber=C_getWinnumber();
       uint num_count=number[winnernumber];
       uint averageprize=winnerprize/num_count;
       require(winnerprize>=totalnum);
       require(winnercount!=0);
       for(uint i=0;i<winnercount;i++){
         uint winner_numcount= OwnerNumCount[winnerlist[i]][winnernumber];
           _transfer(address(this),winnerlist[i],averageprize*winner_numcount-1);
       }
       _triggergivewinner_cooldowntime();
        emit C_giveWinnerEvent(winnerlist,averageprize*winner_numcount-1,winnernumber);
           reset();
    }
}