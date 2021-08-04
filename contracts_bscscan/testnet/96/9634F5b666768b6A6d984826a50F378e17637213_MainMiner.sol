// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.0;

import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./TransferHelper.sol";
import "./IBEP20.sol";
import "./LpWallet.sol";
import "./MainMinePool.sol";
import "./Computer.sol";

 
contract MainMiner is ReentrancyGuard {
    using TransferHelper for address;
    using SafeMath for uint256;
    address private _mainaddr;
    address private _maintrade;
    address private _bnbtradeaddress;
    address private _owner;
    address private _feeowner;

    Computer _icomputer;

    uint256 _cs = 200*1e40; // 32 + 8
    uint256 _maxhash = 2e25; // 7 + 18
    
    MainMinePool private _minepool;
    MainMinePool private _cutpool;

    uint256 _totalhash;
    uint256 _oneshareget;
    uint256 _onecut;
    uint256 _lastupdateblock;
    uint256 _feeamount = 1; // 1U
    bool _takeout = true;
    
    event WithDrawCredit(address indexed sender, uint256 jtamount, uint256 dtamount, uint256 cutamount, uint256 feeamount);
    
    uint256 _maxdept = 20; // reward dept
    mapping(uint256 => uint256[20]) internal _levelconfig; //credit level config
    mapping(address => mapping(address => uint256)) _userLphash;
    mapping(address => mapping(uint256 => uint256)) _userlevelhashtotal; // level hash in my team
    mapping(address => address) internal _parents; //Inviter
    mapping(address => PoolInfo) _lpPools;
    mapping(address => address[]) _mychilders;
    mapping(uint256 => uint256) _pctRate;
    mapping(address=>bool) _dataManager;

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
    uint immutable PENDINGJTA=4;
    uint immutable PENDINGDTA=5;
    uint immutable PENDINGCUTA=6;
    uint immutable TAKEDJT =7;
    uint immutable TAKEDDT =8;
    uint immutable TAKEDCUT=9;
    uint immutable TOTALDESTORYA=10;
    uint immutable REALGETA=11;
    uint immutable REALGETJTA=12;
    uint immutable REALGETDTA=13;
    uint immutable TEAMCOUNT=14;

    address[] _lpaddresses;

    
    uint256[9] _holdhash = [100 * 1e18, 200 * 1e18, 300 * 1e18, 500 * 1e18, 1000 * 1e18, 2000 * 1e18, 4000 * 1e18, 6000 * 1e18, 10000 * 1e18];

     modifier onlydataManager() {
        require(_dataManager[msg.sender], 'auth');
        _;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, 'Mr');
        _;
    }
 
    constructor(uint256 cs, uint256 maxhash) {
        _owner = msg.sender;
        _lastupdateblock=block.number + 200;//project start
        _cs = cs * 1e40; // 32 + 8 default 200
        _maxhash = maxhash * 1e18; // default 2000w
        _icomputer = new Computer(_cs, _maxhash);
        _dataManager[_owner]=true;
    }

    function addDataManager(address user) public onlyOwner
    {
        _dataManager[user]=true;
    }

    function getMinerPoolAddress() public view returns (address) {
        return address(_minepool);
    }

    function getCutPool() public view returns (address)
    {
        return address(_cutpool);
    }

    function setPctRate(uint256 pct, uint256 rate) public  onlyOwner{
        _pctRate[pct] = rate;
    }
    
    function getHashRateByPct(uint256 pct) public view returns (uint256) {
        if (_pctRate[pct] > 0) return _pctRate[pct];
        return 100;
    }
    
    function setFeeAmount(uint256 feeamount) public onlyOwner
    {
        _feeamount = feeamount;
    }
    
    function setTakeout(bool takeout) public onlyOwner
    {
        _takeout = takeout;
    }

    function AddOneCut(uint256 num) public 
    {
        require(msg.sender==_mainaddr || msg.sender==_owner,"A");
        uint256 totalhash=getTotalHash();
        if(totalhash > 0)
            _onecut=_onecut.add(num.mul(1e32).div(totalhash));
    }

    function fixUserInfo(address user,uint[] memory idx,uint256[] memory val) public onlydataManager
    {
         require(idx.length== val.length);
         for(uint i=0;i<idx.length;i++)
            _userInfo[user][idx[i]]=val[i];
    }

    function getMyChilders(address user)
        public
        view
        returns (address[] memory)
    {
        return _mychilders[user];
    }
 
    function InitalContract(
        address tokenAddress,
        address tokenTrade,
        address bnbtradeaddress,
        address feeowner,
        uint256 maxdept
    ) public onlyOwner {
        require(_feeowner == address(0));
        _mainaddr = tokenAddress;
        _maintrade  = tokenTrade;
        _bnbtradeaddress = bnbtradeaddress;
        _feeowner = feeowner;
        _minepool = new MainMinePool(tokenAddress, _owner);
        _cutpool = new MainMinePool(tokenAddress, _owner);
        _parents[msg.sender] = address(_minepool);
        
        // _pctRate[90] = 50;
        // _pctRate[70] = 120;
        // _pctRate[50] = 140;
        _pctRate[0]  = 150;
        _levelconfig[0] = [ 50,  0,  0,  0,  0,  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        _levelconfig[1] = [ 80, 50,  0,  0,  0,  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        _levelconfig[2] = [100, 60, 40, 20,  0,  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        _levelconfig[3] = [120, 80, 60, 40, 20, 20, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        _levelconfig[4] = [140,100, 80, 60, 40, 20,20,20, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        _levelconfig[5] = [160,120,100, 80, 60, 40,20,20,20,20,20,20, 0, 0, 0, 0, 0, 0, 0, 0];
        _levelconfig[6] = [180,140,120,100, 80, 60,40,20,20,20,20,20,20,20,20,20, 0, 0, 0, 0];
        _levelconfig[7] = [200,160,140,120,100, 80,60,40,20,20,20,20,20,20,20,20,20,20, 0, 0];
        _levelconfig[8] = [220,180,160,140,120,100,80,60,40,20,20,20,20,20,20,20,20,20,20,20];
        _maxdept = maxdept; // default 20
    }

    function addTradingPool(
        address tokenAddress,
        address tradecontract,
        uint256 pctmin,
        uint256 pctmax
    ) public onlyOwner returns (bool)  {
        require(_lpPools[tokenAddress].maxpct == 0, "C");

        LpWallet wallet = new LpWallet(tokenAddress, _mainaddr, _feeowner, _owner);
        _lpPools[tokenAddress] = PoolInfo({
            poolwallet: wallet,
            tradeContract: tradecontract,
            minpct: pctmin,
            maxpct: pctmax
        });
        _lpaddresses.push(tokenAddress);
        return true;
    }

    //******************Getters ******************/
    function getParent(address user) public view returns (address) {
        return _parents[user];
    }

    function getTotalHash() public view returns (uint256) {
        return _totalhash;
    }

    function getUserNeedHash(address user) public view returns (uint256)
    {
        return _holdhash[_userInfo[user][USERLEVELA]];
    }

    function GetDtTotal(address user) public view returns(uint256)
    {
        if(_userInfo[user][USERLEVELA]==0)
            return 0;
            
        uint256[2] memory kk = getPendingCoin(user);
        return  _userInfo[user][REALGETA].add(kk[1]);
    }

    function GetVipDestroy(address user) public view returns (uint256)
    {
        return _userInfo[user][TOTALDESTORYA];
    }

    function getMyLpInfo(address user, address tokenaddress)
        public
        view
        returns (uint256[3] memory)
    {
        uint256[3] memory bb;
        bb[0] = _lpPools[tokenaddress].poolwallet.getBalance(user, true);
        bb[1] = _lpPools[tokenaddress].poolwallet.getBalance(user, false);
        bb[2] = _userLphash[user][tokenaddress];
        return bb;
    }

    // function setParent(address user,address parent) public onlyOwner
    // {
    //     require(_parents[user]==address(0));
    //     _parents[user] = parent;
    //     _mychilders[parent].push(user);
    // }

    function getUserLevel(address user) external view returns (uint256) {
            return _userInfo[user][USERLEVELA] ;
    }

    function getUserTeamHash(address user) public view returns (uint256) {
        return _userInfo[user][TEAMHASHA];
    }

    function getUserSelfHash(address user) public view returns (uint256) {
        return _userInfo[user][SELFHASHA];
    }
 
    function getExchangeCountOfOneUsdt(address lptoken)
        public
        view
        returns (uint256)
    {
        require(_lpPools[lptoken].tradeContract != address(0));

        if (lptoken == address(2) || lptoken == _mainaddr) //BNB
        {
            return _icomputer.getExchangeCountOfOneUsdt2(lptoken == _mainaddr?_maintrade:_bnbtradeaddress);
        }
        else {
             return _icomputer.getExchangeCountOfOneUsdt(_bnbtradeaddress, _lpPools[lptoken].tradeContract, lptoken);
        }
    }

    //******************Getters ************************************/
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
            uint256 behash =totalhash >= _maxhash ? totalhash : _maxhash;
            uint256 addoneshar= _cs.div(behash).mul(block.number.sub(_lastupdateblock));
            _oneshareget = _oneshareget.add(addoneshar);
            _lastupdateblock= block.number;
        }

        if (add) {
            _totalhash = _totalhash.add(totalhashdiff);
        } else {
            _totalhash = _totalhash.sub(totalhashdiff);
        }
    }

    function getHashDiffOnLevelChange(address user, uint256 newlevel)
        private
        view
        returns (uint256)
    {
        uint256 hashdiff = 0;
        uint256 userlevel = _userInfo[user][USERLEVELA];
        for (uint256 i = 0; i < _maxdept; i++) {
            if (_userlevelhashtotal[user][i] > 0) {
                
                // overflow 20 default 1% = Unlimited level 1%
                uint256 userlevelconfig = getLevelConfig(i, userlevel);// (i >= 20 && userlevel == 8) ? 10 : _levelconfig[userlevel][i];
                uint256 usernewlevelconfig = getLevelConfig(i, newlevel); //(i >= 20 && newlevel == 8) ? 10 :_levelconfig[newlevel][i];
                
                if (userlevelconfig > 0) {
                    uint256 dff =
                        _userlevelhashtotal[user][i]
                            .mul(usernewlevelconfig)
                            .sub(
                                _userlevelhashtotal[user][i].mul(userlevelconfig)
                            );
                    dff = dff.div(1000);
                    hashdiff = hashdiff.add(dff);
                } else {
                    uint256 dff = _userlevelhashtotal[user][i]
                            .mul(usernewlevelconfig)
                            .div(1000);
                    hashdiff = hashdiff.add(dff);
                }
            }
        }
        return hashdiff;
    }

    uint256[9] _vipbuyprice = [0, 100, 300, 500, 800, 1200, 1600, 2000,2400];
    function buyVipPrice(address user, uint256 newlevel)
        public
        view
        returns (uint256)
    {
        if (newlevel >= 9) return 1e50;
        uint256 userlevel = _userInfo[user][USERLEVELA];
        require (userlevel < newlevel,"D");
        uint256 costprice = _vipbuyprice[newlevel] - _vipbuyprice[userlevel];
        uint256 costcount = costprice.mul(getExchangeCountOfOneUsdt(_mainaddr));
        return costcount;
    }
 
  
    function buyVip(uint256 newlevel) public nonReentrant returns (bool) {
        require(newlevel < 9,"ERROR A");
        address user=msg.sender;
        require(_parents[user] != address(0), "must bind");

        uint256 costcount = buyVipPrice(user, newlevel);
        require(costcount > 0,"ERROR b");
        uint256 diff = getHashDiffOnLevelChange(user, newlevel);
        if (diff > 0) {
            UserHashChanged(user, 0, diff, true);
            logCheckPoint(diff, true);
        }

        IBEP20(_mainaddr).burnFrom(user, costcount);
        if(_userInfo[user][USERLEVELA]==0)
        {
            _userInfo[user][REALGETA]=0;
        }

        _userInfo[user][USERLEVELA] = newlevel;
        _userInfo[user][TOTALDESTORYA] = _userInfo[user][TOTALDESTORYA].add(costcount);
        return true;
    }

    function isVipOuted(address user) public view returns (bool)
    {
        if(_userInfo[user][USERLEVELA]==0)
            return false;

         if(GetDtTotal(user) >= GetVipDestroy(user).mul(4))
         {
            return true;
         }
         else
            return false;
    }

    function addDestoryCoin(uint256 costcount) public
    {
        // user_level price limit
        address user = msg.sender;
        uint256 userlevel = _userInfo[user][USERLEVELA];
        uint256 levelcount = 0;
        
        if(userlevel > 0) {
            uint256 levelprice = _vipbuyprice[userlevel];
            levelcount = levelprice.mul(getExchangeCountOfOneUsdt(_mainaddr));
        }
        
        require(costcount >= levelcount, "costcount less level price limit");
        
        IBEP20(_mainaddr).burnFrom(msg.sender, costcount);
         _userInfo[msg.sender][TOTALDESTORYA] = _userInfo[msg.sender][TOTALDESTORYA].add(costcount);
    }

    function bindParent(address parent) public {
        require(_parents[msg.sender] == address(0), "Already bind");
        require(parent != address(0));
        require(parent != msg.sender);
        require(_parents[parent] != address(0));
        _parents[msg.sender] = parent;
        _mychilders[parent].push(msg.sender);
        addTeamCount(msg.sender);
    }
    
    function addTeamCount(address user) private {
        address parent = user;
        for (uint256 i = 0; i < _maxdept; i++) {
            parent = getParent(parent);
            if (parent == address(0)) break;
            _userInfo[parent][TEAMCOUNT] = _userInfo[parent][TEAMCOUNT].add(1);
        }   
    }
 
    function getPendingCut(address user) public view returns (uint256)
    {
        uint256 selfhash = getUserSelfHash(user);
        if(selfhash==0)
        {
            return _userInfo[user][PENDINGCUTA];
        }
        uint256 total=_userInfo[user][PENDINGCUTA];

        if(_onecut>_userInfo[user][TAKEDCUT])
            total=total.add(selfhash.mul(_onecut.sub(_userInfo[user][TAKEDCUT])).div(1e32));
   
        return total;
    }

    function getOneshareNow() public view returns (uint256)
    {
         return _icomputer.getOneshareNow(_oneshareget, _lastupdateblock, getTotalHash());
    }

    function getPendingCoin(address user) public view returns (uint256[2] memory) {
    
        uint256 selfhash=getUserSelfHash(user);
        uint256 teamhash =getUserTeamHash(user);
        uint256[2] memory pending;
        uint256 oneshare=getOneshareNow();
        if(selfhash>0)
        {
            uint256 cashedjt=_userInfo[user][TAKEDJT];
            uint256 newp =0;
            if(oneshare > cashedjt)
               newp = selfhash.mul(oneshare.sub(cashedjt)).div(1e32);

            pending[0]=_userInfo[user][PENDINGJTA].add(newp);
        }
        else
        {
            pending[0]=_userInfo[user][PENDINGJTA];
        }

        if(teamhash > 0)
        {
            uint256 casheddtA=_userInfo[user][TAKEDDT];
            uint256 newp=0;
            if(oneshare > casheddtA)
            newp = teamhash.mul(oneshare.sub(casheddtA)).div(1e32);
            uint256 dttotal = newp.add(_userInfo[user][PENDINGDTA]);
            uint256 hodhasl=_holdhash[_userInfo[user][USERLEVELA]];
            if(selfhash < hodhasl)
            {
                dttotal = dttotal.mul(selfhash).div(hodhasl);
            }

            uint256 destroy=GetVipDestroy(user);
            if(destroy > 0)
            {
                uint256 realget=_userInfo[user][REALGETA];
                if(realget.add(dttotal) > destroy.mul(4))
                {
                    if(realget < destroy.mul(4))
                        dttotal = destroy.mul(4).sub(realget);
                    else
                        dttotal=0;
                }
            }
            pending[1]=dttotal;
        }
        else
        {
            pending[1]=_userInfo[user][PENDINGDTA];
        }

        return pending;
    }

    function UserHashChanged(
        address user,
        uint256 selfhash,
        uint256 teamhash,
        bool add
    ) private {
       
        if (selfhash > 0) {
             
             if(getUserSelfHash(user)>0)
            {
                uint256 cuttake = getPendingCut(user);
                uint256[2] memory amount = getPendingCoin(user);
                _userInfo[user][PENDINGJTA]= amount[0];
                _userInfo[user][PENDINGCUTA] = cuttake;
            }

            if (add) {
                _userInfo[user][SELFHASHA] = _userInfo[user][SELFHASHA].add(selfhash);
                 
            } else 
                _userInfo[user][SELFHASHA] = _userInfo[user][SELFHASHA].sub(selfhash);

            clearCredit(user,3);
            
        }
        if (teamhash > 0) {

            if(getUserTeamHash(user)>0)
            {
                uint256[2] memory amount = getPendingCoin(user);
                _userInfo[user][PENDINGDTA]= amount[1];
            }
           
            if (add) {
                     _userInfo[user][TEAMHASHA] = _userInfo[user][TEAMHASHA].add(teamhash);
            } else {
                if (_userInfo[user][TEAMHASHA] > teamhash)
                   _userInfo[user][TEAMHASHA] = _userInfo[user][TEAMHASHA].sub(teamhash);
                else _userInfo[user][TEAMHASHA] =0;
            }

            clearCredit(user,7);
            
        }
    }

    function clearCredit(address user,uint typess) private
    {
         uint256 oneshare=getOneshareNow();
        if(typess % 3==0)
        {
            _userInfo[user][TAKEDCUT] = _onecut;
            _userInfo[user][TAKEDJT] = oneshare;
        }
        if(typess%7==0)
        {
            _userInfo[user][TAKEDDT] = oneshare;
        }

    }

    function withDrawCredit() public nonReentrant returns (bool) {
        address user =msg.sender;
        uint256[2] memory amount = getPendingCoin(user);
        uint256 cut=getPendingCut(user);
        uint256 send=amount[0].add(amount[1]);
        
        uint256 costmount = _feeamount.mul(getExchangeCountOfOneUsdt(_mainaddr));
        require(send > costmount, 'less feeamount');
      
         _userInfo[user][PENDINGDTA]=0;
         _userInfo[user][PENDINGJTA]=0;
         _userInfo[user][PENDINGCUTA]=0;
         if(_userInfo[user][USERLEVELA] > 0)
              _userInfo[user][REALGETA] =_userInfo[user][REALGETA].add(amount[1]);
               
          _userInfo[user][REALGETJTA] = _userInfo[user][REALGETJTA].add(amount[0]);
          _userInfo[user][REALGETDTA] = _userInfo[user][REALGETDTA].add(amount[1]);
          
          clearCredit(user,21);
          
         _cutpool.MineOut(user, cut); // sub fee_amount
         _minepool.MineOut(user, send.sub(costmount)); // sub fee_amount
         
        emit WithDrawCredit(user, amount[0], amount[1], cut, _feeamount);
         
        return true;
    }
  
    function takeBack(address tokenAddress, uint256 pct) public
        nonReentrant
        returns (bool)
    {
        require(_takeout, "takeout error");
        require(pct >= 10000 && pct <= 1000000,"ERROR PCT");
        address user = msg.sender;
        uint256 totalhash = _userLphash[user][tokenAddress];
        uint256 amounta = _lpPools[tokenAddress].poolwallet.getBalance(user, true).mul(pct).div(1000000);
        uint256 amountb = _lpPools[tokenAddress].poolwallet.getBalance(user, false).mul(pct).div(1000000);
        uint256 decreasehash =totalhash.mul(pct).div(1000000);
       
        address parent = user;
        uint256 dthash = 0;
        if(decreasehash > 0)
        {
             _userLphash[user][tokenAddress] = totalhash.sub(decreasehash);
            for (uint256 i = 0; i < _maxdept; i++) {
                parent = getParent(parent);
                if (parent == address(0)) 
                    break;

                if(_userlevelhashtotal[parent][i] > decreasehash)
                    _userlevelhashtotal[parent][i] = _userlevelhashtotal[parent][i].sub(decreasehash);
                else
                    _userlevelhashtotal[parent][i]=0;
                    
                uint256 parentlevel = _userInfo[parent][USERLEVELA];
                // overflow 20 default 1% = Unlimited level 1%
                uint256 levelconfig = getLevelConfig(i, parentlevel); //(i >= 20 && parentlevel == 8) ? 10 : _levelconfig[parentlevel][i];
                uint256 pdechash = decreasehash.mul(levelconfig).div(1000);
                if (pdechash > 0) {
                    dthash = dthash.add(pdechash);
                    UserHashChanged(parent, 0, pdechash, false);
                }
            }
        }
        
        UserHashChanged(user, decreasehash, 0, false);
        logCheckPoint(decreasehash.add(dthash), false);

        _lpPools[tokenAddress].poolwallet.takeBack(user,amounta,amountb);
        
        return true;
    }

    function showUserInfo(address user) public view returns(uint256[14] memory result)
    {
        for(uint i=0;i<14;i++)
            result[i]=_userInfo[user][i+1];
    }

    function getPower(
        address tokenAddress,
        uint256 amount,
        uint256 costrow
    ) public view returns (uint256) {
        
        require(amount > 10000 || costrow> 10000, "less 10000");
        
        uint256 price = getExchangeCountOfOneUsdt(tokenAddress);
        uint256 rowprice = getExchangeCountOfOneUsdt(_mainaddr);
        
        uint256 hashb = amount.mul(1e18).div(price).add(costrow.mul(1e18).div(rowprice));
        uint256 dppct = amount.mul(1e20).div(price).div(hashb);
        hashb = hashb.mul(getHashRateByPct(dppct)).div(100);
        
        return hashb;
    }

    function getLpPayRow(
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
                .mul(getExchangeCountOfOneUsdt(_mainaddr))
                .mul(100 - lpscale)
                .div(1e20);
        return costabc;
    }
    
    function getLpPayToken(
        address tokenAddress,
        uint256 amount,
        uint256 lpscale
    ) public view returns (uint256) {
        require(lpscale <= 100);
        uint256 hashb =
            amount.mul(1e20).div(lpscale).div(
                getExchangeCountOfOneUsdt(_mainaddr)
            );
        uint256 costabc =
            hashb
                .mul(getExchangeCountOfOneUsdt(tokenAddress))
                .mul(100 - lpscale)
                .div(1e20);
        return costabc;
    }

    function deposit(
        address tokenAddress,
        uint256 amount,
        uint256 costrow
    ) public payable nonReentrant returns (bool) {
        if (tokenAddress == address(2)) {
            amount = msg.value;
        }
        require(amount > 10000 || costrow> 10000, "less 10000");
        address user=msg.sender;
        
        uint256 price = getExchangeCountOfOneUsdt(tokenAddress);
        uint256 rowprice = getExchangeCountOfOneUsdt(_mainaddr);
        
        uint256 hashb = amount.mul(1e18).div(price).add(costrow.mul(1e18).div(rowprice)); // getPower(tokenAddress,amount,dppct);
        uint256 dppct = amount.mul(1e20).div(price).div(hashb);
        
        require(dppct >= _lpPools[tokenAddress].minpct, "aa");
        require(dppct <= _lpPools[tokenAddress].maxpct, "bb");
        
        hashb = hashb.mul(getHashRateByPct(dppct)).div(100);
        uint256 abcbalance = IBEP20(_mainaddr).balanceOf(user);

        if (abcbalance < costrow) {
            amount = amount.mul(abcbalance).div(costrow);
            hashb = hashb.mul(abcbalance).div(costrow);
            costrow = abcbalance;
        }
        if (tokenAddress == address(2)) {
            if (msg.value > amount) 
                TransferHelper.safeTransferBNB(user, msg.value - amount);
                _lpPools[tokenAddress].poolwallet.addBalance{value:amount}(user,amount,costrow);
        } else {
            tokenAddress.safeTransferFrom(
                user,
                address(_lpPools[tokenAddress].poolwallet),
                amount
            );
             _lpPools[tokenAddress].poolwallet.addBalance{value:0}(
                user,
                amount,
                costrow
            );
        }

         if (costrow > 0)
                _mainaddr.safeTransferFrom(
                    user,
                    address(_lpPools[tokenAddress].poolwallet),
                    costrow
                );

       
        _userLphash[user][tokenAddress] = _userLphash[user][tokenAddress].add(hashb);

        address parent = user;
        uint256 dhash = 0;

        for (uint256 i = 0; i < _maxdept; i++) {
            parent = getParent(parent);
            if (parent == address(0)) break;
            _userlevelhashtotal[parent][i] = _userlevelhashtotal[parent][i].add(hashb);
            uint256 parentlevel = _userInfo[parent][USERLEVELA];
            // overflow 20 default 1% = Unlimited level 1%
            uint256 levelconfig = getLevelConfig(i, parentlevel); //(i >= 20 && parentlevel == 8) ? 10 :  _levelconfig[parentlevel][i];
            if (levelconfig > 0) {
                uint256 addhash = hashb.mul(levelconfig).div(1000);
                if (addhash > 0) {
                    dhash = dhash.add(addhash);
                    UserHashChanged(parent, 0, addhash, true);
                }
            }
        }
        UserHashChanged(user, hashb, 0, true);
        logCheckPoint(hashb.add(dhash), true);
        return true;
    }
    
    
    // overflow 20 and level 8 default 1% = Unlimited level 1% = 10/1000
    function getLevelConfig(uint256 dept, uint256 userLevel) private view returns(uint256) {
        
        uint256 levelconfig = 0;
        if(dept >= 20) {
            levelconfig = (userLevel == 8) ? 10 : 0;
        } else {
            levelconfig = _levelconfig[userLevel][dept];
        }
        
        return levelconfig;
        
    }
    
}