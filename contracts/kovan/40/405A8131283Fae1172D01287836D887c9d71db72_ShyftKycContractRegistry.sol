/**
 *Submitted for verification at Etherscan.io on 2021-07-22
*/

pragma solidity ^0.7.1;
//SPDX-License-Identifier: UNLICENSED

/* New ERC23 contract interface */

interface IErc223 {
    function totalSupply() external view returns (uint);

    function balanceOf(address who) external view returns (uint);

    function transfer(address to, uint value) external returns (bool ok);
    function transfer(address to, uint value, bytes memory data) external returns (bool ok);
    
    event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
}

/**
* @title Contract that will work with ERC223 tokens.
*/

interface IErc223ReceivingContract {
    /**
     * @dev Standard ERC223 function that will handle incoming token transfers.
     *
     * @param _from  Token sender address.
     * @param _value Amount of tokens.
     * @param _data  Transaction metadata.
     */
    function tokenFallback(address _from, uint _value, bytes memory _data) external returns (bool ok);
}


interface IErc20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function transfer(address to, uint tokens) external returns (bool success);

    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}



interface IShyftKycContractRegistry  {
    function isShyftKycContract(address _addr) external view returns (bool result);
    function getCurrentContractAddress() external view returns (address);
    function getContractAddressOfVersion(uint _version) external view returns (address);
    function getContractVersionOfAddress(address _address) external view returns (uint256 result);

    function getAllTokenLocations(address _addr, uint256 _bip32X_type) external view returns (bool[] memory resultLocations, uint256 resultNumFound);
    function getAllTokenLocationsAndBalances(address _addr, uint256 _bip32X_type) external view returns (bool[] memory resultLocations, uint256[] memory resultBalances, uint256 resultNumFound, uint256 resultTotalBalance);
}










interface IShyftKycContract is IErc20, IErc223ReceivingContract {
    function balanceOf(address tokenOwner) external view override returns (uint balance);
    function totalSupply() external view override returns (uint);
    function transfer(address to, uint tokens) external override returns (bool success);

    function getShyftCacheGraphAddress() external view returns (address result);

    function getNativeTokenType() external view returns (uint256 result);

    function withdrawNative(address payable _to, uint256 _value) external returns (bool ok);
    function withdrawToExternalContract(address _to, uint256 _value, uint256 _gasAmount) external returns (bool ok);
    function withdrawToShyftKycContract(address _shyftKycContractAddress, address _to, uint256 _value) external returns (bool ok);

    function mintBip32X(address _to, uint256 _amount, uint256 _bip32X_type) external;
    function burnFromBip32X(address _account, uint256 _amount, uint256 _bip32X_type) external;

    function migrateFromKycContract(address _to) external payable returns(bool result);
    function updateContract(address _addr) external returns (bool);

    function transferBip32X(address _to, uint256 _value, uint256 _bip32X_type) external returns (bool result);
    function allowanceBip32X(address _tokenOwner, address _spender, uint256 _bip32X_type) external view returns (uint remaining);
    function approveBip32X(address _spender, uint _tokens, uint256 _bip32X_type) external returns (bool success);
    function transferFromBip32X(address _from, address _to, uint _tokens, uint256 _bip32X_type) external returns (bool success);

    function transferFromErc20TokenToBip32X(address _erc20ContractAddress, uint256 _value) external returns (bool ok);
    function withdrawTokenBip32XToErc20(address _erc20ContractAddress, address _to, uint256 _value) external returns (bool ok);

    function getBalanceBip32X(address _identifiedAddress, uint256 _bip32X_type) external view returns (uint256 balance);
    function getTotalSupplyBip32X(uint256 _bip32X_type) external view returns (uint256 balance);

    function getBip32XTypeForContractAddress(address _contractAddress) external view returns (uint256 bip32X_type);

    function kycSend(address _identifiedAddress, uint256 _amount, uint256 _bip32X_type, bool _requiredConsentFromAllParties, bool _payForDirty) external returns (uint8 result);

    function getOnlyAcceptsKycInput(address _identifiedAddress) external view returns (bool result);
    function getOnlyAcceptsKycInputPermanently(address _identifiedAddress) external view returns (bool result);
}




// Administrable Contract:
//
// The basic keyed permission access is done with a multiple signing & revocation certificate mechanism.
// Built to be as light-weight as possible and still provide the flexibility required to manage full stack
// dApp integrations.
//
// add/remove and threshold setting.

// @note:@security:@safety:@internalaudit: This function needs to be fully vetted and edge cases examined & documented.

contract Administrable {
    ///@dev An event for primary admin added.
    event EVT_PrimaryAdminAdded(address _admin);
    ///@dev An event for admin promotion.
    event EVT_AdminPromoted(address _admin);
    ///@dev An event for admin revocation.
    event EVT_AdminRevoked(address _admin);

    ///@dev An enum that is used to check whether the current state of the administrator has "administrative powers" so that we can keep a history of addresses that have acted as administrators, active or not.
    enum AdministratorAccess { Unknown, Promoted, Demoted }

    /// @dev An enum that is used to check the state of an administrators vote for multisig
    enum KeyPermissionAccess { Unknown, Signed, Revoked, Reset }

    /// @dev The minimum NofM multisig administrators confirmation thresholds.
    uint256 constant minimumMultiSignAdminConfirmationThreshold = 2;

    /// @dev The current NofM multisig administrators confirmation thresholds.
    uint256 adminConfirmationThreshold = 2;

    /// @dev A struct for the key permissions for a specific administrator.
    struct keyPermissions {
        mapping(address => KeyPermissionAccess) administratorSignatures;
        address[] administrators;

        uint256 numConfirmations;
    }

    /// @dev The constract creator/owner.
    address public owner;

    /// @dev A mapping of public addresses of public addresses to administrator access.
    mapping (address => AdministratorAccess) administrators;
    /// @dev The current number of administrators.
    uint256 public numAdministrators;

    /// @dev A mapping for a specific administrator public address to their multisigned key permissions array.
    mapping (bytes32 => keyPermissions) administratorMultisignPermissionedKeys;

    /// @dev A struct for the administration confirmation proposals.
    struct changeAdminConfirmationsProposal {
        uint256 adminThreshold;
        uint256 endTime;
        bool isCompleted;
    }

    /// @dev The current voting set nonce - updates on promotion/demotion of administrators to block stale sets from voting.
    bytes32 votingSetNonce;

    /// @dev An array of changes to the administrator NofM threshold confirmation
    changeAdminConfirmationsProposal[] proposals_changeAdminConfirmationThreshold;

    /// @dev Basic constructor function, sets owner to the contract creator.
    constructor() {
        owner = msg.sender;
    }

    // ** administrator management ** //
    /// @dev Gets the NofM threshold currently required for passing multisig votes.
    /// @return results the current NofM threshold
    function getAdminConfirmationThreshold() public view returns (uint256 results) {
        return adminConfirmationThreshold;
    }

    /// @dev Gets the level of access for a specific administrator.
    /// @return result the level of access for this administrator
    function getAdminAccess(address _administratorAddress) public view returns(AdministratorAccess result) {
        return administrators[_administratorAddress];
    }

    //@note: difficulties in management arise:
    // 1. if the current administrator(s) add new participants, the voting threshold remains, and thus means a hostile
    //    takeover is possible since new (sybil) administrators can vote to remove legitimate ones by threshold voting.
    //    @todo:@research:
    //
    // 2. if the current administrators first create one vote to change the threshold, the next administrator to start
    //    a new vote tries to create a threshold as well.
    //
    //    voting and confirming an older threshold vote will still work as long as the threshold is lower than the
    //    maximum number of signatures. so a (coalition) of bad actor administrators could hold off on the last vote,
    //    then when good actor administrators created a new vote, could pass it and then later on reset it to the value
    //    that the good actors set.
    //
    //    thus, we use the flexibility of the hashing system (with a sanity check) to add a 2 day maximum time period.
    //    as organization is able to be done such that a proper honest coalition is made, a proposal is initiated and
    //    then the voting begins with a 2 day window.

    /// @dev Gets the number of a specific NofM change proposal.
    /// @return result the number of a specific NofM proposals

    function getNumAdminConfirmationProposals() public view returns (uint256 result) {
        return proposals_changeAdminConfirmationThreshold.length;
    }

    /// @param _proposalIndex A proposal index
    /// @dev Gets the components of a specific NofM change proposal.
    /// @return adminThreshold the threshold of the NofM voting within this proposal
    /// @return endTime the end time of this proposal, after which it cannot be voted on
    /// @return isCompleted whether this proposal has been completed by multisig parties

    function getAdminConfirmationProposal(uint32 _proposalIndex) public view returns (uint256 adminThreshold, uint256 endTime, bool isCompleted) {
        return (proposals_changeAdminConfirmationThreshold[_proposalIndex].adminThreshold, proposals_changeAdminConfirmationThreshold[_proposalIndex].endTime, proposals_changeAdminConfirmationThreshold[_proposalIndex].isCompleted);
    }

    /// @param _newThreshold The new threshold (N of M multisig) that is needed to be passed.
    /// @dev This function proposes a change to the threshold of voting required (N signatories of M total set size = NofM). To prevent stale inattention results, timeout after 2 days.
    /// @return result
    ///    | 0 = not an administrator
    ///    | 1 = not enough administrators to achieve confirmation threshold
    ///    | 2 = new proposal added

    function proposeChangeCurrentAdminConfirmationThreshold(uint256 _newThreshold) public returns (uint8 result) {
        if (isAdministrator(msg.sender)) {
            if (_newThreshold > 0 && _newThreshold <= numAdministrators) {
                changeAdminConfirmationsProposal memory newProposal;
                newProposal.adminThreshold = _newThreshold;
                // setup time stamping for validity periods, end time set for 2 days.
                newProposal.endTime = block.timestamp + 2 days;

                proposals_changeAdminConfirmationThreshold.push(newProposal);

                // new proposal added
                return 2;
            } else {
                // not enough administrators to achieve confirmation threshold
                return 1;
            }
        } else {
            // not an administrator
            return 0;
        }
    }

    /// @param _proposalIndex The index for a specific proposal to change the current administrator confirmation threshold.
    /// @dev | This function takes in an index for a proposal ot change the current administrator confirmation threshold.
    ///      | Uses Multi-signature permissions.
    /// @notice Multiple proposals can be constructed for different sets to apply to change the administrator threshold. As the permissions for multisig keys use a voting set nonce underneath the hood, a change in the current administrator set will cancel all current votes.
    /// @return result
    ///    | 0 = not an administrator
    ///    | 1 = invalid proposal index
    ///    | 2 = not enough administrators to achieve confirmation threshold
    ///    | 3 = proposal has expired
    ///    | 4 = not enough administrators have permissioned change
    ///    | 5 = admin confirmation threshold set

    function changeCurrentAdminConfirmationThreshold(uint32 _proposalIndex) public returns (uint8 result) {
        if (isAdministrator(msg.sender)) {
            if (_proposalIndex < proposals_changeAdminConfirmationThreshold.length) {
                // sanity check for administrators being able to fulfill threshold.
                if (proposals_changeAdminConfirmationThreshold[_proposalIndex].adminThreshold <= numAdministrators) {
                    if (proposals_changeAdminConfirmationThreshold[_proposalIndex].isCompleted == false && block.timestamp <= proposals_changeAdminConfirmationThreshold[_proposalIndex].endTime) {
                        bytes32 keyKeccak = keccak256(abi.encodePacked("adminConfirmationThresholdProposal", _proposalIndex));

                        uint256 numPermissions = getPermissionsForMultisignKey(keyKeccak);

                        bool permittedToModify;

                        if (numPermissions >= adminConfirmationThreshold) {
                            permittedToModify = true;
                        } else {
                            uint256 numConfirmedPermissions = adminApplyAndGetPermissionsForMultisignKey(keyKeccak);

                            if (numConfirmedPermissions >= adminConfirmationThreshold) {
                                permittedToModify = true;
                            }
                        }

                        if (permittedToModify == true) {
                            adminConfirmationThreshold = proposals_changeAdminConfirmationThreshold[_proposalIndex].adminThreshold;

                            // set the endTime for this proposal to zero, disabling further voting on this proposal

                            proposals_changeAdminConfirmationThreshold[_proposalIndex].isCompleted = true;

                            adminResetPermissionsForMultisignKey(keyKeccak);

                            // admin confirmation threshold set
                            return 5;
                        } else {
                            // not enough administrators have permissioned change
                            return 4;
                        }
                    } else {
                        // proposal has expired
                        return 3;
                    }
                } else {
                    // not enough administrators to achieve confirmation threshold
                    return 2;
                }
            } else {
                // invalid proposal index
                return 1;
            }
        } else {
            // not an administrator
            return 0;
        }
    }

    /// @param _newAdministratorAddress The new Administrator's public address.
    /// @dev Sets the primary Administrator for this contract (or those that inherit from it). This transfers ownership of this contracts first administration duties (to find and onboard a second party for multisignature requirements) to the set Administrator's public address.
    /// @return result
    ///    | 0 = not owner
    ///    | 1 = already set first administrator
    ///    | 2 = setup first administrator

    function setPrimaryAdministrator(address _newAdministratorAddress) public virtual returns (uint8 result) {
        if (msg.sender == owner) {
            if (numAdministrators == 0) {
                administrators[_newAdministratorAddress] = AdministratorAccess.Promoted;
                numAdministrators++;

                emit EVT_PrimaryAdminAdded(_newAdministratorAddress);

                //setup first administrator
                return 2;
            } else {

                //already set first administrator
                return 1;
            }
        } else {
            //not owner
            return 0;
        }
    }

    /// @param _newAdministratorAddress The new Administrator's public address.
    /// @dev | Promotes a new administrator. If there is only a primary Administrator set, this will allow the addition of the second administrator and enable multisignature requirements for any actions of this contract (or those inheriting it).
    ///      | Uses Multi-signature permissions if there is more than one Administrator onboarded.
    /// @notice | Uses composition features (based on current validator set) so data structure may be orphaned when promotion/demotion events occur.
    ///         | Whenever this function is called (with a passing vote), there will be a re-hashing of the voting set nonce, so all current votes will become invalidated.
    /// @return result
    ///    | 0 = not administrator
    ///    | 1 = administrator already promoted
    ///    | 2 = new administrator promoted
    ///    | 3 = added vote to promote administrator

    function promoteAdministrator(address _newAdministratorAddress) public virtual returns (uint8 result) {
        if (isAdministrator(msg.sender)) {
            if (administrators[_newAdministratorAddress] != AdministratorAccess.Promoted) {
                //check for past the initial onboarding threshold limit
                if (numAdministrators >= minimumMultiSignAdminConfirmationThreshold) {
                    bytes32 keyKeccak = keccak256(abi.encodePacked("promoteAdministrator", _newAdministratorAddress));

                    uint256 numPermissions = getPermissionsForMultisignKey(keyKeccak);

                    bool permittedToModify;

                    if (numPermissions >= adminConfirmationThreshold) {
                        permittedToModify = true;
                    } else {
                        uint256 numConfirmedPermissions = adminApplyAndGetPermissionsForMultisignKey(keyKeccak);

                        if (numConfirmedPermissions >= adminConfirmationThreshold) {
                            permittedToModify = true;
                        }
                    }

                    if (permittedToModify == true) {
                        administrators[_newAdministratorAddress] = AdministratorAccess.Promoted;
                        numAdministrators++;

                        adminResetPermissionsForMultisignKey(keyKeccak);

                        updateVotingSetNonce(keccak256(abi.encodePacked("promoted", block.timestamp)));

                        emit EVT_AdminPromoted(_newAdministratorAddress);

                        //promoted administrator
                        return 2;
                    } else {
                        //added vote to promote administrator
                        return 3;
                    }
                } else {
                    administrators[_newAdministratorAddress] = AdministratorAccess.Promoted;
                    numAdministrators++;

                    updateVotingSetNonce(keccak256(abi.encodePacked("promoted", block.timestamp)));

                    emit EVT_AdminPromoted(_newAdministratorAddress);

                    //administrator promoted
                    return 2;
                }
            } else {
                //administrator already promoted
                return 1;
            }
        } else {
            //not administrator
            return 0;
        }
    }

    /// @param _revokeAdministratorAddress An existing Administrator's public address.
    /// @dev | Revokes an existing administrator from the multisignature set, checks to see if the # of required votes would be higher then the administrator set size, and if so adjusts to match.
    ///      | Uses Multi-signature permissions if there is more than one Administrator onboarded.
    /// @notice | Uses composition features (based on current validator set) so data structure may be orphaned when promotion/demotion events occur.
    ///         | Whenever this function is called (with a passing vote), there will be a re-hashing of the voting set nonce, so all current votes will become invalidated.
    /// @return result
    //    | 0 = not administrator
    //    | 1 = administrator already inactive
    //    | 2 = added vote to revoke administrator
    //    | 3 = revoked administrator

    function revokeAdministrator(address _revokeAdministratorAddress) public virtual returns (uint8 result) {
        if (isAdministrator(msg.sender)) {
            if (administrators[_revokeAdministratorAddress] == AdministratorAccess.Promoted) {
                bytes32 keyKeccak = keccak256(abi.encodePacked("administrationRevocationVote", _revokeAdministratorAddress));

                uint256 numPermissions = getPermissionsForMultisignKey(keyKeccak);

                bool permittedToModify;

                if (numPermissions >= adminConfirmationThreshold) {
                    permittedToModify = true;
                } else {
                    uint256 numConfirmedPermissions = adminApplyAndGetPermissionsForMultisignKey(keyKeccak);

                    if (numConfirmedPermissions >= adminConfirmationThreshold) {
                        permittedToModify = true;
                    }
                }

                if (permittedToModify == true) {
                    administrators[_revokeAdministratorAddress] = AdministratorAccess.Demoted;

                    numAdministrators--;

                    updateVotingSetNonce(keccak256(abi.encodePacked("revoked", block.timestamp)));

                    //@note: sanity check.. if admins are revoked past a threshold there can be no threshold confirmations
                    // possible, so reduce the adminConfirmationThreshold to match. Given the promoteAdministrator
                    // functionality, 2 is the lowest limit, and this will never restrict the second administrator being
                    // added.

                    if (numAdministrators < adminConfirmationThreshold) {
                        if (numAdministrators > minimumMultiSignAdminConfirmationThreshold) {
                            adminConfirmationThreshold = numAdministrators;
                        } else {
                            adminConfirmationThreshold = minimumMultiSignAdminConfirmationThreshold;
                        }
                    }

                    adminResetPermissionsForMultisignKey(keyKeccak);

                    emit EVT_AdminRevoked(_revokeAdministratorAddress);

                    //revoked administrator
                    return 3;
                } else {
                    //added vote to revoke administrator
                    return 2;
                }
            } else {
                //administrator already inactive
                return 1;
            }
        } else {
            //not administrator
            return 0;
        }
    }

    /// @param _mix A reference for the new voting set nonce to incorporate into the next "mix".
    /// @dev updates the voting set nonce.

    function updateVotingSetNonce(bytes32 _mix) internal {
        votingSetNonce = keccak256(abi.encodePacked(votingSetNonce, _mix));
    }

    /// @param _keyKeccak A hash to reference as the key/value vote subject.
    /// @dev Composes a new key keccak based on the further hashing of it with the current voting set nonce. This creates a situation where if all of the multisig check/update logic is "behind the scenes" and using this function as a reference to the "true" key/value pair, there will never be a situation where a vote can be completed by removing a contrary agent from the multisig pool (ie. there will need to be a new voting session based on the current validator set).
    /// @return result new composed key keccak

    function composeKeyKeccak(bytes32 _keyKeccak) internal view returns (bytes32 result) {
        return keccak256(abi.encodePacked(votingSetNonce, _keyKeccak));
    }

    /// @param _keyKeccak A hash to reference as the key/value vote subject.
    /// @dev Gets whether there have been a specific number of multisignature confirmations for a specific vote.
    /// @notice Uses composition features (based on current validator set) so data structure may be orphaned when promotion/demotion events occur.
    /// @return result 0 to numAdministrators = #confirmations

    function getPermissionsForMultisignKey(bytes32 _keyKeccak) public virtual view returns (uint256 result) {
        bytes32 composedKeyKeccak = composeKeyKeccak(_keyKeccak);
        //(one to the numAdministrators) #confirmations
        return administratorMultisignPermissionedKeys[composedKeyKeccak].numConfirmations;
    }

    /// @param _keyKeccak A hash to reference as the key/value vote subject.
    /// @dev Gets whether the admin is already confirmed with a multisignature vote.
    /// @notice Uses composition features (based on current validator set) so data structure may be orphaned when promotion/demotion events occur.
    /// @return result
    ///    | 0 = not administrator
    ///    | 1 = signature not found
    ///    | 2 = signature found
    ///    | 3 = access revoked

    function adminGetSelfConfirmedFromMultisignKey(bytes32 _keyKeccak) internal view returns (uint16 result) {
        if (isAdministrator(msg.sender)) {
            bytes32 composedKeyKeccak = composeKeyKeccak(_keyKeccak);

            if (administratorMultisignPermissionedKeys[composedKeyKeccak].administratorSignatures[msg.sender] == KeyPermissionAccess.Revoked) {
                //access revoked
                return 3;
            } else if (administratorMultisignPermissionedKeys[composedKeyKeccak].administratorSignatures[msg.sender] == KeyPermissionAccess.Signed) {
                //signature found
                return 2;
            } else {
                //signature not found
                return 1;
            }
        } else {
            //not administrator
            return 0;
        }
    }

    /// @param _keyKeccak A hash to reference as the key/value vote subject.
    /// @dev Applies an administrator's vote & updates the votes for a specific multisignature key/value object.
    /// @notice Uses composition features (based on current validator set) so data structure may be orphaned when promotion/demotion events occur.
    /// @return result
    ///    | 0 = not administrator
    ///    | 1 to numAdministrators = #confirmations

    function adminApplyAndGetPermissionsForMultisignKey(bytes32 _keyKeccak) internal virtual returns (uint256 result) {
        if (isAdministrator(msg.sender)) {
            bytes32 composedKeyKeccak = composeKeyKeccak(_keyKeccak);

            if (administratorMultisignPermissionedKeys[composedKeyKeccak].numConfirmations < numAdministrators &&
                (administratorMultisignPermissionedKeys[composedKeyKeccak].administratorSignatures[msg.sender] == KeyPermissionAccess.Unknown ||
                administratorMultisignPermissionedKeys[composedKeyKeccak].administratorSignatures[msg.sender] == KeyPermissionAccess.Reset)) {
                // increase permission level of the key, apply signature.
                administratorMultisignPermissionedKeys[composedKeyKeccak].numConfirmations++;
                administratorMultisignPermissionedKeys[composedKeyKeccak].administratorSignatures[msg.sender] = KeyPermissionAccess.Signed;

                administratorMultisignPermissionedKeys[composedKeyKeccak].administrators.push(msg.sender);
            }

            //(one to the numAdministrators) #confirmations
            return administratorMultisignPermissionedKeys[composedKeyKeccak].numConfirmations;
        } else {
            //not administrator
            return 0;
        }
    }

    /// @param _keyKeccak A hash to reference as the key/value vote subject.
    /// @dev Resets the permissions for a specific multisignature key/value object.
    /// @notice Uses composition features (based on current validator set) so data structure may be orphaned when promotion/demotion events occur.
    /// @return result
    ///    | 0 = not administrator
    ///    | 1 = already reset
    ///    | 2 = reset correctly

    function adminResetPermissionsForMultisignKey(bytes32 _keyKeccak) internal returns (uint8 result) {
        if (isAdministrator(msg.sender)) {
            bytes32 composedKeyKeccak = composeKeyKeccak(_keyKeccak);

            if (administratorMultisignPermissionedKeys[composedKeyKeccak].numConfirmations != 0) {
                //remove administrator references
                for (uint i = 0; i < administratorMultisignPermissionedKeys[composedKeyKeccak].administrators.length; i++) {
                    administratorMultisignPermissionedKeys[composedKeyKeccak].administratorSignatures[administratorMultisignPermissionedKeys[composedKeyKeccak].administrators[i]] = KeyPermissionAccess.Reset;
                }


                //delete the main holding array
                delete administratorMultisignPermissionedKeys[composedKeyKeccak].administrators;

                //and reset the permission level
                administratorMultisignPermissionedKeys[composedKeyKeccak].numConfirmations = 0;

                //reset correctly
                return 2;
            } else {
                //already reset
                return 1;
            }
        } else {
            //not administrator
            return 0;
        }
    }

    /// @param _confirmationNumber A number to reference as the confirmation number
    /// @dev Returns whether a reference number is over the system's administrator confirmation threshold (ie. the vote passes).
    /// @return result
    ///    | true = is over threshold
    ///    | false = not over threshold

    function isConfirmationsIsOverThreshold(uint256 _confirmationNumber) public virtual view returns (bool result) {
        if (_confirmationNumber >= adminConfirmationThreshold) {
            //is over threshold
            return true;
        } else {
            //not over threshold
            return false;
        }
    }

    /// @param _administratorAddress The public address of a specific administrator.
    /// @dev Returns whether a given address is an administrator.
    /// @return result
    ///    | true = is administrator
    ///    | false = either administrator unset or demoted

    function isAdministrator(address _administratorAddress) public virtual view returns (bool result) {
        if (administrators[_administratorAddress] == AdministratorAccess.Promoted) {
            //is administrator
            return true;
        } else {
            // either administrator unset or demoted
            return false;
        }
    }
}


// This contract acts as a registry between past and current versions of the ShyftKycContract
//
// Also, it has convenience functions for user balances & the versions of the blockchain they're
// using. All of the upgrade functions are hosted within ShyftKycContract.sol so tx.origin issues
// don't crop up.

contract ShyftKycContractRegistry is IShyftKycContractRegistry, Administrable {
    uint256 constant InvalidVersion = 2**256 -1;

    address[] public contracts;
    mapping(address => uint256) versions;
    mapping(address => bool) kycContractMapping;

    uint256 public currentContractVersion;

    constructor() {
        owner = msg.sender;
    }

    //@note: this will need to be called when the ShyftKycContract is deployed for the first time

    //returns:
    // 0 = not an administrator
    // 1 = not enough administrators have permissioned change
    // 2 = could not init
    // 3 = init completed

    function setShyftKycContractAddressInitial(address _initialKycContractAddress) public returns (uint8 result) {
        if (isAdministrator(msg.sender)) {
            bytes32 keyKeccak = keccak256(abi.encodePacked("init", _initialKycContractAddress));

            uint256 numPermissions = getPermissionsForMultisignKey(keyKeccak);

            bool permittedToModify;

            if (numPermissions >= adminConfirmationThreshold) {
                permittedToModify = true;
            } else {
                uint256 numConfirmedPermissions = adminApplyAndGetPermissionsForMultisignKey(keyKeccak);

                if (numConfirmedPermissions >= adminConfirmationThreshold) {
                    permittedToModify = true;
                }
            }

            if (permittedToModify == true) {
                if (doInit(_initialKycContractAddress) == true) {
                    adminResetPermissionsForMultisignKey(keyKeccak);

                    //init completed
                    return 3;
                } else {

                    adminResetPermissionsForMultisignKey(keyKeccak);
                    //could not init
                    return 2;
                }
            } else {
                //not enough administrators have permissioned change
                return 1;
            }
        } else {
            //not an administrator
            return 0;
        }
    }

    //returns:
    // false = already initialized
    // true = initialized contract
    function doInit(address _initialKycContractAddress) internal returns (bool result)  {
        if (contracts.length == 0){
            contracts.push(_initialKycContractAddress); // set original contract w/ version 0
            versions[_initialKycContractAddress] = 1;
            kycContractMapping[_initialKycContractAddress] = true;

            //initialized contract
            return true;
        } else {
            //already initialized
            return false;
        }
    }

    //returns:
    // 0 = not an administrator
    // 1 = not enough administrators have permissioned change
    // 2 = upgrade not completed
    // 3 = upgrade completed properly

    function upgradeShyftKycContract(address _newKycContractAddress) public returns (uint8 result) {
        if (isAdministrator(msg.sender)) {
            bytes32 keyKeccak = keccak256(abi.encodePacked("upgrade", _newKycContractAddress));

            uint256 numPermissions = getPermissionsForMultisignKey(keyKeccak);

            bool permittedToModify;

            if (numPermissions >= adminConfirmationThreshold) {
                permittedToModify = true;
            } else {
                uint256 numConfirmedPermissions = adminApplyAndGetPermissionsForMultisignKey(keyKeccak);

                if (numConfirmedPermissions >= adminConfirmationThreshold) {
                    permittedToModify = true;
                }
            }

            if (permittedToModify == true) {
                if (doUpgrade(_newKycContractAddress) == true) {
                    adminResetPermissionsForMultisignKey(keyKeccak);

                    //upgrade completed properly
                    return 3;
                } else {
                    adminResetPermissionsForMultisignKey(keyKeccak);

                    //upgrade not completed
                    return 2;
                }
            } else {
                //not enough administrators have permissioned change
                return 1;
            }
        } else {
            //not an administrator
            return 0;
        }
    }

    //returns
    // true = upgrade set up properly
    // false = @note: revert()s because of changes from calls :: upgrade did not succeed
    
    //@note: this will need to be called after an updated contract is deployed
    function doUpgrade(address _newKycContractAddress) internal returns (bool) {
        require(_newKycContractAddress != address(0), "new Kyc Contract address cannot be zero");

        if (contracts.length > 0) {
            contracts.push(_newKycContractAddress);
            versions[_newKycContractAddress] = currentContractVersion + 1;
            kycContractMapping[_newKycContractAddress] = true;

            currentContractVersion++;

            IShyftKycContract existingKycContract = IShyftKycContract(contracts[currentContractVersion-1]);
            bool didUpdate = existingKycContract.updateContract(_newKycContractAddress);

            if (didUpdate == true) {
                return true;
            } else {
                //@note: revert because of changed state downstream
                revert();
                //return false;
            }
        } else {
            //init has not been called
            return false;
        }
    }

    function isShyftKycContract(address _addr) public view override returns (bool result) {
        return kycContractMapping[_addr];
    }

    function getCurrentContractAddress() public view override returns (address) {
        return contracts[currentContractVersion];
    }

    function getContractAddressOfVersion(uint _version) public view override returns (address) {
        if (_version < contracts.length) {
            return contracts[_version];
        } else {
            return address(0);
        }
    }

    function getContractVersionOfAddress(address _address) public view override returns (uint256 result) {
        if (versions[_address] > 0) {
            return versions[_address] - 1;
        } else {
            //make sure that the address exists in the mapping, otherwise return max uint256
            return InvalidVersion;
        }
    }

    function getNumContracts() public view returns (uint256) {
        return contracts.length;
    }

    //@note: this function could potentially cost a lot of gas if you ran it outside of the .call external
    // architecture.
    //
    // the return is a full sized array that can be reduced easily in JS etc, or iterated through

    function getAllTokenLocations(address _addr, uint256 _bip32X_type) public view override returns (bool[] memory resultLocations, uint256 resultNumFound) {
        bool[] memory allLocations = new bool[](contracts.length);

        uint256 numFound;

        for (uint256 i = 0; i < contracts.length; i++) {
            IShyftKycContract kycContract = IShyftKycContract(contracts[i]);

            if (kycContract.getBalanceBip32X(_addr, _bip32X_type) > 0) {
                //add to array
                allLocations[i] = true;

                //increment number found
                numFound++;
            }
        }

        return (allLocations, numFound);
    }

    //@note: this function could potentially cost a lot of gas if you ran it outside of the .call external
    // architecture.
    //
    // the return is a full sized array that can be reduced easily in JS etc, or iterated through

    function getAllTokenLocationsAndBalances(address _addr, uint256 _bip32X_type) public view override returns (bool[] memory resultLocations, uint256[] memory resultBalances, uint256 resultNumFound, uint256 resultTotalBalance) {
        bool[] memory allLocations = new bool[](contracts.length);
        uint256[] memory totalSupplyBip32X = new uint256[](contracts.length);
        uint256 kycContractUserBalance;
        uint256 totalKycContractUserBalance;

        uint256 numFound;

        IShyftKycContract kycContract;

        for (uint256 i = 0; i < contracts.length; i++) {
            kycContract = IShyftKycContract(contracts[i]);

            kycContractUserBalance = kycContract.getBalanceBip32X(_addr, _bip32X_type);
            if (kycContractUserBalance > 0) {
                //add to array
                allLocations[i] = true;
                totalSupplyBip32X[i] = kycContractUserBalance;

                totalKycContractUserBalance += kycContractUserBalance;

                //increment number found
                numFound++;
            }
        }

        return (allLocations, totalSupplyBip32X, numFound, totalKycContractUserBalance);
    }
}