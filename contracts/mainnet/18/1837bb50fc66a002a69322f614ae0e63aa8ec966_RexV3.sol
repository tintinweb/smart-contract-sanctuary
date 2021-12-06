// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0; 

import "./EvolveToken.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";


contract RexV3 is Initializable, ERC721EnumerableUpgradeable, OwnableUpgradeable {
    
	using SafeMathUpgradeable for uint256;
	using SafeMathUpgradeable for uint128;
	using SafeMathUpgradeable for uint16;

    uint16 public MAX_TOKENS_MINTABLE;
    uint16 public MAX_BABY_TOKENS;
    uint16 public MAX_UNCOMMON_TOKENS;
    uint16 public MAX_RARE_TOKENS;
    uint16 public MAX_LEGENDARY_TOKENS;
    uint16 public MAX_MYTHICAL_TOKENS;
    uint16 public NUM_BABY_TOKENS;
    uint16 public NUM_UNCOMMON_TOKENS;
    uint16 public NUM_RARE_TOKENS;
    uint16 public NUM_LEGENDARY_TOKENS;
    uint16 public NUM_MYTHICAL_TOKENS;
    uint16 public REX_FOR_UNCOMMON;
    uint16 public REX_FOR_RARE;
    uint16 public REX_FOR_LEGENDARY;
    uint16 public REX_FOR_MYTHICAL;

    bool public EVOLVE_OPEN;
    bool public ON_SALE;    
    bool public ON_PRESALE;

    uint128 public TOKEN_PRICE;

    string private BASE_URI;

    IERC1155 public OPENSEA_STORE;
    EvolveToken public EVOLVE_TOKEN;

    mapping(address => uint256) public balanceGenesis;
    mapping(address => uint256) public balanceUncommon;
    mapping(address => uint256) public balanceRare;
    mapping(address => uint256) public balanceLegendary;
    mapping(address => uint256) public balanceMythical;
    mapping(uint256 => bool) public availableMythicals;
    mapping(uint256 => bool) public mintedMythicals;
    
    address public constant burnAddress = address(0x000000000000000000000000000000000000dEaD);

    mapping(address => bool) public presaleWhitelist;            
    mapping(address => uint256) public addressTokensMinted;   
    
    function mintRex(uint16 numberOfTokens, address userAddress, uint16 tier) internal {
        uint16 nextToken;
        if(tier == 1){
            nextToken = 101 + NUM_BABY_TOKENS;
            NUM_BABY_TOKENS += numberOfTokens;
        }else if(tier == 2){
            nextToken = 10000 + NUM_UNCOMMON_TOKENS;
            NUM_UNCOMMON_TOKENS += numberOfTokens;
		    EVOLVE_TOKEN.updateClaimable(userAddress, address(0));
            balanceUncommon[userAddress] += numberOfTokens;
        }else if(tier == 3){
            nextToken = 20000 + NUM_RARE_TOKENS;
            NUM_RARE_TOKENS += numberOfTokens;
		    EVOLVE_TOKEN.updateClaimable(userAddress, address(0));
            balanceRare[userAddress] += numberOfTokens;
        }else if(tier == 4){
            nextToken = 30000 + NUM_LEGENDARY_TOKENS;
            NUM_LEGENDARY_TOKENS += numberOfTokens;
		    EVOLVE_TOKEN.updateClaimable(userAddress, address(0));
            balanceLegendary[userAddress] += numberOfTokens;
        }else if(tier == 5){
            nextToken = 40000 + NUM_MYTHICAL_TOKENS;
            NUM_MYTHICAL_TOKENS += numberOfTokens;
		    EVOLVE_TOKEN.updateClaimable(userAddress, address(0));
            balanceMythical[userAddress] += numberOfTokens;
        }
        for(uint256 i = 0; i < numberOfTokens; i+=1) {
            _safeMint(userAddress, nextToken+i);
        }
        delete nextToken;
    }

    function mint(uint16 numberOfTokens) external payable  {
        require(ON_SALE, "not on sale");
        require(NUM_BABY_TOKENS + numberOfTokens <= MAX_BABY_TOKENS, "Not enough");
        require(addressTokensMinted[msg.sender] + numberOfTokens <= MAX_TOKENS_MINTABLE, "mint limit");
        require(TOKEN_PRICE * numberOfTokens <= msg.value, 'missing eth');
        mintRex(numberOfTokens,msg.sender,1);
        addressTokensMinted[msg.sender] += numberOfTokens;
    }

    function mintPresale(uint16 numberOfTokens) external payable  {
        require(ON_PRESALE, "not presale");
        require(presaleWhitelist[msg.sender], "Not whitelist");
        require(NUM_BABY_TOKENS + numberOfTokens <= MAX_BABY_TOKENS, "Not enough left");
        require(addressTokensMinted[msg.sender] + numberOfTokens <= MAX_TOKENS_MINTABLE, "mint limit");
        require(TOKEN_PRICE * numberOfTokens <= msg.value, 'missing eth');
        mintRex(numberOfTokens,msg.sender,1);
        addressTokensMinted[msg.sender] += numberOfTokens;
    }
    
	function convertGenesis(uint256 _tokenId) external {
        require(isValidRex(_tokenId),"not valid rex");
		uint256 id = returnCorrectId(_tokenId);
		OPENSEA_STORE.safeTransferFrom(msg.sender, burnAddress, _tokenId, 1, "");
		EVOLVE_TOKEN.updateClaimable(msg.sender, address(0));
		_safeMint(msg.sender, id);
		balanceGenesis[msg.sender]++;
	} 

    function evolve(uint256[] calldata _rexs, uint256 _mythicalToken) external {
        require(EVOLVE_OPEN, "evolve not open");
        uint256 rexEaten = _rexs.length;

        for(uint256 i = 0; i < rexEaten; i+=1) {
            require(ownerOf(_rexs[i]) == msg.sender, "not own rex");
            require(isEdible(_rexs[i]), "cannot eat this");
        }

        if(rexEaten == REX_FOR_UNCOMMON){
            require(NUM_UNCOMMON_TOKENS < MAX_UNCOMMON_TOKENS, "No UNCOMMON left");
            for(uint256 i = 0; i < rexEaten; i+=1) {
                burnRex(_rexs[i]);
            }
            mintRex(1,msg.sender,2);
        }
        else if(rexEaten == REX_FOR_RARE){
            require(NUM_RARE_TOKENS < MAX_RARE_TOKENS, "No RARE left");
            for(uint256 i = 0; i < rexEaten; i+=1) {
                burnRex(_rexs[i]);
            }
            mintRex(1,msg.sender,3);
        }
        else if(rexEaten == REX_FOR_LEGENDARY){
            require(NUM_LEGENDARY_TOKENS < MAX_LEGENDARY_TOKENS, "No LEGENDARY left");
            for(uint256 i = 0; i < rexEaten; i+=1) {
                burnRex(_rexs[i]);
            }
            mintRex(1,msg.sender,4);
        }
        else if(rexEaten == REX_FOR_MYTHICAL){
            require(NUM_MYTHICAL_TOKENS < MAX_MYTHICAL_TOKENS, "No MYTHICAL left");
            require(_mythicalToken >= 40000, "Not a MYTHICAL");
            require(availableMythicals[_mythicalToken], "Mythical not available");
            for(uint256 i = 0; i < rexEaten; i+=1) {
                burnRex(_rexs[i]);
            }
            NUM_MYTHICAL_TOKENS += 1;
            EVOLVE_TOKEN.updateClaimable(msg.sender, address(0));
            _safeMint(msg.sender, _mythicalToken);
            balanceMythical[msg.sender] += 1;
            availableMythicals[_mythicalToken] = false;
        }
        
        delete rexEaten;
    }

    function isEdible(uint256 _tokenId) internal view returns(bool){
        if(_tokenId <= 100){ //101 Genesis Rex
            return false;
        }else if(mintedMythicals[_tokenId]){ //Minted Mythical
            return false;
        }else if(_tokenId >= 5000 && _tokenId <= 5010){ //Mythical Babies
            return false;
        }else if(_tokenId >= 40000){ //Mythical Rex
            return false;
        }
        return true;
    }

    function claimTokens() external {
		EVOLVE_TOKEN.updateClaimable(msg.sender, address(0));
		EVOLVE_TOKEN.claimTokens(msg.sender);
	}
    
    function burnRex(uint256 _tokenId) internal {
        _burn(_tokenId);
        decreaseBalance(_tokenId, msg.sender);
    }


    function increaseBalance(uint256 _tokenId, address _owner) internal {
        if(_tokenId <= 100){ //Genesis
            balanceGenesis[_owner]++;
        }else if(_tokenId < 5000 && !mintedMythicals[_tokenId]){ //babies
            //do not earn
        }else if(_tokenId < 10000 || mintedMythicals[_tokenId]){ //mythical babies
            balanceMythical[_owner]++;
        }else if(_tokenId < 20000){ //uncommon
            balanceUncommon[_owner]++;
        }else if(_tokenId < 30000){ //rare
            balanceRare[_owner]++;
        }else if(_tokenId < 40000){ //legendary
            balanceLegendary[_owner]++;
        }else if(_tokenId < 50000){ //mythical
            balanceMythical[_owner]++;
        }
    }

    function decreaseBalance(uint256 _tokenId, address _owner) internal {
        if(_tokenId <= 100){ //Genesis
            balanceGenesis[_owner]--;
        }else if(_tokenId < 5000 && !mintedMythicals[_tokenId]){ //babies
            //do not earn
        }else if(_tokenId < 10000 || mintedMythicals[_tokenId]){ //mythical babies
            balanceMythical[_owner]--;
        }else if(_tokenId < 20000){ //uncommon
            balanceUncommon[_owner]--;
        }else if(_tokenId < 30000){ //rare
            balanceRare[_owner]--;
        }else if(_tokenId < 40000){ //legendary
            balanceLegendary[_owner]--;
        }else if(_tokenId < 50000){ //mythical
            balanceMythical[_owner]--;
        }
    }

    
    function airdrop(uint16 numberOfTokens, address userAddress, uint16 tier) external onlyOwner {
        if(tier > 1){
            require(numberOfTokens == 1,"multiple airdrop not allowed");
        }
        mintRex(numberOfTokens,userAddress,tier);
    }

    function addToWhitelist(address[] calldata whitelist) external onlyOwner {
        for(uint256 i = 0; i < whitelist.length; i+=1) {
            presaleWhitelist[whitelist[i]] = true;
        }
    }

    function startPreSale() external onlyOwner {
        ON_PRESALE = true;
    }
    function stopPreSale() external onlyOwner {
        ON_PRESALE = false;
    }
    function startSale() external onlyOwner {
        ON_SALE = true;
    }
    function stopSale() external onlyOwner {
        ON_SALE = false;
    }
    function openEvolve() external onlyOwner {
        EVOLVE_OPEN = true;
    }
    function closeEvolve() external onlyOwner {
        EVOLVE_OPEN = false;
    }

    function setTokenPrice(uint128 price) external onlyOwner {
        TOKEN_PRICE = price;
    }
    function setMaxMintable(uint16 quantity) external onlyOwner {
        MAX_TOKENS_MINTABLE = quantity;
    }

    function setRexForUncommon(uint16 quantity) external onlyOwner {
        REX_FOR_UNCOMMON = quantity;
    }
    function setRexForRare(uint16 quantity) external onlyOwner {
        REX_FOR_RARE = quantity;
    }
    function setRexForLegendary(uint16 quantity) external onlyOwner {
        REX_FOR_LEGENDARY = quantity;
    }
    function setRexForMythical(uint16 quantity) external onlyOwner {
        REX_FOR_MYTHICAL = quantity;
    }

    function setMaxBabyTokens(uint16 quantity) external onlyOwner {
        MAX_BABY_TOKENS = quantity;
    }
    function setMaxUncommonTokens(uint16 quantity) external onlyOwner {
        MAX_UNCOMMON_TOKENS = quantity;
    }
    function setMaxRareTokens(uint16 quantity) external onlyOwner {
        MAX_RARE_TOKENS = quantity;
    }
    function setMaxLegendaryTokens(uint16 quantity) external onlyOwner {
        MAX_LEGENDARY_TOKENS = quantity;
    }
    function setMaxMythicalTokens(uint16 quantity) external onlyOwner {
        MAX_MYTHICAL_TOKENS = quantity;
    }
    
    function setOS(address _address) external onlyOwner{
        OPENSEA_STORE = IERC1155(_address);
    }
    
    function setEvolveToken(address _address) external onlyOwner {
        EVOLVE_TOKEN = EvolveToken(_address);
    }

    function setMintedMythical(uint16 _tokenId) external onlyOwner {
        mintedMythicals[_tokenId] = true;
        address mmowner = ownerOf(_tokenId);
        increaseBalance(_tokenId, mmowner);
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        BASE_URI = baseURI;
    }
    
    function _baseURI() internal view override returns (string memory) {
        return BASE_URI;
    }

    function withdrawBalance() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(0x212F952aDfEA0d424cB0B2A314DC1Cb960FE37B6).call{value: balance}("");
        delete balance;
    }

    function createBabyMythicals() external onlyOwner {
        _safeMint(msg.sender, 5000);
        _safeMint(msg.sender, 5001);
        _safeMint(msg.sender, 5002);
        _safeMint(msg.sender, 5003);
        _safeMint(msg.sender, 5004);
        _safeMint(msg.sender, 5005);
        _safeMint(msg.sender, 5006);
        balanceMythical[msg.sender]+=7;
    }

    function isValidRex(uint256 _id) pure internal returns(bool) {

		if (_id >> 96 != 0x0000000000000000000000008d7aeb636db83bd1b1c58eff56a40321584ea18c)
			return false;

		if (_id & 0x000000000000000000000000000000000000000000000000000000ffffffffff != 1)
			return false;

		uint256 id = (_id & 0x0000000000000000000000000000000000000000ffffffffffffff0000000000) >> 40;
		if (id-124 > 100)
			return false;
		return true;
	}

	function returnCorrectId(uint256 _id) pure internal returns(uint256) {
		_id = (_id & 0x0000000000000000000000000000000000000000ffffffffffffff0000000000) >> 40;
		return _id-124;
	}    
    
	function transferFrom(address from, address to, uint256 tokenId) public override {
        EVOLVE_TOKEN.updateClaimable(from, to);
        increaseBalance(tokenId, to);
        decreaseBalance(tokenId, from);
		ERC721Upgradeable.transferFrom(from, to, tokenId);
	}
    
	function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override {
        EVOLVE_TOKEN.updateClaimable(from, to);
        increaseBalance(tokenId, to);
        decreaseBalance(tokenId, from);
		ERC721Upgradeable.safeTransferFrom(from, to, tokenId, _data);
	}

    function initialize(string memory name_, string memory symbol_) public initializer {
        __Ownable_init_unchained();        
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name_, symbol_);

        TOKEN_PRICE = 65000000000000000;
        MAX_TOKENS_MINTABLE = 3;        
        MAX_BABY_TOKENS = 3898;
        MAX_UNCOMMON_TOKENS = 1300;
        MAX_RARE_TOKENS = 500;
        MAX_LEGENDARY_TOKENS = 126;
        MAX_MYTHICAL_TOKENS = 12;
        availableMythicals[40000] = true;
        availableMythicals[40001] = true;
        availableMythicals[40002] = true;
        availableMythicals[40003] = true;
        availableMythicals[40004] = true;
        availableMythicals[40005] = true;
        availableMythicals[40006] = true;
        availableMythicals[40007] = true;
        availableMythicals[40008] = true;
        availableMythicals[40009] = true;
        availableMythicals[40010] = true;
        availableMythicals[40011] = true;
        REX_FOR_UNCOMMON = 2;
        REX_FOR_RARE = 5;
        REX_FOR_LEGENDARY = 10;
        REX_FOR_MYTHICAL = 25;
        BASE_URI = "http://phpstack-636608-2278840.cloudwaysapps.com/rex/api/?token_id=";
    }

    function tokensOfOwner(address _owner) external view returns(uint[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            delete index;
            return result;
        }
    }
    
    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes calldata _data) external view returns(bytes4) {
		require(msg.sender == address(OPENSEA_STORE), "not opensea asset");
		return Rex.onERC1155Received.selector;
	}

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0; 

import "./EvolveToken.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";


contract Rex is Initializable, ERC721EnumerableUpgradeable, OwnableUpgradeable {
    
	using SafeMathUpgradeable for uint256;
	using SafeMathUpgradeable for uint128;
	using SafeMathUpgradeable for uint16;

    uint16 public MAX_TOKENS_MINTABLE;
    uint16 public MAX_BABY_TOKENS;
    uint16 public MAX_UNCOMMON_TOKENS;
    uint16 public MAX_RARE_TOKENS;
    uint16 public MAX_LEGENDARY_TOKENS;
    uint16 public MAX_MYTHICAL_TOKENS;
    uint16 public NUM_BABY_TOKENS;
    uint16 public NUM_UNCOMMON_TOKENS;
    uint16 public NUM_RARE_TOKENS;
    uint16 public NUM_LEGENDARY_TOKENS;
    uint16 public NUM_MYTHICAL_TOKENS;
    uint16 public REX_FOR_UNCOMMON;
    uint16 public REX_FOR_RARE;
    uint16 public REX_FOR_LEGENDARY;
    uint16 public REX_FOR_MYTHICAL;

    bool public EVOLVE_OPEN;
    bool public ON_SALE;    
    bool public ON_PRESALE;

    uint128 public TOKEN_PRICE;

    string private BASE_URI;

    IERC1155 public OPENSEA_STORE;
    EvolveToken public EVOLVE_TOKEN;

    mapping(address => uint256) public balanceGenesis;
    mapping(address => uint256) public balanceUncommon;
    mapping(address => uint256) public balanceRare;
    mapping(address => uint256) public balanceLegendary;
    mapping(address => uint256) public balanceMythical;
    mapping(uint256 => bool) public availableMythicals;
    mapping(uint256 => bool) public mintedMythicals;
    
    address public constant burnAddress = address(0x000000000000000000000000000000000000dEaD);

    mapping(address => bool) public presaleWhitelist;            
    mapping(address => uint256) public addressTokensMinted;   
    
    function mintRex(uint16 numberOfTokens, address userAddress, uint16 tier) internal {
        uint16 nextToken;
        if(tier == 1){
            nextToken = 101 + NUM_BABY_TOKENS;
            NUM_BABY_TOKENS += numberOfTokens;
        }else if(tier == 2){
            nextToken = 10000 + NUM_UNCOMMON_TOKENS;
            NUM_UNCOMMON_TOKENS += numberOfTokens;
		    EVOLVE_TOKEN.updateClaimable(userAddress, address(0));
            balanceUncommon[userAddress] += numberOfTokens;
        }else if(tier == 3){
            nextToken = 20000 + NUM_RARE_TOKENS;
            NUM_RARE_TOKENS += numberOfTokens;
		    EVOLVE_TOKEN.updateClaimable(userAddress, address(0));
            balanceRare[userAddress] += numberOfTokens;
        }else if(tier == 4){
            nextToken = 30000 + NUM_LEGENDARY_TOKENS;
            NUM_LEGENDARY_TOKENS += numberOfTokens;
		    EVOLVE_TOKEN.updateClaimable(userAddress, address(0));
            balanceLegendary[userAddress] += numberOfTokens;
        }else if(tier == 5){
            nextToken = 40000 + NUM_MYTHICAL_TOKENS;
            NUM_MYTHICAL_TOKENS += numberOfTokens;
		    EVOLVE_TOKEN.updateClaimable(userAddress, address(0));
            balanceMythical[userAddress] += numberOfTokens;
        }
        for(uint256 i = 0; i < numberOfTokens; i+=1) {
            _safeMint(userAddress, nextToken+i);
        }
        delete nextToken;
    }

    function mint(uint16 numberOfTokens) external payable  {
        require(ON_SALE, "not on sale");
        require(NUM_BABY_TOKENS + numberOfTokens <= MAX_BABY_TOKENS, "Not enough");
        require(addressTokensMinted[msg.sender] + numberOfTokens <= MAX_TOKENS_MINTABLE, "mint limit");
        require(TOKEN_PRICE * numberOfTokens <= msg.value, 'missing eth');
        mintRex(numberOfTokens,msg.sender,1);
        addressTokensMinted[msg.sender] += numberOfTokens;
    }

    function mintPresale(uint16 numberOfTokens) external payable  {
        require(ON_PRESALE, "not presale");
        require(presaleWhitelist[msg.sender], "Not whitelist");
        require(NUM_BABY_TOKENS * numberOfTokens <= MAX_BABY_TOKENS, "Not enough left");
        require(addressTokensMinted[msg.sender] + numberOfTokens <= MAX_TOKENS_MINTABLE, "mint limit");
        require(TOKEN_PRICE * numberOfTokens <= msg.value, 'missing eth');
        mintRex(numberOfTokens,msg.sender,1);
        addressTokensMinted[msg.sender] += numberOfTokens;
    }
    
	function convertGenesis(uint256 _tokenId) external {
        require(isValidRex(_tokenId),"not valid rex");
		uint256 id = returnCorrectId(_tokenId);
		OPENSEA_STORE.safeTransferFrom(msg.sender, burnAddress, _tokenId, 1, "");
		EVOLVE_TOKEN.updateClaimable(msg.sender, address(0));
		_safeMint(msg.sender, id);
		balanceGenesis[msg.sender]++;
	} 

    function evolve(uint256[] calldata _rexs, uint256 _mythicalToken) external {
        require(EVOLVE_OPEN, "evolve not open");
        uint256 rexEaten = _rexs.length;

        for(uint256 i = 0; i < rexEaten; i+=1) {
            require(ownerOf(_rexs[i]) == msg.sender, "not own rex");
            require(isEdible(_rexs[i]), "cannot eat this");
        }

        if(rexEaten == REX_FOR_UNCOMMON){
            require(NUM_UNCOMMON_TOKENS < MAX_UNCOMMON_TOKENS, "No UNCOMMON left");
            for(uint256 i = 0; i < rexEaten; i+=1) {
                burnRex(_rexs[i]);
            }
            mintRex(1,msg.sender,2);
        }
        else if(rexEaten == REX_FOR_RARE){
            require(NUM_RARE_TOKENS < MAX_RARE_TOKENS, "No RARE left");
            for(uint256 i = 0; i < rexEaten; i+=1) {
                burnRex(_rexs[i]);
            }
            mintRex(1,msg.sender,3);
        }
        else if(rexEaten == REX_FOR_LEGENDARY){
            require(NUM_LEGENDARY_TOKENS < MAX_LEGENDARY_TOKENS, "No LEGENDARY left");
            for(uint256 i = 0; i < rexEaten; i+=1) {
                burnRex(_rexs[i]);
            }
            mintRex(1,msg.sender,4);
        }
        else if(rexEaten == REX_FOR_MYTHICAL){
            require(NUM_MYTHICAL_TOKENS < MAX_MYTHICAL_TOKENS, "No MYTHICAL left");
            require(_mythicalToken >= 40000, "Not a MYTHICAL");
            require(availableMythicals[_mythicalToken], "Mythical not available");
            for(uint256 i = 0; i < rexEaten; i+=1) {
                burnRex(_rexs[i]);
            }
            NUM_MYTHICAL_TOKENS += 1;
            EVOLVE_TOKEN.updateClaimable(msg.sender, address(0));
            _safeMint(msg.sender, _mythicalToken);
            balanceMythical[msg.sender] += 1;
            availableMythicals[_mythicalToken] = false;
        }
        
        delete rexEaten;
    }

    function isEdible(uint256 _tokenId) internal view returns(bool){
        if(_tokenId <= 100){ //101 Genesis Rex
            return false;
        }else if(mintedMythicals[_tokenId]){ //Minted Mythical
            return false;
        }else if(_tokenId >= 5000 && _tokenId <= 5010){ //Mythical Babies
            return false;
        }else if(_tokenId >= 40000){ //Mythical Rex
            return false;
        }
        return true;
    }

    function claimTokens() external {
		EVOLVE_TOKEN.updateClaimable(msg.sender, address(0));
		EVOLVE_TOKEN.claimTokens(msg.sender);
	}
    
    function burnRex(uint256 _tokenId) internal {
        _burn(_tokenId);
        decreaseBalance(_tokenId, msg.sender);
    }


    function increaseBalance(uint256 _tokenId, address _owner) internal {
        if(_tokenId <= 100){ //Genesis
            balanceGenesis[_owner]++;
        }else if(_tokenId < 5000 && !mintedMythicals[_tokenId]){ //babies
            //do not earn
        }else if(_tokenId < 10000 || mintedMythicals[_tokenId]){ //mythical babies
            balanceMythical[_owner]++;
        }else if(_tokenId < 20000){ //uncommon
            balanceUncommon[_owner]++;
        }else if(_tokenId < 30000){ //rare
            balanceRare[_owner]++;
        }else if(_tokenId < 40000){ //legendary
            balanceLegendary[_owner]++;
        }else if(_tokenId < 50000){ //mythical
            balanceMythical[_owner]++;
        }
    }

    function decreaseBalance(uint256 _tokenId, address _owner) internal {
        if(_tokenId <= 100){ //Genesis
            balanceGenesis[_owner]--;
        }else if(_tokenId < 5000 && !mintedMythicals[_tokenId]){ //babies
            //do not earn
        }else if(_tokenId < 10000 || mintedMythicals[_tokenId]){ //mythical babies
            balanceMythical[_owner]--;
        }else if(_tokenId < 20000){ //uncommon
            balanceUncommon[_owner]--;
        }else if(_tokenId < 30000){ //rare
            balanceRare[_owner]--;
        }else if(_tokenId < 40000){ //legendary
            balanceLegendary[_owner]--;
        }else if(_tokenId < 50000){ //mythical
            balanceMythical[_owner]--;
        }
    }

    
    function airdrop(uint16 numberOfTokens, address userAddress, uint16 tier) external onlyOwner {
        if(tier > 1){
            require(numberOfTokens == 1,"multiple airdrop not allowed");
        }
        mintRex(numberOfTokens,userAddress,tier);
    }

    function addToWhitelist(address[] calldata whitelist) external onlyOwner {
        for(uint256 i = 0; i < whitelist.length; i+=1) {
            presaleWhitelist[whitelist[i]] = true;
        }
    }

    function startPreSale() external onlyOwner {
        ON_PRESALE = true;
    }
    function stopPreSale() external onlyOwner {
        ON_PRESALE = false;
    }
    function startSale() external onlyOwner {
        ON_SALE = true;
    }
    function stopSale() external onlyOwner {
        ON_SALE = false;
    }
    function openEvolve() external onlyOwner {
        EVOLVE_OPEN = true;
    }
    function closeEvolve() external onlyOwner {
        EVOLVE_OPEN = false;
    }

    function setTokenPrice(uint128 price) external onlyOwner {
        TOKEN_PRICE = price;
    }
    function setMaxMintable(uint16 quantity) external onlyOwner {
        MAX_TOKENS_MINTABLE = quantity;
    }

    function setRexForUncommon(uint16 quantity) external onlyOwner {
        REX_FOR_UNCOMMON = quantity;
    }
    function setRexForRare(uint16 quantity) external onlyOwner {
        REX_FOR_RARE = quantity;
    }
    function setRexForLegendary(uint16 quantity) external onlyOwner {
        REX_FOR_LEGENDARY = quantity;
    }
    function setRexForMythical(uint16 quantity) external onlyOwner {
        REX_FOR_MYTHICAL = quantity;
    }

    function setMaxBabyTokens(uint16 quantity) external onlyOwner {
        MAX_BABY_TOKENS = quantity;
    }
    function setMaxUncommonTokens(uint16 quantity) external onlyOwner {
        MAX_UNCOMMON_TOKENS = quantity;
    }
    function setMaxRareTokens(uint16 quantity) external onlyOwner {
        MAX_RARE_TOKENS = quantity;
    }
    function setMaxLegendaryTokens(uint16 quantity) external onlyOwner {
        MAX_LEGENDARY_TOKENS = quantity;
    }
    function setMaxMythicalTokens(uint16 quantity) external onlyOwner {
        MAX_MYTHICAL_TOKENS = quantity;
    }
    
    function setOS(address _address) external onlyOwner{
        OPENSEA_STORE = IERC1155(_address);
    }
    
    function setEvolveToken(address _address) external onlyOwner {
        EVOLVE_TOKEN = EvolveToken(_address);
    }

    function setMintedMythical(uint16 _tokenId) external onlyOwner {
        mintedMythicals[_tokenId] = true;
        address mmowner = ownerOf(_tokenId);
        increaseBalance(_tokenId, mmowner);
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        BASE_URI = baseURI;
    }
    
    function _baseURI() internal view override returns (string memory) {
        return BASE_URI;
    }

    function withdrawBalance() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(0x212F952aDfEA0d424cB0B2A314DC1Cb960FE37B6).transfer(balance);
        delete balance;
    }

    function createBabyMythicals() external onlyOwner {
        _safeMint(msg.sender, 5000);
        _safeMint(msg.sender, 5001);
        _safeMint(msg.sender, 5002);
        _safeMint(msg.sender, 5003);
        _safeMint(msg.sender, 5004);
        _safeMint(msg.sender, 5005);
        _safeMint(msg.sender, 5006);
        balanceMythical[msg.sender]+=7;
    }

    function isValidRex(uint256 _id) pure internal returns(bool) {

		if (_id >> 96 != 0x0000000000000000000000008d7aeb636db83bd1b1c58eff56a40321584ea18c)
			return false;

		if (_id & 0x000000000000000000000000000000000000000000000000000000ffffffffff != 1)
			return false;

		uint256 id = (_id & 0x0000000000000000000000000000000000000000ffffffffffffff0000000000) >> 40;
		if (id-124 > 100)
			return false;
		return true;
	}

	function returnCorrectId(uint256 _id) pure internal returns(uint256) {
		_id = (_id & 0x0000000000000000000000000000000000000000ffffffffffffff0000000000) >> 40;
		return _id-124;
	}    
    
	function transferFrom(address from, address to, uint256 tokenId) public override {
        EVOLVE_TOKEN.updateClaimable(from, to);
        increaseBalance(tokenId, to);
        decreaseBalance(tokenId, from);
		ERC721Upgradeable.transferFrom(from, to, tokenId);
	}
    
	function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override {
        EVOLVE_TOKEN.updateClaimable(from, to);
        increaseBalance(tokenId, to);
        decreaseBalance(tokenId, from);
		ERC721Upgradeable.safeTransferFrom(from, to, tokenId, _data);
	}

    function initialize(string memory name_, string memory symbol_) public initializer {
        __Ownable_init_unchained();        
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name_, symbol_);

        TOKEN_PRICE = 65000000000000000;
        MAX_TOKENS_MINTABLE = 3;        
        MAX_BABY_TOKENS = 3898;
        MAX_UNCOMMON_TOKENS = 1300;
        MAX_RARE_TOKENS = 500;
        MAX_LEGENDARY_TOKENS = 126;
        MAX_MYTHICAL_TOKENS = 12;
        availableMythicals[40000] = true;
        availableMythicals[40001] = true;
        availableMythicals[40002] = true;
        availableMythicals[40003] = true;
        availableMythicals[40004] = true;
        availableMythicals[40005] = true;
        availableMythicals[40006] = true;
        availableMythicals[40007] = true;
        availableMythicals[40008] = true;
        availableMythicals[40009] = true;
        availableMythicals[40010] = true;
        availableMythicals[40011] = true;
        REX_FOR_UNCOMMON = 2;
        REX_FOR_RARE = 5;
        REX_FOR_LEGENDARY = 10;
        REX_FOR_MYTHICAL = 25;
        BASE_URI = "http://phpstack-636608-2278840.cloudwaysapps.com/rex/api/?token_id=";
    }

    function tokensOfOwner(address _owner) external view returns(uint[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            delete index;
            return result;
        }
    }
    
    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes calldata _data) external view returns(bytes4) {
		require(msg.sender == address(OPENSEA_STORE), "not opensea asset");
		return Rex.onERC1155Received.selector;
	}

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0; 

import "./Rex.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract EvolveToken is Initializable, ERC20Upgradeable, OwnableUpgradeable {
    
	using SafeMathUpgradeable for uint256;

	uint256 public UNCOMMON_RATE; 
	uint256 public RARE_RATE; 
	uint256 public LEGENDARY_RATE; 
	uint256 public MYTHICAL_RATE; 
	uint256 public GENESIS_RATE; 
	uint256 public END; 
	uint256 public START; 

	mapping(address => uint256) public claimable;
	mapping(address => uint256) public lastUpdate;

	Rex public REX_CONTRACT;

    function initialize(string memory name_, string memory symbol_) public initializer {
        __Ownable_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
        UNCOMMON_RATE = 1 ether;
        RARE_RATE = 5 ether;
        LEGENDARY_RATE = 15 ether;
        MYTHICAL_RATE = 60 ether;
        GENESIS_RATE = 30 ether;
        END = 1798761599;
        START = 1798761599;
    }

    function setRexContract(address _rex) external onlyOwner {
        REX_CONTRACT = Rex(_rex);
    }

    function enableEarning() external onlyOwner {
        START = block.timestamp;
    }

    function setEnd(uint256 _timestamp) external onlyOwner {
        END = _timestamp;
    }

    function setGenesisRate(uint256 _rate) external onlyOwner {
        GENESIS_RATE = _rate;
    }

    function setUncommonRate(uint256 _rate) external onlyOwner {
        UNCOMMON_RATE = _rate;
    }

    function setRareRate(uint256 _rate) external onlyOwner {
        RARE_RATE = _rate;
    }

    function setLegendaryRate(uint256 _rate) external onlyOwner {
        LEGENDARY_RATE = _rate;
    }

    function setMythicalRate(uint256 _rate) external onlyOwner {
        MYTHICAL_RATE = _rate;
    }

	function updateClaimable(address _from, address _to) external {
		require(msg.sender == address(REX_CONTRACT), "not allowed");
        if(START <= block.timestamp){
            uint256 timerFrom = lastUpdate[_from];

            if (timerFrom == 0){
                timerFrom = START;
            }
            updateClaimableFor(_from,timerFrom);
            delete timerFrom;

            if (_to != address(0)) {
                uint256 timerTo = lastUpdate[_to];
                if (timerTo == 0){
                    timerTo = START;
                }
                updateClaimableFor(_to,timerTo);
                delete timerTo;
            }
        }
	}

    function updateClaimableFor(address _owner, uint256 _timer) internal {
        uint256 pending = getPendingClaimable(_owner, _timer);
        claimable[_owner] += pending;
        if (_timer != END) {
            uint256 time = min(block.timestamp, END);
			lastUpdate[_owner] = time;
            delete time;
        }
        delete pending;
    }

	function claimTokens(address _to) external {
		require(msg.sender == address(REX_CONTRACT));
		uint256 canClaim = claimable[_to];
		if (canClaim > 0) {
			claimable[_to] = 0;
			_mint(_to, canClaim);
		}
        delete canClaim;
	}

	function burn(address _from, uint256 _amount) external {
		require(msg.sender == address(REX_CONTRACT));
		_burn(_from, _amount);
	}

    function getPendingClaimable(address _owner, uint256 _timer) internal view returns(uint256){
        uint256 pending = 0;
        uint256 time = min(block.timestamp, END);
        pending += REX_CONTRACT.balanceGenesis(_owner).mul(GENESIS_RATE.mul((time.sub(_timer)))).div(86400);
        pending += REX_CONTRACT.balanceUncommon(_owner).mul(UNCOMMON_RATE.mul((time.sub(_timer)))).div(86400);
        pending += REX_CONTRACT.balanceRare(_owner).mul(RARE_RATE.mul((time.sub(_timer)))).div(86400);
        pending += REX_CONTRACT.balanceLegendary(_owner).mul(LEGENDARY_RATE.mul((time.sub(_timer)))).div(86400);
        pending += REX_CONTRACT.balanceMythical(_owner).mul(MYTHICAL_RATE.mul((time.sub(_timer)))).div(86400);
        return pending;
    }

	function getTotalClaimable(address _user) external view returns(uint256) {
        uint256 pending = 0;
        if(START <= block.timestamp){
            uint256 timerFrom = lastUpdate[_user];
            if (timerFrom == 0){
                timerFrom = START;
            }
            pending += getPendingClaimable(_user, timerFrom);
            delete timerFrom;
        }
		return claimable[_user] + pending;
	}

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
		return a < b ? a : b;
	}

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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
interface IERC165Upgradeable {
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

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
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

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
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

import "../ERC721Upgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721EnumerableUpgradeable is Initializable, ERC721Upgradeable, IERC721EnumerableUpgradeable {
    function __ERC721Enumerable_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721Enumerable_init_unchained();
    }

    function __ERC721Enumerable_init_unchained() internal initializer {
    }
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC721Upgradeable) returns (bool) {
        return interfaceId == type(IERC721EnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Upgradeable.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721EnumerableUpgradeable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721Upgradeable.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721Upgradeable.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
    uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
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
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
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
    ) public virtual override {
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
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
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
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
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
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
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
        address owner = ERC721Upgradeable.ownerOf(tokenId);

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
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
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
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
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
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
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
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}