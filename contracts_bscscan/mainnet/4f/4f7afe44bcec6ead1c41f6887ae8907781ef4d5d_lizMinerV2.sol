// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.0;

import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./TransferHelper.sol";
import "./IBEP20.sol";
import "./LpWallet.sol";
import "./LizMinePool.sol";

interface IlizMiner
{
    function getMyLpInfo(address user, address tokenaddress)
        external
        view
        returns (uint256[3] memory);
        function getPendingCoin(address user) external view returns (uint256);
        function getParent(address user) external view returns (address);
        function getUserLevel(address user) external view returns (uint256);
        function getUserTeamHash(address user) external view returns (uint256);
        function getUserSelfHash(address user) external view returns (uint256);
        function getTotalHash() external view returns (uint256);
        function getMyLpInfoV2(address user, address tokenaddress)  external view  returns (uint256[3] memory);
        function getUserInfo(address user,uint idx) external view returns (uint256);
        function getWalletAddress(address lptoken) external view returns (address);
        function getRoomHash(address user) external view returns (uint256);
        function getPendingMull(address user) external view returns(uint256);
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

 
contract lizMinerV2 is ReentrancyGuard {
    using TransferHelper for address;
    using SafeMath for uint256;
    address private _lizaddr;
    address private _liztrade;
    address private _bnbtradeaddress;
    address private _owner;
    address private _feeowner;
    address private _mull;
    address private _nftcontract;
 
    IlizMiner private _lastminer;
    IlizMiner private _oominer;
    uint256 cs=1e40;
    LizMinePool private _minepool;
  
    mapping(uint256 => uint256[20]) internal _levelconfig; //credit level config
    uint256 _totalhash;
    uint256 _oneshareget;
    uint256 _lastupdateblock;
    uint256[8] _vipbuyprice = [0, 100, 300, 500, 800, 1200, 1600, 2000];
 

    mapping(address => mapping(address => uint256)) _userLphashv2;
    mapping(address => mapping(uint256 => uint256)) _userlevelhashtotal; // level hash in my team
    mapping(address => address) internal _parents; //Inviter
    mapping(address => PoolInfo) _lpPools;
    mapping(address => address[]) _mychilders;
    mapping(uint256 => uint256) _pctRate;
    mapping(address=>bool) _dataManager;
    mapping(address=>mapping(address=>uint256)) _userChildTotal;

    struct PoolInfo {
        LpWallet poolwallet;
        address tradeContract;
        uint256 minpct;
        uint256 maxpct;
    }
    mapping(address=>mapping(uint=>uint256)) _userInfo;
    uint immutable USERLEVELA=1;
    uint immutable SELFHASHA=2;
    uint immutable TEAMHASHA =3;
    uint immutable PENDINGCOIN=4;
    uint immutable TAKEDCOIN =5;
    uint immutable PENDINGMULL=6;
    uint immutable V1HASH=7;
    address[] _lpaddresses;

     modifier onlydataManager() {
        require(_dataManager[msg.sender], 'auth');
        _;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, 'Mr');
        _;
    }
 
    constructor(address lastminer,address oominer) {
        _owner = msg.sender;
        _lastminer= IlizMiner(lastminer);
        _oominer = IlizMiner(oominer);
        _lastupdateblock=0;//project start
        _dataManager[_owner]=true;
    }

    function setartCoin() public onlyOwner
    {
        _lastupdateblock=block.number;
    }

    function addDataManager(address user) public onlyOwner
    {
        _dataManager[user]=true;
    }

    function setNftContract(address nft) public onlyOwner
    {
        _nftcontract=nft;
    }

    function getMinerPoolAddress() public view returns (address) {
        return address(_minepool);
    }

    function setPctRate(uint256 pct, uint256 rate) public  onlyOwner{
        _pctRate[pct] = rate;
    }

    function getHashRateByPct(uint256 pct) public view returns (uint256) {
        if (_pctRate[pct] > 0) return _pctRate[pct];
        return 100;
    }

    function getTotalHash() public view returns (uint256) {
        return _totalhash;
    }

    function fixTradingPool(
        address tokenAddress,
        address tradecontract,
        uint256 pctmin,
        uint256 pctmax
    ) public returns (bool) {
        require(msg.sender == _owner);
        _lpPools[tokenAddress].tradeContract = tradecontract;
        _lpPools[tokenAddress].minpct = pctmin;
        _lpPools[tokenAddress].maxpct = pctmax;
        return true;
    }

    function fixUserInfo(address user,uint[] memory idx,uint256[] memory val) public onlydataManager
    {
         require(idx.length== val.length);
         for(uint i=0;i<idx.length;i++)
            _userInfo[user][idx[i]]=val[i];
    }

    function getMyChilders(address user) public view returns (address[] memory)
    {
        return _mychilders[user];
    }
 
    function InitalContract(
        address lizToken,
        address liztrade,
        address bnbtradeaddress,
        address feeowner,
        address mull
    ) public onlyOwner {
        require(_feeowner == address(0));
        _lizaddr = lizToken;
        _liztrade = liztrade;
        _bnbtradeaddress = bnbtradeaddress;
        _feeowner = feeowner;
        _mull=mull;
        _minepool = new LizMinePool(lizToken, _owner);
        _parents[msg.sender] = address(_minepool);
 
        _pctRate[70] = 120;
        _pctRate[50] = 150;
        _pctRate[100] = 200;
        _levelconfig[0] = [100,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
        _levelconfig[1] = [150,100,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
        _levelconfig[2] = [160,110,90,60,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
        _levelconfig[3] = [170,120,100,70,40,30,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
        _levelconfig[4] = [180,130,110,80,40,30,20,10,0,0,0,0,0,0,0,0,0,0,0,0];
        _levelconfig[5] = [200,140,120,90,40,30,20,10,10,10,10,10,0,0,0,0,0,0];
        _levelconfig[6] = [220,160,140,100,40,30,20,10,10,10,10,10,10,10,10,0,0];
        _levelconfig[7] = [250,180,160,110,40,30,20,10,10,10,10,10,10,10,10,10,10];
    }

    function addTradingPool(
        address tokenAddress,
        address tradecontract,
 
        uint256 pctmin,
        uint256 pctmax
    ) public onlyOwner returns (bool)  {
        require(_lpPools[tokenAddress].maxpct == 0, "C");
        LpWallet wallet =LpWallet(_lastminer.getWalletAddress(tokenAddress));
            
        _lpPools[tokenAddress] = PoolInfo({
            poolwallet: wallet,
            tradeContract: tradecontract,
            minpct: pctmin,
            maxpct: pctmax
        });
        _lpaddresses.push(tokenAddress);
        return true;
    }

    // //******************Getters ******************/
    function getParent(address user) public view returns (address) {
        return _parents[user];
    }

    function getMyLpInfoV2(address user, address tokenaddress)  public view  returns (uint256[3] memory)
    {
        uint256[3] memory bb;
        bb[0] = _lpPools[tokenaddress].poolwallet.getBalance(user, true);
        bb[1] = _lpPools[tokenaddress].poolwallet.getBalance(user, false);
        bb[2] = _userLphashv2[user][tokenaddress];
        return bb;
    }

    function getMyLpInfoV1(address user, address tokenaddress)  public view  returns (uint256[3] memory)
    {
        return  _oominer.getMyLpInfo(user, tokenaddress);
    }

    function getRoomHash(address user) external view returns (uint256)
    {
        return _userLphashv2[user][address(3)];
    }

    function getUserDhash(address user,address child) external view returns (uint256)
    {
        return _userChildTotal[user][child];
    }

     function MappingUserFromOld(address user) public onlyOwner {
         require( _parents[user]==address(0),"binded");
         address parentk=_lastminer.getParent(user);
         _parents[user] = parentk;
        _mychilders[parentk].push(user);
        _userInfo[user][USERLEVELA] = _lastminer.getUserLevel(user);
        _userInfo[user][PENDINGCOIN] = _lastminer.getPendingCoin(user);
        _userInfo[user][PENDINGMULL] = _lastminer.getPendingMull(user);

        uint256 jthashold =  _oominer.getUserSelfHash(user);
        _userInfo[user][V1HASH] = jthashold;
        uint256 jthashnew = _lastminer.getUserSelfHash(user);

        uint256 roomhash = _lastminer.getRoomHash(user);
        if(roomhash>0)
            _userLphashv2[user][address(3)]= roomhash;
         
        if(jthashold.add(roomhash) != jthashnew)
        {
            jthashnew=jthashold.add(roomhash);

            for (uint256 m = 0; m < _lpaddresses.length; m++)
            {
                address tokenAddress = _lpaddresses[m];
                uint256[3] memory info = _lastminer.getMyLpInfoV2(user, tokenAddress);
                if (info[0] > 0) {
                    _userLphashv2[user][tokenAddress] = info[2];
                    jthashnew= jthashnew.add(info[2]);
                }
            }
        }
 
        if(jthashnew > 0)
        {
            _userInfo[user][SELFHASHA]=jthashnew;
            address parent = user;
            uint256 total = jthashnew;
    
            for (uint256 i = 0; i < 20; i++) {
                parent = _lastminer.getParent(parent);
                if (parent == address(0)) {break;}

                    uint256 parentself= _lastminer.getUserSelfHash(parent).mul(3);
                    if(parentself==0)
                    {
                        continue;
                    }
                    uint256 totalhash=jthashnew;
                    if(parentself < totalhash)
                    {
                        totalhash = parentself;
                    }
                    _userlevelhashtotal[parent][i] = _userlevelhashtotal[parent][i].add(totalhash);
        
                    uint256 levelconfig = _levelconfig[_lastminer.getUserLevel(parent)][i];
                    if (levelconfig > 0) 
                    {
                        uint256 addhash = totalhash.mul(levelconfig).div(1000);
                        if (addhash > 0) {
                            total=total.add(addhash);
                            _userInfo[parent][TEAMHASHA] = _userInfo[parent][TEAMHASHA].add(addhash);
                        }
                    }
                
                    _userChildTotal[parent][user]= totalhash;
            }

            _totalhash= _totalhash.add(total);
        }
      
    }
 
    function getUserInfo(address user,uint idx) public view returns (uint256)
    {
        return  _userInfo[user][idx];
    }
 
    function getUserLevel(address user) external view returns (uint256) {
        return _userInfo[user][USERLEVELA] ;
    }

    function getUserTeamHash(address user) public view returns (uint256) {
        return _userInfo[user][TEAMHASHA];
    }

    function getUserSelfHash(address user) public view returns (uint256) {
        return _userInfo[user][SELFHASHA];
    }

    function getUserLevelHashTotal(address user,uint256 level) public view returns (uint256)
    {
        return _userlevelhashtotal[user][level];
    }

    function getExchangeCountOfOneUsdtA(address tradeaddress) private view returns (uint256)
    {
        (uint112 _reserve0, uint112 _reserve1, ) =IPancakePair(tradeaddress).getReserves();
            uint256 a = _reserve0;
            uint256 b = _reserve1;
            return b.mul(1e18).div(a);
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

    function getExchangeCountOfOneUsdt(address lptoken) public view returns (uint256)
    {
        require(_lpPools[lptoken].tradeContract != address(0));

        if (lptoken == address(2) || lptoken == _lizaddr) //BNB
        {
            return  getExchangeCountOfOneUsdtA(lptoken == _lizaddr?_liztrade:_bnbtradeaddress);
        }
        else {
             return  getExchangeCountOfOneUsdtB(_bnbtradeaddress, _lpPools[lptoken].tradeContract, lptoken);
        }
    }

 
    // // //******************Getters ************************************/
    function getWalletAddress(address lptoken) public view returns (address) {
        return address(_lpPools[lptoken].poolwallet);
    }

    function logCheckPoint(
        uint256 totalhashdiff,
        bool add
    ) private {

        if(block.number > _lastupdateblock)
        {
            uint256 totalhash=getTotalHash();
            uint256 behash =totalhash>=1e25?totalhash:1e25;
            uint256 addoneshar= cs.div(behash).mul(block.number.sub(_lastupdateblock));
            _oneshareget = _oneshareget.add(addoneshar);
            _lastupdateblock= block.number;
        }

        if (add) {
            _totalhash = _totalhash.add(totalhashdiff);
        } else {
            _totalhash = _totalhash.subwithlesszero(totalhashdiff);
        }
    }

    function getHashDiffOnLevelChange(address user, uint256 newlevel)
        private
        view
        returns (uint256)
    {
        uint256 hashdiff = 0;
        uint256 userlevel = _userInfo[user][USERLEVELA];
        for (uint256 i = 0; i < 20; i++) {
            if (_userlevelhashtotal[user][i] > 0) {
                if (_levelconfig[userlevel][i] > 0) {
                    uint256 dff =
                        _userlevelhashtotal[user][i]
                            .mul(_levelconfig[newlevel][i])
                            .subwithlesszero(
                            _userlevelhashtotal[user][i].mul(
                                _levelconfig[userlevel][i]
                            )
                        );
                    dff = dff.div(1000);
                    hashdiff = hashdiff.add(dff);
                } else {
                    uint256 dff =
                        _userlevelhashtotal[user][i]
                            .mul(_levelconfig[newlevel][i])
                            .div(1000);
                    hashdiff = hashdiff.add(dff);
                }
            }
        }
        return hashdiff;
    }


    function buyVipPrice(address user, uint256 newlevel)
        public
        view
        returns (uint256)
    {
        if (newlevel >= 8) return 1e50;
        uint256 userlevel = _userInfo[user][USERLEVELA];
        require (userlevel < newlevel,"D");
        uint256 costprice = _vipbuyprice[newlevel] - _vipbuyprice[userlevel];
        uint256 costcount = costprice.mul(getExchangeCountOfOneUsdt(_lizaddr));
        return costcount;
    }

    function buyVip(uint256 newlevel) public nonReentrant returns (bool) {
        require(newlevel < 8,"ERROR A");
        address user=msg.sender;
        require(_parents[user] != address(0), "must bind");

        uint256 costcount = buyVipPrice(user, newlevel);
        require(costcount > 0,"ERROR b");
        uint256 diff = getHashDiffOnLevelChange(user, newlevel);
        if (diff > 0) {
            UserHashChanged(user, 0, diff, true);
            logCheckPoint(diff, true);
        }

        IBEP20(_lizaddr).burnFrom(user, costcount);
        _userInfo[user][USERLEVELA] = newlevel;
        return true;
    }

    function bindParent(address parent) public {
        require(_parents[msg.sender] == address(0), "Already bind");
        require(parent != address(0));
        require(parent != msg.sender);
        require(_parents[parent] != address(0));
        _parents[msg.sender] = parent;
        _mychilders[parent].push(msg.sender);
    }


    function getOneshareNow() public view returns (uint256)
    {
         uint256 oneshare=_oneshareget;
         
         if(_lastupdateblock>0)
         {
             
              if(block.number > _lastupdateblock)
            {
                uint256 totalhash= getTotalHash();
                uint256 behash =totalhash>=1e25?totalhash:1e25;
                oneshare= oneshare.add(cs.div(behash).mul(block.number.sub(_lastupdateblock)));
            }
         }
         return oneshare;
    }

    function getPendingMull(address user) public view returns(uint256)
    {
        uint256 myhash=_userLphashv2[user][address(3)];
 
        uint256 oneshare=getOneshareNow();
        if(myhash>0)
        {
            uint256 cashed=_userInfo[user][TAKEDCOIN];
            uint256 newp =0;
            if(oneshare > cashed)
               newp = myhash.mul(oneshare.subwithlesszero(cashed)).div(1e28);

            return _userInfo[user][PENDINGMULL].add(newp);
        }
        else
        {
            return _userInfo[user][PENDINGMULL];
        }
    }

    function getPendingCoin(address user) public view returns (uint256) {
    
        uint256 myhash=getUserSelfHash(user).add(getUserTeamHash(user));
 
        uint256 oneshare=getOneshareNow();
        if(myhash>0)
        {
            uint256 cashed=_userInfo[user][TAKEDCOIN];
            uint256 newp =0;
            if(oneshare > cashed)
               newp = myhash.mul(oneshare.subwithlesszero(cashed)).div(1e32);

            return _userInfo[user][PENDINGCOIN].add(newp);
        }
        else
        {
            return _userInfo[user][PENDINGCOIN];
        }
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
            _userInfo[user][PENDINGCOIN]= getPendingCoin(user);
        }
        if(_userLphashv2[user][address(3)] > 0)
        {
            _userInfo[user][PENDINGMULL]= getPendingMull(user);
        }
        _userInfo[user][TAKEDCOIN] = getOneshareNow();
       
        if (selfhash > 0) {

            if (add) {
                _userInfo[user][SELFHASHA] = _userInfo[user][SELFHASHA].add(selfhash);
            } else 
                _userInfo[user][SELFHASHA] = _userInfo[user][SELFHASHA].subwithlesszero(selfhash);
            
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
        uint256 mull=getPendingMull(user);
        if(send<100)
            return true;
        _userInfo[user][PENDINGMULL]=0;
        _userInfo[user][PENDINGCOIN]=0;
        _userInfo[user][TAKEDCOIN] = getOneshareNow();
        uint256 fee= send.div(100);
         _minepool.MineOut(user, send.subwithlesszero(fee),fee);
         if(mull>0)
        {
            IBEP20(_mull).mint(user, mull);
        }
        return true;
    }

     function takeBackNft(address user,uint256 decreasehash) public returns(bool)
     {
        require(msg.sender==_nftcontract);
        ChangeTeamhashatUserHashChanged(user,decreasehash,false);
        _userLphashv2[user][address(3)] = _userLphashv2[user][address(3)].sub(decreasehash);
        return true;
     }

    function TakeBackV1(address user) public onlydataManager
    {
        uint256 v1nowhash = _oominer.getUserSelfHash(user);
        uint256 decreasehash = _userInfo[user][V1HASH].subwithlesszero(v1nowhash);
        _userInfo[user][V1HASH]=v1nowhash;
        if(decreasehash > 0)
            ChangeTeamhashatUserHashChanged(user,decreasehash,false);
    }
  
    function TakeBack(address tokenAddress, uint256 pct) public
        nonReentrant
        returns (bool)
    {
        require(pct >= 10000 && pct <= 1000000,"ERROR PCT");
        address user = tx.origin;
        uint256 totalhash = _userLphashv2[user][tokenAddress];
        uint256 amounta = _lpPools[tokenAddress].poolwallet.getBalance(user, true).mul(pct).div(1000000);
        uint256 amountb = _lpPools[tokenAddress].poolwallet.getBalance(user, false).mul(pct).div(1000000);
        uint256 decreasehash =totalhash.mul(pct).div(1000000);
        _userLphashv2[user][tokenAddress] = _userLphashv2[user][tokenAddress].subwithlesszero(decreasehash);
        ChangeTeamhashatUserHashChanged(user,decreasehash,false);
        if(amounta > 0)
            _lpPools[tokenAddress].poolwallet.TakeBack(user,amounta,amountb);
        return true;
    }

    function showUserInfo(address user) public view returns(uint256[10] memory result)
    {
        for(uint i=0;i<8;i++)
            result[i]=_userInfo[user][i+1];
    }

    function getPower(
        address tokenAddress,
        uint256 amount,
        uint256 lpscale
    ) public view returns (uint256) {
        uint256 hashb =
            amount.mul(1e20).div(lpscale).div(getExchangeCountOfOneUsdt(tokenAddress));
            return hashb;
    }

    function getLpPayliz(
        address tokenAddress,
        uint256 amount,
        uint256 lpscale
    ) public view returns (uint256) {
        require(lpscale <= 100);
        uint256 hashb =
            amount.mul(1e20).div(lpscale).div(
                getExchangeCountOfOneUsdt(tokenAddress)
            );
        uint256 costabc =
            hashb
                .mul(getExchangeCountOfOneUsdt(_lizaddr))
                .mul(100 - lpscale)
                .div(1e20);
        return costabc;
    }

    function ChangeTeamhashatUserHashChanged(address user,uint256 shash,bool add) private
    {
          address parent = user;
        uint256 dhasha = 0;
        uint256 dhashb=0;
        uint256 useroldhash =_userInfo[parent][SELFHASHA];

        for (uint256 i = 0; i < 20; i++) {
            parent = getParent(parent);
            if (parent == address(0)) {break;}

                uint256 parentself= _userInfo[parent][SELFHASHA].mul(3);
                uint256 totalhash=useroldhash;
                if(add)
                    totalhash=totalhash.add(shash);
                else
                    totalhash=totalhash.subwithlesszero(shash);

                if(parentself < totalhash)
                {
                    totalhash = parentself;
                }
                uint256 diff=_userChildTotal[parent][user];
                if(totalhash >= diff)
                {
                    uint256 basehash=totalhash.sub(diff);
                    _userlevelhashtotal[parent][i] = _userlevelhashtotal[parent][i].add(basehash);
     
                    uint256 levelconfig = _levelconfig[_userInfo[parent][USERLEVELA]][i];
                     if (levelconfig > 0) 
                     {
                         uint256 addhash = basehash.mul(levelconfig).div(1000);
                         if (addhash > 0) {
                             dhasha = dhasha.add(addhash);
                             UserHashChanged(parent, 0, addhash, true);
                         }
                     }
                }
                else
                {
                    uint256 basehash=diff.subwithlesszero(totalhash);
                     _userlevelhashtotal[parent][i] = _userlevelhashtotal[parent][i].subwithlesszero(basehash);
                      uint256 levelconfig = _levelconfig[_userInfo[parent][USERLEVELA]][i];
                     if (levelconfig > 0) {
                        uint256 addhash = basehash.mul(levelconfig).div(1000);
                        if (addhash > 0) {
                            dhashb = dhashb.add(addhash);
                            UserHashChanged(parent, 0, addhash, false);
                        }
                     }
                }
                _userChildTotal[parent][user]= totalhash;
        }
        UserHashChanged(user, shash, 0, add);
        if(dhasha.add(shash)> dhashb)
            logCheckPoint(shash.add(dhasha).sub(dhashb), true);
        else
            logCheckPoint(dhashb.subwithlesszero(shash.add(dhasha)), false);
    }

   

    function depositNft(address user,uint256 hashjtget) external returns (bool)
    {
        require(msg.sender==_nftcontract);
        ChangeTeamhashatUserHashChanged(user,hashjtget,true);
         _userLphashv2[user][address(3)] = _userLphashv2[user][address(3)].add(hashjtget);
        return true;
    }

    function deposit(address tokenAddress,uint256 amount,uint256 dppct) public payable nonReentrant returns (bool) {
        if (tokenAddress == address(2)) {
            amount = msg.value;
        }
        require(amount > 10000);
        address user=msg.sender;
        require(dppct >= _lpPools[tokenAddress].minpct, "aa");
        require(dppct <= _lpPools[tokenAddress].maxpct, "bb");
        uint256 price = getExchangeCountOfOneUsdt(tokenAddress);
        uint256 lizprice = getExchangeCountOfOneUsdt(_lizaddr);
        uint256 hashjtget = amount.mul(1e20).div(dppct).div(price); // getPower(tokenAddress,amount,dppct);
        uint256 costliz = hashjtget.mul(lizprice).mul(100 - dppct).div(1e20);
        hashjtget = hashjtget.mul(getHashRateByPct(dppct)).div(100);
        uint256 abcbalance = IBEP20(_lizaddr).balanceOf(user);

        if (abcbalance < costliz) {
            amount = amount.mul(abcbalance).div(costliz);
            hashjtget = hashjtget.mul(abcbalance).div(costliz);
            costliz = abcbalance;
        }
        if (tokenAddress == address(2)) {
            if (msg.value > amount)  {TransferHelper.safeTransferBNB(user, msg.value - amount);}

             _lpPools[tokenAddress].poolwallet.addBalance{value:amount}(user,amount,costliz);
        } else {
                tokenAddress.safeTransferFrom(user,address(_lpPools[tokenAddress].poolwallet),amount);
             _lpPools[tokenAddress].poolwallet.addBalance{value:0}(user, amount,costliz);
        }

        if (costliz > 0)
           _lizaddr.safeTransferFrom(user,address(_lpPools[tokenAddress].poolwallet),costliz);
 
        
        ChangeTeamhashatUserHashChanged(user,hashjtget,true);
        _userLphashv2[user][tokenAddress] = _userLphashv2[user][tokenAddress].add(hashjtget);
        return true;
    }
}