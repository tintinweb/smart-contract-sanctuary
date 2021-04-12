/**
 *Submitted for verification at Etherscan.io on 2021-04-12
*/

pragma solidity ^0.5.12;

contract VatLike {
    function hope(address) external;
}

contract PotLike {
    function vat() external view returns (address);
    function chi() external view returns (uint256);
    function rho() external view returns (uint256);
    function drip() external returns (uint256);
    function join(uint256) external;
    function exit(uint256) external;
}

contract JoinLike {
    function dai() external view returns (address);
    function join(address, uint256) external;
    function exit(address, uint256) external;
}

contract GemLike {
    function transferFrom(address,address,uint256) external returns (bool);
    function approve(address,uint256) external returns (bool);
}

contract DsrManager {
    PotLike  public pot;
    GemLike  public dai;
    JoinLike public daiJoin;

    uint256 public supply;

    mapping (address => uint256) public pieOf;

    event Join(address indexed dst, uint256 wad);
    event Exit(address indexed dst, uint256 wad);

    uint256 constant RAY = 10 ** 27;
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }
    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        // always rounds down
        z = mul(x, y) / RAY;
    }
    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        // always rounds down
        z = mul(x, RAY) / y;
    }
    function rdivup(uint256 x, uint256 y) internal pure returns (uint256 z) {
        // always rounds up
        z = add(mul(x, RAY), sub(y, 1)) / y;
    }

    constructor(address pot_, address daiJoin_) public {
        pot = PotLike(pot_);
        daiJoin = JoinLike(daiJoin_);
        dai = GemLike(daiJoin.dai());

        VatLike vat = VatLike(pot.vat());
        vat.hope(address(daiJoin));
        vat.hope(address(pot));
        dai.approve(address(daiJoin), uint256(-1));
    }

    function daiBalance(address usr) external returns (uint256 wad) {
        uint256 chi = (now > pot.rho()) ? pot.drip() : pot.chi();
        wad = rmul(chi, pieOf[usr]);
    }

    // wad is denominated in dai
    function join(address dst, uint256 wad) external {
        uint256 chi = (now > pot.rho()) ? pot.drip() : pot.chi();
        uint256 pie = rdiv(wad, chi);
        pieOf[dst] = add(pieOf[dst], pie);
        supply = add(supply, pie);

        dai.transferFrom(msg.sender, address(this), wad);
        daiJoin.join(address(this), wad);
        pot.join(pie);
        emit Join(dst, wad);
    }

    // wad is denominated in dai
    function exit(address dst, uint256 wad) external {
        uint256 chi = (now > pot.rho()) ? pot.drip() : pot.chi();
        uint256 pie = rdivup(wad, chi);

        require(pieOf[msg.sender] >= pie, "insufficient-balance");

        pieOf[msg.sender] = sub(pieOf[msg.sender], pie);
        supply = sub(supply, pie);

        pot.exit(pie);
        uint256 amt = rmul(chi, pie);
        daiJoin.exit(dst, amt);
        emit Exit(dst, amt);
    }

    function exitAll(address dst) external {
        uint256 chi = (now > pot.rho()) ? pot.drip() : pot.chi();
        uint256 pie = pieOf[msg.sender];

        pieOf[msg.sender] = 0;
        supply = sub(supply, pie);

        pot.exit(pie);
        uint256 amt = rmul(chi, pie);
        daiJoin.exit(dst, amt);
        emit Exit(dst, amt);
    }
}