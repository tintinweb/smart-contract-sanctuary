/**
 *Submitted for verification at Etherscan.io on 2021-04-09
*/

pragma solidity 0.5.9;

library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b)
    internal
    pure
    returns (uint256 c)
    {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b, "SafeMath mul failed");
        return c;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b)
    internal
    pure
    returns (uint256)
    {
        require(b <= a, "SafeMath sub failed");
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b)
    internal
    pure
    returns (uint256 c)
    {
        c = a + b;
        require(c >= a, "SafeMath add failed");
        return c;
    }

    /**
     * @dev gives square root of given x.
     */
    function sqrt(uint256 x)
    internal
    pure
    returns (uint256 y)
    {
        uint256 z = ((add(x, 1)) / 2);
        y = x;
        while (z < y)
        {
            y = z;
            z = ((add((x / z), z)) / 2);
        }
    }

    /**
     * @dev gives square. multiplies x by x
     */
    function sq(uint256 x)
    internal
    pure
    returns (uint256)
    {
        return (mul(x, x));
    }

    /**
     * @dev x to the power of y
     */
    function pwr(uint256 x, uint256 y)
    internal
    pure
    returns (uint256)
    {
        if (x == 0)
            return (0);
        else if (y == 0)
            return (1);
        else
        {
            uint256 z = x;
            for (uint256 i = 1; i < y; i++)
                z = mul(z, x);
            return (z);
        }
    }

    function div(uint256 a, uint256 b)
    internal
    pure
    returns (uint256) {
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function mod(uint256 a, uint256 b)
    internal
    pure
    returns (uint256) {
        require(b != 0);
        return a % b;
    }

}

contract VisionCoin {
    using SafeMath for uint256;

    address payable public owner;
    string public name = "VisionCoin";
    string public symbol = "VC";
    uint8 public decimals = 18;
    uint256 public totalSupply = 100000000000000000000000;

    uint256 public airDropPool = 10000000000000000000000;
    uint256 public stakePool = 25000000000000000000000;
    uint256 public exchangePool = 60000000000000000000000;
    uint256 public oneCoinNeedAmount = 20000000000000000 wei;

    uint256 public limitedBlockHeight = 11662658;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public airDropAddress;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    event Burn(address indexed from, uint256 value);

    event onExchange(address indexed playerAddress, uint value);

    constructor() public {
        owner = msg.sender;
        balanceOf[owner] = totalSupply;
    }

    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != address(0x0));
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to].add(_value) > balanceOf[_to]);

        uint previousBalances = balanceOf[_from].add(balanceOf[_to]);
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from].add(balanceOf[_to]) == previousBalances);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0x0));
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_from != address(0x0));
        require(_to != address(0x0));
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public
    returns (bool success) {
        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function burn(uint256 _value) public ownerOnly(msg.sender) returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(msg.sender, _value);
        return true;
    }

    function airDrop() public returns (bool success) {
        require(block.number <= limitedBlockHeight);
        require(airDropAddress[msg.sender] == 0);
        require(airDropPool >= 2000000000000000000);
        require(balanceOf[owner] >= 2000000000000000000);

        balanceOf[msg.sender] = balanceOf[msg.sender].add(2000000000000000000);
        balanceOf[owner] = balanceOf[owner].sub(2000000000000000000);

        airDropPool = airDropPool.sub(2000000000000000000);
        airDropAddress[msg.sender] = airDropAddress[msg.sender].add(1);

        emit Transfer(owner, msg.sender, 2000000000000000000);

        return true;
    }

    function stake() public payable returns (bool success) {
        require(block.number <= limitedBlockHeight);

        uint256 stakeAmount = msg.value * 150;
        require(stakePool >= stakeAmount);

        require(balanceOf[owner] >= stakeAmount);

        balanceOf[msg.sender] = balanceOf[msg.sender].add(stakeAmount);

        balanceOf[owner] = balanceOf[owner].sub(stakeAmount);

        stakePool = stakePool.sub(stakeAmount);

        emit Transfer(owner, msg.sender, stakeAmount);

        return true;
    }

    function exchange(uint256 buyCoinAmount) public payable
    {
        require(block.number > limitedBlockHeight);

        require(msg.value >= buyCoinAmount.mul(oneCoinNeedAmount), "umm.....  you have to pay more");

        uint256 realCoinAmount = buyCoinAmount.mul(10 ** 18);

        require(exchangePool >= realCoinAmount, "umm.....  vc not enough");

        require(balanceOf[owner] >= realCoinAmount);

        balanceOf[owner] = balanceOf[owner].sub(realCoinAmount);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(realCoinAmount);

        exchangePool = exchangePool.sub(realCoinAmount);

        emit onExchange(msg.sender,buyCoinAmount);

        emit Transfer(owner, msg.sender, realCoinAmount);
    }

    function withdraw(uint256 withdrawAmount)
    ownerOnly(msg.sender)
    public
    {
        owner.transfer(withdrawAmount);
    }

    modifier ownerOnly(address addr) {
        require(addr == owner);
        _;
    }

}