/**
 *Submitted for verification at BscScan.com on 2021-12-21
*/

// SPDX-License-Identifier: MIT
// File: presale/SafeMath.sol

pragma solidity ^0.6.12;

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a, 'SafeMath:INVALID_ADD');
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b <= a, 'SafeMath:OVERFLOW_SUB');
        c = a - b;
    }

    function mul(
        uint256 a,
        uint256 b,
        uint256 decimal
    ) internal pure returns (uint256) {
        uint256 dc = 10**decimal;
        uint256 c0 = a * b;
        require(a == 0 || c0 / a == b, 'SafeMath: multiple overflow');
        uint256 c1 = c0 + (dc / 2);
        require(c1 >= c0, 'SafeMath: multiple overflow');
        uint256 c2 = c1 / dc;
        return c2;
    }

    function div(
        uint256 a,
        uint256 b,
        uint256 decimal
    ) internal pure returns (uint256) {
        require(b != 0, 'SafeMath: division by zero');
        uint256 dc = 10**decimal;
        uint256 c0 = a * dc;
        require(a == 0 || c0 / a == dc, 'SafeMath: division internal');
        uint256 c1 = c0 + (b / 2);
        require(c1 >= c0, 'SafeMath: division internal');
        uint256 c2 = c1 / b;
        return c2;
    }
}

// File: presale/Token.sol

pragma solidity ^0.6.12;

abstract contract ERC20Interface {
    function totalSupply() public view virtual returns (uint256);

    function balanceOf(address tokenOwner) public view virtual returns (uint256 balance);

    function allowance(address tokenOwner, address spender)
        public
        view
        virtual
        returns (uint256 remaining);

    function transfer(address to, uint256 tokens) public virtual returns (bool success);

    function approve(address spender, uint256 tokens)
        public
        virtual
        returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) public virtual returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

abstract contract ApproveAndCallFallBack {
    function receiveApproval(
        address from,
        uint256 tokens,
        address token,
        bytes memory data
    ) public virtual;
}

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract Pausable is Owned {
    event Pause();
    event Unpause();

    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }

    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}

contract BullToken is ERC20Interface, Owned, Pausable {
    using SafeMath for uint256;

    address public dev;
    address public antisnipe;
    string public symbol;
    string public name;
    uint8 public decimals;
    uint256 public total_supply;
    uint256 public rate_receiver; // (!) input value precision follow "decimals"
    uint256 public rate_max_transfer; // (!) input value precision follow "decimals"
    uint256 public total_mint;
    bool public is_mintable;
    bool public antisnipeEnabled;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    mapping(address => bool) public tax_list;
    mapping(address => bool) public tax_whitelist;
    mapping(address => bool) public antiWhale_list;
    mapping(address => bool) public minter_list;

    event UpdateMintable(bool status);
    event UpdateDevAddress(address dev);
    event UpdateTaxAddress(address target_address, bool status);
    event UpdateTaxWhitelist(address target_address, bool status);
    event UpdateRateReceiver(uint256 rate);
    event UpdateRateMaxTransfer(uint256 rate);
    event UpdateAntiWhaleList(address account, bool status);
    event UpdateMinter(address minter, bool status);

    constructor(
        address _dev,
        uint256 _rate_receiver,
        uint256 _rate_max_transfer
    ) public {
        symbol = 'BULL';
        name = 'Bull Token';
        decimals = 18;
        total_supply = 10000000000 * 10**uint256(decimals);
        dev = _dev;
        rate_receiver = _rate_receiver;
        rate_max_transfer = _rate_max_transfer;
        is_mintable = true;
        antisnipeEnabled = true;

        minter_list[msg.sender] = true;
    }

    modifier antiWhale(
        address from,
        address to,
        uint256 amount
    ) {
        if (maxTransferAmount() > 0) {
            if (antiWhale_list[from] || antiWhale_list[to]) {
                require(
                    amount <= maxTransferAmount(),
                    'antiWhale: Transfer amount exceeds the maxTransferAmount'
                );
            }
        }
        _;
    }

    modifier isMinter() {
        require(minter_list[msg.sender], 'Not allowed to mint');
        _;
    }

    function totalSupply() public view override returns (uint256) {
        return total_supply.sub(balances[address(0)]);
    }

    function circulateSupply() public view returns (uint256) {
        return total_mint.sub(balances[address(0)]);
    }

    function balanceOf(address tokenOwner)
        public
        view
        override
        returns (uint256 balance)
    {
        return balances[tokenOwner];
    }

    function approve(address spender, uint256 tokens)
        public
        override
        whenNotPaused
        returns (bool success)
    {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transfer(address to, uint256 tokens)
        public
        override
        whenNotPaused
        antiWhale(msg.sender, to, tokens)
        returns (bool success)
    {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        _transfer(msg.sender, to, tokens);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) public override whenNotPaused antiWhale(from, to, tokens) returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        _transfer(from, to, tokens);
        return true;
    }

    function setAntisnipeAddress(address _address) external onlyOwner {
        antisnipe = _address;
    }

    function setAntisnipeDisable() external onlyOwner {
        require(antisnipeEnabled);
        antisnipeEnabled = false;
    }

    function _transfer(
        address from,
        address to,
        uint256 tokens
    ) internal {
        if (antisnipeEnabled && address(antisnipe) != address(0)) {
            require(IAntisnipe(antisnipe).assureCanTransfer(msg.sender, from, to, tokens, owner));
        }
        
        /*
         * fullfill all requirment below to apply fee
         * 1. "from" or "to" address is in blacklist
         * 2. "from" or "to" address is not in whitelist
         */
        if (
            (tax_list[from] || tax_list[to]) &&
            !(tax_whitelist[from] || tax_whitelist[to])
        ) {
            // send token by calculate allocation to receiver
            uint256 amount = tokens.mul(rate_receiver, decimals);
            balances[to] = balances[to].add(amount);
            emit Transfer(from, to, amount);

            // send remaining token to dev
            uint256 amount_dev = tokens.sub(amount);
            if (amount_dev > 0) {
                balances[dev] = balances[dev].add(amount_dev);
                emit Transfer(from, dev, amount_dev);
            }
        } else {
            // send full amount to receiver
            balances[to] = balances[to].add(tokens);
            emit Transfer(from, to, tokens);
        }
    }

    function allowance(address tokenOwner, address spender)
        public
        view
        override
        returns (uint256 remaining)
    {
        return allowed[tokenOwner][spender];
    }

    function approveAndCall(
        address spender,
        uint256 tokens,
        bytes memory data
    ) public whenNotPaused returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(
            msg.sender,
            tokens,
            address(this),
            data
        );
        return true;
    }

    function updateMinter(address minter, bool status) public onlyOwner {
        minter_list[minter] = status;
        emit UpdateMinter(minter, status);
    }

    function mint(address _address, uint256 amount) public isMinter {
        _mint(_address, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), 'mint to the zero address');
        require(is_mintable, 'not mintable');
        uint256 tmp_total = total_mint.add(amount);
        require(tmp_total <= total_supply, 'total supply exceed');

        balances[account] = balances[account].add(amount);
        total_mint = total_mint.add(amount);
        emit Transfer(address(0), account, amount);
    }

    function transferAnyERC20Token(address tokenAddress, uint256 tokens)
        public
        onlyOwner
        returns (bool success)
    {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }

    function maxTransferAmount() public view returns (uint256) {
        return circulateSupply().mul(rate_max_transfer, decimals);
    }

    function updateRateMaxTransfer(uint256 rate) public onlyOwner returns (bool) {
        rate_max_transfer = rate;
        emit UpdateRateMaxTransfer(rate_max_transfer);
        return true;
    }

    function updateMintable(bool status) public onlyOwner returns (bool) {
        is_mintable = status;
        emit UpdateMintable(status);
        return true;
    }

    function updateDevAddress(address _dev) public onlyOwner returns (bool) {
        dev = _dev;
        emit UpdateDevAddress(_dev);
        return true;
    }

    function updateTaxAddress(address _address, bool status)
        public
        onlyOwner
        returns (bool)
    {
        tax_list[_address] = status;
        emit UpdateTaxAddress(_address, status);
        return true;
    }

    function updateTaxWhitelist(address _address, bool status)
        public
        onlyOwner
        returns (bool)
    {
        tax_whitelist[_address] = status;
        emit UpdateTaxWhitelist(_address, status);
        return true;
    }

    function updateAntiWhaleList(address _address, bool status)
        public
        onlyOwner
        returns (bool)
    {
        antiWhale_list[_address] = status;
        emit UpdateAntiWhaleList(_address, status);
        return true;
    }

    function updateRateReceiver(uint256 _rate_receiver) public onlyOwner returns (bool) {
        rate_receiver = _rate_receiver;
        emit UpdateRateReceiver(_rate_receiver);
        return true;
    }

    fallback() external payable {
        revert();
    }

    receive() external payable{
      
    }
}

interface IAntisnipe {
    function assureCanTransfer(
        address sender,
        address from,
        address to,
        uint256 amount,
        address owner
    ) external returns (bool response);
}