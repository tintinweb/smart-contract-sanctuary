// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC721Metadata.sol";
import "./Address.sol";
import "./Context.sol";
import "./ERC165.sol";
import "./IRNG.sol";
import "./Strings.sol";

contract NobilityKnight is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // total number of NFTs Minted
    uint256 private _totalSupply;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // name + bio of knight
    struct KnightData {
        string name;
        string bio;
    }

    // knight data
    mapping( uint256 => KnightData ) knightData;

    // token stats
    mapping(uint256 => uint256) idToLevel;

    // maximum supply which can be minted
    uint256 public constant maxSupply = 4444;

    // nfts baseURL
    string private baseURI = "https://nftapi.nobilitytoken.com/nblknight/";

    // white list spots
    uint256 public remainingWhitelist;
    uint256 public remainingStaffMints;

    // nobility white list nfts
    address private constant whitelistOne = 0x8bA27DD2621ED0ff1fF5F3513ca7aEA81511677F;
    address private constant whitelistTwo = 0x4F86eDcACD3B67Ab8786B030A3eEe4275c7Ca90d;
    uint256 private constant whitelistOneCost = 3194 * 10**14;

    // use wallet
    address public useWallet = 0xcDe5525CF7971cc28759939481FEcc9E45941ff6;

    // base cost to mint NFT
    uint256 public cost = 4444 * 10**14;

    // 6 month white list timeout
    uint256 private constant whitelistTimeout = 5_200_000;
    uint256 public immutable launchTime;

    // time requirements to upgrade to level 2 or 3
    uint256 public constant timeToUpgradeToLevel3 = 5_200_000;
    uint256 public constant timeToUpgradeToDragon = 2_600_000;

    // TokenID => hasMinted
    mapping ( uint256 => bool ) public whitelistOneHasMinted;
    mapping ( uint256 => bool ) public whitelistTwoHasMinted;

    // when the ownership of tokenIDs changes
    mapping ( uint256 => uint256 ) public timeOfAcquisition;

    // Attacking ID -> Defending ID
    mapping ( uint256 => bool ) public lookingForDual;

    // whether dualing is enabled or not
    bool public dualingEnabled;

    // RNG to fetch salt from
    address private RNG;

    // operator
    address public operator;
    modifier onlyOperator() {
        require(msg.sender == operator, 'Only Operator');
        _;
    }

    // has mint started
    bool saleStarted;

    // events
    event Battle(uint256 attackerID, uint256 defenderID, uint256 winningID);
    event SetUseWallet(address useWallet);


    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor() {
        // token stats
        _name = 'Noble Knights';
        _symbol = 'NBLK';

        // split up mints between whitelist + non whitelisted
        remainingStaffMints = 30;

        // Remaining whitelist, no more will be minted that effect NobleKnights
        remainingWhitelist = 242;

        // time of launch
        launchTime = block.number;

        // operator
        operator = msg.sender;
    }


    // owner functions

    function transferOperator(address nOperator) external onlyOperator {
        operator = nOperator;
    }

    function setRNG(address newRNG) external onlyOperator {
        require(newRNG != address(0));
        RNG = newRNG;
    }

    function setStaffMints(uint256 newStaffMints) external onlyOperator {
        remainingStaffMints = newStaffMints;
    }

    function setWhiteListSpots(uint256 newWhiteListSpots) external onlyOperator {
        remainingWhitelist = newWhiteListSpots;
    }

    function changeCost(uint256 newCost) external onlyOperator {
        cost = newCost;
    }

    function startSale() external onlyOperator {
        saleStarted = true;
    }

    function stopSale() external onlyOperator {
        saleStarted = false;
    }

    function changeUseWallet(address newUseWallet) external onlyOperator {
        useWallet = newUseWallet;
        emit SetUseWallet(newUseWallet);
    }

    function enableDualing() external onlyOperator {
        dualingEnabled = true;
    }

    function disableDualing() external onlyOperator {
        dualingEnabled = false;
    }

    function withdraw(address recipient) external onlyOperator {
        (bool s,) = payable(recipient).call{value: address(this).balance}("");
        require(s);
    }

    function overrideWhitelistReservationSlots() external onlyOperator {
        require(launchTime + whitelistTimeout < block.number, 'Must Wait Until Timeout');
        remainingWhitelist = 0;
    }

    function staffMint(address recipient) external onlyOperator {
        require(remainingStaffMints > 0, 'Zero Staff Mints Left');
        // decrement staff mints
        remainingStaffMints--;
        // mint to recipient
        _safeMint(recipient, _totalSupply);
    }

    function setBaseURI(string calldata uri) external onlyOperator {
        baseURI = uri;
    }

    function _baseURI() internal view returns (string memory) {
        return baseURI;
    }


    // external functions

    function fetchIDSForOwner(bool _whitelistOne, address holder, uint256 whitelistTotalSupply) external view returns (uint256[] memory) {
        uint256 count = 0;
    
        for (uint i = 0; i < whitelistTotalSupply; i++) {
            if (IERC721(_whitelistOne ? whitelistOne : whitelistTwo).ownerOf(i) == holder) {
                if (_whitelistOne && !whitelistOneHasMinted[i]) {
                    count++;
                } else if (!_whitelistOne && !whitelistTwoHasMinted[i]) {
                    count++;
                }                
            }
        }

        uint256[] memory ids = new uint256[](count);
        uint256 j;

        if (count == 0) return ids;

        for (uint i = 0; i < whitelistTotalSupply; i++) {
            if (IERC721(_whitelistOne ? whitelistOne : whitelistTwo).ownerOf(i) == holder) {
                if (_whitelistOne && !whitelistOneHasMinted[i]) {
                    ids[j] = i;
                    j++;
                } else if (!_whitelistOne && !whitelistTwoHasMinted[i]) {
                    ids[j] = i;
                    j++;
                }
                
            }
        }

        return ids;
    }

    function burn(uint256 tokenID) external {
        require(_isApprovedOrOwner(_msgSender(), tokenID), "caller not owner nor approved");
        _burn(tokenID);
    }

    function upgradeToLevel3(uint256 tokenID) external {
        require(ownerOf(tokenID) == msg.sender, 'Not Owner');
        require(idToLevel[tokenID] == 1,        'Must Be Level 2');
        require(timeOfAcquisition[tokenID] + timeToUpgradeToLevel3 <= block.number, 'Hold Time Not Met');

        // reset token hold timer
        timeOfAcquisition[tokenID] = block.number;

        // upgrade token ID
        _upgrade(tokenID);
    }

    function setLookingForDual(uint256 tokenID, bool canDual) external {
        require(dualingEnabled,                 'Duals disabled');
        require(_levelOne(tokenID),             'Only LV One');
        require(ownerOf(tokenID) == msg.sender, 'Not Owner');

        lookingForDual[tokenID] = canDual;
    }

    function battleKnight(uint256 attackingID, uint256 targetID) external {
        require(dualingEnabled,                     'Duals disabled');
        require(ownerOf(attackingID) == msg.sender, 'Not Owner');
        require(_exists(targetID),                  'Target Has No Owner');
        require(_levelOne(attackingID),             'Only LV One');
        require(_levelOne(targetID),                'Only LV One');
        require(lookingForDual[targetID],           'Target Not Looking To Dual');

        _battle(attackingID, targetID);
    }

    function battleOwnedKnights(uint256 attackingID, uint256 defendingID) external {
        require(dualingEnabled,                     'Duals disabled');
        require(ownerOf(attackingID) == msg.sender, 'Not Owner of Attacker');
        require(ownerOf(defendingID) == msg.sender, 'Not Owner of Defender');
        require(_levelOne(attackingID),             'Only LV One');
        require(_levelOne(defendingID),             'Only LV One');

        _battle(attackingID, defendingID);
    }

    function _levelOne(uint256 tokenID) internal view returns (bool) {
        return idToLevel[tokenID] == 0;
    }

    function setName(string calldata name_, uint256 tokenID) external {
        require(ownerOf(tokenID) == msg.sender, 'Invalid Owner');
        knightData[tokenID].name = name_;
    }

    function setBio(string calldata bio, uint256 tokenID) external {
        require(ownerOf(tokenID) == msg.sender, 'Invalid Owner');
        knightData[tokenID].bio = bio;
    }
    

    // Minting Functions
    //   Whitelist, Staff, and Regular
    
    function whitelistMint(bool whiteListContractOne, uint256 tokenID) external payable {
        require(saleStarted, 'Sale Not Started');
        require(remainingWhitelist > 0, 'Zero Slots Left');

        if (whiteListContractOne) {
            require(IERC721(whitelistOne).ownerOf(tokenID) == msg.sender, 'Not Owner');
            require(!whitelistOneHasMinted[tokenID], 'Whitelist Slot Already Used');
            require(msg.value >= whitelistOneCost, 'Invalid ETH Sent');

            whitelistOneHasMinted[tokenID] = true;
        } else {
            require(IERC721(whitelistTwo).ownerOf(tokenID) == msg.sender, 'Not Owner');
            require(!whitelistTwoHasMinted[tokenID], 'Whitelist Slot Already Used');
            require(msg.value >= cost, 'Invalid ETH Sent');
            whitelistTwoHasMinted[tokenID] = true;
        }

        // decrement remaining white list spots
        remainingWhitelist--;

        // mint to sender
        _safeMint(msg.sender, _totalSupply);
    }

    /** 
     * Mints New NFT To Caller
     */
    function mint(uint256 nMints) external payable {
        require(saleStarted, 'Sale Not Started');
        require(nMints > 0 && nMints <= 10, '10 Knights Max In One Mint');
        require(_totalSupply + remainingStaffMints + remainingWhitelist < maxSupply, 'Max NFTs Minted');
        require(msg.value >= cost * nMints, 'Invalid ETH Sent');

        for (uint i = 0; i < nMints; i++) {
            _safeMint(msg.sender, _totalSupply);
        }

        (bool s,) = payable(useWallet).call{value: address(this).balance}("");
        require(s, 'Failure On ETH Payment');
    }

    receive() external payable {}



    // internal functions

    function _battle(uint256 attackingID, uint256 defendingID) internal {

        // calculate rng
        uint256 rng = IRNG(RNG).fetchRandom(uint256(uint160(ownerOf(attackingID))), uint256(uint160(ownerOf(defendingID)))) % 2;
        // remove dual
        delete lookingForDual[attackingID];
        delete lookingForDual[defendingID];

        // upgrade winner
        _upgrade( rng == 0 ? attackingID : defendingID);
        // burn loser
        _burn(    rng == 0 ? defendingID : attackingID);

        // emit event
        emit Battle(attackingID, defendingID, rng == 0 ? attackingID : defendingID);
    }

    function _upgrade(uint256 tokenId) internal {
        require(idToLevel[tokenId] < 2, 'Max Knight Level');
        idToLevel[tokenId]++;
    }

    
    // read functions

    function timeLeftUntilUpgrade(uint256 tokenID) external view returns (uint256) {
        if (idToLevel[tokenID] == 0 || ownerOf(tokenID) == address(0)) return 0;
        if (idToLevel[tokenID] == 1) {
            return block.number > timeOfAcquisition[tokenID] + timeToUpgradeToLevel3 ? 0 :  
                    timeOfAcquisition[tokenID] + timeToUpgradeToLevel3 - block.number;
        } else {
            return block.number > timeOfAcquisition[tokenID] + timeToUpgradeToDragon ? 0 :  
                    timeOfAcquisition[tokenID] + timeToUpgradeToDragon - block.number;
        }
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function soldOut() external view returns (bool) {
        return _totalSupply == maxSupply;
    }

    function getIDsByOwner(address owner) external view returns (uint256[] memory) {
        uint256[] memory ids = new uint256[](balanceOf(owner));
        if (balanceOf(owner) == 0) return ids;
        uint256 count = 0;
        for (uint i = 0; i < _totalSupply; i++) {
            if (ownerOf(i) == owner) {
                ids[count] = i;
                count++;
            }
        }
        return ids;
    }

    function fetchIDSLookingToDual() external view returns (uint256[] memory) {
        uint256 count = 0;
        for (uint i = 0; i < _totalSupply; i++) {
            if (lookingForDual[i]) {
                count++;
            }
        }

        uint256[] memory ids = new uint256[](count);
        uint256 j;

        for (uint i = 0; i < _totalSupply; i++) {
            if (lookingForDual[i]) {
                ids[j] = i;
                j++;
            }
        }

        return ids;
    }

    function fetchIDSLookingToDualInIDRange(uint256 lowerBound, uint256 upperBound) external view returns (uint256[] memory) {
        uint256 count = 0;
        for (uint i = lowerBound; i < upperBound; i++) {
            if (lookingForDual[i]) {
                count++;
            }
        }

        uint256[] memory ids = new uint256[](count);
        uint256 j;

        for (uint i = lowerBound; i < upperBound; i++) {
            if (lookingForDual[i]) {
                ids[j] = i;
                j++;
            }
        }

        return ids;
    }

    function getLevel(uint256 tokenId) external view returns (uint256) {
        return idToLevel[tokenId]+1;
    }

    function canUpgradeToDragon(uint256 tokenID) external view returns (bool) {
        return 
            idToLevel[tokenID] == 2 &&
            ownerOf(tokenID) != address(0) &&
            timeOfAcquisition[tokenID] + timeToUpgradeToDragon <= block.number;
    }

    function getName(uint256 tokenID) external view returns (string memory) {
        return knightData[tokenID].name;
    }

    function getBio(uint256 tokenID) external view returns (string memory) {
        return knightData[tokenID].bio;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address wpowner) public view override returns (uint256) {
        require(wpowner != address(0), "query for the zero address");
        return _balances[wpowner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        address wpowner = _owners[tokenId];
        require(wpowner != address(0), "query for nonexistent token");
        return wpowner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "nonexistent token");

        string memory _base = _baseURI();
        return string(abi.encodePacked(_base, tokenId.toString()));
    }

    

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address wpowner = ownerOf(tokenId);
        require(to != wpowner, "ERC721: approval to current owner");

        require(
            _msgSender() == wpowner || isApprovedForAll(wpowner, _msgSender()),
            "ERC721: not approved or owner"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address _operator, bool approved) public override {
        _setApprovalForAll(_msgSender(), _operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address wpowner, address _operator) public view override returns (bool) {
        return _operatorApprovals[wpowner][_operator];
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
    function _burn(uint256 tokenId) internal {
        require(_exists(tokenId), 'Token Does Not Exist');

        // owner of token
        address owner = ownerOf(tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        delete timeOfAcquisition[tokenId];
        delete knightData[tokenId];
        delete lookingForDual[tokenId];

        // decrement balance
        _balances[owner] -= 1;
        delete _owners[tokenId];

        // emit transfer
        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "caller not owner nor approved");
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
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
    ) public override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "caller not owner nor approved");
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
    ) internal {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: nonexistent token");
        address wpowner = ownerOf(tokenId);
        return (spender == wpowner || getApproved(tokenId) == spender || isApprovedForAll(wpowner, spender));
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId
    ) internal {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, ""),
            "ERC721: non ERC721Receiver implementer"
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
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");
        require(_totalSupply < maxSupply, 'Max NFTs Minted');

        _balances[to] += 1;
        _owners[tokenId] = to;
        _totalSupply++;
        timeOfAcquisition[tokenId] = block.number;

        emit Transfer(address(0), to, tokenId);
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
    ) internal {
        require(ownerOf(tokenId) == from, "Incorrect owner");
        require(to != address(0), "zero address");
        require(balanceOf(from) > 0, 'Zero Balance');

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        // reset name + bio
        delete knightData[tokenId];
        delete lookingForDual[tokenId];

        // Allocate balances
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;
        timeOfAcquisition[tokenId] = block.number;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address wpowner,
        address _operator,
        bool approved
    ) internal {
        require(wpowner != _operator, "ERC721: approve to caller");
        _operatorApprovals[wpowner][_operator] = approved;
        emit ApprovalForAll(wpowner, _operator, approved);
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
                    revert("ERC721: non ERC721Receiver implementer");
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
}