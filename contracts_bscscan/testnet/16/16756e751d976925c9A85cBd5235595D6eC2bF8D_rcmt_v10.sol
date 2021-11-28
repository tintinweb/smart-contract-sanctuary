/**
 *Submitted for verification at BscScan.com on 2021-11-27
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract rcmt_v10 is Context, IERC20, IERC20Metadata, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private lastTrans;
    mapping(address => bool) private whitelist;
    mapping(address => bool) private botBlackList;
    bool private paused = false;
    uint256 private _totalSupply;
    uint256 private antiBotTime = 10;
    string private _name;
    string private _symbol;
    uint256 private actualMinted = 0;
    uint256 private mintTimer = 0;
    uint256 private maxMintPerWeek = 100000;
    bool private initMint = false;

    constructor() {
        _name = "RaCaMeT Coin v11";
        _symbol = "RV11";
        address develop = address(0xf31fF790003fB2b19d025fBf4Bab3699f97B149f);
        address market = address(0xcF1446127F665Da61CB9600cEA13581d5cF44D76);
        whitelist[msg.sender] = true;
        whitelist[develop] = true;
        whitelist[market] = true;
        initMint = true;
        mint(msg.sender, 7500000000);
        mint(develop, 1500000000);
        mint(market, 1000000000);
        initMint = false;
    }

    function name() public view override returns (string memory) {
        return _name;
    }
 
    function withdrawToken(address _tokenContract, uint256 _amount) external onlyOwner {
        IERC20 tokenContract = IERC20(_tokenContract);
        tokenContract.transfer(msg.sender, _amount);
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }
    
    function setAntiBotTime(uint256 timesec)  external onlyOwner {
        antiBotTime = timesec;
    }
    
    function setPaused(bool _paused)  external onlyOwner {
        paused = _paused;
    }

    function decimals() public pure override returns (uint8) {
        return 3;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function isWhitelisted(address addr) external onlyOwner view returns (bool) {
        return whitelist[addr];
    }

    function isBlacklisted(address addr) external onlyOwner view returns (bool) {
        return botBlackList[addr];
    }

    function addWhitelisted(address addr) external onlyOwner {
        whitelist[addr] = true;
    }
    
    function addBotlisted(address addr) external onlyOwner {
        botBlackList[addr] = true;
    }

    function removeWhitelisted(address addr) external onlyOwner {
        whitelist[addr] = false;
    }
    
    function removeBotlisted(address addr) external onlyOwner {
        botBlackList[addr] = false;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        assert(botBlackList[sender] != true);
        assert(botBlackList[recipient] != true);
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        assert(currentAllowance >= amount);
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        assert(currentAllowance >= subtractedValue);
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }


    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        assert(paused == false);
        assert(sender != address(0));
        assert(recipient != address(0));
        assert(botBlackList[sender] != true);
        assert(botBlackList[recipient] != true);
        assert(whitelist[sender] == true || block.timestamp - lastTrans[sender] > antiBotTime);
        assert(whitelist[recipient] == true || block.timestamp - lastTrans[recipient] > antiBotTime);

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        assert(senderBalance >= amount);
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        lastTrans[sender] = block.timestamp;
        lastTrans[recipient] = block.timestamp;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }


    function mint(address account, uint256 amount) public onlyOwner {
        assert(account != address(0));
        if (!initMint) {
            assert(block.timestamp - mintTimer > 604800);
            if (amount+actualMinted >= maxMintPerWeek) {
                amount = (amount+actualMinted)-maxMintPerWeek;
            }
            actualMinted += amount;
            if (actualMinted > maxMintPerWeek) {
                mintTimer = block.timestamp;
            }
        }
        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }
    
 function _burn(address account, uint256 amount) internal {
    require(account != address(0), "BEP20: burn from the zero address");
    emit Transfer(account, address(0), amount);
  }


    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        assert(owner != address(0));
        assert(spender != address(0));

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal {}


    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal {}
}