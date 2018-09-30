pragma solidity ^0.4.24;

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}
contract Ownable {
  address private _owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    _owner = msg.sender;
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(_owner);
    _owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}
contract ERC20Token {
    uint256 public totalSupply;
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract TikMatch is Ownable {
    using SafeMath for uint;

    address KYCContractAddress;
    uint public OrderbookLength;
    uint public constant decimals = 18;
    uint public constant decimalbaseRate = 1000;
    uint public constant deno = 100000;

    mapping(uint => Order) public Orderbook;
    mapping(address => uint[]) public SellerOrderBook;
    mapping(bytes8 => address) public TokenContract;
    mapping(bytes8 => mapping(uint=>uint)) public TokenFee;
    mapping (address => bool) public admins;
    mapping(bytes8 => uint) public FeeBalance;

     struct Fee {
        uint FeeType; //1=Sales, 2=Buy, 3=CancelSale , 4 =ExpiredSale
        uint Amount;
     }

    struct Order {
        bytes8 TokenSale;
        bytes8 TokenAsking;
        uint Amount;
        uint SaleRate;
        uint CreatedDateTime;
        uint ExpDateTime;
        uint Status;
        address Seller;
    }

    event SaleCreated(
        uint indexed OrderBookIndex,
        bytes8 indexed TokenSale,
        bytes8 indexed TokenAsking,
        address Seller
    );

    event SaleCancelled(
        uint indexed OrderBookIndex,
        bytes8 indexed TokenSale,
        bytes8 indexed TokenAsking,
        address Seller
    );
    
    // event SalesDelisted(uint[] OrderBookIndexes);

    event SaleDelisted(
        uint indexed OrderBookIndex,
        bytes8 indexed TokenSale,
        bytes8 indexed TokenAsking
    );

     event SaleDepositWithdrawn(
        uint indexed OrderBookIndex,
        bytes8 indexed TokenSale,
        bytes8 indexed TokenAsking
    );

    function placeSaleOrder(
        bytes8 TokenSale,
        bytes8 TokenAsking,
        uint Amount,
        uint SaleRate,
        uint ExpiryMinute) external returns(bool success) {
        
        if(!withdrawToken(TokenSale,msg.sender, Amount))
        {
          revert();
        }
        uint fee =getFee(TokenSale,1);
        uint index = getOrderbookLength();
        Orderbook[index].TokenSale = TokenSale;
        Orderbook[index].TokenAsking =TokenAsking;
        Orderbook[index].Amount = Amount-fee;
        Orderbook[index].SaleRate = SaleRate;
        Orderbook[index].CreatedDateTime = now;
        Orderbook[index].ExpDateTime =  Orderbook[index].CreatedDateTime + ExpiryMinute * 1 minutes;
        Orderbook[index].Status =1;
        Orderbook[index].Seller = msg.sender;

        SellerOrderBook[msg.sender].push(index);
        FeeBalance[TokenSale] += fee;

        emit SaleCreated(index,Orderbook[index].TokenSale,Orderbook[index].TokenAsking, Orderbook[index].Seller);
          
        return true;

    }

    function cancelSaleOrder (
        uint index
       ) external returns(bool success) {
        
        Order storage order =  Orderbook[index];
        uint fee =getFee(order.TokenSale,3);
        
        SellerOrderBook[msg.sender].push(index);
        FeeBalance[order.TokenSale] += fee;
        
        require(msg.sender == order.Seller);

        if(!transferToken(order.TokenSale, order.Seller, order.Amount-fee))
        {
          revert();
        }

        order.Status = 3;
        emit SaleCancelled(index,Orderbook[index].TokenSale,Orderbook[index].TokenAsking, Orderbook[index].Seller);
          
        return true;
    }


    function placeBuyOrder(uint index, uint amountBuying) external returns(bool success) 
    {
        //if(balanceOf(order.TokenAsking, msg.sender) < amountBuying) revert(); // Insufficient Buyer Balalance

        require(balanceOf(order.TokenAsking, msg.sender) > amountBuying);

        uint amountPay = 0;

        Order storage order =  Orderbook[index];

        if(Orderbook[index].Status == 2) revert();

        amountPay = order.Amount.mul(order.SaleRate.mul(deno).div(decimalbaseRate)).div(deno);
        uint fee =getFee(order.TokenSale,2);
       
        withdrawToken(order.TokenAsking,msg.sender, amountPay); // Transfer Token To Escrow

        transferToken(order.TokenSale, msg.sender, amountBuying-fee); // Transfer Token To Buyer

        FeeBalance[order.TokenSale] += fee;

        transferToken(order.TokenAsking, order.Seller,amountPay); //Transfer Token To Seller

        Orderbook[index].Status = 2;  //Complete

        emit SaleDelisted(index, order.TokenSale, order.TokenAsking);
        
        return true;
    }

    function placeBuyOrders(uint[] index, uint[] amountBuying) external returns(bool success) 
    {
        uint amountTotalPay = 0;
        uint amountTotalBuying=0;
        uint amountBuy =0;
        uint[] memory amountPay= new uint[](index.length);
        uint firstIndex = index[0];
        bytes8  TokenAsking = Orderbook[firstIndex].TokenAsking;
        bytes8  TokenSale = Orderbook[firstIndex].TokenSale;
     
        
        for (uint i = 0; i < index.length; i++) {
             uint keyIndex = index[i];
             if(Orderbook[keyIndex].Status > 1) 
             {
                 revert();
             }else
             {
                  amountBuy =amountBuying[i];
                  amountPay[i] = amountBuy.mul(Orderbook[keyIndex].SaleRate.mul(deno).div(decimalbaseRate)).div(deno);
                  amountTotalPay +=amountPay[i];
                  amountTotalBuying +=amountBuy;
             }
        }
        
      
        amountTotalPay = amountTotalPay+ getFee(TokenAsking,2);
        FeeBalance[TokenAsking]+= getFee(TokenAsking,2);
        //if(balanceOf(TokenAsking, msg.sender) < amountTotalPay) revert(); // Insufficient Buyer Balalance

        withdrawToken(TokenAsking, msg.sender, amountTotalPay); // Transfer Token To Escrow
       
        for (uint j = 0; j < index.length; j++) 
        {    
             uint keyIndexS = index[j];
             
             transferToken(
             TokenAsking, 
             Orderbook[keyIndexS].Seller, 
             amountPay[j]); //Transfer Token To Seller
             
             Orderbook[keyIndexS].Amount -= amountBuying[j];
             
             if(Orderbook[keyIndexS].Amount <= 0)
             {
                //Complete withdrawal
                 Orderbook[keyIndexS].Status = 2;  
                 SaleDelisted(keyIndexS,Orderbook[keyIndexS].TokenSale,Orderbook[keyIndexS].TokenAsking);
             }
             else
             {   //Partial withdrawal
                 SaleDepositWithdrawn(keyIndexS,Orderbook[keyIndexS].TokenSale,Orderbook[keyIndexS].TokenAsking);
             }

        }

        transferToken(TokenSale, msg.sender, amountTotalBuying); // Transfer Token To Buyer    
        return true;

    }

    function getTotalReqAmt(uint[] index, uint[] amountBuying) public constant returns (uint balance) {  
        uint amountTotalPay = 0;
        uint amountTotalBuying=0;
        uint amountBuy =0;
        uint[] memory amountPay= new uint[](index.length);
        uint firstIndex = index[0];

        bytes8  TokenAsking = Orderbook[firstIndex].TokenAsking;
        bytes8  TokenSale = Orderbook[firstIndex].TokenSale;
        uint fee =getFee(TokenAsking,2);
        
        for (uint i = 0; i < index.length; i++) {
             uint keyIndex = index[i];
             if(Orderbook[keyIndex].Status == 2) 
             {
                 return 0;
             }
             else
             {
                  amountBuy =amountBuying[i];
                  amountPay[i] = amountBuy.mul(Orderbook[keyIndex].SaleRate.mul(deno).div(decimalbaseRate)).div(deno);
                  amountTotalPay +=amountPay[i];
                  amountTotalBuying +=amountBuy;
             }
        }
        return amountTotalPay+fee;
    }


    function transferToken(bytes8 token, address to, uint256 amount)private returns (bool success) 
    {
         ERC20Token m = ERC20Token(TokenContract[token]);
         m.transfer(to,amount);
         return true;
    }

    function withdrawToken(bytes8 token, address from, uint256 amount)private returns (bool success) 
    {
         ERC20Token m = ERC20Token(TokenContract[token]);
         m.transferFrom(from,address(this),amount);
         return true;
    }

    function refundToken(bytes8 token, address to, uint256 amount)private returns (bool success) 
    {
         ERC20Token m = ERC20Token(TokenContract[token]);
         m.transferFrom(address(this),to,amount);
         return true;
    }

    function balanceOf(bytes8 token,address owner) public constant returns (uint256 balance) {
          ERC20Token m = ERC20Token(TokenContract[token]);
          return m.balanceOf(owner);
    }

     function getSaleOrdersBySeller(address Seller) public constant returns(
        bytes8[],
        bytes8[],
        uint[],
        uint[],
        uint[]
        ) {

        uint len= SellerOrderBook[Seller].length;
        bytes8[] memory TokenSale= new bytes8[](len);
        bytes8[] memory TokenAsking= new bytes8[](len);
        uint[] memory Amount= new uint[](len);
        uint[] memory SaleRate= new uint[](len);
        uint[] memory ExpDateTime= new uint[](len);

        for (uint i = 1; i < len +1; i++) {
            Order storage item = Orderbook[i];
            Amount[i]= item.Amount;
            SaleRate[i]=item.SaleRate;
            ExpDateTime[i]= item.ExpDateTime;
        }
        return (TokenSale, TokenAsking, Amount,SaleRate,ExpDateTime);
    }

    function getSaleOrder(uint OrderBookIndex) public constant returns (
        bytes8 TokenSale,
        bytes8 TokenAsking,
        uint Amount,
        uint SaleRate,
        uint CreatedDateTime,
        uint ExpiryMinute,
        uint Status)
      {
          return (
            Orderbook[OrderBookIndex].TokenSale,
            Orderbook[OrderBookIndex].TokenAsking,
            Orderbook[OrderBookIndex].Amount,
            Orderbook[OrderBookIndex].SaleRate,
            Orderbook[OrderBookIndex].CreatedDateTime,
            Orderbook[OrderBookIndex].ExpDateTime,
            Orderbook[OrderBookIndex].Status
          );
      }

    function getSaleOrderSeller(uint OrderBookIndex) public constant returns (
        address Seller)
      {
          return Orderbook[OrderBookIndex].Seller;
      }

    function getOrderbookLength() private returns(uint256) { return ++OrderbookLength; }


   function changeKYCAddress(address kycContractAddress) onlyOwner external returns (bool success) {   
        KYCContractAddress = kycContractAddress;
        return true;
   }

   function addEditwalletContractAddress(bytes8 token, address contractAddress) onlyOwner external returns (bool success) {   
       
        TokenContract[token] =  contractAddress;
        return true;
   }

  function getWalletAddress(bytes8 token) public constant returns (address) { 
      return TokenContract[token];
  }

  function getFee(bytes8 token, uint feeType) public constant returns (uint fee) {
    return TokenFee[token][feeType];
  }

  function addEditTokenFee(bytes8 token, uint feeType, uint fee) onlyOwner external returns (bool success) {   
    TokenFee[token][feeType] =fee;
    return true;
    
   }

 function withdrawFee(bytes8 token) onlyOwner external returns (bool success) {
    transferToken(token, msg.sender, FeeBalance[token]);
    return true;
  }

}