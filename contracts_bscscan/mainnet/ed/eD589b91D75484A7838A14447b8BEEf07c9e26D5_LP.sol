// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./IBEP20.sol";
import "./LPWallet.sol";
import "./TransferHelper.sol";

/**
 * pancake interface
 * https://github.com/pancakeswap
 */
interface IPancakePair {
    //get token0
    function token0() external view returns (address);
    //get token1
    function token1() external view returns (address);
    //get reserves
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}


interface IMinerPool {
     function mineOut(address to,uint256 amount) external;
}


interface IDataPublic {
    function checkParent(address addr, address parent) external;
    function getParent(address addr) external view returns (address, bool);
    function onChildWithdrawLp(address addr, address child, uint256 amt, uint256 pRebate, bool isReward) external;
}

// address index
library eAddr {
    //contract owner
    uint constant owner = 1;
    // Pancake swap USDT - WBNB
    uint constant wbnbPancake = 2;
    uint constant usdt = 3;
    uint constant minerPool = 4;
    uint constant hpc = 5;
    uint constant dataPublic = 6;
}

library eUint256 {
    uint constant rebateRate = 1;
    uint constant gac = 2;
    uint constant entrancy = 3;
}

library ePoolType {
    uint8 constant bnb = 1;
    uint8 constant usdt = 2;
}

library eBool {
    uint constant isEnable = 1;
}

library eUser {
    uint256 constant gameAccelerate = 1;
    uint256 constant totalRabate = 2;
    uint256 constant pendingRebate = 3;
    uint256 constant totalLpInUsdt = 4;
}

// the LP contract
contract LP   {
    
    using SafeMath for uint256;
    using TransferHelper for address;
    

    mapping(uint => address) private _dataAddr;
    mapping(address =>LpPool) private _pool;
    mapping(address => bool) private _mgrs;
    mapping(uint => bool) private _dataBool;
    mapping(address => mapping(uint=>uint256)) _userInfo;
    // mapping(address => bool) private _addrLock;
    mapping(uint => uint256) private _dataUint256;
    mapping(address => mapping(address=> UserLp)) _lp;
    address[] _tokens;
    
    struct LpPool {
        // wallet
        LpWallet wallet;
        // pool address
        address pancake;
        // USDT pool or BNB
        uint8 poolType;
        // interest
        uint256 interestRatePerBlock;
        uint8 decimal;
    }

    struct UserLp {
        uint256 amount;
        uint256 amountInUsdt;
        uint256 lastCheckBlock;
        uint256 pendingReward;
        uint256 hpcPrice;
    }

    modifier onlyMgr() {
        require(_mgrs[msg.sender], 'mgr');
        _;
    }

    // modifier lockAddr(address addr) {
    //     require(!_addrLock[addr], "lock");
    //     _addrLock[addr] = true;
    //     _;
    //     _addrLock[addr] = false;
    // }

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_dataUint256[eUint256.entrancy] != 1, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _dataUint256[eUint256.entrancy] = 1;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _dataUint256[eUint256.entrancy] = 0; 
    }
    
    modifier reqEnable() {
        require(_dataBool[eBool.isEnable], "E");
        _;
    }
    
    event Deposite(address addr, address token, uint256 amt, uint256 totalLpInUsdt);
    event Takeback(address addr,  address token, uint256 amt, uint256 totalLpInUsdt);
    event WithdrawReward(address addr, address token,  uint256 amt);
    event WithdrawRebate(address addr, uint256 amt);

    function init(
        address[5] memory addrs,
        uint256[1] memory args
    )  public   {
        require(_dataAddr[eAddr.owner] == address(0), "inited");

        _dataAddr[eAddr.owner] = msg.sender;
        _dataAddr[eAddr.wbnbPancake] = addrs[0];
        _dataAddr[eAddr.usdt] = addrs[1];
        _dataAddr[eAddr.hpc] = addrs[2];
        _dataAddr[eAddr.minerPool] = addrs[3];
        _dataAddr[eAddr.dataPublic] = addrs[4];
        // scale 1e10
        _dataUint256[eUint256.rebateRate] = args[0];
        //1.143
        _dataUint256[eUint256.gac] = 1143 * 1e7;
        _mgrs[msg.sender] = true;
    }

    function tokensCount() public view returns (uint256) {
        return _tokens.length;
    }

    function setAddr(uint idx, address v) public onlyMgr { 
        _dataAddr[idx] = v;
    }
    
    function getAddr(uint idx) public view returns(address) {
        return _dataAddr[idx];
    }
    
    function setUint256(uint idx, uint256 v) public onlyMgr {
        if (idx == eUint256.entrancy) {
            return;
        }
        if (_dataUint256[idx] != v) {
            _dataUint256[idx] = v;
        }
    }

    function getUint256(uint idx) public view returns(uint256) {
        return _dataUint256[idx];
    }

    function setEnable(bool v) public onlyMgr {
        if (_dataBool[eBool.isEnable] == v) {
            return;
        }
        _dataBool[eBool.isEnable] = v;
    }

    function getEnable() public view returns (bool) {
        return _dataBool[eBool.isEnable];
    }

    function setMgr(address addr, bool v) public onlyMgr {
        if (addr == _dataAddr[eAddr.owner]) {
            return;
        }
        if (_mgrs[addr] != v) {
            _mgrs[addr] = v;
        }
    }
    
    function getMgr(address addr) public view returns(bool) {
        return _mgrs[addr];
    }

    function addPool(
        address token,
        address pancake,
        address vToken,
        uint8 poolType,
        uint256 interestRatePerBlock,
        uint8 decimal
    ) public onlyMgr {
        require(_pool[token].pancake == address(0), "exists");
        LpWallet wallet = new LpWallet(token, _dataAddr[eAddr.owner], vToken);
        _pool[token] = LpPool({
            wallet: wallet,
            pancake: pancake,
            poolType: poolType,
            interestRatePerBlock: interestRatePerBlock,
            decimal : decimal
        });
        _tokens.push(token);
    }

    function fixPool(
        address token,
        address pancake,
        address vToken,
        uint8 poolType,
        uint256 interestRatePerBlock,
        uint8 decimal
    ) public onlyMgr {
        _pool[token].pancake = pancake;
        _pool[token].poolType = poolType;
        _pool[token].interestRatePerBlock = interestRatePerBlock;
        _pool[token].wallet.setVToken(vToken);
        _pool[token].decimal = decimal;
    }

    function getTokenCount() public view returns (uint256) {
        return _tokens.length;
    }

    function getTokens(uint256 from) public view returns (address[20] memory) {
        address[20] memory rs;
        for (uint256 i = from; i < from + 20 && i < _tokens.length; i++) {
            rs[i - from] = _tokens[i];
        }
        return rs;
    }

    function getPendingReawrd(address addr, address token) public view returns (uint256[3] memory) {
        uint256[3] memory rs;
        rs[1] = _lp[addr][token].lastCheckBlock;
        rs[2] = uint256(block.number);
        if (_lp[addr][token].amountInUsdt == 0) {
            rs[0] = _lp[addr][token].pendingReward;
            return rs;
        }
        
        uint256 b = block.number;
        uint256 bn = b.sub(_lp[addr][token].lastCheckBlock);
        
        // scale is 1e10
        uint256 rate = _pool[token].interestRatePerBlock;
        if (_userInfo[addr][eUser.gameAccelerate] != 0) {
            rate +=  rate.mul(_dataUint256[eUint256.gac]).div(1e10);
        }

        // price scale 1e18
        // revenuePerBlock = total deposite * rate / hpcprice
        uint256 revenuePerBlock = _lp[addr][token].amountInUsdt.mul(rate).mul(1e18).div(_lp[addr][token].hpcPrice);
        // rate scale is 1e10
        uint256 interest  = bn.mul(revenuePerBlock).div(1e10);

        rs[0] = interest.add(_lp[addr][token].pendingReward);
        return rs;
    }

    function beforeChangeLp(address addr, address token) private {
        uint256[3] memory reward = getPendingReawrd(addr, token);
        _lp[addr][token].pendingReward = reward[0];
        _lp[addr][token].lastCheckBlock = uint256(block.number);
    }

    function deposite(address token, uint256 amount, address parent) public payable reqEnable /*lockAddr(msg.sender)*/   {
        IDataPublic(_dataAddr[eAddr.dataPublic]).checkParent(msg.sender, parent);
        require(_pool[token].pancake != address(0), "T");
        if (token == address(2)) {
            amount = msg.value;
        }
        require(amount > 0, "amt");
        uint256 hpcPrice = getTokenUsdtPrice(_dataAddr[eAddr.hpc]);
        require(hpcPrice>0,"HP");
        uint256 price = getTokenUsdtPrice(token);
        require(price > 0, "P");
        // scale 1e18
        uint256 amtInUsdt = amount.mul(price).div(1e18);
        if (amtInUsdt == 0) {
            return;
        }
        beforeChangeLp(msg.sender, token);
        uint256 bnb = 0;
        if (token == address(2)) {
            // BNB
            bnb = amount;
        }  else {
            token.safeTransferFrom( msg.sender, address(_pool[token].wallet),amount);
        }
        _pool[token].wallet.deposite{value:bnb}(msg.sender, amount);
        
        _lp[msg.sender][token].amount = _lp[msg.sender][token].amount.add(amount);
        _lp[msg.sender][token].amountInUsdt = _lp[msg.sender][token].amountInUsdt.add(amtInUsdt);
        _lp[msg.sender][token].hpcPrice = hpcPrice;

        _userInfo[msg.sender][eUser.totalLpInUsdt] = _userInfo[msg.sender][eUser.totalLpInUsdt].add(amtInUsdt);
        
        emit Deposite(msg.sender, token, amount, _userInfo[msg.sender][eUser.totalLpInUsdt]);
    }
    
    function getDeposite(address token, address addr) public view returns(uint256 amt, uint256 amtInUsdt) {
        amt = _lp[addr][token].amount;
        amtInUsdt =_lp[addr][token].amountInUsdt;
    }
    
    function getDeposite(address token) public view returns(uint256 amt) {
        amt = _pool[token].wallet.getTotalLp();
    }

    function takeBack(address token, uint256 percent) public nonReentrant /*lockAddr(msg.sender)*/  {
        require(_pool[token].pancake != address(0), "T");
        require(percent > 0 && percent <= 100, "p");

        uint256 amount = _lp[msg.sender][token].amount.mul(percent).div(100);
        uint256 usdt = _lp[msg.sender][token].amountInUsdt.mul(percent).div(100);
        if (amount == 0) {
            return;
        }

        beforeChangeLp(msg.sender, token);
        _lp[msg.sender][token].amount = _lp[msg.sender][token].amount.subBe0(amount);
        _lp[msg.sender][token].amountInUsdt = _lp[msg.sender][token].amountInUsdt.subBe0(usdt);

        _userInfo[msg.sender][eUser.totalLpInUsdt] = _userInfo[msg.sender][eUser.totalLpInUsdt].subBe0(usdt);

        _pool[token].wallet.takeBack(msg.sender, amount);
        
        emit Takeback(msg.sender,  token, amount, _userInfo[msg.sender][eUser.totalLpInUsdt]);
    }

    function takeBackByAmt(address token, uint256 amount) public nonReentrant /*lockAddr(msg.sender)*/  {
        require(_pool[token].pancake != address(0), "T");
        require(amount > 0 && amount  <= _lp[msg.sender][token].amount, "p");

        uint256 percent = amount.mul(100) / _lp[msg.sender][token].amount;
        uint256 usdt = _lp[msg.sender][token].amountInUsdt.mul(percent).div(100);

        beforeChangeLp(msg.sender, token);
        _lp[msg.sender][token].amount = _lp[msg.sender][token].amount.subBe0(amount);
        _lp[msg.sender][token].amountInUsdt = _lp[msg.sender][token].amountInUsdt.subBe0(usdt);

        _userInfo[msg.sender][eUser.totalLpInUsdt] = _userInfo[msg.sender][eUser.totalLpInUsdt].subBe0(usdt);

        _pool[token].wallet.takeBack(msg.sender, amount);
        
        emit Takeback(msg.sender,  token, amount, _userInfo[msg.sender][eUser.totalLpInUsdt]);
    }

    function incRebate(address parent, address child, uint256 rebate, uint256 amt, bool isReward) private /*lockAddr(parent)*/ {
        _userInfo[parent][eUser.pendingRebate] = _userInfo[parent][eUser.pendingRebate].add(rebate);
        _userInfo[parent][eUser.totalRabate] = _userInfo[parent][eUser.totalRabate].add(rebate);

        IDataPublic(_dataAddr[eAddr.dataPublic]).onChildWithdrawLp(parent, child, amt, rebate,  isReward);
    }

    function withdrawReward(address token) public /*lockAddr(msg.sender)*/ {
        uint256[3] memory reward = getPendingReawrd(msg.sender, token);
        if (reward[0] == 0) {
            return;
        }
        
        _lp[msg.sender][token].lastCheckBlock = uint256(block.number);
        _lp[msg.sender][token].pendingReward = 0;
        
        (address parent,) = IDataPublic(_dataAddr[eAddr.dataPublic]).getParent(msg.sender);
        if (parent != address(0)) {
            uint256 prebate = reward[0].mul(_dataUint256[eUint256.rebateRate]).div(1e10);
            if (prebate > 0) {
                incRebate(parent, msg.sender, prebate, reward[0], true);
            }
        }

        IMinerPool(_dataAddr[eAddr.minerPool]).mineOut(msg.sender, reward[0]);
        emit WithdrawReward(msg.sender, token, reward[0]);
    }

    function withdrawRebate() public /*lockAddr(msg.sender)*/ {
        uint256 rebate = _userInfo[msg.sender][eUser.pendingRebate];
        if (rebate == 0) {
            return;
        }

        _userInfo[msg.sender][eUser.pendingRebate] = 0;

        (address parent,) = IDataPublic(_dataAddr[eAddr.dataPublic]).getParent(msg.sender);
        if (parent != address(0)) {
            uint256 prebate = rebate.mul(_dataUint256[eUint256.rebateRate]).div(1e10);
            if (prebate > 0) {
                incRebate(parent, msg.sender, prebate, rebate, false);
            }
        }

        IMinerPool(_dataAddr[eAddr.minerPool]).mineOut(msg.sender, rebate);

        emit WithdrawRebate(msg.sender, rebate);
    }

    function setGAC(address addr, bool isSet) private /*lockAddr(addr)*/ {
        for (uint i = 0; i < _tokens.length; i++) {
            beforeChangeLp(addr, _tokens[i]);
        }
        
        _userInfo[addr][eUser.gameAccelerate] = isSet ? 1 : 0;
    }

    function setGameAccelerate(address[] memory addrs, bool isSet) public onlyMgr {
        for (uint256 i = 0; i < addrs.length; i++) {
            setGAC(addrs[i], isSet);
        }
    }

    function getTokenUsdtPriceFromWBNBPool(
        address token,
        address poolAddr, uint8 decimal 
    ) private view returns (uint256) {
        address token0 = IPancakePair(poolAddr).token0();
        (uint112 _reserve0, uint112 _reserve1, ) = IPancakePair(poolAddr).getReserves();
        uint256 wbnbAmt1 = _reserve0;
        uint256 tokenAmt = _reserve1;
        if (token0 == token) {
            tokenAmt = _reserve0;
            wbnbAmt1 = _reserve1;
        }
        if (decimal == 0) {
            decimal = 18;
        }
        // if decimal > 18, error
        uint256 diff = 10 ** (18 - decimal);

        // USDT - WBNB
        (uint112 _reserve2, uint112 _reserve3, ) = IPancakePair(_dataAddr[eAddr.wbnbPancake]).getReserves();
        uint256 usdtAmt = _reserve2;
        uint256 wbnbAmt2 = _reserve3;
        
        if (wbnbAmt2 == 0 || tokenAmt == 0 ) {
            return 0;
        } 
        // scale 1e18
        return usdtAmt.mul(1e18).mul(wbnbAmt1).div(wbnbAmt2.mul(tokenAmt)).div(diff);
    }

    function getTokenUsdtPriceFromUsdtPool(
        address poolAddr, uint8 decimal
    ) private view returns (uint256){
        address token0 = IPancakePair(poolAddr).token0();
        (uint112 _reserve0, uint112 _reserve1, ) = IPancakePair(poolAddr).getReserves();
        uint256 reserve0 = _reserve0;
        uint256 reserve1 = _reserve1;
        if (decimal == 0) {
            decimal = 18;
        }
        // if decimal > 18, error
        uint256 diff = 10 ** (18 - decimal);
        // scale 1e18
        if (token0 == _dataAddr[eAddr.usdt]) {
            return reserve0.mul(1e18).div(reserve1).div(diff);
        } else {
            return reserve1.mul(1e18).div(reserve0).div(diff);
        }
    }

    // get token price 1 token = N USDT
    // scale 1e18
    function getTokenUsdtPrice(address token)
        public
        view
        returns (uint256)
    {
        if (token == _dataAddr[eAddr.usdt]) {
            return 1e18;
        }
        if (_pool[token].pancake == address(0)) {
            return 0;
        }

        if (_pool[token].poolType == ePoolType.usdt) {
            return getTokenUsdtPriceFromUsdtPool(_pool[token].pancake, _pool[token].decimal);
        } else {
            return getTokenUsdtPriceFromWBNBPool(token, _pool[token].pancake, _pool[token].decimal);
        }
    }

    function getAddrInfo(address addr) public view returns(uint256[4] memory) {
        uint256[4] memory rs;
        for (uint i = eUser.gameAccelerate; i <= eUser.totalLpInUsdt; i++) {
            rs[i-1] = _userInfo[addr][i];
        }
        return rs;
    }

    function reedeemFromVenus(address token, address to) public onlyMgr {
        _pool[token].wallet.reedeemFromVenus(to);
    }

    function depositeToVenus(address token) public onlyMgr {
        _pool[token].wallet.depositeToVenus();
    }
}