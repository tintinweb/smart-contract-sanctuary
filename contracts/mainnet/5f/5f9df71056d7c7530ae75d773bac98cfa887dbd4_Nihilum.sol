pragma solidity ^0.4.14;

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
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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


contract Ownable {
  address public owner;

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

//***********Pausible


contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;

  /**
   * @dev modifier to allow actions only when the contract IS paused
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev modifier to allow actions only when the contract IS NOT paused
   */
  modifier whenPaused {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() public onlyOwner whenNotPaused returns (bool) {
    paused = true;
    Pause();
    return true;
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() public onlyOwner whenPaused returns (bool) {
    paused = false;
    Unpause();
    return true;
  }
}


contract Crowdsaleable is Pausable {
  event PauseCrowdsale();
  event UnpauseCrowdsale();

  bool public crowdsalePaused = true;

  /**
   * @dev modifier to allow actions only when the contract IS paused
   */
  modifier whenCrowdsaleNotPaused() {
    require(!crowdsalePaused);
    _;
  }

  /**
   * @dev modifier to allow actions only when the contract IS NOT paused
   */
  modifier whenCrowdsalePaused {
    require(crowdsalePaused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pauseCrowdsale() public onlyOwner whenCrowdsaleNotPaused returns (bool) {
    crowdsalePaused = true;
    PauseCrowdsale();
    return true;
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpauseCrowdsale() public onlyOwner whenCrowdsalePaused returns (bool) {
    crowdsalePaused = false;
    UnpauseCrowdsale();
    return true;
  }
}

contract Nihilum is Crowdsaleable {




    string public name;
    string public symbol;
    uint8 public decimals;

    // address where funds are collected
    address public wallet;
    
    
    uint256 public _tokenPrice;
    uint256 public _minimumTokens;
    bool public _allowManualTokensGeneration;
    uint256 public totalSupply;
    uint public totalShareholders;

    uint256 private lastUnpaidIteration;

    mapping (address => bool) registeredShareholders;
    mapping (uint => address) shareholders;
    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;


    uint256 public totalNihilum;
    struct Account {
        uint256 balance;
        uint256 lastNihilum;
        bool isClaiming;
        bool blacklisted;
        bool whitelisted;
    }
    mapping (address => Account) accounts;


    event Transfer(address indexed from, address indexed to, uint256 value);

    function Nihilum() public {
        balanceOf[msg.sender] = 0;
        name = "Nihilum";
        symbol = "NH";
        decimals = 0;
        _tokenPrice = 0.0024 ether;
        _minimumTokens = 50;
        _allowManualTokensGeneration = true;
        wallet = owner;
        owner = msg.sender;
        totalShareholders = 0;
        lastUnpaidIteration = 1;
    }

    using SafeMath for uint256;
    
    /* Send coins */
    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        if (balanceOf[msg.sender] < _value) return false;              // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) return false;    // Check for overflows
        if (_to == owner || _to == address(this)) return false;         // makes it illegal to send tokens to owner or this contract
        _transfer(msg.sender, _to, _value);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);                        // Subtract from the sender
        balanceOf[_to] = balanceOf[_to].add(_value);                               // Add the same to the recipient

        /* Adding to shareholders count if tokens spent from owner to others */
        if (msg.sender == owner && _to != owner) {
            totalSupply += _value;
        }
        /* Remove from shareholders count if tokens spent from holder to owner */
        if (msg.sender != owner && _to == owner) {
            totalSupply = totalSupply.sub(_value);
        }

        if (owner == _to) {
            // sender is owner
        } else {
            insertShareholder(_to);
        }

        /* Notify anyone listening that this transfer took place */
        Transfer(msg.sender, _to, _value);

        return true;
    }


    function _transfer(address _from, address _to, uint256 _value) internal {
        require(!accounts[_from].blacklisted);
        require(!accounts[_to].blacklisted);
        require(_to != address(0));
        require(_value <= accounts[_from].balance);
        require(accounts[_to].balance + _value > accounts[_to].balance);
 
        var fromOwing = nihilumBalanceOf(_from);
        var toOwing = nihilumBalanceOf(_to);
        require(fromOwing <= 0 && toOwing <= 0);
 
        accounts[_from].balance = accounts[_from].balance.sub(_value);
        
        accounts[_to].balance = accounts[_to].balance.add(_value);
 
        accounts[_to].lastNihilum = totalNihilum;//accounts[_from].lastNihilum;
 
        //Transfer(_from, _to, _value);
    }





    function addTokens(uint256 numTokens) public onlyOwner {
        if (_allowManualTokensGeneration) {
            balanceOf[msg.sender] += numTokens;
            accounts[msg.sender].balance = accounts[msg.sender].balance.add(numTokens);
            Transfer(0, msg.sender, numTokens);
        } else {
            revert();
        }
    }

    function blacklist(address person) public onlyOwner {
        require(person != owner);
        balanceOf[person] = 0;
        accounts[person].balance = 0;
        accounts[person].lastNihilum = totalNihilum;
        accounts[person].blacklisted = true;
    }

    function () external payable {
      if (!crowdsalePaused) {
          buyTokens();
          } else {
              PayNihilumToContract();
              }
    }


        function whitelist(address userAddress) onlyOwner {
            accounts[userAddress].whitelisted = true;            
    }

    /* Buy Token 1 token for x ether */
    function buyTokens() public whenCrowdsaleNotPaused payable {
        require(!accounts[msg.sender].blacklisted);
        require(msg.value > 0);
        require(msg.value >= _tokenPrice);
        require(msg.value % _tokenPrice == 0);
        var numTokens = msg.value / _tokenPrice;
        require(numTokens >= _minimumTokens);
        balanceOf[msg.sender] += numTokens;
        Transfer(0, msg.sender, numTokens);
        wallet.transfer(msg.value);
        accounts[msg.sender].balance = accounts[msg.sender].balance.add(numTokens);
        insertShareholder(msg.sender);
        if (msg.sender != owner) {
            totalSupply += numTokens;
        }
    }

    function payNihilum() public onlyOwner {
        if (this.balance > 0 && totalShareholders > 0) {
            for (uint i = lastUnpaidIteration; i <= totalShareholders; i++) {
                uint256 currentBalance = balanceOf[shareholders[i]];
                lastUnpaidIteration = i;
                if (currentBalance > 0 && nihilumBalanceOf(shareholders[i]) > 0 && !accounts[shareholders[i]].isClaiming && msg.gas > 2000) {
                    accounts[shareholders[i]].isClaiming = true;
                    shareholders[i].transfer(nihilumBalanceOf(shareholders[i]));
                    accounts[shareholders[i]].lastNihilum = totalNihilum;
                    accounts[shareholders[i]].isClaiming = false;
                }
            }
            lastUnpaidIteration = 1;
        }
    }

    function nihilumBalanceOf(address account) public constant returns (uint256) {
        var newNihilum = totalNihilum.sub(accounts[account].lastNihilum);
        var product = accounts[account].balance.mul(newNihilum);
        if (totalSupply <= 0) return 0;
        if (account == owner) return 0;
        return product.div(totalSupply);
    }

    function claimNihilum() public {
        require(!accounts[msg.sender].blacklisted);
        var owing = nihilumBalanceOf(msg.sender);
        if (owing > 0 && !accounts[msg.sender].isClaiming) {
            accounts[msg.sender].isClaiming = true;
            accounts[msg.sender].lastNihilum = totalNihilum;
            msg.sender.transfer(owing);
            accounts[msg.sender].isClaiming = false;
        }
    }

    function PayNihilumToContract() public onlyOwner payable {
        totalNihilum = totalNihilum.add(msg.value);
    }

        function PayToContract() public onlyOwner payable {
        
    }

    function ChangeTokenPrice(uint256 newPrice) public onlyOwner {
        _tokenPrice = newPrice;
    }

    function insertShareholder(address _shareholder) internal returns (bool) {
        if (registeredShareholders[_shareholder] == true) {

        } else {
            totalShareholders += 1;
            shareholders[totalShareholders] = _shareholder;
            registeredShareholders[_shareholder] = true;
            return true;
        }
        return false;
    }
}