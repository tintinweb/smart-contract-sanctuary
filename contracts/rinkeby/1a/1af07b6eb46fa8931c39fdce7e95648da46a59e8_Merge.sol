// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * smatthewenglish oOoOoOoOoOoOoOoOoOoOoOoOoOoOoOoOoOoOoOoOoOoOoOoOoOoOo niftynathan
 * OoOoOoOoOoOoOoOoOoOoOoOoOoO                          OoOoOoOoOoOoOoOoOoOoOoOoOoOo
 * OoOoOoOoOoOoOoOoOoOoO                                      OoOoOoOoOoOoOoOoOoOoOo
 * OoOoOoOoOoOoOoOoOo                                             OoOoOoOoOoOoOoOoOo
 * OoOoOoOoOoOoOo                                                    oOoOoOoOoOoOoOo
 * OoOoOoOoOoOo                                                         OoOoOoOoOoOo
 * OoOoOoOoOo                                                             OoOoOoOoOo
 * OoOoOoOo                                                                 OoOoOoOo
 * OoOoOo                                                                     OoOoOo
 * OoOoO                                                                       oOoOo
 * OoOo                                                                         OoOo
 * OoO                                                                           oOo
 * Oo                                                                             oO
 * Oo                                                                             oO
 * O                                                                               O
 * O                                                                               O
 * O                                                                               O
 * O                                                                               O
 * O                                                                               O
 * Oo                                                                             oO
 * Oo                                                                             oO
 * OoO                                                                           oOo
 * OoOo                                                                         OoOo
 * OoOoO                                                                       oOoOo
 * OoOoOo                                                                     OoOoOo
 * OoOoOoOo                                                                 OoOoOoOo
 * OoOoOoOoOo                                                             OoOoOoOoOo
 * OoOoOoOoOoOo                                                         OoOoOoOoOoOo
 * OoOoOoOoOoOoOo                                                    oOoOoOoOoOoOoOo
 * OoOoOoOoOoOoOoOoOo                                             OoOoOoOoOoOoOoOoOo
 * OoOoOoOoOoOoOoOoOoOoO                                      OoOoOoOoOoOoOoOoOoOoOo
 * OoOoOoOoOoOoOoOoOoOoOoOoOoO                          OoOoOoOoOoOoOoOoOoOoOoOoOoOo
 * soliditygoldminerz oOoOoOoOoOoOoOoOoOoOoOoOoOoOoOoOoOoOo reviewed by manifold.xyz
 */

import {IMergeMetadata} from "./MergeMetadata.sol";

interface INiftyRegistry {
   function isValidNiftySender(address sending_key) external view returns (bool);
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface ERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed fromAddress, address indexed toAddress);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;

    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

interface ERC721Metadata {
    function name() external view returns (string memory _name);
    function symbol() external view returns (string memory _symbol);
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

contract Merge is ERC721, ERC721Metadata {

    IMergeMetadata public _metadataGenerator;

    string private _name;

    string private _symbol;

    uint256 constant private CLASS_MULTIPLIER = 100 * 1000 * 1000; // 100 million

    // valid classes are in the range [1, 4]
    uint256 constant private MIN_CLASS_INCL = 1;
    uint256 constant private MAX_CLASS_INCL = 4;

    function ensureValidClass(uint256 class) private pure {
        require(MIN_CLASS_INCL <= class && class <= MAX_CLASS_INCL, "Merge: Class must be [1, 4].");
    }

    // valid masses are in the range [1, 100m - 1)
    uint256 constant private MIN_MASS_INCL = 1;
    uint256 constant private MAX_MASS_EXCL = CLASS_MULTIPLIER - 1;

    function ensureValidMass(uint256 mass) private pure {
        require(MIN_MASS_INCL <= mass && mass < MAX_MASS_EXCL, "Merge: Mass must be [1, 100m - 1).");
    }

    function isSentinelMass(uint256 value) private pure returns (bool) {
        return (value % CLASS_MULTIPLIER) == MAX_MASS_EXCL;
    }

    bool public _mintingFinalized;
    bool public frozen;

    uint256 public _nextMintId;

    uint256 public _countToken;

    uint256 immutable public _percentageTotal;
    uint256 public _percentageRoyalty;

    uint256 public _alphaMass;

    uint256 public _alphaId;

    uint256 public _massTotal;

    address public _pak;

    address constant public _dead = 0x000000000000000000000000000000000000dEaD;

    address public _omnibus;

    address public _receiver;

    address immutable public _registry;

    event AlphaMassUpdate(uint256 indexed tokenId, uint256 alphaMass);

    event MassUpdate(uint256 indexed tokenIdBurned, uint256 indexed tokenIdPersist, uint256 mass);

    // Mapping of addresses disbarred from holding any token.
    mapping (address => bool) private _blacklistAddress;

    // Mapping of address allowed to hold multiple tokens.
    mapping (address => bool) private _whitelistAddress;

    // Mapping from owner address to token ID.
    mapping (address => uint256) private _tokens;

    // Mapping owner address to token count.
    mapping (address => uint256) private _balances;

    // Mapping from token ID to owner address.
    mapping (uint256 => address) private _owners;

    // Mapping from token ID to approved address.
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals.
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    // Mapping token ID to mass value.
    mapping (uint256 => uint256) private _values;

    // Mapping token ID to all quantity merged into it.
    mapping (uint256 => uint256) private _mergeCount;

    function getMergeCount(uint256 tokenId) public view returns (uint256 mergeCount) {
        require(_exists(tokenId), "ERC721: nonexistent token");
        return _mergeCount[tokenId];
    }

    modifier onlyPak() {
        require(_msgSender() == _pak, "Merge: msg.sender is not pak");
        _;
    }

    modifier onlyValidWhitelist() {
        require(_whitelistAddress[_msgSender()], "Merge: Invalid msg.sender");
        _;
    }
    //
    // modifier onlyValidSender() {
    //     require(INiftyRegistry(_registry).isValidNiftySender(_msgSender()), "Merge: Invalid msg.sender");
    //     _;
    // }

    modifier onlyValidSender() {
        require(_msgSender() == _pak, "Merge: Invalid msg.sender");
        _;
    }

    modifier notFrozen() {
        require(!frozen, "Merge: movement frozen");
        _;
    }

    /**
     * @dev Set the values carefully!
     *
     * Requirements:
     *
     * - `registry_` enforce access control on state-changing ops
     * - `omnibus_` for efficient minting of initial token stock
     * - `metadataGenerator_`
     * - `pak_` - Initial pak address (0x2Ce780D7c743A57791B835a9d6F998B15BBbA5a4)
     *
     */
    constructor(address registry_, address omnibus_, address metadataGenerator_, address pak_) {
        _nextMintId = 1;
        _registry = registry_;
        _omnibus = omnibus_;
        _metadataGenerator = IMergeMetadata(metadataGenerator_);
        _name = "merge.";
        _symbol = "m";

        _pak = pak_;
        _receiver = pak_;

        _percentageTotal = 10000;
        _percentageRoyalty = 1000;


        _blacklistAddress[address(this)] = true;

        _whitelistAddress[omnibus_] = true;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function totalSupply() public view returns (uint256) {
        return _countToken;
    }

    function merge(uint256 tokenIdRcvr, uint256 tokenIdSndr) external onlyValidWhitelist notFrozen returns (uint256 tokenIdDead) {
        address owner = ownerOf(tokenIdRcvr);
        require(owner == ownerOf(tokenIdSndr), "Merge: Illegal argument disparate owner.");
        require(_msgSender() == owner, "ERC721: msg.sender is not token owner.");

        // owners are same, so decrement their balance as we are merging
        _balances[owner] -= 1;

        tokenIdDead = _merge(tokenIdRcvr, tokenIdSndr);

        // clear ownership of dead token
        delete _owners[tokenIdDead];

        // owners are the same; burn dead token from common owner
        emit Transfer(owner, address(0), tokenIdDead);
    }

    function _transfer(address owner, address from, address to, uint256 tokenId) internal notFrozen {
        require(owner == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");
        require(!_blacklistAddress[to], "Merge: transfer attempt to blacklist address");

        // if transferring to `_dead_` then `_transfer` is interpreted as a burn
        if (to == _dead) {
            _burnNoEmitTransfer(owner, tokenId);

            emit Transfer(from, _dead, tokenId);
            emit Transfer(_dead, address(0), tokenId);
        } else {
            // Clear any prior approvals
            // includes an emit of Approval to zero
            _approve(owner, address(0), tokenId);

            // in all cases we first wish to log the transfer
            // no merging later can deny the fact that `from` transferred to `to`
            emit Transfer(from, to, tokenId);

            if (from == to) {
                // !non-local control flow!
                // we make an exception here, as it’s easy to follow that a self transfer
                // can skip _all_ following state changes
                return;
            }

            // if all addresses were whitelisted, then transfer would be like any other ERC-721
            // _balances[from] -= 1;
            // _balances[to] += 1;
            // _owners[tokenId] = to;

            // _balances (1) and _owners (2) are the main mappings to update
            // for non-whitelisted addresses there is also the _tokens (3) mapping
            //
            // Our updates will be
            //   - 1a: decrement balance of `from`
            //   - 1b: update balance of `to` (not guaranteed to increase)
            //   - 2: assign ownership of `tokenId`
            //   - 3a: assign unique token of `to`
            //   - 3b: unassign unique token of `from`

            bool fromIsWhitelisted = isWhitelisted(from);
            bool toIsWhitelisted = isWhitelisted(to);

            // BEGIN PART 1: update _balances
            //
            // PART 1a: decrease balance of `from`
            //   the classic implementation would be
            //   _balances[from] -= 1;
            if (fromIsWhitelisted) {
                // from the reasoning:
                // > if all addresses were whitelisted, then transfer would be like any other ERC-721
                _balances[from] -= 1;
            } else {
                // for non-whitelisted addresses, we have the invariant that
                //   _balances[a] <= 1
                // we known that `from` was the owner so the only possible state is
                //   _balances[from] == 1
                // to save an SLOAD, we can assign a balance of 0 (or delete)
                delete _balances[from];
            }
            // PART 1b: increase balance of `to`
            //   the classic implementation would be
            //   _balances[to] += 1;
            if (toIsWhitelisted) {
                // from the reasoning:
                // > if all addresses were whitelisted, then transfer would be like any other ERC-721
                _balances[to] += 1;
            } else if (_tokens[to] == 0) {
                // for non-whitelisted addresses, we have the invariant that
                //   _balances[a] <= 1
                // if _tokens[to] == 0 then _balances[to] == 0
                // to save an SLOAD, we can assign a balance of 1
                _balances[to] = 1;
            } else {
                // for non-whitelisted addresses, we have the invariant that
                //   _balances[a] <= 1
                // if _tokens[to] != 0 then _balance[to] == 1
                // to preserve the invariant, we have nothing to do (the balance is already 1)
            }
            // END PART 1

            if (toIsWhitelisted) {
                // PART 2: update _owners
                // assign ownership of token
                //   the classic implementation would be
                //   _owners[tokenId] = to;
                //
                // from the reasoning:
                // > if all addresses were whitelisted, then transfer would be like any other ERC-721
                _owners[tokenId] = to;
            } else {
                // label current and sent token with respect to address `to`
                uint256 currentTokenId = _tokens[to];

                if (currentTokenId == 0) {
                    // PART 2: update _owners
                    // assign ownership of token
                    _owners[tokenId] = to;

                    // PART 3a
                    // assign unique token of `to`
                    _tokens[to] = tokenId;
                } else {
                    uint256 sentTokenId = tokenId;

                    // compute token merge, returning the dead token
                    uint256 deadTokenId = _merge(currentTokenId, sentTokenId);

                    // logically, the token has already been transferred to `to`
                    // so log the burning of the dead token id as originating ‘from’ `to`
                    emit Transfer(to, address(0), deadTokenId);

                    // thus inferring the alive token
                    uint256 aliveTokenId = currentTokenId;
                    if (currentTokenId == deadTokenId) {
                        aliveTokenId = sentTokenId;
                    }

                    // PART 2 continued:
                    // and ownership of dead token is deleted
                    delete _owners[deadTokenId];

                    // if received token surplanted the current token
                    if (currentTokenId != aliveTokenId) {
                        // PART 2 continued:
                        // to takes ownership of alive token
                        _owners[aliveTokenId] = to;

                        // PART 3a
                        // assign unique token of `to`
                        _tokens[to] = aliveTokenId;
                    }
                }
            }

            // PART 3b:
            // unassign unique token of `from`
            //
            // _tokens is only defined for non-whitelisted addresses
            if (!fromIsWhitelisted) {
                delete _tokens[from];
            }
        }
    }

    function _merge(uint256 tokenIdRcvr, uint256 tokenIdSndr) internal returns (uint256 tokenIdDead) {
        require(tokenIdRcvr != tokenIdSndr, "Merge: Illegal argument identical tokenId.");

        uint256 massRcvr = decodeMass(_values[tokenIdRcvr]);
        uint256 massSndr = decodeMass(_values[tokenIdSndr]);

        uint256 massSmall = massRcvr;
        uint256 massLarge = massSndr;

        uint256 tokenIdSmall = tokenIdRcvr;
        uint256 tokenIdLarge = tokenIdSndr;

        if (massRcvr >= massSndr) {

            massSmall = massSndr;
            massLarge = massRcvr;

            tokenIdSmall = tokenIdSndr;
            tokenIdLarge = tokenIdRcvr;
        }

        _values[tokenIdLarge] += massSmall;

        uint256 combinedMass = massLarge + massSmall;

        if(combinedMass > _alphaMass) {
            _alphaId = tokenIdLarge;
            _alphaMass = combinedMass;
            emit AlphaMassUpdate(_alphaId, combinedMass);
        }

        _mergeCount[tokenIdLarge]++;

        delete _values[tokenIdSmall];

        _countToken -= 1;

        emit MassUpdate(tokenIdSmall, tokenIdLarge, combinedMass);

        return tokenIdSmall;
    }

    function setRoyaltyBips(uint256 percentageRoyalty_) external onlyPak {
        require(percentageRoyalty_ <= _percentageTotal, "Merge: Illegal argument more than 100%");
        _percentageRoyalty = percentageRoyalty_;
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address, uint256) {
        uint256 royaltyAmount = (salePrice * _percentageRoyalty) / _percentageTotal;
        return (_receiver, royaltyAmount);
    }

    function setBlacklistAddress(address address_, bool status) external onlyPak {
        require(address_ != _omnibus, "Merge: Illegal argument address_ is _omnibus.");
        _blacklistAddress[address_] = status;
    }

    function setPak(address pak_) external onlyPak {
        _pak = pak_;
    }

    function setRoyaltyReceiver(address receiver_) external onlyPak {
        _receiver = receiver_;
    }

    function setMetadataGenerator(address metadataGenerator_) external onlyPak {
        _metadataGenerator = IMergeMetadata(metadataGenerator_);
    }

    function whitelistUpdate(address address_, bool status) external onlyPak {
        if(address_ == _omnibus){
            require(status != false, "Merge: Illegal argument _omnibus can't be removed.");
        }

        if(status == false) {
            require(balanceOf(address_) <= 1, "Merge: Address with more than one token can't be removed.");
        }

        _whitelistAddress[address_] = status;
    }

    function isWhitelisted(address address_) public view returns (bool) {
        return _whitelistAddress[address_];
    }

    function isBlacklisted(address address_) public view returns (bool) {
        return _blacklistAddress[address_];
    }

    function ownerOf(uint256 tokenId) public view override returns (address owner) {
        owner = _owners[tokenId];
        require(owner != address(0), "ERC721: nonexistent token");
    }

    /**
     * @dev Generate the NFTs of this collection.
     *
     * [20001000, 20000900, ]
     *
     * Requirements:
     *
     * - `values_` provided as a list of addresses, each of
     *             which implicitly corresponds to a tokenId,
     *             derrived by the index of the value in the
     *             input array. The values map to a color
     *             attribute.
     *
     * Emits a series of {Transfer} events.
     */
     function mint(uint256[] calldata values_) external {
     // function mint(uint256[] calldata values_) external onlyValidSender {
        require(!_mintingFinalized, "Merge: Minting is finalized.");

        // for efficiency reasons copy from storage into local variables
        uint256 index = _nextMintId;
        uint256 alphaId = _alphaId;
        uint256 alphaMass = _alphaMass;
        address omnibus = _omnibus;

        // initialize accumulators and counters
        uint256 massAdded = 0;
        uint256 newlyMintedCount = 0;
        uint256 valueIx = 0;

        while (valueIx < values_.length) {

            if (isSentinelMass(values_[valueIx])) {
                // SKIP FLAG SET - DON'T MINT
            } else {
                newlyMintedCount++;

                _values[index] = values_[valueIx];
                _owners[index] = omnibus;

                (/* uint256 class */, uint256 mass) = decodeClassAndMass(values_[valueIx]);

                if (alphaMass < mass){
                    alphaMass = mass;
                    alphaId = index;
                }

                massAdded += mass;

                emit Transfer(address(0), omnibus, index);
            }

            // update counters for loop
            valueIx++;
            index++;
        }

        // return new token id index to storage
        _nextMintId = index;

        // update token supply and balances based on batch mint
        _countToken += newlyMintedCount;
        _balances[omnibus] += newlyMintedCount;

        // update total mass in system with aggregate mass of batch mint
        // we must fail if we attempt to mint sufficient mass such that it
        // new total mass in the system becomes unrepresentable
        // i.e., total mass must be bounded by MAX_MASS_EXCL
        uint256 prevMassTotal = _massTotal;
        uint256 newMassTotal = prevMassTotal + massAdded;
        require(newMassTotal < MAX_MASS_EXCL, "Merge: Mass total overflow");
        _massTotal = newMassTotal;

        // if the alpha was supplanted during minting,
        // then return that new state to storage
        if(_alphaId != alphaId) {
            _alphaId = alphaId;
            _alphaMass = alphaMass;
            emit AlphaMassUpdate(alphaId, alphaMass);
        }
    }

    function batchSetMergeCountFromSnapshot(uint256[] calldata tokenIds_, uint256[] calldata mergeCounts_) external onlyValidSender {
        require(!_mintingFinalized, "Merge: Minting is finalized.");
        require(tokenIds_.length == mergeCounts_.length, "");
        for(uint256 i = 0 ; i < tokenIds_.length; i++) {
            _mergeCount[tokenIds_[i]] = mergeCounts_[i];
        }
    }

    function finalize() external onlyPak {
        thaw();
        _mintingFinalized = true;
    }

    function freeze() external onlyPak {
        require(!_mintingFinalized);
        frozen = true;
    }

    function thaw() public onlyPak {
        frozen = false;
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        (address owner, bool isApprovedOrOwner) = _isApprovedOrOwner(_msgSender(), tokenId);
        require(isApprovedOrOwner, "ERC721: transfer caller is not owner nor approved");
        _transfer(owner, from, to, tokenId);
    }

    function balanceOf(address owner) public view override returns (uint256) {
        return _balances[owner];
    }

    function massOf(uint256 tokenId) public view virtual returns (uint256) {
        uint256 value = getValueOf(tokenId);
        return decodeMass(value);
    }

    function getValueOf(uint256 tokenId) public view virtual returns (uint256 value) {
        value = _values[tokenId];
        require(value != 0, "ERC721: nonexistent token");
    }

    function tokenOf(address owner) public view virtual returns (uint256) {
        require(!isWhitelisted(owner), "Merge: tokenOf undefined");
        uint256 token = _tokens[owner];
        return token;
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );
        _approve(owner, to, tokenId);
    }

    function _approve(address owner, address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: nonexistent token");
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");
        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (address owner, bool isApprovedOrOwner) {
        owner = _owners[tokenId];

        require(owner != address(0), "ERC721: nonexistent token");

        isApprovedOrOwner = (spender == owner || _tokenApprovals[tokenId] == spender || isApprovedForAll(owner, spender));
    }

    function tokenURI(uint256 tokenId) public virtual view override returns (string memory) {
        require(_exists(tokenId), "ERC721: nonexistent token");

        return _metadataGenerator.tokenMetadata(
            tokenId,
            decodeClass(_values[tokenId]),
            decodeMass(_values[tokenId]),
            decodeMass(_values[_alphaId]),
            tokenId == _alphaId,
            getMergeCount(tokenId));
    }

    function encodeClassAndMass(uint256 class, uint256 mass) public pure returns (uint256) {
        ensureValidClass(class);
        ensureValidMass(mass);
        return ((class * CLASS_MULTIPLIER) + mass);
    }

    function decodeClassAndMass(uint256 value) public pure returns (uint256, uint256) {
        uint256 class = decodeClass(value);
        uint256 mass = decodeMass(value);

        return (class, mass);
    }

    function decodeClass(uint256 value) public pure returns (uint256 class) {
        class = value / CLASS_MULTIPLIER; // integer division is ‘checked’ in Solidity 0.8.x
        ensureValidClass(class);
    }

    function decodeMass(uint256 value) public pure returns (uint256 mass) {
        mass = value % CLASS_MULTIPLIER; // integer modulo is ‘checked’ in Solidity 0.8.x
        ensureValidMass(mass);
    }

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool) {
        if (isContract(to)) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                }
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
        return true;
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        bytes4 _ERC165_ = 0x01ffc9a7;
        bytes4 _ERC721_ = 0x80ac58cd;
        bytes4 _ERC2981_ = 0x2a55205a;
        bytes4 _ERC721Metadata_ = 0x5b5e139f;
        return interfaceId == _ERC165_
            || interfaceId == _ERC721_
            || interfaceId == _ERC2981_
            || interfaceId == _ERC721Metadata_;
    }

    function burn(uint256 tokenId) public notFrozen {
        (address owner, bool isApprovedOrOwner) = _isApprovedOrOwner(_msgSender(), tokenId);
        require(isApprovedOrOwner, "ERC721: caller is not owner nor approved");

        _burnNoEmitTransfer(owner, tokenId);

        emit Transfer(owner, address(0), tokenId);
    }

    function _burnNoEmitTransfer(address owner, uint256 tokenId) internal {
        _approve(owner, address(0), tokenId);

        _massTotal -= decodeMass(_values[tokenId]);

        delete _tokens[owner];
        delete _owners[tokenId];
        delete _values[tokenId];

        _countToken -= 1;
        _balances[owner] -= 1;

        emit MassUpdate(tokenId, 0, 0);
    }
}