// SPDX-License-Identifier: -- 🧊 --

pragma solidity ^0.8.7;

import "./EIP712MetaTransaction.sol";
import "./AccessController.sol";
import "./TransferHelper.sol";
import "./Interfaces.sol";
import "./Events.sol";

contract IceRegistrant is AccessController, TransferHelper, EIP712MetaTransaction, Events {

    uint256 public upgradeCount;
    uint256 public upgradeRequestCount;

    address public tokenAddressDG;
    address public tokenAddressICE;

    address public depositAddressDG;
    address public depositAddressNFT;

    address public paymentToken;
    uint256 public mintingPrice;

    uint256 public saleCount;

    uint256 public saleLimit;
    uint256 public saleFrame;

    bool public allowChangeSaleLimit;

    struct Level {
        bool isActive;
        uint256 costAmountDG;
        uint256 moveAmountDG;
        uint256 costAmountICE;
        uint256 moveAmountICE;
        uint256 floorBonus;
        uint256 deltaBonus;
    }

    struct Upgrade {
        uint256 level;
        uint256 bonus;
    }

    struct Request {
        uint256 itemId;
        uint256 tokenId;
        address tokenAddress;
        address tokenOwner;
    }

    mapping (bytes32 => address) public owners;
    mapping (address => address) public targets;

    mapping (address => uint256) public frames;
    mapping (uint256 => uint256) public limits;

    mapping (uint256 => Level) public levels;
    mapping (uint256 => Request) public requests;

    mapping (address => mapping (bytes32 => Upgrade)) public registrer;

    constructor(
        uint256 _mintingPrice,
        address _paymentToken,
        address _tokenAddressDG,
        address _tokenAddressICE,
        address _accessoriesContract
    )
        EIP712Base('IceRegistrant', 'v1.2')
    {
        saleLimit = 500;
        saleFrame = 1 hours;

        paymentToken = _paymentToken;
        mintingPrice = _mintingPrice;

        tokenAddressDG = _tokenAddressDG;
        tokenAddressICE = _tokenAddressICE;

        allowChangeSaleLimit = true;

        targets[_accessoriesContract] = _accessoriesContract;

        levels[0].floorBonus = 1;
        levels[0].deltaBonus = 6;

        limits[0] = 100;
    }

    function changeTokenAddressICE(
        address _newTokenAddressICE
    )
        external
        onlyCEO
    {
        tokenAddressICE = _newTokenAddressICE;
    }

    function changeTokenAddressDG(
        address _newTokenAddressDG
    )
        external
        onlyCEO
    {
        tokenAddressDG = _newTokenAddressDG;
    }

    function changeDepositAddressDG(
        address _newDepositAddressDG
    )
        external
        onlyCEO
    {
        depositAddressDG = _newDepositAddressDG;
    }

    function changeDepositAddressNFT(
        address _newDepositAddressNFT
    )
        external
        onlyCEO
    {
        depositAddressNFT = _newDepositAddressNFT;
    }

    function changeMintingPrice(
        uint256 _newMintingPrice
    )
        external
        onlyCEO
    {
        mintingPrice = _newMintingPrice;
    }

    function changeMintLimits(
        uint256 _itemId,
        uint256 _newLimit
    )
        external
        onlyCEO
    {
        limits[_itemId] = _newLimit;
    }

    function changeSaleFrame(
        uint256 _newSaleFrame
    )
        external
        onlyCEO
    {
        saleFrame = _newSaleFrame;
    }

    function changeSaleLimit(
        uint256 _newSaleLimit
    )
        external
        onlyCEO
    {
        require(
            allowChangeSaleLimit == true,
            'iceRegistrant: change disabled'
        );

        saleLimit = _newSaleLimit;
    }

    function disabledSaleLimitChange()
        external
        onlyCEO
    {
        allowChangeSaleLimit = false;
    }

    function changePaymentToken(
        address _newPaymentToken
    )
        external
        onlyCEO
    {
        paymentToken = _newPaymentToken;
    }

    function changeTargetContract(
        address _tokenAddress,
        address _accessoriesContract
    )
        external
        onlyCEO
    {
        targets[_tokenAddress] = _accessoriesContract;
    }

    function manageLevel(
        uint256 _level,
        uint256 _costAmountDG,
        uint256 _moveAmountDG,
        uint256 _costAmountICE,
        uint256 _moveAmountICE,
        uint256 _floorBonus,
        uint256 _deltaBonus,
        bool _isActive
    )
        external
        onlyCEO
    {
        levels[_level].costAmountDG = _costAmountDG;
        levels[_level].moveAmountDG = _moveAmountDG;

        levels[_level].costAmountICE = _costAmountICE;
        levels[_level].moveAmountICE = _moveAmountICE;

        levels[_level].floorBonus = _floorBonus;
        levels[_level].deltaBonus = _deltaBonus;

        levels[_level].isActive = _isActive;

        emit LevelEdit(
            _level,
            _costAmountDG,
            _moveAmountDG,
            _costAmountICE,
            _moveAmountICE,
            _isActive
        );
    }

    function mintToken(
        uint256 _itemId,
        address _minterAddress,
        address _tokenAddress
    )
        external
        onlyWorker
    {
        require(
            saleLimit > saleCount,
            'iceRegistrant: sold-out'
        );

        unchecked {
            saleCount =
            saleCount + 1;
        }

        require(
            limits[_itemId] > 0,
            'iceRegistrant: limited'
        );

        unchecked {
            limits[_itemId] =
            limits[_itemId] - 1;
        }

        require(
            canPurchaseAgain(_minterAddress) == true,
            'iceRegistrant: cool-down detected'
        );

        frames[_minterAddress] = block.timestamp;

        safeTransferFrom(
            paymentToken,
            _minterAddress,
            ceoAddress,
            mintingPrice
        );

        DGAccessories target = DGAccessories(
            targets[_tokenAddress]
        );

        uint256 newTokenId = target.encodeTokenId(
            _itemId,
            getSupply(_itemId, targets[_tokenAddress]) + 1
        );

        bytes32 newHash = getHash(
            targets[_tokenAddress],
            newTokenId
        );

        owners[newHash] = _minterAddress;

        registrer[_minterAddress][newHash].level = 1;
        registrer[_minterAddress][newHash].bonus = getNumber(
            levels[0].floorBonus,
            levels[0].deltaBonus,
            saleCount,
            block.timestamp
        );

        address[] memory beneficiaries = new address[](1);
        beneficiaries[0] = _minterAddress;

        uint256[] memory itemIds = new uint256[](1);
        itemIds[0] = _itemId;

        target.issueTokens(
            beneficiaries,
            itemIds
        );

        emit InitialMinting(
            newTokenId,
            saleCount,
            _minterAddress
        );
    }

    function upgradeToken(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _itemId
    )
        external
        onlyWorker
    {
        require(
            targets[_tokenAddress] != address(0x0),
            'iceRegistrant: invalid token target'
        );

        ERC721 tokenNFT = ERC721(_tokenAddress);
        address tokenOwner = msgSender();

        require(
            tokenNFT.ownerOf(_tokenId) == tokenOwner,
            'iceRegistrant: invalid owner'
        );

        bytes32 tokenHash = getHash(
            _tokenAddress,
            _tokenId
        );

        uint256 nextLevel = getLevel(
            tokenOwner,
            tokenHash
        ) + 1;

        require(
            levels[nextLevel].isActive,
            'iceRegistrant: inactive level'
        );

        uint256 requestIndex = upgradeRequestCount;

        tokenNFT.transferFrom(
            tokenOwner,
            address(this),
            _tokenId
        );

        DGAccessories target = DGAccessories(
            targets[_tokenAddress]
        );

        (uint256 itemId, uint256 issuedId) = target.decodeTokenId(
            _tokenId
        );

        requests[requestIndex].itemId = itemId;
        requests[requestIndex].tokenId = _tokenId;
        requests[requestIndex].tokenAddress = _tokenAddress;
        requests[requestIndex].tokenOwner = tokenOwner;

        unchecked {
            upgradeRequestCount =
            upgradeRequestCount + 1;
        }

        emit UpgradeItem(
            itemId,
            issuedId,
            tokenOwner,
            _tokenId,
            _tokenAddress,
            requestIndex
        );

        _resolveUpgradeMint(
            requestIndex,
            _itemId
        );
    }

    function _resolveUpgradeMint(
        uint256 _requestIndex,
        uint256 _itemId
    )
        internal
    {
        uint256 tokenId = requests[_requestIndex].tokenId;
        address tokenAddress = requests[_requestIndex].tokenAddress;
        address tokenOwner = requests[_requestIndex].tokenOwner;

        delete requests[_requestIndex];

        bytes32 tokenHash = getHash(
            tokenAddress,
            tokenId
        );

        uint256 nextLevel = getLevel(
            tokenOwner,
            tokenHash
        ) + 1;

        delete owners[tokenHash];
        delete registrer[tokenOwner][tokenHash];

        _takePayment(
            tokenOwner,
            levels[nextLevel].costAmountDG,
            levels[nextLevel].costAmountICE
        );

        ERC721(tokenAddress).transferFrom(
            address(this),
            depositAddressNFT,
            tokenId
        );

        DGAccessories target = DGAccessories(
            targets[tokenAddress]
        );

        uint256 newTokenId = target.encodeTokenId(
            _itemId,
            getSupply(_itemId, targets[tokenAddress]) + 1
        );

        bytes32 newHash = getHash(
            targets[tokenAddress],
            newTokenId
        );

        owners[newHash] = tokenOwner;

        registrer[tokenOwner][newHash].level = nextLevel;
        registrer[tokenOwner][newHash].bonus = getNumber(
            levels[nextLevel].floorBonus,
            levels[nextLevel].deltaBonus,
            upgradeCount,
            block.timestamp
        );

        unchecked {
            upgradeCount =
            upgradeCount + 1;
        }

        address[] memory beneficiaries = new address[](1);
        beneficiaries[0] = tokenOwner;

        uint256[] memory itemIds = new uint256[](1);
        itemIds[0] = _itemId;

        target.issueTokens(
            beneficiaries,
            itemIds
        );

        emit UpgradeResolved(
            _itemId,
            tokenOwner,
            newTokenId,
            tokenAddress
        );
    }

    function reIceNFT(
        address _oldOwner,
        address _tokenAddress,
        uint256 _tokenId
    )
        external
    {
        require(
            targets[_tokenAddress] != address(0x0),
            'iceRegistrant: invalid token'
        );

        ERC721 token = ERC721(_tokenAddress);
        address newOwner = msgSender();

        require(
            token.ownerOf(_tokenId) == newOwner,
            'iceRegistrant: invalid owner'
        );

        bytes32 tokenHash = getHash(
            _tokenAddress,
            _tokenId
        );

        uint256 currentLevel = getLevelById(
            _oldOwner,
            _tokenAddress,
            _tokenId
        );

        _takePayment(
            newOwner,
            levels[currentLevel].moveAmountDG,
            levels[currentLevel].moveAmountICE
        );

        uint256 reIceLevel = registrer[_oldOwner][tokenHash].level;
        uint256 reIceBonus = registrer[_oldOwner][tokenHash].bonus;

        require(
            reIceLevel > registrer[newOwner][tokenHash].level,
            'iceRegistrant: preventing level downgrade'
        );

        require(
            reIceBonus > registrer[newOwner][tokenHash].bonus,
            'iceRegistrant: preventing bonus downgrade'
        );

        delete registrer[_oldOwner][tokenHash];

        registrer[newOwner][tokenHash].level = reIceLevel;
        registrer[newOwner][tokenHash].bonus = reIceBonus;

        owners[tokenHash] = newOwner;

        emit IceLevelTransfer(
            _oldOwner,
            newOwner,
            _tokenAddress,
            _tokenId
        );
    }

    function adjustRegistrantEntry(
        address _tokenOwner,
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _bonusValue,
        uint256 _levelValue
    )
        external
        onlyWorker
    {
        bytes32 tokenHash = getHash(
            _tokenAddress,
            _tokenId
        );

        owners[tokenHash] = _tokenOwner;

        registrer[_tokenOwner][tokenHash].level = _levelValue;
        registrer[_tokenOwner][tokenHash].bonus = _bonusValue;
    }

    function getSupply(
        uint256 _itemId,
        address _accessoriesContract
    )
        public
        returns (uint256)
    {
        (   string memory rarity,
            uint256 maxSupply,
            uint256 totalSupply,
            uint256 price,
            address beneficiary,
            string memory metadata,
            string memory contentHash

        ) = DGAccessories(_accessoriesContract).items(_itemId);

        emit SupplyCheck(
            rarity,
            maxSupply,
            price,
            beneficiary,
            metadata,
            contentHash
        );

        return totalSupply;
    }

    function _takePayment(
        address _payer,
        uint256 _dgAmount,
        uint256 _iceAmount
    )
        internal
    {
        if (_dgAmount > 0) {
            safeTransferFrom(
                tokenAddressDG,
                _payer,
                depositAddressDG,
                _dgAmount
            );
        }

        if (_iceAmount > 0) {
            safeTransferFrom(
                tokenAddressICE,
                _payer,
                address(this),
                _iceAmount
            );

            ERC20 iceToken = ERC20(tokenAddressICE);
            iceToken.burn(_iceAmount);
        }
    }

    function getLevel(
        address _tokenOwner,
        bytes32 _tokenHash
    )
        public
        view
        returns (uint256)
    {
        return registrer[_tokenOwner][_tokenHash].level;
    }

    function getLevelById(
        address _tokenOwner,
        address _tokenAddress,
        uint256 _tokenId
    )
        public
        view
        returns (uint256)
    {
        bytes32 tokenHash = getHash(
            _tokenAddress,
            _tokenId
        );

        return registrer[_tokenOwner][tokenHash].level;
    }

    function getIceBonus(
        address _tokenOwner,
        address _tokenAddress,
        uint256 _tokenId
    )
        public
        view
        returns (uint256)
    {
        bytes32 tokenHash = getHash(
            _tokenAddress,
            _tokenId
        );

        return registrer[_tokenOwner][tokenHash].bonus;
    }

    function isIceEnabled(
        address _tokenOwner,
        address _tokenAddress,
        uint256 _tokenId
    )
        public
        view
        returns (bool)
    {
        uint256 iceBonus = getIceBonus(
            _tokenOwner,
            _tokenAddress,
            _tokenId
        );

        return iceBonus > 0;
    }

    function canPurchaseAgain(
        address _minterAddress
    )
        public
        view
        returns (bool)
    {
        return block.timestamp - frames[_minterAddress] > saleFrame;
    }

    function getHash(
        address _tokenAddress,
        uint256 _tokenId
    )
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(
            _tokenAddress,
            _tokenId
        ));
    }

    function getNumber(
        uint256 _floorValue,
        uint256 _deltaValue,
        uint256 _nonceValue,
        uint256 _randomValue
    )
        public
        pure
        returns (uint256)
    {
        return _floorValue + uint256(keccak256(abi.encodePacked(_nonceValue, _randomValue))) % (_deltaValue + 1);
    }
}