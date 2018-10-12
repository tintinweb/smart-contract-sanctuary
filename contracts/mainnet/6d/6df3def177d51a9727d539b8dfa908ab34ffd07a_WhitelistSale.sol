pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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

contract ERC20Constant {
    function balanceOf( address who ) view public returns (uint value);
}
contract ERC20Stateful {
    function transfer( address to, uint value) public returns (bool ok);
}
contract ERC20Events {
    event Transfer(address indexed from, address indexed to, uint value);
}
contract ERC20 is ERC20Constant, ERC20Stateful, ERC20Events {}

contract Owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner,"owner only");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

contract WhitelistSale is Owned {

    ERC20 public blocToken;

    uint256 public blocPerEth;
    
    bool running;

    mapping(address => bool) public whitelisted;

    mapping(address => uint256) public bought;
    
    mapping(address => uint256) public userLimitAmount;
    
    mapping(address => bool) public whitelistUserGettedBloc;
        
    mapping(address => bool) public whitelistUserGettedEthBack;
    
    uint256 rebackRate; // 0-10000
    uint256 constant MaxRate = 10000; 
    address public receiver;
    address[] private whitelistUsers;
    uint256 constant public maxGasPrice = 50000000000;

    event LogWithdrawal(uint256 _value);
    event LogBought(uint orderInMana);
    // event LogUserAdded(address user);
    event LogUserRemoved(address user);

    constructor(
        address _receiver
    ) public Owned()
    {
        blocToken;
        receiver         = _receiver;
        blocPerEth       = 0;
        whitelistUsers   = new address[](0);
        rebackRate       = 0;
        running          = true;
    }
    
    function getRebackRate() public view returns (uint256 rate) {
        return rebackRate;
    }
    
    function changePerEthToBlocNumber(uint256 _value)  public onlyOwner {
        require(_value > 0,"ratio must > 0");
        blocPerEth = _value;
    }
    
    function changeRebackRate(uint256 _rate)  public onlyOwner {
        require(_rate > 0,"refundrate must > 0");
        require(_rate < MaxRate,"refundrate must < 10000");
        rebackRate = _rate;
    }
    
    function changeBlocTokenAdress(ERC20 _tokenContractAddress)  public onlyOwner {
        blocToken = _tokenContractAddress;
    }
    
    function withdrawEth(uint256 _value)  public onlyOwner {
        require(receiver != address(0),"receiver not set");
        receiver.transfer(_value);
    }

    function withdrawBloc(uint256 _value)  public onlyOwner  returns (bool ok) {
        require(blocToken != address(0),"token contract not set");
        return withdrawToken(blocToken, _value);
    }

    function withdrawToken(address _token, uint256 _value) private onlyOwner  returns (bool ok) {
        bool result = ERC20(_token).transfer(owner,_value);
        if (result) emit LogWithdrawal(_value);
        return result;
    }

    function changeReceiver(address _receiver) public onlyOwner {
        require(_receiver != address(0),"empty receiver");
        receiver = _receiver;
    }
    
    function changeBlocPerEth(uint256 _value) public onlyOwner {
        require(_value != 0,"ratio should > 0");
        blocPerEth = _value;
    }
    
    function changeRuningState(bool _value) public onlyOwner {
        running = _value;
    }
    
    modifier onlyIsRuning {
        require(running,"KYC over");
        _;
    }

    function buy() private onlyIsRuning {
        require(whitelisted[msg.sender],"not whitelisted");
        require(whitelistUserGettedBloc[msg.sender] == false,"token already sent");
        require(msg.value >= 0.2 ether,"must greater or equal to 0.2 eth");

        uint256 allowedForSender = SafeMath.sub(userLimitAmount[msg.sender], bought[msg.sender]);
        if (msg.value > allowedForSender) revert("over limit amount");
        // receiver.transfer(msg.value);
        bought[msg.sender] = SafeMath.add(bought[msg.sender], msg.value);
    }
    
    function transferBlocToUser(address userAddress) public onlyOwner {
        require(rebackRate < MaxRate,"refundrate overflow");
        require(blocPerEth > 0,"token ratio not set");
        require(whitelistUserGettedBloc[userAddress] == false,"token already sent");
        require(bought[userAddress] > 0,"not bought");
             
        uint256 bountPerEth = SafeMath.mul( blocPerEth , (MaxRate - rebackRate));
        uint orderInBloc = SafeMath.mul(SafeMath.div(bought[userAddress],MaxRate),bountPerEth) ;
            
        uint256 balanceInBloc = blocToken.balanceOf(address(this));
        if (orderInBloc > balanceInBloc) revert("not enough token");
        if (blocToken.transfer(userAddress, orderInBloc)) whitelistUserGettedBloc[userAddress] = true;
    }
    
    function transferEthBackToUser(address userAddress) public onlyOwner {
        require(rebackRate > 0,"refundrate not set");
        require(whitelistUserGettedEthBack[userAddress] == false,"token already sent");
        require(bought[userAddress] > 0,"not bought");
             
        uint backEthNumber = SafeMath.mul(SafeMath.div(bought[userAddress],MaxRate),rebackRate) ;
        whitelistUserGettedEthBack[userAddress] = true;
        userAddress.transfer(backEthNumber);
    }
    

    function addUser(address user,uint amount) public onlyOwner onlyIsRuning {
        if (whitelisted[user] == true) {
            if (userLimitAmount[user] != amount) {
                userLimitAmount[user] = amount;
            }
            return;
        }
        
        whitelisted[user] = true;
        whitelistUsers.push(user);
        userLimitAmount[user] = amount;
        whitelistUserGettedBloc[user] = false;
        whitelistUserGettedEthBack[user] = false;
        // emit LogUserAdded(user);
    }

    function removeUser(address user) public onlyOwner onlyIsRuning {
        whitelisted[user] = false;
        emit LogUserRemoved(user);
    }

    function addManyUsers(address[] users,uint[] amounts) public onlyOwner onlyIsRuning {
        require(users.length < 10000,"list too long");
        require(users.length == amounts.length, "users&#39; length != amounts&#39; length");
        
        for (uint index = 0; index < users.length; index++) {
            addUser(users[index],amounts[index]);
        }
    }

    function() public payable onlyIsRuning {
        require(tx.gasprice <= maxGasPrice,"gas price must not greater than 50GWei");
        buy();
    }
    
    function getWhiteUsers() public view onlyOwner returns(address[] whitelistUsersResult) {
        return whitelistUsers;
    }


    function getWhiteUsersFrom(uint index, uint size) public view onlyOwner returns(address[] whitelistUsersResult) {
        address[] memory slice = new address[](size);
        uint idx = 0;
        for (uint i = index; idx < size && i < whitelistUsers.length; i++) {
            slice[idx] = whitelistUsers[i];
            idx++;
        }
        return slice;
    }
}