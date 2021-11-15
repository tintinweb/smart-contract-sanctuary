// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "./creatSprite.sol";


contract pixelSprite is creatSprite {
	string constant BALANCE_IS_ZERO = "005001";
	string constant SPRITE_STATUS_IS_NOT_FREE = "005002";
	string constant END_PRICE_SMALL_THAN_START_PRICE = "005003";
	string constant YOU_ARE_NOT_OWNER = "005004";
	string constant END_DAY_MUST_SMALL_THAN_30DAYS = "005005";
	string constant END_PRICE_MUST_BIG_THAN_ZERO = "005006";
	string constant YOU_CANT_BUY_YOUR_SELF = "005007";
	string constant IT_IS_NOT_FOR_SALE = "005008";
	string constant IT_HAS_EXPIRA = "005009";
	string constant UNKOWN_ERROR = "005010";
	string constant PRICE_ERROR = "005011";
	string constant INSUFFICIENT_BALANCE = "005012";
	string constant AUCTION_TYPE_IS_ERROR = "005013";
	string constant END_DAY_MUST_BIG_THAN_1DAYS = "005014";

	
	mapping(address=>uint256) public UserETHBalance;	
	
	struct offer{
		bool 	isForSale;			//Sale status
		uint8 	auctionType;		//Auction type 0 is fixed bid 1 is decreasing in time
		uint32 	startTime;		
		uint32 	expirationTime;	
		address seller;			
		
		uint256 price;				//Selling price, initial price
		uint256 endPrice;			
	}

	mapping(uint256=>offer) public OfferList; 
	
	
	
	function userWithdrawETH()public {
		require(UserETHBalance[msg.sender]>0,BALANCE_IS_ZERO); 

		uint256 sendValue = UserETHBalance[msg.sender]; 
		
		UserETHBalance[msg.sender] = 0; 

		payable(msg.sender).transfer(sendValue); 	
	}
	

	
	function sellWithFixPrice(uint256 _price,uint256 _spriteID) public {
		require(getSpriteStatus(_spriteID)==1, SPRITE_STATUS_IS_NOT_FREE); 
		require(msg.sender ==  SpriteList[_spriteID].owner ,YOU_ARE_NOT_OWNER); 

		changeSpriteStatus(_spriteID,2,0); 
		OfferList[_spriteID] = offer(true,0,uint32(block.timestamp),0,msg.sender,_price,0);
		
		emit AddOffer(_spriteID,0,block.timestamp,0,_price,0);
	}

	function sellWithEndPrice(uint256 _price,uint256 _endPrice,uint256 _spriteID,uint256 _endDay) public {
		require(_endPrice<_price,END_PRICE_SMALL_THAN_START_PRICE);
		require(getSpriteStatus(_spriteID)==1, SPRITE_STATUS_IS_NOT_FREE); 
		require(msg.sender ==  SpriteList[_spriteID].owner ,YOU_ARE_NOT_OWNER);

		require(_endDay<=30,END_DAY_MUST_SMALL_THAN_30DAYS); 
		require(_endDay>0,END_DAY_MUST_BIG_THAN_1DAYS); 
		require(_endPrice>0,END_PRICE_MUST_BIG_THAN_ZERO); 

		uint256 endTime = block.timestamp+_endDay*86400;
		
		changeSpriteStatus(_spriteID,3,endTime); 
		
		OfferList[_spriteID] = offer(true,1,uint32(block.timestamp),uint32(endTime),msg.sender,_price,_endPrice);
	
		emit AddOffer(_spriteID,1,block.timestamp,endTime,_price,_endPrice);
	}

	

	function buySprite(uint256 _spriteID,uint256 _price) payable  public{
		address seller = OfferList[_spriteID].seller;

		require(msg.sender !=  seller ,YOU_CANT_BUY_YOUR_SELF);
		require(OfferList[_spriteID].isForSale,IT_IS_NOT_FOR_SALE);
		
	
		if(OfferList[_spriteID].auctionType == 0 ){ //Fixed bid
			_buyWithFixPrice(_price,_spriteID,seller);
		}else{//Dutch auction
			_buyWithEndPrice(_price,_spriteID,seller);
		}
	
		emit BuySprite(_spriteID,_price,msg.sender,seller);

		emit Transfer(seller,msg.sender,_spriteID);
	}
	

	
	function _buyWithFixPrice(uint256 _price,uint256 _spriteID,address seller) internal {
		require(seller == SpriteList[_spriteID].owner,UNKOWN_ERROR);
		
		require(_price == OfferList[_spriteID].price,PRICE_ERROR); 
		
		UserETHBalance[msg.sender] += msg.value; 

		require(UserETHBalance[msg.sender] >= _price,INSUFFICIENT_BALANCE);
		
		UserETHBalance[seller] += _getValueBySubTransFee(_price);

		UserETHBalance[msg.sender] -= _price;	

        changeSpriteStatus(_spriteID,1,0); 
		changeOwner(_spriteID,msg.sender);  

		
		delete(OfferList[_spriteID]);
	}

	
	function _buyWithEndPrice(uint256 _price,uint256 _spriteID,address seller) internal  {
		require(seller == SpriteList[_spriteID].owner,UNKOWN_ERROR);

		require(OfferList[_spriteID].expirationTime > block.timestamp,IT_HAS_EXPIRA);

		require(_price >= getAuctionPrice(_spriteID),PRICE_ERROR);

		UserETHBalance[msg.sender] += msg.value;

		require(UserETHBalance[msg.sender] >= _price,INSUFFICIENT_BALANCE);
		
		UserETHBalance[seller] += _getValueBySubTransFee(_price);
		UserETHBalance[msg.sender] -= _price;
        
		changeSpriteStatus(_spriteID,1,0);
		changeOwner(_spriteID,msg.sender);

		delete(OfferList[_spriteID]); 
	}

	function cancelOffer(uint256 _spriteID) external {
		address seller = OfferList[_spriteID].seller;

		require(msg.sender ==  seller ,YOU_ARE_NOT_OWNER);
		require(OfferList[_spriteID].isForSale,IT_IS_NOT_FOR_SALE);
		
		if(OfferList[_spriteID].auctionType == 1){ //Can only be cancelled before expiration
			require(OfferList[_spriteID].expirationTime > block.timestamp,IT_HAS_EXPIRA);
		}

		changeSpriteStatus(_spriteID,1,0);
		
		delete(OfferList[_spriteID]);

		emit CancelOffer(_spriteID);
	}

	function _getValueBySubTransFee(uint256 _price) internal returns(uint256)  {
		uint256 fee = _price*5/100;
		OwnerEthBalance += fee;
		return _price-fee;
	}

	function getAuctionPrice(uint256 _spriteID) public view returns(uint256){
		require(OfferList[_spriteID].expirationTime >= block.timestamp,IT_HAS_EXPIRA); 

		require(OfferList[_spriteID].isForSale,IT_IS_NOT_FOR_SALE);
		require(OfferList[_spriteID].auctionType == 1,AUCTION_TYPE_IS_ERROR);

		uint256 duration = OfferList[_spriteID].expirationTime - OfferList[_spriteID].startTime;

		uint256 hasPassed = block.timestamp-OfferList[_spriteID].startTime;

		uint256 totalChange =  OfferList[_spriteID].price - OfferList[_spriteID].endPrice;

      	uint256 currentChange = totalChange * hasPassed / duration;

      	uint256 currentPrice = OfferList[_spriteID].price - currentChange;
		return currentPrice;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./NFToken.sol";

contract creatSprite is NFToken {
	string constant SEND_VALUE_IS_NOT_EQ_ISSUEPRICE = "004001";
	string constant MINT_COUNT_IS_BIG_THAN_MAXSUPPLY = "004002";
	string constant CANT_CALL_FROM_CONTRACT = "004003";
	string constant TO_UINT32_OUT_Of_BOUNDS = "004004";
	string constant NOT_START_MINT = "004005";


	uint256 public constant MaxSupply = 10000;  
	uint256 internal constant IssuePrice = 0.01 ether; 

	
	function mint() external payable {
		require(msg.value == IssuePrice, SEND_VALUE_IS_NOT_EQ_ISSUEPRICE);
		require(SpriteCount < MaxSupply, MINT_COUNT_IS_BIG_THAN_MAXSUPPLY);
		require(msg.sender == tx.origin,CANT_CALL_FROM_CONTRACT);
		require(block.timestamp >= 1633910400,NOT_START_MINT);
		SpriteCount += 1;  //ID 1--10000

		uint256 spriteID = SpriteCount;
		bytes32 randSeed  = keccak256(abi.encodePacked(block.coinbase,block.difficulty,block.timestamp,spriteID,gasleft()));
		
		spriteItem memory sp = _creatSpriteItem(randSeed);
		sp.addBlockNum = block.number;
		sp.owner = msg.sender;
		sp.status = 1;
		
		SpriteList[spriteID] = sp;

		addHolderTokens(msg.sender,spriteID);

		OwnerEthBalance += msg.value;

		emit BuySprite(spriteID,IssuePrice,msg.sender,address(0x0));
		emit Transfer(address(0x0),msg.sender,spriteID);
	}

	function _creatSpriteItem(bytes32 randSeed) pure private returns(spriteItem memory sp){
		uint256[7] memory  partCountList = [uint256(7),28,32,32,16,11,20];
											
		sp.attribute.color_1 = uint8(_getRandUint(randSeed,0)%216);
		sp.attribute.color_2 = uint8(_getRandUint(randSeed,2)%216);
		sp.attribute.color_3 = uint8(_getRandUint(randSeed,4)%216);
		sp.attribute.color_4 = uint8(_getRandUint(randSeed,6)%216);
		

		uint256 randTruck = _getRandUint(randSeed,8)%1000;
		if(randTruck>=partCountList[0]-1){
			randTruck = 0;
		}else{
			randTruck += 1;
		}

		sp.body.trunkIndex = uint8(randTruck);


		sp.body.mouthIndex = uint8(_getRandUint(randSeed,10)%partCountList[1]);
		sp.body.headIndex = uint8(_getRandUint(randSeed,12)%partCountList[2]);
		sp.body.eyeIndex = uint8(_getRandUint(randSeed,14)%partCountList[3]);
		sp.body.tailIndex = uint8(_getRandUint(randSeed,16)%partCountList[4]);
		sp.body.colorContainerIndex = uint8(_getRandUint(randSeed,18)%partCountList[5]);

		sp.body.skinColorIndex = uint8(_getRandUint(randSeed,20)%partCountList[6]);

		sp.attribute.space = uint8(_getRandUint(randSeed,22)%51+10);//10~60
		
		sp.attribute.speed = _getRand0to9(randSeed[26])*10+1+_getRand0to9(randSeed[27]); //1-100
		sp.attribute.capacity = _getRand0to9(randSeed[28])*10+1+_getRand0to9(randSeed[29]); //1-100
	}


	function _getRandUint(bytes32 randSeed,uint startAt) pure private returns(uint256 num){
		bytes memory _bytes = abi.encodePacked(randSeed);

		require(_bytes.length >= startAt + 4, TO_UINT32_OUT_Of_BOUNDS);

		assembly {
			num := mload(add(add(_bytes, 0x4), startAt))
		}
		
		return num;
	}
	

	
	function _getRand0to9(bytes1 inputByte) pure private  returns(uint8) {
		uint num = uint8(inputByte)%30;
		uint reNum = 0;

		if(num<15){
			if(num==0){
				reNum = 0;
			}else if (num==1 || num==2){
				reNum = 1;
			}else if (num>=3 && num <=5){
				reNum = 2;
			}else if (num>=6 && num <=9){
				reNum = 3;
			}else{ // 10-15
				reNum = 4;
			}
		}else { // >=15 && < 30 
			if(num==29){
				reNum = 9;
			}else if (num == 27 || num ==28){
				reNum = 8;
			}else if (num>=24 && num <=26){
				reNum = 7;
			}else if (num>=20 && num <=23){
				reNum = 6;
			}else{ // 15-19
				reNum = 5;
			}
		}
		return uint8(reNum);
	}

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./components/Ierc721.sol";
import "./sprite.sol";

contract NFToken is sprite,IERC721Metadata,IERC721Enumerable {
	
	//In order to get friendly tips
    string constant ZERO_ADDRESS = "ZERO_ADDRESS";
	string constant INDEX_BIG_THAN_BALANCE = "INDEX_BIG_THAN_BALANCE";
	string constant CANT_TRANSFER_TO_YOURSELF = "CANT_TRANSFER_TO_YOURSELF";
	string constant NOT_VALID_NFT = "NOT_VALID_NFT";
	string constant NTF_STATUS_CANT_TO_SEND = "NTF_STATUS_CANT_TO_SEND";
	string constant NOT_OWNER_APPROVED_OR_OPERATOR = "NOT_OWNER_APPROVED_OR_OPERATOR";
	string constant NOT_OWNER_OR_OPERATOR = "NOT_OWNER_OR_OPERATOR";
	string constant IS_OWNER = "IS_OWNER";

	mapping (uint=>address) idToApproval; 
	mapping(address=>mapping(address=>bool)) ownerToOperators; 

	
    mapping(address => mapping(uint256 => uint256)) private OwnedTokens;
    mapping(uint256 => uint256) private OwnedTokensIndex;

	mapping(address => uint256) private NTFBalances;


	function supportsInterface(bytes4 interfaceId) public pure override  returns (bool) {
        return interfaceId == hex"01ffc9a7" || interfaceId == hex"80ac58cd" || interfaceId == hex"780e9d63" || interfaceId == hex"5b5e139f";  
    }
	
	
    function name() public pure  override returns (string memory) {
        return "Pixel Universe Sprite";
    }

	
    function symbol() public pure  override returns (string memory) {
        return "PUS";
    }

	//Decompression demo program https://github.com/pixeluniverselab/sprite_decompression
	function tokenURI(uint256 tokenId) public view  override  returns (string memory){
		
		string memory compressedImage = Base64.encode(getSpriteImage(tokenId));
		
		spriteAttribute memory spa = getSpriteAttribute(tokenId);
		spriteBody memory spb = getSpriteBody(tokenId);
		
		string memory spriteaAttar = string(abi.encodePacked('{"speed":',_toString(spa.speed),',"capacity":',_toString(spa.capacity),',"space":',_toString(spa.space),',"color_1":',_toString(spa.color_1),',"color_2":',_toString(spa.color_2),',"color_3":',_toString(spa.color_3),',"color_4":',_toString(spa.color_4),'}'));
		string memory spriteaBody = string(abi.encodePacked('{"trunkIndex":',_toString(spb.trunkIndex),',"headIndex":',_toString(spb.headIndex),',"eyeIndex":',_toString(spb.eyeIndex),',"mouthIndex":',_toString(spb.mouthIndex),',"tailIndex":',_toString(spb.tailIndex),',"colorContainerIndex":',_toString(spb.colorContainerIndex),',"skinColorIndex":',_toString(spb.skinColorIndex),'}'));

		string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Sprite #', _toString(tokenId), '","description": "Pixel sprite is a metaverse game. All information of the sprite, including image data, is completely stored on the chain. The picture is stored on the chain using a compression algorithm", "attribute": ',spriteaAttar,', "body": ',spriteaBody,', "image": "data:image/compressed_png;Base64,', compressedImage,'"}'))));
		
	
		return string(abi.encodePacked('data:application/json;base64,', json));
	}

	
    function totalSupply() public view  override returns (uint256) {
        return SpriteCount;
    }


	//tokenID start at 1
    function tokenByIndex(uint256 index) public pure  override returns (uint256) {
        return index+1;
    }


	function balanceOf(address _owner) external override view returns (uint256){
		require(_owner != address(0), ZERO_ADDRESS);
		return NTFBalances[_owner];
	}

	
	function ownerOf(uint256 _tokenId) external override view returns (address _owner){
		_owner = SpriteList[_tokenId].owner;
		require(_owner != address(0), ZERO_ADDRESS);
	}

	
    function tokenOfOwnerByIndex(address owner, uint256 index) public view  override returns (uint256) {
		require(NTFBalances[owner] > index, INDEX_BIG_THAN_BALANCE); //不曾拥有该TOken

		return OwnedTokens[owner][index];
    }

	
	function transferFrom(address _from, address _to, uint256 _tokenId) external override   {
		require(_from != _to, CANT_TRANSFER_TO_YOURSELF);  

		address tokenOwner = SpriteList[_tokenId].owner; 
		require(tokenOwner != address(0), NOT_VALID_NFT); 
       
        require(tokenOwner == _from, NOT_OWNER_OR_OPERATOR); 

		require(getSpriteStatus(_tokenId)==1,NTF_STATUS_CANT_TO_SEND); //Only when the sprite is idle can you transfer money

		
		require(tokenOwner == msg.sender || idToApproval[_tokenId] == msg.sender || ownerToOperators[tokenOwner][msg.sender],NOT_OWNER_APPROVED_OR_OPERATOR);
		
		require(_to != address(0), ZERO_ADDRESS);
		
		

		changeOwner(_tokenId,_to); 
		
		emit Transfer(_from, _to, _tokenId);
	}

	
	
	function approve(address _approved, uint256 _tokenId) external override  {
		address tokenOwner = SpriteList[_tokenId].owner;

		require(
			tokenOwner == msg.sender || ownerToOperators[tokenOwner][msg.sender],
			NOT_OWNER_OR_OPERATOR
		);

		require(tokenOwner != address(0), NOT_VALID_NFT);

		require(_approved != tokenOwner, IS_OWNER);

		idToApproval[_tokenId] = _approved;
		emit Approval(tokenOwner, _approved, _tokenId);
	}

	
	function setApprovalForAll(address _operator,bool _approved)external override{
		ownerToOperators[msg.sender][_operator] = _approved;
		emit ApprovalForAll(msg.sender, _operator, _approved);
  	}

	
	function getApproved(uint256 _tokenId) external override view returns (address){
		address tokenOwner = SpriteList[_tokenId].owner;
		require(tokenOwner != address(0), NOT_VALID_NFT);

    	return idToApproval[_tokenId];
  	}

	
	function isApprovedForAll(address _owner,address _operator) external override view returns (bool) {
    	return ownerToOperators[_owner][_operator];
  	}

	
	function _clearApproval(uint256 _tokenId) private{
    	delete idToApproval[_tokenId];
  	}

	
	function _toString(uint256 value) internal pure returns (string memory) {
    	
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

	function changeOwner(uint256 _spriteID,address _newOwner) internal {
		address oldOwner = SpriteList[_spriteID].owner;

		_removeTokenFromOwnerEnumeration(oldOwner,_spriteID);
		_addTokenToOwnerEnumeration(_newOwner,_spriteID);

		SpriteList[_spriteID].owner = _newOwner;

		NTFBalances[oldOwner] -= 1; 
		NTFBalances[_newOwner] += 1;

		_clearApproval(_spriteID);

	}

	
	function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
		

        uint256 length = NTFBalances[to];
        OwnedTokens[to][length] = tokenId;
        OwnedTokensIndex[tokenId] = length;
    }


	function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
		

        uint256 lastTokenIndex = NTFBalances[from] - 1;
        uint256 tokenIndex = OwnedTokensIndex[tokenId];

        
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = OwnedTokens[from][lastTokenIndex];

            OwnedTokens[from][tokenIndex] = lastTokenId; 
            OwnedTokensIndex[lastTokenId] = tokenIndex; 
        }

        delete OwnedTokensIndex[tokenId];
        delete OwnedTokens[from][lastTokenIndex];
    }

	function addHolderTokens(address _owner,uint256 index) internal {
		_addTokenToOwnerEnumeration(_owner,index);
		NTFBalances[_owner] += 1; 
	}


  
}


/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC165 {
    
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}


interface IERC721 is IERC165  {
   
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

   
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

   
    function balanceOf(address _owner) external view returns (uint256);

   
    function ownerOf(uint256 _tokenId) external view returns (address);

   
    function transferFrom(address _from, address _to, uint256 _tokenId) external;


    function approve(address _approved, uint256 _tokenId) external;


    function setApprovalForAll(address _operator, bool _approved) external;


    function getApproved(uint256 _tokenId) external view returns (address);


    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}


interface IERC721Metadata  is IERC721  {
    
    function name() external view returns (string memory _name);

    
    function symbol() external view returns (string memory _symbol);

    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

interface IERC721Enumerable is IERC721  {
    
    function totalSupply() external view returns (uint256);

    
    function tokenByIndex(uint256 _index) external view returns (uint256);

    
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "./components/spriteStruct.sol";
import "./components/ownable.sol";
import "./spriteImage.sol";


contract sprite is spriteImage,Ownable {
	string constant CONTRACT_ADDR_MUST_AUTHORIZED = "002001";
	string constant NEW_STATUS_CANT_SMALL_THAN_ONE = "002002";
	string constant NFT_HAS_NOT_CREAT = "002003";

	uint256 public OwnerEthBalance;		

	uint256 internal SpriteCount = 0;		//Number of sprites, starting from 1
	
	mapping(uint256=>spriteItem) public SpriteList; 			
	mapping(address=>bool) public ChangeStatusContract; 		
	
	event AddOffer(uint256 _spriteID,uint256 _auctionType,uint256 _startTime,uint256 _expirationTime,uint256 _price,uint256 _endPrice); 
	event BuySprite(uint256 indexed _spriteID,uint256  _price,address  indexed _buyer,address indexed _seller); 
	event CancelOffer(uint256 _spriteID); 

	
	function ownerWithdraw() external onlyOwner {
		payable(getManageOwner()).transfer(OwnerEthBalance);
		OwnerEthBalance = 0;
	}

	function setChangeStatusContract(address _addr , bool _isAuthorized) onlyOwner external{
		ChangeStatusContract[_addr] = _isAuthorized;
	}
    	
	
	function changeSpriteStatusExt(uint256 _spriteID,uint256 _newStatus,uint256 _expTime) external {
		require(ChangeStatusContract[msg.sender], CONTRACT_ADDR_MUST_AUTHORIZED);
		changeSpriteStatus(_spriteID,_newStatus,_expTime);
	}
	

	
	
	function changeSpriteStatus(uint256 _spriteID,uint256 _newStatus,uint256 _expTime) internal {
		require(_newStatus>=1,NEW_STATUS_CANT_SMALL_THAN_ONE);
		SpriteList[_spriteID].status = uint32(_newStatus);   
		SpriteList[_spriteID].statusExpTime = uint64(_expTime); 
	}

	
	function getSpriteAttribute(uint256 _spriteID)  public view returns(spriteAttribute memory){
	    return SpriteList[_spriteID].attribute;
	}

	
	function getSpriteBody(uint256 _spriteID)  public view returns(spriteBody memory){
	    return SpriteList[_spriteID].body;
	}

	
	function getSpriteStatusAndOwner(uint256 _spriteID)  external view returns(address,uint256){
	    return (SpriteList[_spriteID].owner,getSpriteStatus(_spriteID));
	}

	
	function getSpriteStatus(uint256 _spriteID) public view returns(uint256 status){
	    uint256	expTime = SpriteList[_spriteID].statusExpTime; //uint64 to uint256
		status = SpriteList[_spriteID].status; //uint32 to  uint256

	    if(status>=2 && expTime != 0 && (block.timestamp > expTime)  ){
	    	status = 1; //1 Means free
	    }
	}


	
	function getSpriteImage(uint256 _spriteID) public view returns(bytes memory) {
		address tokenOwner = SpriteList[_spriteID].owner; 
		require(tokenOwner != address(0), NFT_HAS_NOT_CREAT); 

        spriteBody memory sb = SpriteList[_spriteID].body;
        uint8[4] memory colorList = [SpriteList[_spriteID].attribute.color_1,SpriteList[_spriteID].attribute.color_2,SpriteList[_spriteID].attribute.color_3,SpriteList[_spriteID].attribute.color_4]; 
		return getImageCompressData(colorList,sb);
    }


	

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct spriteAttribute{
	uint8 speed;	 				
	uint8 capacity;  				
	uint8 space;	 				//Affect the size of the production canvas  10~60
	uint8 color_1;
	uint8 color_2;
	uint8 color_3;
	uint8 color_4;
}

struct spriteBody{
	uint8 trunkIndex;  				
	uint8 mouthIndex; 				
	uint8 headIndex;  				
	uint8 eyeIndex;   				
	uint8 tailIndex;  				
	uint8 colorContainerIndex;		
	uint8 skinColorIndex; 			
}

struct spriteItem {
	uint32	status;  				//Sprite state 0: not created, 1:idle,2:Fixed bid transaction,3:Dutch auction 4:production
	uint64 	statusExpTime; 			
	address owner;					
	uint256 addBlockNum;			
	
	spriteAttribute attribute; 		
	spriteBody  body;				
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Ownable  {
    string constant OWNABLE_CALL_IS_NOT_THE_OWNER = "001001";
    string constant OWNABLE_NEW_OWNER_IS_ZERO = "001002";

    address private Manageowner;

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor ()  {
        Manageowner = msg.sender;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function getManageOwner() public view  returns (address) {
        return Manageowner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(Manageowner == msg.sender, OWNABLE_CALL_IS_NOT_THE_OWNER);
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address _newOwner) public  onlyOwner {
        require(_newOwner != address(0), OWNABLE_NEW_OWNER_IS_ZERO);
        Manageowner = _newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./components/spriteStruct.sol";


contract spriteImage   {
    
    enum Part {Trunk,Mouth,Head,Eye,Tail,ColorContainer}

	bytes constant private PartFaceData =hex"822bd8d94a29030224555606942aaac1928555584a50aaab0c6e1555605555605555605555630940005400";
	
	
    mapping(Part=>mapping(uint=>bytes)) private PartData;
    mapping(uint256=>uint8[2]) private  SkinData;
	
	
    
	constructor(){
	    PartData[Part.Trunk][0] = hex"822bd8d95c6ba3012055581840aab05a01554a0451281144a1c122a8d10c9155689cc8d2840d00b000691000";
        PartData[Part.Trunk][1] = hex"852bbbd83533905c6ba301201249340c201249341680124922d008241168081210b43824124836886486db6e413990e46c08039000dc000034880000";
        PartData[Part.Trunk][2] = hex"852bc2d81d169e5c6ba301201249340c201249341680124922d008241168081210b43824124836886486db6e413990e46c08039000dc000034880000";
        PartData[Part.Trunk][3] = hex"852bc1d839329d5c6ba301201249340c201249341680124922d008241168081210b438241248b6886486db6e413990e46c08039000dc000034880000";
        PartData[Part.Trunk][4] = hex"852bc7d883589d5c6ba301201249340c201249341680124922d008241168081210b438241248b6886486db6e413990e46c08039000dc000034880000";
        PartData[Part.Trunk][5] = hex"852b65d8c79d5e5c6ba301201249340c201249341680124922d008241168081210b438241248b6886486db6e413990e46c08039000dc000034880000";
        PartData[Part.Trunk][6] = hex"852b5dd8cea3325c6ba301201249340c201249341680124922d008241168081210b438241248b6886486db6e413990e46c08039000dc000034880000";

        PartData[Part.Mouth][0] = hex"802b639ee11800";
        PartData[Part.Mouth][1] = hex"81972b5364e1001d17f8";
        PartData[Part.Mouth][2] = hex"822bbbb463a111820006630b631120";
        PartData[Part.Mouth][3] = hex"80966b9ae080";
        PartData[Part.Mouth][4] = hex"81d02b5b5ef2070140";
        PartData[Part.Mouth][5] = hex"802b6b9ce0a0";
        PartData[Part.Mouth][6] = hex"802b6362e1ad00";
        PartData[Part.Mouth][7] = hex"80b46b9cf11800";
        PartData[Part.Mouth][8] = hex"8156b4639ef10c2b80";
        PartData[Part.Mouth][9] = hex"81902b639ee11b00";
        PartData[Part.Mouth][10] = hex"812bac639ef1881e20";
        PartData[Part.Mouth][11] = hex"80965b62e180304400";
        PartData[Part.Mouth][12] = hex"842bd873c8d94b6712082db269250c824924936c80000248";
        PartData[Part.Mouth][13] = hex"842bd8c897d94b67120809932d98641249249b6400001240";
        PartData[Part.Mouth][14] = hex"81d7d96b9cf11980";
        PartData[Part.Mouth][15] = hex"81815653270211380a8c05e783c070";
        PartData[Part.Mouth][16] = hex"862bb4d4cdc778a253a95203100bc0000000434090982485b0024e001ca86ec114c4c28880";
        PartData[Part.Mouth][17] = hex"822b56814aef32868406e02000000416b46aa6510f1c4d4cc8226289694058082e18a506c18a3e0400";
        PartData[Part.Mouth][18] = hex"822b585f4aef32868406e02000000416b46aa6510f1c4d4cc8226289694058082e18a506c18a3e0400";
        PartData[Part.Mouth][19] = hex"822b97c24aef32868406e02000000416b46aa6510f1c4d4cc8226289694058082e18a506c18a3e0400";
        PartData[Part.Mouth][20] = hex"822ba2cd4aef32868406e02000000416b46aa6510f1c4d4cc8226289694058082e18a506c18a3e0400";
        PartData[Part.Mouth][21] = hex"822b5a604aef32868406e02000000416b46aa6510f1c4d4cc8226289694058082e18a506c18a3e0400";
        PartData[Part.Mouth][22] = hex"822b161d4aef32868406e02000000416b46aa6510f1c4d4cc8226289694058082e18a506c18a3e0400";
        PartData[Part.Mouth][23] = hex"83ac2bba562adef1800300b81a2b276035c0a8";
        PartData[Part.Mouth][24] = hex"82812b722a1d1180202900580800cdaabd6d309aac7cd2cd1ad5371aa8";
        PartData[Part.Mouth][25] = hex"832bcec7565baf42021014461725120c278155698910d5c5581f810d058a2400";
        PartData[Part.Mouth][26] = hex"832bbb90565baf42021014461725120c278155698910d5c5581f810d058a2400";
        PartData[Part.Mouth][27] = hex"842b9c72ac785bab228410164800000010d014ca910000000000";

        PartData[Part.Head][0] = hex"822bd8d949287203000001942aaac31620aab12813c0aab0";
        PartData[Part.Head][1] = hex"822bd8d948a8720100610862440001250aaab0c68055587f02aac0";
        PartData[Part.Head][2] = hex"822bd9d8386c7201200610041068374521522a51a8628343a429212051250a0a8e503195caaa00";
        PartData[Part.Head][3] = hex"822bd8d950287282002000c10848421620a87122a0c89d2320c8c92320c8f74320ca2c82aaaa00";
        PartData[Part.Head][4] = hex"822bd8d9482a8282002800e10858421a20a88922a0c8bd2320c8f22320aa02a93d42aaaa5d40aaa9a422";
        PartData[Part.Head][5] = hex"832bcea3d840ee930208016100444150d082a20185a45330d2835001548347fe54944212d8649880360200";
        PartData[Part.Head][6] = hex"842bd8d3c1d948687206004100401b609a682580024920c28124924c0f2c1009249824809700924980";
        PartData[Part.Head][7] = hex"832bd7ac8138ae83051800026601fff808ce155555619c232b34d540aaaaacb158e26a955a341800000000";
        PartData[Part.Head][8] = hex"832b1d6b3a386882871801338550204955522d514ad28ed454d4e47d01554b82aaaab98d80000000";
        PartData[Part.Head][9] = hex"842b9ed573d3382e8282200000000a2812492cb04aa0492596c1b28124b2cb08ea000000002c2824924a40cee000000000003bc0124924965b6c44b8000000000000";
        PartData[Part.Head][10] = hex"852b736cd3a87e40ac8281600000000001fd0492e424924024b8ed2524173024a5a92483d586db6db904b60249249490b6b000000000";
        PartData[Part.Head][11] = hex"832bd7bbac483482048807080c501402851a15552b871e155546f8934555542a99e2dd000000d020d982aaabe3f60abbbf9234000000";
        PartData[Part.Head][12] = hex"842bd711d8d948ea828428000040e1b6dc06d4000000004f90492492490124924924212800000000";
        PartData[Part.Head][13] = hex"852bd7d0bb97733870b3028e0000002c482498db04e582496dc741c1a1b8db6e46c249e1b6db71b6ca0b51825b6db65b25201475d765752483fa02db6db6db5da2743b68af0a81820800";
        PartData[Part.Head][14] = hex"816c90512ea2026003e1fc729ff2aa7fcdb4000a40c200";
        PartData[Part.Head][15] = hex"832b9056ba406c8202a0200008d010000828080005f4040003ea0200026d0100017295d555d3c000000000";
        PartData[Part.Head][16] = hex"842b56819ca4386c92032000015609224124049244833a0524912421d029248921474072491b6d860f05249249124871e000000000044700";
        PartData[Part.Head][17] = hex"832bccd7a2382a93028a0002638aae10922aab86050b52f87e50b32f89c58aaafe2dd600007f82aaaa7e000000012a00";
        PartData[Part.Head][18] = hex"824b2bcc403092043000030e000050c00018881cb0000842091000002cc00000d14b54aabcd2d52ab11c00000004cf00000000";
        PartData[Part.Head][19] = hex"842b81d856d949329204500000a384925023a000000002f1019f824924b6d864459000000028986c632000";
        PartData[Part.Head][20] = hex"84123d2bd8d950a87202100388030c1208982416b0492092414a48a56057aa4524e5d36db880";
        PartData[Part.Head][21] = hex"842bd711ac10406c828250000000008301249249641ee824924924b20124924b2cb0f580924965b626a824924a41714092492d8d6a0000000000";
        PartData[Part.Head][22] = hex"822bc7d640ec820460000940aaa886055545f4555543dc15555525f000000000";
        PartData[Part.Head][23] = hex"882b1868123d318e3743406c820540000026c0a686608600d05c4cc17d01a23a19a983ea043533453309980444cc45111016b804c4cd0ccd14cc356000000000000000";
        PartData[Part.Head][24] = hex"822bcca2402e920388050809880b30a2845628aca863a2acb2c881a2cacac8a1c2b2cab23078b2acb2a38f0a28b2b1040428844302b1346080";
        PartData[Part.Head][25] = hex"832bd5d3a938aaa201080410020420ab05403f820555416e8d3555c1e715555d7899a55d77f8b826bf200078e8270800";
        PartData[Part.Head][26] = hex"812b7950a883031003467c5c87f21adff3fe7fc000";
        PartData[Part.Head][27] = hex"822bba72287282832000001a50aaaa85ea1555510002228555545200a821165455554335c4140aaaa8051fe42aaaaaaaa4ac0000000000";
        PartData[Part.Head][28] = hex"822b5580406c828520004900aa82050d5528bd4355523e500000131835554a5ae8d5554a8000000000";
        PartData[Part.Head][29] = hex"822bc79d50a883811000000b822aaac0aaab02aaac0aaab02aaac0000000";
        PartData[Part.Head][30] = hex"832b3b6534406ed2830c0050e0d20469169543258acaaa20b4569557145a2d2aaf8c1f15a557fc000003fc8b21f93633cab19e5d88ccc000";
        PartData[Part.Head][31] = hex"822bc19650ae83012000001c50aaab070a1555615142aaac38a455558005555aa000000000";

        PartData[Part.Eye][0] = hex"802b62dec081ce00";
        PartData[Part.Eye][1] = hex"81d92b62e0c1021e50c0";
        PartData[Part.Eye][2] = hex"802b52e2b1085800";
        PartData[Part.Eye][3] = hex"802b631ec08600";
        PartData[Part.Eye][4] = hex"81d92b62dec081de80";
        PartData[Part.Eye][5] = hex"81562b5aa2c108101e0b83ccc8";
        PartData[Part.Eye][6] = hex"81562b62e2c102246880";
        PartData[Part.Eye][7] = hex"822bd9d65aa2c181024a0b4bad2d24b0";
        PartData[Part.Eye][8] = hex"802b5ae0c080a39400";
        PartData[Part.Eye][9] = hex"81562b5ae2c10412107080";
        PartData[Part.Eye][10] = hex"812bd662e0b08ae8";
        PartData[Part.Eye][11] = hex"802b629ec08071e580";
        PartData[Part.Eye][12] = hex"812bd962e0c1029ef0e0";
        PartData[Part.Eye][13] = hex"81d92b62a0c1021e51c6a0";
        PartData[Part.Eye][14] = hex"81562b5a9eb08438cca0";
        PartData[Part.Eye][15] = hex"812bd962a0c1029eb1beb8";
        PartData[Part.Eye][16] = hex"81d92b62a0c1021e31aea8";
        PartData[Part.Eye][17] = hex"812bd75260c2000620c414a500";
        PartData[Part.Eye][18] = hex"802b52a8c20420a2174001811b10";
        PartData[Part.Eye][19] = hex"812bac4268d281100e20348e26471a8a8a1cb48e6a20ec40";
        PartData[Part.Eye][20] = hex"812bd7526cc2014000cc0003564413d000cc00";
        PartData[Part.Eye][21] = hex"812b424aaac281000032636648080600";
        PartData[Part.Eye][22] = hex"822b5690422ac3012000001d30aaaa800d554800aaaa8e48000000";
        PartData[Part.Eye][23] = hex"812b814a6ac282700372ff06d8507000";
        PartData[Part.Eye][24] = hex"832b8257ac422ac30028000001d00beaf8012a4a80150c042a1c8403f080";
        PartData[Part.Eye][25] = hex"812bb24a68c20220c219ec60ce9b4a254200";
        PartData[Part.Eye][26] = hex"822bb43552a6c20200000568a0500064c000";
        PartData[Part.Eye][27] = hex"814fd75a9eb1021e30a0";
        PartData[Part.Eye][28] = hex"81822b5aa2b1820942b480";
        PartData[Part.Eye][29] = hex"802b5aa0c10107068800";
        PartData[Part.Eye][30] = hex"81812b629ec08071eda0";
        PartData[Part.Eye][31] = hex"802b5aa4b1022c2860";

        PartData[Part.Tail][0] = hex"812bd9b5f19100366800";
        PartData[Part.Tail][1] = hex"822bd9d8b53992062038049941da8440c10ea8d04a6000";
        PartData[Part.Tail][2] = hex"822bd7bab2bb610540663053283a82405a0d01d8440961482c8600";
        PartData[Part.Tail][3] = hex"822b3c68b43b7186802a0c88e15519c2aa45054ad01803407280";
        PartData[Part.Tail][4] = hex"822bd8d7b2f7820120032150310a02462860c50f98a263145a4233211c908fa05014906a938800";
        PartData[Part.Tail][5] = hex"812bd8b3796182404b622d8c363d1c95b2b8e631ce1e3f20";
        PartData[Part.Tail][6] = hex"812bd8b3bb7184405c712a119ce90e54a73e6508e29d02724200";
        PartData[Part.Tail][7] = hex"812bd8b33b81850189146c7524a92c6cd1276da136910d41f5853000";
        PartData[Part.Tail][8] = hex"812bd8b57591800a652cf7d480";
        PartData[Part.Tail][9] = hex"822bd8d9b47b8286200a213089895866a2a412942a918156038100";
        PartData[Part.Tail][10] = hex"822bd8d9b439818680261307d2585a0a8ec1623a4b15456316d1c200";
        PartData[Part.Tail][11] = hex"822bd8d9b4f5720840d8282c285040";
        PartData[Part.Tail][12] = hex"822b8910b3f9618680260d0842a1840400981590c400";
        PartData[Part.Tail][13] = hex"822bd8d9b5338204409c30b0d000";
        PartData[Part.Tail][14] = hex"822bcdd4ca7ba182006400b4c904c954c9a4c9f402502a02f03403903e043047404c405140558000";
        PartData[Part.Tail][15] = hex"822bccd7b1fb6183400a82a11c2aa19c35221c2ca2a832328323b4043404c05405b06306a072078200";

        PartData[Part.ColorContainer][0] = hex"842bdadbdcdd1d4db2842012e0000901201b02400000";
        PartData[Part.ColorContainer][1] = hex"842bdadbdcdd048fb28218000b0804800a8019003c0083e0924901249201b6db024924104a24904a180000";
        PartData[Part.ColorContainer][2] = hex"842bdcdddadb0c51b2031005180013100d003a011004a014a86db0c54492071e0924901249212542490a460000";
        PartData[Part.ColorContainer][3] = hex"842bdadbdcdd044fb2830802800680112800006400f0022004a00a40170030f82492404924806db6c092490512800000";
        PartData[Part.ColorContainer][4] = hex"842bdadbdcdd0d4fb28210040803d012090124900db6c3a412412884168000";
        PartData[Part.ColorContainer][5] = hex"842bdbdcdadd0d11b206201460b08a825b0c7824b6c04949052a1290646141d880";
        PartData[Part.ColorContainer][6] = hex"842bdbdcdadd0d4fb1050008412d60e81296d80de0250520910a760b2000";
        PartData[Part.ColorContainer][7] = hex"842bdcdddadb0351b282018a81900197900001c801d80210022002500270029802b802d9836db0c8612490364412492404924907f3000000";
        PartData[Part.ColorContainer][8] = hex"842bdadcdbdd04cfb181a000008e092db046825b06982c23202a6140c684a40e384949041a000000";
        PartData[Part.ColorContainer][9] = hex"842bdadcdbdd0d8db28230001ae096c025b0129004a40f8c0000";
        PartData[Part.ColorContainer][10] = hex"842bdbdcdadd0d4fb28420010405b075012db00912009290484094160800";

        SkinData[0] = [179,136];
        SkinData[1] = [215,172];
        SkinData[2] = [214,171];
        SkinData[3] = [210,168];
        SkinData[4] = [207,164];
        SkinData[5] = [204,162];
        SkinData[6] = [198,157];
        SkinData[7] = [172,129];
        SkinData[8] = [171,128];
        SkinData[9] = [177,134];
        SkinData[10] = [173,130];
        SkinData[11] = [137,94];
        SkinData[12] = [136,93];
        SkinData[13] = [209,166];
        SkinData[14] = [203,160];
        SkinData[15] = [196,153];
        SkinData[16] = [65,22];
        SkinData[17] = [135,92];
        SkinData[18] = [178,135];
        SkinData[19] = [208,165];

	}

	
	
	function getImageCompressData(uint8[4] memory _colorList, spriteBody memory _sp) view internal returns( bytes memory imageBytes) {
        uint8[2] memory skin;
        bytes[7] memory imageData;
       
        skin = SkinData[_sp.skinColorIndex];
        
        imageBytes = abi.encodePacked(_colorList[0],_colorList[1],_colorList[2],_colorList[3],skin[0],skin[1]);
        
		imageData[0] = PartFaceData;
        imageData[1] = PartData[Part.Trunk][_sp.trunkIndex];
		imageData[2] = PartData[Part.Mouth][_sp.mouthIndex];
        imageData[3] = PartData[Part.Head][_sp.headIndex];
		imageData[4] = PartData[Part.Eye][_sp.eyeIndex];
		imageData[5] = PartData[Part.Tail][_sp.tailIndex];
		imageData[6] = PartData[Part.ColorContainer][_sp.colorContainerIndex];
		
		for(uint i=0;i<7;i++){
		    uint32 imageLen = uint32(imageData[i].length);
		    imageBytes = abi.encodePacked(imageBytes,imageLen,imageData[i]);
		}
	}
}

