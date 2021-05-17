/**
 *Submitted for verification at Etherscan.io on 2021-05-17
*/

pragma solidity ^0.8.4;

contract CoFiXUpdate {
    // COFI Token地址
    address constant COFI_TOKEN_ADDRESS = 0x1a23a6BfBAdB59fa563008c0fB7cf96dfCF34Ea1;
    // USDT Token地址
    address constant USDT_TOKEN_ADDRESS = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    // HBTC Token地址
    address constant HBTC_TOKEN_ADDRESS = 0x0316EB71485b0Ab14103307bf65a021042c6d380;

    // 1.0合约地址
    // 工厂合约地址
    address constant COFIXV1FACTORY_ADDRESS = 0x66C64ecC3A6014733325a8f2EBEE46B4CA3ED550;
    // lp挖矿合约地址
    address constant COFIXV1VAULTFORLP_ADDRESS = 0x6903b1C17A5A0A9484c7346E5c0956027A713fCF;
    // cn挖矿合约地址
    address constant COFIXV1VAULTFORCNODE_ADDRESS = 0x7eDa8251aC08E7898E986DbeC4Ba97B421d545DD;
    // 交易挖矿合约地址
    address constant COFIXV1VAULTFORTRADER_ADDRESS = 0xE6183d3094a9e360B123Ec1330afAE76A74d1cbF;
    // 分红合约地址
    address constant COFISTAKINGREWARDS_ADDRESS = 0x0061c52768378b84306b2665f098c3e0b2C03308;
    // 对接nest3.6的controller
    address constant COFIXV1NEWCONTROLLER_ADDRESS = 0xB99DB9674e03A2cB07c3D7d92406aE1a3BBB9f56;

    // 2.0地址
    // 2.0lp挖矿合约地址
    address constant COFIXV2VAULTFORLP_ADDRESS = 0x618B7b93b07Bf78D04B2e8FB2B1C3B48049F8ED5;
    // 2.0cn挖矿合约地址
    address constant COFIXV2VAULTFORCNODE_ADDRESS = 0x3881292cE52AeD0EdAFF1AC7A40DA12AB2453B84;
    // 2.0交易挖矿合约地址
    address constant COFIXV2VAULTFORTRADER_ADDRESS = 0xb29A8d980E1408E487B9968f5E4f7fD7a9B0CaC5;
    // 2.0DAO合约地址
    address constant COFIXV2DAO_ADDRESS = 0x278f5d08bEa1989BEfcC09A20ad60fB39702D556;

    // 1.0多签合约地址
    address governance = 0xF51d8FdF98286e1EA846c79f1526ECC95b93AbB8;
    // 操作合约的管理员
    address _owner;
    
    constructor() public {
        _owner = msg.sender;
    }

    function doit() public onlyOwner {
        // 1.设置1.0USDT和HBTCLP不挖矿，手续费转到LP池
        setMiningZero();
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

    // Cofix1.0设置新的controller
    function setCofixV1Controller() public onlyOwner {
        ICoFiXFactory cofixFactory = ICoFiXFactory(COFIXV1FACTORY_ADDRESS);
        // Cofix1.0设置新的controller
        cofixFactory.setController(COFIXV1NEWCONTROLLER_ADDRESS);
        require(cofixFactory.controller() == COFIXV1NEWCONTROLLER_ADDRESS, "setCofixV1Controller:!COFIXV1NEWCONTROLLER_ADDRESS");
    }
    
    // 设置1.0USDT和HBTCLP不挖矿，手续费转到LP池
    function setMiningZero() public onlyOwner {
        ICoFiXFactory cofixFactory = ICoFiXFactory(COFIXV1FACTORY_ADDRESS);
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
        require(address(this).balance >= ETHAmount, "turnOutETH:!thisBalance");
        // 转移ETH到DAO合约
        TransferHelper.safeTransferETH(COFIXV2DAO_ADDRESS, ETHAmount);
        require(address(COFIXV2DAO_ADDRESS).balance >= ETHAmount, "turnOutETH:!COFIXV2DAO_ADDRESS");
    }

    // 重置管理员地址
    function resetGovernance() public onlyOwner {
        resetGovernance_COFI_TOKEN();
        resetGovernance_COFIXV1FACTORY();
        resetGovernance_COFIXV1VAULTFORCNODE();
        resetGovernance_COFIXV1VAULTFORLP();
        resetGovernance_COFIXV1VAULTFORTRADER();
        resetGovernance_COFISTAKINGREWARDS();
    }
    
    function resetGovernance_COFI_TOKEN() public onlyOwner {
        ICoFiToken(COFI_TOKEN_ADDRESS).setGovernance(governance);
    }
    
    function resetGovernance_COFIXV1FACTORY() public onlyOwner {
        ICoFiXFactory(COFIXV1FACTORY_ADDRESS).setGovernance(governance);
    }
    
    function resetGovernance_COFIXV1VAULTFORCNODE() public onlyOwner {
        ICoFiXVaultForCNode(COFIXV1VAULTFORCNODE_ADDRESS).setGovernance(governance);
    }
    
    function resetGovernance_COFIXV1VAULTFORLP() public onlyOwner {
        ICoFiXVaultForLP(COFIXV1VAULTFORLP_ADDRESS).setGovernance(governance);
    }
    
    function resetGovernance_COFIXV1VAULTFORTRADER() public onlyOwner {
        ICoFiXVaultForTrader(COFIXV1VAULTFORTRADER_ADDRESS).setGovernance(governance);
    }
    
    function resetGovernance_COFISTAKINGREWARDS() public onlyOwner {
        ICoFiStakingRewards(COFISTAKINGREWARDS_ADDRESS).setGovernance(governance);
    }
    
    function resetGovernance_CUS(address add) public onlyOwner {
        require(add != address(0x0), "resetGovernance_CUS:0x0");
        ICoFiToken(COFI_TOKEN_ADDRESS).setGovernance(add);
        ICoFiXFactory(COFIXV1FACTORY_ADDRESS).setGovernance(add);
        ICoFiXVaultForCNode(COFIXV1VAULTFORCNODE_ADDRESS).setGovernance(add);
        ICoFiXVaultForLP(COFIXV1VAULTFORLP_ADDRESS).setGovernance(add);
        ICoFiXVaultForTrader(COFIXV1VAULTFORTRADER_ADDRESS).setGovernance(add);
        ICoFiStakingRewards(COFISTAKINGREWARDS_ADDRESS).setGovernance(add);
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