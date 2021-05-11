// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC1155/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./dependence/GoatAuctionBase.sol";
import "./interface/IGoatStatus.sol";
import "./interface/IGoatRentalWrapper.sol";


contract GoatRental is GoatAuctionBase, ReentrancyGuard {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    struct RentalOrder{
        address owner;
        address renter;
        address originToken;
        address currency;
        uint256[] originIds;
        uint256[] wrappedIds;
        uint256[] amounts;
        uint256 rentalTerm;
        uint256 repossessFee;
        bool repossessed;
        uint256[] subletRentalOrderIds;
    }

    uint256 public nextRentalOrderId = 1;

    uint256 public constant repossessFeeRate = 50;
    uint256 public constant repossessFeeRateBase = 10000;

    mapping(uint256 => uint256) public limitedPriceOrderRentalTerm;
    mapping(uint256 => uint256) public englishOrderRentalTerm;
    mapping(uint256 => RentalOrder) public rentalOrder;

    mapping(uint256 => uint256) private originRentalOrder;
    mapping(uint256 => mapping(uint256 => bool)) private isOriginRentalOrderSet;

    /** ====================  Event  ==================== */

    event LogLimitedPriceRental(address indexed seller, uint256 indexed orderId, address indexed token, address currency, uint256[] ids, uint256[] amounts, uint256 prices, uint256 rentalTerm);
    event LogLimitedPriceRentalCancel(uint256 indexed orderId);
    event LogLimitedPriceRentalBid(address indexed buyer, uint256 indexed orderId);

    event LogEnglishRental(address indexed seller, uint256 indexed orderId, address indexed token, address currency, uint256[] ids,  uint256[] amounts, uint256 startingPrices, uint256 deadline, uint256 rentalTerm);
    event LogEnglishRentalCancel(uint256 indexed orderId);
    event LogEnglishRentalBid(address indexed buyer, uint256 indexed orderId, uint256 indexed price);
    event LogEnglishRentalFinish(uint256 indexed orderId);

    event LogRentOut(uint256 indexed rentalId);
    event LogRepossess(uint256 indexed rentalId, address indexed executor, uint256 repossessFee);
    
    /** ====================  modifier  ==================== */

    modifier invalidRentalTerm(
        address _token,
        uint256[] memory _ids, 
        uint256 _rentalTerm
    ) { 
        require(_rentalTerm > block.timestamp, "2014: rental term should be longer than the current time");
        
        address goatRentalWrapper = goatStatus.rentalWrapperAddress();
        if (_token == goatRentalWrapper) {
            for(uint256 i = 0; i < _ids.length; i++) {
                (,,,uint256 term) = IGoatRentalWrapper(goatRentalWrapper).getWrapInfo(_ids[i]);
                require(_rentalTerm < term, "2015: rental term of sublet should be shorter than the origin");
            }  
        }
        _;
    }


    /** ====================  constractor  ==================== */
    constructor (
        address _goatStatusAddress
    ) 
        public 
        GoatAuctionBase(_goatStatusAddress)
    {}

    function getRentalOrder(
        uint256 _orderId
    ) 
        external 
        view 
        returns (
            address owner,
            address renter,
            address originToken,
            address currency,
            uint256[] memory originIds,
            uint256[] memory wrappedIds,
            uint256[] memory amounts,
            uint256 rentalTerm,
            uint256 repossessFee,
            bool repossessed,
            uint256[] memory subletRentalOrderIds
        ) 
    {
        require(_orderId < nextRentalOrderId, "2002: id not exist");
        RentalOrder memory order = rentalOrder[_orderId];
        return (
            order.owner,
            order.renter,
            order.originToken,
            order.currency,
            order.originIds,
            order.wrappedIds,
            order.amounts,
            order.rentalTerm,
            order.repossessFee,
            order.repossessed,
            order.subletRentalOrderIds
        );
    }

    /** ==================== repossess rental function  ==================== */
    function repossess(
        uint256 _rentalOrderId
    ) 
        external
        nonReentrant
    {
        RentalOrder memory order = rentalOrder[_rentalOrderId];
        if (order.subletRentalOrderIds.length > 0) {
            for (uint256 i = 0; i < order.subletRentalOrderIds.length; i++) {
                uint256 subletRentalOrderId = order.subletRentalOrderIds[i];
                if (!rentalOrder[subletRentalOrderId].repossessed) {
                    _repossess(subletRentalOrderId);
                }
            }
        }

        _repossess(_rentalOrderId);
    }

    /** ==================== limited price rental function  ==================== */

    function limitedPriceRental(
        address _currency,
        address _token,
        uint256[] memory _tokenIds,
        uint256[] memory _amounts,
        uint256 _price,
        uint256 _rentalTerm
    ) 
        external 
        nonReentrant
        invalidRentalTerm(_token, _tokenIds, _rentalTerm)
    {
        uint256 orderId = _limitedPriceAuction(_currency, _token, _tokenIds, _amounts, _price);
        limitedPriceOrderRentalTerm[orderId] = _rentalTerm;
        
        goatStatus.setTokenStatus(msg.sender, _token, _tokenIds, _amounts, 2, 1);
        emit LogLimitedPriceRental(msg.sender, orderId, _token, _currency, _tokenIds, _amounts, _price, _rentalTerm);
    }

    function limitedPriceRentalCancel(
        uint256 _orderId
    ) 
        external 
        nonReentrant 
    {
        _limitedPriceAuctionCancel(_orderId);
        
        emit LogLimitedPriceRentalCancel(_orderId);
    }

    function limitedPriceRentalBid(
        uint256 _orderId,
        address _currency,
        uint256 _price
    ) 
        external 
        payable 
        nonReentrant 
    {
        LimitedPriceOrder memory order = _limitedPriceAuctionBid(_orderId, _currency, _price);

        uint256 actualPrice = _rentOut(order.seller, msg.sender, order.token, order.ids, order.amounts, limitedPriceOrderRentalTerm[_orderId], order.currency, order.price);
        
        if (_currency == ethAddress) {
            payable(order.seller).transfer(actualPrice);
        } else {
            IERC20(_currency).safeTransfer(order.seller, actualPrice);
        }
        
        goatStatus.setTokenStatus(order.seller, order.token, order.ids, order.amounts, 3, 0);
        emit LogLimitedPriceRentalBid(msg.sender, _orderId);
    }

    /** ==================== english rental function  ==================== */

    function englishRental(
        address _currency,
        address _token,
        uint256[] memory _tokenIds,
        uint256[] memory _amounts,
        uint256 _startingPrices,
        uint256 _deadline,
        uint256 _rentalTerm
    ) 
        external 
        nonReentrant
        invalidRentalTerm(_token, _tokenIds, _rentalTerm) 
    {
        uint256 orderId = _englishAuction(_currency, _token, _tokenIds, _amounts, _startingPrices, _deadline);
        englishOrderRentalTerm[orderId] = _rentalTerm;

        goatStatus.setTokenStatus(msg.sender, _token, _tokenIds, _amounts, 2, 2);
        emit LogEnglishRental(msg.sender, orderId, _token, _currency, _tokenIds, _amounts, _startingPrices, _deadline, _rentalTerm);
    }

    function englishRentalCancel(
        uint256 _orderId
    ) 
        external 
        nonReentrant 
    {
        _englishAuctionCancel(_orderId);

        emit LogEnglishRentalCancel(_orderId);
    }

    function englishRentalBid(
        uint256 _orderId,
        address _currency,
        uint256 _price
    ) 
        external 
        payable 
        nonReentrant 
    {
        _englishAutionBid(_orderId, _currency, _price);

        emit LogEnglishRentalBid(msg.sender, _orderId, _price);
    }

    function englishRentalFinish(
        uint256 _orderId
    ) 
        external 
        nonReentrant 
    {
        EnglishOrder memory order = _englishAuctionFinish(_orderId);

        if (order.highestPriceBuyer != address(0)) {
            uint256 actualPrice = _rentOut(order.seller, order.highestPriceBuyer, order.token, order.ids, order.amounts, englishOrderRentalTerm[_orderId], order.currency, order.highestPrice);
            if (order.currency == ethAddress) {
                payable(order.seller).transfer(actualPrice);
            } else {
                IERC20(order.currency).safeTransfer(order.seller, actualPrice);
            }
            goatStatus.setTokenStatus(order.seller, order.token, order.ids, order.amounts, 3, 0);
        } else {
            IERC1155(order.token).safeBatchTransferFrom(address(this), order.seller, order.ids, order.amounts, "");
            goatStatus.setTokenStatus(order.seller, order.token, order.ids, _getInitialArray(order.ids.length, 0), 0, 0);
        }
        
        emit LogEnglishRentalFinish(_orderId);
    }

    /** ==================== internal rental function  ==================== */
    function _rentOut(
        address _owner,
        address _renter,
        address _token,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        uint256 _rentalTerm,
        address _currency,
        uint256 _price
    ) 
        internal
        returns (uint256 actualPrice)
    {

        IERC1155(_token).setApprovalForAll(goatStatus.rentalWrapperAddress(), true);
        uint256[] memory wrappedIds = IGoatRentalWrapper(goatStatus.rentalWrapperAddress()).wrap(_owner, _token, _ids, _amounts, _renter, _rentalTerm);

        uint256 repossessFee = _price.mul(repossessFeeRate).div(repossessFeeRateBase);
        actualPrice = _price.sub(repossessFee);

        uint256 orderId = nextRentalOrderId;
        nextRentalOrderId++;

        uint256[] memory subletRentalOrderIds;
        rentalOrder[orderId] = RentalOrder(
            _owner,
            _renter,
            _token,
            _currency,
            _ids,
            wrappedIds,
            _amounts,
            _rentalTerm,
            repossessFee,
            false,
            subletRentalOrderIds
        );

        for (uint256 i = 0; i < _ids.length; i++) {
            if (_token != goatStatus.rentalWrapperAddress()){
                originRentalOrder[wrappedIds[i]] = orderId;
            } else {
                uint256 originRentalOrderId = originRentalOrder[_ids[i]];
                originRentalOrder[wrappedIds[i]] = originRentalOrderId;
                if (!isOriginRentalOrderSet[originRentalOrderId][orderId]) {
                    isOriginRentalOrderSet[originRentalOrderId][orderId] = true;
                    rentalOrder[originRentalOrderId].subletRentalOrderIds.push(orderId);
                }
            }
        }

        emit LogRentOut(orderId);
    }

    function _repossess(
        uint256 _rentalOrderId
    ) 
        internal 
    {
        require(_rentalOrderId < nextRentalOrderId, "2016: the rental order not exist");
        RentalOrder memory order = rentalOrder[_rentalOrderId];
        require(order.rentalTerm < block.timestamp, "2013: the auction is not over yet");
        require(!order.repossessed, "2017: the rental order has been repossessed");
        
        rentalOrder[_rentalOrderId].repossessed = true;

        address goatRentalWrapper = goatStatus.rentalWrapperAddress();
        IGoatRentalWrapper(goatRentalWrapper).unwrap(order.wrappedIds, order.amounts, order.owner);

        if (order.currency == ethAddress) {
            payable(msg.sender).transfer(order.repossessFee);
        } else {
            IERC20(order.currency).safeTransfer(msg.sender, order.repossessFee);
        }

        emit LogRepossess(_rentalOrderId, msg.sender, order.repossessFee);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
// pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../interface/IGoatStatus.sol";


contract GoatAuctionBase is ERC1155Holder {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct LimitedPriceOrder {
        address seller;
        address token;
        address currency;
        uint256[] ids;
        uint256[] amounts;
        uint256 price;
        bool finished;
        bool canceled;
    }
    
    struct EnglishOrder {
        address seller;
        address token;
        address currency;
        uint256[] ids;
        uint256[] amounts;
        uint256 startingPrice;
        uint256 deadline;
        uint256 highestPrice;
        address highestPriceBuyer;
        bool finished;
        bool canceled;
    }

    IGoatStatus public goatStatus;
    address public constant ethAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    uint256 public nextLimitedPriceOrderId = 1;
    uint256 public nextEnglishOrderId = 1;
    mapping(uint256 => LimitedPriceOrder) private limitedPriceOrder;
    mapping(uint256 => EnglishOrder) private englishOrder;

    /** ====================  modifier  ==================== */
    modifier isValidCurrency(address _currency) {
        require(goatStatus.isCurrency(_currency), "2001: invalid currency");
        _;
    }

    /** ====================  constractor  ==================== */
    constructor (
        address _goatStatusAddress
    ) 
        public 
    {
        goatStatus = IGoatStatus(_goatStatusAddress);
    }

    /** ==================== view function  ==================== */
    
    function getLimitedPriceOrder(
        uint256 oriderId
    ) 
        public 
        view 
        returns (
            address seller,
            address token,
            address currency,
            uint256[] memory ids,
            uint256[] memory amounts,
            uint256 price,
            bool finished,
            bool canceled
        ) 
    {
        require(oriderId < nextLimitedPriceOrderId, "2002: id not exist");
        LimitedPriceOrder memory order = limitedPriceOrder[oriderId];
        return (
            order.seller,
            order.token,
            order.currency,
            order.ids, 
            order.amounts,
            order.price,
            order.finished, 
            order.canceled
        );

    }

    function getEnglishOrder(
        uint256 oriderId
    ) 
        public 
        view 
        returns (
            address seller,
            address token,
            address currency,
            uint256[] memory ids,
            uint256[] memory amounts,
            uint256 startingPrice,
            uint256 deadline,
            uint256 highestPrice,
            address highestPriceBuyer,
            bool finished,
            bool canceled
        ) 
    {
        require(oriderId < nextEnglishOrderId, "2002: id not exist");
        EnglishOrder memory order = englishOrder[oriderId];
        return (
            order.seller,
            order.token,
            order.currency,
            order.ids, 
            order.amounts,
            order.startingPrice,
            order.deadline, 
            order.highestPrice,
            order.highestPriceBuyer,
            order.finished,
            order.canceled
        );

    }

    /** ==================== limited price auction function  ==================== */

    function _limitedPriceAuction(
        address _currency,
        address _token,
        uint256[] memory _tokenIds,
        uint256[] memory _amounts,
        uint256 _price
    ) 
        internal 
        isValidCurrency(_currency) 
        returns (uint256) 
    {
        require(_tokenIds.length == _amounts.length, "2003: unterschiedlich lang array");
        
        IERC1155 token = IERC1155(_token);
        token.safeBatchTransferFrom(msg.sender, address(this), _tokenIds, _amounts, "");        

        uint256 orderId = _getLimitedPriceOrderId();

        limitedPriceOrder[orderId] = LimitedPriceOrder (
            msg.sender,
            _token,
            _currency,
            _tokenIds,
            _amounts,
            _price,
            false,
            false
        );

        return orderId;
    }

    function _limitedPriceAuctionCancel(
        uint256 _orderId
    ) 
        internal 
    {
        require(_orderId < nextLimitedPriceOrderId, "2002: id not exist");
        LimitedPriceOrder memory order = limitedPriceOrder[_orderId];
        require(order.seller == msg.sender, "2004: caller is not seller");
        require(!order.finished && !order.canceled, "2005: the order is finished or canceled");
        
        limitedPriceOrder[_orderId].canceled = true;

        goatStatus.setTokenStatus(order.seller, order.token, order.ids, _getInitialArray(order.ids.length, 0), 0, 0);

        IERC1155(order.token).safeBatchTransferFrom(address(this), msg.sender, order.ids, order.amounts, "");
    }

    function _limitedPriceAuctionBid(
        uint256 _orderId,
        address _currency,
        uint256 _price
    ) 
        internal 
        isValidCurrency(_currency) 
        returns (LimitedPriceOrder memory) 
    {
        require(_orderId < nextLimitedPriceOrderId, "2002: id not exist");
        LimitedPriceOrder memory order = limitedPriceOrder[_orderId];

        require(!order.finished && !order.canceled, "2005: the order is finished or canceled");
        require(order.seller != msg.sender, "2006: seller can buy your own order");
        require(order.currency == _currency, "2001: invalid currency");
        require(order.price == _price, "2007: invalid price");

        limitedPriceOrder[_orderId].finished = true;

        if (_currency == ethAddress) {
            require(msg.value == _price, "2008: invalid eth value");
        } else {
            IERC20(_currency).safeTransferFrom(msg.sender, address(this), _price);
        }

        return order;
    }

    /** ==================== english auction function  ==================== */

    function _englishAuction(
        address _currency,
        address _token,
        uint256[] memory _tokenIds,
        uint256[] memory _amounts,
        uint256 _startingPrices,
        uint256 _deadline
    ) 
        internal 
        isValidCurrency(_currency) 
        returns (uint256) 
    {
        require(_tokenIds.length == _amounts.length, "2003: unterschiedlich lang array");
        require(_deadline > block.timestamp, "2009: deadline should be longer than the current time");

        IERC1155 token = IERC1155(_token);
        token.safeBatchTransferFrom(msg.sender, address(this), _tokenIds, _amounts, "");

        uint256 orderId = _getEnglishOrderId();

        englishOrder[orderId] = EnglishOrder(
            msg.sender,
            _token,
            _currency,
            _tokenIds,
            _amounts,
            _startingPrices,
            _deadline,
            _startingPrices,
            address(0),
            false,
            false
        );

        return orderId;
    }

    function _englishAuctionCancel(
        uint256 _orderId
    ) 
        internal 
    {
        require(_orderId < nextEnglishOrderId, "2002: id not exist");
        EnglishOrder memory order = englishOrder[_orderId];

        require(order.seller == msg.sender, "2004: caller is not seller");
        require(order.highestPriceBuyer == address(0), "2010: can not cancel auction when someone bids");
        require(!order.finished && !order.canceled, "2005: the order is finished or canceled");

        englishOrder[_orderId].canceled = true;
        
        goatStatus.setTokenStatus(order.seller, order.token, order.ids, _getInitialArray(order.ids.length, 0), 0, 0);

        IERC1155(order.token).safeBatchTransferFrom(address(this), msg.sender, order.ids, order.amounts, "");
    }

    function _englishAutionBid(
        uint256 _orderId,
        address _currency,
        uint256 _price
    ) 
        internal 
        isValidCurrency(_currency) 
    {
        require(_orderId < nextEnglishOrderId, "2002: id not exist");
        EnglishOrder memory order = englishOrder[_orderId];

        require(!order.finished && !order.canceled, "2005: the order is finished or canceled");
        require(order.deadline > block.timestamp, "2011: The auction is over");
        require(order.seller != msg.sender, "2006: seller can buy your own order");
        require(order.currency == _currency, "2001: invalid currency");
        require(order.highestPrice < _price, "2012: the peice should be higher than the current highest price");

        if (_currency == ethAddress) {
            require(msg.value == _price, "2008: invalid eth value");
            if(order.highestPriceBuyer != address(0)) {
                payable(order.highestPriceBuyer).transfer(order.highestPrice);
            }
        } else {
            IERC20(_currency).safeTransferFrom(msg.sender, address(this), _price);
            if(order.highestPriceBuyer != address(0)) {
                IERC20(_currency).safeTransfer(order.highestPriceBuyer, order.highestPrice);
            }
        }

        englishOrder[_orderId].highestPriceBuyer = msg.sender;
        englishOrder[_orderId].highestPrice = _price;
    }

    function _englishAuctionFinish(
        uint256 _orderId
    ) 
        internal 
        returns (EnglishOrder memory) 
    {
        require(_orderId < nextEnglishOrderId, "2002: id not exist");
        EnglishOrder memory order = englishOrder[_orderId];

        require(!order.finished && !order.canceled, "2005: the order is finished or canceled");
        require(order.deadline <= block.timestamp, "2013: the auction is not over yet");

        englishOrder[_orderId].finished = true;

        return order;
    }

    /** ==================== internal function  ==================== */

    function _getLimitedPriceOrderId() 
        internal 
        returns (uint256 id) 
    {
        id = nextLimitedPriceOrderId;
        nextLimitedPriceOrderId++;
    }

    function _getEnglishOrderId() 
        internal 
        returns (uint256 id) 
    {
        id = nextEnglishOrderId;
        nextEnglishOrderId++;
    }

    function _getInitialArray(
        uint256 _length,
        uint256 _value
    ) internal view returns (uint256[] memory) {
        uint256[] memory array = new uint256[](_length);
        for (uint256 i = 0; i < _length; i++) {
            array[i] = _value;
        }
        return array;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IGoatRentalWrapper {
    function wrap(
        address _owner,
        address _token,
        uint256[] calldata _ids,
        uint256[] calldata _amounts,
        address _receiver,
        uint256 _rentalTerm
    ) external returns (uint256[] memory);

    function unwrap(
        uint256[] calldata _wrappedIds,
        uint256[] calldata _amounts,
        address _receiver
    ) external;

    function getWrapInfo(
        uint256 _wrappedId
    ) external view returns (
            address owner,
            address originToken,
            uint256 originId,
            uint256 rentalTerm
        );

}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;


interface IGoatStatus {

    function setAddress(
        address _saleAddress,
        address _rentalAddress,
        address _goatNFTAddress,
        address _rentalWrapperAddress
    ) external;
    function saleAddress() external view returns (address);
    function rentalAddress() external view returns (address);
    function goatNFTAddress() external view returns (address);
    function rentalWrapperAddress() external view returns (address);

    function setCurrencyToken(address token, bool enable) external;
    function isCurrency(address token) external view returns (bool);
    function getCurrencyList() external view returns (address[] memory);


    function setTokenStatus(
        address _owner,
        address _token,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        uint256 _tokenStatus,
        uint256 _auctionType
    ) external;

    function getTokenStatus(
        address _owner,
        address _token,
        uint256 _id
    )
    external
    view
    returns (
        uint256 tokenStatus,
        uint256 auctionType,
        uint256 amount
    );
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
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
library SafeMath {
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

import "./ERC1155Receiver.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC1155Receiver.sol";
import "../../introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    constructor() internal {
        _registerInterface(
            ERC1155Receiver(address(0)).onERC1155Received.selector ^
            ERC1155Receiver(address(0)).onERC1155BatchReceived.selector
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
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

import "./IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
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

import "../../introspection/IERC165.sol";

/**
 * _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.2 <0.8.0;

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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

    constructor () internal {
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

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 1000
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}