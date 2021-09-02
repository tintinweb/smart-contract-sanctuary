/**
 *Submitted for verification at polygonscan.com on 2021-09-02
*/

// SPDX-License-Identifier: MIT @GoPocketStudio
pragma solidity ^0.7.5;
pragma abicoder v2;

interface IERC1155 {
    function balanceOf(address account, uint256 id) external view returns (uint256);
}

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract NFTBalanceChecker {
    
    /* Fallback function, don't accept any ETH */
    receive() external payable {
        // revert();
        revert("BalanceChecker does not accept payments");
    }

    function isContract(address token) public view returns(bool){
        // check if token is actually a contract
        uint256 tokenCode;
        assembly { tokenCode := extcodesize(token) } // contract code size
        return tokenCode > 0;
    }

    function balances(address[] memory users, address[] memory tokens, uint256[] memory ids) external view returns (uint[] memory) {
        uint[] memory addrBalances = new uint[](tokens.length * users.length);
        for (uint i = 0; i < users.length; i++) {
            for (uint j = 0; j < tokens.length; j++) {
                uint addrIdx = j + tokens.length * i;
                if (isContract(tokens[j])) {
                    IERC1155 t = IERC1155(tokens[j]);
                    addrBalances[addrIdx] = t.balanceOf(users[i], ids[j]);
                } else {
                    addrBalances[addrIdx] = 0;
                }
                
            }
        }
        return addrBalances;
    }

    function owners(address[] memory users, address[] memory tokens, uint256[] memory ids) external view returns (address[] memory) {
        address[] memory addrBalances = new address[](tokens.length * users.length);
        for (uint i = 0; i < users.length; i++) {
            for (uint j = 0; j < tokens.length; j++) {
                uint addrIdx = j + tokens.length * i;
                if (isContract(tokens[j])) {
                    IERC721 t = IERC721(tokens[j]);
                    addrBalances[addrIdx] = t.ownerOf(ids[j]);
                } else {
                    addrBalances[addrIdx] = address(0x0);
                }
                
            }
        }
        return addrBalances;
    }
}