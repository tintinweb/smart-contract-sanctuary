/**
 *Submitted for verification at BscScan.com on 2021-12-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


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
        _transferOwnership(_msgSender());
    }

    
    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }


    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }


    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract BitContracts is Ownable {
    mapping(address => bool) private bitcoincopyContracts;

    function addToBitcoinCOPYContracts(address _bitContract) public onlyOwner {
        require(!bitcoincopyContracts[_bitContract], "This contract is already a bitcoin-copyContract");
        bitcoincopyContracts[_bitContract] = true;
    }
    function removeBitcoinCOPYContract(address _bitContract) public onlyOwner {
        bitcoincopyContracts[_bitContract] = false;
    }

    function isBitiContract(address _cont) public view returns(bool){
        return(bitcoincopyContracts[_cont]);
    }

    modifier isBitContract() {
        require(bitcoincopyContracts[_msgSender()], "This contract is not a bitcoin-copy contract");
        _;
    }
}

abstract contract BotProtection is Ownable {
    uint256 private maxTradable = 10000 ether;
    uint256 private constant botProtectionLength = 300; // in seconds

    function setMaxTradable(uint256 _max) public onlyOwner {
        maxTradable = _max;
    }

    function _scan(uint256 activationTS, uint256 amount, address from, address to) internal view returns(bool){
        if(_msgSender() == owner() || (from == owner() || to == owner())){
            return true;
        }else{
            require(activationTS != 0, "BTC-C20: Token has not yet been activated");
            if(block.timestamp > activationTS+botProtectionLength){
                return true;
            }else{
                require(amount <= maxTradable, "Cannot trade more than the max the first 5 minutes");
                return true;
            }
        }
    }

    modifier noBotAllowed(uint256 activationTS, uint256 amount, address from, address to) {
       require(_scan(activationTS, amount, from, to), "BotProtection: potential bot behavior");
        _;
    }
}

interface BITI20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface BITI20Metadata is BITI20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract BTCC is BotProtection, BITI20, BITI20Metadata {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint256 private constant _maxSupply = 100000000 ether;
    string private _name = "Bitcoin-COPY";
    string private _symbol = "BTC-C";

    bool public active;
    uint256 public activationTimestamp;
    uint256 public transactionFees = 7; // Fees 7/1000 = 0.007 => 0.7% 

    function setTXNFees(uint256 _txnFee) external onlyOwner {
        require(_txnFee <= 30, "BTC-C20: transaction fees are capped at 3%");
        transactionFees = _txnFee;
    }

    enum Allocations {
        INITIAL,
        TEAM,
        MARKETING,
        PARTNERS,
        NFTFARMING,
        VESTING,
        IDO,
        STAKING,
        RESERVE,
        P2E
    }

    struct BitAllocations {
        uint256 _allocationPercentage;
        address _allocationAddress;
        bool _allocated;
    }

    mapping(Allocations => BitAllocations) private _allocations;

    constructor() {
        initAllocations();
    }

    function ActivateBtcc() external onlyOwner {
        require(!active, "BTC-C20: can only activate the token contract once");
        activationTimestamp = block.timestamp;
        active = true;
    }


    function initAllocations() internal {
        _allocations[Allocations.INITIAL] = BitAllocations(40,msg.sender,false);
        _allocations[Allocations.TEAM] = BitAllocations(120, address(0),  false);
        _allocations[Allocations.MARKETING] = BitAllocations(86, msg.sender,  false);
        _allocations[Allocations.PARTNERS] = BitAllocations(80, address(0),  false);
        _allocations[Allocations.NFTFARMING] = BitAllocations(200, address(0),  false);
        _allocations[Allocations.VESTING] = BitAllocations(50, address(0),  false);
        _allocations[Allocations.IDO] = BitAllocations(34, address(0),  false);
        _allocations[Allocations.STAKING] = BitAllocations(100, address(0), false);
        _allocations[Allocations.RESERVE] = BitAllocations(140, address(0),  false);
        _allocations[Allocations.P2E] = BitAllocations(150, address(0), false);
    }

    function setAllocAddress(Allocations alloc, address allocAddr) external onlyOwner {
        require(_allocations[alloc]._allocationAddress == address(0),"BTC-C20: allocation already has an address");
        _allocations[alloc]._allocationAddress = allocAddr;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function maxSupply() public pure returns(uint256) {
        return _maxSupply;
    }
 
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
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

    function transferFrom( address sender,address recipient,uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "BTC-C20: transfer amount exceeds allowance");
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
        require(currentAllowance >= subtractedValue, "BTC-C20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }
        return true;
    }

    function releaseAllocation(Allocations alloc) external onlyOwner {
        require(_canAllocate(alloc), "BTC-C20: Cannot Allocate Funds");
        _mint(_allocations[alloc]._allocationAddress, _calculateAllocation(_allocations[alloc]._allocationPercentage));
        _allocations[alloc]._allocated = true;
    }

    function _calculateAllocation(uint256 allocPercentage) internal pure returns(uint256){
        return(((allocPercentage*_maxSupply)/1000));
    }

    function _canAllocate(Allocations alloc) internal view returns(bool) {
        require(!_allocations[alloc]._allocated, "BTC-C20: Already Allocated");
        require(_allocations[alloc]._allocationAddress != address(0), "BTC-C20: Cannot allocate to zero address");
        return true;
    }

    function _calculateTXNFees(uint256 amount) internal view returns(uint256 postAmount, uint256 feesAmount){
        if(amount > 1 ether){
            feesAmount = ((amount*transactionFees)/1000);
        }else{
            feesAmount = 0;
        }
        postAmount = (amount - feesAmount);
    }

    function _transfer(address sender,address recipient,uint256 amount) internal virtual {
        require(sender != address(0), "BTC-C20: transfer from the zero address");
        require(recipient != address(0), "BTC-C20: transfer to the zero address");
        _beforeTokenTransfer(sender, recipient, amount);
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "BTC-C20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        (uint256 recpAmount, uint256 fees) = _calculateTXNFees(amount);
        _balances[recipient] += recpAmount;
        _balances[owner()] += fees;
        emit Transfer(sender, recipient, amount);
        _afterTokenTransfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "BTC-C20: mint to the zero address");
        require(_totalSupply + amount <= _maxSupply, "BTC-C20: cannot mint more than max supply");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "BTC-C20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "BTC-C20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(address owner,address spender,uint256 amount) internal virtual {
        require(owner != address(0), "BTC-C20: approve from the zero address");
        require(spender != address(0), "BTC-C20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from,address to,uint256 amount) internal virtual noBotAllowed(activationTimestamp, amount, from, to) {

    }


    function _afterTokenTransfer(address from,address to,uint256 amount) internal virtual {

    }
}