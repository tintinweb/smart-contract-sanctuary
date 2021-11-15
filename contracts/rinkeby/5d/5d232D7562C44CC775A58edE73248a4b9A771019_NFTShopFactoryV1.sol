// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interfaces/INFTShopFactoryV1.sol";
import "./FundManager.sol";
import "./FungibleToken.sol";
import "./NFTShopV1.sol";

/**
 * @dev Implementation of the {INFTShopFactoryV1} interface.
 * @author Ahmed Ali Bhatti <github.com/ahmedali8>
 *
 * Note: Deployer will be the {owner} and {wallet}
 */
contract NFTShopFactoryV1 is INFTShopFactoryV1, Ownable, FundManager {
    using Counters for Counters.Counter;
    using Address for address;

    // tokenId tracker using lib
    Counters.Counter private _shopIdTracker;

    /**
     * @dev See {INFTShopFactoryV1-totalShops}.
     */
    uint256 public override totalShops;

    /**
     * @dev See {INFTShopFactoryV1-shopFee}.
     */
    uint256 public override shopFee;

    /**
     * @dev See {INFTShopFactoryV1-shops}.
     *
     * unique id -> shop struct
     */
    mapping(uint256 => Shop) public override shops;

    /**
     * @dev See {INFTShopFactoryV1-ownerShops}.
     *
     * Note that in V1 one address can have one shop
     * shop owner -> unique id
     */
    mapping(address => uint256) public override ownerShops;

    /**
     * @dev Sets the values for {shopFee} and {FundManager-constructor}.
     *
     * {shopFee} changes with {setShopFee}.
     */
    constructor(address _dev, uint256 _shopFee)
        FundManager(msg.sender, _dev, address(this))
    {
        shopFee = _shopFee;
    }

    /**
     * @dev See {INFTShopFactoryV1-shopExists}.
     *
     * Requirements:
     *
     * - `_id` cannot be the zero.
     */
    function shopExists(uint256 _id) public view override returns (bool) {
        require(_id != 0, "id must be non-zero");
        return shops[_id].nftAddr != address(0);
    }

    /**
     * @dev See {INFTShopFactoryV1-shopOwner}.
     *
     * Requirements:
     *
     * - shop with `_id` must exist.
     */
    function shopOwner(uint256 _id) public view override returns (address) {
        require(shopExists(_id), "shop doesnot exist");
        return shops[_id].owner;
    }

    /**
     * @dev See {INFTShopFactoryV1-shopAddress}.
     *
     * Requirements:
     *
     * - shop with `_id` must exist.
     */
    function shopAddress(uint256 _id)
        public
        view
        override
        returns (address payable)
    {
        require(shopExists(_id), "shop doesnot exist");
        return payable(shops[_id].nftAddr);
    }

    /**
     * @dev See {INFTShopFactoryV1-shopURI}.
     *
     * Requirements:
     *
     * - shop with `_id` must exist.
     */
    function shopURI(uint256 _id) public view override returns (string memory) {
        require(shopExists(_id), "shop doesnot exist");
        return _concatURI(shops[_id].uri);
    }

    /**
     * @dev See {INFTShopFactoryV1-ownerShopExists}.
     */
    function ownerShopExists(address _shopOwner)
        public
        view
        override
        returns (bool)
    {
        return ownerShops[_shopOwner] != 0;
    }

    /**
     * @dev See {INFTShopFactoryV1-createSimpleShop}.
     */
    function createSimpleShop(
        string calldata _shopName,
        string calldata _shopSymbol,
        string calldata _shopUri
    ) external payable override {
        _createShop(
            true,
            msg.value,
            address(0),
            0,
            "",
            "",
            _shopName,
            _shopSymbol,
            _shopUri
        );
    }

    /**
     * @dev See {INFTShopFactoryV1-createShopWithToken}.
     *
     * Requirements:
     *
     * - `_ftAddr` address must be valid.
     */
    function createShopWithToken(
        address _ftAddr,
        string calldata _shopName,
        string calldata _shopSymbol,
        string calldata _shopUri
    ) external payable override {
        require(_ftAddr.isContract(), "address not valid");

        _createShop(
            false,
            msg.value,
            _ftAddr,
            0,
            "",
            "",
            _shopName,
            _shopSymbol,
            _shopUri
        );
    }

    /**
     * @dev See {INFTShopFactoryV1-createShopAndToken}.
     *
     * Requirements:
     *
     * - `_ftSupply` cannot be zero.
     */
    function createShopAndToken(
        uint256 _ftSupply,
        string calldata _ftName,
        string calldata _ftSymbol,
        string calldata _shopName,
        string calldata _shopSymbol,
        string calldata _shopUri
    ) external payable override {
        require(_ftSupply != 0, "invalid supply");

        _createShop(
            false,
            msg.value,
            address(0),
            _ftSupply,
            _ftName,
            _ftSymbol,
            _shopName,
            _shopSymbol,
            _shopUri
        );
    }

    /**
     * @dev See {INFTShopFactoryV1-deleteShop}.
     *
     * Emits a {ShopDeleted} event indicating the shop with `_id` has been deleted.
     *
     * Requirements:
     *
     * - shop with `_id` must exist.
     * - caller must be {wallet} or {owner}.
     * - caller must execute {INFTShopV1-destructShop} for shop destruction.
     *
     */
    function deleteShop(uint256 _id) public override onlyOwner {
        require(shopExists(_id), "shop doesnot exist");
        address _owner = shopOwner(_id);
        address payable _addr = shopAddress(_id);

        // update state
        delete shops[_id];
        delete ownerShops[_owner];
        totalShops = totalShops - 1;

        emit ShopDeleted(_owner, _addr, _id);
    }

    /**
     * @dev See {INFTShopFactoryV1-setShopFee}.
     *
     * Emits a {FeeChanged} event indicating the new {shopFee}.
     *
     * Requirements:
     *
     * - caller must be {wallet} or {owner}.
     *
     */
    function setShopFee(uint256 _fee) public override onlyOwner {
        uint256 _prevFee = shopFee;
        shopFee = _fee;
        emit FeeChanged(_prevFee, _fee);
    }

    /**
     * @dev See {Ownable-transferOwnership}.
     *
     * Changes {wallet} to `_newOwner`.
     *
     * Requirements:
     *
     * - caller must be {wallet} or {owner}.
     *
     */
    function transferOwnership(address _newOwner) public override onlyOwner {
        wallet = _newOwner;
        super.transferOwnership(_newOwner);
    }

    /**
     * @dev Creates new shop with unique shopId.
     *
     * Emits a {ShopCreated} event indicating the creation of shop.
     *
     * Requirements:
     *
     * - `_fee` must be equal to {shopFee}.
     * - caller cannot already have a shop.
     * - `_ftAddr` must be zero for simpleshop.
     */
    function _createShop(
        bool _nativePayment,
        uint256 _fee,
        address _ftAddr,
        uint256 _ftSupply,
        string memory _ftName,
        string memory _ftSymbol,
        string memory _shopName,
        string memory _shopSymbol,
        string memory _shopUri
    ) internal {
        require(_fee == shopFee, "shop creation fee not valid");
        require(!ownerShopExists(_msgSender()), "caller already has a shop");
        if (_nativePayment) {
            require(_ftAddr == address(0), "ft address must be zero");
        }

        // to ensure id not equal zero
        _shopIdTracker.increment();
        uint256 _shopId = _shopIdTracker.current();

        // create a new fungible token if none given
        if (!_nativePayment && _ftAddr == address(0)) {
            _ftAddr = _deployFungibleToken(
                _msgSender(),
                _ftSupply,
                _shopId,
                _ftName,
                _ftSymbol
            );
        }

        address _nftAddr = _deployShop(
            _msgSender(),
            _ftAddr,
            _shopId,
            _shopName,
            _shopSymbol
        );

        // update state
        shops[_shopId] = Shop({
            owner: _msgSender(),
            nftAddr: _nftAddr,
            ftAddr: _ftAddr,
            uri: _shopUri
        });
        ownerShops[_msgSender()] = _shopId;
        totalShops = totalShops + 1;

        // transfer fees
        _transferFees(address(this), _fee, address(0));

        // emit event
        emit ShopCreated(
            _msgSender(),
            _ftAddr,
            _nftAddr,
            _shopId,
            _fee,
            _shopUri
        );
    }

    /**
     * @dev Returns URI concatenated with baseURI.
     *
     * Requirements:
     *
     * - `_URI length` cannot be zero.
     */
    function _concatURI(string memory _URI)
        internal
        pure
        returns (string memory)
    {
        return
            (bytes(_URI).length > 0)
                ? string(abi.encodePacked("https://ipfs.io/ipfs/", _URI))
                : "";
    }

    /**
     * @dev Deploys FungibleToken contract.
     */
    function _deployFungibleToken(
        address _beneficiary,
        uint256 _ftSupply,
        uint256 _shopId,
        string memory _ftName,
        string memory _ftSymbol
    ) internal returns (address _addr) {
        bytes memory _bytecode = type(FungibleToken).creationCode;
        _bytecode = abi.encodePacked(
            _bytecode,
            abi.encode(_ftName, _ftSymbol, _ftSupply, _beneficiary)
        );

        return _deploy(_bytecode, _createSalt(_beneficiary, _shopId));
    }

    /**
     * @dev Deploys NFTShopV1 contract.
     */
    function _deployShop(
        address _caller,
        address _ftAddr,
        uint256 _shopId,
        string memory _shopName,
        string memory _shopSymbol
    ) internal returns (address _addr) {
        bytes memory _bytecode = type(NFTShopV1).creationCode;
        _bytecode = abi.encodePacked(
            _bytecode,
            abi.encode(_ftAddr, wallet, dev, _caller, _shopName, _shopSymbol)
        );

        _addr = _deploy(_bytecode, _createSalt(_caller, _shopId));
    }

    /**
     * @dev Creates salt for deploying through `create2`.
     */
    function _createSalt(address _caller, uint256 _shopId)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_caller, _shopId));
    }

    /**
     * @dev Deploys contract using `_bytecode` and `_salt`.
     */
    function _deploy(bytes memory _bytecode, bytes32 _salt)
        private
        returns (address _addr)
    {
        assembly {
            _addr := create2(0, add(_bytecode, 32), mload(_bytecode), _salt)

            if iszero(extcodesize(_addr)) {
                revert(0, 0)
            }
        }
    }
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @dev Interface of the NFTShopFactoryV1.
 * @author Ahmed Ali Bhatti <github.com/ahmedali8>
 *
 * Note: Deployer will be the {owner} and {wallet}
 */
interface INFTShopFactoryV1 {
    /**
     * @dev Shop custom datatype.
     *
     * `owner` - owner of the shop.
     * `nftAddr` - address of shop.
     * `ftAddr` - address of ERC20/BEP20 token and zero address if ether/bnb is
     * choosen as the payment method.
     * `uri` - URL of the metadata of shop.
     */
    struct Shop {
        address owner;
        address nftAddr;
        address ftAddr;
        string uri;
    }

    /**
     * @dev Emitted when shop is created using `createSimpleShop`
     *  or `createShopWithToken` or `createShopAndToken`.
     */
    event ShopCreated(
        address indexed owner,
        address ftAddr,
        address indexed shopAddr,
        uint256 indexed id,
        uint256 fee,
        string uri
    );

    /**
     * @dev Emitted when any shop is deleted.
     */
    event ShopDeleted(
        address indexed owner,
        address indexed addr,
        uint256 indexed id
    );

    /**
     * @dev Emitted when {shopFee} is changed to `newFee`.
     */
    event FeeChanged(uint256 oldFee, uint256 newFee);

    /**
     * @dev Returns the total number of shops in factory.
     */
    function totalShops() external view returns (uint256);

    /**
     * @dev Returns the fee for creation of shop.
     *
     * This value changes when {setShopFee} is called.
     *
     */
    function shopFee() external view returns (uint256);

    /**
     * @dev Returns the values of {Shop} from mapping.
     */
    function shops(uint256 _id)
        external
        view
        returns (
            address,
            address,
            address,
            string memory
        );

    /**
     * @dev Returns the `shopId` of the shop owner owns from mapping.
     */
    function ownerShops(address _shopOwner) external view returns (uint256);

    /**
     * @dev Returns a boolean value if `shopId` exists.
     */
    function shopExists(uint256 _id) external view returns (bool);

    /**
     * @dev Returns the address of shop owner of `shopId`.
     */
    function shopOwner(uint256 _id) external view returns (address);

    /**
     * @dev Returns the payable address of `shopId`.
     */
    function shopAddress(uint256 _id) external view returns (address payable);

    /**
     * @dev Returns the `URI` of `shopId`.
     */
    function shopURI(uint256 _id) external view returns (string calldata);

    /**
     * @dev Returns a boolean value if shop owner owns any shop.
     */
    function ownerShopExists(address _shopOwner) external view returns (bool);

    /**
     * @dev Creates a simple shop with payment method as ether/bnb.
     *
     * Emits a {ShopCreated} event.
     */
    function createSimpleShop(
        string calldata _shopName,
        string calldata _shopSymbol,
        string calldata _shopUri
    ) external payable;

    /**
     * @dev Creates a shop with payment method as already deployed fungible token.
     *
     * Emits a {ShopCreated} event.
     */
    function createShopWithToken(
        address _ftAddr,
        string calldata _shopName,
        string calldata _shopSymbol,
        string calldata _shopUri
    ) external payable;

    /**
     * @dev Creates a shop with payment method as newly deployed fungible token.
     *
     * Emits a {ShopCreated} event.
     */
    function createShopAndToken(
        uint256 _ftSupply,
        string calldata _ftName,
        string calldata _ftSymbol,
        string calldata _shopName,
        string calldata _shopSymbol,
        string calldata _shopUri
    ) external payable;

    /**
     * @dev Deletes a shop with shopId `_id`
     *
     * Note:
     *
     * - caller must be {wallet} or {owner}.
     * - caller must execute {INFTShopV1-destructShop} for shop destruction.
     *
     * Emits a {ShopDeleted} event.
     */
    function deleteShop(uint256 _id) external;

    /**
     * @dev Sets `_fee` as the new `shopFee`.
     *
     * Note that caller must be {wallet} or {owner}.
     *
     * Emits a {FeeChanged} event.
     */
    function setShopFee(uint256 _fee) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IFundManager.sol";

/**
 * @dev Implementation of the {IFundManager} interface.
 * @author Ahmed Ali Bhatti <github.com/ahmedali8>
 */
contract FundManager is IFundManager, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address;

    /**
     * @dev See {IFundManager-feePercent}.
     *
     * Note that it is `4%` by default.
     */
    uint256 public override feePercent = 4 * 10**18;

    /**
     * @dev See {IFundManager-factory}.
     */
    address public override factory;

    /**
     * @dev See {IFundManager-wallet}.
     */
    address public override wallet;

    /**
     * @dev See {IERC20-dev}.
     */
    address public override dev;

    /**
     * @dev Modifier for `caller` must be {wallet}.
     */
    modifier onlyWallet() {
        require(msg.sender == wallet, "caller is not wallet");
        _;
    }

    /**
     * @dev Modifier for `caller` must be an Externally Owned Account.
     */
    modifier onlyEOA() {
        require(!(msg.sender.isContract()), "caller must be EOA");
        _;
    }

    /**
     * @dev Sets the values for {wallet}, {dev} and {factory}.
     *
     * {dev} and {factory} are immutable: they can only be set once during
     * construction.
     * {wallet} changes with {transferOwnership}.
     */
    constructor(
        address _wallet,
        address _dev,
        address _factory
    ) {
        wallet = _wallet;
        dev = _dev;
        factory = _factory;
    }

    /**
     * @dev Transfers any `ether/bnb` to {wallet} and {dev} proportionally.
     */
    receive() external payable {
        _transferFees(msg.sender, msg.value, address(0));
    }

    /**
     * @dev See {IFundManager-setFeePercent}.
     *
     * Requirements:
     *
     * - caller must be {wallet}.
     */
    function setFeePercent(uint256 _newFeePercent) public override onlyWallet {
        uint256 _prevFeePer = feePercent;
        feePercent = _newFeePercent;
        emit FeePercentChanged(_prevFeePer, _newFeePercent);
    }

    /**
     * @dev Distributes `fee` to {wallet} and {dev} while `remain` to `_to`.
     */
    function _distributeFunds(
        address _from,
        address _to,
        uint256 _amount,
        address _ftAddr
    ) internal virtual {
        uint256 _fee = (feePercent * _amount) / 1e20;
        uint256 _remain = _amount - _fee;

        // transfer `remain` amount to `_to`
        _transferFunds(_from, _to, _remain, _ftAddr);

        // transfer `fees` to `wallet` and `dev`
        _transferFees(_from, _fee, _ftAddr);
    }

    /**
     * @dev Transfer `fee` to {wallet} and {dev} a/c to respective percentages.
     *
     * Note:
     * - `96%` share of `fee` goes to {wallet}.
     * - `4%` goes of `fee` to {dev}.
     */
    function _transferFees(
        address _from,
        uint256 _amount,
        address _ftAddr
    ) internal virtual {
        _transferFunds(_from, wallet, (_amount * 96) / 100, _ftAddr);
        _transferFunds(_from, dev, (_amount * 4) / 100, _ftAddr);
    }

    /**
     * @dev Transfers `_amount` from `_from` to `_to`.
     *
     * Emits {FundsTransferred} events.
     *
     * Requirements:
     *
     * - `_from` and `_to` cannot be the zero address.
     * - `_from` must have a balance of at least `_amount`.
     */
    function _transferFunds(
        address _from,
        address _to,
        uint256 _amount,
        address _ftAddr
    ) internal virtual nonReentrant onlyEOA {
        if (_ftAddr != address(0)) {
            IERC20(_ftAddr).safeTransferFrom(_from, _to, _amount);
        } else {
            (bool success, ) = payable(_to).call{value: _amount}("");
            require(success, "transfer failed");
        }

        emit FundsTransferred(_to, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @dev Implementation of the {ERC20} contract.
 * @author Ahmed Ali Bhatti <github.com/ahmedali8>
 */
contract FungibleToken is ERC20 {
    /**
     * @dev Sets the values for {name} and {symbol}
     *
     * Note that it mints `_totalSupply` amount of tokens to `_beneficiary`
     * once during construction.
     *
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply,
        address _beneficiary
    ) ERC20(_name, _symbol) {
        _mint(_beneficiary, _totalSupply);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./interfaces/INFTShopV1.sol";
import "./FundManager.sol";

/**
 * @dev Implementation of the {INFTShopV1} interface.
 * @author Ahmed Ali Bhatti <github.com/ahmedali8>
 */
contract NFTShopV1 is INFTShopV1, ERC721URIStorage, FundManager {
    using Counters for Counters.Counter;

    // tokenId tracker using lib
    Counters.Counter private _tokenIdTracker;

    /**
     * @dev See {INFTShopV1-ftAddr}.
     */
    address public override ftAddr;

    /**
     * @dev See {INFTShopV1-shopOwner}.
     */
    address public override shopOwner;

    /**
     * @dev See {INFTShopV1-allowed}.
     */
    bool public override allowed = true;

    /**
     * @dev See {INFTShopV1-tokenPrices}.
     *
     * nft id -> price
     */
    mapping(uint256 => uint256) public override tokenPrices;

    /**
     * @dev See {INFTShopV1-nftsOnSale}.
     *
     * nft -> bool
     */
    mapping(uint256 => bool) public override nftsOnSale;

    /**
     * @dev Modifier for shop must be allowed.
     */
    modifier isAllowed() {
        require(allowed == true, "shop is disabled");
        _;
    }

    /**
     * @dev Modifier for `caller` must be {shopOwner}.
     */
    modifier onlyShopOwner() {
        require(shopOwner == _msgSender(), "caller is not shop owner");
        _;
    }

    /**
     * @dev Sets the values for {shopOwner}, {ftAddr}, {ERC721-constructor}
     * and {FundManager-constructor}.
     */
    constructor(
        address _ftAddr,
        address _wallet,
        address _dev,
        address _shopOwner,
        string memory name,
        string memory symbol
    ) ERC721(name, symbol) FundManager(_wallet, _dev, msg.sender) {
        shopOwner = _shopOwner;
        ftAddr = _ftAddr;
    }

    /**
     * @dev See {INFTShopV1-totalNFTs}.
     */
    function totalNFTs() public view override returns (uint256) {
        return _tokenIdTracker.current();
    }

    /**
     * @dev See {INFTShopV1-buyNFT}.
     *
     * Requirements:
     *
     * - `_ftAddr` must be zero address.
     * - caller must provide ether/bnb equal to price of NFT.
     * - shop must be allowed.
     */
    function buyNFT(uint256 _tokenId) public payable override {
        require(ftAddr == address(0), "payment method is token");
        _buyNFT(_tokenId, msg.value);
    }

    /**
     * @dev See {INFTShopV1-buyNFTWithToken}.
     *
     * Requirements:
     *
     * - `_ftAddr` cannot be zero address.
     * - caller must {IERC20-approve} shop to spend tokens equal to price of NFT.
     * - shop must be allowed.
     */
    function buyNFTWithToken(uint256 _tokenId, uint256 _tokenPrice)
        public
        override
    {
        require(ftAddr != address(0), "payment method is not token");
        _buyNFT(_tokenId, _tokenPrice);
    }

    /**
     * @dev See {INFTShopV1-createNFT}.
     *
     * Emits a {NFTCreated} event indicating the creation of a new NFT.
     *
     * Requirements:
     *
     * - `_price` cannot be zero.
     * - caller must be {shopOwner}.
     * - shop must be allowed.
     */
    function createNFT(uint256 _price, string memory _tokenURI)
        public
        override
        isAllowed
        onlyShopOwner
    {
        require(_price != 0, "price not valid");
        // incrementing tokenId first
        _tokenIdTracker.increment();
        uint256 _tokenId = _tokenIdTracker.current();

        // mint nft
        _safeMint(_msgSender(), _tokenId);

        // set tokenURI
        _setTokenURI(_tokenId, _tokenURI);

        // set price
        tokenPrices[_tokenId] = _price;

        // set onsale to true
        nftsOnSale[_tokenId] = true;

        // emit event
        emit NFTCreated(_msgSender(), _tokenId, _price, _tokenURI);
    }

    /**
     * @dev See {INFTShopV1-toggleShop}.
     *
     * Emits a {ShopToggled} event indicating the shop is allowed or disabled.
     *
     * Requirements:
     *
     * - caller must be {wallet}.
     *
     */
    function toggleShop() public override onlyWallet {
        allowed = !allowed;
        emit ShopToggled(address(this), allowed);
    }

    /**
     * @dev See {INFTShopV1-destructShop}.
     *
     * Emits a {ShopDestruct} event indicating the destruction of shop.
     *
     * Requirements:
     *
     * - caller must be {wallet}.
     * - caller must execute {INFTShopFactoryV1-deleteShop} for shop deletion.
     *
     */
    function destructShop() public override onlyWallet {
        emit ShopDestruct(address(this));
        selfdestruct(payable(wallet));
    }

    /**
     * @dev Buy `_tokenId` NFT with `_tokenPrice`.
     *
     * Emits a {NFTPurchase} event indicating the purchase of NFT.
     *
     * Requirements:
     *
     * - `_tokenId` must exist.
     * - valid `_tokenPrice` must be given for purchase.
     * - caller cannot be previous owner or {shopOwner}.
     * - shop must be allowed.
     * - NFT must be on sale.
     */
    function _buyNFT(uint256 _tokenId, uint256 _tokenPrice) internal isAllowed {
        require(_tokenId != 0 && _exists(_tokenId), "tokenId not valid");

        address prevOwner = ownerOf(_tokenId);
        uint256 _price = tokenPrices[_tokenId];
        address _ftAddr = ftAddr;

        require(
            _msgSender() != shopOwner && _msgSender() != prevOwner,
            "owner can't call"
        );
        require(nftsOnSale[_tokenId], "nft not on sale");
        require(_tokenPrice >= _price, "invalid price for nft");

        // delete price and onsale
        delete tokenPrices[_tokenId];
        delete nftsOnSale[_tokenId];

        // distribute funds
        _distributeFunds(_msgSender(), prevOwner, _price, _ftAddr);

        // transfer nft to new user (clears approvals too)
        _safeTransfer(prevOwner, _msgSender(), _tokenId, "");

        emit NFTPurchase(prevOwner, _msgSender(), _tokenId, _price);
    }

    /**
     * @dev See {ERC721-_baseURI}.
     */
    function _baseURI() internal pure override returns (string memory) {
        return "https://ipfs.io/ipfs/";
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
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

    constructor() {
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @dev Interface of the FundManager.
 * @author Ahmed Ali Bhatti <github.com/ahmedali8>
 */
interface IFundManager {
    /**
     * @dev Emitted when `amount` ether/bnb or tokens are moved to `beneficiary`.
     */
    event FundsTransferred(address beneficiary, uint256 amount);

    /**
     * @dev Emitted when {feePercent} is changed to `newFeePercent`.
     */
    event FeePercentChanged(uint256 prevFeePercent, uint256 newFeePercent);

    /**
     * @dev Returns the fee percentage of platform.
     *
     * This value changes when {setFeePercent} is called.
     */
    function feePercent() external view returns (uint256);

    /**
     * @dev Returns the address of NFTShopFactory contract.
     */
    function factory() external view returns (address);

    /**
     * @dev Returns the address of {wallet}.
     *
     * This value changes when ownership is transferred.
     */
    function wallet() external view returns (address);

    /**
     * @dev Returns the address of {dev}.
     */
    function dev() external view returns (address);

    /**
     * @dev Sets `_newFeePercent` as the new {feePercent}.
     *
     * Note that caller must be {wallet}.
     *
     * Emits a {FeePercentChanged} event.
     */
    function setFeePercent(uint256 _newFeePercent) external;
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
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
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
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
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
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
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
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @dev Interface of the NFTShopV1.
 * @author Ahmed Ali Bhatti <github.com/ahmedali8>
 */
interface INFTShopV1 {
    /**
     * @dev Emitted when an NFT is created.
     */
    event NFTCreated(
        address indexed owner,
        uint256 tokenId,
        uint256 price,
        string tokenURI
    );

    /**
     * @dev Emitted when an NFT is purchased.
     */
    event NFTPurchase(
        address indexed prevOwner,
        address indexed newOwner,
        uint256 tokenId,
        uint256 price
    );

    /**
     * @dev Emitted when an NFT price is changed.
     */
    event NFTPriceChanged(
        uint256 indexed tokenId,
        uint256 prevPrice,
        uint256 newPrice
    );

    /**
     * @dev Emitted when shop is toggled by {wallet}.
     */
    event ShopToggled(address indexed shopAddr, bool toggle);

    /**
     * @dev Emitted when shop is destructed.
     */
    event ShopDestruct(address indexed shopAddr);

    /**
     * @dev Returns the address of token if payment method is ERC20/BEP20
     * otherwise Returns zero address for ether/bnb payment method
     */
    function ftAddr() external view returns (address);

    /**
     * @dev Returns the address of owner of shop.
     */
    function shopOwner() external view returns (address);

    /**
     * @dev Returns a boolean value for shop is allowed or not.
     */
    function allowed() external view returns (bool);

    /**
     * @dev Returns the price of NFT from mapping.
     */
    function tokenPrices(uint256 _tokenId) external view returns (uint256);

    /**
     * @dev Returns a boolean value if NFT is on sale or not from mapping.
     */
    function nftsOnSale(uint256 _tokenId) external view returns (bool);

    /**
     * @dev Returns the total number of NFTs created from shop.
     */
    function totalNFTs() external view returns (uint256);

    /**
     * @dev Creates an NFT with `_price` and `_tokenURI`.
     *
     * Emits a {NFTCreated} event.
     */
    function createNFT(uint256 _price, string memory _tokenURI) external;

    /**
     * @dev Buys `_tokenId` NFT with ether/bnb.
     *
     * Emits a {NFTPurchase} event.
     */
    function buyNFT(uint256 _tokenId) external payable;

    /**
     * @dev Buys `_tokenId` NFT with fungible token.
     *
     * Emits a {NFTPurchase} event.
     */
    function buyNFTWithToken(uint256 _tokenId, uint256 _tokenPrice) external;

    /**
     * @dev Sets {allowed} to true or false.
     *
     * Note that caller must be `wallet`.
     *
     * Emits a {ShopToggled} event.
     */
    function toggleShop() external;

    /**
     * @dev Destroys the shop.
     *
     * Note:
     *
     * - caller must be {wallet}.
     * - caller must execute {INFTShopFactoryV1-deleteShop} for shop deletion.
     *
     * Emits a {ShopDestruct} event.
     */
    function destructShop() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

