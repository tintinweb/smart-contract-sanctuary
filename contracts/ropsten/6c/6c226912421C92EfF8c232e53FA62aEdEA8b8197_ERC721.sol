/**
 *Submitted for verification at Etherscan.io on 2021-05-18
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a,uint256 b, string memory errorMessage ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a,uint256 b,string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a,uint256 b,string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    modifier validAddress(address addr) {
    require(addr != address(0), "Address cannot be 0x0");
    require(addr != address(this), "Address cannot be contract address");
    _;
    }
    constructor() public{
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

   
    function transferOwnership(address newOwner) public virtual onlyOwner validAddress(newOwner) {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ERC721 is Ownable
{
      using SafeMath for uint256;
    string public name = "APE NFT";
    string public symbol = "APEN";
    mapping (uint256 => address) _tokenOwner; //id>owner
    mapping (address => uint256) private _ownedTokensCount; //address>count
    
    
    function balanceOf(address _owner) external  view returns (uint256){
         return _ownedTokensCount[_owner];
    }
    function mint(address _owner,uint256 _id) external {
        require(msg.sender == _calleraddress,"Invalid caller");
        require(_owner != address(0),"Invalid  address" );
        _ownedTokensCount[_owner] = _ownedTokensCount[_owner].add(1);
        _tokenOwner[_id] = _owner;
        transferFrom(address(0),_owner,_id);
    }
    
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    function transferFrom(address _from, address _to, uint256 _tokenId) public  {
         require(msg.sender == _calleraddress,"Invalid caller");
        _ownedTokensCount[_to] += _ownedTokensCount[_from];
        _ownedTokensCount[_from] = 0;
        _tokenOwner[_tokenId] = _to;
        emit Transfer(_from,_to,_tokenId);
    }
    address _calleraddress;
    function setCallerAddress(address _address) external onlyOwner
    {
        _calleraddress = _address;
    }
    
  
}

contract Vesting is Ownable {

    
     using SafeMath for uint256;
     
    //----------------ERC20----------------------//
    mapping(address => uint256) balances;
    string public name = "APE SAFT";
    string public symbol = "APE";
    uint256 public _decimals = 18;
    
    function decimals() external view  returns (uint256)
    {
         return _decimals;
    }
    uint256 public _totalSupply = 10000000 * 10**18;
    function totalSupply() public view  returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view  returns (uint256) {
        return balances[account];
    }
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    function transfer(address to, uint tokens) public returns (bool success)
    {
       
       //balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(address(this), to, tokens);
        return true;
    }
    //-----------------------ERC721-------------------//

    // ERC721 NFT;
   
    
    // constructor(address _nft) public{
    //   NFT = ERC721(_nft);
    // }
    
   // address NFTToken;
    ERC721 erc721; 
    constructor(address _address) public
    {
        erc721 = ERC721(_address);
    }
    //-----------------Vesting Code----------------//
    mapping(address => uint256) idAddress; //id > address
    
    mapping (uint256 => uint256) private _released; // id > amount
    mapping (uint256 => uint256) private totalTokenAllocataed; // id > totalAmount
    uint256 basePrice = 1000000000000000; // 1000000000000000 wei(0.001 ether) = 1 Token
    mapping (uint256 => uint256) public lastRedemmedTimeStamp; // id > timestamp
  
    
    event TokensReleased(address token, uint256 amount);
   
    uint256 lockInPeriod = 5; // in minutes
    uint256 _saleStatus = 0; //0= not started , 1 = started. 2 = finished;
   
    uint256 public startTime;
    uint256 userID = 1;
    function startSale() external onlyOwner
    {
       _saleStatus = 1;
    }
    function stopSale() external onlyOwner
    {
        _saleStatus = 2;
        startTime = block.timestamp;
    }
    
    function takeStake() external payable saleStatus  // 1000000000000000 wei(0.001 ether) = 1 Token
    {
        uint256 token = (msg.value.mul(10**18)/basePrice);
        if (idAddress[msg.sender] > 0)
        {
            totalTokenAllocataed[idAddress[msg.sender]] = totalTokenAllocataed[idAddress[msg.sender]].add(token);
            erc721.mint(msg.sender,userID);
        }
        else
        {
            idAddress[msg.sender] = userID;
            totalTokenAllocataed[userID] = totalTokenAllocataed[userID].add(token);
            erc721.mint(msg.sender,userID);
            userID++;
        }
        
        
            
    }
    
  
    event Step(uint256 amount,uint256 step);
    event TimeStamo(uint256 amount,uint256 step);
    function realaseToken() external 
    {
      
      require(_saleStatus == 2,"Sale is not finished yet");
      require(idAddress[msg.sender] != 0,"user dosenot exist");
      require(totalTokenAllocataed[idAddress[msg.sender]].sub(_released[idAddress[msg.sender]]) > 0,"Insufficien Fund");
      // require(totalTokenAllocataed[idAddress[msg.sender]] > 0,"Insufficien Fund");
       uint256 diff = block.timestamp - startTime;
      require(diff >= 2 minutes,"Invalid time difference");
      
       
       
      if (lastRedemmedTimeStamp[idAddress[msg.sender]] == 0)
      {
          //((1620899940-1620896540)/60)/5
          uint256 releasedTime = ((block.timestamp.sub(startTime)).div(60)).div(2);
            
          uint256 token = ((totalTokenAllocataed[idAddress[msg.sender]].mul(10)).div(100)).mul(releasedTime);
           
          transfer(msg.sender,token);
          _released[idAddress[msg.sender]] = _released[idAddress[msg.sender]].add(token);
           emit Step(startTime.add(releasedTime * 60),3);
           if (releasedTime == 1)
           {
               lastRedemmedTimeStamp[idAddress[msg.sender]] = startTime.add((releasedTime*2) * 60);
           }
          
      }
      else
      {
          emit TimeStamo(block.timestamp,lastRedemmedTimeStamp[idAddress[msg.sender]].add(2 minutes));
          require(block.timestamp >= (lastRedemmedTimeStamp[idAddress[msg.sender]].add(2 minutes)) ,"Try after sometime");
           uint256 releasedTime = ((block.timestamp.sub(lastRedemmedTimeStamp[idAddress[msg.sender]])).div(60)).div(2);
           emit Step(releasedTime,1);
          uint256 token = ((totalTokenAllocataed[idAddress[msg.sender]].mul(10)).div(100)).mul(releasedTime);
           emit Step(token,2);
          transfer(msg.sender,token);
          _released[idAddress[msg.sender]] = _released[idAddress[msg.sender]].add(token);
          lastRedemmedTimeStamp[idAddress[msg.sender]] = (lastRedemmedTimeStamp[idAddress[msg.sender]].add((releasedTime*2).mul(60)));
      }
    }
    
    event TranferStakeOwner(address from, address to);
    function transStakeferOwnerShip(address _address) external
    {
        
        require(idAddress[msg.sender] != 0,'Invalid transaction');
        idAddress[_address] = idAddress[msg.sender];
        erc721.transferFrom(msg.sender,_address,idAddress[_address]);
        idAddress[msg.sender] = 0;
    }
    function contractEther() external view returns(uint256)
    {
        return address(this).balance;
    }
    
    function duration() public view returns (uint256) {
         return lockInPeriod;
    }
    
    function getlastRedemmedTimeStamp(address token) public view returns (uint256) {
        return lastRedemmedTimeStamp[idAddress[token]];
    }
    function released(address token) public view returns (uint256) {
        return _released[idAddress[token]];
    }
    function totalRelasePending(uint256 _id) public view  returns(uint256)
    {
        return totalTokenAllocataed[_id] - _released[_id];
    }
    function totalToken(address token) public view returns (uint256) {
        return totalTokenAllocataed[idAddress[token]];
    }
    function getIDFromAddres() external view returns(uint256)
    {
        return idAddress[msg.sender];
    }
    
    modifier saleStatus()
    {
        require(_saleStatus == 1,"Sale is off");
        _;
    }
}