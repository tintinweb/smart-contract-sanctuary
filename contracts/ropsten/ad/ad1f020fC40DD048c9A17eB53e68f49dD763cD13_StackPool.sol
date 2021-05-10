/**
 *Submitted for verification at Etherscan.io on 2021-05-10
*/

/**
 *Submitted for verification at BscScan.com on 2021-05-07
*/

pragma solidity 0.6.12;

library SafeMath {

    function add(uint a, uint b) internal pure returns(uint) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint a, uint b) internal pure returns(uint) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint a, uint b) internal pure returns(uint) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint a, uint b) internal pure returns(uint) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }

    function mod(uint a, uint b) internal pure returns(uint) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract StackPool{

    struct UserStruct{
        bool isExist;
        uint currentId;
        address referer;
        address[] referals;
        mapping(uint8 => uint) previousDepositTime;
        mapping(uint8 => uint8) currentLevel;
        mapping(uint8 => mapping(uint8 => bool)) investStatus;
        mapping(uint => mapping(uint => uint)) reInvestCount;
    }

    struct userPlan {
        uint[] plan;
        uint[] level;
        uint[] depositTime;
        uint[] depositAmount;
        bool[] activeStatus;
        bool[] completedStatus;
        bool[]roiStatus;
    }

    using SafeMath for uint256;


    address public owner;
    address[] public ownerList;

    address[] public commitee;
    uint[4] public adminPercentage = [6e18, 6e18, 1e18, 1e18];
    uint public lastUserId = 2;
    uint public commiteeShare = 0;
    bool public lockStatus;
    uint public ROI_DURATION = 10 days;
    uint public adminShare;

    event adminDepositEvent(address indexed depositor, uint depositAmount, uint time);
    event Registration(address indexed user, address indexed referrer, uint value, uint plan, uint time);
    event buyLevelEvent(address indexed user, uint plan, uint level, uint amount, uint time);
    event reInvestEvent(address indexed user, uint plan, uint level, uint amount, uint time);
    event adminShareEvent(address indexed user, address indexed to, uint value, uint time);
    event directRefer(address indexed user, address indexed to, uint value, uint time);
    event refererBouns(address indexed user, address indexed to, uint plan, uint level, uint value, uint uplineNo, uint time);
    event withdrawCheck(address indexed user, uint value, uint time);
    event commiteeCheckShare(address indexed to, uint value, uint time);

    mapping(address => userPlan) userData;
    mapping(uint => address) public userList;
    mapping(address => UserStruct) public users;
    mapping(uint => mapping(uint => uint)) public planPrice;
    mapping(uint => uint) public levelPercent;
    mapping(address => uint) public loopCheck;
    mapping(address => mapping(uint8 => uint)) public refAmount;
    mapping(address => uint)public withdrawamount;
    mapping(address => uint)public roiAmount;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only Owner");
        _;
    }

    modifier isLock() {
        require(lockStatus == false, "Contract Locked");
        _;
    }

    modifier userExist(address user) {
        require(users[user].isExist == true, "User not Exist");
        _;
    }

    constructor(address _ownerAddress) public{
        owner = _ownerAddress;

        UserStruct memory userstruct;
        userstruct = UserStruct({
            isExist: true,
            currentId: 1,
            referer: address(0),
            referals: new address[](0)
        });

        users[owner] = userstruct;
        userList[1] = owner;

        //Starter category
        planPrice[1][1] = 0.15e18;
        planPrice[1][2] = 0.3e18;
        planPrice[1][3] = 0.6e18;
        planPrice[1][4] = 1.2e18;
        planPrice[1][5] = 3e18;
        planPrice[1][6] = 6e18;
        planPrice[1][7] = 9e18;
        planPrice[1][8] = 14e18;
        planPrice[1][9] = 23e18;
        planPrice[1][10] = 41e18;

        //standard category
        planPrice[2][1] = 10e18;
        planPrice[2][2] = 13e18;
        planPrice[2][3] = 18.5e18;
        planPrice[2][4] = 28e18;
        planPrice[2][5] = 44e18;
        planPrice[2][6] = 72e18;
        planPrice[2][7] = 105e18;
        planPrice[2][8] = 165e18;
        planPrice[2][9] = 280e18;
        planPrice[2][10] = 510e18;

        levelPercent[0] = 2e18;
        levelPercent[1] = 1e18;
        levelPercent[2] = 1e18;
        levelPercent[3] = 0.5e18;
        levelPercent[4] = 0.25e18;
        levelPercent[5] = 0.25e18;

        users[owner].currentLevel[1] = 10;
        users[owner].currentLevel[2] = 10;
    }

    function fallback()external  payable{

        emit adminDepositEvent(msg.sender, msg.value, block.timestamp);
    }

    /**
    * @dev registration : User can register
    */
    function registration(address referer, uint8 plan)public isLock userExist(referer) payable {
        require(users[msg.sender].isExist == false, "User Exist");
        require(!isContract(msg.sender), "Invalid address");


        if (plan == 1 || plan == 2) {
            require(planPrice[plan][1] == msg.value, " Invalid  Price");
            _planActivation(msg.sender, plan, 1, msg.value, referer);
            loopCheck[msg.sender] = 0;
            directRefShare(referer, msg.value);
            payUplineShare(referer, msg.value, 1, 1);
            users[msg.sender].previousDepositTime[plan] = block.timestamp;
            users[msg.sender].investStatus[plan][1] = true;
            emit Registration(msg.sender, referer, msg.value, plan, block.timestamp);
        }
        else {
            require(planPrice[1][1].add(planPrice[2][1]) == msg.value, " Invalid  Price");
            _planActivation(msg.sender, 1, 1, planPrice[1][1], referer);
            _planActivation(msg.sender, 2, 1, planPrice[2][1], referer);
            loopCheck[msg.sender] = 0;
            directRefShare(referer, planPrice[1][1]);
            payUplineShare(referer, planPrice[1][1], 1, 1);
            loopCheck[msg.sender] = 0;
            directRefShare(referer, planPrice[2][1]);
            payUplineShare(referer, planPrice[2][1], 2, 1);

            users[msg.sender].previousDepositTime[1] = block.timestamp;
            users[msg.sender].previousDepositTime[2] = block.timestamp;

            users[msg.sender].investStatus[1][1] = true;
            users[msg.sender].investStatus[2][1] = true;

            emit Registration(msg.sender, referer, planPrice[1][1], 1, block.timestamp);
            emit Registration(msg.sender, referer, planPrice[2][1], 2, block.timestamp);
        }

    }

    function _planActivation(address _user, uint8 _plan, uint8 _level, uint _amount, address referer) internal {

        if (users[_user].isExist == false) {
            UserStruct memory userstruct;
            userstruct = UserStruct({
                isExist: true,
                currentId: lastUserId,
                referer: referer,
                referals: new address[](0)
            });

            users[_user] = userstruct;
            userList[lastUserId] = _user;
            users[referer].referals.push(_user);
            lastUserId++;


        }

        uint adminpercent = (_amount.mul(14e18)).div(100e18);
        uint commiteepercent = (_amount.mul(2e18)).div(100e18);

        adminShare = adminShare.add(adminpercent);
        commiteeShare = commiteeShare.add(commiteepercent);

        users[_user].currentLevel[_plan] = _level;

        userData[_user].plan.push(_plan);
        userData[_user].level.push(_level);
        userData[_user].depositTime.push(block.timestamp);
        userData[_user].depositAmount.push(_amount);
        userData[_user].activeStatus.push(true);
        userData[_user].completedStatus.push(false);
        userData[_user].roiStatus.push(false);

    }

    function _directRef(uint8 _flag, address _ref, uint amount) internal {
        if (users[_ref].referals.length > 0 && users[_ref].referals.length <= 10) {
            refAmount[_ref][_flag] = refAmount[_ref][_flag].add((amount.mul(5e18)).div(100e18));
            emit directRefer(msg.sender, _ref, (amount.mul(5e18)).div(100e18), block.timestamp);
        }
        else if (users[_ref].referals.length >= 11 && users[_ref].referals.length <= 40) {
            refAmount[_ref][_flag] = refAmount[_ref][_flag].add((amount.mul(7.5e18)).div(100e18));
            emit directRefer(msg.sender, _ref, (amount.mul(7.5e18)).div(100e18), block.timestamp);
        }
        else if (users[_ref].referals.length >= 41 && users[_ref].referals.length <= 70) {
            refAmount[_ref][_flag] = refAmount[_ref][_flag].add((amount.mul(10e18)).div(100e18));
            emit directRefer(msg.sender, _ref, (amount.mul(10e18)).div(100e18), block.timestamp);
        }
        else if (users[_ref].referals.length >= 71 && users[_ref].referals.length <= 99) {
            refAmount[_ref][_flag] = refAmount[_ref][_flag].add((amount.mul(12.5e18)).div(100e18));
            emit directRefer(msg.sender, _ref, (amount.mul(12.5e18)).div(100e18), block.timestamp);
        }
        else if (users[_ref].referals.length > 99) {
            refAmount[_ref][_flag] = refAmount[_ref][_flag].add((amount.mul(15e18)).div(100e18));
            emit directRefer(msg.sender, _ref, (amount.mul(15e18)).div(100e18), block.timestamp);
        }
    }

    function directRefShare(address _ref, uint amount) internal {

        uint previousDepositTime1 = users[_ref].previousDepositTime[1];
        uint previousDepositTime2 = users[_ref].previousDepositTime[2];

        if ((block.timestamp <= previousDepositTime1.add(ROI_DURATION) || block.timestamp <= previousDepositTime2.add(ROI_DURATION)) || _ref == owner) {
            _directRef(1, _ref, amount);
        }
        else {
            _directRef(2, _ref, amount);
        }
    }

    /**
    * @dev adminWithdraw : Only admin can withdraw 
    * 14% amount split into 4 address
    */
    function adminWithdraw() public onlyOwner {
        uint shares = adminShare;
        adminShare = 0;

        if (shares > 0) {
            require(address(uint160(owner)).send((shares.mul(adminPercentage[0])).div(100e18)), "transfer failed");
            emit adminShareEvent(msg.sender, owner, (shares.mul(adminPercentage[0])).div(100e18), block.timestamp);

            if (ownerList.length == 3) {
                for (uint8 i = 0; i < 3; i++) {
                    require(ownerList[i] != address(0), "transaction failed");
                    require(address(uint160(ownerList[i])).send((shares.mul(adminPercentage[i + 1])).div(100e18)), "transfer failed");
                    emit adminShareEvent(msg.sender, ownerList[i], (shares.mul(adminPercentage[i + 1])).div(100e18), block.timestamp);
                }
            }
        }
    }

    /**
    * @dev commiteeWithdraw : Only admin can withdraw 
    * 2% amount split into 20 address
    */

    function commiteeWithdraw()public onlyOwner{

        uint commitshare = commiteeShare.div(20);
        commiteeShare = 0;
        if (commitee.length == 20) {
            for (uint i = 0; i < 20; i++) {
                require(commitee[i] != address(0), "transaction failed");
                require(address(uint160(commitee[i])).send(commitshare), "commitee failed");
                emit commiteeCheckShare(commitee[i], commitshare, block.timestamp);
            }
        }

        else
            return;
    }


    function buyLevel(uint8 plan, uint8 level) public isLock userExist(msg.sender) payable {
        uint previousDepositTime = users[msg.sender].previousDepositTime[plan];

        require(block.timestamp >= previousDepositTime.add(ROI_DURATION), "Already in Active Stage in Some Levels in this Plan");
        require(users[msg.sender].currentLevel[plan] + 1 == level || users[msg.sender].investStatus[plan][level] == true,"Given wrong level");
        if (users[msg.sender].currentLevel[plan] + 1 == level || users[msg.sender].investStatus[plan][level] == true) {
            refAmount[msg.sender][1] = refAmount[msg.sender][1].add(msg.value);
        }
       
        _roiWithdraw(msg.sender);

        uint cumulativerefAmount = refAmount[msg.sender][1].add(refAmount[msg.sender][2]).add(roiAmount[msg.sender]);

        require(cumulativerefAmount >= planPrice[plan][level], "Insufficient Amount for buy");
        refAmountShare(msg.sender, plan, level);

        users[msg.sender].previousDepositTime[plan] = block.timestamp;

        if (users[msg.sender].investStatus[plan][level] == true)
            reInvest(msg.sender, plan, level);
        else
            buyNext(msg.sender, plan, level);
    }

    /**
    * @dev buyLevel : User can buy a new level
    * Ther is chance to skip one level
    * nochance to buy preivous before completing 10 levels
    */
    function buyNext(address _user, uint8 plan, uint8 _level) internal {
        require(users[_user].investStatus[plan][_level] == false, "Buy Next Error");

        if (_level != 1) {
            if (users[_user].currentLevel[plan] != 0)
                require((users[_user].currentLevel[plan] + 1 == _level) || (users[_user].currentLevel[plan] + 2 == _level), "wrong level given");
        }


        if (users[_user].currentLevel[plan] == 10 || users[_user].currentLevel[plan] == 0) {
            require(_level == 1, "Start From Level 1");
        }
        else
            require(users[_user].currentLevel[plan] < _level, "invalid level");

        _planActivation(_user, plan, _level, planPrice[plan][_level], users[_user].referer);
        users[_user].investStatus[plan][_level] = true;
        loopCheck[_user] = 0;
        directRefShare(users[_user].referer, planPrice[plan][_level]);
        payUplineShare(users[_user].referer, planPrice[plan][_level], plan, _level);

        emit buyLevelEvent(_user, plan, _level, planPrice[plan][_level], block.timestamp);

    }

    /**
    * @dev userWithdraw : user can withdraw their staking amount
    */
    function userWithdraw()public isLock userExist(msg.sender) {

        uint i = 0;
        uint wAmount;
        _roiWithdraw(msg.sender);



        while (i < userData[msg.sender].plan.length) {

            if (userData[msg.sender].completedStatus[i] == false) {

                uint _plan = userData[msg.sender].plan[i];
                uint _level = userData[msg.sender].level[i];

                if (block.timestamp >= userData[msg.sender].depositTime[i].add(ROI_DURATION)) {
                    userData[msg.sender].completedStatus[i] = true;
                    userData[msg.sender].activeStatus[i] = false;

                    uint roiPer;
                    if (users[msg.sender].reInvestCount[_plan][_level] > 0)
                        roiPer = ((10e18) * (_level)) /(2);
                    
                    else
                    roiPer = ((10e18) * (_level));


                    wAmount = wAmount.add(userData[msg.sender].depositAmount[i]);

                }


            }

            i = i + 1;
        }

        wAmount = wAmount.add(refAmount[msg.sender][1]).add(roiAmount[msg.sender]);
        refAmount[msg.sender][1] = 0;
        roiAmount[msg.sender] = 0;
        require(address(uint160(msg.sender)).send(wAmount), "withdraw failed");
        emit withdrawCheck(msg.sender, wAmount, block.timestamp);

    }


    function _roiWithdraw(address _user) internal  {
        uint i = 0;
        uint roiCalc;


        while (i < userData[_user].plan.length) {

            if (userData[_user].roiStatus[i] == false && block.timestamp >= userData[_user].depositTime[i].add(ROI_DURATION)) {

                uint _plan = userData[_user].plan[i];
                uint _level = userData[_user].level[i];

                if (now >= userData[_user].depositTime[i].add(ROI_DURATION)) {


                    uint roiPer;
                    if (users[_user].reInvestCount[_plan][_level] > 0) {
                        roiPer = ((10e18) * (_level)) /(2);
                    }
                    else {
                        roiPer = ((10e18) * (_level));
                    }

                    roiCalc = (userData[_user].depositAmount[i].mul(roiPer)).div(100e18);
                    roiAmount[_user] = roiAmount[_user].add(roiCalc);

                }

                if (roiCalc > 0) {
                    userData[_user].roiStatus[i] = true;
                }

            }

            i = i + 1;
        }



    }

    function viewAvailableWithdraw(address _user) public view returns(uint) {

        uint i = 0;
        uint wAmount;

        uint Roi = viewRoi(_user);


        while (i < userData[_user].plan.length) {

            if (userData[_user].completedStatus[i] == false && block.timestamp >= userData[_user].depositTime[i].add(ROI_DURATION))

                wAmount = wAmount.add(userData[_user].depositAmount[i]);



            i = i + 1;
        }

        wAmount = wAmount.add(refAmount[_user][1]).add(Roi).add(roiAmount[_user]);
        return wAmount;
    }



    function viewRoi(address _user) public view returns(uint){
        uint i = 0;
        uint roiCalc;
        uint bal;

        while (i < userData[_user].plan.length) {

            if (userData[_user].completedStatus[i] == false && userData[_user].roiStatus[i] == false) {

                uint _plan = userData[_user].plan[i];
                uint _level = userData[_user].level[i];

                if (now >= userData[_user].depositTime[i].add(ROI_DURATION)) {

                    uint roiPer;

                    if (users[_user].reInvestCount[_plan][_level] > 0) {
                        roiPer = (10e18 * (_level)).div(2);

                    }
                    else {
                        roiPer = (10e18 * _level);

                    }


                    bal = (userData[_user].depositAmount[i].mul(roiPer)).div(100e18);


                    roiCalc = roiCalc.add(bal);


                }

            }

            i = i + 1;
        }



        return roiCalc;
    }

    function refAmountShare(address _user, uint8 plan, uint8 level) internal {

        if (planPrice[plan][level] <= refAmount[_user][1])
            refAmount[_user][1] = refAmount[_user][1].sub(planPrice[plan][level]);

        else if (planPrice[plan][level] > refAmount[_user][1]) {
            uint refShare1 = refAmount[_user][1];
            uint actualPrice = planPrice[plan][level];
            refAmount[_user][1] = 0;
            actualPrice = actualPrice.sub(refShare1);

            if (actualPrice > 0) {
                if (actualPrice <= refAmount[_user][2])
                    refAmount[_user][2] = refAmount[_user][2].sub(actualPrice);
                else if (actualPrice > refAmount[_user][2]) {
                    uint refShare2 = refAmount[_user][2];
                    uint actualPrice2 = actualPrice;
                    refAmount[_user][2] = 0;
                    actualPrice2 = actualPrice2.sub(refShare2);

                    if (actualPrice2 > 0) {
                        roiAmount[_user] = roiAmount[_user].sub(actualPrice2);
                    }

                }

            }
        }
    }

    /**
    * @dev reInvest : user an reinvest same level
    */
    function reInvest(address _user, uint8 plan, uint8 level)internal {
        require(users[_user].investStatus[plan][level] == true , "not eligible");
        if (users[_user].currentLevel[plan] == 10 ){
            require(level == 10 || level == 1,"Level should be 1 or 10");
        }
        else{
            require(users[_user].currentLevel[plan] <= level,"Wrong level given");
        }
        _planActivation(_user, plan, level, planPrice[plan][level], users[_user].referer);
        users[_user].reInvestCount[plan][level] = users[_user].reInvestCount[plan][level].add(1);

        loopCheck[_user] = 0;
        directRefShare(users[_user].referer, planPrice[plan][level]);
        payUplineShare(users[_user].referer, planPrice[plan][level], plan, level);
        emit reInvestEvent(_user, plan, level, planPrice[plan][level], block.timestamp);
    }



    function payUplineShare(address referrer, uint amount, uint _plan, uint _level) internal {
        address ref = users[referrer].referer;
        if (ref == address(0))
            ref = owner;

        uint previousDepositTime1 = users[ref].previousDepositTime[1];
        uint previousDepositTime2 = users[ref].previousDepositTime[2];

        if ((block.timestamp <= previousDepositTime1.add(ROI_DURATION) || block.timestamp <= previousDepositTime2.add(ROI_DURATION)) || ref == owner) {

            if (loopCheck[msg.sender] < 6) {
                refAmount[ref][1] = refAmount[ref][1].add(amount.mul(levelPercent[loopCheck[msg.sender]]).div(100e18));
                emit refererBouns(msg.sender, ref, _plan, _level, amount.mul(levelPercent[loopCheck[msg.sender]]).div(100e18), loopCheck[msg.sender] + 2, block.timestamp);
                loopCheck[msg.sender]++;
                payUplineShare(ref, amount, _plan, _level);
            }
        }
        else {
            if (loopCheck[msg.sender] < 6) {
                refAmount[ref][2] = refAmount[ref][2].add(amount.mul(levelPercent[loopCheck[msg.sender]]).div(100e18));
                emit refererBouns(msg.sender, ref, _plan, _level, amount.mul(levelPercent[loopCheck[msg.sender]]).div(100e18), loopCheck[msg.sender] + 2, block.timestamp);
                loopCheck[msg.sender]++;
                payUplineShare(ref, amount, _plan, _level);
            }
        }

    }


  /**
   * @dev addCommiteeMembers and admin : Only Admin can add 20 address and 3 address for admin member
   */
    function updateCommiteeadmin(address[] memory _admins, address[] memory _commite)public onlyOwner {
        commitee = _commite;
        ownerList = _admins;
    }



    /**
    * @dev refWithdraw : user can withdraw their referal commision
    */
    function referalWithdraw()public isLock userExist(msg.sender) {
        uint cumulativerefAmount;
        uint previousDepositTime1 = users[msg.sender].previousDepositTime[1];
        uint previousDepositTime2 = users[msg.sender].previousDepositTime[2];

        if ((block.timestamp <= previousDepositTime1.add(ROI_DURATION) || block.timestamp <= previousDepositTime2.add(ROI_DURATION)) || msg.sender == owner) {
            cumulativerefAmount = refAmount[msg.sender][1].add(refAmount[msg.sender][2]);
            require(cumulativerefAmount > 0, "insufficient balance");
            refAmount[msg.sender][1] = 0;
            refAmount[msg.sender][2] = 0;
            require(address(uint160(msg.sender)).send(cumulativerefAmount), "ref withdraw failed");
        }
        else {
            cumulativerefAmount = refAmount[msg.sender][1];
            require(cumulativerefAmount > 0, "insufficient balance");
            refAmount[msg.sender][1] = 0;
            require(address(uint160(msg.sender)).send(cumulativerefAmount), "ref withdraw failed");
        }

    }


    /**
    * @dev viewUser : user can view their details
    */

    function viewUserDetails(address user, uint8 plan, uint8 level)public view returns(address _refererAddress, address[] memory _referralList,
        uint _referralLength, uint _previousDepositTime, uint8 _currentActiveLevel, uint currentid){

        return (users[user].referer, users[user].referals, users[user].referals.length,
            users[user].previousDepositTime[plan], users[user].currentLevel[plan], users[user].currentId);
    }

    /**
    * @dev userDetails : user can view their details by seperate plan
    */

    function viewInvestDetails(address _user, uint8 plan, uint8 level)public view returns(uint[] memory _investedPlans, uint[] memory _investedLevels,
        uint[] memory _depositedTime, uint[] memory _depositedAmount, bool[] memory _activeStatus, bool[] memory _withdrawnStatus, uint reinvestcount){

        _investedPlans = userData[_user].plan;
        _investedLevels = userData[_user].level;
        _depositedTime = userData[_user].depositTime;
        _depositedAmount = userData[_user].depositAmount;
        _activeStatus = userData[_user].activeStatus;
        _withdrawnStatus = userData[_user].completedStatus;

        reinvestcount = users[_user].reInvestCount[plan][level];
    }

    function viewroistatus(address _user, uint8 plan, uint8 level)public view returns(bool[] memory _roistatus, bool status) {
        _roistatus = userData[_user].roiStatus;
        status = users[_user].investStatus[plan][level];
    }
    
    function viewEarn(uint8 _plan,uint8 _level)public view returns(uint){
        require( users[msg.sender].investStatus[_plan][_level] == true,"Not invest");
        uint price = uint(planPrice[_plan][_level]);
        uint amount;
        uint calc = 10e18 *_level;
        if(users[msg.sender].reInvestCount[_plan][_level] == 0 ){
            amount = price.mul(calc).div(100e18);
            return amount;
        }
        else{
            amount = price.mul(calc).div(100e18);
            amount = amount.div(2);
            return amount;
        }
    }

    /**
    * @dev failSafe : For admin purpose
    */
    function failSafe(address payable _toUser, uint _amount) public onlyOwner returns(bool) {
        require(_toUser != address(0), "Invalid Address");
        require(address(this).balance >= _amount, "Insufficient balance");

        (_toUser).transfer(_amount);
        return true;
    }

    function updateLevelPrice(uint8 _plan, uint8 _level, uint _price) public onlyOwner returns(bool) {
        planPrice[_plan][_level] = _price;
        return true;
    }

    function updateROI_duration(uint _duration) public onlyOwner returns(bool) {
        ROI_DURATION = _duration;
    }

    /**
    * @dev contractLock : For admin purpose
    */
    function contractLock(bool _lockStatus) public onlyOwner returns(bool) {
        lockStatus = _lockStatus;
        return true;
    }

    function isContract(address account) public view returns(bool) {
        uint32 size;
        assembly {
            size:= extcodesize(account)
        }
        if (size != 0)
            return true;

        return false;
    }

}