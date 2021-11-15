//SPDX-License-Identifier: Unlicense
// pragma solidity ^0.8.0;

// import "hardhat/console.sol";


// contract Greeter {
//   string greeting;

//   constructor(string memory _greeting) {
//     console.log("Deploying a Greeter with greeting:", _greeting);
//     greeting = _greeting;
//   }

//   function greet() public view returns (string memory) {
//     return greeting;
//   }

//   function setGreeting(string memory _greeting) public {
//     console.log("Changing greeting from '%s' to '%s'", greeting, _greeting);
//     greeting = _greeting;
//   }
// }


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

contract infinityMLM{
    
    using SafeMath for uint256;
    
    address private _owner;
    address private _rewardDistributor;
    bool private _paused = false;
    
    uint256[] private planOne = [25,50,100,200,400,800,1600,3200,6400,12500,25000,50000];
    uint256[] private planTwo = [100,200,400,800,1600,3200,6400,12500,25000,50000];
    uint256[] private planThree = [100,200,400,800,1600,3200,6400,12500];
    
    struct userUnilevelData{
        uint256 rewardCount;
        address upline;
        bool status;
    }
    
    struct binaryData{
        uint256 depositAmount;
        uint256 planRewards;
        uint256 updatetime;
        uint256 expirytime;
        mapping (uint256 => bool) boxStatus;
    }
    
    mapping (address => mapping (uint256 => userUnilevelData)) private usersUnilevel;
    mapping (address => mapping (uint256 => binaryData)) private binaryTree;
    
    event _reg(address indexed _user,address indexed _ref,uint256 _box,uint256 _amount,uint256 _time);
    event _buyAllPlan(address indexed _user,address indexed _ref,uint256[3] _box,uint256 _amount,uint256 _time);
    event _buyPlan(string _plan,address indexed _user,uint256 _box,uint256 _amount,uint256 _time);
    event _planOneReward(address indexed _user,address indexed _ref,uint256 _amount,uint256 _box,uint256 _time);
    event _ownerShipTransferred(address indexed _previousOwner, address indexed _newOwner);
    event _distributorTransferred(address indexed _newDistributor,uint256 _time);
    event _rewardUpdate(address indexed _user,uint256 _Plan,uint256 _planReward,uint256 _time);
    event _rewardWithdraw(address indexed _user,uint256 _rewards,uint256 _time);
    event _failSafe(address indexed _addr,uint256 _amount,uint256 _time);
    event _pause(bool _status,uint256 _time);
    event _unpause(bool _status,uint256 _time);
    
    constructor(address add1,address add2) public{
        _owner = add1;
        _rewardDistributor = add2;
        
        for(uint i=0; i < planOne.length; i++){
            usersUnilevel[_owner][i].status = true;
            
             if(i==2 || i==3) binaryTree[_owner][i].depositAmount = 100e6;
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
    
    function priceUpdate(uint[] memory _planOne,uint[] memory _planTwo,uint[] memory _planThree) public onlyOwner {
        planOne = _planOne;
        planTwo = _planTwo;
        planThree = _planThree;
        
        for(uint i=0; i < planOne.length; i++){
            usersUnilevel[_owner][i].status = true;
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
        require(msg.value == (planOne[_box] * 1e6), "Amount is invalid");
        require(usersUnilevel[_uniRef][_box].status, "Referrer address is invalid");
        require((usersUnilevel[msg.sender][_box - 1].status) && !(usersUnilevel[msg.sender][_box].status) , "Buy previous plan");
        
        usersUnilevel[msg.sender][_box].upline = _uniRef;
        usersUnilevel[msg.sender][_box].status = true;
        
        emit _buyPlan("One",msg.sender,_box,msg.value,block.timestamp);
        
        planOneReward(msg.sender,_uniRef,(planOne[_box] * 1e6),_box);  
    }
    
    function buyPlanTwo(uint256 _box) public whenNotPaused payable{
        require(_box <= planTwo.length - 1, "plan id is invalid");
        require(msg.value == (planTwo[_box] * 1e6), "Amount is invalid");
        require((binaryTree[msg.sender][2].boxStatus[_box - 1]) && !(binaryTree[msg.sender][2].boxStatus[_box]), "Buy previous plan");
        
        binaryTree[msg.sender][2].boxStatus[_box] = true;
        binaryTree[msg.sender][2].depositAmount += planTwo[_box] * 1e6;
        
        emit _buyPlan("Two",msg.sender,_box,msg.value,block.timestamp);
    }
    
    function buyPlanThree(uint256 _box) public whenNotPaused payable{
        require(_box <= planThree.length - 1, "plan id is invalid");
        require(msg.value == (planThree[_box] * 1e6), "Amount is invalid");
        require((binaryTree[msg.sender][3].boxStatus[_box - 1] && !(binaryTree[msg.sender][3].boxStatus[_box])), "Buy previous plan");
        
        binaryTree[msg.sender][3].boxStatus[_box] = true;
        binaryTree[msg.sender][3].depositAmount += planThree[_box] * 1e6;
        
        emit _buyPlan("Three",msg.sender,_box,msg.value,block.timestamp);
    } 
    
    function regUser(address _uniRef,uint256 _box) public whenNotPaused payable {
        require(_box == 0, "plan id is invalid");
        require(msg.value == ((planOne[_box] + planTwo[_box] + planThree[_box]) * 1e6 ), "Amount is invalid");
        require(usersUnilevel[_uniRef][_box].status, "Referrer address is invalid");
        require(!(usersUnilevel[msg.sender][_box].status) && !(binaryTree[msg.sender][2].boxStatus[_box]) && !(binaryTree[msg.sender][3].boxStatus[_box]), "Already exists in this plan");
        
        
        usersUnilevel[msg.sender][_box].upline = _uniRef;
        usersUnilevel[msg.sender][_box].status = true;
        binaryTree[msg.sender][2].depositAmount += planOne[_box] * 1e6;
        binaryTree[msg.sender][3].depositAmount += planTwo[_box] * 1e6;
        binaryTree[msg.sender][2].boxStatus[_box] = true;
        binaryTree[msg.sender][3].boxStatus[_box] = true;
        
        emit _reg(msg.sender,_uniRef,_box,msg.value,block.timestamp);
        
        planOneReward(msg.sender,_uniRef,planOne[_box] * 1e6,_box);
    }
    
    function buyAllPlan(address _uniRef,uint256[3] memory _box) public whenNotPaused payable {

        require(_box[0] != 0 && _box[0] <=  planOne.length - 1, "plan id is invalid");
        require(_box[1] != 0 && _box[1] <=  planTwo.length - 1, "plan id is invalid");
        require(_box[2] != 0 && _box[2] <=  planThree.length - 1, "plan id is invalid");
        (uint256 _planOne,uint256 _planTwo,uint256 _planThree) = (planOne[_box[0]] * 1e6,planTwo[_box[1]]  * 1e6 , planThree[_box[2]] * 1e6 );
        require(msg.value == (_planOne + _planTwo + _planThree ), "Amount is invalid");
        require(usersUnilevel[_uniRef][_box[0]].status && !(usersUnilevel[msg.sender][_box[0]].status) && (usersUnilevel[msg.sender][_box[0] - 1].status) , "plan one error");
        require(!(binaryTree[msg.sender][2].boxStatus[_box[1]]) && (binaryTree[msg.sender][2].boxStatus[_box[1] - 1]) , "plan two error");
        require( !(binaryTree[msg.sender][3].boxStatus[_box[2]]) && (binaryTree[msg.sender][3].boxStatus[_box[2] - 1]) , "plan three error");
        
        usersUnilevel[msg.sender][_box[0]].upline = _uniRef;
        usersUnilevel[msg.sender][_box[0]].status = true;
        binaryTree[msg.sender][2].depositAmount += _planTwo;
        binaryTree[msg.sender][3].depositAmount += _planThree;
        binaryTree[msg.sender][2].boxStatus[_box[1]] = true;
        binaryTree[msg.sender][3].boxStatus[_box[2]] = true;
        
        emit _buyAllPlan(msg.sender,_uniRef,_box,msg.value,block.timestamp);
        
        planOneReward(msg.sender,_uniRef,_planOne,_box[0]);
    }
    
    function planOneReward(address _user,address _ref,uint256 _amount,uint256 _box) internal {
         usersUnilevel[_ref][_box].rewardCount++;
         
         if(usersUnilevel[_ref][_box].rewardCount.mod(4) == 0){
             _ref = _owner;
         }
         
         require(address(uint160(_ref)).send(_amount), "Transaction Failed");
         emit _planOneReward(_user,_ref,_amount,_box,block.timestamp);
    }
    
    function singlePlanRewardUpdate(address _addr,uint256 _whichPlan,uint256 _planReward) public whenNotPaused onlyRewardsDistribution {
        require(_whichPlan == 2 || _whichPlan == 3, "plan id is invalid");
        require((binaryTree[_addr][_whichPlan].depositAmount != 0), "User is not exist in this plan");
        
        binaryTree[_addr][_whichPlan].planRewards += _planReward;
        binaryTree[_addr][_whichPlan].expirytime = block.timestamp + 600;
        binaryTree[_addr][_whichPlan].updatetime = block.timestamp;
        
        emit _rewardUpdate(_addr,_whichPlan,_planReward,block.timestamp);
    }
    
    function mulPlanRewardUpdate(address _addr,uint256[2] memory _planReward) public whenNotPaused onlyRewardsDistribution {
        for(uint256 i=2; i<4 ; i++){
            require((binaryTree[_addr][i].depositAmount != 0), "User is not exist in this plan");
        
            binaryTree[_addr][i].planRewards += _planReward[i - 2];
            binaryTree[_addr][i].expirytime = block.timestamp + 600;
            binaryTree[_addr][i].updatetime = block.timestamp;
            
            emit _rewardUpdate(_addr,i,_planReward[i],block.timestamp);
        }
    }
    
    function withdraw(uint256 _whichPlan) public whenNotPaused {
        require(_whichPlan == 2 || _whichPlan == 3, "plan id is invalid");
        require((binaryTree[msg.sender][_whichPlan].depositAmount != 0), "User is not exist in this plan");
        binaryData storage data = binaryTree[msg.sender][_whichPlan];
        require(block.timestamp <= data.expirytime, "rewards distribution time expired");
        
        if(data.planRewards > 0){
            emit _rewardWithdraw(msg.sender,data.planRewards,block.timestamp);
            
            address(uint160(msg.sender)).transfer(data.planRewards);
            
            data.planRewards = 0;
        }
    }
    
    function multipleWithdraw() public whenNotPaused {
        for(uint256 i=2; i<4 ; i++){
            require((binaryTree[msg.sender][i].depositAmount != 0), "User is not exist in this plan");
            binaryData storage data = binaryTree[msg.sender][i];
            require(block.timestamp <= data.expirytime, "rewards distribution time expired");
            
            if(data.planRewards > 0){
                emit _rewardWithdraw(msg.sender,data.planRewards,block.timestamp);
                
                address(uint160(msg.sender)).transfer(data.planRewards);
                
                data.planRewards = 0;
            }
        }
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
    
    function planOneDetails(address _addr,uint8 _box) public view returns(uint256 _rewardCount,address _upline,bool _status){
        userUnilevelData storage data = usersUnilevel[_addr][_box];
        
        _rewardCount = data.rewardCount;
        _upline = data.upline;
        _status = data.status;
    }
    
    function planTwoThreeRegStatus(address _addr,uint256 _whichPlan,uint256 _box) public view returns(bool){
        return binaryTree[_addr][_whichPlan].boxStatus[_box];
    }
    
    function planTwoAndThreeDetails(address _addr,uint256 _whichPlan) public view returns( uint256 _depositAmount,uint256 _planRewards,uint256 _updatetime,uint256 _expirytime){
        _depositAmount = binaryTree[_addr][_whichPlan].depositAmount;
        _planRewards = binaryTree[_addr][_whichPlan].planRewards;
        _updatetime = binaryTree[_addr][_whichPlan].updatetime;
        _expirytime = binaryTree[_addr][_whichPlan].expirytime;
    }
}

