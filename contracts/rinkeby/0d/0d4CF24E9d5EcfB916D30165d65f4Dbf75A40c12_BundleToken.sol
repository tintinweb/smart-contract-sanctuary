// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
//pragma abicoder v2;
//For Remix
pragma experimental ABIEncoderV2;

 import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
 import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
 import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
 import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
 import '@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol';
 import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

//For Remix
//import "https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v3.4.0/contracts/token/ERC20/SafeERC20Upgradeable.sol";
//import "https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v3.4.0/contracts/token/ERC20/IERC20Upgradeable.sol";
//import "https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v3.4.0/contracts/token/ERC1155/ERC1155Upgradeable.sol";
//import "https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v3.4.0/contracts/utils/CountersUpgradeable.sol";
//import "https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v3.4.0/contracts/proxy/Initializable.sol";

import "./IBundle.sol";
import "./Dividends.sol";
import "./Market.sol";
import "./Swap.sol";

contract BundleToken is IBundle, ERC1155Upgradeable, Market, Dividends, Swap {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    CountersUpgradeable.Counter private _bundleIds;

    address private constant _ETH_ADDRESS = address(1);
    mapping(uint256 => Bundle) private bundleMap;
    mapping(address => uint256[]) private creatorBundles;
    mapping(address => uint256[]) private ownerBundles;

    event CreateBundle(address indexed creator, uint256 bundleId);
    event PublishBonds(address indexed owner, uint256 marketId);
    event CancelSellingBonds(address indexed owner, uint256 bundleId, uint256 marketId);
    event BuyBonds(address indexed buyer, uint256 bundleId, uint256 marketId, address seller, uint256 amount);
    event PayDividends(address indexed creator, uint256 bundleId);
    event DestroyBondsByCreator(address indexed creator, uint256 bundleId);
    event DestroyBondsByOwner(address indexed creator, uint256 bundleId);

    function initialize() initializer public {
        __ERC1155_init("https://api-dev.quotient.fi/api/v1/bundles/{id}");
    }

    function createBundle(
        string memory bundleName,
        string memory profileName,
        uint256 amountOfBonds,
        address[] memory assetsList,
        uint256[] memory assetsAmount,
        address dividendCurrency,
        uint256 initialPrice,
        uint8 dividendPercentage,
        uint256 endDate,
        uint256[] memory paymentStrategy
    ) public override payable {
        require(bytes(bundleName).length > 0, "Bundle name is require");
        require(bytes(profileName).length > 0, "Profile name is require");
        require(amountOfBonds > 0, "The number of bonds must be greater than 0");
        require(assetsList.length > 0, "The number of assets for the bundle must be greater than 0");
        require(assetsAmount.length > 0, "The number of amount for the bundle must be greater than 0");
        require(assetsList.length == assetsAmount.length, "The number of assets and the amount of assets in the package must be the same");
        require(dividendCurrency != address(0), "The address of currency is invalid");
        require(initialPrice > 0, "The initial price must be greater then 0");
        require(dividendPercentage > 0 && dividendPercentage <= 100, "The percentage of dividends must be between 0 and 100");
        require(endDate > block.timestamp, "The bundle destruction date must be greater than the current date");
        require(paymentStrategy.length > 0, "The number of payment strategy must be greater than 0");
        _lockAssets(assetsList, assetsAmount);
        uint256 newBundleId = _bundleIds.current();
        Bundle storage bundle = bundleMap[newBundleId];
        bundle.id = newBundleId;
        bundle.bundleName = bundleName;
        bundle.profileName = profileName;
        bundle.totalSupply = amountOfBonds;
        bundle.creator = msg.sender;
        bundle.dividendCurrency = dividendCurrency;
        bundle.initialPrice = initialPrice;
        bundle.dividendPercentage = dividendPercentage;
        bundle.startDate = block.timestamp;
        bundle.endDate = endDate;
        _generateAssetsList(newBundleId, amountOfBonds, assetsList, assetsAmount);
        generatePaymentSchedulerList(newBundleId, paymentStrategy);
        _mint(msg.sender, newBundleId, amountOfBonds, "");
        creatorBundles[msg.sender].push(newBundleId);
        publishBonds(newBundleId, amountOfBonds, initialPrice);
        _bundleIds.increment();
        emit CreateBundle(msg.sender, newBundleId);
    }

    function publishBonds(uint256 bundleId, uint256 amount, uint256 price) public override {
        uint256 amountAvailable = balanceOf(msg.sender, bundleId) - getAmountOnMarket(bundleId, msg.sender);
        require(amountAvailable >= amount, "No available funds");
        require(checkSellable(bundleId, bundleMap[bundleId].startDate, bundleMap[bundleId].endDate), "Bond isn`t sellable");
        uint256 marketId = addToMarket(bundleId, price, amount, msg.sender);
        setApprovalForAll(address(this), true);
        emit PublishBonds(msg.sender, marketId);
    }

    function cancelSellingByOwner(uint256 marketId) public override {
        (uint256 bundleId,,, address seller) = getMarketItem(marketId);
        require(msg.sender == seller, "You cannot cancel selling bond");
        require(balanceOf(msg.sender, bundleId) > 0, "Already sold this bond");
        deleteFromMarketByOwner(marketId);
        setApprovalForAll(address(this), false);
        emit CancelSellingBonds(msg.sender, bundleId, marketId);
    }

    function payDividendsByBundle(uint256 bundleId) public override payable {
        require(msg.sender == bundleMap[bundleId].creator, "Only a bond creator can pay dividends");
        if (_isETH(bundleMap[bundleId].dividendCurrency)) {
            require(msg.value == calculateDividendsForBundle(bundleId), "Incorrectly transferred amount of ETH");
        }
        require(block.timestamp < getLastPaymentTime(bundleId) + 600, "You miss last payment and can`t pay now");
        uint256 payTime = getPaymentTime(bundleId);
        require(block.timestamp > payTime, "Can`t pay dividends before time");

        uint256 value = calculateDividendsForOneBond(bundleId, bundleMap[bundleId].dividendPercentage, bundleMap[bundleId].startDate, bundleMap[bundleId].initialPrice, bundleMap[bundleId].totalSupply);

        for (uint256 i = 0; i < bundleMap[bundleId].holders.length; i++) {
            uint valueToPay = calculateDividendsForOneHolder(bundleId, bundleMap[bundleId].holders[i], value);
            sendAssets(bundleMap[bundleId].dividendCurrency, msg.sender, bundleMap[bundleId].holders[i], valueToPay);
            address holder = bundleMap[bundleId].holders[i];
            updateHistory(bundleId, this.balanceOf(holder, bundleId), holder);
        }
        updateDividends(bundleId);
        emit PayDividends(msg.sender, bundleId);
    }

    function buyBonds(uint256 marketId, uint256 amount) public override payable {
        (uint256 bundleId, uint256 price, uint256 marketAmount, address seller) = getMarketItem(marketId);
        require(msg.sender != seller, "The seller cannot buy bond");
        require(checkSellable(bundleId, bundleMap[bundleId].startDate, bundleMap[bundleId].endDate), "Bond isn`t sellable");
        require(bundleMap[bundleId].creator != msg.sender, "The creator cannot buy bond");
        address currency = bundleMap[bundleId].dividendCurrency;
        uint256 value = (price / marketAmount) * amount;
        if (_isETH(currency)) {
            require(msg.value == value, "Incorrectly transferred amount of ETH");
        }
        sendAssets(currency, msg.sender, seller, value);
        this.safeTransferFrom(seller, msg.sender, bundleId, amount, "");
        setApprovalForAll(address(this), true);
        updateMarket(marketId, amount, value);

        if (getHistoryLength(bundleId, msg.sender) == 0) {
            ownerBundles[msg.sender].push(bundleId);
            bundleMap[bundleId].holders.push(msg.sender);
        }
        addToHistory(bundleId, balanceOf(msg.sender, bundleId));
        if (bundleMap[bundleId].creator != seller) {
            addToHistory(bundleId, balanceOf(seller, bundleId));
        }
        emit BuyBonds(msg.sender, bundleId, marketId, seller, amount);
    }

    function calculateDividendsForBundle(uint256 bundleId) public view returns (uint256 dividendsSum) {
        uint256 value = calculateDividendsForOneBond(bundleId, bundleMap[bundleId].dividendPercentage, bundleMap[bundleId].startDate, bundleMap[bundleId].initialPrice, bundleMap[bundleId].totalSupply);
        uint256 valueToPay = 0;
        for (uint256 i = 0; i < bundleMap[bundleId].holders.length; i++) {
            valueToPay += calculateDividendsForOneHolder(bundleId, bundleMap[bundleId].holders[i], value);
        }
        return valueToPay;
    }

    function destroyBondByCreator(uint256 bundleId) public override payable {
        require(msg.sender == bundleMap[bundleId].creator, "Only bond creator can destroy bond");
        require(block.timestamp > bundleMap[bundleId].endDate, "Bond has not expired yet");
        if (block.timestamp < getLastPaymentTime(bundleId) + 600) {
            require(checkLastPayment(bundleId), "You must pay dividends");
        }
        if (checkFullDestroy(bundleId)) {
            address currency = bundleMap[bundleId].dividendCurrency;
            for (uint256 i = 0; i < bundleMap[bundleId].holders.length; i++) {
                address holder = bundleMap[bundleId].holders[i];
                uint256 holderBonds = this.balanceOf(holder, bundleId);
                uint256 value = (bundleMap[bundleId].initialPrice / bundleMap[bundleId].totalSupply) * holderBonds;
                sendAssets(currency, msg.sender, holder, value);
                _burn(holder, bundleId, holderBonds);
                deleteHistory(bundleId, holder);
            }
            for (uint i = 0; i < bundleMap[bundleId].assets.length; i++) {
                address asset = bundleMap[bundleId].assets[i].assetAddress;
                uint256 amount = bundleMap[bundleId].assets[i].amount;
                sendAssets(asset, address(this), msg.sender, amount);
            }
            _burn(msg.sender, bundleId, this.balanceOf(msg.sender, bundleId));
            deletePaymentScheduler(bundleId);
        } else {
            unlockAssetsPart(bundleId, msg.sender);
            _burn(msg.sender, bundleId, this.balanceOf(msg.sender, bundleId));
        }
        emit DestroyBondsByCreator(msg.sender, bundleId);
    }

    // TODO: Function for mainnet with swap assets functionality
    //    function destroyBondByOwner(uint256 bundleId) public  payable override {
    //        uint256 holderBonds = this.balanceOf(msg.sender, bundleId);
    //        require(checkCallable(bundleId, bundleMap[bundleId].startDate, bundleMap[bundleId].endDate),"Bond without penalties");
    //        require(holderBonds > 0, "Only bond owner can destroy bond");
    //        require(calculatePenaltyDays(bundleId) >= 1 && checkLastPayment(bundleId) == false, "You can`t destroy this bond");
    //        unlockAndSwapAssetsPart(bundleId, msg.sender);
    //        _burn(msg.sender, bundleId, this.balanceOf(msg.sender, bundleId));
    //        emit DestroyBondsByCreator(msg.sender, bundleId);
    //    }

    function destroyBondByOwner(uint256 bundleId) public override {
        uint256 holderBonds = this.balanceOf(msg.sender, bundleId);
        require(checkCallable(bundleId, bundleMap[bundleId].startDate, bundleMap[bundleId].endDate), "Bond without penalties");
        require(holderBonds > 0, "Only bond owner can destroy bond");
        require(calculatePenaltyDays(bundleId) >= 1, "You can`t destroy this bond");
        unlockAssetsPart(bundleId, msg.sender);
        _burn(msg.sender, bundleId, this.balanceOf(msg.sender, bundleId));
        emit DestroyBondsByOwner(msg.sender, bundleId);
    }


    function getBundleInfoById(uint256 bundleId) public override view returns (Bundle memory bundle){
        return bundleMap[bundleId];
    }

    function getBundlesByCreator(address creator) public view returns (uint256[] memory bundles){
        return creatorBundles[creator];
    }

    function getBundlesByOwner(address owner) public view returns (uint256[] memory bundles){
        return ownerBundles[owner];
    }

    function _lockAssets(address[] memory assetsList, uint256[] memory assetsAmount) private {
        for (uint256 i = 0; i < assetsList.length; i++) {
            if (_isETH(assetsList[i])) {
                require(msg.value == assetsAmount[i], "Incorrectly transferred amount of ETH");
            } else {
                _sendERC20(assetsList[i], msg.sender, address(this), assetsAmount[i]);
            }
        }
    }

    function unlockAssetsPart(uint256 bundleId, address holder) private {
        for (uint i = 0; i < bundleMap[bundleId].assets.length; i++) {
            address asset = bundleMap[bundleId].assets[i].assetAddress;
            uint256 amount = bundleMap[bundleId].assets[i].amount;
            uint256 holderBondsPart = bundleMap[bundleId].totalSupply / this.balanceOf(holder, bundleId);
            uint256 holderAssetPart = amount / holderBondsPart;
            sendAssets(asset, address(this), holder, holderAssetPart);
        }
    }

    function unlockAndSwapAssetsPart(uint256 bundleId, address holder) private {
        for (uint i = 0; i < bundleMap[bundleId].assets.length; i++) {
            address asset = bundleMap[bundleId].assets[i].assetAddress;
            uint256 amount = bundleMap[bundleId].assets[i].amount;
            uint256 holderBondsPart = bundleMap[bundleId].totalSupply / this.balanceOf(holder, bundleId);
            uint256 holderAssetPart = amount / holderBondsPart;

            if (_isETH(bundleMap[bundleId].dividendCurrency)) {
                if (_isETH(asset)) {
                    _sendETH(holder, holderAssetPart);
                } else {
                    IERC20Upgradeable(asset).approve(UNISWAP_ROUTER_ADDRESS, holderAssetPart);
                    swapExactTokensForETH(asset, holderAssetPart, holder);
                }
            } else {
                if (_isETH(asset)) {
                    swapExactETHforTokens(holderAssetPart, bundleMap[bundleId].dividendCurrency, holder);
                } else if (asset == bundleMap[bundleId].dividendCurrency) {
                    sendAssets(asset, address(this), holder, holderAssetPart);
                } else {
                    IERC20Upgradeable(asset).approve(UNISWAP_ROUTER_ADDRESS, holderAssetPart);
                    swapExactTokensForTokens(asset, bundleMap[bundleId].dividendCurrency, holderAssetPart, holder);
                }
            }
        }
    }

    function _generateAssetsList(uint256 bundleId, uint256 amount, address[] memory assetsList, uint256[] memory assetsAmount) private {
        require(assetsList.length == assetsAmount.length, "The sizes of arrays of asset addresses and their amount must be the same");
        require(amount != 0, "The amount of bonds in bundle must be greater than 0");
        for (uint256 i = 0; i < assetsList.length; i++) {
            bundleMap[bundleId].assets.push(Asset(assetsList[i], SafeMathUpgradeable.div(assetsAmount[i], amount)));
        }
    }

    function _isETH(address _currency) private pure returns (bool){
        return _currency == _ETH_ADDRESS;
    }

    function _sendETH(address _receiver, uint256 _amount) private {
        (bool success,) = _receiver.call{value : _amount}("");
        require(success, "Contract execution Failed");
    }

    function _sendERC20(address _currency, address _sender, address _receiver, uint256 _amount) private {
        IERC20Upgradeable(_currency).safeTransferFrom(_sender, _receiver, _amount);
    }

    function sendAssets(address _currency, address _sender, address _receiver, uint256 _amount) private {
        if (_isETH(_currency)) {
            _sendETH(_receiver, _amount);
        } else {
            _sendERC20(_currency, _sender, _receiver, _amount);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC1155Upgradeable.sol";
import "./IERC1155MetadataURIUpgradeable.sol";
import "./IERC1155ReceiverUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../introspection/ERC165Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../proxy/Initializable.sol";

/**
 *
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC1155Upgradeable, IERC1155MetadataURIUpgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    // Mapping from token ID to account balances
    mapping (uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping (address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /*
     *     bytes4(keccak256('balanceOf(address,uint256)')) == 0x00fdd58e
     *     bytes4(keccak256('balanceOfBatch(address[],uint256[])')) == 0x4e1273f4
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,uint256,bytes)')) == 0xf242432a
     *     bytes4(keccak256('safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)')) == 0x2eb2c2d6
     *
     *     => 0x00fdd58e ^ 0x4e1273f4 ^ 0xa22cb465 ^
     *        0xe985e9c5 ^ 0xf242432a ^ 0x2eb2c2d6 == 0xd9b67a26
     */
    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;

    /*
     *     bytes4(keccak256('uri(uint256)')) == 0x0e89341c
     */
    bytes4 private constant _INTERFACE_ID_ERC1155_METADATA_URI = 0x0e89341c;

    /**
     * @dev See {_setURI}.
     */
    function __ERC1155_init(string memory uri_) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC1155_init_unchained(uri_);
    }

    function __ERC1155_init_unchained(string memory uri_) internal initializer {
        _setURI(uri_);

        // register the supported interfaces to conform to ERC1155 via ERC165
        _registerInterface(_INTERFACE_ID_ERC1155);

        // register the supported interfaces to conform to ERC1155MetadataURI via ERC165
        _registerInterface(_INTERFACE_ID_ERC1155_METADATA_URI);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) external view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    )
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        public
        virtual
        override
    {
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][from] = _balances[id][from].sub(amount, "ERC1155: insufficient balance for transfer");
        _balances[id][to] = _balances[id][to].add(amount);

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        public
        virtual
        override
    {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            _balances[id][from] = _balances[id][from].sub(
                amount,
                "ERC1155: insufficient balance for transfer"
            );
            _balances[id][to] = _balances[id][to].add(amount);
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(address account, uint256 id, uint256 amount, bytes memory data) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] = _balances[id][account].add(amount);
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] = amounts[i].add(_balances[ids[i]][to]);
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(address account, uint256 id, uint256 amount) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        _balances[id][account] = _balances[id][account].sub(
            amount,
            "ERC1155: burn amount exceeds balance"
        );

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(address account, uint256[] memory ids, uint256[] memory amounts) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint i = 0; i < ids.length; i++) {
            _balances[ids[i]][account] = _balances[ids[i]][account].sub(
                amounts[i],
                "ERC1155: burn amount exceeds balance"
            );
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal
        virtual
    { }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        private
    {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155ReceiverUpgradeable(to).onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        private
    {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (bytes4 response) {
                if (response != IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../math/SafeMathUpgradeable.sol";

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library CountersUpgradeable {
    using SafeMathUpgradeable for uint256;

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
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
//pragma abicoder v2;
//For Remix
pragma experimental ABIEncoderV2;

interface IBundle {

    struct Asset {
        address assetAddress;
        uint256 amount;
    }

    struct Bundle {
        uint256 id;
        string bundleName;
        string profileName;
        uint256 totalSupply;
        address creator;
        address dividendCurrency;
        Asset[] assets;
        uint256 initialPrice;
        uint8 dividendPercentage;
        uint256 startDate;
        uint256 endDate;
        address[] holders;
    }

    function createBundle(
        string memory bundleName,
        string memory profileName,
        uint256 amountOfFractions,
        address[] memory assetsList,
        uint256[] memory assetsAmount,
        address dividendCurrency,
        uint256 initialPrice,
        uint8 dividendPercentage,
        uint256 endDate,
        uint256[] memory dividendsStrategy
    ) external payable;

    function publishBonds(
        uint256 bundleId,
        uint256 amount,
        uint256 price
    ) external;

    function cancelSellingByOwner(
        uint256 marketId
    ) external;

    function payDividendsByBundle(uint256 bundleId) external payable;

    function buyBonds(uint256 marketId, uint256 amount) external payable;

    function destroyBondByCreator(uint256 bondId) external payable;

    function destroyBondByOwner(uint256 bondId) external;

    function getBundleInfoById(uint256 bundleId) external view returns (Bundle memory bundle);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
//pragma abicoder v2;
//For Remix
pragma experimental ABIEncoderV2;

import "./IDividends.sol";

contract Dividends is IDividends {
    mapping(uint256 => PaymentCounter) paymentCounterList;
    mapping(uint256 => mapping(uint256 => PaymentData)) paymentScheduler;
    mapping(uint256 => mapping(address => OwnerHistory[])) historyForPayment;

    function generatePaymentSchedulerList(uint256 bundleId, uint256[] memory paymentList) internal {
        for (uint256 i = 0; i < paymentList.length; i++) {
            paymentScheduler[bundleId][i] = PaymentData(paymentList[i], 0, false);
            paymentCounterList[bundleId] = PaymentCounter(0, paymentList.length - 1);
        }
    }

    function addToHistory(uint256 bundleId, uint256 amount) internal {
        historyForPayment[bundleId][msg.sender].push(OwnerHistory(block.timestamp, amount));
    }

    function updateHistory(uint256 bundleId, uint256 amount, address holder) internal {
        delete historyForPayment[bundleId][holder];
        historyForPayment[bundleId][holder].push(OwnerHistory(getPaymentTime(bundleId), amount));
    }

    function getAllPayments(uint256 bundleId) public view returns (PaymentData[] memory allPayments){
        uint256 length = paymentCounterList[bundleId].lastPaymentNumber + 1;
        PaymentData[] memory payments = new PaymentData[](length);
        for (uint256 i = 0; i < length; i++) {
            payments[i] = paymentScheduler[bundleId][i];
        }
        return payments;
    }

    function deleteHistory(uint256 bundleId, address holder) internal {
        delete historyForPayment[bundleId][holder];
    }

    function deletePaymentScheduler(uint256 bundleId) internal {
        for (uint256 i = 0; i < paymentCounterList[bundleId].lastPaymentNumber; i++) {
            delete paymentScheduler[bundleId][i];
        }
        delete paymentCounterList[bundleId];
    }

    function checkPayment(uint256 bundleId) internal view returns (bool status){
        return paymentScheduler[bundleId][paymentCounterList[bundleId].paymentsNumber].status;
    }

    function checkLastPayment(uint256 bundleId) public view returns (bool status){
        return paymentScheduler[bundleId][paymentCounterList[bundleId].lastPaymentNumber].status;
    }


    function checkFullDestroy(uint256 bundleId) internal view returns (bool status){
        uint256 lastPayTime = paymentScheduler[bundleId][paymentCounterList[bundleId].lastPaymentNumber].actualTime;
        return lastPayTime < getLastPaymentTime(bundleId) + 600 && checkLastPayment(bundleId);
    }

    function getHistoryLength(uint256 bundleId, address sender) public view returns (uint256 length){
        return historyForPayment[bundleId][sender].length;
    }

    function updateDividends(uint256 bundleId) internal {
        paymentScheduler[bundleId][paymentCounterList[bundleId].paymentsNumber].status = true;
        paymentScheduler[bundleId][paymentCounterList[bundleId].paymentsNumber].actualTime = block.timestamp;
        paymentCounterList[bundleId].paymentsNumber += 1;
    }

    function getPaymentTime(uint256 bundleId) public view returns (uint256 payTime){
        return paymentScheduler[bundleId][paymentCounterList[bundleId].paymentsNumber].scheduleTime;
    }

    function getLastPaymentTime(uint256 bundleId) public view returns (uint256 payTime){
        return paymentScheduler[bundleId][paymentCounterList[bundleId].lastPaymentNumber].scheduleTime;
    }

    function calculateDividendsForOneBond(uint256 bundleId, uint256 dividendPercentage, uint256 startDate, uint256 initialPrice, uint256 totalSupply) internal view returns (uint256 valueToPay) {
        if (getPaymentTime(bundleId) + 300 < block.timestamp) {
            dividendPercentage += 2;
        }
        uint256 percents = (dividendPercentage * 100) / (paymentCounterList[bundleId].lastPaymentNumber + 1);
        uint256 paymentDays = (paymentScheduler[bundleId][0].scheduleTime - startDate) / 60;
        if (paymentCounterList[bundleId].lastPaymentNumber > 0) {
            paymentDays = (paymentScheduler[bundleId][1].scheduleTime - paymentScheduler[bundleId][0].scheduleTime) / 60;
        }
        uint256 valueForPeriod = ((initialPrice * 100) * percents) / 100;
        return (valueForPeriod / paymentDays) / totalSupply;
    }

    function calculateDividendsForOneHolder(uint256 bundleId, address holder, uint256 dividend) internal view returns (uint256 dividendsForHolder){
        uint256 sum;
        if (historyForPayment[bundleId][holder].length == 1) {
            uint256 payTime = ((paymentScheduler[bundleId][paymentCounterList[bundleId].paymentsNumber].scheduleTime - historyForPayment[bundleId][holder][0].time) / 60);
            sum += (historyForPayment[bundleId][holder][0].amount * dividend) * payTime;
        } else {
            for (uint256 i = 0; i < historyForPayment[bundleId][holder].length - 1; i++) {
                uint time = (historyForPayment[bundleId][holder][i + 1].time - historyForPayment[bundleId][holder][i].time) / 60;
                sum += (historyForPayment[bundleId][holder][i].amount * dividend) * time;
                if (i == historyForPayment[bundleId][holder].length - 2) {
                    time = ((paymentScheduler[bundleId][paymentCounterList[bundleId].paymentsNumber].scheduleTime - historyForPayment[bundleId][holder][i + 1].time) / 60);
                    sum += (historyForPayment[bundleId][holder][i + 1].amount * dividend) * time;
                }
            }
        }
        return sum / 10000;
    }

    function calculatePenaltyDays(uint256 bundleId) public view returns (uint256 penaltyDays){
        if (block.timestamp > paymentScheduler[bundleId][paymentCounterList[bundleId].paymentsNumber].scheduleTime) {
            return ((block.timestamp - paymentScheduler[bundleId][paymentCounterList[bundleId].paymentsNumber].scheduleTime) / 60);
        }
        return 0;
    }

    function calculatePenaltyPayments(uint256 bundleId) public view returns (uint256 penaltyPaymentsNum){
        uint256 penaltyPayments;
        for (uint256 i = paymentCounterList[bundleId].paymentsNumber; i <= paymentCounterList[bundleId].lastPaymentNumber; i++) {
            if (paymentScheduler[bundleId][i].scheduleTime < block.timestamp) {
                penaltyPayments += 1;
            }
        }
        return penaltyPayments;
    }


    function checkSellable(uint256 bundleId, uint256 start, uint256 end) public view returns (bool isSellable){
        uint256 bondLifeTime = (end - start) / 60;
        if (bondLifeTime > 365) {
            return calculatePenaltyPayments(bundleId) < 2;
        }
        return calculatePenaltyPayments(bundleId) < 1;
    }

    function checkCallable(uint256 bundleId, uint256 start, uint256 end) public view returns (bool isCallable){
        uint256 bondLifeTime = (end - start) / 60;
        if (end + 60 < block.timestamp && !checkLastPayment(bundleId)){
            return true;
        }
        if (bondLifeTime > 365) {
            return calculatePenaltyDays(bundleId) > 42;
        } else if (92 < bondLifeTime && bondLifeTime <= 365) {
            return calculatePenaltyPayments(bundleId) >= 4;
        } else if (31 < bondLifeTime && bondLifeTime <= 92) {
            return calculatePenaltyPayments(bundleId) >= 3;
        }
        return false;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
//pragma abicoder v2;
//For Remix
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol';
import './IMarket.sol';

//For Remix
// import "https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v3.4.0/contracts/utils/CountersUpgradeable.sol";

contract Market is IMarket {
  using CountersUpgradeable for CountersUpgradeable.Counter;
  CountersUpgradeable.Counter private _marketIds;
  MarketItem[] market;

  function addToMarket(
    uint256 bundleId,
    uint256 price,
    uint256 amount,
    address owner
  ) internal returns (uint256 marketId) {
    uint256 newMarketId = _marketIds.current();
    market.push(MarketItem(newMarketId, bundleId, price, amount, owner));
    _marketIds.increment();
    return newMarketId;
  }

  function getMarket() public view returns (MarketItem[] memory allMarket) {
    return market;
  }

  function getAmountOnMarket(uint256 bundleId, address seller)
    public
    view
    returns (uint256 amountOnMarket)
  {
    uint256 amount;

    for (uint256 i = 0; i < market.length; i++) {
      if (market[i].bundleId == bundleId && market[i].owner == seller) {
        amount += market[i].amount;
      }
    }
    return amount;
  }

  function getMarketItem(uint256 marketId)
    public
    view
    returns (
      uint256 bundleId,
      uint256 price,
      uint256 amount,
      address seller
    )
  {
    return (
      market[marketId].bundleId,
      market[marketId].price,
      market[marketId].amount,
      market[marketId].owner
    );
  }

  function deleteFromMarketByOwner(uint256 marketId) internal {
    require(
      market[marketId].owner == msg.sender,
      'Only owner can cancel selling'
    );
    market[marketId].amount = 0;
  }

  function deleteFromMarket(uint256 marketId) internal {
    market[marketId].amount = 0;
  }

  function updateMarket(
    uint256 marketId,
    uint256 amount,
    uint256 soldValue
  ) internal {
    market[marketId].amount -= amount;
    market[marketId].price -= soldValue;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

import './IUniswapV2Router02.sol';
import '@openzeppelin/contracts-upgradeable/proxy/Initializable.sol';

contract Swap is Initializable {
  // Smart contract addresses at Ropsten
  address internal constant UNISWAP_ROUTER_ADDRESS =
    0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  IUniswapV2Router02 uniswap;

  function __SWAP_init() public initializer {
    uniswap = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);
  }

  // Swaps an exact amount of input tokens for as many output tokens as possible, along the route determined by the path
  function swapExactTokensForTokens(
    address tokenIn,
    address tokenOut,
    uint256 amountIn,
    address holder
  ) internal {
    uint256 deadline = block.timestamp + 30;
    address[] memory path = new address[](2);
    path[0] = tokenIn;
    path[1] = tokenOut;

    uint256[] memory amountOutMin = uniswap.getAmountsOut(amountIn, path);
    uniswap.swapExactTokensForTokens(
      amountIn,
      amountOutMin[0],
      path,
      holder,
      deadline
    );
  }

  // Swaps an exact amount of ETH for as many output tokens as possible, along the route determined by the path
  function swapExactETHforTokens(
    uint256 amountIn,
    address tokenOut,
    address holder
  ) internal {
    uint256 deadline = block.timestamp + 30;
    address[] memory path = new address[](2);
    path[0] = uniswap.WETH();
    path[1] = tokenOut;

    uint256[] memory amountOut = uniswap.getAmountsOut(amountIn, path);

    uniswap.swapExactETHForTokens{value: amountIn}(
      amountOut[0],
      path,
      holder,
      deadline
    );
  }

  // Swaps an exact amount of tokens for as much ETH as possible, along the route determined by the path
  function swapExactTokensForETH(
    address tokenIn,
    uint256 amountIn,
    address holder
  ) internal {
    uint256 deadline = block.timestamp + 30;
    address[] memory path = new address[](2);
    path[0] = tokenIn;
    path[1] = uniswap.WETH();

    uint256[] memory amountOutMin = uniswap.getAmountsOut(amountIn, path);
    uniswap.swapExactTokensForETH(
      amountIn,
      amountOutMin[0],
      path,
      holder,
      deadline
    );
  }

  // important to receive ETH
  receive() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC1155Upgradeable.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../introspection/IERC165Upgradeable.sol";

/**
 * _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC165Upgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
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

pragma solidity >=0.6.0 <0.8.0;

interface IDividends {

    struct OwnerHistory {
        uint256 time;
        uint256 amount;
    }


    struct PaymentData {
        uint256 scheduleTime;
        uint256 actualTime;
        bool status;
    }

    struct PaymentCounter {
        uint256 paymentsNumber;
        uint256 lastPaymentNumber;
    }

    //    function calculateDividendsByBundle(uint256 bundleId, uint256 dividendPercentage, uint256 startDate, uint256 initialPrice, uint256 totalSupply) internal view returns (uint256 valueToPay);
    //    function addToHistory(uint256 bundleId, uint256 amount) external;
    //    function updateHistory(uint256 bundleId, uint256 amount, address holder) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface IMarket {

    struct MarketItem {
        uint256 marketId;
        uint256 bundleId;
        uint256 price;
        uint256 amount;
        address owner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

interface IUniswapV2Router02 {
    // From uniswap-v2-periphery/contracts/UniswapV2Router02.sol

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);

    // From uniswap-v2-periphery/contracts/interfaces/IUniswapV2Router01.sol
    // Returns the address of wrapped ether
    function WETH() external pure returns (address);
}

