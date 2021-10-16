/**
 *Submitted for verification at BscScan.com on 2021-10-15
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


interface IBEP20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function getOwner() external view returns (address);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract MatrixPlus is Ownable {

    IBEP20 constant private  BUSD = IBEP20(0x6D044CACd2513ECd07eAbbb575344f5873Cd9a39);
    uint256 private lastUserId = 1;
    uint256 public basePrice = 60*10**18; //  with 18 decimals
    uint256 public refPrice = 10*10**18; //  with 18 decimals

    bool gasOptimization;

    // Structures
    struct User{
        uint32 timeJoined;
        bool position;  // left = false, right = right
        address sponsorId;
        uint256 poolId;
        uint256 planId;
    }

    struct UserInfo{
        uint256 id;
        address ref;
        uint nextEntry;
        uint256 totalStaked;
        uint256 wallet;
        uint256 received;
        address[3] direct_downline;
        uint256 totalDownline;
    }


    struct Matrix{
        address refAddress;
        uint256 amount;
        uint256 level; 
    }

    struct LevelIncome{
        uint256 level;
        uint256 amount;
        address refAddress;

    }

    struct BinaryIncome{
        uint32 leftPoint;
        uint32 rightPoint;
        uint32 matchPoint;
        uint32 perPointAmt;
        uint32 matchingPointAmt;
    }

    struct GenerationPlan{
        uint256 level;
        uint256 amount;
        address refAddress;
    }

    struct Rewarding{
        uint256 matchingPair;
        uint256 rewardAmt;
    }

    // mappings
    mapping (address => User) public _User;

    mapping(address => UserInfo) private users;

    mapping(address => address) private Parent;

    mapping (address => bool) public isRegistered;

    mapping (address => Matrix) public _Matrix;

    mapping (address => LevelIncome) public _LevelIncome;

    mapping (address => BinaryIncome) public _BinaryIncome;

    mapping (address => GenerationPlan) public _GenerationPlan;

    mapping (address => Rewarding) public _Rewarding;

    // events
    event Registered(address user, address ref, bool position);

    event MatrixUpdated(address user, address ref, uint256 amount, uint256 level);

    event LevelIncomeUpdated(address user, address ref, uint256 amount, uint256 level);

    event GenerationPlanUpdated(address user, address ref, uint256 amount, uint256 level);

    event BinaryIncomeUpdated(address user);

    event RewardingUpdated(address user, uint256 matchingPair, uint256 rewardAmt);

    event UserPositionUpdated(address user, uint prevPosition, uint newPosition);

    event PoolIdUpdated(address user, uint oldId, uint newId);

    event PlanIdUpdated(address user, uint oldId, uint newId);

    event UserLevelUpdated(address user, uint newLevel);

    constructor(){

        isRegistered[msg.sender] = true;
        _User[msg.sender].sponsorId = address(this);
        _User[msg.sender].timeJoined = uint32(block.timestamp);
        _User[msg.sender].planId = 1;
        _User[msg.sender].poolId = 1;
        emit Registered(msg.sender, address(this), true); // true == right

        gasOptimization = true;
    }

    // Functions
    function register(address refAddress, bool _position) external returns (bool){
        // check for user pre-registry
        require( !isRegistered[msg.sender] ,"User Registered");

        //check for valid refAddress
        require( isRegistered[refAddress] ,"Invalid Referral Address");

        // check for BUSD Approval
        require(BUSD.allowance(msg.sender, address(this)) >= basePrice,"BUSD: allowance error");

        // check for valid amount
        require(BUSD.balanceOf(msg.sender) >= basePrice ,"BUSD: insufficient amount");

        BUSD.transferFrom(msg.sender, address(this), basePrice);

        isRegistered[msg.sender] = true;

        _User[msg.sender].sponsorId = refAddress;
        _User[msg.sender].position = _position;
        _User[msg.sender].timeJoined = uint32(block.timestamp);
        _User[msg.sender].planId = 1;
        _User[msg.sender].poolId = 1;

        // _Matrix[user].refAddress = refAddress;
        // _LevelIncome[user].refAddress = refAddress;
        // _GenerationPlan[user].refAddress = refAddress;

        emit Registered(msg.sender, refAddress, _position);

        if(!gasOptimization){
            // check if refAddress has empty slots
            if(users[refAddress].totalDownline < 3){
                users[refAddress].direct_downline[users[refAddress].totalDownline] = (msg.sender);
                users[refAddress].totalDownline++;

                // send 5$ to refAddress -- remaining goes to contract
                BUSD.transferFrom(msg.sender, address(this), basePrice);
                users[refAddress].received += refPrice;

                users[msg.sender].id = lastUserId;
                lastUserId++;
                users[msg.sender].ref = refAddress;
                Parent[msg.sender] = refAddress;
                users[msg.sender].totalStaked += basePrice;
                 return true;
            }

            else if(users[refAddress].totalDownline > 3 && users[refAddress].totalDownline < 12) {

                address tempAdd;

                // check for lastentry and start from there
                uint x = users[refAddress].nextEntry;  // index range : 0 1 2

                for(uint i = 0; i < 3; i++){
                    require(x<3, "Calculation Error");

                    tempAdd = users[refAddress].direct_downline[x];

                    if(users[tempAdd].totalDownline < 3 ){

                        users[tempAdd].direct_downline[users[tempAdd].totalDownline] = msg.sender;
                        users[tempAdd].totalDownline++;
                        users[refAddress].totalDownline++;

                        //
                        users[refAddress].nextEntry = x+1;
                        //

                        users[msg.sender].id = lastUserId;
                        lastUserId++;
                        users[msg.sender].ref = tempAdd; //
                        Parent[msg.sender] = tempAdd; //
                        users[msg.sender].totalStaked += basePrice;

                        // send 5$-5$ to refAddress -- remaining goes to contract
                        BUSD.transferFrom(msg.sender, address(this), basePrice);
                        users[tempAdd].received += refPrice;

                        if(users[refAddress].totalDownline <= 10){
                            payable(refAddress).transfer(refPrice);
                            users[refAddress].received += refPrice;
                        }
                        else if(users[refAddress].totalDownline == 11){
                            users[refAddress].wallet += refPrice;
                        }
                        else if(users[refAddress].totalDownline == 12){
                            users[refAddress].wallet += refPrice;
                            reentry(refAddress);
                        }

                        return true;
                    }

                    x = (x+1)%3;

                }
                return false;
            }

            else{
                 return false;
            }

        }

        return true;
    }

    function updatePoolId(address user, uint _poolId) external onlyOwner returns(bool){
        uint prevPoolId = _User[user].poolId;
        _User[user].poolId = _poolId;
        emit PoolIdUpdated(user, prevPoolId, _poolId);
        return true;
    }

    function updatePlanId(address user, uint _planId) external onlyOwner returns(bool){
        uint prevPlanlId = _User[user].planId;
        _User[user].planId = _planId;
        emit PlanIdUpdated(user, prevPlanlId, _planId);
        return true;
    }

    function reentry(address userAdd) internal returns(bool){
        // get refAddress
        address refAddress = Parent[userAdd];
        require(refAddress != address(0), "Invalid address found");

        // check for ref's empty slot
        if(refAddress != address(this) && users[refAddress].totalDownline<11){
                // register with refAddress
                // check if refAddress has empty slots
                if(users[refAddress].totalDownline < 3){
                    users[refAddress].direct_downline[users[refAddress].totalDownline] = (userAdd);
                    users[refAddress].totalDownline++;

                    // send 5$ to refAddress -- remaining goes to contract
                    BUSD.transferFrom(msg.sender, address(this), refPrice);
                    users[refAddress].received += refPrice;


                    // users[userAdd].id = lastUserId;
                    // lastUserId++;
                    users[userAdd].ref = refAddress;
                    users[userAdd].totalStaked += users[userAdd].wallet;
                    users[userAdd].wallet = 0;

                    users[userAdd].nextEntry = 0;
                    users[userAdd].totalDownline = 0;
                    users[userAdd].direct_downline[0] = address(0);
                    users[userAdd].direct_downline[1] = address(0);
                    users[userAdd].direct_downline[2] = address(0);

                    return true;

                }

                else if(users[refAddress].totalDownline > 3 && users[refAddress].totalDownline < 12) {

                    address tempAdd;

                    // check for last entry and start from there
                    uint x = users[refAddress].nextEntry;  // index range : 0 1 2

                    for(uint i = 0; i < 3; i++){
                        require(x<3, "Calculation Error");

                        tempAdd = users[refAddress].direct_downline[x];

                        if(users[tempAdd].totalDownline < 3 && tempAdd!=userAdd ){

                            users[tempAdd].direct_downline[users[tempAdd].totalDownline] = (userAdd);
                            users[tempAdd].totalDownline++;
                            users[refAddress].totalDownline++;

                            users[refAddress].nextEntry = x+1;

                            users[userAdd].ref = refAddress;
                            users[userAdd].totalStaked += users[userAdd].wallet;
                            users[userAdd].wallet = 0;

                            users[userAdd].nextEntry = 0;
                            users[userAdd].totalDownline = 0;
                            users[userAdd].direct_downline[0] = address(0);
                            users[userAdd].direct_downline[1] = address(0);
                            users[userAdd].direct_downline[2] = address(0);

                            // send 5$-5$ to refAddress -- remaining goes to contract
                            payable(tempAdd).transfer(refPrice);
                            users[tempAdd].received += refPrice;

                            if(users[refAddress].totalDownline < 10){
                                payable(refAddress).transfer(refPrice);
                                users[refAddress].received += refPrice;
                            }
                            else if(users[refAddress].totalDownline == 11){
                                users[refAddress].wallet += refPrice;
                            }
                            else if(users[refAddress].totalDownline == 12){
                                users[refAddress].wallet += refPrice;
                                reentry(refAddress);
                            }

                            return true;
                        }

                        x = (x+1)%3;

                    }
                    return false;
                }

                else{
                     return false;
                }
        }
        else{
            // register with null-contract address
            users[userAdd].totalStaked += users[userAdd].wallet;
            users[userAdd].wallet = 0;
            users[userAdd].ref = address(this);
            users[userAdd].nextEntry = 0;
            users[userAdd].totalDownline = 0;
            users[userAdd].direct_downline[0] = address(0);
            users[userAdd].direct_downline[1] = address(0);
            users[userAdd].direct_downline[2] = address(0);
        }
        // check with
        return true;
    }


    function updateMatrix(address _user, address _ref, uint256 _amount, uint256 _level) external onlyOwner() returns(bool){

        Matrix storage userMatrix = _Matrix[_user];
        userMatrix.refAddress = _ref;
        userMatrix.amount = _amount;
        userMatrix.level = _level;

        emit MatrixUpdated(_user, _ref, _amount, _level);
        return true;
    }

    function updateLevelIncome(address _user, address _ref, uint256 _amount, uint256 _level) external onlyOwner() returns(bool){
        LevelIncome storage userLevelIncome = _LevelIncome[_user];
        userLevelIncome.refAddress = _ref;
        userLevelIncome.amount = _amount;
        userLevelIncome.level = _level;

        emit LevelIncomeUpdated(_user, _ref, _amount, _level);
        return true;
    }

    function updateGenerationPlan(address _user, address _ref, uint256 _amount, uint256 _level) external onlyOwner() returns(bool){

        GenerationPlan storage userGenerationPlan = _GenerationPlan[_user];
        userGenerationPlan.refAddress = _ref;
        userGenerationPlan.amount = _amount;
        userGenerationPlan.level = _level;

        emit GenerationPlanUpdated(_user, _ref, _amount, _level);
        return true;
    }

    function updateBinaryIncome(address _user, uint _leftPoint, uint _rightPoint, uint _matchPoint, uint _perPointAmt,  uint _matchingPointAmt) external onlyOwner() returns(bool){

        BinaryIncome storage userBinary = _BinaryIncome[_user];
        userBinary.leftPoint = uint32(_leftPoint);
        userBinary.rightPoint = uint32(_rightPoint);
        userBinary.matchPoint = uint32(_matchPoint);
        userBinary.perPointAmt = uint32(_perPointAmt);
        userBinary.matchingPointAmt = uint32(_matchingPointAmt);

        emit BinaryIncomeUpdated(_user);
        return true;
    }

    function updateRewarding(address _user, uint256 _matchingPair, uint256 _rewardAmt) external onlyOwner() returns(bool){

        Rewarding storage userReward = _Rewarding[_user];
        userReward.matchingPair = _matchingPair;
        userReward.rewardAmt = _rewardAmt;

        emit RewardingUpdated(_user, _matchingPair, _rewardAmt);
        return true;
    }

    function withdraw(uint256 amt) external onlyOwner() returns(bool){
        BUSD.transfer(owner(), amt);
        return true;
    }

    function rescue() external onlyOwner() returns(bool){
        payable(owner()).transfer(address(this).balance);
        return true;
    }
}