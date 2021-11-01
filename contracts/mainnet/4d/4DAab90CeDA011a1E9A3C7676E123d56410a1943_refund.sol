/**
 *Submitted for verification at Etherscan.io on 2021-11-01
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.6.8;



// Part: IERC721

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

// File: refund.sol

contract refund {

    IERC721 public froggies;
    address private owner;
    uint256 public refunded;
    mapping(uint256 => bool) tokenRedeemed;

    constructor(address _froggies) public {
        froggies = IERC721(_froggies);
        owner = msg.sender;
    }

    receive() external payable {
        refunded += msg.value;
    }
    

    function refundTokens(uint256[] memory _tokenids) public {
        uint256 r;
        require(_tokenids.length > 0);
        for(uint256 i = 0; i < _tokenids.length; i++) {
            require(_tokenids[i] <= 1284, "not in snapshot");
            require(froggies.ownerOf(_tokenids[i]) == msg.sender, "not owner");
            require(tokenRedeemed[_tokenids[i]] != true, "already claimed");
            tokenRedeemed[_tokenids[i]] = true;
            r += 0.05 ether;
        }
        payable(msg.sender).transfer(r + tx.gasprice);
    }

    function withdraw() public {
        require(msg.sender == owner);
        refunded -= address(this).balance;
        payable(msg.sender).transfer(address(this).balance);
    }



}