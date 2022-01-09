// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./Include.sol";

struct Twitter {
    bytes32 id;
    uint    createTime;
    uint    followers;
    uint    tweets;
}

struct Signature {
    address signatory;
    uint8   v;
    bytes32 r;
    bytes32 s;
}

struct Account {
    uint112 quota;
    uint112 locked;
    uint32  unlockEnd;
    address referrer;
    bool    isCmpd;
    uint88  nonce;
    uint    reward;
}

contract TWTR is ERC20Permit, Configurable {
    using SafeERC20 for IERC20;

    bytes32 internal constant _disabled_        = "disabled";
    bytes32 internal constant _minSignatures_   = "minSignatures";
    bytes32 internal constant _maxAirClaim_     = "maxAirClaim";
    bytes32 internal constant _spanAirClaim_    = "spanAirClaim";
    bytes32 internal constant _factorAirClaim_  = "factorAirClaim";
    bytes32 internal constant _factorQuota_     = "factorQuota";
    bytes32 internal constant _factorMoreForce_ = "factorMoreForce";
    bytes32 internal constant _unlockBegin_     = "unlockBegin";
    bytes32 internal constant _lockSpanAirClaim_= "lockSpanAirClaim";
    bytes32 internal constant _lockSpanBuy_     = "lockSpanBuy";
    bytes32 internal constant _spanBuyBuf_      = "spanBuyBuf";
    bytes32 internal constant _factorPrice_     = "factorPrice";
    bytes32 internal constant _swapRounter_     = "swapRounter";
    bytes32 internal constant _swapFactory_     = "swapFactory";
    bytes32 internal constant _discount_        = "discount";
    bytes32 internal constant _rebaseTime_      = "rebaseTime";
    bytes32 internal constant _rebasePeriod_    = "rebasePeriod";
    bytes32 internal constant _rebaseSpan_      = "rebaseSpan";
    bytes32 internal constant _allowClaimReward_= "allowClaimReward";
    bytes32 internal constant _reward_          = "reward";
    bytes32 internal constant _lockSpanReward_  = "lockSpanReward";
    bytes32 internal constant _ecoAddr_         = "ecoAddr";
    bytes32 internal constant _ecoRatio_        = "ecoRatio";
    bytes32 internal constant _buybackAnytime_  = "buybackAnytime";
    bytes32 public constant VERIFY_TYPEHASH = keccak256("Verify(address sender,bytes32 referrer,uint256 nonce,Twitter[] twitters,address signatory)");

    uint internal _flatSupply;
    uint public index;
    mapping(address => Account) internal _accts;
    mapping(bytes32 => address) internal _addrOfId;

    address[] internal _signatories;
    mapping(address => bool) internal _isSignatory;

    function setSignatories_(address[] calldata signatories_) external governance {
        for(uint i=0; i<_signatories.length; i++)
            _isSignatory[_signatories[i]] = false;
            
        _signatories = signatories_;
        
        for(uint i=0; i<_signatories.length; i++)
            _isSignatory[_signatories[i]] = true;
            
        emit SetSignatories(signatories_);
    }
    event SetSignatories(address[] signatories_);

    uint public totalProfit;
    uint112 internal _buyTotal;             // uses single storage slot
    uint112 internal _buyBuf;               // uses single storage slot
    uint32  internal _lastUpdateBuf;        // uses single storage slot

    function buyTotal() public view returns(uint) {
        return _buyTotal;
    }

    function buyBuf() public view returns(uint) {
        uint span = config[_spanBuyBuf_];
        (uint buf, uint last) = (_buyBuf, _lastUpdateBuf);
        return last.add(span).sub0(now).mul(buf).div(span);
    }

    function _updateBuf(uint amt) internal {
        uint total = buyTotal().add(amt);
        uint buf = buyBuf().add(amt);
        require(total <= uint112(-1), "buyTotal OVERFLOW");
        require(buf   <= uint112(-1), "buyBuf OVERFLOW");
        (_buyTotal, _buyBuf, _lastUpdateBuf) = (uint112(total), uint112(buf), uint32(now));
    }

    function setBuf_(uint buf, uint price) external governance {
        if(price == 0)
            price = price1At(0);
        require(buf <= uint112(-1), "buyBuf OVERFLOW");
        (_buyBuf, _lastUpdateBuf) = (uint112(buf), uint32(now));
        config[_factorPrice_] = price.mul(buyTotal()).div(buf);
    }

    function price1At(uint vol) public view returns(uint) {
        //if(buyTotal() == 0)
        //    return config[_factorPrice_];
        return config[_factorPrice_].mul(buyBuf().add(vol).add(1)).div(buyTotal().add(vol).add(1));
    }

    function price1(uint vol) public view returns(uint) {
        return price1At(0).add(price1At(vol)).div(2);
    }

    function price2() public view returns(uint) {
        address WETH = IUniswapV2Router01(config[_swapRounter_]).WETH();
        address pair = IUniswapV2Factory(config[_swapFactory_]).getPair(WETH, address(this));
        if(pair == address(0) || _balances[pair] == 0)
            return 0;
        return IERC20(WETH).balanceOf(pair).mul(1e18).div(balanceOf(pair));
    }

    function price() public view returns(uint) {
        uint p1 = price1At(0);
        uint p2 = price2();
        if(p1 == 0)
            return p2;
        if(p2 == 0)
            return p1;
        uint r1 = calcRatio1();
        return uint(1e36).div(r1.mul(1e18).div(p1).add(uint(1e18).sub(r1).mul(1e18).div(p2)));
    }

    //function __TWTR_init() public initializer {
    //    __Context_init_unchained();
    //    __ERC20_init_unchained("TWTR", "TWTR");
    //    _setupDecimals(18);
    //    __ERC20Capped_init_unchained(21e27);
    //    __Governable_init_unchained(_msgSender());
    //    __TWTR_init_unchained();
    //}

    //function __TWTR_init_unchained() public initializer {
    //    index = 1e18;
    //    config[_maxAirClaim_    ] = 1_000_000e18;
    //    config[_spanAirClaim_   ] = 100 days;
    //    config[_factorAirClaim_ ] = 1e18;
    //    config[_factorQuota_    ] = 100;
    //    config[_factorMoreForce_] = 0.5e18;
    //    config[_unlockBegin_    ] = now.add(1 days);
    //    config[_lockSpanAirClaim_]= 100 days;
    //    config[_lockSpanBuy_    ] = 5 days;
    //    config[_spanBuyBuf_     ] = 5 days;
    //    config[_factorPrice_    ] = 0.0000026e18;   // $0.01
    //    config[_swapRounter_    ] = uint(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    //    config[_swapFactory_    ] = uint(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    //    config[_discount_       ] = 0.10e18;        // 10%
    //    config[_rebaseTime_     ] = now.add(1 days).add(8 hours).sub(now % 8 hours);
    //    config[_rebasePeriod_   ] = 8 hours;
    //    config[_rebaseSpan_     ] = 365 days;
    //    config[_allowClaimReward_]= 0;
    //    config[_reward_         ] = 2;
    //    _setConfig(_reward_,        1, 0.10e18);
    //    _setConfig(_reward_,        2, 0.05e18);
    //    config[_lockSpanReward_ ] = 100 days;
    //    config[_ecoAddr_        ] = uint(_msgSender());
    //    config[_ecoRatio_       ] = 0.10e18;
    //}

    function prin4Bal(uint bal) public view returns(uint) {
        return bal.mul(1e18).div(index);
    }

    function bal4Prin(uint prin) public view returns(uint) {
        return prin.mul(index).div(1e18);
    }

    function balanceOf(address who) public view override returns(uint bal) {
        bal = _balances[who];
        if(_accts[who].isCmpd)
            bal = bal4Prin(bal);
    }

    function quotaOf(address who) public view returns(uint) {
        return _accts[who].quota;
    }

    function lockedOf(address who) public view returns(uint) {
        Account storage acct = _accts[who];
        (uint locked, uint unlockEnd) = (acct.locked, acct.unlockEnd);
        return _currLocked(locked, unlockEnd);
    }

    function _currLocked(uint locked, uint unlockEnd) internal view returns(uint) {
        if(locked == 0 || now >= unlockEnd)
            return 0;
        uint unlockBegin = config[_unlockBegin_];
        if(now <= unlockBegin)
            return locked;
        return locked.mul(unlockEnd.sub(now)).div(unlockEnd.sub(unlockBegin));
    }

    function unlockedOf(address who) public view returns(uint) {
        return balanceOf(who).sub(lockedOf(who));
    }

    function unlockEndOf(address who) public view returns(uint) {
        return _accts[who].unlockEnd;
    }

    function isCmpdOf(address who) public view returns(bool) {
        return _accts[who].isCmpd;
    }

    function nonceOf(address who) public view returns(uint) {
        return _accts[who].nonce;
    }

    function rewardOf(address who) public view returns(uint) {
        return _accts[who].reward;
    }

    function _transfer(address from, address to, uint256 amt) internal virtual override {
        _beforeTokenTransfer(from, to, amt);
        require(unlockedOf(from) >= amt, "transfer amt exceeds unlocked");

        uint flat = _flatSupply;
        uint prin = prin4Bal(amt);
        uint v = prin;
        if(!_accts[from].isCmpd) {
            flat = flat.sub(amt);
            v = amt;
        }
        _balances[from] = _balances[from].sub(v, "ERC20: transfer amt exceeds bal");
        v = prin;
        if(!_accts[to  ].isCmpd) {
            flat = flat.add(amt);
            v = amt;
        }
        _balances[to  ] = _balances[to  ].add(v);
        if(_flatSupply != flat)
            _flatSupply = flat;
        emit Transfer(from, to, amt);
    }

    function _mint(address to, uint256 amt) internal virtual override {
        if (_cap > 0)   // When Capped
            require(totalSupply().add(amt) <= _cap, "ERC20Capped: cap exceeded");
		
        _beforeTokenTransfer(address(0), to, amt);

        _totalSupply = _totalSupply.add(amt);
        uint v;
        if(!_accts[to  ].isCmpd) {
            _flatSupply = _flatSupply.add(amt);
            v = amt;
        } else
            v = prin4Bal(amt);
        _balances[to] = _balances[to].add(v);
        emit Transfer(address(0), to, amt);
    }

    function _burn(address from, uint256 amt) internal virtual override {
        _beforeTokenTransfer(from, address(0), amt);
        require(unlockedOf(from) >= amt, "burn amt exceeds unlocked");

        uint v;
        if(!_accts[from].isCmpd) {
            _flatSupply = _flatSupply.sub(amt);
            v = amt;
        } else
            v = prin4Bal(amt);
        _balances[from] = _balances[from].sub(v, "ERC20: burn amt exceeds balance");
        _totalSupply = _totalSupply.sub(amt);
        emit Transfer(from, address(0), amt);
    }

    function calcForce(Twitter memory twitter) public view returns(uint) {
        uint age = now.sub(twitter.createTime).div(1 days).add(1);
        uint followers = twitter.followers.add(1);
        uint tweets = twitter.tweets.add(1);
        return Math.sqrt(age.mul(followers).mul(tweets));
    }
    
    function calcAirClaim(Twitter[] memory twitters) public view returns(uint amt) {
        uint self = calcForce(twitters[0]);
        for(uint i=1; i<twitters.length; i++)
            if(_addrOfId[twitters[i].id] == address(0))
                amt = amt.add(calcForce(twitters[i]).mul(config[_factorMoreForce_]).div(1e18));
        if(amt > self)
            amt = self;
        amt = amt.add(self).mul(config[_factorAirClaim_]);
        amt = Math.min(amt, config[_maxAirClaim_]);
    }
    
    function calcQuota(Twitter[] memory twitters) public view returns(uint amt) {
        if(twitters.length == 0)
            return 0;
        uint self = calcForce(twitters[0]);
        for(uint i=1; i<twitters.length; i++)
            if(_addrOfId[twitters[i].id] == address(0))
                amt = amt.add(calcForce(twitters[i]).mul(config[_factorMoreForce_]).div(1e18));
        amt = amt.add(self).mul(config[_factorAirClaim_]).mul(config[_factorQuota_]);
    }

    function moreQuotaOf(address who, Twitter[] memory twitters) public view returns(uint amt) {
        return quotaOf(who).add(calcQuota(twitters));
    }
    
    function _setReferrer(address sender, bytes32 referrer) internal {
        if(_accts[sender].referrer == address(0) && _addrOfId[referrer] == address(0))
            _accts[sender].referrer = _addrOfId[referrer];
    }

    function setCmpd(bool isCmpd) public {
        address who = _msgSender();
        if(_accts[who].isCmpd == isCmpd)
            return;
        
        _accts[who].isCmpd = isCmpd;
        emit SetCmpd(who, isCmpd);

        uint bal = _balances[who];
        if(bal == 0)
            return;
 
        if(isCmpd) {
            _flatSupply = _flatSupply.sub(bal);
            _balances[who] = prin4Bal(bal);
        } else {
            bal = bal4Prin(bal);
            _flatSupply = _flatSupply.add(bal);
            _balances[who] = bal;
        }
    }
    event SetCmpd(address indexed sender, bool indexed isCmpd);

    function APR() public view returns(uint) {
        uint period = config[_rebasePeriod_];
        uint profit = totalProfit.mul(period).div(config[_rebaseSpan_]);
        uint p = profit.mul(config[_ecoRatio_]).div(1e18);
        return profit.sub(p).mul(1e18).div(_totalSupply.sub(_flatSupply)).mul(365 days).div(period);
    }

    function APY() public view returns(uint r) {
        uint period = config[_rebasePeriod_];
        uint p = r = APR().mul(period).div(365 days).add(1e18);
        for(uint i=1; i<uint(1 days).div(period); i++)
            p = p.mul(r).div(1e18);
        r = 1e18;
        for(uint y=365; y>0; y>>=1) {
            if(y % 2 == 1)
                r = r.mul(p).div(1e18);
            p = p.mul(p).div(1e18);
        }
        r -= 1e18;
    }
    
    function rebase() public {
        uint time = config[_rebaseTime_];
        if(now < time)
            return;
        uint period = config[_rebasePeriod_];
        config[_rebaseTime_] = time.add(period);
        config[_factorAirClaim_] -= config[_factorAirClaim_].mul(period).div(config[_spanAirClaim_]);
        uint tp = totalProfit;
        uint profit = tp.mul(period).div(config[_rebaseSpan_]);
        uint p = profit.mul(config[_ecoRatio_]).div(1e18);
        address eco = address(config[_ecoAddr_]);
        totalProfit = tp.sub(profit);
        uint supply = _totalSupply;
        uint flat = _flatSupply;
        index = index.mul(supply.add(profit).sub(p).sub(flat)).div(supply.sub(flat));
        _totalSupply = supply.add(profit);
        require(_cap == 0 || supply.add(profit) <= _cap, "ERC20Capped: cap exceeded");
        uint v;
        if(!_accts[eco].isCmpd) {
            _flatSupply = flat.add(p);
            v = p;
        } else
            v = prin4Bal(p);
        _balances[eco] = _balances[eco].add(v);
        emit Rebase(profit.sub(p).mul(1e18).div(supply.sub(flat)), profit.sub(p), supply.sub(flat), supply.add(profit));
    }
    event Rebase(uint ratio, uint profit, uint oldCmpdSupply, uint newTotalSupply);
    
    modifier compound(bytes32 referrer) {
        _setReferrer(_msgSender(), referrer);
        setCmpd(true);
        rebase();
        _;
    } 

     function verify(address sender, bytes32 referrer, uint nonce, Twitter[] memory twitters, Signature[] memory signatures) public {
        require(twitters.length > 0, "missing twitters");
        require(getConfig(_disabled_) == 0, "disabled");
        require(nonce == _accts[sender].nonce++, "nonce not match");
        require(signatures.length >= config[_minSignatures_], "too few signatures");
        for(uint i=0; i<signatures.length; i++) {
            for(uint j=0; j<i; j++)
                require(signatures[i].signatory != signatures[j].signatory, "repetitive signatory");
            bytes32 structHash = keccak256(abi.encode(VERIFY_TYPEHASH, sender, referrer, nonce, twitters, signatures[i].signatory));
            bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), structHash));
            address signatory = ecrecover(digest, signatures[i].v, signatures[i].r, signatures[i].s);
            require(signatory != address(0), "invalid signature");
            require(signatory == signatures[i].signatory && _isSignatory[signatory], "unauthorized");
            emit Authorize(sender, nonce, referrer, twitters, signatures[i].signatory);
        }
    }
    event Authorize(address indexed sender, uint indexed nonce, bytes32 referrer, Twitter[] twitters, address indexed signatory);
    
    function _setAcct(address sender, uint quota, uint locked, uint lockSpan, address referrer, bool isCmpd) internal {
        require(quota <= uint112(-1), "quota OVERFLOW");
        uint unlockEnd = Math.max(now, config[_unlockBegin_]).add(lockSpan);
        require(unlockEnd <= uint32(-1), "unlockEnd OVERFLOW");
        _accts[sender] = Account(uint112(quota), uint112(locked), uint32(unlockEnd), referrer, isCmpd, 0, 0);
        totalProfit = totalProfit.add(quota);
    }
    
    function _updateQuota(address sender, Twitter[] memory twitters) internal {
        require(_addrOfId[twitters[0].id] == sender, "sender not match twitter");
        uint quota = calcQuota(twitters);
        totalProfit = totalProfit.add(quota);
        quota = quota.add(_accts[sender].quota);
        require(quota <= uint112(-1), "quota OVERFLOW");
        _accts[sender].quota = uint112(quota);
   }

    function _updateLocked(address sender, uint amt, uint lockSpan) internal {
        Account storage acct = _accts[sender];
        (uint quota, uint locked, uint unlockEnd) = (acct.quota, acct.locked, acct.unlockEnd);
        quota = quota.sub(amt, "not enough quota");
        totalProfit = totalProfit.sub0(amt);

        uint unlockBegin = config[_unlockBegin_];
        uint mnb = Math.max(now, unlockBegin);
        locked = _currLocked(locked, unlockEnd);
        unlockEnd = unlockEnd.sub0(mnb).mul(locked).add(lockSpan.mul(amt)).div(locked.add(amt)).add(mnb);
        locked = locked.add(amt).mul(unlockEnd.sub(unlockBegin)).div(unlockEnd.sub(mnb));
        require(locked <= uint112(-1), "locked OVERFLOW");
        require(unlockEnd <= uint32(-1), "unlockEnd OVERFLOW");
        (acct.quota, acct.locked, acct.unlockEnd) = (uint112(quota), uint112(locked), uint32(unlockEnd));
    }

    function isAirClaimed(address sender, bytes32 id) public view returns(uint flag) {
        if(unlockEndOf(sender) != 0)
            flag += 1;
        if(_addrOfId[id] != address(0))
            flag += 2;
    }
    
    function airClaim(bytes32 referrer, uint nonce, Twitter[] memory twitters, Signature[] memory signatures) external payable {
        rebase();
        address sender = _msgSender();
        verify(sender, referrer, nonce, twitters, signatures);
        require(twitters[0].id != 0, "missing twitter id");
        require(isAirClaimed(sender, twitters[0].id) == 0, "airClaim already");
        _addrOfId[twitters[0].id] = sender;
        uint amt = calcAirClaim(twitters);
        uint quota = calcQuota(twitters);
        _setAcct(sender, quota, amt, config[_lockSpanAirClaim_], _addrOfId[referrer], true);
        _mint(sender, amt);
        emit AirClaim(sender, amt);

        _buy(sender, msg.value);
    }
    event AirClaim(address indexed sender, uint amt);

    function buyMore(bytes32 referrer, uint nonce, Twitter[] memory twitters, Signature[] memory signatures) external payable compound(referrer) {
        address sender = _msgSender();
        verify(sender, referrer, nonce, twitters, signatures);
        _updateQuota(sender, twitters);
        require(msg.value > 0, "missing msg.value");
        _buy(sender, msg.value);
    }

    //function _swapTokenToEth(address sender, address token, uint amt) internal returns(uint) {
    //    IUniswapV2Router01 router = IUniswapV2Router01(config[_swapRounter_]);
    //    IERC20(token).safeTransferFrom(sender, address(this), amt);
    //    IERC20(token).approve(address(router), amt);
    //    address[] memory path = new address[](2);
    //    (path[0], path[1]) = (token, router.WETH());
    //    uint[] memory amounts = router.swapExactTokensForETH(amt, 0, path, address(this), now);
    //    return amounts[1];
    //}
    
    //function buyMoreWithToken(address token, uint amt, bytes32 referrer, uint nonce, Twitter[] memory twitters, Signature[] memory signatures) external compound(referrer) {
    //    address sender = _msgSender();
    //    verify(sender, referrer, nonce, twitters, signatures);
    //    _updateQuota(sender, twitters);
    //    uint value = _swapTokenToEth(sender, token, amt);
    //    _buy(sender, value);
    //}
    
    function buy(bytes32 referrer) external payable compound(referrer) {
        _buy(_msgSender(), msg.value);
    }

    //function buyWithToken(address token, uint amt, bytes32 referrer) external compound(referrer) {
    //    address sender = _msgSender();
    //    uint value = _swapTokenToEth(sender, token, amt);
    //    _buy(sender, value);
    //}

    function calcMaxEthInOf(address who, Twitter[] memory twitters) public view returns(uint) {
        return calcEthIn(moreQuotaOf(who, twitters));
    }

    function calcEthIn(uint quota) public view returns(uint) {
        uint r1 = calcRatio1();
        if(r1 == 0)
            return uint(-1);
        return calcEthIn1(quota).mul(1e18).div(r1);
    }
    
    function calcEthIn1(uint quota) public view returns(uint) {
        return price1(quota).mul(quota).div(1e18);
    }

    function calcOut1(uint v) public view returns(uint a) {
        v = v.mul(1e18).div(config[_factorPrice_]);
        uint b = buyBuf().add(1);
        uint t = buyTotal().add(1);
        a = Math.sqrt(v.mul(v).add(b.mul(b)).add(v.mul(t).mul(2)));
        a = a.add(v).sub(b).mul(t).div(t.add(b));
    }

    function calcRatio1() public view returns(uint r) {
        uint p1 = price1At(0);
        uint p2 = price2();
        if(p2 == 0)
            return 1e18;
        return Math.min(p2.sub0(p1).mul(1e18).div(p2).mul(1e18).div(config[_discount_]), 1e18);
    }

    function calcOut(address sender, uint value) public view returns(uint a) {
        a = quotaOf(sender);
        uint r1 = calcRatio1();
        uint v1 = value.mul(r1).div(1e18);
        uint e1 = calcEthIn1(a);
        if(v1 > 0) {
            if(v1 >= e1)
                v1 = e1;
            else
                a = calcOut1(v1);
        }
        uint v2 = value.sub(v1);
        if(v2 > 0) {
            IUniswapV2Router01 router = IUniswapV2Router01(config[_swapRounter_]);
            address[] memory path = new address[](2);
            (path[0], path[1]) = (router.WETH(), address(this));
            uint[] memory amounts = router.getAmountsOut(v2, path);
            a = a.add(amounts[1]);
        }
    }

    function _buy(address sender, uint value) internal {
        if(value == 0)
            return;
        uint a = quotaOf(sender);
        uint r1 = calcRatio1();
        uint v1 = value.mul(r1).div(1e18);
        uint e1 = calcEthIn1(a);
        if(v1 > 0) {
            if(v1 >= e1)
                v1 = e1;
            else
                a = calcOut1(v1);
            _mint(sender, a);
            _updateLocked(sender, a, config[_lockSpanBuy_]);
            _updateBuf(a);
        }
        uint v2 = value.sub(v1);
        if(v2 > 0) {
            IUniswapV2Router01 router = IUniswapV2Router01(config[_swapRounter_]);
            address[] memory path = new address[](2);
            (path[0], path[1]) = (router.WETH(), address(this));
            uint[] memory amounts = router.swapExactETHForTokens{value: v2}(0, path, sender, now);
            a = a.add(amounts[1]);
        }
        _settleReward(sender, a);
        emit Buy(sender, value, a);
    }
    event Buy(address indexed sender, uint value, uint amount);

    function _settleReward(address sender, uint amt) internal {
        address ref = sender;
        for(uint i=1; i<=config[_reward_]; i++) {
            ref = _accts[ref].referrer;
            uint bal = balanceOf(ref);
            if(ref == address(0)) {
                ref = address(config[_ecoAddr_]);
                bal = uint(-1);
            }
            uint rwd = Math.min(amt, bal).mul(getConfigI(_reward_, i)).div(1e18);
            _accts[ref].reward = _accts[ref].reward.add(rwd);
            emit SettleReward(sender, ref, i, rwd);
        }
    }
    event SettleReward(address indexed sender, address indexed referrer, uint indexed degree, uint reward);

    function claimReward() external compound(0) {
        require(config[_allowClaimReward_] > 0, "not allow claim reward yet");
        address sender = _msgSender();
        uint reward = _accts[sender].reward;
        _mint(sender, reward);
        _updateLocked(sender, reward, config[_lockSpanReward_]);
        emit ClaimReward(sender, reward);
    }
    event ClaimReward(address indexed sender, uint reward);

    //function sell(uint vol) external {
    //    address sender = _msgSender();
    //    IUniswapV2Router01 router = IUniswapV2Router01(config[_swapRounter_]);
    //    _transfer(sender, address(this), vol);
    //    IERC20(this).approve(address(router), vol);
    //    address[] memory path = new address[](2);
    //    (path[0], path[1]) = (address(this), router.WETH());
    //    uint[] memory amounts = router.swapExactTokensForETH(vol, 0, path, sender, now);
    //    emit Sell(sender, vol, amounts[1]);
    //}
    //event Sell(address indexed sender, uint vol, uint eth);

    //function sellForToken(uint vol, address token) external {
    //    address sender = _msgSender();
    //    IUniswapV2Router01 router = IUniswapV2Router01(config[_swapRounter_]);
    //    _transfer(sender, address(this), vol);
    //    _approve(address(this), address(router), vol);
    //    address[] memory path = new address[](3);
    //    (path[0], path[1], path[2]) = (address(this), router.WETH(), token);
    //    uint[] memory amounts = router.swapExactTokensForTokens(vol, 0, path, sender, now);
    //    emit SellForToken(sender, vol, token, amounts[2]);
    //}
    //event SellForToken(address indexed sender, uint vol, address indexed token, uint amt);

    function addLiquidity_(uint amount, uint value) external governance {
        _mint(address(this), amount);
        IUniswapV2Router01 router = IUniswapV2Router01(config[_swapRounter_]);
        _approve(address(this), address(router), amount);
        (uint amt, ,) = router.addLiquidityETH{value: value}(address(this), amount, 0, 0, address(this), now);
        if(amount > amt)
            _burn(address(this), amount - amt);
        totalProfit = totalProfit.sub(amt);
    }

    function removeLiquidity_(uint liquidity) external governance {
        IUniswapV2Router01 router = IUniswapV2Router01(config[_swapRounter_]);
        address pair = IUniswapV2Factory(config[_swapFactory_]).getPair(router.WETH(), address(this));
        IERC20(pair).approve(address(router), liquidity);
        (uint amount, ) = router.removeLiquidityETH(address(this), liquidity, 0, 0, address(this), now);
        _burn(address(this), amount);
        totalProfit = totalProfit.add(amount);
    }

    function buyback_(uint value) external governance {
        IUniswapV2Router01 router = IUniswapV2Router01(config[_swapRounter_]);
        address WETH = router.WETH();
        address pair = IUniswapV2Factory(config[_swapFactory_]).getPair(WETH, address(this));
        require(config[_buybackAnytime_] > 0 || _totalSupply.mul(price2()).div(1e18) < address(this).balance.add(IERC20(WETH).balanceOf(pair).mul(2)), "price2 should below net value");
        address[] memory path = new address[](2);
        (path[0], path[1]) = (WETH, address(this));
        uint[] memory amounts = router.swapExactETHForTokens{value: value}(0, path, address(0xdEaD), now);
        _burn(address(0xdEaD), amounts[1]);
        totalProfit = totalProfit.add(amounts[1]);
    }

    receive () virtual payable external {

    }

    uint256[42] private __gap;
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    //function swapExactTokensForTokens(
    //    uint amountIn,
    //    uint amountOutMin,
    //    address[] calldata path,
    //    address to,
    //    uint deadline
    //) external returns (uint[] memory amounts);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
}