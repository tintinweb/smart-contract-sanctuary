/**
 *Submitted for verification at Etherscan.io on 2021-05-14
*/

pragma solidity ^0.8.4;

contract CoFiXUpdate {
    // COFI Token地址
    address constant COFI_TOKEN_ADDRESS = 0x5c6134399D38Ba6Ba1866eCAa34EDcdb2b22E79D;
    // USDT Token地址
    address constant USDT_TOKEN_ADDRESS = 0x20D9165Ce14c5f3a3d97c87d1B217c475a4bC154;
    // HBTC Token地址
    address constant HBTC_TOKEN_ADDRESS = 0xc4E6F199A72E8cbaEE801Bf3aD658F7c5bF3582d;

    // 1.0合约地址
    // 工厂合约地址
    address constant COFIXV1FACTORY_ADDRESS = 0x71467c65Ec768B943245D82495E50eDa35d47B64;
    // lp挖矿合约地址
    address constant COFIXV1VAULTFORLP_ADDRESS = 0x01a63418C78b1beaDc98e3Baa8373543C4918e38;
    // cn挖矿合约地址
    address constant COFIXV1VAULTFORCNODE_ADDRESS = 0x0eCa4e56C97720fE1e6EeBA95f9aAa3cd7F74393;
    // 交易挖矿合约地址
    address constant COFIXV1VAULTFORTRADER_ADDRESS = 0xc09FE9aBecCE1Fc73c5aF13EBaA5D2d721783353;
    // 分红合约地址
    address constant COFISTAKINGREWARDS_ADDRESS = 0xc53b82878fF8dbC358209fdc46eBcDFB4D4D287c;
    // 对接nest3.6的controller
    address constant COFIXV1NEWCONTROLLER_ADDRESS = 0x11C802e598A29d6B093D297c1446E170828fa4ad;

    // 2.0地址
    // 2.0lp挖矿合约地址
    address constant COFIXV2VAULTFORLP_ADDRESS = 0xE417B846b53916B60CD23f852Af9Fd3d0372933E;
    // 2.0cn挖矿合约地址
    address constant COFIXV2VAULTFORCNODE_ADDRESS = 0x889c35Bad6bb15C30D2E45EbA0e9cF6d22cDb225;
    // 2.0交易挖矿合约地址
    address constant COFIXV2VAULTFORTRADER_ADDRESS = 0xD73aF8B3f6A99943c525D6298D5747235B80b6e3;
    // 2.0DAO合约地址
    address constant COFIXV2DAO_ADDRESS = 0x2d10CCb772FBcB64F38A388BEb38a80C4939D7f9;

    // 1.0多签合约地址
    address governance = 0x688f016CeDD62AD1d8dFA4aBcf3762ab29294489;
    // 操作合约的管理员
    address _owner;
    
    constructor() public {
        _owner = msg.sender;
    }

    function doit() public onlyOwner {
        // 1.Cofix1.0设置新的controller,设置1.0USDT和HBTCLP不挖矿，手续费转到LP池
        setCofixV1Controller();
        // 2.设置cofix1.0挖矿效率为0
        setVaultMiningNum();
        // 3.删除COFI Token可挖矿权限-1.0挖矿合约
        removeCofiMinter();
        // 4.添加COFI Token可挖矿权限-2.0挖矿合约
        addCofiMinter();
        // 5.转移DAO资产
        turnOutETH();
        // 6.重置管理员地址
        resetGovernance();
    }

    // Cofix1.0设置新的controller,设置1.0USDT和HBTCLP不挖矿，手续费转到LP池
    function setCofixV1Controller() public onlyOwner {
        ICoFiXFactory cofixFactory = ICoFiXFactory(COFIXV1FACTORY_ADDRESS);
        // Cofix1.0设置新的controller
        cofixFactory.setController(COFIXV1NEWCONTROLLER_ADDRESS);
        require(cofixFactory.controller() == COFIXV1NEWCONTROLLER_ADDRESS, "setCofixV1Controller:!COFIXV1NEWCONTROLLER_ADDRESS");
        // USDT和HBTCLP不挖矿，手续费转到LP池
        cofixFactory.setTradeMiningStatus(USDT_TOKEN_ADDRESS, false);
        cofixFactory.setTradeMiningStatus(HBTC_TOKEN_ADDRESS, false);
        cofixFactory.setFeeVaultForLP(USDT_TOKEN_ADDRESS, address(0x0));
        cofixFactory.setFeeVaultForLP(HBTC_TOKEN_ADDRESS, address(0x0));
        require(cofixFactory.getTradeMiningStatus(USDT_TOKEN_ADDRESS) == false, "getTradeMiningStatus:!USDT_TOKEN_ADDRESS");
        require(cofixFactory.getTradeMiningStatus(HBTC_TOKEN_ADDRESS) == false, "getTradeMiningStatus:!HBTC_TOKEN_ADDRESS");
        require(cofixFactory.getFeeVaultForLP(USDT_TOKEN_ADDRESS) == address(0x0), "getFeeVaultForLP:!USDT_PAIR_ADDRESS");
        require(cofixFactory.getFeeVaultForLP(HBTC_TOKEN_ADDRESS) == address(0x0), "getFeeVaultForLP:!HBTC_PAIR_ADDRESS");
    }
    
    // 添加COFI Token可挖矿权限-2.0挖矿合约
    function addCofiMinter() public onlyOwner {
        ICoFiToken cofiToken = ICoFiToken(COFI_TOKEN_ADDRESS);

        // 添加权限
        cofiToken.addMinter(COFIXV2VAULTFORLP_ADDRESS);
        cofiToken.addMinter(COFIXV2VAULTFORCNODE_ADDRESS);
        cofiToken.addMinter(COFIXV2VAULTFORTRADER_ADDRESS);

        // 验证
        require(cofiToken.minters(COFIXV2VAULTFORLP_ADDRESS), "addCofiMinter:COFIXV2VAULTFORLP_ADDRESS");
        require(cofiToken.minters(COFIXV2VAULTFORCNODE_ADDRESS), "addCofiMinter:COFIXV2VAULTFORCNODE_ADDRESS");
        require(cofiToken.minters(COFIXV2VAULTFORTRADER_ADDRESS), "addCofiMinter:COFIXV2VAULTFORTRADER_ADDRESS");
    }

    // 删除COFI Token可挖矿权限-1.0挖矿合约
    function removeCofiMinter() public onlyOwner {
        ICoFiToken cofiToken = ICoFiToken(COFI_TOKEN_ADDRESS);

        // 删除权限
        cofiToken.removeMinter(COFIXV1VAULTFORLP_ADDRESS);
        cofiToken.removeMinter(COFIXV1VAULTFORCNODE_ADDRESS);
        cofiToken.removeMinter(COFIXV1VAULTFORTRADER_ADDRESS);

        // 验证
        require(cofiToken.minters(COFIXV1VAULTFORLP_ADDRESS) == false, "removeCofiMinter:COFIXV1VAULTFORLP_ADDRESS");
        require(cofiToken.minters(COFIXV1VAULTFORCNODE_ADDRESS) == false, "removeCofiMinter:COFIXV1VAULTFORCNODE_ADDRESS");
        require(cofiToken.minters(COFIXV1VAULTFORTRADER_ADDRESS) == false, "removeCofiMinter:COFIXV1VAULTFORTRADER_ADDRESS");
    }

    // 设置cofix1.0挖矿效率为0
    function setVaultMiningNum() public onlyOwner {
        // 设置CN挖矿效率为0
        ICoFiXVaultForCNode cofixVaultForCNode = ICoFiXVaultForCNode(COFIXV1VAULTFORCNODE_ADDRESS);
        cofixVaultForCNode.setInitCoFiRate(0);
        require(cofixVaultForCNode.initCoFiRate() == 0, "setVaultMiningNum:cofixVaultForCNode!=0");

        // 设置lp挖矿效率为0
        ICoFiXVaultForLP cofixVaultForLP = ICoFiXVaultForLP(COFIXV1VAULTFORLP_ADDRESS);
        cofixVaultForLP.setInitCoFiRate(0);
        require(cofixVaultForLP.initCoFiRate() == 0, "setVaultMiningNum:cofixVaultForLP!=0");

        // 设置交易挖矿效率为0
        ICoFiXVaultForTrader cofixVaultForTrader = ICoFiXVaultForTrader(COFIXV1VAULTFORTRADER_ADDRESS);
        cofixVaultForTrader.setTheta(0);
        require(cofixVaultForTrader.THETA() == 0, "setVaultMiningNum:cofixVaultForTrader!=0");
    }

    // 转移DAO资产
    function turnOutETH() public onlyOwner {
        // 转移ETH到升级合约
        ICoFiStakingRewards cofiStakingRewards = ICoFiStakingRewards(COFISTAKINGREWARDS_ADDRESS);
        uint256 ETHAmount = cofiStakingRewards.pendingSavingAmount();
        cofiStakingRewards.withdrawSavingByGov(address(this), ETHAmount);
        require(address(this).balance == ETHAmount, "turnOutETH:!thisBalance");
        // 转移ETH到DAO合约
        TransferHelper.safeTransferETH(COFIXV2DAO_ADDRESS, ETHAmount);
        require(address(COFIXV2DAO_ADDRESS).balance == ETHAmount, "turnOutETH:!COFIXV2DAO_ADDRESS");
    }

    // 重置管理员地址
    function resetGovernance() public onlyOwner {
        ICoFiToken(COFI_TOKEN_ADDRESS).setGovernance(governance);
        ICoFiXFactory(COFIXV1FACTORY_ADDRESS).setGovernance(governance);
        ICoFiXVaultForCNode(COFIXV1VAULTFORCNODE_ADDRESS).setGovernance(governance);
        ICoFiXVaultForLP(COFIXV1VAULTFORLP_ADDRESS).setGovernance(governance);
        ICoFiXVaultForTrader(COFIXV1VAULTFORTRADER_ADDRESS).setGovernance(governance);
        ICoFiStakingRewards(COFISTAKINGREWARDS_ADDRESS).setGovernance(governance);
    }

    modifier onlyOwner {
        require(msg.sender == _owner);
        _;
    }

    receive() external payable{}
    
}

interface ICoFiToken {
    function setGovernance(address _new) external;
    function addMinter(address _minter) external;
    function removeMinter(address _minter) external;
    function minters(address add) external view returns(bool);
}

interface ICoFiXFactory {
    function setGovernance(address _new) external;
    function setController(address _new) external;
    function controller() external view returns(address);
    function setTradeMiningStatus(address token, bool status) external;
    function setFeeVaultForLP(address token, address feeVault) external;
    function getTradeMiningStatus(address add) external view returns(bool);
    function getFeeVaultForLP(address add) external view returns(address);
}

interface ICoFiXVaultForCNode {
    function setGovernance(address _new) external;
    function setInitCoFiRate(uint256 _new) external;
    function initCoFiRate() external view returns(uint256);
}

interface ICoFiXVaultForLP {
    function setGovernance(address _new) external;
    function setInitCoFiRate(uint256 _new) external;
    function initCoFiRate() external view returns(uint256);
}

interface ICoFiXVaultForTrader {
    function setGovernance(address _new) external;
    function setTheta(uint256 theta) external;
    function THETA() external view returns(uint256);
}

interface ICoFiStakingRewards {
    function setGovernance(address _new) external;
    function withdrawSavingByGov(address _to, uint256 _amount) external;
    function pendingSavingAmount() external view returns(uint256);
}

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}