pragma solidity ^0.5.8;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./TransferHelper.sol";
import "./IWithdraw.sol";
import "./ECDSA.sol";

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract Withdraw is IWithdraw, ReentrancyGuard, Owned {
    IERC20 private tokenAddr;
    using TransferHelper for address;
    using SafeMath for uint256;
    using ECDSA for bytes32;
    string public name;
    bool public stop_status = false;

    mapping(uint256 => bool) usedNonce;

    modifier withdraw_status {
        require(stop_status == false, "WITHDRAW:STOP");
        _;
    }

    constructor(address _tokenAddr, address _owner) public {
        tokenAddr = IERC20(_tokenAddr);
        name = "ADAO-WITHDRAW";
        owner = _owner;
    }

    function verifySign(
        uint256 amount,
        uint256 nonce,
        address userAddr,
        bytes memory signature
    ) public view returns (bool) {
        address recoverAddr =
            keccak256(abi.encode(userAddr, amount, nonce, this))
                .toEthSignedMessageHash()
                .recover(signature);
        require(recoverAddr == owner, "WITHDRAW:SIGN_FAILURE");
        require(!usedNonce[nonce], "WITHDRAW:NONCE_USED");
        return true;
    }

    function withdraw(
        uint256 amount,
        uint256 nonce,
        bytes memory signature
    ) public nonReentrant withdraw_status returns (bool) {
        verifySign(amount, nonce, msg.sender, signature);
        usedNonce[nonce] = true;
        require(
            address(tokenAddr).safeTransfer(msg.sender, amount),
            "WITHDRAW:INSUFFICIENT_CONTRACT_BALANCE"
        );
        emit WithdrawEvent(msg.sender, amount, nonce);
        return true;
    }

    function stop() public nonReentrant onlyOwner {
        stop_status = true;
    }

    function draw(uint256 amount, address toAddr)
        public
        nonReentrant
        onlyOwner
    {
        require(
            address(tokenAddr).safeTransfer(toAddr, amount),
            "WITHDRAW:INSUFFICIENT_CONTRACT_BALANCE"
        );
        emit DrawEvent(toAddr, amount);
    }
}