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

    /*
    function assert(bool x) internal {
        if (!x) throw;
    }
    */
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
        
        emit Transfer(msg.sender, dst, wad);
        
        return true;
    }
    
    function transferFrom(address src, address dst, uint wad) public returns (bool) {
        assert(_balances[src] >= wad);
        assert(_approvals[src][msg.sender] >= wad);
        
        _approvals[src][msg.sender] = sub(_approvals[src][msg.sender], wad);
        _balances[src] = sub(_balances[src], wad);
        _balances[dst] = add(_balances[dst], wad);
        
        emit Transfer(src, dst, wad);
        
        return true;
    }
    
    function approve(address guy, uint256 wad) public returns (bool) {
        _approvals[msg.sender][guy] = wad;
        
        emit Approval(msg.sender, guy, wad);
        
        return true;
    }
}

contract DSToken is DSTokenBase(0), DSStop {

    string public  name = "ERC20 token CES";
    string public  symbol = "CES"; //token name
    uint8  public  decimals = 18; // standard token precision.

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
}


contract Crowdsale is DSAuth, DSMath {
    
    struct accountInfo {
        // The account name used at CES block chain ecocsystem
        string accountName;
        // The public key used for account
        string publicKey;
    }
    
    DSToken public CES;

    uint128 public  totalIssue;  // token total issue 
    uint128 public  totalSell;   // token total sell 
    uint public onePieceOfToken; // how much token of one piece
    uint public pieceSupply;     // how much piece of the sell token
    uint public pieceSell;       // how much piece was sold
    uint public amountRaised;    // how much ETH was got by crowdsale
    uint public price;           // how much ETH of one piece
    uint public deadline;        // only sell one year
    
    bool fundingGoalReached = false;
    bool crowdsaleClosed = false;

    mapping (address => uint256) public balanceContributor;
    mapping (address => accountInfo) public accountInfos;
    

    event GoalReached(address recipient, uint totalPieceSell);
    event FundTransfer(address backer, uint amount, bool isContribution);
    event LogRegister (address user, string account, string key);

    constructor () public {
        totalIssue  = 200000000000000000000000000; // 200 million token
        totalSell   =  15000000000000000000000000; //  15 million token
        amountRaised = 0;
        onePieceOfToken = 1000;
        pieceSupply = hdiv(totalSell, 1E18) / onePieceOfToken;
        price = 0.000000000001 * 1 ether;
        deadline = now + 365 * 24 * 60 * 1 minutes;
    }
    
    function initialize(DSToken tokenReward) public auth {
        emit LogRegister(0x00, "root", "A");
        assert(address(CES) == address(0));
        emit LogRegister(0x00, "root", "AA");
        assert(tokenReward.owner() == address(this));
        emit LogRegister(0x00, "root", "AAA");
        assert(tokenReward.authority() == DSAuthority(0));
        emit LogRegister(0x00, "root", "AAAA");
        assert(tokenReward.totalSupply() == 0);
        emit LogRegister(0x00, "root", "AAAAA");

        CES = tokenReward;
        CES.mint(totalIssue);
        emit LogRegister(0x00, "root", "B");
        CES.push(0x00, hsub(totalIssue, totalSell));
        accountInfos[0x00].accountName = "root";
        accountInfos[0x00].publicKey = "AAAAA";
        emit LogRegister(0x00, "root", "AAAAA");
    }

    
    modifier afterDeadline() { if (now >= deadline) _; }

    /**
     * Fallback function
     *
     * The function without name is the default function that is called 
     * whenever anyone sends funds to a contract
     */
    function () payable public afterDeadline {
        require(!crowdsaleClosed);
        require(pieceSell < pieceSupply);
        
        uint amount = msg.value;
        balanceContributor[msg.sender] += amount;
        amountRaised += amount;
        CES.transfer(msg.sender, (amount / price) * onePieceOfToken);
        emit FundTransfer(msg.sender, amount, true);
    }

    /**
     * Check if goal was reached
     *
     * Checks if the goal or time limit has been reached and ends the campaign
     */
    function checkGoalReached() public afterDeadline {
        if (pieceSell >= 1000){
            fundingGoalReached = true;
            emit GoalReached(msg.sender, pieceSell);
        }
    }


    /**
     * claim the funds
     *
     * Checks to see if goal or time limit has been reached, 
     * If goal was not reached, each contributor can withdraw
     * the amount they contributed.
     */
    function claim() public afterDeadline {
        if (!fundingGoalReached) {
            uint amount = balanceContributor[msg.sender];
            balanceContributor[msg.sender] = 0;
            if (amount > 0) {
                if (msg.sender.send(amount)) {
                   emit FundTransfer(msg.sender, amount, false);
                } else {
                    balanceContributor[msg.sender] = amount;
                }
            }
        }
    }
    
    function safeWithdrawal() public auth {
        if (fundingGoalReached) {
            if (msg.sender.send(amountRaised)) {
               emit FundTransfer(msg.sender, amountRaised, false);
            }
        }
    }
    
    function crowdClosed() public auth {
        crowdsaleClosed = true;
        CES.stop();
    }
    
    function cancel() public auth {
        fundingGoalReached = false;
        crowdClosed();
    }
    
    // Account name and the public key. Set this later after test network come in
    function register(string account, string key) public {
        require(fundingGoalReached);
        assert(bytes(account).length <= 10);
        assert(bytes(key).length <= 128); //maybe public key is 64 bytes

        uint amount = balanceContributor[msg.sender];
        if(amount > 0)
        {
            accountInfos[msg.sender].accountName = account;
            accountInfos[msg.sender].publicKey = key;
    
            emit LogRegister(msg.sender, account, key);
        }
    }
}