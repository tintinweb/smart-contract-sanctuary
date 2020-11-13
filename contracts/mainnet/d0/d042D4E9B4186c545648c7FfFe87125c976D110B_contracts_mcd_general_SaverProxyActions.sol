pragma solidity ^0.6.0;

abstract contract GemLike {
    function approve(address, uint) virtual public;
    function transfer(address, uint) virtual public;
    function transferFrom(address, address, uint) virtual public;
    function deposit() virtual public payable;
    function withdraw(uint) virtual public;
}

abstract contract ManagerLike {
    function cdpCan(address, uint, address) virtual public view returns (uint);
    function ilks(uint) virtual public view returns (bytes32);
    function owns(uint) virtual public view returns (address);
    function urns(uint) virtual public view returns (address);
    function vat() virtual public view returns (address);
    function open(bytes32, address) virtual public returns (uint);
    function give(uint, address) virtual public;
    function cdpAllow(uint, address, uint) virtual public;
    function urnAllow(address, uint) virtual public;
    function frob(uint, int, int) virtual public;
    function flux(uint, address, uint) virtual public;
    function move(uint, address, uint) virtual public;
    function exit(address, uint, address, uint) virtual public;
    function quit(uint, address) virtual public;
    function enter(address, uint) virtual public;
    function shift(uint, uint) virtual public;
}

abstract contract VatLike {
    function can(address, address) virtual public view returns (uint);
    function ilks(bytes32) virtual public view returns (uint, uint, uint, uint, uint);
    function dai(address) virtual public view returns (uint);
    function urns(bytes32, address) virtual public view returns (uint, uint);
    function frob(bytes32, address, address, address, int, int) virtual public;
    function hope(address) virtual public;
    function move(address, address, uint) virtual public;
}

abstract contract GemJoinLike {
    function dec() virtual public returns (uint);
    function gem() virtual public returns (GemLike);
    function join(address, uint) virtual public payable;
    function exit(address, uint) virtual public;
}

abstract contract GNTJoinLike {
    function bags(address) virtual public view returns (address);
    function make(address) virtual public returns (address);
}

abstract contract DaiJoinLike {
    function vat() virtual public returns (VatLike);
    function dai() virtual public returns (GemLike);
    function join(address, uint) virtual public payable;
    function exit(address, uint) virtual public;
}

abstract contract HopeLike {
    function hope(address) virtual public;
    function nope(address) virtual public;
}

abstract contract ProxyRegistryInterface {
    function proxies(address _owner) virtual public view returns (address);
    function build(address) virtual public returns (address);
}

abstract contract EndLike {
    function fix(bytes32) virtual public view returns (uint);
    function cash(bytes32, uint) virtual public;
    function free(bytes32) virtual public;
    function pack(uint) virtual public;
    function skim(bytes32, address) virtual public;
}

abstract contract JugLike {
    function drip(bytes32) virtual public returns (uint);
}

abstract contract PotLike {
    function pie(address) virtual public view returns (uint);
    function drip() virtual public returns (uint);
    function join(uint) virtual public;
    function exit(uint) virtual public;
}

abstract contract ProxyRegistryLike {
    function proxies(address) virtual public view returns (address);
    function build(address) virtual public returns (address);
}

abstract contract ProxyLike {
    function owner() virtual public view returns (address);
}

abstract contract DSProxy {
    function execute(address _target, bytes memory _data) virtual public payable returns (bytes32);
    function setOwner(address owner_) virtual public;
}

// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// WARNING: These functions meant to be used as a a library for a DSProxy. Some are unsafe if you call them directly.
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

contract Common {
    uint256 constant RAY = 10 ** 27;

    // Internal functions

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "mul-overflow");
    }

    // Public functions

    function daiJoin_join(address apt, address urn, uint wad) public {
        // Gets DAI from the user's wallet
        DaiJoinLike(apt).dai().transferFrom(msg.sender, address(this), wad);
        // Approves adapter to take the DAI amount
        DaiJoinLike(apt).dai().approve(apt, wad);
        // Joins DAI into the vat
        DaiJoinLike(apt).join(urn, wad);
    }
}

contract SaverProxyActions is Common {


    event CDPAction(string indexed, uint indexed, uint, uint);

    // Internal functions

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "sub-overflow");
    }

    function toInt(uint x) internal pure returns (int y) {
        y = int(x);
        require(y >= 0, "int-overflow");
    }

    function toRad(uint wad) internal pure returns (uint rad) {
        rad = mul(wad, 10 ** 27);
    }

    function convertTo18(address gemJoin, uint256 amt) internal returns (uint256 wad) {
        // For those collaterals that have less than 18 decimals precision we need to do the conversion before passing to frob function
        // Adapters will automatically handle the difference of precision
        wad = mul(
            amt,
            10 ** (18 - GemJoinLike(gemJoin).dec())
        );
    }

    function _getDrawDart(
        address vat,
        address jug,
        address urn,
        bytes32 ilk,
        uint wad
    ) internal returns (int dart) {
        // Updates stability fee rate
        uint rate = JugLike(jug).drip(ilk);

        // Gets DAI balance of the urn in the vat
        uint dai = VatLike(vat).dai(urn);

        // If there was already enough DAI in the vat balance, just exits it without adding more debt
        if (dai < mul(wad, RAY)) {
            // Calculates the needed dart so together with the existing dai in the vat is enough to exit wad amount of DAI tokens
            dart = toInt(sub(mul(wad, RAY), dai) / rate);
            // This is neeeded due lack of precision. It might need to sum an extra dart wei (for the given DAI wad amount)
            dart = mul(uint(dart), rate) < mul(wad, RAY) ? dart + 1 : dart;
        }
    }

    function _getWipeDart(
        address vat,
        uint dai,
        address urn,
        bytes32 ilk
    ) internal view returns (int dart) {
        // Gets actual rate from the vat
        (, uint rate,,,) = VatLike(vat).ilks(ilk);
        // Gets actual art value of the urn
        (, uint art) = VatLike(vat).urns(ilk, urn);

        // Uses the whole dai balance in the vat to reduce the debt
        dart = toInt(dai / rate);
        // Checks the calculated dart is not higher than urn.art (total debt), otherwise uses its value
        dart = uint(dart) <= art ? - dart : - toInt(art);
    }

    function _getWipeAllWad(
        address vat,
        address usr,
        address urn,
        bytes32 ilk
    ) internal view returns (uint wad) {
        // Gets actual rate from the vat
        (, uint rate,,,) = VatLike(vat).ilks(ilk);
        // Gets actual art value of the urn
        (, uint art) = VatLike(vat).urns(ilk, urn);
        // Gets actual dai amount in the urn
        uint dai = VatLike(vat).dai(usr);

        uint rad = sub(mul(art, rate), dai);
        wad = rad / RAY;

        // If the rad precision has some dust, it will need to request for 1 extra wad wei
        wad = mul(wad, RAY) < rad ? wad + 1 : wad;
    }

    // Public functions

    function transfer(address gem, address dst, uint wad) public {
        GemLike(gem).transfer(dst, wad);
    }

    function ethJoin_join(address apt, address urn) public payable {
        // Wraps ETH in WETH
        GemJoinLike(apt).gem().deposit{value: msg.value}();
        // Approves adapter to take the WETH amount
        GemJoinLike(apt).gem().approve(address(apt), msg.value);
        // Joins WETH collateral into the vat
        GemJoinLike(apt).join(urn, msg.value);
    }

    function gemJoin_join(address apt, address urn, uint wad, bool transferFrom) public {
        // Only executes for tokens that have approval/transferFrom implementation
        if (transferFrom) {
            // Gets token from the user's wallet
            GemJoinLike(apt).gem().transferFrom(msg.sender, address(this), wad);
            // Approves adapter to take the token amount
            GemJoinLike(apt).gem().approve(apt, 0);
            GemJoinLike(apt).gem().approve(apt, wad);
        }
        // Joins token collateral into the vat
        GemJoinLike(apt).join(urn, wad);
    }

    function hope(
        address obj,
        address usr
    ) public {
        HopeLike(obj).hope(usr);
    }

    function nope(
        address obj,
        address usr
    ) public {
        HopeLike(obj).nope(usr);
    }

    function open(
        address manager,
        bytes32 ilk,
        address usr
    ) public returns (uint cdp) {
        cdp = ManagerLike(manager).open(ilk, usr);
    }

    function give(
        address manager,
        uint cdp,
        address usr
    ) public {
        ManagerLike(manager).give(cdp, usr);

        emit CDPAction('give', cdp, 0, 0);
    }

    function giveToProxy(
        address proxyRegistry,
        address manager,
        uint cdp,
        address dst
    ) public {
        // Gets actual proxy address
        address proxy = ProxyRegistryLike(proxyRegistry).proxies(dst);
        // Checks if the proxy address already existed and dst address is still the owner
        if (proxy == address(0) || ProxyLike(proxy).owner() != dst) {
            uint csize;
            assembly {
                csize := extcodesize(dst)
            }
            // We want to avoid creating a proxy for a contract address that might not be able to handle proxies, then losing the CDP
            require(csize == 0, "Dst-is-a-contract");
            // Creates the proxy for the dst address
            proxy = ProxyRegistryLike(proxyRegistry).build(dst);
        }
        // Transfers CDP to the dst proxy
        give(manager, cdp, proxy);
    }

    function cdpAllow(
        address manager,
        uint cdp,
        address usr,
        uint ok
    ) public {
        ManagerLike(manager).cdpAllow(cdp, usr, ok);
    }

    function urnAllow(
        address manager,
        address usr,
        uint ok
    ) public {
        ManagerLike(manager).urnAllow(usr, ok);
    }

    function flux(
        address manager,
        uint cdp,
        address dst,
        uint wad
    ) public {
        ManagerLike(manager).flux(cdp, dst, wad);
    }

    function move(
        address manager,
        uint cdp,
        address dst,
        uint rad
    ) public {
        ManagerLike(manager).move(cdp, dst, rad);
    }

    function frob(
        address manager,
        uint cdp,
        int dink,
        int dart
    ) public {
        ManagerLike(manager).frob(cdp, dink, dart);
    }

    function quit(
        address manager,
        uint cdp,
        address dst
    ) public {
        ManagerLike(manager).quit(cdp, dst);
    }

    function enter(
        address manager,
        address src,
        uint cdp
    ) public {
        ManagerLike(manager).enter(src, cdp);
    }

    function shift(
        address manager,
        uint cdpSrc,
        uint cdpOrg
    ) public {
        ManagerLike(manager).shift(cdpSrc, cdpOrg);
    }

    function makeGemBag(
        address gemJoin
    ) public returns (address bag) {
        bag = GNTJoinLike(gemJoin).make(address(this));
    }

    function lockETH(
        address manager,
        address ethJoin,
        uint cdp
    ) public payable {
        // Receives ETH amount, converts it to WETH and joins it into the vat
        ethJoin_join(ethJoin, address(this));
        // Locks WETH amount into the CDP
        VatLike(ManagerLike(manager).vat()).frob(
            ManagerLike(manager).ilks(cdp),
            ManagerLike(manager).urns(cdp),
            address(this),
            address(this),
            toInt(msg.value),
            0
        );

        emit CDPAction('lockETH', cdp, msg.value, 0);
    }

    function lockGem(
        address manager,
        address gemJoin,
        uint cdp,
        uint wad,
        bool transferFrom
    ) public {
        // Takes token amount from user's wallet and joins into the vat
        gemJoin_join(gemJoin, address(this), wad, transferFrom);
        // Locks token amount into the CDP
        VatLike(ManagerLike(manager).vat()).frob(
            ManagerLike(manager).ilks(cdp),
            ManagerLike(manager).urns(cdp),
            address(this),
            address(this),
            toInt(convertTo18(gemJoin, wad)),
            0
        );

        emit CDPAction('lockGem', cdp, wad, 0);
    }

    function freeETH(
        address manager,
        address ethJoin,
        uint cdp,
        uint wad
    ) public {
        // Unlocks WETH amount from the CDP
        frob(manager, cdp, -toInt(wad), 0);
        // Moves the amount from the CDP urn to proxy's address
        flux(manager, cdp, address(this), wad);
        // Exits WETH amount to proxy address as a token
        GemJoinLike(ethJoin).exit(address(this), wad);
        // Converts WETH to ETH
        GemJoinLike(ethJoin).gem().withdraw(wad);
        // Sends ETH back to the user's wallet
        msg.sender.transfer(wad);

        emit CDPAction('freeETH', cdp, wad, 0);
    }

    function freeGem(
        address manager,
        address gemJoin,
        uint cdp,
        uint wad
    ) public {
        uint wad18 = convertTo18(gemJoin, wad);
        // Unlocks token amount from the CDP
        frob(manager, cdp, -toInt(wad18), 0);
        // Moves the amount from the CDP urn to proxy's address
        flux(manager, cdp, address(this), wad18);
        // Exits token amount to the user's wallet as a token
        GemJoinLike(gemJoin).exit(msg.sender, wad);

        emit CDPAction('freeGem', cdp, wad, 0);
    }

    function exitETH(
        address manager,
        address ethJoin,
        uint cdp,
        uint wad
    ) public {
        // Moves the amount from the CDP urn to proxy's address
        flux(manager, cdp, address(this), wad);

        // Exits WETH amount to proxy address as a token
        GemJoinLike(ethJoin).exit(address(this), wad);
        // Converts WETH to ETH
        GemJoinLike(ethJoin).gem().withdraw(wad);
        // Sends ETH back to the user's wallet
        msg.sender.transfer(wad);
    }

    function exitGem(
        address manager,
        address gemJoin,
        uint cdp,
        uint wad
    ) public {
        // Moves the amount from the CDP urn to proxy's address
        flux(manager, cdp, address(this), convertTo18(gemJoin, wad));

        // Exits token amount to the user's wallet as a token
        GemJoinLike(gemJoin).exit(msg.sender, wad);
    }

    function draw(
        address manager,
        address jug,
        address daiJoin,
        uint cdp,
        uint wad
    ) public {
        address urn = ManagerLike(manager).urns(cdp);
        address vat = ManagerLike(manager).vat();
        bytes32 ilk = ManagerLike(manager).ilks(cdp);
        // Generates debt in the CDP
        frob(manager, cdp, 0, _getDrawDart(vat, jug, urn, ilk, wad));
        // Moves the DAI amount (balance in the vat in rad) to proxy's address
        move(manager, cdp, address(this), toRad(wad));
        // Allows adapter to access to proxy's DAI balance in the vat
        if (VatLike(vat).can(address(this), address(daiJoin)) == 0) {
            VatLike(vat).hope(daiJoin);
        }
        // Exits DAI to the user's wallet as a token
        DaiJoinLike(daiJoin).exit(msg.sender, wad);

        emit CDPAction('draw', cdp, 0, wad);
    }

    function wipe(
        address manager,
        address daiJoin,
        uint cdp,
        uint wad
    ) public {
        address vat = ManagerLike(manager).vat();
        address urn = ManagerLike(manager).urns(cdp);
        bytes32 ilk = ManagerLike(manager).ilks(cdp);

        address own = ManagerLike(manager).owns(cdp);
        if (own == address(this) || ManagerLike(manager).cdpCan(own, cdp, address(this)) == 1) {
            // Joins DAI amount into the vat
            daiJoin_join(daiJoin, urn, wad);
            // Paybacks debt to the CDP
            frob(manager, cdp, 0, _getWipeDart(vat, VatLike(vat).dai(urn), urn, ilk));
        } else {
             // Joins DAI amount into the vat
            daiJoin_join(daiJoin, address(this), wad);
            // Paybacks debt to the CDP
            VatLike(vat).frob(
                ilk,
                urn,
                address(this),
                address(this),
                0,
                _getWipeDart(vat, wad * RAY, urn, ilk)
            );
        }

        emit CDPAction('wipe', cdp, 0, wad);
    }

    function wipeAll(
        address manager,
        address daiJoin,
        uint cdp
    ) public {
        address vat = ManagerLike(manager).vat();
        address urn = ManagerLike(manager).urns(cdp);
        bytes32 ilk = ManagerLike(manager).ilks(cdp);
        (, uint art) = VatLike(vat).urns(ilk, urn);

        address own = ManagerLike(manager).owns(cdp);
        if (own == address(this) || ManagerLike(manager).cdpCan(own, cdp, address(this)) == 1) {
            // Joins DAI amount into the vat
            daiJoin_join(daiJoin, urn, _getWipeAllWad(vat, urn, urn, ilk));
            // Paybacks debt to the CDP
            frob(manager, cdp, 0, -int(art));
        } else {
            // Joins DAI amount into the vat
            daiJoin_join(daiJoin, address(this), _getWipeAllWad(vat, address(this), urn, ilk));
            // Paybacks debt to the CDP
            VatLike(vat).frob(
                ilk,
                urn,
                address(this),
                address(this),
                0,
                -int(art)
            );
        }

        emit CDPAction('wipeAll', cdp, 0, art);
    }

    function lockETHAndDraw(
        address manager,
        address jug,
        address ethJoin,
        address daiJoin,
        uint cdp,
        uint wadD
    ) public payable {
        address urn = ManagerLike(manager).urns(cdp);
        address vat = ManagerLike(manager).vat();
        bytes32 ilk = ManagerLike(manager).ilks(cdp);
        // Receives ETH amount, converts it to WETH and joins it into the vat
        ethJoin_join(ethJoin, urn);
        // Locks WETH amount into the CDP and generates debt
        frob(manager, cdp, toInt(msg.value), _getDrawDart(vat, jug, urn, ilk, wadD));
        // Moves the DAI amount (balance in the vat in rad) to proxy's address
        move(manager, cdp, address(this), toRad(wadD));
        // Allows adapter to access to proxy's DAI balance in the vat
        if (VatLike(vat).can(address(this), address(daiJoin)) == 0) {
            VatLike(vat).hope(daiJoin);
        }
        // Exits DAI to the user's wallet as a token
        DaiJoinLike(daiJoin).exit(msg.sender, wadD);
    }

    function openLockETHAndDraw(
        address manager,
        address jug,
        address ethJoin,
        address daiJoin,
        bytes32 ilk,
        uint wadD
    ) public payable returns (uint cdp) {
        cdp = open(manager, ilk, address(this));
        lockETHAndDraw(manager, jug, ethJoin, daiJoin, cdp, wadD);

        emit CDPAction('openLockETHAndDraw', cdp, msg.value, wadD);
    }

    function lockGemAndDraw(
        address manager,
        address jug,
        address gemJoin,
        address daiJoin,
        uint cdp,
        uint wadC,
        uint wadD,
        bool transferFrom
    ) public {
        address urn = ManagerLike(manager).urns(cdp);
        address vat = ManagerLike(manager).vat();
        bytes32 ilk = ManagerLike(manager).ilks(cdp);
        // Takes token amount from user's wallet and joins into the vat
        gemJoin_join(gemJoin, urn, wadC, transferFrom);
        // Locks token amount into the CDP and generates debt
        frob(manager, cdp, toInt(convertTo18(gemJoin, wadC)), _getDrawDart(vat, jug, urn, ilk, wadD));
        // Moves the DAI amount (balance in the vat in rad) to proxy's address
        move(manager, cdp, address(this), toRad(wadD));
        // Allows adapter to access to proxy's DAI balance in the vat
        if (VatLike(vat).can(address(this), address(daiJoin)) == 0) {
            VatLike(vat).hope(daiJoin);
        }
        // Exits DAI to the user's wallet as a token
        DaiJoinLike(daiJoin).exit(msg.sender, wadD);

    }

    function openLockGemAndDraw(
        address manager,
        address jug,
        address gemJoin,
        address daiJoin,
        bytes32 ilk,
        uint wadC,
        uint wadD,
        bool transferFrom
    ) public returns (uint cdp) {
        cdp = open(manager, ilk, address(this));
        lockGemAndDraw(manager, jug, gemJoin, daiJoin, cdp, wadC, wadD, transferFrom);

        emit CDPAction('openLockGemAndDraw', cdp, wadC, wadD);

    }

    function wipeAllAndFreeETH(
        address manager,
        address ethJoin,
        address daiJoin,
        uint cdp,
        uint wadC
    ) public {
        address vat = ManagerLike(manager).vat();
        address urn = ManagerLike(manager).urns(cdp);
        bytes32 ilk = ManagerLike(manager).ilks(cdp);
        (, uint art) = VatLike(vat).urns(ilk, urn);

        // Joins DAI amount into the vat
        daiJoin_join(daiJoin, urn, _getWipeAllWad(vat, urn, urn, ilk));
        // Paybacks debt to the CDP and unlocks WETH amount from it
        frob(
            manager,
            cdp,
            -toInt(wadC),
            -int(art)
        );
        // Moves the amount from the CDP urn to proxy's address
        flux(manager, cdp, address(this), wadC);
        // Exits WETH amount to proxy address as a token
        GemJoinLike(ethJoin).exit(address(this), wadC);
        // Converts WETH to ETH
        GemJoinLike(ethJoin).gem().withdraw(wadC);
        // Sends ETH back to the user's wallet
        msg.sender.transfer(wadC);

        emit CDPAction('wipeAllAndFreeETH', cdp, wadC, art);
    }

    function wipeAndFreeGem(
        address manager,
        address gemJoin,
        address daiJoin,
        uint cdp,
        uint wadC,
        uint wadD
    ) public {
        address urn = ManagerLike(manager).urns(cdp);
        // Joins DAI amount into the vat
        daiJoin_join(daiJoin, urn, wadD);
        uint wad18 = convertTo18(gemJoin, wadC);
        // Paybacks debt to the CDP and unlocks token amount from it
        frob(
            manager,
            cdp,
            -toInt(wad18),
            _getWipeDart(ManagerLike(manager).vat(), VatLike(ManagerLike(manager).vat()).dai(urn), urn, ManagerLike(manager).ilks(cdp))
        );
        // Moves the amount from the CDP urn to proxy's address
        flux(manager, cdp, address(this), wad18);
        // Exits token amount to the user's wallet as a token
        GemJoinLike(gemJoin).exit(msg.sender, wadC);
    }

    function wipeAllAndFreeGem(
        address manager,
        address gemJoin,
        address daiJoin,
        uint cdp,
        uint wadC
    ) public {
        address vat = ManagerLike(manager).vat();
        address urn = ManagerLike(manager).urns(cdp);
        bytes32 ilk = ManagerLike(manager).ilks(cdp);
        (, uint art) = VatLike(vat).urns(ilk, urn);

        // Joins DAI amount into the vat
        daiJoin_join(daiJoin, urn, _getWipeAllWad(vat, urn, urn, ilk));
        uint wad18 = convertTo18(gemJoin, wadC);
        // Paybacks debt to the CDP and unlocks token amount from it
        frob(
            manager,
            cdp,
            -toInt(wad18),
            -int(art)
        );
        // Moves the amount from the CDP urn to proxy's address
        flux(manager, cdp, address(this), wad18);
        // Exits token amount to the user's wallet as a token
        GemJoinLike(gemJoin).exit(msg.sender, wadC);

        emit CDPAction('wipeAllAndFreeGem', cdp, wadC, art);
    }

    function createProxyAndCDP(
        address manager,
        address jug,
        address ethJoin,
        address daiJoin,
        bytes32 ilk,
        uint wadD,
        address registry
        ) public payable returns(uint) {

            address proxy = ProxyRegistryInterface(registry).build(msg.sender);

            uint cdp = openLockETHAndDraw(manager,
                jug,
                ethJoin,
                daiJoin,
                ilk,
                wadD
                );

            give(manager, cdp, address(proxy));

            return cdp;

    }

    function createProxyAndGemCDP(
        address manager,
        address jug,
        address gemJoin,
        address daiJoin,
        bytes32 ilk,
        uint wadC,
        uint wadD,
        bool transferFrom,
        address registry
        ) public returns(uint) {


            address proxy = ProxyRegistryInterface(registry).build(msg.sender);

            uint cdp = openLockGemAndDraw(manager,
                jug,
                gemJoin,
                daiJoin,
                ilk,
                wadC,
                wadD,
                transferFrom);

            give(manager, cdp, address(proxy));

            return cdp;
    }
}
