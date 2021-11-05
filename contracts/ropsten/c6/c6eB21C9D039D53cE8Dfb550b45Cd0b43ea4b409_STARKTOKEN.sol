/**
 *Submitted for verification at Etherscan.io on 2021-11-05
*/

pragma solidity ^0.6.0;



interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract STARKTOKEN is IERC20 {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    address public owner;

    string public name;
    string public symbol;
    uint8 public decimals;

    constructor() public {
        name = "STARK Token";
        symbol = "SAT";
        decimals = 18;
        owner = msg.sender;

        //1 million tokens to be generated
        _totalSupply = 1000000 * 10**uint256(decimals);
        //transfer total supply to owner
        _balances[owner] = _totalSupply;

        //fire an event on transfer of tokens
        emit Transfer(address(this), owner, _totalSupply);
    }

    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address sender = msg.sender;
        require(sender != address(0), "BCC1: transfer from the zero address");
        require(recipient != address(0), "BCC1: transfer to the zero address");
        require(
            _balances[sender] > amount,
            "BCC1: transfer amount exceeds balance"
        );

        //decrease the balance of token sender account
        _balances[sender] = _balances[sender] - amount;

        //increase the balance of token recipient account
        _balances[recipient] = _balances[recipient] + amount;

        emit Transfer(sender, recipient, amount);
        return true;
    }

    function allowance(address tokenOwner, address spender)
        public
        virtual
        override
        view
        returns (uint256)
    {
        return _allowances[tokenOwner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address tokenOwner = msg.sender;
        require(
            tokenOwner != address(0),
            "BCC1: approve from the zero address"
        );
        require(spender != address(0), "BCC1: approve to the zero address");
        _allowances[tokenOwner][spender] = amount;
        emit Approval(tokenOwner, spender, amount);
        return true;
    }

    function transferFrom(
        address tokenOwner,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = msg.sender;
        uint256 _allowance = _allowances[tokenOwner][spender];
        require(_allowance > amount, "BCC1: transfer amount exceeds allowance");
        //deducting allowance
        _allowance = _allowance - amount;
        //--- start transfer execution --
        //owner decrease balance
        _balances[tokenOwner] = _balances[tokenOwner] - amount;
        //transfer token to recipient;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(tokenOwner, recipient, amount);
        //-- end transfer execution--
        //decrease the approval amount;
        _allowances[tokenOwner][spender] = _allowance;
        emit Approval(tokenOwner, spender, amount);
        return true;
    }
}