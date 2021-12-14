// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

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

    modifier onlyValidSender() {
        require(INiftyRegistry(_registry).isValidNiftySender(_msgSender()), "Merge: Invalid msg.sender");
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
     function mint(uint256[] calldata values_) external onlyValidSender {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

/** 
 * XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
 * XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
 * XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX  .***   XXXXXXXXXXXXXXXXXXXXXXXXXXXXX
 * XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX  ,*********  XXXXXXXXXXXXXXXXXXXXXXXXXXX
 * XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX  ***************  XXXXXXXXXXXXXXXXXXXXXXXX
 * XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX  .*******************  XXXXXXXXXXXXXXXXXXXXXX
 * XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX  ***********    **********  XXXXXXXXXXXXXXXXXXX
 * XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX   ***********       ***********  XXXXXXXXXXXXXXXXX
 * XXXXXXXXXXXXXXXXXXXXXXXXXXXX  ***********         ***************  XXXXXXXXXXXXXX
 * XXXXXXXXXXXXXXXXXXXXXXXXXX  ***********           ****    ********* XXXXXXXXXXXXX
 * XXXXXXXXXXXXXXXXXXXXXXXXXX *********      ***    ***      *********  XXXXXXXXXXXX
 * XXXXXXXXXXXXXXXXXXXXXXXXXX  **********  *****          *********** XXXXXXXXXXXXXX
 * XXXXXXXXXXXXXXXXXXXXXX   /////.*************         ***********  XXXXXXXXXXXXXXX
 * XXXXXXXXXXXXXXXXXXX  /////////...***********      ************  XXXXXXXXXXXXXXXXX
 * XXXXXXXXXXXXXXXXX/ ///////////..... /////////   ///////////   XXXXXXXXXXXXXXXXXXX
 * XXXXXXXXXXXXXXXX  /    //////.........///////////////////   XXXXXXXXXXXXXXXXXXXXX
 * XXXXXXXXXXXXXXXXXXXX .///////...........//////////////   XXXXXXXXXXXXXXXXXXXXXXXX
 * XXXXXXXXXXXXXXXXXXX .///////.....//..////  /////////  XXXXXXXXXXXXXXXXXXXXXXXXXXX
 * XXXXXXXXXXXXXXXXX# /////////////////////  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
 * XXXXXXXXXXXXXXX   ////////////////////   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
 * XXXXXXXXXXXX   ////////////// //////   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
 * XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
 * XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
 */

import {ABDKMath64x64} from "../util/ABDKMath64x64.sol";
import {Base64} from "../util/Base64.sol";
import {Roots} from "../util/Roots.sol";
import {Strings} from "../util/Strings.sol";

interface IMergeMetadata {    
    function tokenMetadata(
        uint256 tokenId, 
        uint256 rarity, 
        uint256 tokenMass, 
        uint256 alphaMass, 
        bool isAlpha, 
        uint256 mergeCount) external view returns (string memory);
}

contract MergeMetadata is IMergeMetadata {
    
    struct ERC721MetadataStructure {
        bool isImageLinked;
        string name;
        string description;
        string createdBy;
        string image;
        ERC721MetadataAttribute[] attributes;
    }

    struct ERC721MetadataAttribute {
        bool includeDisplayType;
        bool includeTraitType;
        bool isValueAString;
        string displayType;
        string traitType;
        string value;
    }
    
    using ABDKMath64x64 for int128;    
    using Base64 for string;
    using Roots for uint;    
    using Strings for uint256;    
    
    address public owner;  

    string private _name;
    string private _imageBaseURI;
    string private _imageExtension;
    uint256 private _maxRadius;
    string[] private _imageParts;
    mapping (string => string) private _classStyles;
  
    string constant private _RADIUS_TAG = '<RADIUS>';
    string constant private _CLASS_TAG = '<CLASS>';  
    string constant private _CLASS_STYLE_TAG = '<CLASS_STYLE>';  
  
    constructor() {
        owner = msg.sender;
        _name = "m";
        _imageBaseURI = ""; // Set to empty string - results in on-chain SVG generation by default unless this is set later
        _imageExtension = ""; // Set to empty string - can be changed later to remain empty, .png, .mp4, etc
        _maxRadius = 1000;

        // Deploy with default SVG image parts - can be completely replaced later
        _imageParts.push("<svg xmlns='http://www.w3.org/2000/svg' version='1.1' width='2000' height='2000'>");
            _imageParts.push("<style>");
                _imageParts.push(".m1 #c{fill: #fff;}");
                _imageParts.push(".m1 #r{fill: #000;}");
                _imageParts.push(".m2 #c{fill: #fc3;}");
                _imageParts.push(".m2 #r{fill: #000;}");
                _imageParts.push(".m3 #c{fill: #fff;}");
                _imageParts.push(".m3 #r{fill: #33f;}");
                _imageParts.push(".m4 #c{fill: #fff;}");
                _imageParts.push(".m4 #r{fill: #f33;}");
                _imageParts.push(".a #c{fill: #000 !important;}");
                _imageParts.push(".a #r{fill: #fff !important;}");
                _imageParts.push(_CLASS_STYLE_TAG);
            _imageParts.push("</style>");
            _imageParts.push("<g class='");
                _imageParts.push(_CLASS_TAG);
                _imageParts.push("'>");
                    _imageParts.push("<rect id='r' width='2000' height='2000'/>");
                    _imageParts.push("<circle id='c' cx='1000' cy='1000' r='");
                        _imageParts.push(_RADIUS_TAG);
                    _imageParts.push("'/>");
            _imageParts.push("</g>");                
        _imageParts.push("</svg>");
    }        
    
    function setName(string calldata name_) external { 
        _requireOnlyOwner();       
        _name = name_;
    }

    function setImageBaseURI(string calldata imageBaseURI_, string calldata imageExtension_) external {        
        _requireOnlyOwner();
        _imageBaseURI = imageBaseURI_;
        _imageExtension = imageExtension_;
    }

    function setMaxRadius(uint256 maxRadius_) external {
        _requireOnlyOwner();
        _maxRadius = maxRadius_;
    }    

    function tokenMetadata(uint256 tokenId, uint256 rarity, uint256 tokenMass, uint256 alphaMass, bool isAlpha, uint256 mergeCount) external view override returns (string memory) {        
        string memory base64Json = Base64.encode(bytes(string(abi.encodePacked(_getJson(tokenId, rarity, tokenMass, alphaMass, isAlpha, mergeCount)))));
        return string(abi.encodePacked('data:application/json;base64,', base64Json));
    }

    function updateImageParts(string[] memory imageParts_) public {
        _requireOnlyOwner();
        _imageParts = imageParts_;
    }

    function updateClassStyle(string calldata cssClass, string calldata cssStyle) external {
        _requireOnlyOwner();
        _classStyles[cssClass] = cssStyle;
    }

    function getClassStyle(string memory cssClass) public view returns (string memory) {
        return _classStyles[cssClass];
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function imageBaseURI() public view returns (string memory) {
        return _imageBaseURI;
    }

    function imageExtension() public view returns (string memory) {
        return _imageExtension;
    }

    function maxRadius() public view returns (uint256) {
        return _maxRadius;
    }            

    function getClassString(uint256 tokenId, uint256 rarity, bool isAlpha, bool offchainImage) public pure returns (string memory) {
        return _getClassString(tokenId, rarity, isAlpha, offchainImage);
    }

    function _getJson(uint256 tokenId, uint256 rarity, uint256 tokenMass, uint256 alphaMass, bool isAlpha, uint256 mergeCount) private view returns (string memory) {        
        string memory imageData = 
            bytes(_imageBaseURI).length == 0 ? 
                _getSvg(tokenId, rarity, tokenMass, alphaMass, isAlpha) :
                string(abi.encodePacked(imageBaseURI(), _getClassString(tokenId, rarity, isAlpha, true), "_", uint256(int256(_getScaledRadius(tokenMass, alphaMass, _maxRadius).toInt())).toString(), imageExtension()));

        ERC721MetadataStructure memory metadata = ERC721MetadataStructure({
            isImageLinked: bytes(_imageBaseURI).length > 0, 
            name: string(abi.encodePacked(name(), "(", tokenMass.toString(), ") #", tokenId.toString())),
            description: tokenMass.toString(),
            createdBy: "Pak",
            image: imageData,
            attributes: _getJsonAttributes(tokenId, rarity, tokenMass, mergeCount, isAlpha)
        });

        return _generateERC721Metadata(metadata);
    }        

    function _getJsonAttributes(uint256 tokenId, uint256 rarity, uint256 tokenMass, uint256 mergeCount, bool isAlpha) private pure returns (ERC721MetadataAttribute[] memory) {
        uint256 tensDigit = tokenId % 100 / 10;
        uint256 onesDigit = tokenId % 10;
        uint256 class = tensDigit * 10 + onesDigit;

        ERC721MetadataAttribute[] memory metadataAttributes = new ERC721MetadataAttribute[](5);
        metadataAttributes[0] = _getERC721MetadataAttribute(false, true, false, "", "Mass", tokenMass.toString());
        metadataAttributes[1] = _getERC721MetadataAttribute(false, true, false, "", "Alpha", isAlpha ? "1" : "0");
        metadataAttributes[2] = _getERC721MetadataAttribute(false, true, false, "", "Tier", rarity.toString());
        metadataAttributes[3] = _getERC721MetadataAttribute(false, true, false, "", "Class", class.toString());
        metadataAttributes[4] = _getERC721MetadataAttribute(false, true, false, "", "Merges", mergeCount.toString());
        return metadataAttributes;
    }    

    function _getERC721MetadataAttribute(bool includeDisplayType, bool includeTraitType, bool isValueAString, string memory displayType, string memory traitType, string memory value) private pure returns (ERC721MetadataAttribute memory) {
        ERC721MetadataAttribute memory attribute = ERC721MetadataAttribute({
            includeDisplayType: includeDisplayType,
            includeTraitType: includeTraitType,
            isValueAString: isValueAString,
            displayType: displayType,
            traitType: traitType,
            value: value
        });

        return attribute;
    }    

    function _getSvg(uint256 tokenId, uint256 rarity, uint256 tokenMass, uint256 alphaMass, bool isAlpha) private view returns (string memory) {
        bytes memory byteString;
        for (uint i = 0; i < _imageParts.length; i++) {
          if (_checkTag(_imageParts[i], _RADIUS_TAG)) {
            byteString = abi.encodePacked(byteString, _floatToString(_getScaledRadius(tokenMass, alphaMass, _maxRadius)));
          } else if (_checkTag(_imageParts[i], _CLASS_TAG)) {
            byteString = abi.encodePacked(byteString, _getClassString(tokenId, rarity, isAlpha, false));
          } else if (_checkTag(_imageParts[i], _CLASS_STYLE_TAG)) {
              uint256 tensDigit = tokenId % 100 / 10;
              uint256 onesDigit = tokenId % 10;
              uint256 class = tensDigit * 10 + onesDigit;
              string memory classCss = getClassStyle(_getTokenIdClass(class));
              if(bytes(classCss).length > 0) {
                  byteString = abi.encodePacked(byteString, classCss);
              }            
          } else {
            byteString = abi.encodePacked(byteString, _imageParts[i]);
          }
        }
        return string(byteString); 
    }

    function _getScaledRadius(uint256 tokenMass, uint256 alphaMass, uint256 maximumRadius) private pure returns (int128) {
        int128 radiusMass = _getRadius64x64(tokenMass);
        int128 radiusAlphaMass = _getRadius64x64(alphaMass);
        int128 scalePercentage = ABDKMath64x64.div(radiusMass, radiusAlphaMass);                
        int128 scaledRadius = ABDKMath64x64.mul(ABDKMath64x64.fromUInt(maximumRadius), scalePercentage);
        if(uint256(int256(scaledRadius.toInt())) == 0) {
            scaledRadius = ABDKMath64x64.fromUInt(1);
        }
        return scaledRadius;
    }

    // Radius = Cube Root(Mass) * Cube Root (0.23873241463)
    // Radius = Cube Root(Mass) * 0.62035049089
    function _getRadius64x64(uint256 mass) private pure returns (int128) {        
        int128 cubeRootScalar = ABDKMath64x64.divu(62035049089, 100000000000);
        int128 cubeRootMass = ABDKMath64x64.divu(mass.nthRoot(3, 6, 32), 1000000);
        int128 radius = ABDKMath64x64.mul(cubeRootMass, cubeRootScalar);        
        return radius;
    }            

    function _generateERC721Metadata(ERC721MetadataStructure memory metadata) private pure returns (string memory) {
      bytes memory byteString;    
    
        byteString = abi.encodePacked(
          byteString,
          _openJsonObject());
    
        byteString = abi.encodePacked(
          byteString,
          _pushJsonPrimitiveStringAttribute("name", metadata.name, true));
    
        byteString = abi.encodePacked(
          byteString,
          _pushJsonPrimitiveStringAttribute("description", metadata.description, true));
    
        byteString = abi.encodePacked(
          byteString,
          _pushJsonPrimitiveStringAttribute("created_by", metadata.createdBy, true));
    
        if(metadata.isImageLinked) {
            byteString = abi.encodePacked(
                byteString,
                _pushJsonPrimitiveStringAttribute("image", metadata.image, true));
        } else {
            byteString = abi.encodePacked(
                byteString,
                _pushJsonPrimitiveStringAttribute("image_data", metadata.image, true));
        }

        byteString = abi.encodePacked(
          byteString,
          _pushJsonComplexAttribute("attributes", _getAttributes(metadata.attributes), false));
    
        byteString = abi.encodePacked(
          byteString,
          _closeJsonObject());
    
        return string(byteString);
    }

    function _getAttributes(ERC721MetadataAttribute[] memory attributes) private pure returns (string memory) {
        bytes memory byteString;
    
        byteString = abi.encodePacked(
          byteString,
          _openJsonArray());
    
        for (uint i = 0; i < attributes.length; i++) {
          ERC721MetadataAttribute memory attribute = attributes[i];

          byteString = abi.encodePacked(
            byteString,
            _pushJsonArrayElement(_getAttribute(attribute), i < (attributes.length - 1)));
        }
    
        byteString = abi.encodePacked(
          byteString,
          _closeJsonArray());
    
        return string(byteString);
    }

    function _getAttribute(ERC721MetadataAttribute memory attribute) private pure returns (string memory) {
        bytes memory byteString;
        
        byteString = abi.encodePacked(
          byteString,
          _openJsonObject());
    
        if(attribute.includeDisplayType) {
          byteString = abi.encodePacked(
            byteString,
            _pushJsonPrimitiveStringAttribute("display_type", attribute.displayType, true));
        }
    
        if(attribute.includeTraitType) {
          byteString = abi.encodePacked(
            byteString,
            _pushJsonPrimitiveStringAttribute("trait_type", attribute.traitType, true));
        }
    
        if(attribute.isValueAString) {
          byteString = abi.encodePacked(
            byteString,
            _pushJsonPrimitiveStringAttribute("value", attribute.value, false));
        } else {
          byteString = abi.encodePacked(
            byteString,
            _pushJsonPrimitiveNonStringAttribute("value", attribute.value, false));
        }
    
        byteString = abi.encodePacked(
          byteString,
          _closeJsonObject());
    
        return string(byteString);
    }

    function _getClassString(uint256 tokenId, uint256 rarity, bool isAlpha, bool offchainImage) private pure returns (string memory) {
        bytes memory byteString;    
    
        byteString = abi.encodePacked(byteString, _getRarityClass(rarity));
        
        if(isAlpha) {
            byteString = abi.encodePacked(
              byteString,
              string(abi.encodePacked(offchainImage ? "_" : " ", "a")));
        }

        uint256 tensDigit = tokenId % 100 / 10;
        uint256 onesDigit = tokenId % 10;
        uint256 class = tensDigit * 10 + onesDigit;

        byteString = abi.encodePacked(
          byteString,
          string(abi.encodePacked(offchainImage ? "_" : " ", _getTokenIdClass(class))));

        return string(byteString);    
    }

    function _getRarityClass(uint256 rarity) private pure returns (string memory) {
        return string(abi.encodePacked("m", rarity.toString()));
    }

    function _getTokenIdClass(uint256 class) private pure returns (string memory) {
        return string(abi.encodePacked("c", class.toString()));
    }

    function _checkTag(string storage a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function _floatToString(int128 value) private pure returns (string memory) {
        uint256 decimal4 = (value & 0xFFFFFFFFFFFFFFFF).mulu(10000);
        return string(abi.encodePacked(uint256(int256(value.toInt())).toString(), '.', _decimal4ToString(decimal4)));
    }
  
    function _decimal4ToString(uint256 decimal4) private pure returns (string memory) {
        bytes memory decimal4Characters = new bytes(4);
        for (uint i = 0; i < 4; i++) {
          decimal4Characters[3 - i] = bytes1(uint8(0x30 + decimal4 % 10));
          decimal4 /= 10;
        }
        return string(abi.encodePacked(decimal4Characters));
    }

    function _requireOnlyOwner() private view {
        require(msg.sender == owner, "You are not the owner");
    }

    function _openJsonObject() private pure returns (string memory) {        
        return string(abi.encodePacked("{"));
    }

    function _closeJsonObject() private pure returns (string memory) {
        return string(abi.encodePacked("}"));
    }

    function _openJsonArray() private pure returns (string memory) {        
        return string(abi.encodePacked("["));
    }

    function _closeJsonArray() private pure returns (string memory) {        
        return string(abi.encodePacked("]"));
    }

    function _pushJsonPrimitiveStringAttribute(string memory key, string memory value, bool insertComma) private pure returns (string memory) {
        return string(abi.encodePacked('"', key, '": "', value, '"', insertComma ? ',' : ''));
    }

    function _pushJsonPrimitiveNonStringAttribute(string memory key, string memory value, bool insertComma) private pure returns (string memory) {
        return string(abi.encodePacked('"', key, '": ', value, insertComma ? ',' : ''));
    }

    function _pushJsonComplexAttribute(string memory key, string memory value, bool insertComma) private pure returns (string memory) {
        return string(abi.encodePacked('"', key, '": ', value, insertComma ? ',' : ''));
    }

    function _pushJsonArrayElement(string memory value, bool insertComma) private pure returns (string memory) {
        return string(abi.encodePacked(value, insertComma ? ',' : ''));
    }
}

// SPDX-License-Identifier: BSD-4-Clause
/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity ^0.8.6;

/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.  As long as denominator is always the same, there is no
 * need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 */
library ABDKMath64x64 {
  /*
   * Minimum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

  /*
   * Maximum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  /**
   * Convert signed 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromInt (int256 x) internal pure returns (int128) {
    unchecked {
      require (x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
      return int128 (x << 64);
    }
  }

  /**
   * Convert signed 64.64 fixed point number into signed 64-bit integer number
   * rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64-bit integer number
   */
  function toInt (int128 x) internal pure returns (int64) {
    unchecked {
      return int64 (x >> 64);
    }
  }

  /**
   * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromUInt (uint256 x) internal pure returns (int128) {
    unchecked {
      require (x <= 0x7FFFFFFFFFFFFFFF);
      return int128 (int256 (x << 64));
    }
  }

  /**
   * Convert signed 64.64 fixed point number into unsigned 64-bit integer
   * number rounding down.  Revert on underflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return unsigned 64-bit integer number
   */
  function toUInt (int128 x) internal pure returns (uint64) {
    unchecked {
      require (x >= 0);
      return uint64 (uint128 (x >> 64));
    }
  }

  /**
   * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
   * number rounding down.  Revert on overflow.
   *
   * @param x signed 128.128-bin fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function from128x128 (int256 x) internal pure returns (int128) {
    unchecked {
      int256 result = x >> 64;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Convert signed 64.64 fixed point number into signed 128.128 fixed point
   * number.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 128.128 fixed point number
   */
  function to128x128 (int128 x) internal pure returns (int256) {
    unchecked {
      return int256 (x) << 64;
    }
  }

  /**
   * Calculate x + y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function add (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) + y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x - y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sub (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) - y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x * y rounding down.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function mul (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) * y >> 64;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
   * number and y is signed 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y signed 256-bit integer number
   * @return signed 256-bit integer number
   */
  function muli (int128 x, int256 y) internal pure returns (int256) {
    unchecked {
      if (x == MIN_64x64) {
        require (y >= -0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF &&
          y <= 0x1000000000000000000000000000000000000000000000000);
        return -y << 63;
      } else {
        bool negativeResult = false;
        if (x < 0) {
          x = -x;
          negativeResult = true;
        }
        if (y < 0) {
          y = -y; // We rely on overflow behavior here
          negativeResult = !negativeResult;
        }
        uint256 absoluteResult = mulu (x, uint256 (y));
        if (negativeResult) {
          require (absoluteResult <=
            0x8000000000000000000000000000000000000000000000000000000000000000);
          return -int256 (absoluteResult); // We rely on overflow behavior here
        } else {
          require (absoluteResult <=
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
          return int256 (absoluteResult);
        }
      }
    }
  }

  /**
   * Calculate x * y rounding down, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y unsigned 256-bit integer number
   * @return unsigned 256-bit integer number
   */
  function mulu (int128 x, uint256 y) internal pure returns (uint256) {
    unchecked {
      if (y == 0) return 0;

      require (x >= 0);

      uint256 lo = (uint256 (int256 (x)) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
      uint256 hi = uint256 (int256 (x)) * (y >> 128);

      require (hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      hi <<= 64;

      require (hi <=
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
      return hi + lo;
    }
  }

  /**
   * Calculate x / y rounding towards zero.  Revert on overflow or when y is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function div (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);
      int256 result = (int256 (x) << 64) / y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are signed 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x signed 256-bit integer number
   * @param y signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divi (int256 x, int256 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);

      bool negativeResult = false;
      if (x < 0) {
        x = -x; // We rely on overflow behavior here
        negativeResult = true;
      }
      if (y < 0) {
        y = -y; // We rely on overflow behavior here
        negativeResult = !negativeResult;
      }
      uint128 absoluteResult = divuu (uint256 (x), uint256 (y));
      if (negativeResult) {
        require (absoluteResult <= 0x80000000000000000000000000000000);
        return -int128 (absoluteResult); // We rely on overflow behavior here
      } else {
        require (absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int128 (absoluteResult); // We rely on overflow behavior here
      }
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divu (uint256 x, uint256 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);
      uint128 result = divuu (x, y);
      require (result <= uint128 (MAX_64x64));
      return int128 (result);
    }
  }

  /**
   * Calculate -x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function neg (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != MIN_64x64);
      return -x;
    }
  }

  /**
   * Calculate |x|.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function abs (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != MIN_64x64);
      return x < 0 ? -x : x;
    }
  }

  /**
   * Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function inv (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != 0);
      int256 result = int256 (0x100000000000000000000000000000000) / x;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function avg (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      return int128 ((int256 (x) + int256 (y)) >> 1);
    }
  }

  /**
   * Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
   * Revert on overflow or in case x * y is negative.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function gavg (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 m = int256 (x) * int256 (y);
      require (m >= 0);
      require (m <
          0x4000000000000000000000000000000000000000000000000000000000000000);
      return int128 (sqrtu (uint256 (m)));
    }
  }

  /**
   * Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y uint256 value
   * @return signed 64.64-bit fixed point number
   */
  function pow (int128 x, uint256 y) internal pure returns (int128) {
    unchecked {
      bool negative = x < 0 && y & 1 == 1;

      uint256 absX = uint128 (x < 0 ? -x : x);
      uint256 absResult;
      absResult = 0x100000000000000000000000000000000;

      if (absX <= 0x10000000000000000) {
        absX <<= 63;
        while (y != 0) {
          if (y & 0x1 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x2 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x4 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x8 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          y >>= 4;
        }

        absResult >>= 64;
      } else {
        uint256 absXShift = 63;
        if (absX < 0x1000000000000000000000000) { absX <<= 32; absXShift -= 32; }
        if (absX < 0x10000000000000000000000000000) { absX <<= 16; absXShift -= 16; }
        if (absX < 0x1000000000000000000000000000000) { absX <<= 8; absXShift -= 8; }
        if (absX < 0x10000000000000000000000000000000) { absX <<= 4; absXShift -= 4; }
        if (absX < 0x40000000000000000000000000000000) { absX <<= 2; absXShift -= 2; }
        if (absX < 0x80000000000000000000000000000000) { absX <<= 1; absXShift -= 1; }

        uint256 resultShift = 0;
        while (y != 0) {
          require (absXShift < 64);

          if (y & 0x1 != 0) {
            absResult = absResult * absX >> 127;
            resultShift += absXShift;
            if (absResult > 0x100000000000000000000000000000000) {
              absResult >>= 1;
              resultShift += 1;
            }
          }
          absX = absX * absX >> 127;
          absXShift <<= 1;
          if (absX >= 0x100000000000000000000000000000000) {
              absX >>= 1;
              absXShift += 1;
          }

          y >>= 1;
        }

        require (resultShift < 64);
        absResult >>= 64 - resultShift;
      }
      int256 result = negative ? -int256 (absResult) : int256 (absResult);
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate sqrt (x) rounding down.  Revert if x < 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sqrt (int128 x) internal pure returns (int128) {
    unchecked {
      require (x >= 0);
      return int128 (sqrtu (uint256 (int256 (x)) << 64));
    }
  }

  /**
   * Calculate binary logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function log_2 (int128 x) internal pure returns (int128) {
    unchecked {
      require (x > 0);

      int256 msb = 0;
      int256 xc = x;
      if (xc >= 0x10000000000000000) { xc >>= 64; msb += 64; }
      if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
      if (xc >= 0x10000) { xc >>= 16; msb += 16; }
      if (xc >= 0x100) { xc >>= 8; msb += 8; }
      if (xc >= 0x10) { xc >>= 4; msb += 4; }
      if (xc >= 0x4) { xc >>= 2; msb += 2; }
      if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

      int256 result = msb - 64 << 64;
      uint256 ux = uint256 (int256 (x)) << uint256 (127 - msb);
      for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
        ux *= ux;
        uint256 b = ux >> 255;
        ux >>= 127 + b;
        result += bit * int256 (b);
      }

      return int128 (result);
    }
  }

  /**
   * Calculate natural logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function ln (int128 x) internal pure returns (int128) {
    unchecked {
      require (x > 0);

      return int128 (int256 (
          uint256 (int256 (log_2 (x))) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF >> 128));
    }
  }

  /**
   * Calculate binary exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp_2 (int128 x) internal pure returns (int128) {
    unchecked {
      require (x < 0x400000000000000000); // Overflow

      if (x < -0x400000000000000000) return 0; // Underflow

      uint256 result = 0x80000000000000000000000000000000;

      if (x & 0x8000000000000000 > 0)
        result = result * 0x16A09E667F3BCC908B2FB1366EA957D3E >> 128;
      if (x & 0x4000000000000000 > 0)
        result = result * 0x1306FE0A31B7152DE8D5A46305C85EDEC >> 128;
      if (x & 0x2000000000000000 > 0)
        result = result * 0x1172B83C7D517ADCDF7C8C50EB14A791F >> 128;
      if (x & 0x1000000000000000 > 0)
        result = result * 0x10B5586CF9890F6298B92B71842A98363 >> 128;
      if (x & 0x800000000000000 > 0)
        result = result * 0x1059B0D31585743AE7C548EB68CA417FD >> 128;
      if (x & 0x400000000000000 > 0)
        result = result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8 >> 128;
      if (x & 0x200000000000000 > 0)
        result = result * 0x10163DA9FB33356D84A66AE336DCDFA3F >> 128;
      if (x & 0x100000000000000 > 0)
        result = result * 0x100B1AFA5ABCBED6129AB13EC11DC9543 >> 128;
      if (x & 0x80000000000000 > 0)
        result = result * 0x10058C86DA1C09EA1FF19D294CF2F679B >> 128;
      if (x & 0x40000000000000 > 0)
        result = result * 0x1002C605E2E8CEC506D21BFC89A23A00F >> 128;
      if (x & 0x20000000000000 > 0)
        result = result * 0x100162F3904051FA128BCA9C55C31E5DF >> 128;
      if (x & 0x10000000000000 > 0)
        result = result * 0x1000B175EFFDC76BA38E31671CA939725 >> 128;
      if (x & 0x8000000000000 > 0)
        result = result * 0x100058BA01FB9F96D6CACD4B180917C3D >> 128;
      if (x & 0x4000000000000 > 0)
        result = result * 0x10002C5CC37DA9491D0985C348C68E7B3 >> 128;
      if (x & 0x2000000000000 > 0)
        result = result * 0x1000162E525EE054754457D5995292026 >> 128;
      if (x & 0x1000000000000 > 0)
        result = result * 0x10000B17255775C040618BF4A4ADE83FC >> 128;
      if (x & 0x800000000000 > 0)
        result = result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB >> 128;
      if (x & 0x400000000000 > 0)
        result = result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9 >> 128;
      if (x & 0x200000000000 > 0)
        result = result * 0x10000162E43F4F831060E02D839A9D16D >> 128;
      if (x & 0x100000000000 > 0)
        result = result * 0x100000B1721BCFC99D9F890EA06911763 >> 128;
      if (x & 0x80000000000 > 0)
        result = result * 0x10000058B90CF1E6D97F9CA14DBCC1628 >> 128;
      if (x & 0x40000000000 > 0)
        result = result * 0x1000002C5C863B73F016468F6BAC5CA2B >> 128;
      if (x & 0x20000000000 > 0)
        result = result * 0x100000162E430E5A18F6119E3C02282A5 >> 128;
      if (x & 0x10000000000 > 0)
        result = result * 0x1000000B1721835514B86E6D96EFD1BFE >> 128;
      if (x & 0x8000000000 > 0)
        result = result * 0x100000058B90C0B48C6BE5DF846C5B2EF >> 128;
      if (x & 0x4000000000 > 0)
        result = result * 0x10000002C5C8601CC6B9E94213C72737A >> 128;
      if (x & 0x2000000000 > 0)
        result = result * 0x1000000162E42FFF037DF38AA2B219F06 >> 128;
      if (x & 0x1000000000 > 0)
        result = result * 0x10000000B17217FBA9C739AA5819F44F9 >> 128;
      if (x & 0x800000000 > 0)
        result = result * 0x1000000058B90BFCDEE5ACD3C1CEDC823 >> 128;
      if (x & 0x400000000 > 0)
        result = result * 0x100000002C5C85FE31F35A6A30DA1BE50 >> 128;
      if (x & 0x200000000 > 0)
        result = result * 0x10000000162E42FF0999CE3541B9FFFCF >> 128;
      if (x & 0x100000000 > 0)
        result = result * 0x100000000B17217F80F4EF5AADDA45554 >> 128;
      if (x & 0x80000000 > 0)
        result = result * 0x10000000058B90BFBF8479BD5A81B51AD >> 128;
      if (x & 0x40000000 > 0)
        result = result * 0x1000000002C5C85FDF84BD62AE30A74CC >> 128;
      if (x & 0x20000000 > 0)
        result = result * 0x100000000162E42FEFB2FED257559BDAA >> 128;
      if (x & 0x10000000 > 0)
        result = result * 0x1000000000B17217F7D5A7716BBA4A9AE >> 128;
      if (x & 0x8000000 > 0)
        result = result * 0x100000000058B90BFBE9DDBAC5E109CCE >> 128;
      if (x & 0x4000000 > 0)
        result = result * 0x10000000002C5C85FDF4B15DE6F17EB0D >> 128;
      if (x & 0x2000000 > 0)
        result = result * 0x1000000000162E42FEFA494F1478FDE05 >> 128;
      if (x & 0x1000000 > 0)
        result = result * 0x10000000000B17217F7D20CF927C8E94C >> 128;
      if (x & 0x800000 > 0)
        result = result * 0x1000000000058B90BFBE8F71CB4E4B33D >> 128;
      if (x & 0x400000 > 0)
        result = result * 0x100000000002C5C85FDF477B662B26945 >> 128;
      if (x & 0x200000 > 0)
        result = result * 0x10000000000162E42FEFA3AE53369388C >> 128;
      if (x & 0x100000 > 0)
        result = result * 0x100000000000B17217F7D1D351A389D40 >> 128;
      if (x & 0x80000 > 0)
        result = result * 0x10000000000058B90BFBE8E8B2D3D4EDE >> 128;
      if (x & 0x40000 > 0)
        result = result * 0x1000000000002C5C85FDF4741BEA6E77E >> 128;
      if (x & 0x20000 > 0)
        result = result * 0x100000000000162E42FEFA39FE95583C2 >> 128;
      if (x & 0x10000 > 0)
        result = result * 0x1000000000000B17217F7D1CFB72B45E1 >> 128;
      if (x & 0x8000 > 0)
        result = result * 0x100000000000058B90BFBE8E7CC35C3F0 >> 128;
      if (x & 0x4000 > 0)
        result = result * 0x10000000000002C5C85FDF473E242EA38 >> 128;
      if (x & 0x2000 > 0)
        result = result * 0x1000000000000162E42FEFA39F02B772C >> 128;
      if (x & 0x1000 > 0)
        result = result * 0x10000000000000B17217F7D1CF7D83C1A >> 128;
      if (x & 0x800 > 0)
        result = result * 0x1000000000000058B90BFBE8E7BDCBE2E >> 128;
      if (x & 0x400 > 0)
        result = result * 0x100000000000002C5C85FDF473DEA871F >> 128;
      if (x & 0x200 > 0)
        result = result * 0x10000000000000162E42FEFA39EF44D91 >> 128;
      if (x & 0x100 > 0)
        result = result * 0x100000000000000B17217F7D1CF79E949 >> 128;
      if (x & 0x80 > 0)
        result = result * 0x10000000000000058B90BFBE8E7BCE544 >> 128;
      if (x & 0x40 > 0)
        result = result * 0x1000000000000002C5C85FDF473DE6ECA >> 128;
      if (x & 0x20 > 0)
        result = result * 0x100000000000000162E42FEFA39EF366F >> 128;
      if (x & 0x10 > 0)
        result = result * 0x1000000000000000B17217F7D1CF79AFA >> 128;
      if (x & 0x8 > 0)
        result = result * 0x100000000000000058B90BFBE8E7BCD6D >> 128;
      if (x & 0x4 > 0)
        result = result * 0x10000000000000002C5C85FDF473DE6B2 >> 128;
      if (x & 0x2 > 0)
        result = result * 0x1000000000000000162E42FEFA39EF358 >> 128;
      if (x & 0x1 > 0)
        result = result * 0x10000000000000000B17217F7D1CF79AB >> 128;

      result >>= uint256 (int256 (63 - (x >> 64)));
      require (result <= uint256 (int256 (MAX_64x64)));

      return int128 (int256 (result));
    }
  }

  /**
   * Calculate natural exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp (int128 x) internal pure returns (int128) {
    unchecked {
      require (x < 0x400000000000000000); // Overflow

      if (x < -0x400000000000000000) return 0; // Underflow

      return exp_2 (
          int128 (int256 (x) * 0x171547652B82FE1777D0FFDA0D23A7D12 >> 128));
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return unsigned 64.64-bit fixed point number
   */
  function divuu (uint256 x, uint256 y) private pure returns (uint128) {
    unchecked {
      require (y != 0);

      uint256 result;

      if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        result = (x << 64) / y;
      else {
        uint256 msb = 192;
        uint256 xc = x >> 192;
        if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
        if (xc >= 0x10000) { xc >>= 16; msb += 16; }
        if (xc >= 0x100) { xc >>= 8; msb += 8; }
        if (xc >= 0x10) { xc >>= 4; msb += 4; }
        if (xc >= 0x4) { xc >>= 2; msb += 2; }
        if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

        result = (x << 255 - msb) / ((y - 1 >> msb - 191) + 1);
        require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

        uint256 hi = result * (y >> 128);
        uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

        uint256 xh = x >> 192;
        uint256 xl = x << 64;

        if (xl < lo) xh -= 1;
        xl -= lo; // We rely on overflow behavior here
        lo = hi << 128;
        if (xl < lo) xh -= 1;
        xl -= lo; // We rely on overflow behavior here

        assert (xh == hi >> 128);

        result += xl / y;
      }

      require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return uint128 (result);
    }
  }

  /**
   * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
   * number.
   *
   * @param x unsigned 256-bit integer number
   * @return unsigned 128-bit integer number
   */
  function sqrtu (uint256 x) private pure returns (uint128) {
    unchecked {
      if (x == 0) return 0;
      else {
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) { xx >>= 128; r <<= 64; }
        if (xx >= 0x10000000000000000) { xx >>= 64; r <<= 32; }
        if (xx >= 0x100000000) { xx >>= 32; r <<= 16; }
        if (xx >= 0x10000) { xx >>= 16; r <<= 8; }
        if (xx >= 0x100) { xx >>= 8; r <<= 4; }
        if (xx >= 0x10) { xx >>= 4; r <<= 2; }
        if (xx >= 0x8) { r <<= 1; }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return uint128 (r < r1 ? r : r1);
      }
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

pragma solidity ^0.8.6;

library Roots {

// calculates a^(1/n) to dp decimal places
    // maxIts bounds the number of iterations performed
    function nthRoot(uint _a, uint _n, uint _dp, uint _maxIts) pure internal returns(uint) {
        assert (_n > 1);

        // The scale factor is a crude way to turn everything into integer calcs.
        // Actually do (a * (10 ^ ((dp + 1) * n))) ^ (1/n)
        // We calculate to one extra dp and round at the end
        uint one = 10 ** (1 + _dp);
        uint a0 = one ** _n * _a;

        // Initial guess: 1.0
        uint xNew = one;

        uint iter = 0;
        while (iter < _maxIts) {
            uint x = xNew;
            uint t0 = x ** (_n - 1);
            if (x * t0 > a0) {
                xNew = x - (x - a0 / t0) / _n;
            } else {
                xNew = x + (a0 / t0 - x) / _n;
            }
            ++iter;
            if(xNew == x) {
                break;
            }
        }

        // Round to nearest in the last dp.
        return (xNew + 5) / 10;
    }
}

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

}