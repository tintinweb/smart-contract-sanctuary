/**
 *Submitted for verification at polygonscan.com on 2021-10-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

contract DDSDividend is Context, ReentrancyGuard {
    event fundsDeposited(address account, uint256 amount);
    event fundsClaimed(address account, uint256 amount);

    mapping(address => uint256) private _funds;

    function fundsOf(address payee) public view returns (uint256) {
        return _funds[payee];
    }

    function depositFunds(address[] memory payees, uint256[] memory shares) public payable {
        require(payees.length == shares.length, "DDSDividend: payees and shares length mismatch");
        require(payees.length > 0, "DDSDividend: no payees");

        uint256 _totalFunds = msg.value;
        uint256 _totalShares = 0;

        for (uint256 i = 0; i < shares.length; i++) {
            _totalShares = _totalShares + shares[i];
        }

        for (uint256 i = 0; i < payees.length; i++) {
            uint256 assignedFunds = _totalFunds * (shares[i] / _totalShares);
            _funds[payees[i]] = assignedFunds;
            emit fundsDeposited(payees[i], assignedFunds);
        } 
    } 

    function claimFunds() public {
        address payable _sender = payable(msg.sender);

        require(_funds[_sender] > 0, "DDSDividend: address has no available funds to claim");

        uint256 payment = _funds[_sender];
        _funds[_sender] = 0;
        _sender.transfer(payment);

        emit fundsClaimed(_sender, payment);
    }
}