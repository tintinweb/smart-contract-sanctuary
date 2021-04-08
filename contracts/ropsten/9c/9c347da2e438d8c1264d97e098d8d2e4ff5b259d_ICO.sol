/**
 *Submitted for verification at Etherscan.io on 2021-04-08
*/

pragma solidity 0.5.0;


/**
 * token contract functions
*/
contract Ierc20 {
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }

  function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
    uint256 c = add(a,m);
    uint256 d = sub(c,1);
    return mul(div(d,m),m);
  }
}

contract Owned {
        address public owner;
        event OwnerChanges(address newOwner);
        
        constructor() public {
            owner = msg.sender;
        }

        modifier onlyOwner {
            require(msg.sender == owner);
            _;
        }

        function transferOwnership(address newOwner) onlyOwner external {
            require(newOwner != address(0), "New owner is the zero address");
            owner = newOwner;
            emit OwnerChanges(newOwner);
        }
}

contract ICO is Owned {
    using SafeMath for uint256;
    
    Ierc20 public usdt;
    uint256 public dataId;
    uint256 public maxDepositLimit;
    mapping(address => bool) public whiteListAddress;
    mapping (uint256 => address) public walletById;
    
    mapping (address => uint256) public tokenBalance;
    event Transferred(address user, uint256 amount);
    event OwnerGetFunds(uint256 amount);
    
    /**
     * Constrctor function
    */
    constructor() public {
        usdt = Ierc20(0x8CfDaeb56Ebb87229d311109Cf02Be3aAE57eb3C);
        maxDepositLimit = 100000000000000000000;
    }
    
    /**
     * The function to send token into contract
    */
    function deposit(uint256 _amount) external {
        require(whiteListAddress[msg.sender], "only whitelist address allowed");
        require(_amount > 0, "amount cannot be zero");
        require(maxDepositLimit >= tokenBalance[msg.sender].add(_amount), "max deposit limit exceeds");
        //add data
        if (tokenBalance[msg.sender] == 0) {
            walletById[dataId] = msg.sender;
            dataId++;
        }
        
        tokenBalance[msg.sender] = tokenBalance[msg.sender].add(_amount);
        usdt.transferFrom(msg.sender, address(this), _amount);
        emit Transferred(msg.sender, _amount);
    }
    
    //get latest id
    function getCurrentId() external view returns (uint256 _id) {
        return dataId;
    }
    
    //get balance by address
    function getBalanceByAddress(address _address) external view returns (uint256 _balance) {
        return tokenBalance[_address];
    }
    
    //get address by id
    function getAddressById(uint256 _id) external view returns (address _walletAddress) {
        return walletById[_id];
    }
    
    //get token address
    function getTokenAddress() external view returns (address _usdtAddress) {
        return address(usdt);
    }
    
    //set token address
    function setTokenAddress(address _address) external onlyOwner {
        usdt = Ierc20(_address);
    }
    
    //set max deposit limit
    function setMaxDepositLimit(uint256 _maxLimit) external onlyOwner {
        maxDepositLimit = _maxLimit;
    }
    
    //set white list single address
    function setWhiteListAddress(address _userAddress, bool _whiteList) external onlyOwner {
        whiteListAddress[_userAddress] = _whiteList;
    }
    
    //set multiple white list addresses
    function setMultipleWhitelistAddresses(address[] memory _userAddresses) public onlyOwner {
        require(_userAddresses.length > 0, "No address passed");
        for (uint256 i=0; i < _userAddresses.length; i++ ) {
            whiteListAddress[_userAddresses[i]] = true;
        }
    }
    
    //owner get funds
    function ownerGetFunds(uint256 _amount) external onlyOwner {
        require(_amount > 0, "amount cannot be zero");
        require(usdt.balanceOf(address(this)) >= _amount, "not enough balance");
        
        usdt.transfer(msg.sender, _amount);
        emit OwnerGetFunds(_amount);
    }
    
}