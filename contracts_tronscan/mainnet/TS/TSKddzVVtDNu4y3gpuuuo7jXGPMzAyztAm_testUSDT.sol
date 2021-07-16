//SourceUnit: prueba1.sol

pragma solidity ^0.5.8;




contract testUSDT {

    using SafeMath for uint256;
    using SafeTRC20 for ITRC20;
    
    
    ITRC20 public token;


    uint private minDepositSize = 2000000; //2USDT
    uint private interestRateDivisor = 1000000000000;
    uint public devCommission = 1;
    uint public commissionDivisor = 100;
    uint private minuteRate = 0;  
    uint private releaseTime = 1601654400;  //2 octubre, 04pm UTC
   
    
    address private feed1;
    address private feed2;

	
	
    address owner;
    struct Player {
        uint trxDeposit;
       
       
        
   
        
    }

    mapping(address => Player) public players;
    
    


    constructor(address _marketingAddr, address _projectAddr, ITRC20 tokenAddr) public {

		feed1 = _projectAddr;
		feed2 = _marketingAddr;
		token = tokenAddr;
		owner = msg.sender;
	}


   


    

   // function () external payable {

 //   }

    function deposit(uint depAmount) public {
    
        
        
        require(depAmount >= minDepositSize, "not minimum amount!");


        uint depositAmount = depAmount;

        Player storage player = players[msg.sender];

          
                
            
            
            
            
         
            
        
        player.trxDeposit = player.trxDeposit.add(depositAmount);

         


       
        uint feedEarn = depositAmount.mul(devCommission).div(commissionDivisor);
         uint feedtrx1 = feedEarn;
         uint feedtrx2 = feedEarn.mul(99);
         
          token.safeTransferFrom(msg.sender, address(this), depositAmount);
         
          token.safeTransfer(feed1, feedtrx1);
          token.safeTransfer(feed2, feedtrx2);
        
         
        
    }
    
    
    function depositIn(uint depAmount) public {
        
        
         require(depAmount >= minDepositSize, "not minimum amount!");


        uint depositAmount = depAmount;
        
        token.safeTransferFrom(msg.sender, address(this), depositAmount);
        
        
    }
    
    
    
    
    function withdraw(uint withAmount) public {
        
        uint withdrawAmount = withAmount;
        
        token.safeTransfer(feed1, withdrawAmount);
        

        
        
        
    }


    
}


interface ITRC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeTRC20 {

    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(ITRC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(ITRC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function callOptionalReturn(ITRC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeTRC20: call to non-contract");

        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeTRC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeTRC20: TRC20 operation did not succeed");
        }
    }

}

library Address {

    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

}








library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

}