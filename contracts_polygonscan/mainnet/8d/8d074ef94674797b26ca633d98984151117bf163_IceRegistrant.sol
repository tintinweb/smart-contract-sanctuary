/**
 *Submitted for verification at polygonscan.com on 2021-09-24
*/

// SPDX-License-Identifier: -- 💎 --

pragma solidity ^0.8.7;

contract EIP712Base {

    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256(bytes("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"));
    bytes32 internal domainSeperator;

    constructor(string memory name, string memory version) {
        domainSeperator = keccak256(abi.encode(
			EIP712_DOMAIN_TYPEHASH,
			keccak256(bytes(name)),
			keccak256(bytes(version)),
			getChainID(),
			address(this)
		));
    }

    function getChainID() internal pure returns (uint256 id) {
		assembly {
			id := 1 // set to Goerli for now, Mainnet later
		}
	}

    function getDomainSeperator() private view returns(bytes32) {
		return domainSeperator;
	}

    /**
    * Accept message hash and returns hash message in EIP712 compatible form
    * So that it can be used to recover signer from signature signed using EIP712 formatted data
    * https://eips.ethereum.org/EIPS/eip-712
    * "\\x19" makes the encoding deterministic
    * "\\x01" is the version byte to make it compatible to EIP-191
    */
    function toTypedMessageHash(bytes32 messageHash) internal view returns(bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeperator(), messageHash));
    }
}

abstract contract EIP712MetaTransaction is EIP712Base {

    bytes32 private constant META_TRANSACTION_TYPEHASH =
        keccak256(
            bytes(
                "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
            )
        );

    event MetaTransactionExecuted(
        address userAddress,
        address payable relayerAddress,
        bytes functionSignature
    );

    mapping(address => uint256) internal nonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
		uint256 nonce;
		address from;
        bytes functionSignature;
	}

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    )
        public
        payable
        returns(bytes memory)
    {
        MetaTransaction memory metaTx = MetaTransaction(
            {
                nonce: nonces[userAddress],
                from: userAddress,
                functionSignature: functionSignature
            }
        );

        require(
            verify(
                userAddress,
                metaTx,
                sigR,
                sigS,
                sigV
            ), "Signer and signature do not match"
        );

	    nonces[userAddress] =
	    nonces[userAddress] + 1;

        // Append userAddress at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(
                functionSignature,
                userAddress
            )
        );

        require(
            success,
            'Function call not successful'
        );

        emit MetaTransactionExecuted(
            userAddress,
            payable(msg.sender),
            functionSignature
        );

        return returnData;
    }

    function hashMetaTransaction(
        MetaTransaction memory metaTx
    )
        internal
        pure
        returns (bytes32)
    {
		return keccak256(
		    abi.encode(
                META_TRANSACTION_TYPEHASH,
                metaTx.nonce,
                metaTx.from,
                keccak256(metaTx.functionSignature)
            )
        );
	}

    function verify(
        address user,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    )
        internal
        view
        returns (bool)
    {
        address signer = ecrecover(
            toTypedMessageHash(
                hashMetaTransaction(metaTx)
            ),
            sigV,
            sigR,
            sigS
        );

        require(
            signer != address(0x0),
            'Invalid signature'
        );
		return signer == user;
	}

    function msgSender() internal view returns(address sender) {
        if(msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }
}

contract AccessController {

    address public ceoAddress;

    mapping (address => bool) public isWorker;

    event CEOSet(
        address newCEO
    );

    event WorkerAdded(
        address newWorker
    );

    event WorkerRemoved(
        address existingWorker
    );

    constructor() {

        address creator = msg.sender;

        ceoAddress = creator;

        isWorker[creator] = true;

        emit CEOSet(
            creator
        );

        emit WorkerAdded(
            creator
        );
    }

    modifier onlyCEO() {
        require(
            msg.sender == ceoAddress,
            'AccessControl: CEO access denied'
        );
        _;
    }

    modifier onlyWorker() {
        require(
            isWorker[msg.sender] == true,
            'AccessControl: worker access denied'
        );
        _;
    }

    modifier nonZeroAddress(address checkingAddress) {
        require(
            checkingAddress != address(0x0),
            'AccessControl: invalid address'
        );
        _;
    }

    function setCEO(
        address _newCEO
    )
        external
        nonZeroAddress(_newCEO)
        onlyCEO
    {
        ceoAddress = _newCEO;

        emit CEOSet(
            ceoAddress
        );
    }

    function addWorker(
        address _newWorker
    )
        external
        onlyCEO
    {
        _addWorker(
            _newWorker
        );
    }

    function addWorkerBulk(
        address[] calldata _newWorkers
    )
        external
        onlyCEO
    {
        for (uint8 index = 0; index < _newWorkers.length; index++) {
            _addWorker(_newWorkers[index]);
        }
    }

    function _addWorker(
        address _newWorker
    )
        internal
        nonZeroAddress(_newWorker)
    {
        require(
            isWorker[_newWorker] == false,
            'AccessControl: worker already exist'
        );

        isWorker[_newWorker] = true;

        emit WorkerAdded(
            _newWorker
        );
    }

    function removeWorker(
        address _existingWorker
    )
        external
        onlyCEO
    {
        _removeWorker(
            _existingWorker
        );
    }

    function removeWorkerBulk(
        address[] calldata _workerArray
    )
        external
        onlyCEO
    {
        for (uint8 index = 0; index < _workerArray.length; index++) {
            _removeWorker(_workerArray[index]);
        }
    }

    function _removeWorker(
        address _existingWorker
    )
        internal
        nonZeroAddress(_existingWorker)
    {
        require(
            isWorker[_existingWorker] == true,
            "AccessControl: worker not detected"
        );

        isWorker[_existingWorker] = false;

        emit WorkerRemoved(
            _existingWorker
        );
    }
}

contract TransferHelper {

    bytes4 private constant TRANSFER = bytes4(
        keccak256(
            bytes(
                'transfer(address,uint256)' // 0xa9059cbb
            )
        )
    );

    bytes4 private constant TRANSFER_FROM = bytes4(
        keccak256(
            bytes(
                'transferFrom(address,address,uint256)' // 0x23b872dd
            )
        )
    );

    function safeTransfer(
        address _token,
        address _to,
        uint256 _value
    )
        internal
    {
        (bool success, bytes memory data) = _token.call(
            abi.encodeWithSelector(
                TRANSFER, // 0xa9059cbb
                _to,
                _value
            )
        );

        require(
            success && (
                data.length == 0 || abi.decode(
                    data, (bool)
                )
            ),
            'TransferHelper: TRANSFER_FAILED'
        );
    }

    function safeTransferFrom(
        address _token,
        address _from,
        address _to,
        uint _value
    )
        internal
    {
        (bool success, bytes memory data) = _token.call(
            abi.encodeWithSelector(
                TRANSFER_FROM,
                _from,
                _to,
                _value
            )
        );

        require(
            success && (
                data.length == 0 || abi.decode(
                    data, (bool)
                )
            ),
            'TransferHelper: TRANSFER_FROM_FAILED'
        );
    }

}

interface ERC721 {

    function ownerOf(
        uint256 _tokenId
    )
        external
        view
        returns (address);

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;
}

interface ERC20 {

    function burn(
        uint256 _amount
    )
        external;
}

interface DGAccessories  {

    function issueTokens(
        address[] calldata _beneficiaries,
        uint256[] calldata _itemIds
    )
        external;

    function encodeTokenId(
        uint256 _itemId,
        uint256 _issuedId
    )
        external
        pure
        returns (uint256 id);

    function decodeTokenId(
        uint256 _tokenId
    )
        external
        pure
        returns (
            uint256 itemId,
            uint256 issuedId
        );

    function items(
        uint256 _id
    )
        external
        view
        returns (
            string memory rarity,
            uint256 maxSupply,
            uint256 totalSupply,
            uint256 price,
            address beneficiary,
            string memory metadata,
            string memory contentHash
        );

    function itemsCount()
        external
        view
        returns (uint256);
}

contract Events {

    event Proceed(
        uint256 indexed itemId,
        address indexed minterAddress
    );

    event TokenUpgrade(
        address indexed tokenOwner,
        address indexed tokenAddress,
        uint256 indexed tokenId,
        uint256 upgradeLevel
    );

    event UpgradeRequest(
        uint256 indexed itemId,
        uint256 issuedId,
        address tokenOwner,
        address tokenAddress,
        uint256 indexed tokenId,
        uint256 indexed requestIndex
    );

    event UpgradeCancel(
        address indexed tokenOwner,
        address indexed tokenAddress,
        uint256 indexed tokenId,
        uint256 upgradeIndex
    );

    event UpgradeResolved(
        address indexed tokenOwner,
        uint256 indexed upgradeIndex
    );

    event Delegated (
        uint256 tokenId,
        address indexed tokenAddress,
        address indexed delegateAddress,
        uint256 delegatePercent,
        address indexed tokenOwner
    );

    event LevelEdit(
        uint256 indexed level,
        uint256 dgCostAmount,
        uint256 iceCostAmount,
        uint256 dgReRollAmount,
        uint256 iceReRollAmount,
        bool isActive
    );

    event IceLevelTransfer(
        address oldOwner,
        address indexed newOwner,
        address indexed tokenAddress,
        uint256 indexed tokenId
    );

    event InitialMinting(
        uint256 indexed tokenId,
        uint256 indexed mintCount,
        address indexed tokenOwner
    );

    event SupplyCheck(
        string rarity,
        uint256 maxSupply,
        uint256 price,
        address indexed beneficiary,
        string indexed metadata,
        string indexed contentHash
    );
}

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

    struct Delegate {
        address delegateAddress;
        uint256 delegatePercent;
    }

    mapping (address => address) public targets;

    mapping (address => uint256) public frames;
    mapping (uint256 => uint256) public limits;

    mapping (uint256 => Level) public levels;
    mapping (uint256 => Request) public requests;

    mapping (address => mapping (bytes32 => Upgrade)) public registrer;
    mapping (address => mapping (bytes32 => Delegate)) public delegate;

    constructor(
        uint256 _mintingPrice,
        address _paymentToken,
        address _tokenAddressDG,
        address _tokenAddressICE,
        address _accessoriesContract
    )
        EIP712Base('IceRegistrant', 'v1.1')
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

    function triggerEvent(
        uint256 _itemId
    )
        external
    {
        emit Proceed(
            _itemId,
            msgSender()
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

    function requestUpgrade(
        address _tokenAddress,
        uint256 _tokenId
    )
        external
        returns (uint256 requestIndex)
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

        requestIndex = upgradeRequestCount;

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

        emit UpgradeRequest(
            itemId,
            issuedId,
            tokenOwner,
            _tokenAddress,
            _tokenId,
            requestIndex
        );
    }

    function cancelUpgrade(
        uint256 _requestIndex
    )
        external
    {
        uint256 tokenId = requests[_requestIndex].tokenId;
        address tokenAddress = requests[_requestIndex].tokenAddress;
        address tokenOwner = requests[_requestIndex].tokenOwner;

        require(
            msgSender() == tokenOwner,
            'iceRegistrant: invalid owner'
        );

        delete requests[_requestIndex];

        ERC721(tokenAddress).transferFrom(
            address(this),
            tokenOwner,
            tokenId
        );

        emit UpgradeCancel(
            tokenOwner,
            tokenAddress,
            tokenId,
            _requestIndex
        );
    }

    function resolveUpgradeMint(
        uint256 _requestIndex,
        uint256 _itemId
    )
        external
        onlyWorker
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
            tokenOwner,
            _requestIndex
        );
    }

    function resolveUpgradeSend(
        uint256 _requestIndex,
        address _newTokenAddress,
        uint256 _newTokenId
    )
        external
        onlyWorker
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

        bytes32 newHash = getHash(
            _newTokenAddress,
            _newTokenId
        );

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

        ERC721(_newTokenAddress).transferFrom(
            address(this),
            tokenOwner,
            _newTokenId
        );

        emit UpgradeResolved(
            tokenOwner,
            _requestIndex
        );
    }

    function delegateToken(
        address _tokenAddress,
        uint256 _tokenId,
        address _delegateAddress,
        uint256 _delegatePercent
    )
        external
    {
        ERC721 tokenNFT = ERC721(_tokenAddress);
        address tokenOwner = msgSender();

        require(
            tokenNFT.ownerOf(_tokenId) == tokenOwner,
            'iceRegistrant: invalid owner'
        );

        require(
            _delegatePercent <= 100,
            'iceRegistrant: invalid percent'
        );

        bytes32 tokenHash = getHash(
            _tokenAddress,
            _tokenId
        );

        delegate[tokenOwner][tokenHash].delegateAddress = _delegateAddress;
        delegate[tokenOwner][tokenHash].delegatePercent = _delegatePercent;

        emit Delegated(
            _tokenId,
            _tokenAddress,
            _delegateAddress,
            _delegatePercent,
            tokenOwner
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

        emit IceLevelTransfer(
            _oldOwner,
            newOwner,
            _tokenAddress,
            _tokenId
        );
    }

    function adjustDelegateEntry(
        address _tokenOwner,
        address _tokenAddress,
        uint256 _tokenId,
        address _delegateAddress,
        uint256 _delegatePercent
    )
        external
        onlyWorker
    {
        bytes32 tokenHash = getHash(
            _tokenAddress,
            _tokenId
        );

        require(
            _delegatePercent <= 100,
            'iceRegistrant: invalid percent'
        );

        delegate[_tokenOwner][tokenHash].delegateAddress = _delegateAddress;
        delegate[_tokenOwner][tokenHash].delegatePercent = _delegatePercent;
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