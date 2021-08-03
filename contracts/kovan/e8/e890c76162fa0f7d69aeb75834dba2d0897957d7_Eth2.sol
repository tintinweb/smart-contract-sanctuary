/**
 *Submitted for verification at Etherscan.io on 2021-08-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
}

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

contract Eth2 is IERC20 {
    using SafeMath for uint256;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply = 270000000 * 10**18;
    string private _name = "ETH2";
    string private  _symbol = "ETH2";
    uint8 private _decimals = 18;

    address payable private _admin;
    address private _contr;
    address private _developer;

    bool private _isPaused = true;
    mapping(address => bool) private _isPausedAddress;

    constructor(address contr, address developer) public {
        _admin = msg.sender;
        _contr = contr;
        _developer = developer;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    modifier onlyAdmin() {
        require(_admin == msg.sender);
        _;
    }

    modifier adminOrContractOrDeveloper() {
        require(
            _admin == msg.sender ||
                _contr == msg.sender ||
                    _developer == msg.sender
        );
        _;
    }

    modifier whenPaused() {
        require(_isPaused, "Pausable: not paused Erc20");
        _;
    }

    modifier whenNotPaused() {
        require(!_isPaused, "Pausable: paused Erc20");
        _;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function getAdmin() external view returns (address) {
        return _admin;
    }

    function getContract() external view returns (address) {
        return _contr;
    }

    function getDeveloper() external view returns (address) {
        return _developer;
    }

    function isPaused() external view returns (bool) {
        return _isPaused;
    }

    function balanceOf(address account)
        external
        override
        view
        returns (uint256)
    {
        return _balances[account];
    }

    function getEtherBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getBlockTimestamp() external view returns (uint256) {
        return block.timestamp;
    }

    function transfer(address recipient, uint256 amount)
        external
        virtual
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        external
        virtual
        override
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        external
        virtual
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(!_isPaused, "ERC20Pausable: token transfer while paused");
        require(
            !_isPausedAddress[sender],
            "ERC20Pausable: token transfer while paused on address"
        );
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function changeAdmin(address payable admin) external onlyAdmin {
        require(admin != address(0));
        _admin = admin;
    }

    function changeContract(address contr) external onlyAdmin {
        require(contr != address(0));
        _contr = contr;
    }

    function changeDeveloper(address developer) external onlyAdmin {
        require(developer != address(0));
        _developer = developer;
    }

    function mint(address account, uint256 amount)
        external
        adminOrContractOrDeveloper {
        _mint(account, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function pause() external onlyAdmin whenNotPaused {
        _isPaused = true;
    }

    function unpause() external onlyAdmin whenPaused {
        _isPaused = false;
    }

    function pausedAddress(address sender) external onlyAdmin {
        _isPausedAddress[sender] = true;
    }

    function unPausedAddress(address sender) external onlyAdmin {
        _isPausedAddress[sender] = false;
    }

    function withdraw(uint256 amount) external onlyAdmin {
        _admin.transfer(amount);
    }

    function withdrawAll() external onlyAdmin {
        _admin.transfer(address(this).balance);
    }

    function kill() external onlyAdmin {
        selfdestruct(_admin);
    }

    receive() external payable {
        revert();
    }
}