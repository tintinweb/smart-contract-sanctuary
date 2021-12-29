/**
 *Submitted for verification at Etherscan.io on 2021-12-27
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.7;

interface MagicERC20 {
    function symbol() external returns(string memory);
    function balanceOf(address _owner) external view returns (uint256);
}

/// @author @karmacoma_eth
contract KarmaGang {
    event NewSubmission(address addr, string twitterHandle, string freeformMessage, bool claimDevDaoNft);

    error SenderAddressNotCoolEnough(address);
    error SenderNotMagicEnough(uint, uint);
    error SenderIsContract(address);

    mapping (address => bool) public coolSenders;
    mapping (address => bool) public definitelyNotContract;

    function register() external {
        if (msg.sender.code.length == 0) {
            definitelyNotContract[msg.sender] = true;
        }
    }

    /// A little holiday code challenge, with 3 DEV DAO Genesis NFTs to be claimed for aspiring web3 devs 💖
    /// If you just want to complete the challenge for fun, set `claimDevDaoNft` to `false`
    function submit(string calldata twitterHandle, string calldata freeformMessage, bool claimDevDaoNft) external {
        uint balanceThen = MagicERC20(msg.sender).balanceOf(address(this));

        // 1. you got to be cool
        coolSenders[msg.sender] = uint160(msg.sender) >> (8 * 17) == 0xc0de42;
        if (!coolSenders[msg.sender]) revert SenderAddressNotCoolEnough(msg.sender);

        // 2. you got to be magic
        uint balanceNow = MagicERC20(msg.sender).balanceOf(address(this));
        if (!(balanceNow > balanceThen)) revert SenderNotMagicEnough(balanceThen, balanceNow);

        // 3. you got to be a real human
        if (!definitelyNotContract[msg.sender]) revert SenderIsContract(msg.sender);

        // a winner is you! 👏
        emit NewSubmission(msg.sender, twitterHandle, freeformMessage, claimDevDaoNft);
    }
}