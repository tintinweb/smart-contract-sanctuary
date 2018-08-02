pragma solidity ^0.4.21;

library bn256g1 {
    uint256 internal constant FIELD_ORDER = 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47;
    uint256 internal constant GEN_ORDER = 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001;
    uint256 internal constant CURVE_B = 3;
    uint256 internal constant CURVE_A = 0xc19139cb84c680a6e14116da060561765e05aa45a1c72a34f082305b61f3f52;
    struct Point {
        uint256 X;
        uint256 Y;
    }
    function genOrder() internal pure returns (uint256) {
        return GEN_ORDER;
    }
    function fieldOrder() internal pure returns (uint256) {
        return FIELD_ORDER;
    }
    function infinity() internal pure returns (Point) {
        return Point(0, 0);
    }
    function generator() internal pure returns (Point) {
        return Point(1, 2);
    }
    function equal(Point a, Point b) internal pure returns (bool) {
        return a.X == b.X && a.Y == b.Y;
    }
    function negate(Point p) internal pure returns (Point) {
        if(p.X == 0 && p.Y == 0) {
            return Point(0, 0);
        }
        return Point(p.X, FIELD_ORDER - (p.Y % FIELD_ORDER));
    }
    function hashToPoint(bytes32 s) internal view returns (Point) {
        uint256 beta = 0;
        uint256 y = 0;
        uint256 x = uint256(s) % GEN_ORDER;
        while( true ) {
            (beta, y) = findYforX(x);
            if(beta == mulmod(y, y, FIELD_ORDER)) {
                return Point(x, y);
            }

            x = addmod(x, 1, FIELD_ORDER);
        }
    }
    function findYforX(uint256 x) internal view returns (uint256, uint256) {
        uint256 beta = addmod(mulmod(mulmod(x, x, FIELD_ORDER), x, FIELD_ORDER), CURVE_B, FIELD_ORDER);
        uint256 y = expMod(beta, CURVE_A, FIELD_ORDER);
        return (beta, y);
    }
    function isInfinity(Point p) internal pure returns (bool) {
        return p.X == 0 && p.Y == 0;
    }
    function isOnCurve(Point p) internal pure returns (bool) {
        uint256 p_squared = mulmod(p.X, p.X, FIELD_ORDER);
        uint256 p_cubed = mulmod(p_squared, p.X, FIELD_ORDER);
        return addmod(p_cubed, CURVE_B, FIELD_ORDER) == mulmod(p.Y, p.Y, FIELD_ORDER);
    }
    function scalarBaseMult(uint256 x) internal view returns (Point r) {
        return scalarMult(generator(), x);
    }
    function pointAdd(Point p1, Point p2) internal view returns (Point r) {
        uint256[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        assembly {
            success := staticcall(sub(gas, 2000), 6, input, 0x80, r, 0x40)
            switch success case 0 { invalid() }
        }
        require(success);
    }
    function scalarMult(Point p, uint256 s) internal view returns (Point r) {
        uint256[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        assembly {
            success := staticcall(sub(gas, 2000), 7, input, 0x60, r, 0x40)
            switch success case 0 { invalid() }
        }
        require(success);
    }
    function expMod(uint256 base, uint256 exponent, uint256 modulus)
        internal view returns (uint256 retval)
    {
        bool success;
        uint256[1] memory output;
        uint256[6] memory input;
        input[0] = 0x20;
        input[1] = 0x20;
        input[2] = 0x20;
        input[3] = base;
        input[4] = exponent;
        input[5] = modulus;
        assembly {
            success := staticcall(sub(gas, 2000), 5, input, 0xc0, output, 0x20)
            switch success case 0 { invalid() }
        }
        require(success);
        return output[0];
    }
}

library LinkableRing {
    using bn256g1 for bn256g1.Point;
    uint256 public constant RING_SIZE = 1;
    struct Data {
        bn256g1.Point hash;
        bn256g1.Point[] pubkeys;
        uint256[] tags;
    }
    function message(Data storage self) internal view returns (bytes32) {
        require(isFull(self));
        return bytes32(self.hash.X);
    }
    function isDead(Data storage self) internal view returns (bool) {
        return self.hash.X == 0 || (self.tags.length >= RING_SIZE && self.pubkeys.length >= RING_SIZE);
    }
    function pubExists(Data storage self, uint256 pub_x) internal view returns (bool) {
        for(uint i = 0; i < self.pubkeys.length; i++) {
            if(self.pubkeys[i].X == pub_x) {
                return true;
            }
        }
        return false;
    }
    function tagExists(Data storage self, uint256 pub_x) internal view returns (bool) {
        for(uint i = 0; i < self.tags.length; i++) {
            if(self.tags[i] == pub_x) {
                return true;
            }
        }
        return false;
    }
    function isInitialized(Data storage self) internal view returns (bool) {
        return self.hash.X != 0;
    }
    function initialize(Data storage self, bytes32 guid) internal returns (bool) {
        require(uint256(guid) != 0);
        require(self.hash.X == 0);
        self.hash.X = uint256(guid);
        return true;
    }
    function isFull(Data storage self) internal view returns (bool) {
        return self.pubkeys.length == RING_SIZE;
    }
    function addParticipant(Data storage self, uint256 pub_x, uint256 pub_y)
        internal returns (bool)
    {
        require(!isFull(self));
        require(!pubExists(self, pub_x));
        bn256g1.Point memory pub = bn256g1.Point(pub_x, pub_y);
        require(pub.isOnCurve());
        self.hash.X = uint256(sha256(self.hash.X, pub.X, pub.Y));
        self.pubkeys.push(pub);
        if(isFull(self)) {
            self.hash = bn256g1.hashToPoint(bytes32(self.hash.X));
        }
        return true;
    }
    function tagAdd(Data storage self, uint256 tag_x) internal {
        self.tags.push(tag_x);
    }
    function ringLink(uint256 previous_hash, uint256 cj, uint256 tj, bn256g1.Point tau, bn256g1.Point h, bn256g1.Point yj)
        internal view returns (uint256 ho)
    {
        bn256g1.Point memory yc = yj.scalarMult(cj);
        bn256g1.Point memory a = bn256g1.scalarBaseMult(tj).pointAdd(yc);
        bn256g1.Point memory b = h.scalarMult(tj).pointAdd(tau.scalarMult(cj));
        return uint256(sha256(previous_hash, a.X, a.Y, b.X, b.Y));
    }
    function isSignatureValid(Data storage self, uint256 tag_x, uint256 tag_y, uint256[] ctlist)
        internal view returns (bool)
    {
        require(isFull(self));
        require(!tagExists(self, tag_x));
        uint256 hashout = uint256(sha256(self.hash.X, tag_x, tag_y));
        uint256 csum = 0;

        for (uint i = 0; i < self.pubkeys.length; i++) {
            uint256 cj = ctlist[2*i] % bn256g1.genOrder();
            uint256 tj = ctlist[2*i+1] % bn256g1.genOrder();
            hashout = ringLink(hashout, cj, tj, bn256g1.Point(tag_x, tag_y), self.hash, self.pubkeys[i]);
            csum = addmod(csum, cj, bn256g1.genOrder());
        }

        hashout %= bn256g1.genOrder();
        return hashout == csum;
    }
}

interface ERC223 {
    function transferFrom(address _from, address _to, uint _value) external returns (bool);
    function approve(address _spender, uint _value) external returns (bool);
    function allowance(address _owner, address _spender) external returns (uint);
    function transfer(address _to, uint _value, bytes _data) public returns (bool);

    event Approval(address indexed _owner, address indexed _spender, uint _value);
    event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
}

contract ERC223ReceivingContract {
    function tokenFallback(address _from, uint _value, bytes _data) public;
}

contract ERC20Compatible {
    function transferFrom(address from, address to, uint256 value) public;
    function transfer(address to, uint256 value) public;
}

contract Mixer {
    using LinkableRing for LinkableRing.Data;

    struct Data {
        bytes32 guid;
        uint256 denomination;
        address token;
        LinkableRing.Data ring;
    }

    mapping(bytes32 => Data) internal m_rings;
    mapping(uint256 => bytes32) internal m_pubx_to_ring;
    mapping(bytes32 => bytes32) internal m_filling;
    
    uint256 internal m_ring_ctr;

    event LogMixerDeposit(bytes32 indexed ring_id,uint256 indexed pub_x,address token,uint256 value);
    event LogMixerWithdraw(bytes32 indexed ring_id,uint256 tag_x,address token,uint256 value);
    event LogMixerReady(bytes32 indexed ring_id, bytes32 message);
    event LogMixerDead(bytes32 indexed ring_id);

    function () public {
        revert();
    }

    function message(bytes32 ring_guid) public view returns (bytes32)
    {
        Data storage entry = m_rings[ring_guid];
        LinkableRing.Data storage ring = entry.ring;
        require(0 != entry.denomination);
        return ring.message();
    }

    function depositEther(address token, uint256 denomination, uint256 pub_x, uint256 pub_y) public payable returns (bytes32)
    {
        require(token == 0);
        require(denomination == msg.value);
        bytes32 ring_guid = depositLogic(token, denomination, pub_x, pub_y);
        return ring_guid;
    }

    function depositERC20Compatible(address token, uint256 denomination, uint256 pub_x, uint256 pub_y) public returns (bytes32)
    {
        uint256 codeLength;
        assembly {
            codeLength := extcodesize(token)
        }

        require(token != 0 && codeLength > 0);
        bytes32 ring_guid = depositLogic(token, denomination, pub_x, pub_y);
        ERC20Compatible untrustedErc20Token = ERC20Compatible(token);
        untrustedErc20Token.transferFrom(msg.sender, this, denomination);
        return ring_guid;
    }

    function withdrawEther(bytes32 ring_id, uint256 tag_x, uint256 tag_y, uint256[] ctlist) public returns (bool)
    {
        Data memory entry = withdrawLogic(ring_id, tag_x, tag_y, ctlist);
        msg.sender.transfer(entry.denomination);
        return true;
    }

    function withdrawERC20Compatible(bytes32 ring_id, uint256 tag_x, uint256 tag_y, uint256[] ctlist) public returns (bool)
    {
        Data memory entry = withdrawLogic(ring_id, tag_x, tag_y, ctlist);
        ERC20Compatible untrustedErc20Token = ERC20Compatible(entry.token);
        untrustedErc20Token.transfer(msg.sender, entry.denomination);
        return true;
    }

    function lookupFillingRing(address token, uint256 denomination) internal returns (bytes32, Data storage)
    {
        bytes32 filling_id = sha256(token, denomination);
        bytes32 ring_guid = m_filling[filling_id];
        if(ring_guid != 0) {
            return (filling_id, m_rings[ring_guid]);
        }
        ring_guid = sha256(address(this), m_ring_ctr, filling_id);
        Data storage entry = m_rings[ring_guid];
        require(0 == entry.denomination);
        require(entry.ring.initialize(ring_guid));
        entry.guid = ring_guid;
        entry.token = token;
        entry.denomination = denomination;
        m_ring_ctr += 1;
        m_filling[filling_id] = ring_guid;
        return (filling_id, entry);
    }

    function depositLogic(address token, uint256 denomination, uint256 pub_x, uint256 pub_y)
        internal returns (bytes32)
    {
        require(denomination != 0 && 0 == (denomination & (denomination - 1)));
        require(0 == uint256(m_pubx_to_ring[pub_x]));
        bytes32 filling_id;
        Data storage entry;
        (filling_id, entry) = lookupFillingRing(token, denomination);
        LinkableRing.Data storage ring = entry.ring;
        require(ring.addParticipant(pub_x, pub_y));
        bytes32 ring_guid = entry.guid;
        m_pubx_to_ring[pub_x] = ring_guid;
        emit LogMixerDeposit(ring_guid, pub_x, token, denomination);
        if(ring.isFull()) {
            delete m_filling[filling_id];
            emit LogMixerReady(ring_guid, ring.message());
        }
        return ring_guid;
    }

    function withdrawLogic(bytes32 ring_id, uint256 tag_x, uint256 tag_y, uint256[] ctlist)
        internal returns (Data)
    {
        Data storage entry = m_rings[ring_id];
        LinkableRing.Data storage ring = entry.ring;
        require(0 != entry.denomination);
        require(ring.isFull());
        require(ring.isSignatureValid(tag_x, tag_y, ctlist));
        ring.tagAdd(tag_x);
        emit LogMixerWithdraw(ring_id, tag_x, entry.token, entry.denomination);
        Data memory entrySaved = entry;
        if(ring.isDead()) {
            for(uint i = 0; i < ring.pubkeys.length; i++) {
                delete m_pubx_to_ring[ring.pubkeys[i].X];
            }
            delete m_rings[ring_id];
            emit LogMixerDead(ring_id);
        }
        return entrySaved;
    }
}
//This project was developed by Apolo Blockchain Technologies LLC - HA08-07C23-10V26-02 - CD10-05A29-09F10-08