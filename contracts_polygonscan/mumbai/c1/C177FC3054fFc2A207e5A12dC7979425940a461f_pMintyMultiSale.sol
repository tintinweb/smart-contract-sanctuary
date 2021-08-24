//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
//pragma abicoder v2;

import "../common/meta-transactions/ContentMixin.sol";
import "../common/meta-transactions/NativeMetaTransaction.sol";

/*

    1. Allow Multiple Mints at once
    2. Restrict level 0 sales to people who satisfy the criteria set out in the 1155

*/

struct PoolEntry {
    address  beneficiary;
    uint256  share;
} 

interface IMintyMultiToken {

    function isApprovedForAll(address account, address operator) external view returns (bool);

    function mint(uint256 tokenId, uint256 quantity, string memory ipfsHash, uint256 poolId) external; // mints tokens to contract owner

    function mintBatch(uint [] memory tokenIds, uint [] memory quantities, string[] memory hashes, uint256 poolId) external;

    function minted(uint256 id) external view returns (bool) ;

    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes calldata data) external;

    function creator(uint256 tokenId) external view returns (address);

    function balanceOf(address account, uint256 id) external view returns (uint256); 

    function owner() external view returns (address);

    function uri(uint256 id) external view returns (string memory);

    function validateBuyer(address buyer) external; // should revert is not valid

    function getRoyalties(uint saleNumber, uint256 tokenId) external view returns (PoolEntry[] memory);

    function royaltyPerMille() external view returns (uint256);
}

abstract contract oldContract  {
    mapping(IMintyMultiToken      => mapping(uint256 => Offer1155[]))   public items; 
    function numberOfOffers(IMintyMultiToken token,uint tokenId) external view virtual returns (uint);
}


struct Offer1155 {
    address           creator;
    uint256           quantity;
    string            itemHash;
    uint256           unitPrice;
}

interface IERC20 {
    function transferFrom(address owner, address receiver, uint256 amount) external returns (bool);
}

contract pMintyMultiSale  is ContextMixin, NativeMetaTransaction {

    //          token                         tokenid     offer
    mapping(IMintyMultiToken      => mapping(uint256 => Offer1155[]))   public items; 

    mapping(IMintyMultiToken      => address) public multiTokenOwners;

    address                        public owner = msg.sender;
    IERC20                         public weth;

    bool                                  entered;
    uint                           public divisor;
    address                        public minty;

    bool                           public paused;

    //mapping(IMintyMultiToken => mapping(uint => mapping(address => uint256))) public bids;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event WalletTransferred(address indexed previousWallet, address indexed newWallet);

    event FeeUpdated(uint256 divisor);
    event NewOffer(IMintyMultiToken token, uint256 tokenId, address owner, uint256 quantity, uint256 price, string hash, uint256 poolId);
    event OfferWithdrawn(IMintyMultiToken token, uint256 tokenId);

    event ResaleOffer(IMintyMultiToken token,uint256 tokenId, uint256 quantity, address owner, uint256 price, uint256 position);
    event SaleRepriced(IMintyMultiToken token, uint256 tokenId, uint256 pos, uint256 price, address owner);
    event OfferAccepted(address buyer, IMintyMultiToken token, uint256 tokenId, uint256 pos, uint256 quantity, uint256 price);
    event SaleRetracted(IMintyMultiToken token, uint256 tokenId,uint256 pos, address owner);

    event BidReceived(address  bidder, IMintyMultiToken token, uint256 tokenId, uint256 bid);
    event BidIncreased(address bidder, IMintyMultiToken token, uint256 tokenId, uint256 previous_bid, uint256 this_bid);
    event BidWithdrawn(IMintyMultiToken token, uint256 tokenId);


    event Payment(address wallet,address creator, address _owner,uint256 amount);

    event Paused(bool isPaused);

    modifier onlyOwner() {
        require(msgSender() == owner, "unauthorised");
        _;
    }

    modifier notPaused() {
        require(!paused,"operation not permitted when sale is paused");
        _;
    }


    constructor(address wallet, IERC20 _weth, uint256 _divisor) {
        require(_divisor >= 1000, "Divisor must be >= 1000");
        minty = wallet;
        weth = _weth;
        divisor = _divisor;
        emit FeeUpdated(_divisor);
    }

    function updateShares(uint256 _divisor) external onlyOwner {
        require(_divisor >= 1000, "Divisor must be >= 1000");
        divisor = _divisor;
        emit FeeUpdated(_divisor);
    }

    function offerNew(IMintyMultiToken token, uint256 tokenId, string memory ipfsString, uint256 quantity, uint256 price, uint256 poolId) external notPaused {
        require(token.isApprovedForAll(msgSender(),address(this)),"You have not approved this contract to sell your tokens");
        require(!token.minted(tokenId),"Token ID already minted");
        require(token.owner() == msgSender(),"Unauthorised");
        require(items[token][tokenId].length == 0,"Unable to offer new");
        token.mint(tokenId,quantity,ipfsString, poolId);
        items[token][tokenId].push(Offer1155(msgSender(), quantity, ipfsString,price));
        emit NewOffer(token, tokenId, msgSender(), quantity, price, ipfsString,poolId);
        return;        
    }

    function offerNewBatch(IMintyMultiToken token, uint256[] memory tokenIds, string[] memory ipfsStrings, uint256[] memory quantities, uint256[] memory prices, uint256 poolId) external  notPaused {
        require(token.isApprovedForAll(msgSender(),address(this)),"You have not approved this contract to sell your tokens");
        require(token.owner() == msgSender(),"Unauthorised");
        for (uint j = 0; j < tokenIds.length; j++) {
            require(!token.minted(tokenIds[j]),"Token ID already minted");
            require(items[token][tokenIds[j]].length == 0,"Unable to offer new");
            items[token][tokenIds[j]].push(Offer1155(msgSender(), quantities[j], ipfsStrings[j],prices[j]));
            emit NewOffer(token, tokenIds[j], msgSender(), quantities[j], prices[j], ipfsStrings[j],poolId);
        }
        token.mintBatch(tokenIds,quantities,ipfsStrings, poolId);
        return;        
    }

    //   SistineToken--->132-->[(initial Offer)]

 
    function offerResale(IMintyMultiToken token, uint256 tokenId, uint256 quantity, uint256 price) external  notPaused {
        require((quantity <= token.balanceOf(msgSender(),tokenId) && (quantity > 0)),"You do not own enough of this token");
        require(token.isApprovedForAll(msgSender(),address(this)),"You have not approved this contract to sell your tokens");
        uint pos = items[token][tokenId].length;
        items[token][tokenId].push(Offer1155(msgSender(), quantity, token.uri(tokenId),price));
        emit ResaleOffer(token,tokenId, quantity,msgSender(), price, pos);
    }

   //   SistineToken--->132-->[(initial Offer),(resale offer)]

   //  SistineToken--->132-->[( Artist 5pcs )]
   //  SistineToken--->132-->[( Artist 3pcs )( Dave 1 pcs)]

   //                art_id


    function retractRemainingOffer(IMintyMultiToken token,uint256 tokenId, uint256 pos) external {
        require(pos < items[token][tokenId].length,"invalid offer position");
        Offer1155 memory offer = items[token][tokenId][pos];
        require(msgSender() == offer.creator, "not your offer");
        offer.quantity = 0;
        items[token][tokenId][pos] = offer;
        emit SaleRetracted(token,tokenId, pos, msgSender());
    }

    function reSubmitOffer(IMintyMultiToken token, uint256 tokenId, uint256 pos, uint256 price) external  notPaused {
        require(pos < items[token][tokenId].length,"invalid offer position");
        Offer1155 memory offer = items[token][tokenId][pos];
        require(msgSender() == offer.creator, "not your offer");
        offer.unitPrice = price;
        items[token][tokenId][pos] = offer;
        emit SaleRepriced(token,tokenId, pos, price, msgSender());
    }

    function acceptOffer(IMintyMultiToken token,uint tokenId, uint256 pos, uint256 quantity) external  notPaused {
        require(!entered,"No reentrancy please");
        if (pos == 0) {
            token.validateBuyer(msgSender());
        }
        entered = true;
        bytes memory data;
        Offer1155 memory offer = items[token][tokenId][pos];
        address _owner = offer.creator;
        require(offer.quantity >= quantity,"not enough items available");
        uint value = mul(offer.unitPrice,quantity);
        require(token.balanceOf(_owner,tokenId) >= quantity,"not enough items owned by offerer");
        token.safeTransferFrom(_owner,msgSender(),tokenId,quantity, data);

        offer.quantity -= quantity;
        items[token][tokenId][pos] = offer;
        emit Payment(minty,offer.creator,_owner,value);
        splitFee(token,tokenId, pos, _owner, value);
        entered = false;
        emit OfferAccepted(msgSender(), token, tokenId, pos, quantity, value);
    }

    //-------- UTILITY ------

    function numberOfOffers(IMintyMultiToken token,uint tokenId) external view returns (uint) {
        return items[token][tokenId].length;
    }

    function available(IMintyMultiToken token,uint tokenId, uint offerId) external view returns (uint) {
        require(offerId < items[token][tokenId].length,"OfferID not valid");
        Offer1155 memory offer = items[token][tokenId][offerId];
        if (!token.isApprovedForAll(offer.creator,address(this))) return 0;
        uint256 onOffer = offer.quantity;
        uint256 owned   = token.balanceOf(offer.creator,tokenId);
        return min(onOffer,owned);
    }

    function price(IMintyMultiToken token,uint tokenId, uint offerId) external view returns (uint) {
        require(offerId < items[token][tokenId].length,"OfferID not valid");
        Offer1155 memory offer = items[token][tokenId][offerId];
        if (!token.isApprovedForAll(offer.creator,address(this))) return 0;
        return offer.unitPrice;
    }


    function splitFee(IMintyMultiToken token, uint256 tokenId, uint256 position, address _seller, uint value) internal {
        
        uint royaltyPerMille = token.royaltyPerMille();
        uint royaltyPart = mul(value , royaltyPerMille) / divisor;

        uint sellerPart  = mul(value , (1000 - royaltyPerMille)) / divisor;
        require(weth.transferFrom(msgSender(),_seller,sellerPart),"cannot transfer funds");

        uint sent = sellerPart;
        PoolEntry[] memory royalties = token.getRoyalties(position, tokenId);
        for (uint j = 0; j < royalties.length; j++) {
            uint amount = mul(royaltyPart , royalties[j].share) / 1000;
            require(weth.transferFrom(msgSender(),royalties[j].beneficiary,amount),"cannot transfer funds");
            sent += amount;
        }

        uint mintyPart = value - sent;
        require(weth.transferFrom(msgSender(),minty,mintyPart),"cannot transfer funds");
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    function min(uint a, uint b) internal pure returns (uint) {
        if (a < b) return a;
        return b;
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

 

    // don't over engineer this - just the offers
    function transferItems(oldContract old, IMintyMultiToken token, uint256 tokenId) external onlyOwner {
        require(1 == old.numberOfOffers(token,tokenId),"Only when there is a single offer");
        // address           creator;
        // uint256           quantity;
        // string            itemHash;
        // uint256           unitPrice;
        Offer1155   memory   theOffer;
        (theOffer.creator,theOffer.quantity,theOffer.itemHash,theOffer.unitPrice) = old.items(token,tokenId,0);

        items[token][tokenId].push(theOffer);
    }

    function PauseSale(bool putOnHold) external onlyOwner {
        paused = putOnHold;
        emit Paused(putOnHold);
    }
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

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}