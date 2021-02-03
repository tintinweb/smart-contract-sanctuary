/**
 *Submitted for verification at Etherscan.io on 2021-01-31
*/

pragma solidity 0.6.12;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

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

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

   function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Ownable {
    address public owner;
    address public newowner;
    address public admin;
    address public dev;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyNewOwner {
        require(msg.sender == newowner);
        _;
    }
    
    function transferOwnership(address _newOwner) public onlyOwner {
        newowner = _newOwner;
    }
    
    function takeOwnership() public onlyNewOwner {
        owner = newowner;
    }    
    
    function setAdmin(address _admin) public onlyOwner {
        admin = _admin;
    }
    
    function setDev(address _dev) public onlyOwner {
        dev = _dev;
    }
    
    modifier onlyAdmin {
        require(msg.sender == admin || msg.sender == owner);
        _;
    }

    modifier onlyDev {
        require(msg.sender == dev || msg.sender == admin || msg.sender == owner);
        _;
    }    
}

abstract contract ContractConn{
    function transfer(address _to, uint _value) virtual public;
    function transferFrom(address _from, address _to, uint _value) virtual public;
    function balanceOf(address who) virtual public view returns (uint);
}


contract PledgeDeposit is Ownable{

    using SafeMath for uint256;
    
    struct PoolInfo {
        ContractConn token;
        string symbol;
    }

    struct DepositInfo {
        uint256 userOrderId;
        uint256 depositAmount;
        uint256 pledgeAmount;
        uint256 depositTime;
        uint256 depositBlock;
        uint256 expireBlock;
    }
    

    ContractConn public zild;

    uint256 public depositBlock = 1;
    uint256 public depositBlockChange;
    uint256 public changeDepositTime;
    bool    public needChangeTime = false;

 
    PoolInfo[] public poolArray;


    // poolId , user address, DepositInfo
    mapping (uint256 => mapping (address => DepositInfo[])) public userDepositMap;

    mapping (address => uint256) public lastUserOrderIdMap;

    uint256 public pledgeBalance;    

    event NewPool(address addr, string symbol);

    event SetDepositBlock(uint256 dblock,address  who,uint256 time);
    event EffectDepositBlock(uint256 dblock,address  who,uint256 time);
    event ZildBurnDeposit(address  userAddress,uint256 userOrderId, uint256 burnAmount);
    event Deposit(address  userAddress,uint256 userOrderId, uint256 poolId,string symbol,uint256 depositId, uint256 depositAmount,uint256 pledgeAmount);
    event Withdraw(address  userAddress,uint256 userOrderId, uint256 poolId,string symbol,uint256 depositId, uint256 depositAmount,uint256 pledgeAmount);
    
    constructor(address _zild,address _usdt) public {
        zild = ContractConn(_zild);

        // poolArray[0] :  ETH 
        addPool(address(0),'ETH');  

        // poolArray[1] : ZILD  
        addPool(_zild,'ZILD');  

        // poolArray[2] : USDT  
        addPool(_usdt,'USDT');    
    }
    

    function addPool(address  _token, string memory _symbol) public onlyAdmin {
        poolArray.push(PoolInfo({token: ContractConn(_token),symbol: _symbol}));
        emit NewPool(_token, _symbol);
    }

    function poolLength() external view returns (uint256) {
        return poolArray.length;
    }

    function setDepositBlock(uint256 _block) public onlyAdmin {
        require(_block > 0,"Desposit: New deposit time must be greater than 0");
        depositBlockChange = _block;
        changeDepositTime = block.number;
        needChangeTime = true;
        emit SetDepositBlock(_block,msg.sender,now);
    }
    
    function effectBlockChange() public onlyAdmin {
        require(needChangeTime,"Deposit: No new deposit time are set");
        uint256 currentTime = block.number;
        uint256 effectTime = changeDepositTime.add(depositBlock);
        if (currentTime < effectTime) return;
        depositBlock = depositBlockChange;
        needChangeTime = false;
        emit SetDepositBlock(depositBlockChange,msg.sender,now);
    }    

    function tokenDepositCount(address _user, uint256 _poolId)  view public returns(uint256) {
        require(_poolId < poolArray.length, "invalid _poolId");
        return userDepositMap[_poolId][_user].length;
    }

    function burnDeposit(uint256 _userOrderId, uint256 _burnAmount) public{
       require(_userOrderId > lastUserOrderIdMap[msg.sender], "_userOrderId should greater than lastUserOrderIdMap[msg.sender]");
       
       lastUserOrderIdMap[msg.sender]  = _userOrderId;
       
       zild.transferFrom(address(msg.sender), address(1024), _burnAmount);       
  
       emit ZildBurnDeposit(msg.sender, _userOrderId, _burnAmount);
    }

    function deposit(uint256 _userOrderId, uint256 _poolId, uint256 _depositAmount,uint256 _pledgeAmount) public payable{
       require(_poolId < poolArray.length, "invalid _poolId");
       require(_userOrderId > lastUserOrderIdMap[msg.sender], "_userOrderId should greater than lastUserOrderIdMap[msg.sender]");
       
       lastUserOrderIdMap[msg.sender]  = _userOrderId;
       PoolInfo storage poolInfo = poolArray[_poolId];

       // ETH
       if(_poolId == 0){
            require(_depositAmount == msg.value, "invald  _depositAmount for ETH");
            zild.transferFrom(address(msg.sender), address(this), _pledgeAmount);
       }
       // ZILD
       else if(_poolId == 1){
            uint256 zildAmount = _pledgeAmount.add(_depositAmount);
            zild.transferFrom(address(msg.sender), address(this), zildAmount);
       }
       else{
            zild.transferFrom(address(msg.sender), address(this), _pledgeAmount);
            poolInfo.token.transferFrom(address(msg.sender), address(this), _depositAmount);
       }

       pledgeBalance = pledgeBalance.add(_pledgeAmount);

       uint256 depositId = userDepositMap[_poolId][msg.sender].length;
       userDepositMap[_poolId][msg.sender].push(
            DepositInfo({
                userOrderId: _userOrderId,
                depositAmount: _depositAmount,
                pledgeAmount: _pledgeAmount,
                depositTime: now,
                depositBlock: block.number,
                expireBlock: block.number.add(depositBlock)
            })
        );
    
        emit Deposit(msg.sender, _userOrderId, _poolId, poolInfo.symbol, depositId, _depositAmount, _pledgeAmount);
    }

    function getUserDepositInfo(address _user, uint256 _poolId,uint256 _depositId) public view returns (
        uint256 _userOrderId, uint256 _depositAmount,uint256 _pledgeAmount,uint256 _depositTime,uint256 _depositBlock,uint256 _expireBlock) {
        require(_poolId < poolArray.length, "invalid _poolId");
        require(_depositId < userDepositMap[_poolId][_user].length, "invalid _depositId");

        DepositInfo memory depositInfo = userDepositMap[_poolId][_user][_depositId];
        
        _userOrderId = depositInfo.userOrderId;
        _depositAmount = depositInfo.depositAmount;
        _pledgeAmount = depositInfo.pledgeAmount;
        _depositTime = depositInfo.depositTime;
        _depositBlock = depositInfo.depositBlock;
        _expireBlock = depositInfo.expireBlock;
    }

    function withdraw(uint256 _poolId,uint256 _depositId) public {
        require(_poolId < poolArray.length, "invalid _poolId");
        require(_depositId < userDepositMap[_poolId][msg.sender].length, "invalid _depositId");

        PoolInfo storage poolInfo = poolArray[_poolId];
        DepositInfo storage depositInfo = userDepositMap[_poolId][msg.sender][_depositId];

        require(block.number > depositInfo.expireBlock, "The withdrawal block has not arrived");
        uint256 depositAmount =  depositInfo.depositAmount;
        require( depositAmount > 0, "There is no deposit available!");

        uint256 pledgeAmount = depositInfo.pledgeAmount;

        // ETH
        if(_poolId == 0) {
            msg.sender.transfer(depositAmount);
            zild.transfer(msg.sender,pledgeAmount);
        }
        // ZILD
        else if(_poolId == 1){
            zild.transfer(msg.sender, depositAmount.add(pledgeAmount));
        }
        else{
            poolInfo.token.transfer(msg.sender, depositAmount);
            zild.transfer(msg.sender,pledgeAmount);
        }   

        pledgeBalance = pledgeBalance.sub(pledgeAmount);
        depositInfo.depositAmount =  0;    
        depositInfo.pledgeAmount = 0;

        emit Withdraw(msg.sender, depositInfo.userOrderId, _poolId, poolInfo.symbol, _depositId, depositAmount, pledgeAmount);
      }
}