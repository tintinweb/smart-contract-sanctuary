/**
 *Submitted for verification at Etherscan.io on 2022-01-13
*/

// File: contracts/brokerV2_utils/ERC20Addresses.sol

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

// library for erc20address array 
library ERC20Addresses {
    using ERC20Addresses for erc20Addresses;

    struct erc20Addresses {
        address[] array;
    }

    function addERC20Tokens(erc20Addresses storage self, address erc20address)
        external
    {
        self.array.push(erc20address);
    }

    function getIndexByERC20Token(
        erc20Addresses storage self,
        address _ercTokenAddress
    ) internal view returns (uint256, bool) {
        uint256 index;
        bool exists;

        for (uint256 i = 0; i < self.array.length; i++) {
            if (self.array[i] == _ercTokenAddress) {
                index = i;
                exists = true;

                break;
            }
        }
        return (index, exists);
    }

    function removeERC20Token(
        erc20Addresses storage self,
        address _ercTokenAddress
    ) internal {
        if (self.array.length > 1){
            for (uint256 i = 0; i < self.array.length; i++) {
                    if (
                        self.array[i] == _ercTokenAddress 
                    ) {
                        delete self.array[i];
                    }
                }
        }
        else{
            self.array.length = 0;
        }
    }
    function exists(
        erc20Addresses storage self,
        address _ercTokenAddress
    ) internal view returns (bool) {
        for (uint256 i = 0; i < self.array.length; i++) {
            if (
                self.array[i] == _ercTokenAddress 
            ) {
                return true;
            }
        }
        return false;
    }
}

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

// pragma solidity ^0.8.0;
pragma solidity ^0.5.0;


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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // (bool success, ) = recipient.call{value: amount}("");
        (bool success, ) = recipient.call.value(amount)("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call.value(value)(
            data
        );
        //  (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// File: @openzeppelin/contracts/proxy/utils/Initializable.sol


// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.5.0;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```

 * constructor() initializer {}
 * ```
 * ====
 */
 contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

// File: contracts/brokerV2_utils/Ownable.sol

pragma solidity ^0.5.0;


 contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view  returns (address) {
        return msg.sender;
    }

    function _msgData() internal pure returns(bytes memory ) {
        return msg.data;
    }
    uint256[50] private __gap;
}


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
 contract OwnableUpgradeable is ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view  returns (address) {
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
    function renounceOwnership() public  onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public  onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal  {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// File: contracts/brokerV2_utils/TokenDetArrayLib.sol

pragma solidity ^0.5.17;

// librray for TokenDets
library TokenDetArrayLib {
    // Using for array of strcutres for storing mintable address and token id
    using TokenDetArrayLib for TokenDets;

    struct TokenDet {
        address NFTAddress;
        uint256 tokenID;
    }

    // custom type array TokenDets
    struct TokenDets {
        TokenDet[] array;
    }

    function addTokenDet(
        TokenDets storage self,
        TokenDet memory _tokenDet
        // address _mintableAddress,
        // uint256 _tokenID
    ) public {
        if (!self.exists(_tokenDet)) {
            self.array.push(_tokenDet);
        }
    }

    function getIndexByTokenDet(
        TokenDets storage self,
        TokenDet memory _tokenDet
    ) internal view returns (uint256, bool) {
        uint256 index;
        bool tokenExists = false;
        for (uint256 i = 0; i < self.array.length; i++) {
            if (
                self.array[i].NFTAddress == _tokenDet.NFTAddress &&
                self.array[i].tokenID == _tokenDet.tokenID 
            ) {
                index = i;
                tokenExists = true;
                break;
            }
        }
        return (index, tokenExists);
    }

    function removeTokenDet(
        TokenDets storage self,
        TokenDet memory _tokenDet
    ) internal returns (bool) {
        (uint256 i, bool tokenExists) = self.getIndexByTokenDet(_tokenDet);
        if (tokenExists == true) {
            self.array[i] = self.array[self.array.length - 1];
            self.array.pop();
            return true;
        }
        return false;
    }

    function exists(
        TokenDets storage self,
        TokenDet memory _tokenDet
    ) internal view returns (bool) {
        for (uint256 i = 0; i < self.array.length; i++) {
            if (
                self.array[i].NFTAddress == _tokenDet.NFTAddress &&
                self.array[i].tokenID == _tokenDet.tokenID
            ) {
                return true;
            }
        }
        return false;
    }
}
// File: contracts/brokerV2_utils/Storage.sol

pragma solidity ^0.5.17;



// import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";

interface IERC20 {
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) public returns (bytes4);
}




contract ERC721HolderUpgradeable is Initializable, IERC721Receiver {
    function __ERC721Holder_init() internal onlyInitializing {
        __ERC721Holder_init_unchained();
    }

    function __ERC721Holder_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public returns (bytes4) {
        return this.onERC721Received.selector;
    }
    uint256[50] private __gap;
}
// contract ERC721HolderUpgradeable is IERC721Receiver {


//     function onERC721Received(
//         address,
//         address,
//         uint256,
//         bytes memory
//     ) public returns (bytes4) {
//         return this.onERC721Received.selector;
//     }
// }

contract IMintableToken {
    // Required methods
    function ownerOf(uint256 _tokenId) external view returns (address owner);

    function royalities(uint256 _tokenId) public view returns (uint256);

    function creators(uint256 _tokenId) public view returns (address payable);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public;

    function getApproved(uint256 tokenId)
        public
        view
        returns (address operator);

    // Events
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

    // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
    function supportsInterface(bytes4 _interfaceID)
        external
        view
        returns (bool);
}

contract Storage is OwnableUpgradeable {
    using TokenDetArrayLib for TokenDetArrayLib.TokenDets;
    using ERC20Addresses for ERC20Addresses.erc20Addresses;
    // address owner;
    uint16 public brokerage;
    uint256 public updateClosingTime;
    mapping(address => mapping(uint256 => bool)) tokenOpenForSale;
    mapping(address => TokenDetArrayLib.TokenDets) tokensForSalePerUser;
    TokenDetArrayLib.TokenDets fixedPriceTokens;
    TokenDetArrayLib.TokenDets auctionTokens;

    //auction type :
    // 1 : only direct buy
    // 2 : only bid
    // 3 : both buy and bid

    struct auction {
        address payable lastOwner;
        uint256 currentBid;
        address payable highestBidder;
        uint256 auctionType;
        uint256 startingPrice;
        uint256 buyPrice;
        bool buyer;
        uint256 startingTime;
        uint256 closingTime;
        address erc20Token;
    }

    struct OfferDetails {
        address offerer;
        uint256 amount;
    }
    // address[] public offererAddressArray ;
    // mapping(address => mapping(uint256 => OfferDetails)) public offerprice;
    mapping(address => mapping(uint256 => OfferDetails)) public offerprice;

    mapping(address => mapping(uint256 => auction)) public auctions;

    TokenDetArrayLib.TokenDets tokensForSale;
    ERC20Addresses.erc20Addresses erc20TokensArray;

    function getErc20Tokens()
        public
        view
        returns (ERC20Addresses.erc20Addresses memory)
    {
        return erc20TokensArray;
    }

    function getTokensForSale()
        public
        view
        returns (TokenDetArrayLib.TokenDet[] memory)
    {
        return tokensForSale.array;
    }

    function getFixedPriceTokensForSale()
        public
        view
        returns (TokenDetArrayLib.TokenDet[] memory)
    {
        return fixedPriceTokens.array;
    }

    function getAuctionTokensForSale()
        public
        view
        returns (TokenDetArrayLib.TokenDet[] memory)
    {
        return auctionTokens.array;
    }

    function getTokensForSalePerUser(address _user)
        public
        view
        returns (TokenDetArrayLib.TokenDet[] memory)
    {
        return tokensForSalePerUser[_user].array;
    }

    function setBrokerage(uint16 _brokerage) public onlyOwner {
        brokerage = _brokerage;
    }

    function setUpdatedClosingTime(uint256 _updateTime) public onlyOwner {
        updateClosingTime = _updateTime;
    }
}

// File: contracts/brokerV2_utils/BrokerModifiers.sol

pragma solidity 0.5.17;


contract BrokerModifiers is Storage {
    modifier erc20Allowed(address _erc20Token) {
        if (_erc20Token != address(0)) {
            require(
                erc20TokensArray.exists(_erc20Token),
                "ERC20 not allowed"
            );
        }
        _;
    }

    modifier onSaleOnly(uint256 tokenID, address _mintableToken) {
        require(
            tokenOpenForSale[_mintableToken][tokenID] == true,
            "Token Not For Sale"
        );
        _;
    }

    modifier activeAuction(uint256 tokenID, address _mintableToken) {
        require(
            block.timestamp < auctions[_mintableToken][tokenID].closingTime,
            "Auction Time Over!"
        );
        require(
            block.timestamp > auctions[_mintableToken][tokenID].startingTime,
            "Auction Not Started yet!"
        );
        _;
    }

    modifier auctionOnly(uint256 tokenID, address _mintableToken) {
        require(
            auctions[_mintableToken][tokenID].auctionType != 1,
            "Auction Not For Bid"
        );
        _;
    }

    modifier flatSaleOnly(uint256 tokenID, address _mintableToken) {
        require(
            auctions[_mintableToken][tokenID].auctionType != 2,
            "Auction for Bid only!"
        );
        _;
    }

    modifier tokenOwnerOnlly(uint256 tokenID, address _mintableToken) {
        // Sender will be owner only if no have bidded on auction.
        require(
            IMintableToken(_mintableToken).ownerOf(tokenID) == msg.sender,
            "You must be owner and Token should not have any bid"
        );
        _;
    }
}

// File: contracts/BrokerV3.sol

pragma solidity ^0.5.17;



contract BrokerV2 is ERC721HolderUpgradeable, BrokerModifiers {
    // events
    event Bid(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        address bidder,
        uint256 amouont,
        uint256 time,
        address ERC20Address
    );
    event Buy(
        address indexed collection,
        uint256 tokenId,
        address indexed seller,
        address indexed buyer,
        uint256 amount,
        uint256 time,
        address ERC20Address
    );
    event Collect(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        address buyer,
        address collector,
        uint256 time,
        address ERC20Address
    );
    event OnSale(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 auctionType,
        uint256 amount,
        uint256 time,
        address ERC20Address
    );
    event PriceUpdated(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 auctionType,
        uint256 oldAmount,
        uint256 amount,
        uint256 time,
        address ERC20Address
    );
    event OffSale(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 time,
        address ERC20Address
    );

    event MakeAnOffer(
        address indexed collection,
        uint256 tokenId,
        address indexed offerer,
        uint256 offerAmount
    );

    event AcceptAnOffer(
        address indexed collection,
        uint256 tokenId,
        address indexed selectedAddress
    );

    mapping(address => uint256) public brokerageBalance;

    // constructor(uint16 _brokerage, uint256 _updatedTime) public {
    //     brokerage = _brokerage;
    //     setUpdatedClosingTime(_updatedTime);
    //     transferOwnership(msg.sender);
    // }
     

   

    function initialize(uint16 _brokerage, uint256 _updatedTime) public initializer {
        OwnableUpgradeable.__Ownable_init();
        brokerage = _brokerage;
        setUpdatedClosingTime(_updatedTime);
        transferOwnership(msg.sender);
    }


    function makeAnOffer(
        uint256 tokenID,
        address _mintableToken,
        uint256 amount
    )
        public
        payable
        onSaleOnly(tokenID, _mintableToken)
        activeAuction(tokenID, _mintableToken)
    {
        auction memory _auction = auctions[_mintableToken][tokenID];

        if (_auction.erc20Token == address(0)) {
            require(
                msg.value >= offerprice[_mintableToken][tokenID].amount,
                "amount is not less  than msg value"
            );

            if (
                offerprice[_mintableToken][tokenID].offerer != address(0) &&
                offerprice[_mintableToken][tokenID].amount != 0
            ) {
                address(uint160(offerprice[_mintableToken][tokenID].offerer))
                    .transfer(offerprice[_mintableToken][tokenID].amount);
            }
            offerprice[_mintableToken][tokenID] = OfferDetails(
                msg.sender,
                msg.value
            );
        } else {
            IERC20 erc20Token = IERC20(_auction.erc20Token);
            require(
                erc20Token.allowance(msg.sender, address(this)) >=
                    _auction.buyPrice,
                "Insufficient spent allowance "
            );

            erc20Token.transferFrom(msg.sender, address(this), amount);
            if (
                offerprice[_mintableToken][tokenID].offerer != address(0) &&
                offerprice[_mintableToken][tokenID].amount != 0
            ) {
                erc20Token.transfer(
                    offerprice[_mintableToken][tokenID].offerer,
                    offerprice[_mintableToken][tokenID].amount
                );
            }
            offerprice[_mintableToken][tokenID] = OfferDetails(
                msg.sender,
                amount
            );
        }
        emit MakeAnOffer(_mintableToken, tokenID, msg.sender, amount);
    }

    function balofBroker() public view returns (uint256) {
        return (address(this).balance);
    }

    function AccpetOffer(uint256 tokenID, address _mintableToken)
        public
        payable
        onSaleOnly(tokenID, _mintableToken)
        activeAuction(tokenID, _mintableToken)
    {
        auction memory _auction = auctions[_mintableToken][tokenID];

        IMintableToken Token = IMintableToken(_mintableToken);

        TokenDetArrayLib.TokenDet memory _tokenDet = TokenDetArrayLib.TokenDet(
            _mintableToken,
            tokenID
        );

        uint256 stackdeepFixtokenID = tokenID;

        address _mintableTokenstackdeepfix = _mintableToken;

        require(
            offerprice[_mintableToken][tokenID].offerer != address(0),
            "selected candidate amount not match "
        );

        address payable lastOwner2 = _auction.lastOwner;
        uint256 royalities = Token.royalities(stackdeepFixtokenID);
        address payable creator = Token.creators(stackdeepFixtokenID);
        uint256 royality = (royalities *
            offerprice[_mintableTokenstackdeepfix][stackdeepFixtokenID]
                .amount) / 10000;
        uint256 brokerageAmount = (brokerage *
            offerprice[_mintableTokenstackdeepfix][stackdeepFixtokenID]
                .amount) / 10000;

        uint256 lastOwner_funds = offerprice[_mintableTokenstackdeepfix][
            stackdeepFixtokenID
        ].amount -
            royality -
            brokerageAmount;

        if (_auction.erc20Token == address(0)) {
            creator.transfer(royality);
            lastOwner2.transfer(lastOwner_funds);
        } else {
            IERC20 erc20Token = IERC20(_auction.erc20Token);

            // transfer royalitiy to creator
            erc20Token.transfer(creator, royality);
            erc20Token.transfer(lastOwner2, lastOwner_funds);
        }

        brokerageBalance[_auction.erc20Token] += brokerageAmount;
        tokenOpenForSale[_tokenDet.NFTAddress][_tokenDet.tokenID] = false;

        Token.safeTransferFrom(
            Token.ownerOf(_tokenDet.tokenID),
            offerprice[_mintableTokenstackdeepfix][stackdeepFixtokenID].offerer,
            _tokenDet.tokenID
        );
        emit AcceptAnOffer(
            _mintableTokenstackdeepfix,
            stackdeepFixtokenID,
            offerprice[_mintableTokenstackdeepfix][stackdeepFixtokenID].offerer
        );

        delete offerprice[_mintableTokenstackdeepfix][stackdeepFixtokenID];

        tokensForSale.removeTokenDet(_tokenDet);
        tokensForSalePerUser[lastOwner2].removeTokenDet(_tokenDet);

        fixedPriceTokens.removeTokenDet(_tokenDet);
        delete auctions[_tokenDet.NFTAddress][_tokenDet.tokenID];
    }

    function _revertOffer(address _mintableToken, uint256 tokenID) private {
        address(uint160(offerprice[_mintableToken][tokenID].offerer)).transfer(
            offerprice[_mintableToken][tokenID].amount
        );
    }

    function revertOffer(address _mintableToken, uint256 _tokenID)
        public
        payable
    {
        require(msg.sender == offerprice[_mintableToken][_tokenID].offerer);

        _revertOffer(_mintableToken, _tokenID);
    }

    function revertOffererc20Token(uint256 _tokenID, address _mintableToken)
        public
    {
        require(msg.sender == offerprice[_mintableToken][_tokenID].offerer);
        _revertOffererc20Token(_mintableToken, _tokenID);
    }

    function _revertOffererc20Token(address _mintableToken, uint256 tokenID)
        private
    {
        auction memory _auction = auctions[_mintableToken][tokenID];

        IERC20 erc20Token = IERC20(_auction.erc20Token);

        // transfer royalitiy to creator
        erc20Token.transfer(
            offerprice[_mintableToken][tokenID].offerer,
            offerprice[_mintableToken][tokenID].amount
        );

        delete offerprice[_mintableToken][tokenID];
    }

    function addERC20TokenPayment(address _erc20Token) public onlyOwner {
        erc20TokensArray.addERC20Tokens(_erc20Token);
    }

    function removeERC20TokenPayment(address _erc20Token)
        public
        erc20Allowed(_erc20Token)
        onlyOwner
    {
        erc20TokensArray.removeERC20Token(_erc20Token);
    }

    function bid(
        uint256 tokenID,
        address _mintableToken,
        uint256 amount
    )
        public
        payable
        onSaleOnly(tokenID, _mintableToken)
        activeAuction(tokenID, _mintableToken)
    {
        IMintableToken Token = IMintableToken(_mintableToken);

        auction memory _auction = auctions[_mintableToken][tokenID];

        if (_auction.erc20Token == address(0)) {
            require(
                msg.value > _auction.currentBid,
                "Insufficient bidding amount."
            );

            if (_auction.buyer == true) {
                _auction.highestBidder.transfer(_auction.currentBid);
            }
        } else {
            IERC20 erc20Token = IERC20(_auction.erc20Token);
            require(
                erc20Token.allowance(msg.sender, address(this)) >= amount,
                "Allowance is less than amount sent for bidding."
            );
            require(
                amount > _auction.currentBid,
                "Insufficient bidding amount."
            );
            erc20Token.transferFrom(msg.sender, address(this), amount);

            if (_auction.buyer == true) {
                erc20Token.transfer(
                    _auction.highestBidder,
                    _auction.currentBid
                );
            }
        }

        _auction.currentBid = _auction.erc20Token == address(0)
            ? msg.value
            : amount;

        Token.safeTransferFrom(Token.ownerOf(tokenID), address(this), tokenID);
        _auction.buyer = true;
        _auction.highestBidder = msg.sender;
        _auction.closingTime += updateClosingTime;
        auctions[_mintableToken][tokenID] = _auction;

        // Bid event
        emit Bid(
            _mintableToken,
            tokenID,
            _auction.lastOwner,
            _auction.highestBidder,
            _auction.currentBid,
            block.timestamp,
            _auction.erc20Token
        );
    }

    // Collect Function are use to collect funds and NFT from Broker
    function collect(uint256 tokenID, address _mintableToken) public {
        IMintableToken Token = IMintableToken(_mintableToken);
        auction memory _auction = auctions[_mintableToken][tokenID];
        TokenDetArrayLib.TokenDet memory _tokenDet = TokenDetArrayLib.TokenDet(
            _mintableToken,
            tokenID
        );

        require(
            block.timestamp > _auction.closingTime && _auction.auctionType == 2,
            "Auction Not Over!"
        );

        address payable lastOwner2 = _auction.lastOwner;
        uint256 royalities = Token.royalities(tokenID);
        address payable creator = Token.creators(tokenID);

        uint256 royality = (royalities * _auction.currentBid) / 10000;
        uint256 brokerageAmount = (brokerage * _auction.currentBid) / 10000;

        // uint256 lastOwner_funds = ((10000 - royalities - brokerage) *
        //     _auction.currentBid) / 10000;

        uint256 lastOwner_funds = _auction.currentBid -
            royality -
            brokerageAmount;

        if (_auction.buyer == true) {
            if (_auction.erc20Token == address(0)) {
                creator.transfer(royality);
                lastOwner2.transfer(lastOwner_funds);
            } else {
                IERC20 erc20Token = IERC20(_auction.erc20Token);
                // transfer royalitiy to creator
                erc20Token.transfer(creator, royality);
                erc20Token.transfer(lastOwner2, lastOwner_funds);
            }
            brokerageBalance[_auction.erc20Token] += brokerageAmount;
            tokenOpenForSale[_mintableToken][tokenID] = false;
            Token.safeTransferFrom(
                Token.ownerOf(tokenID),
                _auction.highestBidder,
                tokenID
            );

            // Buy event
            emit Buy(
                _tokenDet.NFTAddress,
                _tokenDet.tokenID,
                lastOwner2,
                _auction.highestBidder,
                _auction.currentBid,
                block.timestamp,
                _auction.erc20Token
            );
        }

        // Collect event
        emit Collect(
            _tokenDet.NFTAddress,
            _tokenDet.tokenID,
            lastOwner2,
            _auction.highestBidder,
            msg.sender,
            block.timestamp,
            _auction.erc20Token
        );

        tokensForSale.removeTokenDet(_tokenDet);

        tokensForSalePerUser[lastOwner2].removeTokenDet(_tokenDet);
        auctionTokens.removeTokenDet(_tokenDet);
        delete auctions[_mintableToken][tokenID];
    }

    function buy(uint256 tokenID, address _mintableToken)
        public
        payable
        onSaleOnly(tokenID, _mintableToken)
        flatSaleOnly(tokenID, _mintableToken)
    {
        IMintableToken Token = IMintableToken(_mintableToken);
        auction memory _auction = auctions[_mintableToken][tokenID];
        TokenDetArrayLib.TokenDet memory _tokenDet = TokenDetArrayLib.TokenDet(
            _mintableToken,
            tokenID
        );

        address payable lastOwner2 = _auction.lastOwner;
        uint256 royalities = Token.royalities(tokenID);
        address payable creator = Token.creators(tokenID);
        uint256 royality = (royalities * _auction.buyPrice) / 10000;
        uint256 brokerageAmount = (brokerage * _auction.buyPrice) / 10000;

        uint256 lastOwner_funds = _auction.buyPrice -
            royality -
            brokerageAmount;

        if (_auction.erc20Token == address(0)) {
            require(msg.value >= _auction.buyPrice, "Insufficient Payment");

            creator.transfer(royality);
            lastOwner2.transfer(lastOwner_funds);
        } else {
            IERC20 erc20Token = IERC20(_auction.erc20Token);
            require(
                erc20Token.allowance(msg.sender, address(this)) >=
                    _auction.buyPrice,
                "Insufficient spent allowance "
            );
            // transfer royalitiy to creator
            erc20Token.transferFrom(msg.sender, creator, royality);
            // transfer brokerage amount to broker
            erc20Token.transferFrom(msg.sender, address(this), brokerageAmount);
            // transfer remaining  amount to lastOwner
            erc20Token.transferFrom(msg.sender, lastOwner2, lastOwner_funds);
        }
        brokerageBalance[_auction.erc20Token] += brokerageAmount;

        tokenOpenForSale[_tokenDet.NFTAddress][_tokenDet.tokenID] = false;
        // _auction.buyer = true;
        // _auction.highestBidder = msg.sender;
        // _auction.currentBid = _auction.buyPrice;

        Token.safeTransferFrom(
            Token.ownerOf(_tokenDet.tokenID),
            // _auction.highestBidder,/
            msg.sender,
            _tokenDet.tokenID
        );

        // Buy event
        emit Buy(
            _tokenDet.NFTAddress,
            _tokenDet.tokenID,
            lastOwner2,
            msg.sender,
            _auction.buyPrice,
            block.timestamp,
            _auction.erc20Token
        );

        tokensForSale.removeTokenDet(_tokenDet);
        tokensForSalePerUser[lastOwner2].removeTokenDet(_tokenDet);

        fixedPriceTokens.removeTokenDet(_tokenDet);
        delete auctions[_tokenDet.NFTAddress][_tokenDet.tokenID];
    }

    function withdraw() public onlyOwner {
        msg.sender.transfer(brokerageBalance[address(0)]);
        brokerageBalance[address(0)] = 0;
    }

    function withdrawERC20(address _erc20Token) public onlyOwner {
        require(
            erc20TokensArray.exists(_erc20Token),
            "This erc20token payment not allowed"
        );
        IERC20 erc20Token = IERC20(_erc20Token);
        erc20Token.transfer(msg.sender, brokerageBalance[_erc20Token]);
        brokerageBalance[_erc20Token] = 0;
    }

    function putOnSale(
        uint256 _tokenID,
        uint256 _startingPrice,
        uint256 _auctionType,
        uint256 _buyPrice,
        uint256 _startingTime,
        uint256 _closingTime,
        address _mintableToken,
        address _erc20Token
    )
        public
        erc20Allowed(_erc20Token)
        tokenOwnerOnlly(_tokenID, _mintableToken)
    {
        IMintableToken Token = IMintableToken(_mintableToken);
        //   uint256 _ID =_tokenID;
        //   uint256 _aucType =_auctionType;
        //   uint256 _startPrice= _startingPrice;
        auction memory _auction = auctions[_mintableToken][_tokenID];

        // Allow to put on sale to already on sale NFT \
        // only if it was on auction and have 0 bids and auction is over
        if (tokenOpenForSale[_mintableToken][_tokenID] == true) {
            require(
                _auction.auctionType == 2 &&
                    _auction.buyer == false &&
                    block.timestamp > _auction.closingTime,
                "This NFT is already on sale."
            );
        }
        TokenDetArrayLib.TokenDet memory _tokenDet = TokenDetArrayLib.TokenDet(
            _mintableToken,
            _tokenID
        );
        auction memory newAuction = auction(
            msg.sender,
            _startingPrice,
            address(0),
            _auctionType,
            _startingPrice,
            _buyPrice,
            false,
            _startingTime,
            _closingTime,
            _erc20Token
        );

        require(
            Token.getApproved(_tokenDet.tokenID) == address(this),
            "Broker Not approved"
        );
        require(
            _closingTime > _startingTime,
            "Closing time should be greater than starting time!"
        );
        auctions[_tokenDet.NFTAddress][_tokenDet.tokenID] = newAuction;

        // Store data in all mappings if adding fresh token on sale
        if (
            tokenOpenForSale[_tokenDet.NFTAddress][_tokenDet.tokenID] == false
        ) {
            tokenOpenForSale[_tokenDet.NFTAddress][_tokenDet.tokenID] = true;

            tokensForSale.addTokenDet(_tokenDet);
            tokensForSalePerUser[msg.sender].addTokenDet(_tokenDet);

            // Add token to fixedPrice on Timed list
            if (_auctionType == 1) {
                fixedPriceTokens.addTokenDet(_tokenDet);
            } else if (_auctionType == 2) {
                auctionTokens.addTokenDet(_tokenDet);
            }
        }

        // OnSale event
        emit OnSale(
            _tokenDet.NFTAddress,
            _tokenDet.tokenID,
            msg.sender,
            newAuction.auctionType,
            newAuction.auctionType == 1
                ? newAuction.buyPrice
                : newAuction.startingPrice,
            block.timestamp,
            newAuction.erc20Token
        );
    }

    function updatePrice(
        uint256 tokenID,
        address _mintableToken,
        uint256 _newPrice,
        address _erc20Token
    )
        public
        onSaleOnly(tokenID, _mintableToken)
        erc20Allowed(_erc20Token)
        tokenOwnerOnlly(tokenID, _mintableToken)
    {
        // IMintableToken Token = IMintableToken(_mintableToken);
        auction memory _auction = auctions[_mintableToken][tokenID];

        if (_auction.auctionType == 2) {
            require(
                block.timestamp < _auction.closingTime,
                "Auction Time Over!"
            );
        }
        emit PriceUpdated(
            _mintableToken,
            tokenID,
            _auction.lastOwner,
            _auction.auctionType,
            _auction.auctionType == 1
                ? _auction.buyPrice
                : _auction.startingPrice,
            _newPrice,
            block.timestamp,
            _auction.erc20Token
        );
        // Update Price
        if (_auction.auctionType == 1) {
            _auction.buyPrice = _newPrice;
        } else {
            _auction.startingPrice = _newPrice;
            _auction.currentBid = _newPrice;
        }
        _auction.erc20Token = _erc20Token;
        auctions[_mintableToken][tokenID] = _auction;
    }

    function putSaleOff(uint256 tokenID, address _mintableToken)
        public
        tokenOwnerOnlly(tokenID, _mintableToken)
    {
        // IMintableToken Token = IMintableToken(_mintableToken);
        auction memory _auction = auctions[_mintableToken][tokenID];
        TokenDetArrayLib.TokenDet memory _tokenDet = TokenDetArrayLib.TokenDet(
            _mintableToken,
            tokenID
        );
        tokenOpenForSale[_mintableToken][tokenID] = false;

        // OffSale event
        emit OffSale(
            _mintableToken,
            tokenID,
            msg.sender,
            block.timestamp,
            _auction.erc20Token
        );

        tokensForSale.removeTokenDet(_tokenDet);

        tokensForSalePerUser[msg.sender].removeTokenDet(_tokenDet);
        // Remove token from list
        if (_auction.auctionType == 1) {
            fixedPriceTokens.removeTokenDet(_tokenDet);
        } else if (_auction.auctionType == 2) {
            auctionTokens.removeTokenDet(_tokenDet);
        }
        delete auctions[_mintableToken][tokenID];
    }

    function getOnSaleStatus(address _mintableToken, uint256 tokenID)
        public
        view
        returns (bool)
    {
        return tokenOpenForSale[_mintableToken][tokenID];
    }
}