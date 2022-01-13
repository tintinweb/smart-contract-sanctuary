// SPDX-License-Identifier: UNLICENSED

pragma solidity = 0.8.1;

import "./ArtLoaning.sol";
import "./ArtSketch.sol";

/**
    @dev Final Kryptinsky contract - the one that is deployed.
        Inherits from ArtSketch <= KryptinskyNFT <= (AbstractArt, ArtworkCombination, ERC721)
*/
contract Kryptinsky is ArtSketch{

    constructor(address root,
        address modelManagerAddress,
        address artMarketAddress,
        address loanOutAddress){

        transferOwnership(root);
        modelManager = ModelManager(modelManagerAddress);
        approvedOperators.push(artMarketAddress);
        approvedOperators.push(loanOutAddress);
    }



    /**
        @dev baseUri for metadata, e.g. for external NFT markets.
    */
    string baseURI = "http://kryptinsky.art/metadata/";
    function _baseURI() internal override view returns(string memory){
        return baseURI;
    }
    function setBaseURI(string memory newBaseURI) external onlyOwner{
        baseURI = newBaseURI;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.1;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./KryptinskyNFT.sol";


contract ArtLoaning is Ownable{

    address mainContractAddress;
    KryptinskyNFT mainContract;

    function setMainContract(address _addr) external onlyOwner{
        require(mainContractAddress == address(0));
        mainContractAddress = _addr;
        mainContract = KryptinskyNFT(_addr);
    }

    struct LoanOutOffer{
        address owner;
        bool exists;
        bool autoSeal;
        uint128 price;
        uint16 maxLoans;
        uint16 loansDone;
    }

    event LoanOutOfferCreated(uint256 artId, uint128 price, uint16 maxLoans, bool autoSeal);
    event LoanOutCancelled(uint256 artId);

    mapping(uint256 => LoanOutOffer) public loanOutOffers;

    /*
        Loaning Fee can be adjusted by contract owner (Starts at 10%)
        Can be set to a maximum of 20% (or lower)
    */
    uint private maxFeeCut = 20000;
    uint private loaningFeeCut = 10000;

    function getLoaningFeeCut() public view returns(uint){
        return loaningFeeCut;
    }

    function setLoaningFeeCut(uint newFeeCut) external onlyOwner{
        require(newFeeCut <= maxFeeCut);
        loaningFeeCut = newFeeCut;
    }

    /**
        Create a loanout offer for artwork #artId.
        Saves owner, in case artwork is sold (or put in market) after loan-out created.
    */
    function loanOut(uint256 artId,
        uint128 price,
        uint16 maxLoans,
        bool autoSeal) external{

        require(msg.sender == mainContract.ownerOf(artId));

        loanOutOffers[artId].owner = msg.sender;
        loanOutOffers[artId].exists = true;
        loanOutOffers[artId].price = price;
        loanOutOffers[artId].maxLoans = maxLoans;
        loanOutOffers[artId].loansDone = 0;
        loanOutOffers[artId].autoSeal = autoSeal;
        emit LoanOutOfferCreated(artId, price, maxLoans, autoSeal);
    }

    function deleteLoanOutOffer(uint256 artId) private {
        loanOutOffers[artId].exists=false;
        delete loanOutOffers[artId];
        emit LoanOutCancelled(artId);
    }

    function cancelLoanOutOffer(uint256 artId) external{
        require(msg.sender == mainContract.ownerOf(artId));
        deleteLoanOutOffer(artId);
    }

    function getFeeCut(uint256 amount) private view returns(uint256){
        return amount * loaningFeeCut / 100000;
    }

    function takeLoan(uint256 ownArt, uint256 loanedArt, uint32 modelId) external payable returns(uint256){
        require(loanOutOffers[loanedArt].exists, "No loan-out offer for this piece.");
        require(loanOutOffers[loanedArt].loansDone < loanOutOffers[loanedArt].maxLoans, "The loan-out offer has expired.");

        address buyer = mainContract.ownerOf(ownArt);
        address seller = mainContract.ownerOf(loanedArt);

        require(buyer == msg.sender);
        require(seller == loanOutOffers[loanedArt].owner, "Artwork was sold.");

        uint256 price = loanOutOffers[loanedArt].price;
        require(msg.value >= price, "Not enough funds sent");

        uint256 feeCut = getFeeCut(loanOutOffers[loanedArt].price);
        bool autoSeal = loanOutOffers[loanedArt].autoSeal;

        loanOutOffers[loanedArt].loansDone++;
        if (loanOutOffers[loanedArt].loansDone == loanOutOffers[loanedArt].maxLoans){
            deleteLoanOutOffer(loanedArt);
        }

        //Prevents reentrancy through cool-down
        uint256 artId = mainContract.combineArt{value: msg.value - price}(buyer, ownArt, loanedArt, autoSeal, modelId);

        payable(seller).transfer(price - feeCut);

        return artId;
    }

    function withdraw(uint256 amount, address receiver) external onlyOwner{
        payable(receiver).transfer(amount);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.1;

import "./KryptinskyNFT.sol";

/**
    @dev Contract that handles Sketches (stored random seeds that can be used to create a new artwork later):
        Users create a sketch: Random seed, parents and modelId are stored.
        These are sufficient to deterministically call geneMixing of the corresponding model with the random seed =>
        Allows users to view an artwork before it is actually stored on the blockchain and either finish or discard it.
*/
contract ArtSketch is KryptinskyNFT {

    struct RandomSketch{
        uint256 p1;
        uint256 p2;
        uint32 modelId;
        uint224 randomSeed;
    }

    // Emitted when new sketch created - does not contain actual random seed!
    event SketchCreated(address owner, uint256 sketchId, uint256 p1, uint256 p2, uint32 modelId);
    event SketchRemoved(address owner, uint256 sketchId);

    // Each artwork can be used to create a sketch every 8 hours -> Cool-down blocktime + 8 hours.
    // However, it's possible to convert an existing sketch into an artwork 8 hours before cool-down ends =>
    // Can create sketch and, if they like it, convert it into an artwork immediately.
    uint64 sketchCoolDown = uint64(8 hours);

    // For each user address, each sketch is assigned a random ID (created in frontend - no danger of exploitation)
    mapping(address => mapping(uint256 => RandomSketch)) randomSketches;

    function getSketch(address owner, uint256 id) public view returns(RandomSketch memory){
        return randomSketches[owner][id];
    }


    /**
        @dev Allows user to create a sketch for two parents, for a specific modelId.
               Random ID is set by user/frontend.
        @param p1 parent1
        @param p2 parent2
        @param sketchId (random) ID for the sketch - generated by user or frontend.
        @param modelId Id of the model used for gene mixing. The resulting artwork will also have this modelId.
    */
    function createSketchFor(uint256 p1, uint256 p2, uint256 sketchId, uint32 modelId) public {

        // Checks if owner (onlyArtOwner)
        require(_isApprovedOrOwner(msg.sender, p1));
        require(_isApprovedOrOwner(msg.sender, p2));

        // Checks if Sealed
        require(!artworks[p1].isSealed && !artworks[p2].isSealed, "Sealed!");

        // Checks if artworks are close relatives
        require(modelManager.models(modelId).canGraft(p1, p2), "MCG");

        // Checks if they are on CoolDown
        setCoolDown(p1, sketchCoolDown);    //setCoolDown also checks the cool-down
        setCoolDown(p2, sketchCoolDown);

        randomSketches[msg.sender][sketchId] = RandomSketch({
                p1:p1,
                p2:p2,
                modelId: modelId,
                randomSeed:uint224(modelManager.models(modelId).getRandomCanvas())}
            );

        emit SketchCreated(msg.sender, sketchId, p1, p2, modelId);
    }

    /**
        @dev sketch is accessed through mapping[msg.sender] => no additional ownership checks required.
        @param sketchId ID of sketch (IDs are unique for each user - it's possible for two owner addresses to have a sketch of same ID.)
    */
    function realizeSketch(uint256 sketchId) external payable{

        // ownership checked by main contract (in combineArt)
        // coolDown --"--
        // model and graftOk checked on sketch creation

        uint256 p1 = randomSketches[msg.sender][sketchId].p1;
        uint256 p2 = randomSketches[msg.sender][sketchId].p2;
        uint32 modelId = randomSketches[msg.sender][sketchId].modelId;
        uint240 rndSeed = randomSketches[msg.sender][sketchId].randomSeed;

        //If the rndSeed is not > 0, Sketch does not exist.
        require(rndSeed > 0, "Sketch not available.");

        // Sketches can be converted into artworks immediately after creation despite cool-down.
        artworks[p1].coolDownEnd -= sketchCoolDown;
        artworks[p2].coolDownEnd -= sketchCoolDown;

        // Owner of new artwork is msg.sender: This is guaranteed to be owner of sketch because of structure of mapping.
        _combineArt(msg.sender, p1, p2, rndSeed, false, modelId);

        deleteSketch(sketchId);
    }

    /**
        @dev deletes sketch with ID sketchId from sketches[msg.sender]
        @param sketchId ID of sketch to be deleted.
    */
    function deleteSketch(uint256 sketchId) public {
        // Can only delete own sketch(by msg.sender)
        delete randomSketches[msg.sender][sketchId];
        emit SketchRemoved(msg.sender, sketchId);
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.1;

import "./ArtModel.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./AbstractArt.sol";
import "./ModelManager.sol";

interface ArtworkCombination {
    function combineArt(address newOwner, uint256 first, uint256 second, bool autoSeal, uint32 modelId) external payable returns(uint256);
}

/**
 @title Main contract for Kryptinsky NFT
 @dev Handles Kryptinsky definition, minting, combination.
 Inherits from AbstractArt (Struct and datastructures)
    and ArtworkCombination (so that external contracts can easily get an interface to interact
    with combine, e.g. ArtLoaning)
*/
contract KryptinskyNFT is Ownable, ERC721,
                            AbstractArt, ArtworkCombination{

    ModelManager modelManager;

    event ArtworkTitled(uint256 artId, string title);
    event ArtworkSealed(uint256 artId);

    constructor() ERC721("KryptinskyNFT", "KRPTNSKY") {}

    event NewArtwork(uint256 id,
        address owner,
        uint256 p1,
        uint256 p2,
        uint32 modelId,
        uint32 generation
    );

    modifier onlyArtOwner(uint256 artworkId){
        _isApprovedOrOwner(msg.sender, artworkId);
        _;
    }

    uint64 graftingBaseCoolDown = uint64(24 hours);

    /**
        @dev to regulate amount of Kryptinskies, there's a cool-down after grafting.
        This increases with number of children and generation.
        @param artId Calculates cool-down for this art-Id.
    */
    function getGraftingCoolDown(uint256 artId) public view returns(uint64){
        return getGraftingCoolDown(artworks[artId].generation, artworks[artId].numChildren);
    }
    /**
        @dev Get cool-down directly for generation and number of children.
    */
    function getGraftingCoolDown(uint32 generation, uint32 numChildren) private view returns(uint64){
        return graftingBaseCoolDown + uint64( (generation + numChildren) * 4 hours);
    }

    /**
        @dev requires that the artwork is currently not on cool-down, then sets the cool-down.
            e.g. New cool-down 8 hours => This function sets cool-down for artwork #artId to block.timestamp + cool-down
    */
    function setCoolDown(uint256 artId, uint64 coolDown) internal{
        require(block.timestamp >= artworks[artId].coolDownEnd, "On Cool-down");
        artworks[artId].coolDownEnd = uint64(block.timestamp) + coolDown;
    }

    /**
        @dev Called by all means of adding a new artwork
            - Requires that the artwork does not exist (by gene-hash - prevents accidental double minting)
            - Adds new artwork to the mapping
            - Calls the ERC721 method mint - Transfer event
            - emits NewArtwork event
            - returns gene-hash
        @param new_art All the artInfo, including genes
        @param owner New owner of the NFT.
    */
    function createArtwork(Artwork memory new_art, address owner) private returns(uint256){

        uint256 id = uint256(keccak256(abi.encodePacked(new_art.genes)));

        //Should only happen if owner of model tries to double mint.
        require(!artworks[id].exists, "An artwork with the same genes already exists.");

        artworks[id] = new_art;

        _safeMint(owner, id);

        emit NewArtwork(id, owner, new_art.p1, new_art.p2, new_art.modelId, new_art.generation);

        return id;
    }

    /**
        @dev for two parents, calculate generation of child ( = max(p1.generation, p2.generation) + 1 )
    */
    function getChildGeneration(uint256 p1, uint256 p2) private view returns(uint32){
        uint32 new_generation = artworks[p1].generation + 1;
        if(artworks[p2].generation > artworks[p1].generation){
            new_generation = artworks[p2].generation + 1;
        }
        return(new_generation);
    }

    /**
        @dev given two parents, a random seed and the ID of the model used for mixing, return genes of offspring
        @param p1 parent1
        @param p2 parent2
        @param randomSeed Usually generated by model (e.g. stored in sketch or directly generated in combine)
        @param modelId ID of model used for mixing. Offspring will have this modelId.
    */
    function getCanvasGenes(uint256 p1, uint256 p2, uint256 randomSeed, uint32 modelId) public view returns(bytes32[] memory){
        return modelManager.models(modelId).geneMixing(p1, p2, randomSeed);
    }

    /**
        @dev internal function for artwork combination - Called every time two artworks combine, whether directly or from sketch.
            checks that they are not sealed, and checks and sets the new cool-down.
        @param newOwner owner of new Artwork
        @param p1 parent1
        @param p2 parent2
        @param randomSeed random seed used for gene mixing
        @param autoSeal if set, resulting artwork is sealed immediately
        @param modelId model used for mixing
    */
    function _combineArt(address newOwner, uint256 p1, uint256 p2, uint256 randomSeed, bool autoSeal, uint32 modelId)
            internal returns(uint256) {

        require(_isApprovedOrOwner(msg.sender, p1) &&
            _isApprovedOrOwner(msg.sender, p2), "No permission");
        require(!artworks[p1].isSealed && !artworks[p2].isSealed, "Sealed");

        //Also checks cool-down and reverts if not ok.
        setCoolDown(p1, getGraftingCoolDown(p1));
        setCoolDown(p2, getGraftingCoolDown(p2));

        artworks[p1].numChildren += 1;
        artworks[p2].numChildren += 1;

        bytes32[] memory newGenes = getCanvasGenes(p1, p2, randomSeed, modelId);
        uint32 generation = getChildGeneration(p1, p2);

        ArtModel model = modelManager.models(modelId);

        //Forward msg.value to pay the grafting fee to the model contract
        model.payGraft{value: msg.value}(p1, p2);

        uint256 newIdx = createArtwork(Artwork({
        creationTime: uint56(block.timestamp),
        coolDownEnd: getGraftingCoolDown(generation, 0),
        p1: p1,
        p2: p2,
        modelId: modelId,
        generation: generation,
        numChildren: 0,
        title: "",
        isSealed: autoSeal,
        exists: true,
        genes: newGenes
        }), newOwner);

        if(autoSeal) emit ArtworkSealed(newIdx);

        return newIdx;
    }

    /**
        @dev external function for direct combination of two artworks. Also called e.g by artLoaning.
                Can NOT set random seed!
        @param newOwner Owner of new artwork
        @param p1 parent1
        @param p2 parent2
        @param autoSeal Whether offspring is sealed immediately (e.g. when called from loan-out)
        @param modelId model used for gene mixing.
    */
    function combineArt(address newOwner, uint256 p1, uint256 p2, bool autoSeal, uint32 modelId)
        external payable override returns(uint256){

        ArtModel model = modelManager.models(modelId);
        //Checks if models and artworks are compatible
        require(model.canGraft(p1, p2));

        uint256 randomSeed = model.getRandomCanvas();

        return _combineArt(newOwner, p1, p2, randomSeed, autoSeal, modelId);
    }

    /**
        @dev Create a new Gen-0 Artwork. Can only be called by the owner of the model.
            Also checks whether this model is still allowed for minting (e.g. gen0 limit not exceeded)
        @param modelId msg.sender has to be allowed to mint for this model.
        @param genes Genes for artwork. Has to be unique.
        @param title Give title immediately
    */
    function mint_art(uint32 modelId, bytes32[] calldata genes, string calldata title) external payable returns(uint256){

        require(modelManager.isValidModelId(modelId), "NM");
        require(modelManager.models(modelId).allowedToMint(msg.sender), "NAM");
        require(modelManager.models(modelId).areValidGenes(genes), "NVG");

        modelManager.models(modelId).mint{value:msg.value}();

        uint256 idx =  createArtwork(
            Artwork({
            creationTime: uint64(block.timestamp),
            coolDownEnd: uint64(0),
            p1: 0,
            p2: 0,
            modelId: modelId,
            numChildren: 0,
            generation: 0,
            title: title,
            isSealed: false,
            exists: true,
            genes: genes
        }), msg.sender);

        if(bytes(title).length > 0) emit ArtworkTitled(idx, title);

        return idx;
    }

    /**
     @dev Seals an artwork - sealed artworks cannot be used to create a new one. Cannot be undone by anyone.
            Useful before selling.
    */
    function sealArtwork(uint256 artworkId) external onlyArtOwner(artworkId){
        require(!artworks[artworkId].isSealed);
        artworks[artworkId].isSealed = true;
        emit ArtworkSealed(artworkId);
    }
    /**
        @dev Allows the owner of an artwork to give it a title. Titles cannot be changed.
    */
    function giveTitle(uint256 artworkId, string calldata new_title) external onlyArtOwner(artworkId){
        require(bytes(artworks[artworkId].title).length == 0);
        artworks[artworkId].title = new_title;
        emit ArtworkTitled(artworkId, new_title);
    }

    /**
     @dev Need to override...
    */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal virtual
    override(ERC721)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     @dev Need to override...
    */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     @dev Operator approval does not work without override...
    */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual override returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    address[] public approvedOperators;
    bool public approvesSealed = false;
    /**
     @dev Approved Addresses are set in Kryptinsky.sol by Owner (e.g. market, loaning, opensea, ...)
    */
    function isApprovedForAll(address _owner, address _operator) public override view returns(bool){
        for(uint i = 0; i < approvedOperators.length; i++){
            if(approvedOperators[i] == _operator){
                return true;
            }
        }
        return ERC721.isApprovedForAll(_owner, _operator);
    }

    /**
    @dev Can add new approved Operators (e.g. loan-out, market, offers, opensea, ...) Until sealed.
           Seal so that no malicious contracts can be approved once everything is up and running.
    */
    function sealApproved() external onlyOwner{
        require(!approvesSealed);
        approvesSealed = true;
    }
    /**
        @dev Can only be called until approved operators are sealed.
        @param _approvedAddress Address of approved operator
    */
    function addApprovedOperators(address _approvedAddress, uint256 _index) external onlyOwner{
        require(!approvesSealed);
        if(_index < approvedOperators.length){
            approvedOperators[_index] = _approvedAddress;
        } else{
            approvedOperators.push(_approvedAddress);
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

import "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity =0.8.1;

abstract contract ArtModel is Ownable{

    string public description;

    function initialize() public virtual;

    function allowedToMint(address) public virtual view returns(bool);
    function mint() public payable virtual;

    function geneMixing(uint256 p1, uint256 p2) public virtual returns(bytes32[] memory){
        return geneMixing(p1, p2, getRandomCanvas());
    }

    function geneMixing(uint256 p1, uint256 p2, uint256 randomSeed) public virtual view returns(bytes32[] memory);

    function areValidGenes(bytes32[] memory genes) public virtual view returns(bool);

    function getRandomCanvas() public virtual view returns(uint256);

    function getGraftingPrice(uint256 p1, uint256 p2) public virtual view returns(uint256);

    function payGraft(uint256 p1, uint256 p2) external payable{
        require(msg.value >= getGraftingPrice(p1, p2), "Not enough funds sent.");
    }

    function withdraw(uint256 _amount, address _to) external onlyOwner(){
        payable(_to).transfer(_amount);
    }

    function canGraft(uint256 p1, uint256 p2) view public virtual returns(bool);
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.1;

/**
    @dev Introduces the struct where all of the information about an artwork is stored.
            Mapping uint256 (keccak256 of genes) => ArtInfo
            Some public functions for external contracts (such as models) to fetch info.
*/
abstract contract AbstractArt {

    struct Artwork{

        uint256 p1;
        uint256 p2;

        uint64 creationTime;
        uint64 coolDownEnd;

        uint32 generation;
        uint32 modelId;
        uint32 numChildren;

        bool exists;
        bool isSealed;

        string title;

        bytes32[] genes;
    }

    mapping(uint256 => Artwork) artworks;

    function getArtInfo(uint256 artId) public view returns(Artwork memory){
        return artworks[artId];
    }
    function getModelId(uint256 artId) public view returns(uint32){
        return artworks[artId].modelId;
    }
    function getParents(uint256 artId) public view returns(uint256, uint256){
        return (artworks[artId].p1, artworks[artId].p2);
    }
    function getGenes(uint256 artId) public view returns(bytes32[] memory){
        return artworks[artId].genes;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.1;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ArtModel.sol";

/**
    @dev Contract that manages models -
        Owner can create proposal for new model. Owner of that model can accept proposal (by paying).
*/
contract ModelManager is Ownable{

    ArtModel[] public models;

    constructor(address adr){
        transferOwnership(adr);
    }

    struct ModelProposal{
        address owner;
        address contractAddress;
        uint256 price;
        bool is_valid;
    }
    ModelProposal[] model_proposals;

    function getProposal(uint256 proposalId) external view returns(ModelProposal memory){
        return model_proposals[proposalId];
    }

    function createProposal(
    address _owner,
    address _modelContract,
    uint256 _modelPrice
    ) external onlyOwner returns(uint256){
        model_proposals.push(
            ModelProposal(
                _owner,
                _modelContract,
                _modelPrice,
                true
            )
        );
        return model_proposals.length - 1;
    }

    function accept_proposal(uint256 proposal_id) external payable returns(uint256){

        require(msg.value >= model_proposals[proposal_id].price);
        require(msg.sender == model_proposals[proposal_id].owner);
        require(model_proposals[proposal_id].is_valid);

        model_proposals[proposal_id].is_valid = false;
        models.push(ArtModel(model_proposals[proposal_id].contractAddress));

        models[models.length -1].initialize();
        return models.length - 1;
    }

    function isValidModelId(uint256 modelId) external view returns(bool){
        return modelId < models.length;
    }

    function cancelProposal(uint256 proposal_id) external onlyOwner{
        model_proposals[proposal_id].is_valid = false;
    }

    function withdraw(uint256 amount, address receiver) external onlyOwner{
        payable(receiver).transfer(amount);
    }
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