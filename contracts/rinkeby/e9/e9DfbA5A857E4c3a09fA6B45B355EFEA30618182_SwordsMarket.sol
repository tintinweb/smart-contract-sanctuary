// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

/*


   ▄████████  ▄█     █▄   ▄██████▄     ▄████████ ████████▄     ▄████████ 
  ███    ███ ███     ███ ███    ███   ███    ███ ███   ▀███   ███    ███ 
  ███    █▀  ███     ███ ███    ███   ███    ███ ███    ███   ███    █▀  
  ███        ███     ███ ███    ███  ▄███▄▄▄▄██▀ ███    ███   ███        
▀███████████ ███     ███ ███    ███ ▀▀███▀▀▀▀▀   ███    ███ ▀███████████ 
         ███ ███     ███ ███    ███ ▀███████████ ███    ███          ███ 
   ▄█    ███ ███ ▄█▄ ███ ███    ███   ███    ███ ███   ▄███    ▄█    ███ 
 ▄████████▀   ▀███▀███▀   ▀██████▀    ███    ███ ████████▀   ▄████████▀  
                                      ███    ███                         

                       GIMMIX ENTERTAINMENT MMXXI
                       
                               presents...
                               
██████  ██████      ███    ███  █████  ███    ██ ███    ██ ██    ██ ███████ 
     ██      ██     ████  ████ ██   ██ ████   ██ ████   ██  ██  ██  ██      
 █████   █████      ██ ████ ██ ███████ ██ ██  ██ ██ ██  ██   ████   ███████ 
     ██ ██          ██  ██  ██ ██   ██ ██  ██ ██ ██  ██ ██    ██         ██ 
██████  ███████     ██      ██ ██   ██ ██   ████ ██   ████    ██    ███████ 
                                                                            
                  (Manny + Sword (Loot or MLoot) Required)

*/

import {SwordsEvent} from "../SwordsEvent.sol";

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

interface ILootComponents {
    function weaponComponents(uint256 tokenId)
        external
        view
        returns (uint256[5] memory);
}

contract ThirtyTwoMannys is SwordsEvent {
    // * CONSTANTS * //
    uint256 private constant EVENT_ID = 1;
    uint256 private constant MINT_FEE = .25 ether;

    // * STORAGE * //
    address public mannyContract;
    address public lootContract;
    address public mLootContract;
    address public lootComponentsContract;

    // * CONSTRUCTOR (RUNS ON DEPLOY) * //
    constructor(
        address mannyContract_,
        address lootContract_,
        address mLootContract_,
        address lootComponentsContract_,
        address marketContractAddress_,
        address eventBankImplementation_,
        address eventTeamAddress,
        address mannyAddress,
        address domAddress
    )
        SwordsEvent(
            EVENT_ID,
            MINT_FEE,
            eventTeamAddress,
            mannyAddress,
            domAddress,
            marketContractAddress_,
            eventBankImplementation_
        )
    {
        mannyContract = mannyContract_;
        lootContract = lootContract_;
        mLootContract = mLootContract_;
        lootComponentsContract = lootComponentsContract_;

        // Mint Kings
        mintKing(5, domAddress);
        mintKing(29, mannyAddress);
    }

    // * CUSTOM MINT FUNCTIONS * //
    function mint(uint256) public payable override {
        revert("disabled");
    }

    function mint(
        uint256 tokenId,
        uint256 mannyTokenId,
        uint256 lootTokenId
    ) public payable onlyNonKings(tokenId) {
        require(
            IERC721(mannyContract).ownerOf(mannyTokenId) == msg.sender,
            "you dont have this manny"
        );
        require(
            lootTokenId > 8000
                ? IERC721(mLootContract).ownerOf(lootTokenId) == msg.sender
                : IERC721(lootContract).ownerOf(lootTokenId) == msg.sender,
            "you dont have this loot"
        );
        uint256 weapon = ILootComponents(lootComponentsContract)
            .weaponComponents(lootTokenId)[0];

        require(weapon >= 5 && weapon <= 9, "no sword in this loot");

        super.mint(tokenId);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

/*
   ▄████████  ▄█     █▄   ▄██████▄     ▄████████ ████████▄     ▄████████ 
  ███    ███ ███     ███ ███    ███   ███    ███ ███   ▀███   ███    ███ 
  ███    █▀  ███     ███ ███    ███   ███    ███ ███    ███   ███    █▀  
  ███        ███     ███ ███    ███  ▄███▄▄▄▄██▀ ███    ███   ███        
▀███████████ ███     ███ ███    ███ ▀▀███▀▀▀▀▀   ███    ███ ▀███████████ 
         ███ ███     ███ ███    ███ ▀███████████ ███    ███          ███ 
   ▄█    ███ ███ ▄█▄ ███ ███    ███   ███    ███ ███   ▄███    ▄█    ███ 
 ▄████████▀   ▀███▀███▀   ▀██████▀    ███    ███ ████████▀   ▄████████▀  
                                      ███    ███                         

                       GIMMIX ENTERTAINMENT MMXXI
*/

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ISwordsEvent} from "./interfaces/ISwordsEvent.sol";
import {ISwordsMarket} from "./interfaces/ISwordsMarket.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {ERC2981Base} from "./lib/ERC2981Base.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

interface ISwordsEventBank {
    function initialize(address[] memory members_, uint256[] memory shares_)
        external;
}

contract SwordsEvent is
    ERC721,
    ISwordsEvent,
    AccessControl,
    ReentrancyGuard,
    ERC2981Base
{
    // * CONSTANTS * //
    bytes32 public constant PRODUCER = keccak256("PRODUCER");

    // * STORAGE * //
    uint256 public tokensActive;
    uint256 public mintFee;
    uint256 public eventId;
    EventState public state;
    bytes8[] public moves;
    address public marketContract;
    address public eventTeam;
    address public artistW;
    address public artistB;
    address public bankContract;
    mapping(address => uint256) public tokenOwned;
    mapping(uint256 => bool) public prizeClaimed;

    // * MODIFIERS * //
    modifier onlyExistingToken(uint256 tokenId) {
        require(_exists(tokenId), "token doesnt exist");
        _;
    }

    modifier onlyWhileEventActive() {
        require(state == EventState.ACTIVE, "event not active");
        _;
    }
    modifier onlyApprovedOrOwner(address spender, uint256 tokenId) {
        require(_isApprovedOrOwner(spender, tokenId), "not approved or owner");
        _;
    }

    modifier onlyNonKings(uint256 tokenId) {
        require(tokenId != 5 && tokenId != 29, "kings cant be used here");
        _;
    }

    // * CONSTRUCTOR (RUNS ON DEPLOY) * //
    constructor(
        uint256 eventId_,
        uint256 mintFee_,
        address eventTeam_,
        address artistW_,
        address artistB_,
        address marketContract_,
        address eventBankImplementation_
    ) ERC721("32 Swords", "SWORDS") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PRODUCER, _msgSender());
        eventId = eventId_;
        mintFee = mintFee_;
        eventTeam = eventTeam_;
        artistW = artistW_;
        artistB = artistB_;
        marketContract = marketContract_;
        bankContract = Clones.clone(eventBankImplementation_);

        address[] memory bankMembers = new address[](3);
        bankMembers[0] = artistW;
        bankMembers[1] = artistB;
        bankMembers[2] = eventTeam;

        uint256[] memory bankShares = new uint256[](3);
        bankShares[0] = 1;
        bankShares[1] = 1;
        bankShares[2] = 1;
        ISwordsEventBank(bankContract).initialize(bankMembers, bankShares);
    }

    // * PUBLIC PREGAME MINT FUNCTION * //
    function mint(uint256 tokenId)
        public
        payable
        virtual
        onlyNonKings(tokenId)
    {
        require(tokenId >= 1 && tokenId <= 32, "tokenId out of range");
        require(!_exists(tokenId), "token already minted");
        require(msg.value == mintFee, "not right amount of ether");
        require(balanceOf(msg.sender) == 0, "already an owner in this event");
        _safeMint(_msgSender(), tokenId);
        tokensActive++;
    }

    // * START PRODUCER FUNCTIONS * //
    function mintKing(uint256 tokenId, address toAddress)
        public
        virtual
        onlyRole(PRODUCER)
    {
        require(tokenId == 5 || tokenId == 29, "token not a king");
        require(!_exists(tokenId), "token already minted");
        require(balanceOf(toAddress) == 0, "already an owner in this event");
        _safeMint(toAddress, tokenId);
        tokensActive++;
    }

    function startEvent() public virtual onlyRole(PRODUCER) {
        require(state == EventState.PREGAME, "event not in pregame");
        require(tokensActive == 32, "not all pieces have been minted");
        state = EventState.ACTIVE;
        emit EventStateChanged(state, 0);
    }

    function submitMove(bytes8 move)
        public
        virtual
        onlyWhileEventActive
        onlyRole(PRODUCER)
    {
        moves.push(move);
        emit MoveMade(move, moves.length);
    }

    function submitMoveWithCapture(
        bytes8 move,
        uint256 tokenId,
        uint256 capturedBy
    )
        public
        virtual
        onlyWhileEventActive
        onlyRole(PRODUCER)
        onlyExistingToken(tokenId)
        onlyNonKings(tokenId)
    {
        submitMove(move);
        _burn(tokenId);
        tokensActive--;
        emit PieceCaptured(tokenId, capturedBy, moves.length);
    }

    function finishEvent(EventState state_)
        public
        virtual
        onlyWhileEventActive
        onlyRole(PRODUCER)
    {
        require(state_ > EventState.ACTIVE, "must specify valid end state");
        state = state_;
        if (state == EventState.WIN_WHITE) {
            for (uint8 i = 1; i <= 16; i++) {
                if (i == 5) {
                    tokensActive--;
                    continue; // DONT BURN THE KING
                }
                if (_exists(i)) {
                    _burn(i);
                    tokensActive--;
                }
            }
        } else if (state == EventState.WIN_BLACK) {
            for (uint8 i = 17; i <= 32; i++) {
                if (i == 29) {
                    tokensActive--;
                    continue; // DONT BURN THE KING
                }
                if (_exists(i)) {
                    tokensActive--;
                    _burn(i);
                }
            }
        }
        emit EventStateChanged(state, moves.length);
    }

    // * END PRODUCER FUNCTIONS * //

    // * WINNER FUNCTIONS * //
    function claimPrize() public virtual {
        require(state > EventState.ACTIVE, "event not finished");
        require(balanceOf(msg.sender) != 0, "no surviving tokens held");
        uint256 tokenId = tokenOwned[msg.sender];
        require(
            prizeClaimed[tokenId] == false,
            "already claimed for this token"
        );
        require(
            (state == EventState.DRAW ||
                state == EventState.STALEMATE ||
                (state == EventState.WIN_WHITE && tokenId >= 17) ||
                (state == EventState.WIN_BLACK && tokenId <= 16)),
            "not a winner"
        );
        payable(msg.sender).transfer((30 * mintFee) / tokensActive);
        prizeClaimed[tokenId] = true;
        emit PrizeClaimed(tokenId);
    }

    // * ERC721 OVERRIDES * //
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        require(
            to == address(0) || balanceOf(to) == 0,
            "address is already an owner in this event"
        );
        tokenOwned[from] = 0;
        if (to != address(0)) tokenOwned[to] = tokenId;
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        ISwordsMarket(marketContract).removeAsk(eventId, tokenId);
        super._transfer(from, to, tokenId);
    }

    // * START MARKET CONTRACT FUNCTIONS * //
    function exchangeTransfer(uint256 tokenId, address recipient) external {
        require(_msgSender() == marketContract, "only market contract");
        _safeTransfer(ownerOf(tokenId), recipient, tokenId, "");
    }

    function setAsk(uint256 tokenId, uint256 askAmount)
        public
        override
        nonReentrant
        onlyApprovedOrOwner(_msgSender(), tokenId)
    {
        ISwordsMarket(marketContract).setAsk(eventId, tokenId, askAmount);
    }

    function removeAsk(uint256 tokenId)
        external
        override
        nonReentrant
        onlyApprovedOrOwner(_msgSender(), tokenId)
    {
        ISwordsMarket(marketContract).removeAsk(eventId, tokenId);
    }

    function setBid(uint256 tokenId, uint256 bidAmount)
        public
        payable
        nonReentrant
        onlyExistingToken(tokenId)
    {
        require(msg.value == bidAmount, "not enough ether for this bid");
        ISwordsMarket(marketContract).setBid{value: msg.value}(
            eventId,
            tokenId,
            bidAmount,
            _msgSender()
        );
    }

    function removeBid(uint256 tokenId)
        external
        nonReentrant
        onlyExistingToken(tokenId)
    {
        ISwordsMarket(marketContract).removeBid(eventId, tokenId, _msgSender());
    }

    function acceptBid(
        uint256 tokenId,
        uint256 bidAmount,
        address bidder
    ) public nonReentrant onlyApprovedOrOwner(_msgSender(), tokenId) {
        ISwordsMarket(marketContract).acceptBid(
            eventId,
            tokenId,
            bidAmount,
            bidder
        );
    }

    function revokeApproval(uint256 tokenId) external nonReentrant {
        require(
            _msgSender() == getApproved(tokenId),
            "caller not approved address"
        );
        _approve(address(0), tokenId);
    }

    // * END MARKET CONTRACT FUNCTIONS * //

    // * ROYALTIES * //
    function royaltyInfo(uint256, uint256 value)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (bankContract, (value * 500) / 10000); // 5% royalty goes to bank contract
    }

    // * START INTERFACES * //
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControl, ERC721, ERC2981Base)
        returns (bool)
    {
        return
            interfaceId == type(AccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {ISwordsMarket} from "./ISwordsMarket.sol";

interface ISwordsEvent {
    enum EventState {
        PREGAME,
        ACTIVE,
        WIN_WHITE,
        WIN_BLACK,
        STALEMATE,
        DRAW
    }

    event PieceCaptured(
        uint256 captured,
        uint256 capturedBy,
        uint256 turnNumber
    );

    event MoveMade(bytes8 move, uint256 turnNumber);

    event EventStateChanged(EventState state, uint256 turnNumber);

    event PrizeClaimed(uint256 tokenId);

    function exchangeTransfer(uint256 tokenId, address recipient) external;

    function setAsk(uint256 tokenId, uint256 amount) external;

    function removeAsk(uint256 tokenId) external;

    function setBid(uint256 tokenId, uint256 amount) external payable;

    function removeBid(uint256 tokenId) external;

    function acceptBid(
        uint256 tokenId,
        uint256 amount,
        address bidder
    ) external;

    function eventTeam() external view returns (address);

    function artistW() external view returns (address);

    function artistB() external view returns (address);

    function revokeApproval(uint256 tokenId) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

interface ISwordsMarket {
    event BidCreated(
        uint256 indexed eventId,
        uint256 indexed tokenId,
        uint256 amount,
        address bidder
    );
    event BidRemoved(
        uint256 indexed eventId,
        uint256 indexed tokenId,
        uint256 amount,
        address bidder
    );
    event BidFinalized(
        uint256 indexed eventId,
        uint256 indexed tokenId,
        uint256 amount,
        address bidder
    );
    event AskCreated(
        uint256 indexed eventId,
        uint256 indexed tokenId,
        uint256 amount
    );
    event AskRemoved(
        uint256 indexed eventId,
        uint256 indexed tokenId,
        uint256 amount
    );

    function bidForEventTokenBidder(
        uint256 eventId,
        uint256 tokenId,
        address bidder
    ) external view returns (uint256);

    function currentAskForEventToken(uint256 eventId, uint256 tokenId)
        external
        view
        returns (uint256);

    function isValidBid(uint256 bidAmount) external view returns (bool);

    function splitShare(uint256 sharePercentage, uint256 amount)
        external
        pure
        returns (uint256);

    function registerEvent(uint256 eventId, address eventAddress) external;

    function setAsk(
        uint256 eventId,
        uint256 tokenId,
        uint256 amount
    ) external;

    function removeAsk(uint256 eventId, uint256 tokenId) external;

    function setBid(
        uint256 eventId,
        uint256 tokenId,
        uint256 amount,
        address bidder
    ) external payable;

    function removeBid(
        uint256 eventId,
        uint256 tokenId,
        address bidder
    ) external;

    function acceptBid(
        uint256 eventId,
        uint256 tokenId,
        uint256 amount,
        address bidder
    ) external;
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

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
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

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "../interfaces/IERC2981Royalties.sol";

/// @dev This is a contract used to add ERC2981 support to ERC721 and 1155
abstract contract ERC2981Base is ERC165, IERC2981Royalties {
    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC2981Royalties).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @notice Uses Bitpacking to encode royalties into one bytes32 (saves gas)
    /// @return the bytes32 representation
    function encodeRoyalties(address recipient, uint256 amount)
        public
        pure
        returns (bytes32)
    {
        require(amount <= 10000, "!WRONG_AMOUNT!");
        return bytes32((uint256(uint160(recipient)) << 96) + amount);
    }

    /// @notice Uses Bitpacking to decode royalties from a bytes32
    /// @return recipient and amount
    function decodeRoyalties(bytes32 royalties)
        public
        pure
        returns (address recipient, uint256 amount)
    {
        recipient = address(uint160(uint256(royalties) >> 96));
        amount = uint256(uint96(uint256(royalties)));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IERC2981Royalties
/// @dev Interface for the ERC2981 - Token Royalty standard
interface IERC2981Royalties {
    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _value - the sale price of the NFT asset specified by _tokenId
    /// @return _receiver - address of who should be sent the royalty payment
    /// @return _royaltyAmount - the royalty payment amount for value sale price
    function royaltyInfo(uint256 _tokenId, uint256 _value)
        external
        view
        returns (address _receiver, uint256 _royaltyAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
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

// From mannynotfound.eth
// slightly modified to work with openzeppelin v4 and hardhat tests

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract MannysGame is ERC721Enumerable, Ownable {
    using SafeMath for uint256;

    uint16[] mannys;
    bool public mintActive = true;
    bool public goldMannyMinted = false;
    bool public gameWon = false;
    uint256 public gameStart;
    address public gameWinner;

    mapping(address => uint256) public claimedPerWallet;
    uint256 public constant price = 0.1 ether;

    address public constant mannyWallet =
        0xF3A45Ee798fc560CE080d143D12312185f84aa72;
    address public constant vaultWallet =
        0x65861c79fA4249ACc971C229eB52f80A3eDEDedc;

    constructor() ERC721("mannys.game", "MNYGME") {
        gameStart = block.timestamp;

        // token 404 is reserved for game winner so skip it
        for (uint16 i = 1; i <= 1616; i++) {
            if (i != 404) {
                mannys.push(i);
            }
        }

        // mint token 1 to mannys wallet
        mannys[0] = mannys[mannys.length - 1];
        mannys.pop();
        _safeMint(mannyWallet, 1);

        // mint 1 of each token type to vault wallet
        mannys[201] = mannys[mannys.length - 1]; // base rare
        mannys.pop();
        _safeMint(vaultWallet, 202);
        mannys[400] = mannys[mannys.length - 1]; // albino
        mannys.pop();
        _safeMint(vaultWallet, 401);
        mannys[41] = mannys[mannys.length - 1]; // holo
        mannys.pop();
        _safeMint(vaultWallet, 42);
        mannys[143] = mannys[mannys.length - 1]; // inverted
        mannys.pop();
        _safeMint(vaultWallet, 144);
        mannys[65] = mannys[mannys.length - 1]; // silver
        mannys.pop();
        _safeMint(vaultWallet, 66);
        mannys[243] = mannys[mannys.length - 1]; // stone
        mannys.pop();
        _safeMint(vaultWallet, 244);
        mannys[254] = mannys[mannys.length - 1]; // zombie
        mannys.pop();
        _safeMint(vaultWallet, 255);
    }

    function mint(uint256 numberOfTokens) public payable {
        require(mintActive == true, "mint is not active rn..");
        require(tx.origin == msg.sender, "dont get Seven'd");
        require(numberOfTokens > 0, "mint more lol");
        require(numberOfTokens <= 16, "dont be greedy smh");
        require(numberOfTokens <= mannys.length, "no more tokens sry");
        require(
            claimedPerWallet[msg.sender] + numberOfTokens <= 64,
            "claimed too many"
        );
        require(msg.value >= price.mul(numberOfTokens), "more eth pls");

        // mint a random manny
        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 randManny = getRandom(mannys);
            _safeMint(msg.sender, randManny);
            claimedPerWallet[msg.sender] += 1;
        }

        uint256 mannyCut = (msg.value * 40) / 100;
        payable(mannyWallet).transfer(mannyCut);
    }

    function getRandom(uint16[] storage _arr) private returns (uint256) {
        uint256 random = _getRandomNumber(_arr);
        uint256 tokenId = uint256(_arr[random]);

        _arr[random] = _arr[_arr.length - 1];
        _arr.pop();

        return tokenId;
    }

    /**
     * @dev Pseudo-random number generator
     * if you're able to exploit this you probably deserve to win TBH
     */
    function _getRandomNumber(uint16[] storage _arr)
        private
        view
        returns (uint256)
    {
        uint256 random = uint256(
            keccak256(
                abi.encodePacked(
                    _arr.length,
                    blockhash(block.number - 1),
                    block.coinbase,
                    block.difficulty,
                    msg.sender
                )
            )
        );

        return random % _arr.length;
    }

    function tokensByOwner(address _owner)
        external
        view
        returns (uint16[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint16[](0);
        } else {
            uint16[] memory result = new uint16[](tokenCount);
            uint16 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = uint16(tokenOfOwnerByIndex(_owner, index));
            }
            return result;
        }
    }

    function mintGoldManny() public {
        require(goldMannyMinted == false, "golden manny already minted...");
        uint16[5] memory zombie = [13, 143, 180, 255, 363];
        uint16[16] memory inverted = [
            10,
            17,
            44,
            60,
            64,
            77,
            78,
            144,
            155,
            165,
            168,
            216,
            219,
            298,
            329,
            397
        ];
        uint16[16] memory silver = [
            7,
            24,
            76,
            66,
            85,
            127,
            148,
            167,
            172,
            186,
            210,
            287,
            303,
            304,
            348,
            396
        ];
        uint16[16] memory stone = [
            11,
            33,
            36,
            58,
            108,
            138,
            171,
            173,
            184,
            190,
            209,
            231,
            234,
            244,
            308,
            332
        ];
        uint16[24] memory albinos = [
            59,
            91,
            93,
            94,
            115,
            118,
            119,
            141,
            145,
            150,
            160,
            179,
            192,
            195,
            235,
            237,
            271,
            273,
            291,
            297,
            325,
            326,
            381,
            401
        ];
        uint16[24] memory holos = [
            42,
            90,
            92,
            98,
            122,
            124,
            132,
            156,
            162,
            182,
            197,
            206,
            240,
            242,
            253,
            306,
            335,
            341,
            351,
            382,
            387,
            390,
            391,
            399
        ];

        uint16[] memory tokensOwned = this.tokensByOwner(msg.sender);
        uint16[] memory points = new uint16[](7);

        for (uint16 k = 0; k < tokensOwned.length; k++) {
            uint16 token = tokensOwned[k];
            bool isBase = token <= 403;
            for (uint16 i = 0; i < 24; i++) {
                if (i < albinos.length && albinos[i] == token) {
                    points[1] = 1;
                    isBase = false;
                } else if (i < holos.length && holos[i] == token) {
                    points[2] = 1;
                    isBase = false;
                } else if (i < inverted.length && inverted[i] == token) {
                    points[3] = 1;
                    isBase = false;
                } else if (i < silver.length && silver[i] == token) {
                    points[4] = 1;
                    isBase = false;
                } else if (i < stone.length && stone[i] == token) {
                    points[5] = 1;
                    isBase = false;
                } else if (i < zombie.length && zombie[i] == token) {
                    points[6] = 1;
                    isBase = false;
                }
            }
            // if checked all special ids and none matched, add base point
            if (isBase) {
                points[0] = 1;
            }
        }

        uint16 totalPoints;
        for (uint16 j = 0; j < points.length; j++) {
            if (points[j] == 1) {
                totalPoints += 1;
            }
        }

        require(
            totalPoints >= 7,
            "not enough points for a golden manny, ngmi..."
        );
        _safeMint(msg.sender, 404);
        goldMannyMinted = true;
    }

    function winTheGame() public {
        require(gameWon == false, "game has already been won, gg");
        require(
            this.ownerOf(404) == msg.sender,
            "have not acquired the golden manny, smh..."
        );
        payable(msg.sender).transfer(address(this).balance);
        gameWon = true;
        gameWinner = msg.sender;
    }

    // admin
    function setBaseURI(string memory baseURI) public onlyOwner {
        // _setBaseURI(baseURI);
    }

    function setMintActive(bool _mintActive) public onlyOwner {
        mintActive = _mintActive;
    }

    function withdraw() public onlyOwner {
        uint256 days404 = 86400 * 404;
        // time hasnt expired, so enforce rules
        if (block.timestamp <= gameStart + days404) {
            require(gameWon == true, "game isnt over yet...");
        }

        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);

        if (gameWon == false) {
            gameWon = true;
            gameWinner = msg.sender;
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

// BASED ON OpenZeppelin's PaymentSplitter
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/finance/PaymentSplitter.sol

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract SwordsEventBank is Ownable {
    // * STORAGE * //
    uint256 private _totalShares;
    uint256 private _totalClaimed;
    bool private _initialized;
    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _claimed;
    address[] private _members;

    // * EVENTS * //
    event MemberAdded(address account, uint256 shares);
    event MemberClaimed(address member, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    // * INITIALIZATION * //
    constructor() {
        _initialized = true;
    }

    function initialize(address[] memory members_, uint256[] memory shares_)
        public
    {
        require(!_initialized, "already initialized");
        require(
            members_.length == shares_.length,
            "members and shares length mismatch"
        );
        require(members_.length > 0, "no members");

        for (uint256 i = 0; i < members_.length; i++) {
            _addMember(members_[i], shares_[i]);
        }
        _initialized = true;
    }

    receive() external payable {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    function totalClaimed() public view returns (uint256) {
        return _totalClaimed;
    }

    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    function claimed(address account) public view returns (uint256) {
        return _claimed[account];
    }

    function member(uint256 index) public view returns (address) {
        return _members[index];
    }

    function members() public view returns (address[] memory) {
        return _members;
    }

    function balance(address account) public view returns (uint256) {
        uint256 totalReceived = address(this).balance + _totalClaimed;
        return
            (totalReceived * _shares[account]) /
            _totalShares -
            _claimed[account];
    }

    function claim(address payable account) public virtual {
        require(_shares[account] > 0, "account has no shares");

        uint256 totalReceived = address(this).balance + _totalClaimed;
        uint256 payment = (totalReceived * _shares[account]) /
            _totalShares -
            _claimed[account];

        require(payment != 0, "account is not due payment");

        _claimed[account] = _claimed[account] + payment;
        _totalClaimed = _totalClaimed + payment;

        Address.sendValue(account, payment);
        emit MemberClaimed(account, payment);
    }

    function _addMember(address account, uint256 shares_) private {
        require(account != address(0), "account is the zero address");
        require(shares_ > 0, "shares are 0");
        require(_shares[account] == 0, "account already has shares");

        _members.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
        emit MemberAdded(account, shares_);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

/*
   ▄████████  ▄█     █▄   ▄██████▄     ▄████████ ████████▄     ▄████████ 
  ███    ███ ███     ███ ███    ███   ███    ███ ███   ▀███   ███    ███ 
  ███    █▀  ███     ███ ███    ███   ███    ███ ███    ███   ███    █▀  
  ███        ███     ███ ███    ███  ▄███▄▄▄▄██▀ ███    ███   ███        
▀███████████ ███     ███ ███    ███ ▀▀███▀▀▀▀▀   ███    ███ ▀███████████ 
         ███ ███     ███ ███    ███ ▀███████████ ███    ███          ███ 
   ▄█    ███ ███ ▄█▄ ███ ███    ███   ███    ███ ███   ▄███    ▄█    ███ 
 ▄████████▀   ▀███▀███▀   ▀██████▀    ███    ███ ████████▀   ▄████████▀  
                                      ███    ███                         

                       GIMMIX ENTERTAINMENT MMXXI
*/

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ISwordsMarket} from "./interfaces/ISwordsMarket.sol";
import {ISwordsEvent} from "./interfaces/ISwordsEvent.sol";

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

interface IERC2981Royalties {
    function royaltyInfo(uint256 _tokenId, uint256 _value)
        external
        view
        returns (address _receiver, uint256 _royaltyAmount);
}

contract SwordsMarket is ISwordsMarket, Ownable {
    mapping(address => bool) private _eventRegistry;
    mapping(uint256 => address) private _eventContracts;
    mapping(uint256 => mapping(uint256 => mapping(address => uint256)))
        private _eventTokenBidders;
    mapping(uint256 => mapping(uint256 => uint256)) private _eventTokenAsks;

    modifier onlyEventCaller() {
        require(_eventRegistry[msg.sender] == true, "only event contract");
        _;
    }

    function bidForEventTokenBidder(
        uint256 eventId,
        uint256 tokenId,
        address bidder
    ) external view returns (uint256) {
        return _eventTokenBidders[eventId][tokenId][bidder];
    }

    function currentAskForEventToken(uint256 eventId, uint256 tokenId)
        external
        view
        returns (uint256)
    {
        return _eventTokenAsks[eventId][tokenId];
    }

    function isValidBid(uint256 bidAmount) public pure returns (bool) {
        return bidAmount != 0;
    }

    function splitShare(uint256 sharePercentage, uint256 amount)
        public
        pure
        returns (uint256)
    {
        return (amount * sharePercentage) / 100;
    }

    function registerEvent(uint256 eventId, address eventAddress)
        external
        onlyOwner
    {
        require(
            _eventContracts[eventId] == address(0),
            "event already configured"
        );
        require(
            _eventRegistry[eventAddress] == false,
            "contract already used in another event"
        );
        _eventContracts[eventId] = eventAddress;
        _eventRegistry[eventAddress] = true;
    }

    function setAsk(
        uint256 eventId,
        uint256 tokenId,
        uint256 askAmount
    ) public onlyEventCaller {
        require(isValidBid(askAmount), "SwordsMarket: Ask invalid");
        _eventTokenAsks[eventId][tokenId] = askAmount;
        emit AskCreated(eventId, tokenId, askAmount);
    }

    function removeAsk(uint256 eventId, uint256 tokenId)
        external
        onlyEventCaller
    {
        delete _eventTokenAsks[eventId][tokenId];
        emit AskRemoved(eventId, tokenId, _eventTokenAsks[eventId][tokenId]);
    }

    /**
     * @notice Sets the bid on a particular media for a bidder. The token being used to bid
     * is transferred from the spender to this contract to be held until removed or accepted.
     * If another bid already exists for the bidder, it is refunded.
     */
    function setBid(
        uint256 eventId,
        uint256 tokenId,
        uint256 bidAmount,
        address bidder
    ) public payable onlyEventCaller {
        require(bidder != address(0), "bidder cannot be 0 address");
        require(bidAmount != 0, "cannot bid amount of 0");
        require(msg.value == bidAmount, "bid amount must match msg value");

        uint256 existingBidAmount = _eventTokenBidders[eventId][tokenId][
            bidder
        ];

        // If there is an existing bid from this bidder, refund it before continuing
        if (existingBidAmount > 0) {
            removeBid(eventId, tokenId, bidder);
        }

        _eventTokenBidders[eventId][tokenId][bidder] = bidAmount;
        emit BidCreated(eventId, tokenId, bidAmount, bidder);

        // If a bid meets the criteria for an ask, automatically accept the bid.
        // If no ask is set or the bid does not meet the requirements, ignore.
        if (bidAmount >= _eventTokenAsks[eventId][tokenId]) {
            // Finalize exchange
            _finalizeNFTTransfer(eventId, tokenId, bidder);
        }
    }

    /**
     * @notice Removes the bid on a particular media for a bidder. The bid amount
     * is transferred from this contract to the bidder, if they have a bid placed.
     */
    function removeBid(
        uint256 eventId,
        uint256 tokenId,
        address bidder
    ) public onlyEventCaller {
        uint256 bidAmount = _eventTokenBidders[eventId][tokenId][bidder];

        require(bidAmount > 0, "cannot remove bid amount of 0");
        payable(bidder).transfer(bidAmount);

        emit BidRemoved(eventId, tokenId, bidAmount, bidder);
        delete _eventTokenBidders[eventId][tokenId][bidder];
    }

    /**
     * @notice Accepts a bid from a particular bidder. Can only be called by the media contract.
     * See {_finalizeNFTTransfer}
     * Provided bid must match a bid in storage. This is to prevent a race condition
     * where a bid may change while the acceptBid call is in transit.
     * A bid cannot be accepted if it cannot be split equally into its shareholders.
     * This should only revert in rare instances (example, a low bid with a zero-decimal token),
     * but is necessary to ensure fairness to all shareholders.
     */
    function acceptBid(
        uint256 eventId,
        uint256 tokenId,
        uint256 expectedBidAmount,
        address expectedBidBidder
    ) external onlyEventCaller {
        uint256 bidAmount = _eventTokenBidders[eventId][tokenId][
            expectedBidBidder
        ];
        require(bidAmount > 0, "cannot accept bid of 0");
        require(bidAmount == expectedBidAmount, "unexpected bid found.");

        _finalizeNFTTransfer(eventId, tokenId, expectedBidBidder);
    }

    /**
     * @notice Given a token ID and a bidder, this method transfers the value of
     * the bid to the shareholders. It also transfers the ownership of the media
     * to the bid recipient. Finally, it removes the accepted bid and the current ask.
     */
    function _finalizeNFTTransfer(
        uint256 eventId,
        uint256 tokenId,
        address bidder
    ) private {
        uint256 bidAmount = _eventTokenBidders[eventId][tokenId][bidder];
        ISwordsEvent swordsContract = ISwordsEvent(_eventContracts[eventId]);

        (address eventBank, uint256 amount) = IERC2981Royalties(
            _eventContracts[eventId]
        ).royaltyInfo(tokenId, bidAmount);

        // Transfer royalty share to event bank address
        payable(eventBank).transfer(amount);

        // Transfer remainder to current owner
        payable(IERC721(_eventContracts[eventId]).ownerOf(tokenId)).transfer(
            bidAmount - amount
        );

        // Transfer media to bidder
        swordsContract.exchangeTransfer(tokenId, bidder);

        // Remove the accepted bid
        delete _eventTokenBidders[eventId][tokenId][bidder];

        emit BidFinalized(eventId, tokenId, bidAmount, bidder);
    }
}