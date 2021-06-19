/**
 *Submitted for verification at Etherscan.io on 2021-06-18
*/

pragma solidity >=0.7.0 <0.9.0;


/**
 * 基于以以太坊的双色球彩票
 */
contract DCB {
    
    string public name = "Dubbo Color Ball Coin Token"; // Set the name for display purposes
    string public symbol = "DCBC";  // Set the symbol for display purposes
    
    uint8 public decimals = 18;
    // 18 decimals is the strongly suggested default, avoid changing it
    
    uint256 public totalSupply;
    
    uint256 initialSupply = 100000000000;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    
    // 结构体-用户下单号码信息
    struct PersonNumberInfo{
        uint256 number;         // 用户选择的彩票号码
        uint256 totalAmount;    // 用户对应彩票号码下注金额
    }
    
    // 结构体-用户信息
    struct PersonInfo{
        address buyer;                  // 用户地址
        uint256 totalAmount;            // 用户总下单金额
        PersonNumberInfo [] numbers;    // 用户下单号码信息
    }
    
    // 购彩号码 =》 购彩地址 =》购彩信息
    mapping(uint256 => mapping(address => PersonInfo)) private _ticketsNumPool;

    // 历史购彩用户地址
    mapping(uint256 => address[]) private _historyBuyers;
    
    // 历史中奖信息 期数=》中奖级别=》中奖地址=》中奖金额
    mapping(uint256=>mapping(uint256=>mapping(address=>uint256))) historyLucyers;
    
    mapping(uint256=> uint256) _historyLuckyNubers;
    
    // 拥有者地址 
    address private owner;
    
    // 彩票期数
    uint256[] private ticketNumbers;
    
    // 彩票当前期数
    uint256 private currentNumber;
    
    // 购彩号码长度
    uint256 private _ticketNumberLength = 11;
    
    uint256[] private _redBalls = new uint256[](10);
    uint256[] private _bluBalls = new uint256[](10);
    
    event Transfer(address from, address to, uint amount);
    event Approval(address owner, address spender, uint amount);
    event Burn(address indexed from, uint256 value);
    
    IERC20 private token;
    
    // 构造函数-初始化合约
    constructor(IERC20 _token) payable{
        token = _token;
        totalSupply = initialSupply * 10 ** uint256(decimals); // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply; // Give the creator all initial tokens
        owner = msg.sender;
        currentNumber = block.timestamp;
        ticketNumbers.push(currentNumber);
        _redBalls[0] = 0;
        _redBalls[1] = 1;
        _redBalls[2] = 2;
        _redBalls[3] = 3;
        _redBalls[4] = 4;
        _redBalls[5] = 5;
        _redBalls[6] = 6;
        _redBalls[7] = 7;
        _redBalls[8] = 8;
        _redBalls[9] = 9;
        _bluBalls[0] = 0;
        _bluBalls[1] = 1;
        _bluBalls[2] = 2;
        _bluBalls[3] = 3;
        _bluBalls[4] = 4;
        _bluBalls[5] = 5;
        _bluBalls[6] = 6;
        _bluBalls[7] = 7;
        _bluBalls[8] = 8;
        _bluBalls[9] = 9;
    }    
    
    function _transfer(address _from, address _to, uint _value) internal {
        
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(_from, _value);
        return true;
    }
    
    function  transferOut(address toAddr, uint amount) external {
        token.transfer(toAddr, amount);
     }

    function  transferIn(address fromAddr, uint amount) external {
        token.transferFrom(msg.sender, fromAddr, amount);
    }
   
    /**
     * @notice 购买彩票
     * @param number  购彩号码
     * @param amount  购彩金额
     */
    function buyTicket(uint number, uint256 amount) public{
      
      require(amount >= 1, "The amount is invalid , min amount is 1");
      require(token.balanceOf(msg.sender) > amount, 'The balance is not enough');
      
      token.transferFrom(msg.sender,address(this), amount);
      
      
      PersonInfo storage p = _ticketsNumPool[currentNumber][msg.sender];
      
      if(p.totalAmount > 0) {
        PersonNumberInfo[] storage numbers = p.numbers;
        bool isContain = false;
        for(uint index = 0;index < numbers.length; index++) {
            PersonNumberInfo storage pni = numbers[index];
            uint256 tmpNumber = pni.number;
            if(number == tmpNumber) {
                pni.totalAmount += amount;
                isContain = true;
                break;
            }
        }
        if(!isContain) {
            PersonNumberInfo memory pni = PersonNumberInfo(number, amount);
            numbers.push(pni);
        }
        p.totalAmount += amount;
        _ticketsNumPool[currentNumber][msg.sender] = p;
    
      } else {
         p.totalAmount += amount;
         p.buyer = msg.sender;
         PersonNumberInfo memory pni = PersonNumberInfo(number, amount);
         p.numbers.push(pni);
         _ticketsNumPool[currentNumber][msg.sender] = p;
      }
      address sender = msg.sender;
      _historyBuyers[currentNumber].push(sender);
      
    }

    /**
     * @notice 查询地址购彩记录
     * @param sender    查询地址
     * @return address  查询地址
     * @return string   购买的号码集合
     * @return uint256  购买的金额集合
     */
    function _getTicket(address sender) private view returns(uint256,address,uint256 [] memory,uint256[] memory) {
        
        uint256 _totalNumbers = _ticketsNumPool[currentNumber][sender].numbers.length;
        
        uint256[] memory numbers = new uint256[](_totalNumbers);
        uint256[] memory totalAmounts = new uint256[](_totalNumbers);
        
        PersonNumberInfo [] storage pnis = _ticketsNumPool[currentNumber][sender].numbers;
        
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
    function getMyTicket() public view returns(uint256,address,uint256 [] memory,uint256[] memory) {
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
        for(uint256 index=0; index< _historyBuyers[currentNumber].length;index++) {
            
           PersonInfo storage p = _ticketsNumPool[currentNumber][_historyBuyers[currentNumber][index]];
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
    
    /*
     * 获取开奖号码
     * @return uint256      彩票期数
     * @return uint256      中奖号码
     */
    function getLuckyNumber() public view returns(uint256 ticketNumber, uint256[] memory luckyNumber) {
        
        //uint256 times = block.timestamp - currentNumber;
        // uint256 interval = 1000 * 60 * 5;
        // uint256 openTimes = currentNumber - interval;
        
        //require(times - openTimes <= 0,'It is not time to open the ticket !');
        
        uint256 [] memory crtLuckyBalls = new uint256[](11);
        uint256 crtRedPostion = 0;
        
        
        while(crtRedPostion <=10) {
            
             uint256 number = _rand(10);
             
             //console.log(number);
             
             uint256 tmpNumber = _redBalls[number];
             bool isExisted = false;
            
             for(uint256 index=0; index < 10; ++index){
                 uint256 ball = crtLuckyBalls[index];
                 if (tmpNumber == ball) {
                     isExisted = true;
                     break;
                 }
                 
             }
             
             if (!isExisted) {
                 crtLuckyBalls[crtRedPostion] = _redBalls[number];
                 crtRedPostion = crtRedPostion + 1;
                 if(crtRedPostion >= 10) {
                     break;
                 }
             }
             
        }
       
        return(currentNumber, crtLuckyBalls);
    }
    
    function _rand(uint256 _length) private view returns(uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
        return uint256(random%_length);
    }
    
    /*
     * 获取中奖信息
     * @param uint256       中奖号码
     */
    function _getLuckyNumbers(uint256 currentLucyNumber) private {
        
        address [] memory currentByers = _historyBuyers[currentNumber];
        
        for (uint256 index=0; index < currentByers.length; index ++) {
            
            PersonInfo storage personInfo = _ticketsNumPool[currentNumber][currentByers[index]];
            
            PersonNumberInfo [] storage numbers = personInfo.numbers;
            
            for(uint256 j=0;j< numbers.length; j++) {
                
                if(numbers[j].number == currentLucyNumber) {
                    historyLucyers[currentNumber][1][personInfo.buyer] = personInfo.totalAmount;
                    continue;
                }
                
            }
        }
    }
}

interface IERC20 {
  function transfer(address recipient, uint256 amount) external;
  function balanceOf(address account) external view returns (uint256);
  function transferFrom(address sender, address recipient, uint256 amount) external ;
  function decimals() external view returns (uint8);
  function approve(address _spender, uint256 _value) external returns (bool success);
}