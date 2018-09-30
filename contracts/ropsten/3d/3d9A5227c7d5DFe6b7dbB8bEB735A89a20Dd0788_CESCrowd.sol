pragma solidity ^0.4.18;

contract DSNote {
    event LogNote(
        bytes4   indexed  sig,
        address  indexed  guy,
        bytes32  indexed  foo,
        bytes32  indexed  bar,
        uint              wad,
        bytes             fax
    ) anonymous;

    modifier note {
        bytes32 foo;
        bytes32 bar;

        assembly {
            foo := calldataload(4)
            bar := calldataload(36)
        }

        emit LogNote(msg.sig, msg.sender, foo, bar, msg.value, msg.data);

        _;
    }
}

contract DSAuthority {
    function canCall(
        address src, address dst, bytes4 sig
    ) constant public returns (bool);
}

contract DSAuthEvents {
    event LogSetAuthority (address indexed authority);
    event LogSetOwner     (address indexed owner);
}

contract DSAuth is DSAuthEvents {
    DSAuthority  public  authority;
    address      public  owner;

    constructor() public {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

    function setOwner(address owner_) public
        auth
    {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_) public
        auth
    {
        authority = authority_;
        emit LogSetAuthority(authority);
    }

    modifier auth {
        assert(isAuthorized(msg.sender, msg.sig));
        _;
    }

    modifier authorized(bytes4 sig) {
        assert(isAuthorized(msg.sender, sig));
        _;
    }

    function isAuthorized(address src, bytes4 sig) view internal returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == DSAuthority(0)) {
            return false;
        } else {
            return authority.canCall(src, this, sig);
        }
    }
}

contract DSStop is DSAuth, DSNote {

    bool public stopped;

    modifier stoppable {
        assert (!stopped);
        _;
    }
    
    function stop() public auth note {
        stopped = true;
    }
    
    function start() public auth note {
        stopped = false;
    }

}

contract DSMath {
    
    /*
    standard uint256 functions
     */

    function add(uint256 x, uint256 y) pure internal returns (uint256 z) {
        assert((z = x + y) >= x);
    }

    function sub(uint256 x, uint256 y) pure internal returns (uint256 z) {
        assert((z = x - y) <= x);
    }

    function mul(uint256 x, uint256 y) pure internal returns (uint256 z) {
        assert((z = x * y) >= x);
    }

    function div(uint256 x, uint256 y) pure internal returns (uint256 z) {
        z = x / y;
    }

    function min(uint256 x, uint256 y) pure internal returns (uint256 z) {
        return x <= y ? x : y;
    }
    
    function max(uint256 x, uint256 y) pure internal returns (uint256 z) {
        return x >= y ? x : y;
    }
    

    /*
    uint128 functions (h is for half)
     */

    function hadd(uint128 x, uint128 y) pure internal returns (uint128 z) {
        assert((z = x + y) >= x);
    }

    function hsub(uint128 x, uint128 y) pure internal returns (uint128 z) {
        assert((z = x - y) <= x);
    }

    function hmul(uint128 x, uint128 y) pure internal returns (uint128 z) {
        assert((z = x * y) >= x);
    }

    function hdiv(uint128 x, uint128 y) pure internal returns (uint128 z) {
        z = x / y;
    }

    function hmin(uint128 x, uint128 y) pure internal returns (uint128 z) {
        return x <= y ? x : y;
    }
    
    function hmax(uint128 x, uint128 y) pure internal returns (uint128 z) {
        return x >= y ? x : y;
    }


    /*
    int256 functions
     */

    function imin(int256 x, int256 y) pure internal returns (int256 z) {
        return x <= y ? x : y;
    }
    
    function imax(int256 x, int256 y) pure internal returns (int256 z) {
        return x >= y ? x : y;
    }

    /*
    WAD math
     */

    uint128 constant WAD = 10 ** 18;

    function wadd(uint128 x, uint128 y) pure internal returns (uint128) {
        return hadd(x, y);
    }

    function wsub(uint128 x, uint128 y) pure internal returns (uint128) {
        return hsub(x, y);
    }

    function wmul(uint128 x, uint128 y) pure internal returns (uint128 z) {
        z = cast((uint256(x) * y + WAD / 2) / WAD);
    }

    function wdiv(uint128 x, uint128 y) pure internal returns (uint128 z) {
        z = cast((uint256(x) * WAD + y / 2) / y);
    }

    function wmin(uint128 x, uint128 y) pure internal returns (uint128) {
        return hmin(x, y);
    }
    
    function wmax(uint128 x, uint128 y) pure internal returns (uint128) {
        return hmax(x, y);
    }

    /*
    RAY math
     */

    uint128 constant RAY = 10 ** 27;

    function radd(uint128 x, uint128 y) pure internal returns (uint128) {
        return hadd(x, y);
    }

    function rsub(uint128 x, uint128 y) pure internal returns (uint128) {
        return hsub(x, y);
    }

    function rmul(uint128 x, uint128 y) pure internal returns (uint128 z) {
        z = cast((uint256(x) * y + RAY / 2) / RAY);
    }

    function rdiv(uint128 x, uint128 y) pure internal returns (uint128 z) {
        z = cast((uint256(x) * RAY + y / 2) / y);
    }

    function rpow(uint128 x, uint64 n) pure internal returns (uint128 z) {
        // This famous algorithm is called "exponentiation by squaring"
        // and calculates x^n with x as fixed-point and n as regular unsigned.
        //
        // It&#39;s O(log n), instead of O(n) for naive repeated multiplication.
        //
        // These facts are why it works:
        //
        //  If n is even, then x^n = (x^2)^(n/2).
        //  If n is odd,  then x^n = x * x^(n-1),
        //   and applying the equation for even x gives
        //    x^n = x * (x^2)^((n-1) / 2).
        //
        //  Also, EVM division is flooring and
        //    floor[(n-1) / 2] = floor[n / 2].

        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }

    function rmin(uint128 x, uint128 y) pure internal returns (uint128) {
        return hmin(x, y);
    }
    
    function rmax(uint128 x, uint128 y) pure internal returns (uint128) {
        return hmax(x, y);
    }

    function cast(uint256 x) pure internal returns (uint128 z) {
        assert((z = uint128(x)) == x);
    }

}

contract ERC20 {
    function totalSupply() constant public returns (uint supply);
    function balanceOf( address who ) constant public returns (uint value);
    function allowance( address owner, address spender ) constant public returns (uint _allowance);

    function transfer( address to, uint value) public returns (bool ok);
    function transferFrom( address from, address to, uint value) public returns (bool ok);
    function approve( address spender, uint value ) public returns (bool ok);

    event Transfer( address indexed from, address indexed to, uint value);
    event Approval( address indexed owner, address indexed spender, uint value);
}

contract DSTokenBase is ERC20, DSMath {
    uint256                                            _supply;
    mapping (address => uint256)                       _balances;
    mapping (address => mapping (address => uint256))  _approvals;
    
    address[] _addrLists;
    
    constructor(uint256 supply) public {
        _balances[msg.sender] = supply;
        _supply = supply;
    }
    
    function totalSupply() public constant returns (uint256) {
        return _supply;
    }
    
    function balanceOf(address src) public constant returns (uint256) {
        return _balances[src];
    }
    
    function allowance(address src, address guy) public constant returns (uint256) {
        return _approvals[src][guy];
    }
    
    function transfer(address dst, uint wad) public returns (bool) {
        assert(_balances[msg.sender] >= wad);
        
        _balances[msg.sender] = sub(_balances[msg.sender], wad);
        _balances[dst] = add(_balances[dst], wad);
        
        pushAddr(dst);
        
        emit Transfer(msg.sender, dst, wad);
        
        return true;
    }
    
    function transferFrom(address src, address dst, uint wad) public returns (bool) {
        assert(_balances[src] >= wad);
        assert(_approvals[src][msg.sender] >= wad);
        
        _approvals[src][msg.sender] = sub(_approvals[src][msg.sender], wad);
        _balances[src] = sub(_balances[src], wad);
        _balances[dst] = add(_balances[dst], wad);
        
        pushAddr(dst);
        
        emit Transfer(src, dst, wad);
        
        return true;
    }
    
    function approve(address guy, uint256 wad) public returns (bool) {
        _approvals[msg.sender][guy] = wad;
        
        emit Approval(msg.sender, guy, wad);
        
        return true;
    }
    
    function pushAddr(address dst) internal {

        bool bExist = false;
        address addr;
        for(uint i = 0; i < _addrLists.length; i++){
            addr = _addrLists[i];
            
            if(address(addr) == address(dst)){
                bExist = true;
                break;
            }
        }
        
        if(!bExist)
        {
            _addrLists.push(dst);
        }
    }
}

contract DSToken is DSTokenBase(0), DSStop {

    string public name = "ERC20 CES token";
    string public symbol = "CES"; //token name
    uint8  public decimals = 0; // standard token precision.
    
    struct accountInfo {
        // Mark the address whether was got InitAccount
        bool bInitAccount;
        // The account name used at CES block chain ecocsystem
        string accountName;
        // The public key used for your account
        string publicKey;
        // The pinblock used for your account calc by your password
        string pinblock;
    }
    
    mapping (address => accountInfo) public accountInfos;
    
    event LogRegister (address user, string account, string key, string pin);
    

    function transfer(address dst, uint wad) public stoppable note returns (bool) {
        return super.transfer(dst, wad);
    }
    
    function transferFrom (address src, address dst, uint wad) 
        public stoppable note returns (bool) {
        return super.transferFrom(src, dst, wad);
    }
    
    function approve(address guy, uint wad) public stoppable note returns (bool) {
        return super.approve(guy, wad);
    }

    function push(address dst, uint128 wad) public returns (bool) {
        return transfer(dst, wad);
    }
    
    function pull(address src, uint128 wad) public returns (bool) {
        return transferFrom(src, msg.sender, wad);
    }

    function mint(uint128 wad) public auth stoppable note {
        _balances[msg.sender] = add(_balances[msg.sender], wad);
        _supply = add(_supply, wad);
    }

    function burn(uint128 wad) public auth stoppable note {
        _balances[msg.sender] = sub(_balances[msg.sender], wad);
        _supply = sub(_supply, wad);
    }
    
    /**
     * makeInitAccount function
     *
     * if you had 1000 token, you can get the initialize account at the check point
     * this function only call once
     */
    function makeInitAccount() public auth {

        address addr;
        for(uint i = 0; i < _addrLists.length; i++){
            addr = _addrLists[i];
            
            if(address(addr) == address(0)){
                continue;
            }
            
            if(_balances[addr] >= 1000) // more than 1000 token
            {
                accountInfos[addr].bInitAccount = true;
            }
        }
    }
    
    // Do this after we provide tool for produce public key and encrypt your password
    function register(string account, string publicKey, string pin) public {
            
        registerA(account, publicKey, pin, msg.sender);
    }
    
    function registerA(string account, string publicKey, string pin, address src)
        internal {

        assert(bytes(account).length <= 10 && bytes(account).length >= 2);
        assert(bytes(publicKey).length <= 128); //maybe public key is 64 bytes
        assert(bytes(pin).length == 16 || bytes(pin).length == 32);

        if(accountInfos[src].bInitAccount)
        {
            accountInfos[src].accountName = account;
            accountInfos[src].publicKey = publicKey;
            accountInfos[src].pinblock = pin;
    
            emit LogRegister(src, account, publicKey, pin);
        }
    }
}


contract CESCrowd is DSAuth, DSMath {
    
    DSToken public CES;
    
    uint128 public pieceOfToken;    // how many tokens of one piece
    uint128 public pieceSupply;     // total pieces of the all sell token
    uint128 public pieceSold;       // how many pieces was sold
    uint128 public pieceGoalReached;// how many pieces must to be sold
    
    uint public priceOfPiece;    // one piece cost ETH
    uint public gotETH;          // how much ETH was got by crowdsale
    uint public deadline;        // only sell one year
    
    bool public crowdsaleClosed = false;
    
    bool fundingGoalReached = false;
    

    mapping (address => uint256) public ethContributor;
    
    event GoalReached(address recipient, uint128 piece);
    event FundTransfer(address backer, uint amount, bool isContribution);
    
    modifier afterDeadline()  { require (now >= deadline); _; }
    modifier beforeDeadline() { require (now <  deadline); _; }

    constructor () public {

        pieceOfToken = 1000;
        pieceGoalReached = 2000; // 10% of total supply

        priceOfPiece = 0.0001 * 1 ether;

        deadline = now + 365 * 24 * 60 * 1 minutes;
    }
    
    function initialize(DSToken tokenReward) public auth {
        assert(address(CES) == address(0));
        assert(tokenReward.owner() == address(this));
        assert(tokenReward.authority() == DSAuthority(0));
        assert(tokenReward.totalSupply() == 0);

        CES = tokenReward;
        
        uint128 totalIssue = 210000000; // 210 million token, total issue 
        uint128 totalSell  =  20000000; //  20 million token, total sell
        
        pieceSupply = hdiv(totalSell, pieceOfToken);

        CES.mint(totalIssue);
        CES.push(msg.sender, hsub(totalIssue, totalSell));
    }

    /**
     * Fallback function
     *
     * The function without name is the default function that is called 
     * whenever anyone sends funds to a contract
     */
    function () public payable beforeDeadline {
        require(!crowdsaleClosed);
        require(pieceSold < pieceSupply);
        require(msg.value >= priceOfPiece); // warning : the best is multiple of priceOfPiece
        
        uint money = msg.value;
        ethContributor[msg.sender] = add(ethContributor[msg.sender], money);
        gotETH = add(gotETH, money);
        
        // warning : multiple of piece, remainder is lost
        uint piece = div(money, priceOfPiece);
        pieceSold = hadd(pieceSold, cast(piece));
        
        CES.transfer(msg.sender, mul(piece, pieceOfToken));
        emit FundTransfer(msg.sender, money, true);
    }
    
    /**
     * claim the funds
     *
     * Checks to see if goal or time limit has been reached, 
     * If goal was not reached, each contributor can withdraw
     * the amount they contributed.
     */
    function claim() external afterDeadline {
        require(!fundingGoalReached);
        
        uint amount = ethContributor[msg.sender];
        if (amount > 0) {
            ethContributor[msg.sender] = 0;
            if (msg.sender.send(amount)) {
                emit FundTransfer(msg.sender, amount, false);
            }
            else {
                ethContributor[msg.sender] = amount;
            }
        }
    }

    /**
     * Check if goal was reached
     */
    function checkGoalReached() public beforeDeadline {
        require(!fundingGoalReached);
        
        if (pieceSold >= pieceGoalReached){
            fundingGoalReached = true;
            emit GoalReached(msg.sender, pieceSold);
        }
    }
    
    function withdrawal() external auth {
        
        uint takeNow = address(this).balance;
        if (fundingGoalReached) {
            if (msg.sender.send(takeNow)) {
                emit FundTransfer(msg.sender, takeNow, false);
            }
        }
    }
    
    function crowdClosed() external auth {
        crowdsaleClosed = true;
        CES.stop();
    }
    
    // We will specified when to do this and provide tool to register
    function makeInitAccount() external auth {
        require(fundingGoalReached);
        
        CES.makeInitAccount();
    }
    
    /*
    function register(string account, string publicKey, string pin) external {
            
        CES.registerA(account, publicKey, pin, msg.sender);
    }
    */
    
    /*
    function setPrice(uint price) external auth beforeDeadline {
        priceOfPiece = price;
    }
    */
}