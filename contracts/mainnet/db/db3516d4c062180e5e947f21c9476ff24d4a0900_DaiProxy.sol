/**
 *Submitted for verification at Etherscan.io on 2021-05-24
*/

pragma solidity ^0.5.12;

contract ReserveLike {
    function depositToken(address, string memory, bytes memory, uint) public;
}

contract WrappedDaiLike {
    function setProxy(address) public;
    function setReserve(address) public;

    uint public totalSupply;
    function approve(address, uint) public returns (bool);

    function mint(address, uint) public;
    function burn(address, uint) public;
}

contract DaiLike {
    function approve(address, uint) public returns (bool);
    function transferFrom(address, address, uint) public returns (bool);
}

contract JoinLike {
    VatLike public vat;
    DaiLike public dai;

    function join(address, uint) public;
    function exit(address, uint) public;
}

contract PotLike {
    mapping(address => uint) public pie;
    uint public chi;

    VatLike public vat;
    uint public rho;

    function drip() public returns (uint);

    function join(uint) public;
    function exit(uint) public;
}

contract VatLike {
    mapping(address => uint) public dai;

    function hope(address) public;
    function move(address, address, uint) public;
}

contract DaiProxy {
    string public constant version = "0511";

    // --- Owner ---
    address public owner;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    event SetOwner(address owner);

    function setOwner(address _owner) public onlyOwner {
        owner = _owner;
        emit SetOwner(_owner);
    }

    // --- State ---
    enum State { Ready, Running, Killed }

    State public state = State.Ready;

    modifier notStarted {
        require(state == State.Ready);
        _;
    }

    modifier notPaused {
        require(state == State.Running);
        _;
    }

    // --- Math ---
    uint constant ONE = 10 ** 27;

    function add(uint a, uint b) private pure returns (uint) {
        require(a <= uint(-1) - b);
        return a + b;
    }

    function sub(uint a, uint b) private pure returns (uint) {
        require(a >= b);
        return a - b;
    }

    function mul(uint a, uint b) private pure returns (uint) {
        require(b == 0 || a <= uint(-1) / b);
        return a * b;
    }

    function div(uint a, uint b) private pure returns (uint) {
        require(b != 0);
        return a / b;
    }

    function ceil(uint a, uint b) private pure returns (uint) {
        require(b != 0);

        uint r = a / b;
        return a > r * b ? r + 1 : r;
    }

    function muldiv(uint a, uint b, uint c) private pure returns (uint) {
        uint safe = 1 << (256 - 32);  // 2.696e67
        uint mask = (1 << 32) - 1;

        require(c != 0 && c < safe);

        if (b == 0) return 0;
        if (a < b) (a, b) = (b, a);
        
        uint p = a / c;
        uint r = a % c;

        uint res = 0;

        while (true) {  // most 8 times
            uint v = b & mask;
            res = add(res, add(mul(p, v), r * v / c));

            b >>= 32;
            if (b == 0) break;

            require(p < safe);

            p <<= 32;
            r <<= 32;

            p = add(p, r / c);
            r %= c;
        }

        return res;
    }

    // --- Contracts & Constructor ---
    DaiLike public Dai;
    JoinLike public Join;
    PotLike public Pot;
    VatLike public Vat;

    ReserveLike public Reserve;

    WrappedDaiLike public EDai;
    WrappedDaiLike public ODai;

    event SetReserve(address reserve);

    constructor(address dai, address join, address pot, address vat, address eDai, address oDai) public {
        owner = msg.sender;

        Dai = DaiLike(dai);
        Join = JoinLike(join);
        Pot = PotLike(pot);
        Vat = VatLike(vat);

        EDai = WrappedDaiLike(eDai);
        ODai = WrappedDaiLike(oDai);

        require(address(Join.dai()) == dai);
        require(address(Join.vat()) == vat);
        require(address(Pot.vat()) == vat);

        Vat.hope(pot);  // Pot.join
        Vat.hope(join);  // Join.exit

        require(Dai.approve(join, uint(-1)));  // Join.join -> dai.burn
    }

    function setReserve(address reserve) public onlyOwner {
        require(EDai.approve(address(Reserve), 0));
        require(ODai.approve(address(Reserve), 0));

        Reserve = ReserveLike(reserve);

        EDai.setReserve(reserve);
        ODai.setReserve(reserve);

        // approve for Reserve.depositToken
        require(EDai.approve(reserve, uint(-1)));
        require(ODai.approve(reserve, uint(-1)));

        emit SetReserve(reserve);
    }

    modifier onlyEDai {
        require(msg.sender == address(EDai));
        _;
    }

    modifier onlyODai {
        require(msg.sender == address(ODai));
        _;
    }

    // --- Integration ---
    function chi() private returns (uint) {
        return now > Pot.rho() ? Pot.drip() : Pot.chi();
    }

    function joinDai(uint dai) private {
        require(Dai.transferFrom(msg.sender, address(this), dai));
        Join.join(address(this), dai);

        uint vat = Vat.dai(address(this));
        Pot.join(div(vat, chi()));
    }

    function exitDai(address to, uint dai) private {
        uint vat = Vat.dai(address(this));
        uint req = mul(dai, ONE);

        if (req > vat) {
            uint pot = ceil(req - vat, chi());
            Pot.exit(pot);
        }

        Join.exit(to, dai);
    }

    function mintODai(address to, uint dai) private returns (uint) {
        uint wad = dai;

        if (ODai.totalSupply() != 0) {
            uint pie = Pot.pie(address(this));
            uint vat = Vat.dai(address(this));

            // 기존 rad
            uint rad = sub(add(mul(pie, chi()), vat), mul(EDai.totalSupply(), ONE));

            // rad : supply = dai * ONE : wad
            wad = muldiv(ODai.totalSupply(), mul(dai, ONE), rad);
        }

        joinDai(dai);
        ODai.mint(to, wad);
        return wad;
    }

    function depositEDai(string memory toChain, uint dai, bytes memory to) public notPaused {
        require(dai > 0);

        joinDai(dai);

        EDai.mint(address(this), dai);
        Reserve.depositToken(address(EDai), toChain, to, dai);
    }

    function depositODai(string memory toChain, uint dai, bytes memory to) public notPaused {
        require(dai > 0);

        uint wad = mintODai(address(this), dai);
        Reserve.depositToken(address(ODai), toChain, to, wad);
    }

    function swapFromEDai(address from, address to, uint dai) private {
        EDai.burn(from, dai);
        exitDai(to, dai);
    }

    function swapFromODai(address from, address to, uint wad) private {
        uint pie = Pot.pie(address(this));
        uint vat = Vat.dai(address(this));

        // 기존 rad
        uint rad = sub(add(mul(pie, chi()), vat), mul(EDai.totalSupply(), ONE));

        // rad : supply = dai * ONE : wad
        uint dai = muldiv(rad, wad, mul(ODai.totalSupply(), ONE));

        ODai.burn(from, wad);
        exitDai(to, dai);
    }

    function withdrawEDai(address to, uint dai) public onlyEDai notPaused {
        require(dai > 0);

        swapFromEDai(address(Reserve), to, dai);
    }

    function withdrawODai(address to, uint wad) public onlyODai notPaused {
        require(wad > 0);

        swapFromODai(address(Reserve), to, wad);
    }

    function swapToEDai(uint dai) public notPaused {
        require(dai > 0);

        joinDai(dai);
        EDai.mint(msg.sender, dai);
    }

    function swapToODai(uint dai) public notPaused {
        require(dai > 0);

        mintODai(msg.sender, dai);
    }

    function swapFromEDai(uint dai) public notPaused {
        require(dai > 0);

        swapFromEDai(msg.sender, msg.sender, dai);
    }

    function swapFromODai(uint wad) public notPaused {
        require(wad > 0);

        swapFromODai(msg.sender, msg.sender, wad);
    }

    // --- Migration ---
    DaiProxy public NewProxy;

    event SetNewProxy(address proxy);
    event StartProxy(address prev);
    event KillProxy(address next, bool mig);

    modifier onlyNewProxy {
        require(msg.sender == address(NewProxy));
        _;
    }


    function setNewProxy(address proxy) public onlyOwner {
        NewProxy = DaiProxy(proxy);
        emit SetNewProxy(proxy);
    }


    function killProxy(address to) public notPaused onlyOwner {
        state = State.Killed;

        chi();

        Pot.exit(Pot.pie(address(this)));
        Join.exit(to, Vat.dai(address(this)) / ONE);

        emit KillProxy(to, false);
    }


    function migrateProxy() public notPaused onlyNewProxy {
        state = State.Killed;

        EDai.setProxy(address(NewProxy));
        ODai.setProxy(address(NewProxy));

        chi();

        Pot.exit(Pot.pie(address(this)));
        Vat.move(address(this), address(NewProxy), Vat.dai(address(this)));

        emit KillProxy(address(NewProxy), true);
    }


    function startProxy(address oldProxy) public notStarted onlyOwner {
        state = State.Running;

        if (oldProxy != address(0)) {
            DaiProxy(oldProxy).migrateProxy();

            uint vat = Vat.dai(address(this));
            Pot.join(div(vat, chi()));
        }

        emit StartProxy(oldProxy);
    }
}