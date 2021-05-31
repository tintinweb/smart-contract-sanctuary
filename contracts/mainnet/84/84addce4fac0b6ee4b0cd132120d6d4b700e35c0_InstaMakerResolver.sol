/**
 *Submitted for verification at Etherscan.io on 2021-05-30
*/

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface ManagerLike {
    function ilks(uint) external view returns (bytes32);
    function owns(uint) external view returns (address);
    function urns(uint) external view returns (address);
    function vat() external view returns (address);
}

interface CdpsLike {
    function getCdpsAsc(address, address) external view returns (uint[] memory, address[] memory, bytes32[] memory);
}

interface VatLike {
    function ilks(bytes32) external view returns (uint, uint, uint, uint, uint);
    function dai(address) external view returns (uint);
    function urns(bytes32, address) external view returns (uint, uint);
    function gem(bytes32, address) external view returns (uint);
    function debt() external view returns (uint);
    function Line() external view returns (uint);
}

interface JugLike {
    function ilks(bytes32) external view returns (uint, uint);
    function base() external view returns (uint);
}

interface PotLike {
    function dsr() external view returns (uint);
    function pie(address) external view returns (uint);
    function chi() external view returns (uint);
}

interface SpotLike {
    function ilks(bytes32) external view returns (PipLike, uint);
}

interface PipLike {
    function peek() external view returns (bytes32, bool);
}

interface InstaMcdAddress {
    function manager() external view returns (address);
    function vat() external view returns (address);
    function jug() external view returns (address);
    function spot() external view returns (address);
    function pot() external view returns (address);
    function getCdps() external view returns (address);
}


contract DSMath {

    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "math-not-safe");
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        z = x - y <= x ? x - y : 0;
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "math-not-safe");
    }

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

}


contract Helpers is DSMath {
    /**
     * @dev get MakerDAO MCD Address contract
     */
    function getMcdAddresses() public pure returns (address) {
        return 0xF23196DF1C440345DE07feFbe556a5eF0dcD29F0;
    }

    struct VaultData {
        uint id;
        address owner;
        string colType;
        uint collateral;
        uint art;
        uint debt;
        uint liquidatedCol;
        uint borrowRate;
        uint colPrice;
        uint liquidationRatio;
        address vaultAddress;
    }

    struct ColInfo {
        uint borrowRate;
        uint price;
        uint liquidationRatio;
        uint vaultDebtCelling;
        uint vaultDebtFloor;
        uint vaultTotalDebt;
        uint totalDebtCelling;
        uint TotalDebt;
    }

    /**
     * @dev Convert String to bytes32.
    */
    function stringToBytes32(string memory str) internal pure returns (bytes32 result) {
        require(bytes(str).length != 0, "String-Empty");
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            result := mload(add(str, 32))
        }
    }

    /**
     * @dev Convert bytes32 to String.
    */
    function bytes32ToString(bytes32 _bytes32) internal pure returns (string memory) {
        bytes32  _temp;
        uint count;
        for (uint256 i; i < 32; i++) {
            _temp = _bytes32[i];
            if( _temp != bytes32(0)) {
                count += 1;
            }
        }
        bytes memory bytesArray = new bytes(count);
        for (uint256 i; i < count; i++) {
                bytesArray[i] = (_bytes32[i]);
        }
        return (string(bytesArray));
    }


    function getFee(bytes32 ilk) internal view returns (uint fee) {
        address jug = InstaMcdAddress(getMcdAddresses()).jug();
        (uint duty,) = JugLike(jug).ilks(ilk);
        uint base = JugLike(jug).base();
        fee = add(duty, base);
    }

    function getColPrice(bytes32 ilk) internal view returns (uint price) {
        address spot = InstaMcdAddress(getMcdAddresses()).spot();
        address vat = InstaMcdAddress(getMcdAddresses()).vat();
        (, uint mat) = SpotLike(spot).ilks(ilk);
        (,,uint spotPrice,,) = VatLike(vat).ilks(ilk);
        price = rmul(mat, spotPrice);
    }

    function getColRatio(bytes32 ilk) internal view returns (uint ratio) {
        address spot = InstaMcdAddress(getMcdAddresses()).spot();
        (, ratio) = SpotLike(spot).ilks(ilk);
    }

    function getDebtFloorAndCeiling(bytes32 ilk) internal view returns (uint, uint, uint, uint, uint) {
        address vat = InstaMcdAddress(getMcdAddresses()).vat();
        (uint totalArt,uint rate,, uint vaultDebtCellingRad, uint vaultDebtFloor) = VatLike(vat).ilks(ilk);
        uint vaultDebtCelling = vaultDebtCellingRad / 10 ** 45;
        uint vaultTotalDebt = rmul(totalArt, rate);

        uint totalDebtCelling = VatLike(vat).Line();
        uint totalDebt = VatLike(vat).debt();
        return (
            vaultDebtCelling,
            vaultTotalDebt,
            vaultDebtFloor,
            totalDebtCelling,
            totalDebt
        );
    }
}


contract VaultResolver is Helpers {
     function getVaults(address owner) external view returns (VaultData[] memory) {
        address manager = InstaMcdAddress(getMcdAddresses()).manager();
        address cdpManger = InstaMcdAddress(getMcdAddresses()).getCdps();

        (uint[] memory ids, address[] memory urns, bytes32[] memory ilks) = CdpsLike(cdpManger).getCdpsAsc(manager, owner);
        VaultData[] memory vaults = new VaultData[](ids.length);

        for (uint i = 0; i < ids.length; i++) {
            (uint ink, uint art) = VatLike(ManagerLike(manager).vat()).urns(ilks[i], urns[i]);
            (,uint rate, uint priceMargin,,) = VatLike(ManagerLike(manager).vat()).ilks(ilks[i]);
            uint mat = getColRatio(ilks[i]);

            vaults[i] = VaultData(
                ids[i],
                owner,
                bytes32ToString(ilks[i]),
                ink,
                art,
                rmul(art,rate),
                VatLike(ManagerLike(manager).vat()).gem(ilks[i], urns[i]),
                getFee(ilks[i]),
                rmul(priceMargin, mat),
                mat,
                urns[i]
            );
        }
        return vaults;
    }

    function getVaultById(uint id) external view returns (VaultData memory) {
        address manager = InstaMcdAddress(getMcdAddresses()).manager();
        address urn = ManagerLike(manager).urns(id);
        bytes32 ilk = ManagerLike(manager).ilks(id);

        (uint ink, uint art) = VatLike(ManagerLike(manager).vat()).urns(ilk, urn);
        (,uint rate, uint priceMargin,,) = VatLike(ManagerLike(manager).vat()).ilks(ilk);

        uint mat = getColRatio(ilk);

        uint feeRate = getFee(ilk);
        VaultData memory vault = VaultData(
            id,
            ManagerLike(manager).owns(id),
            bytes32ToString(ilk),
            ink,
            art,
            rmul(art,rate),
            VatLike(ManagerLike(manager).vat()).gem(ilk, urn),
            feeRate,
            rmul(priceMargin, mat),
            mat,
            urn
        );
        return vault;
    }

    function getColInfo(string[] memory name) public view returns (ColInfo[] memory) {
        ColInfo[] memory colInfo = new ColInfo[](name.length);

        for (uint i = 0; i < name.length; i++) {
            bytes32 ilk = stringToBytes32(name[i]);
            (
                uint256 vaultDebtCelling,
                uint256 vaultDebtFloor,
                uint256 vaultTotalDebt,
                uint256 totalDebtCelling,
                uint256 totalDebt
            ) = getDebtFloorAndCeiling(ilk);

            colInfo[i] = ColInfo(
                getFee(ilk),
                getColPrice(ilk),
                getColRatio(ilk),
                vaultDebtCelling,
                vaultDebtFloor,
                vaultTotalDebt,
                totalDebtCelling,
                totalDebt
            );
        }
        return colInfo;
    }

}


contract DSRResolver is VaultResolver {
    function getDsrRate() public view returns (uint dsr) {
        address pot = InstaMcdAddress(getMcdAddresses()).pot();
        dsr = PotLike(pot).dsr();
    }

    function getDaiPosition(address owner) external view returns (uint amt, uint dsr) {
        address pot = InstaMcdAddress(getMcdAddresses()).pot();
        uint chi = PotLike(pot).chi();
        uint pie = PotLike(pot).pie(owner);
        amt = rmul(pie,chi);
        dsr = getDsrRate();
    }
}


contract InstaMakerResolver is DSRResolver {
    string public constant name = "Maker-Resolver-v1.4";
}