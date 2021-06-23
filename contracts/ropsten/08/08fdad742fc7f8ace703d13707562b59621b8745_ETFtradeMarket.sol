/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;


interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns(bool);
}

interface IERC20{
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint256);
    
    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
    
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

abstract contract IERC721 is IERC165 {
    
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    
    // Returns the number of NFTs in 'owner''s account.
    
    function balanceOf(address owner) public view virtual returns(uint256 balance);
    
    // Returns the owner of the NFT specified by 'tokenId'.
    
    function ownerOf(uint256 tokenId) public view virtual returns(address owner);
    
    // Transfers a specific NFT('tokenId') from one account ('from') to another ('to').
    
    function safeTransferFrom(address from,address to,uint256 tokenId) public virtual;
    
    function transferFrom(address from, address to, uint256 tokenId) public virtual;
    
    // Requirements
    // If the caller is not 'from',it must be approved to move this NFT by either {approve} or setApprovalForAll}.
    
    function approve(address to,uint256 tokenId) public virtual;
    function getApproved(uint256 tokenId) public view virtual returns(address operator);
    function setApprovalForAll(address operator,bool _approved) public virtual;
    function isApprovedForAll(address owner,address operator) public view virtual returns(bool);
    
}

abstract contract IERC1155 is IERC165 {
    
        event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);
        event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);
        event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
        event URI(string _value, uint256 indexed _id);
        
        
        function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external virtual;
        function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external virtual;
        function balanceOf(address _owner, uint256 _id) external view virtual returns (uint256);
        function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view virtual returns (uint256[] memory);
        function setApprovalForAll(address _operator, bool _approved) external virtual;
        function isApprovedForAll(address _owner, address _operator) external view virtual returns (bool);
}

contract TransferProxy  {

    function erc721safeTransferFrom(IERC721 token, address from, address to, uint256 tokenId) external  {
        token.safeTransferFrom(from, to, tokenId);
    }

    function erc1155safeTransferFrom(IERC1155 token, address from, address to, uint256 id, uint256 value, bytes calldata data) external  {
        token.safeTransferFrom(from, to, id, value, data);
    }
}

contract TransferProxyForDeprecated  {

    function erc721TransferFrom(IERC721 token, address from, address to, uint256 tokenId) external  {
        token.transferFrom(from, to, tokenId);
    }
}


contract ETFtradeMarket{
    
    using SafeMath for uint256;
    enum Type {
        TOKEN,
        ORACLE,
        NFT,
        INSURANCE
    }
    enum Side {
        BUY,
        SELL
    }
  
    //Token

    // NFT 

    // Oracle

    // Insurance

    struct ETF{
        bytes32 ticker;
        address etfAddress;
        Type typed;
        uint256 tokenId;
    }


    struct Order{
        uint256 id;
        address trader;
        Side side;
        bytes32 ticker;
        uint256 amount;
        uint256 filled;
        uint256 price;
        uint256 date;
    }
    
    

    
   TransferProxy public transferProxy;    
   mapping(bytes32 => ETF) public etfs;
   bytes32[] public etfList;
   mapping(address => mapping(bytes32 => uint256)) public traderBalances;
   mapping(bytes32 => mapping(uint256 => Order[])) public orderBook;
   address public admin;
   uint256 public nextOrderId;
   uint256 public nextTradeId;
   bytes32 constant PLE = bytes32('PLE');
   
   
    event NewTrade (

       uint256 tradeId,
       uint256 orderId,
       bytes32 indexed ticker,
       address indexed trader1,
       address indexed trader2,
       uint256 amount,
       uint256 price,
       uint256 date
   );
   
   modifier assetIsNotPle(bytes32 ticker) {
       require(ticker != PLE ,'cannot trade PLE');
       _;
   }

   modifier etfExist(bytes32 ticker){
       require(
           etfs[ticker].etfAddress != address(0),
           'this underlying asset does not exist'
       );
       _;
   }

   modifier onlyAdmin(){
       require(msg.sender == admin,'only admin');
       _;
   }

   constructor(TransferProxy _tranferProxy) public {
       admin = msg.sender;
       transferProxy = _tranferProxy;
   }
   
   
     // GET the underlying assets
   function getEFT() external view returns(ETF[] memory){
       ETF[] memory _etfs = new ETF[](etfList.length);
       for(uint256 i =0 ;i < etfList.length; i++){

           _etfs[i] = ETF(etfs[etfList[i]].ticker,etfs[etfList[i]].etfAddress,etfs[etfList[i]].typed,etfs[etfList[i]].tokenId);
       }
       return _etfs;
   }

   // Add the underlying assets 
    function addETF(bytes32 ticker,Type typed,address etfAddress,uint256 tokenId) onlyAdmin() external {
        etfs[ticker] = ETF(ticker,etfAddress,typed,tokenId);
        etfList.push(ticker);
    }
    
    
     // Deposit the underlying assets 

    function deposite(uint256 amount,bytes32 ticker,Type typed) etfExist(ticker) external {
       if(typed == Type.TOKEN){
           IERC20(etfs[ticker].etfAddress).transferFrom(
               msg.sender,
               address(this),
               amount
           );

           traderBalances[msg.sender][ticker] = traderBalances[msg.sender][ticker].add(amount);
       }
       else if(typed == Type.NFT){
           
           transferProxy.erc721safeTransferFrom(IERC721(etfs[ticker].etfAddress),msg.sender,address(this),etfs[ticker].tokenId);

       }
       else if(typed == Type.ORACLE){

       }
       else{

       }
    }
    
    
    function withdraw(uint256 amount,bytes32 ticker,Type typed) etfExist(ticker) external {
       
       require(traderBalances[msg.sender][ticker] >= amount,'balance too low');

        if(typed == Type.TOKEN){
          
         traderBalances[msg.sender][ticker] = traderBalances[msg.sender][ticker].sub(amount);
         IERC20(etfs[ticker].etfAddress).transfer(msg.sender,amount);
       }
       else if(typed == Type.NFT){
        transferProxy.erc721safeTransferFrom(IERC721(etfs[ticker].etfAddress),address(this),msg.sender,etfs[ticker].tokenId);
       }
       else if(typed == Type.ORACLE){

       }
       else{

       }

        
    }
    
    function createMarketOrder(
        bytes32 ticker,
        uint256 amount,
        Side side) 
        etfExist(ticker) 
        assetIsNotPle(ticker) external{
        
         if(side == Side.SELL) {
            require(
                traderBalances[msg.sender][ticker] >= amount, 
                'token balance too low'
            );
        }
        
        Order[] storage orders = orderBook[ticker][uint256(side == Side.BUY ? Side.SELL : Side.BUY)];
        uint256 i;
        uint256 remaining = amount;
        
          while(i < orders.length && remaining > 0) {
            uint256 available = orders[i].amount.sub(orders[i].filled);
            uint256 matched = (remaining > available) ? available : remaining;
            remaining = remaining.sub(matched);
            orders[i].filled = orders[i].filled.add(matched);
            emit NewTrade(
                nextTradeId,
                orders[i].id,
                ticker,
                orders[i].trader,
                msg.sender,
                matched,
                orders[i].price,
                now
            );
            if(side == Side.SELL) {
                traderBalances[msg.sender][ticker] = traderBalances[msg.sender][ticker].sub(matched);
                traderBalances[msg.sender][PLE] = traderBalances[msg.sender][PLE].add(matched.mul(orders[i].price));
                traderBalances[orders[i].trader][ticker] = traderBalances[orders[i].trader][ticker].add(matched);
                traderBalances[orders[i].trader][PLE] = traderBalances[orders[i].trader][PLE].sub(matched.mul(orders[i].price));
            }
            if(side == Side.BUY) {
                require(
                    traderBalances[msg.sender][PLE] >= matched.mul(orders[i].price),
                    'PLE balance too low'
                );
                traderBalances[msg.sender][ticker] = traderBalances[msg.sender][ticker].add(matched);
                traderBalances[msg.sender][PLE] = traderBalances[msg.sender][PLE].sub(matched.mul(orders[i].price));
                traderBalances[orders[i].trader][ticker] = traderBalances[orders[i].trader][ticker].sub(matched);
                traderBalances[orders[i].trader][PLE] = traderBalances[orders[i].trader][PLE].add(matched.mul(orders[i].price));
                
            }
            nextTradeId++;
            i++;
        }
        
        i = 0;
        while(i < orders.length && orders[i].filled == orders[i].amount) {
            for(uint256 j = i; j < orders.length - 1; j++ ) {
                orders[j] = orders[j + 1];
            }
            orders.pop();
            i++;
        }
        
        
        
    }
    
      function createLimitOrder(
        bytes32 ticker,
        uint amount,
        uint price,
        Side side)
        etfExist(ticker) 
        assetIsNotPle(ticker)
        external {
        if(side == Side.SELL) {
            require(
                traderBalances[msg.sender][ticker] >= amount, 
                'token balance too low'
            );
        } else {
            require(
                traderBalances[msg.sender][PLE] >= amount.mul(price),
                'ple balance too low'
            );
        }
        Order[] storage orders = orderBook[ticker][uint(side)];
        orders.push(Order(
            nextOrderId,
            msg.sender,
            side,
            ticker,
            amount,
            0,
            price,
            now 
        ));
        
        uint i = orders.length > 0 ? orders.length - 1 : 0;
        while(i > 0) {
            if(side == Side.BUY && orders[i - 1].price > orders[i].price) {
                break;   
            }
            if(side == Side.SELL && orders[i - 1].price < orders[i].price) {
                break;   
            }
            Order memory order = orders[i - 1];
            orders[i - 1] = orders[i];
            orders[i] = order;
            i--;
        }
        nextOrderId++;
    }
    
    
    
   
}