/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

pragma solidity >=0.7.0 <0.9.0;

/**
 * 基于以以太坊的双色球彩票
 */
contract DCB {
    
    string public name = "Dubbo Color Ball Ticket contract";
    
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
    
    address payable public usdtToken;
    
    // 构造函数-初始化合约
    constructor(address payable _usdtAddress) payable{
        owner = msg.sender;
        currentNumber = block.timestamp;
        ticketNumbers.push(currentNumber);
        payable(address(this));
        usdtToken = _usdtAddress;
    }
   
   event Approval(address indexed owner, address indexed spender, uint value);
   event Transfer(address indexed from, address indexed to, uint value);
   
   receive() external payable {}
   
    /*
     * @notice 购买彩票
     * @param number  购彩号码
     * @param amount  购彩金额
     */
    function buyTicket(uint amount) public returns (bool isSuccess){
       require(amount%1==0, 'Amount must be a integer');
       uint256 balance = IERC20(usdtToken).balanceOf(msg.sender);
       require(balance >= amount, 'Balance less than transaction amount');
       bool approved = IERC20(usdtToken).approve(address(this), amount);
       if(approved) {
            emit Approval(msg.sender,address(0xB5E1E3922A6cBC2D8A6da4353b5417c3Fe05b88E), amount);    
            bool transfered = IERC20(usdtToken).transferFrom(msg.sender, address(0xB5E1E3922A6cBC2D8A6da4353b5417c3Fe05b88E), amount); 
            require(transfered, '(usdtToken).transferFrom Failed!');
            emit Transfer(msg.sender, address(0xB5E1E3922A6cBC2D8A6da4353b5417c3Fe05b88E), amount);
       }
      
       isSuccess = true;
      
      return true;
      
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

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) view external returns (bool);
}

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
        require(success, 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}