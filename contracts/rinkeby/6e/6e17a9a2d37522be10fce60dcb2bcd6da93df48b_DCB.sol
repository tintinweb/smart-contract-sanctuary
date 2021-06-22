/**
 *Submitted for verification at Etherscan.io on 2021-06-22
*/

pragma solidity >=0.7.0 <0.9.0;

/**
 * 基于以以太坊的双色球彩票
 */
contract DCB {
    
    string public name = "Dubbo Color Ball Ticket";
    
    // 结构体-用户下单号码信息
    struct PersonNumberInfo{
        string number;         // 用户选择的彩票号码
        uint256 totalAmount;    // 用户对应彩票号码下注金额
    }
    
    // 结构体-用户信息
    struct PersonInfo{
        address buyer;                  // 用户地址
        uint256 totalAmount;            // 用户总下单金额
        PersonNumberInfo [] numbers;    // 用户下单号码信息
    }
    
    // 购彩号码 =》 购彩地址 =》购彩信息
    mapping(uint256 => mapping(address => PersonInfo)) private ticketsNumPool;

    // 历史购彩用户地址
    mapping(uint256 => address[]) private historyBuyers;
    
    // 历史中奖信息 期数=》中奖地址=》中奖金额
    mapping(uint256=>mapping(address=>uint256)) historyLucyers;
    
    mapping(uint256=> uint) historyLuckyNubers;
    
    // 拥有者地址 
    address private owner;
    
    // 彩票期数
    uint256[] private ticketNumbers;
    
    // 彩票当前期数
    uint256 private currentNumber;
    
    Token private usdtToken;
    Token private dcbcToken;
    
    // 构造函数-初始化合约
    constructor(address _usdtAddress, address _dcbcAddress) payable{
        owner = msg.sender;
        currentNumber = block.timestamp;
        ticketNumbers.push(currentNumber);
        payable(address(this));
        usdtToken = Token(_usdtAddress);
        dcbcToken = Token(_dcbcAddress);
    }
   
    /*
     * @notice 购买彩票
     * @param number  购彩号码
     * @param amount  购彩金额
     */
    function buyTicket(uint256 amount, string memory _number) public{
      
      require(amount%1==0, 'Amount must be a integer');
      require(usdtToken.balanceOf(msg.sender) >= amount,"Insufficient balance!");
      
      bool isApproved = usdtToken.approve(address(this), amount);
      require(isApproved, 'User canceled approve to buy ticket');
      
      bool isTransfered = usdtToken.transferFrom(msg.sender,address(this), amount);
      require(isTransfered,'The transfer token was failed, buy ticket will cancel.');
      
      PersonInfo storage p = ticketsNumPool[currentNumber][msg.sender];
      
      
      if(p.totalAmount > 0) {
        PersonNumberInfo[] storage numbers = p.numbers;
        bool isContain = false;
        for(uint index = 0;index < numbers.length; index++) {
            PersonNumberInfo storage pni = numbers[index];
            string memory tmpNumber = pni.number;
            if(keccak256(abi.encode(_number))==keccak256(abi.encode(tmpNumber))) {
                pni.totalAmount += amount;
                isContain = true;
                break;
            }
        }
        if(!isContain) {
            PersonNumberInfo memory pni = PersonNumberInfo(_number, amount);
            numbers.push(pni);
        }
        p.totalAmount += amount;
        ticketsNumPool[currentNumber][msg.sender] = p;
    
      } else {
         p.totalAmount += amount;
         p.buyer = msg.sender;
         PersonNumberInfo memory pni = PersonNumberInfo(_number, amount);
         p.numbers.push(pni);
         ticketsNumPool[currentNumber][msg.sender] = p;
      }
      
      address sender = msg.sender;
      historyBuyers[currentNumber].push(sender);
      
      
      if(p.totalAmount >100 && dcbcToken.balanceOf(address(this)) > amount) {
         dcbcToken.transfer(msg.sender, amount);    
      }
      
    }

    /**
     * @notice 查询地址购彩记录
     * @param sender    查询地址
     * @return address  查询地址
     * @return string   购买的号码集合
     * @return uint256  购买的金额集合
     */
    function _getTicket(address sender) private view returns(uint256,address,string [] memory,uint256[] memory) {
        
        uint256 _totalNumbers = ticketsNumPool[currentNumber][sender].numbers.length;
        
        string[] memory numbers = new string[](_totalNumbers);
        uint256[] memory totalAmounts = new uint256[](_totalNumbers);
        
        PersonNumberInfo [] storage pnis = ticketsNumPool[currentNumber][sender].numbers;
        
        for(uint256 index=0; index< _totalNumbers;index++) {
            numbers[index] = pnis[index].number;
            totalAmounts[index] = pnis[index].totalAmount;
        }
        
        return (currentNumber,sender,numbers, totalAmounts);
    }
    
    /*
     * @notice 查询地址购彩记录
     * @param sender        查询地址
     * @return crtNumber    当前期数
     * @return address      查询地址
     * @return string       购买的号码集合
     * @return uint256      购买的金额集合
     */
    function getMyTicket() public view returns(uint256,address,string [] memory,uint256[] memory) {
        return _getTicket(msg.sender);
    }
    
    /**
     * @notice 获取当前彩票总资金池余额
     * @return uint256      当前彩票期数
     * @return uint256      当前期数资金池
     */
    function getPoolTotalAmount() public view returns(uint256,uint256){
        
        uint256 totalAmt = 0;
        address lastAddress;
        for(uint256 index=0; index< historyBuyers[currentNumber].length;index++) {
            
           PersonInfo storage p = ticketsNumPool[currentNumber][historyBuyers[currentNumber][index]];
           if(lastAddress == p.buyer) {
               continue;
           }
           if(p.totalAmount <= 0) {
               break;
           }
           totalAmt += p.totalAmount;
           lastAddress = p.buyer;
        }
        
        return (currentNumber, totalAmt);
        
    }
    
    function _rand() private view returns(uint) {
     return uint(keccak256(
         abi.encodePacked(
         (block.timestamp)
         +(block.difficulty)
         +((uint(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp))
         +(block.gaslimit)
         +((uint(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp))
         +(block.number)
         )
         )) % 100000;
    }
    
    /*
     * 获取中奖信息
     * @param uint256       中奖号码
     */
    function _getLuckyNumbers(string memory currentLucyNumber) external {
        
        address [] memory currentByers = historyBuyers[currentNumber];
        
        for (uint256 index=0; index < currentByers.length; index ++) {
            
            PersonInfo storage personInfo = ticketsNumPool[currentNumber][currentByers[index]];
            
            PersonNumberInfo [] storage numbers = personInfo.numbers;
            
            for(uint256 j=0;j< numbers.length; j++) {
                
                if(keccak256(abi.encode(numbers[j].number))==keccak256(abi.encode(currentLucyNumber))) {
                    // historyLucyers[currentNumber][1][personInfo.buyer] = personInfo.totalAmount;
                    continue;
                }
                
            }
        }
    }
}

interface Token {
    /// 获取账户_owner拥有token的数量
    function balanceOf(address _owner) external returns (uint256 balance);
    //从消息发送者账户中往_to账户转数量为_value的token
    function transfer(address _to, uint256 _value) external returns (bool success);
    //从账户_from中往账户_to转数量为_value的token，与approve方法配合使用
    function transferFrom(address _from, address _to, uint256 _value)external returns  (bool success);
    //消息发送账户设置账户_spender能从发送账户中转出数量为_value的token
    function approve(address _spender, uint256 _value) external returns  (bool success);
    //获取账户_spender可以从账户_owner中转出token的数量
    function allowance(address _owner, address _spender) external returns  (uint256 remaining);
}