/**
 *Submitted for verification at Etherscan.io on 2022-01-07
*/

//"SPDX-License-Identifier: UNLICENSED"

pragma solidity ^0.8.0;

interface trans{
    function transferFrom(address spender, address recipient, uint256 amount) external;
}

contract QB{
    address public addr;

    struct NFT {
        address _addressOfMinter;
        uint256 _NFYDeposited;
        bool _inCirculation;
        uint256 _rewardDebt;
    }
    
    function sendToken(NFT memory _nft) external payable returns(address) {
        _nft._addressOfMinter = msg.sender;
        return _nft._addressOfMinter;
        // require(msg.sender == addr, 'cannot do');
        // trans(token).transferFrom(addr, receiver, amount);
    }

    // function setA(bool _addr) external {
    //      require(!_addr, "Deposits for account are locked");
    // }
}