// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DreamUtil.sol";

/**
 * @title DreamMaker contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract DreamMaker is ERC721, Ownable
{
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;

	/* CID 
	* Constant CID of the IPFS folder containing tokens. The art will be uploaded before the Contract is deployed.
	* This guarantees that the token order or contents cannot be changed afterwards.
	*/
	string public constant PROVENANCE_CID = "QmeXbJhw6Lp7g7FcV6yHzyvoSTcvKQxFVFdXZVQa8SQYvm";	

	/* PRICES */
	uint256 public PRICE_PASS 			= 200000000000000000;	// 0.20 ETH
	uint256 public PRICE_MINT_WITH_PASS =  80000000000000000;	// 0.08	ETH
	uint256 public PRICE_MINT_WITH_T1 	= 100000000000000000;	// 0.10 ETH 
	uint256 public PRICE_MINT_WITH_T2 	= 120000000000000000;	// 0.12 ETH
	uint256 public PRICE_MINT_GENERAL 	= 150000000000000000;	// 0.15 ETH
	
	/* LIMITS */ 
	uint256 public MAX_DREAMS 			= 10000; 
	uint256 public MINTS_PER_GENERAL 	= 1;
	uint256 public MAX_PASSES 			= 500;
	uint256 public MINTS_PER_PASS 		= 3;
	uint256 public MAX_T1 				= 1000;
	uint256 public MINTS_PER_T1 		= 2;
	uint256 public MAX_T2 				= 2000; 
	uint256 public MINTS_PER_T2 		= 1;
	uint256 public MAX_RESERVE 			= 250;
	
	/* TIMESTAMPS */ 
	uint256 public TIMESTAMP_T1 		= 1643112000;
	uint256 public TIMESTAMP_T2 		= 1643198400;
	uint256 public TIMESTAMP_GENERAL 	= 1643284800;
	uint256 public TIMESTAMP_REVEAL 	= 1643371200;
	
	/* LISTS */
	mapping(address => bool) public passList;
	mapping(address => uint256) public whiteList;
	mapping(address => uint256) public mintList;
	address[] public passOwners;
	
	/* URIS */ 
	string public _blindURI; 
	string public _tokenURI; 
	string public _contractURI; 
	
	/* TOGGLES */
	bool public saleIsActive = true;
	
	/* RESERVED */
	uint256 public reserved;
	address wallet1;
    address wallet2;
	address wallet3;
	address publisher;
	
	constructor() ERC721("Dream Babes", "DREAM") 
	{
		wallet1 = 0x6e6C4b1F09bDb69a0F7E63541F0cc849f1c59138;
		wallet2 = 0x04871659708aAC877AeF2181ef4f7cfF0CE69DDc;
		wallet3 = 0xd22B4DA311d97299652ac1a7a4C18C1487fb9a56;
		/* this will be set once, after the initial deployment */
		publisher = address(0);

		_blindURI = "https://dreambabes.mypinata.cloud/ipfs/QmZUbUqiUSyHogTGr4zveDXLAdXGm2hB2gWKcnDujPaUFj";
		_tokenURI = "https://dreambabes.mypinata.cloud/ipfs/QmQJ5iyee8aHAfhWtQiW31K1iM2BKBUKvGmhSNqvPYaQd3/";

		/* this will be set after the initial deployment, because OpenSea requires the address of this contract to send the royalties to it*/
		_contractURI = "";
	}

	/* SET TIMESTAMP_GENERAL 
	*/
	function setTimestampGeneral(uint256 value) external onlyOwner
	{
		TIMESTAMP_GENERAL = value;
	}

	/* SET TIMESTAMP_REVEAL 
	*/
	function setTimestampReveal(uint256 value) external onlyOwner
	{
		TIMESTAMP_REVEAL = value;
	}

	/* SET TIMESTAMP_T1 
	*/
	function setTimestampT1(uint256 value) external onlyOwner
	{
		TIMESTAMP_T1 = value;
	}

	/* SET TIMESTAMP_T2 
	*/
	function setTimestampT2(uint256 value) external onlyOwner
	{
		TIMESTAMP_T2 = value;
	}

	/* SET PUBLISHER ADDRESS 
	*/
	function setPublisher(address value) external onlyOwner
	{
		require(publisher == address(0), "Already set!");
		publisher = value;
	}

    /* RESERVE 
        - initial reserve for team members
    */
    function reserveDreams(address[] memory addresses, uint256 numberOfTokens) external onlyOwner 
	{
		require(reserved + numberOfTokens.mul(addresses.length) <= MAX_RESERVE);

		for (uint256 a = 0; a < addresses.length; a++)
		{
			require(addresses[a] != address(0), "0 address");

			uint256 supply = totalSupply();
			for (uint256 i = 0; i < numberOfTokens; i++) 
			{
				_safeMint(addresses[a], supply + i);
			}

			reserved += numberOfTokens;
		}
    }

	/* BURN ALL 
		- burn all 
	*/
	function burnDreams() external onlyOwner 
	{
        MAX_DREAMS = totalSupply();
        if (startingIndexBlock == 0)
		{
            startingIndexBlock = block.number;
        } 
    }
	
	/* PASS RESERVE 
        - initial reserve for supporters
    */
    function reservePasses(address[] memory addresses) external onlyOwner 
	{
        for (uint256 i = 0; i < addresses.length; i++)
		{
			passOwners.push(addresses[i]);
			passList[addresses[i]] = true; 
		}
    }

	function getPassList() view external returns (address[] memory)
	{
		return passOwners;
	}

	/* WHITELIST
		- set whitelist for an array of addresses
	*/
	function whitelist(address[] memory addresses, uint16 value) external onlyOwner 
	{
		require(value == 1 || value == 2, "Invalid whitelist");

		for (uint256 i = 0; i < addresses.length; i++)
		{
			require (addresses[i] != address(0));
			whiteList[addresses[i]] = value; 
		}
	}

	/* GET/SET CONTRACT URI 
		- sets the contract URI for Opensea integration
	*/
	function setContractURI(string memory value) external onlyOwner
	{
		_contractURI = value; 
	}
	function contractURI() public view returns (string memory) 
	{
        return _contractURI;
    }

	/* GET TOKEN URI 
	*/
	function tokenURI(uint256 tokenId) public view virtual override(ERC721) returns (string memory) 
	{
        require(_exists(tokenId), "Nonexistent token");

		if (block.timestamp < TIMESTAMP_REVEAL) 
        {
            return string(abi.encodePacked(_blindURI));
        } 
        else 
        {
			string memory sequenceId;
			sequenceId = uint2str((tokenId + startingIndex) % MAX_DREAMS);

        	return string(abi.encodePacked(_tokenURI, sequenceId));
		}
	}

	/* WITHDRAW 
		- withdraws funds
	*/ 
	function withdraw() external onlyOwner
	{	
		uint256 balance = address(this).balance;

		// Send shares to team
        uint256 baseShare = balance.mul(27).div(100);
        payable(wallet1).transfer(baseShare);
        payable(wallet2).transfer(baseShare);
		payable(wallet3).transfer(baseShare);

		// Send share to publisher
		if (publisher != address(0))
		{
			uint256 publisherShare = balance.mul(9).div(100);
			payable(publisher).transfer(publisherShare);
		}

		// Send an even split to all Mint Pass owners
		if (passOwners.length > 0)
		{
			uint256 passShare = balance.mul(10).div(100).div(passOwners.length);
			for(uint256 i = 0; i < passOwners.length; i++)
			{
				payable(passOwners[i]).transfer(passShare);
			}
		}
	}
	
	/* SET SALE STATE 
		- sets sale to active or inactive state
	*/
	function setSaleState(bool state) external onlyOwner
	{
		saleIsActive = state;
	}

	/* MINT PASS 
		- mints a pass to enable the user to mint before presale starts
	*/ 
	function mintPass() external payable 
	{
		require(msg.value >= PRICE_PASS, "Ether value incorrect");
        require(passList[msg.sender] == false, "Already bought");
		require(MAX_PASSES > 0, "No passes left");
		
		passList[msg.sender] = true;
		passOwners.push(msg.sender);
		MAX_PASSES--;
	}

	/* MINT DREAM 
		- mints a dream token 
	*/
	uint256 private startingIndex = 0;
	uint256 private startingIndexBlock = 0;
	function mintDreams(uint256 numberOfTokens) external payable 
	{
		require(saleIsActive == true, "Sale inactive");
		require(totalSupply().add(numberOfTokens) <= MAX_DREAMS, "Max reached");
		require(numberOfTokens > 0, "0 tokens");

		// Pass holders are privileged
		if (passList[msg.sender] == true)
		{
			require(PRICE_MINT_WITH_PASS.mul(numberOfTokens) <= msg.value, "P: value incorrect");
			require(mintList[msg.sender].add(numberOfTokens) <= MINTS_PER_PASS , "P: zero dreams");
		}
		// Whitelist T1 holders next
		else if (whiteList[msg.sender] == 1) 
		{
			require(block.timestamp >= TIMESTAMP_T1, "T1: not started ");
			require(PRICE_MINT_WITH_T1.mul(numberOfTokens) <= msg.value, "T1: value incorrect");
			require(mintList[msg.sender].add(numberOfTokens) <= MINTS_PER_T1 , "T1: zero dreams");
		}
		// Whitelist T2 holders next
		else if (whiteList[msg.sender] == 2) 
		{
			require(block.timestamp >= TIMESTAMP_T2, "T2: not started");
			require(PRICE_MINT_WITH_T2.mul(numberOfTokens) <= msg.value, "T2: value incorrect");
			require(mintList[msg.sender].add(numberOfTokens) <= MINTS_PER_T2 , "T2: zero dreams");
		}
		// General sale 
		else
		{
			require(block.timestamp >= TIMESTAMP_GENERAL, "G: not started");
			require(PRICE_MINT_GENERAL.mul(numberOfTokens) <= msg.value, "G: value incorrect");
			require(mintList[msg.sender].add(numberOfTokens) <= MINTS_PER_GENERAL , "G: zero dreams");
		}

        for(uint256 i = 0; i < numberOfTokens; i++) 
		{
            uint256 mintIndex = totalSupply();
			
            if (mintIndex < MAX_DREAMS) 
			{
                _safeMint(msg.sender, mintIndex);
            }
        }

        mintList[msg.sender] = mintList[msg.sender].add(numberOfTokens);

        if (startingIndexBlock == 0 && (totalSupply() == MAX_DREAMS || block.timestamp >= TIMESTAMP_REVEAL)) 
		{
            startingIndexBlock = block.number;
        } 
    }

	/* SET STARTING INDEX 
		- sets the startingIndex to a random position
		- makes sure the index is actually random for everyone, including us
		- this function can only be called once
	*/
	function setStartingIndex() public onlyOwner
	{
        require(startingIndex == 0, "SI set");
        require(startingIndexBlock != 0, "SIB not set");
        
        startingIndex = uint(blockhash(startingIndexBlock)) % MAX_DREAMS;
        if (block.number.sub(startingIndexBlock) > 255) 
		{
            startingIndex = uint(blockhash(block.number - 1)) % MAX_DREAMS;
        }

        if (startingIndex == 0) 
		{
            startingIndex = startingIndex.add(1);
        }
    }

	// never call this
	function emergencySetStartingIndexBlock() public onlyOwner 
	{
        require(startingIndex == 0, "SI set");
        
        startingIndexBlock = block.number;
    }
	
	/* TOKENS OF 
		- gets all tokens for a certain address
		- used for Dream Babe feature integration in Dream Babes and other games
	*/
	function tokensOfOwner(address _owner) external view returns(uint256[] memory) 
	{
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) 
		{
            return new uint256[](0);
        } 
		else 
		{
            uint256[] memory result = new uint256[](tokenCount);
            for (uint256 index; index < tokenCount; index++) 
			{
                result[index] = (tokenOfOwnerByIndex(_owner, index) + startingIndex) % MAX_DREAMS;
            }
            return result;
        }
    }

    /* STATUS OF 
		- returns the status of owner - 3 for Pass, 2 for T2, 1 for T1 and 0 for general user
	*/
    function statusOfOwner(address _owner) external view returns(uint256)
    {
        if (passList[_owner] == true)
        {
            return 3;
        }
        else 
        {
            return whiteList[_owner];   
        }
    }
}