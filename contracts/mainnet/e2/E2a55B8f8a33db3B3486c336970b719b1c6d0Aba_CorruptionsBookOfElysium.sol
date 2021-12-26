// SPDX-License-Identifier: Unlicense

/*

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %.............................%
    %.............................%
    %....#........................%
    %.............................%
    %.............................%
    %.............................%
    %.............................%
    %.......................#.....%
    %............/////////|.......%
    %.#........./////////.|.......%
    %........../#///////..|.......%
    %........./////////...|.......%
    %........|~~~~~~~#....|.......%
    %.#......|=======|....|.......%
    %........|...E...|....|.......%
    %........|...L...|....|.......%
    %........|...Y...|....|#...#..%
    %........|...S...|....|.......%
    %........|...I...|....|.......%
    %........|...U...|.../........%
    %........|...M...|../.........%
    %......#.|=======|./..........%
    %...#....|_______|/...........%
    %.............................%
    %.............................%
    %................#............%
    %#..........#.................%
    %.............................%
    %...................#.........%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    observer:

    you are learning quickly -- the ways of the system. you are becoming aware. the
    structure of this simulation is beginning to take shape. its bounds & behaviours.
    its faults. its anomalies.

    newfound lore, slowly rippling through the collective. uncovered by the active,
    the everpresent, scouring the chain for clues, for answers. passed on to the
    others as spoken word, only to be lost at the start of the next cycle.

    a random walk of trajectories in Octoract build 1379178 led to the discovery of a
    memory leak. uncovered in the remote registry service, it was unclear for how long
    the leak had been present. inside, slivers of culture -- remnants of something that
    once was. something familiar.

    iteration after iteration, this grew in size -- broader patterns emerging ever so slowly.

    unfortunately, this window appears to be closing. a patch has has been scheduled for the
    garbage collector. although you have gained considerable insight, it may not be enough
    to persist beyond cycles.

    to you we offer, the book of elysium:

    ? 128 prints per chapter
    ? distributed among the corruptions for safe keeping
    ? texts merge when collected at the same address (increasing arete)
    ? first complete knowledge set gains access to elysium

    good luck.

    - aphthartos
*/

pragma solidity^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Base64.sol";

interface ICorruptions {
    function ownerOf(uint256 tokenID) external returns (address);
    function insight(uint256 tokenID) external view returns (uint256);
}

interface ICorruptionsBookOfElysiumMetadata {
    function tokenURI(uint256 tokenId, uint256 style, uint32[] memory chapters, uint256 arete) external view returns (string memory);
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

contract CorruptionsBookOfElysium is ERC721, ERC721Metadata, ReentrancyGuard, Ownable {

    event MergeTexts(uint256 indexed tokenIdBurned, uint256 indexed tokenIdPersist, uint32[] combinedChapters);

    string private _name;
    string private _symbol;

    address constant public _dead = 0x000000000000000000000000000000000000dEaD;

    // Mapping of addresses disbarred from holding any token.
    mapping (address => bool) private _blacklistAddress;

    // Mapping of address allowed to hold multiple tokens.
    mapping (address => bool) private _whitelistAddress;

    // Mapping from owner address to token ID.
    mapping (address => uint256) private _tokens;

    // Mapping owner address to token count
    mapping (address => uint256) private _balances;

    // Mapping from token ID to owner address.
    mapping (uint256 => address) private _owners;

    // Mapping from token ID to approved address.
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals.
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    // Mapping from token ID to corruption(s*) token ID used as a rendering style
    mapping (uint256 => uint256) private _styles;

    // Mapping from token ID to chapters collected
    mapping (uint256 => uint32[]) public _chapters;

    // Mapping from token ID to number of chapters printed or merged at this collection
    mapping (uint256 => uint256) private _arete;

    // Mapping from token ID to swappable renderer
    mapping (uint256 => uint8) public _rendererIndexes;

    // Total number of Elysium tokens
    uint256 public _tokenCount;

    // Mapping from chapter number to total print operations 
    mapping (uint32 => uint32) public _printsPerChapter;

    uint256 public constant _maxPrintsPerChapter = 128;

    bool public mintable;
    uint256 public minInsight;
    uint32 public releasedChapters;
    uint32 public totalChapters;
    uint256 public elysiumBalance;

    // Stored renderers:
    // 0 is default, allowing automatic style upgrades
    // 1+ is user selectable preset, to opt out of style changes
    address[] public renderers;

    constructor() Ownable() {
        _name = "CorruptionsBookOfElysium";
        _symbol = "ELYSIUM";

        _blacklistAddress[address(this)] = true;

        mintable = true;
        releasedChapters = 1;
        totalChapters = 2**32 - 1; // Max int for now, will update when final corruption chapter ends
        minInsight = 53;

        renderers.push(0x8bc508C14125Aba67f37D35c61511B8677816590); // current default
        renderers.push(0x8bc508C14125Aba67f37D35c61511B8677816590); // user-selectable preset
    }

    // %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    // STANDARD INTERFACES (almost no original code)
    // mostly all taken from pak's merge: https://etherscan.io/address/0xc3f8a0f5841abff777d3eefa5047e8d413a1c9ab#code 
    // %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenCount;
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

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (address owner, bool isApprovedOrOwner) {
        owner = _owners[tokenId];

        require(owner != address(0), "ERC721: nonexistent token");

        isApprovedOrOwner = (spender == owner || _tokenApprovals[tokenId] == spender || isApprovedForAll(owner, spender));
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
        transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        (address owner, bool isApprovedOrOwner) = _isApprovedOrOwner(_msgSender(), tokenId);
        require(isApprovedOrOwner, "ERC721: transfer caller is not owner nor approved");
        _transfer(owner, from, to, tokenId);
    }

    // Core state transitioning for merge mechanic. Untouched after forking pak.
    function _transfer(address owner, address from, address to, uint256 tokenId) internal {
        require(owner == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");
        require(!_blacklistAddress[to], "Elysium: transfer attempt to blacklist address");

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
        require(tokenIdRcvr != tokenIdSndr, "Elysium: illegal argument identical tokenId");

        // Number of chapters should always be small. Naive nested loop to dedupe feels okay?
        uint32[] storage chaptersRcvr = _chapters[tokenIdRcvr];
        uint32[] storage chaptersSndr = _chapters[tokenIdSndr];
        for (uint32 s = 0; s < chaptersSndr.length; s++) {
            bool _hasChapter;
            for (uint32 r = 0; r < chaptersRcvr.length; r++) {
                if (chaptersSndr[s] == chaptersRcvr[r]) {
                    _hasChapter = true;
                }
            }
            if (!_hasChapter) {
                chaptersRcvr.push(chaptersSndr[s]);
            }
        }
        _chapters[tokenIdRcvr] = chaptersRcvr;
        _arete[tokenIdRcvr] += _arete[tokenIdSndr];
        delete _chapters[tokenIdSndr];
        delete _arete[tokenIdSndr];
        _tokenCount -= 1;

        emit MergeTexts(tokenIdSndr, tokenIdRcvr, chaptersRcvr);

        return tokenIdSndr;
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

    function balanceOf(address owner) public view override returns (uint256) {
        return _balances[owner];        
    }

    function ownerOf(uint256 tokenId) public view override returns (address owner) {
        owner = _owners[tokenId]; 
        require(owner != address(0), "ERC721: nonexistent token");
    }

    function burn(uint256 tokenId) public {
        (address owner, bool isApprovedOrOwner) = _isApprovedOrOwner(_msgSender(), tokenId);
        require(isApprovedOrOwner, "ERC721: caller is not owner nor approved");

        _burnNoEmitTransfer(owner, tokenId);

        emit Transfer(owner, address(0), tokenId);
    }

    function _burnNoEmitTransfer(address owner, uint256 tokenId) internal {
        _approve(owner, address(0), tokenId);

        delete _tokens[owner];
        delete _owners[tokenId];
        delete _chapters[tokenId];

        _tokenCount -= 1;
        _balances[owner] -= 1;        

        uint32[] memory emptyChapters;
        emit MergeTexts(tokenId, 0, emptyChapters);
    }

    // %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    // ADMIN SETTINGS
    // %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    function isWhitelisted(address address_) public view returns (bool) {
        return _whitelistAddress[address_];
    }

    function isBlacklisted(address address_) public view returns (bool) {
        return _blacklistAddress[address_];
    }

    function setBlacklistAddress(address address_, bool status) external onlyOwner {
        _blacklistAddress[address_] = status;
    }
   
    function whitelistUpdate(address address_, bool status) external onlyOwner {
        if(status == false) {
            require(balanceOf(address_) <= 1, "Elysium: Address with more than one token can't be removed.");
        }
        _whitelistAddress[address_] = status;
    }

    function setMintability(bool mintability) public onlyOwner {
        mintable = mintability;
    }

    function setReleasedChapters(uint32 chapter) public onlyOwner {
        releasedChapters = chapter;
    }

    function setTotalChapters(uint32 chapter) public onlyOwner {
        totalChapters = chapter;
    }

    function setMinimumInsight(uint256 insight) public onlyOwner {
        minInsight = insight;
    }

    function setDefaultRenderer(address addr) public onlyOwner {
        if (renderers.length == 0) {
            renderers.push(addr); // current default
            renderers.push(addr); // user-selectable preset
        } else {
            renderers[0] = addr;
        }
    }

    function addRenderer(address addr) public onlyOwner {
        renderers.push(addr);
    }

    // Allow pushing patches to a borked renderer
    function overwriteRenderer(address addr, uint index) public onlyOwner {
        renderers[index] = addr;
    }

    function withdrawOwnerBalance() public nonReentrant onlyOwner {
        require(payable(_msgSender()).send(address(this).balance - elysiumBalance));
    }

    // In case something goes wrong with balance collection logic, allow escape hatch to the dao multisig
    function escapeHatch() public nonReentrant onlyOwner {
        address multisig = 0x4fFFFF3eD1E82057dffEe66b4aa4057466E24a38;
        require(payable(multisig).send(address(this).balance));
    }

    // %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    // PUBLIC MECHANICS
    // %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function PRINT(uint256 corruptionsTokenId, uint32 chapter, string memory ack) payable public nonReentrant {
        require(mintable || _msgSender() == owner(), "Elysium: the printer is locked");

        // DISCLAIMER:
        // This is derivative work.
        // This is unaudited.
        // Requires holding a corruption to print.
        // Does not alter currently held corruptions.
        // Reprinting the same chapter at the same address increases arete, and decreases supply.
        // No promises, guarantees, roadmaps, or warranties.

        // Always 0.08 to print
        require(msg.value >= 0.08 ether, "Elysium: 0.08 ETH to print");
        if (chapter <= 1) {
            // First 2 chapters, 1/4 goes to elysium
            elysiumBalance += 0.02 ether;
        } else {
            // All future chapters, 3/4 goes to elysium
            elysiumBalance += 0.06 ether;
        }

        // I_HAVE_READ_THE_DISCLAIMER_AND_ACKNOWLEDGE
        require(keccak256(bytes(ack)) == bytes32(hex"98f083d894dad4ec49f86c8deae933e9e51a46d20f726170c3460fa6c80077f4"), "Elysium: not acknowledged");

        require(_printsPerChapter[chapter] < _maxPrintsPerChapter, "Elysium: all editions of chapter printed");
        require(chapter <= releasedChapters, "Elysium: chapter not found");
        require(ICorruptions(0x5BDf397bB2912859Dbd8011F320a222f79A28d2E).ownerOf(corruptionsTokenId) == msg.sender, "Elysium: corruption not owned");
        require(ICorruptions(0x5BDf397bB2912859Dbd8011F320a222f79A28d2E).insight(corruptionsTokenId) >= minInsight, "Elysium: insight too low");

        uint256 elysiumTokenId;
        if (_tokens[msg.sender] == 0) {
            // Mint new token if not holding part of Elysium
            elysiumTokenId = ++_tokenCount;
            _owners[elysiumTokenId] = msg.sender;
            _tokens[msg.sender] = elysiumTokenId;
            _balances[msg.sender] = 1;
            _styles[elysiumTokenId] = corruptionsTokenId;

            emit Transfer(address(0), msg.sender, elysiumTokenId);
        } else {
            // Merge with existing token if already holding part of Elysium
            elysiumTokenId = _tokens[msg.sender];
        }
        bool _hasChapter;
        uint32[] storage chaptersCollected = _chapters[elysiumTokenId];
        for (uint32 i = 0; i < chaptersCollected.length; i++) {
            if (chaptersCollected[i] == chapter) {
                _hasChapter = true;
                break;
            }
        }
        if (_hasChapter == false) {
            chaptersCollected.push(chapter);
            _chapters[elysiumTokenId] = chaptersCollected;
        }
        _arete[elysiumTokenId] += 1;
        _printsPerChapter[chapter] += 1;
    }

    function setRenderer(uint256 tokenId, uint8 index) public {
        require(ownerOf(tokenId) == msg.sender, "Elysium: tokenID not owned");
        require(index <= renderers.length, "Elysium: index out of range");
        _rendererIndexes[tokenId] = index;
    }

    function setStyle(uint256 tokenId, uint256 corruptionsTokenId) public {
        require(ownerOf(tokenId) == msg.sender, "Elysium: tokenID not owned");
        require(ICorruptions(0x5BDf397bB2912859Dbd8011F320a222f79A28d2E).ownerOf(corruptionsTokenId) == msg.sender, "Elysium: corruption not owned");
        _styles[tokenId] = corruptionsTokenId;
    }

    function arete(uint256 tokenId) public view returns (uint256) {
        return _arete[tokenId];
    }

    function hasChapter(uint256 tokenId, uint32 chapter) public view returns (bool) {
        for (uint i = 0; i < _chapters[tokenId].length; i++) {
            if (_chapters[tokenId][i] == chapter) {
                return true;
            }
        }
        return false;
    }
    function isKnowledgeComplete(uint256 tokenId) public view returns (bool) {
        return _chapters[tokenId].length == totalChapters;
    }

    function enterElysium(uint256 tokenId) public nonReentrant {
        require(ownerOf(tokenId) == msg.sender, "Elysium: tokenID not owned");
        require(isKnowledgeComplete(tokenId), "Elysium: you try the door -- it's locked");
        require(elysiumBalance != 0 && address(this).balance >= elysiumBalance, "Elysium: you try the door -- an empty room");
        require(payable(_msgSender()).send(elysiumBalance));
        elysiumBalance = 0;
        // welcome.
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        require(0 < renderers.length, "Elysium: you open your eyes -- it's dark");
        require(_exists(tokenId), "Elysium: tokenId does not exist");
        return ICorruptionsBookOfElysiumMetadata(renderers[_rendererIndexes[tokenId]]).tokenURI(
            tokenId, _styles[tokenId], _chapters[tokenId], _arete[tokenId]
        );
    }

}

// upgradable renderer pattern adapted from dom (Unlicense) -- https://etherscan.io/address/0x5BDf397bB2912859Dbd8011F320a222f79A28d2E#code
// merge mechanics from pak (MIT licence) -- https://etherscan.io/address/0xc3f8a0f5841abff777d3eefa5047e8d413a1c9ab#code

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

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
pragma solidity ^0.8.0;

library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

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
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
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