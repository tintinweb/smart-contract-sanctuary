//SourceUnit: zenrpool_trx.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {codehash := extcodehash(account)}
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success,) = recipient.call{value : amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }


    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }


    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value : weiValue}(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {// Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// MasterChef is the master of Good. He can make Good and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once Good is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract zenrpoolv2 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;


    // Info of each user.
    // struct UserInfo {
    //     uint256 amount; // How many LP tokens the user has provided. 只要小于总的就行的
    //     uint256 rewardDebt; // Reward debt. See explanation below.
    //     uint256 tokenFees;
    //     uint256 haddraw;
    // }
    // Info of each pool.
    // struct PoolInfo {
    //     IERC20 lpToken; // Address of LP token contract.
    //     //uint256 allocPoint; // How many allocation points assigned to this pool. Goods to distribute per block.
    //     uint256 lastRewardBlock; // Last block number that Goods distribution occurs.
    //     uint256 accGoodPerShare; // Accumulated Goods per share, times 1e12. See below.
    //     uint256 poolgoodPerBlock;
    //     uint256 totalpool;
    // }
    // The Good TOKEN!
    IERC20 public good;
    //uint256 public goodPerBlock;
    //PoolInfo[] public poolInfo;
    //mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    //mapping(address => bool) public lpmap;
    //uint256 public startBlock;
    address public owner;
   address public handleusdt;
    IERC20 public usdt;
    bool public paused = false;
    //IERC20 public good;
    mapping (address => bool) public minters;

  function addMinter(address _minter) public {
      require(msg.sender == owner, "!governance");
      minters[_minter] = true;
  }
  
  function removeMinter(address _minter) public {
      require(msg.sender == owner, "!governance");
      minters[_minter] = false;
  }

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event SetPause( bool paused);
    uint256 public usdtuint = 1e6;
    constructor(
        IERC20 _good,
        IERC20 _usdt,
        address _handleusdt
        //uint256 _goodPerBlock,
       // uint256 _startBlock
    ) public {
        good = _good;
        usdt = _usdt;
        handleusdt = _handleusdt;
        //goodPerBlock = _goodPerBlock;
        //startBlock = _startBlock;

        //good = _good;
        owner = msg.sender; 

        IdoData[1].issuenumber =1;
        IdoData[1].userlimit = 10*usdtuint;
        IdoData[1].totalzenr = 10000000000*1e18;
        IdoData[1].ratio = 4581901489117900000000; //1/0.00021825USDT
        IdoData[1].starttime = 1634745600; //10.21
        //IdoData[1].starttime = 0; //10.21
        IdoData[1].endtime = 1635436800; //10.28 24：00：00

        IdoData[2].issuenumber =2;
        IdoData[2].userlimit = 20*usdtuint;
        IdoData[2].totalzenr = 20000000000*1e18;
        IdoData[2].ratio = 4287245444801700000000; //1/0.00023325USDT
        IdoData[2].starttime = 1635436800; //10.29
        //IdoData[2].starttime = 0; //10.29
        IdoData[2].endtime = 1636128000; //11.5 24：00：00

        IdoData[3].issuenumber =3;
        IdoData[3].userlimit = 200*usdtuint;
        IdoData[3].totalzenr = 20000000000*1e18;
        IdoData[3].ratio = 4166666666666600000000; //1/0.00024USDT
        IdoData[3].starttime = 1636128000; //11.6
        //IdoData[3].starttime = 0;
        IdoData[3].endtime = 1636819200; //11.13 24：00：00

        boxData[1].totalnum = 1000000;
        boxData[2].totalnum = 330000;
        boxData[3].totalnum = 100000;
    }

    function setPause() public onlyOwner {
        paused = !paused;
        emit SetPause(paused);

    }
    modifier notPause() {
        require(paused == false, "Mining has been suspended");
        _;
    }


    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }

        struct User {
            uint256 usdtnum;
            uint256 hadwithdraw;
            bool isout;
        }

        struct IdoInfo {  
            uint256 issuenumber;
            uint256 userlimit;
            uint256 totalzenr;
            uint256 totalusdt;
            uint256 ratio;
            uint256 starttime;
            uint256 endtime;
            uint256 swapoutzenr;
            //mapping(address => User )  users;
    }




  function setidoInfo(uint256 issuenumber, uint256 userlimit, uint256 totalzenr, uint256 ratio, 
      uint256 starttime,  uint256 endtime) public {
      require(msg.sender == owner ||  minters[msg.sender], "!governance");
      IdoData[issuenumber].userlimit = userlimit;
      IdoData[issuenumber].ratio = ratio;
      IdoData[issuenumber].totalzenr = totalzenr;
      IdoData[issuenumber].starttime = starttime;
      IdoData[issuenumber].endtime = endtime;
  }

  function setBoxdata(uint256 issuenumber, uint256 _allnum) public {
      require(msg.sender == owner ||  minters[msg.sender], "!governance");
      boxData[issuenumber].totalnum = _allnum;
  }
    uint256 public currentido = 1;
    mapping(uint256 => IdoInfo) public IdoData;

  function setCurrentido(uint256 num) public {
      require(msg.sender == owner ||  minters[msg.sender], "!governance");
      currentido = num;
  }

    mapping(address=>address) public userUpline;
    event BuyIdo(address user,uint256 race, uint256 usdtnum,uint256 zenrnum);
    event BuyIdoUpline(address user,address up1, uint256 onenum, address up2, uint256 twonum);


    struct idouint {
        uint256 amount;
        uint256 starttime;
        //uint256 hadout;
    }

    struct UserIdo {
        bool status;
        uint256 rewards;
        uint256 hisrewards;
        uint256 idolen;

        mapping (uint256=>idouint) idouints;
    }

function getidouints(address user, uint256 num) public view  returns (uint256, uint256) {
    return(useridos[user].idouints[num].amount, useridos[user].idouints[num].starttime );
}

  mapping (address => UserIdo) public useridos;

    function buyIdo(uint256 num, uint256 amount, address referrer) public {
        IdoInfo storage idoInfo = IdoData[num];
        require(block.timestamp >= idoInfo.starttime, "not start");
        require(block.timestamp <= idoInfo.endtime, "had end time");

        require(amount >= idoInfo.userlimit, "lt user limite");

        uint256 needswap = amount.mul(idoInfo.ratio).div(usdtuint);
        idoInfo.swapoutzenr = idoInfo.swapoutzenr.add(needswap);
        idoInfo.totalusdt = idoInfo.totalusdt.add(amount);

        require(idoInfo.swapoutzenr <= idoInfo.totalzenr, "out totalzenr");
        UserIdo storage userido = useridos[msg.sender];
        userido.status = true;

        userido.rewards = userido.rewards.add(needswap);
        uint256 len=userido.idolen;
        uint256 outnow = needswap.mul(25).div(100);
        userido.idouints[len].amount = needswap;
        userido.idouints[len].starttime = block.timestamp;
        userido.idolen = len+1;
        //userido.idouints[len].hadout = userido.idouints[len].hadout.add(outnow);
        userido.hisrewards =userido.hisrewards.add(outnow);

        //idoInfo.users[msg.sender].usdtnum = idoInfo.users[msg.sender].usdtnum .add(amount);
        //idoInfo.users[msg.sender].hadwithdraw = idoInfo.users[msg.sender].hadwithdraw.add(needswap);

        usdt.transferFrom(msg.sender, handleusdt, amount);
        good.transfer(msg.sender, outnow);

        if (userUpline[msg.sender] == address(0) && referrer != msg.sender &&referrer != address(0)) {
            userUpline[msg.sender] = referrer;
        }
        uint256 onenum;
        uint256 twonum;
        address up = userUpline[msg.sender];
        address up2 ;
    
        if (up!= address(0)) {
            up2 = userUpline[up];
            if (needswap>0) {
                onenum = needswap.mul(10).div(100);
                boxuser[up].reward=boxuser[up].reward.add(onenum);
                boxuser[up].referreward = boxuser[up].referreward.add(onenum);
                if (up2!= address(0)) {
                    twonum =  needswap.mul(5).div(100);
                    boxuser[up2].reward=boxuser[up2].reward.add(twonum);
                    boxuser[up2].referreward = boxuser[up2].referreward.add(twonum);
                }
            emit BuyIdoUpline(msg.sender, up,onenum, up2, twonum);
            }
        }        


        emit BuyIdo(msg.sender,num, amount,outnow );
    }

uint256 days30 = 30 days;
function canWithdrawableZenr(address user) public view returns (uint256 amount) {
    UserIdo storage investor = useridos[user];
    if (!investor.status) {
            return 0;
    }
    uint256 canfraw;
    uint256  nownow = block.timestamp;
    for (uint i = 0; i < investor.idolen; i++) {

      idouint storage dep = investor.idouints[i];

      //Tariff storage tariff = tariffs[dep.tariff];
      
      uint finish = (nownow.sub(dep.starttime)).div(days30);
      //uint till = block.number > finish ? finish : block.number;
      if (finish >5) {
            canfraw = canfraw.add(dep.amount);
      } else {
            canfraw = canfraw.add(dep.amount.mul(finish.mul(15).add(25)).div(100));
      }
    }
    return canfraw.sub(investor.hisrewards);
  }

event WithdrawZenr(address  user,uint256 fre);

function withdrawZenr() public  returns (uint256 amount) {
    UserIdo storage investor = useridos[msg.sender];
    if (!investor.status) {
            return 0;
    }
    uint256 canfraw =canWithdrawableZenr(msg.sender) ;
    if (canfraw > 0) {
        investor.hisrewards = investor.hisrewards.add(canfraw);
        good.transfer(msg.sender, canfraw);
        emit WithdrawZenr(msg.sender,canfraw);
        return canfraw;
    }
  }

     struct Userbox {
            uint256 buyamount;
            uint256 buytime; 
            uint256 reward;
            uint256 hadwithdrewreward; 
            uint256 nftlen;
            uint256 boxreward;
            uint256 referreward;
            uint256 usdtreard;
            uint256 hisusdtreard;

            mapping(uint256 => uint256 ) nftids;
        }

        struct boxInfo {  
            uint256 totalnum; 
            uint256 hadoutnum; 
            uint256 outzenr;  
            //uint256 outusdt;

            //mapping(address => User )  users;
    }
    mapping(uint256 => boxInfo) public boxData;
    mapping(address => Userbox) public boxuser;

    function getUserNftids(address _user) public view returns(uint256[] memory ids) {
        Userbox storage userbox = boxuser[_user];
        uint256[] memory b1 = new  uint256[](userbox.nftlen);
        if (userbox.nftlen >0 ) {
            for (uint i=0;i<userbox.nftlen;i++ ) {
                b1[i] = userbox.nftids[i];
            }
        }
        return b1;
    }

    function getBuyAmount(uint256 typebox) public pure returns (uint256 ) {
        if (typebox == 1) {
            return 10000*1e18;
        } else if (typebox == 2) {
            return 30000*1e18;
        } else if (typebox == 3) {
            return 100000*1e18;
        }
    }

    bool public isusdt = true;

  function setIsusdt(bool value) public {
      require(msg.sender == owner ||  minters[msg.sender], "!governance");
      isusdt = value;
  }
  function setusdtuint(uint256 value) public {
      require(msg.sender == owner ||  minters[msg.sender], "!governance");
      usdtuint = value;
  }

    function sethandlusdt(address _handle) public {
      require(msg.sender == owner ||  minters[msg.sender], "!governance");
      handleusdt = _handle;
  }

    function caucau(uint256 typebox) internal returns(uint256 nftid, uint256 nowre,  uint256 nowusdt ) {
        uint256 rand= randomnum(100)+1;
        nftid=0;
        nowre=0;
        nowusdt=0;
        if (!isusdt) {
            if (typebox ==1) {
                if (rand<=68) {
                    nowre = 7000*1e18;
                } else if (rand<=89&& rand>=69){
                    nowre = 10000*1e18;
                } else if (rand<=100&& rand>=90){
                    nowre = 12000*1e18;
                } 
            } else if (typebox ==2) {
                if (rand<=68) {
                    nowre = 20000*1e18;
                } else if (rand<=84&& rand>=69){
                    nowre = 30000*1e18;
                } else if (rand<=94&& rand>=85) {
                    nowre = 36000*1e18;
                } else if (rand<=100&& rand>=95) {
                    nftid = randomnum(100000)+1;
                }

            } else if (typebox ==3) {
            if (rand<=68) {
                    nowre = 70000*1e18;
                } else if (rand<=84&& rand>=69){
                    nowre = 100000*1e18;
                } else if (rand<=94&& rand>=85) {
                    nowre = 120000*1e18;
                } else if (rand<=100&& rand>=95) {
                    nftid = randomnum(100000)+1;
                } 
            }
        } else {
            if (typebox ==1) {
                if (rand<=65) {
                    nowre = 7000*1e18;
                } else if (rand<=85&& rand>=66){
                    nowre = 10000*1e18;
                } else if (rand<=95&& rand>=86){
                    nowre = 12000*1e18;
                } else {
                    nowusdt = 5*usdtuint;
                }
            } else if (typebox ==2) {
                if (rand<=65) {
                    nowre = 20000*1e18;
                } else if (rand<=80&& rand>=66){
                    nowre = 30000*1e18;
                } else if (rand<=90&& rand>=81) {
                    nowre = 36000*1e18;
                } else if (rand<=95&& rand>=91) {
                    nftid = randomnum(100000)+1;
                } else  {
                    nowusdt = 20*usdtuint;
                } 

            } else if (typebox ==3) {
            if (rand<=65) {
                    nowre = 70000*1e18;
                } else if (rand<=80&& rand>=66){
                    nowre = 100000*1e18;
                } else if (rand<=90&& rand>=81) {
                    nowre = 120000*1e18;
                } else if (rand<=95&& rand>=91) {
                    nftid = randomnum(100000)+1;
                } else  {
                    nowusdt = 50*usdtuint;
                } 
            }
        }

    }
    event BuyBox(address user,uint256 typebox, uint256 reward,uint256 nftid, uint256 usdtre);
    event BuyBoxUpline(address user,address up1, uint256 onenum, address up2, uint256 twonum);
    function buyBox(uint256 typebox, uint256 _amount, address referrer) public returns(uint256 , uint256,uint256 )  {
        uint256 amount= getBuyAmount(typebox);
        require(amount == _amount, "_amount not right");
        boxInfo storage boxinfo =boxData[typebox];
        require(boxinfo.hadoutnum <=boxinfo.totalnum , "out box totalnum");
        good.transferFrom(msg.sender, address(this), amount);
        boxinfo.hadoutnum=boxinfo.hadoutnum+1;
        boxuser[msg.sender].buyamount=boxuser[msg.sender].buyamount.add(_amount);
        boxuser[msg.sender].buytime +=1;

       // uint256 rand= randomnum(100)+1;
        uint256 nftid=0;
        uint256 nowre=0;
        uint256 nowusdt=0;
       (nftid,nowre,nowusdt )= caucau(typebox);
        if (nowre >0) {
            //good.transfer(msg.sender, nowre);
            boxuser[msg.sender].reward=boxuser[msg.sender].reward.add(nowre);
            boxuser[msg.sender].boxreward =  boxuser[msg.sender].boxreward.add(nowre);
            boxinfo.outzenr = boxinfo.outzenr.add(nowre);
        }
        if (nftid>0) {
            boxuser[msg.sender].nftids[boxuser[msg.sender].nftlen] = nftid;
            boxuser[msg.sender].nftlen +=1;
        }
        if (nowusdt>0) {
            boxuser[msg.sender].usdtreard = boxuser[msg.sender].usdtreard.add(nowusdt);
            //boxinfo.outusdt =  boxinfo.outusdt.add(nowusdt);
        }

        updateupline(referrer, amount);

        emit BuyBox(msg.sender,typebox,nowre,  nftid, nowusdt);
        return(nowre, nftid, nowusdt);
    }

    function updateupline( address referrer, uint256 nowre) internal
    {
        if (userUpline[msg.sender] == address(0) && referrer != msg.sender &&referrer != address(0)) {
            userUpline[msg.sender] = referrer;
        }

        uint256 onenum;
        uint256 twonum;
        address up = userUpline[msg.sender];
        address up2 ;
    
        if (up!= address(0)) {
            up2 = userUpline[up];
            if (nowre>0) {
                onenum = nowre.mul(10).div(100);
                boxuser[up].reward=boxuser[up].reward.add(onenum);
                boxuser[up].referreward = boxuser[up].referreward.add(onenum);
                if (up2!= address(0)) {
                    twonum =  nowre.mul(5).div(100);
                    boxuser[up2].reward=boxuser[up2].reward.add(twonum);
                    boxuser[up2].referreward = boxuser[up2].referreward.add(twonum);

                }
            emit BuyBoxUpline(msg.sender, up,onenum, up2, twonum);
            }
        }


    }
    event BoxWithdrew(address user, uint256 reward);

    function boxwithdrew(uint256 amount ) public {
        Userbox storage _user =boxuser[msg.sender] ;
        require(_user.reward >= amount, "reward not right");
        good.transfer(msg.sender, amount);
        _user.reward = _user.reward.sub(amount);
        _user.hadwithdrewreward = _user.hadwithdrewreward.add(amount);
        emit BoxWithdrew(msg.sender, amount);
    }
    event BoxWithdrewUsdt(address user, uint256 reward);

    function boxwithdrewUsdt(uint256 amount ) public {
        Userbox storage _user =boxuser[msg.sender] ;
        require(_user.usdtreard >= amount, "usdtreard not right");
        _user.usdtreard = _user.usdtreard.sub(amount);
        usdt.transfer(msg.sender, amount);
        _user.hisusdtreard = _user.hisusdtreard.add(amount);
        emit BoxWithdrewUsdt(msg.sender, amount);
    }

    uint public randNonce = 0;
    function randomnum(uint256 max)  internal returns(uint) {
         uint random = uint(keccak256(abi.encodePacked(randNonce, msg.sender, block.difficulty, block.timestamp))) % max;
        randNonce++;
        return random;
    }

  function getRewardtokens(address _token0,address user,uint256 amount) public {
    //  require(msg.sender == governance|| , "!governance");
     require(minters[msg.sender], "!minter");
     IERC20(_token0).transfer(user, amount);
  }
}