//SourceUnit: CoinToken.sol

pragma solidity ^0.5.10;

import "./Erc20Token.sol";

contract CoinToken is Erc20Token {
    address public admin_address; //

    modifier verify_admin() {
        require(msg.sender == admin_address, "no admin Auth");
        _;
    }

    //
    event Burn(address indexed burner, uint256 value);
    //
    event Increases(address indexed burner, uint256 value);

    //
    function updateAdmin(address newAdmin)
        external
        verify_admin
        returns (bool)
    {
        admin_address = newAdmin;
        return true;
    }

    //
    function increases(address[] memory tos, uint256[] memory moneys)
        public
        verify_admin
        returns (bool)
    {
        require(tos.length == moneys.length, "length error");
        uint256 sumMoney = 0;
        for (uint256 index = 0; index < tos.length; index++) {
            if (moneys[index] > 0) {
                sumMoney = sumMoney.add(moneys[index]);
                balances[tos[index]] = balances[tos[index]].add(moneys[index]);
            }
            emit Increases(tos[index], moneys[index]);
            emit Transfer(address(this), tos[index], moneys[index]);
        }
        totalSupply = totalSupply.add(sumMoney);
        return true;
    }

    //
    function increase(address to, uint256 money)
        public
        verify_admin
        returns (bool)
    {
        if (money > 0) {
            balances[to] = balances[to].add(money);
        }
        emit Increases(to, money);
        emit Transfer(address(this), to, money);
        totalSupply = totalSupply.add(money);
        return true;
    }

    //
    function transfers(address[] memory tos, uint256[] memory moneys)
        public
        returns (bool success)
    {
        require(tos.length == moneys.length, "length error");
        uint256 sumMoney = 0;
        for (uint256 index = 0; index < moneys.length; index++) {
            sumMoney = sumMoney.add(moneys[index]);
        }
        require(balances[msg.sender] >= sumMoney, "not balance");
        balances[msg.sender] = balances[msg.sender].sub(sumMoney);
        for (uint256 index = 0; index < tos.length; index++) {
            if (moneys[index] > 0) {
                balances[tos[index]] = balances[tos[index]].add(moneys[index]);
                emit Transfer(msg.sender, tos[index], moneys[index]);
            }
        }
        return true;
    }

    //
    function withDraw(address payable to, uint256 money)
        public
        verify_admin
        returns (bool)
    {
        require(address(this).balance > money, "not balance");
        to.transfer(money);
        return true;
    }

    //
    function withDrawToken(
        address tokenAddress,
        address toAddress,
        uint256 money
    ) public verify_admin returns (bool) {
        Erc20Token baseToken = Erc20Token(tokenAddress);
        baseToken.transfer(toAddress, money);
        return true;
    }

    function() external payable {}

    //
    function kill() external verify_admin returns (bool) {
        selfdestruct(msg.sender);
        return true;
    }
}


//SourceUnit: Erc20Token.sol

pragma solidity ^0.5.10;

import "./SafeMath.sol";

contract Erc20Token {
    using SafeMath for uint256;
    uint256 public totalSupply;
    uint8 public decimals; //
    string public name; //
    string public symbol; //

    mapping(address => uint256) balances; //

    mapping(address => mapping(address => uint256)) allowed; //

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function transfer(address to, uint256 value) external returns (bool) {
        require(to != address(0), "to address error");
        require(balances[msg.sender] >= value, "lack of balance");
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool) {
        require(allowed[from][msg.sender] >= value, "lack of allowed");
        require(balances[from] >= value, "lack of balance");
        balances[to] = balances[to].add(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        balances[from] = balances[from].sub(value);
        emit Transfer(from, to, value);
        return true;
    }

    function balanceOf(address who) external view returns (uint256) {
        return balances[who];
    }

    function allowance(address owner, address spender)
        external
        view
        returns (uint256)
    {
        return allowed[owner][spender];
    }

}


//SourceUnit: McoinToken.sol

pragma solidity ^0.5.10;

import "./CoinToken.sol";

contract McoinToken is CoinToken {
    CoinToken public assetToken;

    address public mbidefi_address;
    uint256 public sell_max;
    uint256 public sell_current = 0;
    uint256 public mining_max = 0;
    uint256 public mining_current = 0;
    uint256 public admin_rate = 25;
    uint256 public price_rate = 10000;

    event Buy(address indexed burner, uint256 value);
    event Mining(address indexed burner, uint256 value);

    modifier verify_mbidefi() {
        require(
            msg.sender == mbidefi_address,
            "This function is restricted to the contract's mbidefi"
        );
        _;
    }

    constructor(
        uint256 _totalSupply,
        uint8 _decimals,
        string memory _name,
        string memory _symbol,
        address _adminAddress
    ) public {
        totalSupply = _totalSupply.mul(10**uint256(_decimals));
        balances[_adminAddress] = totalSupply;
        admin_address = _adminAddress;
        name = _name;
        decimals = _decimals;
        symbol = _symbol;
    }

    //
    function mining(address to, uint256 money)
        external
        verify_mbidefi
        returns (bool)
    {
        if (mining_max < mining_current.add(money)) {
            return false;
        }
        //
        mining_current = mining_current.add(money);

        //
        balances[to] = balances[to].add(money);

        //
        uint256 admin_money = money.mul(admin_rate).div(100);
        balances[admin_address] = balances[admin_address].add(admin_money);

        //
        totalSupply = money.add(admin_money).add(totalSupply);
        emit Mining(to, money);
        emit Transfer(address(this), to, money);
        return true;
    }

    //
    function setMbi(
        address _mbidefiTokenAddress,
        address payable _assetTokenAddress,
        uint256 _sell_max,
        uint256 _sell_current,
        uint256 _mining_max,
        uint256 _mining_current,
        uint256 _admin_rate,
        uint256 _price_rate
    ) external verify_admin returns (bool) {
        mbidefi_address = _mbidefiTokenAddress;
        assetToken = CoinToken(_assetTokenAddress);
        sell_max = _sell_max;
        mining_max = _mining_max;
        admin_rate = _admin_rate;
        price_rate = _price_rate;
        sell_current = _sell_current;
        mining_current = _mining_current;
        return true;
    }

    //
    function buy(uint256 money) external returns (bool) {
        require(sell_max > sell_current.add(money), "sell ok");
        //
        require(
            assetToken.transferFrom(msg.sender, admin_address, money),
            "lack of balance"
        );
        uint256 amount = money.mul(price_rate).div(10000);
        //
        sell_current = sell_current.add(amount);

        //
        balances[msg.sender] = balances[msg.sender].add(amount);

        //
        uint256 admin_money = amount.mul(admin_rate).div(100);
        balances[admin_address] = balances[admin_address].add(admin_money);

        totalSupply = amount.add(admin_money).add(totalSupply);
        emit Buy(msg.sender, amount);
        emit Transfer(address(this), msg.sender, amount);
        return true;
    }
}


//SourceUnit: SafeMath.sol

pragma solidity ^0.5.10;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath#mul: OVERFLOW");

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath#div: DIVISION_BY_ZERO");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath#sub: UNDERFLOW");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath#add: OVERFLOW");

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath#mod: DIVISION_BY_ZERO");
        return a % b;
    }
}