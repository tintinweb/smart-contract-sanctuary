/**
 *Submitted for verification at Etherscan.io on 2019-07-08
*/

pragma solidity >= 0.4.24;

//by AGAINST Network Team

interface erc20 {
    function name() external returns (string);
	function symbol() external returns (string);
	function decimals() external returns (uint8);
    function transfer(address receiver, uint amount) external;
	function transferFrom(address from, address to, uint value) external;
    function balanceOf(address tokenOwner) constant external returns (uint balance);
    function allowance(address _owner, address _spender) constant external returns (uint remaining); 
}

contract againstTokenRegister {
    string public name = "AGAINST TKDEX";
    string public symbol = "AGAINST";
    string public comment = "AGAINST Token Index & Full DEX 1.0";
    address internal owner;
    address internal creditContract;
    uint public indexCount = 0;
    uint public gatewayCount = 0;
	uint public registerFee = 0;
    uint public ratePlaces = 9;
    uint public openMarketFee = 0;
    uint public minQtdDiv = 5;
    uint internal minQtd = (10**18)/(10**minQtdDiv);
	
	event orderPlaced(address token, address tokenPair, address ownerId, uint orderId);
	event orderDone(address token, address tokenPair, uint orderId, uint doneId);
	event orderCanceled(address token, address tokenPair, uint orderId);
	event orderRemovedLowBalance(address token, address tokenPair, uint orderId);
  
    struct order {
      bool placed;
      address orderOwner;
      uint rate; // use decimal places def in ratePlaces
      uint amount;
      uint date;
      bool sell; 
    } 
   
    struct done {
	  uint orderId;
      address fillOwner;
      uint fillAmount;
      uint fillDate;   
    }
	
	struct market {  
      bool exists;
      address tokenPair;
      uint ordersCount;
      uint donesCount;
	  mapping(uint => order) orders; 
      mapping(uint => done) dones;
	}

    struct voted {
      bool like;
      bool dislike;
    }

    struct token {
      address tokenBase;
      string name;
      string symbol;
      uint decimals;
      uint likesCount;
      uint dislikesCount; 
      uint marketsCount;
      mapping(uint => address) marketIndex; 
      mapping(address => market) markets;
      mapping(address => voted) voteStatus;
    }

    struct gateway {
      bool exists;
      address gatewayContractAddr;
      uint gatewayMinCredits;
      string gatewayUrl;
      uint lastSeen;
    }
	
    mapping(uint => address) public index;
	mapping(address => token) public tokens;
    mapping(address => bool) public exists;	
    mapping(uint => address) gatewayIndex;
    mapping(address => gateway) gatewayContract;
    	
	constructor() public {
       owner = address(msg.sender); 
    }

    function getTokenByAddr(address _addr) public view returns (address _tokenBase, 
                                                                string _name, 
                                                                string _symbol, 
                                                                uint _decimals, 
                                                                uint _marketsCount) {

       return (tokens[_addr].tokenBase,
               tokens[_addr].name,
               tokens[_addr].symbol,
               tokens[_addr].decimals,
               tokens[_addr].marketsCount);
    }

    function getTokenByIndex(uint _index) public view returns (address _tokenBase, 
                                                               string _name, 
                                                               string _symbol, 
                                                               uint _decimals, 
                                                               uint _marketsCount) {
       return (tokens[index[_index]].tokenBase, 
               tokens[index[_index]].name,
               tokens[index[_index]].symbol,
               tokens[index[_index]].decimals,
               tokens[index[_index]].marketsCount);
    }

    function getLikesByAddr(address _addr) public view returns (uint _likesCount, uint _dislikesCount) {
       return (tokens[_addr].likesCount, tokens[_addr].dislikesCount);
    }

    function getLikesByIndex(uint _index) public view returns (uint _likesCount, uint _dislikesCount) {
       return (tokens[index[_index]].likesCount, tokens[index[_index]].dislikesCount);
    }

    function getPairByAddr(address _base, address _pairAddr) public view returns (uint _ordersCount, uint _donesCount) {
       return (tokens[_base].markets[_pairAddr].ordersCount,
               tokens[_base].markets[_pairAddr].donesCount);
    }

    function getPairByIndex(address _base, uint _pairIndex) public view returns (uint _ordersCount, uint _donesCount) {
       return (tokens[_base].markets[tokens[_base].marketIndex[_pairIndex]].ordersCount,
               tokens[_base].markets[tokens[_base].marketIndex[_pairIndex]].donesCount);
    }

    function getOrders(address _base, address _pair, uint orderIndex) public view returns (address _owner,
                                                                                           uint _rate,
                                                                                           uint _amount,
                                                                                           uint _date,
                                                                                           bool _sell) {
       return (tokens[_base].markets[_pair].orders[orderIndex].orderOwner,
               tokens[_base].markets[_pair].orders[orderIndex].rate,
               tokens[_base].markets[_pair].orders[orderIndex].amount,
               tokens[_base].markets[_pair].orders[orderIndex].date,
               tokens[_base].markets[_pair].orders[orderIndex].sell);
    }

    function getDones(address _base, address _pair, uint doneIndex) public view returns (uint _orderId,
                                                                                         address _fillOwner,
                                                                                         uint _fillAmount,
                                                                                         uint _fillDate) {
       return (tokens[_base].markets[_pair].dones[doneIndex].orderId,
               tokens[_base].markets[_pair].dones[doneIndex].fillOwner,
               tokens[_base].markets[_pair].dones[doneIndex].fillAmount,
               tokens[_base].markets[_pair].dones[doneIndex].fillDate);
    }

    function getGatewayByIndex(uint _index) public view returns (address _gatewayContractAddr,
                                                                 uint _gatewayMinCredits,
                                                                 string _gatewayUrl,
                                                                 uint _lastSeen) {
       return (gatewayContract[gatewayIndex[_index]].gatewayContractAddr,
               gatewayContract[gatewayIndex[_index]].gatewayMinCredits,
               gatewayContract[gatewayIndex[_index]].gatewayUrl,
               gatewayContract[gatewayIndex[_index]].lastSeen);
    }

    function getGatewayByOwner(address gatewayOwner) public view returns (address _gatewayContractAddr,
                                                                          uint _gatewayMinCredits,
                                                                          string _gatewayUrl,
                                                                          uint _lastSeen) {
       return (gatewayContract[gatewayOwner].gatewayContractAddr,
               gatewayContract[gatewayOwner].gatewayMinCredits,
               gatewayContract[gatewayOwner].gatewayUrl,
               gatewayContract[gatewayOwner].lastSeen);
    }		

	function changeOwner(address _newOwner) public {
	  if (msg.sender == owner) {
	    owner = _newOwner;
	  }
	}

    function addGateway(address _gatewayContractAddr, uint _gatewayMinCredits, string _gatewayUrl) public payable {
       require(_gatewayMinCredits >= 0, "Invalid gatewayMinCredits");
       require(!gatewayContract[msg.sender].exists,"Already listed gateway");
       gatewayCount = gatewayCount+1;
       gatewayIndex[gatewayCount] = msg.sender;
       gatewayContract[msg.sender].exists = true;
       gatewayContract[msg.sender].gatewayContractAddr = _gatewayContractAddr;
       gatewayContract[msg.sender].gatewayMinCredits = _gatewayMinCredits; 
       gatewayContract[msg.sender].gatewayUrl = _gatewayUrl;
       gatewayContract[msg.sender].lastSeen = now;
    }

    function gatewayUpdate(address _gatewayContractAddr, uint _gatewayMinCredits, string _gatewayUrl) public payable {
       require(gatewayContract[msg.sender].exists,"Gateway not listed");
       require(_gatewayMinCredits >= 0, "Invalid gatewayMinCredits");
       gatewayContract[msg.sender].gatewayContractAddr = _gatewayContractAddr;
       gatewayContract[msg.sender].gatewayMinCredits = _gatewayMinCredits; 
       gatewayContract[msg.sender].gatewayUrl = _gatewayUrl;
       gatewayContract[msg.sender].lastSeen = now;       
    }

    function gatewayLastSeen() public payable {
       require(gatewayContract[msg.sender].exists,"Gateway not listed");
       gatewayContract[msg.sender].lastSeen = now;  
    }
	
	function registerToken(address _token) public payable {
	   require((msg.sender == owner) || (msg.value >= registerFee), "Register Fee Very Low");
	   erc20 refToken = erc20(_token);
       if (!exists[_token]) {            
            indexCount = indexCount+1;
            index[indexCount] = _token; 
            tokens[_token].tokenBase = _token;  
            tokens[_token].name = refToken.name();		
            tokens[_token].symbol = refToken.symbol();
            tokens[_token].decimals = refToken.decimals();			
            tokens[_token].likesCount = 0;
            tokens[_token].dislikesCount = 0;
            tokens[_token].marketsCount = 0; 		
            exists[_token] = true;            
       }	             
	   if (address(this).balance > 0) {
		    require(owner.send(address(this).balance),"Send error");
	   }
	}

    function createMarket(address _token, address _tokenPair) public payable {
      require(msg.value >= openMarketFee, "Open Market Fee Very Low");
      require(exists[_token] && exists[_tokenPair],"token or tokenPair not listed");     
      require(!tokens[_token].markets[_tokenPair].exists,"Market already exists");
      require(tokens[_token].tokenBase != _tokenPair,"Not allowed token = tokenPair");
      tokens[_token].marketsCount = tokens[_token].marketsCount+1;
      tokens[_token].marketIndex[tokens[_token].marketsCount] = _tokenPair;
      tokens[_token].markets[_tokenPair].tokenPair = _tokenPair;
      tokens[_token].markets[_tokenPair].ordersCount = 0;
      tokens[_token].markets[_tokenPair].donesCount = 0;
    }

    function createOrder(address _token, address _tokenPair, uint _rate, uint _amount, bool _sell) public {  
       require(_token != _tokenPair,"Not allowed token = tokenPair");     
       require(exists[_token] && exists[_tokenPair],"Token or tokenPair not listed");
       require((_rate > 0) && (_rate <= (10**ratePlaces) && (_amount > 0) && (_amount <= 10**36)),"Invalid Values");
       tokens[_token].markets[_tokenPair].ordersCount = tokens[_token].markets[_tokenPair].ordersCount+1;
       tokens[_token].markets[_tokenPair].orders[tokens[_token].markets[_tokenPair].ordersCount].placed = true;
       tokens[_token].markets[_tokenPair].orders[tokens[_token].markets[_tokenPair].ordersCount].orderOwner = msg.sender; 
       tokens[_token].markets[_tokenPair].orders[tokens[_token].markets[_tokenPair].ordersCount].rate = _rate;
       tokens[_token].markets[_tokenPair].orders[tokens[_token].markets[_tokenPair].ordersCount].amount = _amount;
       tokens[_token].markets[_tokenPair].orders[tokens[_token].markets[_tokenPair].ordersCount].date = now;
       tokens[_token].markets[_tokenPair].orders[tokens[_token].markets[_tokenPair].ordersCount].sell = _sell;
	   emit orderPlaced(_token, _tokenPair, msg.sender, tokens[_token].markets[_tokenPair].ordersCount);
    }
	
	function tokenLike(address _token) public {	
        require(exists[_token], "Token not listed");    
        if (!tokens[_token].voteStatus[msg.sender].like) {
	      tokens[_token].likesCount = tokens[_token].likesCount+1;
          tokens[_token].voteStatus[msg.sender].like = true;
          if (tokens[_token].voteStatus[msg.sender].dislike) {
	          tokens[_token].dislikesCount = tokens[_token].dislikesCount-1;
              tokens[_token].voteStatus[msg.sender].dislike = false;
          }
        } else {
          tokens[_token].likesCount = tokens[_token].likesCount-1;
          tokens[_token].voteStatus[msg.sender].like = false;
        }	   
	}
	
	function tokenDislike(address _token) public {
        require(exists[_token],"Token not listed");
   	    if (!tokens[_token].voteStatus[msg.sender].dislike) {
	      tokens[_token].dislikesCount = tokens[_token].dislikesCount+1;
          tokens[_token].voteStatus[msg.sender].dislike = true;
          if (tokens[_token].voteStatus[msg.sender].like) {
            tokens[_token].likesCount = tokens[_token].likesCount-1;
            tokens[_token].voteStatus[msg.sender].like = false;
          }	   
        } else {
	      tokens[_token].dislikesCount = tokens[_token].dislikesCount-1;
          tokens[_token].voteStatus[msg.sender].dislike = false;
        }	   
	}		
	
	function changeRegisterFee(uint _registerFee) public {
	   require(msg.sender == owner);
	   registerFee = _registerFee;	  
	}	

	function changeMinQtdDiv(uint _minQtdDiv) public {
       require((_minQtdDiv >= 1) && (minQtdDiv <= 18) ,"minQtdDiv out ot range");
	   require(msg.sender == owner,"Access denied");
	   minQtdDiv = _minQtdDiv;
       minQtd = (10**18)/(10**minQtdDiv);
	}

	function changeOpenMarketFee(uint _openMarketFee) public {
	   require(msg.sender == owner,"Access denied");
	   openMarketFee = _openMarketFee;
	}

    function fillOrder(uint _orderID, address _token, address _tokenPair, uint _amountFill, address _gatewayOwner) public payable {
       require(erc20(gatewayContract[_gatewayOwner].gatewayContractAddr).balanceOf(msg.sender) >= gatewayContract[_gatewayOwner].gatewayMinCredits, "You dont have GATEWAY credits");
       require(tokens[_token].markets[_tokenPair].orders[_orderID].placed,"Order not placed"); 
       require((_amountFill > 0) && (_amountFill <= 10**36),"amountFill out of range");
       erc20 tokenMaker;
       erc20 tokenTaker;
       if (tokens[_token].markets[_tokenPair].orders[_orderID].sell) {
	     tokenMaker = erc20(tokens[_token].tokenBase);
         tokenTaker = erc20(tokens[_token].markets[_tokenPair].tokenPair);
       } else {
	     tokenMaker = erc20(tokens[_token].markets[_tokenPair].tokenPair);
         tokenTaker = erc20(tokens[_token].tokenBase);         
       }
       uint rate = tokens[_token].markets[_tokenPair].orders[_orderID].rate;	   
       require(tokenTaker.allowance(msg.sender, address(this)) >= _amountFill, "Verify taker approval");
	   require(tokenTaker.balanceOf(msg.sender) >= _amountFill, "Verify taker balance");	   
	   uint amount = (((_amountFill/(10**tokens[_tokenPair].decimals))*rate)/(10**ratePlaces))*(10**tokens[_token].decimals);
       require(tokenMaker.allowance(tokens[_token].markets[_tokenPair].orders[_orderID].orderOwner, address(this)) >= amount, "Verify maker approval");
	   require(tokenMaker.balanceOf(tokens[_token].markets[_tokenPair].orders[_orderID].orderOwner) >= amount, "Verify maker balance");	   
	   tokens[_token].markets[_tokenPair].orders[_orderID].amount=tokens[_token].markets[_tokenPair].orders[_orderID].amount-amount;	         
       tokenMaker.transferFrom(tokens[_token].markets[_tokenPair].orders[_orderID].orderOwner, msg.sender,amount);
       tokenTaker.transferFrom(msg.sender,tokens[_token].markets[_tokenPair].orders[_orderID].orderOwner,_amountFill);
       tokens[_token].markets[_tokenPair].donesCount = tokens[_token].markets[_tokenPair].donesCount+1;
	   tokens[_token].markets[_tokenPair].dones[tokens[_token].markets[_tokenPair].donesCount].orderId = _orderID;
       tokens[_token].markets[_tokenPair].dones[tokens[_token].markets[_tokenPair].donesCount].fillOwner = msg.sender;
       tokens[_token].markets[_tokenPair].dones[tokens[_token].markets[_tokenPair].donesCount].fillAmount = _amountFill;
       tokens[_token].markets[_tokenPair].dones[tokens[_token].markets[_tokenPair].donesCount].fillDate = now;
	   emit orderDone(_token, _tokenPair, _orderID, tokens[_token].markets[_tokenPair].donesCount);
       if (tokens[_token].markets[_tokenPair].orders[_orderID].amount < minQtd) {
          delete tokens[_token].markets[_tokenPair].orders[_orderID];
		  emit orderRemovedLowBalance(_token, _tokenPair, _orderID);
       }
    }

    function cancelOrder(uint _orderId, address _token, address _tokenPair) public payable {
       require(tokens[_token].markets[_tokenPair].orders[_orderId].orderOwner == msg.sender,"Access denied"); 
       delete tokens[_token].markets[_tokenPair].orders[_orderId];
	   emit orderCanceled(_token, _tokenPair, _orderId);
    }    

}