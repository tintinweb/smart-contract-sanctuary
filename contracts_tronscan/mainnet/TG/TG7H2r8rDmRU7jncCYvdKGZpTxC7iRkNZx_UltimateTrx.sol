//SourceUnit: new_ultimate_finally.sol

/**
 *Submitted for verification at Etherscan.io on 2020-05-28
*/

pragma solidity 0.5.10;


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
     *
     * NOTE: This is a feature of the next version of OpenZeppelin Contracts.
     * @dev Get it via `npm install @openzeppelin/contracts@next`.
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
     * NOTE: This is a feature of the next version of OpenZeppelin Contracts.
     * @dev Get it via `npm install @openzeppelin/contracts@next`.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

contract UltimateTrx {
    
    using SafeMath for *;
    
    address public ownerWallet;
    address public wallet1; //5%
    address public wallet2; //15%


    
   struct UserStruct {
        bool isExist;
        uint id;
        uint referrerID;
        address[] referral;
        uint directSponsor;
        uint referralCounter;
        uint holdamount;
        mapping(uint => uint) levelExpired;
    }

    uint REFERRER_1_LEVEL_LIMIT = 2;
    uint PERIOD_LENGTH = 180 days;
    uint private adminFees = 5;
    uint private directSponsorFees = 15;
    uint private earnings =80;

    mapping(uint => uint) public LEVEL_PRICE;
    
    mapping(uint => uint) public HOLD_LEVEL_PRICE;

    mapping (address => UserStruct) public users;
    mapping (uint => address) public userList;
    uint public currUserID = 0;

    event regLevelEvent(address indexed _user, address indexed _referrer, uint _time);
    event buyLevelEvent(address indexed _user, uint _level, uint _time);
    event getMoneyForLevelEvent(address indexed _user, address indexed _referral, uint _level, uint _time);
    event getSponsorBonusEvent(address indexed _sponsor, address indexed _user, uint _level, uint _time);
    event lostMoneyForLevelEvent(address indexed _user, address indexed _referral, uint _level, uint _time, uint number);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address _owner, address _wallet1, address _wallet2) public {
        ownerWallet = msg.sender;
        wallet1 = _wallet1;
        wallet2 = _wallet2;

        LEVEL_PRICE[1] = 500 trx;
        LEVEL_PRICE[2] = 1000 trx;
        LEVEL_PRICE[3] = 2000 trx;
        LEVEL_PRICE[4] = 7500 trx;
        LEVEL_PRICE[5] = 50000 trx;
        LEVEL_PRICE[6] = 500000 trx;
        LEVEL_PRICE[7] = 1000000 trx;
        LEVEL_PRICE[8] = 1500000 trx;
        LEVEL_PRICE[9] = 4000000 trx;
        LEVEL_PRICE[10] = 10000000 trx;
        LEVEL_PRICE[11] = 25000000 trx;
        LEVEL_PRICE[12] = 50000000 trx;
        
        HOLD_LEVEL_PRICE[2] = 666.7 trx;
        HOLD_LEVEL_PRICE[3] = 1500 trx;
        HOLD_LEVEL_PRICE[4] = 5000 trx;
        HOLD_LEVEL_PRICE[5] = 35715 trx;
        HOLD_LEVEL_PRICE[6] = 250000 trx;
        HOLD_LEVEL_PRICE[7] = 750000 trx;
        HOLD_LEVEL_PRICE[8] = 1000000 trx;
        HOLD_LEVEL_PRICE[9] = 2000000 trx;
        HOLD_LEVEL_PRICE[10] = 5000000 trx;
        HOLD_LEVEL_PRICE[11] = 10000000 trx;
        HOLD_LEVEL_PRICE[12] = 0 trx;
      //  HOLD_LEVEL_PRICE[12] = 1000 trx;

        UserStruct memory userStruct;
        currUserID++;

        userStruct = UserStruct({
            isExist: true,
            id: currUserID,
            referrerID: 0,
            referral: new address[](0),
            directSponsor: 0,
            referralCounter: 0,
            holdamount : 0
        });
        users[_owner] = userStruct;
        userList[currUserID] = _owner;

        for(uint i = 1; i <= 12; i++) {
            users[_owner].levelExpired[i] = 55555555555;
        }
    }

    function () external payable {
        uint level;

        if(msg.value == LEVEL_PRICE[1]) level = 1;
        else if(msg.value == LEVEL_PRICE[2]) level = 2;
        else if(msg.value == LEVEL_PRICE[3]) level = 3;
        else if(msg.value == LEVEL_PRICE[4]) level = 4;
        else if(msg.value == LEVEL_PRICE[5]) level = 5;
        else if(msg.value == LEVEL_PRICE[6]) level = 6;
        else if(msg.value == LEVEL_PRICE[7]) level = 7;
        else if(msg.value == LEVEL_PRICE[8]) level = 8;
        else if(msg.value == LEVEL_PRICE[9]) level = 9;
        else if(msg.value == LEVEL_PRICE[10]) level = 10;
        else if(msg.value == LEVEL_PRICE[11]) level = 11;
        else if(msg.value == LEVEL_PRICE[12]) level = 12;
        
        else revert('Incorrect Value send');

        if(users[msg.sender].isExist) buyLevel(level,msg.sender);
        else if(level == 1) {
            uint refId = 0;
            address referrer = bytesToAddress(msg.data);

            if(users[referrer].isExist) refId = users[referrer].id;
            else revert('Incorrect referrer');

            regUser(refId);
        }
        else revert('Please buy first level for 0.03 TRX');
    }

    function regUser(uint _referrerID) public payable {
       
        require(!users[msg.sender].isExist, 'User exist');
        require(_referrerID > 0 && _referrerID <= currUserID, 'Incorrect referrer Id');
        require(msg.value == LEVEL_PRICE[1]+LEVEL_PRICE[2], 'Incorrect Value RU');

        uint tempReferrerID = _referrerID;

        if(users[userList[_referrerID]].referral.length >= REFERRER_1_LEVEL_LIMIT) 
            _referrerID = users[findFreeReferrer(userList[_referrerID])].id;

        UserStruct memory userStruct;
        currUserID++;

        userStruct = UserStruct({
            isExist: true,
            id: currUserID,
            referrerID: _referrerID,
            referral: new address[](0),
            directSponsor: tempReferrerID,
            referralCounter: 0,
            holdamount : 0
        });

        users[msg.sender] = userStruct;
        userList[currUserID] = msg.sender;

        users[msg.sender].levelExpired[1] = now + PERIOD_LENGTH;
         users[msg.sender].levelExpired[2] = now + PERIOD_LENGTH;

        users[userList[_referrerID]].referral.push(msg.sender);

        payForLevel(1, msg.sender,userList[_referrerID]);
        
        payForLevel(2, msg.sender, userList[users[msg.sender].directSponsor]);

        emit buyLevelEvent(msg.sender, 2, now);
        //payForLevel(2, msg.sender,userList[users[userList[_referrerID]].referrerID]);
        
        //increase the referral counter;
        users[userList[tempReferrerID]].referralCounter++;

        emit regLevelEvent(msg.sender, userList[tempReferrerID], now);
    }
    
    function regAdmins(address [] memory _adminAddress) public  {
        
        require(msg.sender == ownerWallet,"You are not authorized");
        require(currUserID <= 8, "No more admins can be registered");
        
        UserStruct memory userStruct;
        
        for(uint i = 0; i < _adminAddress.length; i++){
            
            currUserID++;

            uint _referrerID = 1;
            uint tempReferrerID = _referrerID;
    
            if(users[userList[_referrerID]].referral.length >= REFERRER_1_LEVEL_LIMIT) 
                _referrerID = users[findFreeReferrer(userList[_referrerID])].id;
    
            userStruct = UserStruct({
                isExist: true,
                id: currUserID,
                referrerID: _referrerID,
                referral: new address[](0),
                directSponsor: tempReferrerID,
                referralCounter: 0,
                holdamount : 0
            });
    
            users[_adminAddress[i]] = userStruct;
            userList[currUserID] = _adminAddress[i];
            
            for(uint j = 1; j <= 12; j++) {
                users[_adminAddress[i]].levelExpired[j] = 55555555555;
            }
    
            users[userList[_referrerID]].referral.push(_adminAddress[i]);
    
            //increase the referral counter;
            users[userList[tempReferrerID]].referralCounter++;
    
            emit regLevelEvent(msg.sender, userList[tempReferrerID], now);
        }
    }
    
    

    function buyLevel(uint _level,address _user) public payable {
        require(users[_user].isExist, 'User not exist'); 
        require(_level > 0 && _level <= 12, 'Incorrect level');

        if(_level == 1) {
            require(users[_user].holdamount >= LEVEL_PRICE[1], 'Incorrect Value bu');
            users[_user].levelExpired[1] += PERIOD_LENGTH;
        }
        else {
            require(users[_user].holdamount >= LEVEL_PRICE[_level], 'Incorrect Value be');

            for(uint l =_level - 1; l > 0; l--) require(users[_user].levelExpired[l] >= now, 'Buy the previous level');

            if(users[_user].levelExpired[_level] == 0) users[_user].levelExpired[_level] = now + PERIOD_LENGTH;
            else users[_user].levelExpired[_level] += PERIOD_LENGTH;
        }

        payForLevel(_level, _user, userList[users[_user].directSponsor]);

        emit buyLevelEvent(_user, _level, now);
    }
    
   
    function payForLevel(uint _level, address _user, address _sponsor) internal {
        address actualReferer;
        address referer1;
        address referer2;
        

        if(_level == 1)
            actualReferer = userList[users[_user].directSponsor];
        
        else if(_level == 7) {
            actualReferer = userList[users[_user].referrerID];
        }
        else if(_level == 2 || _level == 8) {
            referer1 = userList[users[_user].referrerID];
            actualReferer = userList[users[referer1].referrerID];
        }
        else if(_level == 3 || _level == 9) {
            referer1 = userList[users[_user].referrerID];
            referer2 = userList[users[referer1].referrerID];
            actualReferer = userList[users[referer2].referrerID];
        }
        else if(_level == 4 || _level == 10) {
            referer1 = userList[users[_user].referrerID];
            referer2 = userList[users[referer1].referrerID];
            referer1 = userList[users[referer2].referrerID];
            actualReferer = userList[users[referer1].referrerID];
        }
        else if(_level == 5 || _level == 11) {
            referer1 = userList[users[_user].referrerID];
            referer2 = userList[users[referer1].referrerID];
            referer1 = userList[users[referer2].referrerID];
            referer2 = userList[users[referer1].referrerID];
            actualReferer = userList[users[referer2].referrerID];
        }
        else if(_level == 6 || _level == 12) {
            referer1 = userList[users[_user].referrerID];
            referer2 = userList[users[referer1].referrerID];
            referer1 = userList[users[referer2].referrerID];
            referer2 = userList[users[referer1].referrerID];
            referer1 = userList[users[referer2].referrerID];
            actualReferer = userList[users[referer1].referrerID];
        }

        if(!users[actualReferer].isExist) actualReferer = userList[1];

        bool sent = false;
        
        if(_level == 1) {
            if(users[actualReferer].levelExpired[_level] >= now) {
                sent = address(uint160(actualReferer)).send(LEVEL_PRICE[_level]);
                if (sent) {
                    emit getSponsorBonusEvent(actualReferer, msg.sender, _level, now);
                }
            }
            else {
                address(uint160(wallet2)).transfer(LEVEL_PRICE[_level]);
                emit lostMoneyForLevelEvent(actualReferer, msg.sender, _level, now,1);
            }
        }
        else {
            if(users[actualReferer].levelExpired[_level] >= now) {
                
                if(users[actualReferer].levelExpired[_level+1] >= now)
                sent = address(uint160(actualReferer)).send(LEVEL_PRICE[_level].mul(earnings).div(100)); //  80% for level income
                else
                {
                    uint tot_amt=LEVEL_PRICE[_level].mul(earnings).div(100);
                    uint hold=HOLD_LEVEL_PRICE[_level];
                    users[actualReferer].holdamount=users[actualReferer].holdamount.add(hold);
                    uint left_amt=tot_amt-hold;
                    sent = address(uint160(actualReferer)).send(left_amt); //  80% for level income
                    uint tot_hold_amt=users[actualReferer].holdamount;
                    if(tot_hold_amt>=LEVEL_PRICE[_level+1])
                    {
                       buyLevel(_level+1,actualReferer) ;
                    }
                }

                if (sent) {
                    
                    //if(users[_sponsor].levelExpired[_level] >= now) {
                        address(uint160(_sponsor)).transfer(LEVEL_PRICE [_level].mul(directSponsorFees).div(100)); // direct income on level purchase
                        emit getSponsorBonusEvent(_sponsor, msg.sender, _level, now);
                    //}
                    // else{
                    //     address(uint160(wallet2)).transfer(LEVEL_PRICE [_level].mul(directSponsorFees).div(100));// direct income to admin on level purchase
                    //     emit lostMoneyForLevelEvent(_sponsor, msg.sender, _level, now, 1);
                    // }   
                    address(uint160(wallet1)).transfer(LEVEL_PRICE[_level].mul(adminFees).div(100)); // admin fee
                    emit getMoneyForLevelEvent(actualReferer, msg.sender, _level, now);
                    
                }
            }
            
            if(!sent) {
                emit lostMoneyForLevelEvent(actualReferer, msg.sender, _level, now, 2);
    
                payForLevel(_level, actualReferer, _sponsor);
            }
        }
    }

    function findFreeReferrer(address _user) public view returns(address) {
        if(users[_user].referral.length < REFERRER_1_LEVEL_LIMIT) return _user;

        address[] memory referrals = new address[](1022);
        referrals[0] = users[_user].referral[0];
        referrals[1] = users[_user].referral[1];

        address freeReferrer;
        bool noFreeReferrer = true;

        for(uint i = 0; i < 1022; i++) {
            if(users[referrals[i]].referral.length == REFERRER_1_LEVEL_LIMIT) {
                if(i < 62) {
                    referrals[(i+1)*2] = users[referrals[i]].referral[0];
                    referrals[(i+1)*2+1] = users[referrals[i]].referral[1];
                }
            }
            else {
                noFreeReferrer = false;
                freeReferrer = referrals[i];
                break;
            }
        }

        require(!noFreeReferrer, 'No Free Referrer');

        return freeReferrer;
    }
    
    function view_hold(address _user) public view returns(uint) {
        return users[_user].holdamount;
    } 

    function viewUserReferral(address _user) public view returns(address[] memory) {
        return users[_user].referral;
    }

    function viewUserLevelExpired(address _user, uint _level) public view returns(uint) {
        return users[_user].levelExpired[_level];
    }

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
    
     /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external {
        
        require(msg.sender == ownerWallet,"You are not authorized");
        _transferOwnership(newOwner);
    }

     /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "New owner cannot be the zero address");
        emit OwnershipTransferred(ownerWallet, newOwner);
        ownerWallet = newOwner;
    }
    function withdrawLostTRXFromBalance() public payable{
        require(msg.sender == ownerWallet, "onlyOwner");
        msg.sender.transfer(address(this).balance);
    }
}