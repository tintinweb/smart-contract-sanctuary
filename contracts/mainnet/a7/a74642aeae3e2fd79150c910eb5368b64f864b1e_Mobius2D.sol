pragma solidity^0.4.24;

/**
                        MOBIUS 2D
                     https://m2d.win 
                                       
    This game was inspired by FOMO3D. Our code is much cleaner and more efficient (built from scratch).
    Some useless "features" like the teams were not implemented.
 
    The Mobius2D game consists of rounds with guaranteed winners!
    You buy "shares" (instad of keys) for a given round, and you get returns from investors after you.
    The sare price is constant until the hard deadline, after which it increases exponentially. 
    If a round is inactive for a day it can end earlier than the hard deadline.
    If a round runs longer, it is guaranteed to finish not much after the hard deadline (and the last investor gets the big jackpot).
    Additionally, if you invest more than 0.1 ETH you get a chance to win an airdrop and you get bonus shares
    Part of all funds also go to a big final jackpot - the last investor (before a round runs out) wins.
    Payouts work in REAL TIME - you can withdraw your returns at any time!
    Additionally, the first round is an ICO, so you&#39;ll also get our tokens by participating!
    !!!!!!!!!!!!!!
    Token holders will receive part of current and future revenue of this and any other game we develop!
    !!!!!!!!!!!!!!
    
    .................................. LAUGHING MAN sssyyhddmN..........................................
    ..........................Nmdyyso+/:--.``` :`  `-`:--:/+ossyhdmN....................................
    ......................Ndhyso/:.`   --.     o.  /+`o::` `` `-:+osyh..................................
    ..................MNdyso/-` /-`/:+./:/..`  +.  //.o +.+::+ -`  `-/sshdN.............................
    ................Ndyso:` ` --:+`o//.-:-```  ...  ``` - /::::/ +..-` ./osh............................
    ..............Nhso/. .-.:/`o--:``   `..-:::oss+::--.``    .:/::/`+-`/../sydN........................
    ............mhso-``-:+./:-:.   .-/+osssssssssssssssssso+:-`  -//o::+:/` .:oyhN......................
    ..........Nhso:`  .+-./ `  .:+sssssso+//:-------:://+ossssso/---.`-`/:-o/ `:syd.....................
    ........Mdyo- +/../`-`  ./osssso/-.`                 ``.:+ossss+:`  `-+`  ` `/sy....................
    ......MNys/` -:-/:    -+ssss+-`                           `.:+ssss/.  `  -+-. .osh..................
    ......mys-  :-/+-`  :osss+-`                                  .:osss+.  `//o:- `/syN................
    ....Mdso. --:-/-  -osss+.                                       `-osss+`  :--://`-sy................
    ....dso-. ++:+  `/sss+.                                           `:osss:  `:.-+  -sy...............
    ..Mdso``+///.` .osss:                                               `/sss+`  :/-.. -syN.............
    ..mss` `+::/  .ssso.                                                  :sss+` `+:/+  -syN............
    ..ys-   ```  .ssso`                                                    -sss+` `:::+:`/sh............
    Mds+ `:/..  `osso`                                                      -sss+  -:`.` `ssN...........
    Mys. `/+::  +sss/........................................................+sss:.....-::+sy..NN.......
    ds+  :-/-  .ssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssyyhdN...
    hs: `/+::   :/+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ossssyhNM
    ss. `:::`                    ````                        ```                               ``-+sssyN
    ss` /:-+` `o++:           .:+oooo+/.                 `-/ooooo+-`                               -sssy
    ss  `:/:  `sss/          :ooo++/++os/`              .oso++/++oso.                               osss
    ss``/:--  `sss/         ./.`      `.::              /-.`     ``-/`                             -sssy
    ss.:::-:.  ssso         `            `                                                    ``.-+sssyN
    hs:`:/:/.  /sss.   .++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++oossssyhNM
    ds+ ``     .sss/   -ssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssyyyyhmN...
    Nss.:::::.  +sss.   +sss/........................................osss:...+sss:......../shmNNN.......
    Mds+..-:::` `osso`  `+sss:                                     `+sss:   -sss+  .:-.` `ssN...........
    ..ys- .+.::  .ssso`  `/sss+.                                  -osss:   -sss+` `:++-` /sh............
    ..mss` .-.    .ssso.   :osss/`                              .+ssso.   :sss+` `.:+:` -syN............
    ..Mdso`  `--:` .osss:   `/ssss/.`                        `-+ssso:`  `/sss+` `++.-. -syN.............
    ....dso` -//+-` `/sss+.   ./ossso/-``                `.:+sssso:`  `:osss:  .::+/. -sy...............
    ....Mdso. `-//-`  -osss+.   `-+ssssso+/:-.`````..-:/+osssso/.   `-osss+.` -///-  -sy................
    ......mys- `/://.`  :osss+-`   `-/+osssssssssssssssssso+:.    .:osss+.  .:`..-``/syN................
    ......MNys/` ..+-/:   -+ssss+-`    `.-://++oooo++/:-.`    `.:+ssss/.  .`      .osh..................
    ........Mdyo- `::/.  `  ./osssso/-.`                 ``.:+ossss+:` `  .//`  `/sy....................
    ..........Nhso-     :+:.`  .:+sssssso+//:--------://+ossssso/:.  `::/: --/.:syd.....................
    ............mhso-` ./+--+-:    .-/+osssssssssssssssssso+/-.  .+` `//-/ `::oyhN......................
    ..............Nhso/`   +/:--+.-`    `..-:::////::--.``    .`:/-o`  ./`./sydN........................
    ................Ndys+:` ``--+++-  .:  `.``      `` -.`/:/`.o./::.  ./osh............................
    ..................MNdyso/-` ` :`  +-  :+.o`s ::-/++`s`+/o.-:`  `-/sshdN.............................
    ......................Ndhyso/:.` .+   +/:/ +:/-./:-`+: `` `.:+osyh..................................
    ..........................Nmdyyso+/:--/.``      ``..-:/+ossyhdmN....................................
    ..............................MN..dhhyyssssssssssssyyhddmN..........................................
 */
 
contract DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
    function imin(int x, int y) internal pure returns (int z) {
        return x <= y ? x : y;
    }
    function imax(int x, int y) internal pure returns (int z) {
        return x >= y ? x : y;
    }

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

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
    //
    function rpow(uint x, uint n) internal pure returns (uint z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

contract DSAuthority {
    function canCall(
        address src, address dst, bytes4 sig
    ) public view returns (bool);
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

    function setOwner(address owner_)
        public
        auth
    {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_)
        public
        auth
    {
        authority = authority_;
        emit LogSetAuthority(authority);
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig));
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
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

interface MobiusToken {
    function mint(address _to, uint _amount) external;
    function finishMinting() external returns (bool);
    function disburseDividends() external payable;
}
 
contract Mobius2D is DSMath, DSAuth {
    // IPFS hash of the website - can be accessed even if our domain goes down.
    // Just go to any public IPFS gateway and use this hash - e.g. ipfs.infura.io/ipfs/<ipfsHash>
    string public ipfsHash;
    string public ipfsHashType = "ipfs"; // can either be ipfs, or ipns

    MobiusToken public token;

    // In case of an upgrade, these variables will be set. An upgrade does not affect a currently running round,
    // nor does it do anything with investors&#39; vaults.
    bool public upgraded;
    address public nextVersion;

    // Total stats
    uint public totalSharesSold;
    uint public totalEarningsGenerated;
    uint public totalDividendsPaid;
    uint public totalJackpotsWon;

    // Fractions for where revenue goes
    uint public constant DEV_FRACTION = WAD / 20;             // 5% goes to devs
    uint public constant DEV_DIVISOR = 20;             // 5% 

    uint public constant RETURNS_FRACTION = 65 * 10**16;      // 65% goes to share holders
    // 1% if it is a referral purchase, this value will be taken from the above fraction (e.g. if 1% is for refferals, then 64% goes to returns) 
    uint public constant REFERRAL_FRACTION = 1 * 10**16;  
    uint public constant JACKPOT_SEED_FRACTION = WAD / 20;    // 5% goes to the next round&#39;s jackpot
    uint public constant JACKPOT_FRACTION = 15 * 10**16;      // 15% goes to the final jackpot
    uint public constant AIRDROP_FRACTION = WAD / 100;        // 1% goes to airdrops
    uint public constant DIVIDENDS_FRACTION = 9 * 10**16;     // 9% goes to token holders!

    uint public constant STARTING_SHARE_PRICE = 1 finney; // a 1000th of an ETH
    uint public constant PRICE_INCREASE_PERIOD = 1 hours; // how often the price doubles after the hard deadline

    uint public constant HARD_DEADLINE_DURATION = 30 days; // hard deadline is this much after the round start
    uint public constant SOFT_DEADLINE_DURATION = 1 days; // max soft deadline
    uint public constant TIME_PER_SHARE = 5 minutes; // how much time is added to the soft deadline per share purchased
    
    uint public jackpotSeed;// Jackpot from previous rounds
    uint public devBalance; // outstanding balance for devs
    uint public raisedICO;

    // Helpers to calculate returns - no funds are ever held on lockdown
    uint public unclaimedReturns;
    uint public constant MULTIPLIER = RAY;

    // This represents an investor. No need to player IDs - they are useless (everyone already has a unique address).
    // Just use native mappings (duh!)
    struct Investor {
        uint lastCumulativeReturnsPoints;
        uint shares;
    }

    // This represents a round
    struct MobiusRound {
        uint totalInvested;        
        uint jackpot;
        uint airdropPot;
        uint totalShares;
        uint cumulativeReturnsPoints; // this is to help calculate returns when the total number of shares changes
        uint hardDeadline;
        uint softDeadline;
        uint price;
        uint lastPriceIncreaseTime;
        address lastInvestor;
        bool finalized;
        mapping (address => Investor) investors;
    }

    struct Vault {
        uint totalReturns; // Total balance = returns + referral returns + jackpots/airdrops 
        uint refReturns; // how much of the total is from referrals
    }

    mapping (address => Vault) vaults;

    uint public latestRoundID;// the first round has an ID of 0
    MobiusRound[] rounds;

    event SharesIssued(address indexed to, uint shares);
    event ReturnsWithdrawn(address indexed by, uint amount);
    event JackpotWon(address by, uint amount);
    event AirdropWon(address by, uint amount);
    event RoundStarted(uint indexed ID, uint hardDeadline);
    event IPFSHashSet(string _type, string _hash);

    constructor(address _token) public {
        token = MobiusToken(_token);
    }

    // The return values will include all vault balance, but you must specify a roundID because
    // Returns are not actually calculated in storage until you invest in the round or withdraw them
    function estimateReturns(address investor, uint roundID) public view 
    returns (uint totalReturns, uint refReturns) 
    {
        MobiusRound storage rnd = rounds[roundID];
        uint outstanding;
        if(rounds.length > 1) {
            if(hasReturns(investor, roundID - 1)) {
                MobiusRound storage prevRnd = rounds[roundID - 1];
                outstanding = _outstandingReturns(investor, prevRnd);
            }
        }

        outstanding += _outstandingReturns(investor, rnd);
        
        totalReturns = vaults[investor].totalReturns + outstanding;
        refReturns = vaults[investor].refReturns;
    }

    function hasReturns(address investor, uint roundID) public view returns (bool) {
        MobiusRound storage rnd = rounds[roundID];
        return rnd.cumulativeReturnsPoints > rnd.investors[investor].lastCumulativeReturnsPoints;
    }

    function investorInfo(address investor, uint roundID) external view
    returns(uint shares, uint totalReturns, uint referralReturns) 
    {
        MobiusRound storage rnd = rounds[roundID];
        shares = rnd.investors[investor].shares;
        (totalReturns, referralReturns) = estimateReturns(investor, roundID);
    }

    function roundInfo(uint roundID) external view 
    returns(
        address leader, 
        uint price,
        uint jackpot, 
        uint airdrop, 
        uint shares, 
        uint totalInvested,
        uint distributedReturns,
        uint _hardDeadline,
        uint _softDeadline,
        bool finalized
        )
    {
        MobiusRound storage rnd = rounds[roundID];
        leader = rnd.lastInvestor;
        price = rnd.price;
        jackpot = rnd.jackpot;
        airdrop = rnd.airdropPot;
        shares = rnd.totalShares;
        totalInvested = rnd.totalInvested;
        distributedReturns = wmul(rnd.totalInvested, RETURNS_FRACTION);
        _hardDeadline = rnd.hardDeadline;
        _softDeadline = rnd.softDeadline;
        finalized = rnd.finalized;
    }

    function totalsInfo() external view 
    returns(
        uint totalReturns,
        uint totalShares,
        uint totalDividends,
        uint totalJackpots
    ) {
        MobiusRound storage rnd = rounds[latestRoundID];
        if(rnd.softDeadline > now) {
            totalShares = totalSharesSold + rnd.totalShares;
            totalReturns = totalEarningsGenerated + wmul(rnd.totalInvested, RETURNS_FRACTION);
            totalDividends = totalDividendsPaid + wmul(rnd.totalInvested, DIVIDENDS_FRACTION);
        } else {
            totalShares = totalSharesSold;
            totalReturns = totalEarningsGenerated;
            totalDividends = totalDividendsPaid;
        }
        totalJackpots = totalJackpotsWon;
    }

    function () public payable {
        buyShares(address(0x0));
    }

    /// Function to buy shares in the latest round. Purchase logic is abstracted
    function buyShares(address ref) public payable {        
        if(rounds.length > 0) {
            MobiusRound storage rnd = rounds[latestRoundID];   
               
            _purchase(rnd, msg.value, ref);            
        } else {
            revert("Not yet started");
        }
    }

    /// Function to purchase with what you have in your vault as returns
    function reinvestReturns(uint value) public {        
        reinvestReturns(value, address(0x0));
    }

    function reinvestReturns(uint value, address ref) public {        
        MobiusRound storage rnd = rounds[latestRoundID];
        _updateReturns(msg.sender, rnd);        
        require(vaults[msg.sender].totalReturns >= value, "Can&#39;t spend what you don&#39;t have");        
        vaults[msg.sender].totalReturns = sub(vaults[msg.sender].totalReturns, value);
        vaults[msg.sender].refReturns = min(vaults[msg.sender].refReturns, vaults[msg.sender].totalReturns);
        unclaimedReturns = sub(unclaimedReturns, value);
        _purchase(rnd, value, ref);
    }

    function withdrawReturns() public {
        MobiusRound storage rnd = rounds[latestRoundID];

        if(rounds.length > 1) {// check if they also have returns from before
            if(hasReturns(msg.sender, latestRoundID - 1)) {
                MobiusRound storage prevRnd = rounds[latestRoundID - 1];
                _updateReturns(msg.sender, prevRnd);
            }
        }
        _updateReturns(msg.sender, rnd);
        uint amount = vaults[msg.sender].totalReturns;
        require(amount > 0, "Nothing to withdraw!");
        unclaimedReturns = sub(unclaimedReturns, amount);
        vaults[msg.sender].totalReturns = 0;
        vaults[msg.sender].refReturns = 0;
        
        rnd.investors[msg.sender].lastCumulativeReturnsPoints = rnd.cumulativeReturnsPoints;
        msg.sender.transfer(amount);

        emit ReturnsWithdrawn(msg.sender, amount);
    }

    // Manually update your returns for a given round in case you were inactive since before it ended
    function updateMyReturns(uint roundID) public {
        MobiusRound storage rnd = rounds[roundID];
        _updateReturns(msg.sender, rnd);
    }

    function finalizeAndRestart() public payable {
        finalizeLastRound();
        startNewRound();
    }

    /// Anyone can start a new round
    function startNewRound() public payable {
        require(!upgraded, "This contract has been upgraded!");
        if(rounds.length > 0) {
            require(rounds[latestRoundID].finalized, "Previous round not finalized");
            require(rounds[latestRoundID].softDeadline < now, "Previous round still running");
        }
        uint _rID = rounds.length++;
        MobiusRound storage rnd = rounds[_rID];
        latestRoundID = _rID;

        rnd.lastInvestor = msg.sender;
        rnd.price = STARTING_SHARE_PRICE;
        rnd.hardDeadline = now + HARD_DEADLINE_DURATION;
        rnd.softDeadline = now + SOFT_DEADLINE_DURATION;
        rnd.jackpot = jackpotSeed;
        jackpotSeed = 0; 

        _purchase(rnd, msg.value, address(0x0));
        emit RoundStarted(_rID, rnd.hardDeadline);
    }

    /// Anyone can finalize a finished round
    function finalizeLastRound() public {
        MobiusRound storage rnd = rounds[latestRoundID];
        _finalizeRound(rnd);
    }
    
    /// This is how devs pay the bills
    function withdrawDevShare() public auth {
        uint value = devBalance;
        devBalance = 0;
        msg.sender.transfer(value);
    }

    function setIPFSHash(string _type, string _hash) public auth {
        ipfsHashType = _type;
        ipfsHash = _hash;
        emit IPFSHashSet(_type, _hash);
    }

    function upgrade(address _nextVersion) public auth {
        require(_nextVersion != address(0x0), "Invalid Address!");
        require(!upgraded, "Already upgraded!");
        upgraded = true;
        nextVersion = _nextVersion;
        if(rounds[latestRoundID].finalized) {
            //if last round was finalized (and no new round was started), transfer the jackpot seed to the new version
            vaults[nextVersion].totalReturns = jackpotSeed;
            jackpotSeed = 0;
        }
    }

    /// Purchase logic
    function _purchase(MobiusRound storage rnd, uint value, address ref) internal {
        require(rnd.softDeadline >= now, "After deadline!");
        require(value >= rnd.price/10, "Not enough Ether!");
        rnd.totalInvested = add(rnd.totalInvested, value);

        // Set the last investor (to win the jackpot after the deadline)
        if(value >= rnd.price)
            rnd.lastInvestor = msg.sender;
        // Check out airdrop 
        _airDrop(rnd, value);
        // Process revenue in different "buckets"
        _splitRevenue(rnd, value, ref);
        // Update returns before issuing shares
        _updateReturns(msg.sender, rnd);
        //issue shares for the current round. 1 share = 1 time increase for the deadline
        uint newShares = _issueShares(rnd, msg.sender, value);

        //Mint tokens during the first round
        if(rounds.length == 1) {
            token.mint(msg.sender, newShares);
        }
        uint timeIncreases = newShares/WAD;// since 1 share is represented by 1 * 10^18, divide by 10^18
        // adjust soft deadline to new soft deadline
        uint newDeadline = add(rnd.softDeadline, mul(timeIncreases, TIME_PER_SHARE));
        rnd.softDeadline = min(newDeadline, now + SOFT_DEADLINE_DURATION);
        // If after hard deadline, double the price every price increase periods
        if(now > rnd.hardDeadline) {
            if(now > rnd.lastPriceIncreaseTime + PRICE_INCREASE_PERIOD) {
                rnd.price = rnd.price * 2;
                rnd.lastPriceIncreaseTime = now;
            }
        }
    }

    function _finalizeRound(MobiusRound storage rnd) internal {
        require(!rnd.finalized, "Already finalized!");
        require(rnd.softDeadline < now, "Round still running!");

        if(rounds.length == 1) {
            // After finishing minting tokens they will be transferable and dividends will be available!
            require(token.finishMinting(), "Couldn&#39;t finish minting tokens!");
        }
        // Transfer jackpot to winner&#39;s vault
        vaults[rnd.lastInvestor].totalReturns = add(vaults[rnd.lastInvestor].totalReturns, rnd.jackpot);
        unclaimedReturns = add(unclaimedReturns, rnd.jackpot);
        
        emit JackpotWon(rnd.lastInvestor, rnd.jackpot);
        totalJackpotsWon += rnd.jackpot;
        // transfer the leftover to the next round&#39;s jackpot
        jackpotSeed = add(jackpotSeed, wmul(rnd.totalInvested, JACKPOT_SEED_FRACTION));
        //Empty the AD pot if it has a balance.
        jackpotSeed = add(jackpotSeed, rnd.airdropPot);
        if(upgraded) {
            // if upgraded transfer the jackpot seed to the new version
            vaults[nextVersion].totalReturns = jackpotSeed;
            jackpotSeed = 0; 
        }        
        //Send out dividends to token holders
        uint _div;
        if(rounds.length == 1){
            // 2% during the first round, and the normal fraction otherwise
            _div = wmul(rnd.totalInvested, 2 * 10**16);            
        } else {
            _div = wmul(rnd.totalInvested, DIVIDENDS_FRACTION);            
        }
        token.disburseDividends.value(_div)();
        totalDividendsPaid += _div;
        totalSharesSold += rnd.totalShares;
        totalEarningsGenerated += wmul(rnd.totalInvested, RETURNS_FRACTION);

        rnd.finalized = true;
    }

    /** 
        This is where the magic happens: every investor gets an exact share of all returns proportional to their shares
        If you&#39;re early, you&#39;ll have a larger share for longer, so obviously you earn more.
    */
    function _updateReturns(address _investor, MobiusRound storage rnd) internal {
        if(rnd.investors[_investor].shares == 0) {
            return;
        }
        
        uint outstanding = _outstandingReturns(_investor, rnd);

        // if there are any returns, transfer them to the investor&#39;s vaults
        if (outstanding > 0) {
            vaults[_investor].totalReturns = add(vaults[_investor].totalReturns, outstanding);
        }

        rnd.investors[_investor].lastCumulativeReturnsPoints = rnd.cumulativeReturnsPoints;
    }

    function _outstandingReturns(address _investor, MobiusRound storage rnd) internal view returns(uint) {
        if(rnd.investors[_investor].shares == 0) {
            return 0;
        }
        // check if there&#39;ve been new returns
        uint newReturns = sub(
            rnd.cumulativeReturnsPoints, 
            rnd.investors[_investor].lastCumulativeReturnsPoints
            );

        uint outstanding = 0;
        if(newReturns != 0) { 
            // outstanding returns = (total new returns points * ivestor shares) / MULTIPLIER
            // The MULTIPLIER is used also at the point of returns disbursment
            outstanding = mul(newReturns, rnd.investors[_investor].shares) / MULTIPLIER;
        }

        return outstanding;
    }

    /// Process revenue according to fractions
    function _splitRevenue(MobiusRound storage rnd, uint value, address ref) internal {
        uint roundReturns;
        uint returnsOffset;
        if(rounds.length == 1){
            returnsOffset = 13 * 10**16;// during the first round reduce returns (by 13%) and give more to the ICO
        }
        if(ref != address(0x0)) {
            // if there was a referral
            roundReturns = wmul(value, RETURNS_FRACTION - REFERRAL_FRACTION - returnsOffset);
            uint _ref = wmul(value, REFERRAL_FRACTION);
            vaults[ref].totalReturns = add(vaults[ref].totalReturns, _ref);            
            vaults[ref].refReturns = add(vaults[ref].refReturns, _ref);
            unclaimedReturns = add(unclaimedReturns, _ref);
        } else {
            roundReturns = wmul(value, RETURNS_FRACTION - returnsOffset);
        }
        
        uint airdrop = wmul(value, AIRDROP_FRACTION);
        uint jackpot = wmul(value, JACKPOT_FRACTION);
        
        uint dev;
        // During the ICO, devs get 25% (5% originally, 7% from the dividends fraction, 
        // and 13% from the returns), leaving 2% for dividends, and 52% for returns 
        // This is only during the first round, and later rounds leave the original fractions:
        // 5% for devs, 9% dividends, 65% returns 
        if(rounds.length == 1){
            // calculate dividends at the end, no need to do it at every purchase
            dev = value / 4; // 25% 
            raisedICO += dev;
        } else {
            dev = value / DEV_DIVISOR;
        }
        // if this is the first purchase, send to jackpot (no one can claim these returns otherwise)
        if(rnd.totalShares == 0) {
            rnd.jackpot = add(rnd.jackpot, roundReturns);
        } else {
            _disburseReturns(rnd, roundReturns);
        }
        
        rnd.airdropPot = add(rnd.airdropPot, airdrop);
        rnd.jackpot = add(rnd.jackpot, jackpot);
        devBalance = add(devBalance, dev);
    }

    function _disburseReturns(MobiusRound storage rnd, uint value) internal {
        unclaimedReturns = add(unclaimedReturns, value);// keep track of unclaimed returns
        // The returns points represent returns*MULTIPLIER/totalShares (at the point of purchase)
        // This allows us to keep outstanding balances of shareholders when the total supply changes in real time
        if(rnd.totalShares == 0) {
            rnd.cumulativeReturnsPoints = mul(value, MULTIPLIER) / wdiv(value, rnd.price);
        } else {
            rnd.cumulativeReturnsPoints = add(
                rnd.cumulativeReturnsPoints, 
                mul(value, MULTIPLIER) / rnd.totalShares
            );
        }
    }

    function _issueShares(MobiusRound storage rnd, address _investor, uint value) internal returns(uint) {    
        if(rnd.investors[_investor].lastCumulativeReturnsPoints == 0) {
            rnd.investors[_investor].lastCumulativeReturnsPoints = rnd.cumulativeReturnsPoints;
        }    
        
        uint newShares = wdiv(value, rnd.price);
        
        //bonuses:
        if(value >= 100 ether) {
            newShares = mul(newShares, 2);//get double shares if you paid more than 100 ether
        } else if(value >= 10 ether) {
            newShares = add(newShares, newShares/2);//50% bonus
        } else if(value >= 1 ether) {
            newShares = add(newShares, newShares/3);//33% bonus
        } else if(value >= 100 finney) {
            newShares = add(newShares, newShares/10);//10% bonus
        }

        rnd.investors[_investor].shares = add(rnd.investors[_investor].shares, newShares);
        rnd.totalShares = add(rnd.totalShares, newShares);
        emit SharesIssued(_investor, newShares);
        return newShares;
    }    

    function _airDrop(MobiusRound storage rnd, uint value) internal {
        require(msg.sender == tx.origin, "ONLY HOOMANS (or scripts that don&#39;t use smart contracts)!");
        if(value > 100 finney) {
            /**
                Creates a random number from the last block hash and current timestamp.
                One could add more seemingly random data like the msg.sender, etc, but that doesn&#39;t 
                make it harder for a miner to manipulate the result in their favor (if they intended to).
             */
            uint chance = uint(keccak256(abi.encodePacked(blockhash(block.number - 1), now)));
            if(chance % 200 == 0) {// once in 200 times
                uint prize = rnd.airdropPot / 2;// win half of the pot, regardless of how much you paid
                rnd.airdropPot = rnd.airdropPot / 2;
                vaults[msg.sender].totalReturns = add(vaults[msg.sender].totalReturns, prize);
                unclaimedReturns = add(unclaimedReturns, prize);
                totalJackpotsWon += prize;
                emit AirdropWon(msg.sender, prize);
            }
        }
    }
}