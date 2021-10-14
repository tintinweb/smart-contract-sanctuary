/**
 *Submitted for verification at BscScan.com on 2021-10-14
*/

/**
 *Submitted for verification at BscScan.com on 2021-03-17
*/

/*

 ____      __                                               __                
/\  _`\   /\ \__                                           /\ \               
\ \,\L\_\ \ \ ,_\     __      __       ___ ___       __    \_\ \              
 \/_\__ \  \ \ \/   /'__`\  /'__`\   /' __` __`\   /'__`\  /'_` \             
   /\ \L\ \ \ \ \_ /\  __/ /\ \L\.\_ /\ \/\ \/\ \ /\  __/ /\ \L\ \            
   \ `\____\ \ \__\\ \____\\ \__/.\_\\ \_\ \_\ \_\\ \____\\ \___,_\           
    \/_____/  \/__/ \/____/ \/__/\/_/ \/_/\/_/\/_/ \/____/ \/__,_ /           
 __  __                                                                          
/\ \/\ \                                                  
\ \ \_\ \      __       ___ ___      ____                 
 \ \  _  \   /'__`\   /' __` __`\   /',__\                
  \ \ \ \ \ /\ \L\.\_ /\ \/\ \/\ \ /\__, `\               
   \ \_\ \_\\ \__/.\_\\ \_\ \_\ \_\\/\____/               
    \/_/\/_/ \/__/\/_/ \/_/\/_/\/_/ \/___/                
                                                   

                                                                                

Website:
SteamedHams.finance

Twitter:
@Sthamstoken

Telegram:
https://t.me/joinchat/3TiY9-FzAO5kNDRk

Github:
https://github.com/stehams



*/

pragma solidity ^0.5.11;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

//SafeMath
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
        uint256 c = a / b;
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

    function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
        uint256 c = add(a, m);
        uint256 d = sub(c, 1);
        return mul(div(d, m), m);
    }
}

// Boilerplate for IERC20
contract ERC20Detailed is IERC20 {
    uint8 private _Tokendecimals;
    string private _Tokenname;
    string private _Tokensymbol;

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals
    ) public {
        _Tokendecimals = decimals;
        _Tokenname = name;
        _Tokensymbol = symbol;
    }

    function name() public view returns (string memory) {
        return _Tokenname;
    }

    function symbol() public view returns (string memory) {
        return _Tokensymbol;
    }

    function decimals() public view returns (uint8) {
        return _Tokendecimals;
    }
}

//Contract details
contract STHAMS is ERC20Detailed {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowed;
    string constant tokenName = "PC Coin";
    string constant tokenSymbol = "PCCP";
    uint8 constant tokenDecimals = 18;
    uint256 constant easyDecimals = 1000000000000000000;
    uint256 _totalSupply = 200000000 * easyDecimals;

    IERC20 currentToken;
    address payable public _owner;

    //Modifiers
    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

    //Create initialSupply
    constructor()
        public
        payable
        ERC20Detailed(tokenName, tokenSymbol, tokenDecimals)
    {
        _owner = msg.sender;
        require(_totalSupply != 0);
        _balances[_owner] = _balances[_owner].add(_totalSupply);
        emit Transfer(address(0), _owner, _totalSupply);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    function allowance(address owner, address spender)
        public
        view
        returns (uint256)
    {
        return _allowed[owner][spender];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        _executeTransfer(msg.sender, to, value);
        return true;
    }

    function multiTransfer(address[] memory receivers, uint256[] memory values)
        public
    {
        require(receivers.length == values.length);
        for (uint256 i = 0; i < receivers.length; i++)
            _executeTransfer(msg.sender, receivers[i], values[i]);
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public returns (bool) {
        require(value <= _allowed[from][msg.sender]);
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _executeTransfer(from, to, value);
        return true;
    }

    //Burn
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    //Burning Function
    function _burn(address account, uint256 amount) internal {
        require(amount != 0);
        require(amount <= _balances[account]);
        _totalSupply = _totalSupply.sub(amount);
        _balances[account] = _balances[account].sub(amount);
        emit Transfer(account, address(0), amount);
    }

    // No zeros for decimals necessary
    function multiTransferEqualAmount(
        address[] memory receivers,
        uint256 amount
    ) public {
        uint256 amountWithDecimals = amount * 10**uint256(tokenDecimals);

        for (uint256 i = 0; i < receivers.length; i++) {
            transfer(receivers[i], amountWithDecimals);
        }
    }

    // Standart `IERC20.approve`.
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    // Mitigate the well-known issues around setting  allowances
    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        require(spender != address(0));
        _allowed[msg.sender][spender] = (
            _allowed[msg.sender][spender].add(addedValue)
        );
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    // Mitigate the well-known issues around setting  allowances
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        require(spender != address(0));
        _allowed[msg.sender][spender] = (
            _allowed[msg.sender][spender].sub(subtractedValue)
        );
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    // Take back unclaimed tokens
    function withdrawUnclaimedTokens(address contractUnclaimed)
        external
        onlyOwner
    {
        currentToken = IERC20(contractUnclaimed);
        uint256 amount = currentToken.balanceOf(address(this));
        currentToken.transfer(_owner, amount);
    }

    // Allow transfers from one wallet to another
    function _executeTransfer(
        address _from,
        address _to,
        uint256 _value
    ) private {
        if (_to == address(0)) revert();
        if (_value <= 0) revert();
        if (_balances[_from] < _value) revert();
        if (_balances[_to] + _value < _balances[_to]) revert();

        _balances[_from] = SafeMath.sub(_balances[_from], _value);
        _balances[_to] = SafeMath.add(_balances[_to], _value);
        emit Transfer(_from, _to, _value);
    }
}