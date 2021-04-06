/**
 *Submitted for verification at Etherscan.io on 2021-04-06
*/

// File: contracts/EscrowSwaper.sol

pragma solidity 0.5.12;


library SafeMath {
    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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

contract ERC20 {
    uint256 public totalSupply;

    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  function owner() public view returns(address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract EscrowSwaper is Ownable {
    
    uint public tokenCount;
    uint public orderCount;
    
    enum TokenStatus {SaleNotStarted, OpenForSale, SaleEnded}
    
    struct OrderBook {
        uint orderID;
        address requesterAddress;
        ERC20 depositTokenAddress;
        ERC20 withdrawTokenAddress;
        bool isDeposited;
        bool isWithdrawn;
        uint256 depositAmount;
        uint256 withdrawAmount;
    }
    
    struct Token {
        uint tokenID;
        ERC20 tokenAddress;
        string tokenName;
        TokenStatus tokenStatus;
        uint256 tokenPrice;
        bool isValidToken;
        uint8 decimals;
    }
    
    mapping(uint => Token) public TokenInfo;
 
    mapping(uint => OrderBook) public orderBook;

    mapping(address => OrderBook) public orderBookByRequester;
    
    constructor () public {
        tokenCount = 0;
        orderCount = 0;
    }    

    event AddNewToken(uint tokenID, ERC20 tokenAddress, string tokenName, TokenStatus tokenStatus, uint256 tokenPrice);
    event UpdateTokenStatusForSale(uint TokenID, TokenStatus tokenStatus);
    event UpdateTokenStatusToEndSale(uint TokenID, TokenStatus tokenStatus);
    event DepositToken(uint orderID, address requesterAddress, string depositTokenName, string withdrawTokenName, ERC20 depositTokenAddress, ERC20 withdrawTokenAddress, uint256 depositAmount, uint256 withdrawAmount, bool isDeposited);
    event WithdrawToken(uint orderID,address requesterAddress,ERC20 depositTokenAddress,ERC20 withdrawTokenAddress,uint256 depositAmount, uint256 withdrawAmount, bool isDeposited, bool isWithdrawn);
    event NewOrder(uint orderID, address requesterAddress, string depositTokenName, string withdrawTokenName, ERC20 depositTokenAddress, ERC20 withdrawTokenAddress, uint256 depositAmount, uint256 withdrawAmount, bool isDeposited, bool isWithdrawn);
    event PriceUpdate(uint256 newPrice, uint tokenID);

    function getBalanceOfToken(uint tokenID) public view returns (uint256) {
             return TokenInfo[tokenID].tokenAddress.balanceOf(address(this));
    }
    
    function addNewToken (string memory _tokenName, ERC20 _newTokenAddress, uint256 _tokenPrice, uint8 _decimals) public onlyOwner returns (bool success) {
    
        require(!TokenInfo[tokenCount].isValidToken);
        
        TokenInfo[tokenCount].tokenID = tokenCount;
        TokenInfo[tokenCount].tokenAddress = _newTokenAddress;
        TokenInfo[tokenCount].tokenName = _tokenName;
        TokenInfo[tokenCount].tokenStatus = TokenStatus.SaleNotStarted;
        TokenInfo[tokenCount].tokenPrice = _tokenPrice;
        TokenInfo[tokenCount].isValidToken = true;
        TokenInfo[tokenCount].decimals = _decimals;

        emit AddNewToken(TokenInfo[tokenCount].tokenID, TokenInfo[tokenCount].tokenAddress, TokenInfo[tokenCount].tokenName, TokenInfo[tokenCount].tokenStatus, TokenInfo[tokenCount].tokenPrice);
        tokenCount++;
    
        return true;
    }
    
    function updateTokenPrice (uint256 _tokenPrice, uint _tokenId) public onlyOwner returns (bool success) {
    
        require(TokenInfo[_tokenId].isValidToken);
        
        TokenInfo[_tokenId].tokenPrice = _tokenPrice;

        emit PriceUpdate(_tokenPrice, _tokenId);

        return true;
    }
    
    function updateTokenStatusForSale (uint tokenID) public onlyOwner returns (bool success) {
        require(TokenInfo[tokenID].isValidToken);
        
        TokenInfo[tokenID].tokenStatus = TokenStatus.OpenForSale;
        
        emit UpdateTokenStatusForSale(tokenID, TokenStatus.OpenForSale);
        
        return true;
    }

    function updateTokenStatusToEndSale (uint tokenID) public onlyOwner returns (bool success) {
        require(TokenInfo[tokenID].isValidToken);
        
        TokenInfo[tokenID].tokenStatus = TokenStatus.SaleEnded;
        
        emit UpdateTokenStatusToEndSale(tokenID, TokenStatus.SaleEnded);
        
        return true;
    }

    function isValidToken(uint tokenID) public view returns(bool success) {
        
        return TokenInfo[tokenID].isValidToken;
    }
    
    function getOrdersIdByAddress(address requester) public view returns(uint) {
        
        return orderBookByRequester[requester].orderID;
    }

    function getTokenAddressByID(uint tokenID) public view returns(ERC20 tokenAddress) {
        
        return TokenInfo[tokenID].tokenAddress;
    }

    function swap(ERC20 depositTokenAddress, ERC20 withdrawTokenAddress, uint256 depositTokenAmount, uint depositTokenID, uint withdrawTokenID) public returns (uint){
        require(isValidToken(depositTokenID), "depositTokenID is not valid");
        require(isValidToken(withdrawTokenID)," withdrawTokenID is not valid");
        require(TokenInfo[depositTokenID].tokenStatus == TokenStatus.OpenForSale, "depositTokenID is not open for sale");
        require(TokenInfo[withdrawTokenID].tokenStatus == TokenStatus.OpenForSale, "withdrawTokenID is not open for sale");
        
        uint orderID = depositToken(depositTokenAddress, withdrawTokenAddress, depositTokenAmount, depositTokenID, withdrawTokenID);
        
        if(orderBook[orderID].withdrawAmount <= withdrawTokenAddress.balanceOf(address(this))){
            withdrawToken(withdrawTokenID, orderID);
            emit NewOrder(orderID, orderBook[orderID].requesterAddress, TokenInfo[depositTokenID].tokenName, TokenInfo[withdrawTokenID].tokenName, orderBook[orderID].depositTokenAddress, orderBook[orderID].withdrawTokenAddress, orderBook[orderID].depositAmount, orderBook[orderID].withdrawAmount, orderBook[orderID].isDeposited, orderBook[orderID].isWithdrawn);
    
            return orderID;
        }
        // else {
        //     return 0;
        // }
        // else {
        //     emit NewOrder(orderID, orderBook[orderID].requesterAddress, TokenInfo[depositTokenID].tokenName, TokenInfo[withdrawTokenID].tokenName, orderBook[orderID].depositTokenAddress, orderBook[orderID].withdrawTokenAddress, orderBook[orderID].depositAmount, orderBook[orderID].withdrawAmount, orderBook[orderID].isDeposited, orderBook[orderID].isWithdrawn);
        //     return orderID;
        // }
    
    }

// event DateTest(uint256 multiplyAmount, uint256 calcTokens, uint256 depositAmount, uint256 depositTokenPrice, uint256 withdrawTokenPrice);

    function depositToken(ERC20 depositTokenAddress, ERC20 withdrawTokenAddress, uint256 depositTokenAmount, uint depositTokenID, uint withdrawTokenID) internal returns (uint success) {
        require(isValidToken(depositTokenID),"Invalid: depositTokenID is not valid");
        require(isValidToken(withdrawTokenID), "Invalid: withdrawTokenID is not valid");
        
        orderBook[orderCount].orderID = orderCount;
        orderBook[orderCount].requesterAddress = msg.sender;
        orderBook[orderCount].depositTokenAddress = depositTokenAddress;
        orderBook[orderCount].withdrawTokenAddress = withdrawTokenAddress;
        
        // uint256 calcWithdrawTokens = SafeMath.div(SafeMath.mul(orderBook[orderCount].depositAmount, TokenInfo[depositTokenID].tokenPrice), TokenInfo[withdrawTokenID].tokenPrice);
         uint256 calcWithdrawTokens = 0 ;
         uint256 multiplyAmount = 0;
        if (TokenInfo[depositTokenID].decimals == 6 && TokenInfo[withdrawTokenID].decimals == 18) {
                // calcWithdrawTokens = SafeMath.div(SafeMath.mul(orderBook[orderCount].depositAmount, TokenInfo[depositTokenID].tokenPrice), TokenInfo[withdrawTokenID].tokenPrice);
               
                orderBook[orderCount].depositAmount = depositTokenAmount;

                multiplyAmount = SafeMath.mul(orderBook[orderCount].depositAmount, TokenInfo[depositTokenID].tokenPrice);
                calcWithdrawTokens = SafeMath.div(multiplyAmount, TokenInfo[withdrawTokenID].tokenPrice);
                
                orderBook[orderCount].withdrawAmount = calcWithdrawTokens * 10 ** 12 ;
                
                // emit DateTest( multiplyAmount,  calcWithdrawTokens,  orderBook[orderCount].depositAmount,  TokenInfo[depositTokenID].tokenPrice,  TokenInfo[withdrawTokenID].tokenPrice);


        } else if (TokenInfo[depositTokenID].decimals == 18 && TokenInfo[withdrawTokenID].decimals == 6) {
                // calcWithdrawTokens = SafeMath.div(SafeMath.mul(orderBook[orderCount].depositAmount, TokenInfo[depositTokenID].tokenPrice), TokenInfo[withdrawTokenID].tokenPrice);
                
                orderBook[orderCount].depositAmount = depositTokenAmount;

                multiplyAmount = SafeMath.mul(orderBook[orderCount].depositAmount, TokenInfo[depositTokenID].tokenPrice);
                calcWithdrawTokens = SafeMath.div(multiplyAmount, TokenInfo[withdrawTokenID].tokenPrice);
                
                orderBook[orderCount].withdrawAmount = calcWithdrawTokens / 10 ** 12 ;
                
                // emit DateTest( multiplyAmount,  calcWithdrawTokens,  orderBook[orderCount].depositAmount,  TokenInfo[depositTokenID].tokenPrice,  TokenInfo[withdrawTokenID].tokenPrice);


        } else {
                
                orderBook[orderCount].depositAmount = depositTokenAmount;

                multiplyAmount = SafeMath.mul(orderBook[orderCount].depositAmount, TokenInfo[depositTokenID].tokenPrice);
                calcWithdrawTokens = SafeMath.div(multiplyAmount, TokenInfo[withdrawTokenID].tokenPrice);
                
                orderBook[orderCount].withdrawAmount = calcWithdrawTokens;
                
        }
        
        // depositTokenAddress.allowance(msg.sender, address(this));
        
        // depositTokenAddress.approve(address(this), orderBook[orderCount].depositAmount);

        depositTokenAddress.transferFrom(msg.sender, address(this), orderBook[orderCount].depositAmount);
        
        orderBook[orderCount].isDeposited = true;
                
        emit DepositToken(orderBook[orderCount].orderID, orderBook[orderCount].requesterAddress, TokenInfo[depositTokenID].tokenName, TokenInfo[withdrawTokenID].tokenName, orderBook[orderCount].depositTokenAddress, orderBook[orderCount].withdrawTokenAddress, orderBook[orderCount].depositAmount, orderBook[orderCount].withdrawAmount, orderBook[orderCount].isDeposited);
                
        orderCount++;
        
        return orderBook[orderCount-1].orderID;
    }
    
    function exitSwappedLiquidity(ERC20 _withdrawToken, uint256 _tokens) public onlyOwner returns (bool success) {
        
        _withdrawToken.transfer(msg.sender, _tokens);
        
        return true;
    }
    
    
    function getTestingValues(uint256 depositAmount, uint256 depositTokenPrice, uint256 withdrawTokenPrice) public view returns(uint256) {
       uint256 multiplyAmount = SafeMath.mul(depositAmount, depositTokenPrice);
       uint256 calcWithdrawTokens = SafeMath.div(multiplyAmount, withdrawTokenPrice);  
       return calcWithdrawTokens;
    }
    
    function withdrawToken(uint withdrawID, uint orderID) internal returns (bool success){

        require(isValidToken(withdrawID), "Invalid: withdrawTokenID is not valid");
        require(orderBook[orderID].isDeposited, "Token should be deposited");
        require(!orderBook[orderID].isWithdrawn, "Token should not be withdrawn");
        require(getBalanceOfToken(withdrawID) >= orderBook[orderID].withdrawAmount, "Withdraw token balance should greater or equals to the order amount in contract");
            
        orderBook[orderID].withdrawTokenAddress.transfer(orderBook[orderID].requesterAddress, orderBook[orderID].withdrawAmount);
        orderBook[orderID].isWithdrawn = true;
        
        emit WithdrawToken(orderID, orderBook[orderID].requesterAddress, orderBook[orderID].depositTokenAddress, orderBook[orderID].withdrawTokenAddress, orderBook[orderID].depositAmount, orderBook[orderID].withdrawAmount, orderBook[orderID].isDeposited, orderBook[orderID].isWithdrawn);
        
        return true;
    
    }
    
}