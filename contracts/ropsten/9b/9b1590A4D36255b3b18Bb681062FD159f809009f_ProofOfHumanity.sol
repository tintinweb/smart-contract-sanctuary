// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import { IProofOfHumanity } from "./interfaces/IProofOfHumanity.sol";

contract ProofOfHumanity is IProofOfHumanity {

    struct Register {
        bool submitted;
        bool registered;
        bool superUser;
    }

    bool superUserAllowed;
    bool selfRegistrationAllowed;
    uint256 submittedQuantity;
    uint256 registeredQuantity;
    uint256 superUserQuantity;
    mapping(address => Register) registry;

    constructor(bool _superUserAllowed, bool _selfRegistrationAllowed) {
        superUserAllowed = _superUserAllowed;
        selfRegistrationAllowed = _selfRegistrationAllowed;
        registry[msg.sender] = Register(true, true, _superUserAllowed);
        submittedQuantity++;
        registeredQuantity++;
        superUserQuantity += boolToDigit(_superUserAllowed);
    }

    function boolToDigit(bool _bool) internal pure returns (uint256) {
        return _bool ? 1 : 0;
    }

    function isSuperUserAllowed() external view returns (bool) {
        return superUserAllowed;
    }

    function isSelfRegistrationAllowed() external view returns (bool) {
        return selfRegistrationAllowed;
    }

    function getSubmittedQuantity() external view returns (uint256) {
        return submittedQuantity;
    }

    function getRegisteredQuantity() external view returns (uint256) {
        return registeredQuantity;
    }

    function getSuperUserQuantity() external view returns (uint256) {
        return superUserQuantity;
    }

    function isSubmitted(address _address) external view returns (bool) {
        return registry[_address].submitted;
    }

    function isRegistered(address _address) override external view returns (bool) {
        return registry[_address].registered;
    }

    function isSuperUser(address _address) external view returns (bool) {
        return registry[_address].superUser;
    }

    function submit() external {
        require(!registry[msg.sender].submitted, "Already submitted");
        submittedQuantity++;
        registry[msg.sender].submitted = true;
    }

    function register(address _address) external {
        require(!registry[_address].registered, "Already registered");
        require(msg.sender != _address || selfRegistrationAllowed, "Self registration not allowed in this version");
        if (msg.sender != _address) {
            require(registry[msg.sender].registered, "You must be registered before registering others");
            require(registry[_address].submitted, "Address must perform submission before being registered");
        }
        registeredQuantity++;
        registry[_address].registered = true;
    }

    function sudoRegister(address _address, bool _submitted, bool _registered, bool _superUser) external {
        require(superUserAllowed, "Super user not allowed in this version");
        require(registry[msg.sender].superUser, "You must be a super user");
        require(!_registered || _submitted, "Can't be registered but not submitted");
        submittedQuantity += registry[_address].submitted ? -boolToDigit(!_submitted) : boolToDigit(_submitted);
        registeredQuantity += registry[_address].registered ? -boolToDigit(!_registered) : boolToDigit(_registered);
        superUserQuantity += registry[_address].superUser ? -boolToDigit(!_superUser) : boolToDigit(_superUser);
        registry[_address] = Register(_submitted, _registered, _superUser);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface IProofOfHumanity {

    /** @dev Return true if the submission is registered and not expired.
     *  @param _address The address of the submission.
     *  @return Whether the submission is registered or not.
     */
    function isRegistered(address _address) external view returns (bool);
}

