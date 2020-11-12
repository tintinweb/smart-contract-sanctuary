/**
 *Submitted for verification at Etherscan.io on 2020-10-29
*/

pragma solidity >=0.6.0 <0.7.0;

// Abstract contract for the full ERC 20 Token standard
// https://github.com/ethereum/EIPs/issues/20

interface ERC20Token {

    /**
     * @notice send `_value` token to `_to` from `msg.sender`
     * @param _to The address of the recipient
     * @param _value The amount of token to be transferred
     * @return success Whether the transfer was successful or not
     */
    function transfer(address _to, uint256 _value) external returns (bool success);

    /**
     * @notice `msg.sender` approves `_spender` to spend `_value` tokens
     * @param _spender The address of the account able to transfer the tokens
     * @param _value The amount of tokens to be approved for transfer
     * @return success Whether the approval was successful or not
     */
    function approve(address _spender, uint256 _value) external returns (bool success);

    /**
     * @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value The amount of token to be transferred
     * @return success Whether the transfer was successful or not
     */
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

    /**
     * @param _owner The address from which the balance will be retrieved
     * @return balance The balance
     */
    function balanceOf(address _owner) external view returns (uint256 balance);

    /**
     * @param _owner The address of the account owning tokens
     * @param _spender The address of the account able to transfer the tokens
     * @return remaining Amount of remaining tokens allowed to spent
     */
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    /**
     * @notice return total supply of tokens
     */
    function totalSupply() external view returns (uint256 supply);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract ReentrancyGuard {

    bool internal reentranceLock = false;

    /**
     * @dev Use this modifier on functions susceptible to reentrancy attacks
     */
    modifier reentrancyGuard() {
        require(!reentranceLock, "Reentrant call detected!");
        reentranceLock = true; // No no no, you naughty naughty!
        _;
        reentranceLock = false;
    }
}
pragma experimental ABIEncoderV2;





/**
 * @author Ricardo Guilherme Schmidt (Status Research & Development GmbH)
 * @notice interface for StickerMarket
 */
interface StickerMarket {

    event ClaimedTokens(address indexed _token, address indexed _controller, uint256 _amount);
    event MarketState(State state);
    event RegisterFee(uint256 value);
    event BurnRate(uint256 value);

    enum State { Invalid, Open, BuyOnly, Controlled, Closed }

    function state() external view returns(State);
    function snt() external view returns (address);
    function stickerPack() external view returns (address);
    function stickerType() external view returns (address);

    /**
     * @dev Mints NFT StickerPack in `_destination` account, and Transfers SNT using user allowance
     * emit NonfungibleToken.Transfer(`address(0)`, `_destination`, `tokenId`)
     * @notice buy a pack from market pack owner, including a StickerPack's token in `_destination` account with same metadata of `_packId`
     * @param _packId id of market pack
     * @param _destination owner of token being brought
     * @param _price agreed price
     * @return tokenId generated StickerPack token
     */
    function buyToken(
        uint256 _packId,
        address _destination,
        uint256 _price
    )
        external
        returns (uint256 tokenId);

    /**
     * @dev emits StickerMarket.Register(`packId`, `_urlHash`, `_price`, `_contenthash`)
     * @notice Registers to sell a sticker pack
     * @param _price cost in wei to users minting this pack
     * @param _donate value between 0-10000 representing percentage of `_price` that is donated to StickerMarket at every buy
     * @param _category listing category
     * @param _owner address of the beneficiary of buys
     * @param _contenthash EIP1577 pack contenthash for listings
     * @param _fee Fee msg.sender agrees to pay for this registration
     * @return packId Market position of Sticker Pack data.
     */
    function registerPack(
        uint256 _price,
        uint256 _donate,
        bytes4[] calldata _category,
        address _owner,
        bytes calldata _contenthash,
        uint256 _fee
    )
        external
        returns(uint256 packId);

}



/**
 * @dev ERC-721 non-fungible token standard. 
 * See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md.
 */
interface ERC721
{

  /**
   * @dev Emits when ownership of any NFT changes by any mechanism. This event emits when NFTs are
   * created (`from` == 0) and destroyed (`to` == 0). Exception: during contract creation, any
   * number of NFTs may be created and assigned without emitting Transfer. At the time of any
   * transfer, the approved address for that NFT (if any) is reset to none.
   */
  event Transfer(
    address indexed from,
    address indexed to,
    uint256 indexed value
  );

  /**
   * @dev This emits when the approved address for an NFT is changed or reaffirmed. The zero
   * address indicates there is no approved address. When a Transfer event emits, this also
   * indicates that the approved address for that NFT (if any) is reset to none.
   */
  event Approval(
    address indexed _owner,
    address indexed _approved,
    uint256 indexed _tokenId
  );

  /**
   * @dev This emits when an operator is enabled or disabled for an owner. The operator can manage
   * all NFTs of the owner.
   */
  event ApprovalForAll(
    address indexed _owner,
    address indexed _operator,
    bool _approved
  );

  /**
   * @dev Transfers the ownership of an NFT from one address to another address.
   * @notice Throws unless `msg.sender` is the current owner, an authorized operator, or the
   * approved address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is
   * the zero address. Throws if `_tokenId` is not a valid NFT. When transfer is complete, this
   * function checks if `_to` is a smart contract (code size > 0). If so, it calls
   * `onERC721Received` on `_to` and throws if the return value is not 
   * `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`.
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   * @param _data Additional data with no specified format, sent in call to `_to`.
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes calldata _data
  )
    external;

  /**
   * @dev Transfers the ownership of an NFT from one address to another address.
   * @notice This works identically to the other function with an extra data parameter, except this
   * function just sets data to ""
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external;

  /**
   * @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the approved
   * address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is the zero
   * address. Throws if `_tokenId` is not a valid NFT.
   * @notice The caller is responsible to confirm that `_to` is capable of receiving NFTs or else
   * they mayb be permanently lost.
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external;

  /**
   * @dev Set or reaffirm the approved address for an NFT.
   * @notice The zero address indicates there is no approved address. Throws unless `msg.sender` is
   * the current NFT owner, or an authorized operator of the current owner.
   * @param _approved The new approved NFT controller.
   * @param _tokenId The NFT to approve.
   */
  function approve(
    address _approved,
    uint256 _tokenId
  )
    external;

  /**
   * @dev Enables or disables approval for a third party ("operator") to manage all of
   * `msg.sender`'s assets. It also emits the ApprovalForAll event.
   * @notice The contract MUST allow multiple operators per owner.
   * @param _operator Address to add to the set of authorized operators.
   * @param _approved True if the operators is approved, false to revoke approval.
   */
  function setApprovalForAll(
    address _operator,
    bool _approved
  )
    external;

  /**
   * @dev Returns the number of NFTs owned by `_owner`. NFTs assigned to the zero address are
   * considered invalid, and this function throws for queries about the zero address.
   * @param _owner Address for whom to query the balance.
   * @return Balance of _owner.
   */
  function balanceOf(
    address _owner
  )
    external
    view
    returns (uint256);

  /**
   * @dev Returns the address of the owner of the NFT. NFTs assigned to zero address are considered
   * invalid, and queries about them do throw.
   * @param _tokenId The identifier for an NFT.
   * @return Address of _tokenId owner.
   */
  function ownerOf(
    uint256 _tokenId
  )
    external
    view
    returns (address);
    
  /**
   * @dev Get the approved address for a single NFT.
   * @notice Throws if `_tokenId` is not a valid NFT.
   * @param _tokenId The NFT to find the approved address for.
   * @return Address that _tokenId is approved for. 
   */
  function getApproved(
    uint256 _tokenId
  )
    external
    view
    returns (address);

  /**
   * @dev Returns true if `_operator` is an approved operator for `_owner`, false otherwise.
   * @param _owner The address that owns the NFTs.
   * @param _operator The address that acts on behalf of the owner.
   * @return True if approved for all, false otherwise.
   */
  function isApprovedForAll(
    address _owner,
    address _operator
  )
    external
    view
    returns (bool);

}



/**
 * @dev Optional enumeration extension for ERC-721 non-fungible token standard.
 * See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md.
 */
interface ERC721Enumerable
{

  /**
   * @dev Returns a count of valid NFTs tracked by this contract, where each one of them has an
   * assigned and queryable owner not equal to the zero address.
   * @return Total supply of NFTs.
   */
  function totalSupply()
    external
    view
    returns (uint256);

  /**
   * @dev Returns the token identifier for the `_index`th NFT. Sort order is not specified.
   * @param _index A counter less than `totalSupply()`.
   * @return Token id.
   */
  function tokenByIndex(
    uint256 _index
  )
    external
    view
    returns (uint256);

  /**
   * @dev Returns the token identifier for the `_index`th NFT assigned to `_owner`. Sort order is
   * not specified. It throws if `_index` >= `balanceOf(_owner)` or if `_owner` is the zero address,
   * representing invalid NFTs.
   * @param _owner An address where we are interested in NFTs owned by them.
   * @param _index A counter less than `balanceOf(_owner)`.
   * @return Token id.
   */
  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    external
    view
    returns (uint256);

}


/**
 * @author Ricardo Guilherme Schmidt (Status Research & Development GmbH)
 * @notice interface for StickerType
 */
/* interface */ abstract contract StickerType is ERC721, ERC721Enumerable { // Interfaces can't inherit

    /**
     * @notice controller can generate packs at will
     * @param _price cost in wei to users minting with _urlHash metadata
     * @param _donate optional amount of `_price` that is donated to StickerMarket at every buy
     * @param _category listing category
     * @param _owner address of the beneficiary of buys
     * @param _contenthash EIP1577 pack contenthash for listings
     * @return packId Market position of Sticker Pack data.
     */
    function generatePack(
        uint256 _price,
        uint256 _donate,
        bytes4[] calldata _category,
        address _owner,
        bytes calldata _contenthash
    )
        external
        virtual
        returns(uint256 packId);

    /**
     * @notice removes all market data about a marketed pack, can only be called by market controller
     * @param _packId position to be deleted
     * @param _limit limit of categories to cleanup
     */
    function purgePack(uint256 _packId, uint256 _limit)
        external
        virtual;

    /**
     * @notice changes contenthash of `_packId`, can only be called by controller
     * @param _packId which market position is being altered
     * @param _contenthash new contenthash
     */
    function setPackContenthash(uint256 _packId, bytes calldata _contenthash)
        external
        virtual;

    /**
     * @notice This method can be used by the controller to extract mistakenly
     *  sent tokens to this contract.
     * @param _token The address of the token contract that you want to recover
     *  set to 0 in case you want to extract ether.
     */
    function claimTokens(address _token)
        external
        virtual;

    /**
     * @notice changes price of `_packId`, can only be called when market is open
     * @param _packId pack id changing price settings
     * @param _price cost in wei to users minting this pack
     * @param _donate value between 0-10000 representing percentage of `_price` that is donated to StickerMarket at every buy
     */
    function setPackPrice(uint256 _packId, uint256 _price, uint256 _donate)
        external
        virtual;

    /**
     * @notice add caregory in `_packId`, can only be called when market is open
     * @param _packId pack adding category
     * @param _category category to list
     */
    function addPackCategory(uint256 _packId, bytes4 _category)
        external
        virtual;

    /**
     * @notice remove caregory in `_packId`, can only be called when market is open
     * @param _packId pack removing category
     * @param _category category to unlist
     */
    function removePackCategory(uint256 _packId, bytes4 _category)
        external
        virtual;

    /**
     * @notice Changes if pack is enabled for sell
     * @param _packId position edit
     * @param _mintable true to enable sell
     */
    function setPackState(uint256 _packId, bool _mintable)
        external
        virtual;

    /**
     * @notice read available market ids in a category (might be slow)
     * @param _category listing category
     * @return availableIds array of market id registered
     */
    function getAvailablePacks(bytes4 _category)
        external
        virtual
        view
        returns (uint256[] memory availableIds);

    /**
     * @notice count total packs in a category
     * @param _category listing category
     * @return size total number of packs in category
     */
    function getCategoryLength(bytes4 _category)
        external
        virtual
        view
        returns (uint256 size);

    /**
     * @notice read a packId in the category list at a specific index
     * @param _category listing category
     * @param _index index
     * @return packId on index
     */
    function getCategoryPack(bytes4 _category, uint256 _index)
        external
        virtual
        view
        returns (uint256 packId);

    /**
     * @notice returns all data from pack in market
     * @param _packId pack id being queried
     * @return category list of categories registered to this packType
     * @return owner authorship holder
     * @return mintable new pack can be generated (rare tool)
     * @return timestamp registration timestamp
     * @return price current price
     * @return contenthash EIP1577 encoded hash
     */
    function getPackData(uint256 _packId)
        external
        virtual
        view
        returns (
            bytes4[] memory category,
            address owner,
            bool mintable,
            uint256 timestamp,
            uint256 price,
            bytes memory contenthash
        );

    /**
     * @notice returns all data from pack in market
     * @param _packId pack id being queried
     * @return category list of categories registered to this packType
     * @return timestamp registration timestamp
     * @return contenthash EIP1577 encoded hash
     */
    function getPackSummary(uint256 _packId)
        external
        virtual
        view
        returns (
            bytes4[] memory category,
            uint256 timestamp,
            bytes memory contenthash
        );

    /**
     * @notice returns payment data for migrated contract
     * @param _packId pack id being queried
     * @return owner authorship holder
     * @return mintable new pack can be generated (rare tool)
     * @return price current price
     * @return donate informational value between 0-10000 representing percentage of `price` that is donated to StickerMarket at every buy
     */
    function getPaymentData(uint256 _packId)
        external
        virtual
        view
        returns (
            address owner,
            bool mintable,
            uint256 price,
            uint256 donate
        );
   
}




/**
 * @title SafeERC20
 * @dev Adapted from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/SafeERC20.sol
 * and https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol
 */
contract SafeTransfer {
    
    function _safeTransfer(ERC20Token token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function _safeTransferFrom(ERC20Token token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    
    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(ERC20Token token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(_isContract(address(token)), "SafeTransfer: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeTransfer: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeTransfer: ERC20 operation did not succeed");
        }
    }

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
    function _isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
}







/**
 * @author Ricardo Guilherme Schmidt (Status Research & Development GmbH)
 * @notice Owner's backdoor withdrawal logic, used for code reuse.
 */
contract TokenWithdrawer is SafeTransfer {
    /**
     * @dev Withdraw all balance of each `_tokens` into `_destination`.
     * @param _tokens address of ERC20 token, or zero for withdrawing ETH.
     * @param _destination receiver of token
     */
    function withdrawTokens(
        address[] memory _tokens,
        address payable _destination
    )
        internal
    {
        uint len = _tokens.length;
        for(uint i = 0; i < len; i++){
            withdrawToken(_tokens[i], _destination);
        }
    }

    /**
     * @dev Withdraw all balance of `_token` into `_destination`.
     * @param _token address of ERC20 token, or zero for withdrawing ETH.
     * @param _destination receiver of token
     */
    function withdrawToken(address _token, address payable _destination)
        internal
    {
        uint256 balance;
        if (_token == address(0)) {
            balance = address(this).balance;
            (bool success, ) = _destination.call.value(balance)("");
            require(success, "Transfer failed");
        } else {
            ERC20Token token = ERC20Token(_token);
            balance = token.balanceOf(address(this));
            _safeTransfer(token, _destination, balance);
        }
    }
}


/// @title Starterpack Distributor
/// @notice Attempts to deliver 1 and only 1 starterpack containing ETH, ERC20 Tokens and NFT Stickerpacks to an eligible recipient
/// @dev The contract assumes Signer has verified an In-App Purchase Receipt
contract SimplifiedDistributor is SafeTransfer, ReentrancyGuard, TokenWithdrawer {
    address payable public owner;  // Contract deployer can modify parameters
    address public signer; // Signer can only distribute Starterpacks

    // Defines the Starterpack parameters
    struct Pack {
        uint256 ethAmount; // The Amount of ETH to transfer to the recipient
        address[] tokens; // Array of ERC20 Contract Addresses
        uint256[] tokenAmounts; // Array of ERC20 amounts corresponding to cells in tokens[]
    }

    Pack public defaultPack;

    ERC20Token public sntToken;

    bool public pause = true;
    
    event RequireApproval(address attribution);
    
    mapping(address => uint) public maxPacksPerAttrAddress;
    uint public defaultMaxPacksForReferrals;
    mapping(address => uint) public packsPerAttrAddress;


    mapping(address => uint) public pendingAttributionCnt;
    mapping(address => uint) public attributionCnt;

    uint public totalPendingAttributions;
    
    struct Attribution {
        bool enabled;
        uint256 ethAmount; // The Amount of ETH to transfer to the referrer
        address[] tokens; // Array of ERC20 Contract Addresses
        uint256[] tokenAmounts; // Array of ERC20 amounts corresponding to cells in tokens[]
        uint limit;
    }
    
    mapping(address => Attribution) defaultAttributionSettings;
    mapping(address => Attribution) promoAttributionSettings;

    // Modifiers --------------------------------------------------------------------------------------------

    // Functions only Owner can call
    modifier onlyOwner {
        require(msg.sender == owner, "Unauthorized");
        _;
    }

    // Logic ------------------------------------------------------------------------------------------------

    /// @notice Check if an address is eligible for a starterpack
    /// @dev will return false if a transaction of distributePack for _recipient has been successfully executed
    ///      RETURNING TRUE BECAUSE ELIGIBILITY WILL BE HANDLED BY THE BACKEND
    /// @param _recipient The address to be checked for eligibility
    function eligible(address _recipient) public view returns (bool){
        return true;
    }

    /// @notice Get the starter pack configuration
    /// @return stickerMarket address Stickermarket contract address
    /// @return ethAmount uint256 ETH amount in wei that will be sent to a recipient
    /// @return tokens address[] List of tokens that will be sent to a recipient
    /// @return tokenAmounts uint[] Amount of tokens that will be sent to a recipient
    /// @return stickerPackIds uint[] List of sticker packs to send to a recipient
    function getDefaultPack() external view returns(address stickerMarket, uint256 ethAmount, address[] memory tokens, uint[] memory tokenAmounts, uint[] memory stickerPackIds) {
        ethAmount = defaultPack.ethAmount;
        tokens = defaultPack.tokens;
        tokenAmounts = defaultPack.tokenAmounts;
    }

    /// @notice Get the promo pack configuration
    /// @return stickerMarket address Stickermarket contract address
    /// @return ethAmount uint256 ETH amount in wei that will be sent to a recipient
    /// @return tokens address[] List of tokens that will be sent to a recipient
    /// @return tokenAmounts uint[] Amount of tokens that will be sent to a recipient
    /// @return stickerPackIds uint[] List of sticker packs to send to a recipient
    /// @return available uint number of promo packs available
    function getPromoPack() external view returns(address stickerMarket, uint256 ethAmount, address[] memory tokens, uint[] memory tokenAmounts, uint[] memory stickerPackIds, uint256 available) {
        // Removed the promo pack functionality, so returning default values (to not affect the ABI)
    }

    event Distributed(address indexed recipient, address indexed attribution);
    event AttributionReedeemed(address indexed recipient, uint qty);


    /// @notice Determines if there are starterpacks available for distribution
    /// @param _assignedTo: Address who refered the starterpack recipient. Use 0x0 when there is no _attribution address
    function starterPacksAvailable(address _assignedTo) public view returns(bool) {
        Attribution memory attr = defaultAttributionSettings[_assignedTo];
        if (!attr.enabled) {
            return packsPerAttrAddress[_assignedTo] < defaultMaxPacksForReferrals;
        } else {
            return packsPerAttrAddress[_assignedTo] < maxPacksPerAttrAddress[_assignedTo];
        }
    }

    /// @notice Distributes a starterpack to an eligible address. Either a promo pack or a default will be distributed depending on availability
    /// @dev Can only be called by signer, assumes signer has validated an IAP receipt, owner can block calling by pausing.
    /// @param _recipient A payable address that is sent a starterpack after being checked for eligibility
    /// @param _attribution A payable address who referred the starterpack purchaser 
    function distributePack(address payable _recipient, address payable _attribution) external reentrancyGuard {
        require(!pause, "Paused");
        require(msg.sender == signer, "Unauthorized");
        require(_recipient != _attribution, "Recipient should be different from Attribution address");


        Pack memory pack = defaultPack;

        // Transfer Tokens
        // Iterate over tokens[] and transfer the an amount corresponding to the i cell in tokenAmounts[]
        for (uint256 i = 0; i < pack.tokens.length; i++) {
            ERC20Token token = ERC20Token(pack.tokens[i]);
            uint256 amount = pack.tokenAmounts[i];
            require(token.transfer(_recipient, amount), "ERC20 operation did not succeed");
        }

        // Transfer ETH
        // .transfer bad post Istanbul fork :|
        (bool success, ) = _recipient.call.value(pack.ethAmount)("");
        require(success, "ETH Transfer failed");

        emit Distributed(_recipient, _attribution);

        if (_attribution == address(0)) {
            require(packsPerAttrAddress[address(0)] < maxPacksPerAttrAddress[address(0)], "No starter packs available");
            packsPerAttrAddress[address(0)]++;
            return;
        }

        Attribution memory attr = defaultAttributionSettings[_attribution];
        if (!attr.enabled) {
            require(packsPerAttrAddress[_attribution] < defaultMaxPacksForReferrals, "No starter packs available");
        } else {
            require(packsPerAttrAddress[_attribution] < maxPacksPerAttrAddress[_attribution], "No starter packs available");
        }

        pendingAttributionCnt[_attribution] += 1;
        totalPendingAttributions += 1;
        packsPerAttrAddress[_attribution]++;  
    }

    function withdrawAttributions() external {
        require(!pause, "Paused");
        
        uint pendingAttributions = pendingAttributionCnt[msg.sender];
        uint attributionsPaid = attributionCnt[msg.sender];

        if (pendingAttributions == 0) return;

        Attribution memory attr = defaultAttributionSettings[msg.sender];
        if (!attr.enabled) {
           attr = defaultAttributionSettings[address(0)];
        }

        uint totalETHToPay;
        uint totalSNTToPay;
        uint attributionsToPay;
        if((attributionsPaid + pendingAttributions) > attr.limit){
            emit RequireApproval(msg.sender);
            if(attributionsPaid < attr.limit){
                attributionsToPay = attr.limit - attributionsPaid;
            } else {
                attributionsToPay = 0;
            }
            attributionsPaid += attributionsToPay;
            pendingAttributions -= attributionsToPay;
        } else {
            attributionsToPay = pendingAttributions;
            attributionsPaid += attributionsToPay;
            pendingAttributions = 0;
        }

        emit AttributionReedeemed(msg.sender, attributionsToPay);

        totalPendingAttributions -= attributionsToPay;

        totalETHToPay += attributionsToPay * attr.ethAmount;

        for (uint256 i = 0; i < attr.tokens.length; i++) {
            if(attr.tokens[i] == address(sntToken)){
                totalSNTToPay += attributionsToPay * attr.tokenAmounts[i];
            } else {
                ERC20Token token = ERC20Token(attr.tokens[i]);
                uint256 amount = attributionsToPay * attr.tokenAmounts[i];
                _safeTransfer(token, msg.sender, amount);
            }
        }

        pendingAttributionCnt[msg.sender] = pendingAttributions;
        attributionCnt[msg.sender] = attributionsPaid;

        if (totalETHToPay != 0){
            
            (bool success, ) = msg.sender.call.value(totalETHToPay)("");
            require(success, "ETH Transfer failed");
        }

        if (totalSNTToPay != 0){
            ERC20Token token = ERC20Token(sntToken);
            _safeTransfer(token, msg.sender, totalSNTToPay);
        }
    }
    

    /// @notice Get rewards for specific referrer
    /// @param _account The address to obtain the attribution config
    /// @param _isPromo Indicates if the configuration for a promo should be returned or not
    /// @return ethAmount Amount of ETH in wei
    /// @return tokenLen Number of tokens configured as part of the reward
    /// @return maxThreshold If isPromo == true: Number of promo bonuses still available for that address else: Max number of attributions to pay before requiring approval
    /// @return attribCount Number of referrals
    function getReferralReward(address _account, bool _isPromo) public view returns (uint ethAmount, uint tokenLen, uint maxThreshold, uint attribCount) {
        require(_isPromo != true);
        Attribution memory attr = defaultAttributionSettings[_account];
        if (!attr.enabled) {
            attr = defaultAttributionSettings[address(0)];
        }
        
        ethAmount = attr.ethAmount;
        maxThreshold = attr.limit;
        attribCount = attributionCnt[_account];
        tokenLen = attr.tokens.length;
    }

    /// @notice Get token rewards for specific address
    /// @param _account The address to obtain the attribution's token config
    /// @param _isPromo Indicates if the configuration for a promo should be returned or not
    /// @param _idx Index of token array in the attribution used to obtain the token config
    /// @return token ERC20 contract address
    /// @return tokenAmount Amount of token configured in the attribution
    function getReferralRewardTokens(address _account, bool _isPromo, uint _idx) public view returns (address token, uint tokenAmount) {
        require(_isPromo != true);
        Attribution memory attr = defaultAttributionSettings[_account];
        if (!attr.enabled) {
            attr = defaultAttributionSettings[address(0)];
        }
        
        token = attr.tokens[_idx];
        tokenAmount = attr.tokenAmounts[_idx];
    }
    
    fallback() external payable  {
     // ...
    }
    
    // Admin ------------------------------------------------------------------------------------------------

    /// @notice Allows the Owner to allow or prohibit Signer from calling distributePack().
    /// @dev setPause must be called before Signer can call distributePack()
    function setPause(bool _pause) external onlyOwner {
        pause = _pause;
    }

    /// @notice Set a starter pack configuration
    /// @dev The Owner can change the default starterpack contents
    /// @param _newPack starter pack configuration
    /// @param _maxPacks Maximum number of starterpacks that can be distributed when no attribution address is used
    function changeStarterPack(Pack memory _newPack, uint _maxPacks, uint _defaultMaxPacksForReferrals) public onlyOwner {
        require(_newPack.tokens.length == _newPack.tokenAmounts.length, "Mismatch with Tokens & Amounts");

        for (uint256 i = 0; i < _newPack.tokens.length; i++) {
            require(_newPack.tokenAmounts[i] > 0, "Amounts must be non-zero");
        }

        maxPacksPerAttrAddress[address(0x0000000000000000000000000000000000000000)] = _maxPacks;
        defaultMaxPacksForReferrals = _defaultMaxPacksForReferrals;
        defaultPack = _newPack;
    }

    /// @notice Safety function allowing the owner to immediately pause starterpack distribution and withdraw all balances in the the contract
    function withdraw(address[] calldata _tokens) external onlyOwner {
        pause = true;
        withdrawTokens(_tokens, owner);
    }

    /// @notice Changes the Signer of the contract
    /// @param _newSigner The new Signer of the contract
    function changeSigner(address _newSigner) public onlyOwner {
        require(_newSigner != address(0), "zero_address not allowed");
        signer = _newSigner;
    }

    /// @notice Changes the owner of the contract
    /// @param _newOwner The new owner of the contract
    function changeOwner(address payable _newOwner) external onlyOwner {
        require(_newOwner != address(0), "zero_address not allowed");
        owner = _newOwner;
    }

    /// @notice Set default/custom payout and threshold for referrals
    /// @param _ethAmount Payout for referrals
    /// @param _thresholds Max number of referrals allowed beforee requiring approval
    /// @param _assignedTo Use a valid address here to set custom settings. To set the default payout and threshold, use address(0);
    /// @param _maxPacks Maximum number of starterpacks that can be distributed for the addresses in _assignedTo
    function setPayoutAndThreshold(
        uint256 _ethAmount,
        address[] calldata _tokens,
        uint256[] calldata _tokenAmounts,
        uint256[] calldata _thresholds,
        address[] calldata _assignedTo,
        uint[] calldata _maxPacks
    ) external onlyOwner {
        require(_thresholds.length == _assignedTo.length, "Array length mismatch");
        require(_thresholds.length == _maxPacks.length, "Array length mismatch");
        require(_tokens.length == _tokenAmounts.length, "Array length mismatch");

        for (uint256 i = 0; i < _thresholds.length; i++) {
            bool enabled = _assignedTo[i] != address(0);
            
            Attribution memory attr = Attribution({
                enabled: enabled,
                ethAmount: _ethAmount,
                limit: _thresholds[i],
                tokens: _tokens,
                tokenAmounts: _tokenAmounts
            });
            
            maxPacksPerAttrAddress[_assignedTo[i]] = _maxPacks[i];
            defaultAttributionSettings[_assignedTo[i]] = attr;
        }
    }
    
    /// @notice Remove attribution configuration for addresses
    /// @param _assignedTo Array of addresses with an attribution configured
    /// @param _isPromo Indicates if the configuration to delete is the promo or default
    function removePayoutAndThreshold(address[] calldata _assignedTo, bool _isPromo) external onlyOwner {
        for (uint256 i = 0; i < _assignedTo.length; i++) {
            delete defaultAttributionSettings[_assignedTo[i]];
        }
    }

    /// @notice Resets the counter of starterpacks distributed per address
    /// @param _assignedTo Array of addresses with an attribution configured or 0x0 if not using attribution
    function resetPackCounter(address[] calldata _assignedTo) external onlyOwner {
        for (uint256 i = 0; i < _assignedTo.length; i++) {
            delete packsPerAttrAddress[_assignedTo[i]];
        }
    }

    /// @notice Set SNT address
    /// @param _sntToken SNT token address
    function setSntToken(address _sntToken) external onlyOwner {
        sntToken = ERC20Token(_sntToken);
    }

    /// @notice Set Default Max Packs to distribute for referral addresses. This will be used when there is an attribution address in distribute pack, and the default attribution is used because a specific payout threshold has not been set for an address
    /// @param _maxPacks Max number of starterpacks to be distributed when there is an attribution address and a specific payout threshold has not been set
    function setDefaultMaxPacksForReferrals(uint _maxPacks) external onlyOwner {
        defaultMaxPacksForReferrals = _maxPacks;
    }

    /// @notice Set max packs to distribute for an specific referral address. This will override the limit set via setPayoutAndThreshold
    /// @param _assignedTo Referral address. Use 0x0 for when no attribution address is used
    /// @param _maxPacks Max number of starterpacks to be distributed by an address
    function setMaxPacksForReferrals(address _assignedTo, uint _maxPacks) external onlyOwner {
        maxPacksPerAttrAddress[_assignedTo] = _maxPacks;
    }

    /// @notice Set Default Max Packs to distribute when no attribution address is used
    /// @param _maxPacks Max number of starterpacks to be distributed when no attribution address is used
    function setDefaultMaxPacksForNonReferrals(uint _maxPacks) external onlyOwner {
        maxPacksPerAttrAddress[address(0)] = _maxPacks;
    }

    /// @param _signer allows the contract deployer(owner) to define the signer on construction
    /// @param _sntToken SNT token address
    constructor(address _signer, address _sntToken) public {
        require(_signer != address(0), "zero_address not allowed");
        owner = msg.sender;
        signer = _signer;
        sntToken = ERC20Token(_sntToken);
    }
}