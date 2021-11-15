// SPDX-License-Identifier: bsl-1.1

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "./interfaces/IVault.sol";
import "./interfaces/ICollateralRegistry.sol";

contract CDPRegistry{
    struct CDP{
        address asset;
        address owner;
    }

    // cdpList[asset][0] = owner
    mapping(address => address[]) cdpList;

    // cdpIndex[asset][owner] = idx
    mapping(address => mapping(address => uint)) cdpIndex;

    /**
        引用变量
     */
    IVault public immutable vault;
    ICollateralRegistry public immutable collateralRegistry;

    /**
       事件
    */
    event Added(address indexed asset, address indexed owner);
    event Removed(address indexed asset, address indexed owner);

    constructor(address _vault, address _collateralRegistry) {
        vault = IVault(_vault);
        collateralRegistry = ICollateralRegistry(_collateralRegistry);
    }

    /**
       业务函数
    */
    function checkpoint(address asset, address owner) public {
        require(asset != address(0), "Atom Protocol: ZERO_ADDRESS");

        bool listed = isListed(asset, owner);
        bool alive = isAlive(asset, owner);

        if(alive && !listed){
            _addCdp(asset, owner);
        }
        else if(!alive && listed){
            _removeCdp(asset, owner);
        }
    }

    function getCdpsByCollateral(address asset) external view returns (CDP[] memory cdps) {
        address[] memory owners = cdpList[asset];
        cdps = new CDP[](owners.length);
        for(uint i=0; i<owners.length; i++){
            cdps[i] = CDP(asset, owners[i]);
        }
    }

    function getCdpsByOwner(address owner) external view returns (CDP[] memory r) {
        address[] memory assets = collateralRegistry.collaterals();
        CDP[] memory cdps = new CDP[](assets.length);
        uint actualCdpsCount;

        for(uint i=0; i<assets.length; i++){
            if(isListed(assets[i], owner)){
                cdps[actualCdpsCount++] = CDP(assets[i], owner);
            }
        }

        // 数据转存（真实count）
        r = new CDP[](actualCdpsCount);
        for(uint i=0; i<actualCdpsCount; i++){
            r[i] = cdps[i];
        }
    }

    function getAllCdps() external view returns (CDP[] memory r){
        uint totalCdpCount = getCdpsCount();
        uint cdpCount;

        r = new CDP[](totalCdpCount);

        address[] memory assets = collateralRegistry.collaterals();
        for(uint i=0; i<assets.length; i++){
            address[] memory owners = cdpList[assets[i]];
            for(uint j=0; j<owners.length; j++){
                r[cdpCount++] = CDP(assets[i],owners[j]);
            }
        }
    }

    /**
       工具函数
    */
    function isAlive(address asset, address owner) public view returns (bool){
        uint debts = vault.debts(asset, owner);
        return (debts != 0);
    }

    function isListed(address asset, address owner) public view returns (bool){
        if(cdpList[asset].length == 0){
            return false;
        }
        return (cdpIndex[asset][owner] != 0) || (cdpList[asset][0] == owner);
    }

    function getCdpsCount() public view returns (uint totalCdpCount) {
        address[] memory assets = collateralRegistry.collaterals();
        for(uint i=0; i<assets.length; i++){
            totalCdpCount += cdpList[assets[i]].length;
        }
    }

    function getCdpsCountForCollateral(address asset) public view returns (uint) {
        return cdpList[asset].length;
    }

    // 批量checkpoint某个资产的所有用户
    function batchCheckpointForAsset(address asset, address[] calldata owners) external {
        for(uint i=0; i<owners.length; i++){
            checkpoint(asset, owners[i]);
        }
    }

    // 批量checkpoint，某个用户某个资产列表
    function batchCheckpoint(address[] calldata assets, address[] calldata owners) external {
        require(assets.length == owners.length, "Unit Protocol: ARGUMENTS_LENGTH_MISMATCH");
            for(uint i=0; i<owners.length; i++){
                checkpoint(assets[i], owners[i]);
            }
    }

    /**
       工具函数（内部）
    */
    function _addCdp(address asset, address owner) internal {
        cdpList[asset].push(owner);
        cdpIndex[asset][owner] = cdpList[asset].length - 1;

        emit Added(asset, owner);
    }

    function _removeCdp(address asset, address owner) internal {
        uint idx = cdpIndex[asset][owner];
        delete cdpIndex[asset][owner];

        uint lastIdx = cdpList[asset].length - 1;
        if(idx != lastIdx){
            address tempLastOwner = cdpList[asset][lastIdx];
            cdpList[asset][idx] = tempLastOwner;
            cdpIndex[asset][tempLastOwner] = idx;
        }
        cdpList[asset].pop();

        emit Removed(asset, owner);
    }
}

// SPDX-License-Identifier: bsl-1.1

pragma solidity 0.7.6;

interface IVault {
    /**
       计算用常量定义
    */
    function DENOMINATOR_1E5() external view returns (uint);
    
    /**
       Token变量
    */
    function weth() external view returns (address payable);
    function usdg() external view returns (address);
    
    /**
       业务相关变量
    */
    function collaterals(address, address) external view returns (uint);
    function debts(address, address) external view returns (uint);
    function liquidationBlock(address, address) external view returns (uint);
    function liquidationPrice(address, address) external view returns (uint);
    function tokenDebts(address) external view returns (uint);
    function stabilityFee(address, address) external view returns (uint);
    function liquidationFee(address, address) external view returns (uint);
    function oracleType(address, address) external view returns (uint);
    function lastUpdate(address, address) external view returns (uint);
    
    /**
        业务函数
    */
    function spawn(address asset, address user, uint _oracleType) external;
    function destroy(address asset, address user) external;
    function depositMain(address asset, address user, uint amount) external;
    function depositEth(address user) external payable;
    function withdrawMain(address asset, address user, uint amount) external;
    function WithdrawEth(address payable user, uint amount) external;
    function borrow(address asset, address user, uint amount) external returns (uint);
    function repay(address asset, address user, uint amount) external returns(uint) ;
    function triggerLiquidation(address asset, address positionOwner, uint initialPrice) external;
    function liquidate(address asset, address positionOwner, uint mainAssetToLiquidator, uint mainAssetToPositionOwner, uint repayment, uint penalty, address liquidator) external;

    /**
        工具函数
    */
    function chargeFee(address asset, address user, uint amount) external;
    function update(address asset, address user) external;
    function getTotalDebt(address asset, address user) external view returns (uint) ;
    function calculateFee(address asset, address user, uint debt) external view returns (uint) ;
    function changeOracleType(address asset, address user, uint newOracleType) external;
}

// SPDX-License-Identifier: bsl-1.1

pragma solidity 0.7.6;

interface ICollateralRegistry {
    /**
       业务相关变量
    */
    function collateralList(uint idx) external view returns (address);
    function collateralId(address) external view returns (uint);

    /**
       业务函数
    */
    function addCollateral(address asset) external;
    function removeCollateral(address asset) external;

    /**
       工具函数
    */
    function isCollateral(address asset) external view returns (bool);
    function collaterals() external view returns (address[] memory);
    function collateralsCount() external view returns (uint);
}

