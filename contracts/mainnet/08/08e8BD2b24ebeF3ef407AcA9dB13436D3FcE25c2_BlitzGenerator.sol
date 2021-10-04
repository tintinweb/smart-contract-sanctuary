// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./AccessControl.sol";
import "./Counters.sol";

contract BlitzGenerator is ERC721, ERC721Enumerable, AccessControl {
    using Counters for Counters.Counter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bool allowInternalPurchases = true;
    uint256 public numSeries;
    
    struct SeriesStruct {
        uint256 numMint;  //number minted to date per series
        uint256 maxMint; //maximum number of generated per series
        uint256 weiPrice; //curent token price
        uint256 secondaryMarketPercentage;
        uint scriptCount;
        string[10] scripts;
        string ipfs_cid;
        bool locked; //can't modify maxMint or codeLocation
        bool paused; //paused for purchases
    }
    struct TokenParamsStruct {
        bytes32 seed; //hash seed for random generation
        uint32 nTrades; //number of times traded
    }
    
    mapping(uint256 => TokenParamsStruct) tokenParams; //maps each token to set of parameters
    mapping(uint256 => SeriesStruct) series; //series
    mapping(uint256 => uint256) token2series; //maps each token to a series
    mapping(uint256 => uint256[]) series2tokens;
    
    Counters.Counter private _tokenIdCounter;
    
    modifier sidInRange(uint256 sid) {
      require(sid < numSeries,"Series id does not exist");
      _;
    }
    
    modifier requireUnlocked(uint256 sid) {
      require(!series[sid].locked, "Series is locked");
      _;
    }
    
    event Mint(
        address indexed to,
        uint256 indexed tokenID,
        uint256 indexed sid
    );

    constructor() ERC721("Blitz Generative", "Blitz") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        addSeries(.1e18, 1000, 0);
    }
    
    function addSeries(uint256 startingWeiPrice, uint256 maxMint, uint256 royaltyPercentage) public onlyRole(DEFAULT_ADMIN_ROLE) returns(uint256 sid) {
        series[numSeries].maxMint = maxMint;
        series[numSeries].weiPrice = startingWeiPrice; //starter token price
        series[numSeries].secondaryMarketPercentage = royaltyPercentage;
        series[numSeries].scriptCount = 0;
        series[numSeries].paused = true;
        series[numSeries].ipfs_cid = "NA";
        numSeries++;
        return numSeries;
    }
    
    function setMaxMint(uint256 sid, uint256 m) public onlyRole(DEFAULT_ADMIN_ROLE) sidInRange(sid) requireUnlocked(sid) {
      series[sid].maxMint = m;
    }
    
    function setSecondaryMarketPercentage(uint256 sid, uint256 m) public onlyRole(DEFAULT_ADMIN_ROLE) sidInRange(sid) {
        require(m <= 100, "Max of 100%");
      series[sid].secondaryMarketPercentage = m;
    }
    
    function addSeriesScript(uint256 sid, string memory _script) public onlyRole(DEFAULT_ADMIN_ROLE)  {
        series[sid].scripts[series[sid].scriptCount] = _script;
        series[sid].scriptCount +=1;
    }
    
    function updateSeriesScript(uint256 sid, uint256 _scriptId, string memory _script) public onlyRole(DEFAULT_ADMIN_ROLE) requireUnlocked(sid) {
        require(_scriptId < series[sid].scriptCount, "scriptId out of range");
        series[sid].scripts[_scriptId] = _script;
    }
    
    function getTokenParams(uint256 i) public view returns (bytes32 seed, string memory codeLocation0, uint256 seriesID, uint256 royaltyPercentage, uint32 nTrades) {
        require(i < _tokenIdCounter.current(),"TokenId out of range");
        uint256 sid = token2series[i];
        codeLocation0 = series[sid].scripts[0];
        seriesID = sid;
        royaltyPercentage = series[sid].secondaryMarketPercentage;
        seed = tokenParams[i].seed;
        nTrades = tokenParams[i].nTrades;
    }
    
    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
        return _tokensOfOwner(owner);
    }
    
    function setWeiPrice(uint256 sid, uint256 p) public sidInRange(sid) onlyRole(MINTER_ROLE) {
        series[sid].weiPrice = p;
    }
    
    function setSeriesIPFS(uint256 sid, string memory cid) public sidInRange(sid) onlyRole(DEFAULT_ADMIN_ROLE) {
        series[sid].ipfs_cid = cid;
    }
    
    function getSeries(uint256 i, uint256 script_id) public sidInRange(i) view returns (string memory script, uint256 numCodeLocations, uint256 numMint, uint256 maxMint, uint256 curPricePerToken, uint256 royaltyPercentage, string memory ipfs_cid, bool paused, bool locked) {
      script = series[i].scripts[script_id];
      numCodeLocations = series[i].scriptCount;
      numMint = series[i].numMint;
      maxMint = series[i].maxMint;
      royaltyPercentage = series[i].secondaryMarketPercentage;
      locked = series[i].locked;
      paused = series[i].paused;
      curPricePerToken = series[i].weiPrice;
      ipfs_cid = series[i].ipfs_cid;
    } 
    
    function showAllTokensPerSeries(uint256 sid) public sidInRange(sid) view returns (uint256[] memory){
        return series2tokens[sid];    
    }
    
    function _baseURI() internal pure override returns (string memory) {
        // CHECK THIS IS CORRECT!!!
        return "https://blitzgenerative.com/uris/";
    }
    
    function setAllowInternalPurchases(bool m) public onlyRole(DEFAULT_ADMIN_ROLE) {
        allowInternalPurchases = m;
    }
    
    function setSeriesPause(uint256 sid,bool m) public sidInRange(sid) onlyRole(DEFAULT_ADMIN_ROLE) {
      series[sid].paused = m;
    }
    
    function lockCodeForever(uint256 sid) public sidInRange(sid) onlyRole(DEFAULT_ADMIN_ROLE) {
      //Can no longer update max mint, code locations, or series parameters
      series[sid].locked = true;
    }
    
    // sid is the series ID
    function purchase(uint256 sid) public sidInRange(sid) payable returns(uint256 _tokenId) {
        require(allowInternalPurchases,"Can only purchase from external minting contract");
        require(!series[sid].paused,"Purchasing is paused");   
        require(msg.value >= series[sid].weiPrice, "Insufficient funds!");
        uint256 diff = msg.value - series[sid].weiPrice;
        payable(msg.sender).transfer(diff);
        
        _tokenId = _mintInternal(sid, msg.sender);
        return _tokenId;
    }

    function minterMint(uint256 sid, address to) public sidInRange(sid) onlyRole(MINTER_ROLE) {
        _mintInternal(sid, to);
    }
    
    //all mint ops flow through here. 
    function _mintInternal(uint256 sid, address to) internal virtual returns (uint256 _tokenId) {
        require(series[sid].numMint +1 <= series[sid].maxMint,"Maximum minted");
        series[sid].numMint++;
        // using safe mint here!! 
        _safeMint(to, _tokenIdCounter.current());
        uint256 tokenID = _tokenIdCounter.current();
        bytes32 hash = keccak256(abi.encodePacked(tokenID,block.timestamp,block.difficulty,msg.sender));
        //store random hash
        tokenParams[tokenID].seed = hash;
        token2series[tokenID] = sid;
        series2tokens[sid].push(tokenID);
        _tokenIdCounter.increment();
        emit Mint(to, tokenID, sid);
        return tokenID;
    }
    
    function withdraw(uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(amount <= address(this).balance,"Insufficient funds to withdraw");	
        payable(msg.sender).transfer(amount);
    }
    
    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
        tokenParams[tokenId].nTrades++;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}