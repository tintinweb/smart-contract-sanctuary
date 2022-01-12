// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import './IUserRegistry.sol';
import './Ownable.sol';

contract BrightIdUserRegistry is Ownable, IUserRegistry {
    string private constant ERROR_NEWER_VERIFICATION = 'NEWER VERIFICATION REGISTERED BEFORE';
    string private constant ERROR_NOT_AUTHORIZED = 'NOT AUTHORIZED';
    string private constant ERROR_INVALID_VERIFIER = 'INVALID VERIFIER';
    string private constant ERROR_INVALID_CONTEXT = 'INVALID CONTEXT';

    bytes32 public context;
    address public verifier;

    struct Verification {
        uint256 time;
        bool isVerified;
    }
    mapping(address => Verification) public verifications;

    event SetBrightIdSettings(bytes32 context, address verifier);
    event Sponsor(address indexed addr);

    /**
     * @param _context BrightID context used for verifying users
     * @param _verifier BrightID verifier address that signs BrightID verifications
     */
    constructor(bytes32 _context, address _verifier) {
        // ecrecover returns zero on error
        require(_verifier != address(0), ERROR_INVALID_VERIFIER);

        context = _context;
        verifier = _verifier;
    }

    /**
     * @notice Sponsor a BrightID user by context id
     * @param addr BrightID context id
     */
    function sponsor(address addr) public {
        emit Sponsor(addr);
    }

    /**
     * @notice Set BrightID settings
     * @param _context BrightID context used for verifying users
     * @param _verifier BrightID verifier address that signs BrightID verifications
     */
    function setSettings(bytes32 _context, address _verifier) external onlyOwner {
        // ecrecover returns zero on error
        require(_verifier != address(0), ERROR_INVALID_VERIFIER);

        context = _context;
        verifier = _verifier;
        emit SetBrightIdSettings(_context, _verifier);
    }

    /**
     * @notice Check a user is verified or not
     * @param _user BrightID context id used for verifying users
     */
    function isVerifiedUser(address _user)
      override
      external
      view
      returns (bool)
    {
        return verifications[_user].isVerified;
    }


    /**
     * @notice Register a user by BrightID verification
     * @param _context The context used in the users verification
     * @param _addrs The history of addresses used by this user in this context
     * @param _timestamp The BrightID node's verification timestamp
     * @param _v Component of signature
     * @param _r Component of signature
     * @param _s Component of signature
     */
    function register(
        bytes32 _context,
        address[] calldata _addrs,
        uint _timestamp,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        require(context == _context, ERROR_INVALID_CONTEXT);
        require(verifications[_addrs[0]].time < _timestamp, ERROR_NEWER_VERIFICATION);

        bytes32 message = keccak256(abi.encodePacked(_context, _addrs, _timestamp));
        address signer = ecrecover(message, _v, _r, _s);
        require(verifier == signer, ERROR_NOT_AUTHORIZED);

        verifications[_addrs[0]].time = _timestamp;
        verifications[_addrs[0]].isVerified = true;
        for(uint i = 1; i < _addrs.length; i++) {
            // update time of all previous context ids to be sure no one can use old verifications again
            verifications[_addrs[i]].time = _timestamp;
            // set old verifications unverified
            verifications[_addrs[i]].isVerified = false;
        }
    }
}