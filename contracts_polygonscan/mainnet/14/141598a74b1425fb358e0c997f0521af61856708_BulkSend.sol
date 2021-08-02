/**
 *Submitted for verification at polygonscan.com on 2021-08-01
*/

pragma solidity 0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

contract StandardToken {

    function transfer(address _to, uint256 _value) external returns (bool) ;
    
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    
    function approve(address spender, uint256 amount) external returns (bool);

    function allowance(address _owner, address _spender) external constant returns (uint256);
}

contract BulkSend {
    using SafeMath for uint256;
    
    address public owner;
    
    constructor() public payable{
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
      require(msg.sender == owner);
      _;
    }
    
    function getbalance(address addr) public constant returns (uint256 value){
        return addr.balance;
    }
    
    function deposit() payable public returns (bool){
        return true;
    }
    
    function withdrawEther(address addr, uint256 amount) public onlyOwner returns(bool success){
        addr.transfer(amount * 10 ** 12 wei);
        return true;
    }
    
    function withdrawToken(StandardToken tokenAddr, address _to, uint256 _amount) public onlyOwner returns(bool success){
        tokenAddr.transfer(_to, _amount * 10 ** 12 wei );
        return true;
    }
    
    function bulkSendEth(address[] addresses, uint256[] amounts) public payable returns(bool success){
        uint256 total = 0;
        for(uint8 i = 0; i < amounts.length; i++){
            total = total.add(amounts[i] * 10 ** 12 wei);
        }
        
        require(msg.value >= (total * 1 wei));
        
        //transfer to each address
        for (uint8 j = 0; j < addresses.length; j++) {
            addresses[j].transfer(amounts[j] * 10 ** 12 wei);
        }
        return true;
    }
    
    function bulkSendToken(StandardToken tokenAddr, address[] addresses, uint256[] amounts) public payable returns(bool success){
        uint256 total = 0;
        //address multisendContractAddress = this;
        for(uint8 i = 0; i < amounts.length; i++){
            total = total.add(amounts[i]);
        }
        
        // check if user has enough balance
        require(total <= tokenAddr.allowance(msg.sender, tokenAddr));
        
        // transfer token to addresses
        for (uint8 j = 0; j < addresses.length; j++) {
            tokenAddr.transferFrom(msg.sender, addresses[j], amounts[j] * 10 ** 12);
        }
        return true;
        
    }
    
    function bulkSendEthSameValue(address[] addresses, uint256 amount) public payable returns(bool success){
        uint256 total = 0;
        total = addresses.length * amount * 10 ** 12;
        
        require(msg.value >= (total * 1 wei));
        
        for (uint8 j = 0; j < addresses.length; j++) {
            addresses[j].transfer(amount * 10 ** 12 wei);
        }

        return true;
    }
    
    function bulkSendTokenSameValue(StandardToken tokenAddr, address[] addresses, uint256 amount) public payable returns(bool success){
        uint256 total = 0;
        total = addresses.length * amount * 10 ** 12;
        
        require(total <= tokenAddr.allowance(msg.sender, this));
        
        for (uint8 j = 0; j < addresses.length; j++) {
            tokenAddr.transferFrom(msg.sender, addresses[j], amount * 10 ** 12);
        }
        return true;
        
    }
    
    function destroy (address _to) public onlyOwner {
        selfdestruct(_to);
    }
}