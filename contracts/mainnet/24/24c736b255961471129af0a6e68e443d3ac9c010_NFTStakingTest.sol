/**
 *Submitted for verification at Etherscan.io on 2021-06-17
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;



interface RaribleInterface {
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external;
    function setApprovalForAll(address _operator, bool _approved) external;
}

contract NFTStakingTest {
    
    RaribleInterface rarible =  RaribleInterface(0xd07dc4262BCDbf85190C01c996b4C06a461d2430);

    function depositNFT(uint id, uint value) public {
        rarible.setApprovalForAll(address(this), true);
        require(rarible.balanceOf(address(msg.sender), id) >= value);
        rarible.safeTransferFrom(address(msg.sender), address(this), id, value, "");
    }

    function withdrawNFT(uint id, uint value) public {
        rarible.safeTransferFrom(address(this), address(msg.sender), id, value, "");
    }

    function nftIDBalance(uint id) public view returns(uint) {
        uint nftBalance = rarible.balanceOf(address(msg.sender), id);
        return nftBalance;
    }
}