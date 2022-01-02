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
}

contract TWTR is ERC20Permit, Configurable {
    bytes32 internal constant _disabled_        = "disabled";
    bytes32 internal constant _minSignatures_   = "minSignatures";
    bytes32 internal constant _maxAirClaim_     = "maxAirClaim";
    bytes32 internal constant _factorAirClaim_  = "factorAirClaim";
    bytes32 internal constant _factorQuota_     = "factorQuota";
    bytes32 internal constant _factorMoreForce_ = "factorMoreForce";
    bytes32 internal constant _unlockBegin_     = "unlockBegin";
    bytes32 internal constant _lockSpanAirClaim_= "lockSpanAirClaim";
    bytes32 public constant VERIFY_TYPEHASH = keccak256("Verify(address sender,bytes32 referrer,Twitter[] twitters,address signatory)");

    uint internal _flatSupply;
    uint internal index;
    mapping(address => Account) internal accts;
    mapping(bytes32 => address) internal _addrOfId;

    address[] public signatories;
    mapping(address => bool) public isSignatory;

    function setSignatories_(address[] calldata signatories_) external governance {
        for(uint i=0; i<signatories.length; i++)
            isSignatory[signatories[i]] = false;
            
        signatories = signatories_;
        
        for(uint i=0; i<signatories.length; i++)
            isSignatory[signatories[i]] = true;
            
        emit SetSignatories(signatories_);
    }
    event SetSignatories(address[] signatories_);

    function __TWTR_init() public initializer {
        __Context_init_unchained();
        __ERC20_init_unchained("TWTR", "TWTR");
        _setupDecimals(18);
        __ERC20Capped_init_unchained(21e27);
        __TWTR_init_unchained();
    }

    function __TWTR_init_unchained() public initializer {
        index = 1e18;
        config[_maxAirClaim_    ] = 1_000_000e18;
        config[_factorAirClaim_ ] = 1e18;
        config[_factorQuota_    ] = 100;
        config[_factorMoreForce_] = 0.5e18;
        config[_lockSpanAirClaim_]= 100 days;
    }

    function prin4Bal(uint bal) public view returns(uint) {
        return bal.mul(1e18).div(index);
    }

    function bal4Prin(uint prin) public view returns(uint) {
        return prin.mul(index).div(1e18);
    }

    function balanceOf(address who) public view override returns(uint bal) {
        bal = _balances[who];
        if(accts[who].isCmpd)
            bal = bal4Prin(bal);
    }

    function quotaOf(address who) public view returns(uint) {
        return accts[who].quota;
    }

    function lockedOf(address who) public view returns(uint) {
        Account storage acct = accts[who];
        (uint locked, uint unlockEnd) = (acct.locked, acct.unlockEnd);
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
        return accts[who].unlockEnd;
    }

    function isCmpdOf(address who) public view returns(bool) {
        return accts[who].isCmpd;
    }

    function _transfer(address from, address to, uint256 amt) internal virtual override {
        _beforeTokenTransfer(from, to, amt);
        require(unlockedOf(from) >= amt, "transfer amt exceeds unlocked");

        uint prin = prin4Bal(amt);
        _balances[from] = _balances[from].sub(accts[from].isCmpd ? prin : amt, "ERC20: transfer amt exceeds bal");
        _balances[to  ] = _balances[to  ].add(accts[to  ].isCmpd ? prin : amt);
        emit Transfer(from, to, amt);
    }

    function _mint(address to, uint256 amt) internal virtual override {
        if (_cap > 0)   // When Capped
            require(totalSupply().add(amt) <= _cap, "ERC20Capped: cap exceeded");
		
        _beforeTokenTransfer(address(0), to, amt);

        _totalSupply = _totalSupply.add(amt);
        _balances[to] = _balances[to].add(accts[to].isCmpd ? prin4Bal(amt) : amt);
        emit Transfer(address(0), to, amt);
    }

    function _burn(address from, uint256 amt) internal virtual override {
        _beforeTokenTransfer(from, address(0), amt);
        require(unlockedOf(from) >= amt, "burn amt exceeds unlocked");

        _balances[from] = _balances[from].sub(accts[from].isCmpd ? prin4Bal(amt) : amt, "ERC20: burn amt exceeds balance");
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
        uint self = calcForce(twitters[0]);
        for(uint i=1; i<twitters.length; i++)
            if(_addrOfId[twitters[i].id] == address(0))
                amt = amt.add(calcForce(twitters[i]).mul(config[_factorMoreForce_]).div(1e18));
        amt = amt.add(self).mul(config[_factorAirClaim_]).mul(config[_factorQuota_]);
    }

    function moreQuotaOf(address who, Twitter[] memory twitters) public view returns(uint amt) {
        return quotaOf(who).add(calcQuota(twitters));
    }
    
    function setCmpd(bool isCmpd) public {
        address who = _msgSender();
        if(accts[who].isCmpd == isCmpd)
            return;
        
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
        accts[who].isCmpd = isCmpd;
    }
    event SetCmpd(address indexed sender, bool indexed isCmpd);

    function rebase() public {

    }
    
    modifier compound {
        setCmpd(true);
        rebase();
        _;
    } 

     function verify(address sender, bytes32 referrer, Twitter[] memory twitters, Signature[] memory signatures) public {
        require(twitters.length > 0, "missing twitters");
        require(getConfig(_disabled_) == 0, "disabled");
        require(signatures.length >= config[_minSignatures_], "too few signatures");
        for(uint i=0; i<signatures.length; i++) {
            for(uint j=0; j<i; j++)
                require(signatures[i].signatory != signatures[j].signatory, "repetitive signatory");
            bytes32 structHash = keccak256(abi.encode(VERIFY_TYPEHASH, sender, referrer, twitters, signatures[i].signatory));
            bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), structHash));
            address signatory = ecrecover(digest, signatures[i].v, signatures[i].r, signatures[i].s);
            require(signatory != address(0), "invalid signature");
            require(signatory == signatures[i].signatory && isSignatory[signatory], "unauthorized");
            emit Authorize(sender, twitters, signatures[i].signatory);
        }
    }
    event Authorize(address indexed sender, Twitter[] twitters, address indexed signatory);
    
    function _updateAcct(address acct, uint quota, uint locked, uint lockSpan, address referrer, bool isCmpd) internal {
        require(quota <= uint112(-1), "quota OVERFLOW");
        uint unlockEnd = Math.max(now, config[_unlockBegin_]).add(lockSpan);
        require(unlockEnd <= uint32(-1), "unlockEnd OVERFLOW");
        accts[acct] = Account(uint112(quota), uint112(locked), uint32(unlockEnd), referrer, isCmpd);
    }
    
    function airClaim(bytes32 referrer, Twitter[] memory twitters, Signature[] memory signatures) external payable {
        address sender = _msgSender();
        verify(sender, referrer, twitters, signatures);
        require(_addrOfId[twitters[0].id] == address(0) && unlockEndOf(sender) == 0, "airClaim already");
        _addrOfId[twitters[0].id] = sender;
        uint amt = calcAirClaim(twitters);
        uint quota = calcQuota(twitters).add(accts[sender].quota);
        _updateAcct(sender, quota, amt, config[_lockSpanAirClaim_], _addrOfId[referrer], true);
        _mint(sender, amt);
        emit AirClaim(sender, amt);

        if(msg.value > 0)
            _buy();

        rebase();
    }
    event AirClaim(address indexed sender, uint amt);

    function buyMore(bytes32 referrer, Twitter[] memory twitters, Signature[] memory signatures) external payable compound {
        verify(_msgSender(), referrer, twitters, signatures);
    }

    function buyMoreWithToken(address token, uint amt, bytes32 referrer, Twitter[] memory twitters, Signature[] memory signatures) external compound {
        verify(_msgSender(), referrer, twitters, signatures);

    }
    
    function buy() external payable compound {
        _buy();
    }

    function buyWithToken(address token, uint amt) external compound {

    }

    function _buy() internal {

    }

    function __buy() internal {

    }

    function claim() external compound {

    }

    function sell() external {

    }

    function sellForToken() external {

    }

}