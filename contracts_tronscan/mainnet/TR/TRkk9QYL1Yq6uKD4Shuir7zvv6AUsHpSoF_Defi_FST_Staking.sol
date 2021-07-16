//SourceUnit: ROI_roi (1).sol


/** FORSAGETRON STAKING V.1.0.0
ПРОТОКОЛ СТАЙКИНГА FST DeFi
PROTOKOL STAYKINGA FST DeFi
TESTED - AUDITED - VERIFIED 
**/

pragma solidity 0.5.9;
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
        return 0;
    }
    uint256 c = a * b;
    require(c / a == b, 'SafeMath mul failed');
    return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, 'SafeMath sub failed');
    return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, 'SafeMath add failed');
    return c;
    }
}
    
contract owned {
    address payable public owner;
    address payable internal newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    //this flow is to prevent transferring ownership to wrong wallet by mistake
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}
   
 interface tokenInterface
 {
    function transfer_(address _to, uint256 _amount) external returns (bool);
    function transfer(address _to, uint256 _amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);
    function getUsdfByTrx() external payable returns(uint);
    function balanceOf(address _user) external view returns(uint);
    function users(address _user) external view returns(uint, address payable);
    function idToAddress(uint _id) external view returns(address);
    function getUsdfByFst(uint fstAmount)  external  returns(uint);
    function viewTrxForUsdf(uint _usdf) external view returns(uint);
 }
 
contract Defi_FST_Staking is owned
{
    using SafeMath for uint256;
    address public usdfAddress;
    address public fstAddress;
    address public frsgAddress;
    
    uint public _total_users;
    uint public _total_deposited;
    uint public _total_withdraw;
    uint public _pool_last_draw;
    uint public _pool_balance;
    uint public _pool_lider;

    uint public lastIDCount = 1; 

        
    struct userInfo
    {
        bool joined;
        bool newjoin;
        uint id ;
        address userAddress;
        uint referrerID ;
        uint deposit_time;
        uint lastWithdrawTime ;
        uint totalGain;
        uint deposit_amount ;
        uint payouts;
        uint direct_bonus;
        uint pool_bonus;
        uint match_bonus;       
        // activeLevel;
        uint sponserVolume;       
        address[] referral;
    }

    struct userTotal
    {
        uint referrals;
        uint total_deposits;
        uint total_payouts;
        uint total_structure;        
    }

    mapping (address => userInfo ) public userInfos;
    mapping(address => uint) public lastInvested;
    mapping (address => userTotal ) public userInfoss;
    mapping (uint => address payable) public userAddressByID;
    mapping(address => bool) public blackListed;
    address payable poolAddress;
    address payable reserve;
    address payable[5] public topVolumeHolder;
    uint public poolFund;
    uint public lastPoolWithdrawTime;
    uint public daysCap = 325;
    uint public dailyPercent = 1000; // = 1%

    uint public minDepositTRX = 3000000 ;
    uint public maxDepositTRX = 1000000000000;
    uint[20] public referralPercent;

    event invested(address _user, uint netAmount, uint paidAmount, uint _referrerID );

    constructor (address _usdfAddress, address _frsgAddress, address _fstAddress) public 
    {
        usdfAddress = _usdfAddress;
        frsgAddress = _frsgAddress;
        fstAddress = _fstAddress;
         userInfo memory temp;
         temp.newjoin = true;
         temp.id= lastIDCount;
         temp.referrerID = 1;
         //temp.activeLevel = 20;
         temp.userAddress = msg.sender;
         userInfos[msg.sender] = temp;
         userAddressByID[temp.id] = msg.sender;
         _total_users++;
         emit invested(msg.sender, 0,0 , 1);
        referralPercent[0] = 25;
        referralPercent[1] = 8;
        referralPercent[2] = 8;
        referralPercent[3] = 8;
        referralPercent[4] = 8;
        referralPercent[5] = 5;
        referralPercent[6] = 5;
        referralPercent[7] = 5;
        referralPercent[8] = 5;
        referralPercent[9] = 3;
        referralPercent[10] = 3;
        referralPercent[11] = 3;
        referralPercent[12] = 3;
        referralPercent[13] = 3;
        referralPercent[14] = 3;
        referralPercent[15] = 1;
        referralPercent[16] = 1;
        referralPercent[17] = 1;
        referralPercent[18] = 1;
        referralPercent[19] = 1;        

    }

    function setblackListed(address _user, bool _black) public onlyOwner returns(bool)
    {
        blackListed[_user] = _black;
        return true;
    }

    function setMinMaxInvestTrx(uint _min, uint _max) public onlyOwner returns(bool)
    {
        minDepositTRX = _min;
        maxDepositTRX = _max;
        return true;
    }    

    function changeusdfAddress(address _usdfAddress, address _frsgAddress, address _fstAddress) onlyOwner public returns(string memory){
        //if owner makes this 0x0 address, then it will halt all the operation of the contract. This also serves as security feature.
        //so owner can halt it in any problematic situation. Owner can then input correct address to make it all come back to normal.
        usdfAddress = _usdfAddress;
        frsgAddress = _frsgAddress;
        fstAddress = _fstAddress;
        return("Token address updated successfully");
    }

    function invest(address _refAdd, uint amount) public payable returns(bool) 
    {
        uint _referrerID = userInfos[_refAdd].id;
        require(userInfos[msg.sender].deposit_amount == 0, "already invested");
        
        if(msg.value > 0 )
        {
            amount = tokenInterface(usdfAddress).getUsdfByTrx.value(msg.value)();
        }
        else if(amount > 0 && tokenInterface(usdfAddress).balanceOf(msg.sender) < amount)
        {
            require(tokenInterface(fstAddress).balanceOf(msg.sender) >= amount, "Insufficient fstToken");
            amount = tokenInterface(usdfAddress).getUsdfByFst(amount);
        }

        uint trxAmt = tokenInterface(usdfAddress).viewTrxForUsdf(amount);
        require (trxAmt <= maxDepositTRX && trxAmt >= minDepositTRX, "invalid amount");
        require(lastInvested[msg.sender] <= amount, "less than current");
        lastInvested[msg.sender] = amount;
        require(userInfos[msg.sender].deposit_amount == 0, "already invested");
        if(_referrerID == 0 || _referrerID > lastIDCount) _referrerID = 1;
        require( tokenInterface(usdfAddress).transferFrom(msg.sender, address(this), amount) , "token transfer failed");
        (uint id_,) = tokenInterface(frsgAddress).users(msg.sender);
        address payable refAdd = userAddressByID[_referrerID];
        if(! userInfos[msg.sender].joined )
        {
            lastIDCount++;
            userInfo memory temp;
            temp.joined = true;
            if(id_ == 0 ) temp.newjoin = true;
            temp.id= lastIDCount;
            temp.userAddress = msg.sender;
            temp.referrerID = _referrerID;
            userInfos[msg.sender] = temp;
            userAddressByID[temp.id] = msg.sender;
            _total_users++;
            updateStructure(refAdd);
        }
        userInfos[msg.sender].deposit_time = now;
        userInfos[msg.sender].lastWithdrawTime = now;
        userInfos[msg.sender].deposit_amount = amount;
        _total_deposited += amount * 82/100;
        userInfoss[msg.sender].total_deposits+= amount;
        
        //if(userInfos[refAdd].activeLevel < 20) userInfos[refAdd].activeLevel++;
        userInfos[refAdd].referral.push(msg.sender);
        userInfoss[refAdd].referrals++;
        userInfos[refAdd].sponserVolume += amount;
        uint vol = userInfos[refAdd].sponserVolume;
        if ( userInfos[topVolumeHolder[0]].sponserVolume <  vol  ) topVolumeHolder[0] = refAdd;
        else if(userInfos[topVolumeHolder[1]].sponserVolume <  vol  ) topVolumeHolder[1] = refAdd;
        else if(userInfos[topVolumeHolder[2]].sponserVolume <  vol  ) topVolumeHolder[2] = refAdd;
        else if(userInfos[topVolumeHolder[3]].sponserVolume <  vol  ) topVolumeHolder[3] = refAdd;
        else if(userInfos[topVolumeHolder[4]].sponserVolume <  vol  ) topVolumeHolder[4] = refAdd;
        checkNPay(refAdd,amount / 10,0);
        poolFund += amount * 3/100;
        _pool_balance +=  amount * 3/100;
        tokenInterface(usdfAddress).transfer_(owner,  amount * 5 / 100);
        emit invested(msg.sender, amount * 82 / 100, amount, _referrerID);        
        return true;
    }

    function updateStructure(address payable _ref) internal returns(bool)
    {
        userInfoss[_ref].total_structure++;
        _ref = getRef(_ref);
        for (uint i=0;i<19;i++)
        {
            userInfoss[_ref].total_structure++;
            _ref = getRef(_ref);
        }
        return true;
    }

    // Payout events type definition
    // 0 = direct pay 
    // 1 = daily gain
    // 2 = level pay
    // 4 = pool pay
    event paidEv(uint _type, address payable paidTo,uint paidAmount);
    event missedEv(uint _type, address payable missedBy,uint missedAmount);
    event investWithdrawnEv(address _user, uint _amount);
    function withdrawGain(address payable _user, bool _reInvest) public returns(bool)
    {
        uint investAmount = userInfos[_user].deposit_amount * 82 / 100;
        require(investAmount > 0, "nothing invested");

        uint dayPassed =  now - userInfos[_user].deposit_time;
        dayPassed = dayPassed / 86400;

        uint dayPassedFromLastWithdraw = now - userInfos[_user].lastWithdrawTime;
        dayPassedFromLastWithdraw = dayPassedFromLastWithdraw / 86400;

        uint GainAmount = dayPassedFromLastWithdraw * dailyPercent * (investAmount/ 100000);

        //uint finalAmount = userAddressByID[_user].totalGain + _amount 
        uint gp = daysCap;
        if(userInfos[_user].totalGain + GainAmount > (investAmount * gp/100) ) 
        {
            GainAmount = (investAmount * gp/100) - userInfos[_user].totalGain;
            checkNPay(_user, GainAmount * 9 / 10,1 );
            payToReferrer(_user, GainAmount * 10000 / 100000);
            if(_reInvest) 
            {
                userInfos[_user].deposit_time = now;
                userInfos[_user].lastWithdrawTime = now;
                userInfos[_user].totalGain = 0;
            }
            else
            {
                userInfos[_user].deposit_time = 0;
                userInfos[_user].lastWithdrawTime = 0;
                userInfos[_user].deposit_amount = 0;
                userInfos[_user].totalGain = 0;
                if(! blackListed[_user] ) tokenInterface(usdfAddress).transfer_(_user, investAmount);
                else tokenInterface(usdfAddress).transfer_(owner, investAmount);
                _total_withdraw += investAmount;
                emit investWithdrawnEv(_user, investAmount);
            }
        } 
        else
        {
            checkNPay(_user, GainAmount * 9 / 10,1 );
            payToReferrer(_user, GainAmount * 1000 / 10000);
            userInfos[_user].totalGain+= GainAmount;
            userInfos[_user].lastWithdrawTime = now;
        }    
        return true;    
    }


    function viewGain(address _user) public view returns(uint)
    {
        uint investAmount = userInfos[_user].deposit_amount * 82 / 100;

        uint dayPassed =  now - userInfos[_user].deposit_time;
        dayPassed = dayPassed / 86400;

        uint dayPassedFromLastWithdraw = now - userInfos[_user].lastWithdrawTime;
        dayPassedFromLastWithdraw = dayPassedFromLastWithdraw / 86400;

        uint GainAmount = dayPassedFromLastWithdraw * dailyPercent * (investAmount/ 100000);

        //uint finalAmount = userAddressByID[_user].totalGain + _amount 
        uint gp = daysCap;
        if(userInfos[_user].totalGain + GainAmount > (investAmount * gp/100) ) 
        {
            GainAmount = (investAmount * gp/100) - userInfos[_user].totalGain;
        }   
        return GainAmount;    
    }


    event refPaid(address _against, address paidTo, uint amount, uint level);
    event refMissed(address _against, address missedBy, uint amount, uint level);

    function payToReferrer(address payable _user, uint _amount) internal returns(bool)
    {
        address payable _refUser = getRef(_user);
        uint ownerAmount;
        for(uint i=0; i<15; i++)
        {
            uint amt = _amount * referralPercent[i] * 100000 / 1000000;
           if(userInfos[_refUser].referral.length >= i+1 && userInfos[_refUser].deposit_amount > minDepositTRX)
           {
               checkNPay(_refUser,amt ,2);
               emit refPaid(_user, _refUser,amt , i+1);
           } 
           else
           {
               ownerAmount += amt;
               emit refMissed(_user,_refUser, amt, i+1);
           }
            _refUser = getRef(_refUser);          
        } 
        if(ownerAmount > 0 ) tokenInterface(usdfAddress).transfer_(owner, ownerAmount);       
        return true;
    }


    function getRef(address payable _user) public view returns(address payable)
    {
        address payable _refUser;
        if(! userInfos[_user].newjoin)
        {
            ( , _refUser) = tokenInterface(frsgAddress).users(_user);
        }
        else
        {
            uint _refID = userInfos[_user].referrerID;
            _refUser= userAddressByID[_refID];
        }       
        return _refUser;
    }


    function viewUserReferral(address _user) public view returns(address[] memory) 
    {
        return userInfos[_user].referral;
    }

    event withdrawPoolGainEv(address _user, uint amount);
    function withdrawPoolGain() public returns(bool)
    {
        require(now > lastPoolWithdrawTime + 86400,"wait few more hours" );
        lastPoolWithdrawTime = now;
        uint poolDist = poolFund *1/100;
        poolFund -= poolDist;
        _pool_balance -= poolDist;
        _pool_last_draw = poolDist;
        _pool_lider += poolDist;
        for(uint i=0;i<5;i++)
        {
            address payable ad =  topVolumeHolder[i];
            if(ad == address(0)) ad = owner;
            checkNPay(ad, poolDist / 5,3);
            emit withdrawPoolGainEv(ad, poolDist/5);
        }
        return true;
    }



    function checkNPay(address payable _user, uint _amount,uint  _type) internal returns (bool)
    {
        if(userInfos[_user].totalGain + _amount <= userInfos[_user].deposit_amount * 12 && _user != address(0))
        {
            if(! blackListed[_user] || !userInfos[_user].joined)
            {
                tokenInterface(usdfAddress).transfer_(_user, _amount);
                emit paidEv(_type,_user,_amount);
            }
            else 
            {
                tokenInterface(usdfAddress).transfer_(poolAddress, _amount);
                emit missedEv(_type,_user,_amount);
            }
            userInfos[_user].totalGain += _amount;
            
            
            if(_type == 0) userInfos[_user].direct_bonus += _amount;
            else if (_type == 1) 
            {
                userInfos[_user].payouts += _amount;
                userInfoss[_user].total_payouts += _amount;
            }
            else if (_type == 2) userInfos[_user].match_bonus += _amount;
            else if (_type == 3) userInfos[_user].pool_bonus += _amount;
        }
        else
        {
            tokenInterface(usdfAddress).transfer_(owner, _amount);
        }
        return true;
    }

    function setDaysCap(uint _daysCap, uint _dailyPercent) public onlyOwner returns(bool)
    {
        daysCap = _daysCap;
        dailyPercent = _dailyPercent;
        return true;
    }

    function preExit() public returns (bool)
    {
        address _user = msg.sender;
        uint invAmt = userInfos[_user].deposit_amount;
        require( invAmt > 0 && now < userInfos[_user].deposit_time + 100 days, "can not pre exit");
        invAmt = invAmt.sub(userInfos[_user].totalGain);
        userInfos[_user].deposit_time = 0;
        userInfos[_user].lastWithdrawTime = 0;
        userInfos[_user].deposit_amount = 0;
        userInfos[_user].totalGain = 0;
        if(! blackListed[_user])tokenInterface(usdfAddress).transfer_(_user, invAmt);
        else tokenInterface(usdfAddress).transfer_(owner, invAmt);
        emit investWithdrawnEv(_user, invAmt);        
        return true;
    }

    function sendToReserve(uint _value) public onlyOwner returns(bool)
    {
        tokenInterface(fstAddress).transfer(reserve,_value );
        return true;
    }

    function sendTrxReserve() public onlyOwner returns(bool)
    {
        reserve.transfer(address(this).balance);
        return true;
    }

    function setReserve(address payable _reserve, address payable _poolAddress) public onlyOwner returns(bool)
    {
        poolAddress = _poolAddress;
        reserve = _reserve;
        return true;
    }



    function contractInfo() public view returns(uint _total_users_,uint _total_deposited_,uint _total_withdraw_,uint _pool_last_draw_,uint _pool_balance_,uint _pool_lider_)
    {
        return (_total_users,_total_deposited,_total_withdraw,_pool_last_draw,_pool_balance,_pool_lider);
    }

    function payoutOf(address _user) public view returns(uint payout, uint max_payout)
    {
        payout = userInfos[_user].payouts;
        max_payout = userInfos[_user].deposit_amount * 12;
        return (payout, max_payout);
    }

    function userInfosTotal(address _user) public view returns(uint referrals, uint total_deposits, uint total_payouts, uint total_structure)
    {
        userTotal memory temp = userInfoss[_user];
        return (temp.referrals, temp.total_deposits, temp.total_payouts, temp.total_structure);
    }

    function poolTopInfo() public view returns( address[5] memory addrs, uint[5] memory deps)
    {
        addrs[0] = topVolumeHolder[0];
        addrs[1] = topVolumeHolder[1];
        addrs[2] = topVolumeHolder[2];
        addrs[3] = topVolumeHolder[3];
        addrs[4] = topVolumeHolder[4];
        deps[0] = userInfos[addrs[0]].sponserVolume;
        deps[1] = userInfos[addrs[1]].sponserVolume;
        deps[2] = userInfos[addrs[2]].sponserVolume;
        deps[3] = userInfos[addrs[3]].sponserVolume;
        deps[4] = userInfos[addrs[4]].sponserVolume;
        return (addrs, deps);
    }

}