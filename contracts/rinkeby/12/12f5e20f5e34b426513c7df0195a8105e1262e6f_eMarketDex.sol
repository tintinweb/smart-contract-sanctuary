/**
 *Submitted for verification at Etherscan.io on 2021-03-22
*/

pragma solidity 0.5.17;   /*

    ___________________________________________________________________
      _      _                                        ______           
      |  |  /          /                                /              
    --|-/|-/-----__---/----__----__---_--_----__-------/-------__------
      |/ |/    /___) /   /   ' /   ) / /  ) /___)     /      /   )     
    __/__|____(___ _/___(___ _(___/_/_/__/_(___ _____/______(___/__o_o_
    
    
███████╗███╗░░░███╗░█████╗░██████╗░██╗░░██╗███████╗████████╗  ██████╗░███████╗██╗░░██╗
██╔════╝████╗░████║██╔══██╗██╔══██╗██║░██╔╝██╔════╝╚══██╔══╝  ██╔══██╗██╔════╝╚██╗██╔╝
█████╗░░██╔████╔██║███████║██████╔╝█████═╝░█████╗░░░░░██║░░░  ██║░░██║█████╗░░░╚███╔╝░
██╔══╝░░██║╚██╔╝██║██╔══██║██╔══██╗██╔═██╗░██╔══╝░░░░░██║░░░  ██║░░██║██╔══╝░░░██╔██╗░
███████╗██║░╚═╝░██║██║░░██║██║░░██║██║░╚██╗███████╗░░░██║░░░  ██████╔╝███████╗██╔╝╚██╗
╚══════╝╚═╝░░░░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚══════╝░░░╚═╝░░░  ╚═════╝░╚══════╝╚═╝░░╚═╝

 
------------------------------------------------------------------------------------------------------
 Copyright 2018 and beyond eMarketDEX https://eMarket.io
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

//*******************************************************************//
//------------------ Contract to Manage Ownership -------------------//
//*******************************************************************//
    
contract owned {
    address payable public owner;
    address payable public newOwner;


    event OwnershipTransferred(uint256 curTime, address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }


    function onlyOwnerTransferOwnership(address payable _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    //this flow is to prevent transferring ownership to wrong wallet by mistake
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(now, owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

interface ERC20Essential 
{

    function transfer(address _to, uint256 _amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);

}

interface ERC865Essential
{
    function transferPreSigned(address _from, address _to,uint256 _value,uint256 _fee,uint256 _nonce,uint8 v,bytes32 r,bytes32 s) external returns(bool);
    function withdrawPreSigned(address _from, address _to,uint256 _value,uint256 _fee,uint256 _nonce,uint8 v,bytes32 r,bytes32 s) external returns(bool);
}

contract eMarketDex is owned {
  using SafeMath for uint256;
  bool public safeGuard; // To hault all non owner functions in case of imergency - by default false
  address public admin; //the admin address
  address public feeAccount; //the account that will receive fees
  uint public tradingFee = 50; // 50 = 0.5%
  
  mapping (address => mapping (address => uint)) public tokens; //mapping of token addresses to mapping of account balances (token=0 means Ether)
  mapping (address => mapping (bytes32 => bool)) public orders; //mapping of user accounts to mapping of order hashes to booleans (true = submitted by user, equivalent to offchain signature)
  mapping (address => mapping (bytes32 => uint)) public orderFills; //mapping of user accounts to mapping of order hashes to uints (amount of order that has been filled)
  
  event Order(uint256 curTime, address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user);
  event Cancel(uint256 curTime, address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s);
  event Trade(uint256 curTime, address tokenGet, uint amountGet, address tokenGive, uint amountGive, address get, address give, uint256 orderBookID);
  event Deposit(uint256 curTime, address token, address user, uint amount, uint balance);
  event Withdraw(uint256 curTime, address token, address user, uint amount, uint balance);

    event OwnerWithdrawTradingFee(address indexed ownerAddress, uint256 amount);


    constructor() public {
        feeAccount = msg.sender;
    }

    //Calculate percent and return result
    function calculatePercentage(uint256 PercentOf, uint256 percentTo ) internal pure returns (uint256) 
    {
        uint256 factor = 10000;
        require(percentTo <= factor);
        uint256 c = PercentOf.mul(percentTo).div(factor);
        return c;
    }  

  // contract without fallback automatically reject incoming ether
  // function() external {  }


  function changeFeeAccount(address feeAccount_) public onlyOwner {
    feeAccount = feeAccount_;
  }

  function changetradingFee(uint tradingFee_) public onlyOwner{
    //require(tradingFee_ <= tradingFee);
    tradingFee = tradingFee_;
  }
  
  function availableTradingFeeOwner() public view returns(uint256){
      //it only holds ether as fee
      return tokens[address(0)][feeAccount];
  }
  
  function withdrawTradingFeeOwner() public onlyOwner returns (string memory){
      uint256 amount = availableTradingFeeOwner();
      require (amount > 0, 'Nothing to withdraw');
      
      tokens[address(0)][feeAccount] = 0;
      
      msg.sender.transfer(amount);
      
      emit OwnerWithdrawTradingFee(owner, amount);
      
  }

  function deposit() public payable {
    tokens[address(0)][msg.sender] = tokens[address(0)][msg.sender].add(msg.value);
    emit Deposit(now, address(0), msg.sender, msg.value, tokens[address(0)][msg.sender]);
  }

  function withdraw(uint amount) public {
    require(!safeGuard,"System Paused by Admin");
    require(tokens[address(0)][msg.sender] >= amount);
    tokens[address(0)][msg.sender] = tokens[address(0)][msg.sender].sub(amount);
    msg.sender.transfer(amount);
    emit Withdraw(now, address(0), msg.sender, amount, tokens[address(0)][msg.sender]);
  }

  function depositToken(address token, uint amount) public {
    //remember to call Token(address).approve(this, amount) or this contract will not be able to do the transfer on your behalf.
    require(token!=address(0));
    require(ERC20Essential(token).transferFrom(msg.sender, address(this), amount));
    tokens[token][msg.sender] = tokens[token][msg.sender].add(amount);
    emit Deposit(now, token, msg.sender, amount, tokens[token][msg.sender]);
  }
	
  function withdrawToken(address token, uint amount) public {
    require(!safeGuard,"System Paused by Admin");
    require(token!=address(0));
    require(tokens[token][msg.sender] >= amount);
    tokens[token][msg.sender] = tokens[token][msg.sender].sub(amount);
	  ERC20Essential(token).transfer(msg.sender, amount);
    emit Withdraw(now, token, msg.sender, amount, tokens[token][msg.sender]);
  }

  function balanceOf(address token, address user) public view returns (uint) {
    return tokens[token][user];
  }

  function order(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce) public {
    bytes32 hash = keccak256(abi.encodePacked(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce));
    orders[msg.sender][hash] = true;
    emit Order(now, tokenGet, amountGet, tokenGive, amountGive, expires, nonce, msg.sender);
  }

  function trade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s, uint amount, uint256 orderBookID) public {
    require(!safeGuard,"System Paused by Admin");
    //amount is in amountGet terms
    bytes32 hash = keccak256(abi.encodePacked(address(this), tokenGet, amountGet, tokenGive, amountGive, expires, nonce));
    require((
      (orders[user][hash] || ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)),v,r,s) == user) &&
      block.number <= expires &&
      orderFills[user][hash].add(amount) <= amountGet
    ),"Invalid");
    splitTrade(tokenGet, amountGet, tokenGive, amountGive, user, amount, orderBookID);
    orderFills[user][hash] = orderFills[user][hash].add(amount);
    
  }
  
  function splitTrade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, address user, uint amount, uint256 orderBookID) internal {
      
      tradeBalances(tokenGet, amountGet, tokenGive, amountGive, user, amount);
      emit Trade(now, tokenGet, amount, tokenGive, amountGive * amount / amountGet, user, msg.sender, orderBookID);
  }

  function tradeBalances(address tokenGet, uint amountGet, address tokenGive, uint amountGive, address user, uint amount) internal {
    
    uint tradingFeeXfer = calculatePercentage(amount,tradingFee);

    tokens[tokenGet][msg.sender] = tokens[tokenGet][msg.sender].sub(amount.add(tradingFeeXfer));
    tokens[tokenGet][user] = tokens[tokenGet][user].add(amount.sub(tradingFeeXfer));
    tokens[address(0)][feeAccount] = tokens[address(0)][feeAccount].add(tradingFeeXfer);

    tokens[tokenGive][user] = tokens[tokenGive][user].sub(amountGive.mul(amount) / amountGet);
    tokens[tokenGive][msg.sender] = tokens[tokenGive][msg.sender].add(amountGive.mul(amount) / amountGet);
  }

  function testTrade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s, uint amount, address sender) public view returns(bool) {
    
    if (!(
      tokens[tokenGet][sender] >= amount &&
      availableVolume(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, user, v, r, s) >= amount
    )) return false;
    return true;
  }

  function availableVolume(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s) public view returns(uint) {
    bytes32 hash = keccak256(abi.encodePacked(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce));
    uint available1;
    if (!(
      (orders[user][hash] || ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)),v,r,s) == user) &&
      block.number <= expires
    )) return 0;
    available1 = tokens[tokenGive][user].mul(amountGet) / amountGive;
    
    if (amountGet.sub(orderFills[user][hash])<available1) return amountGet.sub(orderFills[user][hash]);
    return available1;
    
  }

  function amountFilled(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user) public view returns(uint) {
    bytes32 hash = keccak256(abi.encodePacked(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce));
    return orderFills[user][hash];
  }

  function cancelOrder(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, uint8 v, bytes32 r, bytes32 s) public {
    require(!safeGuard,"System Paused by Admin");
    bytes32 hash = keccak256(abi.encodePacked(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce));
    require((orders[msg.sender][hash] || ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)),v,r,s) == msg.sender));
    orderFills[msg.sender][hash] = amountGet;
    emit Cancel(now, tokenGet, amountGet, tokenGive, amountGive, expires, nonce, msg.sender, v, r, s);
  }

    /****************************************/
    /* Custom Code for the ERC865 TOKEN */
    /****************************************/

     /* Nonces of transfers performed */
    mapping(bytes32 => bool) transactionHashes;
    
    function transferFromPreSigned(
        address token,
        address _from,
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce,
        uint8 v, 
        bytes32 r, 
        bytes32 s
    )
        public
        returns (bool)
    {
        require(_to != address(0));
        bytes32 hashedTx = keccak256(abi.encodePacked('transferFromPreSigned', address(this), _from, _to, _value, _fee, _nonce));
        require(transactionHashes[hashedTx] == false, 'transaction hash is already used');
        address spender = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hashedTx)),v,r,s);
        require(spender != address(0), 'Invalid _from address');
        require(ERC20Essential(token).transferFrom(_from, _to, _value),"transferfrom fail");
        require(ERC20Essential(token).transferFrom(spender, msg.sender, _fee),"transfer from fee fail");
        transactionHashes[hashedTx] = true;
        return true;
    }
    
    function transferPreSigned(
        address token,
        address _from,
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce,
        uint8 v, 
        bytes32 r, 
        bytes32 s
    )
        public
        returns (bool)
    {
        require(_to != address(0));
        bytes32 hashedTx = keccak256(abi.encodePacked('transferFromPreSigned', address(this), _to, _value, _fee, _nonce));
        require(transactionHashes[hashedTx] == false, 'transaction hash is already used');
        address spender = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hashedTx)),v,r,s);
        require(spender != address(0), 'Invalid _from address');
        require(_from==spender);
        require(ERC20Essential(token).transfer(_to, _value.sub(_fee)),"transferfrom fail");
        require(ERC20Essential(token).transfer( msg.sender, _fee),"transfer from fee fail");
        transactionHashes[hashedTx] = true;
        return true;
    }
     
    function testSender(
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce,
        uint8 v, 
        bytes32 r, 
        bytes32 s
    )
        public
        view
        returns (address)
    {
        bytes32 hashedTx = keccak256(abi.encodePacked(address(this), _to, _value, _fee, _nonce));
        return ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hashedTx)),v,r,s);
    }

    /********************************/
    /*  Code for helper functions   */
    /********************************/
      
    //Just in case, owner wants to transfer Ether from contract to owner address
    function manualWithdrawEther()onlyOwner public{
        address(owner).transfer(address(this).balance);
    }
    
    //Just in case, owner wants to transfer Tokens from contract to owner address
    //tokenAmount must be in WEI
    function manualWithdrawTokens(address token, uint256 tokenAmount)onlyOwner public{
        ERC20Essential(token).transfer(msg.sender, tokenAmount);
    }
    
    //selfdestruct function. just in case owner decided to destruct this contract.
    function destructContract()onlyOwner public{
        selfdestruct(owner);
    }
    
    /**
     * Change safeguard status on or off
     *
     * When safeguard is true, then all the non-owner functions will stop working.
     * When safeguard is false, then all the functions will resume working back again!
     */
    function changeSafeguardStatus() onlyOwner public{
        if (safeGuard == false){
            safeGuard = true;
        }
        else{
            safeGuard = false;    
        }
    }
    
    // function getpreSignHash(string memory _messg, address currentcon, address _to, uint _amount, uint fee, uint _nonce)public view returns (bytes32)
    // {
    //     return keccak256(abi.encodePacked(_messg,currentcon,_to,_amount,fee,_nonce));
    // }
    
    // function transferfromPresignedhash(string memory _messg,address _from, address currentcon, address _to, uint _amount, uint fee, uint _nonce)public view returns (bytes32)
    // {
    //     return keccak256(abi.encodePacked(_messg,currentcon,_from, _to,_amount,fee,_nonce));
    // }
    
    // function getpreSignTradeHash(address tokenGet,uint amountGet,address tokenGive,uint amountGive,uint expires,uint nonce, address _from)public view returns (bytes32)
    // {
    //     return keccak256(abi.encodePacked(_from, tokenGet, amountGet, tokenGive, amountGive, expires, nonce));
    // }
    
    function preSignDeposit(address token, uint amount,uint8 v,bytes32 r,bytes32 s, address _from, uint _fee,uint _nonce) public {
        
        require(token!=address(0));
        require(ERC865Essential(token).transferPreSigned(_from, address(this), amount, _fee, _nonce, v, r, s));
        //require(ERC20Essential(token).transfer(msg.sender, _fee));
        tokens[token][_from] = tokens[token][_from].add(amount).sub(_fee);
        emit Deposit(now, token, _from, amount, tokens[token][_from]);
      }
      
      function preSignWithdraw(address token,address _to, uint amount,uint fee,uint8 v,bytes32 r,bytes32 s,uint _nonce ) public  returns(bool){
        
        require(!safeGuard,"System Paused by Admin");
        require(token!=address(0));
        require(tokens[token][_to] >= amount);
    	require(ERC865Essential(token).withdrawPreSigned(address(this),_to, amount, fee, _nonce, v, r, s));
    	tokens[token][_to] = tokens[token][_to].sub(amount).sub(fee);
        emit Withdraw(now, token, _to, amount, tokens[token][_to]);
        return true;
      }
      
function presigntrade(address _from, address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s, uint amount, uint _fee, uint256 orderBookID) public {
    require(!safeGuard,"System Paused by Admin");
    //amount is in amountGet terms
    bytes32 hash = keccak256(abi.encodePacked(address(this), tokenGet, amountGet, tokenGive, amountGive, expires, nonce));
    require(orders[user][hash] || ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)),v,r,s) == user,"invvalid");
    require(block.number <= expires,"Block Expired");
    require(orderFills[user][hash].add(amount) <= amountGet,"invalid amount");
    splitPresignTrade(_from,tokenGet, amountGet, tokenGive, amountGive, user, amount, _fee, orderBookID);
    orderFills[user][hash] = orderFills[user][hash].add(amount);
    //emit Trade(now, tokenGet, amount, tokenGive, amountGive * amount / amountGet, user, _from);
  }
  
  function splitPresignTrade(address _from, address tokenGet, uint amountGet, address tokenGive, uint amountGive, address user, uint amount, uint _fee, uint256 orderBookID) internal {
     
      presigntradeBalances(_from,tokenGet, amountGet, tokenGive, amountGive, user, amount, _fee);
      emit Trade(now, tokenGet, amount, tokenGive, amountGive * amount / amountGet, user, _from, orderBookID);
     
  }

  function presigntradeBalances(address _from, address tokenGet, uint amountGet, address tokenGive, uint amountGive, address user, uint amount, uint _fee) internal {
    
    uint tradingFeeXfer = calculatePercentage(amount,tradingFee);

    tokens[tokenGet][_from] = tokens[tokenGet][_from].sub(amount.add(tradingFeeXfer));
    tokens[tokenGet][user] = tokens[tokenGet][user].add(amount.sub(tradingFeeXfer));
    tokens[address(0)][feeAccount] = tokens[address(0)][feeAccount].add(tradingFeeXfer);

    tokens[tokenGive][user] = tokens[tokenGive][user].sub(amountGive.mul(amount) / amountGet);
    tokens[tokenGive][_from] = tokens[tokenGive][_from].add(amountGive.mul(amount) / amountGet).sub(_fee);
    tokens[tokenGive][msg.sender] = tokens[tokenGive][msg.sender].add(_fee);
   
  }
  
}