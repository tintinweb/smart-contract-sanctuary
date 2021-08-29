/**
 *Submitted for verification at Etherscan.io on 2021-08-29
*/

// File: node_modules\@openzeppelin\contracts\utils\Context.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin\contracts\access\Ownable.sol



pragma solidity ^0.8.0;

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @openzeppelin\contracts\token\ERC20\IERC20.sol



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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// File: contracts\lib\Signature.sol


pragma solidity ^0.8.0;

library Signature {

    /**
     * @dev Splits signature
     */
    function splitSignature(bytes memory sig) private pure returns (uint8 v, bytes32 r, bytes32 s) {
        require(sig.length == 65);

        assembly {
            // first 32 bytes, after the length prefix.
            r := mload(add(sig, 32))
            // second 32 bytes.
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes).
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    /**
     * @dev Recovers signer
     */
    function recoverSigner(bytes32 message, bytes memory sig) internal pure returns (address) {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);

        return ecrecover(message, v, r, s);
    }

    /**
     * @dev Builds a prefixed hash to mimic the behavior of eth_sign.
     */
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

}

// File: contracts\TokenClaim.sol


pragma solidity ^0.8.0;




contract TokenClaim is Ownable {

    using Signature for bytes32;

    event SignatureVerifierUpdated(address account);
    event AdminWalletUpdated(address account);
    event TokenWithdrawed(address account, uint256 amount);
    event TokenClaimed(uint256 phaseId, address account, uint256 amount);

    IERC20 private _token;

    address private _signatureVerifier;

    address private _adminWallet;

    mapping(uint256 => mapping(address => bool)) _claimed;

    /**
     * @dev Constructor
     */
    constructor(address token, address signatureVerifier, address adminWallet)
    {
        _token = IERC20(token);

        _signatureVerifier = signatureVerifier;
        _adminWallet = adminWallet;
    }

    /**
     * @dev Updates signature verifier
     */
    function updateSignatureVerifier(address account)
        external
        onlyOwner
    {
        require(account != address(0), "TokenClaim: address is invalid");

        _signatureVerifier = account;

        emit SignatureVerifierUpdated(account);
    }

    /**
     * @dev Updates admin wallet
     */
    function updateAdminWallet(address account)
        external
        onlyOwner
    {
        require(account != address(0), "TokenClaim: address is invalid");

        _adminWallet = account;

        emit AdminWalletUpdated(account);
    }

    /**
     * @dev Withdraws token out of this smart contract and transfer to 
     * admin wallet
     */
    function withdrawFund(uint256 amount)
        external
        onlyOwner
    {
        require(amount > 0, "TokenClaim: amount is invalid");

        _token.transfer(_adminWallet, amount);

        emit TokenWithdrawed(_adminWallet, amount);
    }

    /**
     * @dev Returns smart contract information
     */
    function getContractInfo()
        external
        view
        returns (address, address, address, uint256)
    {
        return (address(_token), _signatureVerifier, _adminWallet, _token.balanceOf(address(this)));
    }

    /**
     * @dev Returns true if account claimed
     */
    function isClaimed(uint256 phaseId, address account)
        external
        view
        returns (bool)
    {
        return _claimed[phaseId][account];
    }

    /**
     * @dev Claims token
     */
    function claim(uint256 phaseId, uint256 index, uint256 amount, uint256 releaseTime, bytes memory signature)
        external
    {
        address msgSender = _msgSender();

        require(!_claimed[phaseId][msgSender], "TokenClaim: account already claimed");

        require(block.timestamp >= releaseTime, "TokenClaim: token still is in locking time");

        bytes32 message = keccak256(abi.encodePacked(phaseId, index, msgSender, amount, releaseTime, address(this))).prefixed();

        require(message.recoverSigner(signature) == _signatureVerifier, "TokenClaim: signature is invalid");

        amount = amount * 1e18;

        _claimed[phaseId][msgSender] = true;

        _token.transfer(msgSender, amount);

        emit TokenClaimed(phaseId, msgSender, amount);
    }

}