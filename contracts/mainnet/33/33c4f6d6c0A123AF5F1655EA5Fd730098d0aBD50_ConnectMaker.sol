pragma solidity ^0.6.0;

interface TokenInterface {
    function approve(address, uint) external;
    function transfer(address, uint) external;
    function transferFrom(address, address, uint) external;
    function deposit() external payable;
    function withdraw(uint) external;
    function balanceOf(address) external view returns (uint);
}

interface ManagerLike {
    function cdpCan(address, uint, address) external view returns (uint);
    function ilks(uint) external view returns (bytes32);
    function last(address) external view returns (uint);
    function count(address) external view returns (uint);
    function owns(uint) external view returns (address);
    function urns(uint) external view returns (address);
    function vat() external view returns (address);
    function open(bytes32, address) external returns (uint);
    function give(uint, address) external;
    function frob(uint, int, int) external;
    function flux(uint, address, uint) external;
    function move(uint, address, uint) external;
}

interface VatLike {
    function can(address, address) external view returns (uint);
    function ilks(bytes32) external view returns (uint, uint, uint, uint, uint);
    function dai(address) external view returns (uint);
    function urns(bytes32, address) external view returns (uint, uint);
    function frob(
        bytes32,
        address,
        address,
        address,
        int,
        int
    ) external;
    function hope(address) external;
    function move(address, address, uint) external;
    function gem(bytes32, address) external view returns (uint);

}

interface TokenJoinInterface {
    function dec() external returns (uint);
    function gem() external returns (TokenInterface);
    function join(address, uint) external payable;
    function exit(address, uint) external;
}

interface DaiJoinInterface {
    function vat() external returns (VatLike);
    function dai() external returns (TokenInterface);
    function join(address, uint) external payable;
    function exit(address, uint) external;
}

interface JugLike {
    function drip(bytes32) external returns (uint);
}

interface PotLike {
    function pie(address) external view returns (uint);
    function drip() external returns (uint);
    function join(uint) external;
    function exit(uint) external;
}

interface InstaMapping {
    function gemJoinMapping(bytes32) external view returns (address);
}

contract DSMath {

    uint256 constant RAY = 10 ** 27;
    uint constant WAD = 10 ** 18;

    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "math-not-safe");
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "sub-overflow");
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "math-not-safe");
    }

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

    function toInt(uint x) internal pure returns (int y) {
        y = int(x);
        require(y >= 0, "int-overflow");
    }

    function toRad(uint wad) internal pure returns (uint rad) {
        rad = mul(wad, 10 ** 27);
    }

    function convertTo18(uint _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = mul(_amt, 10 ** (18 - _dec));
    }

    function convert18ToDec(uint _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = (_amt / 10 ** (18 - _dec));
    }
}


contract Helpers is DSMath {
    /**
     * @dev Return ethereum address
     */
    function getAddressETH() internal pure returns (address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE; // ETH Address
    }

    function getAddressWETH() internal pure returns (address) {
        return 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // mainnet
        // return 0xd0A1E359811322d97991E03f863a0C30C2cF029C; // kovan
    }

    function isETH(address token) internal pure returns(bool) {
        return token == getAddressETH() || token == getAddressWETH();
    }
}


contract MakerMCDAddresses is Helpers {
    /**
     * @dev Return Maker MCD Manager Address.
    */
    function getMcdManager() internal pure returns (address) {
        return 0x5ef30b9986345249bc32d8928B7ee64DE9435E39; //mainnet
        // return 0x1476483dD8C35F25e568113C5f70249D3976ba21; // kovan
    }

    /**
     * @dev Return Maker MCD DAI_Join Address.
    */
    function getMcdDaiJoin() internal pure returns (address) {
        return 0x9759A6Ac90977b93B58547b4A71c78317f391A28; // mainnet
        // return 0x5AA71a3ae1C0bd6ac27A1f28e1415fFFB6F15B8c; // kovan
    }

    /**
     * @dev Return Maker MCD Jug Address.
    */
    function getMcdJug() internal pure returns (address) {
        return 0x19c0976f590D67707E62397C87829d896Dc0f1F1; // mainnet
        // return 0xcbB7718c9F39d05aEEDE1c472ca8Bf804b2f1EaD; // kovan
    }
}

contract MakerHelpers is MakerMCDAddresses {
    /**
     * @dev Return InstaMapping Address.
     */
    function getMappingAddr() internal pure returns (address) {
        return 0xe81F70Cc7C0D46e12d70efc60607F16bbD617E88;
    }

    /**
     * @dev Get Vault's ilk.
    */
    function getVaultData(ManagerLike managerContract, uint vault) internal view returns (bytes32 ilk, address urn) {
        ilk = managerContract.ilks(vault);
        urn = managerContract.urns(vault);
    }

    /**
     * @dev Gem Join address is ETH type collateral.
    */
    function isGemEth(address tknAddr) internal pure returns (bool) {
        return tknAddr == getAddressWETH();
    }

    /**
     * @dev Get Vault Debt Amount.
    */
    function _getVaultDebt(
        address vat,
        bytes32 ilk,
        address urn
    ) internal view returns (uint wad) {
        (, uint rate,,,) = VatLike(vat).ilks(ilk);
        (, uint art) = VatLike(vat).urns(ilk, urn);
        uint dai = VatLike(vat).dai(urn);

        uint rad = sub(mul(art, rate), dai);
        wad = rad / RAY;

        wad = mul(wad, RAY) < rad ? wad + 1 : wad;
    }

    /**
     * @dev Get Borrow Amount.
    */
    function _getBorrowAmt(
        address vat,
        address urn,
        bytes32 ilk,
        uint amt
    ) internal returns (int dart)
    {
        address jug = getMcdJug();
        uint rate = JugLike(jug).drip(ilk);
        uint dai = VatLike(vat).dai(urn);
        if (dai < mul(amt, RAY)) {
            dart = toInt(sub(mul(amt, RAY), dai) / rate);
            dart = mul(uint(dart), rate) < mul(amt, RAY) ? dart + 1 : dart;
        }
    }

    /**
     * @dev Get Payback Amount.
    */
    function _getWipeAmt(
        address vat,
        uint amt,
        address urn,
        bytes32 ilk
    ) internal view returns (int dart)
    {
        (, uint rate,,,) = VatLike(vat).ilks(ilk);
        (, uint art) = VatLike(vat).urns(ilk, urn);
        dart = toInt(amt / rate);
        dart = uint(dart) <= art ? - dart : - toInt(art);
    }

}

contract BasicResolver is MakerHelpers {
    event LogDeposit(uint256 indexed vault, bytes32 indexed ilk, uint256 tokenAmt);
    event LogWithdraw(uint256 indexed vault, bytes32 indexed ilk, uint256 tokenAmt);
    event LogBorrow(uint256 indexed vault, bytes32 indexed ilk, uint256 tokenAmt);
    event LogPayback(uint256 indexed vault, bytes32 indexed ilk, uint256 tokenAmt);

    /**
     * @dev Deposit ETH/ERC20_Token Collateral.
     * @param vault Vault ID.
     * @param amt token amount to deposit.
    */
    function deposit(uint vault, uint amt) external payable
    {
        ManagerLike managerContract = ManagerLike(getMcdManager());

        uint _amt = amt;
        (bytes32 ilk, address urn) = getVaultData(managerContract, vault);

        address colAddr = InstaMapping(getMappingAddr()).gemJoinMapping(ilk);
        TokenJoinInterface tokenJoinContract = TokenJoinInterface(colAddr);
        TokenInterface tokenContract = tokenJoinContract.gem();

        if (isGemEth(address(tokenContract))) {
            _amt = _amt == uint(-1) ? address(this).balance : _amt;
            tokenContract.deposit.value(_amt)();
        } else {
            _amt = _amt == uint(-1) ?  tokenContract.balanceOf(address(this)) : _amt;
        }

        tokenContract.approve(address(colAddr), _amt);
        tokenJoinContract.join(address(this), _amt);

        VatLike(managerContract.vat()).frob(
            ilk,
            urn,
            address(this),
            address(this),
            toInt(convertTo18(tokenJoinContract.dec(), _amt)),
            0
        );

        emit LogDeposit(vault, ilk, _amt);

    }

    /**
     * @dev Withdraw ETH/ERC20_Token Collateral.
     * @param vault Vault ID.
     * @param amt token amount to withdraw.
    */
    function withdraw(uint vault, uint amt) external payable {
        ManagerLike managerContract = ManagerLike(getMcdManager());

        uint _amt = amt;
        (bytes32 ilk, address urn) = getVaultData(managerContract, vault);

        address colAddr = InstaMapping(getMappingAddr()).gemJoinMapping(ilk);
        TokenJoinInterface tokenJoinContract = TokenJoinInterface(colAddr);

        uint _amt18;
        if (_amt == uint(-1)) {
            (_amt18,) = VatLike(managerContract.vat()).urns(ilk, urn);
            _amt = convert18ToDec(tokenJoinContract.dec(), _amt18);
        } else {
            _amt18 = convertTo18(tokenJoinContract.dec(), _amt);
        }

        managerContract.frob(
            vault,
            -toInt(_amt18),
            0
        );

        managerContract.flux(
            vault,
            address(this),
            _amt18
        );

        TokenInterface tokenContract = tokenJoinContract.gem();

        if (isGemEth(address(tokenContract))) {
            tokenJoinContract.exit(address(this), _amt);
            tokenContract.withdraw(_amt);
        } else {
            tokenJoinContract.exit(address(this), _amt);
        }

        

        emit LogWithdraw(vault, ilk, _amt);
    }

    /**
     * @dev Borrow DAI.
     * @param vault Vault ID.
     * @param amt token amount to borrow.
    */
    function borrow(uint vault, uint amt) external payable {
        ManagerLike managerContract = ManagerLike(getMcdManager());

        uint _amt = amt;
        (bytes32 ilk, address urn) = getVaultData(managerContract, vault);

        address daiJoin = getMcdDaiJoin();

        VatLike vatContract = VatLike(managerContract.vat());

        managerContract.frob(
            vault,
            0,
            _getBorrowAmt(
                address(vatContract),
                urn,
                ilk,
                _amt
            )
        );

        managerContract.move(
            vault,
            address(this),
            toRad(_amt)
        );

        if (vatContract.can(address(this), address(daiJoin)) == 0) {
            vatContract.hope(daiJoin);
        }

        DaiJoinInterface(daiJoin).exit(address(this), _amt);

        emit LogBorrow(vault, ilk, _amt);

    }

    /**
     * @dev Payback borrowed DAI.
     * @param vault Vault ID.
     * @param amt token amount to payback.
    */
    function payback(uint vault, uint amt) external payable {
        ManagerLike managerContract = ManagerLike(getMcdManager());
        uint _amt = amt;
        (bytes32 ilk, address urn) = getVaultData(managerContract, vault);

        address vat = managerContract.vat();

        uint _maxDebt = _getVaultDebt(vat, ilk, urn);

        _amt = _amt == uint(-1) ? _maxDebt : _amt;

        require(_maxDebt >= _amt, "paying-excess-debt");

        DaiJoinInterface daiJoinContract = DaiJoinInterface(getMcdDaiJoin());
        daiJoinContract.dai().approve(getMcdDaiJoin(), _amt);
        daiJoinContract.join(urn, _amt);

        managerContract.frob(
            vault,
            0,
            _getWipeAmt(
                vat,
                VatLike(vat).dai(urn),
                urn,
                ilk
            )
        );

        emit LogPayback(vault, ilk, _amt);
    }
}

contract ConnectMaker is  BasicResolver {
    string public constant name = "Flashloan-MakerDao-v1.0";
}