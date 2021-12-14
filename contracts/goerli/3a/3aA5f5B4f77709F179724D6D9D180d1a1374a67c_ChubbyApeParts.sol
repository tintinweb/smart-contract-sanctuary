// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./PartsTokensMetadata.sol";
import "./ChubbyApeEquipmentsId.sol";

interface IChubbyMetalApe {
    function getMetalApeByPairing(uint256 _metalApeTokenId)
        external
        view
        returns (bool);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function totalSupply() external returns (uint256);

    // function mintToAccount(
    //     address _itemAddress,
    //     address _account,
    //     uint256[] memory _itemIds
    // ) external;

    function mintMetalApe(
        uint256 _chubbyApeTokenId,
        address _targetAddress,
        address _itemAddress,
        uint256[] memory _itemIds
    ) external;

    function mintMetalApeThroughPairing(
        uint256 _leftPairId,
        uint256 _rightPairId,
        address _targetAddress,
        address _itemAddress,
        uint256[] memory _itemIds
    ) external returns (uint256 newMetalApeId);
}

// library Errors {
//     string constant DoesNotOwnChubbyApeParts =
//         "you do not own the Chubby Ape Parts for this airdrop";
//     string constant IsNotChubbyApeParts =
//         "msg.sender is not the Chubby Ape Parts contract";
// }

/// @title ChubbyApeParts Tokens
/// @author ChubbyApe
/// @notice Allows "opening" your ERC721 Loot bags and extracting the items inside it
/// The created tokens are ERC1155 compatible, and their on-chain SVG is their name
contract ChubbyApeParts is Ownable, ERC1155, PartsTokensMetadata {
    using SafeMath for uint256;

    // The Chubby Ape contract
    IERC721Enumerable immutable chubbyApe;
    IChubbyMetalApe immutable chubbyMetalApe;

    // Track declared Parts components
    mapping(uint256 => bool) public declaredByTokenId;

    // Track MetalApe declared Basic equipment
    mapping(uint256 => bool) public declareBasicEquipmentByMetalApeTokenId;

    //紀錄用戶有沒有用ChubbyApe的token id免費領過
    //mapping(uint256 => bool) minted;
    mapping(uint256 => uint256) freeMintedRecord;

    //用戶可以免費兌換的次數
    uint256 public acquireNumberLimit = 2;

    //紀錄用戶有沒有用ChubbyApe的token id 產生過一隻MetalApe
    mapping(uint256 => bool) mintedMetalApeApe;

    //mapping(address => bool) minted;
    //mapping(address => uint256) purchased;

    //uint256 public MAX_SUPPLY = 10000;
    uint256 public MAX_NFT_PURCHASE = 50;
    uint256 public NFT_PRICE = 60000000000000000; // 0.06 ETH

    // tokenIdStart of 0 is based on the following lines in the Loot contract:
    /**
    function claim(uint256 tokenId) public nonReentrant {
        require(tokenId > 0 && tokenId < 7778, "Token ID invalid");
        _safeMint(_msgSender(), tokenId);
    }
    */
    uint256 public tokenIdStart = 0;

    /**
    這是用來宣告上一個亂數種子
     */
    uint256 public declareSeed = 0;

    // tokenIdEnd of 8000 is based on the following lines in the Loot contract:
    /**
        function ownerClaim(uint256 tokenId) public nonReentrant onlyOwner {
        require(tokenId > 7777 && tokenId < 8001, "Token ID invalid");
        _safeMint(owner(), tokenId);
    }
    */
    uint256 public tokenIdEnd = 10000;

    //Basic equipment id
    uint256 public basicEquipmentTokenId = 4;

    address payable _incomeWallet;

    bool public saleIsActive = true;

    modifier mintOnlyExchangeLimit(uint256 _chubbyApeTokenId) {
        require(
            freeMintedRecord[_chubbyApeTokenId] < acquireNumberLimit,
            "Mint equipment limit"
        );
        freeMintedRecord[_chubbyApeTokenId] += 1;
        _;
    }

    modifier mintMetalApeOnlyOnce(uint256 _chubbyApeTokenId) {
        require(!mintedMetalApeApe[_chubbyApeTokenId], "Only mint once");
        mintedMetalApeApe[_chubbyApeTokenId] = true;
        _;
    }

    //檢查每一個裝備的類型
    modifier checkEquipmentType(uint256[] memory ids) {
        //檢查每一個裝備的類型
        (, uint256 _itemType0) = TokenId.fromId(ids[0]);
        (, uint256 _itemType1) = TokenId.fromId(ids[1]);
        (, uint256 _itemType2) = TokenId.fromId(ids[2]);
        (, uint256 _itemType3) = TokenId.fromId(ids[3]);
        (, uint256 _itemType4) = TokenId.fromId(ids[4]);
        (, uint256 _itemType5) = TokenId.fromId(ids[5]);
        (, uint256 _itemType6) = TokenId.fromId(ids[6]);

        require(_itemType0 == WEAPON, "Must be weapon");
        require(_itemType1 == CHEST, "Must be chest");
        require(_itemType2 == HEAD, "Must be head");
        require(_itemType3 == WAIST, "Must be waist");
        require(_itemType4 == FOOT, "Must be foot");
        require(_itemType5 == HAND, "Must be hand");
        require(_itemType6 == NECK, "Must be neck");
        _;
    }

    constructor(
        address payable _newincomeWallet,
        address _chubbyApeAddress,
        address _chubbyMetalApeAddress,
        string memory _baseURI
    ) ERC1155("") PartsTokensMetadata(_baseURI) {
        //chubbyApeParts = IERC721Enumerable(_chubbyApeParts);
        _incomeWallet = _newincomeWallet;
        chubbyApe = IERC721Enumerable(_chubbyApeAddress);
        chubbyMetalApe = IChubbyMetalApe(_chubbyMetalApeAddress);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155)
        returns (bool)
    {
        return
            interfaceId == ChubbyApeEquipmentsId.INTERFACE_ID ||
            super.supportsInterface(interfaceId);
    }

    /***
    把裝備傳到MEtalApe的合約裡面 chubbyMetalApe
     */
    // function _equipmentToMetalApeContract(
    //     address from,
    //     uint256[] memory ids,
    //     uint256[] memory amounts
    // ) internal checkEquipmentType(ids) {
    //     require(
    //         from == _msgSender() || isApprovedForAll(from, _msgSender()),
    //         "ERC1155: caller is not owner nor approved"
    //     );

    //     address operator = _msgSender();
    //     address to = address(chubbyMetalApe);
    //     _beforeTokenTransfer(operator, from, to, ids, amounts, "");

    //     for (uint256 i = 0; i < ids.length; ++i) {
    //         uint256 id = ids[i];
    //         uint256 amount = amounts[i];
    //         uint256 fromBalance = _balances[id][from];
    //         require(
    //             fromBalance >= amount,
    //             "ERC1155: insufficient balance for transfer"
    //         );

    //         //移除自己
    //         _balances[id][from] = fromBalance - 1;

    //         //安裝到合約
    //         _balances[id][to] += 1;
    //     }
    //     emit TransferBatch(operator, to, address(chubbyMetalApe), ids, amounts);
    // }

    /***
    Declare From MetalApe  
     */
    function _declareBasicEquipmentToMetalApe(address to)
        internal
        returns (uint256[] memory _itemIds)
    {
        require(to != address(0), "ERC1155: mint to the zero address");

        uint256[] memory ids = new uint256[](7);
        uint256[] memory amounts = new uint256[](7);
        ids[0] = itemId(basicEquipmentTokenId, weaponComponents, WEAPON);
        ids[1] = itemId(basicEquipmentTokenId, chestComponents, CHEST);
        ids[2] = itemId(basicEquipmentTokenId, headComponents, HEAD);
        ids[3] = itemId(basicEquipmentTokenId, waistComponents, WAIST);
        ids[4] = itemId(basicEquipmentTokenId, footComponents, FOOT);
        ids[5] = itemId(basicEquipmentTokenId, handComponents, HAND);
        ids[6] = itemId(basicEquipmentTokenId, neckComponents, NECK);

        for (uint256 i = 0; i < ids.length; i++) {
            amounts[i] = 1;
            _balances[ids[i]][to] += 1;
        }
        emit TransferBatch(_msgSender(), address(0), to, ids, amounts);

        return ids;
    }

    /// @notice Declare all components for Parts. Performs safety checks
    function _declare(address to) internal returns (uint256[] memory ids) {
        require(to != address(0), "ERC1155: mint to the zero address");

        //generate random number
        uint256 rand = random(declareSeed);
        uint256 declareId = rand % 10001;

        ids = new uint256[](7);
        uint256[] memory amounts = new uint256[](7);
        ids[0] = itemId(declareId, weaponComponents, WEAPON);
        ids[1] = itemId(declareId, chestComponents, CHEST);
        ids[2] = itemId(declareId, headComponents, HEAD);
        ids[3] = itemId(declareId, waistComponents, WAIST);
        ids[4] = itemId(declareId, footComponents, FOOT);
        ids[5] = itemId(declareId, handComponents, HAND);
        ids[6] = itemId(declareId, neckComponents, NECK);

        require(
            ids.length == amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );

        address operator = _msgSender();

        for (uint256 i = 0; i < ids.length; i++) {
            amounts[i] = 1;
            _balances[ids[i]][to] += 1;
        }
        emit TransferBatch(operator, address(0), to, ids, amounts);

        //完成宣告
        declareSeed = declareId;

        return ids;
    }

    function itemId(
        uint256 tokenId,
        function(uint256) view returns (uint256[5] memory) componentsFn,
        uint256 itemType
    ) private view returns (uint256) {
        uint256[5] memory components = componentsFn(tokenId);
        return TokenId.toId(components, itemType);
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return tokenURI(tokenId);
    }

    /** BasicEquipmentTokenId settings*/
    function setBasicEquipmentTokenId(uint256 _basicEquipmentTokenId)
        public
        onlyOwner
    {
        basicEquipmentTokenId = _basicEquipmentTokenId;
    }

    /**
    買包功能 au04
    取得一套裝備
     */
    //** Provided to users who hold ChubbyApe token to mint */
    function mintChubbyApeEquipmentForFree(uint256 _chubbyApeTokenId)
        external
        mintOnlyExchangeLimit(_chubbyApeTokenId)
    {
        require(saleIsActive, "Mint is not active");

        require(
            msg.sender == chubbyApe.ownerOf(_chubbyApeTokenId),
            "Must own Chubby Ape token"
        );

        //取得一套裝備
        _declare(msg.sender);
    }

    //單純取得7個裝備
    function mintChubbyApeEquipments(uint256 numberOfDeclare) public payable {
        require(saleIsActive, "Mint is not active");

        require(
            numberOfDeclare <= MAX_NFT_PURCHASE,
            "Can only mint up to specific quantity"
        );
        require(
            numberOfDeclare > 0,
            "Number of tokens can not be less than or equal to 0"
        );
        require(
            NFT_PRICE.mul(numberOfDeclare) == msg.value,
            "Sent ether value is incorrect"
        );

        for (uint256 i = 0; i < numberOfDeclare; i++) {
            _declare(_msgSender());
        }

        _incomeWallet.transfer(msg.value);
    }

    /**
     自帶裝備 ; 
    1. 把自己的裝備轉給合約
    2.一定要用chubbyApe來產生出一隻MetalApe
     */
    function mintMetalApeThenEquipment(
        uint256 _chubbyApeTokenId,
        uint256[] memory _itemIds
    )
        public
        mintMetalApeOnlyOnce(_chubbyApeTokenId)
        checkEquipmentType(_itemIds)
    {
        require(saleIsActive, "Mint is not active");
        require(
            _msgSender() == chubbyApe.ownerOf(_chubbyApeTokenId),
            "Must own Chubby Ape token"
        );

        //產生出一個MetalApe然後記錄裝備
        chubbyMetalApe.mintMetalApe(
            _chubbyApeTokenId,
            _msgSender(),
            address(this),
            _itemIds
        );

        // uint256[] memory amounts = new uint256[](7);
        // amounts[0] = 1;
        // amounts[1] = 1;
        // amounts[2] = 1;
        // amounts[3] = 1;
        // amounts[4] = 1;
        // amounts[5] = 1;
        // amounts[6] = 1;
        // _equipmentToMetalApeContract(_msgSender(), _itemIds, amounts);
    }

    /**
     自帶兩個MetalApe  ; 
    1. left Id ,right Id
     */
    function mintMetalApeThroughPairingThenPutOn(
        uint256 _leftPairId,
        uint256 _rightPairId,
        uint256[] memory _itemIds
    ) public checkEquipmentType(_itemIds) {
        require(saleIsActive, "Mint is not active");
        require(
            msg.sender == chubbyMetalApe.ownerOf(_leftPairId) &&
                msg.sender == chubbyMetalApe.ownerOf(_rightPairId),
            "Must own Chubby Ape token"
        );

        //產生出一個MetalApe然後記錄裝備
        chubbyMetalApe.mintMetalApeThroughPairing(
            _leftPairId,
            _rightPairId,
            msg.sender,
            address(this),
            _itemIds
        );

        // uint256[] memory amounts = new uint256[](7);
        // amounts[0] = 1;
        // amounts[1] = 1;
        // amounts[2] = 1;
        // amounts[3] = 1;
        // amounts[4] = 1;
        // amounts[5] = 1;
        // amounts[6] = 1;
        // _equipmentToMetalApeContract(_msgSender(), _itemIds, amounts);
    }

    /**

     自帶兩個MetalApe  ; 
    1. left Id ,right Id
     */
    function mintMetalApeThroughPairingAndGetEquipmentThenPutOn(
        uint256 _leftPairId,
        uint256 _rightPairId
    ) external {
        require(saleIsActive, "Mint is not active");
        require(
            msg.sender == chubbyMetalApe.ownerOf(_leftPairId) &&
                msg.sender == chubbyMetalApe.ownerOf(_rightPairId),
            "Must own Chubby Ape token"
        );

        //產生基礎裝備
        uint256[] memory _itemIds = _declareBasicEquipmentToMetalApe(
            msg.sender
        );

        //產生出一個MetalApe然後記錄裝備
        chubbyMetalApe.mintMetalApeThroughPairing(
            _leftPairId,
            _rightPairId,
            msg.sender,
            address(this),
            _itemIds
        );
    }

    /**---------------------
    Setting
     *----------------------/ 
    /** NFT_PRICE settings*/
    function getNFT_PRICE() public view returns (uint256) {
        return NFT_PRICE;
    }

    function setNFT_PRICE(uint256 _NFT_PRICE) public onlyOwner {
        NFT_PRICE = _NFT_PRICE;
    }

    /** IncomeWallet settings*/
    function incomeWallet() public view returns (address) {
        return _incomeWallet;
    }

    function setIncomeWallet(address payable _nextincomeWallet)
        public
        onlyOwner
    {
        _incomeWallet = _nextincomeWallet;
    }

    /** MAX_NFT_PURCHASE settings*/
    function setMAX_NFT_PURCHASE(uint256 _MAX_NFT_PURCHASE) public onlyOwner {
        MAX_NFT_PURCHASE = _MAX_NFT_PURCHASE;
    }

    /** saleIsActive settings*/
    function switchSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    /** ExchangeNumberLimit settings*/
    function setAcquireNumberLimit(uint256 _acquireNumberLimit)
        public
        onlyOwner
    {
        acquireNumberLimit = _acquireNumberLimit;
    }

    /**---------------------
    Helper
     *----------------------/ 
    /**
     * generates a pseudorandom number
     * @param seed a value ensure different outcomes for different sources in the same block
     * @return a pseudorandom value
     */
    function random(uint256 seed) internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        tx.origin,
                        blockhash(block.number - 1),
                        block.timestamp,
                        seed
                    )
                )
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) internal _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
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
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            account != address(0),
            "ERC1155: balance query for the zero address"
        );
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(
            accounts.length == ids.length,
            "ERC1155: accounts and ids length mismatch"
        );

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        require(
            _msgSender() != operator,
            "ERC1155: setting approval status for self"
        );

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
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
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
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
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(
            operator,
            from,
            to,
            _asSingletonArray(id),
            _asSingletonArray(amount),
            data
        );

        uint256 fromBalance = _balances[id][from];
        require(
            fromBalance >= amount,
            "ERC1155: insufficient balance for transfer"
        );
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(
            ids.length == amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(
                fromBalance >= amount,
                "ERC1155: insufficient balance for transfer"
            );
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            from,
            to,
            ids,
            amounts,
            data
        );
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
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(
            operator,
            address(0),
            account,
            _asSingletonArray(id),
            _asSingletonArray(amount),
            data
        );

        _balances[id][account] += amount;
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(
            operator,
            address(0),
            account,
            id,
            amount,
            data
        );
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
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(
            ids.length == amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            address(0),
            to,
            ids,
            amounts,
            data
        );
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(
            operator,
            account,
            address(0),
            _asSingletonArray(id),
            _asSingletonArray(amount),
            ""
        );

        uint256 accountBalance = _balances[id][account];
        require(
            accountBalance >= amount,
            "ERC1155: burn amount exceeds balance"
        );
        unchecked {
            _balances[id][account] = accountBalance - amount;
        }

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(
            ids.length == amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 accountBalance = _balances[id][account];
            require(
                accountBalance >= amount,
                "ERC1155: burn amount exceeds balance"
            );
            unchecked {
                _balances[id][account] = accountBalance - amount;
            }
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
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155Received(
                    operator,
                    from,
                    id,
                    amount,
                    data
                )
            returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
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
    ) private {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155BatchReceived(
                    operator,
                    from,
                    ids,
                    amounts,
                    data
                )
            returns (bytes4 response) {
                if (
                    response != IERC1155Receiver.onERC1155BatchReceived.selector
                ) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element)
        private
        pure
        returns (uint256[] memory)
    {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

/// @title Encoding / decoding utilities for token ids
/// @author Georgios Konstantopoulos
/// @dev Token ids are generated from the components via a bijective encoding
/// using the token type and its attributes. We shift left by 16 bits, i.e. 2 bytes
/// each time so that the IDs do not overlap, assuming that components are smaller than 256
library TokenId {
    // 2 bytes
    uint256 constant SHIFT = 16;

    /// Encodes an array of Loot components and an item type (weapon, chest etc.)
    /// to a token id
    function toId(uint256[5] memory components, uint256 itemType)
        internal
        pure
        returns (uint256)
    {
        uint256 id = itemType;
        id += encode(components[0], 1);
        id += encode(components[1], 2);
        id += encode(components[2], 3);
        id += encode(components[3], 4);
        id += encode(components[4], 5);

        return id;
    }

    /// Decodes a token id to an array of Loot components and its item type (weapon, chest etc.)
    function fromId(uint256 id)
        internal
        pure
        returns (uint256[5] memory components, uint256 itemType)
    {
        itemType = decode(id, 0);
        components[0] = decode(id, 1);
        components[1] = decode(id, 2);
        components[2] = decode(id, 3);
        components[3] = decode(id, 4);
        components[4] = decode(id, 5);
    }

    /// Masks the component with 0xff and left shifts it by `idx * 2 bytes
    function encode(uint256 component, uint256 idx)
        private
        pure
        returns (uint256)
    {
        return (component & 0xff) << (SHIFT * idx);
    }

    /// Right shifts the provided token id by `idx * 2 bytes` and then masks the
    /// returned value with 0xff.
    function decode(uint256 id, uint256 idx) private pure returns (uint256) {
        return (id >> (SHIFT * idx)) & 0xff;
    }
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./ApeEquipments.sol";
import "./TokenId.sol";
import "./IChubbyApeEquipments.sol";
import {Base64, toString} from "./MetadataUtils.sol";

struct ItemIds {
    uint256 weapon;
    uint256 chest;
    uint256 head;
    uint256 waist;
    uint256 foot;
    uint256 hand;
    uint256 neck;
}

struct ItemNames {
    string weapon;
    string chest;
    string head;
    string waist;
    string foot;
    string hand;
    string neck;
}

/// @title Helper contract for generating ERC-1155 token ids and descriptions for
/// the individual items inside a Parts.
/// @author Gary Thung, forked from Georgios Konstantopoulos
/// @dev Inherit from this contract and use it to generate metadata for your tokens
contract PartsTokensMetadata is IChubbyApeEquipments, ApeEquipments {
    uint256 internal constant WEAPON = 0x0;
    uint256 internal constant CHEST = 0x1;
    uint256 internal constant HEAD = 0x2;
    uint256 internal constant WAIST = 0x3;
    uint256 internal constant FOOT = 0x4;
    uint256 internal constant HAND = 0x5;
    uint256 internal constant NECK = 0x6;

    string[] internal itemTypes = [
        "weapon",
        "chest",
        "head",
        "waist",
        "foot",
        "hand",
        "neck"
    ];

    string public baseURI;

    constructor(string memory _baseURI) {
        baseURI = _baseURI;
    }

    function name() external pure returns (string memory) {
        return "CAPT";
    }

    function symbol() external pure returns (string memory) {
        return "CAPEP";
    }

    function setBaseURI(string memory _newBaseURI) external {
        baseURI = _newBaseURI;
    }

    /// @notice Returns an SVG for the provided token id
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        "{",
                        '"name": "',
                        nameFor(tokenId),
                        '", ',
                        '"description": "',
                        nameFor(tokenId),
                        "\\n\\n",
                        'MetalApe Equipments are individual equipments that you can trade and use to upgrade your MetalApe. Different combinations of MetalApe equipments unlock special abilities and powers.", ',
                        '"image": ',
                        '"',
                        baseURI,
                        "/",
                        toString(tokenId),
                        '.png", ',
                        '"attributes": ',
                        attributes(tokenId),
                        "}"
                    )
                )
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    /// @notice Returns the attributes associated with this item.
    /// @dev Opensea Standards: https://docs.opensea.io/docs/metadata-standards
    function attributes(uint256 id) public view returns (string memory) {
        (uint256[5] memory components, uint256 itemType) = TokenId.fromId(id);
        // should we also use components[0] which contains the item name?
        string memory slot = itemTypes[itemType];
        string memory res = string(
            abi.encodePacked("[", trait("Item Type", slot))
        );

        string memory item = itemName(itemType, components[0]);
        res = string(abi.encodePacked(res, ", ", trait("Name", item)));

        //Greatness
        string memory data = suffixes[components[1]];
        res = string(abi.encodePacked(res, ", ", trait("Greatness", data)));

        // if (components[1] > 0) {
        //     string memory data = suffixes[components[1] - 1];
        //     res = string(abi.encodePacked(res, ", ", trait("Suffix", data)));
        // }

        // if (components[2] > 0) {
        //     string memory data = namePrefixes[components[2] - 1];
        //     res = string(
        //         abi.encodePacked(res, ", ", trait("Name Prefix", data))
        //     );
        // }

        // if (components[3] > 0) {
        //     string memory data = nameSuffixes[components[3] - 1];
        //     res = string(
        //         abi.encodePacked(res, ", ", trait("Name Suffix", data))
        //     );
        // }

        // if (components[4] > 0) {
        //     res = string(
        //         abi.encodePacked(res, ", ", trait("Augmentation", "Yes"))
        //     );
        // }

        res = string(abi.encodePacked(res, "]"));

        return res;
    }

    /// @notice Returns the item type of this component.
    function itemTypeFor(uint256 id)
        external
        pure
        override
        returns (string memory)
    {
        (, uint256 _itemType) = TokenId.fromId(id);
        return
            ["weapon", "chest", "head", "waist", "foot", "hand", "neck"][
                _itemType
            ];
    }

    // Helper for encoding as json w/ trait_type / value from opensea
    function trait(string memory _traitType, string memory _value)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "{",
                    '"trait_type": "',
                    _traitType,
                    '", ',
                    '"value": "',
                    _value,
                    '"',
                    "}"
                )
            );
    }

    /// @notice Given an ERC1155 token id, it returns its name by decoding and parsing
    /// the id
    function nameFor(uint256 id) public view override returns (string memory) {
        (uint256[5] memory components, uint256 itemType) = TokenId.fromId(id);
        return componentsToString(components, itemType);
    }

    // Returns the "vanilla" item name w/o any prefix/suffixes or augmentations
    function itemName(uint256 itemType, uint256 idx)
        public
        view
        returns (string memory)
    {
        string[] storage arr;
        if (itemType == WEAPON) {
            arr = weapons;
        } else if (itemType == CHEST) {
            arr = chestArmor;
        } else if (itemType == HEAD) {
            arr = headArmor;
        } else if (itemType == WAIST) {
            arr = waistArmor;
        } else if (itemType == FOOT) {
            arr = footArmor;
        } else if (itemType == HAND) {
            arr = handArmor;
        } else if (itemType == NECK) {
            arr = necklaces;
        } else {
            revert("Unexpected armor piece");
        }

        return arr[idx];
    }

    // Creates the token description given its components and what type it is
    function componentsToString(uint256[5] memory components, uint256 itemType)
        public
        view
        returns (string memory)
    {
        // item type: what slot to get
        // components[0] the index in the array
        string memory item = itemName(itemType, components[0]);

        // We need to do -1 because the 'no description' is not part of loot copmonents

        // add the Greatness
        if (components[1] < 16) {
            item = string(abi.encodePacked(item, " ", suffixes[components[1]]));
        }

        // if (components[1] > 0) {
        //     item = string(
        //         abi.encodePacked(item, " ", suffixes[components[1] - 1])
        //     );
        // }

        // // add the name prefix / suffix
        // if (components[2] > 0) {
        //     // prefix
        //     string memory namePrefixSuffix = string(
        //         abi.encodePacked("'", namePrefixes[components[2] - 1])
        //     );
        //     if (components[3] > 0) {
        //         namePrefixSuffix = string(
        //             abi.encodePacked(
        //                 namePrefixSuffix,
        //                 " ",
        //                 nameSuffixes[components[3] - 1]
        //             )
        //         );
        //     }

        //     namePrefixSuffix = string(abi.encodePacked(namePrefixSuffix, "' "));

        //     item = string(abi.encodePacked(namePrefixSuffix, item));
        // }

        // // add the augmentation
        // if (components[4] > 0) {
        //     item = string(abi.encodePacked(item, " +1"));
        // }

        return item;
    }

    // View helpers for getting the item ID that corresponds to a bag's items
    function weaponId(uint256 tokenId) public pure returns (uint256) {
        return TokenId.toId(weaponComponents(tokenId), WEAPON);
    }

    function chestId(uint256 tokenId) public pure returns (uint256) {
        return TokenId.toId(chestComponents(tokenId), CHEST);
    }

    function headId(uint256 tokenId) public pure returns (uint256) {
        return TokenId.toId(headComponents(tokenId), HEAD);
    }

    function waistId(uint256 tokenId) public pure returns (uint256) {
        return TokenId.toId(waistComponents(tokenId), WAIST);
    }

    function footId(uint256 tokenId) public pure returns (uint256) {
        return TokenId.toId(footComponents(tokenId), FOOT);
    }

    function handId(uint256 tokenId) public pure returns (uint256) {
        return TokenId.toId(handComponents(tokenId), HAND);
    }

    function neckId(uint256 tokenId) public pure returns (uint256) {
        return TokenId.toId(neckComponents(tokenId), NECK);
    }

    // Given an erc721 bag, returns the erc1155 token ids of the items in the bag
    function ids(uint256 tokenId) public pure returns (ItemIds memory) {
        return
            ItemIds({
                weapon: weaponId(tokenId),
                chest: chestId(tokenId),
                head: headId(tokenId),
                waist: waistId(tokenId),
                foot: footId(tokenId),
                hand: handId(tokenId),
                neck: neckId(tokenId)
            });
    }

    function idsMany(uint256[] memory tokenIds)
        public
        pure
        returns (ItemIds[] memory)
    {
        ItemIds[] memory itemids = new ItemIds[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            itemids[i] = ids(tokenIds[i]);
        }

        return itemids;
    }

    // Given an ERC721 bag, returns the names of the items in the bag
    function names(uint256 tokenId) public view returns (ItemNames memory) {
        ItemIds memory items = ids(tokenId);
        return
            ItemNames({
                weapon: nameFor(items.weapon),
                chest: nameFor(items.chest),
                head: nameFor(items.head),
                waist: nameFor(items.waist),
                foot: nameFor(items.foot),
                hand: nameFor(items.hand),
                neck: nameFor(items.neck)
            });
    }

    function namesMany(uint256[] memory tokenNames)
        public
        view
        returns (ItemNames[] memory)
    {
        ItemNames[] memory itemNames = new ItemNames[](tokenNames.length);
        for (uint256 i = 0; i < tokenNames.length; i++) {
            itemNames[i] = names(tokenNames[i]);
        }

        return itemNames;
    }
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

function toString(uint256 value) pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
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

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

// Any component stores need to have this function so that Adventurer can determine what
// type of item it is
interface IChubbyApeEquipments {
    function itemTypeFor(uint256 tokenId) external view returns (string memory);

    function nameFor(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

library ChubbyApeEquipmentsId {
    bytes4 internal constant INTERFACE_ID = 0xd35e2fbd;
}

/**
 *Submitted for verification at Etherscan.io on 2021-08-30
 */

// SPDX-License-Identifier: Unlicense

/*

    LootComponents.sol

    This is a utility contract to make it easier for other
    contracts to work with Loot properties.

    Call weaponComponents(), chestComponents(), etc. to get
    an array of attributes that correspond to the item.

    The return format is:

    uint256[5] =>
        [0] = Item ID
        [1] = Suffix ID (0 for none)
        [2] = Name Prefix ID (0 for none)
        [3] = Name Suffix ID (0 for none)
        [4] = Augmentation (0 = false, 1 = true)

    See the item and attribute tables below for corresponding IDs.

*/

pragma solidity ^0.8.0;

contract ApeEquipments {
    string[] internal weapons = [
        "Warhammer", // 0
        "Quarterstaff", // 1
        "Maul", // 2
        "Mace", // 3
        "Club", // 4
        "Katana", // 5
        "Falchion", // 6
        "Scimitar", // 7
        "Long Sword", // 8
        "Short Sword", // 9
        "Ghost Wand", // 10
        "Grave Wand", // 11
        "Bone Wand", // 12
        "Wand" // 13
    ];
    uint256 constant weaponsLength = 14;

    string[] internal chestArmor = [
        "Divine Robe", // 0
        "Silk Robe", // 1
        "Linen Robe", // 2
        "Robe", // 3
        "Shirt", // 4
        "Demon Husk", // 5
        "Dragonskin Armor", // 6
        "Studded Leather Armor", // 7
        "Hard Leather Armor", // 8
        "Leather Armor", // 9
        "Holy Chestplate", // 10
        "Ornate Chestplate", // 11
        "Plate Mail", // 12
        "Chain Mail" // 13
    ];
    uint256 constant chestLength = 14;

    string[] internal headArmor = [
        "Ancient Helm", // 0
        "Ornate Helm", // 1
        "Great Helm", // 2
        "Full Helm", // 3
        "Helm", // 4
        "Demon Crown", // 5
        "Dragon's Crown", // 6
        "War Cap", // 7
        "Leather Cap", // 8
        "Cap", // 9
        "Crown", // 10
        "Divine Hood", // 11
        "Silk Hood", // 12
        "Linen Hood" // 13
    ];
    uint256 constant headLength = 15;

    string[] internal waistArmor = [
        "Ornate Belt", // 0
        "War Belt", // 1
        "Plated Belt", // 2
        "Mesh Belt", // 3
        "Heavy Belt", // 4
        "Demonhide Belt", // 5
        "Dragonskin Belt", // 6
        "Studded Leather Belt", // 7
        "Hard Leather Belt", // 8
        "Leather Belt", // 9
        "Brightsilk Sash", // 10
        "Silk Sash", // 11
        "Wool Sash", // 12
        "Linen Sash" // 13
    ];
    uint256 constant waistLength = 14;

    string[] internal footArmor = [
        "Holy Greaves", // 0
        "Ornate Greaves", // 1
        "Greaves", // 2
        "Chain Boots", // 3
        "Heavy Boots", // 4
        "Demonhide Boots", // 5
        "Dragonskin Boots", // 6
        "Studded Leather Boots", // 7
        "Hard Leather Boots", // 8
        "Leather Boots", // 9
        "Divine Slippers", // 10
        "Silk Slippers", // 11
        "Wool Shoes", // 12
        "Linen Shoes" // 13
    ];
    uint256 constant footLength = 14;

    string[] internal handArmor = [
        "Holy Gauntlets", // 0
        "Ornate Gauntlets", // 1
        "Gauntlets", // 2
        "Chain Gloves", // 3
        "Heavy Gloves", // 4
        "Demon's Hands", // 5
        "Dragonskin Gloves", // 6
        "Studded Leather Gloves", // 7
        "Hard Leather Gloves", // 8
        "Leather Gloves", // 9
        "Divine Gloves", // 10
        "Silk Gloves", // 11
        "Wool Gloves", // 12
        "Linen Gloves" // 13
    ];
    uint256 constant handLength = 14;

    string[] internal necklaces = [
        "Necklace", // 0
        "Amulet", // 1
        "Pendant", // 2
        "Necklace", // 3
        "Amulet", // 4
        "Pendant", // 5
        "Necklace", // 6
        "Amulet", // 7
        "Pendant", // 8
        "Necklace", // 9
        "Amulet", // 10
        "Pendant" // 11
        "Wool Gloves", // 12
        "Linen Gloves" // 13
    ];
    uint256 constant necklacesLength = 14;

    // string[] internal rings = [
    //     "Gold Ring", // 0
    //     "Silver Ring", // 1
    //     "Bronze Ring", // 2
    //     "Platinum Ring", // 3
    //     "Titanium Ring", // 4
    //     "Pendant", // 5
    //     "Necklace", // 6
    //     "Amulet", // 7
    //     "Pendant", // 8
    //     "Necklace", // 9
    //     "Amulet", // 10
    //     "Pendant" // 11
    //     "Wool Gloves", // 12
    //     "Linen Gloves" // 13
    // ];
    // uint256 constant ringsLength = 14;

    // string[] internal suffixes = [
    //     // <no suffix>          // 0
    //     "of Power", // 1
    //     "of Giants", // 2
    //     "of Titans", // 3
    //     "of Skill", // 4
    //     "of Perfection", // 5
    //     "of Brilliance", // 6
    //     "of Enlightenment" // 7 
    // ];
    string[] internal suffixes = [ 
        "of Ultra Rare", // 0
        "of Super Rare", // 1
        "of Rare", // 2
        "of Normal" // 3 
    ];
    uint256 constant suffixesLength = 6;

    // string[] internal namePrefixes = [
    //     // <no name>            // 0
    //     "Agony", // 1
    //     "Apocalypse", // 2
    //     "Armageddon", // 3
    //     "Beast", // 4
    //     "Behemoth", // 5
    //     "Blight", // 6
    //     "Blood" // 7 
    // ];
    // uint256 constant namePrefixesLength = 6;

    // string[] internal nameSuffixes = [
    //     // <no name>            // 0
    //     "Bane", // 1
    //     "Root", // 2
    //     "Bite", // 3
    //     "Song", // 4
    //     "Roar", // 5
    //     "Grasp", // 6
    //     "Instrument" // 7 
    // ];
    // uint256 constant nameSuffixesLength = 6;

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function weaponComponents(uint256 tokenId)
        internal
        pure
        returns (uint256[5] memory)
    {
        return pluck(tokenId, "WEAPON", weaponsLength);
    }

    function chestComponents(uint256 tokenId)
        internal
        pure
        returns (uint256[5] memory)
    {
        return pluck(tokenId, "CHEST", chestLength);
    }

    function headComponents(uint256 tokenId)
        internal
        pure
        returns (uint256[5] memory)
    {
        return pluck(tokenId, "HEAD", headLength);
    }

    function waistComponents(uint256 tokenId)
        internal
        pure
        returns (uint256[5] memory)
    {
        return pluck(tokenId, "WAIST", waistLength);
    }

    function footComponents(uint256 tokenId)
        internal
        pure
        returns (uint256[5] memory)
    {
        return pluck(tokenId, "FOOT", footLength);
    }

    function handComponents(uint256 tokenId)
        internal
        pure
        returns (uint256[5] memory)
    {
        return pluck(tokenId, "HAND", handLength);
    }

    function neckComponents(uint256 tokenId)
        internal
        pure
        returns (uint256[5] memory)
    {
        return pluck(tokenId, "NECK", necklacesLength);
    }

    // function ringComponents(uint256 tokenId)
    //     internal
    //     pure
    //     returns (uint256[5] memory)
    // {
    //     return pluck(tokenId, "RING", ringsLength);
    // }

    function pluck(
        uint256 tokenId,
        string memory keyPrefix,
        uint256 sourceArrayLength
    ) internal pure returns (uint256[5] memory) {
        uint256[5] memory components;

        uint256 rand = random(
            string(abi.encodePacked(keyPrefix, toString(tokenId)))
        );

        components[0] = rand % sourceArrayLength;
        components[1] = 0;
        components[2] = 0;

        // uint256 greatness = rand % 21;
        // if (greatness > 14) {
        //     components[1] = (rand % suffixesLength) + 1;
        // }
        // if (greatness >= 19) {
        //     components[2] = (rand % namePrefixesLength) + 1;
        //     components[3] = (rand % nameSuffixesLength) + 1;
        //     if (greatness == 19) {
        //         // ...
        //     } else {
        //         components[4] = 1;
        //     }
        // }
        uint256 greatness = (rand % 100)+1; //1-100
        if (greatness >= 16 && greatness <= 100) {
            components[1] = 3;
        }else if(greatness >= 6 && greatness <= 15)  {
            components[1] = 2;  
        }else if(greatness >= 2 && greatness <= 5) {
            components[1] = 1;  
        }else if(greatness == 1) {
            components[1] = 0; 
        }
        

        return components;
    }

    // TODO: This costs 2.5k gas per invocation. We call it a lot when minting.
    // How can this be improved?
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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

import "../IERC1155.sol";

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

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
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
    ) external returns (bytes4);

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
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

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
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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