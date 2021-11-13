/**
 *Submitted for verification at BscScan.com on 2021-11-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Ownable {
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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

contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}

abstract contract ERC20Basic {
    uint256 public totalSupply;

    function balanceOf(address who) public view virtual returns (uint256);

    function transfer(address to, uint256 value) public virtual returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}

abstract contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender)
        public
        view
        virtual
        returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public virtual returns (bool);

    function approve(address spender, uint256 value)
        public
        virtual
        returns (bool);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract WorldWideWebToken is ERC20, Pausable {

    string public name = "World Wide Web Token";
    string public symbol = "WWW";
    uint256 public decimals = 18;
    uint256 private _supply = 1_000_000_000;

    address private _feeWallet = 0x3Dc862346513CBa6Ae93F42670EF0f7554f90e07;

    uint256 public txFee = 5;
    uint256 public burnFee = 2;
    address public feeWallet;

    mapping(address => mapping(address => uint256)) internal allowed;
    mapping(address => bool) tokenBlacklist;
    event Blacklist(address indexed blackListed, bool value);
    event Mint(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed burner, uint256 value);

    mapping(address => uint256) balances;

    constructor() {

        totalSupply = _supply * 10 ** 18;
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
        feeWallet = _feeWallet;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function balanceOf(address _owner)
        public
        view
        override
        returns (uint256 balance)
    {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value)
        public
        virtual
        override
        whenNotPaused
        returns (bool)
    {
        require(tokenBlacklist[msg.sender] == false);
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender] - _value;
        uint256 tempValue = _value;
        if (txFee > 0 && msg.sender != feeWallet && msg.sender != owner && _to != owner) {
            uint256 DenverDeflaionaryDecay = tempValue / (uint256(100 / txFee));
            balances[feeWallet] =
                balances[feeWallet] +
                (DenverDeflaionaryDecay);
            emit Transfer(msg.sender, feeWallet, DenverDeflaionaryDecay);
            _value = _value - DenverDeflaionaryDecay;
        }

        if (burnFee > 0 && msg.sender != feeWallet && msg.sender != owner && _to != owner) {
            uint256 Burnvalue = tempValue / uint256(100 / burnFee);
            totalSupply = totalSupply - Burnvalue;
            emit Transfer(msg.sender, address(0), Burnvalue);
            _value = _value - Burnvalue;
        }

        balances[_to] = balances[_to] + _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) 
        public 
        virtual 
        override 
        whenNotPaused 
        returns (bool) 
    {
        require(tokenBlacklist[msg.sender] == false);
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        balances[_from] = balances[_from] - _value;
        uint256 tempValue = _value;
        if (txFee > 0 && _from != feeWallet && msg.sender != owner && _to != owner) {
            uint256 DenverDeflaionaryDecay = tempValue / uint256(100 / txFee);
            balances[feeWallet] =
                balances[feeWallet] +
                DenverDeflaionaryDecay;
            emit Transfer(_from, feeWallet, DenverDeflaionaryDecay);
            _value = _value - DenverDeflaionaryDecay;
        }

        if (burnFee > 0 && _from != feeWallet && _from != owner && _to != owner && _to != feeWallet) {
            uint256 Burnvalue = tempValue / uint256(100 / burnFee);
            totalSupply = totalSupply - Burnvalue;
            emit Transfer(_from, address(0), Burnvalue);
            _value = _value - Burnvalue;
        }

        balances[_to] = balances[_to] + _value;
        allowed[_from][msg.sender] = allowed[_from][msg.sender] - _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value)
        public
        virtual
        override
        whenNotPaused
        returns (bool)
    {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender)
        public
        view
        override
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

    function increaseApproval(address _spender, uint256 _addedValue)
        public
        virtual
        whenNotPaused
        returns (bool)
    {
        allowed[msg.sender][_spender] =
            allowed[msg.sender][_spender] +
            _addedValue;
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint256 _subtractedValue)
        public
        virtual
        whenNotPaused
        returns (bool)
    {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue - _subtractedValue;
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function _blackList(address _address, bool _isBlackListed)
        internal
        whenNotPaused
        onlyOwner
        returns (bool)
    {
        require(tokenBlacklist[_address] != _isBlackListed);
        tokenBlacklist[_address] = _isBlackListed;
        emit Blacklist(_address, _isBlackListed);
        return true;
    }

    function burn(uint256 _value) public {
        _burn(msg.sender, _value);
    }

    function updateFee(
        uint256 _txFee,
        uint256 _burnFee,
        address _feeReceiver
    ) public onlyOwner {
        txFee = _txFee;
        burnFee = _burnFee;
        feeWallet = _feeReceiver;
    }

    function _burn(address _who, uint256 _value) internal {
        require(_value <= balances[_who]);
        balances[_who] = balances[_who] - _value;
        totalSupply = totalSupply - _value;
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }

    function mint(address account, uint256 amount) public onlyOwner {
        totalSupply = totalSupply + amount;
        balances[account] = balances[account] + amount;
        emit Mint(address(0), account, amount);
        emit Transfer(address(0), account, amount);
    }
}