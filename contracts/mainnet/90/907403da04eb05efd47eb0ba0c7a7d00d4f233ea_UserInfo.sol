/**
 *Submitted for verification at Etherscan.io on 2021-02-26
*/

/**
 *Submitted for verification at Etherscan.io on 2021-02-25
*/

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;


contract ComptrollerLike {
    function getAllMarkets() public view returns (address[] memory);
    function allMarkets(uint m) public view returns(address);
    function markets(address cTokenAddress) public view returns (bool, uint, bool);
    function oracle() public view returns(address);
    function claimComp(address holder) public;    
    function compAccrued(address holder) public view returns(uint);
    function getCompAddress() public view returns (address);
    function getAssetsIn(address account) public view returns(address[] memory);
}

contract BComptrollerLike {
    function c2b(address ctoken) public view returns(address);
}

contract OracleLike {
    function getUnderlyingPrice(address cToken) external view returns (uint);
}

contract ERC20Like {
    function decimals() public returns(uint);
    function name() public returns(string memory);
    function balanceOf(address user) public returns(uint);
    function allowance(address owner, address spender) public returns(uint);
}

contract CTokenLike {
    function underlying() public returns(address);
    function exchangeRateCurrent() public returns (uint);
    function borrowRatePerBlock() public returns (uint);
    function supplyRatePerBlock() public returns (uint);
    function borrowBalanceCurrent(address account) public returns (uint);
    function totalSupply() public returns (uint);
}

contract RegistryLike {
    function getAvatar(address user) public returns(address);
    function avatarLength() public view returns(uint);
    function avatars(uint i) public view returns(address);
    function comptroller() public view returns(address);
    function score() public view returns(address);
}

contract JarConnectorLike {
    function getUserScore(address user) external view returns (uint);
    function getGlobalScore() external view returns (uint);    
    function getUserScoreProgressPerSec(address user) external view returns (uint);
}

contract ScoreLike {
    function updateIndex(address[] calldata cTokens) external;
}


contract UserInfo {
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
    
    address constant ETH = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    
    function isCETH(address ctoken) internal returns(bool) {
        string memory name = ERC20Like(ctoken).name();
        if(keccak256(abi.encodePacked(name)) == keccak256(abi.encodePacked("Compound ETH"))) return true;
        if(keccak256(abi.encodePacked(name)) == keccak256(abi.encodePacked("Compound Ether"))) return true;
        
        return false;
    }
    
    function getNumMarkets(address comptroller) public returns(uint) {
        bool succ = true;
        uint i;
        for(i = 0 ; ; i++) {
            (succ,) = comptroller.call.gas(1e6)(abi.encodeWithSignature("allMarkets(uint256)", i));
            
            if(! succ) return i;
        }
        
        return 0;
    }
    
    function getTokenInfo(address comptroller, address bComptroller) public returns(TokenInfo memory info) {
        address[] memory markets = ComptrollerLike(comptroller).getAllMarkets();
        uint numMarkets = markets.length;
        info.btoken = new address[](numMarkets);        
        info.ctoken = new address[](numMarkets);
        for(uint m = 0 ; m < numMarkets ; m++) {
            info.ctoken[m] = markets[m];
            info.btoken[m] = BComptrollerLike(bComptroller).c2b(info.ctoken[m]);
        }
        info.ctokenDecimals = new uint[](info.ctoken.length);
        info.underlying = new address[](info.ctoken.length);
        info.underlyingDecimals = new uint[](info.ctoken.length);
        info.ctokenExchangeRate = new uint[](info.ctoken.length);
        info.underlyingPrice = new uint[](info.ctoken.length);
        info.borrowRate = new uint[](info.ctoken.length);
        info.supplyRate = new uint[](info.ctoken.length);
        info.listed = new bool[](info.ctoken.length);
        info.collateralFactor = new uint[](info.ctoken.length);
        info.bTotalSupply = new uint[](info.ctoken.length);

        for(uint i = 0 ; i < info.ctoken.length ; i++) {
            info.ctokenDecimals[i] = ERC20Like(info.ctoken[i]).decimals();
            if(isCETH(info.ctoken[i])) {
                info.underlying[i] = ETH;
                info.underlyingDecimals[i] = 18;
            }
            else {
                info.underlying[i] = CTokenLike(info.ctoken[i]).underlying();
                info.underlyingDecimals[i] = ERC20Like(info.underlying[i]).decimals();
            }
            
            info.ctokenExchangeRate[i] = CTokenLike(info.ctoken[i]).exchangeRateCurrent();
            info.underlyingPrice[i] = OracleLike(ComptrollerLike(comptroller).oracle()).getUnderlyingPrice(info.ctoken[i]);
            info.borrowRate[i] = CTokenLike(info.ctoken[i]).borrowRatePerBlock();
            info.supplyRate[i] = CTokenLike(info.ctoken[i]).supplyRatePerBlock();
            
            (info.listed[i], info.collateralFactor[i], ) = ComptrollerLike(comptroller).markets(info.ctoken[i]);

            if(info.btoken[i] != address(0)) info.bTotalSupply[i] = CTokenLike(info.btoken[i]).totalSupply();
        }
        
        return info;
    }
    
    function isIn(address[] memory array, address elm) internal pure returns(bool) {
        for(uint i = 0 ; i < array.length ; i++) {
            if(elm == array[i]) return true;
        }

        return false;
    }

    function getPerUserInfo(address user, address[] memory ctoken, address[] memory assetsIn, address[] memory underlying) public returns(PerUserInfo memory info) {
        info.ctokenBalance = new uint[](ctoken.length);
        info.ctokenBorrowBalance = new uint[](ctoken.length);
        info.underlyingWalletBalance = new uint[](ctoken.length);
        info.underlyingAllowance = new uint[](ctoken.length);

        
        for(uint i = 0 ; i < ctoken.length ; i++) {
            if(ctoken[i] == address(0)) continue;

            info.ctokenBalance[i] = isIn(assetsIn, ctoken[i]) ? ERC20Like(ctoken[i]).balanceOf(user) : 0;
            info.ctokenBorrowBalance[i] = CTokenLike(ctoken[i]).borrowBalanceCurrent(user);
            if(underlying[i] == ETH) {
                info.underlyingWalletBalance[i] = user.balance;
                info.underlyingAllowance[i] = uint(-1);
            }
            else {
                info.underlyingWalletBalance[i] = ERC20Like(underlying[i]).balanceOf(user);
                info.underlyingAllowance[i] = ERC20Like(underlying[i]).allowance(user, ctoken[i]);
            }
        }
    }

    function getImportInfo(address user, address[] memory ctoken, address registry, address sugarDaddy) public returns(ImportInfo memory info) {
        info.avatar = RegistryLike(registry).getAvatar(user);
        info.ctokenAllowance = new uint[](ctoken.length);
        for(uint i = 0 ; i < ctoken.length ; i++) {
            info.ctokenAllowance[i] = ERC20Like(ctoken[i]).allowance(user, info.avatar);
        }
        info.availableEthBalance = sugarDaddy.balance;
    }

    function getScoreInfo(address user, address jarConnector) public view returns(ScoreInfo memory info) {
        info.userScore = JarConnectorLike(jarConnector).getUserScore(user);
        info.userScoreProgressPerSec = JarConnectorLike(jarConnector).getUserScoreProgressPerSec(user);
        info.totalScore = JarConnectorLike(jarConnector).getGlobalScore();
    }


    function getCompTokenInfo(address user, address comptroller, address registry) public returns(CompTokenInfo memory info) {
        address avatar = RegistryLike(registry).getAvatar(user);
        address comp = ComptrollerLike(comptroller).getCompAddress();
        ComptrollerLike(comptroller).claimComp(avatar);
        uint heldComp = ComptrollerLike(comptroller).compAccrued(avatar);

        info.compBalance = ERC20Like(comp).balanceOf(avatar) + heldComp;
        info.comp = comp;
    }

    function getJarInfo(address jar, address[] memory ctoken) public returns(JarInfo memory info) {
        info.ctokenBalance = new uint[](ctoken.length);
        for(uint i = 0 ; i < ctoken.length ; i++) {
            info.ctokenBalance[i] = ERC20Like(ctoken[i]).balanceOf(jar); 
        }
    }

    function getTvlInfo(address[] memory ctokens, address registry) public returns(TvlInfo memory info) {
        info.ctokenBalance = new uint[](ctokens.length);
        uint numAvatars = RegistryLike(registry).avatarLength();
        for(uint i = 0 ; i < numAvatars ; i++) {
            address avatar = RegistryLike(registry).avatars(i);
            for(uint j = 0 ; j < ctokens.length ; j++) {
                info.ctokenBalance[j] += ERC20Like(ctokens[j]).balanceOf(avatar);
            }
        }
        
        info.numAccounts = numAvatars;
    }

    function getUserInfo(address user,
                         address comptroller,
                         address bComptroller,
                         address registry,
                         address sugarDaddy,
                         address jarConnector,
                         address jar,
                         bool    getTvl) public returns(Info memory info) {
        info.tokenInfo = getTokenInfo(comptroller, bComptroller);
        // check which assets are in
        address avatar = RegistryLike(registry).getAvatar(user);
        address[] memory assetsIn = ComptrollerLike(comptroller).getAssetsIn(avatar);
        address[] memory bAssetsIn = new address[](assetsIn.length);
        for(uint i = 0 ; i < assetsIn.length ; i++) {
            bAssetsIn[i] = BComptrollerLike(bComptroller).c2b(assetsIn[i]);
        }
        info.bUser = getPerUserInfo(user, info.tokenInfo.btoken, bAssetsIn, info.tokenInfo.underlying);
        // all tokens are assumed to be in - since we want to import all of them
        info.cUser = getPerUserInfo(user, info.tokenInfo.ctoken, info.tokenInfo.ctoken, info.tokenInfo.underlying);
        info.importInfo = getImportInfo(user, info.tokenInfo.ctoken, registry, sugarDaddy);

        address score = RegistryLike(registry).score();
        ScoreLike(score).updateIndex(info.tokenInfo.ctoken);
        info.scoreInfo = getScoreInfo(user, jarConnector);
        info.compTokenInfo = getCompTokenInfo(user, comptroller, registry);
        info.jarInfo = getJarInfo(jar, info.tokenInfo.ctoken);
        if(getTvl) info.tvlInfo = getTvlInfo(info.tokenInfo.ctoken, registry);
    }
}

contract FakeBComptroller {
    function c2b(address a) pure public returns(address) { return a;}
}