/**
 *Submitted for verification at Etherscan.io on 2021-03-10
*/

// EscrowMinerReward
// Handling miner reward distribution after miner finish mining computation.
// Adapted from: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/escrow/Escrow.sol
// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;

contract EscrowMinerReward {
    uint256 private constant _AUTHORIZED = 0;
    uint256 private constant _UNAUTHORIZED = 1;

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    event Deposited(address indexed payee, uint256 weiAmount);
    event Withdrawn(address indexed payee, uint256 weiAmount);
    event Refunded(address indexed payee, address recipient, uint256 weiAmount);

    address private _owner;
    address[] private _authorizedList;
    mapping(address => uint256) private _deposits;

    constructor() {
        _owner = msg.sender;
        _authorizedList.push(_owner);
        _status = _NOT_ENTERED;
    }

    modifier onlyAuthorized() {
        require(isAuthorized(msg.sender) == _AUTHORIZED, "only authorized addr call");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "only owner call");
        _;
    }

    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/fb95a8b34bb34d797f5b1dcf64a7be5cce7219c4/contracts/security/ReentrancyGuard.sol#L49
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

    // Returns deposited amount for payee
    function depositsOf(address payee) public view returns (uint256) {
        return _deposits[payee];
    }

    // Grant permission for address to call release reward and refund
    function addAuthorizedAddr(address addr) public onlyOwner {
        if (isAuthorized(addr) == _UNAUTHORIZED) {
            _authorizedList.push(addr);
        }
    }

    // Revoke address from authorized list
    function revokeAuthorizedAddr(address addr) public onlyOwner {
        uint n = _authorizedList.length;
        for (uint idx = 0; idx < n; ++idx) {
            if (_authorizedList[idx] == addr) {
                delete _authorizedList[idx];
                break;
            }
        }
    }

    function authorizedAddrList() public view returns(address[] memory) {
        return _authorizedList;
    }

     // Stores the sent amount as credit to be withdrawn.
    function deposit(address payee) public payable {
        uint256 amount = msg.value;

        _deposits[payee] = _deposits[payee] + amount;

        emit Deposited(payee, amount);
    }

    // Authorized release reward fund for miner
    function releaseReward(address payable payee, uint256 amount) public onlyAuthorized {
        require(_deposits[payee] >= amount, "Payee has not enough fund to withdraw");

        _deposits[payee] = _deposits[payee] - amount;

        sendValue(payee, amount);

        emit Withdrawn(payee, amount);
    }

    // Authorized refund to recipient
    function refund(address payable recipient, address payee, uint256 amount) public payable onlyAuthorized {
        require(_deposits[payee] >= amount, "Payee has not enough fund to refund");

        _deposits[payee] = _deposits[payee] - amount;

        sendValue(recipient, amount);

        emit Refunded(payee, recipient, amount);
    }

    function isAuthorized(address addr) private view returns(uint256) {
        uint n = _authorizedList.length;
        for (uint idx = 0; idx < n; ++idx) {
            if (_authorizedList[idx] == addr) {
                return _AUTHORIZED;
            }
        }
        return _UNAUTHORIZED;
    }

    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/fb95a8b34bb34d797f5b1dcf64a7be5cce7219c4/contracts/utils/Address.sol#L53
    function sendValue(address payable recipient, uint256 amount) private nonReentrant {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}