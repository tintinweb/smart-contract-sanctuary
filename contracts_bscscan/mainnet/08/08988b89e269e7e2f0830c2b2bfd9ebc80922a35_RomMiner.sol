// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.0;

import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./TransferHelper.sol";
import "./IBEP20.sol";
import "./RomMinePool.sol";

interface INetdb
{
    function bindParent(address user,address parent) external;
    function SetParent(address user,address parent) external;
    function getParent(address user) external view returns (address);
    function getMyChilders(address user) external view returns (address[] memory);
}

interface IPancakePair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

 
contract RomMiner is ReentrancyGuard {
    using TransferHelper for address;
    using SafeMath for uint256;
    address private _Romaddr;
    address private _Romtrade;
    address private _bnbtradeaddress;
    address private _owner;
    address private _feeowner;
    address private _rowaddr;
    address _usdttoken;
    INetdb _netdb;
    uint256 cs=9e39;
    RomMinePool private _minepool;
    RomMinePool private _creditPool;
    mapping(uint256 => uint256[10]) internal _levelconfig; //credit level config
    uint256 _totalhash;
    uint256 _oneshareget;
    uint256 _lastupdateblock;
    uint256 public _nextNew;
    uint256 public _lefthash;
    uint256 _behash;
    address[12] _tokens;

    mapping(address => mapping(uint256 => uint256)) _userlevelhashtotal; // level hash in my team
    mapping(address => PoolInfo) _lpPools;
    mapping(address=>bool) _dataManager;
    event SelfHashChanged(uint256 indexed hash,bool indexed add);

    struct PoolInfo {
        address tradeContract;
        uint256 hashrate;
        bool isusdtcontract;
    }
    mapping(address=>mapping(uint=>uint256)) _userInfo;
    uint immutable USERLEVELA=1;
    uint immutable SELFHASHA=2;
    uint immutable TEAMHASHA =3;
    uint immutable PENDINGJTA=4;
    uint immutable SXHASH=5;
    uint immutable TAKEDJT =7;
    uint immutable TOTALSTACKVALUE=8;
    
    uint256[9] _holdhash = [500 * 1e18, 1000 * 1e18, 2000 * 1e18, 3000 * 1e18, 4000 * 1e18, 6000 * 1e18, 8000 * 1e18, 10000 * 1e18];

     modifier onlydataManager() {
        require(_dataManager[msg.sender], 'auth');
        _;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, 'Mr');
        _;
    }

    function setBehash(uint256 amount) public onlyOwner
    {
        _behash=amount;
    }
 
    constructor(address netdb) {
        _owner = msg.sender;
        _netdb = INetdb(netdb);
        _lastupdateblock= block.number;//project start
        _dataManager[_owner]=true;

        _nextNew=1636819200;
        _lefthash=500000*1e18;
        _behash=500000*1e18;

        _levelconfig[0] =[0,0,0,0,0,0,0,0,0,0];
        _levelconfig[1] = [50,0,0,0,0,0,0,0,0,0];
        _levelconfig[2] = [60,40,0,0,0,0,0,0,0,0];
        _levelconfig[3] = [80,40,20,0,0,0,0,0,0,0];
        _levelconfig[4] = [90,60,40,20,0,0,0,0,0,0];
        _levelconfig[5] = [100,80,60,40,20,0,0,0,0,0];
        _levelconfig[6] = [120,100,80,60,40,20,0,0,0,0];
        _levelconfig[7] = [140,120,100,80,60,40,20,20,0,0];
        _levelconfig[8] = [160,140,120,100,80,60,40,20,20,20];

        _tokens[0]=0x413F22Bacb885143dE12A77Da54d670Fc72bA2d6;
        _tokens[1]=0x3A6E7FDc786D7393522Bce1D2C266561fB1c6f53;
        _tokens[2]=0x7d09688b3fC4d14f4C306030584bd115Deb65E20;
        _tokens[3]=0x831E3301b28B7591d67256264963BD2292f385c4;
        _tokens[4]=0x8B5A8c9Aaf9018eaF056F94C568DdfBf0D6D2187;
        _tokens[5]=0x58f20dfB8B3415d315Dc544762815F241e901aa9;
        _tokens[6]=0xA7C01eF6f57e1b3456F7844EAc7Bc8C867121760;
        _tokens[7]=0xf592fAF13721839db3D743c13fC3dbf2179B9D30;
        _tokens[8]=0x6B2fa93ACE60ed4849017Af2a92d4Ecf3bD25D89;
        _tokens[9]=0xc073241C8B21ACA1A308aD08aa92d5D636b88dbe;
        _tokens[10]=0xF834e4aC0A142FF9BF293D227741c466233eB96d;
        _tokens[11]=0x01f3E62A6Ed4C8Fa98F5Cfc4336D99b44d963665;
        
    }

    function addDataManager(address user) public onlyOwner
    {
        _dataManager[user]=true;
    }

    function getMinerPoolAddress() public view returns (address) {
        return address(_minepool);
    }

    function StartMine() public onlyOwner
    {
        _lastupdateblock=block.number;
    }

 
    function fixUserInfo(address user,uint256 idx,uint256 val) public onlydataManager
    {
        _userInfo[user][idx]=val;
    }
 
    function InitalContract(
        address RomToken,
        address Romtrade,
        address bnbtradeaddress,
        address feeowner,
        address usdttoken
    ) public onlyOwner {
        require(_feeowner == address(0));
        _Romaddr = RomToken;
        _Romtrade = Romtrade;
        _bnbtradeaddress = bnbtradeaddress;
        _feeowner = feeowner;
        _minepool = new RomMinePool(RomToken, _owner);
        _creditPool = new RomMinePool(RomToken,_owner);
        _usdttoken= usdttoken;
    }

    function addTradingPool(
        address tokenAddress,
        address trade,
        uint256 rate,
        bool isusdt
    ) public onlyOwner returns (bool)  {
        require(rate>0,"error");
        _lpPools[tokenAddress].tradeContract=trade;
        _lpPools[tokenAddress].hashrate=rate;
        _lpPools[tokenAddress].isusdtcontract=isusdt;
        return true;
    }

     

    //******************Getters ******************/
    function getParent(address user) public view returns (address) {
        return _netdb.getParent(user);
    }

    function getTotalHash() public view returns (uint256) {
        return _totalhash;
    }

    function getUserInfo(address user,uint idx) public view returns (uint256)
    {
        return _userInfo[user][idx];
    }
    
    function FixHash(address user,uint256 dohash,bool add) public onlydataManager
    {
        _changeTeamhashonselfhashchanged(user,dohash,add);
    }

    function _changeTeamhashonselfhashchanged(address user,uint256 dohash,bool add) private
    {
        address parent = user;
        uint256 dthash = 0;
        for (uint256 i = 0; i < 10; i++) {
            parent = _netdb.getParent(parent);
            if (parent == address(0)) 
                break;

            if(add)
            {
                _userlevelhashtotal[parent][i] = _userlevelhashtotal[parent][i].add(dohash);
                uint256 parentlevel = _userInfo[parent][USERLEVELA];
                uint256 levelconfig = _levelconfig[parentlevel][i];
                if (levelconfig > 0) {
                    uint256 addhash = dohash.mul(levelconfig).div(1000);
                    if (addhash > 0) {
                        dthash = dthash.add(addhash);
                        UserHashChanged(parent, 0, addhash, true);
                    }
                }
            }
            else
            {
                if(_userlevelhashtotal[parent][i] > dohash)
                    _userlevelhashtotal[parent][i] = _userlevelhashtotal[parent][i].sub(dohash);
                else
                    _userlevelhashtotal[parent][i]=0;
                uint256 parentlevel = _userInfo[parent][USERLEVELA];
                uint256 pdechash = dohash.mul(_levelconfig[parentlevel][i]).div(1000);
                if (pdechash > 0) {
                    dthash = dthash.add(pdechash);
                    UserHashChanged(parent, 0, pdechash, false);
                }
            }
        }

        UserHashChanged(user, dohash, 0, add);
        logCheckPoint(dohash.add(dthash), add);
    } 

    function getExchangeCountOfOneUsdt(address lptoken)
        public
        view
        returns (uint256)
    {
        require(_lpPools[lptoken].tradeContract != address(0),"ERROR a");
         if (_lpPools[lptoken].isusdtcontract) //BNB
        {
            return  getExchangeCountOfOneUsdtA(_lpPools[lptoken].tradeContract);
        }
        else {
             return  getExchangeCountOfOneUsdtB(_bnbtradeaddress, _lpPools[lptoken].tradeContract, lptoken);
        }
 
    }


    function getExchangeCountOfOneUsdtA(address tradeaddress) private view returns (uint256)
    {
        (uint112 _reserve0, uint112 _reserve1, ) =IPancakePair(tradeaddress).getReserves();
            uint256 a = _reserve0;
            uint256 b = _reserve1;
            if(IPancakePair(tradeaddress).token0() == _usdttoken)
                return b.mul(1e18).div(a);
            else
                return a.mul(1e18).div(b);

    }


    function getExchangeCountOfOneUsdtB(address bnbtrade,address tradeaddress,address lptoken) private view returns (uint256)
    {
         (uint112 _reserve0, uint112 _reserve1, ) =
                IPancakePair(bnbtrade).getReserves();
            (uint112 _reserve3, uint112 _reserve4, ) =
                IPancakePair(tradeaddress).getReserves();

            uint256 balancea = _reserve0;
            uint256 balanceb = _reserve1;
            uint256 balancec = _reserve4;
            uint256 balanced = _reserve3;

            if(IPancakePair(tradeaddress).token0() == lptoken)
            {
                balancec=_reserve3;
                balanced=_reserve4;
            }
            if (balancea == 0 || balanceb == 0 || balanced == 0) return 0;
            return balancec.mul(1e18).div(balancea.mul(balanced).div(balanceb));
    }

    //******************Getters ************************************/

    function logCheckPoint(
        uint256 totalhashdiff,
        bool add
    ) private {

        if(block.number > _lastupdateblock)
        {
            uint256 totalhash=getTotalHash();
            uint256 behash =totalhash>=6e25?totalhash:6e25;
            uint256 addoneshar= cs.div(behash).mul(block.number.sub(_lastupdateblock));
            _oneshareget = _oneshareget.add(addoneshar);
            _lastupdateblock= block.number;
        }

        if (add) {
            _totalhash = _totalhash.add(totalhashdiff);
        } else {
            _totalhash = _totalhash.sub(totalhashdiff);
        }
    }

    function CorrectHashOnLevelChange(address user, uint256 newlevel) private
    {
        uint256 userlevel = _userInfo[user][USERLEVELA];
        if(userlevel==newlevel)
            return;

        uint256 oldteamhash = _userInfo[user][TEAMHASHA];
        uint256 newhash= 0;
        for (uint256 i = 0; i < 10; i++) 
        {
            if (_userlevelhashtotal[user][i] > 0 && _levelconfig[userlevel][i] > 0)
            {
                uint256 p=_userlevelhashtotal[user][i].mul(_levelconfig[newlevel][i]).div(1000);
                newhash = newhash.add(p);
            }
        }

        if(newhash==oldteamhash)
            return;

        if(newhash > oldteamhash )
        {
            UserHashChanged(user, 0, newhash.sub(oldteamhash), true);
            logCheckPoint(newhash.sub(oldteamhash), true);
        }
        else
        {
            UserHashChanged(user, 0, oldteamhash.sub(newhash), false);
            logCheckPoint(oldteamhash.sub(newhash), false);
        }
    }


    function getOneshareNow() public view returns (uint256)
    {
         uint256 oneshare=_oneshareget;
         
         if(_lastupdateblock>0)
         {
             
              if(block.number > _lastupdateblock)
            {
                uint256 totalhash= getTotalHash();
                uint256 behash =totalhash>=6e25?totalhash:6e25;
                oneshare= oneshare.add(cs.div(behash).mul(block.number.sub(_lastupdateblock)));
            }
         }
         return oneshare;
    }

    function CorrentUserLevel(address user) private
    {
  
         uint256 selfhash=_userInfo[user][SELFHASHA];
         uint256 newlevel=0;
        for(uint256 i=1;i<=8;i++)
        {
            if(selfhash >= _holdhash[i])
                newlevel=i;
            else
                break;
        }
        CorrectHashOnLevelChange(user,newlevel);
        _userInfo[user][USERLEVELA]= newlevel;
    } 

    function getUserSelfHash(address user) public view returns (uint256) {
        return _userInfo[user][SELFHASHA].add(_userInfo[user][SXHASH]);
    }

    function getUserTeamHash(address user) public view returns (uint256) {
        return _userInfo[user][TEAMHASHA];
    }
 

    function getPendingCoin(address user) public view returns (uint256) {
    
        uint256 selfhash=getUserSelfHash(user).add(_userInfo[user][TEAMHASHA]);
        uint256  pending;
        uint256 oneshare=getOneshareNow();
        if(selfhash>0)
        {
            uint256 cashedjt=_userInfo[user][TAKEDJT];
            uint256 newp =0;
            if(oneshare > cashedjt)
               newp = selfhash.mul(oneshare.sub(cashedjt)).div(1e32);

            pending=_userInfo[user][PENDINGJTA].add(newp);
        }
        else
        {
            pending=_userInfo[user][PENDINGJTA];
        }
       
        return pending;
    }


    function SxHashChanged(
        address user,
        uint256 selfhash,
        bool add
    ) private { 
        uint256 phash = getUserSelfHash(user).add(getUserTeamHash(user));
        if(phash>0)
        {
            _userInfo[user][PENDINGJTA]= getPendingCoin(user);
        }

        _userInfo[user][TAKEDJT] =getOneshareNow();
        if (selfhash > 0) {
            if (add) {
                _userInfo[user][SXHASH] = _userInfo[user][SXHASH].add(selfhash);
                 emit SelfHashChanged(selfhash,add);
            } else 
                _userInfo[user][SXHASH] = _userInfo[user][SXHASH].sub(selfhash);
        }

        logCheckPoint(selfhash, add);
    }
 
    function UserHashChanged(
        address user,
        uint256 selfhash,
        uint256 teamhash,
        bool add
    ) private { 
        uint256 phash = getUserSelfHash(user).add(getUserTeamHash(user));
        if(phash>0)
        {
            _userInfo[user][PENDINGJTA]= getPendingCoin(user);
        }

        _userInfo[user][TAKEDJT] =getOneshareNow();
        if (selfhash > 0) {
            if (add) {
                _userInfo[user][SELFHASHA] = _userInfo[user][SELFHASHA].add(selfhash);
                 
            } else 
                _userInfo[user][SELFHASHA] = _userInfo[user][SELFHASHA].subwithlesszero(selfhash);

            CorrentUserLevel(user);
            emit SelfHashChanged(selfhash,add);
        }
        if (teamhash > 0) {
            if (add) {
                _userInfo[user][TEAMHASHA] = _userInfo[user][TEAMHASHA].add(teamhash);
            } else {
                 _userInfo[user][TEAMHASHA] = _userInfo[user][TEAMHASHA].subwithlesszero(teamhash);
            }
        }
    }

    function WithDrawCredit() public nonReentrant returns (bool) {
        address user =msg.sender;
        uint256 send=getPendingCoin(user);
        uint256 fee = send.div(20);
        uint256 give=send.sub(fee);

        uint256 cutprice = getExchangeCountOfOneUsdt(_Romaddr);

        if(_userInfo[user][SELFHASHA] > 0)
        {
            uint256 decVal = give.mul(1e18).div(cutprice).div(3);

            if(_userInfo[user][TOTALSTACKVALUE] > decVal)
            {
                uint256 dechash = decVal.mul(_userInfo[user][SELFHASHA]).div(_userInfo[user][TOTALSTACKVALUE]);
                _changeTeamhashonselfhashchanged(user,dechash,false);
            } 
            else
                _changeTeamhashonselfhashchanged(user,_userInfo[user][SELFHASHA],false);
        }
        _userInfo[user][PENDINGJTA]=0;
        _userInfo[user][TAKEDJT] =getOneshareNow();
        _minepool.MineOut(user,give);
        _minepool.MineOut(address(_creditPool), fee);
        return true;
    }
  

    function getPower(address tokenAddress,uint256 amount) public view returns (uint256) {
        uint256 hashb =amount.mul(1e18).div(getExchangeCountOfOneUsdt(tokenAddress));
        hashb=hashb.mul(_lpPools[tokenAddress].hashrate).div(100);
        return hashb;
    }

    function StackSx(uint product) public nonReentrant  
    {
        require(product>0 && product <5,"error prroduct");

        if(block.timestamp > _nextNew)
        {
            _lefthash=_behash;
            _nextNew=_nextNew+86400;
        }

        address user=msg.sender;
        uint256 amount=1e8;
        IBEP20(_tokens[0]).burnFrom(user, amount);
        IBEP20(_tokens[1]).burnFrom(user, amount);
        IBEP20(_tokens[2]).burnFrom(user, amount);
        IBEP20(_tokens[3]).burnFrom(user, amount);
        IBEP20(_tokens[4]).burnFrom(user, amount);
        IBEP20(_tokens[5]).burnFrom(user, amount);
        IBEP20(_tokens[6]).burnFrom(user, amount);
        IBEP20(_tokens[7]).burnFrom(user, amount);
        IBEP20(_tokens[8]).burnFrom(user, amount);

        if(product==1)
        {
            _lefthash=_lefthash.sub(1500*1e18);
            SxHashChanged(user,1500*1e18,true);
            return;
        }


        if(product==2)
        {
            _lefthash=_lefthash.sub(2500*1e18);
            IBEP20(_tokens[9]).burnFrom(user, amount);
            SxHashChanged(user,2500*1e18,true);
            return;
        }


        if(product==3)
        {
             _lefthash=_lefthash.sub(5000*1e18);
            IBEP20(_tokens[9]).burnFrom(user, amount);
            IBEP20(_tokens[10]).burnFrom(user, amount);
            SxHashChanged(user,5000*1e18,true);
            return;
        }

        if(product==4)
        {
            _lefthash=_lefthash.sub(15000*1e18);
            IBEP20(_tokens[9]).burnFrom(user, amount);
            IBEP20(_tokens[10]).burnFrom(user, amount);
            IBEP20(_tokens[11]).burnFrom(user, amount);
            SxHashChanged(user,15000*1e18,true);
            return;
        }
         
    }
 
    function StackToken(address tokenaddress,uint256 amount) public nonReentrant
    {
        address user=msg.sender;
        uint256 price = getExchangeCountOfOneUsdt(tokenaddress);
        uint256 valueds= amount.mul(1e18).div(price);
        uint256 hashb = valueds.mul(_lpPools[tokenaddress].hashrate).div(100);
        _userInfo[user][TOTALSTACKVALUE] = _userInfo[user][TOTALSTACKVALUE].add(valueds);
        IBEP20(tokenaddress).burnFrom(user,amount);
        _changeTeamhashonselfhashchanged(user,hashb,true);
    }


}