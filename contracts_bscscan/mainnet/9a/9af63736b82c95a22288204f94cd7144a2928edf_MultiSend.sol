/**
 *Submitted for verification at BscScan.com on 2021-08-03
*/

pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }
    
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

contract MultiSend is Ownable {
    mapping(address => bool) private _isWhiteList;

    modifier onlyWhiteList() {
        require(_isWhiteList[msg.sender], "You do not have execute permission");
        _;
    }

    constructor () {
        _isWhiteList[msg.sender] = true;
    }

    receive() external payable {}

    function addWhiteList(address[] calldata _account) external onlyOwner() {
        for (uint256 i = 0; i < _account.length; i++) {
            _isWhiteList[_account[i]] = true;
        }
    }

    function isWhiteList(address _account) public view returns (bool) {
        return _isWhiteList[_account];
    }

    function RecoverERC20(address _tokenAddress) public onlyWhiteList {
        uint256 balance = IERC20(_tokenAddress).balanceOf(address(this));
        IERC20(_tokenAddress).transfer(owner(), balance);
    }

    function RecoverETH() public onlyWhiteList() {
        address owner = owner();
        payable(owner).transfer(address(this).balance);
    }

    function MultiSendETH(address[] calldata _users, uint256 _amount) external payable onlyWhiteList {
        require(_amount != 0, 'amount is 0');
        require(_users.length != 0, 'users is 0');

        uint256 userCount = _users.length;
        uint256 balance = address(this).balance;

        require(balance >= _amount * userCount, 'Insufficient balance');
        // send eth
        for (uint256 i = 0; i < userCount; i++) {
            payable(_users[i]).transfer(_amount);
        }
        if (address(this).balance != 0) {
            RecoverETH();
        }
    }

    function BulkSendETH(address[] calldata _users, uint256[] calldata _amount) external payable onlyWhiteList {
        require(address(this).balance != 0, 'balance is 0');
        require(_amount.length != 0, 'amount is 0');
        require(_users.length != 0, 'users is 0');

        uint256 amountCount = _amount.length;
        uint256 userCount = _users.length;

        require(amountCount == userCount, 'counter do not match');
        // send eth
        for (uint256 i = 0; i < userCount; i++) {
            payable(_users[i]).transfer(_amount[i]);
        }
        if (address(this).balance != 0) {
            RecoverETH();
        }
    }
    
    function MultiSendToken(address[] calldata _users, uint256 _amount, address _tokenAddress) external onlyWhiteList {
        require(_amount != 0, 'amount is 0');
        require(_users.length != 0, 'users is 0');

        uint256 userCount = _users.length;

        IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amount * userCount);
        // send token
        for (uint256 i = 0; i < userCount; i++) {
            IERC20(_tokenAddress).transfer(_users[i], _amount);
        }
        if (IERC20(_tokenAddress).balanceOf(address(this)) != 0) {
            RecoverERC20(_tokenAddress);
        }
    }

    function BulkSendToken(address[] calldata _users, uint256[] calldata _amount, address _tokenAddress) external onlyWhiteList {
        require(_amount.length != 0, 'amount is 0');
        require(_users.length != 0, 'users is 0');

        uint256 amountCount = _amount.length;
        uint256 userCount = _users.length;

        require(amountCount == userCount, 'counter do not match');
        // check amount
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amountCount; i++) {
            totalAmount += _amount[i];
        }

        IERC20(_tokenAddress).transferFrom(msg.sender, address(this), totalAmount);
        // send token
        for (uint256 i = 0; i < userCount; i++) {
            IERC20(_tokenAddress).transfer(_users[i], _amount[i]);
        }
        if (IERC20(_tokenAddress).balanceOf(address(this)) != 0) {
            RecoverERC20(_tokenAddress);
        }
    }
    

}