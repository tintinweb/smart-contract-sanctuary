pragma solidity 0.6.7;
pragma experimental ABIEncoderV2;

import "./../openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./../openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./../openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./../openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./../openzeppelin/contracts/math/SafeMath.sol";
import "./../openzeppelin/contracts/access/Ownable.sol";
import "./../openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Crowns.sol";
import "./NftMetadataInterface.sol";

/// @title Nft Swap is a part of Seascape marketplace platform.
/// It allows users to obtain desired nfts in exchange for their offered nfts,
/// a fee and an optional bounty
/// @author Nejc Schneider
contract NftSwap is Crowns, Ownable, ReentrancyGuard, IERC721Receiver {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;


    uint256 public lastOfferId;             /// @dev keep count of offers (aka offerIds)
    bool public tradeEnabled = true;        /// @dev enable/disable create and accept offer
    uint256 public fee;                     /// @dev fee for creating an offer

    /// @notice individual offer related data
    struct OfferObject{
        uint256 offerId;                   // offer ID
        uint8 offeredTokensAmount;         // total offered tokens
        uint8 requestedTokensAmount;       // total requested tokens
        uint256 bounty;                    // reward for the buyer
        address bountyAddress;             // currency address for paying bounties
        address payable seller;            // seller's address
        uint256 fee;                       // fee amount at the time offer was created
        mapping(uint256 => OfferedToken) offeredTokens;       // offered tokens data
        mapping(uint256 => RequestedToken) requestedTokens;   // requested tokensdata
    }

    /// @notice individual offered token related data
    struct OfferedToken{
        uint256 tokenId;                    // offered token id
        address tokenAddress;               // offered token address
    }

    /// @notice individual requested token related data
    struct RequestedToken{
        address tokenAddress;              // requested token address
        bytes tokenParams;                 // requested token Params - metadata
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    /// @dev store offer objects.
    /// @param offerId => OfferObject
    mapping(uint256 => OfferObject) offerObjects;
    /// @dev supported ERC721 and ERC20 contracts
    mapping(address => bool) public supportedBountyAddresses;
    /// @dev parse metadata contract addresses (1 per individual nftSeries)
    /// @param nftAddress => nftMetadata contract address
    mapping(address => address) public supportedNftAddresses;

    event CreateOffer(
        uint256 indexed offerId,
        address indexed seller,
        uint256 bounty,
        address indexed bountyAddress,
        uint256 fee,
        uint256 offeredTokensAmount,
        uint256 requestedTokensAmount,
        OfferedToken [5] offeredTokens,
        RequestedToken [5] requestedTokens
    );

    event AcceptOffer(
        uint256 indexed offerId,
        address indexed buyer,
        uint256 bounty,
        address indexed bountyAddress,
        uint256 fee,
        uint256 requestedTokensAmount,
        uint256 [5] requestedTokenIds,
        uint256 offeredTokensAmount,
        uint256 [5] offeredTokenIds
    );

    event CancelOffer(
        uint256 indexed offerId,
        address indexed seller
    );

    event NftReceived(address operator, address from, uint256 tokenId, bytes data);
    event Received(address, uint);

    /// @param _feeRate - fee amount
    /// @param _crownsAddress staking currency address
    constructor(uint256 _feeRate, address _crownsAddress) public {
        /// @dev set crowns is defined in Crowns.sol
        require(_crownsAddress != address(0x0), "invalid cws address");
        setCrowns(_crownsAddress);
        fee = _feeRate;
    }

    //--------------------------------------------------
    // External methods
    //--------------------------------------------------

    fallback() external payable {
        emit Received(msg.sender, msg.value);
    }

    /// @notice enable/disable trade
    /// @param _tradeEnabled set tradeEnabled to true/false
    function enableTrade(bool _tradeEnabled) external onlyOwner { tradeEnabled = _tradeEnabled; }

    /// @notice add supported nft contract
    /// @param _nftAddress ERC721 contract address
    // @param _nftMetadataAddress contract address
    function enableSupportedNftAddress(
        address _nftAddress,
        address _nftMetadataAddress
    )
        external
        onlyOwner
    {
        require(_nftAddress != address(0x0), "invalid nft address");
        require(_nftMetadataAddress != address(0x0), "invalid NftMetadata address");
        require(supportedNftAddresses[_nftAddress] == address(0x0),
            "nft address already enabled");
        supportedNftAddresses[_nftAddress] = _nftMetadataAddress;
    }

    /// @notice disable supported nft token
    /// @param _nftAddress ERC721 contract address
    function disableSupportedNftAddress(address _nftAddress) external onlyOwner {
        require(_nftAddress != address(0x0), "invalid address");
        require(supportedNftAddresses[_nftAddress] != address(0),
            "nft address already disabled");
        supportedNftAddresses[_nftAddress] = address(0x0);
    }

    /// @notice add supported currency address for bounty
    /// @param _bountyAddress ERC20 contract address
    function addSupportedBountyAddress(address _bountyAddress) external onlyOwner {
        require(!supportedBountyAddresses[_bountyAddress], "bounty already supported");
        supportedBountyAddresses[_bountyAddress] = true;
    }

    /// @notice disable supported currency address for bounty
    /// @param _bountyAddress ERC20 contract address
    function removeSupportedBountyAddress(address _bountyAddress) external onlyOwner {
        require(supportedBountyAddresses[_bountyAddress], "bounty already removed");
        supportedBountyAddresses[_bountyAddress] = false;
    }

    /// @notice change fee amount
    /// @param _feeRate set fee to this value.
    function setFee(uint256 _feeRate) external onlyOwner { fee = _feeRate; }

    /// @notice returns amount of offers
    /// @return total amount of offer objects
    function getLastOfferId() external view returns(uint) { return lastOfferId; }

    //--------------------------------------------------
    // Public methods
    //--------------------------------------------------

    /// @notice create a new offer
    /// @param _offeredTokensAmount how many nfts to offer
    /// @param _offeredTokens array of five OfferedToken structs
    /// @param _requestedTokensAmount amount of required nfts
    /// @param _requestedTokens array of five RequestedToken structs
    /// @param _bounty additional cws to offer to buyer
    /// @param _bountyAddress currency contract address for bounty
    /// @return lastOfferId total amount of offers
    function createOffer(
        uint8 _offeredTokensAmount,
        OfferedToken [5] memory _offeredTokens,
        uint8 _requestedTokensAmount,
        RequestedToken [5] memory _requestedTokens,
        uint256 _bounty,
        address _bountyAddress
    )
        public
        payable
        returns(uint256)
    {
        /// require statements
        require(tradeEnabled, "trade is disabled");
        require(_offeredTokensAmount > 0, "should offer at least one nft");
        require(_offeredTokensAmount <= 5, "cant offer more than 5 tokens");
        require(_requestedTokensAmount > 0, "should require at least one nft");
        require(_requestedTokensAmount <= 5, "cant request more than 5 tokens");
        // bounty & fee related requirements
        if (_bounty > 0) {
            if (address(crowns) == _bountyAddress) {
                require(crowns.balanceOf(msg.sender) >= fee + _bounty,
                    "not enough CWS for fee & bounty");
            } else {
                require(supportedBountyAddresses[_bountyAddress],
                    "bounty address not supported");

                if (_bountyAddress == address(0x0)) {
                    require (msg.value >= _bounty, "insufficient transfer amount");
                    uint256 returnBack = msg.value.sub(_bounty);
                    if (returnBack > 0)
                        msg.sender.transfer(returnBack);
                } else {
                    IERC20 currency = IERC20(_bountyAddress);
                    require(currency.balanceOf(msg.sender) >= _bounty,
                        "not enough money to pay bounty");
                }
            }
        } else {
            require(crowns.balanceOf(msg.sender) >= fee, "not enough CWS for fee");
        }
        /// input token verification
        // verify offered nft oddresses and ids
        for (uint index = 0; index < _offeredTokensAmount; index++) {
            // the following checks should only apply if slot at index is filled.
            require(_offeredTokens[index].tokenId > 0, "nft id must be greater than 0");
            require(supportedNftAddresses[_offeredTokens[index].tokenAddress] != address(0),
                "offered nft address unsupported");
            IERC721 nft = IERC721(_offeredTokens[index].tokenAddress);
            require(nft.ownerOf(_offeredTokens[index].tokenId) == msg.sender,
                "sender not owner of nft");
        }
        // verify requested nft oddresses
        for (uint _index = 0; _index < _requestedTokensAmount; _index++) {
            address nftMetadataAddress = supportedNftAddresses[_requestedTokens[_index].tokenAddress];
            require(nftMetadataAddress != address(0),
                "requested nft address unsupported");
            // verify nft parameters
            // external but trusted contract maintained by Seascape
            NftMetadataInterface requestedToken = NftMetadataInterface (nftMetadataAddress);
            require(requestedToken.metadataIsValid(lastOfferId, _requestedTokens[_index].tokenParams,
              _requestedTokens[_index].v, _requestedTokens[_index].r, _requestedTokens[_index].s),
                "invalid nft metadata");
        }

        /// make transactions
        // send offered nfts to smart contract
        for (uint index = 0; index < _offeredTokensAmount; index++) {
            // send nfts to contract
            IERC721(_offeredTokens[index].tokenAddress)
                .safeTransferFrom(msg.sender, address(this), _offeredTokens[index].tokenId);
        }
        // send fee and _bounty to contract
        if (_bounty > 0) {
            if (_bountyAddress == address(crowns)) {
                IERC20(crowns).safeTransferFrom(msg.sender, address(this), fee + _bounty);
            } else {
                if (_bountyAddress == address(0)) {
                    address(this).transfer(_bounty);
                } else {
                    IERC20(_bountyAddress).safeTransferFrom(msg.sender, address(this), _bounty);
                }
                IERC20(crowns).safeTransferFrom(msg.sender, address(this), fee);
            }
        } else {
            IERC20(crowns).safeTransferFrom(msg.sender, address(this), fee);
        }

        /// update states
        lastOfferId++;

        offerObjects[lastOfferId].offerId = lastOfferId;
        offerObjects[lastOfferId].offeredTokensAmount = _offeredTokensAmount;
        offerObjects[lastOfferId].requestedTokensAmount = _requestedTokensAmount;
        for(uint256 i = 0; i < _offeredTokensAmount; i++){
            offerObjects[lastOfferId].offeredTokens[i] = _offeredTokens[i];
        }
        for(uint256 i = 0; i < _requestedTokensAmount; i++){
            offerObjects[lastOfferId].requestedTokens[i] = _requestedTokens[i];
        }
        offerObjects[lastOfferId].bounty = _bounty;
        offerObjects[lastOfferId].bountyAddress = _bountyAddress;
        offerObjects[lastOfferId].seller = msg.sender;
        offerObjects[lastOfferId].fee = fee;

        /// emit events
        emit CreateOffer(
            lastOfferId,
            msg.sender,
            _bounty,
            _bountyAddress,
            fee,
            _offeredTokensAmount,
            _requestedTokensAmount,
            _offeredTokens,
            _requestedTokens
          );

        return lastOfferId;
    }

    /// @notice make a trade
    /// @param _offerId offer unique ID
    function acceptOffer(
        uint256 _offerId,
        uint256 [5] memory _requestedTokenIds,
        address [5] memory _requestedTokenAddresses,
        uint8 [5] memory _v,
        bytes32 [5] memory _r,
        bytes32 [5] memory _s
    )
        public
        nonReentrant
        payable
    {
        OfferObject storage obj = offerObjects[_offerId];
        require(tradeEnabled, "trade is disabled");
        require(msg.sender != obj.seller, "cant buy self-made offer");

        /// @dev verify requested tokens
        for(uint256 i = 0; i < obj.requestedTokensAmount; i++){
            require(_requestedTokenIds[i] > 0, "nft id must be greater than 0");
            require(_requestedTokenAddresses[i] == obj.requestedTokens[i].tokenAddress,
                "wrong requested token address");
            IERC721 nft = IERC721(obj.requestedTokens[i].tokenAddress);
            require(nft.ownerOf(_requestedTokenIds[i]) == msg.sender,
                "sender not owner of nft");
            /// digital signature part
            bytes32 _messageNoPrefix = keccak256(abi.encodePacked(
                _offerId,
                _requestedTokenIds[i],
                _requestedTokenAddresses[i],
                msg.sender
            ));
            bytes32 _message = keccak256(abi.encodePacked(
                "\x19Ethereum Signed Message:\n32", _messageNoPrefix));
            address _recover = ecrecover(_message, _v[i], _r[i], _s[i]);
            require(_recover == owner(),  "Verification failed");
        }

        /// make transactions
        // send requestedTokens from buyer to seller
        for (uint index = 0; index < obj.requestedTokensAmount; index++) {
            IERC721(_requestedTokenAddresses[index])
                .safeTransferFrom(msg.sender, obj.seller, _requestedTokenIds[index]);
        }
        // send offeredTokens from SC to buyer
        for (uint index = 0; index < obj.offeredTokensAmount; index++) {
            IERC721(obj.offeredTokens[index].tokenAddress)
                .safeTransferFrom(address(this), msg.sender, obj.offeredTokens[index].tokenId);
        }
        // spend obj.fee and send obj.bounty from SC to buyer
        crowns.spend(obj.fee);
        if(obj.bounty > 0) {
            if(obj.bountyAddress == address(0))
                msg.sender.transfer(obj.bounty);
            else
                IERC20(obj.bountyAddress).safeTransfer(msg.sender, obj.bounty);
        }

        /// emit events
        emit AcceptOffer(
            obj.offerId,
            msg.sender,
            obj.bounty,
            obj.bountyAddress,
            obj.fee,
            obj.requestedTokensAmount,
            _requestedTokenIds,
            obj.offeredTokensAmount,
            [obj.offeredTokens[0].tokenId,
            obj.offeredTokens[1].tokenId,
            obj.offeredTokens[2].tokenId,
            obj.offeredTokens[3].tokenId,
            obj.offeredTokens[4].tokenId]
        );

        /// update states
        delete offerObjects[_offerId];
    }

    /// @notice cancel the offer
    /// @param _offerId offer unique ID
    function cancelOffer(uint _offerId) public {
        OfferObject storage obj = offerObjects[_offerId];
        require(obj.seller == msg.sender, "sender is not creator of offer");

        /// make transactions
        // send the offeredTokens from SC to seller
        for (uint index=0; index < obj.offeredTokensAmount; index++) {
            IERC721(obj.offeredTokens[index].tokenAddress)
                .safeTransferFrom(address(this), obj.seller, obj.offeredTokens[index].tokenId);
        }

        // send crowns and bounty from SC to seller
        if (obj.bounty > 0) {
            if (obj.bountyAddress == address(crowns)) {
                crowns.transfer(msg.sender, obj.fee + obj.bounty);
            } else {
                if (obj.bountyAddress == address(0)) {
                    msg.sender.transfer(obj.bounty);
                } else {
                    IERC20(obj.bountyAddress).safeTransfer(msg.sender, obj.bounty);
                }
                crowns.transfer(msg.sender, obj.fee);
            }
        } else {
            crowns.transfer(msg.sender, obj.fee);
        }

        /// emit events
        emit CancelOffer(
            obj.offerId,
            obj.seller
        );

        /// update states
        delete offerObjects[_offerId];
    }

    /// @dev fetch offer object at offerId and nftAddress
    /// @param _offerId unique offer ID
    /// @return OfferObject at given index
    function getOffer(uint _offerId)
        external
        view
        returns(uint256, uint8, uint8, uint256, address, address, uint256)
    {
        return (
        offerObjects[_offerId].offerId,
        offerObjects[_offerId].offeredTokensAmount,
        offerObjects[_offerId].requestedTokensAmount,
        offerObjects[_offerId].bounty,
        offerObjects[_offerId].bountyAddress,
        offerObjects[_offerId].seller,
        offerObjects[_offerId].fee
        );
    }

    /// @dev encrypt token data
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    )
        public
        override
        returns (bytes4)
    {
        //only receive the _nft staff
        if (address(this) != operator) {
            //invalid from nft
            return 0;
        }

        //success
        emit NftReceived(operator, from, tokenId, data);
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
    external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transfered from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

// File: contracts/library/ReentrancyGuard.sol

pragma solidity ^0.6.7;

contract ReentrancyGuard {
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

    constructor() internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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

    function initReentrancyStatus() internal {
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity 0.6.7;


/// @dev Interface of the nftSwapParams

interface NftMetadataInterface {

    /// @dev Returns true if signature is valid
    function metadataIsValid(uint256 _offerId, bytes calldata _encodedParams,
        uint8 v, bytes32 r, bytes32 s) external view returns (bool);

}

pragma solidity 0.6.7;

import "./../crowns/erc-20/contracts/CrownsToken/CrownsToken.sol";

/// @dev Nft Rush and Leaderboard contracts both are with Crowns.
/// So, making Crowns available for both Contracts by moving it to another contract.
///
/// @author Medet Ahmetson
contract Crowns {
    CrownsToken public crowns;

   function setCrowns(address _crowns) internal {
        require(_crowns != address(0), "Crowns can't be zero address");
       	crowns = CrownsToken(_crowns);
   }
}

// contracts/Crowns.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.6.7;

import "./../../../../openzeppelin/contracts/access/Ownable.sol";
import "./../../../../openzeppelin/contracts/GSN/Context.sol";
import "./../../../../openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./../../../../openzeppelin/contracts/math/SafeMath.sol";
import "./../../../../openzeppelin/contracts/utils/Address.sol";

/// @title Official token of Blocklords and the Seascape ecosystem.
/// @author Medet Ahmetson
/// @notice Crowns (CWS) is an ERC-20 token with a Rebase feature.
/// Rebasing is a distribution of spent tokens among all current token holders.
/// In order to appear in balance, rebased tokens need to be claimed by users by triggering transaction with the ERC-20 contract.
/// @dev Implementation of the {IERC20} interface.
contract CrownsToken is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    struct Account {
        uint256 balance;
        uint256 lastRebase;
    }

    mapping (address => Account) private _accounts;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    uint256 private constant _minSpend = 10 ** 6;
    uint256 private constant _decimalFactor = 10 ** 18;
    uint256 private constant _million = 1000000;

    /// @notice Total amount of tokens that have yet to be transferred to token holders as part of a rebase.
    /// @dev Used Variable tracking unclaimed rebase token amounts.
    uint256 public unclaimedRebase = 0;
    /// @notice Amount of tokens spent by users that have not been rebased yet.
    /// @dev Calling the rebase function will move the amount to {totalRebase}
    uint256 public unconfirmedRebase = 0;
    /// @notice Total amount of tokens that were rebased overall.
    /// @dev Total aggregate rebase amount that is always increasing.
    uint256 public totalRebase = 0;

    /**
     * @dev Sets the {name} and {symbol} of token.
     * Initializes {decimals} with a default value of 18.
     * Mints all tokens.
     * Transfers ownership to another account. So, the token creator will not be counted as an owner.
     */
    constructor () public {
        _name = "Crowns";
        _symbol = "CWS";
        _decimals = 18;

        // Grant the minter roles to a specified account
        address inGameAirdropper     = 0xFa4D7D1AC9b7a7454D09B8eAdc35aA70599329EA;
        address rechargeDexManager   = 0x53bd91aEF5e84A61F9B87781A024ee648733f973;
        address teamManager          = 0xB5de2b5186E1Edc947B73019F3102EF53c2Ac691;
        address investManager        = 0x1D3Db9BCA5aa2CE931cE13B7B51f8E14F5895368;
        address communityManager     = 0x0811e2DFb6482507461ca2Ab583844313f2549B5;
        address newOwner             = msg.sender;

        // 3 million tokens
        uint256 inGameAirdrop        = 3 * _million * _decimalFactor;
        uint256 rechargeDex          = inGameAirdrop;
        // 1 million tokens
        uint256 teamAllocation       = 1 * _million * _decimalFactor;
        uint256 investment           = teamAllocation;
        // 750,000 tokens
        uint256 communityBounty      = 750000 * _decimalFactor;
        // 1,25 million tokens
        uint256 inGameReserve        = 1250000 * _decimalFactor; // reserve for the next 5 years.

        _mint(inGameAirdropper,      inGameAirdrop);
        _mint(rechargeDexManager,    rechargeDex);
        _mint(teamManager,           teamAllocation);
        _mint(investManager,         investment);
        _mint(communityManager,      communityBounty);
        _mint(newOwner,              inGameReserve);

        transferOwnership(newOwner);
   }

    /**
     * @notice Return amount of tokens that {account} gets during rebase
     * @dev Used both internally and externally to calculate the rebase amount
     * @param account is an address of token holder to calculate for
     * @return amount of tokens that player could get
     */
    function rebaseOwing (address account) public view returns(uint256) {
        Account memory _account = _accounts[account];

        uint256 newRebase = totalRebase.sub(_account.lastRebase);
        uint256 proportion = _account.balance.mul(newRebase);

        // The rebase is not a part of total supply, since it was moved out of balances
        uint256 supply = _totalSupply.sub(newRebase);

        // rebase owed proportional to current balance of the account.
        // The decimal factor is used to avoid floating issue.
        uint256 rebase = proportion.mul(_decimalFactor).div(supply).div(_decimalFactor);

        return rebase;
    }

    /**
     * @dev Called before any edit of {account} balance.
     * Modifier moves the belonging rebase amount to its balance.
     * @param account is an address of Token holder.
     */
    modifier updateAccount(address account) {
        uint256 owing = rebaseOwing(account);
        _accounts[account].lastRebase = totalRebase;

        if (owing > 0) {
            _accounts[account].balance    = _accounts[account].balance.add(owing);
            unclaimedRebase     = unclaimedRebase.sub(owing);

            emit Transfer(
                address(0),
                account,
                owing
            );
        }

        _;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _getBalance(account);
    }

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

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
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal updateAccount(sender) updateAccount(recipient) virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Can not send 0 token");
        require(_getBalance(sender) >= amount, "ERC20: Not enough token to send");

        _beforeTokenTransfer(sender, recipient, amount);

        _accounts[sender].balance =  _accounts[sender].balance.sub(amount);
        _accounts[recipient].balance = _accounts[recipient].balance.add(amount);

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _accounts[account].balance = _accounts[account].balance.add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Moves `amount` tokens from `account` to {unconfirmedRebase} without reducing the
     * total supply. Will be rebased among token holders.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal updateAccount(account) virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        require(_getBalance(account) >= amount, "ERC20: Not enough token to burn");

        _beforeTokenTransfer(account, address(0), amount);

        _accounts[account].balance = _accounts[account].balance.sub(amount);

        unconfirmedRebase = unconfirmedRebase.add(amount);

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }

    /**
     * @notice Spend some token from caller's balance in the game.
     * @dev Moves `amount` of token from caller to `unconfirmedRebase`.
     * @param amount Amount of token used to spend
     */
    function spend(uint256 amount) public returns(bool) {
        require(amount > _minSpend, "Crowns: trying to spend less than expected");
        require(_getBalance(msg.sender) >= amount, "Crowns: Not enough balance");

        _burn(msg.sender, amount);

	return true;
    }

    function spendFrom(address sender, uint256 amount) public returns(bool) {
	require(amount > _minSpend, "Crowns: trying to spend less than expected");
	require(_getBalance(sender) >= amount, "Crowns: not enough balance");

	_burn(sender, amount);
	_approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));

	return true;
    }

    /**
     * @notice Return the rebase amount, when `account` balance was updated.
     */
    function getLastRebase(address account) public view returns (uint256) {
        return _accounts[account].lastRebase;
    }

    /**
     * @dev Returns actual balance of account as a sum of owned divends and current balance.
     * @param account Address of Token holder.
     * @return Token amount
     */
    function _getBalance(address account) private view returns (uint256) {
        uint256 balance = _accounts[account].balance;
    	if (balance == 0) {
    		return 0;
    	}
    	uint256 owing = rebaseOwing(account);

    	return balance.add(owing);
    }

    /**
     * @dev Emitted when `spent` tokens are moved `unconfirmedRebase` to `totalRebase`.
     */
    event Rebase(
        uint256 spent,
        uint256 totalRebase
    );

    /**
     * @notice Rebasing is a unique feature of Crowns (CWS) token. It redistributes tokens spenth within game among all token holders.
     * @dev Moves tokens from {unconfirmedRebase} to {totalRebase}.
     * Any account balance related functions will use {totalRebase} to calculate the dividend shares for each account.
     *
     * Emits a {Rebase} event.
     */
    function rebase() public onlyOwner() returns (bool) {
    	totalRebase = totalRebase.add(unconfirmedRebase);
    	unclaimedRebase = unclaimedRebase.add(unconfirmedRebase);
    	unconfirmedRebase = 0;

        emit Rebase (
            unconfirmedRebase,
            totalRebase
        );

        return true;
    }
}