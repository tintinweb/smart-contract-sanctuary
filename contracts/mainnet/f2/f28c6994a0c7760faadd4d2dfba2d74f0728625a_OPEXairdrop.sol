pragma solidity 0.4.23;

contract ERC20BasicInterface {
    event Transfer(address indexed from, address indexed to, uint256 value);

    function decimals() public view returns (uint8);
    function name() public view returns (string);
    function symbol() public view returns (string);
    function totalSupply() public view returns (uint256 supply);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
}

contract ERC20Interface is ERC20BasicInterface {
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
}

/**
 * @title ERC20Pocket
 *
 * This contract keeps particular token for the single owner.
 *
 * Original purpose is to be able to separate your tokens into different pockets for dedicated purposes.
 * Whenewer a withdrawal happen, it will be transparent that tokens were taken from a particular pocket.
 *
 * Contract emits purely informational events when transfers happen, for better visualisation on explorers.
 */
contract OPEXairdrop is ERC20BasicInterface {
    ERC20Interface public constant TOKEN = ERC20Interface(0x0b34a04b77Aa9bd2C07Ef365C05f7D0234C95630);
    address public constant OWNER = 0xCba6eE74b7Ca65Bd0506cf21d62bDd7c71F86AD8;
    string constant NAME = &#39;Optherium Airdrop Tokens&#39;;
    string constant SYMBOL = &#39;OPEXairdrop&#39;;

    modifier onlyOwner() {
        require(msg.sender == OWNER, &#39;Access denied&#39;);
        _;
    }

    function deposit(uint _value) public onlyOwner() returns(bool) {
        require(TOKEN.transferFrom(OWNER, address(this), _value), &#39;Deposit failed&#39;);
        emit Transfer(0x0, OWNER, _value);
        return true;
    }

    function withdraw(address _to, uint _value) public onlyOwner() returns(bool) {
        require(TOKEN.transfer(_to, _value), &#39;Withdrawal failed&#39;);
        emit Transfer(OWNER, 0x0, _value);
        return true;
    }

    function totalSupply() public view returns(uint) {
        return TOKEN.balanceOf(address(this));
    }

    function balanceOf(address _holder) public view returns(uint) {
        if (_holder == OWNER) {
            return totalSupply();
        }
        return 0;
    }

    function decimals() public view returns(uint8) {
        return TOKEN.decimals();
    }

    function name() public view returns(string) {
        return NAME;
    }

    function symbol() public view returns(string) {
        return SYMBOL;
    }

    function transfer(address _to, uint _value) public returns(bool) {
        if (_to == address(this)) {
            deposit(_value);
        } else {
            withdraw(_to, _value);
        }
        return true;
    }

    function recoverTokens(ERC20BasicInterface _token, address _to, uint _value) public onlyOwner() returns(bool) {
        require(address(_token) != address(TOKEN), &#39;Can not recover this token&#39;);
        return _token.transfer(_to, _value);
    }
}