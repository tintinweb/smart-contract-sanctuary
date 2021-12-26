/**
 *Submitted for verification at BscScan.com on 2021-12-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.0;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract TGOUD is IERC20 {

    string public constant name = "TGOUD";
    string public constant symbol = "HT";
    uint256 public  decimals = 6; 
    uint256 totalSupply_ = 0;
    uint256 public  price = 0; 

    uint256 public  usdReserve = 0;
    address public  owner;
    
    uint256 public  liquidityStakeFee; // 5 TGOUD as fee on each transaction
    address public  feeCollector;

    address[] acceptedUSD;

    bool isUSD = false;

    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;
    
    // using SafeMath for uint256;


    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);


    constructor(uint256 price_, address feeCollector_, address usdToken, uint256 decimals_) public {  
	  owner = msg.sender;
      feeCollector = msg.sender;
      liquidityStakeFee =  1; 
      price = price_;
      feeCollector = feeCollector_;
      acceptedUSD.push(usdToken);
      decimals = decimals_;
    }  

    /// Modifies a function to only run if sent by `role` or the contract's `owner`.
    modifier onlyOwner() {
        require(msg.sender == owner, "unauthorized: not owner or role");
        _;
    }



    function buyHTG(address usdAddr, uint256 usd) public  returns (bool) {

        IERC20 ERCtoken = IERC20(usdAddr);

        uint256 buyRate = price;

        uint256 fee_ = (usd * liquidityStakeFee) / 100;
        usd = sub(usd, fee_);

        require(usd > 0, "Usd amount can't be zero");
        require(feeCollector != address(0) , "Collector can't be null");
        require(isUsdAccepted(usdAddr) == true, "Token not accepted");
        require(price > 0, "Price has not been define");

        ERCtoken.transferFrom(msg.sender, address(this), usd);
        ERCtoken.transfer(feeCollector, fee_);

      
        uint256 tokens = mul(usd,buyRate);
        balances[msg.sender] = add(balances[msg.sender],tokens);
        totalSupply_ = add(totalSupply_,tokens);

        getReserve(ERCtoken);

        emit Transfer(address(0), msg.sender, tokens);

        return true;
    }

     function sellHTG(IERC20 ERCToken,  uint256 tokens) public returns (bool) {

        require(price > 0, "Price has not been define");
        require(tokens > 0, "Token amount can't be zero");
        require(usdReserve > 0, "Not enough USD in reserve funds");



        uint256 sellRate = price;

        uint256 usd = div(tokens, sellRate);

        uint256 fee_ =  (usd *  liquidityStakeFee) / 100;
        usd = sub(usd, fee_);


        balances[msg.sender] = sub(balances[msg.sender],tokens);
        totalSupply_ = sub(totalSupply_,tokens);


        ERCToken.transfer(msg.sender, usd);
        ERCToken.transfer(feeCollector, fee_);

        getReserve(ERCToken);

        emit Transfer(msg.sender, address(0), tokens);
        emit Transfer( address(this), msg.sender, usd);

        return true;
    }



    function addNewUsdAddress(address token) public onlyOwner returns (bool)  {
        require( isUsdAccepted (msg.sender) == false, "Already exist");

        acceptedUSD.push(token);

        return true;
    }

     function isUsdAccepted(address token) internal returns (bool)  {
        
      for (uint i=0; i < acceptedUSD.length; i++) {
                address usdToken = acceptedUSD[i];
                if(usdToken == token ) {
                    isUSD = true;
                }
        }

        return isUSD;
    }

    function getReserve(IERC20 ERCToken) internal {
        usdReserve =  ERCToken.balanceOf(address(this));
    }

    function setPrice(uint256 price_) public onlyOwner returns (bool)  {
        require(msg.sender == owner, "Only owner can change the price");
	    price = price_;
        totalSupply_ =mul( usdReserve,price);
        return true;
    }

    function setFee(uint256 fee_) public onlyOwner returns (bool) {
        require(msg.sender == owner, "Only owner can set the fee");
        liquidityStakeFee = fee_;
        return true;
    }

    function setFeeCollector(address feeCollector_) public onlyOwner returns (bool) {
     require(feeCollector_ != address(0) , "Collector can't be null");
	 feeCollector = feeCollector_;
     return true;
    }




    function totalSupply() public override view returns (uint256) {
	    return totalSupply_;
    }
    
    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = sub(balances[msg.sender],numTokens);
        balances[receiver] = add(balances[receiver],numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint256 numTokens) public override returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner_, address delegate) public override view returns (uint) {
        return allowed[owner_][delegate];
    }

    function transferFrom(address owner_, address buyer, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[owner_]);    
        require(numTokens <= allowed[owner_][msg.sender]);
    
        balances[owner] = sub(balances[owner_],numTokens);
        allowed[owner_][msg.sender] = sub(allowed[owner_][msg.sender],numTokens);
        balances[buyer] = add(balances[buyer],numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }




     function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }


    function mul(uint256 a, uint256 b) public pure returns (uint256 ) {
        uint256 c = a * b;
        
        assert(a == 0 || c / a == b);
            return c;
    }

    function div(uint256 a, uint256 b) public pure returns (uint256 ) {
        assert(b > 0);
        uint256	c = a / b;
        return c;
    }
}