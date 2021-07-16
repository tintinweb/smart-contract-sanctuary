//SourceUnit: lemox.sol

/**
 *Submitted for verification at Trxscan.io on 2020-06-29
*/

/**
 *Submitted for verification at Trxscan.io on 2020-06-28
*/

/**
 *Submitted for verification at Trxscan.io on 2020-06-26
*/

/**
 *Submitted for verification at Trxscan.io on 2020-06-23
*/

pragma solidity 0.5.9; 


contract owned
{
    address payable internal owner;
    address payable internal newOwner;
    address payable internal signer;
    address payable internal bufferOwner;
    bool public allowWithdrawInTrx;


    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
        signer = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }


    modifier onlySigner {
        require(msg.sender == signer, 'caller must be signer');
        _;
    }


    function changeSigner(address payable _signer) public onlyOwner {
        signer = _signer;
    }

    function transferOwnership(address payable  _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    //the reason for this flow is to protect owners from sending ownership to unintended address due to human error
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


interface mscInterface
{
    function doPay(uint256 _networkId,uint256 _poolIndex, uint256 _amount,address payable _userId) external returns(bool);
    //  baseUserId, user, parentId, referrerId, childCount, lastBoughtLevel, referralCount, levelExpiry
    function userInfos(uint256 _networkId,uint256 _planIndex,bool mainTree, uint256 _userId) external view returns(uint256,address payable,uint256,uint256,uint256,uint256,uint256,uint256);
    function regUserViaContract(uint256 _networkId,uint256 _referrerId,uint256 _parentId, uint256 amount) external returns(bool);
    function buyLevelViaContract(uint256 _networkId,uint256 _planIndex, uint256 _userId, uint256 amount) external returns(bool);
    function addToPool(uint256 _networkId,uint256 _poolIndex, uint256 _amount) external returns(bool);
    //function userIndex(uint256 _networkId, uint256 _planIndex,bool mainTree, address payable _user) external view returns(uint256[] memory);
    function subUserId(uint256 _networkId, uint256 _planIndex, bool mainTree, uint256  _baseUserId ) external view returns(uint256);
}

interface LMXInterface
{
    function addBalanceOf(address user,uint amount) external returns(bool);
    function subBalanceOf(address user, uint amount) external returns(bool);
    function approveSpecial(address from, address _spender, uint256 _value) external returns (bool);
    function mintToken(address target, uint256 mintedAmount) external returns(bool); 
    function rewardExtraToken(address target, uint256 mintedAmount) external returns(bool); 
    function balanceOf(address user) external view returns(uint);
    function rewardOf(address user) external view returns(uint);
    function burnSpecial(address user, uint256 _value) external returns (bool);

}

contract lemoxCash is owned
{

   // Lemox plan functions
    uint256 public oneTrxToDollarPercent = 5000000000;  //  price of one token

    address payable public mscContractAddress;
    uint256 public networkId;
    address payable public tokenContractAddress;
    address payable public usdtContractAddress;

    // all first mappings are userId
    mapping(uint256 => uint256[6]) public boosterGain;
    mapping(uint256 => uint256[8]) public teamActivationGain;
    mapping(uint256 => uint256[8]) public teamBonusGain;
    mapping(uint256 => uint256[10]) public megaPoolGain;
    mapping(uint256 => bool[10]) public megaPoolReadyToWithdraw;

    mapping(uint256 => uint256[6]) public paidBoosterGain;
    mapping(uint256 => uint256[8]) public paidTeamActivationGain;
    mapping(uint256 => uint256[8]) public paidTeamBonusGain;
    mapping(uint256 => uint256[10]) public paidMegaPoolGain;


    mapping(uint256 => uint256[3]) public teamTurnOver;
    // 2nd is level 
    mapping(uint256 => mapping(uint256 => uint256[6])) public autoPoolGain;
    mapping(uint256 => mapping(uint256 => uint256[6])) public paidAutoPoolGain;

    uint256[10] public megaPoolPrice;
    uint256[6] public levelBuyPrice;
    uint256[8] public bonusPrice;

    mapping(uint256 => uint256) public reInvestGain;
    mapping(uint256 => uint256) public expiryTime;
    uint256 reInvestPeriod;
    //mapping(uint256 => uint256[11]) memory payOutArray;

    struct autoPay
    {
        uint[11] payOutArray;
    }    
    
    constructor(address payable _owner, address payable _bufferOwner) public{ 
        owner = _owner;
        bufferOwner = _bufferOwner;

        levelBuyPrice = [35000000,40000000,100000000,500000000,1000000000,5000000000];
        megaPoolPrice = [5000000,10000000,20000000,80000000,220000000,600000000,1000000000,2000000000,8000000000,16000000000];
        bonusPrice = [50000000,250000000,625000000,1875000000,2500000000,12500000000,25000000000,12500000000];
        reInvestPeriod = 172800;

        for(uint i=0;i<10;i++)
        {
            megaPoolReadyToWithdraw[0][i] = true;
        }



    }

   
    function() external payable
    {

    }

    function setAllowWithdrawInTrx(bool _value) public onlyOwner returns (bool)
    {
        allowWithdrawInTrx = _value;
        return true;
    }


    event processExternalMainEv(uint256 _networkId,uint256 _planIndex,uint256 _baseUserId,  uint256 _subTreeId, uint256 _referrerId, uint256 _paidAmount, bool mainTree);
    function processExternalMain(uint256 _networkId,uint256 _planIndex,uint256 _baseUserId,  uint256 _subTreeId, uint256 _referrerId, uint256 _paidAmount, bool mainTree) external returns(bool)
    {
        require(msg.sender == mscContractAddress, "Invalid caller");
        ( ,,,uint rId,,,,) = mscInterface(mscContractAddress).userInfos(_networkId,0,true, _baseUserId);
        if(_paidAmount > 0)
        {        
            require(_networkId == networkId, "Invalid call by MSC");
            autoPay[5] memory payOutArr;
            payOutArr[0].payOutArray = [uint256(10000000),uint256(6666666),uint256(5000000),uint256(5000000),uint256(5000000),uint256(5000000),uint256(5000000),uint256(23750000),uint256(26408),uint256(26408),uint256(125437)];
            payOutArr[1].payOutArray = [uint256(10000000),uint256(6666666),uint256(6000000),uint256(6000000),uint256(5000000),uint256(5000000),uint256(5000000),uint256(20000000),uint256(30864),uint256(30864),uint256(123457)];
            payOutArr[2].payOutArray = [uint256(10000000),uint256(6666666),uint256(5000000),uint256(6000000),uint256(7000000),uint256(8000000),uint256(9000000),uint256(13000000),uint256(64977),uint256(73099),uint256(105588)];
            payOutArr[3].payOutArray = [uint256(10000000),uint256(6666666),uint256(5000000),uint256(6000000),uint256(7000000),uint256(8000000),uint256(9000000),uint256(10000000),uint256(79012),uint256(88889),uint256(98765)];
            payOutArr[4].payOutArray = [uint256(10000000),uint256(6666666),uint256(2000000),uint256(2400000),uint256(2800000),uint256(3200000),uint256(3600000),uint256(9000000),uint256(41585),uint256(46784),uint256(116959)];
            if(_planIndex == 0)
            {
                require(payIndex0(_baseUserId, rId,_paidAmount),"fund allot fail");
            }
            else if(_planIndex >= 1)
            {
                require(payIndex1(_baseUserId,_planIndex, rId,_paidAmount,payOutArr[_planIndex -1].payOutArray),"fund allot fail");
            }
        }
        emit processExternalMainEv(_networkId,_planIndex,_baseUserId,_subTreeId, _referrerId, _paidAmount, mainTree);
        return true;
    }

    // 0 = main referral
    // 1 = 10 % referral
    // 2 = 40% parent by level
    // 3 = team activation
    // 4 = team bonus
    // 5 = auto pool
    // 6 = mega pool
    // 7 = reinvest Gain 
   
    
    event payOutDetailEv(uint payoutType, uint amount,uint paidTo, uint paidAgainst);

    function payIndex0(uint256 _baseUserId, uint256 _referrerId,uint256 _paidAmount) internal returns(bool)
    {
        uint256[9] memory tmpDist;
        uint tmp2;
        uint256 _networkId = networkId;
        // pay referral
        uint Pamount = _paidAmount * 42857143 / 100000000;
        boosterGain[_referrerId][0] +=  Pamount;
        emit payOutDetailEv(0, Pamount, _referrerId, _baseUserId);

        // pay team activation
        uint256 pId = _baseUserId;
        uint tmp = 3571428;
        uint256 i;

        for(i=0;i<8;i++)
        {
            // here pId is referrer id
            ( ,,,pId,,,,) = mscInterface(mscContractAddress).userInfos(_networkId,0,true, pId);
            Pamount =  _paidAmount * tmp / 100000000;
            teamActivationGain[pId][i] += Pamount;
            emit payOutDetailEv(3, Pamount, pId, _baseUserId); 
            if((i+1) % 2 == 0) tmp = tmp - 714285;
        }

        //Team bonous will be triggered by external call from server to add user part 
        tmpDist = [uint256(714285),uint256(1428571),uint256(2857142),uint256(2142857),uint256(2142857),uint256(4428571),uint256(54627),uint256(54627),uint256(112896)];
        // pay auto pool - basic
        pId = mscInterface(mscContractAddress).subUserId(_networkId, 0, false, _baseUserId );

        for(i=0;i<6;i++)
        {
   
            ( ,,pId,,,,,) = mscInterface(mscContractAddress).userInfos(_networkId,0,false, pId);
            if(i<3)
            {
                Pamount =  _paidAmount * tmpDist[i]/ 100000000;
                autoPoolGain[pId][0][i] += Pamount;
                emit payOutDetailEv(5, Pamount, pId, _baseUserId); 
            }
            else
            {
                ( ,,pId,,,,,) = mscInterface(mscContractAddress).userInfos(_networkId,0,false, pId);
                tmp = _paidAmount * tmpDist[i] / 100000000;
                tmp2 = 2 * _paidAmount * tmpDist[i+3] / 100000000;
                autoPoolGain[pId][0][i] += tmp - tmp2;
                emit payOutDetailEv(5, tmp - tmp2, pId, _baseUserId); 
                reInvestGain[pId] += tmp2;
                emit payOutDetailEv(7, tmp2, pId, _baseUserId); 
            }
        }
        if(reInvestGain[pId] >= _paidAmount) expiryTime[_baseUserId] = now + reInvestPeriod;
        require(payMegaPool(_baseUserId,0),"mega pool pay fail");
        return true;
    }


    function payIndex1(uint256 _baseUserId,uint256 _planIndex, uint256 _referrerId,uint256 _paidAmount, uint[11] memory prcnt) internal returns(bool)
    {
        require(msg.sender == mscContractAddress, "invalid caller");
        uint256 _networkId = networkId;
        // pay referral 10%
        uint Pamount = _paidAmount  * prcnt[0] / 100000000;
        boosterGain[_referrerId][_planIndex] += Pamount;
        emit payOutDetailEv((10* _planIndex) + 1, Pamount, _referrerId, _baseUserId); 

        // pay equal from 40% to  6 parent  
        uint256 pId = _baseUserId;
        uint256 tmp;
        uint256 i;
        ( ,,pId,,,,,) = mscInterface(mscContractAddress).userInfos(_networkId,0,true, pId);
        ( ,,,,,tmp,,) = mscInterface(mscContractAddress).userInfos(_networkId,0,true, pId); // tmp is bought level here
        Pamount = _paidAmount * prcnt[1] / 100000000;
        if(tmp >= _planIndex + 1)
        {
            boosterGain[pId][i] += (6 * Pamount);
            emit payOutDetailEv((10* _planIndex) + 2, (6* Pamount), pId, _baseUserId);  
        }
        else
        {
            pId = _baseUserId;
            for(i=0;i<6;i++)
            {
                ( ,,pId,,,,,) = mscInterface(mscContractAddress).userInfos(_networkId,0,true, pId);
                boosterGain[pId][i] += Pamount;
                emit payOutDetailEv((10* _planIndex) + 2, Pamount, pId, _baseUserId);  
            }
        }

        // pay 5 auto-pool different amount 
        pId = mscInterface(mscContractAddress).subUserId(_networkId, _planIndex, false, _baseUserId );
        tmp = 0;
        uint tmp2;
        for(i=0;i<5;i++)
        {
            ( ,,pId,,,,,) = mscInterface(mscContractAddress).userInfos(_networkId,_planIndex,false, pId);
            tmp = _paidAmount * prcnt[i+2] / 100000000;
            tmp2 = 0;
            if(i > 2) tmp2 = (2**(_planIndex +1)) * levelBuyPrice[0] * prcnt[i+5] / 100000000;  // deduct in multiple of 35 
            autoPoolGain[pId][_planIndex][i] += (tmp - tmp2);
            emit payOutDetailEv((10* _planIndex + 5), tmp - tmp2, pId, _baseUserId); 
            reInvestGain[pId] += tmp2;
            if(tmp2>0) emit payOutDetailEv((10* _planIndex) +  7, tmp2, pId, _baseUserId); 
        }
        if(reInvestGain[pId] >= levelBuyPrice[0]) expiryTime[_baseUserId] = now + reInvestPeriod;
        //require(payMegaPool(_baseUserId,_planIndex),"mega pool pay fail");
        return true;
    }


    function payMegaPool(uint256 _baseUserId, uint256 _levelIndex) internal returns(bool)
    {
        uint256 _networkId = networkId;
        uint pId;
        uint Pamount;
        pId =  mscInterface(mscContractAddress).subUserId(_networkId, 6, false, _baseUserId );
        if(_levelIndex == 0) 
        {
            ( ,,pId,,,,,) = mscInterface(mscContractAddress).userInfos(_networkId,6,false, pId);
            Pamount = megaPoolPrice[_levelIndex];
            megaPoolGain[pId][_levelIndex] += Pamount ;
            emit payOutDetailEv((10* _levelIndex) + 6, Pamount, pId, _baseUserId); 
        }
        uint256 x=_levelIndex + 1;
        if(_levelIndex >= 5 ) x = x -5;

        if(megaPoolGain[pId][_levelIndex] == megaPoolPrice[_levelIndex] * (uint(2) ** x )  && megaPoolReadyToWithdraw[pId][_levelIndex] == false && _levelIndex < 9) 
        {
            Pamount = megaPoolPrice[_levelIndex+1];
            megaPoolGain[pId][_levelIndex] =  megaPoolGain[pId][_levelIndex] - Pamount;
            megaPoolReadyToWithdraw[pId][_levelIndex] = true;                   
            for(uint256 k=0;k<=_levelIndex+1;k++)
            {
                ( ,,pId,,,,,) = mscInterface(mscContractAddress).userInfos(_networkId,6,false, pId);
            }  
            
            megaPoolGain[pId][_levelIndex+1] += Pamount;
            emit payOutDetailEv(( 10 * (_levelIndex+1)) + 6, Pamount, pId, _baseUserId); 
            if(_levelIndex < 9 ) payMegaPool(pId, _levelIndex + 1 );
        }
        return true;
    }

    function updateTeamCount(uint256 _userId, uint256 _turnOverCountLeg1, uint256 _turnOverCountLeg2, uint256 _turnOverCountLeg3) public onlySigner returns(bool)
    {
        uint256 totalCount;
        teamTurnOver[_userId][0] = _turnOverCountLeg1;
        teamTurnOver[_userId][1] = _turnOverCountLeg2;
        teamTurnOver[_userId][2] = _turnOverCountLeg3;
        if(_turnOverCountLeg1 > _turnOverCountLeg2 && _turnOverCountLeg1 > _turnOverCountLeg3)
        {
            totalCount = _turnOverCountLeg1 / 2;
            totalCount += ( _turnOverCountLeg2 + _turnOverCountLeg3);
        }
        else if(_turnOverCountLeg2 > _turnOverCountLeg1 && _turnOverCountLeg2 > _turnOverCountLeg3)
        {
            totalCount = _turnOverCountLeg2 / 2;
            totalCount += ( _turnOverCountLeg1 + _turnOverCountLeg3);
        }
        else
        {
            totalCount = _turnOverCountLeg3 / 2;
            totalCount += ( _turnOverCountLeg1 + _turnOverCountLeg2);
        }

        if(totalCount >=3000 && totalCount < 15000 && teamBonusGain[_userId][0] == 0) 
        {
            teamBonusGain[_userId][0] = bonusPrice[0];
        }

        if(totalCount >=15000 && totalCount < 30000 && teamBonusGain[_userId][1] == 0) 
        {
            teamBonusGain[_userId][1] = bonusPrice[1];
        }

        if(totalCount >=30000 && totalCount < 150000 && teamBonusGain[_userId][2] == 0) 
        {
            teamBonusGain[_userId][2] = bonusPrice[2];
        }

        if(totalCount >=150000 && totalCount < 300000 && teamBonusGain[_userId][3] == 0) 
        {
            teamBonusGain[_userId][3] = bonusPrice[3];
        }

        if(totalCount >=300000 && totalCount < 1500000 && teamBonusGain[_userId][4] == 0) 
        {
            teamBonusGain[_userId][4] = bonusPrice[4];
        }
        if(totalCount >=1500000 && totalCount < 3000000 && teamBonusGain[_userId][5] == 0) 
        {
            teamBonusGain[_userId][5] = bonusPrice[5];
        }
        if(totalCount >=3000000 && totalCount < 15000000 && teamBonusGain[_userId][6] == 0) 
        {
            teamBonusGain[_userId][6] = bonusPrice[6];
        }
        if(totalCount >=15000000 && teamBonusGain[_userId][7] == 0) 
        {
            teamBonusGain[_userId][7] = bonusPrice[7];
        }
        return true;
    }

    function withdraw(uint256 _userId) public returns (bool)
    {
        for(uint256 j=0; j<6;j++)
        {            
            withdrawBoosterAndAutoPoolGain(_userId,j);
        }
        withdrawTeamActivationGain(_userId);
        withdrawTeamBonusGain(_userId);
        withdrawMegaPoolGain(_userId); 
        return true;         
    }


    function withdrawBoosterAndAutoPoolGain(uint256 _userId, uint256 level) public returns(bool)
    {
        //booster
        uint256 refCount;
        uint256 lastLevel;        
        uint256 totalAmount;
        uint256 boosterbalance = boosterGain[_userId][level] - paidBoosterGain[_userId][level];
        //level++;
        // for level 0
        ( ,,,,,lastLevel,refCount,) = mscInterface(mscContractAddress).userInfos(networkId,0,true, _userId);
        if((lastLevel == level + 1 &&  level == 5) || (lastLevel > level + 1 && refCount >= (level+1) * 3) || _userId == 0 ) 
        {
            totalAmount = boosterbalance;
            paidBoosterGain[_userId][level] = boosterGain[_userId][level];
            //uint256 pId = mscInterface(mscContractAddress).subUserId(networkId, level, false, _userId );
            for(uint256 i=0;i<6;i++)
            {
                totalAmount += (autoPoolGain[_userId][level][i] - paidAutoPoolGain[_userId][level][i]);
                paidAutoPoolGain[_userId][level][i] = autoPoolGain[_userId][level][i];
            }
        }
        else if(lastLevel <= level+1 && boosterbalance >= levelBuyPrice[lastLevel] )
        {
            require(buyLevelbyTokenGain(lastLevel,_userId ), "internal level buy fail");
            withdrawBoosterAndAutoPoolGain(_userId, level);
        }
        if(totalAmount>0 ) withdrawToken(totalAmount,_userId);
        return true;
    }

    // use level 1 to 6 not 0 to 5
    function withdrawTeamActivationGain(uint256 _userId) public returns(bool)
    {
        //booster
        uint256 refCount;
        uint256 lastLevel;        
        uint256 totalAmount;
        // for level 0
        ( ,,,,,lastLevel,refCount,) = mscInterface(mscContractAddress).userInfos(networkId,0,true, _userId);
        if(lastLevel >= 2 && refCount >= 3 ) 
        {
            for(uint256 i=0;i<8;i++)
            {
                totalAmount += teamActivationGain[_userId][i] - paidTeamActivationGain[_userId][i];
                paidTeamActivationGain[_userId][i] = teamActivationGain[_userId][i];
            }
        }
        if(totalAmount>0 ) withdrawToken(totalAmount,_userId);
        return true;
    }

    // use level 1 to 6 not 0 to 5
    function withdrawTeamBonusGain(uint256 _userId) public returns(bool)
    {
        //booster
        uint256 refCount;
        uint256 lastLevel;        
        uint256 totalAmount;
        // for level 0
        ( ,,,,,lastLevel,refCount,) = mscInterface(mscContractAddress).userInfos(networkId,0,true, _userId);
        if(lastLevel >= 2 && refCount >= 3 ) 
        {
            for(uint256 i=0;i<8;i++)
            {
                totalAmount += teamBonusGain[_userId][i] - paidTeamBonusGain[_userId][i];
                paidTeamBonusGain[_userId][i] = teamBonusGain[_userId][i];
            }
        }
        if(totalAmount>0 ) withdrawToken(totalAmount,_userId);
        return true;
    }


    function withdrawMegaPoolGain(uint256 _userId) public returns(bool)
    {
        //booster
        uint256 refCount;
        uint256 lastLevel;        
        uint256 totalAmount;
        // for level 0
        ( ,,,,,lastLevel,refCount,) = mscInterface(mscContractAddress).userInfos(networkId,0,false, _userId);
        uint256 pId = mscInterface(mscContractAddress).subUserId(networkId, 6, false, _userId );
        if(lastLevel >= 2 && refCount >= 3 ) 
        {
            for(uint256 i=0;i<10;i++)
            {
                if(megaPoolReadyToWithdraw[pId][i]) 
                {
                    totalAmount += megaPoolGain[pId][i] - paidMegaPoolGain[pId][i];
                    paidMegaPoolGain[pId][i] = megaPoolGain[pId][i];
                }
            }        
        }
        if(totalAmount>0 ) withdrawToken(totalAmount,_userId);
        return true;
    }

    event withdrawTokenEv(uint timeNow, address user,uint amount, uint adminPart, uint bufferpart);
    function withdrawToken(uint amount, uint _userId) internal returns (bool)
    {
        uint256 _networkId = networkId;
        uint adminPart = amount * 6000000 / 100000000;
        uint bufferpart = amount * 4000000 / 100000000;
        ( ,address payable user,,,,,,) = mscInterface(mscContractAddress).userInfos(_networkId,0,true, _userId);
        require(LMXInterface(tokenContractAddress).subBalanceOf(mscContractAddress, amount - (adminPart + bufferpart)),"balance update fail");
        require(LMXInterface(tokenContractAddress).addBalanceOf(user, amount),"balance update fail");
        require(mscInterface(mscContractAddress).addToPool(_networkId,1,adminPart));
        require(mscInterface(mscContractAddress).addToPool(_networkId,2,bufferpart));
        emit withdrawTokenEv(now, user, amount,adminPart,bufferpart);
        return true;
    }

    event getTrxFromTokenEv(uint timeNow,address user,uint tokenAmount,uint trxAmount );
    function getTrxFromToken(uint amount) public returns (bool)
    {
        require(allowWithdrawInTrx, "now allowed");
        require(LMXInterface(tokenContractAddress).balanceOf(msg.sender) >= amount,"not enough balance");
        uint trxAmount = amount * oneTrxToDollarPercent / 100000000  ;
        //require(LMXInterface(tokenContractAddress).subBalanceOf(msg.sender, amount),"balance update fail");
        LMXInterface(tokenContractAddress).burnSpecial(msg.sender, amount);       
        msg.sender.transfer(trxAmount);
        emit getTrxFromTokenEv(now,msg.sender, amount, trxAmount );
        return true;
    }


    function viewDashBoardData(uint256 _userId) public view returns(uint256 boostIncome,uint256 teamActivationIncome,uint256 teamBonus,uint256 megaIncome, uint256[6] memory autoPoolIncome)
    {
        uint256 i;

        //booster
        for(i=0;i<6;i++)
        {
            boostIncome += ( boosterGain[_userId][i] - paidBoosterGain[_userId][i]);
        }
        //team activation

        for(i=0;i<8;i++)
        {
            teamActivationIncome += (teamActivationGain[_userId][i] - paidTeamActivationGain[_userId][i]);
        }
        //team bonous

        for(i=0;i<8;i++)
        {
            teamBonus += (teamBonusGain[_userId][i] - paidTeamBonusGain[_userId][i]);
        }

        for(i=0;i<10;i++)
        {
            megaIncome += ( megaPoolGain[_userId][i] - paidMegaPoolGain[_userId][i]);
        }     

        // auto pool

        uint256 j;
        for(j=0;j<6;j++)
        {       
            for(i=0;i<6;i++)
            {
                autoPoolIncome[j] += autoPoolGain[_userId][j][i] - paidAutoPoolGain[_userId][j][i];
            } 
        }
    }

    event payInEv(uint timeNow,address _user,uint256 amount);
    function regUser(uint256 _referrerId,uint256 _parentId) public payable returns(bool)
    {
        uint amount = levelBuyPrice[0];
        require(viewPlanPriceInTrx(0) == msg.value, "incorrect price sent");
        require(LMXInterface(tokenContractAddress).mintToken(msg.sender, amount),"token mint fail");
        require(LMXInterface(tokenContractAddress).approveSpecial(msg.sender, mscContractAddress,amount),"approve fail"); 
        require(LMXInterface(tokenContractAddress).rewardExtraToken(msg.sender,amount),"token reward fail");
        require(mscInterface(mscContractAddress).regUserViaContract(networkId,_referrerId,_parentId,amount),"regUser fail");
        emit payInEv(now,msg.sender,msg.value);
        return true;
    }
        
    
    function buyLevel(uint256 _planIndex, uint256 _userId) public payable returns(bool)
    {
        uint amount = levelBuyPrice[_planIndex];
        require(viewPlanPriceInTrx(_planIndex) == msg.value, "incorrect price sent");
        require(LMXInterface(tokenContractAddress).mintToken(msg.sender, amount),"token mint fail");
        require(LMXInterface(tokenContractAddress).approveSpecial(msg.sender, mscContractAddress,amount),"approve fail"); 
        require(LMXInterface(tokenContractAddress).rewardExtraToken(msg.sender,amount),"token reward fail");
        require(mscInterface(mscContractAddress).buyLevelViaContract(networkId,_planIndex,_userId, amount),"regUser fail");
        emit payInEv(now,msg.sender,msg.value);
        return true;
    }

    event buyLevelbyTokenGainEv(uint256 timeNow, uint256 _networkId,uint256 _planIndex, uint256 _userId, uint amount );
    function buyLevelbyTokenGain(uint256 _planIndex, uint256 _userId ) internal returns(bool)
    {
        uint amount = levelBuyPrice[_planIndex] ;
        require( amount <= boosterGain[_userId][_planIndex-1] - paidBoosterGain[_userId][_planIndex-1],"not enough amount");
        require(LMXInterface(tokenContractAddress).subBalanceOf(mscContractAddress, amount),"balance update fail");
        require(LMXInterface(tokenContractAddress).addBalanceOf(msg.sender, amount),"balance update fail");
        require(LMXInterface(tokenContractAddress).approveSpecial(msg.sender, mscContractAddress,amount),"approve fail");        
        paidBoosterGain[_userId][_planIndex-1] += amount;
        require(LMXInterface(tokenContractAddress).rewardExtraToken(msg.sender,amount),"token reward fail");
        require(mscInterface(mscContractAddress).buyLevelViaContract(networkId,_planIndex,_userId, amount),"regUser fail");
        emit buyLevelbyTokenGainEv(now,networkId,_planIndex,_userId,amount);
        return true;
    }

    event reInvestEv(uint256 timeNow, uint256 _networkId,uint256 _referrerId, uint256 _parentId, uint amount );
    function reInvest(uint256 _userId, uint256 _parentId) public returns(bool)
    {
        uint amount = levelBuyPrice[0];
        uint _networkId = networkId;
        require(reInvestGain[_userId] >= amount && now <= expiryTime[_userId], "either less amount or time expired" );
        require(LMXInterface(tokenContractAddress).subBalanceOf(mscContractAddress, amount),"balance update fail");
        require(LMXInterface(tokenContractAddress).addBalanceOf(msg.sender, amount),"balance update fail");
        require(LMXInterface(tokenContractAddress).approveSpecial(msg.sender, mscContractAddress,amount),"approve fail");        
        reInvestGain[_userId] -= amount; 
        ( ,,,uint pId,,,,) = mscInterface(mscContractAddress).userInfos(_networkId,0,true, _userId);    
        require(mscInterface(mscContractAddress).regUserViaContract(_networkId,pId,_parentId, amount),"regUser fail");
        emit reInvestEv(now,_networkId,pId,_parentId,amount);
        return true;
    }

    event claimReInvestEv(uint256 timeNow, uint256 _networkId,uint256 _planIndex, uint256 _userId, uint amount );
    function claimReInvest(uint256 _userId) public onlyOwner returns(bool)
    {
        uint amount = levelBuyPrice[0] ;
        require(reInvestGain[_userId] >= amount && now > expiryTime[_userId], "either less amount or time expired" );
        require(LMXInterface(tokenContractAddress).subBalanceOf(mscContractAddress, amount),"balance update fail");
        require(LMXInterface(tokenContractAddress).addBalanceOf(owner, amount),"balance update fail");        
        emit claimReInvestEv(now,networkId,0,_userId,amount);
        return true;
    }

    function setBasicData(address payable _mscContractAddress,address payable _tokenContractAddress,address payable _usdtContractAddress, uint256 _networkId ) public onlyOwner returns(bool)
    {
        mscContractAddress = _mscContractAddress;
        tokenContractAddress = _tokenContractAddress;
        usdtContractAddress = _usdtContractAddress;
        networkId = _networkId;
        return true;
    }

    function setOneTrxToDollar(uint _value) public onlySigner returns(bool)
    {
        oneTrxToDollarPercent = _value;
        return true;
    }

    event withdrawForUSDTEv(uint256 timeNow, uint256 amount);
    function withdrawForUSDT() public onlyOwner returns(bool)
    {
        require(usdtContractAddress != address(0), "invalid usdt address");
        usdtContractAddress.transfer(address(this).balance);
        emit withdrawForUSDTEv(now, address(this).balance);
    }

    // 1 = admin, 2 = buffer
    function getFund(uint amount, uint _type) public returns(bool)
    {
        require(_type > 0 && _type < 3, "invalid type");
        if(_type == 1) require(msg.sender == owner);
        if(_type == 2) require(msg.sender == bufferOwner);
        mscInterface(mscContractAddress).doPay(networkId,_type,amount,msg.sender);
        return true;
    }

    function changeOwnerNBufferAddress(address payable _owner, address payable _bufferOwner) public onlyOwner returns(bool)
    {
        owner = _owner;
        bufferOwner = _bufferOwner;
        return true;
    }

    function viewPlanPriceInTrx(uint256 _levelIndex ) public view returns(uint256)
    {
        if (_levelIndex < 6) return  levelBuyPrice[_levelIndex] * oneTrxToDollarPercent / 100000000;
        return 0;
    }

    function viewTokenValueOfTrx(uint256 _trxAmount ) public view returns(uint256)
    {
        return _trxAmount *  100000000 / oneTrxToDollarPercent;
    }


}