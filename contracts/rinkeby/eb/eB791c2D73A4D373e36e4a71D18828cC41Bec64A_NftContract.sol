// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './IERC165.sol';
import './IERC721.sol';
import './IERC721Metadata.sol';
import './IERC721Receiver.sol';

/**
 * @dev Minimal ERC721 with projects
 * 
 * Does not implement enumerable to reduce gas cost and since Transfer events are used everywhere anyway to calculate ownership
 * 
 * It is also possible to iterate ownerOf for all tokenIds by using projectIdLast() & project(projectId).projectTokenCount
 * projectTokenIDs = projectId * PROJECT_BUCKET_SIZE + [0..projectTokenCount]
 */
contract NftContract is IERC165 
, IERC721
, IERC721Metadata
{
    constructor () {
        _artist = msg.sender;
    }

    // Permissions ---
    address private _artist;
    modifier onlyArtist(){
        require(_artist == msg.sender, 'a');
        _;
    }

    // Interfaces ---
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public pure override(IERC165) returns (bool) {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId
            ;
    }

    // Metadata ---
    function name() public pure override(IERC721Metadata) returns (string memory) {
        return 'RickLove';
    }

    function symbol() public pure override(IERC721Metadata) returns (string memory) {
        return 'RICKLOVE';
    }

    string private _baseURI = 'https://ricklove.me/art/_metadata/main/';
    function setBaseURI(string memory baseURI) public onlyArtist {
        _baseURI = baseURI;
    }

    // Open sea contractURI to get open sea metadata
    // https://docs.opensea.io/docs/contract-level-metadata
    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(_baseURI, 'contract.json'));
    }
    // Token Metadata:
    // https://docs.opensea.io/docs/metadata-standards
    function tokenURI(uint256 tokenId) public view override(IERC721Metadata) returns (string memory) {
        return string(abi.encodePacked(_baseURI, _uint2str(tokenId), '.json'));
    }
    function _uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return '0';
        }
        uint256 temp = _i;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (_i != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(_i % 10)));
            _i /= 10;
        }
        return string(buffer);
    }

    // Token Ownership ---
    uint256 private _totalSupply;
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    // uint256 private _projectIdLast;

    /** tokenId => owner */ 
    mapping (uint256 => address) private _owners;
    function ownerOf(uint256 tokenId) public view override(IERC721) returns (address) {
        return _owners[tokenId];
    }

    /** Owner balances */
    mapping(address => uint256) private _balances;
    function balanceOf(address user) public view override(IERC721) returns (uint256) {
        return _balances[user];
    }

    // Minting (with projects) --- 
    uint32 constant PROJECT_BUCKET_SIZE = 1000000;
    uint256 private _projectIdLast;
    mapping (uint256 => uint32) private _projectTokenSupply;
    mapping (uint256 => uint32) private _projectTokenCount;
    mapping (uint256 => uint256) private _projectMintPrice;

    function projectIdLast() view public returns (uint256) {
        return _projectIdLast;
    } 
    function projectDetails(uint256 projectId) view public returns (uint32 projectTokenSupply, uint32 projectTokenCount, uint256 projectMintPrice) {
        projectTokenSupply = _projectTokenSupply[projectId];
        projectTokenCount = _projectTokenCount[projectId];
        projectMintPrice = _projectMintPrice[projectId];
    }


    /** set project data (Control mintability)
     *
     * Avoid skipping projectIds for new projects - since projectIdLast = max(projectIds)
     *
     * - newProjectId = projectIdLast()
     * 
     */
    function createProject(uint256 projectId, uint32 reserveTokenCount, uint256 projectMintPrice) public onlyArtist {
        // Don't break math (could be ignored if careful externally)
        require(reserveTokenCount <= PROJECT_BUCKET_SIZE, 'S');
 
        // Ensure project has no tokens
        require(_projectTokenCount[projectId] == 0, 'b');
 

        _projectIdLast = projectId > _projectIdLast ? projectId : _projectIdLast;

        _totalSupply += reserveTokenCount;
        _projectTokenSupply[projectId] = reserveTokenCount;
        _projectTokenCount[projectId] = reserveTokenCount;
        _projectMintPrice[projectId] = projectMintPrice;

        // Transfer each token to _artist
        _balances[_artist] += reserveTokenCount;

        for(uint32 i = 0; i < reserveTokenCount; i++){
            uint256 tokenId = projectId * PROJECT_BUCKET_SIZE + i;
            _owners[tokenId] = _artist;
            emit Transfer(address(0), _artist, tokenId);
        }
    }

    /** Enable/Disable minting
     *
     * - Enable minting (drop):  (setProjectTokenSupply(projectId, projectTokenSupply))
     * - Disable minting (pause): (setProjectTokenSupply(projectId, project(projectId).projectTokenCount))
     *
     */
    function setProjectTokenSupply(uint256 projectId, uint32 projectTokenSupply) public onlyArtist {
        // Don't break math (could be ignored if careful externally)
        require(projectTokenSupply <= PROJECT_BUCKET_SIZE, 'S');
        // Don't hide existing tokens
        require(projectTokenSupply > _projectTokenCount[projectId], 's');

        // Make sure project was created first (it should have a price)
        require(_projectMintPrice[projectId] > 0, 's');

        _totalSupply += projectTokenSupply - _projectTokenSupply[projectId];
        _projectTokenSupply[projectId] = projectTokenSupply;
    }

    /** Change the project mint price
     *
     * This enables manually changing price after createProject:
     * 
     * - Auctions?
     * - Reverse Auctions - Increase Price, etc.
     */
    function setProjectMintPrice(uint256 projectId, uint32 projectMintPrice) public onlyArtist {
        _projectMintPrice[projectId] = projectMintPrice;
    }

    /** Gas limit to prevent gas war 
     *
     * - Also useful to pause minting (set gas price max to 0)
     */
    uint256 private _gasPriceMax = 100 gwei;
    function getGasPriceMax() public view returns(uint256) {
        return _gasPriceMax;
    }
    function setGasPriceMax(uint256 gasPriceMax) public onlyArtist {
        _gasPriceMax = gasPriceMax;
    }

    /** Ideas: What about restricting the gas price */
    function mint(uint256 tokenId) public payable {
        // Prevent gas war
        require(tx.gasprice <= _gasPriceMax, '~');

         // Unowned tokenId
        require(_owners[tokenId] == address(0), 'O' );

        // Does project exist & has tokens left
        uint256 projectId = tokenId / PROJECT_BUCKET_SIZE;
        uint256 projectTokenIndex = tokenId % PROJECT_BUCKET_SIZE;
        require(projectTokenIndex < _projectTokenSupply[projectId], 'P' );

        // Did caller send enough money?
        require(msg.value >= _projectMintPrice[projectId], '$' );

        // Pay Artist (no reentry vulnerability since _artist is trusted and using exactly msg.value)
        // https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/
        (bool success, ) = _artist.call{ value: msg.value }("");
        require(success, 'F');

        _balances[msg.sender] += 1;
        _owners[tokenId] = msg.sender;
        _projectTokenCount[projectId]++;
    
        emit Transfer(address(0), msg.sender, tokenId);
    }

    // Transfers ---

    function _transfer(address from, address to, uint256 tokenId) internal  {
        // Is the from the real owner
        require(ownerOf(tokenId) == from, 'o');
        // Does msg.sender have authority over this token
        require(_isApprovedOrOwner(tokenId), 'A');
        // Prevent sending to 0
        require(to != address(0), 't');

        // Clear approvals from the previous owner
        if(_tokenApprovals[tokenId] != address(0)){
            _approve(address(0), tokenId);
        }

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(IERC721) {
        _transfer(from, to, tokenId);
        _checkReceiver(from, to, tokenId, '');
    }
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data_) public override(IERC721) {
        _transfer(from, to, tokenId);
        _checkReceiver(from, to, tokenId, data_);
    }
    function transferFrom(address from, address to, uint256 tokenId) public virtual override(IERC721) {
        _transfer(from, to, tokenId);
    }

    function _checkReceiver(address from, address to, uint256 tokenId, bytes memory data_) internal  {
        
        // If contract, confirm is receiver
        uint256 size; 
        assembly { size := extcodesize(to) }
        if (size > 0)
        {
            bytes4 retval = IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data_);
            require(retval == IERC721Receiver(to).onERC721Received.selector, 'z');
        }
    }

    // Approvals ---

    /** Temporary approval during token transfer */ 
    mapping (uint256 => address) private _tokenApprovals;

    function approve(address to, uint256 tokenId) public override(IERC721) {
        address owner = ownerOf(tokenId);
        require(owner == msg.sender || isApprovedForAll(owner, msg.sender), 'o');

        _approve(to, tokenId);
    }
    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function getApproved(uint256 tokenId) public view override(IERC721) returns (address) {
        return _tokenApprovals[tokenId];
    }

    /** Approval for all (operators approved to transfer tokens on behalf of an owner) */
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    function setApprovalForAll(address operator, bool approved) public virtual override(IERC721) {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }
    function isApprovedForAll(address owner, address operator) public view override(IERC721) returns (bool) {
        return _operatorApprovals[owner][operator];
    }
    function _isApprovedOrOwner(uint256 tokenId) internal view  returns (bool) {
        address owner = ownerOf(tokenId);
        return (owner == msg.sender 
            || getApproved(tokenId) == msg.sender 
            || isApprovedForAll(owner, msg.sender));
    }

}