/**
 *Submitted for verification at BscScan.com on 2021-12-03
*/

pragma solidity 0.5.4;

library SafeMath {
	/**
	 * @dev Returns the addition of two unsigned integers, reverting on
	 * overflow.
	 *
	 * Counterpart to Solidity's `+` operator.
	 *
	 * Requirements:
	 *
	 * - Addition cannot overflow.
	 */
	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		require(c >= a, "SafeMath: addition overflow");
		return c;
	}

	/**
	 * @dev Returns the subtraction of two unsigned integers, reverting on
	 * overflow (when the result is negative).
	 *
	 * Counterpart to Solidity's `-` operator.
	 *
	 * Requirements:
	 *
	 * - Subtraction cannot overflow.
	 */
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		return sub(a, b, "SafeMath: subtraction overflow");
	}

	/**
	 * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
	 * overflow (when the result is negative).
	 *
	 * Counterpart to Solidity's `-` operator.
	 *
	 * Requirements:
	 *
	 * - Subtraction cannot overflow.
	 */
	function sub(
		uint256 a,
		uint256 b,
		string memory errorMessage
	) internal pure returns (uint256) {
		require(b <= a, errorMessage);
		uint256 c = a - b;
		return c;
	}

	/**
	 * @dev Returns the multiplication of two unsigned integers, reverting on
	 * overflow.
	 *
	 * Counterpart to Solidity's `*` operator.
	 *
	 * Requirements:
	 *
	 * - Multiplication cannot overflow.
	 */
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		// Gas optimization: this is cheaper than requiring 'a' not being zero, but the
		// benefit is lost if 'b' is also tested.
		// See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
		if (a == 0) {
			return 0;
		}

		uint256 c = a * b;
		require(c / a == b, "SafeMath: multiplication overflow");
		return c;
	}

	/**
	 * @dev Returns the integer division of two unsigned integers. Reverts on
	 * division by zero. The result is rounded towards zero.
	 *
	 * Counterpart to Solidity's `/` operator. Note: this function uses a
	 * `revert` opcode (which leaves remaining gas untouched) while Solidity
	 * uses an invalid opcode to revert (consuming all remaining gas).
	 *
	 * Requirements:
	 *
	 * - The divisor cannot be zero.
	 */
	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		return div(a, b, "SafeMath: division by zero");
	}

	/**
	 * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
	 * division by zero. The result is rounded towards zero.
	 *
	 * Counterpart to Solidity's `/` operator. Note: this function uses a
	 * `revert` opcode (which leaves remaining gas untouched) while Solidity
	 * uses an invalid opcode to revert (consuming all remaining gas).
	 *
	 * Requirements:
	 *
	 * - The divisor cannot be zero.
	 */
	function div(
		uint256 a,
		uint256 b,
		string memory errorMessage
	) internal pure returns (uint256) {
		require(b > 0, errorMessage);
		uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn't hold

		return c;
	}

	/**
	 * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
	 * Reverts when dividing by zero.
	 *
	 * Counterpart to Solidity's `%` operator. This function uses a `revert`
	 * opcode (which leaves remaining gas untouched) while Solidity uses an
	 * invalid opcode to revert (consuming all remaining gas).
	 *
	 * Requirements:
	 *
	 * - The divisor cannot be zero.
	 */
	function mod(uint256 a, uint256 b) internal pure returns (uint256) {
		return mod(a, b, "SafeMath: modulo by zero");
	}

	/**
	 * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
	 * Reverts with custom message when dividing by zero.
	 *
	 * Counterpart to Solidity's `%` operator. This function uses a `revert`
	 * opcode (which leaves remaining gas untouched) while Solidity uses an
	 * invalid opcode to revert (consuming all remaining gas).
	 *
	 * Requirements:
	 *
	 * - The divisor cannot be zero.
	 */
	function mod(
		uint256 a,
		uint256 b,
		string memory errorMessage
	) internal pure returns (uint256) {
		require(b != 0, errorMessage);
		return a % b;
	}
}


// import "./ERC20.sol";
// import "./ERC20Detailed.sol";
// contract token { function transfer(address receiver, uint amount){ receiver; amount; } } //transfer方法的接口说明
interface Token {
    // 普通转账(禁止冻结账号交易))
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address owner) external view returns (uint256);
    // function approve(address spender, uint256 amount) external returns (bool);
}


contract Game {
    //定义用户
    struct User {
        address upline;
        // uint256 level;
        bool used;
        uint256 hasUseNum;
    }
    
    struct DAO{
        uint8 status;
    }
    
    using SafeMath for uint256;
    
    //定义奖池
    uint256 pool_bouns;

    address payable private owner;
    mapping(address => User) private users;
    mapping(address => DAO) private daos;
    uint256 private daosLen;
    uint256 userNum;
    // address payable []  userslist;
    // address[] Daos;
    
    Token private token;
    address mainaddress;
    
    
    event newUserRegister(address indexed _from, address  _upline);
    event newDAO(address indexed _from);
    event newGame(address indexed _from, uint256 number,uint256 result,uint256 amount);
    
    //创建合约  
    constructor(address payable _owner,address mainaddr_) public {
        daosLen=0;
        owner=_owner;
        // users[_owner].level=1;
        users[_owner].hasUseNum=0;
        users[_owner].used=true;
        // userslist.push(_owner);
        pool_bouns=0;
        userNum=1;
        mainaddress=mainaddr_;
        token = Token(0x232196191b757E55AB0C1827e81359144de058a3);    
    }
    
    //会员注册 
    function registration(address payable _upline) payable public{
        // require(msg.value>0, "Bad deposit");
        // _initUser(msg.sender,_upline);
        // require(users[_upline].level>0,'upline not exsit');
        // require(msg.sender!=_upline,'upline can not be yourself');
        require(msg.sender!=_upline,'upline can not be yourself');
        require(!users[msg.sender].used,'upline not exsit');
        // address contract_address=address(this);
        // if(users[msg.sender].level!=1){
            users[msg.sender].upline=_upline;
            users[msg.sender].hasUseNum=0;  
            // users[msg.sender].level==1;
            users[msg.sender].used=true;
            emit newUserRegister(msg.sender,_upline);
            // token.approve(contract_address,uint256(-1));
            userNum++;    
        // }
        
        // return true;
    }
    
    // function _initUser(address  _addr,address payable _upline)  internal {
    //     require(users[_upline].level>=0,'upline not exsit');
    //     require(_addr!=_upline,'upline can not be yourself');
    //     users[_addr].upline=_upline;
    //     users[_addr].hasUseNum=0;  
    //     users[_addr].level==0;
    //     // emit newUserRegister(_addr, users[_addr].upline);
    // }
    
    //开始游戏 
    // function Bet() internal{
    //     require(msg.value!=1,'bet number must is 1 USDT');
        
    // }
    
    function Bet(uint256 amount,uint256[] memory betNums ) payable public {
    //检测买了几个号码 
    uint256 betNum=betNums.length;
    
    //转入代币 
    address contract_address=address(this);
      require(amount<1* (10 ** 8),'bet number must is 1 USDT'); 
    //   token.balanceOf(msg.sender).mod(1)
      require(amount.mod(1* (10 ** 8))!=0,'bet number must is int'); 
      require(amount>100* (10 ** 8),'bet number must is 100 USDT'); 
       //11%转入专门有帐户 
      token.transferFrom(msg.sender,mainaddress,amount.mul(15).div(100));
       //其余转入奖池 
      token.transferFrom(msg.sender,contract_address,amount.mul(85).div(100));
   
      startGame(betNums, amount.div(betNum),betNum);
      users[msg.sender].hasUseNum+=amount;
    }
    
    
    function airdrop() private view returns(uint256){
            uint256 seed = uint256(keccak256(abi.encodePacked(
            (block.timestamp).add
            (block.difficulty).add
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)).add
            (block.gaslimit).add
            ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (now)).add
            (block.number))));
            return seed%12;
        // if((seed - ((seed / 1000) * 1000)) < airDropTracker_)
        //     return(true);
        // else
        //     return(false);

    }


    function startGame(uint256[] memory betNums,uint256 amount,uint256 betNum)  private {
        uint256 result=airdrop();
        for(uint8 i=0;i<betNum;i++){
            if(betNums[i]==result){
              token.transfer(msg.sender,amount.div(10));  
            }
        }
        // emit newGame(msg.sender,betNums,result,amount);
        // uint256 result=1;
        // return result;
    }
    
    function startGame2(uint8 number,uint256 amount)  private {
        require(number>=0 && number<12,'bet number must is big 1 '); 
        require(number%1==0,'bet number must is big 1 '); 
        uint256 result=airdrop();
        if(number==result){
            token.transfer(msg.sender,amount.div(10));
        }
        emit newGame(msg.sender,number,result,amount);
        users[msg.sender].hasUseNum+=amount;
        // uint256 result=1;
        // return result;
    }
    
    
    function addDAO(uint256 amount) payable public{
    //   require(amount==1000* (10 ** 8),'bet number must is 1000 USDT');
    //   require(Daos.length<=10000,'number must 10000');
      
    //   Daos.push(msg.sender);
      require(amount==1000* (10 ** 8),'bet number must is 1000 USDT');
      require(daosLen<10000,'number must 10000');
    // require(amount==1,'bet number must is 1000 USDT');
    //   require(daosLen<3,'number must 10000');
      address contract_address=address(this);
      token.transferFrom(msg.sender,contract_address,amount);
      require(daos[msg.sender].status<1,'has add DAO');
      daos[msg.sender].status=1;
      daosLen++;
      emit newDAO(msg.sender);
    }
    
    
    //获取奖池金额 
    function getJackpot() public view returns(uint) {
       return pool_bouns;
    }
    
    
    function getBalance_token(address addr_) public view returns(uint) {
       return token.balanceOf(addr_);
    }
    
    //给奖池充奖励
    function addJackpot(uint256 amount) payable public{
        address contract_address=address(this);
        token.transferFrom(msg.sender,contract_address,amount);
    }
    
    //从奖池提现 
    function getFromJackpot(uint256 amount) public{
        require(msg.sender == owner);
        token.transfer(owner,amount);
    }
    
    //获取用户数量 
     function getUserNum() public view returns(uint256){
        return userNum;
    }
    
    //获取会员的等级 
    // function getLevel() public view returns(uint256){
    //     return users[msg.sender].level;
    // }
    
    //检查账号是否为股东
    function getDaoStatus() public view returns(uint256){
        return daos[msg.sender].status;
    }
    
    //检查账号是否注册 
    function checkUserReg() public view returns(bool){
        return users[msg.sender].used;
    }
    
    //获取用户的参与流水 
      function getUserHasUsedNum() public view returns(uint256){
        return users[msg.sender].hasUseNum;
    }
    
    
    
    
    
    // function addDAO_test(uint256 amount) payable public{
    //   require(amount==1000* (10 ** 8),'bet number must is 1000 USDT');
    // //   require(Daos.length<=10000,'number must 10000');
    // //   address contract_address=address(this);
    // //   token.transferFrom(msg.sender,contract_address,amount);
    //   require(daos[msg.sender].status<1,'has add DAO');
    //   daos[msg.sender].status=1;
    //   daosLen++;
      
    // }
    
    // function getDaoslen() public view returns (uint256){
    //     return Daos.length;
    // }
    
    // function getBalance() public view return (uint256){
    //     return 0;
    //     // return token.balanceOf(msg.sender);
    // }
    
}