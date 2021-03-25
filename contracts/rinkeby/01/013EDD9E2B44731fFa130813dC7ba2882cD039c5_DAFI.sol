/**
 *Submitted for verification at Etherscan.io on 2021-03-25
*/

// File: contracts\SafeMath.sol

pragma solidity ^0.5.16;


library SafeMath {

  
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
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
}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  
  constructor (address _owner) public {
    require(_owner != address(0));
    owner = _owner;
  }

  
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0),"invalid address");
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

interface IToken {
    function mint(uint256 _value, address _beneficiary) external;
    function balanceOf(address _owner) external view returns (uint256 balance);
    function rebase(uint256 newSupply) external;
}

interface IData{
    function isTokenMinted(address _beneficiary, bytes32 _type) external view returns(bool);
    function setIfTokenMinted(address _beneficiary, bytes32 _type) external;
    function updateDemandFactorHistory(bytes32 _type, uint256 _supply, uint256 _time) external;
    function getDemandFactorHistory(bytes32 _type, address _beneficiary) external view returns(uint256 _day1, uint256 _day2, uint256 _day3, uint256 _day4, uint256 _day5);
    function userReward(address _address) external;
    function userDAFIReward(address _address) external view returns(uint256);
    function userRewardGiven(address _address) external view returns(bool);
    function userCount() external view returns(uint256 _count);
}

interface IPriceConsumerV3{
    function getLatestPrice(bytes32 _synth) external returns (int);
}

interface IoffTokens{
    function balanceOf(address _owner) external view returns (uint256);
}

contract DAFI is Ownable{
    
    using SafeMath for uint256;
    
    IPriceConsumerV3 public price;
    IToken public platformToken;
    IoffTokens public offToken;
    IData public dataContract;
    
    address public DAFIPlatformContract;
    
    bytes32 public dLINK;
    bytes32 public dBTC;
    bytes32 public dETH;
    bytes32 public dSNX;
    
    mapping (bytes32 => dToken) public dTokenDetails;
    
    struct dToken{
        bool minted;
        uint256 baseLinePrice;
        uint256 currentPrice;
        uint256 oldPrice;
        uint256 demandFactor;
        IoffTokens mainAddress;
        IToken tokenAddress;
    }
    
    modifier onlyDAFIPlatform{
        require(msg.sender == DAFIPlatformContract, "Not Authorized address");
        _;
    }
    
    constructor(IPriceConsumerV3 _price, IData _dataContract,IToken _dBTC, IoffTokens dBTCmain, IToken _dETH, IoffTokens dETHmain, IToken _dLINK, IoffTokens dLINKmain, IToken _dSNX, IoffTokens dSNXmain) public Ownable(msg.sender){
        
        price = _price;
        dataContract  =_dataContract;
        
        setBytes32Code();

        dTokenDetails[dBTC].baseLinePrice = 100000000000000000000000;
        dTokenDetails[dBTC].currentPrice = (uint256(price.getLatestPrice(dBTC))).mul(10000000000);
        dTokenDetails[dBTC].tokenAddress = _dBTC;
        dTokenDetails[dBTC].mainAddress = dBTCmain;

        dTokenDetails[dETH].baseLinePrice = 5000000000000000000000;
        dTokenDetails[dETH].currentPrice = (uint256(price.getLatestPrice(dETH))).mul(10000000000);
        dTokenDetails[dETH].tokenAddress = _dETH;
        dTokenDetails[dETH].mainAddress = dETHmain;

        dTokenDetails[dLINK].baseLinePrice = 75000000000000000000;
        dTokenDetails[dLINK].currentPrice = (uint256(price.getLatestPrice(dLINK))).mul(10000000000);
        dTokenDetails[dLINK].tokenAddress = _dLINK;
        dTokenDetails[dLINK].mainAddress = dLINKmain;

        dTokenDetails[dSNX].baseLinePrice = 100000000000000000000;
        dTokenDetails[dSNX].currentPrice = (uint256(price.getLatestPrice(dSNX))).mul(10000000000);
        dTokenDetails[dSNX].tokenAddress = _dSNX;
        dTokenDetails[dSNX].mainAddress = dSNXmain;
        
    }
    
    function getdToken(string calldata _type, uint256 _balance, address _beneficiary) external onlyDAFIPlatform{
        
        bytes32 __type = stringToBytes32(_type);

        require (dataContract.isTokenMinted(_beneficiary,__type) == false,"Already Minted! Not allowed to mint again");
        
        platformToken = dTokenDetails[__type].tokenAddress;
        
        if(__type == dETH){
            require (_balance <= _beneficiary.balance,"Not enough balance");
            dataContract.setIfTokenMinted(_beneficiary,__type);
        }
        else if (__type == dLINK){
            offToken = dTokenDetails[__type].mainAddress;
            require (_balance <= offToken.balanceOf(_beneficiary),"Not enough balance");
            dataContract.setIfTokenMinted(_beneficiary,__type);
            
        }
        else if (__type == dBTC){
            offToken = dTokenDetails[__type].mainAddress;
            require (_balance <= offToken.balanceOf(_beneficiary).mul(10000000000),"Not enough balance");
            dataContract.setIfTokenMinted(_beneficiary,__type);
        }
        else if (__type == dSNX){
            offToken = dTokenDetails[__type].mainAddress;
            require (_balance <= offToken.balanceOf(_beneficiary),"Not enough balance");
            dataContract.setIfTokenMinted(_beneficiary,__type);
        }
        
        if (dataContract.userRewardGiven(_beneficiary) == false){
            dataContract.userReward(_beneficiary);
        }
        
        if (dTokenDetails[__type].demandFactor == 0){
            dTokenDetails[__type].currentPrice = (uint256(price.getLatestPrice(__type))).mul(10000000000);
            dTokenDetails[__type].demandFactor = (dTokenDetails[__type].currentPrice.mul(1 ether)).div(dTokenDetails[__type].baseLinePrice);
            dTokenDetails[__type].minted = true;
            platformToken.rebase(dTokenDetails[__type].demandFactor);
        }
        
        platformToken.mint(_balance,_beneficiary);
        
    }
    
    function rebase() external onlyDAFIPlatform{

        startRebase(dLINK);
        
        startRebase(dBTC);
        
        startRebase(dETH);
        
        startRebase(dSNX);
        
    }
    
    function startRebase(bytes32 _type) internal {
        if (dTokenDetails[_type].minted){
            
            uint256 newPrice = (uint256(price.getLatestPrice(_type))).mul(10000000000);
            
            if (newPrice != dTokenDetails[_type].currentPrice){

                dTokenDetails[_type].oldPrice = dTokenDetails[_type].currentPrice;
                
                dTokenDetails[_type].currentPrice = newPrice;
                platformToken = dTokenDetails[_type].tokenAddress;
                
                uint256 demandFactor = ((dTokenDetails[_type].currentPrice).mul(1 ether)).div(dTokenDetails[_type].baseLinePrice);
                
                dataContract.updateDemandFactorHistory(_type,dTokenDetails[_type].demandFactor,uint256(now));
                
                platformToken.rebase(demandFactor);

                dTokenDetails[_type].demandFactor = demandFactor;
            }
            else {
                dataContract.updateDemandFactorHistory(_type,dTokenDetails[_type].demandFactor,uint256(now));
            }
        }
    }
    
    function getDAFIToken(address _beneficiary) external view returns(uint256 USDValOfdLINK, uint256 USDValOfdBTC, uint256 USDValOfdETH, uint256 USDValOfdSNX, uint256 totalAssetVal) {
        
        IToken platformToken_1 = dTokenDetails[dLINK].tokenAddress;
        if (platformToken_1.balanceOf(_beneficiary) > 0){
            USDValOfdLINK = (platformToken_1.balanceOf(_beneficiary).mul(dTokenDetails[dLINK].currentPrice)).div(1 ether);
        }
        
        
        IToken platformToken_2 = dTokenDetails[dBTC].tokenAddress;
        if(platformToken_2.balanceOf(_beneficiary) > 0){
            USDValOfdBTC = (platformToken_2.balanceOf(_beneficiary).mul(dTokenDetails[dBTC].currentPrice)).div(1 ether);
        }
        
        
        IToken platformToken_3 = dTokenDetails[dETH].tokenAddress;
        if (platformToken_3.balanceOf(_beneficiary) > 0){
            USDValOfdETH = (platformToken_3.balanceOf(_beneficiary).mul(dTokenDetails[dETH].currentPrice)).div(1 ether);
        }
        
        IToken platformToken_4 = dTokenDetails[dSNX].tokenAddress;
        if (platformToken_4.balanceOf(_beneficiary) > 0){
            USDValOfdSNX = (platformToken_4.balanceOf(_beneficiary).mul(dTokenDetails[dSNX].currentPrice)).div(1 ether);
        }
        
        totalAssetVal = ((USDValOfdLINK.add(USDValOfdBTC)).add(USDValOfdETH)).add(USDValOfdSNX);
    }
    
    function setdToken(string calldata _type, uint256 _baseLinePrice, IToken _address, IoffTokens _mainAddress) external onlyDAFIPlatform{
        bytes32 __type = stringToBytes32(_type);
        dTokenDetails[__type].baseLinePrice = _baseLinePrice;
        dTokenDetails[__type].currentPrice = (uint256(price.getLatestPrice(__type))).mul(10000000000);
        dTokenDetails[__type].tokenAddress = _address;
        dTokenDetails[__type].mainAddress = _mainAddress;
    }
    
    function setBytes32Code() internal{
        dLINK = stringToBytes32("dLINK");
        dBTC = stringToBytes32("dBTC");
        dETH = stringToBytes32("dETH");
        dSNX = stringToBytes32("dSNX");
    }
    
    function setDAFIPlatformContract(address _address) public onlyOwner {
        require(_address != address(0),"invalid address");
        DAFIPlatformContract = _address;
    }
    
    function getdTokenDetails(bytes32 _type) external view returns(uint256 _currentPrice, uint256 _demandFactor, uint256 _oldPrice){
        _currentPrice = dTokenDetails[_type].currentPrice;
        _demandFactor = dTokenDetails[_type].demandFactor;
        _oldPrice = dTokenDetails[_type].oldPrice;
    }
    
    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
    
        assembly {
            result := mload(add(source, 32))
        }
        
    }
}