/**
 *Submitted for verification at Etherscan.io on 2021-06-12
*/

pragma solidity >=0.8.4;

interface IX1ERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IX1Factory {
    event TokenCreated(string name, string symbol, uint8 decimals, uint totalSupply, address);

    function fee() external view returns (uint);
    function vipFee() external view returns (uint);
    function tokenFeeRate() external view returns (uint16);
    function tokenFeePrecision() external pure returns (uint16);
    function feeReceiver() external view returns (address payable);
    function owner() external view returns (address);

    function createToken(string calldata _name,
                         string calldata _symbol,
                         uint8 _decimals,
                         uint _totalSupply,
                         bytes calldata _vipTemplate) payable external returns (address tokenAddress);

    function setFee(uint) external;
    function setVIPFee(uint) external;
    function setTokenFeeRate(uint16) external;
    function setFeeReceiver(address payable) external;
    function changeOwner(address) external;
}

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

contract X1ERC20 is IX1ERC20 {
    using SafeMath for uint;

    string public override name;
    string public override symbol;
    uint8 public override decimals;
    uint  public override totalSupply;
    mapping(address => uint) public override balanceOf;
    mapping(address => mapping(address => uint)) public override allowance;

    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint _totalSupply) {
        require(type(uint).max != _totalSupply && uint(10) ** _decimals < _totalSupply);
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        balanceOf[msg.sender] = _totalSupply;

        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) override external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) override external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) override external returns (bool) {
        if (allowance[from][msg.sender] != type(uint).max) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }
}

contract X1Factory is IX1Factory {
    using SafeMath for uint;

    uint public override fee;
    uint16 public override tokenFeeRate;
    uint public override vipFee;
    address payable public override feeReceiver;
    address public override owner;

    uint16 public constant override tokenFeePrecision = 10000;

    constructor(address payable _feeReceiver, uint _fee, uint16 _tokenFeeRate, uint _vipFee) payable {
        require(address(0) != _feeReceiver);
        require(_tokenFeeRate < tokenFeePrecision);
        feeReceiver = _feeReceiver;
        owner = msg.sender;
        fee = _fee;
        tokenFeeRate = _tokenFeeRate;
        vipFee = _vipFee;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function _transferFee(uint _fee) private {
        require(msg.value >= _fee);
        feeReceiver.transfer(msg.value);
    }

    function _transferToken(address _tokenAddress, uint _totalSupply) private {
        uint feeAmount = _totalSupply;
        feeAmount = feeAmount.mul(tokenFeeRate) / tokenFeePrecision;
        IX1ERC20(_tokenAddress).transfer(feeReceiver, feeAmount);
        IX1ERC20(_tokenAddress).transfer(msg.sender, _totalSupply.sub(feeAmount));
    }

    function createToken(string calldata _name,
                         string calldata _symbol,
                         uint8 _decimals,
                         uint _totalSupply,
                         bytes calldata _vipTemplate) payable override external returns (address tokenAddress) {
        bytes memory bytecode;
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, block.number));
        if (_vipTemplate.length > 0) {
            _transferFee(vipFee);
            bytecode = _vipTemplate;
        } else {
            _transferFee(fee);
            bytecode = type(X1ERC20).creationCode;
        }
        bytecode = abi.encodePacked(bytecode, abi.encode(_name, _symbol, _decimals, _totalSupply));
        assembly {
            tokenAddress := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
        //tokenAddress = address(new X1ERC20{salt: salt}(_name, _symbol, _decimals, _totalSupply));
        emit TokenCreated(_name, _symbol, _decimals, _totalSupply, tokenAddress);

        _transferToken(tokenAddress, _totalSupply);
    }

    function setFee(uint _fee) override external onlyOwner {
        fee = _fee;
    }

    function setVIPFee(uint _vipFee) override external onlyOwner {
        vipFee = _vipFee;
    }

    function setTokenFeeRate(uint16 _tokenFeeRate) override external onlyOwner {
        require(_tokenFeeRate < tokenFeePrecision);
        tokenFeeRate = _tokenFeeRate;
    }

    function setFeeReceiver(address payable _feeReceiver) override external onlyOwner {
        require(address(0) != _feeReceiver);
        feeReceiver = _feeReceiver;
    }

    function changeOwner(address _newOwner) override external onlyOwner {
        require(_newOwner != msg.sender);
        require(address(0) != _newOwner);
        owner = _newOwner;
    }
}