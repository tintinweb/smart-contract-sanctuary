/**
 *Submitted for verification at Etherscan.io on 2021-06-21
*/

pragma solidity >=0.7.0 <0.9.0;

interface tokenRecipient {function receiveApproval(address _from, uint256 _value, address _token, bytes memory _extraData) external;}

/**
 * 基于以以太坊的双色球彩票
 */
contract DCB {
    
    string public name = "Dubbo Color Ball Coin Token";
    
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
    mapping(uint256 => mapping(address => PersonInfo)) private _ticketsNumPool;

    // 历史购彩用户地址
    mapping(uint256 => address[]) private _historyBuyers;
    
    // 历史中奖信息 期数=》中奖级别=》中奖地址=》中奖金额
    mapping(uint256=>mapping(uint256=>mapping(address=>uint256))) historyLucyers;
    
    mapping(uint256=> uint) _historyLuckyNubers;
    
    // 拥有者地址 
    address private owner;
    
    // 彩票期数
    uint256[] private ticketNumbers;
    
    // 彩票当前期数
    uint256 private currentNumber;
    
    // 购彩号码长度
    uint256 private _ticketNumberLength = 11;
    
    string[] private _balls = new string[](9);
  
    // 构造函数-初始化合约
    constructor() payable{
        owner = msg.sender;
        currentNumber = block.timestamp;
        ticketNumbers.push(currentNumber);
        _balls[0] = '1';
        _balls[1] = '2';
        _balls[2] = '3';
        _balls[3] = '4';
        _balls[4] = '5';
        _balls[5] = '6';
        _balls[6] = '7';
        _balls[7] = '8';
        _balls[8] = '9';
        
        payable(address(this));
        // TokenCreator creator = new TokenCreator();
        // ownedToken = creator.createToken('Dubbo Color ball Coin','DCBC', 100000000 * 10 ** uint256(_decimals));
    }    
   
    /*
     * @notice 购买彩票
     * @param number  购彩号码
     * @param amount  购彩金额
     */
    function buyTicket(uint256 amount, uint [] memory _numbers) public{
      
    //   require(ownedToken.balanceOf(msg.sender) >= amount,"Insufficient balance!");
    //   require(number.length == 11,'the thickt number is invalid!');
    //   ownedToken.approve(address(this), amount);
    //   ownedToken.transferFrom(msg.sender,address(this), amount);
      
      PersonInfo storage p = _ticketsNumPool[currentNumber][msg.sender];
      string memory number = '';
      for(uint i=0;i< _numbers.length;i++) {
          number = new string(_numbers[i]);
      }
      
      if(p.totalAmount > 0) {
        PersonNumberInfo[] storage numbers = p.numbers;
        bool isContain = false;
        for(uint index = 0;index < numbers.length; index++) {
            PersonNumberInfo storage pni = numbers[index];
            string memory tmpNumber = pni.number;
            if(keccak256(abi.encode(number))==keccak256(abi.encode(tmpNumber))) {
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
    function _getTicket(address sender) private view returns(uint256,address,string [] memory,uint256[] memory) {
        
        uint256 _totalNumbers = _ticketsNumPool[currentNumber][sender].numbers.length;
        
        string[] memory numbers = new string[](_totalNumbers);
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
    function getLuckyNumber() public view returns(uint256 ticketNumber, string[] memory luckyNumber) {
        
        //uint256 times = block.timestamp - currentNumber;
        // uint256 interval = 1000 * 60 * 5;
        // uint256 openTimes = currentNumber - interval;
        
        //require(times - openTimes <= 0,'It is not time to open the ticket !');
        
        string [] memory crtLuckyBalls;
        crtLuckyBalls[0] = (_balls[_rand()]);  
        crtLuckyBalls[1] = (_balls[_rand()]);  
        crtLuckyBalls[2] = (_balls[_rand()]);  
        crtLuckyBalls[3] = (_balls[_rand()]);  
        crtLuckyBalls[4] = (_balls[_rand()]);  
        crtLuckyBalls[5] = (_balls[_rand()]);  
        crtLuckyBalls[6] = (_balls[_rand()]);  
        crtLuckyBalls[7] = (_balls[_rand()]);  
        crtLuckyBalls[8] = (_balls[_rand()]);  
       
        return(currentNumber, crtLuckyBalls);
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
        
        address [] memory currentByers = _historyBuyers[currentNumber];
        
        for (uint256 index=0; index < currentByers.length; index ++) {
            
            PersonInfo storage personInfo = _ticketsNumPool[currentNumber][currentByers[index]];
            
            PersonNumberInfo [] storage numbers = personInfo.numbers;
            
            for(uint256 j=0;j< numbers.length; j++) {
                
                if(keccak256(abi.encode(numbers[j].number))==keccak256(abi.encode(currentLucyNumber))) {
                    historyLucyers[currentNumber][1][personInfo.buyer] = personInfo.totalAmount;
                    continue;
                }
                
            }
        }
    }
}

contract OwnedToken {
    
    TokenCreator creator;
    
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;
    
    address owner;
    bytes32 public name;
    uint8 public decimals = 8;
    string public symbol;
    uint256 public totalSupply;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    
    constructor(bytes32 _name, string memory _symbol, uint256 _totalSupply) {
        owner = msg.sender;
        creator = TokenCreator(msg.sender);
        name = _name;
        totalSupply = _totalSupply;
        symbol = _symbol;
    }

    function changeName(bytes32 newName) public {
        if (msg.sender == address(creator))
            name = newName;
    }

    function transfer(address newOwner) public {
        if (msg.sender != owner) return;
        if (creator.isTokenTransferOK(owner, newOwner))
            owner = newOwner;
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

    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
            return true;
        }
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
    
}


contract TokenCreator {
    function createToken(bytes32 _name,string memory _symbol, uint256 _totalSupply) public returns (OwnedToken tokenAddress) {
        return new OwnedToken(_name, _symbol,_totalSupply);
    }

    function changeName(OwnedToken tokenAddress, bytes32 name) public {
        tokenAddress.changeName(name);
    }

    function isTokenTransferOK(address currentOwner, address newOwner) public pure returns (bool ok) {
        return keccak256(abi.encodePacked(currentOwner, newOwner))[0] == 0x7f;
    }
}

contract Console {
    event LogUint(string, uint);
    function log(string memory s , uint x) internal {
        emit LogUint(s, x);
    }
    
    event LogInt(string, int);
    function log(string memory s , int x) internal {
        emit LogInt(s, x);
    }
    
    event LogBytes(string, bytes);
    function log(string memory s , bytes memory x) internal {
        emit LogBytes(s, x);
    }
    
    event LogBytes32(string, bytes32);
    function log(string memory s , bytes32 x) internal {
        emit LogBytes32(s, x);
    }

    event LogAddress(string, address);
    function log(string memory s , address x) internal {
        emit LogAddress(s, x);
    }

    event LogBool(string, bool);
    function log(string memory s , bool x) internal {
        emit LogBool(s, x);
    }
}