/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.3;

// 升级合约
contract NEST36Update {
    
    // usdt地址
    address constant USDT_TOKEN_ADDRESS = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    // nest地址
    address constant NEST_TOKEN_ADDRESS = address(0x04abEdA201850aC0124161F037Efd70c74ddC74C);
    // NN地址
    address constant NEST_NODE_ADDRESS = address(0xC028E81e11F374f7c1A3bE6b8D2a815fa3E96E6e);
    
    //---3.5地址
    // 矿池 INestPool
    address constant NEST_POOL_ADDRESS = address(0xCA208DCfbEF22941D176858A640190C2222C8c8F);
    // DAO
    // INestDAO
    address constant NEST_DAO_ADDRESS = address(0x105ee568DaB631b8ff84f328Bc48e95387dfFB4f);
    // nest挖矿合约
    // INestMining35
    address constant NEST_MINING35_ADDRESS = address(0x243f207F9358cf67243aDe4A8fF3C5235aa7b8f6);
    
    //---3.6合约地址
    // nest挖矿合约 
    address constant NEST_MINING_ADDRESS = address(0x03dF236EaCfCEf4457Ff7d6B88E8f00823014bcd);
    // NN挖矿合约
    address constant NN_INCOME_ADDRESS = address(0x95557DE67444B556FE6ff8D7939316DA0Aa340B2);
    // DAO账本
    address constant NEST_LEDGER_ADDRESS = address(0x34B931C7e5Dc45dDc9098A1f588A0EA0dA45025D);
    // 管理合约
    address constant NEST_GOVERNANCE_ADDRESS = address(0xA2eFe217eD1E56C743aeEe1257914104Cf523cf5);
    // nTokenController
    // INTokenController
    address constant NTOKEN_CONTROLLER_ADDRESS = address(0xc4f1690eCe0145ed544f0aee0E2Fa886DFD66B62);
    // NestRedeeming
    address constant NEST_REDEEMING_ADDRESS = address(0xF48D58649dDb13E6e29e03059Ea518741169ceC8);
    
    // token数量
    uint constant TOKEN_COUNT = 58;

    function _tokenList() private pure returns (address[TOKEN_COUNT] memory) {
        // token列表
        return [0xdAC17F958D2ee523a2206206994597C13D831ec7,
                0x0316EB71485b0Ab14103307bf65a021042c6d380,
                0x6f259637dcD74C767781E37Bc6133cd6A68aa161,
                0xa66Daa57432024023DB65477BA87D4E7F5f95213,
                0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599,
                0x514910771AF9Ca656af840dff83E8264EcF986CA,
                0x6B175474E89094C44Da98b954EedeAC495271d0F,
                0x3212b29E33587A00FB1C83346f5dBFA69A458923,
                0xdF574c24545E5FfEcb9a659c229253D4111d87e1,
                0xb3104b4B9Da82025E8b9F8Fb28b3553ce2f67069,
                0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2,
                0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
                0x0D8775F648430679A709E98d2b0Cb6250d2887EF,
                0xdd974D5C2e2928deA5F71b9825b8b646686BD200,
                0x75231F58b43240C9718Dd58B4967c5114342a86c,
                0xE41d2489571d322189246DaFA5ebDe1F4699F498,
                0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F,
                0xD46bA6D942050d489DBd938a2C909A5d5039A161,
                0x0F5D2fB29fb7d3CFeE444a200298f468908cC942,
                0xc00e94Cb662C3520282E6f5717214004A7f26888,
                0x0000000000085d4780B73119b644AE5ecd22b376,
                0x960b236A07cf122663c4303350609A66A7B288C0,
                0x408e41876cCCDC0F92210600ef50372656052a38,
                0x80fB784B7eD66730e8b1DBd9820aFD29931aab03,
                0xBBbbCA6A901c926F240b89EacB641d8Aec7AEafD,
                0x11eeF04c884E24d9B7B4760e7476D06ddF797f36,
                0x8E870D67F660D95d5be530380D0eC0bd388289E1,
                0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D,
                0xba100000625a3754423978a60c9317c58a424e3D,
                0x4Cd988AfBad37289BAAf53C13e98E2BD46aAEa8c,
                0xa1d0E215a23d7030842FC67cE582a6aFa3CCaB83,
                0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e,
                0xd26114cd6EE289AccF82350c8d8487fedB8A0C07,
                0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984,
                0xaAC679720204aAA68B6C5000AA87D789a3cA0Aa5,
                0xBA11D00c5f74255f56a5E366F4F77f5A186d7f55,
                0xD533a949740bb3306d119CC777fa900bA034cd52,
                0x8762db106B2c2A0bccB3A80d1Ed41273552616E8,
                0x0d438F3b5175Bebc262bF23753C1E53d03432bDE,
                0x476c5E26a75bd202a9683ffD34359C0CC15be0fF,
                0x04Fa0d235C4abf4BcF4787aF4CF447DE572eF828,
                0x1776e1F26f98b1A5dF9cD347953a26dd3Cb46671,
                0x9ffc3bCDe7B68C46a6dC34f0718009925c1867cB,
                0x221657776846890989a759BA2973e427DfF5C9bB,
                0xF629cBd94d3791C9250152BD8dfBDF380E2a3B9c,
                0x1a23a6BfBAdB59fa563008c0fB7cf96dfCF34Ea1,
                0x57Ab1ec28D129707052df4dF418D58a2D46d5f51,
                0x6B3595068778DD592e39A122f4f5a5cF09C90fE2,
                0x9AFb950948c2370975fb91a441F36FDC02737cD4,
                0x4Fabb145d64652a948d72533023f6E7A623C7C53,
                0x8dAEBADE922dF735c38C80C7eBD708Af50815fAa,
                0x14007c545e6664C8370F27fa6B99DC830e6510a6,
                0xB64ef51C888972c908CFacf59B47C1AfBC0Ab8aC,
                0x85Eee30c52B0b379b046Fb0F85F4f3Dc3009aFEC,
                0x0Ae055097C6d159879521C384F1D2123D1f195e6,
                0x2c000c0093dE75a8fA2FccD3d97b314e20b431C3,
                0x3845badAde8e6dFF049820680d1F14bD3903a5d0,
                0x1F573D6Fb3F13d689FF844B4cE37794d79a7FF1C];
    }

    function _ntokenList() private pure returns (address[TOKEN_COUNT] memory) {
        // ntoken列表
        return [0x04abEdA201850aC0124161F037Efd70c74ddC74C,
                0x1F832091fAf289Ed4f50FE7418cFbD2611225d46,
                0x55B9D8475bd87c4eD47D0C161999EEab4d330C4F,
                0xe5A153bD9270973F9dE557c60D819be7EC62E066,
                0xE4EcBca33c5e29d34263400912157d4ddb26b49d,
                0xA7cB028F4194EaCE616CE6605387a335Ae95ED7f,
                0xEd14feC6fB1a04DD6e04F04A7b5030BB06f86918,
                0x88Eb85C4dB7e955875a990D2488De57F2D524eF0,
                0x017E701B153d63e4eE96f1CdEb6930dBa060CED9,
                0xC4ee960700323AA22D0040A68ce915E1735b7048,
                0x5E17a41c59007abC492dB7C4C65B85eE26dc5Fcd,
                0xC85877048e34edf317fa6C151760CDbbE705c7a4,
                0xb7fF97D631bA9aEeb48a953eD27cC5F6C0C42Be3,
                0x24fCfB935b731C1b312F31324eBBDA7CEbcaC57e,
                0x387f14A4C43Ea1E694CBA3a30638073222ec33b5,
                0x3D4fe58F7A3203c168504fEf624820898Fb56E4B,
                0x75Cb85F01B9436483F3B8f8bcaFB89e07e6B87ff,
                0x10fD3fbE5BE41748be8fd4B514A4219E5F079bbd,
                0x386E91E810ECE2B28C9e36F33B69cD19a63d5603,
                0x60c1386fbD6239e5cb430a984476DF80CC59F177,
                0xF529dcD5dDcD8E15084d6066602a63c776608d37,
                0xC0681693Fb25DB0cA72082aAdc407FBeC84b6F8A,
                0x731cFd398e89573e246A10712F213902839FBB50,
                0x1Ec8b1D7Ad6f53096fE6686313Beef3394D8D73d,
                0x798f8677a322B86A5A9201d00A6C0E69699D6e57,
                0xd0Ecd1c2895F178fF0d461d5fb89CE2b21C8cE31,
                0x1E5922f4EF1c30E0780Dc017A83c5E9b3C26c857,
                0xa1a8aC9E3BfE5E45EF88b09AC6f8694859A0fe9f,
                0x0670eeC3b57ceCD88DA0835A1349212f51B0BC45,
                0x432b009284d36e57A79C8a07a06C44db44213762,
                0xFcc2e387d7caD4B599A69fb160c098028FB7015d,
                0x075190c6130EA0a3A7E40802F1D77F4Ea8f38fE2,
                0xb27B5c073436A6a1D2b08b5aDad0CB72249Ca5a1,
                0x73869e38DEEb35bD39C268F89FFAC2F31ab4aC06,
                0x71DB8019EF642bc79650045b261740705F052fd8,
                0x532e4dC827D0D0d391B731a64F01E76f9F32698a,
                0xc3AdD44372d250d59Ea211C7E13b8B5Ee58eB3bF,
                0x6F3f42EA2c2DB04399F98b93d038f198E933ad08,
                0xE4ebA4a66486c057b0Bc9A85676e4e1d61d37680,
                0xe58645f0416e503FBD362eDBfE3558994048d87B,
                0x4A244Fe3735DDE065E7C3eBF54D389b46cdE457a,
                0x4F417Ed67006e67396C43574a0B1eC1A999aA25B,
                0xd6Dd90DdA11B471434ae1fe580cF7574CbD15336,
                0x60d9Af8F7EA58D2906B01994a8e16D3C16cC390c,
                0x98d3205D307032B26e6dbAA0bFC4C4fe526ad822,
                0xa347DAD4CD014e70165085fbaEa6F9cCa9AE9316,
                0x00DB9600F13f8DC4D003b7fDE4e9587527209b2A,
                0x2cB3766dA1E21bd5b21EcdaEA3c3A879A7c5a410,
                0x8a0F90A072b98E87d31D6e90754B1c0dc3fB34B8,
                0xcA2a63756da62882832E77A5B2EbBAec1Bb019AC,
                0xBc6f3E053D014B1AD89B2918ccb97baE87a1250a,
                0xd7811b4dbe1610fa806f2CBEe98d88aA0FabA985,
                0x18abB1b83F5f50EA668Be64625fbBf1D1ba69a8E,
                0xAd674D7D751c384C10E4DAEE96D2650b88180cfd,
                0xd4d82783D38994ba462730F4098A9c183221Ea5F,
                0x6f92D1e8165658D0C3897F9859615ca73d54F3Cd,
                0x72fBDc8e67b1Cee84332Eadf2F8aD1E02A0Bd768,
                0x8444F4b634b0726166272d5F9A62184b04421C95];
    }

    // 管理员
    address _owner;
    
    constructor() {
        _owner = msg.sender;
    }
    
    // 更新
    function update() public {

        // 1.转移NEST
        transferNest();
        // 2.转移DAO资产
        transferDaoAssets();
        // 3.更新nToken和NN的映射合约
        changeMap();
        // 4.恢复3.5管理员
        setGov35();
    }
    
    // 恢复3.5管理员
    function setGov35() public onlyOwner {
        INestPool(NEST_POOL_ADDRESS).setGovernance(address(_owner));
        INestDAO(NEST_DAO_ADDRESS).loadGovernance();
    }
    
    // 设置ntoken映射-可以提前操作
    function setNToken() public onlyOwner {
        
        address[TOKEN_COUNT] memory tokenList = _tokenList();
        address[TOKEN_COUNT] memory ntokenList = _ntokenList();
        for(uint i = 0; i < TOKEN_COUNT; i++) {
            INTokenController(NTOKEN_CONTROLLER_ADDRESS).setNTokenMapping(tokenList[i], ntokenList[i], 1);
        }
    }
    
    //================================
    
    // 转移NEST
    function transferNest() public onlyOwner {

        // 0. 验证目标地址
        require(INestMining(NEST_MINING_ADDRESS).getAccountCount() == 1, "!NEST_MINING_ADDRESS");

        INestLedger(NEST_LEDGER_ADDRESS).totalETHRewards(NEST_TOKEN_ADDRESS);
        require(INestLedger(NEST_LEDGER_ADDRESS).checkApplication(NEST_REDEEMING_ADDRESS) == 1, "!NEST_LEDGER_ADDRESS");
        
        // 设置NN最新区块
        uint latestMinedHeight = INestMining35(NEST_MINING35_ADDRESS).latestMinedHeight();
        INNIncome(NN_INCOME_ADDRESS).setBlockCursor(latestMinedHeight);
        INNIncome(NN_INCOME_ADDRESS).increment();
        require(INNIncome(NN_INCOME_ADDRESS).getBlockCursor() == latestMinedHeight, "!NN_INCOME_ADDRESS");

        // 1. 从3.5的NestPool取出矿池的nest
        uint nestGov_front = INestPool(NEST_POOL_ADDRESS).getMinerNest(address(this));
        INestPool(NEST_POOL_ADDRESS).drainNest(address(this), nestGov_front, address(this));
        require(IERC20(NEST_TOKEN_ADDRESS).balanceOf(address(this)) == nestGov_front, "!nestGov_front");
        // 管理员nest置空
        INestPool(NEST_POOL_ADDRESS).setGovernance(address(this));
        
        // 2. 80%分给nest挖矿合约 
        uint nestMiningAmount_front = IERC20(NEST_TOKEN_ADDRESS).balanceOf(address(NEST_MINING_ADDRESS));
        uint nestMiningAmount = nestGov_front * 80 / 100;
        require(IERC20(NEST_TOKEN_ADDRESS).transfer(NEST_MINING_ADDRESS, nestMiningAmount), "transfer:nestMiningAmount");
        require(IERC20(NEST_TOKEN_ADDRESS).balanceOf(address(NEST_MINING_ADDRESS)) == nestMiningAmount_front + nestMiningAmount, "!NEST_MINING_ADDRESS");
        
        // 3. 5%分给DAO账本
        uint nestLedgerAmount_front = IERC20(NEST_TOKEN_ADDRESS).balanceOf(address(NEST_LEDGER_ADDRESS));
        uint nestLedgerAmount = nestGov_front * 5 / 100;
        require(IERC20(NEST_TOKEN_ADDRESS).transfer(NEST_LEDGER_ADDRESS, nestLedgerAmount), "transfer:nestLedgerAmount");
        require(IERC20(NEST_TOKEN_ADDRESS).balanceOf(address(NEST_LEDGER_ADDRESS)) == nestLedgerAmount_front + nestLedgerAmount, "!NEST_LEDGER_ADDRESS");

        // 4. 15%分给NN挖矿合约
        uint NNIncomeAmount_front = IERC20(NEST_TOKEN_ADDRESS).balanceOf(address(NN_INCOME_ADDRESS));
        uint NNIncomeAmount = nestGov_front * 15 / 100;
        require(IERC20(NEST_TOKEN_ADDRESS).transfer(NN_INCOME_ADDRESS, NNIncomeAmount), "transfer:NNIncomeAmount");
        require(IERC20(NEST_TOKEN_ADDRESS).balanceOf(address(NN_INCOME_ADDRESS)) == NNIncomeAmount_front + NNIncomeAmount, "!NN_INCOME_ADDRESS");
        
    }
    
    // 转移DAO资产
    function transferDaoAssets() public onlyOwner {

        // 更新管理员地址
        INestDAO(NEST_DAO_ADDRESS).loadGovernance();

        // 领取剩余 nest
        INestDAO(NEST_DAO_ADDRESS).collectNestReward();

        // 转移资产
        address[] memory list = new address[](TOKEN_COUNT);
        address[TOKEN_COUNT] memory ntokenList = _ntokenList();
        for (uint i = 0; i < TOKEN_COUNT; i++) {
            list[i] = ntokenList[i];
        }
        INestDAO(NEST_DAO_ADDRESS).migrateTo(NEST_LEDGER_ADDRESS, list);
    }
    
    // 更新nToken和NN的映射合约
    function changeMap() public onlyOwner {

        require(INestGovernance(NEST_GOVERNANCE_ADDRESS).checkOwners(address(this)), "!checkOwners");
        // 排除NEST
        address[TOKEN_COUNT] memory ntokenList = _ntokenList();
        for(uint i = 1; i < TOKEN_COUNT; i++) {
            INest_NToken(ntokenList[i]).changeMapping(NEST_GOVERNANCE_ADDRESS);
        }
        
        ISuperMan(NEST_NODE_ADDRESS).changeMapping(NEST_GOVERNANCE_ADDRESS);
    }

    modifier onlyOwner {
        require(msg.sender == _owner);
        _;
    }
    
}

// ERC20合约
interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address who) external view returns (uint);
    function allowance(address _owner, address spender) external view returns (uint);
    function transfer(address to, uint value) external returns (bool);
    function approve(address spender, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed _owner, address indexed spender, uint value);
}

// 3.6nest挖矿合约
interface INestMining {
    function getNTokenAddress(address tokenAddress) external view returns (address);

    /// @dev Get the length of registered account array
    /// @return The length of registered account array
    function getAccountCount() external view returns (uint);
}

// 3.6DAO账本
interface INestLedger {
    function totalETHRewards(address ntokenAddress) external view returns (uint);

    /// @dev Check DAO application flag
    /// @param addr DAO application contract address
    /// @return Authorization flag, 1 means authorization, 0 means cancel authorization
    function checkApplication(address addr) external view returns (uint);
}

// 3.6NN挖矿合约
interface INNIncome {
    function increment() external view returns (uint);
    function setBlockCursor(uint blockCursor) external;
    /// @dev Get blockCursor value
    /// @return blockCursor value
    function getBlockCursor() external view returns (uint);
}

// 3.6管理员合约
interface INestGovernance {
    function checkOwners(address addr) external view returns (bool);
    function setGovernance(address addr, uint flag) external;
}

// 3.6NTokenController
interface INTokenController {
    function setNTokenMapping(address tokenAddress, address ntokenAddress, uint state) external;
}

// 3.5矿池合约
interface INestPool {
    // 取出nest
    function drainNest(address to, uint amount, address gov) external;
    // 查询nest数量
    function getMinerNest(address miner) external view returns (uint nestAmount);
    // 设置管理员
    function setGovernance(address _gov) external;
}

// 3.5DAO合约
interface INestDAO {
    // 转移资产
    function migrateTo(address newDAO_, address[] memory ntokenL_) external;
    // 取出剩余 nest(5%)
    function collectNestReward() external returns(uint);
    // 更新管理员地址
    function loadGovernance() external;
}

// 3.5挖矿合约
interface INestMining35{
    function latestMinedHeight() external view returns (uint64);
}

// NToken合约
interface INest_NToken {
    // 更改映射
    function changeMapping (address voteFactory) external;
}

// NN合约
interface ISuperMan {
    // 更改映射
    function changeMapping(address map) external;
}

// 3.0ntoken映射合约
interface INest_NToken_TokenMapping {
    function checkTokenMapping(address token) external view returns (address);
}