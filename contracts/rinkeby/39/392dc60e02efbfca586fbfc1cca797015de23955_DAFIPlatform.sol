/**
 *Submitted for verification at Etherscan.io on 2021-04-19
*/

// File: contracts\Ownable.sol

pragma solidity ^0.5.16;


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

interface IDAFI{
    function getdToken(string calldata _type, uint256 _balance, address _beneficiary) external;
    function rebase() external;
    function getDAFIToken(address _beneficiary) external view returns(uint256 USDValOfdLINK, uint256 USDValOfdBTC, uint256 USDValOfdETH, uint256 USDValOfdAAVE, uint256 totalAssetVal);
    function setdToken(string calldata _type, uint256 _baseLinePrice, IToken _address, IToken _mainAddress) external;
    function getdTokenDetails(bytes32 _type) external view returns(uint256 _currentPrice, uint256 _demandFactor, uint256 _oldPrice);
}

contract DAFIPlatform is Ownable{
    
    using SafeMath for uint256;
    
    IDAFI public DAFIContract;
    IData public dataContract;
    
    address payable public wallet;

    event DAFIContractChange(IDAFI oldAddress, IDAFI newAddress);
    
    constructor( IDAFI _DAFIContract, IData _dataContract, address payable _wallet) public Ownable(msg.sender){
        
        DAFIContract = _DAFIContract;
        dataContract = _dataContract;
        wallet = _wallet;
    }
    
    function getdToken(string memory _type, uint256 _balance) public payable {
        require (msg.value == 5000000000000000000,"Fee amount is not valid");
        DAFIContract.getdToken(_type,_balance,msg.sender);
        wallet.transfer(msg.value);
    } 
    
    function rebase() public onlyOwner{
        DAFIContract.rebase();
    }
    
    function getDAFIToken(address _beneficiary) public view returns(uint256 totalAssetVal, uint256 USDValOfdLINK, uint256 USDValOfdBTC, uint256 USDValOfdETH, uint256 USDValOfdAAVE, uint256 DAFIToken){
        (USDValOfdLINK, USDValOfdBTC, USDValOfdETH, USDValOfdAAVE, totalAssetVal) = DAFIContract.getDAFIToken(_beneficiary);
        DAFIToken = dataContract.userDAFIReward(_beneficiary);
    }
    
    function setdToken(string memory _type, uint256 _baseLinePrice, IToken _address, IToken _mainAddress) public onlyOwner {
        DAFIContract.setdToken(_type,_baseLinePrice,_address,_mainAddress);
    }
    
    function setDAFIContract(IDAFI _DAFIContract) public onlyOwner{
        emit DAFIContractChange(DAFIContract,_DAFIContract);
        DAFIContract = _DAFIContract;
    }
    
    function getdTokenDetails(bytes32 _type) public view returns(uint256 _currentPrice, uint256 _demandFactor, uint256 _oldPrice){
        (_currentPrice, _demandFactor, _oldPrice) = DAFIContract.getdTokenDetails(_type);
    }
    
    function getTokenSupplyHistory(bytes32 _type, address _beneficiary) public view returns(uint256 _day1, uint256 _day2, uint256 _day3, uint256 _day4, uint256 _day5){
        (_day1, _day2, _day3, _day4, _day5) = dataContract.getDemandFactorHistory(_type, _beneficiary);
    }
    
}