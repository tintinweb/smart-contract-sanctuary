/**
 *Submitted for verification at Etherscan.io on 2021-12-13
*/

// File: @openzeppelin/contracts/utils/Context.sol

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/ethereum/VerificationEIP712.sol

// ----------------------------------------------------------------------------
// This smart contract can easily verify any Ethereum signed message signature.
// You just have to provide the Ethereum address that signed the message,
// the  generated signature and the message that has to be verified.

// Updated     : To support Solidity version ^0.8.3
// Programmer  : Idris Bowman
// Link        : https://idrisbowman.com
// Last test   : locally 12/29/21 (https://github.com/V00D00-child/web3-cloud-verification/blob/main/test/Verificationeip712.test.js)

// ----------------------------------------------------------------------------


contract VerificationEIP712 is Ownable  {
    uint256 private chainId;
    string private name;
    string private version;
    address constant ETHER = address(0);
    event Withdraw(address token, address user, uint256 amount, uint256 balance);

    // Structs
    struct Identity {
        string action;
        address signer; 
        string email;
        string url;
        string version;
        uint256 nonce;
        uint256 expiration;
    }
  
    constructor(uint256 _chainId, string memory _name, string memory _version) Ownable() {
        chainId = _chainId;
        name = _name;
        version = _version;
    }

    function verify(
        uint8 v,
        bytes32 r,
        bytes32 s,
        string memory action,
        address sender,
        string memory email,
        string memory url,
        uint256 nonce,
        uint256 expiration
    ) public view returns (bool) {
            require(block.timestamp < expiration, "Signature has expired");

            // get domain hash
            bytes32 DOMAIN_SEPARATOR_HASH = keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256(bytes(version)),
                    chainId,
                    address(this)
                )
            );

            // get struct hash
            bytes32 structHash = keccak256(
                    abi.encode(
                        keccak256("Identity(string action,address signer,string email,string url,uint256 nonce,uint256 expiration)"),
                        keccak256(bytes(action)),
                        sender,
                        keccak256(bytes(email)),
                        keccak256(bytes(url)),
                        nonce,
                        expiration
                    )
            );

            // verify signature
            bytes32 hash = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR_HASH, structHash));
            address signer = ecrecover(hash, v, r, s);
            require(signer != address(0), "ECDSA: Invalid signature");
            return signer == sender;
    }

        receive() external payable {}
     
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function destory() public onlyOwner {
        address _owner = this.owner();
        selfdestruct(payable(_owner)); 
    }

    function withdrawEther(uint256 _amount) payable public onlyOwner {
        require(address(this).balance >= _amount);
        payable(msg.sender).transfer(_amount);
        emit Withdraw(ETHER, msg.sender, _amount, address(this).balance);
    }
}