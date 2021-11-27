//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract TikTakToken {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    address owner = msg.sender;

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    string private _name = "Tic Tac Token";
    string private _symbol = "TTT";
    uint8 private decimal = 18;
    uint256 private _totalSupply = 0; //total tokens

    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event Approval(address indexed _from, address indexed _to, uint256 _amount);

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return decimal;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _account) public view returns (uint256) {
        return _balances[_account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(recipient != address(0), "Tic Tac Token: transfered to nowhere");

        uint256 senderBalance = _balances[msg.sender];
        require(senderBalance >= amount,"Tic Tac Token: you're asking for too much");

        _balances[msg.sender] -= amount;
        _balances[recipient] += amount;

        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        require(spender != address(0), "Tic Tac Token: approved to nowhere");

        _allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function allowance(address _owner, address spender)
        public
        view
        returns (uint256)
    {
        return _allowances[_owner][spender];
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) {
        require(recipient != address(0), "Tic Tac Token: transfered to nowhere");
        require(sender == msg.sender || _allowances[sender][msg.sender] >= amount, "Tic Tac Token: you are not owner or approval address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Tic Tac Token: you're asking for too much");

        _allowances[sender][msg.sender] -= amount;

        _balances[sender] -= amount;
        _balances[recipient] += amount;

        return true;
    }

    function mint(address _to, uint256 _amount) public onlyOwner {
        require(_to != address(0), "Tic Tac Token: transfered to nowhere");
        require(_amount > 0, "Tic Tac Token: amount is too small");

        _balances[_to] += _amount;
        _totalSupply += _amount;
    }
}