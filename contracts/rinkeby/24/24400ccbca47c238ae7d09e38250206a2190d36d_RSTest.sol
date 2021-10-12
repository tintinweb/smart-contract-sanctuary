// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Pausable.sol";
import "./AccessControl.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";


contract RSTest is ERC721Enumerable, Ownable, AccessControl {

    using Strings for uint256;

    bytes32 public constant MODERATOR = keccak256("MODERATOR");
    bytes32 public constant WHITELIST = keccak256("WHITELIST");
    uint256 public constant MAX_SUPPLY = 500;
    uint256 public CURRENT_PRICE = 0.01 ether;

    uint256 public RESERVED_SUPPLY = 0;
    uint256 public RESERVED_PREMINT_SUPPLY = 0;
    
    uint256 public MINT_AMOUNT = 0;
    uint256 public PREMINT_AMOUNT = 0;

    mapping(address => bool) private _presale;

    bool public mintingStopped = true;
    bool public preMintingStopped = true;
    string private _baseTokenURI = "";

    address creatorAccount;

    modifier whenMintNotStopped() {
        require(!mintingStopped, "Minting has Stopped");
        _;
    }

    modifier whenPreMintNotStopped() {
        require(!preMintingStopped, "Pre-Mint has Stopped");
        _;
    }

    event MintStopped(address account);
    event MintStarted(address account);
    event PreMintStopped(address account);
    event PreMintStarted(address account);
    event setPreMintRole(address account);
    event issuedPreMint(address account);

    constructor(
        string memory _name,
        string memory _symbol,
        address _creatorAccount
    )
        ERC721(_name, _symbol)
    {
        creatorAccount = _creatorAccount;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MODERATOR, msg.sender);
    }

    fallback() external payable { }

    receive() external payable { }

    function mint(uint256 num) public payable whenMintNotStopped(){
        uint256 supply = totalSupply();
        uint256 tokenCount = balanceOf(msg.sender);
        require( num <= MINT_AMOUNT,                                "Maximum of MINT_AMOUNT Tokens" );
        require( tokenCount + num <= MINT_AMOUNT + PREMINT_AMOUNT,  "Maximum of MINT_AMOUNT + PREMINT_AMOUNT Tokens per wallet" );
        require( supply + num <= MAX_SUPPLY - RESERVED_SUPPLY,      "Maximum Token supply" );
        require( msg.value >= CURRENT_PRICE * num,                  "Ether sent is less than PRICE * num" );

        for(uint256 i; i < num; i++){
            _safeMint( msg.sender, supply + i );
        }
    }

    function preMint() public payable whenPreMintNotStopped() {
        require(hasRole(WHITELIST, msg.sender),                     "Account is not allowed to pre-mint");
        require( RESERVED_PREMINT_SUPPLY > 0,                       "Exceeds pre-mint reserved supply" );
        require( msg.value >= CURRENT_PRICE,                        "Ether sent is less than PRICE" );
        RESERVED_PREMINT_SUPPLY -= PREMINT_AMOUNT;
        uint256 supply = totalSupply();
        _safeMint( msg.sender, supply);
        emit issuedPreMint(msg.sender);
    }

    function giveAway(address _to) external onlyRole(MODERATOR) {
        require(RESERVED_SUPPLY > 0,                                "Exceeds giveaway reserved supply" );
        RESERVED_SUPPLY -= 1;
        uint256 supply = totalSupply();
        _safeMint( _to, supply);
    }

    function stopMint() public onlyRole(MODERATOR) {
        mintingStopped = true;
        emit MintStopped(msg.sender);
    }

    function startMint() public onlyRole(MODERATOR) {
        mintingStopped = false;
        emit MintStarted(msg.sender);
    }

    function stopPreMint() public onlyRole(MODERATOR) {
        preMintingStopped = true;
        emit PreMintStopped(msg.sender);
    }

    function startPreMint() public onlyRole(MODERATOR) {
        preMintingStopped = false;
        emit PreMintStarted(msg.sender);
    }

    function updateCreatorAccount(address _creatorAccount) public onlyOwner {
        creatorAccount = _creatorAccount;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setCurrentPrice(uint256 currentPrice) public onlyOwner {
        CURRENT_PRICE = currentPrice;
    }

    function setReservedSupply(uint256 reservedSupply) public onlyOwner {
        RESERVED_SUPPLY = reservedSupply;
    }

    function setReservedPreMintSupply(uint256 reservedPreMintSupply) public onlyOwner {
        RESERVED_PREMINT_SUPPLY = reservedPreMintSupply;
    }
    
    function setMintAmount(uint256 mintAmount) public onlyOwner {
        MINT_AMOUNT = mintAmount;
    }
    
    function setPreMintAmount(uint256 preMintAmount) public onlyOwner {
        PREMINT_AMOUNT = preMintAmount;
    }
    
    function withdrawAmount(uint256 amount) public onlyOwner {
        uint256 _balance = address(this).balance;
        require(_balance > 0,                                       "Withdraw amount call without balance");
        require(_balance-amount >= 0,                               "Withdraw amount call with more than balance");
        require(payable(creatorAccount).send(amount),               "FAILED withdraw amount call");
    }

    function withdrawAll() public onlyOwner {
        uint256 _balance = address(this).balance;
        require(_balance > 0,                                       "Withdraw all call without balance");
        require(payable(creatorAccount).send(_balance),             "FAILED withdraw all call");
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId),                                   "URI query for nonexistent token");

        string memory baseURI = getBaseURI();
        string memory json = ".json";
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString(), json))
            : '';
    }

    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function getCreatorAccount() public view onlyOwner returns(address splitter) {
        return creatorAccount;
    }
    
    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function allowedPreMint(address account) public view  returns (bool) {
        return _presale[account];
    }

    function getBaseURI() public view returns (string memory) {
        return _baseTokenURI;
    }
}