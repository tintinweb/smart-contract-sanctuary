//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./Controllable.sol";
import "./ITokenSale.sol";

/// tokensale implementation
contract TokenSale is ITokenSale, Controllable, Initializable {

    address payee;
    address soldToken;
    uint256 salePrice_;
    uint256 issueCount;
    uint256 maxCount;
    uint256 vipReserve;
    uint256 vipIssued;

    TokenMinting[] _purchasers;
    TokenMinting[] _mintees;

    address _partner;
    uint256 _permill;

    bool _openState;

    /// @notice Called to purchase some quantity of a token
    /// @param _soldToken - the erc721 address
    /// @param _salePrice - the sale price
    /// @param _maxCount - the max quantity
    /// @param _vipReserve - the vip reserve to set aside for minting directly
    constructor(address _soldToken, uint256 _salePrice, uint256 _maxCount, uint256 _vipReserve) {

        _addController(msg.sender);
        payee = msg.sender;
        soldToken = _soldToken;
        salePrice_ = _salePrice;
        issueCount = 0;
        maxCount = _maxCount;
        vipReserve = _vipReserve;
        vipIssued = 0;
    }

    /// @dev called after constructor once to init stuff
    function initialize(address partner, uint256 permill) public initializer {
        require(IMintable(soldToken).getMinter() == address(this), "soldToken must be controllable by this contract");
        _partner = partner;
        _permill = permill;
    }

    /// @dev create a token hash using the address of this objcet, sender address and the current issue count
    function _createTokenHash() internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(address(this), msg.sender, issueCount)));
    }

    /// @notice Called to purchase some quantity of a token
    /// @param receiver - the address of the account receiving the item
    /// @param quantity - the quantity to purchase. max 5. 
    function purchase(address receiver, uint256 quantity) external payable override returns (TokenMinting[] memory mintings) {
        require(issueCount + quantity + vipReserve <= maxCount, "cannot purchase more than maxCount");
        require(salePrice_ * quantity <= msg.value, "must attach funds to purchase items");
        require(quantity > 0 && quantity <= 5, "cannot purchase more than 5 items");
        require(_openState, "cannot mint when tokensale is closed");

        // mint the desired tokens to the receiver
        mintings = new TokenMinting[](quantity);
        for(uint256 i = 0; i < quantity; i++) {
            TokenMinting memory _minting = TokenMinting(receiver, _createTokenHash());
            // create a record of this new minting
            _purchasers.push(_minting);
            // and get a refence to it
            mintings[i] = _minting;
            issueCount = issueCount + 1;
            // mint the token
            IMintable(soldToken).mint(receiver, _minting.tokenHash);
            // emit an event to that respect
            emit TokenSold(receiver, _minting.tokenHash);
        }

        uint256 partnerShare = 0;
        // transfer to partner share
        if(_partner != address(0) && _permill > 0) {
            partnerShare = msg.value * _permill / 1000000;
            payable(_partner).transfer(partnerShare);
        }
        uint256 ourShare = msg.value - partnerShare; 
        payable(payee).transfer(ourShare);
    }

    /// @notice returns the sale price in ETH for the given quantity.
    /// @param quantity - the quantity to purchase. max 5. 
    /// @return price - the sale price for the given quantity
    function salePrice(uint256 quantity) external view override returns (uint256 price) {
        price = salePrice_ * quantity;
    }

    /// @notice Mint a specific tokenhash to a specific address ( up to har-cap limit)
    /// only for controller of token
    /// @param receiver - the address of the account receiving the item
    /// @param tokenHash - token hash to mint to the receiver
    function mint(address receiver, uint256 tokenHash) external override onlyController {
        require(vipIssued < vipReserve, "cannot mint more than the reserve");
        require(issueCount < maxCount, "cannot mint more than maxCount");
        vipIssued = vipIssued + 1;
        issueCount = issueCount + 1;
        _mintees.push(TokenMinting(receiver, _createTokenHash()));
        IMintable(soldToken).mint(receiver, tokenHash);
    }

    /// @notice set the revenue partner on this tokensale. we split revenue with the partner
    /// only for controller of token
    /// @param partner - the address of the partner. will receive x%% of the revenue
    /// @param permill - permilliage of the revenue to be split. min 0 max 1000000
    function setRevenuePartner(address partner, uint256 permill) external override onlyController {
        require(permill >= 0 && permill <= 1000000, "permill must be between 0 and 1000000");
        _partner = partner;
        _permill = permill;
        emit RevenuePartnerChanged(partner, permill);
    }

    /// @notice get the revenue partner on this tokensale. we split revenue with the partner
    /// @return partner - the address of the partner. will receive x%% of the revenue
    /// @return permill - permilliage of the revenue to be split. permill = 1 / 1000000
    function getRevenuePartner() external view override returns (address partner, uint256 permill) {
        return (_partner, _permill);
    }

    /// @notice open / close the tokensale
    /// only for controller of token
    /// @param openState - the open state of the tokensale
    function setOpenState(bool openState) external override onlyController {
        _openState = openState;
    }

    /// @notice get the token sale open state
    /// @return openState - the open state of the tokensale
    function getOpenState() external view override returns (bool openState) {
        openState = _openState;
    }

    /// @notice set the psale price
    /// only for controller of token
    /// @param _salePrice - the open state of the tokensale
    function setSalePrice(uint256 _salePrice) external override onlyController {
        require(salePrice_ > 0, "salePrice must be greater than 0");
        salePrice_ = _salePrice;
    }

    /// @notice get the token sale price
    /// @return salePrice - the open state of the tokensale
    function getSalePrice() external view  override returns (uint256) {
        return salePrice_;
    }

    /// @notice set the psale price
    /// only for controller of token
    /// @param _payee - the open state of the tokensale
    function setPayee(address _payee) external override onlyController {
        require(_payee != address(0), "payee cannoot be zero address");
        payee = _payee;
        emit PayeeChanged(payee);
    }

    /// @notice get the token sale price
    /// @return salePrice - the open state of the tokensale
    function getPayee() external view  override returns (address) {
        return payee;
    }

    /// @notice get the address of the sole token
    /// @return token - the address of the sole token
    function getSaleToken() external view override returns (address token) {
        return soldToken;
    }

    /// @notice get the total list of purchasers
    /// @return _list - total list of purchasers
    function purchaserList() external view override returns (TokenMinting[] memory _list) {
        _list = _purchasers;
    }

    /// @notice get the total list of minters
    /// @return _list - total list of purchasers
    function minterList() external view override returns (TokenMinting[] memory _list) {
        _list = _mintees;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "./IControllable.sol";

abstract contract Controllable is IControllable {
    mapping(address => bool) internal _controllers;

    /**
     * @dev Throws if called by any account not in authorized list
     */
    modifier onlyController() {
        require(
            _controllers[msg.sender] == true || address(this) == msg.sender,
            "Controllable: caller is not a controller"
        );
        _;
    }

    /**
     * @dev Add an address allowed to control this contract
     */
    function _addController(address _controller) internal {
        _controllers[_controller] = true;
    }

    /**
     * @dev Add an address allowed to control this contract
     */
    function addController(address _controller)
        external
        override
        onlyController
    {
        _controllers[_controller] = true;
    }

    /**
     * @dev Check if this address is a controller
     */
    function isController(address _address)
        external
        view
        override
        returns (bool allowed)
    {
        allowed = _controllers[_address];
    }

    /**
     * @dev Remove the sender address from the list of controllers
     */
    function relinquishControl() external override onlyController {
        delete _controllers[msg.sender];
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

///
/// @dev Interface for the NFT Royalty Standard
///
interface ITokenSale {

    /// @notice Called to purchase some quantity of a token
    /// @param receiver - the address of the account receiving the item
    /// @param quantity - the quantity to purchase. max 5. 
    function purchase(address receiver, uint256 quantity) external payable returns (TokenMinting[] memory mintings);

    /// @notice returns the sale price in ETH for the given quantity.
    /// @param quantity - the quantity to purchase. max 5. 
    /// @return price - the sale price for the given quantity
    function salePrice(uint256 quantity) external view returns (uint256 price);

    /// @notice Mint a specific tokenhash to a specific address ( up to har-cap limit)
    /// only for controller of token
    /// @param receiver - the address of the account receiving the item
    /// @param tokenHash - token hash to mint to the receiver
    function mint(address receiver, uint256 tokenHash) external;

    /// @notice set the revenue partner on this tokensale. we split revenue with the partner
    /// only for controller of token
    /// @param partner - the address of the partner. will receive x%% of the revenue
    /// @param permill - permilliage of the revenue to be split. min 0 max 1000000
    function setRevenuePartner(address partner, uint256 permill) external;

    /// @notice get the revenue partner on this tokensale. we split revenue with the partner
    /// @return partner - the address of the partner. will receive x%% of the revenue
    /// @return permill - permilliage of the revenue to be split. permill = 1 / 1000000
    function getRevenuePartner() external view returns (address , uint256);

    /// @notice open / close the tokensale
    /// only for controller of token
    /// @param openState - the open state of the tokensale
    function setOpenState(bool openState) external;

    /// @notice get the token sale open state
    /// @return openState - the open state of the tokensale
    function getOpenState() external view returns (bool);

    /// @notice set the psale price
    /// only for controller of token
    /// @param _salePrice - the open state of the tokensale
    function setSalePrice(uint256 _salePrice) external;

    /// @notice get the token sale price
    /// @return salePrice - the open state of the tokensale
    function getSalePrice() external view returns(uint256);


    /// @notice get the address of the sole token
    /// @return token - the address of the sole token
    function getSaleToken() external view returns(address);

    /// @notice get the primary token sale payee
    /// @return payee_ the token sale payee
    function getPayee() external view returns (address payee_);
    
    /// @notice set the primary token sale payee
    /// @param _payee - the token sale payee
    function setPayee(address _payee) external;

    /// @notice return the mintee list
    /// @return _list the token sale payee
    function minterList() external view returns (TokenMinting[] memory _list);

    /// @notice return the purchaser list
    /// @return _list the token sale payee
    function purchaserList() external view returns (TokenMinting[] memory _list);

    struct TokenMinting {
        address recipient;
        uint256 tokenHash;
    }

    event TokenSold(address indexed receiver, uint256 tokenHash);
    event PayeeChanged(address indexed receiver);
    event RevenuePartnerChanged(address indexed partner, uint256 permill);
}

interface IMintable {
    function mint(address receiver, uint256 tokenHash) external;
    function getMinter() external view returns (address);
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IControllable {
    
    event ControllerAdded(
        address indexed contractAddress,
        address indexed controllerAddress
    );

    event ControllerRemoved(
        address indexed contractAddress,
        address indexed controllerAddress
    );

    function addController(address controller) external;

    function isController(address controller) external view returns (bool);

    function relinquishControl() external;
}