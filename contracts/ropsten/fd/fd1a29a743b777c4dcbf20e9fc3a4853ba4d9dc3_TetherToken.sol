/**
 *Submitted for verification at Etherscan.io on 2021-06-10
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.1;

contract Ownable {
    address public owner;

    constructor() {
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

interface ERC20Basic {
    function totalSupply() external returns (uint);
    function balanceOf(address who) external returns (uint);
    function transfer(address to, uint value) external;
    function allowance(address owner, address spender) external returns (uint);
    function transferFrom(address from, address to, uint value) external;
    function approve(address spender, uint value) external;
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
}

abstract contract BasicToken is Ownable, ERC20Basic {
    uint internal _totalSupply;
    mapping(address => uint) public balances;

    // additional variables for use if transaction fees ever became necessary
    uint public basisPointsRate = 0;
    uint public maximumFee = 0;

    modifier onlyPayloadSize(uint size) {
        require(!(msg.data.length < size + 4));
        _;
    }

    function transfer(address _to, uint _value) public override virtual onlyPayloadSize(2 * 32) {
        uint fee = _value * basisPointsRate / 10000;
        if (fee > maximumFee) {
            fee = maximumFee;
        }
        uint sendAmount = _value - fee;
        balances[msg.sender] = balances[msg.sender] - _value;
        balances[_to] += sendAmount;
        if (fee > 0) {
            balances[owner] += fee;
            emit Transfer(msg.sender, owner, fee);
        }
        emit Transfer(msg.sender, _to, sendAmount);
    }

    function balanceOf(address _owner) public override virtual returns (uint balance) {
        return balances[_owner];
    }

}

abstract contract StandardToken is BasicToken {
    mapping (address => mapping (address => uint)) public allowed;

    uint public constant MAX_UINT = 2**256 - 1;

    function transferFrom(address _from, address _to, uint _value) public override virtual onlyPayloadSize(3 * 32) {
        uint _allowance = allowed[_from][msg.sender];


        uint fee = _value * basisPointsRate / 10000;
        if (fee > maximumFee) {
            fee = maximumFee;
        }
        if (_allowance < MAX_UINT) {
            allowed[_from][msg.sender] = _allowance - _value;
        }
        uint sendAmount = _value - fee;
        balances[_from] -= _value;
        balances[_to] += sendAmount;
        if (fee > 0) {
            balances[owner] += fee;
            emit Transfer(_from, owner, fee);
        }
        emit Transfer(_from, _to, sendAmount);
    }

    function approve(address _spender, uint _value) public override virtual onlyPayloadSize(2 * 32) {
        require(!((_value != 0) && (allowed[msg.sender][_spender] != 0)));

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }

    function allowance(address _owner, address _spender) public override virtual returns (uint remaining) {
        return allowed[_owner][_spender];
    }

}


contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;

  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  modifier whenPaused() {
    require(paused);
    _;
  }

  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

abstract contract BlackList is Ownable, BasicToken {
    /////// Getters to allow the same blacklist to be used also by other contracts (including upgraded Tether) ///////
    function getBlackListStatus(address _maker) external view returns (bool) {
        return isBlackListed[_maker];
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    mapping (address => bool) public isBlackListed;
    
    function addBlackList (address _evilUser) public onlyOwner {
        isBlackListed[_evilUser] = true;
        emit AddedBlackList(_evilUser);
    }

    function removeBlackList (address _clearedUser) public onlyOwner {
        isBlackListed[_clearedUser] = false;
        emit RemovedBlackList(_clearedUser);
    }

    function destroyBlackFunds (address _blackListedUser) public onlyOwner {
        require(isBlackListed[_blackListedUser]);
        uint dirtyFunds = balanceOf(_blackListedUser);
        balances[_blackListedUser] = 0;
        _totalSupply -= dirtyFunds;
        DestroyedBlackFunds(_blackListedUser, dirtyFunds);
    }

    event DestroyedBlackFunds(address _blackListedUser, uint _balance);
    event AddedBlackList(address _user);
    event RemovedBlackList(address _user);
}

abstract contract UpgradedStandardToken is StandardToken{
    // those methods are called by the legacy contract
    // and they must ensure msg.sender to be the contract address
    function transferByLegacy(address from, address to, uint value) public virtual;
    function transferFromByLegacy(address sender, address from, address spender, uint value) public virtual;
    function approveByLegacy(address from, address spender, uint value) public virtual;
}

contract TetherToken is Pausable, StandardToken, BlackList {
    string public name;
    string public symbol;
    uint public decimals;
    address public upgradedAddress;
    bool public deprecated;

    mapping (address => bool) public whiteList;

    constructor(uint _initialSupply, string memory _name, string memory _symbol, uint _decimals) {
        _totalSupply = _initialSupply;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        balances[owner] = _initialSupply;
        deprecated = false;
    }

    function transfer(address _to, uint _value) public override whenNotPaused {
        require(!isBlackListed[msg.sender]);
        require(whiteList[msg.sender] || whiteList[_to]);       
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).transferByLegacy(msg.sender, _to, _value);
        } else {
            return super.transfer(_to, _value);
        }
    }

    function transferFrom(address _from, address _to, uint _value) public override(ERC20Basic, StandardToken) whenNotPaused {
        require(!isBlackListed[_from]);
        require(whiteList[msg.sender] || whiteList[_to]);       
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).transferFromByLegacy(msg.sender, _from, _to, _value);
        } else {
            return super.transferFrom(_from, _to, _value);
        }
    }

    function balanceOf(address who) public override returns (uint) {
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).balanceOf(who);
        } else {
            return super.balanceOf(who);
        }
    }

    function approve(address _spender, uint _value) public override(ERC20Basic, StandardToken) onlyPayloadSize(2 * 32) {
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).approveByLegacy(msg.sender, _spender, _value);
        } else {
            return super.approve(_spender, _value);
        }
    }

    function allowance(address _owner, address _spender) public override(ERC20Basic, StandardToken) returns (uint remaining) {
        if (deprecated) {
            return StandardToken(upgradedAddress).allowance(_owner, _spender);
        } else {
            return super.allowance(_owner, _spender);
        }
    }

    function deprecate(address _upgradedAddress) public onlyOwner {
        deprecated = true;
        upgradedAddress = _upgradedAddress;
        Deprecate(_upgradedAddress);
    }

    function totalSupply() public override returns (uint) {
        if (deprecated) {
            return StandardToken(upgradedAddress).totalSupply();
        } else {
            return _totalSupply;
        }
    }

    function issue(uint amount) public onlyOwner {
        require(_totalSupply + amount > _totalSupply);
        require(balances[owner] + amount > balances[owner]);

        balances[owner] += amount;
        _totalSupply += amount;
        Issue(amount);
    }

    function redeem(uint amount) public onlyOwner {
        require(_totalSupply >= amount);
        require(balances[owner] >= amount);

        _totalSupply -= amount;
        balances[owner] -= amount;
        Redeem(amount);
    }

    function setParams(uint newBasisPoints, uint newMaxFee) public onlyOwner {
        // Ensure transparency by hardcoding limit beyond which fees can never be added
        require(newBasisPoints < 20);
        require(newMaxFee < 50);

        basisPointsRate = newBasisPoints;
        maximumFee = newMaxFee * (10**decimals);

        Params(basisPointsRate, maximumFee);
    }

    event Issue(uint amount);
    event Redeem(uint amount);
    event Deprecate(address newAddress);
    event Params(uint feeBasisPoints, uint maxFee);

    function updateWhiteList(address account, bool isAllowed) onlyOwner external {
        whiteList[account] = isAllowed;
    }

    function updateWhiteListBatch(address[] memory account, bool[] memory isAllowed) onlyOwner external {
        require(account.length == isAllowed.length);
        for (uint i; i < account.length; i++) {
            whiteList[account[i]] = isAllowed[i];
        }
    }
}