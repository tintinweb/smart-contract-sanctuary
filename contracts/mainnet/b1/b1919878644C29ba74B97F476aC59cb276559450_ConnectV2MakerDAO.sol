pragma solidity ^0.7.0;

/**
 * @title MakerDAO.
 * @dev Collateralized Borrowing.
 */

import { TokenInterface, AccountInterface } from "../../common/interfaces.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";
import { VatLike, TokenJoinInterface } from "./interface.sol";

abstract contract MakerResolver is Helpers, Events {
    /**
     * @dev Open Vault
     * @notice Open a MakerDAO Vault
     * @param colType Type of Collateral.(eg: 'ETH-A')
    */
    function open(string calldata colType) external payable returns (string memory _eventName, bytes memory _eventParam) {
        bytes32 ilk = stringToBytes32(colType);
        require(instaMapping.gemJoinMapping(ilk) != address(0), "wrong-col-type");
        uint256 vault = managerContract.open(ilk, address(this));

        _eventName = "LogOpen(uint256,bytes32)";
        _eventParam = abi.encode(vault, ilk);
    }

    /**
     * @dev Close Vault
     * @notice Close a MakerDAO Vault
     * @param vault Vault ID to close.
    */
    function close(uint256 vault) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _vault = getVault(vault);
        (bytes32 ilk, address urn) = getVaultData(_vault);
        (uint ink, uint art) = VatLike(managerContract.vat()).urns(ilk, urn);

        require(ink == 0 && art == 0, "vault-has-assets");
        require(managerContract.owns(_vault) == address(this), "not-owner");

        managerContract.give(_vault, giveAddr);

        _eventName = "LogClose(uint256,bytes32)";
        _eventParam = abi.encode(_vault, ilk);
    }

    /**
     * @dev Transfer Vault
     * @notice Transfer a MakerDAO Vault to "nextOwner"
     * @param vault Vault ID to close.
     * @param nextOwner Address of the next owner of the vault.
    */
    function transfer(
        uint vault,
        address nextOwner
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        require(AccountInterface(address(this)).isAuth(nextOwner), "nextOwner-is-not-auth");

        uint256 _vault = getVault(vault);
        (bytes32 ilk,) = getVaultData(_vault);

        require(managerContract.owns(_vault) == address(this), "not-owner");

        managerContract.give(_vault, nextOwner);

        _eventName = "LogTransfer(uint256,bytes32,address)";
        _eventParam = abi.encode(_vault, ilk, nextOwner);
    }

    /**
     * @dev Deposit ETH/ERC20_Token Collateral.
     * @notice Deposit collateral to a MakerDAO vault
     * @param vault Vault ID. (Use 0 for last opened vault)
     * @param amt The amount of tokens to deposit. (For max: `uint256(-1)`)
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of tokens deposited.
    */
    function deposit(
        uint256 vault,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);
        uint _vault = getVault(vault);
        (bytes32 ilk, address urn) = getVaultData(_vault);

        address colAddr = instaMapping.gemJoinMapping(ilk);
        TokenJoinInterface tokenJoinContract = TokenJoinInterface(colAddr);
        TokenInterface tokenContract = tokenJoinContract.gem();

        if (isEth(address(tokenContract))) {
            _amt = _amt == uint(-1) ? address(this).balance : _amt;
            tokenContract.deposit{value: _amt}();
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

        setUint(setId, _amt);

        _eventName = "LogDeposit(uint256,bytes32,uint256,uint256,uint256)";
        _eventParam = abi.encode(_vault, ilk, _amt, getId, setId);
    }

    /**
     * @dev Withdraw ETH/ERC20_Token Collateral.
     * @notice Withdraw collateral from a MakerDAO vault
     * @param vault Vault ID. (Use 0 for last opened vault)
     * @param amt The amount of tokens to withdraw. (For max: `uint256(-1)`)
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of tokens withdrawn.
    */
    function withdraw(
        uint256 vault,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);
        uint _vault = getVault(vault);
        (bytes32 ilk, address urn) = getVaultData(_vault);

        address colAddr = instaMapping.gemJoinMapping(ilk);
        TokenJoinInterface tokenJoinContract = TokenJoinInterface(colAddr);

        uint _amt18;
        if (_amt == uint(-1)) {
            (_amt18,) = VatLike(managerContract.vat()).urns(ilk, urn);
            _amt = convert18ToDec(tokenJoinContract.dec(), _amt18);
        } else {
            _amt18 = convertTo18(tokenJoinContract.dec(), _amt);
        }

        managerContract.frob(
            _vault,
            -toInt(_amt18),
            0
        );

        managerContract.flux(
            _vault,
            address(this),
            _amt18
        );

        TokenInterface tokenContract = tokenJoinContract.gem();

        if (isEth(address(tokenContract))) {
            tokenJoinContract.exit(address(this), _amt);
            tokenContract.withdraw(_amt);
        } else {
            tokenJoinContract.exit(address(this), _amt);
        }

        setUint(setId, _amt);

        _eventName = "LogWithdraw(uint256,bytes32,uint256,uint256,uint256)";
        _eventParam = abi.encode(_vault, ilk, _amt, getId, setId);
    }

    /**
     * @dev Borrow DAI.
     * @notice Borrow DAI using a MakerDAO vault
     * @param vault Vault ID. (Use 0 for last opened vault)
     * @param amt The amount of DAI to borrow.
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of DAI borrowed.
    */
    function borrow(
        uint256 vault,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);
        uint _vault = getVault(vault);
        (bytes32 ilk, address urn) = getVaultData(_vault);

        VatLike vatContract = VatLike(managerContract.vat());

        managerContract.frob(
            _vault,
            0,
            _getBorrowAmt(
                address(vatContract),
                urn,
                ilk,
                _amt
            )
        );

        managerContract.move(
            _vault,
            address(this),
            toRad(_amt)
        );

        if (vatContract.can(address(this), address(daiJoinContract)) == 0) {
            vatContract.hope(address(daiJoinContract));
        }

        daiJoinContract.exit(address(this), _amt);

        setUint(setId, _amt);

        _eventName = "LogBorrow(uint256,bytes32,uint256,uint256,uint256)";
        _eventParam = abi.encode(_vault, ilk, _amt, getId, setId);
    }

    /**
     * @dev Payback borrowed DAI.
     * @notice Payback DAI debt owed by a MakerDAO vault
     * @param vault Vault ID. (Use 0 for last opened vault)
     * @param amt The amount of DAI to payback. (For max: `uint256(-1)`)
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of DAI paid back.
    */
    function payback(
        uint256 vault,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);
        uint _vault = getVault(vault);
        (bytes32 ilk, address urn) = getVaultData(_vault);

        address vat = managerContract.vat();

        uint _maxDebt = _getVaultDebt(vat, ilk, urn);

        _amt = _amt == uint(-1) ? _maxDebt : _amt;

        require(_maxDebt >= _amt, "paying-excess-debt");

        daiJoinContract.dai().approve(address(daiJoinContract), _amt);
        daiJoinContract.join(urn, _amt);

        managerContract.frob(
            _vault,
            0,
            _getWipeAmt(
                vat,
                VatLike(vat).dai(urn),
                urn,
                ilk
            )
        );

        setUint(setId, _amt);

        _eventName = "LogPayback(uint256,bytes32,uint256,uint256,uint256)";
        _eventParam = abi.encode(_vault, ilk, _amt, getId, setId);
    }

    /**
     * @dev Withdraw leftover ETH/ERC20_Token after Liquidation.
     * @notice Withdraw leftover collateral after Liquidation.
     * @param vault Vault ID. (Use 0 for last opened vault)
     * @param amt token amount to Withdraw. (For max: `uint256(-1)`)
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of collateral withdrawn.
    */
    function withdrawLiquidated(
        uint256 vault,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);
        (bytes32 ilk, address urn) = getVaultData(vault);

        address colAddr = instaMapping.gemJoinMapping(ilk);
        TokenJoinInterface tokenJoinContract = TokenJoinInterface(colAddr);

        uint _amt18;
        if (_amt == uint(-1)) {
            _amt18 = VatLike(managerContract.vat()).gem(ilk, urn);
            _amt = convert18ToDec(tokenJoinContract.dec(), _amt18);
        } else {
            _amt18 = convertTo18(tokenJoinContract.dec(), _amt);
        }

        managerContract.flux(
            vault,
            address(this),
            _amt18
        );

        TokenInterface tokenContract = tokenJoinContract.gem();
        tokenJoinContract.exit(address(this), _amt);
        if (isEth(address(tokenContract))) {
            tokenContract.withdraw(_amt);
        }

        setUint(setId, _amt);

        _eventName = "LogWithdrawLiquidated(uint256,bytes32,uint256,uint256,uint256)";
        _eventParam = abi.encode(vault, ilk, _amt, getId, setId);
    }

    struct MakerData {
        uint _vault;
        address colAddr;
        TokenJoinInterface tokenJoinContract;
        VatLike vatContract;
        TokenInterface tokenContract;
    }
    /**
     * @dev Deposit ETH/ERC20_Token Collateral and Borrow DAI.
     * @notice Deposit collateral and borrow DAI.
     * @param vault Vault ID. (Use 0 for last opened vault)
     * @param depositAmt The amount of tokens to deposit. (For max: `uint256(-1)`)
     * @param borrowAmt The amount of DAI to borrow.
     * @param getIdDeposit ID to retrieve depositAmt.
     * @param getIdBorrow ID to retrieve borrowAmt.
     * @param setIdDeposit ID stores the amount of tokens deposited.
     * @param setIdBorrow ID stores the amount of DAI borrowed.
    */
    function depositAndBorrow(
        uint256 vault,
        uint256 depositAmt,
        uint256 borrowAmt,
        uint256 getIdDeposit,
        uint256 getIdBorrow,
        uint256 setIdDeposit,
        uint256 setIdBorrow
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        MakerData memory makerData;
        uint _amtDeposit = getUint(getIdDeposit, depositAmt);
        uint _amtBorrow = getUint(getIdBorrow, borrowAmt);

        makerData._vault = getVault(vault);
        (bytes32 ilk, address urn) = getVaultData(makerData._vault);

        makerData.colAddr = instaMapping.gemJoinMapping(ilk);
        makerData.tokenJoinContract = TokenJoinInterface(makerData.colAddr);
        makerData.vatContract = VatLike(managerContract.vat());
        makerData.tokenContract = makerData.tokenJoinContract.gem();

        if (isEth(address(makerData.tokenContract))) {
            _amtDeposit = _amtDeposit == uint(-1) ? address(this).balance : _amtDeposit;
            makerData.tokenContract.deposit{value: _amtDeposit}();
        } else {
            _amtDeposit = _amtDeposit == uint(-1) ?  makerData.tokenContract.balanceOf(address(this)) : _amtDeposit;
        }

        makerData.tokenContract.approve(address(makerData.colAddr), _amtDeposit);
        makerData.tokenJoinContract.join(urn, _amtDeposit);

        managerContract.frob(
            makerData._vault,
            toInt(convertTo18(makerData.tokenJoinContract.dec(), _amtDeposit)),
            _getBorrowAmt(
                address(makerData.vatContract),
                urn,
                ilk,
                _amtBorrow
            )
        );

        managerContract.move(
            makerData._vault,
            address(this),
            toRad(_amtBorrow)
        );

        if (makerData.vatContract.can(address(this), address(daiJoinContract)) == 0) {
            makerData.vatContract.hope(address(daiJoinContract));
        }

        daiJoinContract.exit(address(this), _amtBorrow);

        setUint(setIdDeposit, _amtDeposit);
        setUint(setIdBorrow, _amtBorrow);

        _eventName = "LogDepositAndBorrow(uint256,bytes32,uint256,uint256,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(
            makerData._vault,
            ilk,
            _amtDeposit,
            _amtBorrow,
            getIdDeposit,
            getIdBorrow,
            setIdDeposit,
            setIdBorrow
        );
    }

    /**
     * @dev Exit DAI from urn.
     * @notice Exit DAI from urn.
     * @param vault Vault ID. (Use 0 for last opened vault)
     * @param amt The amount of DAI to exit. (For max: `uint256(-1)`)
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of DAI exited.
    */
    function exitDai(
        uint256 vault,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);
        uint _vault = getVault(vault);
        (bytes32 ilk, address urn) = getVaultData(_vault);

        VatLike vatContract = VatLike(managerContract.vat());
        if(_amt == uint(-1)) {
            _amt = vatContract.dai(urn);
            _amt = _amt / 10 ** 27;
        }

        managerContract.move(
            _vault,
            address(this),
            toRad(_amt)
        );

        if (vatContract.can(address(this), address(daiJoinContract)) == 0) {
            vatContract.hope(address(daiJoinContract));
        }

        daiJoinContract.exit(address(this), _amt);

        setUint(setId, _amt);

        _eventName = "LogExitDai(uint256,bytes32,uint256,uint256,uint256)";
        _eventParam = abi.encode(_vault, ilk, _amt, getId, setId);
    }

    /**
     * @dev Deposit DAI in DSR.
     * @notice Deposit DAI in DSR.
     * @param amt The amount of DAI to deposit. (For max: `uint256(-1)`)
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of DAI deposited.
    */
    function depositDai(
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);

        _amt = _amt == uint(-1) ?
            daiJoinContract.dai().balanceOf(address(this)) :
            _amt;

        VatLike vat = daiJoinContract.vat();
        uint chi = potContract.drip();

        daiJoinContract.dai().approve(address(daiJoinContract), _amt);
        daiJoinContract.join(address(this), _amt);
        if (vat.can(address(this), address(potContract)) == 0) {
            vat.hope(address(potContract));
        }

        potContract.join(mul(_amt, RAY) / chi);
        setUint(setId, _amt);

        _eventName = "LogDepositDai(uint256,uint256,uint256)";
        _eventParam = abi.encode(_amt, getId, setId);
    }

    /**
     * @dev Withdraw DAI from DSR.
     * @notice Withdraw DAI from DSR.
     * @param amt The amount of DAI to withdraw. (For max: `uint256(-1)`)
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of DAI withdrawn.
    */
    function withdrawDai(
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);

        VatLike vat = daiJoinContract.vat();

        uint chi = potContract.drip();
        uint pie;
        if (_amt == uint(-1)) {
            pie = potContract.pie(address(this));
            _amt = mul(chi, pie) / RAY;
        } else {
            pie = mul(_amt, RAY) / chi;
        }

        potContract.exit(pie);

        uint bal = vat.dai(address(this));
        if (vat.can(address(this), address(daiJoinContract)) == 0) {
            vat.hope(address(daiJoinContract));
        }
        daiJoinContract.exit(
            address(this),
            bal >= mul(_amt, RAY) ? _amt : bal / RAY
        );

        setUint(setId, _amt);

        _eventName = "LogWithdrawDai(uint256,uint256,uint256)";
        _eventParam = abi.encode(_amt, getId, setId);
    }
}

contract ConnectV2MakerDAO is MakerResolver {
    string public constant name = "MakerDAO-v1.1";
}

pragma solidity ^0.7.0;

interface TokenInterface {
    function approve(address, uint256) external;
    function transfer(address, uint) external;
    function transferFrom(address, address, uint) external;
    function deposit() external payable;
    function withdraw(uint) external;
    function balanceOf(address) external view returns (uint);
    function decimals() external view returns (uint);
}

interface MemoryInterface {
    function getUint(uint id) external returns (uint num);
    function setUint(uint id, uint val) external;
}

interface InstaMapping {
    function cTokenMapping(address) external view returns (address);
    function gemJoinMapping(bytes32) external view returns (address);
}

interface AccountInterface {
    function enable(address) external;
    function disable(address) external;
    function isAuth(address) external view returns (bool);
}

pragma solidity ^0.7.0;

import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";
import { TokenInterface } from "../../common/interfaces.sol";
import { ManagerLike, DaiJoinInterface, PotLike, VatLike, JugLike } from "./interface.sol";

abstract contract Helpers is DSMath, Basic {
    /**
     * @dev Manager Interface
     */
    ManagerLike internal constant managerContract = ManagerLike(0x5ef30b9986345249bc32d8928B7ee64DE9435E39);

    /**
     * @dev DAI Join
     */
    DaiJoinInterface internal constant daiJoinContract = DaiJoinInterface(0x9759A6Ac90977b93B58547b4A71c78317f391A28);

    /**
     * @dev Pot
     */
    PotLike internal constant potContract = PotLike(0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7);

    /**
     * @dev Maker MCD Jug Address.
    */
    JugLike internal constant mcdJug = JugLike(0x19c0976f590D67707E62397C87829d896Dc0f1F1);

    /**
     * @dev Return Close Vault Address.
    */
    address internal constant giveAddr = 0x4dD58550eb15190a5B3DfAE28BB14EeC181fC267;

    /**
     * @dev Get Vault's ilk.
    */
    function getVaultData(uint vault) internal view returns (bytes32 ilk, address urn) {
        ilk = managerContract.ilks(vault);
        urn = managerContract.urns(vault);
    }

    /**
     * @dev Gem Join address is ETH type collateral.
    */
    function isEth(address tknAddr) internal pure returns (bool) {
        return tknAddr == ethAddr ? true : false;
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
        uint rate = mcdJug.drip(ilk);
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

    /**
     * @dev Convert String to bytes32.
    */
    function stringToBytes32(string memory str) internal pure returns (bytes32 result) {
        require(bytes(str).length != 0, "string-empty");
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            result := mload(add(str, 32))
        }
    }

    /**
     * @dev Get vault ID. If `vault` is 0, get last opened vault.
    */
    function getVault(uint vault) internal view returns (uint _vault) {
        if (vault == 0) {
            require(managerContract.count(address(this)) > 0, "no-vault-opened");
            _vault = managerContract.last(address(this));
        } else {
            _vault = vault;
        }
    }

}

pragma solidity ^0.7.0;

contract Events {
    event LogOpen(uint256 indexed vault, bytes32 indexed ilk);
    event LogClose(uint256 indexed vault, bytes32 indexed ilk);
    event LogTransfer(uint256 indexed vault, bytes32 indexed ilk, address newOwner);
    event LogDeposit(uint256 indexed vault, bytes32 indexed ilk, uint256 tokenAmt, uint256 getId, uint256 setId);
    event LogWithdraw(uint256 indexed vault, bytes32 indexed ilk, uint256 tokenAmt, uint256 getId, uint256 setId);
    event LogBorrow(uint256 indexed vault, bytes32 indexed ilk, uint256 tokenAmt, uint256 getId, uint256 setId);
    event LogPayback(uint256 indexed vault, bytes32 indexed ilk, uint256 tokenAmt, uint256 getId, uint256 setId);
    event LogWithdrawLiquidated(uint256 indexed vault, bytes32 indexed ilk, uint256 tokenAmt, uint256 getId, uint256 setId);
    event LogExitDai(uint256 indexed vault, bytes32 indexed ilk, uint256 tokenAmt, uint256 getId, uint256 setId);
    event LogDepositDai(uint256 tokenAmt, uint256 getId, uint256 setId);
    event LogWithdrawDai(uint256 tokenAmt, uint256 getId, uint256 setId);

    event LogDepositAndBorrow(
        uint256 indexed vault,
        bytes32 indexed ilk,
        uint256 depositAmt,
        uint256 borrowAmt,
        uint256 getIdDeposit,
        uint256 getIdBorrow,
        uint256 setIdDeposit,
        uint256 setIdBorrow
    );
}

pragma solidity ^0.7.0;

import { TokenInterface } from "../../common/interfaces.sol";

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

pragma solidity ^0.7.0;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

contract DSMath {
  uint constant WAD = 10 ** 18;
  uint constant RAY = 10 ** 27;

  function add(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(x, y);
  }

  function sub(uint x, uint y) internal virtual pure returns (uint z) {
    z = SafeMath.sub(x, y);
  }

  function mul(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.mul(x, y);
  }

  function div(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.div(x, y);
  }

  function wmul(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(SafeMath.mul(x, y), WAD / 2) / WAD;
  }

  function wdiv(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(SafeMath.mul(x, WAD), y / 2) / y;
  }

  function rdiv(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(SafeMath.mul(x, RAY), y / 2) / y;
  }

  function rmul(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(SafeMath.mul(x, y), RAY / 2) / RAY;
  }

  function toInt(uint x) internal pure returns (int y) {
    y = int(x);
    require(y >= 0, "int-overflow");
  }

  function toRad(uint wad) internal pure returns (uint rad) {
    rad = mul(wad, 10 ** 27);
  }

}

pragma solidity ^0.7.0;

import { TokenInterface } from "./interfaces.sol";
import { Stores } from "./stores.sol";
import { DSMath } from "./math.sol";

abstract contract Basic is DSMath, Stores {

    function convert18ToDec(uint _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = (_amt / 10 ** (18 - _dec));
    }

    function convertTo18(uint _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = mul(_amt, 10 ** (18 - _dec));
    }

    function getTokenBal(TokenInterface token) internal view returns(uint _amt) {
        _amt = address(token) == ethAddr ? address(this).balance : token.balanceOf(address(this));
    }

    function getTokensDec(TokenInterface buyAddr, TokenInterface sellAddr) internal view returns(uint buyDec, uint sellDec) {
        buyDec = address(buyAddr) == ethAddr ?  18 : buyAddr.decimals();
        sellDec = address(sellAddr) == ethAddr ?  18 : sellAddr.decimals();
    }

    function encodeEvent(string memory eventName, bytes memory eventParam) internal pure returns (bytes memory) {
        return abi.encode(eventName, eventParam);
    }

    function changeEthAddress(address buy, address sell) internal pure returns(TokenInterface _buy, TokenInterface _sell){
        _buy = buy == ethAddr ? TokenInterface(wethAddr) : TokenInterface(buy);
        _sell = sell == ethAddr ? TokenInterface(wethAddr) : TokenInterface(sell);
    }

    function convertEthToWeth(bool isEth, TokenInterface token, uint amount) internal {
        if(isEth) token.deposit{value: amount}();
    }

    function convertWethToEth(bool isEth, TokenInterface token, uint amount) internal {
       if(isEth) {
            token.approve(address(token), amount);
            token.withdraw(amount);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.7.0;

import { MemoryInterface, InstaMapping } from "./interfaces.sol";


abstract contract Stores {

  /**
   * @dev Return ethereum address
   */
  address constant internal ethAddr = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  /**
   * @dev Return Wrapped ETH address
   */
  address constant internal wethAddr = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  /**
   * @dev Return memory variable address
   */
  MemoryInterface constant internal instaMemory = MemoryInterface(0x8a5419CfC711B2343c17a6ABf4B2bAFaBb06957F);

  /**
   * @dev Return InstaDApp Mapping Addresses
   */
  InstaMapping constant internal instaMapping = InstaMapping(0xe81F70Cc7C0D46e12d70efc60607F16bbD617E88);

  /**
   * @dev Get Uint value from InstaMemory Contract.
   */
  function getUint(uint getId, uint val) internal returns (uint returnVal) {
    returnVal = getId == 0 ? val : instaMemory.getUint(getId);
  }

  /**
  * @dev Set Uint value in InstaMemory Contract.
  */
  function setUint(uint setId, uint val) virtual internal {
    if (setId != 0) instaMemory.setUint(setId, val);
  }

}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}