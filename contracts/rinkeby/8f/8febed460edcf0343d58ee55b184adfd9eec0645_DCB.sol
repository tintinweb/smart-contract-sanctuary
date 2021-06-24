/**
 *Submitted for verification at Etherscan.io on 2021-06-24
*/

pragma solidity >=0.7.0 <0.9.0;

interface tokenRecipient {function receiveApproval(address _from, uint256 _value, address _token, bytes memory _extraData) external;}

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
    
    OwnedToken ownedToken;
    
    // 构造函数-初始化合约
    constructor() payable{
        owner = msg.sender;
        currentNumber = block.timestamp;
        ticketNumbers.push(currentNumber);
        ownedToken = new OwnedToken('Dubbo Color ball Coin','DCBC', 100000000 * 10 ** uint256(18), 18);
    }    
    
    receive() external payable{}
    
    function balanceOfToken(address _address) public view returns(uint256 balance) {
        return ownedToken.balanceOf(_address);
    }
    
    /*
     * @notice 购买彩票
     * @param number  购彩号码
     * @param amount  购彩金额
     */
    function buyTicket(address _token, uint256 _amount, string memory _number) public{
      
      require(_amount % 1 == 0, 'Amount must be a integer');
      require(ownedToken.balanceOf(msg.sender) >= _amount,"Insufficient balance!");
      
      TransferHelper.safeTransferFrom(_token, msg.sender, address(this), _amount);
      
      PersonInfo storage p = ticketsNumPool[currentNumber][msg.sender];
      
      if(p.totalAmount > 0) {
        PersonNumberInfo[] storage numbers = p.numbers;
        bool isContain = false;
        for(uint index = 0;index < numbers.length; index++) {
            PersonNumberInfo storage pni = numbers[index];
            string memory tmpNumber = pni.number;
            if(keccak256(abi.encode(_number)) == keccak256(abi.encode(tmpNumber))) {
                pni.totalAmount += _amount;
                isContain = true;
                break;
            }
        }
        
        if(!isContain) {
            PersonNumberInfo memory pni = PersonNumberInfo(_number, _amount);
            numbers.push(pni);
        }
        
        p.totalAmount += _amount;
        ticketsNumPool[currentNumber][msg.sender] = p;
    
      } else {
         p.totalAmount += _amount;
         p.buyer = msg.sender;
         PersonNumberInfo memory pni = PersonNumberInfo(_number, _amount);
         p.numbers.push(pni);
         ticketsNumPool[currentNumber][msg.sender] = p;
      }
      
      address sender = msg.sender;
      historyBuyers[currentNumber].push(sender);
      
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
    
    /*
     * 获取开奖号码
     * @return uint256      彩票期数
     * @return uint256      中奖号码
     */
    function getLuckyNumber() public {
        
        
    }
}



contract OwnedToken {
    
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;
    
    address owner;
    bytes32 public name;
    uint public decimals;
    string public symbol;
    uint256 public totalSupply;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    
    constructor(bytes32 _name, string memory _symbol, uint _totalSupply,uint _decimals) {
        owner = msg.sender;
        name = _name;
        totalSupply = _totalSupply;
        symbol = _symbol;
        decimals = _decimals;
    }

    function changeName(bytes32 newName) public {
        if (msg.sender == owner)
            name = newName;
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

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}