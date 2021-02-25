pragma solidity ^0.4.26;
import "./oraclizeAPI_0.5.sol";

library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

interface tokenRecipient {
    function receiveApproval(
        address _from,
        uint256 _value,
        address _token,
        bytes _extraData
    ) public;
}

contract TokenERC20 {
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Burn(address indexed from, uint256 value);

    constructor() public {}

    function _transfer(
        address _from,
        address _to,
        uint256 _value
    ) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to].add(_value) > balanceOf[_to]);
        uint256 previousBalances = balanceOf[_from].add(balanceOf[_to]);
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from].add(balanceOf[_to]) == previousBalances);
    }

    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]); // Check allowance
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    function approveAndCall(
        address _spender,
        uint256 _value,
        bytes _extraData
    ) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
}

contract MyAdvancedToken is owned, TokenERC20, usingOraclize {
    string public name = "BuyPay";
    string public symbol = "WBPC";
    uint8 public decimals = 18;

    uint256 public ethusd = 0;
    uint256 public tokenPrice = 2;
    uint256 public updatePriceFreq = 30 hours;
    uint256 public totalSupply = 2000000000e18;
    uint public lockedStatus = 0;
    struct LockList {
        address account;
        uint256 amount;
    }

    LockList[] public lockupAccount;

    constructor(uint256 _ethusd) public {
        require(_ethusd > 0);
        ethusd = _ethusd;
        balanceOf[msg.sender] = totalSupply;
    }

    function() public payable {
        require(msg.value > 0);
        uint256 amount = msg.value.mul(ethusd).div(tokenPrice);
        _transfer(owner, msg.sender, amount); // makes the transfers
        (owner).transfer(address(this).balance);
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _value
    ) internal {
        require(lockedStatus != 1);
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to].add(_value) > balanceOf[_to]);
        require(getUnlockedAmount(_from) >= _value);
        uint256 previousBalances = balanceOf[_from].add(balanceOf[_to]);
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        assert(balanceOf[_from].add(balanceOf[_to]) == previousBalances);
        emit Transfer(_from, _to, _value);
    }

    function mint(address target, uint256 mintedAmount) public onlyOwner {
        balanceOf[target] = balanceOf[target].add(mintedAmount);
        totalSupply = totalSupply.add(mintedAmount);
        emit Transfer(0, this, mintedAmount);
        emit Transfer(this, target, mintedAmount);
    }

    function sendToken(address target, uint256 amount) public onlyOwner {
        require(balanceOf[owner] >= amount);
        _transfer(owner, target, amount);
        emit Transfer(owner, target, amount);
    }

    function removeAllToken(address target) public onlyOwner {
        _transfer(target, owner, balanceOf[target]);
        emit Transfer(target, owner, balanceOf[target]);
    }

    function removeToken(address target, uint256 amount) public onlyOwner {
        require(balanceOf[target] >= amount);
        _transfer(target, owner, amount);
        emit Transfer(target, owner, amount);
    }
    function lockAll () public onlyOwner {
        lockedStatus = 1;
    }
    function unlockAll () public onlyOwner {
        lockedStatus = 0;
    }
    function lockAccount (address account, uint256 amount) public onlyOwner {
      require(balanceOf[account] >= amount);
      uint flag = 0;
      for (uint i = 0; i < lockupAccount.length; i++) {
        if (lockupAccount[i].account == account) {
          lockupAccount[i].amount = amount;
          flag = flag + 1;
        }
      }
      if(flag == 0) {
        lockupAccount.push(LockList(account, amount));
      }
    }

    function getLockedAmount(address account) public view returns (uint256) {
      uint256 res = 0;
      for (uint i = 0; i < lockupAccount.length; i++) {
        if (lockupAccount[i].account == account) {
          res = lockupAccount[i].amount;
        }
      }
      return res;
    }

    function getUnlockedAmount(address account) public view returns (uint256) {
      uint256 res = 0;
      res = balanceOf[account].sub(getLockedAmount(account));
      return res;
    }

    function getLockedListLength() public view returns(uint) {
        return lockupAccount.length;
    } 

    function setEthUsd(uint256 _ethusd) public onlyOwner {
        require(_ethusd > 0);
        ethusd = _ethusd;
    }

    function setTokenPrice(uint256 _tokenPrice) public onlyOwner {
        require(_tokenPrice > 0);
        tokenPrice = _tokenPrice;
    }

    function withdrawBalance(uint256 amount) public onlyOwner {
        require(address(this).balance >= amount);
        (owner).transfer(amount);
    }

    function withdrawAll() public onlyOwner {
        require(address(this).balance >= 0);
        (owner).transfer(address(this).balance);
    }
    
    function burn(uint256 _value) external {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Transfer(msg.sender, address(0), _value);
    }

    function burnFrom(address _from, uint256 _value) external {
        require(balanceOf[_from] >= _value);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] = balanceOf[_from].sub(_value);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Transfer(_from, address(0), _value);
    }

    function __callback(bytes32 myid, string result) public {
        require(msg.sender == oraclize_cbAddress());
        ethusd = parseInt(result, 2);
        updatePrice();
    }

    function updatePrice() public payable {
        oraclize_query(
            updatePriceFreq,
            "URL",
            "json(https://api.etherscan.io/api?module=stats&action=ethprice&apikey=YourApiKeyToken).result.ethusd"
        );
    }
}