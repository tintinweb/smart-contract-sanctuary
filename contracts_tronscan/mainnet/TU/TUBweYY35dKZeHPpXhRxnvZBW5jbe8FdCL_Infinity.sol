//SourceUnit: Infinity.sol


pragma solidity ^0.5.14;

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

contract Infinity{
    
    using SafeMath for uint256;
    
    address private _owner;
    address private _rewardDistributor;
    bool private _paused = false;
    
    uint256 public regFee = 5000000;
    uint256 public buyFee = 5000000;
    uint256 public withdrawFee = 9e6;
    uint256 public withdrawLimit = 100e6;
    
    uint256[] private planOne = [25,50,100,200,400,800,1600,3200,6400,12500,25000,50000];
    uint256[] private planTwo = [100,200,400,800,1600,3200,6400,12500,25000,50000];
    uint256[] private planThree = [100,200,400,800,1600,3200,6400,12500];
    
    struct userUnilevelData{
        // Plan One
        uint256 rewardAmount;
        address upline;
        bool status;
    }
    
    struct planTwoAndThreeStore {
        // Plan two and three
        uint256 depositAmount;
        mapping (uint256 => bool) boxStatus;
    }
    
    struct rewardStore {
        uint256 planTwoAndThreeRewards;
        uint256 updatetime;
        uint256 expirytime;
    }
    
    mapping (address => mapping (uint256 => userUnilevelData)) private userInfo;
    mapping (address => mapping (uint256 => planTwoAndThreeStore)) private userTwoAndThreeInfo;
    mapping (address => rewardStore) private rewardInfo;
    
    event _reg(address indexed _user,address indexed _ref,uint256 _box,uint256 _amount,uint256 _time);
    event _buyAllPlan(address indexed _user,address indexed _ref,uint256[3] _box,uint256 _amount,uint256 _time);
    event _buyPlan(string _plan,address indexed _user,uint256 _box,uint256 _amount,uint256 _time);
    event _planOneReward(address indexed _user,address indexed _ref,uint256 _amount,uint256 _box,uint256 _time);
    event _ownerShipTransferred(address indexed _previousOwner, address indexed _newOwner);
    event _distributorTransferred(address indexed _newDistributor,uint256 _time);
    event _rewardUpdate(address indexed _user,uint256 _planReward,uint256 _time);
    event _rewardWithdraw(address indexed _user,uint256 _rewards,uint256 _time);
    event _rewardDistributorFee(address indexed _user,uint256 _amount);
    event _failSafe(address indexed _addr,uint256 _amount,uint256 _time);
    event _pause(bool _status,uint256 _time);
    event _unpause(bool _status,uint256 _time);
    
    constructor(address _ownerAddr,address _rewardDistributorAddr) public{
        _owner = _ownerAddr;
        _rewardDistributor = _rewardDistributorAddr;
        
        for(uint i=0; i < planOne.length; i++){
            userInfo[_owner][i].status = true;
            
             if(i==2 || i==3) userTwoAndThreeInfo[_owner][i].depositAmount = 100e6;
        }
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    modifier onlyRewardsDistribution() {
        require(msg.sender == _rewardDistributor, "Caller is not RewardsDistributor");
        _;
    }
    
    modifier whenNotPaused() {
        require(!_paused);
        _;
    }
    
    modifier whenPaused() {
        require(_paused);
        _;
    }
    
    function setFee(uint256 _regFee,uint256 _buyFee) public onlyOwner {
        regFee = _regFee;
        buyFee = _buyFee;
    }
    
    function withdrawFeeUpdate(uint256 _withdrawLimit,uint256 _withdrawFee) public onlyOwner {
        withdrawLimit = _withdrawLimit;
        withdrawFee = _withdrawFee;
    }
    
    function priceUpdate(uint[] memory _planOne,uint[] memory _planTwo,uint[] memory _planThree) public onlyOwner {
        planOne = _planOne;
        planTwo = _planTwo;
        planThree = _planThree;
        
        for(uint i=0; i < planOne.length; i++){
            userInfo[_owner][i].status = true;
        }
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Ownable: new owner is the zero address");
        emit _ownerShipTransferred(_owner, _newOwner);
        _owner = _newOwner;
    }
    
    function rewardDistributorUpdate(address _newDistributor) public onlyOwner {
        require(_newDistributor != address(0), "Ownable: new distributor is the zero address"); 
        emit _distributorTransferred(_newDistributor, block.timestamp);
        _rewardDistributor = _newDistributor;
    }

    function pause() public onlyOwner whenNotPaused {
        _paused = true;
        emit _pause(true,block.timestamp);
    }

    function unpause() public onlyOwner whenPaused {
        _paused = false;
        emit _unpause(false,block.timestamp);
    }
    
    function buyPlanOne(address _uniRef,uint256 _box) public whenNotPaused payable{
        require(_box <= planOne.length - 1, "plan id is invalid");
        require(msg.value == (planOne[_box] * 1e6).add(buyFee), "Amount is invalid");
        require(userInfo[_uniRef][_box].status, "Referrer address is invalid");
        require((userInfo[msg.sender][_box - 1].status) && !(userInfo[msg.sender][_box].status) , "Buy previous plan");
        
        userInfo[msg.sender][_box].upline = _uniRef;
        userInfo[msg.sender][_box].status = true;
        
        emit _buyPlan("One",msg.sender,_box,msg.value,block.timestamp);
        
        planOneReward(msg.sender,_uniRef,(planOne[_box] * 1e6),_box);  
    }
    
    function buyPlanTwo(uint256 _box) public whenNotPaused payable{
        require(_box <= planTwo.length - 1, "plan id is invalid");
        require(msg.value == (planTwo[_box] * 1e6).add(buyFee), "Amount is invalid");
        require((userTwoAndThreeInfo[msg.sender][2].boxStatus[_box - 1]) && !(userTwoAndThreeInfo[msg.sender][2].boxStatus[_box]), "Buy previous plan");
        
        userTwoAndThreeInfo[msg.sender][2].boxStatus[_box] = true;
        userTwoAndThreeInfo[msg.sender][2].depositAmount += planTwo[_box] * 1e6;
        
        emit _buyPlan("Two",msg.sender,_box,msg.value,block.timestamp);
    }
    
    function buyPlanThree(uint256 _box) public whenNotPaused payable{
        require(_box <= planThree.length - 1, "plan id is invalid");
        require(msg.value == (planThree[_box] * 1e6).add(buyFee), "Amount is invalid");
        require((userTwoAndThreeInfo[msg.sender][3].boxStatus[_box - 1] && !(userTwoAndThreeInfo[msg.sender][3].boxStatus[_box])), "Buy previous plan");
        
        userTwoAndThreeInfo[msg.sender][3].boxStatus[_box] = true;
        userTwoAndThreeInfo[msg.sender][3].depositAmount += planThree[_box] * 1e6;
        
        emit _buyPlan("Three",msg.sender,_box,msg.value,block.timestamp);
    } 
    
    function regUser(address _uniRef,uint256 _box) public whenNotPaused payable {
        require(_box == 0, "plan id is invalid");
        require(msg.value == (((planOne[_box] + planTwo[_box] + planThree[_box]) * 1e6).add(regFee)), "Amount is invalid");
        require(userInfo[_uniRef][_box].status, "Referrer address is invalid");
        require(!(userInfo[msg.sender][_box].status) && !(userTwoAndThreeInfo[msg.sender][2].boxStatus[_box]) && !(userTwoAndThreeInfo[msg.sender][3].boxStatus[_box]), "Already exists in this plan");
        
        
        userInfo[msg.sender][_box].upline = _uniRef;
        userInfo[msg.sender][_box].status = true;
        userTwoAndThreeInfo[msg.sender][2].depositAmount += planOne[_box] * 1e6;
        userTwoAndThreeInfo[msg.sender][3].depositAmount += planTwo[_box] * 1e6;
        userTwoAndThreeInfo[msg.sender][2].boxStatus[_box] = true;
        userTwoAndThreeInfo[msg.sender][3].boxStatus[_box] = true;
        
        emit _reg(msg.sender,_uniRef,_box,msg.value,block.timestamp);
        
        planOneReward(msg.sender,_uniRef,planOne[_box] * 1e6,_box);
    }
    
    function buyAllPlan(address _uniRef,uint256[3] memory _box) public whenNotPaused payable {
        require(_box[0] != 0 && _box[0] <=  planOne.length - 1, "plan id is invalid");
        require(_box[1] != 0 && _box[1] <=  planTwo.length - 1, "plan id is invalid");
        require(_box[2] != 0 && _box[2] <=  planThree.length - 1, "plan id is invalid");
        (uint256 _planOne,uint256 _planTwo,uint256 _planThree) = (planOne[_box[0]] * 1e6,planTwo[_box[1]]  * 1e6 , planThree[_box[2]] * 1e6 );
        require(msg.value == (_planOne + _planTwo + _planThree).add(regFee), "Amount is invalid");
        require(userInfo[_uniRef][_box[0]].status && !(userInfo[msg.sender][_box[0]].status) && (userInfo[msg.sender][_box[0] - 1].status) , "plan one error");
        require(!(userTwoAndThreeInfo[msg.sender][2].boxStatus[_box[1]]) && (userTwoAndThreeInfo[msg.sender][2].boxStatus[_box[1] - 1]) , "plan two error");
        require( !(userTwoAndThreeInfo[msg.sender][3].boxStatus[_box[2]]) && (userTwoAndThreeInfo[msg.sender][3].boxStatus[_box[2] - 1]) , "plan three error");
        
        userInfo[msg.sender][_box[0]].upline = _uniRef;
        userInfo[msg.sender][_box[0]].status = true;
        userTwoAndThreeInfo[msg.sender][2].depositAmount += _planTwo;
        userTwoAndThreeInfo[msg.sender][3].depositAmount += _planThree;
        userTwoAndThreeInfo[msg.sender][2].boxStatus[_box[1]] = true;
        userTwoAndThreeInfo[msg.sender][3].boxStatus[_box[2]] = true;
        
        emit _buyAllPlan(msg.sender,_uniRef,_box,msg.value,block.timestamp);
        
        planOneReward(msg.sender,_uniRef,_planOne,_box[0]);
        
    }
    
    function planOneReward(address _user,address _ref,uint256 _amount,uint256 _box) internal {
         userInfo[_ref][_box].rewardAmount = userInfo[_ref][_box].rewardAmount.add(_amount);
         
         require(address(uint160(_ref)).send(_amount), "Transaction Failed");
         emit _planOneReward(_user,_ref,_amount,_box,block.timestamp);
    }
    
    function rewardUpdate(address _addr,uint256 _reward) public whenNotPaused onlyRewardsDistribution {
        require((userTwoAndThreeInfo[_addr][2].depositAmount != 0) || (userTwoAndThreeInfo[_addr][3].depositAmount != 0) , "User is not exist in this plan");
        
        rewardInfo[_addr].planTwoAndThreeRewards = _reward;
        rewardInfo[_addr].expirytime = block.timestamp + 600;
        rewardInfo[_addr].updatetime = block.timestamp;
        
        emit _rewardUpdate(_addr,_reward,block.timestamp);
    }
    
    
    function withdraw() public whenNotPaused {
        require((userTwoAndThreeInfo[msg.sender][2].depositAmount != 0) || (userTwoAndThreeInfo[msg.sender][3].depositAmount != 0) , "User is not exist in this plan");
        
        rewardStore storage data = rewardInfo[msg.sender];
        require(block.timestamp <= data.expirytime, "rewards distribution time expired");
        require(data.planTwoAndThreeRewards >= withdrawLimit, "Withdraw Limit is exceed");
            
        uint256 distributorFee = data.planTwoAndThreeRewards.sub(withdrawFee);
            
        address(uint160(msg.sender)).transfer(distributorFee);
        address(uint160(_rewardDistributor)).transfer(withdrawFee);
            
        emit _rewardWithdraw(msg.sender,data.planTwoAndThreeRewards,block.timestamp);
        emit _rewardDistributorFee(_rewardDistributor,withdrawFee);
            
        data.planTwoAndThreeRewards = 0;
    }
    
    
    function failSafe(address _addr,uint256 _amount) public onlyOwner{
        require(_addr != address(0), "Zero address");
        require(_amount <= address(this).balance, "Amount is invalid");
        
        address(uint160(_addr)).transfer(_amount);
        emit _failSafe(_addr,_amount,block.timestamp);
    }
    
    function owner() public view returns (address) {
        return _owner;
    }
    
    function rewardDistributor() public view returns (address) {
        return _rewardDistributor;
    }

    function paused() public view returns(bool) {
        return _paused;
    }
    
    function PlanOnePrice() public view returns(uint256[] memory){
        return planOne;
    }
    
    function PlanTwoPrice() public view returns(uint256[] memory){
        return planTwo;
    }
    
    function PlanThreePrice() public view returns(uint256[] memory){
        return planThree;
    }
    
    function planOneDetails(address _addr,uint8 _box) public view returns(uint256 _rewardAmount,address _upline,bool _status){
        userUnilevelData storage data = userInfo[_addr][_box];
        
        _rewardAmount = data.rewardAmount;
        _upline = data.upline;
        _status = data.status;
    }
    
    function planTwoThreeRegStatus(address _addr,uint256 _whichPlan,uint256 _box) public view returns(bool){
        return userTwoAndThreeInfo[_addr][_whichPlan].boxStatus[_box];
    }
    
    function planTwoAndThreeDetails(address _addr) public view returns( uint256 _planOneDeposit,uint256 _planTwoDeposit,uint256 _planRewards,uint256 _updatetime,uint256 _expirytime){
        _planOneDeposit = userTwoAndThreeInfo[_addr][2].depositAmount;
        _planTwoDeposit = userTwoAndThreeInfo[_addr][3].depositAmount;
        _planRewards = rewardInfo[_addr].planTwoAndThreeRewards;
        _updatetime = rewardInfo[_addr].updatetime;
        _expirytime = rewardInfo[_addr].expirytime;
    }
}