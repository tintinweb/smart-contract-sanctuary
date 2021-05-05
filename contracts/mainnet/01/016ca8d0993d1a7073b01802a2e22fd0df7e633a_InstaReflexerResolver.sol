/**
 *Submitted for verification at Etherscan.io on 2021-05-04
*/

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface ManagerLike {
    function collateralTypes(uint) external view returns (bytes32);
    function ownsSAFE(uint) external view returns (address);
    function safes(uint) external view returns (address);
    function safeEngine() external view returns (address);
}

interface GetSafesLike {
    function getSafesAsc(address, address) external view returns (uint[] memory, address[] memory, bytes32[] memory);
}

interface SAFEEngineLike {
    function collateralTypes(bytes32) external view returns (uint, uint, uint, uint, uint);
    function coinBalance(address) external view returns (uint);
    function safes(bytes32, address) external view returns (uint, uint);
    function tokenCollateral(bytes32, address) external view returns (uint);
}

interface TaxCollectorLike {
    function collateralTypes(bytes32) external view returns (uint, uint);
    function globalStabilityFee() external view returns (uint);
}

interface OracleRelayerLike {
    function collateralTypes(bytes32) external view returns (OracleLike, uint, uint);
    function redemptionRate() external view returns (uint);

}

interface OracleLike {
    function getResultWithValidity() external view returns (bytes32, bool);
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

    struct SafeData {
        uint id;
        address owner;
        string colType;
        uint collateral;
        uint debt;
        uint adjustedDebt;
        uint liquidatedCol;
        uint borrowRate;
        uint colPrice;
        uint liquidationRatio;
        address safeAddress;
    }

    struct ColInfo {
        uint borrowRate;
        uint price;
        uint liquidationRatio;
        uint debtCeiling;
        uint debtFloor;
        uint totalDebt;
    }

    struct ReflexerAddresses {
        address manager;
        address safeEngine;
        address taxCollector;
        address oracleRelayer;
        address getSafes;
    }

    /**
     * @dev get Reflexer Address contract
     */
    function getReflexerAddresses() public pure returns (ReflexerAddresses memory) {
        return ReflexerAddresses(
            0xEfe0B4cA532769a3AE758fD82E1426a03A94F185, // manager
            0xCC88a9d330da1133Df3A7bD823B95e52511A6962, // safeEngine
            0xcDB05aEda142a1B0D6044C09C64e4226c1a281EB, // taxCollector
            0x4ed9C0dCa0479bC64d8f4EB3007126D5791f7851, // oracleRelayer
            0xdf4BC9aA98cC8eCd90Ba2BEe73aD4a1a9C8d202B  // getSafes
        );
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


    function getFee(bytes32 collateralType) internal view returns (uint fee) {
        address taxCollector = getReflexerAddresses().taxCollector;
        (uint stabilityFee,) = TaxCollectorLike(taxCollector).collateralTypes(collateralType);
        uint globalStabilityFee = TaxCollectorLike(taxCollector).globalStabilityFee();
        fee = add(stabilityFee, globalStabilityFee);
    }

    function getColPrice(bytes32 collateralType) internal view returns (uint price) {
        address oracleRelayer = getReflexerAddresses().oracleRelayer;
        address safeEngine = getReflexerAddresses().safeEngine;
        (, uint safetyCRatio,) = OracleRelayerLike(oracleRelayer).collateralTypes(collateralType);
        (,,uint spotPrice,,) = SAFEEngineLike(safeEngine).collateralTypes(collateralType);
        price = rmul(safetyCRatio, spotPrice);
    }

    function getColRatio(bytes32 collateralType) internal view returns (uint ratio) {
        address oracleRelayer = getReflexerAddresses().oracleRelayer;
        (, ratio,) = OracleRelayerLike(oracleRelayer).collateralTypes(collateralType);
    }

    function getDebtState(bytes32 collateralType) internal view returns (uint debtCeiling, uint debtFloor, uint totalDebt) {
        address safeEngine = getReflexerAddresses().safeEngine;
        (uint globalDebt,uint rate,,uint debtCeilingRad, uint debtFloorRad) = SAFEEngineLike(safeEngine).collateralTypes(collateralType);
        debtCeiling = debtCeilingRad / 10 ** 45;
        debtFloor = debtFloorRad / 10 ** 45;
        totalDebt = rmul(globalDebt, rate);
    }
}


contract SafeResolver is Helpers {
     function getSafes(address owner) external view returns (SafeData[] memory) {
        address manager = getReflexerAddresses().manager;
        address safeManger = getReflexerAddresses().getSafes;

        (uint[] memory ids, address[] memory handlers, bytes32[] memory collateralTypes) = GetSafesLike(safeManger).getSafesAsc(manager, owner);
        SafeData[] memory safes = new SafeData[](ids.length);

        for (uint i = 0; i < ids.length; i++) {
            (uint collateral, uint debt) = SAFEEngineLike(ManagerLike(manager).safeEngine()).safes(collateralTypes[i], handlers[i]);
            (,uint rate, uint priceMargin,,) = SAFEEngineLike(ManagerLike(manager).safeEngine()).collateralTypes(collateralTypes[i]);
            uint safetyCRatio = getColRatio(collateralTypes[i]);

            safes[i] = SafeData(
                ids[i],
                owner,
                bytes32ToString(collateralTypes[i]),
                collateral,
                debt,
                rmul(debt,rate),
                SAFEEngineLike(ManagerLike(manager).safeEngine()).tokenCollateral(collateralTypes[i], handlers[i]),
                getFee(collateralTypes[i]),
                rmul(priceMargin, safetyCRatio),
                safetyCRatio,
                handlers[i]
            );
        }
        return safes;
    }

    function getSafeById(uint id) external view returns (SafeData memory) {
        address manager = getReflexerAddresses().manager;
        address handler = ManagerLike(manager).safes(id);
        bytes32 collateralType = ManagerLike(manager).collateralTypes(id);

        (uint collateral, uint debt) = SAFEEngineLike(ManagerLike(manager).safeEngine()).safes(collateralType, handler);
        (,uint rate, uint priceMargin,,) = SAFEEngineLike(ManagerLike(manager).safeEngine()).collateralTypes(collateralType);

        uint safetyCRatio = getColRatio(collateralType);

        uint feeRate = getFee(collateralType);
        SafeData memory safe = SafeData(
            id,
            ManagerLike(manager).ownsSAFE(id),
            bytes32ToString(collateralType),
            collateral,
            debt,
            rmul(debt,rate),
            SAFEEngineLike(ManagerLike(manager).safeEngine()).tokenCollateral(collateralType, handler),
            feeRate,
            rmul(priceMargin, safetyCRatio),
            safetyCRatio,
            handler
        );
        return safe;
    }

    function getColInfo(string[] memory name) public view returns (ColInfo[] memory) {
        ColInfo[] memory colInfo = new ColInfo[](name.length);

        for (uint i = 0; i < name.length; i++) {
            bytes32 collateralType = stringToBytes32(name[i]);
            (uint debtCeiling, uint debtFloor, uint totalDebt) = getDebtState(collateralType);
            colInfo[i] = ColInfo(
                getFee(collateralType),
                getColPrice(collateralType),
                getColRatio(collateralType),
                debtCeiling,
                debtFloor,
                totalDebt
            );
        }
        return colInfo;
    }

}


contract RedemptionRateResolver is SafeResolver {
    function getRedemptionRate() external view returns (uint redemptionRate) {
        address oracleRelayer = getReflexerAddresses().oracleRelayer;
        redemptionRate = OracleRelayerLike(oracleRelayer).redemptionRate();
    }
}


contract InstaReflexerResolver is RedemptionRateResolver {
    string public constant name = "Reflexer-Resolver-v1";
}