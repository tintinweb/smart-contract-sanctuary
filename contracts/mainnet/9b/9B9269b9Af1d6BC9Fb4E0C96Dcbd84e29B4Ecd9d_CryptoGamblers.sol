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
    
    constructor() ERC721("CryptoGamblers", "GAMBLERS") 
    {
        proxyRegistryAddress = address(0xa5409ec958C83C3f309868babACA7c86DCB077c1);
        ERC721._setBaseURI("https://meta.cryptogamblers.life/gamblers/");
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
	    uint participants_count = 0;
	    for(uint i=0;i<totalSupply();i++)
	    {
	        if(tokenPropertiesString[i].strMatch(properties))
            {
	            participants[participants_count++] = i+1;
	        }
	    }
	    return (participants, participants_count);
	}
	
    // RNG functions ownerOnly
    // probability sheet : https://ipfs.io/ipfs/QmPTm2MvYTHjoSQZSJY5SErGaEL3soje7QpcaqFntwkGno
	function generateRandomProperties() internal returns(string memory)
	{
        // prob(id_0) = (prob_arr[1] - prob_arr[0]) / prob_arr[prob_arr.length - 1]
        // prob(id_1) = (prob_arr[2] - prob_arr[1]) / prob_arr[prob_arr.length - 1] ....
        
        uint[] memory hat_hair = new uint[](9);
        hat_hair[0] = 0; 
        hat_hair[1] = 7;    // Blank - 7.00%
        hat_hair[2] = 22;   // Cilinder - 15.00%
        hat_hair[3] = 35;   // Fallout - 13.00%
        hat_hair[4] = 46;   // Jokerstars - 11.00%
        hat_hair[5] = 61;   // Leverage - 15.00%
        hat_hair[6] = 73;   // Peaky Blinder - 12.00%
        hat_hair[7] = 92;   // Pump & Dump - 19.00%
        hat_hair[8] = 100;  // SquidFi Hat - 8.00%
        
        uint[] memory skin_color_facial_expression = new uint[](22);
        skin_color_facial_expression[0] = 0;
        skin_color_facial_expression[1] = 0; // Blank - 0.00%
        skin_color_facial_expression[2] = 17; // Ape Bronze - 1.70% 
        skin_color_facial_expression[3] = 24; // Ape Red - 0.70%
        skin_color_facial_expression[4] = 84; // Black Ecstatic - 6.00%
        skin_color_facial_expression[5] = 144; // Black Frustrated - 6.00%
        skin_color_facial_expression[6] = 204; // Black Rage - 6.00%
        skin_color_facial_expression[7] = 264; // Black Devastated - 6.00%
        skin_color_facial_expression[8] = 271; // Golden Pepe - 0.70%
        skin_color_facial_expression[9] = 288; // Green Pepe - 1.70%
        skin_color_facial_expression[10] = 348; // White Devastated 6.00%
        skin_color_facial_expression[11] = 408; // White Ecstatic 6.00%
        skin_color_facial_expression[12] = 468; // White Frustrated 6.00%
        skin_color_facial_expression[13] = 528;// White Rage 6.00%
        skin_color_facial_expression[14] = 588; // Yellow Devastated 6.00%
        skin_color_facial_expression[15] = 648; // Yellow Excited 6.00%
        skin_color_facial_expression[16] = 708;  // Yellow Frustrated 6.00%
        skin_color_facial_expression[17] = 768; // Yellow Happy 6.00%
        skin_color_facial_expression[18] = 826; // Zombie Happy 5.80%
        skin_color_facial_expression[19] = 884; // Zombie Devastated 5.80%
        skin_color_facial_expression[20] = 942; // Zombie Ecstatic 5.80%
        skin_color_facial_expression[21] = 1000; // Zombie Rage 5.80%
        
        uint[] memory neck = new uint[](8);
        
        neck[0] = 0; 
        neck[1] = 70; // Blank - 7.00%
        neck[2] = 127; // Golden chain - 5.70%
        neck[3] = 397; // Horseshoe -27.00%
        neck[4] = 577; // Ledger - 18.00%
        neck[5] = 723; // Lucky Clover - 14.60%
        neck[6] = 873; // Piggy Bank - 15.00%
        neck[7] = 1000; // Silver chain  - 12.70%
        
        
        uint[] memory upper_body = new uint[](10);
        upper_body[0] = 0; 
        upper_body[1] = 7; // Blank - 7.00%
        upper_body[2] = 17; // 9 to 5 Shirt - 10.00%
        upper_body[3] = 23; // ChimsCoin T-shirt - 6.00%
        upper_body[4] = 38;// Coinface Jacket -15.00%
        upper_body[5] = 48; // Hawaii Shirt - 10.00%
        upper_body[6] = 58; // Hoodie Lose365 - 10.00%
        upper_body[7] = 66; // Lumber-Gambler Shirt - 8.00%
        upper_body[8] = 80; // Tuxedo Top - 14.00%
        upper_body[9] = 100; // Uniswamp degen T-shirt - 20.00%

        
        uint[] memory lower_body = new uint[](8);
        lower_body[0] = 0; 
        lower_body[1] = 7; // Blank - 7.00%
        lower_body[2] = 19; // Baggy Jeans - 12.00%
        lower_body[3] = 35; // Blue Jeans - 16.00%
        lower_body[4] = 51; // Colorful Shorts - 16.00%
        lower_body[5] = 60; // Ripped Jeans - 9.00%
        lower_body[6] = 85; // Sports Pants - 25.00%
        lower_body[7] = 100;// Tuxedo Pants - 15.00%

        uint[] memory shoes = new uint[](8);
        shoes[0] = 0; 
        shoes[1] = 7; // Blank - 7.00%
        shoes[2] = 23; // Cowboy Boots - 16.00% 
        shoes[3] = 43; // Crocs - 20.00%
        shoes[4] = 51; // Fancy Sneakers - 8.00%
        shoes[5] = 55; // Lux Flip Flops - 4.00%
        shoes[6] = 80; // Old Sneakers - 25.00%
        shoes[7] = 100; //Oxfords - 20.00%
        
        uint[] memory attributes = new uint[](26);
        attributes[0] = 0;
        attributes[1] = 0; // Blank - 0.00%
        attributes[2] = 100; // Cone (left hand) - 10.00%
        attributes[3] = 200; // Fishing pole (right hand) - 10.00%
        attributes[4] = 220; // Fishing pole (right hand) + Cone (left hand) - 2.00%
        attributes[5] = 230; // Fishing pole (right hand) + Golden watch (left hand) - 1.00%
        attributes[6] = 250; // Fishing pole (right hand) + Joint (left hand) - 2.00%
        attributes[7] = 255; // Fishing  pole(right hand) + OpenOcean bag (left hand) - 0.50%
        attributes[8] = 355; // Golden watch (left hand) - 10.00%
        attributes[9] = 455; // Gun (right hand) - 10.00%
        attributes[10] = 555; // Joint (left hand) - 10.00%
        attributes[11] = 655; // Money bills (right hand) - 10.00%
        attributes[12] = 670; // Money bills (right hand) + Cone (left hand) - 1.50%
        attributes[13] = 690; // Money bills (right hand) + Golden watch (left hand) - 2.00%
        attributes[14] = 695; // Money bills (right hand) + Joint (left hand) - 0.50%
        attributes[15] = 715; // Money bills (right hand) + OpenOcean bag (left hand) - 2.00%
        attributes[16] = 815; // OpenOcean bag (left hand) - 10.00%
        attributes[17] = 915; // Phone (right hand) - 10.00%
        attributes[18] = 920; // Phone (right hand) + Cone (left hand) - 0.50%
        attributes[19] = 935; // Phone (right hand) + Golden watch (left hand) - 1.50%
        attributes[20] = 950; // Phone (right hand) + Joint (left hand) - 1.50%
        attributes[21] = 965; // Phone (right hand) + OpenOcean bag (left hand) - 1.50%
        attributes[22] = 975; // Pistol (right hand) + Cone (left hand) - 1.00%
        attributes[23] = 980; // Pistol (right hand) + Golden watch (left hand) - 0.50%
        attributes[24] = 990; // Pistol (right hand) + Joint (left hand) - 1.00%
        attributes[25] = 1000; //Pistol (right hand) + OpenOcean bag (left hand) - 1.00%

        
	    return string(abi.encodePacked( Strings.uintToPad2Str(upperBound(hat_hair,     randomUint(randomSeed(), hat_hair[hat_hair.length - 1])) - 1),
	                                    Strings.uintToPad2Str(upperBound(skin_color_facial_expression,      randomUint(randomSeed(), skin_color_facial_expression[skin_color_facial_expression.length - 1])) - 1),
	                                    Strings.uintToPad2Str(upperBound(neck,    randomUint(randomSeed(), neck[neck.length - 1])) - 1),
	                                    Strings.uintToPad2Str(upperBound(upper_body,    randomUint(randomSeed(), upper_body[upper_body.length - 1])) - 1),
	                                    Strings.uintToPad2Str(upperBound(lower_body,        randomUint(randomSeed(), lower_body[lower_body.length - 1])) - 1),
	                                    Strings.uintToPad2Str(upperBound(shoes,    randomUint(randomSeed(), shoes[shoes.length - 1])) - 1),
	                                    Strings.uintToPad2Str(upperBound(attributes,         randomUint(randomSeed(), attributes[attributes.length - 1])) - 1)));
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