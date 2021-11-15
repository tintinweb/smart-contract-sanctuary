pragma solidity ^0.7.0;

/**
 * @title Reflexer.
 * @dev Collateralized Borrowing.
 */

import { TokenInterface } from "../../common/interfaces.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";
import { SafeEngineLike, TokenJoinInterface } from "./interface.sol";

abstract contract GebResolver is Helpers, Events {
    /**
     * @dev Open Safe
     * @notice Open a Reflexer Safe.
     * @param colType Type of Collateral.(eg: 'ETH-A')
    */
    function open(string calldata colType) external payable returns (string memory _eventName, bytes memory _eventParam) {
        bytes32 collateralType = stringToBytes32(colType);
        require(getCollateralJoinAddress(collateralType) != address(0), "wrong-col-type");
        uint256 safe = managerContract.openSAFE(collateralType, address(this));

        _eventName = "LogOpen(uint256,bytes32)";
        _eventParam = abi.encode(safe, collateralType);
    }

    /**
     * @dev Close Safe
     * @notice Close a Reflexer Safe.
     * @param safe Safe ID to close.
    */
    function close(uint256 safe) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _safe = getSafe(safe);
        (bytes32 collateralType, address handler) = getSafeData(_safe);
        (uint collateral, uint debt) = SafeEngineLike(managerContract.safeEngine()).safes(collateralType, handler);

        require(collateral == 0 && debt == 0, "safe-has-assets");
        require(managerContract.ownsSAFE(_safe) == address(this), "not-owner");

        managerContract.transferSAFEOwnership(_safe, giveAddr);

        _eventName = "LogClose(uint256,bytes32)";
        _eventParam = abi.encode(_safe, collateralType);
    }

    /**
     * @dev Deposit ETH/ERC20_Token Collateral.
     * @notice Deposit collateral to a Reflexer safe
     * @param safe Safe ID.
     * @param amt token amount to deposit.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function deposit(
        uint256 safe,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);
        uint _safe = getSafe(safe);
        (bytes32 collateralType, address handler) = getSafeData(_safe);

        address colAddr = getCollateralJoinAddress(collateralType);
        TokenJoinInterface tokenJoinContract = TokenJoinInterface(colAddr);
        TokenInterface tokenContract = tokenJoinContract.collateral();

        if (isEth(address(tokenContract))) {
            _amt = _amt == uint(-1) ? address(this).balance : _amt;
            tokenContract.deposit{value: _amt}();
        } else {
            _amt = _amt == uint(-1) ?  tokenContract.balanceOf(address(this)) : _amt;
        }

        approve(tokenContract, address(colAddr), _amt);
        tokenJoinContract.join(address(this), _amt);

        SafeEngineLike(managerContract.safeEngine()).modifySAFECollateralization(
            collateralType,
            handler,
            address(this),
            address(this),
            toInt(convertTo18(tokenJoinContract.decimals(), _amt)),
            0
        );

        setUint(setId, _amt);

        _eventName = "LogDeposit(uint256,bytes32,uint256,uint256,uint256)";
        _eventParam = abi.encode(_safe, collateralType, _amt, getId, setId);
    }

    /**
     * @dev Withdraw ETH/ERC20_Token Collateral.
     * @notice Withdraw collateral from a Reflexer Safe
     * @param safe Safe ID.
     * @param amt token amount to withdraw.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function withdraw(
        uint256 safe,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);
        uint _safe = getSafe(safe);
        (bytes32 collateralType, address handler) = getSafeData(_safe);

        address colAddr = getCollateralJoinAddress(collateralType);
        TokenJoinInterface tokenJoinContract = TokenJoinInterface(colAddr);

        uint _amt18;
        if (_amt == uint(-1)) {
            (_amt18,) = SafeEngineLike(managerContract.safeEngine()).safes(collateralType, handler);
            _amt = convert18ToDec(tokenJoinContract.decimals(), _amt18);
        } else {
            _amt18 = convertTo18(tokenJoinContract.decimals(), _amt);
        }

        managerContract.modifySAFECollateralization(
            _safe,
            -toInt(_amt18),
            0
        );

        managerContract.transferCollateral(
            _safe,
            address(this),
            _amt18
        );

        TokenInterface tokenContract = tokenJoinContract.collateral();

        if (isEth(address(tokenContract))) {
            tokenJoinContract.exit(address(this), _amt);
            tokenContract.withdraw(_amt);
        } else {
            tokenJoinContract.exit(address(this), _amt);
        }

        setUint(setId, _amt);

        _eventName = "LogWithdraw(uint256,bytes32,uint256,uint256,uint256)";
        _eventParam = abi.encode(_safe, collateralType, _amt, getId, setId);
    }

    /**
     * @dev Borrow Coin.
     * @notice Borrow Coin using a Reflexer safe
     * @param safe Safe ID.
     * @param amt token amount to borrow.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function borrow(
        uint256 safe,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);
        uint _safe = getSafe(safe);
        (bytes32 collateralType, address handler) = getSafeData(_safe);

        SafeEngineLike safeEngineContract = SafeEngineLike(managerContract.safeEngine());

        managerContract.modifySAFECollateralization(
            _safe,
            0,
            _getBorrowAmt(
                address(safeEngineContract),
                handler,
                collateralType,
                _amt
            )
        );

        managerContract.transferInternalCoins(
            _safe,
            address(this),
            toRad(_amt)
        );

        if (safeEngineContract.safeRights(address(this), address(coinJoinContract)) == 0) {
            safeEngineContract.approveSAFEModification(address(coinJoinContract));
        }

        coinJoinContract.exit(address(this), _amt);

        setUint(setId, _amt);

        _eventName = "LogBorrow(uint256,bytes32,uint256,uint256,uint256)";
        _eventParam = abi.encode(_safe, collateralType, _amt, getId, setId);
    }

    /**
     * @dev Payback borrowed Coin.
     * @notice Payback Coin debt owed by a Reflexer safe
     * @param safe Safe ID.
     * @param amt token amount to payback.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function payback(
        uint256 safe,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);
        uint _safe = getSafe(safe);
        (bytes32 collateralType, address handler) = getSafeData(_safe);

        address safeEngine = managerContract.safeEngine();

        uint _maxDebt = _getSafeDebt(safeEngine, collateralType, handler);

        _amt = _amt == uint(-1) ? _maxDebt : _amt;

        require(_maxDebt >= _amt, "paying-excess-debt");

        approve(coinJoinContract.systemCoin(), address(coinJoinContract), _amt);
        coinJoinContract.join(handler, _amt);

        managerContract.modifySAFECollateralization(
            _safe,
            0,
            _getWipeAmt(
                safeEngine,
                SafeEngineLike(safeEngine).coinBalance(handler),
                handler,
                collateralType
            )
        );

        setUint(setId, _amt);

        _eventName = "LogPayback(uint256,bytes32,uint256,uint256,uint256)";
        _eventParam = abi.encode(_safe, collateralType, _amt, getId, setId);
    }

    /**
     * @dev Withdraw leftover ETH/ERC20_Token after Liquidation.
     * @notice Withdraw leftover collateral after Liquidation.
     * @param safe Safe ID.
     * @param amt token amount to Withdraw.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function withdrawLiquidated(
        uint256 safe,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);
        (bytes32 collateralType, address handler) = getSafeData(safe);

        address colAddr = getCollateralJoinAddress(collateralType);
        TokenJoinInterface tokenJoinContract = TokenJoinInterface(colAddr);

        uint _amt18;
        if (_amt == uint(-1)) {
            _amt18 = SafeEngineLike(managerContract.safeEngine()).tokenCollateral(collateralType, handler);
            _amt = convert18ToDec(tokenJoinContract.decimals(), _amt18);
        } else {
            _amt18 = convertTo18(tokenJoinContract.decimals(), _amt);
        }

        managerContract.transferCollateral(
            safe,
            address(this),
            _amt18
        );

        TokenInterface tokenContract = tokenJoinContract.collateral();
        tokenJoinContract.exit(address(this), _amt);
        if (isEth(address(tokenContract))) {
            tokenContract.withdraw(_amt);
        }

        setUint(setId, _amt);

        _eventName = "LogWithdrawLiquidated(uint256,bytes32,uint256,uint256,uint256)";
        _eventParam = abi.encode(safe, collateralType, _amt, getId, setId);
    }

    struct GebData {
        uint _safe;
        address colAddr;
        TokenJoinInterface tokenJoinContract;
        SafeEngineLike safeEngineContract;
        TokenInterface tokenContract;
    }

    /**
     * @dev Deposit ETH/ERC20_Token Collateral and Borrow Coin.
     * @notice Deposit collateral and borrow Coin.
     * @param safe Safe ID.
     * @param depositAmt token deposit amount to Withdraw.
     * @param borrowAmt token borrow amount to Withdraw.
     * @param getIdDeposit Get deposit token amount at this ID from `InstaMemory` Contract.
     * @param getIdBorrow Get borrow token amount at this ID from `InstaMemory` Contract.
     * @param setIdDeposit Set deposit token amount at this ID in `InstaMemory` Contract.
     * @param setIdBorrow Set borrow token amount at this ID in `InstaMemory` Contract.
    */
    function depositAndBorrow(
        uint256 safe,
        uint256 depositAmt,
        uint256 borrowAmt,
        uint256 getIdDeposit,
        uint256 getIdBorrow,
        uint256 setIdDeposit,
        uint256 setIdBorrow
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        GebData memory gebData;
        uint _amtDeposit = getUint(getIdDeposit, depositAmt);
        uint _amtBorrow = getUint(getIdBorrow, borrowAmt);

        gebData._safe = getSafe(safe);
        (bytes32 collateralType, address handler) = getSafeData(gebData._safe);

        gebData.colAddr = getCollateralJoinAddress(collateralType);
        gebData.tokenJoinContract = TokenJoinInterface(gebData.colAddr);
        gebData.safeEngineContract = SafeEngineLike(managerContract.safeEngine());
        gebData.tokenContract = gebData.tokenJoinContract.collateral();

        if (isEth(address(gebData.tokenContract))) {
            _amtDeposit = _amtDeposit == uint(-1) ? address(this).balance : _amtDeposit;
            gebData.tokenContract.deposit{value: _amtDeposit}();
        } else {
            _amtDeposit = _amtDeposit == uint(-1) ?  gebData.tokenContract.balanceOf(address(this)) : _amtDeposit;
        }

        approve(gebData.tokenContract, address(gebData.colAddr), _amtDeposit);
        gebData.tokenJoinContract.join(handler, _amtDeposit);

        managerContract.modifySAFECollateralization(
            gebData._safe,
            toInt(convertTo18(gebData.tokenJoinContract.decimals(), _amtDeposit)),
            _getBorrowAmt(
                address(gebData.safeEngineContract),
                handler,
                collateralType,
                _amtBorrow
            )
        );

        managerContract.transferInternalCoins(
            gebData._safe,
            address(this),
            toRad(_amtBorrow)
        );

        if (gebData.safeEngineContract.safeRights(address(this), address(coinJoinContract)) == 0) {
            gebData.safeEngineContract.approveSAFEModification(address(coinJoinContract));
        }

        coinJoinContract.exit(address(this), _amtBorrow);

        setUint(setIdDeposit, _amtDeposit);
        setUint(setIdBorrow, _amtBorrow);

        _eventName = "LogDepositAndBorrow(uint256,bytes32,uint256,uint256,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(
            gebData._safe,
            collateralType,
            _amtDeposit,
            _amtBorrow,
            getIdDeposit,
            getIdBorrow,
            setIdDeposit,
            setIdBorrow
        );
    }

    /**
     * @dev Exit Coin from handler.
     * @notice Exit Coin from handler.
     * @param safe Safe ID.
     * @param amt token amount to exit.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function exit(
        uint256 safe,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);
        uint _safe = getSafe(safe);
        (bytes32 collateralType, address handler) = getSafeData(_safe);

        SafeEngineLike safeEngineContract = SafeEngineLike(managerContract.safeEngine());
        if(_amt == uint(-1)) {
            _amt = safeEngineContract.coinBalance(handler);
            _amt = _amt / 10 ** 27;
        }

        managerContract.transferInternalCoins(
            _safe,
            address(this),
            toRad(_amt)
        );

        if (safeEngineContract.safeRights(address(this), address(coinJoinContract)) == 0) {
            safeEngineContract.approveSAFEModification(address(coinJoinContract));
        }

        coinJoinContract.exit(address(this), _amt);

        setUint(setId, _amt);

        _eventName = "LogExit(uint256,bytes32,uint256,uint256,uint256)";
        _eventParam = abi.encode(_safe, collateralType, _amt, getId, setId);
    }

}

contract ConnectV2Reflexer is GebResolver {
    string public constant name = "Reflexer-v1";
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
import { 
    ManagerLike, 
    CoinJoinInterface, 
    SafeEngineLike, 
    TaxCollectorLike, 
    TokenJoinInterface,
    GebMapping 
} from "./interface.sol";

abstract contract Helpers is DSMath, Basic {
    /**
     * @dev Manager Interface
     */
    ManagerLike internal constant managerContract = ManagerLike(0xEfe0B4cA532769a3AE758fD82E1426a03A94F185);

    /**
     * @dev Coin Join
     */
    CoinJoinInterface internal constant coinJoinContract = CoinJoinInterface(0x0A5653CCa4DB1B6E265F47CAf6969e64f1CFdC45);

    /**
     * @dev Reflexer Tax collector Address.
    */
    TaxCollectorLike internal constant taxCollectorContract = TaxCollectorLike(0xcDB05aEda142a1B0D6044C09C64e4226c1a281EB);

    /**
     * @dev Return Close Safe Address.
    */
    address internal constant giveAddr = 0x4dD58550eb15190a5B3DfAE28BB14EeC181fC267;

     /**
     * @dev Return Reflexer mapping Address.
     */
    function getGebMappingAddress() internal pure returns (address) {
        return 0x573e5132693C046D1A9F75Bac683889164bA41b4;
    }

    function getCollateralJoinAddress(bytes32 collateralType) internal view returns (address) {
        return GebMapping(getGebMappingAddress()).collateralJoinMapping(collateralType);
    }

    /**
     * @dev Get Safe's collateral type.
    */
    function getSafeData(uint safe) internal view returns (bytes32 collateralType, address handler) {
        collateralType = managerContract.collateralTypes(safe);
        handler = managerContract.safes(safe);
    }

    /**
     * @dev Collateral Join address is ETH type collateral.
    */
    function isEth(address tknAddr) internal pure returns (bool) {
        return tknAddr == wethAddr ? true : false;
    }

    /**
     * @dev Get Safe Debt Amount.
    */
    function _getSafeDebt(
        address safeEngine,
        bytes32 collateralType,
        address handler
    ) internal view returns (uint wad) {
        (, uint rate,,,) = SafeEngineLike(safeEngine).collateralTypes(collateralType);
        (, uint debt) = SafeEngineLike(safeEngine).safes(collateralType, handler);
        uint coin = SafeEngineLike(safeEngine).coinBalance(handler);

        uint rad = sub(mul(debt, rate), coin);
        wad = rad / RAY;

        wad = mul(wad, RAY) < rad ? wad + 1 : wad;
    }

    /**
     * @dev Get Borrow Amount.
    */
    function _getBorrowAmt(
        address safeEngine,
        address handler,
        bytes32 collateralType,
        uint amt
    ) internal returns (int deltaDebt)
    {
        uint rate = taxCollectorContract.taxSingle(collateralType);
        uint coin = SafeEngineLike(safeEngine).coinBalance(handler);
        if (coin < mul(amt, RAY)) {
            deltaDebt = toInt(sub(mul(amt, RAY), coin) / rate);
            deltaDebt = mul(uint(deltaDebt), rate) < mul(amt, RAY) ? deltaDebt + 1 : deltaDebt;
        }
    }

    /**
     * @dev Get Payback Amount.
    */
    function _getWipeAmt(
        address safeEngine,
        uint amt,
        address handler,
        bytes32 collateralType
    ) internal view returns (int deltaDebt)
    {
        (, uint rate,,,) = SafeEngineLike(safeEngine).collateralTypes(collateralType);
        (, uint debt) = SafeEngineLike(safeEngine).safes(collateralType, handler);
        deltaDebt = toInt(amt / rate);
        deltaDebt = uint(deltaDebt) <= debt ? - deltaDebt : - toInt(debt);
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
     * @dev Get safe ID. If `safe` is 0, get lastSAFEID opened safe.
    */
    function getSafe(uint safe) internal view returns (uint _safe) {
        if (safe == 0) {
            require(managerContract.safeCount(address(this)) > 0, "no-safe-opened");
            _safe = managerContract.lastSAFEID(address(this));
        } else {
            _safe = safe;
        }
    }

}

pragma solidity ^0.7.0;

contract Events {
    event LogOpen(uint256 indexed safe, bytes32 indexed collateralType);
    event LogClose(uint256 indexed safe, bytes32 indexed collateralType);
    event LogTransfer(uint256 indexed safe, bytes32 indexed collateralType, address newOwner);
    event LogDeposit(uint256 indexed safe, bytes32 indexed collateralType, uint256 tokenAmt, uint256 getId, uint256 setId);
    event LogWithdraw(uint256 indexed safe, bytes32 indexed collateralType, uint256 tokenAmt, uint256 getId, uint256 setId);
    event LogBorrow(uint256 indexed safe, bytes32 indexed collateralType, uint256 tokenAmt, uint256 getId, uint256 setId);
    event LogPayback(uint256 indexed safe, bytes32 indexed collateralType, uint256 tokenAmt, uint256 getId, uint256 setId);
    event LogWithdrawLiquidated(uint256 indexed safe, bytes32 indexed collateralType, uint256 tokenAmt, uint256 getId, uint256 setId);
    event LogExit(uint256 indexed safe, bytes32 indexed collateralType, uint256 tokenAmt, uint256 getId, uint256 setId);
    event LogDepositAndBorrow(
        uint256 indexed safe,
        bytes32 indexed collateralType,
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
    function safeCan(address, uint, address) external view returns (uint);
    function collateralTypes(uint) external view returns (bytes32);
    function lastSAFEID(address) external view returns (uint);
    function safeCount(address) external view returns (uint);
    function ownsSAFE(uint) external view returns (address);
    function safes(uint) external view returns (address);
    function safeEngine() external view returns (address);
    function openSAFE(bytes32, address) external returns (uint);
    function transferSAFEOwnership(uint, address) external;
    function modifySAFECollateralization(uint, int, int) external;
    function transferCollateral(uint, address, uint) external;
    function transferInternalCoins(uint, address, uint) external;
}

interface SafeEngineLike {
    function safeRights(address, address) external view returns (uint);
    function collateralTypes(bytes32) external view returns (uint, uint, uint, uint, uint);
    function coinBalance(address) external view returns (uint);
    function safes(bytes32, address) external view returns (uint, uint);
    function modifySAFECollateralization(
        bytes32,
        address,
        address,
        address,
        int,
        int
    ) external;
    function approveSAFEModification(address) external;
    function transferInternalCoins(address, address, uint) external;
    function tokenCollateral(bytes32, address) external view returns (uint);
}

interface TokenJoinInterface {
    function decimals() external returns (uint);
    function collateral() external returns (TokenInterface);
    function collateralType() external returns (bytes32);
    function join(address, uint) external payable;
    function exit(address, uint) external;
}

interface CoinJoinInterface {
    function safeEngine() external returns (SafeEngineLike);
    function systemCoin() external returns (TokenInterface);
    function join(address, uint) external payable;
    function exit(address, uint) external;
}

interface TaxCollectorLike {
    function taxSingle(bytes32) external returns (uint);
}

interface ConnectorsInterface {
    function chief(address) external view returns (bool);
}

interface IndexInterface {
    function master() external view returns (address);
}

interface GebMapping {
    function collateralJoinMapping(bytes32) external view returns(address);
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

    function approve(TokenInterface token, address spender, uint256 amount) internal {
        try token.approve(spender, amount) {

        } catch {
            token.approve(spender, 0);
            token.approve(spender, amount);
        }
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
            approve(token, address(token), amount);
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

