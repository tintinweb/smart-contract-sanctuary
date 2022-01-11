// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./PausableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./IERC721.sol";

contract Marketplace is
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using SafeMath for uint256;

    enum EnItemStatus {
        DEFAULT,
        CANCELLED,
        LISTING,
        BOUGHT
    }

    event EListingMarketItem(
        uint256 indexed _itemId,
        uint256 indexed _tokenId,
        uint256 _price,
        address _seller,
        address _owner,
        EnItemStatus _status
    );

    event ESaleMaketItem(
        uint256 indexed _itemId,
        uint256 indexed _tokenId,
        uint256 _fee,
        address buyer,
        EnItemStatus _status
    );

    event ECancelMarketItem(
        uint256 indexed _itemId,
        uint256 indexed _tokenId,
        address _owner,
        EnItemStatus _status
    );

    event EWithdrawToken(address _owner, uint256 _amount);

    struct OMarketItem {
        uint256 itemId;
        uint256 tokenId;
        uint256 price;
        address seller;
        address owner;
        EnItemStatus status;
    }

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    CountersUpgradeable.Counter private _cItemIds;

    IERC20 IPLVToken;
    IERC721 INFTToken;

    mapping(uint256 => OMarketItem) private mMarketItems;

    uint256 private commissionFee;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        address _owner,
        address _PLVAddress,
        address _NFTAddress
    ) public initializer {
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
        _grantRole(PAUSER_ROLE, _owner);
        _grantRole(UPGRADER_ROLE, _owner);
        _grantRole(OPERATOR_ROLE, _owner);

        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);

        IPLVToken = IERC20(_PLVAddress);
        INFTToken = IERC721(_NFTAddress);
        commissionFee = 5;
    }

    function transferAdmin(address _admin) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_admin != address(0), "ZERO_ADDRESS");
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function setOperatorRole(address _operator)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_operator != address(0), "ZERO_ADDRESS");
        _grantRole(OPERATOR_ROLE, _operator);
    }

    function removeOperatorRole(address _operator)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_operator != address(0), "ZERO_ADDRESS");
        _revokeRole(OPERATOR_ROLE, _operator);
    }

    function listMarketItem(uint256 _tokenId, uint256 _price)
        public
        returns (uint256)
    {
        require(INFTToken.ownerOf(_tokenId) == msg.sender, "NOT_OWNER_NFT");

        _cItemIds.increment();
        uint256 _itemId = _cItemIds.current();
        mMarketItems[_itemId] = OMarketItem(
            _itemId,
            _tokenId,
            _price,
            msg.sender,
            address(this),
            EnItemStatus.LISTING
        );

        INFTToken.transferFrom(msg.sender, address(this), _tokenId);

        emit EListingMarketItem(
            _itemId,
            _tokenId,
            _price,
            msg.sender,
            address(this),
            EnItemStatus.LISTING
        );
        return _itemId;
    }

    function saleMaketItem(uint256 _itemId) public {
        require(_itemId <= _cItemIds.current(), "ITEM_ID_OUT_OF_RANGE_MARKET");
        OMarketItem storage _omi = mMarketItems[_itemId];
        require(_omi.status == EnItemStatus.LISTING, "ITEM_NOT_IN_LISTING");
        require(_omi.seller != msg.sender, "NOT_BUY_YOURSELF");
        require(
            _omi.price <= IPLVToken.balanceOf(msg.sender),
            "BALANCE_NOT_SUFFICIENT"
        );

        uint256 _fee = _omi.price.mul(commissionFee).div(100);

        _omi.owner = msg.sender;
        _omi.status = EnItemStatus.BOUGHT;
        _cItemIds.increment();

        IPLVToken.transferFrom(msg.sender, _omi.seller, _omi.price.sub(_fee));
        IPLVToken.transferFrom(msg.sender, address(this), _fee);
        INFTToken.transferFrom(address(this), msg.sender, _omi.tokenId);

        emit ESaleMaketItem(
            _itemId,
            _omi.tokenId,
            _fee,
            msg.sender,
            EnItemStatus.BOUGHT
        );
    }

    function cancelMarketItem(uint256 _itemId) public {
        require(_itemId <= _cItemIds.current(), "ITEM_ID_OUT_OF_RANGE_MARKET");
        OMarketItem storage _omi = mMarketItems[_itemId];
        require(_omi.status == EnItemStatus.LISTING, "ITEM_NOT_IN_LISTING");
        require(_omi.seller == msg.sender, "NOT_OWN_ITEM");

        _omi.owner = msg.sender;
        _omi.status = EnItemStatus.CANCELLED;

        INFTToken.transferFrom(address(this), msg.sender, _omi.tokenId);

        emit ECancelMarketItem(
            _itemId,
            _omi.tokenId,
            msg.sender,
            EnItemStatus.CANCELLED
        );
    }

    function withdrawToken() public onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 amount = IPLVToken.balanceOf(address(this));
        IPLVToken.transfer(msg.sender, amount);
        emit EWithdrawToken(msg.sender, amount);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}

    /**
     * @dev function return current verion of smart contract
     */
    function version() public pure returns (string memory) {
        return "v1.0!";
    }
}