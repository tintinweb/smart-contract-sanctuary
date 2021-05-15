/**
 *Submitted for verification at Etherscan.io on 2021-05-15
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.1;

contract Base{
    constructor ()  { }
    event Transfer(address from, address to, uint256 tokenId);

    mapping (uint256 => address) public IndexToOwner;
    mapping (address => uint256) public ownershipTokenCount;
    mapping (uint256 => address) public IndexToApproved;
    
    function getMyTokens(address myaddress) view public returns(uint[] memory){
        uint num = ownershipTokenCount[myaddress];
        uint found = 0;
        uint[] memory myTokens = new uint[](num);
        while (found<num){
            for (uint i=0; i<100; i++){
                if (IndexToOwner[i]==myaddress){
                    myTokens[found] = i;
                    found++;
                }
            }
        }
        return myTokens;
    }

    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        ownershipTokenCount[_to]++;
        IndexToOwner[_tokenId] = _to;
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
            // clear any previously approved ownership exchange
            delete IndexToApproved[_tokenId];
        }
        // Emit the transfer event.
        emit Transfer(_from, _to, _tokenId);
    }
}