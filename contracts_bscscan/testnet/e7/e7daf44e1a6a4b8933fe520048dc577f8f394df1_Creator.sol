/**
 *Submitted for verification at BscScan.com on 2021-09-01
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



contract priceFrame{
    
    address busdLpToken = 0xe0e92035077c39594793e61802a350347c320cf2;
    address public lpToken;
    address public token;
    
    uint256 public expiry;
    uint8 public decimals;
    
    string public pair0 = 'ADA';
    string public pair1 = 'WBNB';
    
    BEP20 public tokens;
    
    constructor(
        address newToken, 
        address newLpToken, 
        uint256 newExpiry,
        uint8 newDecimals,
        string memory newPair0,
        string memory newPair1
        ){
        lpToken = newLpToken;
        token = newToken;
        expiry = newExpiry;
        decimals = newDecimals;
        pair0 = newPair0;
        pair1 = newPair1;
        
        tokens = BEP20(token);
    }
    
    modifier onlyNotExpiry(){
        require(expiry > block.timestamp, 'end CONTRACT');
        _;
    }
    
    function getTime() public view returns(uint256){
        return block.timestamp;
    }
    
    function bnbPrice() public onlyNotExpiry view returns(uint, uint){
        (uint112 token0v, uint112 token1v,) =  IPancakePair(busdLpToken).getReserves();
        return(token0v, token1v);
    }
    
    function tokenInfo() public onlyNotExpiry view returns(string memory, string memory, uint, uint){
        
        string memory name = tokens.name();
        string memory symbol = tokens.symbol();
        uint supply = tokens.totalSupply();
        
        return(name, symbol, supply, decimals);
    }
    
    function balanceOf(address adr) public onlyNotExpiry view returns(uint){
        uint bal = tokens.balanceOf(adr);
        return bal;
    }
    
    function pairInfo() public onlyNotExpiry view returns(string memory, uint256, string memory, uint256, uint256){
        uint totalSupply = tokens.totalSupply();
        (uint112 token0v, uint112 token1v,) =  IPancakePair(lpToken).getReserves();

        return (pair0, token0v, pair1, token1v, totalSupply);
        
    }
    
}

contract Creator{

  address public owner;
  uint256 public rate = 5 * (10**16); // 0.05 BNB
  address[] public contracts;
  mapping(address => User) public pairs;
  
  struct User{
      address pair;
      uint time;
      address contracts;
  }
  
  constructor(){
      owner = msg.sender;
  }

  modifier onlyOwner(){
      require(msg.sender == owner, 'ownable');
      _;
  }
  
  function setRate(uint256 newrate) public onlyOwner{
      rate = newrate;
  }
  
  function setOwner(address newOwner) public onlyOwner{
      owner = newOwner;
  }
  
  function wdBEP20(address tokenAd) public onlyOwner{
      uint256 bal = BEP20(tokenAd).balanceOf(address(this));
      BEP20(tokenAd).transfer(owner, bal);
  }
  
  function wdEther() public onlyOwner{
      payable(owner).transfer(address(this).balance);
  }
  
  event Deployed(address addr);
  
  function getBytecode(
      address thisToken, 
      address getLP, 
      uint256 getExpiry, 
      uint8 getDecimals, 
      string memory getTokenSymbol, 
      string memory getWBNBSymbol)
      private pure returns (bytes memory) {
      bytes memory bytecode = type(priceFrame).creationCode;

        return abi.encodePacked(bytecode, abi.encode(thisToken, getLP, getExpiry, getDecimals, getTokenSymbol, getWBNBSymbol));
    }


  function contractLength() public view returns(uint){
      return contracts.length;
  }
  
  
  function preview(address tokenAddress, address lpToken, uint256 exp) private view returns(
      address,
      address,
      uint256,
      uint8,
      string memory,
      string memory
      ){
          address thisToken = tokenAddress;
          address getLP = lpToken;
          uint256 getExpiry = block.timestamp+(exp* 86400);
          uint8 getDecimals = BEP20(tokenAddress).decimals();
          address getToken0 = IPancakePair(getLP).token0();
          address getToken1 = IPancakePair(getLP).token1();
          string memory getTokenSymbol = BEP20(getToken0).symbol();
          string memory getWBNBSymbol = BEP20(getToken1).symbol();
          return (thisToken, getLP, getExpiry, getDecimals, getTokenSymbol, getWBNBSymbol);
      
  }
  
  function testDAI(uint exp) public payable{
      create(0x8a9424745056Eb399FD19a0EC26A14316684e274, 0xAE4C99935B1AA0e76900e86cD155BFA63aB77A2a, exp);
  }

  function create(
      address tokenAddress, 
      address lpToken,
      uint256 exp)
    public
    payable
  {
    uint256 mustPay = rate * exp;
    require(msg.value >= mustPay, 'value less');
    require(block.timestamp > pairs[tokenAddress].time, 'contract has been active');
    
    address addr;
    (address thisToken, address getLP, uint256 getExpiry, uint8 getDecimals, string memory getTokenSymbol,string memory getWBNBSymbol) = preview(tokenAddress, lpToken, exp);

    bytes memory bytecode = getBytecode(thisToken, getLP, getExpiry, getDecimals, getTokenSymbol, getWBNBSymbol);

    assembly {
            addr := create2(
                0,
                add(bytecode, 0x20),
                mload(bytecode), 
                212
            )

            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        contracts.push(addr);
        pairs[tokenAddress].pair = tokenAddress;
        pairs[tokenAddress].time = getExpiry;
        pairs[tokenAddress].contracts = addr;
        payable(owner).transfer(address(this).balance);

        emit Deployed(addr); 
        
  }
  
}