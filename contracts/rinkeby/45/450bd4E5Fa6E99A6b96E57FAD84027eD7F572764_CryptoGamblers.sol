// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract CryptoGamblers is ERC721, Ownable 
{
	using Strings for string;
	using SafeMath for uint;
	// Max tokens supply
	uint public constant maxSupply = 777;
	//_tokenPropertiesString[tokenID-1] = propertiesString
    string[maxSupply] private tokenPropertiesString;
    // The IPFS hash of token's metadata
    string public metadataHash = "";
    // Variables used for RNG 
    uint private nextBlockNumber = 0;
    bytes32 private secretHash = 0;
    uint private _rngSeed = 0;
    uint private seedExpiry = 0; 
    bool private rngSemaphore = false;
     // Whitelist OpenSea proxy contract for easy trading.
    address proxyRegistryAddress;
    
    // Events
    event SeedInit(address  _from, uint _totalSupply, uint _seedExpiry, uint __rngSeed);
    event SeedReset(address _from, uint _totalSupply, uint _seedExpiry);
    event LotteryFromTo(address indexed _from, address _winner, uint _value, uint _firstTokenId, uint _lastTokenId, string _userInput, uint indexed _luckyNumber);
    event LotteryProperties(address indexed _from, address _winner, uint _value, string _propertiesString, string _userInput, uint indexed _luckyNumber);
    
    constructor() ERC721("CryptoGamblers", "GMBLR") 
    {
        proxyRegistryAddress = address(0xa5409ec958C83C3f309868babACA7c86DCB077c1);
        ERC721._setBaseURI("https://nft.cryptogamblers.life/gamblers/");
    }
    
    function mint(string memory properties) public onlyOwner 
	{
        require(totalSupply() < maxSupply, "Exceeds max supply");
        require(seedExpiry > totalSupply(), "_rngSeed expired");
        require(rngSemaphore == false, "secret is not revealed");
        
		uint newTokenId = totalSupply().add(1);
		if(newTokenId != maxSupply)
		{
			properties = generateRandomProperties();
		}
		else
		{
			// the special one
			require(properties.strMatch("??????????????"));
		}
      	_mint(owner(), newTokenId);
		tokenPropertiesString[newTokenId-1] = properties;
   	}
   	
   	function setMetadataHash(string memory hash) public onlyOwner 
    {
        // modifications are not allowed
        require(bytes(metadataHash).length == 0 && totalSupply() == maxSupply);
        metadataHash = hash;
    }

    // public getters
    function propertiesOf(uint tokenId) public view returns (string memory) 
	{
		require(tokenId >= 1 && tokenId <= totalSupply());
		return tokenPropertiesString[tokenId-1];
	}
	
	function getGamblersByProperties(string memory properties) public view returns(uint[] memory, uint)
	{
	    uint[] memory participants = new uint[](totalSupply());
	    bytes memory pattern = bytes(properties);
	    uint participants_count = 0;
	    for(uint i=0;i<totalSupply();i++)
	    {
	        if(Strings.strMatch(bytes(tokenPropertiesString[i]), pattern))
            {
	            participants[participants_count++] = i+1;
	        }
	    }
	    return (participants, participants_count);
	}
	
    // RNG functions ownerOnly
	function generateRandomProperties() internal returns(string memory)
	{
        // prob(id_0) = (prob_arr[1] - prob_arr[0]) / prob_arr[prob_arr.length - 1]
        // prob(id_1) = (prob_arr[2] - prob_arr[1]) / prob_arr[prob_arr.length - 1] ....
        uint[] memory face_skin = new uint[](18);
        face_skin[0] = 0; 
        face_skin[1] = 0; 
        face_skin[2] = 5; // white - 15%
        face_skin[3] = 10; // black - 15%
        face_skin[4] = 20; // yellow - 40%
        face_skin[5] = 25; // gypsy - 30%
        face_skin[6] = 35; // gypsy - 30%
        face_skin[7] = 40; // gypsy - 30%
        face_skin[8] = 45; // gypsy - 30%
        face_skin[9] = 50; // gypsy - 30%
        face_skin[10] = 52; // gypsy - 30%
        face_skin[11] = 55; // gypsy - 30%
        face_skin[12] = 60; // gypsy - 30%
        face_skin[13] = 65; // gypsy - 30%
        face_skin[14] = 75; // gypsy - 30%
        face_skin[15] = 85; // gypsy - 30%
        face_skin[16] = 90; // gypsy - 30%
        face_skin[17] = 100; // gypsy - 30%
        
        
        uint[] memory hat_hair = new uint[](9);
        hat_hair[0] = 0; 
        hat_hair[1] = 10; 
        hat_hair[2] = 20; 
        hat_hair[3] = 30;
        hat_hair[4] = 50; 
        hat_hair[5] = 70; 
        hat_hair[6] = 80; 
        hat_hair[7] = 90; 
        hat_hair[8] = 100; 

        
        uint[] memory upper_body = new uint[](9);
        upper_body[0] = 0; 
        upper_body[1] = 10; 
        upper_body[2] = 20; 
        upper_body[3] = 30;
        upper_body[4] = 40; 
        upper_body[5] = 50; 
        upper_body[6] = 70; 
        upper_body[7] = 80; 
        upper_body[8] = 100; 

        
        uint[] memory lower_body = new uint[](6);
        lower_body[0] = 0; 
        lower_body[1] = 30; 
        lower_body[2] = 60; 
        lower_body[3] = 80;
        lower_body[4] = 90; 
        lower_body[5] = 100; 

        
        
        uint[] memory amulet = new uint[](5);
        amulet[0] = 0; 
        amulet[1] = 50; 
        amulet[2] = 70; 
        amulet[3] = 90;
        amulet[4] = 100; 

        
        uint[] memory attributes = new uint[](24);
        attributes[0] = 0; 
        attributes[1] = 5; 
        attributes[2] = 10; 
        attributes[3] = 30;
        attributes[4] = 35; 
        attributes[5] = 40; 
        attributes[6] = 44; 
        attributes[7] = 46; 
        attributes[8] = 50; 
        attributes[9] = 55; 
        attributes[10] = 60; 
        attributes[11] = 63; 
        attributes[12] = 66; 
        attributes[13] = 69; 
        attributes[14] = 75; 
        attributes[15] = 80; 
        attributes[16] = 82; 
        attributes[17] = 84; 
        attributes[18] = 86; 
        attributes[19] = 88; 
        attributes[20] = 90; 
        attributes[21] = 93; 
        attributes[22] = 96; 
        attributes[23] = 100;

        
        uint[] memory shoes = new uint[](7);
        shoes[0] = 0; 
        shoes[1] = 2; 
        shoes[2] = 20; 
        shoes[3] = 30;
        shoes[4] = 50; 
        shoes[5] = 60; 
        shoes[6] = 100; 

        
        
	    return string(abi.encodePacked( Strings.uintToPad2Str(upperBound(face_skin,     randomUint(randomSeed(), face_skin[face_skin.length - 1])) - 1),
	                                    Strings.uintToPad2Str(upperBound(hat_hair,      randomUint(randomSeed(), hat_hair[hat_hair.length - 1])) - 1),
	                                    Strings.uintToPad2Str(upperBound(upper_body,    randomUint(randomSeed(), upper_body[upper_body.length - 1])) - 1),
	                                    Strings.uintToPad2Str(upperBound(lower_body,    randomUint(randomSeed(), lower_body[lower_body.length - 1])) - 1),
	                                    Strings.uintToPad2Str(upperBound(amulet,        randomUint(randomSeed(), amulet[amulet.length - 1])) - 1),
	                                    Strings.uintToPad2Str(upperBound(attributes,    randomUint(randomSeed(), attributes[attributes.length - 1])) - 1),
	                                    Strings.uintToPad2Str(upperBound(shoes,         randomUint(randomSeed(), shoes[shoes.length - 1])) - 1)));
	}
	
	function sendSecretHash(bytes32 _secretHash, uint count) public onlyOwner
    {
        require(rngSemaphore == false && seedExpiry == totalSupply() && count > 0);
        secretHash = _secretHash;
        seedExpiry = count.add(totalSupply());
        nextBlockNumber = block.number + 1;
        rngSemaphore = true;
    }
    
    function initRng(string memory secret) public onlyOwner
    {
        require(rngSemaphore == true && block.number >= nextBlockNumber);
        require(keccak256(abi.encodePacked(secret)) == secretHash, "wrong secret");
        _rngSeed = uint(keccak256(abi.encodePacked(secret, blockhash(nextBlockNumber))));
        rngSemaphore = false;
        emit SeedInit(msg.sender, totalSupply(), seedExpiry, _rngSeed);
    }

    function resetRng() public onlyOwner
    {   // we should never call this function
        require(rngSemaphore == true);
        // event trigger
        emit SeedReset(msg.sender, totalSupply(), seedExpiry);
        seedExpiry = totalSupply();
        rngSemaphore = false;
    }
    
    function randomSeed() internal returns (uint)
    {
        //unchecked
//        {
           _rngSeed = _rngSeed + 1;
//        }
        return _rngSeed;
    }
    
    // RNG functions public 
    function randomUint(uint seed, uint modulo) internal pure returns (uint) 
    {
        uint num;
        uint nonce = 0;
        do
        {
            num = uint(keccak256(abi.encodePacked(seed, nonce++ )));
        } 
        while( num >= type(uint).max - (type(uint).max.mod(modulo)) );
        return num.mod(modulo);
    }
    
    // Lottery functions, Off chain randomness : seed = Hash(userSeed + blockhash(currBlockNumber-7))
    function tipRandomGambler(uint firstTokenId, uint lastTokenId, string memory userSeed) public payable
	{
	    require(msg.value != 0, "Send some ether" );
	    require(firstTokenId >= 1 && lastTokenId <= totalSupply() && lastTokenId.sub(firstTokenId) > 0, "Invalid arguments");
	    uint winner = firstTokenId.add(randomUint(uint(keccak256(abi.encodePacked(userSeed, blockhash(block.number - 7)))), lastTokenId.sub(firstTokenId).add(1)));
	    address winnerOwner = ownerOf(winner);
	    payable(winnerOwner).transfer(msg.value);
	    emit LotteryFromTo(msg.sender, winnerOwner, msg.value, firstTokenId, lastTokenId, userSeed, winner);
	}
	
	function tipRandomGambler(string memory userSeed) public payable
	{
        tipRandomGambler(1, totalSupply(), userSeed);
	}
    
    function tipRandomGambler(string memory properties, string memory userSeed) public payable
	{
	    require(msg.value != 0, "Send some ether" );
        require(properties.strMatch("??????????????"), "Invalid arguments");
        (uint[] memory participants, uint participants_count) = getGamblersByProperties(properties);
	    require(participants_count != 0, "No participants");
	    uint winner = participants[randomUint(uint(keccak256(abi.encodePacked(userSeed, blockhash(block.number - 7)))), participants_count)];
	    address winnerOwner = ownerOf(winner);
	    payable(winnerOwner).transfer(msg.value);
	    emit LotteryProperties(msg.sender, winnerOwner, msg.value, properties, userSeed, winner);
	}
	
    // Binary search
    function upperBound(uint[] memory arr, uint value) internal pure returns(uint) 
    { 
        uint mid; 
        uint low = 0; 
        uint high = arr.length; 

        while (low < high) 
        { 
            mid = low + (high - low) / 2; 
            if (value >= arr[mid]) 
                low = mid + 1; 
            else 
                high = mid; 
        } 
        return low; 
    } 
	
    /**
    * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
    */
    function isApprovedForAll(address owner, address operator)
        public
        view
		override
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }
}