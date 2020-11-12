/*
B.PROTOCOL TERMS OF USE
=======================

THE TERMS OF USE CONTAINED HEREIN (THESE “TERMS”) GOVERN YOUR USE OF B.PROTOCOL, WHICH IS A DECENTRALIZED PROTOCOL ON THE ETHEREUM BLOCKCHAIN (the “PROTOCOL”) THAT enables a backstop liquidity mechanism FOR DECENTRALIZED LENDING PLATFORMS (“DLPs”).  
PLEASE READ THESE TERMS CAREFULLY AT https://github.com/backstop-protocol/Terms-and-Conditions, INCLUDING ALL DISCLAIMERS AND RISK FACTORS, BEFORE USING THE PROTOCOL. BY USING THE PROTOCOL, YOU ARE IRREVOCABLY CONSENTING TO BE BOUND BY THESE TERMS. 
IF YOU DO NOT AGREE TO ALL OF THESE TERMS, DO NOT USE THE PROTOCOL. YOUR RIGHT TO USE THE PROTOCOL IS SUBJECT AND DEPENDENT BY YOUR AGREEMENT TO ALL TERMS AND CONDITIONS SET FORTH HEREIN, WHICH AGREEMENT SHALL BE EVIDENCED BY YOUR USE OF THE PROTOCOL.
Minors Prohibited: The Protocol is not directed to individuals under the age of eighteen (18) or the age of majority in your jurisdiction if the age of majority is greater. If you are under the age of eighteen or the age of majority (if greater), you are not authorized to access or use the Protocol. By using the Protocol, you represent and warrant that you are above such age.

License; No Warranties; Limitation of Liability;
(a) The software underlying the Protocol is licensed for use in accordance with the 3-clause BSD License, which can be accessed here: https://opensource.org/licenses/BSD-3-Clause.
(b) THE PROTOCOL IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS", “WITH ALL FAULTS” and “AS AVAILABLE” AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
(c) IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 
*/


pragma solidity ^0.5.12;


contract Math {
    // --- Math ---
    function add(uint x, int y) internal pure returns (uint z) {
        z = x + uint(y);
        require(y >= 0 || z <= x);
        require(y <= 0 || z >= x);
    }
    function sub(uint x, int y) internal pure returns (uint z) {
        z = x - uint(y);
        require(y <= 0 || z <= x);
        require(y >= 0 || z >= x);
    }
    function mul(uint x, int y) internal pure returns (int z) {
        z = int(x) * y;
        require(int(x) >= 0);
        require(y == 0 || z / y == int(x));
    }
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    uint constant RAY = 10 ** 27;

    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = mul(x, RAY) / y;
    }
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = mul(x, y) / RAY;
    }
    function rpow(uint x, uint n, uint b) internal pure returns (uint z) {
      assembly {
        switch x case 0 {switch n case 0 {z := b} default {z := 0}}
        default {
          switch mod(n, 2) case 0 { z := b } default { z := x }
          let half := div(b, 2)  // for rounding.
          for { n := div(n, 2) } n { n := div(n,2) } {
            let xx := mul(x, x)
            if iszero(eq(div(xx, x), x)) { revert(0,0) }
            let xxRound := add(xx, half)
            if lt(xxRound, xx) { revert(0,0) }
            x := div(xxRound, b)
            if mod(n,2) {
              let zx := mul(z, x)
              if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
              let zxRound := add(zx, half)
              if lt(zxRound, zx) { revert(0,0) }
              z := div(zxRound, b)
            }
          }
        }
      }
    }

    function toInt(uint x) internal pure returns (int y) {
        y = int(x);
        require(y >= 0);
    }
}


contract LibNote {
    event LogNote(
        bytes4   indexed  sig,
        address  indexed  usr,
        bytes32  indexed  arg1,
        bytes32  indexed  arg2,
        bytes             data
    ) anonymous;

    modifier note {
        _;
        assembly {
            // log an 'anonymous' event with a constant 6 words of calldata
            // and four indexed topics: selector, caller, arg1 and arg2
            let mark := msize()                       // end of memory ensures zero
            mstore(0x40, add(mark, 288))              // update free memory pointer
            mstore(mark, 0x20)                        // bytes type data offset
            mstore(add(mark, 0x20), 224)              // bytes size (padded)
            calldatacopy(add(mark, 0x40), 0, 224)     // bytes payload
            log4(mark, 288,                           // calldata
                 shl(224, shr(224, calldataload(0))), // msg.sig
                 caller(),                            // msg.sender
                 calldataload(4),                     // arg1
                 calldataload(36)                     // arg2
                )
        }
    }
}

contract BCdpScoreLike {
    function updateScore(uint cdp, bytes32 ilk, int dink, int dart, uint time) external;
}

contract BCdpScoreConnector {
    BCdpScoreLike public score;
    mapping(uint => uint) public left;

    constructor(BCdpScoreLike score_) public {
        score = score_;
    }

    function setScore(BCdpScoreLike bcdpScore) internal {
        score = bcdpScore;
    }

    function updateScore(uint cdp, bytes32 ilk, int dink, int dart, uint time) internal {
        if(left[cdp] == 0) score.updateScore(cdp, ilk, dink, dart, time);
    }

    function quitScore(uint cdp) internal {
        if(left[cdp] == 0) left[cdp] = now;
    }
}



contract UrnHandler {
    constructor(address vat) public {
        VatLike(vat).hope(msg.sender);
    }
}

contract DssCdpManager is LibNote {
    address                   public vat;
    uint                      public cdpi;      // Auto incremental
    mapping (uint => address) public urns;      // CDPId => UrnHandler
    mapping (uint => List)    public list;      // CDPId => Prev & Next CDPIds (double linked list)
    mapping (uint => address) public owns;      // CDPId => Owner
    mapping (uint => bytes32) public ilks;      // CDPId => Ilk

    mapping (address => uint) public first;     // Owner => First CDPId
    mapping (address => uint) public last;      // Owner => Last CDPId
    mapping (address => uint) public count;     // Owner => Amount of CDPs

    mapping (
        address => mapping (
            uint => mapping (
                address => uint
            )
        )
    ) public cdpCan;                            // Owner => CDPId => Allowed Addr => True/False

    mapping (
        address => mapping (
            address => uint
        )
    ) public urnCan;                            // Urn => Allowed Addr => True/False

    struct List {
        uint prev;
        uint next;
    }

    event NewCdp(address indexed usr, address indexed own, uint indexed cdp);

    modifier cdpAllowed(
        uint cdp
    ) {
        require(msg.sender == owns[cdp] || cdpCan[owns[cdp]][cdp][msg.sender] == 1, "cdp-not-allowed");
        _;
    }

    modifier urnAllowed(
        address urn
    ) {
        require(msg.sender == urn || urnCan[urn][msg.sender] == 1, "urn-not-allowed");
        _;
    }

    constructor(address vat_) public {
        vat = vat_;
    }

    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }

    function toInt(uint x) internal pure returns (int y) {
        y = int(x);
        require(y >= 0);
    }

    // Allow/disallow a usr address to manage the cdp.
    function cdpAllow(
        uint cdp,
        address usr,
        uint ok
    ) public cdpAllowed(cdp) {
        cdpCan[owns[cdp]][cdp][usr] = ok;
    }

    // Allow/disallow a usr address to quit to the the sender urn.
    function urnAllow(
        address usr,
        uint ok
    ) public {
        urnCan[msg.sender][usr] = ok;
    }

    // Open a new cdp for a given usr address.
    function open(
        bytes32 ilk,
        address usr
    ) public note returns (uint) {
        require(usr != address(0), "usr-address-0");

        cdpi = add(cdpi, 1);
        urns[cdpi] = address(new UrnHandler(vat));
        owns[cdpi] = usr;
        ilks[cdpi] = ilk;

        // Add new CDP to double linked list and pointers
        if (first[usr] == 0) {
            first[usr] = cdpi;
        }
        if (last[usr] != 0) {
            list[cdpi].prev = last[usr];
            list[last[usr]].next = cdpi;
        }
        last[usr] = cdpi;
        count[usr] = add(count[usr], 1);

        emit NewCdp(msg.sender, usr, cdpi);
        return cdpi;
    }

    // Give the cdp ownership to a dst address.
    function give(
        uint cdp,
        address dst
    ) public note cdpAllowed(cdp) {
        require(dst != address(0), "dst-address-0");
        require(dst != owns[cdp], "dst-already-owner");

        // Remove transferred CDP from double linked list of origin user and pointers
        if (list[cdp].prev != 0) {
            list[list[cdp].prev].next = list[cdp].next;         // Set the next pointer of the prev cdp (if exists) to the next of the transferred one
        }
        if (list[cdp].next != 0) {                              // If wasn't the last one
            list[list[cdp].next].prev = list[cdp].prev;         // Set the prev pointer of the next cdp to the prev of the transferred one
        } else {                                                // If was the last one
            last[owns[cdp]] = list[cdp].prev;                   // Update last pointer of the owner
        }
        if (first[owns[cdp]] == cdp) {                          // If was the first one
            first[owns[cdp]] = list[cdp].next;                  // Update first pointer of the owner
        }
        count[owns[cdp]] = sub(count[owns[cdp]], 1);

        // Transfer ownership
        owns[cdp] = dst;

        // Add transferred CDP to double linked list of destiny user and pointers
        list[cdp].prev = last[dst];
        list[cdp].next = 0;
        if (last[dst] != 0) {
            list[last[dst]].next = cdp;
        }
        if (first[dst] == 0) {
            first[dst] = cdp;
        }
        last[dst] = cdp;
        count[dst] = add(count[dst], 1);
    }

    // Frob the cdp keeping the generated DAI or collateral freed in the cdp urn address.
    function frob(
        uint cdp,
        int dink,
        int dart
    ) public note cdpAllowed(cdp) {
        address urn = urns[cdp];
        VatLike(vat).frob(
            ilks[cdp],
            urn,
            urn,
            urn,
            dink,
            dart
        );
    }

    // Transfer wad amount of cdp collateral from the cdp address to a dst address.
    function flux(
        uint cdp,
        address dst,
        uint wad
    ) public note cdpAllowed(cdp) {
        VatLike(vat).flux(ilks[cdp], urns[cdp], dst, wad);
    }

    // Transfer wad amount of any type of collateral (ilk) from the cdp address to a dst address.
    // This function has the purpose to take away collateral from the system that doesn't correspond to the cdp but was sent there wrongly.
    function flux(
        bytes32 ilk,
        uint cdp,
        address dst,
        uint wad
    ) public note cdpAllowed(cdp) {
        VatLike(vat).flux(ilk, urns[cdp], dst, wad);
    }

    // Transfer wad amount of DAI from the cdp address to a dst address.
    function move(
        uint cdp,
        address dst,
        uint rad
    ) public note cdpAllowed(cdp) {
        VatLike(vat).move(urns[cdp], dst, rad);
    }

    // Quit the system, migrating the cdp (ink, art) to a different dst urn
    function quit(
        uint cdp,
        address dst
    ) public note cdpAllowed(cdp) urnAllowed(dst) {
        (uint ink, uint art) = VatLike(vat).urns(ilks[cdp], urns[cdp]);
        VatLike(vat).fork(
            ilks[cdp],
            urns[cdp],
            dst,
            toInt(ink),
            toInt(art)
        );
    }

    // Import a position from src urn to the urn owned by cdp
    function enter(
        address src,
        uint cdp
    ) public note urnAllowed(src) cdpAllowed(cdp) {
        (uint ink, uint art) = VatLike(vat).urns(ilks[cdp], src);
        VatLike(vat).fork(
            ilks[cdp],
            src,
            urns[cdp],
            toInt(ink),
            toInt(art)
        );
    }

    // Move a position from cdpSrc urn to the cdpDst urn
    function shift(
        uint cdpSrc,
        uint cdpDst
    ) public note cdpAllowed(cdpSrc) cdpAllowed(cdpDst) {
        require(ilks[cdpSrc] == ilks[cdpDst], "non-matching-cdps");
        (uint ink, uint art) = VatLike(vat).urns(ilks[cdpSrc], urns[cdpSrc]);
        VatLike(vat).fork(
            ilks[cdpSrc],
            urns[cdpSrc],
            urns[cdpDst],
            toInt(ink),
            toInt(art)
        );
    }
}


interface DSAuthority {
    function canCall(
        address src, address dst, bytes4 sig
    ) external view returns (bool);
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
        emit LogSetAuthority(address(authority));
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig), "ds-auth-unauthorized");
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
            return authority.canCall(src, address(this), sig);
        }
    }
}


contract VatLike {
    function urns(bytes32, address) public view returns (uint, uint);
    function hope(address) external;
    function flux(bytes32, address, address, uint) public;
    function move(address, address, uint) public;
    function frob(bytes32, address, address, address, int, int) public;
    function fork(bytes32, address, address, int, int) public;
    function ilks(bytes32 ilk) public view returns(uint Art, uint rate, uint spot, uint line, uint dust);

}

contract CatLike {
    function ilks(bytes32) public returns(address flip, uint256 chop, uint256 lump);
}

contract EndLike {
    function cat() public view returns(CatLike);
}

contract PriceFeedLike {
    function read(bytes32 ilk) external view returns(bytes32);
}

contract LiquidationMachine is DssCdpManager, BCdpScoreConnector, Math {
    VatLike                   public vat;
    EndLike                   public end;
    address                   public pool;
    PriceFeedLike             public real;

    mapping(uint => uint)     public tic;  // time of bite
    mapping(uint => uint)     public cushion; // how much was topped in art units

    uint constant             public GRACE = 1 hours;
    uint constant             public WAD = 1e18;

    mapping (uint => bool)    public out;

    modifier onlyPool {
        require(msg.sender == pool, "not-pool");
        _;
    }

    constructor(VatLike vat_, EndLike end_, address pool_, PriceFeedLike real_) public {
        vat = vat_;
        end = end_;
        pool = pool_;
        real = real_;
    }

    function setPool(address newPool) internal {
        pool = newPool;
    }

    function quitBLiquidation(uint cdp) internal {
        untop(cdp);
        out[cdp] = true;
    }

    function topup(uint cdp, uint dtopup) external onlyPool {
        if(out[cdp]) return;

        address urn = urns[cdp];
        bytes32 ilk = ilks[cdp];

        (, uint rate,,,) = vat.ilks(ilk);
        uint dtab = mul(rate, dtopup);

        vat.move(pool, address(this), dtab);
        vat.frob(ilk, urn, urn, address(this), 0, -toInt(dtopup));

        cushion[cdp] = add(cushion[cdp], dtopup);
    }

    function bitten(uint cdp) public view returns(bool) {
        return tic[cdp] + GRACE > now;
    }

    function untop(uint cdp) internal {
        require(! bitten(cdp), "untop: cdp was already bitten");

        uint top = cushion[cdp];
        if(top == 0) return; // nothing to do

        bytes32 ilk = ilks[cdp];
        address urn = urns[cdp];

        (, uint rate,,,) = vat.ilks(ilk);
        uint dtab = mul(rate, top);

        cushion[cdp] = 0;

        // move topping to pool
        vat.frob(ilk, urn, urn, urn, 0, toInt(top));
        vat.move(urn, pool, dtab);
    }

    function untopByPool(uint cdp) external onlyPool {
        untop(cdp);
    }

    function doBite(uint dart, bytes32 ilk, address urn, uint dink) internal {
        (, uint rate,,,) = vat.ilks(ilk);
        uint dtab = mul(rate, dart);

        vat.move(pool, address(this), dtab);

        vat.frob(ilk, urn, urn, address(this), 0, -toInt(dart));
        vat.frob(ilk, urn, msg.sender, urn, -toInt(dink), 0);
    }

    function calcDink(uint dart, uint rate, bytes32 ilk) internal returns(uint dink) {
        (, uint chop,) = end.cat().ilks(ilk);
        uint tab = mul(mul(dart, rate), chop) / WAD;
        bytes32 realtimePrice = real.read(ilk);

        dink = rmul(tab, WAD) / uint(realtimePrice);
    }

    function bite(uint cdp, uint dart) external onlyPool returns(uint dink){
        address urn = urns[cdp];
        bytes32 ilk = ilks[cdp];

        (uint ink, uint art) = vat.urns(ilk, urn);
        art = add(art, cushion[cdp]);
        (, uint rate, uint spotValue,,) = vat.ilks(ilk);

        require(dart <= art, "debt is too low");

        // verify cdp is unsafe now
        if(! bitten(cdp)) {
            require(mul(art, rate) > mul(ink, spotValue), "bite: cdp is safe");
            require(cushion[cdp] > 0, "bite: not-topped");
            tic[cdp] = now;
        }

        dink = calcDink(dart, rate, ilk);
        updateScore(cdp, ilk, -toInt(dink), -toInt(dart), now);

        uint usedCushion = mul(cushion[cdp], dart) / art;
        cushion[cdp] = sub(cushion[cdp], usedCushion);
        uint bart = sub(dart, usedCushion);

        doBite(bart, ilk, urn, dink);
    }
}


contract BCdpManager is BCdpScoreConnector, LiquidationMachine, DSAuth {
    constructor(address vat_, address end_, address pool_, address real_, address score_) public
        DssCdpManager(vat_)
        LiquidationMachine(VatLike(vat_), EndLike(end_), pool_, PriceFeedLike(real_))
        BCdpScoreConnector(BCdpScoreLike(score_))
    {

    }

    // Frob the cdp keeping the generated DAI or collateral freed in the cdp urn address.
    function frob(
        uint cdp,
        int dink,
        int dart
    ) public cdpAllowed(cdp) {
        bytes32 ilk = ilks[cdp];

        untop(cdp);
        updateScore(cdp, ilk, dink, dart, now);

        super.frob(cdp, dink, dart);
    }

    // Quit the system, migrating the cdp (ink, art) to a different dst urn
    function quit(
        uint cdp,
        address dst
    ) public cdpAllowed(cdp) urnAllowed(dst) {
        address urn = urns[cdp];
        bytes32 ilk = ilks[cdp];

        untop(cdp);
        (uint ink, uint art) = vat.urns(ilk, urn);
        updateScore(cdp, ilk, -toInt(ink), -toInt(art), now);

        super.quit(cdp, dst);
    }

    // Import a position from src urn to the urn owned by cdp
    function enter(
        address src,
        uint cdp
    ) public urnAllowed(src) cdpAllowed(cdp) {
        bytes32 ilk = ilks[cdp];

        untop(cdp);
        (uint ink, uint art) = vat.urns(ilk, src);
        updateScore(cdp, ilk, toInt(ink), toInt(art), now);

        super.enter(src, cdp);
    }

    // Move a position from cdpSrc urn to the cdpDst urn
    function shift(
        uint cdpSrc,
        uint cdpDst
    ) public cdpAllowed(cdpSrc) cdpAllowed(cdpDst) {
        bytes32 ilkSrc = ilks[cdpSrc];

        untop(cdpSrc);
        untop(cdpDst);

        address src = urns[cdpSrc];

        (uint inkSrc, uint artSrc) = vat.urns(ilkSrc, src);

        updateScore(cdpSrc, ilkSrc, -toInt(inkSrc), -toInt(artSrc), now);
        updateScore(cdpDst, ilkSrc, toInt(inkSrc), toInt(artSrc), now);

        super.shift(cdpSrc, cdpDst);
    }

    ///////////////// B specific control functions /////////////////////////////

    function quitB(uint cdp) external cdpAllowed(cdp) note {
        quitScore(cdp);
        quitBLiquidation(cdp);
    }

    function setScoreContract(BCdpScoreLike _score) external auth {
        super.setScore(_score);
    }

    function setPoolContract(address _pool) external auth {
        super.setPool(_pool);
    }
}

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ScoringMachine is Ownable {
    struct AssetScore {
        // total score so far
        uint score;

        // current balance
        uint balance;

        // time when last update was
        uint last;
    }

    // user is bytes32 (will be the sha3 of address or cdp number)
    mapping(bytes32 => mapping(bytes32 => AssetScore[])) public checkpoints;

    mapping(bytes32 => mapping(bytes32 => AssetScore)) public userScore;

    bytes32 constant public GLOBAL_USER = bytes32(0x0);

    uint public start; // start time of the campaign;

    function spin() external onlyOwner { // start a new round
        start = now;
    }

    function assetScore(AssetScore storage score, uint time, uint spinStart) internal view returns(uint) {
        uint last = score.last;
        uint currentScore = score.score;
        if(last < spinStart) {
            last = spinStart;
            currentScore = 0;
        }

        return add(currentScore, mul(score.balance, sub(time, last)));
    }

    function addCheckpoint(bytes32 user, bytes32 asset) internal {
        checkpoints[user][asset].push(userScore[user][asset]);
    }

    function updateAssetScore(bytes32 user, bytes32 asset, int dbalance, uint time) internal {
        AssetScore storage score = userScore[user][asset];

        if(score.last < start) addCheckpoint(user, asset);

        score.score = assetScore(score, time, start);
        score.balance = add(score.balance, dbalance);
        
        score.last = time;
    }

    function updateScore(bytes32 user, bytes32 asset, int dbalance, uint time) internal {
        updateAssetScore(user, asset, dbalance, time);
        updateAssetScore(GLOBAL_USER, asset, dbalance, time);
    }

    function getScore(bytes32 user, bytes32 asset, uint time, uint spinStart, uint checkPointHint) public view returns(uint score) {
        if(time >= userScore[user][asset].last) return assetScore(userScore[user][asset], time, spinStart);

        // else - check the checkpoints
        uint checkpointsLen = checkpoints[user][asset].length;
        if(checkpointsLen == 0) return 0;

        // hint is invalid
        if(checkpoints[user][asset][checkPointHint].last < time) checkPointHint = checkpointsLen - 1;

        for(uint i = checkPointHint ; ; i--){
            if(checkpoints[user][asset][i].last <= time) return assetScore(checkpoints[user][asset][i], time, spinStart);
        }

        // this supposed to be unreachable
        return 0;
    }

    function getCurrentBalance(bytes32 user, bytes32 asset) public view returns(uint balance) {
        balance = userScore[user][asset].balance;
    }

    // Math functions without errors
    // ==============================
    function add(uint x, uint y) internal pure returns (uint z) {
        z = x + y;
        if(!(z >= x)) return 0;

        return z;
    }

    function add(uint x, int y) internal pure returns (uint z) {
        z = x + uint(y);
        if(!(y >= 0 || z <= x)) return 0;
        if(!(y <= 0 || z >= x)) return 0;

        return z;
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        if(!(y <= x)) return 0;
        z = x - y;

        return z;
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        if (x == 0) return 0;

        z = x * y;
        if(!(z / x == y)) return 0;

        return z;
    }
}


contract BCdpScore is ScoringMachine {
    BCdpManager public manager;

    modifier onlyManager {
        require(msg.sender == address(manager), "not-manager");
        _;
    }

    function setManager(address newManager) external onlyOwner {
        manager = BCdpManager(newManager);
    }

    function user(uint cdp) public pure returns(bytes32) {
        return keccak256(abi.encodePacked("BCdpScore", cdp));
    }

    function artAsset(bytes32 ilk) public pure returns(bytes32) {
        return keccak256(abi.encodePacked("BCdpScore", "art", ilk));
    }

    function updateScore(uint cdp, bytes32 ilk, int dink, int dart, uint time) external onlyManager {
        dink; // shh compiler warning
        updateScore(user(cdp), artAsset(ilk), dart, time);
    }

    function slashScore(uint maliciousCdp) external {
        address urn = manager.urns(maliciousCdp);
        bytes32 ilk = manager.ilks(maliciousCdp);

        (, uint realArt) = manager.vat().urns(ilk, urn);

        bytes32 maliciousUser = user(maliciousCdp);
        bytes32 asset = artAsset(ilk);

        uint left = BCdpScoreConnector(address(manager)).left(maliciousCdp);

        realArt = left > 0 ? 0 : realArt;
        uint startTime = left > 0 ? left : now;

        uint calculatedArt = getCurrentBalance(maliciousUser, asset);
        require(realArt < calculatedArt, "slashScore-cdp-is-ok");
        int dart = int(realArt) - int(calculatedArt);
        uint time = sub(startTime, 30 days);
        if(time < start) time = start;
        
        updateScore(maliciousUser, asset, dart, time);
    }

    function getArtScore(uint cdp, bytes32 ilk, uint time, uint spinStart) public view returns(uint) {
        return getScore(user(cdp), artAsset(ilk), time, spinStart, 0);
    }

    function getArtGlobalScore(bytes32 ilk, uint time, uint spinStart) public view returns(uint) {
        return getScore(GLOBAL_USER, artAsset(ilk), time, spinStart, 0);
    }
}



contract JarConnector is Math {
    BCdpScore   public score;
    BCdpManager public man;
    bytes32[]   public ilks;
    // ilk => supported
    mapping(bytes32 => bool) public milks;

    // end of every round
    uint[2] public end;
    // start time of every round
    uint[2] public start;

    uint public round;

    constructor(
        bytes32[] memory _ilks,
        uint[2] memory _duration
    ) public {
        ilks = _ilks;

        for(uint i = 0; i < _ilks.length; i++) {
            milks[_ilks[i]] = true;
        }

        end[0] = now + _duration[0];
        end[1] = now + _duration[0] + _duration[1];

        round = 0;
    }

    function setManager(address _manager) public {
        require(man == BCdpManager(0), "manager-already-set");
        man = BCdpManager(_manager);
        score = BCdpScore(address(man.score()));
    }

    // callable by anyone
    function spin() public {
        if(round == 0) {
            round++;
            score.spin();
            start[0] = score.start();
        }
        if(round == 1 && now > end[0]) {
            round++;
            score.spin();
            start[1] = score.start();
        }
        if(round == 2 && now > end[1]) {
            round++;        
            // score is not counted anymore, and this must be followed by contract upgrade
            score.spin();
        }
    }

    function getUserScore(bytes32 user) external view returns (uint) {
        if(round == 0) return 0;

        uint cdp = uint(user);
        bytes32 ilk = man.ilks(cdp);

        // Should return 0 score for unsupported ilk
        if( ! milks[ilk]) return 0;

        if(round == 1) return 2 * score.getArtScore(cdp, ilk, now, start[0]);

        uint firstRoundScore = 2 * score.getArtScore(cdp, ilk, start[1], start[0]);
        uint time = now;
        if(round > 2) time = end[1];

        return add(score.getArtScore(cdp, ilk, time, start[1]), firstRoundScore);
    }

    function getGlobalScore() external view returns (uint) {
        if(round == 0) return 0;

        if(round == 1) return 2 * getArtGlobalScore(now, start[0]);

        uint firstRoundScore = 2 * getArtGlobalScore(start[1], start[0]);
        uint time = now;
        if(round > 2) time = end[1];

        return add(getArtGlobalScore(time, start[1]), firstRoundScore);
    }

    function getGlobalScore(bytes32 ilk) external view returns (uint) {
        if(round == 0) return 0;

        if(round == 1) return 2 * score.getArtGlobalScore(ilk, now, start[0]);

        uint firstRoundScore = 2 * score.getArtGlobalScore(ilk, start[1], start[0]);
        uint time = now;
        if(round > 2) time = end[1];

        return add(score.getArtGlobalScore(ilk, time, start[1]), firstRoundScore);
    }

    function getArtGlobalScore(uint time, uint spinStart) internal view returns (uint totalScore) {
        for(uint i = 0; i < ilks.length; i++) {
            totalScore = add(totalScore, score.getArtGlobalScore(ilks[i], time, spinStart));
        }
    }

    function toUser(bytes32 user) external view returns (address) {
        return man.owns(uint(user));
    }
}