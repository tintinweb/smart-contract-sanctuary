/**
 *Submitted for verification at BscScan.com on 2021-08-27
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.7;

interface BEP20 {

  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function getOwner() external view returns (address);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}



contract chartFrame{
    
    string public name = 'price frame contract';
    
    address public WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public lpToken;
    address public token;
    
    uint256 public expiry;
    uint8 public decimals;
    
    address public token0;
    address public token1;
    
    string public pair0 = 'ADA';
    string public pair1 = 'WBNB';
    
    constructor(
        address newToken, 
        address newLpToken, 
        uint256 newExpiry,
        uint8 newDecimals,
        address newToken0,
        address newToken1,
        string memory newPair0,
        string memory newPair1
        ){
        lpToken = newLpToken;
        token = newToken;
        expiry = newExpiry;
        decimals = newDecimals;
        token0 = newToken0;
        token1 = newToken1;
        pair0 = newPair0;
        pair1 = newPair1;
    }
    
    modifier onlyNotExpiry(){
        require(expiry > block.timestamp, 'expired CONTRACT');
        _;
    }
    
    function getTime() public view returns(uint256){
        return block.timestamp;
    }
    
    function getExpiry() public view returns(uint256){
        return expiry;
    }

    
    /*function getReserves() public onlyNotExpiry view returns(uint112, uint112, uint32){
        (uint112 token0v, uint112 token1v, uint32 time) =  IPancakePair(lpToken).getReserves();
        return (token0v, token1v, time);
    }*/
    
    function getPrice() public onlyNotExpiry view returns(uint256){
        (uint112 token0v, uint112 token1v, uint32 time) =  IPancakePair(lpToken).getReserves();
        uint256 liquidityToken;
        uint256 liquidityWBNB;
        uint256 price;
        
        if(address(token0) != WBNB){
            liquidityToken = token0v / (10**decimals);
            liquidityWBNB  = token1v / (10**18);
            price = liquidityToken / liquidityWBNB  ;
        } else{
            liquidityToken = token1v / (10**decimals);
            liquidityWBNB  = token0v / (10**18);
            price = liquidityToken / liquidityWBNB ;
        }
        
        return price * (10**18);
        
    }
    
}

contract Creator{

  address public owner;
  uint256 public rate;
  address[] public contracts;
  address factory = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
  address public WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
  mapping(address => user) users;
  
  struct user{
      address userContract;
  }
  
  modifier onlyOwner(){
      require(msg.sender == owner, 'ownable');
      _;
  }
  
  function setRate(uint256 newrate) public onlyOwner{
      rate = newrate;
  }
  
  event Deployed(address addr);
  
  function getUserContract(address thisUser) public view returns(address){
      return users[thisUser].userContract;
  }
  
  function getBytecode(address newToken, uint256 newExpiry,uint8 newDecimals) public pure returns (bytes memory) {
        bytes memory bytecode = type(chartFrame).creationCode;

        return abi.encodePacked(bytecode, abi.encode(newToken, newExpiry, newDecimals));
    }


  function getContractCount() 
    public
    view
    returns(uint contractCount)
  {
    return contracts.length;
  }
  
  
  function preview(address tokenAddress, address lpToken) public view returns(
      address,
      address,
      uint256,
      uint8,
      address, 
      address,
      string memory,
      string memory
      ){
          address thisToken = tokenAddress;
          address getLP = lpToken;//IPancakePair(factory).getPair(tokenAddress , WBNB);
          uint256 getExpiry = block.timestamp+86400;
          uint8 getDecimals = BEP20(tokenAddress).decimals();
          address getToken0 = IPancakePair(getLP).token0();
          address getToken1 = IPancakePair(getLP).token1();
          string memory getTokenSymbol = BEP20(getToken0).symbol();
          string memory getWBNBSymbol = BEP20(getToken1).symbol();
          return (thisToken, getLP, getExpiry, getDecimals, getToken0, getToken1, getTokenSymbol, getWBNBSymbol);
      
  }

  function newContract(address newToken,uint8 newDecimals)
    public

  {
    
    address addr;
    uint256 newExpiry = block.timestamp+86400;// (1*60*60*24);
    bytes memory bytecode = getBytecode(newToken, newExpiry, newDecimals);

    assembly {
            addr := create2(
                0, // wei sent with current call
                // Actual code starts after skipping the first 32 bytes
                add(bytecode, 32),
                mload(bytecode), // Load the size of code contained in the first 32 bytes
                newDecimals // Salt from function arguments
            )

            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        contracts.push(addr);
        users[msg.sender].userContract = addr;

        emit Deployed(addr); 
        
  }
  
}