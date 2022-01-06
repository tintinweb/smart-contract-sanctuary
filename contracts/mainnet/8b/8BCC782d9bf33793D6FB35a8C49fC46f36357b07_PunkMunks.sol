// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./PaymentVerifiable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PunkMunks is PaymentVerifiable, Ownable {
    uint256 tokenSold;

    /**
     * @dev owner fund: Address that revceive payment 
     * @dev amdin: Address that can sign for the user to make payment
     */
    address payable public ownerFund;
    address public admin;
    uint256 public totalSupply;

    //mapping store the tokens that are created
    mapping(uint256 => bool) tokens;

    /**
     * @dev Set address whose owner recieve payments from user
     */
    function setOwnerFund(address newOwnerFundAddress_) public onlyOwner {
        require(newOwnerFundAddress_ != address(0), "Invalid owner fund");
        ownerFund = payable(newOwnerFundAddress_);
    }

    /**
     * @notice only owner can set new admin
     */
    function setAdmin(address newAdmin_) public onlyOwner {
        admin = newAdmin_;
    }

    modifier onlyAuthorizer() {
        require(msg.sender == owner() || msg.sender == admin);
        _;
    }

  
    constructor() {
        ownerFund = payable(msg.sender); //initially set ownerfund to the payment contract creator
        admin = msg.sender; //initially set admin to the payment contract creator
        totalSupply = 10000; //Gallery only sells 10000 items
    }

    event PaymentSucceeded(
        address indexed buyer,
        address ownerFund,
        address nftAddress,
        uint256[] tokenId,
        uint256 price
    );

    /**
     * @dev buyer call this function
     */
    function makePayment(
        bytes memory signature_,
        address buyer_,
        address nftAddress_,
        uint256[] memory tokenId_,
        uint256 tokenPrice_
    ) public payable {
        require(msg.sender == buyer_, "Only Buyer can make payment");

        require(
            tokenSold + tokenId_.length <= totalSupply,
            "Token supply exceeded"
        );

        require(
            msg.value == tokenPrice_,
            "Msg value and token price are not matched"
        );

        // if any token id existed, revert
        for (uint256 i = 0; i < tokenId_.length; i++) {
            require(!isTokenExisted(tokenId_[i]), "TokenId existed");
        }

        address signer = verify(signature_, buyer_, nftAddress_, tokenId_, tokenPrice_);
        require( //accept payment with signing message from either owner or admin
            signer ==  owner() || signer == admin,
            "Signer is not admin or owner"
        );

        ownerFund.transfer(tokenPrice_);
        for (uint256 i = 0; i < tokenId_.length; i++) {
            tokens[tokenId_[i]] = true;
        }

        tokenSold += tokenId_.length;

        emit PaymentSucceeded(
            buyer_,
            ownerFund,
            nftAddress_,
            tokenId_,
            tokenPrice_
        );
    }

    /**
     * @dev unsold a token incase of error - mannualy
     */
    function unsoldToken(uint256 tokenId_) public onlyAuthorizer {
        require(tokens[tokenId_], "token is not sold yet");
        tokens[tokenId_] = false;
    }

    /**
     * @dev Give away case: mark token that are giveawayed from polygon
     */
    function setSoldToken(uint256[] memory tokenId_) public onlyAuthorizer {
        for (uint256 i = 0; i < tokenId_.length; i++) {
            tokens[tokenId_[i]] = true;
        }
    }

    function isTokenExisted(uint256 tokenId_) public view returns (bool) {
        return tokens[tokenId_];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

/* Make contract verifiable when creating new NFT, and when refunding to a specific user */
contract PaymentVerifiable {
    function getMessageHash(
        address buyer_,
        address nftAddress_,
        uint256[] memory tokenId_,
        uint256 price_
    ) public pure returns (bytes32) {
        return
            keccak256(abi.encodePacked(buyer_, nftAddress_, tokenId_, price_));
    }

    function getEthSignedMessageHash(bytes32 messageHash_)
        private
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    messageHash_
                )
            );
    }

    function verify(
        bytes memory signature_,
        address buyer_,
        address nftAddress_,
        uint256[] memory tokenId_,
        uint256 price_
    ) public pure returns (address) {
        bytes32 messageHash = getMessageHash(
            buyer_,
            nftAddress_,
            tokenId_,
            price_
        );
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature_);

        return ecrecover(ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        private
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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