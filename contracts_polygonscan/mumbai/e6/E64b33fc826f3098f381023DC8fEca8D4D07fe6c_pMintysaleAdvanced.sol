pragma solidity ^0.8.0;
//SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../common/meta-transactions/ContentMixin.sol";
import "../common/meta-transactions/NativeMetaTransaction.sol";


    struct Offer {
        address  creator;
        string   itemHash;
        uint256  price;
        bool     available;
        bool     minted;
    } 

interface IMintyToken {
    function mint(address buyer, address artist,uint256 tokenId, string memory ipfsHash) external;

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    function artist(uint256 tokenId) external view returns (address);

    function tokenExists(uint256 tokenId) external view returns (bool);

    function ownerOf(uint256 tokenId) external view  returns (address);

    function isApprovedForAll(address owner, address operator) external view returns (bool) ;

    function getApproved(uint256 tokenId) external view returns (address);
}

contract pMintysaleAdvanced  is ContextMixin, NativeMetaTransaction {

    address                     public owner = msg.sender;
    IMintyToken                 public token;
    IERC20                      public weth;

    uint256                     public nextToken;
    mapping(uint256 => Offer)   public items; 

    mapping(address => bool)    public isMinter;

    bool                               entered;
    uint                        public ownerPerMille;
    uint                        public creatorPerMille;
    uint                        public divisor;
    address                     public minty;

    mapping(uint => mapping(address => uint256)) public bids;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event WalletTransferred(address indexed previousWallet, address indexed newWallet);

    event SharesUpdated(uint256 ownerShare, uint256 creatorShare, uint256 divisor);
    event NewOffer(uint256 tokenId, address owner, uint256 price, string hash);
    event ResaleOffer(uint256 tokenId, address owner, uint256 price);
    event SaleResubmitted(uint256 tokenId, uint256 price);
    event OfferAccepted(address buyer, uint256 tokenId, uint256 price);
    event SaleRetracted(uint256 tokenId);

    event BidReceived(address  bidder, uint256 tokenId, uint256 bid);
    event BidIncreased(address bidder, uint256 tokenId, uint256 previous_bid, uint256 this_bid);


    event Payment(address wallet,address creator, address _owner);

    modifier onlyOwner() {
        require(msgSender() == owner, "unauthorised");
        _;
    }

    constructor(IERC20 _weth, address wallet, uint256 _ownerPerMille, uint256 _creatorPerMille, uint _divisor) {
        require(_creatorPerMille + _ownerPerMille <= 1000,"sum(_creatorPerMille + _ownerPerMille) must be less than or equal 1000");
        require(_divisor >= 1000,"divisor is less than 1000");
        weth = _weth;
        minty = wallet;
        ownerPerMille = _ownerPerMille;
        creatorPerMille = _creatorPerMille;
        divisor = _divisor;
        _initializeEIP712("MintyUniqueSale");
        emit SharesUpdated(_ownerPerMille, _creatorPerMille, _divisor);
    }

    function setMintyUnique(IMintyToken m) external onlyOwner {
        token = m;
    }

    function setMinter(address minter, bool status) external onlyOwner {
        isMinter[minter] = status;
    }

    function updateShares(uint256 _ownerPerMille, uint256 _creatorPerMille, uint _divisor) external onlyOwner {
        require(_creatorPerMille + _ownerPerMille == 1000,"sum(_creatorPerMille + _ownerPerMille) must equal 1000");
        require(divisor >= 1000,"divisor is less than 1000");
        ownerPerMille = _ownerPerMille;
        creatorPerMille = _creatorPerMille;
        divisor = _divisor;
        emit SharesUpdated(_ownerPerMille, _creatorPerMille, _divisor);
    }

    function offerNew(uint256 tokenId, string memory ipfsString, uint256 price) external {
        require(!token.tokenExists(tokenId),"Invalid token ID");
        require(isMinter[msgSender()],"You are not allowed to mint tokens here");
        Offer memory offer = items[tokenId];
        require((offer.creator == address(0) ),"Attempt to modify an existing offer");
        items[tokenId] = Offer(msgSender(), ipfsString,price, true,false);
        emit NewOffer(tokenId, msgSender(), price, ipfsString);
    }

    function offerResale(uint256 tokenId, uint256 price) external {
        require(token.tokenExists(tokenId),"Token does not exist!");
        require(msgSender() == token.ownerOf(tokenId),"You do not own this token");
        require( (token.isApprovedForAll(msgSender(), address(this))) || (token.getApproved(tokenId) == address(this)),"You have not approved this contract to sell your tokens");
        items[tokenId] = Offer(msgSender(), "",price, true,true);
        emit ResaleOffer(tokenId, msgSender(), price);
    }

    // only needed if we are replacing an old contract
    function offerSpecial(uint256 tokenId, address creator, string memory ipfsString, uint256 price) external onlyOwner {
        require(!token.tokenExists(tokenId),"Invalid token ID");
        items[tokenId] = Offer(creator, ipfsString,price, true,false);
        emit NewOffer(tokenId, creator, price, ipfsString);
    }

    function retractOffer(uint256 tokenId) external {
        Offer memory offer = items[tokenId];
        address _owner = offer.creator;
        if (token.tokenExists(tokenId)) {
            _owner = token.ownerOf(tokenId);
        }
        require(_owner == msgSender(),"Unauthorised");
        offer.available = false;
        items[tokenId] = offer;
        emit SaleRetracted(tokenId);
    }

    function reSubmitOffer(uint256 tokenId, uint256 price) external {
        Offer memory offer = items[tokenId];
        address _owner = offer.creator;
        if (token.tokenExists(tokenId)) {
            _owner = token.ownerOf(tokenId);
        }
        require(_owner == msgSender(),"Unauthorised");
        offer.available = true;
        offer.price = price;
        items[tokenId] = offer;
        emit SaleResubmitted(tokenId, price);
    }

    function acceptOffer(uint tokenId) external  {
        uint256 price = items[tokenId].price;
        require(weth.transferFrom(msgSender(), address(this), price),"Cannot transfer funds");
        accept(tokenId, price);
    }

    function accept(uint tokenId,uint value) internal {
        bool minting;
        require(!entered,"No reentrancy please");
        entered = true;
        bytes memory data;
        Offer memory offer = items[tokenId];
        address _owner = offer.creator;
        require(offer.available,"Item not available");
        require(value >= offer.price, "Price not met");
        if (offer.minted) {
            address _realOwner = token.ownerOf(tokenId);
            require(_realOwner == _owner,"Item not owned by offerer");
            token.safeTransferFrom(_owner,msgSender(),tokenId,data);
        } else {
            token.mint(msgSender(),offer.creator,tokenId,offer.itemHash);
            offer.minted = true;
            minting = true;
        }
        offer.available = false;
        items[tokenId] = offer;
        address creator = token.artist(tokenId); 
        emit Payment(minty,creator,_owner);
        splitFee(creator, _owner, value, minting);
        entered = false;
        emit OfferAccepted(msgSender(), tokenId, value);
    }

    function splitFee(address  creator, address  _owner, uint value,bool minting) internal {
        uint256 creatorPart;
        uint256 ownerPart;

        if (minting) {
            creatorPart = value * ownerPerMille / divisor;
            require(weth.transfer(creator,creatorPart),"Cannot transfer funds");
        } else {
            ownerPart   = value * ownerPerMille / divisor;
            creatorPart = value * creatorPerMille / divisor;
            if (creator == _owner) {
                require(weth.transfer(creator,creatorPart+ownerPart),"Cannot transfer funds");
            } else {
                require(weth.transfer(creator,creatorPart),"Cannot transfer funds");
                require(weth.transfer(_owner, ownerPart),"Cannot transfer funds");
            }
        }
        uint mintyPart   = value - (creatorPart + ownerPart);
        require(weth.transfer(minty,mintyPart),"Cannot transfer funds");
    }

    function makeBid(uint256 tokenId, uint256 topup) external  {
        require(weth.transferFrom(msgSender(), address(this), topup),"Cannot transfer funds");
        Offer memory offer = items[tokenId];
        require(offer.available,"Item not available");
        uint myBid = topup + bids[tokenId][msgSender()];
        if (myBid > offer.price) {
            bids[tokenId][msgSender()] = 0;
            accept(tokenId, myBid);
            return;
        }
        bids[tokenId][msgSender()] = myBid;
        if (myBid == topup) {
            emit BidReceived(msgSender(), tokenId, myBid);
        } else {
            emit BidIncreased(msgSender(), tokenId, myBid-topup, topup);
        }
    }

    function acceptBid(uint256 tokenId, address bidder) external {
        bytes memory data;
        require(!entered,"No reentrancy please");
        entered = true;

        Offer memory offer = items[tokenId];
        address _owner = offer.creator;
        address _realOwner = token.ownerOf(tokenId);
        require(offer.available,"Item not available");
        require(_realOwner == _owner,"Item not owned by offerer");
        require(msgSender() == _owner,"Not your item to sell");
        uint256 bid = bids[tokenId][bidder];
        bids[tokenId][bidder] = 0;
        bool minting;
        if (offer.minted) {
            token.safeTransferFrom(_owner,bidder,tokenId,data);
        } else {
            token.mint(bidder,offer.creator,tokenId,offer.itemHash);
            offer.minted = true;
            minting = true;
        }
        offer.available = false;
        items[tokenId] = offer;
        emit Payment(minty,offer.creator,_owner);
        splitFee(offer.creator, _owner,bid,minting);
        entered = false;
        emit OfferAccepted(msgSender(), tokenId, bid);
    }

    function withdrawBid(uint256 tokenId) external {
        require(!entered,"No reentrancy please");
        entered = true;
        uint256 bid = bids[tokenId][msgSender()];
        require(bid > 0,"nothing to withdraw");
        bids[tokenId][msgSender()] = 0;
        require(weth.transfer(msgSender(),bid),"Cannot transfer funds");
        entered = false;
    }

    // ------ UTILS

    function available(uint256 tokenId) external view returns (bool) {
        Offer memory offer = items[tokenId];
        if (!offer.available) return false;
        if (!offer.minted) return true;
        if (token.ownerOf(tokenId) != items[tokenId].creator) return false;
        if (token.isApprovedForAll(offer.creator, address(this))) return true;
        return (token.getApproved(tokenId) == address(this));
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0),"Do not set to address zero");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function changeWallet(address newWallet) public onlyOwner {
        require(newWallet != address(0),"Do not set to address zero");
        emit WalletTransferred(minty, newWallet);
        minty = newWallet;
    }

}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;



abstract contract ContextMixin {
    function msgSender()
        internal
        view
        returns (address payable sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }
       
        return sender;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {SafeMath} from  "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {EIP712Base} from "./EIP712Base.sol";

contract NativeMetaTransaction is EIP712Base {
    using SafeMath for uint256;
    bytes32 private constant META_TRANSACTION_TYPEHASH = keccak256(
        bytes(
            "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
        )
    );
    event MetaTransactionExecuted(
        address userAddress,
        address payable relayerAddress,
        bytes functionSignature
    );
    mapping(address => uint256) nonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable returns (bytes memory) {
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });

        require(
            verify(userAddress, metaTx, sigR, sigS, sigV),
            "Signer and signature do not match"
        );

        // increase nonce for user (to avoid re-use)
        nonces[userAddress] = nonces[userAddress].add(1);

        emit MetaTransactionExecuted(
            userAddress,
            payable(msg.sender),
            functionSignature
        );

        // Append userAddress and relayer address at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );
        require(success, "Function call not successful");

        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    META_TRANSACTION_TYPEHASH,
                    metaTx.nonce,
                    metaTx.from,
                    keccak256(metaTx.functionSignature)
                )
            );
    }

    function getNonce(address user) public view returns (uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(
        address signer,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        require(signer != address(0), "NativeMetaTransaction: INVALID_SIGNER");
        return
            signer ==
            ecrecover(
                toTypedMessageHash(hashMetaTransaction(metaTx)),
                sigV,
                sigR,
                sigS
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Initializable} from "./Initializable.sol";

contract EIP712Base is Initializable {
    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    string constant public ERC712_VERSION = "1";

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256(
        bytes(
            "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"
        )
    );
    bytes32 internal domainSeperator;

    // supposed to be called once while initializing.
    // one of the contracts that inherits this contract follows proxy pattern
    // so it is not possible to do this in a constructor
    function _initializeEIP712(
        string memory name
    )
        internal
        initializer
    {
        _setDomainSeperator(name);
    }

    function _setDomainSeperator(string memory name) internal {
        domainSeperator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(ERC712_VERSION)),
                address(this),
                bytes32(getChainId())
            )
        );
    }

    function getDomainSeperator() public view returns (bytes32) {
        return domainSeperator;
    }

    function getChainId() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     */
    function toTypedMessageHash(bytes32 messageHash)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", getDomainSeperator(), messageHash)
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Initializable {
    bool inited = false;

    modifier initializer() {
        require(!inited, "already inited");
        _;
        inited = true;
    }
}

