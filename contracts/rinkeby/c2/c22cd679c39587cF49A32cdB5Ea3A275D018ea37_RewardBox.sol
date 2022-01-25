// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Ownable.sol";

interface IRewardToken {
    function mint(address account, uint256 amount) external;
}

contract RewardBox is Ownable {
    string public constant CONTRACT_NAME = "RewardBox";
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
        );
    bytes32 public constant WITHDRAW_TYPEHASH =
        keccak256(
            "Withdraw(uint256[] withdrawalIds,uint256[] amounts,address user)"
        );

    IRewardToken public rewardToken;

    address public admin = 0xa1E40541060FB96Aa63E27DfD327b384c3a1CDe3;

    mapping(uint256 => bool) public withdrawal;

    event Withdraw(uint256 withdrawalId, uint256 amount, address user);

    constructor() {}

    function setBatt(IRewardToken _rewardToken) external onlyOwner {
        rewardToken = _rewardToken;
    }

    function changeAdmin(address newAdmin) external onlyOwner {
        admin = newAdmin;
    }

    function withdraw(
        uint256[] calldata withdrawalIds,
        uint256[] calldata amounts,
        address user,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(CONTRACT_NAME)),
                getChainId(),
                address(this)
            )
        );
        bytes32 structHash = keccak256(
            abi.encode(
                WITHDRAW_TYPEHASH,
                keccak256(abi.encodePacked(withdrawalIds)),
                keccak256(abi.encodePacked(amounts)),
                user
            )
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );
        address signatory = ecrecover(digest, v, r, s);
        require(signatory == admin, "Invalid signatory");

        uint256 total = 0;
        for (uint256 i = 0; i < withdrawalIds.length; i++) {
            uint256 id = withdrawalIds[i];
            if (!withdrawal[id] && amounts[i] > 0) {
                total += amounts[i];
                withdrawal[id] = true;
                emit Withdraw(id, amounts[i], user);
            }
        }

        if (total > 0) {
            rewardToken.mint(user, total);
        }
    }

    function getChainId() internal view returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}