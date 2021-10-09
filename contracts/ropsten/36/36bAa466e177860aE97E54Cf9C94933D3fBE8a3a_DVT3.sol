pragma solidity 0.6.12;

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
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}


contract DVT3{
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;

    string public name = "DVT3";
    string public symbol = "DVT3";
    uint8 public decimals = 18;
    address public owner;
    uint256 public totalSupply;

    event SendFlag(address addr);
    event OwnerExchanged(address indexed previousOwner, address indexed newOwner);
    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(address _owner) public {
        owner  = _owner;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return _balances[_owner];
    }

    function airDrop(bool isFrist, address account) public onlyOwner returns(bool) {
        require(account != address(0));
        uint256 amount = 1e18;
        if(isFrist) {
            amount = 5e18;
        }
        totalSupply = totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
        return true;
    }

    function transfer(address from, address to, uint256 value) public onlyOwner returns (bool) {
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
        return true;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "The caller must be owner");
        _;
    }

    function changeOwner(address newOwner) public onlyOwner returns(bool) {
        require(newOwner != address(0));
        emit OwnerExchanged(owner, newOwner);
        owner = newOwner;
        return true;
    }

    function payforflag() public onlyOwner {
        emit SendFlag(msg.sender);
    }

}