/**
 *Submitted for verification at Etherscan.io on 2021-09-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

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

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BadiumToken is IERC20, Ownable {
    //    later private
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;
    mapping(address => bool) public receivers;
    uint256 private _totalSupply;
    address[] private ownersList;
    mapping(address => uint256) private ownersIndexes;

    uint256 constant PURCHASE_RATE = 100;
    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        uint initSupply = 10000000 * 1e18;
        _mint(msg.sender, initSupply);
        ownersList.push(msg.sender);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return balances[account];
    }

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external override returns (bool){
        address sender = msg.sender;
        require(receivers[recipient] || sender == owner(), "Recipient is not in allowed receivers");
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        uint256 senderBalance = balances[sender];
        require(senderBalance >= amount, "Not enough tokens");
        balances[sender] = senderBalance - amount;
        balances[recipient] += amount;
        addTokenOwner(recipient);
        removeTokenOwner(sender);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view override returns (uint256) {
        return allowances[owner][spender];
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external override returns (bool) {
        require(spender != address(0), "can not approve to zero address");
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (msg.sender != owner()){
            require(sender != address(0));
            require(recipient != address(0));
            require(allowances[sender][msg.sender] >= amount, "Not enough allowance");
            require(receivers[recipient], "Only receivers can receive tokens");
            allowances[sender][msg.sender] -= amount;
        }
        require(balances[sender] >= amount, "Not enough balance");
        balances[sender] -= amount;
        balances[recipient] += amount;
        addTokenOwner(recipient);
        removeTokenOwner(sender);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function setReceiver(address _account, bool _isReceiver) public onlyOwner {
        receivers[_account] = _isReceiver;
    }

    function getReceiver(address _account) public view returns(bool) {
        return receivers[_account];
    }

    function _mint(address recipient, uint256 amount) private {
        _totalSupply += amount;
        balances[recipient] += amount;
        addTokenOwner(recipient);
        emit Transfer(address(0), recipient, amount);
    }

    function mint(address recipient, uint256 amount) external onlyOwner {
        _mint(recipient, amount);
    }

    function burn(address account, uint256 amount) external onlyOwner {
        require(balances[account] >= amount, "not enough balance to burn");
        _totalSupply -= amount;
        balances[account] -= amount;
        removeTokenOwner(account);
        emit Transfer(account, address(0), amount);
    }

    function buyTokens(address recipient) public payable {
        require(recipient != address(0), "can not buy to zero address");
        uint256 tokensToBuy = msg.value * PURCHASE_RATE;
        require(balanceOf(owner()) >= tokensToBuy, "not enough tokens to buy");
        balances[owner()] -= tokensToBuy;
        balances[msg.sender] += tokensToBuy;
        addTokenOwner(msg.sender);
    }

    receive() external payable {
        buyTokens(msg.sender);
    }

    function addTokenOwner(address newOwner) private {
        if (newOwner == owner()){return;}
        if (ownersIndexes[newOwner] == 0){
            ownersIndexes[newOwner] = ownersList.length;
            ownersList.push(newOwner);
        }
    }

    function removeTokenOwner(address owner) private {
        if(balances[owner] > 0){return;}
        uint remIndex = ownersIndexes[owner];
        delete ownersList[remIndex];
        ownersList[remIndex] = ownersList[ownersList.length - 1];
        ownersIndexes[ownersList[remIndex]] = remIndex;
        ownersList.pop();
    }

    function burnAll() public onlyOwner returns(uint256) {
        uint arrayLength = ownersList.length;
        address ownerAddr;
        for (uint i=0; i<arrayLength; i++) {
            ownerAddr = ownersList[i];
            _totalSupply -= balances[ownerAddr];
            balances[ownerAddr] = 0;
        }
        return _totalSupply;
    }

}