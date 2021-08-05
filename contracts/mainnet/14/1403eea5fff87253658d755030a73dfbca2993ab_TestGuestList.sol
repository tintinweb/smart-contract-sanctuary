/**
 *Submitted for verification at Etherscan.io on 2020-11-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

/**
 * @notice A basic guest list contract for testing.
 * @dev For a Vyper implementation of this contract containing additional
 * functionality, see https://github.com/banteg/guest-list/blob/master/contracts/GuestList.vy
 */
contract TestGuestList {
    address public vault;
    address public bouncer;
    mapping(address => bool) public guests;

    /**
     * @notice Create the test guest list, setting the message sender as
     * `bouncer`.
     * @dev Note that since this is just for testing, you're unable to change
     * `bouncer`.
     */
    constructor() public {
        bouncer = msg.sender;
    }

    /**
     * @notice Invite guests or kick them from the party.
     * @param _guests The guests to add or update.
     * @param _invited A flag for each guest at the matching index, inviting or
     * uninviting the guest.
     */
    function setGuests(address[] calldata _guests, bool[] calldata _invited) external {
        assert(msg.sender == bouncer);
        assert(_guests.length == _invited.length);
        for (uint256 i = 0; i < _guests.length; i++) {
            if (_guests[i] == address(0)) {
                break;
            }
            guests[_guests[i]] = _invited[i];
        }
    }
    
    function setBouncer(address _bouncer) external {
        assert(msg.sender == bouncer);
        bouncer = _bouncer;
    }

    /**
     * @notice Check if a guest with a bag of a certain size is allowed into
     * the party.
     * @dev Note that `_amount` isn't checked to keep test setup simple, since
     * from the vault tests' perspective this is a pass/fail call anyway.
     * @param _guest The guest's address to check.
     * @param _amount Not used. The amount of tokens the guest is bringing.
     */
    function authorized(address _guest, uint256 _amount) external view returns (bool) {
        return guests[_guest];
    }
}