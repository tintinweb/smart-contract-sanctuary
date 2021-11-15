pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./EtherFreakers.sol";
import "./FreakerAttack.sol";


contract FreakerFortress is ERC721, ERC721Holder {

	address public manager;
	uint128 public joinFeeWei = 1e17;
	uint128 public attackFeeWei = 5e17;
	address public etherFreakersAddress;
	address public attackContract;
	uint8 public maxRemoteAttackers = 4;

	constructor(address author, address _etherFreakersAddress) ERC721("FreakerFortress", "FEFKR") {
        manager = author;
        etherFreakersAddress = _etherFreakersAddress;
    }

    modifier ownerOrApproved(uint128 freakerID) { 
    	require(_isApprovedOrOwner(msg.sender, freakerID), "FreakerFortress: caller is not owner nor approved");
    	_; 
    }

    modifier managerOnly() { 
    	require(msg.sender == manager, "FreakerFortress: caller is not owner nor approved");
    	_; 
    }
    
    function depositFreaker(address payable mintTo, uint128 freakerID) payable external {
        require(msg.value >= joinFeeWei, "FreakerFortress: Join fee too low");
        EtherFreakers(etherFreakersAddress).transferFrom(msg.sender, address(this), freakerID);
        _safeMint(mintTo, freakerID, "");
    }

    // attack contract only 
    function depositFreakerFree(address payable mintTo, uint128 freakerID) payable external {
        require(msg.sender == attackContract, "FreakerFortress: Attack contract only");
        EtherFreakers(etherFreakersAddress).transferFrom(msg.sender, address(this), freakerID);
        _safeMint(mintTo, freakerID, "");
    }

    function withdrawFreaker(address to, uint128 freakerID) payable external ownerOrApproved(freakerID) {
        EtherFreakers(etherFreakersAddress).safeTransferFrom(address(this), to, freakerID);
        _burn(freakerID);
    }

    function discharge(uint128 freakerID, uint128 amount) public {
        require(ownerOf(freakerID) == msg.sender, "FreakerFortress: only owner");
        // calculate what the contract will be paid before we call
        uint128 energy = EtherFreakers(etherFreakersAddress).energyOf(freakerID);
        uint128 capped = amount > energy ? energy : amount;
        EtherFreakers(etherFreakersAddress).discharge(freakerID, amount);
        // pay owner 
        address owner = ownerOf(freakerID);
        payable(owner).transfer(capped);
    }

    function charge(uint128 freakerID) payable ownerOrApproved(freakerID) public {
       EtherFreakers(etherFreakersAddress).charge{value: msg.value}(freakerID);
    }

    function tokenURI(uint256 tokenID) public view virtual override returns (string memory) {
        return EtherFreakers(etherFreakersAddress).tokenURI(tokenID);
    }

    // this is to handle tokens sent to the contract 
    function claimToken(address to, uint256 freakerID) payable external {
        require(!_exists(freakerID), "FreakerFortress: token has owner");
        require(EtherFreakers(etherFreakersAddress).ownerOf(freakerID) == address(this), "FreakerFortress: fortress does not own token");
    	_safeMint(to, freakerID, "");
    }

    // these methods allow someone to pay to have members of the fortress 
    // attack a target

    function createAttackContract() external {
    	require(attackContract == address(0), "FreakerFortress: attack contract already exists");
    	attackContract = address(new FreakerAttack(payable(address(this)), etherFreakersAddress)); 
    }

    function remoteAttack(uint128[] calldata freakers, uint128 sourceId, uint128 targetId) external payable returns(bool response) {
    	require(msg.value >= attackFeeWei, "FreakerFortress: Attack fee too low");
        require(attackContract != address(0), "FreakerFortress: attack contract does not exist");
    	require(EtherFreakers(etherFreakersAddress).ownerOf(targetId) != address(this), "FreakerFortress: cannot attack freak in fortress");
    	require(!EtherFreakers(etherFreakersAddress).isEnlightened(targetId), "FreakerFortress: target is enlightened");
    	require(freakers.length <= maxRemoteAttackers, "FreakerFortress: too many attackers");
    	for(uint i=0; i < freakers.length; i++){
			EtherFreakers(etherFreakersAddress).transferFrom(address(this), attackContract, freakers[i]);
		}
		response = FreakerAttack(attackContract).attack(payable(msg.sender), sourceId, targetId);
		FreakerAttack(attackContract).sendBack(freakers);
    }

    // owner methods

    function updateFightFee(uint128 _fee) external managerOnly {
        attackFeeWei = _fee;
    }

    function updateJoinFee(uint128 _fee) external managerOnly {
        joinFeeWei = _fee;
    }

    function updateManager(address _manager) external managerOnly {
        manager = _manager;
    }

    function updateMaxRemoteAttackers(uint8 count) external managerOnly {
        maxRemoteAttackers = count;
    }

    function payManager(uint256 amount) external managerOnly {
        require(amount <= address(this).balance, "FreakerFortress:  amount  too high");
        payable(manager).transfer(amount);
    }

    // payable

    receive() payable external {
        // nothing to do
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "./extensions/IERC721Enumerable.sol";
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
    mapping (uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping (address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId
            || super.supportsInterface(interfaceId);
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
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString()))
            : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
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

        require(_msgSender() == owner || ERC721.isApprovedForAll(owner, _msgSender()),
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
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
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
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
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
        return (spender == owner || getApproved(tokenId) == spender || ERC721.isApprovedForAll(owner, spender));
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
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
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
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    // solhint-disable-next-line no-inline-assembly
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

  /**
   * @dev Implementation of the {IERC721Receiver} interface.
   *
   * Accepts all token transfers.
   * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
   */
contract ERC721Holder is IERC721Receiver {

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

struct Freaker {
    uint8 species;
    uint8 stamina;
    uint8 fortune;
    uint8 agility;
    uint8 offense;
    uint8 defense;
}

struct EnergyBalance {
    uint128 basic;
    uint128 index;
}

struct CombatMultipliers {
    uint128 attack;
    uint128 defend;
}

struct SpeciesCounter {
    int32 pluto;
    int32 mercury;
    int32 saturn;
    int32 uranus;
    int32 venus;
    int32 mars;
    int32 neptune;
    int32 jupiter;
}

contract EtherFreakers is ERC721 {
    /// Number of tokens in existence.
    uint128 public numTokens;

    /// Record of energy costs paid for birthing.
    uint256[] public birthCertificates;

    /// Index for the creator energy pool.
    uint128 public creatorIndex;

    /// Index for the freaker energy pool.
    uint128 public freakerIndex;

    /// Total freaker shares.
    uint128 public totalFortune;

    /// Mapping from freaker id to freaker.
    mapping(uint128 => Freaker) public freakers;

    /// Mapping from token id to energy balance.
    mapping(uint128 => EnergyBalance) public energyBalances;

    /// Mapping from account to aggregate multipliers.
    mapping(address => CombatMultipliers) public combatMultipliers;

    /// Mapping from account to count of each species.
    mapping(address => SpeciesCounter) public speciesCounters;

    event Born(address mother, uint128 energy, uint128 indexed freakerId, Freaker freaker);
    event Missed(address attacker, address defender, uint128 indexed sourceId, uint128 indexed targetId);
    event Thwarted(address attacker, address defender, uint128 indexed sourceId, uint128 indexed targetId);
    event Captured(address attacker, address defender, uint128 indexed sourceId, uint128 indexed targetId);

    /**
     * @notice Construct the EtherFreakers contract.
     * @param author Jared's address.
     */
    constructor(address author) ERC721("EtherFreakers", "EFKR") {
        for (uint i = 0; i < 8; i++) {
            _mint(author, numTokens++);
        }
    }

    /**
     * @notice Base URI for computing {tokenURI}.
     * @dev EtherFreakers original art algorithm commit hash:
     *  fe61dab48fa91cc298438862652116469fe663ea
     */
    function _baseURI() internal pure override returns (string memory) {
        return "https://ether.freakers.art/m/";
    }

    /**
     * @notice Birth a new freaker, given enough energy.
     */
    function birth() payable public {
        birthTo(payable(msg.sender));
    }

    /**
     * @notice Birth a new freaker, given enough energy.
     * @param to Recipient's address
     */
    function birthTo(address payable to) payable public {
        // Roughly
        //  pick species
        //   0 (1x) ->
        //    fortune / offense
        //   1 (2x) ->
        //    fortune / defense
        //   2 (2x) ->
        //    fortune / agility
        //   3 (3x) ->
        //    offense / defense
        //   4 (3x) ->
        //    defense / offense
        //   5 (4x) ->
        //    agility / offense
        //   6 (4x) ->
        //    agility / defense
        //   7 (1x) ->
        //    defense / agility
        //  pick stamina: [0, 9]
        //  pick fortune, agility, offense, defense based on species: [1, 10]
        //   primary = 300% max
        //   secondary = 200% max

        uint256 middle = middlePrice();
        require(msg.value > middle * 1005 / 1000, "Not enough energy");

        uint128 freakerId = numTokens++;
        uint8 speciesDie = uint8(_randomishIntLessThan("species", 20));
        uint8 species = (
         (speciesDie < 1 ? 0 :
          (speciesDie < 3 ? 1 :
           (speciesDie < 5 ? 2 :
            (speciesDie < 8 ? 3 :
             (speciesDie < 11 ? 4 :
              (speciesDie < 15 ? 5 :
               (speciesDie < 19 ? 6 : 7))))))));

        uint8 stamina = uint8(_randomishIntLessThan("stamina", 10));
        uint8 fortune = uint8(_randomishIntLessThan("fortune", species < 3 ? 30 : 10) + 1);
        uint8 agility = uint8(_randomishIntLessThan("agility",
         (species == 5 || species == 6 ? 30 :
          (species == 2 || species == 7 ? 20 : 10))) + 1);
        uint8 offense = uint8(_randomishIntLessThan("offense",
         (species == 3 ? 30 :
          (species == 0 || species == 4 || species == 5 ? 20 : 10))) + 1);
        uint8 defense = uint8(_randomishIntLessThan("defense",
         (species == 4 || species == 7 ? 30 :
          (species == 1 || species == 4 || species == 6 ? 20 : 10))) + 1);

        Freaker memory freaker = Freaker({
            species: species,
            stamina: stamina,
            fortune: fortune,
            agility: agility,
            offense: offense,
            defense: defense
          });
        freakers[freakerId] = freaker;

        uint128 value = uint128(msg.value);
        uint128 half = value / 2;
        _dissipateEnergyIntoPool(half);
        energyBalances[freakerId] = EnergyBalance({
            basic: half,
            index: freakerIndex
          });
        totalFortune += fortune;

        birthCertificates.push(msg.value);

        emit Born(to, value, freakerId, freaker);
        _safeMint(to, freakerId, "");
    }

    /**
     * @notice Attempt to capture another owner's freaker.
     * @param sourceId The freaker launching the attack.
     * @param targetId The freaker being attacked.
     * @return Whether or not the attack was successful.
     */
    function attack(uint128 sourceId, uint128 targetId) public returns (bool) {
        address attacker = ownerOf(sourceId);
        address defender = ownerOf(targetId);
        require(attacker != defender, "Cannot attack self");
        require(attacker == msg.sender, "Sender does not own source");

        if (isEnlightened(sourceId) || isEnlightened(targetId)) {
            revert("Enlightened beings can neither attack nor be attacked");
        }

        Freaker memory source = freakers[sourceId];
        Freaker memory target = freakers[targetId];

        if (_randomishIntLessThan("hit?", source.agility + target.agility) > source.agility) {
            // source loses energy:
            //  0.1% - 1% (0.1% * (10 - stamina))
            uint128 sourceCharge = energyOf(sourceId);
            uint128 sourceSpent = sourceCharge * (1 * (10 - source.stamina)) / 1000;
            energyBalances[sourceId] = EnergyBalance({
                basic: sourceCharge - sourceSpent,
                index: freakerIndex
              });
            _dissipateEnergyIntoPool(sourceSpent);
            emit Missed(attacker, defender, sourceId, targetId);
            return false;
        }

        if (_randomishIntLessThan("win?", attackPower(sourceId)) < defendPower(targetId)) {
            // both source and target lose energy:
            //  1% - 10% (1% * (10 - stamina))
            uint128 sourceCharge = energyOf(sourceId);
            uint128 targetCharge = energyOf(targetId);
            uint128 sourceSpent = sourceCharge * (1 * (10 - source.stamina)) / 100;
            uint128 targetSpent = targetCharge * (1 * (10 - target.stamina)) / 100;
            energyBalances[sourceId] = EnergyBalance({
                basic: sourceCharge - sourceSpent,
                index: freakerIndex
              });
            energyBalances[targetId] = EnergyBalance({
                basic: targetCharge - targetSpent,
                index: freakerIndex
              });
            _dissipateEnergyIntoPool(sourceSpent);
            _dissipateEnergyIntoPool(targetSpent);
            emit Thwarted(attacker, defender, sourceId, targetId);
            return false;
        } else {
            // source loses energy
            //  2% - 20% (2% * (10 - stamina))
            // return target charge to target owner, if we can
            // transfer target to source owner
            // remaining source energy is split in half and given to target
            uint128 sourceCharge = energyOf(sourceId);
            uint128 targetCharge = energyOf(targetId);
            uint128 sourceSpent = sourceCharge * (2 * (10 - source.stamina)) / 100;
            uint128 sourceRemaining = sourceCharge - sourceSpent;
            if (!payable(defender).send(targetCharge)) {
                creatorIndex += targetCharge / 8;
            }
            _transfer(defender, attacker, targetId);
            _dissipateEnergyIntoPool(sourceSpent);

            uint128 half = sourceRemaining / 2;
            energyBalances[sourceId] = EnergyBalance({
                basic: half,
                index: freakerIndex
              });
            energyBalances[targetId] = EnergyBalance({
                basic: half,
                index: freakerIndex
              });

            emit Captured(attacker, defender, sourceId, targetId);
            return true;
        }
    }

    /**
     * @notice Draw upon a creator's share of energy.
     * @param creatorId The token id of the creator to tap.
     */
    function tap(uint128 creatorId) public {
        require(isCreator(creatorId), "Not a creator");
        address owner = ownerOf(creatorId);
        uint128 unclaimed = creatorIndex - energyBalances[creatorId].index;
        energyBalances[creatorId].index = creatorIndex;
        payable(owner).transfer(unclaimed);
    }

    /**
     * @notice Store energy on a freaker.
     * @param freakerId The token id of the freaker to charge.
     */
    function charge(uint128 freakerId) payable public {
        address owner = ownerOf(freakerId);
        require(msg.sender == owner, "Sender does not own freaker");
        require(isFreaker(freakerId), "Not a freaker");
        EnergyBalance memory balance = energyBalances[freakerId];
        energyBalances[freakerId] = EnergyBalance({
            basic: balance.basic + uint128(msg.value),
            index: balance.index
          });
    }

    /**
     * @notice Withdraw energy from a freaker.
     * @param freakerId The token id of the freaker to discharge.
     * @param amount The amount of energy (Ether) to discharge, capped to max.
     */
    function discharge(uint128 freakerId, uint128 amount) public {
        address owner = ownerOf(freakerId);
        require(msg.sender == owner, "Sender does not own freaker");
        require(isFreaker(freakerId), "Not a freaker");
        uint128 energy = energyOf(freakerId);
        uint128 capped = amount > energy ? energy : amount;
        energyBalances[freakerId] = EnergyBalance({
            basic: energy - capped,
            index: freakerIndex
          });
        payable(owner).transfer(capped);
    }

    function isCreator(uint256 tokenId) public pure returns (bool) { return tokenId < 8; }
    function isFreaker(uint256 tokenId) public pure returns (bool) { return tokenId >= 8; }

    function isEnlightened(uint128 tokenId) public view returns (bool) {
        if (isCreator(tokenId)) {
            return true;
        }
        address owner = ownerOf(tokenId);
        SpeciesCounter memory c = speciesCounters[owner];
        return (
         c.pluto > 0 && c.mercury > 0 && c.saturn > 0 && c.uranus > 0 &&
         c.venus > 0 && c.mars > 0 && c.neptune > 0 && c.jupiter > 0
        );
    }

    function energyOf(uint128 tokenId) public view returns (uint128) {
        if (isCreator(tokenId)) {
            EnergyBalance memory balance = energyBalances[tokenId];
            return balance.basic + (creatorIndex - balance.index);
        } else {
            Freaker memory freaker = freakers[tokenId];
            EnergyBalance memory balance = energyBalances[tokenId];
            return balance.basic + (freakerIndex - balance.index) * freaker.fortune;
        }
    }

    function attackPower(uint128 freakerId) public view returns (uint128) {
        address attacker = ownerOf(freakerId);
        return combatMultipliers[attacker].attack * energyOf(freakerId);
    }

    function defendPower(uint128 freakerId) public view returns (uint128) {
        address defender = ownerOf(freakerId);
        return combatMultipliers[defender].defend * energyOf(freakerId);
    }

    function middlePrice() public view returns (uint256) {
        uint256 length = birthCertificates.length;
        return length > 0 ? birthCertificates[length / 2] : 0;
    }

    function _randomishIntLessThan(bytes32 salt, uint256 n) internal view returns (uint256) {
        if (n == 0)
            return 0;
        return uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, salt))) % n;
    }

    function _dissipateEnergyIntoPool(uint128 amount) internal {
        if (amount > 0) {
            if (totalFortune > 0) {
                uint128 creatorAmount = amount * 20 / 100;
                uint128 freakerAmount = amount * 80 / 100;
                creatorIndex += creatorAmount / 8;
                freakerIndex += freakerAmount / totalFortune;
            } else {
                creatorIndex += amount / 8;
            }
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
        if (isFreaker(tokenId)) {
            uint128 freakerId = uint128(tokenId);
            Freaker memory freaker = freakers[freakerId];

            if (from != address(0)) {
                CombatMultipliers memory multipliers = combatMultipliers[from];
                combatMultipliers[from] = CombatMultipliers({
                    attack: multipliers.attack - freaker.offense * uint128(freaker.offense),
                    defend: multipliers.defend - freaker.defense * uint128(freaker.defense)
                  });
                _countSpecies(from, freaker.species, -1);
            }

            if (to != address(0)) {
                CombatMultipliers memory multipliers = combatMultipliers[to];
                combatMultipliers[to] = CombatMultipliers({
                    attack: multipliers.attack + freaker.offense * uint128(freaker.offense),
                    defend: multipliers.defend + freaker.defense * uint128(freaker.defense)
                  });
                _countSpecies(to, freaker.species, 1);
            }

            if (from != address(0) && to != address(0)) {
                uint128 freakerCharge = energyOf(freakerId);
                uint128 freakerSpent = freakerCharge / 1000;
                energyBalances[freakerId] = EnergyBalance({
                    basic: freakerCharge - freakerSpent,
                    index: freakerIndex
                  });
                _dissipateEnergyIntoPool(freakerSpent);
            }
        }
    }

    function _countSpecies(address account, uint8 species, int8 delta) internal {
        if (species < 4) {
            if (species < 2) {
                if (species == 0) {
                    speciesCounters[account].pluto += delta;
                } else {
                    speciesCounters[account].mercury += delta;
                }
            } else {
                if (species == 2) {
                    speciesCounters[account].saturn += delta;
                } else {
                    speciesCounters[account].uranus += delta;
                }
            }
        } else {
            if (species < 6) {
                if (species == 4) {
                    speciesCounters[account].venus += delta;
                } else {
                    speciesCounters[account].mars += delta;
                }
            } else {
                if (species == 6) {
                    speciesCounters[account].neptune += delta;
                } else {
                    speciesCounters[account].jupiter += delta;
                }
            }
        }
    }
}

pragma solidity ^0.8.2;

import "./EtherFreakers.sol";
import "./FreakerFortress.sol";

contract FreakerAttack {
	address payable public owner;
	address public etherFreakersAddress;

	constructor(address payable creator, address _etherFreakersAddress) {
		owner = creator;
		etherFreakersAddress = _etherFreakersAddress;

	}

	function attack(address payable onBehalfOf, uint128 sourceId, uint128 targetId) external returns (bool) {
		require(msg.sender == owner, "FreakerAttack: Only owner");
		require(address(this) == EtherFreakers(etherFreakersAddress).ownerOf(sourceId), "FreakerAttack: does not own sourceId");
		bool success = EtherFreakers(etherFreakersAddress).attack(sourceId, targetId);
		if(success){
			EtherFreakers(etherFreakersAddress).approve(owner, targetId);
			FreakerFortress(owner).depositFreakerFree(onBehalfOf, targetId);
			return true;
		}
		return false;
	}

	// for gas fees, can use a max of four attackers
	// so we only allow for to be sent back 
	function sendBack(uint128[] calldata freakers) external {
		for(uint i=0; i < freakers.length; i++){
			EtherFreakers(etherFreakersAddress).transferFrom(address(this), owner, freakers[i]);
		}
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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
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

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

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
            buffer[i] = alphabet[value & 0xf];
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

