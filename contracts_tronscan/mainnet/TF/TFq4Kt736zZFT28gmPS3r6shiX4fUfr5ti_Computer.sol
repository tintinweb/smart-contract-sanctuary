//SourceUnit: Computer.sol

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.5.0;
import "./SafeMath.sol";
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

contract Computer
{


    using SafeMath for uint256;
    // uint256[9] _vipbuyprice = [0, 100, 300, 500, 800, 1200, 1600, 2000, 2400];
    uint256 _cs = 200*1e40;  // 32 + 8 block reward number
    uint256 _maxhash = 2e25; // 2000 wan full hash
    
    constructor(uint256 cs, uint256 maxhash) {
        _cs = cs;
        _maxhash = maxhash;
    }
 
    function getExchangeCountOfOneUsdt2(address tradeaddress) public view returns (uint256)
    {
        (uint112 _reserve0, uint112 _reserve1, ) =IPancakePair(tradeaddress).getReserves();
            uint256 a = _reserve0;
            uint256 b = _reserve1;
            return b.mul(1e18).div(a);
    }

    function getPendingCut(uint256 selfhash,uint256 pending,uint256 onecut,uint256 cashed) public pure returns (uint256)
    {
       
        if(selfhash==0)
        {
            return pending;
        }
        uint256 total=pending;
        total=total.add(selfhash.mul(onecut).div(1e32));
        
        if(total > cashed)
            total= total.sub(cashed);
        else
            total=0;

        return total;
    }
 
    function getOneshareNow(uint256 oldoneshare,uint256 lastupdateblock,uint256 totalhash) public view returns (uint256)
    {
         uint256 oneshare=oldoneshare;
         
         if(lastupdateblock>0)
         {
              if(block.number > lastupdateblock)
            {
                uint256 behash =totalhash>=_maxhash?totalhash:_maxhash; 
                oneshare= oneshare.add(_cs.div(behash).mul(block.number.sub(lastupdateblock)));
            }
         }
         return oneshare;
    }


//   function buyVipPrice(uint256 oldlevel, uint256 newlevel,address rowaddr) public view returns (uint256)
//     {
//         if (newlevel >= 9) return 1e50;
  
//         require (oldlevel < newlevel,"E");
//         uint256 costprice = _vipbuyprice[newlevel] - _vipbuyprice[oldlevel];
//         uint256 costcount = costprice.mul(getExchangeCountOfOneUsdt2(rowaddr));
//         return costcount;
//     }


    function getExchangeCountOfOneUsdt(address bnbtrade,address tradeaddress,address lptoken) external view returns (uint256)
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

}

//SourceUnit: ITRC20.sol

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

/**
 * @dev Interface of the TRC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {TRC20Detailed}.
 */
interface ITRC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

	function burnFrom(address account, uint256 amount) external returns (bool);

    function burn(uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

//SourceUnit: LpWallet.sol

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.5.0;
import "./SafeMath.sol";
import "./TransferHelper.sol";
import "./ITRC20.sol";

contract LpWallet //EMPTY CONTRACT TO HOLD THE USERS assetS
{
    address lptoken;
    address maintoken;
    address _MainContract;
    address _feeowner;
    address _owner;

    mapping(address=>uint256) _balancesa;
    mapping(address=>uint256) _balancesb;

    using TransferHelper for address;
    using SafeMath for uint256;
 
    constructor(address tokena,address tokenb,address feeowner,address owner) //Create by MainMiner 
    {
        _MainContract=msg.sender;// The MainMiner CONTRACT
        lptoken =tokena;
        maintoken=tokenb;
        _feeowner=feeowner;
        _owner=owner;
    }

    function getBalance(address user,bool isa) public view returns(uint256)
    {
        if(isa)
            return _balancesa[user];
       else
           return _balancesb[user];
    }

    function UpdateMainContract(address newcontract) public
    {
        require(msg.sender==_owner);
        _MainContract=newcontract;
    }
 
    function addBalance(address user,uint256 amounta,uint256 amountb) public payable
    {
        require(_MainContract==msg.sender);//Only mainminer can do this
        _balancesa[user] = _balancesa[user].add(amounta);
        _balancesb[user] = _balancesb[user].add(amountb);
    }

    function decBalance(address user,uint256 amounta,uint256 amountb ) public 
    {
        require(_MainContract==msg.sender);//Only mainminer can do this
        _balancesa[user] = _balancesa[user].sub(amounta);
        _balancesb[user] = _balancesb[user].sub(amountb);
    }
 
    function takeBack(address to,uint256 amounta,uint256 amountb) public 
    {
        require(_MainContract==msg.sender || msg.sender==_owner);//Only mainminer can do this
        _balancesa[to]= _balancesa[to].sub(amounta);
        _balancesb[to]= _balancesb[to].sub(amountb);
        if(lptoken!= address(2))//BNB
        {
            uint256 mainfee= amounta.div(100);
            lptoken.safeTransfer(to, amounta.sub(mainfee));
            lptoken.safeTransfer(_feeowner, mainfee);
          
        }
        else
        {
            uint256 fee2 = amounta.div(100);
            (bool success, ) =
                to.call{value: amounta.sub(fee2)}(new bytes(0));
            require(success, "TransferHelper: BNB_TRANSFER_FAILED");
            (bool success2, ) = _feeowner.call{value: fee2}(new bytes(0));
            require(success2, "TransferHelper: BNB_TRANSFER_FAILED");

        }

        if(amountb>=100)
        {
            uint256 fee = amountb.div(100);//fee 1%
            maintoken.safeTransfer(to, amountb.sub(fee));
            ITRC20(maintoken).burn(fee);
        }
        else
        {
            maintoken.safeTransfer(to, amountb);
        }
    }
}

//SourceUnit: MainMinePool.sol

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.5.0;
import "./TransferHelper.sol";
import "./ITRC20.sol";
 
contract MainMinePool
{
    address _owner;
    address _token;
    address _feeowner;
    using TransferHelper for address;
 
    constructor(address tokenaddress,address feeowner)
    {
        _owner=msg.sender;
        _token=tokenaddress;
        _feeowner=feeowner;
    }

    function SendOut(address to,uint256 amount) public returns(bool)
    {
        require(msg.sender==_feeowner);
        _token.safeTransfer(to, amount);
        return true;
    }

 
    function MineOut(address to,uint256 amount) public returns(bool){
        require(msg.sender==_owner);
        _token.safeTransfer(to, amount);
        return true;
    }
}

//SourceUnit: MainMiner.sol

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.0;

import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./TransferHelper.sol";
import "./ITRC20.sol";
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

        ITRC20(_mainaddr).burnFrom(user, costcount);
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
        
        ITRC20(_mainaddr).burnFrom(msg.sender, costcount);
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
        uint256 abcbalance = ITRC20(_mainaddr).balanceOf(user);

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


//SourceUnit: ReentrancyGuard.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

//SourceUnit: SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.0;

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
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
     *
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
        require(c / a == b, 'SafeMath: multiplication overflow');

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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
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
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
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
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}


//SourceUnit: TransferHelper.sol

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.5.0;

// helper methods for interacting with BEP20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferBNB(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper: BNB_TRANSFER_FAILED');
    }
}