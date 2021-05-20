/**
 *Submitted for verification at Etherscan.io on 2021-05-19
*/

/**
 *Submitted for verification at Etherscan.io on 2020-07-26
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
        bytes32 colType;
        uint collateral;
        uint art;
        address owner;
    }

    struct VaultIds {
        address owner;
        uint[] id;
    }

    struct ColInfo {
        uint price;
        uint rate;
        bytes32 ilk;
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

    function getColPrice(bytes32 ilk) internal view returns (uint price, uint rate) {
        address spot = InstaMcdAddress(getMcdAddresses()).spot();
        address vat = InstaMcdAddress(getMcdAddresses()).vat();
        (, uint mat) = SpotLike(spot).ilks(ilk);
        (,uint _rate,uint spotPrice,,) = VatLike(vat).ilks(ilk);
        rate = _rate;
        price = rmul(mat, spotPrice);
    }
}


contract VaultResolver is Helpers {
    function getVaultByIds(uint[] calldata ids) external view returns (VaultData[] memory) {
        address manager = InstaMcdAddress(getMcdAddresses()).manager();
        VatLike vat = VatLike(ManagerLike(manager).vat());
        uint len = ids.length;
        VaultData[] memory vaults = new VaultData[](len);
        for (uint i = 0; i < len; i++) {
            address urn = ManagerLike(manager).urns(ids[i]);
            bytes32 ilk = ManagerLike(manager).ilks(ids[i]);
            (uint ink, uint art) = vat.urns(ilk, urn);
            vaults[i] = VaultData(
                ids[i],
                ilk,
                ink,
                art,
                ManagerLike(manager).owns(ids[i])
            );
        }
        return vaults;
    }


    function getIds(address[] calldata owners) external view returns (VaultIds[] memory) {
        address manager = InstaMcdAddress(getMcdAddresses()).manager();
        address cdpManger = InstaMcdAddress(getMcdAddresses()).getCdps();
        uint len = owners.length;
        VaultIds[] memory vaultIds = new VaultIds[](len);
        for (uint i = 0; i < len; i++) {
            (uint[] memory ids,,) = CdpsLike(cdpManger).getCdpsAsc(manager, owners[i]);
            vaultIds[i] = VaultIds(
                owners[i],
                ids
            );
        }
        return vaultIds;
    }

    function getColInfo(string[] memory name) public view returns (ColInfo[] memory) {
        ColInfo[] memory colInfo = new ColInfo[](name.length);

        for (uint i = 0; i < name.length; i++) {
            bytes32 ilk = stringToBytes32(name[i]);
            (uint price, uint rate) = getColPrice(ilk);
            colInfo[i] = ColInfo(
                price,
                rate,
                ilk
            );
        }
        return colInfo;
    }

}