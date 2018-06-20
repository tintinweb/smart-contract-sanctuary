pragma solidity ^0.4.18;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
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

contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function Ownable() public {
        owner = msg.sender;
    }


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
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
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
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() onlyOwner whenPaused public {
        paused = false;
        Unpause();
    }
}

contract ERC20Basic {
    uint256 public totalSupply;

    function balanceOf(address who) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}


contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

}

contract StandardToken is ERC20, BasicToken {

    mapping(address => mapping(address => uint256)) internal allowed;


    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     *
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    /**
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     */
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

contract PausableToken is StandardToken, Pausable {

    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }
}


contract TokenImpl is PausableToken {
    string public name;
    string public symbol;

    uint8 public decimals = 5;
    uint256 private decimal_num = 100000;


    // cap of money in eth * decimal_num
    uint256 public cap;

    // the target token
    ERC20Basic public targetToken;
    // how many token units a buyer gets per ether
    uint16 public exchangeRate;

    // the freeze token
    mapping(address => uint256) frozenTokens;
    uint16 public frozenRate;

    bool public canBuy = true;
    bool public projectFailed = false;
    uint16 public backEthRatio = 10000;


    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value);
    event UpdateTargetToken(address _target, uint16 _exchangeRate, uint16 _freezeRate);
    event IncreaseCap(uint256 cap);
    event ProjectFailed(uint16 _fee);
    event PauseBuy();
    event UnPauseBuy();


    function TokenImpl(string _name, string _symbol, uint256 _cap) public {
        require(_cap > 0);
        name = _name;
        symbol = _symbol;
        cap = _cap.mul(decimal_num);
        paused = true;
    }

    // fallback function can be used to buy tokens
    function() external payable {
        buyTokens(msg.sender);
    }

    // low level token purchase function
    function buyTokens(address beneficiary) public payable {
        require(canBuy && msg.value >= (0.00001 ether));
        require(beneficiary != address(0));

        uint256 _amount = msg.value.mul(decimal_num).div(1 ether);
        totalSupply = totalSupply.add(_amount);
        require(totalSupply <= cap);
        balances[beneficiary] = balances[beneficiary].add(_amount);
        TokenPurchase(msg.sender, beneficiary, _amount);

        forwardFunds();
    }

    // send ether to the fund collection wallet
    function forwardFunds() internal {
        if(!projectFailed){
            owner.transfer(msg.value);
        }
    }


    /**
      * @dev exchange tokens of _exchanger.
      */
    function exchange(address _exchanger, uint256 _value) internal {
        if (projectFailed) {
            _exchanger.transfer(_value.mul(1 ether).mul(backEthRatio).div(10000).div(decimal_num));
        } else {
            require(targetToken != address(0) && exchangeRate > 0);
            uint256 _tokens = _value.mul(exchangeRate).div(decimal_num);
            targetToken.transfer(_exchanger, _tokens);
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused
    returns (bool) {
        updateFrozenToken(_from);
        require(_to != address(0));
        require(_value.add(frozenTokens[_from]) <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        updateFrozenToken(msg.sender);
        if (_to == address(this)) {
            if (frozenRate == 0 || projectFailed) {
                exchange(msg.sender, _value);
                return super.transferFrom(_from, _to, _value);
            }
            uint256 tokens = _value.mul(10000 - frozenRate).div(10000);
            uint256 fTokens = _value.sub(tokens);
            balances[_from] = balances[_from].sub(_value);
            balances[_to] = balances[_to].add(tokens);
            balances[msg.sender] = balances[msg.sender].add(fTokens);
            frozenTokens[msg.sender] = frozenTokens[msg.sender].add(fTokens);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
            Transfer(_from, _to, _value);
            exchange(msg.sender, tokens);
            return true;
        } else {
            return super.transferFrom(_from, _to, _value);
        }
    }

    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        require(_to != address(0));
        updateFrozenToken(msg.sender);
        require(_value.add(frozenTokens[msg.sender]) <= balances[msg.sender]);

        uint256 tokens = _value;
        if (_to == address(this)) {
            if (frozenRate > 0 && !projectFailed) {
                tokens = _value.mul(10000 - frozenRate).div(10000);
                uint256 fTokens = _value.sub(tokens);
                frozenTokens[msg.sender] = frozenTokens[msg.sender].add(fTokens);
            }
            exchange(msg.sender, tokens);
        }
        return super.transfer(_to, tokens);
    }

    function updateFrozenToken(address _owner) internal {
        if (frozenRate == 0 && frozenTokens[_owner] > 0) {
            frozenTokens[_owner] = 0;
        }
    }

    function balanceOfFrozen(address _owner) public view returns (uint256) {
        if (frozenRate == 0) {
            return 0;
        }
        return frozenTokens[_owner];
    }

    function balanceOfTarget(address _owner) public view returns (uint256) {
        if (targetToken != address(0)) {
            return targetToken.balanceOf(_owner);
        } else {
            return 0;
        }
    }

    function saleRatio() public view returns (uint256 ratio) {
        if (cap == 0) {
            return 0;
        } else {
            return totalSupply.mul(10000).div(cap);
        }
    }


    function canExchangeNum() public view returns (uint256) {
        if (targetToken != address(0) && exchangeRate > 0) {
            uint256 _tokens = targetToken.balanceOf(this);
            return decimal_num.mul(_tokens).div(exchangeRate);
        } else {
            return 0;
        }
    }

    function pauseBuy() onlyOwner public {
        canBuy = false;
        PauseBuy();
    }

    function unPauseBuy() onlyOwner public {
        canBuy = true;
        UnPauseBuy();
    }

    // increase the amount of eth
    function increaseCap(int256 _cap_inc) onlyOwner public {
        require(_cap_inc != 0);
        if (_cap_inc > 0) {
            cap = cap.add(decimal_num.mul(uint256(_cap_inc)));
        } else {
            uint256 _dec = uint256(- 1 * _cap_inc);
            uint256 cap_dec = decimal_num.mul(_dec);
            if (cap_dec >= cap - totalSupply) {
                cap = totalSupply;
            } else {
                cap = cap.sub(cap_dec);
            }
        }
        IncreaseCap(cap);
    }


    function projectFailed(uint16 _fee) onlyOwner public {
        require(!projectFailed && _fee >= 0 && _fee <= 10000);
        projectFailed = true;
        backEthRatio = 10000 - _fee;
        frozenRate = 0;
        ProjectFailed(_fee);
    }


    function updateTargetToken(address _target, uint16 _exchangeRate, uint16 _freezeRate) onlyOwner public {
        require(_freezeRate > 0 || _exchangeRate > 0);

        if (_exchangeRate > 0) {
            require(_target != address(0));
            exchangeRate = _exchangeRate;
            targetToken = ERC20Basic(_target);
        }
        if (_freezeRate > 0) {
            frozenRate = _freezeRate;
        }
        UpdateTargetToken(_target, _exchangeRate, _freezeRate);
    }


    function destroy() onlyOwner public {
        selfdestruct(owner);
    }

}