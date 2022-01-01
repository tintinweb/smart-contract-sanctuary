/**
 *Submitted for verification at BscScan.com on 2022-01-01
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-22
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

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

contract StandardToken is ERC20 {
    uint256 public txFee;
    uint256 public burnFee;
    address public FeeAddress;

    mapping(address => mapping(address => uint256)) internal allowed;
    mapping(address => bool) tokenBlacklist;
    mapping(address => uint256) balances;

    event Blacklist(address indexed blackListed, bool value);

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
        returns (bool)
    {
        require(tokenBlacklist[msg.sender] == false);
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] -= _value;
        uint256 originValue = _value;

        if (txFee > 0 && msg.sender != FeeAddress) {
            uint256 DenverDeflaionaryDecay = (originValue * txFee) / 100;
            balances[FeeAddress] += DenverDeflaionaryDecay;
            emit Transfer(msg.sender, FeeAddress, DenverDeflaionaryDecay);
            _value -= DenverDeflaionaryDecay;
        }

        if (burnFee > 0 && msg.sender != FeeAddress) {
            uint256 Burnvalue = (originValue * burnFee) / 100;
            totalSupply -= Burnvalue;
            emit Transfer(msg.sender, address(0), Burnvalue);
            _value -= Burnvalue;
        }

        // SafeMath.sub will throw if there is not enough balance.
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public virtual override returns (bool) {
        require(tokenBlacklist[msg.sender] == false);
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] -= _value;
        uint256 originValue = _value;

        if (txFee > 0 && _from != FeeAddress) {
            uint256 DenverDeflaionaryDecay = (originValue * txFee) / 100;
            balances[FeeAddress] += DenverDeflaionaryDecay;
            emit Transfer(_from, FeeAddress, DenverDeflaionaryDecay);
            _value -= DenverDeflaionaryDecay;
        }

        if (burnFee > 0 && _from != FeeAddress) {
            uint256 Burnvalue = (originValue * burnFee) / 100;
            totalSupply -= Burnvalue;
            emit Transfer(_from, address(0), Burnvalue);
            _value -= Burnvalue;
        }

        balances[_to] += _value;
        allowed[_from][msg.sender] -= originValue;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value)
        public
        virtual
        override
        returns (bool)
    {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

    function increaseApproval(address _spender, uint256 _addedValue)
        public
        virtual
        returns (bool)
    {
        allowed[msg.sender][_spender] += _addedValue;
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint256 _subtractedValue)
        public
        virtual
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
        returns (bool)
    {
        require(tokenBlacklist[_address] != _isBlackListed);
        tokenBlacklist[_address] = _isBlackListed;
        emit Blacklist(_address, _isBlackListed);
        return true;
    }
}

contract PausableToken is StandardToken, Pausable {
    function transfer(address _to, uint256 _value)
        public
        virtual
        override
        whenNotPaused
        returns (bool)
    {
        return super.transfer(_to, _value);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public virtual override whenNotPaused returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value)
        public
        override
        whenNotPaused
        returns (bool)
    {
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint256 _addedValue)
        public
        override
        whenNotPaused
        returns (bool success)
    {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint256 _subtractedValue)
        public
        override
        whenNotPaused
        returns (bool success)
    {
        return super.decreaseApproval(_spender, _subtractedValue);
    }

    function blackListAddress(address listAddress, bool isBlackListed)
        public
        whenNotPaused
        onlyOwner
        returns (bool success)
    {
        return super._blackList(listAddress, isBlackListed);
    }
}

interface IFactory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

interface TokenConverter {
    function checkTokensDistance(address _tokenA, address _tokenB)
        external
        view
        returns (uint8);

    function convertTwo(
        address _tokenA,
        address _tokenB,
        uint256 _amount
    ) external view returns (uint256);

    function DEFAULT_FACTORY() external view returns (IFactory);
}

contract CoinToken is PausableToken {
    string public name;
    string public symbol;
    uint256 public decimals;
    event Burn(address indexed burner, uint256 value);

    // ANTI-SNIPE
    address public constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address public constant TOKEN_CONVERTER = 0x9e023bc4211083A320f36c5360Acaebc06Ac084b; // 0xe2bf8ef5E2b24441d5B2649A3Dc6D81afC1a9517

    uint256 public start = 0;
    uint256 public THRESHOLD = 10 minutes;
    uint256 public MAX_DOLLARS = 1000 * 1e18;
    uint256 public DELAY = 4 seconds;

    mapping(address => bool) public isWhitelist;
    mapping(address => uint256) public lastBuy;

    TokenConverter tokenConverter = TokenConverter(TOKEN_CONVERTER);

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _decimals,
        uint256 _supply,
        uint256 _txFee,
        uint256 _burnFee,
        address _FeeAddress,
        address tokenOwner
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _supply * 10**_decimals;
        balances[tokenOwner] = totalSupply;
        owner = tokenOwner;
        txFee = _txFee;
        burnFee = _burnFee;
        FeeAddress = _FeeAddress;
        emit Transfer(address(0), tokenOwner, totalSupply);
    }

    function burn(uint256 _value) public {
        _burn(msg.sender, _value);
    }

    function updateFee(
        uint256 _txFee,
        uint256 _burnFee,
        address _FeeAddress
    ) public onlyOwner {
        txFee = _txFee;
        burnFee = _burnFee;
        FeeAddress = _FeeAddress;
    }

    function _burn(address _who, uint256 _value) internal {
        require(_value <= balances[_who]);
        balances[_who] -= _value;
        totalSupply -= _value;
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public override whenNotPaused returns (bool) {
        require(
            _canTransfer(_from, _to, _value),
            "transfer attempt was blocked"
        );
        return super.transferFrom(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value)
        public
        override
        whenNotPaused
        returns (bool)
    {
        require(
            _canTransfer(msg.sender, _to, _value),
            "transfer attempt was blocked"
        );
        return super.transfer(_to, _value);
    }

    function _canTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal returns (bool success) {
        if (isWhitelist[_from] || isWhitelist[_to]) {
            if (tokenConverter.checkTokensDistance(address(this), WBNB) == 1) {
                if (start == 0) start = block.timestamp;
            }
            return true;
        }
        if (tokenConverter.checkTokensDistance(address(this), WBNB) == 0)
            return true;

        if (start == 0) start = block.timestamp;
        if ((block.timestamp - start) >= THRESHOLD) return true;

        // BUY filter
        address _pair = getPairAddress();
        if (msg.sender == _pair && _from == _pair) {
            if (_amount > dollarsToTokens(MAX_DOLLARS)) return false;
            if ((block.timestamp - lastBuy[_to]) < DELAY) return false;
            lastBuy[_to] = block.timestamp;
        }
        return true;
    }

    function dollarsToTokens(uint256 _dollars) public view returns (uint256) {
        uint256 _inCoin = tokenConverter.convertTwo(BUSD, WBNB, _dollars);
        uint256 _inToken = tokenConverter.convertTwo(
            WBNB,
            address(this),
            _inCoin
        );
        return _inToken;
    }

    function getPairAddress() public view returns (address) {
        return tokenConverter.DEFAULT_FACTORY().getPair(address(this), WBNB);
    }

    function setWhitelistRights(address _user, bool _value) external onlyOwner {
        isWhitelist[_user] = _value;
    }

    function setWhitelistUsers(address[] memory addresses, bool value)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            isWhitelist[addresses[i]] = value;
        }
    }

    function setThreshold(uint256 value_) external onlyOwner {
        THRESHOLD = value_;
    }

    function setMaxDollars(uint256 value_) external onlyOwner {
        MAX_DOLLARS = value_;
    }
}