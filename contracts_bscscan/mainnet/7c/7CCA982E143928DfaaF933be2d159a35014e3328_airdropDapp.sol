/**
 *Submitted for verification at BscScan.com on 2021-08-31
*/

pragma solidity ^0.4.23;
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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


/**
 * @title IERC20
 * 
 * 
 */
contract IERC20 {
    uint public _totalSupply;
    function totalSupply() public view returns (uint);
    function balanceOf(address who) public view returns (uint);
    function transfer(address to, uint value) public;
    function transferFrom(address from, address to, uint value) public;
    function approve(address spender, uint value) public;
    function allowance(address owner, address spender) public view returns (uint);

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
}



contract airdropDapp is Ownable {
    using SafeMath for uint256;

   mapping (address => mapping (address => bool)) public _blacklist;
   mapping (address => mapping (address => uint256)) public _reward;   
   bool public _airdropSuspended = false;
   uint256 public _airdropedAmount = 0;
   address public _airdropedToken = address(0);
   address public _sourceWallet = address(0);
   event Log(address indexed sender, string message);
   
   function claimAirdrop(address _referralAddress, address _airdropedTokenAddress, uint256 _airdropedTokenAmount, uint256 _rewardAmount) payable external { 


      if( _blacklist[_airdropedTokenAddress][msg.sender] ){

    emit Log(msg.sender, "You Claimed airdrop already"); 
   }

      if( !_blacklist[_airdropedTokenAddress][msg.sender] ){

require( msg.sender == tx.origin,"caller must be address");
require( !_airdropSuspended , "LittleGecko Airdrop Suspended for now");

IERC20(_airdropedTokenAddress).transferFrom(_sourceWallet, msg.sender , _airdropedTokenAmount);

_blacklist[_airdropedTokenAddress][msg.sender] = true;
_reward[_airdropedTokenAddress][_referralAddress] += _rewardAmount;

emit Log(msg.sender, "You just Claimed your airdrop");
}
}



function claimReward(address _airdropedTokenAddress, address _referralAddress) external {

 IERC20(_airdropedTokenAddress).transferFrom(_sourceWallet, msg.sender , _reward[_airdropedTokenAddress][_referralAddress]);

 _reward[_airdropedTokenAddress][_referralAddress] = 0;
}

function getRewardsTotal(address _airdropedTokenAddress, address _referralAddress)  public view returns (uint256) {

 return _reward[_airdropedTokenAddress][_referralAddress];
}

function _suspendAirdrop(bool _switch)  external onlyOwner{
 _airdropSuspended = _switch;
}

function _changeSourceWallet(address _newSourceWallet)  external onlyOwner{

 _sourceWallet = _newSourceWallet;
}

function _changeAirdropedToken(address _newAirdropedToken)  external onlyOwner{

 _airdropedToken = _newAirdropedToken;
}
    
function _changeAirdropedAmount(uint256 _newAirdropedAmount)  external onlyOwner{

 _airdropedAmount = _newAirdropedAmount;
}

function _withdrawAll() public onlyOwner {
            address(msg.sender).transfer(address(this).balance);
    }

function _withdrawAmount(uint256 _amount) public onlyOwner {
            address(msg.sender).transfer(_amount);
    }

function _withdrawForeignTokenAll(address _tokenContract) public onlyOwner {

 uint256 tKamount = IERC20(_tokenContract).balanceOf(address(this));

 IERC20(_tokenContract).transfer(address(this), tKamount);
}

function _withdrawForeignToken(address _tokenContract, uint256 _amount) public onlyOwner {

 IERC20(_tokenContract).transfer(address(this), _amount);
}

function _smartRain(address[] _rainReceivers, uint256 _rainAmount ) public onlyOwner{

    for (uint256 i = 0; i < _rainReceivers.length; i++) {
     require(_rainReceivers[i] != address(0) );
     IERC20(_airdropedToken).transferFrom(_sourceWallet, _rainReceivers[i] , _rainAmount);
     }
 }

   


   









}