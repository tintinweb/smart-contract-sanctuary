// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@opengsn/contracts/src/BaseRelayRecipient.sol";

contract AirdropV2 is BaseRelayRecipient {
    address payable public admin;
    mapping(address => bool) public processedAirdrops;
    IERC20 public token;
    uint256 public currentAirdropAmount;
    uint256 public maxAirdropAmount;

    modifier onlyAdmin() {
        require(admin == msg.sender, "only admin");
        _;
    }

    event AirdropProcessed(address recipient, uint256 amount, uint256 date);
    event EthSent(address recipient, uint256 amount, uint256 date);
    event EthNotSent(address recipient, uint256 amount, uint256 date);

    constructor(
        address _token,
        address _admin,
        uint256 _maxAirdropAmount,
        address _forwarder
    ) {
        _setTrustedForwarder(_forwarder);
        admin = payable(_admin);
        token = IERC20(_token);
        maxAirdropAmount = _maxAirdropAmount * 10**18;
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    function setTrustForwarder(address _trustedForwarder) public onlyAdmin {
        _setTrustedForwarder(_trustedForwarder);
    }

    /**
     * Override this function.
     * This version is to keep track of BaseRelayRecipient you are using
     * in your contract.
     */
    function versionRecipient() external pure override returns (string memory) {
        return "1";
    }

    function updateAdmin(address newAdmin) external onlyAdmin {
        admin = payable(newAdmin);
    }

    function claimTokens(
        address recipient,
        bytes calldata signature,
        uint256 amount
    ) external {
        bytes32 message = prefixed(keccak256(abi.encodePacked(recipient)));

        require(amount > 0, "airdrop amount cannot be 0");
        amount = amount * 10**18;
        require(recoverSigner(message, signature) == admin, "wrong signature");
        require(
            processedAirdrops[recipient] == false,
            "airdrop already processed"
        );
        require(
            token.balanceOf(recipient) == 0,
            "airdrop available only for new Magen token recipients"
        );
        require(
            currentAirdropAmount + amount <= maxAirdropAmount,
            "airdropped 100% of the tokens"
        );
        processedAirdrops[recipient] = true;
        currentAirdropAmount += amount;
        token.transfer(recipient, amount);
        emit AirdropProcessed(recipient, amount, block.timestamp);
    }

    function claimTokensAndEth(
        address payable recipient,
        bytes calldata signature,
        uint256 amount,
        uint256 ethAmount
    ) external {
        bytes32 message = prefixed(keccak256(abi.encodePacked(recipient)));

        require(amount > 0, "airdrop amount cannot be 0");
        amount = amount * 10**18;
        require(
            currentAirdropAmount + amount <= maxAirdropAmount,
            "airdropped 100% of the tokens"
        );
        require(
            address(this).balance > 0,
            "gas tank empty"
        );
        require(recoverSigner(message, signature) == admin, "wrong signature");
        require(
            processedAirdrops[recipient] == false,
            "airdrop already processed"
        );
        require(
            token.balanceOf(recipient) == 0,
            "airdrop available only for new Magen token recipients"
        );
        processedAirdrops[recipient] = true;
        currentAirdropAmount += amount;
        token.transfer(recipient, amount);
        emit AirdropProcessed(recipient, amount, block.timestamp);

        sendEth(recipient, ethAmount);
    }

    function withdrawToken(uint256 amount) external onlyAdmin {
        currentAirdropAmount += amount;
        token.transfer(admin, amount);
    }

    function withdrawEth(uint256 amount) external onlyAdmin {
        (bool sent, ) = admin.call{value: amount}("");
        if (sent) {
            emit EthSent(admin, amount, block.timestamp);
        } else {
            emit EthNotSent(admin, amount, block.timestamp);
        }
    }

    function sendEth(address payable recipient, uint256 amount) private {
        (bool sent, ) = recipient.call{value: amount}("");
        if (sent) {
            emit EthSent(recipient, amount, block.timestamp);
        } else {
            emit EthNotSent(recipient, amount, block.timestamp);
        }
    }

    function prefixed(bytes32 hash) private pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }

    function recoverSigner(bytes32 message, bytes memory sig)
        private
        pure
        returns (address)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(sig);

        return ecrecover(message, v, r, s);
    }

    function splitSignature(bytes memory sig)
        private
        pure
        returns (
            uint8,
            bytes32,
            bytes32
        )
    {
        require(sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// solhint-disable no-inline-assembly
pragma solidity >=0.6.9;

import "./interfaces/IRelayRecipient.sol";

/**
 * A base contract to be inherited by any contract that want to receive relayed transactions
 * A subclass must use "_msgSender()" instead of "msg.sender"
 */
abstract contract BaseRelayRecipient is IRelayRecipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address private _trustedForwarder;

    function trustedForwarder() public virtual view returns (address){
        return _trustedForwarder;
    }

    function _setTrustedForwarder(address _forwarder) internal {
        _trustedForwarder = _forwarder;
    }

    function isTrustedForwarder(address forwarder) public virtual override view returns(bool) {
        return forwarder == _trustedForwarder;
    }

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal override virtual view returns (address ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise (if the call was made directly and not through the forwarder), return `msg.data`
     * should be used in the contract instead of msg.data, where this difference matters.
     */
    function _msgData() internal override virtual view returns (bytes calldata ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length-20];
        } else {
            return msg.data;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/**
 * a contract must implement this interface in order to support relayed transaction.
 * It is better to inherit the BaseRelayRecipient as its implementation.
 */
abstract contract IRelayRecipient {

    /**
     * return if the forwarder is trusted to forward relayed transactions to us.
     * the forwarder is required to verify the sender's signature, and verify
     * the call is not a replay.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, then the real sender is appended as the last 20 bytes
     * of the msg.data.
     * otherwise, return `msg.sender`
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal virtual view returns (address);

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise (if the call was made directly and not through the forwarder), return `msg.data`
     * should be used in the contract instead of msg.data, where this difference matters.
     */
    function _msgData() internal virtual view returns (bytes calldata);

    function versionRecipient() external virtual view returns (string memory);
}