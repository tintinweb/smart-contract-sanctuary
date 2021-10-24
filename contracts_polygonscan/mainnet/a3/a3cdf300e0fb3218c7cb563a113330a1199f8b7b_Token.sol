// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <=0.8.9;

import "./IERC20.sol";

import "./Owner.sol";
import "./SafeMath.sol";
import "./TransferHelper.sol";

contract Token is IERC20, Owner {
    using SafeMath for uint256;
    
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) internal _allowances;

    uint256 internal _totalSupply;
    uint8 internal _decimals;
    string internal _symbol;
    string internal _name;

    address public InformationalFeeContract;
    uint256 public startingDirectSwapTimestamp;
    uint256 public directSwapFee = 500;
    
    struct DirectSwapInfo {
        address dstoken;
        uint256 dsmultiplier;
    }
    
    DirectSwapInfo[] public directSwapInfo;
    
    mapping(address => uint256) internal _dsmultipliers;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 totalSupply_,
        address _InformationalFeeContract
    ) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = totalSupply_.div(200).add(totalSupply_);
        _balances[msg.sender] = totalSupply_;
        _balances[_InformationalFeeContract] = totalSupply_.div(200);

        InformationalFeeContract = _InformationalFeeContract;

        emit Transfer(address(0), msg.sender, totalSupply_);
        emit Transfer(
            address(0),
            _InformationalFeeContract,
            totalSupply_.div(200)
        );
    }
    
    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        external
        view
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        external
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
    ) external override returns (bool) {
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

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function mint(address _to, uint256 _amount)
        external
        override
        isOwner
        returns (bool)
    {
        _mint(_to, _amount);
        return true;
    }

    function burn(uint256 amount) external override returns (bool) {
        _burn(msg.sender, amount);
        return true;
    }
    
    function setStartingDirectSwapTimestamp(uint256 timestamp) external isOwner {
        startingDirectSwapTimestamp = timestamp;
    }
    
    function setDirectSwapFee(uint256 fee) external isOwner {
        require(fee <= 10000, "Invalid directSwapFee");
        directSwapFee = fee;
    }
    
    function setDirectSwapInfo(address[] memory _tokens, uint256[] memory _multipliers) external isOwner {
        require(_tokens.length == _multipliers.length, "Invalid directSwapInfo");
        
        for (uint i = 0; i < directSwapInfo.length; i++) {
            _dsmultipliers[directSwapInfo[i].dstoken]=0;
        }
        
        delete directSwapInfo;
        
        for (uint i = 0; i < _tokens.length; i++) {
            directSwapInfo.push(
                DirectSwapInfo({
                    dstoken: _tokens[i],
                    dsmultiplier: _multipliers[i]
                })
            );
            _dsmultipliers[_tokens[i]] = _multipliers[i];
        }
    }
    
    function directSwap(address tokenFrom, uint256 amount) external {
        require(amount > 0, "amount 0");
        require(_dsmultipliers[tokenFrom] > 0, "There is no multiplier to this tokenFrom");
        require(IERC20(tokenFrom).balanceOf(msg.sender) >= amount, "Not enough tokenFrom");
        require(block.timestamp >= startingDirectSwapTimestamp, "directSwap is not allowed yet");
        
        uint256 fee = amount.mul(directSwapFee).div(10000);
        uint256 tokenFromAmount = amount.sub(fee);
        uint256 tokenAmount = tokenFromAmount.mul(_dsmultipliers[tokenFrom]).div(1e12);
        
        _mint(msg.sender, tokenAmount);
        TransferHelper.safeTransferFrom(tokenFrom, msg.sender, BURN_ADDRESS, amount);
        
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = amount.div(200).add(amount).add(_totalSupply);
        _balances[account] = _balances[account].add(amount);
        _balances[InformationalFeeContract] = amount.div(200).add(
            _balances[InformationalFeeContract]
        );
        emit Transfer(address(0), account, amount);
        emit Transfer(address(0), InformationalFeeContract, amount.div(200));
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(
            account,
            msg.sender,
            _allowances[account][msg.sender].sub(amount)
        );
    }
    
}