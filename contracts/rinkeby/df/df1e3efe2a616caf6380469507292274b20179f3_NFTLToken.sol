// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "./ERC20.sol";
import "./IERC20.sol";

contract NFTLToken is ERC20 {
    address public farmingContract;
    address public owner;

    IERC20 internal oldNFTL;
    uint256 private deployedAt;

    event SetAddFarmingContract(
        address indexed farmingContractAddr,
        address indexed _admin
    );

    constructor(
        address _owner,
        address _initialReceiver,
        uint256 _initialMintAmt,
        address _oldNFTLAddress
    ) ERC20("NFTL Token", "NFTL") public {
        owner = _owner;
        oldNFTL = IERC20(_oldNFTLAddress);
        _mint(_initialReceiver, _initialMintAmt);
        deployedAt = block.timestamp;
    }

    // mint tokens
    function mint(address _to, uint256 _amt) public {
        require(
            farmingContract == msg.sender,
            "CTFToken: You are not authorised to mint"
        );
        _mint(_to, _amt);
        require(totalSupply() <= 86000000 * (10**18));
    }

    function addFarmingContract(address _farmingContractAddr) public {
        require(msg.sender == owner, "CTFToken: You're not owner");
        require(
            farmingContract == address(0),
            "Farming Contract Already Added"
        );
        farmingContract = _farmingContractAddr;
        emit SetAddFarmingContract(_farmingContractAddr, msg.sender);
    }

    // migrate from v1 to v2
    function migrate() public {
        uint256 oldBalance = oldNFTL.balanceOf(msg.sender);
        require(
            deployedAt + 365 days >= block.timestamp,
            "CTFToken: Migration period is over"
        );
        // check if user has enough CTF tokens with old contract
        require(oldBalance > 0, "NFTLToken: Not eligible to migrate");
        // burn the old CTF tokens
        oldNFTL.transferFrom(msg.sender, 0x000000000000000000000000000000000000dEaD, oldBalance);
        // mint new tokens to the user
        _mint(msg.sender, oldBalance);
    }
}