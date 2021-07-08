// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./EnumerableSet.sol";
import "./Ownable.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";

contract CryptoCapsule is Ownable{
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeERC20 for ERC20;

    // Capsule Data
    struct Capsule {
        uint256 id;
        address grantor;
        address payable beneficiary;
        uint48 distributionDate;
        uint256 periodSize;
        uint256 periodCount;
        uint256 claimedPeriods;
        uint48 createdDate;
        bool empty;
        uint256 value;
        address[] tokens;
        uint256[] amounts;
        bool addingAssetsAllowed;
        string message;
    }

    Capsule[] capsules;
    mapping (address => EnumerableSet.UintSet) private sent;
    mapping (address => EnumerableSet.UintSet) private received;


    // Constructor 
    constructor() Ownable() { }


    // Functions
    function createCapsule(
        address payable _beneficiary,
        uint48 _distributionDate,
        uint256 _periodSize,
        uint256 _periodCount,
        address[] calldata _tokens,
        uint256[] calldata _values,
        bool addingAssetsAllowed,
        string calldata _message
    ) public payable returns(Capsule memory) {
        require(_distributionDate > block.timestamp, "Distribution Date must be in future");
        require(_tokens.length == _values.length, "Tokens and Values must be same length");
        require(_periodSize >= 1, "Period Size must greater than or equal to 1");
        require(_periodCount >= 1, "Period Count must greater than or equal to 1");
        require(_tokens.length <= 10, "Assets exceed maximum of 10 per capsule");

        for (uint256 i = 0; i < _tokens.length; i++) {
            require(_values[i] > 0, "Token value must be greater than 0");
            ERC20 erc20Token = ERC20(_tokens[i]);
            erc20Token.safeTransferFrom(msg.sender, address(this), _values[i]);
        }

        // uint256 capsuleId = capsules.length;
        capsules.push(
            Capsule(
                capsules.length,
                msg.sender,
                _beneficiary,
                _distributionDate,
                _periodSize,
                _periodCount,
                0,
                uint48(block.timestamp),
                false,
                msg.value,
                _tokens,
                _values,
                addingAssetsAllowed,
                _message
            )
        );

        sent[msg.sender].add(capsules.length - 1);
        received[_beneficiary].add(capsules.length - 1);
        emit CapsuleCreated(capsules.length - 1);
        return getCapsule(capsules.length - 1);
    }

    function openCapsule(uint256 capsuleId) public {
        require(capsules.length > capsuleId, "Capsule does not exist");
        Capsule memory capsule = capsules[capsuleId];
        require(msg.sender == capsule.beneficiary, "You are not the beneficiary of this Capsule");
        require(!capsule.empty, "Capsule is empty");
        require(block.timestamp >= capsule.distributionDate, "Capsule has not matured yet");
        uint256 nextClaimDate = capsule.distributionDate + capsule.claimedPeriods * capsule.periodSize;
        require(block.timestamp >= nextClaimDate, "No periods available to claim"); 

        uint256 claimablePeriods = (block.timestamp - nextClaimDate) / capsule.periodSize + 1;
        uint256 unclaimedPeriods = capsule.periodCount - capsule.claimedPeriods;
        claimablePeriods = claimablePeriods > unclaimedPeriods ? unclaimedPeriods : claimablePeriods;

        capsules[capsuleId].claimedPeriods = capsule.claimedPeriods + claimablePeriods;
        capsules[capsuleId].empty = capsule.claimedPeriods + claimablePeriods == capsule.periodCount;

        if (capsule.value > 0) capsule.beneficiary.transfer(capsule.value * claimablePeriods / capsule.periodCount);
        for (uint256 i = 0; i < capsule.tokens.length; i++) {
            ERC20 erc20Token = ERC20(capsule.tokens[i]);
            erc20Token.safeTransfer(capsule.beneficiary, capsule.amounts[i] * claimablePeriods / capsule.periodCount);
        }

        emit CapsuleOpened(capsuleId);
    }

    function addAssets(uint256 capsuleId, address[] calldata _tokens, uint256[] calldata _values) public payable {
        require(capsules.length > capsuleId, "Capsule does not exist");
        require(_tokens.length == _values.length, "Tokens and Values must be same length");
        Capsule memory capsule = capsules[capsuleId];
        require(capsule.addingAssetsAllowed, "Adding assets not allowed for this Capsule");
        require(msg.sender == capsule.grantor, "You are not the grantor of this Capsule");
        require(block.timestamp < capsule.distributionDate, "Capsule is past distribution date");

        for (uint256 i = 0; i < _tokens.length; i++) {
            require(_values[i] > 0, "Token value must be greater than 0");
            ERC20 erc20Token = ERC20(_tokens[i]);
            erc20Token.safeTransferFrom(msg.sender, address(this), _values[i]);

            bool tokenExists = false;
            for (uint256 j = 0; j < capsule.tokens.length; j++) {
                if (capsule.tokens[j] == _tokens[i]) {
                    capsules[capsuleId].amounts[j] += _values[i];
                    tokenExists = true;
                    break;
                }
            }
            if (!tokenExists) {
                capsules[capsuleId].tokens.push(_tokens[i]);
                capsules[capsuleId].amounts.push(_values[i]);
            }
        }
        require(capsules[capsuleId].tokens.length <= 10, "Assets exceed maximum of 10 per capsule");

        capsules[capsuleId].value += msg.value; 

        emit AddedAssets(capsuleId, _tokens, _values, msg.value);
    }

    function updateBeneficiary(uint256 capsuleId, address payable beneficiary) public {
        require(capsules.length > capsuleId, "Capsule does not exist");
        Capsule memory capsule = capsules[capsuleId];
        require(msg.sender == capsule.beneficiary, "You are not the beneficiary of this Capsule");
        require(!capsule.empty, "Capsule is empty");
        require(capsule.beneficiary != beneficiary, "Beneficiary is not different to curret");
        received[capsule.beneficiary].remove(capsuleId);
        capsules[capsuleId].beneficiary = beneficiary;
        received[beneficiary].add(capsuleId);
        emit UpdatedBeneficiary(capsuleId, beneficiary);
    }


    // Views
    function getCapsuleCount() public view returns(uint256) {
        return capsules.length;
    }
    
    function getCapsule(uint256 capsuleId) public view returns(Capsule memory) {
        require(capsules.length > capsuleId, "Capsule does not exist");
        return capsules[capsuleId];
    }

    function getCapsules() public view returns(Capsule[] memory) {
        return capsules;
    }

    function getSentCapsules(address grantor) public view returns(Capsule[] memory) {
        uint256 count = sent[grantor].length();
        Capsule[] memory _capsules = new Capsule[](count);
        for (uint256 i = 0; i < count; i++) {
            _capsules[i] = capsules[sent[grantor].at(i)];
        }
        return _capsules;
    }

    function getReceivedCapsules(address beneficiary) public view returns(Capsule[] memory) {
        uint256 count = received[beneficiary].length();
        Capsule[] memory _capsules = new Capsule[](count);
        for (uint256 i = 0; i < count; i++) {
            _capsules[i] = capsules[received[beneficiary].at(i)];
        }
        return _capsules;
    }

    function getMessage(uint256 capsuleId) public view returns(string memory _message) {
        require(capsules.length > capsuleId, "Capsule does not exist");
        return capsules[capsuleId].message;
    }

    // Events
    event CapsuleOpened(uint256 capsuleId);
    event CapsuleCreated(uint256 capsuleId);
    event AddedAssets(uint256 capsuleId, address[] tokens, uint256[] values, uint256 eth);
    event UpdatedBeneficiary(uint256 capsuleId, address payable beneficiary);
}