// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

// ██████████████     ▐████▌     ██████████████
// ██████████████     ▐████▌     ██████████████
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
// ██████████████     ▐████▌     ██████████████
// ██████████████     ▐████▌     ██████████████
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌

pragma solidity 0.8.9;

/// @title IKeepTokenStaking
/// @notice Interface for Keep TokenStaking contract
interface IKeepTokenStaking {
    /// @notice Seize provided token amount from every member in the misbehaved
    /// operators array. The tattletale is rewarded with 5% of the total seized
    /// amount scaled by the reward adjustment parameter and the rest 95% is burned.
    /// @param amountToSeize Token amount to seize from every misbehaved operator.
    /// @param rewardMultiplier Reward adjustment in percentage. Min 1% and 100% max.
    /// @param tattletale Address to receive the 5% reward.
    /// @param misbehavedOperators Array of addresses to seize the tokens from.
    function seize(
        uint256 amountToSeize,
        uint256 rewardMultiplier,
        address tattletale,
        address[] memory misbehavedOperators
    ) external;

    /// @notice Gets stake delegation info for the given operator.
    /// @param operator Operator address.
    /// @return amount The amount of tokens the given operator delegated.
    /// @return createdAt The time when the stake has been delegated.
    /// @return undelegatedAt The time when undelegation has been requested.
    /// If undelegation has not been requested, 0 is returned.
    function getDelegationInfo(address operator)
        external
        view
        returns (
            uint256 amount,
            uint256 createdAt,
            uint256 undelegatedAt
        );

    /// @notice Gets the stake owner for the specified operator address.
    /// @return Stake owner address.
    function ownerOf(address operator) external view returns (address);

    /// @notice Gets the beneficiary for the specified operator address.
    /// @return Beneficiary address.
    function beneficiaryOf(address operator)
        external
        view
        returns (address payable);

    /// @notice Gets the authorizer for the specified operator address.
    /// @return Authorizer address.
    function authorizerOf(address operator) external view returns (address);

    /// @notice Gets the eligible stake balance of the specified address.
    /// An eligible stake is a stake that passed the initialization period
    /// and is not currently undelegating. Also, the operator had to approve
    /// the specified operator contract.
    ///
    /// Operator with a minimum required amount of eligible stake can join the
    /// network and participate in new work selection.
    ///
    /// @param operator address of stake operator.
    /// @param operatorContract address of operator contract.
    /// @return balance an uint256 representing the eligible stake balance.
    function eligibleStake(address operator, address operatorContract)
        external
        view
        returns (uint256 balance);
}

/// @title INuCypherStakingEscrow
/// @notice Interface for NuCypher StakingEscrow contract
interface INuCypherStakingEscrow {
    /// @notice Slash the staker's stake and reward the investigator
    /// @param staker Staker's address
    /// @param penalty Penalty
    /// @param investigator Investigator
    /// @param reward Reward for the investigator
    function slashStaker(
        address staker,
        uint256 penalty,
        address investigator,
        uint256 reward
    ) external;

    /// @notice Request merge between NuCypher staking contract and T staking contract.
    ///         Returns amount of staked tokens
    function requestMerge(address staker, address operator)
        external
        returns (uint256);

    /// @notice Get all tokens belonging to the staker
    function getAllTokens(address staker) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later

// ██████████████     ▐████▌     ██████████████
// ██████████████     ▐████▌     ██████████████
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
// ██████████████     ▐████▌     ██████████████
// ██████████████     ▐████▌     ██████████████
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌

pragma solidity 0.8.9;

import "./ILegacyTokenStaking.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title KEEP ManagedGrant contract interface
interface IManagedGrant {
    function grantee() external view returns (address);
}

/// @title KEEP stake owner resolver
/// @notice T network staking contract supports existing KEEP stakes by allowing
///         KEEP stakers to use their stakes in T network and weights them based
///         on KEEP<>T token ratio. KEEP stake owner is cached in T staking
///         contract and used to restrict access to all functions only owner or
///         operator should call. To cache KEEP staking contract in T staking
///         contract, it fitst needs to resolve the owner. Resolving liquid
///         KEEP stake owner is easy. Resolving token grant stake owner is
///         complicated and not possible to do on-chain from a contract external
///         to KEEP TokenStaking contract. Keep TokenStaking knows the grant ID
///         but does not expose it externally.
///
///         KeepStake contract addresses this problem by exposing
///         operator-owner mappings snapshotted off-chain based on events and
///         information publicly available from KEEP TokenStaking contract and
///         KEEP TokenGrant contract. Additionally, it gives the Governance
///         ability to add new mappings in case they are ever needed; in
///         practice, this will be needed only if someone decides to stake their
///         KEEP token grant in KEEP network after 2021-11-11 when the snapshot
///         was taken.
///
///         Operator-owner pairs were snapshotted 2021-11-11 in the following
///         way:
///         1. Fetch all TokenStaking events from KEEP staking contract.
///         2. Filter out undelegated operators.
///         3. Filter out canceled delegations.
///         4. Fetch grant stake information from KEEP TokenGrant for that
///            operator to determine if we are dealing with grant delegation.
///         5. Fetch grantee address from KEEP TokenGrant contract.
///         6. Check if we are dealing with ManagedGrant by looking for all
///            created ManagedGrants and comparing their address against grantee
///            address fetched from TokenGrant contract.
contract KeepStake is Ownable {
    IKeepTokenStaking public immutable keepTokenStaking;

    mapping(address => address) public operatorToManagedGrant;
    mapping(address => address) public operatorToGrantee;

    constructor(IKeepTokenStaking _keepTokenStaking) {
        keepTokenStaking = _keepTokenStaking;
    }

    /// @notice Allows the Governance to set new operator-managed grant pair.
    ///         This function should only be called for managed grants if
    ///         the snapshot does include this pair.
    function setManagedGrant(address operator, address managedGrant)
        external
        onlyOwner
    {
        operatorToManagedGrant[operator] = managedGrant;
    }

    /// @notice Allows the Governance to set new operator-grantee pair.
    ///         This function should only be called for non-managed grants if
    ///         the snapshot does include this pair.
    function setGrantee(address operator, address grantee) external onlyOwner {
        operatorToGrantee[operator] = grantee;
    }

    /// @notice Resolves KEEP stake owner for the provided operator address.
    ///         Reverts if could not resolve the owner.
    function resolveOwner(address operator) external view returns (address) {
        address owner = operatorToManagedGrant[operator];
        if (owner != address(0)) {
            return IManagedGrant(owner).grantee();
        }

        owner = operatorToGrantee[operator];
        if (owner != address(0)) {
            return owner;
        }

        owner = resolveSnapshottedManagedGrantees(operator);
        if (owner != address(0)) {
            return owner;
        }

        owner = resolveSnapshottedGrantees(operator);
        if (owner != address(0)) {
            return owner;
        }

        owner = keepTokenStaking.ownerOf(operator);
        require(owner != address(0), "Could not resolve the owner");

        return owner;
    }

    function resolveSnapshottedManagedGrantees(address operator)
        internal
        view
        returns (address)
    {
        if (operator == 0x855A951162B1B93D70724484d5bdc9D00B56236B) {
            return
                IManagedGrant(0xFADbF758307A054C57B365Db1De90acA71feaFE5)
                    .grantee();
        }
        if (operator == 0xF1De9490Bf7298b5F350cE74332Ad7cf8d5cB181) {
            return
                IManagedGrant(0xAEd493Aaf3E76E83b29E151848b71eF4544f92f1)
                    .grantee();
        }
        if (operator == 0x39d2aCBCD80d80080541C6eed7e9feBb8127B2Ab) {
            return
                IManagedGrant(0xA2fa09D6f8C251422F5fde29a0BAd1C53dEfAe66)
                    .grantee();
        }
        if (operator == 0xd66cAE89FfBc6E50e6b019e45c1aEc93Dec54781) {
            return
                IManagedGrant(0x306309f9d105F34132db0bFB3Ce3f5B0245Cd386)
                    .grantee();
        }
        if (operator == 0x2eBE08379f4fD866E871A9b9E1d5C695154C6A9F) {
            return
                IManagedGrant(0xd00c0d43b747C33726B3f0ff4BDA4b72dc53c6E9)
                    .grantee();
        }
        if (operator == 0xA97c34278162b556A527CFc01B53eb4DDeDFD223) {
            return
                IManagedGrant(0xB3E967355c456B1Bd43cB0188A321592D410D096)
                    .grantee();
        }
        if (operator == 0x6C76d49322C9f8761A1623CEd89A31490cdB649d) {
            return
                IManagedGrant(0xB3E967355c456B1Bd43cB0188A321592D410D096)
                    .grantee();
        }
        if (operator == 0x4a41c7a884d119eaaefE471D0B3a638226408382) {
            return
                IManagedGrant(0xcdf3d216d82a463Ce82971F2F5DA3d8f9C5f093A)
                    .grantee();
        }
        if (operator == 0x9c06Feb7Ebc8065ee11Cd5E8EEdaAFb2909A7087) {
            return
                IManagedGrant(0x45119cd98d145283762BA9eBCAea75F72D188733)
                    .grantee();
        }
        if (operator == 0x9bD818Ab6ACC974f2Cf2BD2EBA7a250126Accb9F) {
            return
                IManagedGrant(0x6E535043377067621954ee84065b0bd7357e7aBa)
                    .grantee();
        }
        if (operator == 0x1d803c89760F8B4057DB15BCb3B8929E0498D310) {
            return
                IManagedGrant(0xB3E967355c456B1Bd43cB0188A321592D410D096)
                    .grantee();
        }
        if (operator == 0x3101927DEeC27A2bfA6c4a6316e3A221f631dB91) {
            return
                IManagedGrant(0x178Bf1946feD0e2362fdF8bcD3f91F0701a012C6)
                    .grantee();
        }
        if (operator == 0x9d9b187E478bC62694A7bED216Fc365de87F280C) {
            return
                IManagedGrant(0xFBad17CFad6cb00D726c65501D69FdC13Ca5477c)
                    .grantee();
        }
        if (operator == 0xd977144724Bc77FaeFAe219F958AE3947205d0b5) {
            return
                IManagedGrant(0x087B442BFd4E42675cf2df5fa566F87d7A96Fb12)
                    .grantee();
        }
        if (operator == 0x045E511f53DeBF55c9C0B4522f14F602f7C7cA81) {
            return
                IManagedGrant(0xFcfe8C036C414a15cF871071c483687095caF7D6)
                    .grantee();
        }
        if (operator == 0x3Dd301b3c96A282d8092E1e6f6846f24172D45C1) {
            return
                IManagedGrant(0xb5Bdd2D9B3541fc8f581Af37430D26527e59aeF8)
                    .grantee();
        }
        if (operator == 0x5d84DEB482E770479154028788Df79aA7C563aA4) {
            return
                IManagedGrant(0x9D1a179c469a8BdD0b683A9f9250246cc47e8fBE)
                    .grantee();
        }
        if (operator == 0x1dF927B69A97E8140315536163C029d188e8573b) {
            return
                IManagedGrant(0xb5Bdd2D9B3541fc8f581Af37430D26527e59aeF8)
                    .grantee();
        }
        if (operator == 0x617daCE069Fbd41993491de211b4DfccdAcbd348) {
            return
                IManagedGrant(0xb5Bdd2D9B3541fc8f581Af37430D26527e59aeF8)
                    .grantee();
        }
        if (operator == 0x650A9eD18Df873cad98C88dcaC8170531cAD2399) {
            return
                IManagedGrant(0x1Df7324A3aD20526DFa02Cc803eD2D97Cac81F3b)
                    .grantee();
        }
        if (operator == 0x07C9a8f8264221906b7b8958951Ce4753D39628B) {
            return
                IManagedGrant(0x305D12b4d70529Cd618dA7399F5520701E510041)
                    .grantee();
        }
        if (operator == 0x63eB4c3DD0751F9BE7070A01156513C227fa1eF6) {
            return
                IManagedGrant(0x306309f9d105F34132db0bFB3Ce3f5B0245Cd386)
                    .grantee();
        }
        if (operator == 0xc6349eEC31048787676b6297ba71721376A8DdcF) {
            return
                IManagedGrant(0xac1a985E75C6a0b475b9c807Ad0705a988Be2D99)
                    .grantee();
        }
        if (operator == 0x3B945f9C0C8737e44f8e887d4F04B5B3A491Ac4d) {
            return
                IManagedGrant(0x82e17477726E8D9D2C237745cA9989631582eE98)
                    .grantee();
        }
        if (operator == 0xF35343299a4f80Dd5D917bbe5ddd54eBB820eBd4) {
            return
                IManagedGrant(0xCC88c15506251B62ccCeebA193e100d6bBC9a30D)
                    .grantee();
        }
        if (operator == 0x3B9e5ae72d068448bB96786989c0d86FBC0551D1) {
            return
                IManagedGrant(0x306309f9d105F34132db0bFB3Ce3f5B0245Cd386)
                    .grantee();
        }
        if (operator == 0xB2D53Be158Cb8451dFc818bD969877038c1BdeA1) {
            return
                IManagedGrant(0xaE55e3800f0A3feaFdcE535A8C0fab0fFdB90DEe)
                    .grantee();
        }
        if (operator == 0xF6dbF7AFe05b8Bb6f198eC7e69333c98D3C4608C) {
            return
                IManagedGrant(0xbb8D24a20c20625f86739824014C3cBAAAb26700)
                    .grantee();
        }
        if (operator == 0xB62Fc1ADfFb2ab832041528C8178358338d85f76) {
            return
                IManagedGrant(0x9ED98fD1C29018B9342CB8F57A3073B9695f0c02)
                    .grantee();
        }
        if (operator == 0x9bC8d30d971C9e74298112803036C05db07D73e3) {
            return
                IManagedGrant(0x66beda757939f8e505b5Eb883cd02C8d4a11Bca2)
                    .grantee();
        }

        return address(0);
    }

    function resolveSnapshottedGrantees(address operator)
        internal
        pure
        returns (address)
    {
        if (operator == 0x1147ccFB4AEFc6e587a23b78724Ef20Ec6e474D4) {
            return 0x3FB49dA4375Ef9019f17990D04c6d5daD482D80a;
        }
        if (operator == 0x4c21541f95a00C03C75F38C71DC220bd27cbbEd9) {
            return 0xC897cfeE43a8d827F76D4226994D5CE5EBBe2571;
        }
        if (operator == 0x7E6332d18719a5463d3867a1a892359509589a3d) {
            return 0x1578eD833D986c1188D1a998aA5FEcD418beF5da;
        }
        if (operator == 0x8Bd660A764Ca14155F3411a4526a028b6316CB3E) {
            return 0xf6f372DfAeCC1431186598c304e91B79Ce115766;
        }
        if (operator == 0x4F4f0D0dfd93513B3f4Cb116Fe9d0A005466F725) {
            return 0x8b055ac1c4dd287E2a46D4a52d61FE76FB551bD0;
        }
        if (operator == 0x1DF0250027fEC876d8876d1ac7A392c9098F1a1e) {
            return 0xE408fFa969707Ce5d7aA3e5F8d44674Fa4b26219;
        }
        if (operator == 0x860EF3f83B6adFEF757F98345c3B8DdcFCA9d152) {
            return 0x08a3633AAb8f3E436DEA204288Ee26Fe094406b0;
        }
        if (operator == 0xe3a2d16dA142E6B190A5d9F7e0C07cc460B58A5F) {
            return 0x875f8fFCDDeD63B5d8Cf54be4E4b82FE6c6E249C;
        }
        if (operator == 0xBDE07f1cA107Ef319b0Bb26eBF1d0a5b4c97ffc1) {
            return 0x1578eD833D986c1188D1a998aA5FEcD418beF5da;
        }
        if (operator == 0xE86181D6b672d78D33e83029fF3D0ef4A601B4C4) {
            return 0x1578eD833D986c1188D1a998aA5FEcD418beF5da;
        }
        if (operator == 0xb7c561e2069aCaE2c4480111B1606790BB4E13fE) {
            return 0x1578eD833D986c1188D1a998aA5FEcD418beF5da;
        }
        if (operator == 0x526c013f8382B050d32d86e7090Ac84De22EdA4D) {
            return 0x61C6E5DDacded540CD08066C08cbc096d22D91f4;
        }

        return address(0);
    }
}