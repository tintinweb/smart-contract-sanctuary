/**
 *Submitted for verification at Etherscan.io on 2021-02-11
*/

pragma solidity 0.5.13;  /*
 
 
 
 
    ___________________________________________________________________
      _      _                                        ______           
      |  |  /          /                                /              
    --|-/|-/-----__---/----__----__---_--_----__-------/-------__------
      |/ |/    /___) /   /   ' /   ) / /  ) /___)     /      /   )     
    __/__|____(___ _/___(___ _(___/_/_/__/_(___ _____/______(___/__o_o_
    
        
       

██╗   ██╗███╗   ██╗██╗████████╗██╗   ██╗    ██████╗ ███████╗██╗  ██╗
██║   ██║████╗  ██║██║╚══██╔══╝╚██╗ ██╔╝    ██╔══██╗██╔════╝╚██╗██╔╝
██║   ██║██╔██╗ ██║██║   ██║    ╚████╔╝     ██║  ██║█████╗   ╚███╔╝ 
██║   ██║██║╚██╗██║██║   ██║     ╚██╔╝      ██║  ██║██╔══╝   ██╔██╗ 
╚██████╔╝██║ ╚████║██║   ██║      ██║       ██████╔╝███████╗██╔╝ ██╗
 ╚═════╝ ╚═╝  ╚═══╝╚═╝   ╚═╝      ╚═╝       ╚═════╝ ╚══════╝╚═╝  ╚═╝
                                                                    




                                                                                     
                                                                                     
------------------------------------------------------------------------------------------------------
 Copyright (c) 2021 Onwards Unity DEX Inc. ( https://unity-dex.io )
 Contract designed with ❤ by EtherAuthority  ( https://EtherAuthority.io )
------------------------------------------------------------------------------------------------------
*/


//*******************************************************************
//------------------------ SafeMath Library -------------------------
//*******************************************************************
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


interface ERC20Essential 
{

    function transfer(address _to, uint256 _amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);

}




//*******************************************************************//
//------------------ Contract to Manage Ownership -------------------//
//*******************************************************************//
    
contract owned {
    address public owner;
    address private newOwner;


    event OwnershipTransferred(uint256 curTime, address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, 'Only owner can call this function');
        _;
    }


    function onlyOwnerTransferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    //this flow is to prevent transferring ownership to wrong wallet by mistake
    function acceptOwnership() public {
        require(msg.sender == newOwner, 'Only new owner can call this function');
        emit OwnershipTransferred(now, owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}



contract UnityDEX is owned {
  using SafeMath for uint256;
  bool public safeGuard; // To hault all non owner functions in case of imergency - by default false
  address public feeAccount; //the account that will receive fees
  uint public tradingFee = 300; // 300 = 0.3%
  
  //referrals
  uint256 public refPercent = 10;  // percent to calculate referal bonous - by default 10% of trading fee
  
  mapping (address => mapping (address => uint)) public tokens; //mapping of token addresses to mapping of account balances (token=0 means Ether)
  mapping (address => mapping (bytes32 => bool)) public orders; //mapping of user accounts to mapping of order hashes to booleans (true = submitted by user, equivalent to offchain signature)
  mapping (address => mapping (bytes32 => uint)) public orderFills; //mapping of user accounts to mapping of order hashes to uints (amount of order that has been filled)
  
  /* Mapping to track referrer. The second address is the address of referrer, the Up-line/ Sponsor */
  mapping (address => address) public referrers;
  /* Mapping to track referrer bonus for all the referrers */
  mapping (address => uint) public referrerBonusBalance;
  
  event Order(uint256 curTime, address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires,  address user);
  event Cancel(uint256 curTime, address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, address user, uint8 v, bytes32 r, bytes32 s);
  event Trade( uint256 curTime, address tokenGet, uint amountGet, address tokenGive, uint amountGive, address get, address give, uint256 orderBookID);
  event Deposit(uint256 curTime, address token, address user, uint amount, uint balance);
  event Withdraw(uint256 curTime, address token, address user, uint amount, uint balance);
  event OwnerWithdrawCommission(address indexed owner, address indexed tokenAddress, uint256 amount);
  
  // Events to track ether transfer to referrers
  event ReferrerBonus(address indexed referer, address indexed trader, uint256 referralBonus, uint256 timestamp );
  event ReferrerBonusWithdrawn(address indexed referrer, uint256 indexed amount);

  

    constructor() public {
        feeAccount = msg.sender;
    }

    function changeSafeguardStatus() onlyOwner public
    {
        if (safeGuard == false)
        {
            safeGuard = true;
        }
        else
        {
            safeGuard = false;    
        }
    }

    //Calculate percent and return result
    function calculatePercentage(uint256 PercentOf, uint256 percentTo ) internal pure returns (uint256) 
    {
        uint256 factor = 100000;    //so to make 1000 = 1%
        require(percentTo <= factor, 'percentTo must be less than factor');
        uint256 c = PercentOf.mul(percentTo).div(factor);
        return c;
    }  



    
  // contract accepts incoming ether -  this needed in case owner want to fund refPool
  function() payable external {  }


  function changeFeeAccount(address feeAccount_) public onlyOwner {
    feeAccount = feeAccount_;
  }

  function changetradingFee(uint tradingFee_) public onlyOwner{
    require(tradingFee_ <= 10000, 'trading fee can not be more than 100%');
    tradingFee = tradingFee_;
  }
  
  function availableOwnerCommissionEther() public view returns(uint256){
      //assress 0x0 only holds ether as fee
      return tokens[address(0)][feeAccount];
  }
  
  function availableOwnerCommissionToken(address tokenAddress) public view returns(uint256){
      //assress 0x0 only holds ether as fee
      return tokens[tokenAddress][feeAccount];
  }
  
  function withdrawOwnerCommissoinEther() public  returns (string memory){
      require(msg.sender == feeAccount, 'Invalid caller');
      uint256 amount = availableOwnerCommissionEther();
      require (amount > 0, 'Nothing to withdraw');
      tokens[address(0)][feeAccount] = 0;
      msg.sender.transfer(amount);
      emit OwnerWithdrawCommission(msg.sender, address(0), amount);
      return "Ether withdrawn successfully";
  }
  
  function withdrawOwnerCommissoinToken(address tokenAddress) public  returns (string memory){
      require(msg.sender == feeAccount, 'Invalid caller');
      uint256 amount = availableOwnerCommissionToken(tokenAddress);
      require (amount > 0, 'Nothing to withdraw');
      tokens[tokenAddress][feeAccount] = 0;
      ERC20Essential(tokenAddress).transfer(msg.sender, amount);
      emit OwnerWithdrawCommission(msg.sender, tokenAddress, amount);
      return "Token withdrawn successfully";
  }

  function deposit() public payable {
    tokens[address(0)][msg.sender] = tokens[address(0)][msg.sender].add(msg.value);
    emit Deposit(now, address(0), msg.sender, msg.value, tokens[address(0)][msg.sender]);
  }

  function withdraw(uint amount) public {
    require(!safeGuard,"System Paused by Admin");
    require(tokens[address(0)][msg.sender] >= amount, 'Not enough balance');
    tokens[address(0)][msg.sender] = tokens[address(0)][msg.sender].sub(amount);
    msg.sender.transfer(amount);
    emit Withdraw(now, address(0), msg.sender, amount, tokens[address(0)][msg.sender]);
  }

  function depositToken(address token, uint amount) public {
    //remember to call Token(address).approve(address(this), amount) or this contract will not be able to do the transfer on your behalf.
    require(token!=address(0), 'Invalid token address');
    require(ERC20Essential(token).transferFrom(msg.sender, address(this), amount), 'tokens could not be transferred');
    tokens[token][msg.sender] = tokens[token][msg.sender].add(amount);
    emit Deposit(now, token, msg.sender, amount, tokens[token][msg.sender]);
  }
	
  function withdrawToken(address token, uint amount) public {
    require(!safeGuard,"System Paused by Admin");
    require(token!=address(0), 'Invalid token address');
    require(tokens[token][msg.sender] >= amount, 'not enough token balance');
    tokens[token][msg.sender] = tokens[token][msg.sender].sub(amount);
	  ERC20Essential(token).transfer(msg.sender, amount);
    emit Withdraw(now, token, msg.sender, amount, tokens[token][msg.sender]);
  }

  function balanceOf(address token, address user) public view returns (uint) {
    return tokens[token][user];
  }

  function order(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires) public {
    bytes32 hash = keccak256(abi.encodePacked(address(this), tokenGet, amountGet, tokenGive, amountGive, expires));
    orders[msg.sender][hash] = true;
    emit Order(now, tokenGet, amountGet, tokenGive, amountGive, expires, msg.sender);
  }


    /* address[4] addressArray elements
        0 = tokenGet
        1 = tokenGive
        2 = tradeMaker
        3 = referrer
    */
  function trade(address[4] memory addressArray, uint amountGet, uint amountGive, uint expires, uint8 v, bytes32 r, bytes32 s, uint amount, uint orderBookID) public {
    require(!safeGuard,"System Paused by Admin");
    //amount is in amountGet terms
    bytes32 hash = keccak256(abi.encodePacked(address(this), addressArray[0], amountGet, addressArray[1], amountGive, expires));
    require(orders[addressArray[2]][hash] || ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)),v,r,s) == addressArray[2], 'Invalid trade parameters');
    require(block.number <= expires, 'Trade is expired');
    require(orderFills[addressArray[2]][hash].add(amount) <= amountGet, 'Trade order is filled');

    tradeBalances(addressArray, amountGet, amountGive, amount );
    orderFills[addressArray[2]][hash] = orderFills[addressArray[2]][hash].add(amount);
    
    emit Trade(now, addressArray[0], amount, addressArray[1], amountGive * amount / amountGet, addressArray[2], msg.sender, orderBookID);
  }
    
    /**
        addressArray array elements
        0 = tokenGet
        1 = tokenGive
        2 = user
        3 = referrer
    */
  function tradeBalances(address[4] memory addressArray, uint amountGet, uint amountGive, uint amount) internal {
    
    uint tradingFeeXfer = calculatePercentage(amount,tradingFee);
    
    //processing referrers bonus - which is % of the trading fee
    processReferrerBonus(addressArray[3], tradingFeeXfer);

    tokens[addressArray[0]][msg.sender] = tokens[addressArray[0]][msg.sender].sub(amount.add(tradingFeeXfer));
    tokens[addressArray[0]][addressArray[2]] = tokens[addressArray[0]][addressArray[2]].add(amount);
    tokens[addressArray[0]][feeAccount] = tokens[addressArray[0]][feeAccount].add(tradingFeeXfer);

    tokens[addressArray[1]][addressArray[2]] = tokens[addressArray[1]][addressArray[2]].sub(amountGive.mul(amount) / amountGet);
    tokens[addressArray[1]][msg.sender] = tokens[addressArray[1]][msg.sender].add(amountGive.mul(amount) / amountGet);
  }
  
  

  function testTrade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, address user, uint8 v, bytes32 r, bytes32 s, uint amount, address sender) public view returns(bool) {
    
    if (!(
      tokens[tokenGet][sender] >= amount &&
      availableVolume(tokenGet, amountGet, tokenGive, amountGive, expires, user, v, r, s) >= amount
    )) return false;
    return true;
  }
  
  function testVRS(address tokenGet, uint256 amountGet, address tokenGive, uint256 amountGive, uint256 expires, uint8 v, bytes32 r, bytes32 s ) public view returns(address){
      
      bytes32 hash = keccak256(abi.encodePacked(address(this), tokenGet, amountGet, tokenGive, amountGive, expires));
     
      return ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)),v,r,s);
    
  }

  function availableVolume(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, address user, uint8 v, bytes32 r, bytes32 s) public view returns(uint) {
    bytes32 hash = keccak256(abi.encodePacked(address(this), tokenGet, amountGet, tokenGive, amountGive, expires));
    uint available1;
    if (!(
      (orders[user][hash] || ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)),v,r,s) == user) &&
      block.number <= expires
    )) return 0;
    available1 = tokens[tokenGive][user].mul(amountGet) / amountGive;
    
    if (amountGet.sub(orderFills[user][hash])<available1) return amountGet.sub(orderFills[user][hash]);
    return available1;
    
  }

  function amountFilled(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, address user) public view returns(uint) {
    bytes32 hash = keccak256(abi.encodePacked(address(this), tokenGet, amountGet, tokenGive, amountGive, expires));
    return orderFills[user][hash];
  }

  function cancelOrder(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint8 v, bytes32 r, bytes32 s) public {
    require(!safeGuard,"System Paused by Admin");
    bytes32 hash = keccak256(abi.encodePacked(address(this), tokenGet, amountGet, tokenGive, amountGive, expires));
    require(orders[msg.sender][hash] || ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)),v,r,s) == msg.sender, 'Invalid trade order');
    orderFills[msg.sender][hash] = amountGet;
    emit Cancel(now, tokenGet, amountGet, tokenGive, amountGive, expires, msg.sender, v, r, s);
  }



//==================================================//
//              REFERRAL SECTION CODE               //
//==================================================//

function processReferrerBonus(address _referrer, uint256 _tradingFeeLocal) internal {
      
      address existingReferrer = referrers[msg.sender];
      
      if(_referrer != address(0) && existingReferrer != address(0) ){
        referrerBonusBalance[existingReferrer] += _tradingFeeLocal * refPercent / 100;
        emit ReferrerBonus(_referrer, msg.sender, _tradingFeeLocal * refPercent / 100, now );
      }
      else if(_referrer != address(0) && existingReferrer == address(0) ){
        //no referrer exist, but provided in trade function call
        referrerBonusBalance[_referrer] += _tradingFeeLocal * refPercent / 100;
        referrers[msg.sender] = _referrer;
        emit ReferrerBonus(_referrer, msg.sender, _tradingFeeLocal * refPercent / 100, now );
      }
  }
  
  function changeRefPercent(uint256 newRefPercent) public onlyOwner returns (string memory){
      require(newRefPercent <= 100, 'newRefPercent can not be more than 100');
      refPercent = newRefPercent;
      return "refPool fee updated successfully";
  }
  
  /**
        * Function will allow users to withdraw their referrer bonus  
    */
    function claimReferrerBonus() public returns(bool) {
        
        address payable msgSender = msg.sender;
        
        uint256 referralBonus = referrerBonusBalance[msgSender];
        
        require(referralBonus > 0, 'Insufficient referrer bonus');
        referrerBonusBalance[msgSender] = 0;
        
        
        //transfer the referrer bonus
        msgSender.transfer(referralBonus);
        
        //fire event
        emit ReferrerBonusWithdrawn(msgSender, referralBonus);
        
        return true;
    }








}