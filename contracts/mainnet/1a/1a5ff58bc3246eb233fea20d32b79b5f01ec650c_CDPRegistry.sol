/**
 *Submitted for verification at Etherscan.io on 2021-04-07
*/

// File: localhost/contracts/interfaces/ICollateralRegistry.sol

// SPDX-License-Identifier: bsl-1.1

interface ICollateralRegistry {
    function addCollateral ( address asset ) external;
    function collateralId ( address ) external view returns ( uint256 );
    function collaterals (  ) external view returns ( address[] memory );
    function removeCollateral ( address asset ) external;
    function vaultParameters (  ) external view returns ( address );
    function isCollateral ( address asset ) external view returns ( bool );
    function collateralList ( uint id ) external view returns ( address );
    function collateralsCount (  ) external view returns ( uint );
}

// File: localhost/contracts/interfaces/IVault.sol

interface IVault {
    function DENOMINATOR_1E2 (  ) external view returns ( uint256 );
    function DENOMINATOR_1E5 (  ) external view returns ( uint256 );
    function borrow ( address asset, address user, uint256 amount ) external returns ( uint256 );
    function calculateFee ( address asset, address user, uint256 amount ) external view returns ( uint256 );
    function changeOracleType ( address asset, address user, uint256 newOracleType ) external;
    function chargeFee ( address asset, address user, uint256 amount ) external;
    function col (  ) external view returns ( address );
    function colToken ( address, address ) external view returns ( uint256 );
    function collaterals ( address, address ) external view returns ( uint256 );
    function debts ( address, address ) external view returns ( uint256 );
    function depositCol ( address asset, address user, uint256 amount ) external;
    function depositEth ( address user ) external payable;
    function depositMain ( address asset, address user, uint256 amount ) external;
    function destroy ( address asset, address user ) external;
    function getTotalDebt ( address asset, address user ) external view returns ( uint256 );
    function lastUpdate ( address, address ) external view returns ( uint256 );
    function liquidate ( address asset, address positionOwner, uint256 mainAssetToLiquidator, uint256 colToLiquidator, uint256 mainAssetToPositionOwner, uint256 colToPositionOwner, uint256 repayment, uint256 penalty, address liquidator ) external;
    function liquidationBlock ( address, address ) external view returns ( uint256 );
    function liquidationFee ( address, address ) external view returns ( uint256 );
    function liquidationPrice ( address, address ) external view returns ( uint256 );
    function oracleType ( address, address ) external view returns ( uint256 );
    function repay ( address asset, address user, uint256 amount ) external returns ( uint256 );
    function spawn ( address asset, address user, uint256 _oracleType ) external;
    function stabilityFee ( address, address ) external view returns ( uint256 );
    function tokenDebts ( address ) external view returns ( uint256 );
    function triggerLiquidation ( address asset, address positionOwner, uint256 initialPrice ) external;
    function update ( address asset, address user ) external;
    function usdp (  ) external view returns ( address );
    function vaultParameters (  ) external view returns ( address );
    function weth (  ) external view returns ( address payable );
    function withdrawCol ( address asset, address user, uint256 amount ) external;
    function withdrawEth ( address user, uint256 amount ) external;
    function withdrawMain ( address asset, address user, uint256 amount ) external;
}

// File: localhost/contracts/CDPRegistry.sol

/*
  Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;



contract CDPRegistry {

    struct CDP {
        address asset;
        address owner;
    }

    mapping (address => address[]) cdpList;
    mapping (address => mapping (address => uint)) cdpIndex;

    IVault public immutable vault;
    ICollateralRegistry public immutable cr;

    event Added(address indexed asset, address indexed owner);
    event Removed(address indexed asset, address indexed owner);

    constructor (address _vault, address _collateralRegistry) {
        require(_vault != address(0) && _collateralRegistry != address(0), "Unit Protocol: ZERO_ADDRESS");
        vault = IVault(_vault);
        cr = ICollateralRegistry(_collateralRegistry);
    }

    function checkpoint(address asset, address owner) public {
        require(asset != address(0) && owner != address(0), "Unit Protocol: ZERO_ADDRESS");

        bool listed = isListed(asset, owner);
        bool alive = isAlive(asset, owner);

        if (alive && !listed) {
            _addCdp(asset, owner);
        } else if (listed && !alive) {
            _removeCdp(asset, owner);
        }
    }

    function batchCheckpointForAsset(address asset, address[] calldata owners) external {
        for (uint i = 0; i < owners.length; i++) {
            checkpoint(asset, owners[i]);
        }
    }

    function batchCheckpoint(address[] calldata assets, address[] calldata owners) external {
        require(assets.length == owners.length, "Unit Protocol: ARGUMENTS_LENGTH_MISMATCH");
        for (uint i = 0; i < owners.length; i++) {
            checkpoint(assets[i], owners[i]);
        }
    }

    function isAlive(address asset, address owner) public view returns (bool) {
        return vault.debts(asset, owner) != 0;
    }

    function isListed(address asset, address owner) public view returns (bool) {
        if (cdpList[asset].length == 0) { return false; }
        return cdpIndex[asset][owner] != 0 || cdpList[asset][0] == owner;
    }

    function _removeCdp(address asset, address owner) internal {
        uint id = cdpIndex[asset][owner];

        delete cdpIndex[asset][owner];

        uint lastId = cdpList[asset].length - 1;

        if (id != lastId) {
            address lastOwner = cdpList[asset][lastId];
            cdpList[asset][id] = lastOwner;
            cdpIndex[asset][lastOwner] = id;
        }

        cdpList[asset].pop();

        emit Removed(asset, owner);
    }

    function _addCdp(address asset, address owner) internal {
        cdpIndex[asset][owner] = cdpList[asset].length;
        cdpList[asset].push(owner);

        emit Added(asset, owner);
    }

    function getCdpsByCollateral(address asset) external view returns (CDP[] memory cdps) {
        address[] memory owners = cdpList[asset];
        cdps = new CDP[](owners.length);
        for (uint i = 0; i < owners.length; i++) {
            cdps[i] = CDP(asset, owners[i]);
        }
    }

    function getCdpsByOwner(address owner) external view returns (CDP[] memory r) {
        address[] memory assets = cr.collaterals();
        CDP[] memory cdps = new CDP[](assets.length);
        uint actualCdpsCount;

        for (uint i = 0; i < assets.length; i++) {
            if (isListed(assets[i], owner)) {
                cdps[actualCdpsCount++] = CDP(assets[i], owner);
            }
        }

        r = new CDP[](actualCdpsCount);

        for (uint i = 0; i < actualCdpsCount; i++) {
            r[i] = cdps[i];
        }

    }

    function getAllCdps() external view returns (CDP[] memory r) {
        uint totalCdpCount = getCdpsCount();
        
        uint cdpCount;

        r = new CDP[](totalCdpCount);

        address[] memory assets = cr.collaterals();
        for (uint i = 0; i < assets.length; i++) {
            address[] memory owners = cdpList[assets[i]];
            for (uint j = 0; j < owners.length; j++) {
                r[cdpCount++] = CDP(assets[i], owners[j]);
            }
        }
    }

    function getCdpsCount() public view returns (uint totalCdpCount) {
        address[] memory assets = cr.collaterals();
        for (uint i = 0; i < assets.length; i++) {
            totalCdpCount += cdpList[assets[i]].length;
        }
    }

    function getCdpsCountForCollateral(address asset) public view returns (uint) {
        return cdpList[asset].length;
    }
}