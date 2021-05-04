/**
 *Submitted for verification at Etherscan.io on 2021-05-04
*/

/**
 *Submitted for verification at Etherscan.io on 2021-05-04
*/

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;



contract ERC20Like {
    function balanceOf(address user) public view returns(uint);
}

contract CTokenLike {
    function borrowBalanceStored(address account) public view returns (uint);
}

contract RegistryLike {
    function avatarLength() public view returns(uint);
    function avatars(uint i) public view returns(address);
}

contract UserInfo {
    struct TvlInfo {
        uint numAccounts;
        uint[] ctokenBalance;
        uint[] ctokenBorrow;
    }

    function getTvlInfo(address[] memory ctokens, address registry) public view returns(uint[] memory ctokenBalance,
                                                                                        uint[] memory ctokenBorrow) {
        ctokenBalance = new uint[](ctokens.length);
        ctokenBorrow = new uint[](ctokens.length);
        uint numAvatars = RegistryLike(registry).avatarLength();
        for(uint i = 0 ; i < numAvatars ; i++) {
            address avatar = RegistryLike(registry).avatars(i);
            for(uint j = 0 ; j < ctokens.length ; j++) {
                ctokenBalance[j] += ERC20Like(ctokens[j]).balanceOf(avatar);
                ctokenBorrow[j] += CTokenLike(ctokens[j]).borrowBalanceStored(avatar);
            }
        }
    }
}

contract FakeBComptroller {
    function c2b(address a) pure public returns(address) { return a;}
}