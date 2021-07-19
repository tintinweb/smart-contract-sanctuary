//SourceUnit: rel.sol

pragma solidity ^0.5.8;

interface IRewardPool{
    function waitClearn(address _account) external view returns(uint256);
    function totalInviteReward(address _account) external view returns(uint256);
}

library SafeMath {

  /**
   * @dev Multiplies two unsigned integers, reverts on overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath#mul: OVERFLOW");

    return c;
  }

  /**
   * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath#div: DIVISION_BY_ZERO");
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
}

  /**
   * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath#sub: UNDERFLOW");
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Adds two unsigned integers, reverts on overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath#add: OVERFLOW");

    return c;
  }

  /**
   * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
   * reverts when dividing by zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath#mod: DIVISION_BY_ZERO");
    return a % b;
  }

}

interface TRC20 {
  
  function totalSupply() external view returns (uint256);

  
  function balanceOf(address owner) external view returns (uint256);

  
}

contract rel{
    using SafeMath for *;
    address public owner;
    uint256 public PID;
    mapping(address => address) public plyParent;
    mapping(address => uint256) public plyBalance;
    mapping(address => uint256) public plyId;
    
    mapping(address => bool) public rewardPoolAddr;
    address[] public rewardList;
    
    constructor() public{
        owner = msg.sender;
    }
    
    function addRewardPool(address _poolAddr) public{
        require(msg.sender == owner,"only owner");
        require(!rewardPoolAddr[_poolAddr],"already exit");
        rewardPoolAddr[_poolAddr] = true;
        rewardList.push(_poolAddr);
    }
    
    function delRewardPool(address _poolAddr) public{
        require(msg.sender == owner,"only owner");
        rewardPoolAddr[_poolAddr] = false;
        uint256 len = rewardList.length;
        for(uint256 i=0;i<len;i++){
            if(rewardList[i] == _poolAddr){
                delete rewardList[i];
                rewardList.length--;
                return;
            }
        }
    }
    
    function stakeR(address _ply,uint256 _amount,address _plyParent) public onlyRewardePool{
        
        if(plyBalance[_plyParent] > 0){
            if(plyParent[_ply] == address(0) &&  _ply != _plyParent){
                plyParent[_ply] = _plyParent;
            }
        }
        plyBalance[_ply] = plyBalance[_ply]+_amount;
        
        if(plyId[_ply] == 0){
            PID++;
            plyId[_ply] = PID;
        }
    }
    
    function withdrawR(address _ply,uint256 _amount) public onlyRewardePool{
        require(plyBalance[_ply]>=_amount,"must big then _amount");
        plyBalance[_ply] = plyBalance[_ply] - _amount;
    }
    
    function checkParent(address _ply) public view returns(bool,address){
        address parent = plyParent[_ply];
        if(parent == address(0)){
            return(false,parent);
        }
        if(plyBalance[parent] > 0){
            return(true,parent);
        }
        return(false,parent);
    }
    
    function getPlyTotalInfo(address _account) public view returns(uint256 _totalInvite,uint256 _totalPIW){
        uint256 len = rewardList.length;
        
        for(uint256 i=0;i<len;i++){
            _totalInvite += IRewardPool(rewardList[i]).totalInviteReward(_account);
            _totalPIW += IRewardPool(rewardList[i]).waitClearn(_account);
        }
    }
    
    modifier onlyRewardePool(){
        require(rewardPoolAddr[msg.sender],"only reward pool addr");
        _;
    }
    
}