/**
 *Submitted for verification at Etherscan.io on 2021-10-23
*/

/**
 *Submitted for verification at Etherscan.io on 2021-10-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
  _____                  _        _____               _      
 / ____|                | |      |  __ \             | |     
| |     _ __ _   _ _ __ | |_ ___ | |__) |   _ _______| | ___ 
| |    | '__| | | | '_ \| __/ _ \|  ___/ | | |_  /_  / |/ _ \
| |____| |  | |_| | |_) | || (_) | |   | |_| |/ / / /| |  __/
 \_____|_|   \__, | .__/ \__\___/|_|    \__,_/___/___|_|\___|
              __/ | |                                        
             |___/|_|                    
             
by Macha and Wardesq
             
 */
 

/**
 * @dev String operations.
 */
library Strings {
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

interface IFundsDistributionTokenOptional {

	/** 
	 * @notice Deposits funds to this contract.
	 * The deposited funds may be distributed to other accounts.
	 */
	function depositFunds() external payable;

	/** 
	 * @notice Returns the total amount of funds that have been deposited to this contract but not yet distributed.
	 */
	function undistributedFunds() external view returns(uint256);

	/** 
	 * @notice Returns the total amount of funds that have been distributed.
	 */
	function distributedFunds() external view returns(uint256);

	/** 
	 * @notice Distributes undistributed funds to accounts.
	 */
	function distributeFunds() external;

	/** 
	 * @notice Deposits and distributes funds to accounts.
	 * @param from The source of the funds.
	 */
	function depositAndDistributeFunds(address from) external payable;

	/**
	 * @dev This event MUST emit when funds are deposited to this contract.
	 * @param by the address of the sender of who deposited funds.
	 * @param fundsDeposited The amount of distributed funds.
	 */
	event FundsDeposited(address indexed by, uint256 fundsDeposited);
}



library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
        return c;
    }
}

contract CryptoPuzzle {
    using Strings for uint256;
    using SafeMath for uint256;
    
address public owner;    

string public name;
string public symbol;
uint8 public decimals;
uint256 public TOTALSUPPLY;
//uint internal nexttokenIndexToAssign;
//bool internal alltokenAssigned = false;
uint public tokenAssign;
uint public


tokenLinearClaim;
uint public claimPrice;
uint internal randNonce; 
uint256 public OWNERCUTPERCENTAGE = 3;
uint256 public ownerCutTotalSupply;
uint256 public PRIZECUTPERCENTAGE = 3;
uint256 public prizeCutTotalSupply;
uint public forceBuyPrice;
uint public forceBuyInterval;
bool public publicSale = false;
uint public saleStartTime;
uint public saleDuration;
bool internal isLocked; //claim security : reentrancyGuard
bool public marketPaused;
bytes32 DOMAIN_SEPARATOR;
bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
    );
bytes32 constant TRADE_TYPEHASH = keccak256(
        "SignTrade(address maker,uint256 makerWei,uint256[] makerIds,address taker,uint256 takerWei,uint256[] takerIds,uint256 expiry)"
    );
    
    

mapping(uint => address) public tokenIndexToAddress; 
mapping(address => uint) public pendingWithdrawals;
mapping (bytes32 => bool) cancelledTrade;

struct SignTrade {
        address maker;
        uint256 makerWei;
        uint256[] makerIds;// Its for trade NFT to NFT without ether ? 
        address taker;
        uint256 takerWei;
        uint256[] takerIds;// Its for trade NFT to NFT without ether ? 
        uint256 expiry;
   }
   
       struct EIP712Domain {
        string name;
        uint256 chainId;
        address verifyingContract;
    }



    event Assign(address indexed to, uint256 tokenIndex);
    event SaleForced(uint indexed tokenIndex, uint value, address indexed from, address indexed to);
    event Transfer(address indexed from, address indexed to, uint256 tokenIndex, uint value);
    event Claim(address indexed to, uint256 tokenIndex, uint256 value, address indexed from);
    event Mint(address indexed to, uint256 tokenIndex, uint256 value, address indexed from);
    event Deposit(uint indexed tokenIndex, uint value, address indexed from, address indexed to);
    event Withdraw(uint indexed tokenIndex, uint value, address indexed from, address indexed to);
    event Trade(address indexed maker, uint makerWei, uint[] makerIds, address indexed taker, uint takerWei, uint[] takerIds,  uint expiry, bytes signature);
    event Store (uint8 NumberRobot, string indexed robotString);
    event TradeCancelled(address indexed maker, uint makerWei, uint[] makerIds, address indexed taker, uint takerWei, uint[] takerIds,  uint expiry);
  
   IFundsDistributionTokenOptional a_contract_instance;
    constructor (address _a_contract_address) {
        a_contract_instance = IFundsDistributionTokenOptional(_a_contract_address);
    	owner = msg.sender;
    TOTALSUPPLY = 5201;             // update total supply
    name = "CryptoPuzzle";          // set the name for display purposes
    symbol = unicode"🧩";                  // set the symbol for display purposes
    decimals = 0;                   // amount of decimals for display purposes
 DOMAIN_SEPARATOR = hash(EIP712Domain({
            name: "https://cryptopuzzle.com/",
            chainId: 1,
            verifyingContract: address(this)
        }));
        tokenIndexToAddress[0] = msg.sender;
    emit Claim(msg.sender, 0, 0, address(0x0));
   // tokenAssign++; // Not necesary for only 0's claim
    }

      ////////////////
     /// Security ///
    ////////////////
    
    //If size > 0 => contract
              function isContract(address addr) internal view returns (uint32 size){
  assembly {
    size := extcodesize(addr)
  }
  return size;
}
    
    modifier reentrancyGuard() { //claim security : reentrancyGuard
    require(!isLocked, "Locked");
    isLocked = true;
    _;
    isLocked = false;
}

function pauseMarket(bool _paused) external {
    require(msg.sender == owner);
        marketPaused = _paused;
    }
    
      //////////////////
     /// SSTORE NFT ///
    //////////////////
    
    string public baseTokenURI;
    event BaseURIChanged(string baseURI);
    
     function _baseURI() internal view returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public {
        require (msg.sender == owner);
        baseTokenURI = baseURI;
        emit BaseURIChanged(baseURI);
    }
    
function tokenURI(uint256 tokenId) public view returns (string memory) {
   // require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    string memory baseURI = _baseURI();
    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
}


    ////////////////
   /// ERC 2222 ///
  ////////////////
    
    function stack() public payable reentrancyGuard {
    uint amount = ownerCutTotalSupply;
    ownerCutTotalSupply = 0;
    a_contract_instance.depositFunds{value:amount}();
}
     
    ////////////
   /// Bank ///
  ////////////  
    
    function deposit() public payable {
	require (msg.value > 0);
	pendingWithdrawals[msg.sender] += msg.value;
	emit Deposit (0, msg.value, msg.sender, address(0x0));
	}

    function withdraw() public reentrancyGuard {
        require (pendingWithdrawals[msg.sender] > 0);
        uint amount = pendingWithdrawals[msg.sender];
        pendingWithdrawals[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
        emit Withdraw(0, amount, msg.sender, address(0x0));
       }
   
    ///////////////////////////
   /// CPZ gameDesignRules ///
  //////////////////////////
    
    function startSale(uint _price, uint _forceBuyPrice, uint _forceBuyInterval, uint _saleDuration) external {
        require(!publicSale);
        require(msg.sender == owner);
        claimPrice = _price;
        forceBuyPrice = _forceBuyPrice;
        forceBuyInterval = _forceBuyInterval;
        saleDuration = _saleDuration;
        saleStartTime = block.timestamp;
        publicSale = true;
    }
    
    function getClaimPrice() public view returns (uint) {
        require(publicSale, "Sale not started.");
        uint elapsed = block.timestamp.sub(saleStartTime);
        if (elapsed >= saleDuration) {
            return 0;
        } else { if (msg.sender == owner) {
            return 0 wei;
        } else {
            //return saleDuration.sub(elapsed).mul(price).div(saleDuration);
            return claimPrice;
        }
    }}


       function claimtoken() public reentrancyGuard payable returns(uint){
           require(publicSale, "Sale not started.");
           require(!marketPaused, "The market is on pause"); 
           require (tokenAssign < 5000);  //gameDesignRules
           uint salePrice = getClaimPrice();
      require (msg.value >= salePrice); //gameDesignRules
      
     if (msg.value > salePrice) {
            pendingWithdrawals[msg.sender] = pendingWithdrawals[msg.sender].add(msg.value.sub(salePrice));
        }
       uint tokenIndex = 5001;
       randNonce++;  
       uint tokenClaimId = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))) % tokenIndex;
ownerCutTotalSupply = ownerCutTotalSupply.add(msg.value.div(10));
prizeCutTotalSupply = prizeCutTotalSupply.add(msg.value.div(10).mul(9));
               if (tokenAssign < 4200) 
               {
                tokenClaimId = claimRandom(tokenClaimId);
            if (tokenIndexToAddress[tokenClaimId] == address(0x0)) 
            {
                tokenIndexToAddress[tokenClaimId] = msg.sender;
                tokenAssign++;
                emit Claim(msg.sender, tokenClaimId, msg.value, address(0x0));
                return tokenClaimId;
            } 
            else {revert("No puzzle available for your 150 loops. Try again !");}
        } 
        else {
                tokenLinearClaim = claimLinear(tokenLinearClaim);
            if (tokenIndexToAddress[tokenLinearClaim] == address(0x0)) {
                tokenIndexToAddress[tokenLinearClaim] = msg.sender;
                tokenAssign++;
                emit Claim(msg.sender, tokenLinearClaim, msg.value, address(0x0));
                return tokenLinearClaim;
                } else {
                    return tokenLinearClaim;
                    //revert("No puzzle available for your 150 loops. Try again !");
                    }
        }
            }
  
   function claimRandom(uint tokenClaimId) internal view returns (uint x) {
          uint countview = 0;
                 do {
                tokenClaimId++; 
                tokenClaimId %= 5001;
                countview++;
            } while (tokenIndexToAddress[tokenClaimId] != address(0x0) && countview < 150);
          x = tokenClaimId;
          return x;
}

function claimLinear(uint tokenLinearClaimF) internal view returns (uint x) {
          uint countview = 0;
           do {
                tokenLinearClaimF ++; 
                tokenLinearClaimF %= 5001;
                countview++;
            } while (tokenIndexToAddress[tokenLinearClaimF] != address(0x0) && countview < 150);
      x = tokenLinearClaimF;
          return x;
}   
    
    function transferToken(address to, uint tokenIndex) public {
        require (to != address(0x0));
        require (tokenIndex <= TOTALSUPPLY); //gameDesignRules
        require(tokenIndexToAddress[tokenIndex.add(24).div(25).add(5000)] == address(0x0), "Already Mint");//gameDesignRules
        require (tokenIndexToAddress[tokenIndex] == msg.sender); //gameDesignRules
        if (isContract(to) > 0 && tokenIndex <= 5000) {
            if (tokenIndex != 0) {
        revert ("Cannot transfer pieces to a contract");           
        }}
        tokenIndexToAddress[tokenIndex] = to;
        emit Transfer(msg.sender, to , tokenIndex, 0);
    }

	function forceBuy(uint tokenIndex) payable public {
	require (tokenAssign >= 5000, "Not all claims are made!");
	require (tokenIndex <= 5000); //gameDesignRules
	require (msg.value == (forceBuyPrice)); //gameDesignRules
	require (tokenIndexToAddress[tokenIndex] != address(0x0)); //gameDesignRules
	require (tokenIndexToAddress[tokenIndex] != msg.sender); //gameDesignRules
	require (tokenIndexToAddress[tokenIndex.add(24).div(25).add(5000)] == address(0x0), "Already Mint");//gameDesignRules
	require (tokenIndex != 0);
	address forceSeller = tokenIndexToAddress[tokenIndex];
	pendingWithdrawals[forceSeller] = pendingWithdrawals[forceSeller].add(msg.value.sub(msg.value.mul(6).div(100)));
	ownerCutTotalSupply = ownerCutTotalSupply.add(msg.value.mul(OWNERCUTPERCENTAGE).div(100));
	prizeCutTotalSupply = prizeCutTotalSupply.add(msg.value.mul(PRIZECUTPERCENTAGE).div(100));
	tokenIndexToAddress[tokenIndex] = msg.sender;
	emit SaleForced(tokenIndex, msg.value, forceSeller, msg.sender);
	}
    
    
    function mintCPZ (uint familyId) public reentrancyGuard {
            require (tokenAssign >= 5000, "Not all claims are made!");
            require (tokenIndexToAddress[familyId.add(5000)] == address(0x0));//gameDesignRules
            uint proof = 0;
            for (uint i = 0; i < 25; i++) {
                if (tokenIndexToAddress[familyId * 25 - uint(i)] == msg.sender) {proof++;} 
            } 
                if (proof == 25) {
                forceBuyPrice += forceBuyInterval;
           tokenIndexToAddress[familyId.add(5000)] = msg.sender;
        pendingWithdrawals[msg.sender] = pendingWithdrawals[msg.sender].add(prizeCutTotalSupply.div(20));
        emit Mint(msg.sender, familyId.add(5000), prizeCutTotalSupply.div(20), address(0x0));
        prizeCutTotalSupply = prizeCutTotalSupply.sub(prizeCutTotalSupply.div(20));
            } else {revert("You don't have all this familyId's puzzles");
            }}
    


    
    
     ///////////////////////////
    /// Market with EIP 712 ///
   ///////////////////////////
    
        function hash(EIP712Domain memory eip712Domain) private pure returns (bytes32) {
        return keccak256(abi.encode(
            EIP712DOMAIN_TYPEHASH,
            keccak256(bytes(eip712Domain.name)),
            eip712Domain.chainId,
            eip712Domain.verifyingContract
        ));
    }
 
         function hash(SignTrade memory trade) private pure returns (bytes32) {
        return keccak256(abi.encode(
            TRADE_TYPEHASH,
            trade.maker,
            trade.makerWei,
            keccak256(abi.encodePacked(trade.makerIds)),
            trade.taker,
            trade.takerWei,
            keccak256(abi.encodePacked(trade.takerIds)),
            trade.expiry
        ));
    }
    
      function verify(address signer, SignTrade memory trade, bytes memory signature) internal view returns (bool) {
        // Note: we need to use `encodePacked` here instead of `encode`.
        require(signer != address(0));
        require(signature.length == 65);
        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            hash(trade)
        ));
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
        if (v < 27) {
            v += 27;
        }
        require(v == 27 || v == 28);
        return ecrecover(digest, v, r, s) == trade.maker;
    }

    function tradeValid(address maker, uint256 makerWei, uint256[] memory makerIds, address taker, uint256 takerWei, uint256[] memory takerIds, uint256 expiry, bytes memory signature) 
    view public returns (bool) {
        SignTrade memory trade = SignTrade(maker, makerWei, makerIds, taker, takerWei, takerIds, expiry);
        // Check for cancellation
        bytes32 hashCancel = keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            hash(trade)
        ));
        require(cancelledTrade[hashCancel] == false, "Trade offer was cancelled.");
        // Verify signature
        require(verify(trade.maker, trade, signature), "Signature not valid.");
        // Check for expiry
        require(block.timestamp < trade.expiry, "Trade offer expired.");
        // Only one side should ever have to pay, not both
        require(makerWei == 0 || takerWei == 0, "Only one side of trade must pay.");
        // At least one side should offer tokens
        require(makerIds.length > 0 || takerIds.length > 0, "One side must offer tokens.");
        // Make sure the maker has funded the trade
        require(pendingWithdrawals[trade.maker] >= trade.makerWei, "Maker does not have sufficient balance.");
        // Ensure the maker owns the maker tokens
        for (uint i = 0; i < trade.makerIds.length; i++) {
            require(tokenIndexToAddress[trade.makerIds[i]] == trade.maker, "At least one maker token doesn't belong to maker.");
        if (trade.makerIds[i] != 0) {require(tokenIndexToAddress[trade.makerIds[i].add(24).div(25).add(5000)] == address(0x0), "Already Mint");
        }
        }
        // If the taker can be anybody, then there can be no taker tokens
        if (trade.taker == address(0)) {
            //// If taker not specified, then can't specify IDs
            //require(trade.takerIds.length == 0, "If trade is offered to anybody, cannot specify tokens from taker.");
            for (uint i = 0; i < trade.takerIds.length; i++) {
                require(tokenIndexToAddress[trade.takerIds[i]] == msg.sender, "At least one taker token doesn't belong to taker.");
                if (trade.takerIds[i] != 0) {require(tokenIndexToAddress[trade.takerIds[i].add(24).div(25).add(5000)] == address(0x0), "Already Mint");
            }
            }
        } else {
            // Ensure the taker owns the taker tokens
            for (uint i = 0; i < trade.takerIds.length; i++) {
                require(tokenIndexToAddress[trade.takerIds[i]] == trade.taker, "At least one taker token doesn't belong to taker.");
            if (trade.takerIds[i] != 0) {require(tokenIndexToAddress[trade.takerIds[i].add(24).div(25).add(5000)] == address(0x0), "Already Mint");
            }
            }
        }
        return true;
    }

    function cancelTrade(address maker, uint256 makerWei, uint256[] memory makerIds, address taker, uint256 takerWei, uint256[] memory takerIds, uint256 expiry) external {
        require(maker == msg.sender, "Only the maker can cancel this offer.");
        SignTrade memory trade = SignTrade(maker, makerWei, makerIds, taker, takerWei, takerIds, expiry);
        bytes32 hashCancel = keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            hash(trade)
        ));
        cancelledTrade[hashCancel] = true;
        emit TradeCancelled(trade.maker, trade.makerWei, trade.makerIds, trade.taker, trade.takerWei, trade.takerIds, expiry);
    }

    function acceptTrade(address maker, uint256 makerWei, uint256[] memory makerIds, address taker, uint256 takerWei, uint256[] memory takerIds, uint256 expiry, bytes memory signature) external payable reentrancyGuard {
        require(msg.sender != maker, "Can't accept ones own trade.");
        SignTrade memory trade = SignTrade(maker, makerWei, makerIds, taker, takerWei, takerIds, expiry);
        if (msg.value > 0) {
            pendingWithdrawals[msg.sender] = pendingWithdrawals[msg.sender].add(msg.value);
         //  emit Deposit(msg.sender, msg.value);
        }
        require(trade.taker == address(0) || trade.taker == msg.sender, "Not the recipient of this offer.");
        require(tradeValid(maker, makerWei, makerIds, taker, takerWei, takerIds, expiry, signature), "Trade not valid.");
        require(pendingWithdrawals[msg.sender] >= trade.takerWei, "Insufficient funds to execute trade.");
        // Transfer ETH & Tax
            address weiEmitter;
            address weiReceiver;
            uint amountTrade;
            uint taxNumber;
        if (trade.makerWei > 0) {
             weiEmitter = trade.maker;
             weiReceiver = msg.sender;
             amountTrade = trade.makerWei;
        } else {
             weiEmitter = msg.sender;
             weiReceiver = trade.maker;
             amountTrade = trade.takerWei;
        }
        for (uint i = 0; i < takerIds.length; i++) {
            if (trade.takerIds[i] == 0 || trade.takerIds[i] >= 5001) {
                 taxNumber = 1;
            } else {
                 taxNumber = 2;
            }
        }
        for (uint i = 0; i < makerIds.length; i++) {
            if (trade.makerIds[i] == 0 || trade.makerIds[i] >= 5001) {
                 taxNumber = 1;
                                                                      } else  {
                 taxNumber = 2;
                                                                              }
                                                    }
        pendingWithdrawals[weiEmitter] = pendingWithdrawals[weiEmitter].sub(amountTrade);
        pendingWithdrawals[weiReceiver] = pendingWithdrawals[weiReceiver].add(amountTrade.sub(amountTrade.mul(3).mul(taxNumber).div(100)));
        ownerCutTotalSupply = ownerCutTotalSupply.add(amountTrade.mul(OWNERCUTPERCENTAGE).div(100));
        prizeCutTotalSupply = prizeCutTotalSupply.add(amountTrade.mul(PRIZECUTPERCENTAGE).mul(taxNumber.sub(1)).div(100));
        // Transfer maker ids to taker (msg.sender)
        for (uint i = 0; i < makerIds.length; i++) {
            tokenIndexToAddress[trade.makerIds[i]] = msg.sender;
            //transfertoken(msg.sender, makerIds[i]);
        }
        // Transfer taker ids to maker
        for (uint i = 0; i < takerIds.length; i++) {
            tokenIndexToAddress[trade.takerIds[i]] = maker;
            //transfertoken(maker, takerIds[i]);
        }
        // Prevent a replay attack on this offer
        bytes32 hashCancel = keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            hash(trade)
        ));
        cancelledTrade[hashCancel] = true;
    emit Trade(trade.maker, trade.makerWei, trade.makerIds, msg.sender, trade.takerWei, trade.takerIds, expiry, signature);
    }
        }