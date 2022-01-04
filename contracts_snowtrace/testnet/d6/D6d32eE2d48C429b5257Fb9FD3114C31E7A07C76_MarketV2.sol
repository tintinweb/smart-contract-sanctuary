// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./INFT.sol";
import "./access/Ownable.sol";
import "./access/IMarketCurrencyManager.sol";
import "./lifecycle/Pausable.sol";
import "./ERC/ERC20/IBEP20.sol";
import "./access/IMarketAccessManager.sol";
import "./security/ReentrancyGuard.sol";
import "./MarketV2Storage.sol";
import "./ERC/ERC20/SafeBEP20.sol";

contract MarketV2 is Ownable, Pausable, ReentrancyGuard {
    using SafeBEP20 for IBEP20;

    uint256 public duration; //seconds

    mapping(address => bool) nfts;
    IMarketAccessManager private accessManager;
    MarketV2Storage private marketV2Storage;
    IMarketCurrencyManager private currencyManager;
    address vault;

    event Purchase(
        address indexed previousOwner,
        address indexed newOwner,
        address indexed nft,
        uint256 nftId,
        address currency,
        uint256 listingPrice,
        uint256 price,
        uint256 sellerAmount,
        uint256 commissionAmount,
        uint256 time
    );

    event Listing(
        address indexed owner,
        address indexed nft,
        uint256 indexed nftId,
        address listingUser,
        address currency,
        uint256 listingPrice,
        uint256 listingTime,
        uint256 openTime
    );

    event PriceUpdate(
        address indexed owner,
        address indexed nft,
        uint256 nftId,
        uint256 oldPrice,
        uint256 newPrice,
        uint256 time
    );

    event UnListing(address indexed owner, address indexed nft, uint256 indexed nftId, uint256 time);

    constructor(
        IMarketAccessManager _accessManager,
        MarketV2Storage _marketV2Storage,
        IMarketCurrencyManager _currencyManager,
        address _vault,
        uint256 _duration
    ) {
        require(_vault != address(0), "Error: Vault address(0)");
        require(
            address(_accessManager) != address(0),
            "Error: AccessManager address(0)"
        );
        require(
            address(_marketV2Storage) != address(0),
            "Error: MarketV2Storage address(0)"
        );

        require(
            address(_currencyManager) != address(0),
            "Error: CurrencyManager address(0)"
        );

        accessManager = _accessManager;
        marketV2Storage = _marketV2Storage;
        currencyManager = _currencyManager;
        vault = _vault;
        duration = _duration;
    }

    function setAccessManager(IMarketAccessManager _accessManager)
        external
        onlyOwner
    {
        require(
            address(_accessManager) != address(0),
            "Error: AccessManager address(0)"
        );
        accessManager = _accessManager;
    }

    function setVauld(address _vault) external onlyOwner {
        require(_vault != address(0), "Error: Vault address(0)");
        vault = _vault;
    }

    function setDuration(uint256 _duration) external onlyOwner {
        duration = _duration;
    }

    function setNFT(address[] memory _nfts, bool[] memory _isSupports) external onlyOwner {
        require(_nfts.length == _isSupports.length, "Error: invalid input");

        for (uint256 i = 0; i < _nfts.length; i++) {
            require(address(_nfts[i]) != address(0), "Error: NFT address(0)");
            nfts[_nfts[i]] = _isSupports[i];
        }
    }

    function setStorage(MarketV2Storage _marketV2Storage) external onlyOwner {
        require(
            address(_marketV2Storage) != address(0),
            "Error: MarketV2Storage address(0)"
        );
        marketV2Storage = _marketV2Storage;
    }

    function setCurrencyManager(IMarketCurrencyManager _currencyManager)
        external
        onlyOwner
    {
        require(
            address(_currencyManager) != address(0),
            "Error: CurrencyManager address(0)"
        );
        currencyManager = _currencyManager;
    }

    function getItem(address _nft, uint256 _nftId)
        public
        view
        returns (
            address,
            address,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        require(nfts[_nft], "Error: NFT not support");
        require(INFT(_nft).exists(_nftId), "Error: wrong nftId");

        address owner;
        address currency;
        uint256 price;
        uint256 listingTime;
        uint256 openTime;
        (owner, currency, price, listingTime, openTime) = marketV2Storage
            .getItem(_nft, _nftId);
        uint256 gene;
        (, , , gene, ) = INFT(_nft).get(_nftId);

        return (owner, currency, price, gene, listingTime, openTime);
    }

    function listing(
        address _nft,
        uint256 _nftId,
        address _currency,
        uint256 _price
    ) external whenNotPaused {
        require(
            accessManager.isListingAllowed(_msgSender()),
            "Not have listing permisison"
        );

        require(nfts[_nft], "Error: NFT not support");
        require(INFT(_nft).exists(_nftId), "Error: wrong nftId");
        require(
            INFT(_nft).ownerOf(_nftId) == _msgSender(),
            "Error: you are not the owner"
        );
        address owner;
        (owner, , , , ) = marketV2Storage.getItem(_nft,_nftId);
        require(owner == address(0), "Error: item listing already");

        //check currency
        bool valid;
        uint256 minAmount;
        (, minAmount, valid) = currencyManager.getCurrency(_nft, _currency);
        require(valid, "Error: Currency invalid");
        require(_price >= minAmount, "Error: price invalid");

        marketV2Storage.addItem(
            _nft,
            _nftId,
            _msgSender(),
            _currency,
            _price,
            block.timestamp,
            block.timestamp + duration
        );
        //transfer NFT for market contract
        INFT(_nft).transferFrom(_msgSender(), address(this), _nftId);
        emit Listing(
            _msgSender(),
            _nft,
            _nftId,
            _msgSender(),
            _currency,
            _price,
            block.timestamp,
            block.timestamp + duration
        );
    }

    function listingByAdmin(
        address[] memory _nfts,
        uint256[] memory _nftIds,
        address[] memory _currencies,
        uint256[] memory _prices,
        uint256[] memory _durations
    ) external whenNotPaused {
        require(
            accessManager.isListingAdminAllowed(_msgSender()),
            "Not have listing permisison"
        );

        require(_nfts.length == _nftIds.length, "Input invalid");
        require(_nftIds.length == _currencies.length, "Input invalid");
        require(_nftIds.length == _prices.length, "Input invalid");
        require(_nftIds.length == _durations.length, "Input invalid");

        for (uint256 i = 0; i < _nftIds.length; i++) {
            require(nfts[_nfts[i]], "Error: NFT not support");
            require(INFT(_nfts[i]).exists(_nftIds[i]), "Error: wrong nftId");
            require(
                INFT(_nfts[i]).ownerOf(_nftIds[i]) == _msgSender(),
                "Error: you are not the owner"
            );
            address owner;
            (owner, , , , ) = marketV2Storage.getItem(_nfts[i],_nftIds[i]);
            require(owner == address(0), "Error: item listing already");

            marketV2Storage.addItem(
                _nfts[i],
                _nftIds[i],
                _msgSender(),
                _currencies[i],
                _prices[i],
                block.timestamp,
                block.timestamp + _durations[i]
            );
            //transfer NFT for market contract
            INFT(_nfts[i]).transferFrom(
                _msgSender(),
                address(this),
                _nftIds[i]
            );
            emit Listing(
                _msgSender(),
                _nfts[i],
                _nftIds[i],
                _msgSender(),
                _currencies[i],
                _prices[i],
                block.timestamp,
                block.timestamp + _durations[i]
            );
        }
    }

    function buy(
        address _nft,
        uint256 _nftId,
        uint256 _amount
    ) external payable whenNotPaused nonReentrant {
        address owner;
        address currency;
        uint256 price;
        uint256 openTime;
        (owner, currency, price, , openTime) = marketV2Storage.getItem(_nft, _nftId);
        if (currency == address(0)) {
            _amount = msg.value;
        }
        validate(_nft, _nftId, _amount, owner, currency, price, openTime);

        address previousOwner = INFT(_nft).ownerOf(_nftId);
        address newOwner = _msgSender();

        uint256 commissionAmount;
        uint256 sellerAmount;
        (commissionAmount, sellerAmount) = trade(
            _nft,
            _nftId,
            currency,
            _amount,
            owner
        );

        emit Purchase(
            previousOwner,
            newOwner,
            _nft,
            _nftId,
            currency,
            price,
            _amount,
            sellerAmount,
            commissionAmount,
            block.timestamp
        );
    }

    function validate(
        address _nft,
        uint256 _nftId,
        uint256 _amount,
        address _owner,
        address _currency,
        uint256 _price,
        uint256 _openTime
    ) internal view {
        require(nfts[_nft], "Error: NFT not support");
        require(INFT(_nft).exists(_nftId), "Error: wrong nftId");
        require(_owner != address(0), "Item not listed currently");
        require(
            _msgSender() != INFT(_nft).ownerOf(_nftId),
            "Can not buy what you own"
        );
        require(block.timestamp >= _openTime, "Item still lock");
        if (_currency == address(0)) {
            require(msg.value >= _price, "Error: the amount is lower");
        } else {
            require(_amount >= _price, "Error: the amount is lower");
        }
    }

    function trade(
        address _nft,
        uint256 _nftId,
        address _currency,
        uint256 _amount,
        address _nftOwner
    ) internal returns (uint256, uint256) {
        address buyer = _msgSender();

        INFT(_nft).transferFrom(address(this), buyer, _nftId);

        uint256 commission;
        (commission, , ) = currencyManager.getCurrency(_nft,_currency);
        uint256 commissionAmount = (_amount * commission) / 10000;
        uint256 sellerAmount = _amount - commissionAmount;

        if (_currency == address(0)) {
            payable(_nftOwner).transfer(sellerAmount);
            payable(vault).transfer(commissionAmount);
        } else {
            IBEP20(_currency).safeTransferFrom(buyer, _nftOwner, sellerAmount);
            IBEP20(_currency).safeTransferFrom(buyer, vault, commissionAmount);

            //transfer BNB back to user if currency is not address(0)
            if (msg.value != 0) {
                payable(_msgSender()).transfer(msg.value);
            }
        }

        marketV2Storage.deleteItem(_nft, _nftId);
        return (commissionAmount, sellerAmount);
    }

    function updatePrice(
        address[]memory _nfts,
        uint256[] memory _nftIds,
        uint256[] memory _prices
    ) public whenNotPaused returns (bool) {
        require(
            accessManager.isUpdatePriceAllowed(_msgSender()),
            "Not have listing permisison"
        );

        require(_nftIds.length == _nfts.length, "Input invalid");
        require(_nftIds.length == _prices.length, "Input invalid");
        for (uint256 i = 0; i < _nftIds.length; i++) {
            require(nfts[_nfts[i]], "Error: NFT not support");

            address nftOwner;
            address currency;
            uint256 oldPrice;
            uint256 listingTime;
            uint256 openTime;
            (
                nftOwner,
                currency,
                oldPrice,
                listingTime,
                openTime
            ) = marketV2Storage.getItem(_nfts[i], _nftIds[i]);

            require(_msgSender() == nftOwner, "Error: you are not the owner");
            marketV2Storage.updateItem(
                _nfts[i],
                _nftIds[i],
                nftOwner,
                currency,
                _prices[i],
                listingTime,
                openTime
            );

            emit PriceUpdate(
                _msgSender(),
                _nfts[i],
                _nftIds[i],
                oldPrice,
                _prices[i],
                block.timestamp
            );
        }

        return true;
    }

    function unListing(address[]memory _nfts,uint256[] memory _nftIds)
        public
        whenNotPaused
        returns (bool)
    {
        require(_nfts.length==_nftIds.length,"Error: invalid input");

        for (uint256 i = 0; i < _nftIds.length; i++) {
            require(nfts[_nfts[i]], "Error: NFT not support");

            address nftOwner;
            (nftOwner, , , , ) = marketV2Storage.getItem(_nfts[i],_nftIds[i]);
            require(_msgSender() == nftOwner, "Error: you are not the owner");

            marketV2Storage.deleteItem(_nfts[i], _nftIds[i]);

            INFT(_nfts[i]).transferFrom(address(this), _msgSender(), _nftIds[i]);

            emit UnListing(_msgSender(), _nfts[i], _nftIds[i], block.timestamp);
        }

        return true;
    }

    function getCurrency(address _nft, address _currency)
        external
        view
        returns (
            uint256,
            uint256,
            bool
        )
    {
        return currencyManager.getCurrency(_nft, _currency);
    }

    /* ========== EMERGENCY ========== */
    /*
    Users make mistake by transfering usdt/busd ... to contract address. 
    This function allows contract owner to withdraw those tokens and send back to users.
    */
    function rescueStuckErc20(address _token) external onlyOwner {
        uint256 _amount = IBEP20(_token).balanceOf(address(this));
        IBEP20(_token).safeTransfer(owner(), _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

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
        // solhint-disable-next-line no-inline-assembly
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

pragma solidity 0.8.6;

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

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
pragma solidity 0.8.6;

import "../access/Ownable.sol";

contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused, "Contract paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused, "Contract not paused");
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "../util/Context.sol";

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IMarketCurrencyManager {
    function setCurrencies(
        address[] memory _nfts,
        address[] memory _currencies,
        uint256[] memory _commisions,
        uint256[] memory _minAmounts,
        bool[] memory _valids
    ) external;

    function getCurrency(address _nft, address _currency)
        external
        view
        returns (
            uint256,
            uint256,
            bool
        );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IMarketAccessManager {
    function isListingAllowed(address _caller) external view returns (bool);

    function isUpdatePriceAllowed(address _caller) external view returns (bool);

    function isListingAdminAllowed(address _caller)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./access/Ownable.sol";

contract MarketV2Storage is Ownable {
    struct Item {
        address owner;
        address currency;
        uint256 price;
        uint256 listingTime;
        uint256 openTime;
    }
    mapping(address => mapping(uint256 => Item)) items;
    // mapping(uint256 => Item) public items;

    address market;

    modifier onlyMarket() {
        require(market == _msgSender(), "Storage: only market");
        _;
    }

    function setMarket(address _market) external onlyOwner {
        require(_market != address(0), "Error: address(0)");
        market = _market;
    }

    function addItem(
        address _nft,
        uint256 _nftId,
        address _owner,
        address _currency,
        uint256 _price,
        uint256 _listingTime,
        uint256 _openTime
    ) public onlyMarket {
        items[_nft][_nftId] = Item(
            _owner,
            _currency,
            _price,
            _listingTime,
            _openTime
        );
    }

    function addItems(
        address[] memory _nfts,
        uint256[] memory _nftIds,
        address[] memory _owners,
        address[] memory _currencies,
        uint256[] memory _prices,
        uint256[] memory _listingTimes,
        uint256[] memory _openTimes
    ) external onlyMarket {
        for (uint256 i = 0; i < _nftIds.length; i++) {
            addItem(
                _nfts[i],
                _nftIds[i],
                _owners[i],
                _currencies[i],
                _prices[i],
                _listingTimes[i],
                _openTimes[i]
            );
        }
    }

    function deleteItem(address _nft,uint256 _nftId) public onlyMarket {
        delete items[_nft][_nftId];
    }

    function deleteItems(address[] memory _nfts,uint256[] memory _nftIds) external onlyMarket {
        for (uint256 i = 0; i < _nftIds.length; i++) {
            deleteItem(_nfts[i], _nftIds[i]);
        }
    }

    function updateItem(
        address _nft,
        uint256 _nftId,
        address _owner,
        address _currency,
        uint256 _price,
        uint256 _listingTime,
        uint256 _openTime
    ) external onlyMarket {
        items[_nft][_nftId] = Item(
            _owner,
            _currency,
            _price,
            _listingTime,
            _openTime
        );
    }

    function getItem(address _nft, uint256 _nftId)
        external
        view
        returns (
            address,
            address,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            items[_nft][_nftId].owner,
            items[_nft][_nftId].currency,
            items[_nft][_nftId].price,
            items[_nft][_nftId].listingTime,
            items[_nft][_nftId].openTime
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface INFT {
    function get(uint256 _nftId)
        external
        view
        returns (
            address,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function exists(uint256 _id) external view returns (bool);

    function ownerOf(uint256 tokenId) external view returns (address);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "./IBEP20.sol";
import "../../util/Address.sol";

library SafeBEP20 {
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                "SafeBEP20: decreased allowance below zero"
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeBEP20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            require(
                abi.decode(returndata, (bool)),
                "SafeBEP20: BEP20 operation did not succeed"
            );
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}