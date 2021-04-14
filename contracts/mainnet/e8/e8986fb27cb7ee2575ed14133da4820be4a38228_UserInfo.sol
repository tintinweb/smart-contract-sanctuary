/**
 *Submitted for verification at Etherscan.io on 2021-04-13
*/

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;


contract ComptrollerLike {
    function getAssetsIn(address account) public view returns(address[] memory);
}

contract BComptrollerLike {
    function c2b(address ctoken) public view returns(address);
}

contract RegistryLike {
    function getAvatar(address user) public returns(address);
}

contract UserInfoLike {
    struct TokenInfo {
        address[] btoken;
        address[] ctoken;
        uint[] ctokenDecimals;
        address[] underlying;
        uint[] underlyingDecimals;
        uint[] ctokenExchangeRate;
        uint[] underlyingPrice;
        uint[] borrowRate;
        uint[] supplyRate;
        bool[] listed;
        uint[] collateralFactor;
        uint[] bTotalSupply;
    }
    
    struct PerUserInfo {
        uint[] ctokenBalance;
        uint[] ctokenBorrowBalance;
        uint[] underlyingWalletBalance;
        uint[] underlyingAllowance;
    }

    struct ScoreInfo {
        uint userScore;
        uint userScoreProgressPerSec;        
        uint totalScore;
    }

    struct ImportInfo {
        address avatar;
        uint[]  ctokenAllowance;
        uint    availableEthBalance; 
    }

    struct CompTokenInfo {
        uint    compBalance;
        address comp;
    }

    struct JarInfo {
        uint[] ctokenBalance;
    }
    
    struct TvlInfo {
        uint numAccounts;
        uint[] ctokenBalance;
    }

    struct Info {
        TokenInfo     tokenInfo;
        PerUserInfo   cUser; // data on compound
        PerUserInfo   bUser; // data on B
        ImportInfo    importInfo;
        ScoreInfo     scoreInfo;
        CompTokenInfo compTokenInfo;
        JarInfo       jarInfo;
        TvlInfo       tvlInfo;
    }
    
    function getTokenInfo(address comptroller, address bComptroller) public returns(TokenInfo memory info);
    function getPerUserInfo(address user, address[] memory ctoken, address[] memory assetsIn, address[] memory underlying) public returns(PerUserInfo memory info);
    function getImportInfo(address user, address[] memory ctoken, address registry, address sugarDaddy) public returns(ImportInfo memory info);
    function getScoreInfo(address user, address jarConnector) public view returns(ScoreInfo memory info);
    function getCompTokenInfo(address user, address comptroller, address registry) public returns(CompTokenInfo memory info);
    function getJarInfo(address jar, address[] memory ctoken) public returns(JarInfo memory info);
    function getTvlInfo(address[] memory ctokens, address registry) public returns(TvlInfo memory info);
}

contract UserInfo {
    UserInfoLike constant USER_INFO = UserInfoLike(0x907403DA04EB05EFd47eB0BA0C7a7d00d4f233EA);
    
    function getUserInfo(address user,
                         address comptroller,
                         address bComptroller,
                         address registry,
                         address sugarDaddy,
                         address jarConnector,
                         address jar,
                         bool    getTvl) public returns(UserInfoLike.Info memory info) {
        info.tokenInfo = USER_INFO.getTokenInfo(comptroller, bComptroller);
        // check which assets are in
        address avatar = RegistryLike(registry).getAvatar(user);
        address[] memory assetsIn = ComptrollerLike(comptroller).getAssetsIn(avatar);
        address[] memory bAssetsIn = new address[](assetsIn.length);
        for(uint i = 0 ; i < assetsIn.length ; i++) {
            bAssetsIn[i] = BComptrollerLike(bComptroller).c2b(assetsIn[i]);
        }
        info.bUser = USER_INFO.getPerUserInfo(user, info.tokenInfo.btoken, bAssetsIn, info.tokenInfo.underlying);
        // all tokens are assumed to be in - since we want to import all of them
        info.cUser = USER_INFO.getPerUserInfo(user, info.tokenInfo.ctoken, info.tokenInfo.ctoken, info.tokenInfo.underlying);
        info.importInfo = USER_INFO.getImportInfo(user, info.tokenInfo.ctoken, registry, sugarDaddy);

        info.scoreInfo = USER_INFO.getScoreInfo(user, jarConnector);
        info.compTokenInfo = USER_INFO.getCompTokenInfo(user, comptroller, registry);
        info.jarInfo = USER_INFO.getJarInfo(jar, info.tokenInfo.ctoken);
        if(getTvl) info.tvlInfo = USER_INFO.getTvlInfo(info.tokenInfo.ctoken, registry);
    }
}