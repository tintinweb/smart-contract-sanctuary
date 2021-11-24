// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Holder.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";

abstract contract CattoKatsuTreasuryVoteInterface {
    address public ProposedNewContract;
    function getVotingResults() public view virtual returns (uint256, uint256, uint256, uint256);
}

/**
 * @dev
 *
 * Coding conventions:
 * - Constants: uppercase and snake_case, eg. MY_CONSTANT
 * - Global public variables: capitalized and in camelCase, eg. MyPublicVar
 * - Global private variables: same as public variables, and prefixed with _, eg. _MyPrivateVar
 * - Function params: camelCase, prefixed with _, eg. _myParamVar
 * - Scoped params: camelCase, prefixed with __, eg. __scopedParams
 */
contract CattoKatsu is ERC721Enumerable, ERC721Holder, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Strings for uint256;
    using Address for address;

    CattoKatsuTreasuryVoteInterface private _CattoKatsuTreasuryVoteContract;

    // Constants
    uint256 public constant MAX_SUPPLY = 2500;
    uint256 public constant MAX_MINT_PER_TXN = 5;
    uint256 public constant MAX_MINT_PER_WALLET = 10;
    uint256 public constant MINT_PRICE = 70 ether;
    uint256 public constant PEGGED_INCREMENT = 10 ether;
    uint256 public constant ADOPT_TREASURY_CUT = 10 ether;

    // Core Variables
    address public TreasuryGovContractAddr = address(0);
    uint256 public TreasuryReserve = 0 ether;
    uint256 public PeggedPrice = 10 ether;
    string public TokenBaseURI;
    string public ProvenanceHash;

    // Flags
    bool public IsAdoptionLive = false;
    bool public IsMinting = false;
    bool public MetadataFrozen = false;
    uint256 public MintStartTime = 0;

    // @dev TokenID to URI, see {ERC721URIStorage-_tokenURIs}
    mapping(uint256 => string) private _TokenURIs;

    // @dev OG address to bool
    mapping(address => bool) private _ogList;

    // @dev OG claimed address to bool
    mapping(address => bool) private _ogClaimedList;

    // @dev Catto tokenID to betrayed count
    mapping(uint256 => uint256) private _CattoBetrayedCount;

    // @dev Catto tokenID to adoption status
    mapping(uint256 => bool) private _CattoAdoptionStatus;

    // @dev CattoMinted event
    event CattoMinted(address indexed from, address indexed to, uint256 indexed tokenId);

    // @dev CattoBetrayed event
    event CattoBetrayed(address indexed from, uint256 indexed tokenId, uint256 betrayedCount);

    // @dev CattoAdopted event
    event CattoAdopted(address indexed adopter);

    /**
    * @dev Modifier to ensure adoption feature is on and is able to benefit treasury
    */
    modifier adoptionFeatureConstraint() {
        require(IsAdoptionLive, "Adoption feature not live");
        _;
    }

    /**
    * @dev Constructor for contract deployment
    */
    constructor(string memory _initBaseURI, string memory _provHash, uint256 _mintStartTime) ERC721("Catto Katsu", "CTK") {
        setBaseURI(_initBaseURI);
        setMintStartTime(_mintStartTime);
        ProvenanceHash = _provHash;
    }

    /**
    * @dev Function {ERC721-_baseURI}
    */
    function _baseURI() internal view virtual override returns (string memory) {
        return TokenBaseURI;
    }

    /**
    * @dev Function to allow contract owner to set the baseURI of token assets
    */
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        require(!MetadataFrozen, "Metadata is already frozen");
        TokenBaseURI = _newBaseURI;
    }

    /**
     * @dev See {ERC721URIStorage-_tokenURIs}
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");

        string memory __tokenURI = _TokenURIs[_tokenId];
        string memory __base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(__base).length == 0) {
            return __tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(__tokenURI).length > 0) {
            return string(abi.encodePacked(__base, __tokenURI));
        }

        return super.tokenURI(_tokenId);
    }

    /**
    * @dev Function to allow setting of token URI. See {ERC721URIStorage-_setTokenURI}
    */
    function setTokenURI(uint256 _tokenId, string memory _tokenURI) public onlyOwner {
        require(!MetadataFrozen, "Metadata is already frozen");
        require(_exists(_tokenId), "URI set of nonexistent token");
        _TokenURIs[_tokenId] = _tokenURI;
    }

    /**
    * @dev Function to allow setting of metadata frozen flag
    */
    function setMetadataFrozen(bool _freeze) public onlyOwner {
        MetadataFrozen = _freeze;
    }

    /**
    * @dev Function to allow setting of mint start timestamp
    */
    function setMintStartTime(uint256 _mintStartTime) public onlyOwner {
        MintStartTime = _mintStartTime;
    }

    /**
     * @dev Function to calculates total cost required for the given quantity
     */
    function calculateTotalCost(uint256 _qty) internal pure returns (uint256) {
        return MINT_PRICE.mul(_qty);
    }

    /**
    * @dev Function to allow public minting of CTK
    */
    function mintCatto(uint256 _qty) external payable {
        require(IsMinting, "Mint not activated");
        require(MintStartTime != 0, "Mint time not set");
        require(block.timestamp >= MintStartTime, "Mint not started");
        require(!_msgSender().isContract(), "Contract caller not allowed");
        require(_qty > 0, "Qty must be more than 1");
        require(_qty <= MAX_MINT_PER_TXN, "Qty per txn exceeded max");
        require(balanceOf(_msgSender()) < MAX_MINT_PER_WALLET, "Per wallet mint exceeded");
        require(msg.value == calculateTotalCost(_qty), "Under total mint cost");
        require(totalSupply().add(_qty) <= MAX_SUPPLY, "Qty will exceed max supply");

        _mintCatto(_qty, _msgSender());
    }

    /**
    * @dev Function to allow contract owner to mint to a specific wallet, while respecting the treasury mechanism
    */
    function mintCattoTo(uint256 _qty, address _addr) external payable onlyOwner {
        require(_qty > 0, "Qty must be more than 1");
        require(totalSupply().add(_qty) <= MAX_SUPPLY, "Qty will exceed max supply");
        require(msg.value == _qty.mul(PeggedPrice), "Payable to treasury not met");

        _mintCatto(_qty, _addr);
    }

    /**
     * @dev Function to add addresses to OG list for free mint
     * // todo unit test
     */
    function addToOgList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Invalid address");
            _ogList[addresses[i]] = true;
        }
    }

    /**
     * @dev Function check if address in list, and if already claimed
     */
    function checkOgClaimStatus(address _addr) external view returns (bool, bool) {
        return (_ogList[_addr], _ogClaimedList[_addr]);
    }

    /**
    * @dev Function to allow free-claim list to claim 1 Catto, treasury needs to be topped up manually
    */
    function claimCatto() external nonReentrant {
        address claimer = _msgSender();
        require(_ogList[claimer], "Not in OG list");
        require(!_ogClaimedList[claimer], "Already claimed");
        _mintCatto(1, claimer);
        _ogClaimedList[claimer] = true;
    }

    /**
    * @dev Internal mint func
    *
    * Emits a {IERC721-Transfer} event
    */
    function _mintCatto(uint256 _qty, address _addr) internal {
        for (uint256 i = 0; i < _qty; i++) {
            uint256 __newTokenId = totalSupply();
            _safeMint(_addr, __newTokenId);
            emit CattoMinted(address(0), _addr, __newTokenId);
            TreasuryReserve = TreasuryReserve.add(PeggedPrice);
            _TokenURIs[__newTokenId] = string(abi.encodePacked(uint2str(__newTokenId), ".json"));
        }
    }

    /**
    * @dev Function to get owner's tokenIDs
    */
    function getOwnerTokenIDs(address _owner) public view returns (uint256[] memory) {
        uint256 __balance = balanceOf(_owner);
        uint256[] memory __tokenIDs = new uint256[](__balance);

        for (uint256 i = 0; i < __balance; i++) {
            __tokenIDs[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return __tokenIDs;
    }

    /**
    * @dev Function to override _burn. See {ERC721URIStorage-_burn}
    */
    function _burn(uint256 _tokenId) internal override {
        super._burn(_tokenId);

        if (bytes(_TokenURIs[_tokenId]).length != 0) {
            delete _TokenURIs[_tokenId];
        }
    }

    /**
    * @dev Function to allow owner to withdraw funds from contract, minus the treasury reserve
    */
    function withdraw(address _to, uint256 _requestedAmt) external onlyOwner {
        require(_to != address(0));
        uint256 __currentBal = address(this).balance;
        uint256 __allowableAmt = __currentBal.sub(TreasuryReserve);
        require(__allowableAmt > 0, "Nothing to withdraw");
        require(_requestedAmt <= __allowableAmt, "Amount exceeded allowable");

        (bool success,) = _to.call{value: _requestedAmt}("");
        require(success, "Withdrawal failed.");
    }

    /**
    * @dev Function to allow owner to sell back the token back to the contract at a standard pegged price
    *
    * Emits a {CattoBetrayed} event.
    */
    function betrayCatto(uint256 _tokenId) external nonReentrant adoptionFeatureConstraint {
        require(ownerOf(_tokenId) == _msgSender(), "Catto does not belongs to caller");
        address __self = address(this);
        require(__self.balance >= PeggedPrice, "Not enough funds to buy back token");

        // transfer token owner's catto to contract
        safeTransferFrom(_msgSender(), __self, _tokenId);

        // reduce TreasuryReserve amount
        TreasuryReserve = TreasuryReserve.sub(PeggedPrice);

        // increment catto betrayed count and add to adoption list
        _CattoBetrayedCount[_tokenId] = _CattoBetrayedCount[_tokenId].add(1);
        _CattoAdoptionStatus[_tokenId] = true;

        // pay the betrayer "30 pieces of silver"
        (bool success,) = _msgSender().call{value: PeggedPrice}("");
        require(success, "Transfer failed.");

        emit CattoBetrayed(_msgSender(), _tokenId, _CattoBetrayedCount[_tokenId]);
    }

    /**
     * @dev Function to allow existing catto owner to adopt abandoned cattos
     *
     * Emits a {CattoAdopted} event.
     */
    function adoptCatto(uint256 _tokenId) external payable nonReentrant adoptionFeatureConstraint {
        require(_CattoAdoptionStatus[_tokenId], "Catto is not put up for adoption");
        require(msg.value == calculateAdoptionPrice(_tokenId), "Incorrect adoption fee sent");

        // transfer adopted catto to adopter
        _transfer(address(this), _msgSender(), _tokenId);

        uint256 __maxTreasuryReserve = MAX_SUPPLY.mul(MINT_PRICE);

        // fill the treasury till it can cover max supply total mint cost
        if (TreasuryReserve < __maxTreasuryReserve) {
            TreasuryReserve = TreasuryReserve.add(ADOPT_TREASURY_CUT);
        }

        // update adoption status
        _CattoAdoptionStatus[_tokenId] = false;

        emit CattoAdopted(_msgSender());
    }

    function calculateAdoptionPrice(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "Token ID does not exists");
        uint256 betrayedCount = _CattoBetrayedCount[_tokenId];
        return betrayedCount.mul(PeggedPrice) + PEGGED_INCREMENT;
    }

    function getAdoptionMetaById(uint256 _tokenId) public view returns (uint256, bool) {
        require(_exists(_tokenId), "Token ID does not exists");
        return (_CattoBetrayedCount[_tokenId], _CattoAdoptionStatus[_tokenId]);
    }

    /**
    * @dev Function to increase pegged price
    */
    function incrementPeggedPrice() external onlyOwner {
        uint256 _newPeggedPrice = PeggedPrice.add(PEGGED_INCREMENT);
        uint256 _requiredTreasuryReserve = MAX_SUPPLY.mul(_newPeggedPrice);
        require(TreasuryReserve >= _requiredTreasuryReserve, "Treasury amount insufficient");
        PeggedPrice = _newPeggedPrice;
    }

    /**
    * @dev Function to add funds to treasury
    */
    function addFundsToTreasury() external onlyOwner payable {
        TreasuryReserve = TreasuryReserve.add(msg.value);
    }

    /**
    * @dev Function to add funds to contract
    */
    function addFunds() external onlyOwner payable {}

    /**
     * @dev Function to toggle minting status
     */
    function toggleMintingStatus() external onlyOwner {
        IsMinting = !IsMinting;
    }

    /**
     * @dev Function to toggle adoption features
     */
    function toggleAdoptionFeature() external onlyOwner {
        IsAdoptionLive = !IsAdoptionLive;
    }

    /**
     * @dev Function to set treasury voting contract address
     */
    function setTreasuryGovContractAddr(address _addr) external onlyOwner {
        require(TreasuryGovContractAddr == address(0), "Treasury contract address already set");
        require(_addr.isContract(), "Non-contract address not allowed");
        TreasuryGovContractAddr = _addr;
        _CattoKatsuTreasuryVoteContract = CattoKatsuTreasuryVoteInterface(_addr);
    }

    /**
    * @dev Function to allow draining of entire amount in contract, authorized by a governance contract, and voted upon by token holders
    * The purpose of having this is to ensure that in an event where the contract needs to be upgraded and migrated to a new version,
    * the community will still have access to the treasury reserve, by withdrawing the amount to the new contract
    */
    function migrateTreasury() external {
        require(_msgSender() == TreasuryGovContractAddr, "Caller not treasury governance contract");

        (uint256 _positives, uint256 _negatives,,) = _CattoKatsuTreasuryVoteContract.getVotingResults();
        require(_positives > _negatives, "Vote did not pass");

        address _transferTo = _CattoKatsuTreasuryVoteContract.ProposedNewContract();
        require(_transferTo != address(0), "Cannot transfer to blackhole");
        require(_transferTo.isContract(), "Receiver not contract");

        (bool success,) = _transferTo.call{value: address(this).balance}("");
        require(success, "Fund drain failed.");
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

}