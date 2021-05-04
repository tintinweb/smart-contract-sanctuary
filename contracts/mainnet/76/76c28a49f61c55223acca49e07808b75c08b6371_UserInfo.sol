/**
 *Submitted for verification at Etherscan.io on 2021-05-04
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
    struct TvlInfo {
        uint numAccounts;
        uint[] ctokenBalance;
        uint[] ctokenBorrow;
    }

    function getTvlInfo(address[] memory ctokens, address registry) public returns(TvlInfo memory info) {
        info.ctokenBalance = new uint[](ctokens.length);
        uint numAvatars = RegistryLike(registry).avatarLength();
        for(uint i = 0 ; i < numAvatars ; i++) {
            address avatar = RegistryLike(registry).avatars(i);
            for(uint j = 0 ; j < ctokens.length ; j++) {
                info.ctokenBalance[j] += ERC20Like(ctokens[j]).balanceOf(avatar);
                info.ctokenBorrow[j] += CTokenLike(ctokens[j]).borrowBalanceCurrent(avatar);
            }
        }
        
        info.numAccounts = numAvatars;
    }
}

contract FakeBComptroller {
    function c2b(address a) pure public returns(address) { return a;}
}