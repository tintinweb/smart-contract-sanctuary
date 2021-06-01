/**
 *Submitted for verification at Etherscan.io on 2021-05-31
*/

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

interface ListInterface {
    function accounts() external view returns (uint64);
    function accountAddr(uint64) external view returns (address);
}

interface AccountInterface {
    function version() external view returns (uint64);
}

contract InstaDSAPowerResolver {

    struct DSAs {
        address dsa;
        uint256 version;
    }

    function getTotalAccounts() public view returns(uint totalAccounts) {
        ListInterface list = ListInterface(0x4c8a1BEb8a87765788946D6B19C6C6355194AbEb);
        totalAccounts = uint(list.accounts());
    }

    function getDSAWalletsData(uint start, uint end) public view returns(DSAs[] memory wallets) {
        assert(start < end);
        ListInterface list = ListInterface(0x4c8a1BEb8a87765788946D6B19C6C6355194AbEb);
        uint totalAccounts = uint(list.accounts());
        end = totalAccounts < end ? totalAccounts : end;
        uint len = (end - start) + 1;
        wallets = new DSAs[](len);
        for (uint i = 0; i < len; i++) {
            address dsa = list.accountAddr(uint64(start + i));
            wallets[i] = DSAs({
                dsa: dsa,
                version: AccountInterface(dsa).version()
            });
        }
        return wallets;
    }

    function getDSAWallets(uint start, uint end) public view returns(address[] memory) {
        assert(start < end);
        ListInterface list = ListInterface(0x4c8a1BEb8a87765788946D6B19C6C6355194AbEb);
        uint totalAccounts = uint(list.accounts());
        end = totalAccounts < end ? totalAccounts : end;
        uint len = (end - start) + 1;
        address[] memory wallets = new address[](len);
        for (uint i = 0; i < len; i++) {
            wallets[i] = list.accountAddr(uint64(start + i));
        }
        return wallets;
    }

    function getDSAVersions(address[] memory dsas) public view returns(uint256[] memory versions) {
        versions = new uint256[](dsas.length);
        for (uint i = 0; i < dsas.length; i++) {
            versions[i] = AccountInterface(dsas[i]).version();
        }
        return versions;
    }
}