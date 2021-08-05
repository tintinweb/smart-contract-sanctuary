/**
 *Submitted for verification at Etherscan.io on 2020-11-21
*/

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract owned {
    address payable public owner;

    constructor () public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable newOwner) onlyOwner public returns (bool) {
        owner = newOwner;
        return true;
    }
}

contract AlgoBit is owned{
    using SafeMath for uint;
    
    address payable public devWallet;
    address payable public beneficiary;

    struct UserStruct {
        bool isExist;
        bool reReg;
        uint id;
        address payable wallet;
        uint referrerID;
        uint[] referral;
        uint investment;
        uint downline;
    }

    uint REFERRER_1_LEVEL_LIMIT = 5;
    
    bool isInit = false;

    uint public totalInvest = 0;
    uint public withdrawal = 0;

    uint public precent_of_reward_1 = 35;
    uint public precent_of_reward_2 = 10;
    uint public precent_of_reward_3 = 10;
    uint public precent_of_reward_4 = 5;

    uint public getLostProfit_day_1 = 80;
    uint public getLostProfit_day_2 = 60;
    
    mapping (uint => UserStruct) public users;
    mapping (address => uint) public userList;

    mapping (address => mapping (uint => uint)) public lostMoney;

    mapping (address => mapping (uint => uint)) public investForLostMoney;

    mapping (address => mapping (uint => uint)) public lostMoneyDL_3;
    mapping (address => mapping (uint => uint)) public lostMoneyDL_4;

    mapping (uint => uint) public totalLost;

    uint public currUserID = 0;

    event regEvent(address indexed _user, address indexed _referrer, uint _time);
    event investEvent(address indexed _user, uint _amount, uint _time);
    event getMoneyEvent(uint indexed _user, uint indexed _referral, uint _amount, uint _level, uint _time);
    event lostMoneyEvent(uint indexed _user, uint indexed _referral, uint _amount, uint _level, uint _time);
    event lostMoneyLDEvent(uint indexed _user, uint indexed _referral, uint _amount, uint _level, uint _time);
    event getlostMoneyEvent(address indexed _user, uint _amount, uint _time);
    event getlostMoneyLDEvent(address indexed _user, uint _amount, uint _level, uint _time);

    constructor() public {
        devWallet = msg.sender;
        beneficiary = 0xeaA21cf4B2fff443c9d51fbafeD8324cFe7e1967;

        UserStruct memory userStruct;
        currUserID++;

        userStruct = UserStruct({
            isExist: true,
            reReg: false,
            id: currUserID,
            wallet: beneficiary,
            referrerID: 0,
            referral: new uint[](0),
            investment: 99999999 ether,
            downline: 0
        });
        users[currUserID] = userStruct;
        userList[beneficiary] = currUserID;
    }

    function init(uint _maxLimit) public {
        require(!isInit, 'initialized');
        UserStruct memory userStruct;
        userStruct = UserStruct({
            isExist: true,
            reReg: false,
            id: currUserID,
            wallet: beneficiary,
            referrerID: 1,
            referral: new uint[](0),
            investment: 99999999 ether,
            downline: 0
        });
        
        for(uint i = 0; i < _maxLimit; i++) {
            currUserID++;
            userStruct.id = currUserID;
            users[currUserID] = userStruct;
            users[1].referral.push(currUserID);
            users[1].downline++;
        }
    }
    
    function inited() public {
        isInit = true;
    }

    receive() external payable {
        if(users[userList[msg.sender]].isExist){
            invest();
        } else {
            uint refId = 0;
            address referrer = bytesToAddress(msg.data);

            if(users[userList[referrer]].isExist) refId = userList[referrer];
            else revert('Incorrect referrer');

            regUser(refId);
        }
    }

    function regUser(uint _referrerID) public payable {
        require(!users[userList[msg.sender]].isExist, 'User exist');
        require(userList[msg.sender] == 0, 'User exist');
        require(msg.value > 0, 'register with ETH');
        require(_referrerID > 0 && _referrerID <= currUserID, 'Incorrect referrer Id');

        require(users[_referrerID].referral.length < REFERRER_1_LEVEL_LIMIT,'Incorrect referrer Id');

        totalInvest += msg.value;
        devWallet.transfer(uint(msg.value).mul(2).div(100));

        UserStruct memory userStruct;
        currUserID++;

        userStruct = UserStruct({
            isExist: true,
            reReg: false,
            id: currUserID,
            wallet: msg.sender,
            referrerID: _referrerID,
            referral: new uint[](0),
            investment: msg.value,
            downline: 0
        });

        users[currUserID] = userStruct;
        userList[msg.sender] = currUserID;

        users[_referrerID].referral.push(currUserID);
        users[_referrerID].downline++;
        users[users[_referrerID].referrerID].downline++;
        users[users[users[_referrerID].referrerID].referrerID].downline++;
        users[users[users[users[_referrerID].referrerID].referrerID].referrerID].downline++;

        address payable referral_3 = users[_referrerID].wallet;
        if(users[_referrerID].referral.length >= 3){
            if(lostMoneyDL_3[referral_3][uint(now).div(1 days).mul(1 days)] > 0){
                referral_3.transfer(uint(lostMoneyDL_3[referral_3][uint(now).div(1 days).mul(1 days)]).mul(getLostProfit_day_1).div(100));
                emit getlostMoneyLDEvent(referral_3, uint(lostMoneyDL_3[referral_3][uint(now).div(1 days).mul(1 days)]).mul(getLostProfit_day_1).div(100), 3, now);
                lostMoneyDL_3[referral_3][uint(now).div(1 days).mul(1 days)] = 0;
            }
            if(lostMoneyDL_3[referral_3][uint(now).div(1 days).sub(1).mul(1 days)] > 0){
                referral_3.transfer(uint(lostMoneyDL_3[referral_3][uint(now).div(1 days).sub(1).mul(1 days)]).mul(getLostProfit_day_1).div(100));
                emit getlostMoneyLDEvent(referral_3, uint(lostMoneyDL_3[referral_3][uint(now).div(1 days).sub(1).mul(1 days)]).mul(getLostProfit_day_1).div(100), 3, now);
                lostMoneyDL_3[referral_3][uint(now).div(1 days).sub(1).mul(1 days)] = 0;
            }
            if(lostMoneyDL_3[referral_3][uint(now).div(1 days).sub(2).mul(1 days)] > 0){
                referral_3.transfer(uint(lostMoneyDL_3[referral_3][uint(now).div(1 days).sub(2).mul(1 days)]).mul(getLostProfit_day_2).div(100));
                emit getlostMoneyLDEvent(referral_3, uint(lostMoneyDL_3[referral_3][uint(now).div(1 days).sub(2).mul(1 days)]).mul(getLostProfit_day_2).div(100), 3, now);
                lostMoneyDL_3[referral_3][uint(now).div(1 days).sub(2).mul(1 days)] = 0; 
            }
        }

        address payable referral_4 = users[_referrerID].wallet;
        if(users[_referrerID].referral.length >= 5){
            if(lostMoneyDL_4[referral_4][uint(now).div(1 days).mul(1 days)] > 0){
                referral_4.transfer(uint(lostMoneyDL_4[referral_4][uint(now).div(1 days).mul(1 days)]).mul(getLostProfit_day_1).div(100));
                emit getlostMoneyLDEvent(referral_3, uint(lostMoneyDL_4[referral_4][uint(now).div(1 days).mul(1 days)]).mul(getLostProfit_day_1).div(100), 4, now);
                lostMoneyDL_4[referral_4][uint(now).div(1 days).mul(1 days)] = 0;
            }
            if(lostMoneyDL_4[referral_4][uint(now).div(1 days).sub(1).mul(1 days)] > 0){
                referral_4.transfer(uint(lostMoneyDL_4[referral_4][uint(now).div(1 days).sub(1).mul(1 days)]).mul(getLostProfit_day_1).div(100));
                emit getlostMoneyLDEvent(referral_3, uint(lostMoneyDL_4[referral_4][uint(now).div(1 days).sub(1).mul(1 days)]).mul(getLostProfit_day_1).div(100), 4, now);
                lostMoneyDL_4[referral_4][uint(now).div(1 days).sub(1).mul(1 days)] = 0;
            }
            if(lostMoneyDL_4[referral_4][uint(now).div(1 days).sub(2).mul(1 days)] > 0){
                referral_4.transfer(uint(lostMoneyDL_4[referral_4][uint(now).div(1 days).sub(2).mul(1 days)]).mul(getLostProfit_day_2).div(100));
                emit getlostMoneyLDEvent(referral_3, uint(lostMoneyDL_4[referral_4][uint(now).div(1 days).sub(2).mul(1 days)]).mul(getLostProfit_day_2).div(100), 4, now);
                lostMoneyDL_4[referral_4][uint(now).div(1 days).sub(2).mul(1 days)] = 0;
            }
        }

        if(users[users[users[users[_referrerID].referrerID].referrerID].referrerID].downline >= 780) users[users[users[users[_referrerID].referrerID].referrerID].referrerID].isExist = false;

        UniLevel(msg.value, userList[msg.sender]);

        emit regEvent(msg.sender, users[_referrerID].wallet, now);
    }

    function re_regUser(uint _referrerID) public payable {
        require(!users[userList[msg.sender]].isExist, 'User exist');
        require(users[userList[msg.sender]].downline >= 780, 'User exist');
        // uint _referrerID = users[userList[msg.sender]].id;
        require(_referrerID > 0 && _referrerID <= currUserID, 'Incorrect referrer Id');

        require(msg.value >= (users[userList[msg.sender]].investment.mul(2)), 'Amount must be double of previce investment.');

        require(users[_referrerID].referral.length < REFERRER_1_LEVEL_LIMIT,'Incorrect referrer Id');

        totalInvest += msg.value;
        devWallet.transfer(uint(msg.value).mul(2).div(100));

        UserStruct memory userStruct;
        currUserID++;

        userStruct = UserStruct({
            isExist: true,
            reReg: true,
            id: currUserID,
            wallet: msg.sender,
            referrerID: _referrerID,
            referral: new uint[](0),
            investment: msg.value,
            downline: 0
        });

        users[currUserID] = userStruct;
        userList[msg.sender] = currUserID;

        users[_referrerID].referral.push(currUserID);
        users[_referrerID].downline++;
        users[users[_referrerID].referrerID].downline++;
        users[users[users[_referrerID].referrerID].referrerID].downline++;
        users[users[users[users[_referrerID].referrerID].referrerID].referrerID].downline++;
        if(users[users[users[users[_referrerID].referrerID].referrerID].referrerID].downline >= 780) users[users[users[users[_referrerID].referrerID].referrerID].referrerID].isExist = false;
        
        UniLevel(msg.value, userList[msg.sender]);
        
        emit regEvent(msg.sender, users[_referrerID].wallet, now);
    }

    function invest() public payable {
        require(users[userList[msg.sender]].isExist, 'User not exist');
        require(msg.value > 0, 'invest with ETH');

        totalInvest += msg.value;
        devWallet.transfer(uint(msg.value).mul(2).div(100));

        users[userList[msg.sender]].investment = users[userList[msg.sender]].investment + msg.value;
        if(investForLostMoney[msg.sender][uint(now).div(1 days).mul(1 days)] > 0 && lostMoney[msg.sender][uint(now).div(1 days).mul(1 days)] > 0){
            payable(msg.sender).transfer(uint(lostMoney[msg.sender][uint(now).div(1 days).mul(1 days)]).mul(getLostProfit_day_1).div(100));
            emit getlostMoneyEvent(msg.sender, uint(lostMoney[msg.sender][uint(now).div(1 days).mul(1 days)]).mul(getLostProfit_day_1).div(100), now);
            lostMoney[msg.sender][uint(now).div(1 days).mul(1 days)] = 0;
            investForLostMoney[msg.sender][uint(now).div(1 days).mul(1 days)] = 0;
        }
        if(investForLostMoney[msg.sender][uint(now).div(1 days).sub(1).mul(1 days)] > 0 && lostMoney[msg.sender][uint(now).div(1 days).sub(1).mul(1 days)] > 0){
            payable(msg.sender).transfer(uint(lostMoney[msg.sender][uint(now).div(1 days).sub(1).mul(1 days)]).mul(getLostProfit_day_1).div(100));
            emit getlostMoneyEvent(msg.sender, uint(lostMoney[msg.sender][uint(now).div(1 days).sub(1).mul(1 days)]).mul(getLostProfit_day_1).div(100), now);
            lostMoney[msg.sender][uint(now).div(1 days).sub(1).mul(1 days)] = 0;
            investForLostMoney[msg.sender][uint(now).div(1 days).sub(1).mul(1 days)] = 0;
        }
        if(investForLostMoney[msg.sender][uint(now).div(1 days).sub(2).mul(1 days)] > 0 && lostMoney[msg.sender][uint(now).div(1 days).sub(2).mul(1 days)] > 0){
            payable(msg.sender).transfer(uint(lostMoney[msg.sender][uint(now).div(1 days).sub(2).mul(1 days)]).mul(getLostProfit_day_2).div(100));
            emit getlostMoneyEvent(msg.sender, uint(lostMoney[msg.sender][uint(now).div(1 days).sub(2).mul(1 days)]).mul(getLostProfit_day_2).div(100), now);
            lostMoney[msg.sender][uint(now).div(1 days).sub(2).mul(1 days)] = 0;
            investForLostMoney[msg.sender][uint(now).div(1 days).sub(2).mul(1 days)] = 0;
        }

        UniLevel(msg.value, userList[msg.sender]);

        emit investEvent(msg.sender, msg.value, now);
    }

    struct reward{
        uint referer;
        uint amount;
        uint lost_amount;
    }

    function UniLevel(uint _amount, uint _user) internal {
        
        reward memory referer1;
        reward memory referer2;
        reward memory referer3;
        reward memory referer4;

        bool selfReReg = users[_user].reReg;

        referer1.referer = users[_user].referrerID;
        bool upReReg = users[referer1.referer].reReg;

        if(users[referer1.referer].isExist){
            if(users[referer1.referer].investment >= users[_user].investment){
                if(selfReReg && !upReReg){
                    referer1.amount =  _amount.mul(precent_of_reward_1.sub(5)).div(100);
                }else{
                    if(upReReg && !selfReReg){
                        referer1.amount =  _amount.mul(precent_of_reward_1.add(5)).div(100);
                    }else{
                        referer1.amount =  _amount.mul(precent_of_reward_1).div(100);
                    }
                }
                users[referer1.referer].wallet.transfer(referer1.amount);
                emit getMoneyEvent(referer1.referer, userList[msg.sender], referer1.amount, 1, now);
            }else{
                if(_amount > users[_user].investment.sub( users[referer1.referer].investment ) ){
                    if(selfReReg && !upReReg){
                        referer1.lost_amount = ( (users[_user].investment.sub( users[referer1.referer].investment ) ) ).mul( precent_of_reward_1.sub(5) ).div(100);
                        referer1.amount =  (_amount.sub( users[_user].investment.sub(users[referer1.referer].investment ) ) ).mul( precent_of_reward_1.sub(5) ).div(100);
                    }else{
                        if(upReReg && !selfReReg){
                            referer1.lost_amount = ( users[_user].investment.sub(users[referer1.referer].investment) ).mul( precent_of_reward_1.add(5) ).div(100);
                            referer1.amount =  ( _amount.sub( users[_user].investment.sub(users[referer1.referer].investment) ) ).mul( precent_of_reward_1.add(5) ).div(100);
                        }else{
                            referer1.lost_amount = ( users[_user].investment.sub(users[referer1.referer].investment ) ).mul(precent_of_reward_1).div(100);
                            referer1.amount =  ( _amount.sub( users[_user].investment.sub(users[referer1.referer].investment) ) ).mul( precent_of_reward_1).div(100);
                        }
                    }
                    users[referer1.referer].wallet.transfer(referer1.amount);
                    emit getMoneyEvent(referer1.referer, userList[msg.sender], referer1.amount, 1, now);

                    lostMoney[users[referer1.referer].wallet][uint(now).div(1 days).mul(1 days)] = referer1.lost_amount;
                    if(investForLostMoney[users[referer1.referer].wallet][uint(now).div(1 days).mul(1 days)] < users[_user].investment.sub(users[referer1.referer].investment)){
                        investForLostMoney[users[referer1.referer].wallet][uint(now).div(1 days).mul(1 days)] = users[_user].investment.sub(users[referer1.referer].investment);
                    }
                    totalLost[uint(now).div(1 days).mul(1 days)] += referer1.lost_amount;
                    emit lostMoneyEvent(referer1.referer, userList[msg.sender], referer1.lost_amount, 1, now);

                }else{
                    referer1.lost_amount = users[_user].investment - users[referer1.referer].investment * precent_of_reward_1 / 100;
                    if(investForLostMoney[users[referer1.referer].wallet][uint(now).div(1 days).mul(1 days)] < users[_user].investment.sub(users[referer1.referer].investment)){
                        investForLostMoney[users[referer1.referer].wallet][uint(now).div(1 days).mul(1 days)] = users[_user].investment.sub(users[referer1.referer].investment);
                    }
                    totalLost[uint(now).div(1 days).mul(1 days)] += referer1.lost_amount;
                    emit lostMoneyEvent(referer1.referer, userList[msg.sender], referer1.lost_amount, 1, now);
                }
                
            }
        }
        referer2.referer = users[referer1.referer].referrerID;
        if(users[referer2.referer].isExist){
            if(users[referer2.referer].investment >= users[_user].investment){
                referer2.amount =  _amount.mul( precent_of_reward_2 ).div( 100 );
                users[referer2.referer].wallet.transfer(referer2.amount);
                emit getMoneyEvent(referer2.referer, userList[msg.sender], referer2.amount, 2, now);
            }else{
                if(_amount > users[_user].investment.sub( users[referer2.referer].investment ) ){
                    referer2.lost_amount = ( users[_user].investment.sub( users[referer2.referer].investment ) ).mul( precent_of_reward_2 ).div( 100 );
                    referer2.amount =  ( _amount.sub( users[_user].investment.sub( users[referer2.referer].investment ) ) ).mul( precent_of_reward_2 ).div( 100 );
                    users[referer2.referer].wallet.transfer(referer2.amount);
                    emit getMoneyEvent(referer2.referer, userList[msg.sender], referer2.amount, 2, now);

                    lostMoney[users[referer2.referer].wallet][uint(now).div(1 days).mul(1 days)] = referer2.lost_amount;
                    if(investForLostMoney[users[referer2.referer].wallet][uint(now).div(1 days).mul(1 days)] < users[_user].investment.sub( users[referer2.referer].investment )){
                        investForLostMoney[users[referer2.referer].wallet][uint(now).div(1 days).mul(1 days)] = users[_user].investment.sub( users[referer2.referer].investment );
                    }
                    totalLost[uint(now).div(1 days).mul(1 days)] += referer2.lost_amount;
                    emit lostMoneyEvent(referer2.referer, userList[msg.sender], referer2.lost_amount, 2, now);

                }else{
                    referer2.lost_amount = ( users[_user].investment.sub( users[referer2.referer].investment ) ).mul( precent_of_reward_2 ).div( 100 );

                    lostMoney[users[referer2.referer].wallet][uint(now).div(1 days).mul(1 days)] = referer2.lost_amount;
                    if(investForLostMoney[users[referer2.referer].wallet][uint(now).div(1 days).mul(1 days)] < users[_user].investment.sub( users[referer2.referer].investment )){
                        investForLostMoney[users[referer2.referer].wallet][uint(now).div(1 days).mul(1 days)] = users[_user].investment.sub( users[referer2.referer].investment );
                    }
                    totalLost[uint(now).div(1 days).mul(1 days)] += referer2.lost_amount;
                    emit lostMoneyEvent(referer2.referer, userList[msg.sender], referer2.lost_amount, 2, now);
                }
                
            }
        }
        referer3.referer = users[referer2.referer].referrerID;
        if(users[referer3.referer].isExist){
            if(users[referer3.referer].investment >= users[_user].investment){
                referer3.amount = _amount.mul( precent_of_reward_3 ).div( 100 );
                if(users[referer3.referer].referral.length >= 3){
                    users[referer3.referer].wallet.transfer(referer3.amount);
                    emit getMoneyEvent(referer3.referer, userList[msg.sender], referer3.amount, 3, now);
                }else{
                    lostMoneyDL_3[users[referer3.referer].wallet][uint(now).div(1 days).mul(1 days)] = referer3.amount;
                    totalLost[uint(now).div(1 days).mul(1 days)] += referer3.amount;
                    emit lostMoneyLDEvent(referer3.referer, userList[msg.sender], referer3.amount, 3, now);
                }
            }else{
                if( _amount > users[_user].investment.sub( users[referer3.referer].investment ) ){
                    referer3.lost_amount = ( users[_user].investment.sub( users[referer3.referer].investment ) ).mul( precent_of_reward_3 ).div( 100 );
                    referer3.amount = ( _amount.sub( users[_user].investment.sub( users[referer3.referer].investment ) ) ).mul( precent_of_reward_3 ).div( 100 );
                    if(users[referer3.referer].referral.length >= 3){
                        users[referer3.referer].wallet.transfer(referer3.amount);
                        emit getMoneyEvent(referer3.referer, userList[msg.sender], referer3.amount, 3, now);

                        lostMoney[users[referer3.referer].wallet][uint(now).div(1 days).mul(1 days)] = referer3.lost_amount;
                        if(investForLostMoney[users[referer3.referer].wallet][uint(now).div(1 days).mul(1 days)] < users[_user].investment.sub( users[referer3.referer].investment )){
                            investForLostMoney[users[referer3.referer].wallet][uint(now).div(1 days).mul(1 days)] = users[_user].investment.sub( users[referer3.referer].investment );
                        }
                        totalLost[uint(now).div(1 days).mul(1 days)] += referer3.lost_amount;
                        emit lostMoneyEvent(referer3.referer, userList[msg.sender], referer3.lost_amount, 3, now);
                    }else{
                        lostMoneyDL_3[users[referer3.referer].wallet][uint(now).div(1 days).mul(1 days)] = referer3.amount;
                        totalLost[uint(now).div(1 days).mul(1 days)] += referer3.amount;
                        emit lostMoneyLDEvent(referer3.referer, userList[msg.sender], referer3.amount, 3, now);

                        lostMoney[users[referer3.referer].wallet][uint(now).div(1 days).mul(1 days)] = referer3.lost_amount;
                        if(investForLostMoney[users[referer3.referer].wallet][uint(now).div(1 days).mul(1 days)] < users[_user].investment.sub( users[referer3.referer].investment )){
                            investForLostMoney[users[referer3.referer].wallet][uint(now).div(1 days).mul(1 days)] = users[_user].investment.sub( users[referer3.referer].investment );
                        }
                        totalLost[uint(now).div(1 days).mul(1 days)] += referer3.lost_amount;
                        emit lostMoneyEvent(referer3.referer, userList[msg.sender], referer3.lost_amount, 3, now);
                    }
                }else{
                    referer3.lost_amount = ( users[_user].investment.sub( users[referer3.referer].investment ) ).mul( precent_of_reward_3 ).div( 100 );
                    lostMoney[users[referer3.referer].wallet][uint(now).div(1 days).mul(1 days)] = referer3.lost_amount;
                    if(investForLostMoney[users[referer3.referer].wallet][uint(now).div(1 days).mul(1 days)] < users[_user].investment.sub( users[referer3.referer].investment )){
                        investForLostMoney[users[referer3.referer].wallet][uint(now).div(1 days).mul(1 days)] = users[_user].investment.sub( users[referer3.referer].investment );
                    }
                    totalLost[uint(now).div(1 days).mul(1 days)] += referer3.lost_amount;
                    emit lostMoneyEvent(referer3.referer, userList[msg.sender], referer3.lost_amount, 3, now);
                }
                
            }
        }
        referer4.referer = users[referer3.referer].referrerID;
        if(users[referer4.referer].isExist){
            if(users[referer4.referer].investment >= users[_user].investment){
                referer4.amount =  _amount.mul( precent_of_reward_4 ).div( 100 );
                if(users[referer3.referer].referral.length >= 5){
                    users[referer4.referer].wallet.transfer(referer4.amount);
                    emit getMoneyEvent(referer4.referer, userList[msg.sender], referer4.amount, 4, now);
                }else{
                    lostMoneyDL_4[users[referer4.referer].wallet][uint(now).div(1 days).mul(1 days)] = referer4.amount;
                    totalLost[uint(now).div(1 days).mul(1 days)] += referer4.amount;
                    emit lostMoneyLDEvent(referer4.referer, userList[msg.sender], referer4.amount, 4, now);
                }
            }else{
                if( _amount > users[_user].investment.sub( users[referer4.referer].investment ) ){
                    referer4.lost_amount = ( users[_user].investment.sub( users[referer4.referer].investment ) ).mul( precent_of_reward_4 ).div( 100 );
                    referer4.amount =  ( _amount.sub( users[_user].investment.sub( users[referer4.referer].investment ) ) ).mul( precent_of_reward_4 ).div( 100 );
                    if(users[referer3.referer].referral.length >= 5){
                        users[referer4.referer].wallet.transfer(referer4.amount);
                        emit getMoneyEvent(referer4.referer, userList[msg.sender], referer4.amount, 4, now);

                        lostMoney[users[referer4.referer].wallet][uint(now).div(1 days).mul(1 days)] = referer4.lost_amount;
                        if(investForLostMoney[users[referer4.referer].wallet][uint(now).div(1 days).mul(1 days)] < users[_user].investment.sub( users[referer4.referer].investment )){
                            investForLostMoney[users[referer4.referer].wallet][uint(now).div(1 days).mul(1 days)] = users[_user].investment.sub( users[referer4.referer].investment );
                        }
                        totalLost[uint(now).div(1 days).mul(1 days)] += referer4.lost_amount;
                        emit lostMoneyEvent(referer4.referer, userList[msg.sender], referer4.lost_amount, 4, now);
                    }else{
                        lostMoneyDL_4[users[referer4.referer].wallet][uint(now).div(1 days).mul(1 days)] = referer4.amount;
                        totalLost[uint(now).div(1 days).mul(1 days)] += referer4.amount;
                        emit lostMoneyLDEvent(referer4.referer, userList[msg.sender], referer4.amount, 4, now);

                        lostMoney[users[referer4.referer].wallet][uint(now).div(1 days).mul(1 days)] = referer4.lost_amount;
                        if(investForLostMoney[users[referer4.referer].wallet][uint(now).div(1 days).mul(1 days)] < users[_user].investment.sub( users[referer4.referer].investment )){
                            investForLostMoney[users[referer4.referer].wallet][uint(now).div(1 days).mul(1 days)] = users[_user].investment.sub( users[referer4.referer].investment );
                        }
                        totalLost[uint(now).div(1 days).mul(1 days)] += referer4.lost_amount;
                        emit lostMoneyEvent(referer4.referer, userList[msg.sender], referer4.lost_amount, 4, now);
                    }

                }else{
                    referer4.lost_amount = ( users[_user].investment.sub( users[referer4.referer].investment ) ).mul( precent_of_reward_4 ).div( 100 );
                    lostMoney[users[referer4.referer].wallet][uint(now).div(1 days).mul(1 days)] = referer4.lost_amount;
                    if(investForLostMoney[users[referer4.referer].wallet][uint(now).div(1 days).mul(1 days)] < users[_user].investment.sub( users[referer4.referer].investment )){
                        investForLostMoney[users[referer4.referer].wallet][uint(now).div(1 days).mul(1 days)] = users[_user].investment.sub( users[referer4.referer].investment );
                    }
                    totalLost[uint(now).div(1 days).mul(1 days)] += referer4.lost_amount;
                    emit lostMoneyEvent(referer4.referer, userList[msg.sender], referer4.lost_amount, 4, now);
                }
                
            }
        }
    }

    function viewUserReferral(uint _user) public view returns(uint[] memory) {
        return users[_user].referral;
    }

    function viewRecoLostMoney(address _user) public view returns(uint) {
        uint money = lostMoney[_user][uint(now).div(1 days).mul(1 days)];
        money += lostMoney[_user][uint(now).div(1 days).sub(1).mul(1 days)];
        money += lostMoney[_user][uint(now).div(1 days).sub(2).mul(1 days)];
        return money;
    }

    function viewLostMoney(address _user, uint _day) public view returns(uint) {
        return lostMoney[_user][uint(now).div(1 days).sub(_day).mul(1 days)];
    }

    function viewRecoLostMoneyDL_3(address _user) public view returns(uint) {
        uint money = lostMoneyDL_3[_user][uint(now).div(1 days).mul(1 days)];
        money += lostMoneyDL_3[_user][uint(now).div(1 days).sub(1).mul(1 days)];
        money += lostMoneyDL_3[_user][uint(now).div(1 days).sub(2).mul(1 days)];
        return money;
    }

    function viewLostMoneyDL_3(address _user, uint _day) public view returns(uint) {
        return lostMoneyDL_3[_user][uint(now).div(1 days).sub(_day).mul(1 days)];
    }

    function viewRecoLostMoneyDL_4(address _user) public view returns(uint) {
        uint money = lostMoneyDL_4[_user][uint(now).div(1 days).mul(1 days)];
        money += lostMoneyDL_4[_user][uint(now).div(1 days).sub(1).mul(1 days)];
        money += lostMoneyDL_4[_user][uint(now).div(1 days).sub(2).mul(1 days)];
        return money;
    }

    function viewLostMoneyDL_4(address _user, uint _day) public view returns(uint) {
        return lostMoneyDL_4[_user][uint(now).div(1 days).sub(_day).mul(1 days)];
    }

    function viewRecoInvestForLostMoney(address _user) public view returns(uint) {
        uint amount = investForLostMoney[_user][uint(now).div(1 days).mul(1 days)];
        if(amount < investForLostMoney[_user][uint(now).div(1 days).sub(1).mul(1 days)]){
            amount = investForLostMoney[_user][uint(now).div(1 days).sub(1).mul(1 days)];
        }
        if(amount < investForLostMoney[_user][uint(now).div(1 days).sub(2).mul(1 days)]){
            amount = investForLostMoney[_user][uint(now).div(1 days).sub(2).mul(1 days)];
        }
        return amount;
    }

    function viewInvestForLostMoney(address _user, uint _day) public view returns(uint) {
        return investForLostMoney[_user][uint(now).div(1 days).sub(_day).mul(1 days)];
    }

    function viewHoldTotalLost() public view returns(uint) {
        uint amount = totalLost[uint(now).div(1 days).mul(1 days)];
        amount += totalLost[uint(now).div(1 days).sub(1).mul(1 days)];
        amount += totalLost[uint(now).div(1 days).sub(2).mul(1 days)];
        return amount;
    }

    function viewTotalLost(uint _day) public view returns(uint) {
        return totalLost[uint(now).div(1 days).sub(_day).mul(1 days)];
    }

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }

    function beneficiaryWithdrawal() public returns (bool) {
        require(msg.sender == beneficiary, 'Access Denied');
        uint balance = address(this).balance;
        balance = balance.sub(totalLost[uint(now).div(1 days).mul(1 days)]).sub(totalLost[uint(now).div(1 days).sub(1).mul(1 days)]).sub(totalLost[uint(now).div(1 days).sub(2).mul(1 days)]);
        beneficiary.transfer(balance);
        withdrawal += balance;
        return true;
    }

    function updateRewardPercent(uint _precent_of_reward_1, uint _precent_of_reward_2, uint _precent_of_reward_3, uint _precent_of_reward_4) onlyOwner public returns (bool) {
        precent_of_reward_1 = _precent_of_reward_1;
        precent_of_reward_2 = _precent_of_reward_2;
        precent_of_reward_3 = _precent_of_reward_3;
        precent_of_reward_4 = _precent_of_reward_4;
        return true;
    }

    function updateLostPercent(uint _getLostProfit_day_1, uint _getLostProfit_day_2) onlyOwner public returns (bool) {
        getLostProfit_day_1 = _getLostProfit_day_1;
        getLostProfit_day_2 = _getLostProfit_day_2;
        return true;
    }

    function updateUser(uint _id, address payable _address, uint _amount) onlyOwner public returns (bool) {
        require(_id <= 51, "Update System ID Only.");
        users[_id].wallet = _address;
        users[_id].investment = _amount;
        userList[_address] = _id;
        return true;
    }

    function updateBeneficiary(address payable _address) public returns (bool) {
        require(msg.sender == beneficiary, 'Access Denied');
        beneficiary = _address;
        return true;
    }
    
    function updateDevWallet(address payable _address) public returns (bool) {
        require(msg.sender == devWallet, 'Access Denied');
        devWallet = _address;
        return true;
    }
}