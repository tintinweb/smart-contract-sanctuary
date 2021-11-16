// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner!");
        _;
    }


    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Cannot transfer ownership to zero address!");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

abstract contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;


    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused, "Contract is paused!");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused, "Contract is not paused!");
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}

abstract contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public virtual view returns (uint256);
    function transfer(address to, uint256 value) public virtual returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

abstract contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public virtual  view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public virtual returns (bool);
    function approve(address spender, uint256 value) public virtual returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


abstract contract StandardTokenPausable is ERC20, Pausable {

    mapping (address => mapping (address => uint256)) internal allowed;
    mapping(address => bool) tokenBlacklist;
    event Blacklist(address indexed blackListed, bool value);


    mapping(address => uint256) balances;


    function transfer(address _to, uint256 _value) public override whenNotPaused returns (bool) {
        require(!tokenBlacklist[msg.sender], "Blacklisted address");
        require(_to != address(0), "Transfer to 0 address!");
        require(_value <= balances[msg.sender], "Insufficient amount!");

        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }


    function balanceOf(address _owner) public override view returns (uint256 balance) {
        return balances[_owner];
    }

    function transferFrom(address _from, address _to, uint256 _value) public override whenNotPaused returns (bool) {
        require(!tokenBlacklist[_from],"Blacklisted address from");
        require(_to != address(0), "Transfer to 0 address!");
        require(_value <= balances[_from], "Insufficient amount!");
        require(_value <= allowed[_from][msg.sender], "Insufficient allowance!");

        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }


    function approve(address _spender, uint256 _value) public override whenNotPaused returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }


    function allowance(address _owner, address _spender) public override view returns (uint256) {
        return allowed[_owner][_spender];
    }


    function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool) {
        allowed[msg.sender][_spender] += _addedValue;
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue - _subtractedValue;
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }



    function _blackList(address _address, bool _isBlackListed) internal whenNotPaused returns (bool) {
        require(tokenBlacklist[_address] != _isBlackListed, "Address is already blacklisted!");
        tokenBlacklist[_address] = _isBlackListed;
        emit Blacklist(_address, _isBlackListed);
        return true;
    }



}

contract T99  is StandardTokenPausable {
    string public name;
    string public symbol;
    uint public decimals;
    event Burn(address indexed burner, uint256 value);


    constructor(string memory _name, string memory _symbol, uint256 _decimals, uint256 _supply, address tokenOwner) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _supply * 10**_decimals;
        balances[tokenOwner] = totalSupply;
        owner = tokenOwner;
        emit Transfer(address(0), tokenOwner, totalSupply);
    }

    function burn(uint256 _value) public whenNotPaused {
        _burn(msg.sender, _value);
    }

    function _burn(address _who, uint256 _value) internal {
        require(_value <= balances[_who], "Insufficient amount!");
        balances[_who] -= _value;
        balances[address(0)] += _value;
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
        }

}