pragma solidity >=0.6.0 <0.7.0;
import "./safeMath.sol";


contract owned {
    address payable public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable newOwner) public onlyOwner {
        owner = newOwner;
    }
}


interface tokenRecipient {
    function receiveApproval(
        address _from,
        uint256 _value,
        address _token,
        bytes calldata _extraData
    ) external;
}


contract TokenERC20 {
    using SafeMath for uint256;
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
    event Burn(address indexed from, uint256 value);

    constructor(
        uint256 initialSupply,
        string memory tokenName,
        string memory tokenSymbol
    ) public {
        totalSupply = initialSupply.mul(10**uint256(decimals));
        balanceOf[address(this)] = totalSupply;
        name = tokenName;
        symbol = tokenSymbol;
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _value
    ) internal {
        require(_to != address(0x0));
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint256 previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value)
        public
        returns (bool success)
    {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function approveAndCall(
        address _spender,
        uint256 _value,
        bytes memory _extraData
    ) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(
                msg.sender,
                _value,
                address(this),
                _extraData
            );
            return true;
        }
        return true;
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value)
        public
        returns (bool success)
    {
        require(balanceOf[_from] >= _value);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(_from, _value);
        return true;
    }
}


contract MyToken is owned, TokenERC20 {
    uint256 public sellBalance;
    uint256 public burnBalance;
    Db db;
    Core core;
    address coreAddress;

    constructor(
        uint256 initialSupply,
        string memory tokenName,
        string memory tokenSymbol
    ) public TokenERC20(initialSupply, tokenName, tokenSymbol) {}

    function price() public view returns (uint256) {
        if (sellBalance < 8e25) {
            uint256 _init = 150e10;
            uint256 _initPrice = uint256(1).mul(1e18).div(_init);
            uint256 _singlePrice = uint256(1).mul(1e18).div(_init).div(100);
            uint256 _ratio = sellBalance.div(1e23);
            uint256 _newPrice = _initPrice.add(_singlePrice.mul(_ratio));
            uint256 _price = uint256(1).mul(1e18).div(_newPrice);
            return _price.div(1e10);
        } else if (sellBalance < 16e25) {
            uint256 _init = 166e9;
            uint256 _initPrice = uint256(1).mul(1e18).div(_init);
            uint256 _singlePrice = uint256(1).mul(1e18).div(_init).div(100);
            uint256 _ratio = (sellBalance.sub(8e25)).div(2e23);
            uint256 _newPrice = _initPrice.add(_singlePrice.mul(_ratio));
            uint256 _price = uint256(1).mul(1e18).div(_newPrice);
            return _price.div(1e10);
        } else if (sellBalance < 229e24) {
            uint256 _init = 33e9;
            uint256 _initPrice = uint256(1).mul(1e18).div(_init);
            uint256 _singlePrice = uint256(1).mul(1e18).div(_init).div(100);
            uint256 _ratio = (sellBalance.sub(16e25)).div(3e23);
            uint256 _newPrice = _initPrice.add(_singlePrice.mul(_ratio));
            uint256 _price = uint256(1).mul(1e18).div(_newPrice);
            return _price.div(1e10);
        } else {
            return 1;
        }
    }

    function init(address _dbAddress, address _coreAddress) public onlyOwner {
        db = Db(_dbAddress);
        core = Core(_coreAddress);
        coreAddress = _coreAddress;
    }

    modifier isCore {
        require(msg.sender == coreAddress);
        _;
    }

    function sendTokenToAddress(address _own, uint256 _balance) public isCore {
        _balance = _balance.mul(1e18);
        require(_balance.add(sellBalance) < 229000000e18);
        sellBalance = sellBalance.add(_balance);
        _transfer(address(this), _own, _balance);
    }

    function sendTokenToV4(address _own, uint256 _balance) public onlyOwner {
        _transfer(address(this), _own, _balance);
    }

    function getToken(address _own) public view returns (uint256) {
        return balanceOf[_own];
    }

    function sendTokenToGame(address _to, uint256 _value)
        public
        isCore
        returns (bool)
    {
        address txAddress = tx.origin;
        require(balanceOf[txAddress] >= _value);
        burnBalance = burnBalance.add(_value);
        _transfer(txAddress, _to, _value);
        return true;
    }

    function getTokenPrice() public view returns (uint256) {
        return price();
    }
}


abstract contract Db {
    function getPlayerInfo(address _own)
        public
        virtual
        view
        returns (
            address _parent,
            bool _isExist,
            bool _isParent
        );
}


abstract contract Core {
    function bindParent(address _parent) public virtual;
}
