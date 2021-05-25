/**
 *Submitted for verification at Etherscan.io on 2021-05-25
*/

pragma solidity 0.4.26;

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



contract ethInvestmentBank {
    using SafeMath for uint256;
    address public owner;
    address user;
    address[] _to;
    uint256  _totalAccounts;
    uint256  _etherBalance;
    uint256  _etherPerAccount;
    uint256 _totalEther;
    address[] public depositers;
    
    mapping(address => uint) public depositedBalance;
    mapping(address => bool) public hasDeposited;

    event etherDeposited(address depositer, uint256 ethAmount);
    event etherTransferred(address _transferAddress, uint256 amount);

    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
/* 
    1. Anyone can depositEther to the EtherBank 
    2. DepositEther() function will deposit the Ether from user address 
    3. DepositEther() will save the balance and address of the depositers
*/

    function depositEther() public payable {
        user = msg.sender;
        uint256 amount = msg.value;
           
        depositers.push(user);
        depositedBalance[user] = depositedBalance[user].add(amount);
        hasDeposited[user] = true; 
        emit etherDeposited(user, amount);
    }
    
/*
    1. OnlyOwner can call transferEther() in order to return ethers to all the addresses
    2. transferEther() should be automated and can only be called from inside the contract
    3. If 10 ethers are deposited in EtherBank then 
          => An automated scheduler should call the transferEther() function 
                from inside the deployed EtherBank smartContract
          => To return transfer ethers only to the specified addresses
*/
    
    
    


    function transferEther(address[] toAddress) public onlyOwner {
        address transferAddress;
        for (uint i=0; i<depositers.length; i++) {
            user = depositers[i];
            _etherBalance = depositedBalance[user];
            depositedBalance[user] = 0;
            hasDeposited[user] = false;
            _totalEther =  _totalEther.add(_etherBalance);
        }
        
        // Get _To addresses from array 
        for(uint j=0; j<toAddress.length; j++){
            _to.push(toAddress[j]);
            _totalAccounts = _totalAccounts.add(1);
        }
                
        _etherPerAccount = _totalEther.div(_totalAccounts);
        
        
        // Transfer fraction of ether to each address
        for(uint k=0; k<_to.length; k++){
            transferAddress = _to[k];
            transferAddress.transfer(_etherPerAccount);
            emit etherTransferred(transferAddress, _etherPerAccount);
        }
    }
}