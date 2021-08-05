/**
 *Submitted for verification at Etherscan.io on 2020-04-28
*/

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
    function owns(uint) external view returns (address);
    function give(uint, address) external;
    function urns(uint) external view returns (address);
    function vat() external view returns (address);
    function frob(uint, int, int) external;
    function flux(uint, address, uint) external;
}

interface VatLike {
    function can(address, address) external view returns (uint);
    function dai(address) external view returns (uint);
    function hope(address) external;
    function urns(bytes32, address) external view returns (uint, uint);
}

interface TokenJoinInterface {
    function dec() external returns (uint);
    function gem() external returns (TokenInterface);
    function join(address, uint) external payable;
    function exit(address, uint) external;
}

interface DaiJoinInterface {
    function vat() external returns (VatLike);
    function exit(address, uint) external;
}

interface PotLike {
    function pie(address) external view returns (uint);
    function drip() external returns (uint);
    function exit(uint) external;
}

interface AccountInterface {
    function isAuth(address _user) external view returns (bool);
}

interface InstaMapping {
    function gemJoinMapping(bytes32) external view returns (address);
}

interface EventInterface {
    function emitEvent(uint _connectorType, uint _connectorID, bytes32 _eventCode, bytes calldata _eventData) external;
}

contract DSMath {

    uint256 constant RAY = 10 ** 27;

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "math-not-safe");
    }

    function convertTo18(uint _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = mul(_amt, 10 ** (18 - _dec));
    }

    function toInt(uint x) internal pure returns (int y) {
        y = int(x);
        require(y >= 0, "int-overflow");
    }

    function convert18ToDec(uint _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = (_amt / 10 ** (18 - _dec));
    }
}


contract Helpers is DSMath {
    /**
     * @dev Return ETH Address.
     */
    function getAddressETH() internal pure returns (address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    }

    /**
     * @dev Return WETH Address.
     */
    function getAddressWETH() internal pure returns (address) {
        return 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    }

    /**
     * @dev Return InstaEvent Address.
     */
    function getEventAddr() internal pure returns (address) {
        return 0x2af7ea6Cb911035f3eb1ED895Cb6692C39ecbA97;
    }

    /**
     * @dev Connector Details
    */
    function connectorID() public pure returns(uint _type, uint _id) {
        (_type, _id) = (2, 2);
    }

    /**
     * @dev Return InstaMapping Address.
     */
    function getMappingAddr() internal pure returns (address) {
        return 0xe81F70Cc7C0D46e12d70efc60607F16bbD617E88;
    }
}


contract MakerMCDAddresses is Helpers {
    /**
     * @dev Return Maker MCD Manager Address.
    */
    function getMcdManager() internal pure returns (address) {
        return 0x5ef30b9986345249bc32d8928B7ee64DE9435E39;
    }

    /**
     * @dev Return Maker MCD DAI_Join Address.
    */
    function getMcdDaiJoin() internal pure returns (address) {
        return 0x9759A6Ac90977b93B58547b4A71c78317f391A28;
    }

    /**
     * @dev Return Maker MCD Pot Address.
    */
    function getMcdPot() internal pure returns (address) {
        return 0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7;
    }
}


contract MakerHelpers is MakerMCDAddresses {
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
    function isEth(address tknAddr) internal pure returns (bool) {
        return tknAddr == getAddressWETH() ? true : false;
    }
}


contract BasicResolver is MakerHelpers {
    event LogWithdraw(uint256 indexed vault, bytes32 indexed ilk, uint256 tokenAmt);


    /**
     * @dev Withdraw ETH/ERC20_Token Collateral.
     * @param vault Vault ID.
     * @param amt token amount to withdraw.
    */
    function withdraw(
        uint vault,
        uint amt
    ) external payable {
        ManagerLike managerContract = ManagerLike(getMcdManager());

        (bytes32 ilk, address urn) = getVaultData(managerContract, vault);

        address colAddr = InstaMapping(getMappingAddr()).gemJoinMapping(ilk);
        TokenJoinInterface tokenJoinContract = TokenJoinInterface(colAddr);

        uint _amt = amt;
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

        if (isEth(address(tokenContract))) {
            tokenJoinContract.exit(address(this), _amt);
            tokenContract.withdraw(_amt);
        } else {
            tokenJoinContract.exit(address(this), _amt);
        }

        emit LogWithdraw(vault, ilk, _amt);
        bytes32 _eventCode = keccak256("LogWithdraw(uint256,bytes32,uint256)");
        bytes memory _eventParam = abi.encode(vault, ilk, _amt);
        (uint _type, uint _id) = connectorID();
        EventInterface(getEventAddr()).emitEvent(_type, _id, _eventCode, _eventParam);
    }

}


contract DsrResolver is BasicResolver {
    event LogWithdrawDai(uint256 tokenAmt);

    /**
     * @dev Withdraw DAI from DSR.
     * @param amt DAI amount to withdraw.
    */
    function withdrawDai(uint amt) external payable {
        address daiJoin = getMcdDaiJoin();

        DaiJoinInterface daiJoinContract = DaiJoinInterface(daiJoin);
        VatLike vat = daiJoinContract.vat();
        PotLike potContract = PotLike(getMcdPot());

        uint chi = potContract.drip();
        uint pie;
        uint _amt = amt;
        if (_amt == uint(-1)) {
            pie = potContract.pie(address(this));
            _amt = mul(chi, pie) / RAY;
        } else {
            pie = mul(_amt, RAY) / chi;
        }

        potContract.exit(pie);

        uint bal = vat.dai(address(this));
        if (vat.can(address(this), address(daiJoin)) == 0) {
            vat.hope(daiJoin);
        }
        daiJoinContract.exit(
            address(this),
            bal >= mul(_amt, RAY) ? _amt : bal / RAY
        );

        emit LogWithdrawDai(_amt);
        bytes32 _eventCode = keccak256("LogWithdrawDai(uint256)");
        bytes memory _eventParam = abi.encode(_amt);
        (uint _type, uint _id) = connectorID();
        EventInterface(getEventAddr()).emitEvent(_type, _id, _eventCode, _eventParam);
    }
}

contract StaticConnectMaker is DsrResolver {
    string public constant name = "Static-MakerDao-v1";
}