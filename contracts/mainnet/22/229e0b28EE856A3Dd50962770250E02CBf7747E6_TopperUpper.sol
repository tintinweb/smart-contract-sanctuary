/**
 *Submitted for verification at Etherscan.io on 2021-10-26
*/

//SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
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


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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


contract FundsRecovery is Ownable {
    address payable internal fundsDestination;
    IERC20 public token;

    event DestinationChanged(
        address indexed previousDestination,
        address indexed newDestination
    );

    function setFundsDestination(address payable _newDestination)
        public
        virtual
        onlyOwner
    {
        require(_newDestination != address(0), "address is 0x0");
        emit DestinationChanged(fundsDestination, _newDestination);
        fundsDestination = _newDestination;
    }

    function getFundsDestination() public view onlyOwner returns (address) {
        return fundsDestination;
    }

    function claimNative() public {
        require(fundsDestination != address(0), "address is 0x0");
        fundsDestination.transfer(address(this).balance);
    }

    function claimTokens(address _token) public {
        require(fundsDestination != address(0), "address is 0x0");
        require(
            _token != address(token),
            "native token funds can't be recovered"
        );
        uint256 _amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(fundsDestination, _amount);
    }
}


contract TopperUpper is FundsRecovery {
    struct Limit {
        uint256 native;
        uint256 token;
        uint256 blocksWindow;
    }

    struct CurrentLimit {
        uint256 amount;
        uint256 validTill;
    }

    mapping(address => bool) public managers;
    mapping(address => Limit) public approvedAddresses;
    mapping(address => CurrentLimit) public tokenLimits; // Current period token limits
    mapping(address => CurrentLimit) public nativeLimits; // Current period native currency limits

    modifier onlyManager() {
        require(managers[_msgSender()], "Caller is not a manager");
        _;
    }

    constructor(address _token) {
        token = IERC20(_token);
    }

    receive() external payable {}

    function setManagers(address[] memory _managers) public onlyOwner {
        require(_managers.length > 0, "Please pass at least one manager");
        for (uint256 i = 0; i < _managers.length; i++) {
            managers[_managers[i]] = true;
        }
    }

    function removeManagers(address[] memory _managers) public onlyOwner {
        require(_managers.length > 0, "Invalid array length");
        for (uint256 i = 0; i < _managers.length; i++) {
            delete managers[_managers[i]];
        }
    }

    function approveAddresses(
        address[] memory _addrs,
        uint256[] memory _limitsNative,
        uint256[] memory _limitsToken,
        uint256[] memory _blocksWindow
    ) public onlyOwner {
        require(
            _addrs.length == _limitsNative.length &&
                _limitsNative.length == _limitsToken.length &&
                _blocksWindow.length == _limitsToken.length,
            "Invalid array length"
        );
        for (uint256 i = 0; i < _addrs.length; i++) {
            Limit memory limit = Limit(
                _limitsNative[i],
                _limitsToken[i],
                _blocksWindow[i]
            );
            approvedAddresses[_addrs[i]] = limit;
        }
    }

    function disapproveAddresses(address[] memory _addrs) public onlyOwner {
        require(_addrs.length > 0, "Invalid array length");
        for (uint256 i = 0; i < _addrs.length; i++) {
            delete approvedAddresses[_addrs[i]];
            delete nativeLimits[_addrs[i]];
            delete tokenLimits[_addrs[i]];
        }
    }

    function _topupNative(address payable _to, uint256 _amount) internal {
        if (block.number > nativeLimits[_to].validTill) {
            require(
                approvedAddresses[_to].native >= _amount,
                "Payout limits exceeded"
            );
            nativeLimits[_to].validTill =
                block.number +
                approvedAddresses[_to].blocksWindow;
            nativeLimits[_to].amount = approvedAddresses[_to].native - _amount;
        } else {
            require(
                nativeLimits[_to].amount >= _amount,
                "Payout limits exceeded"
            );
            nativeLimits[_to].amount -= _amount;
        }

        _to.transfer(_amount);
    }

    function topupNative(address payable _to, uint256 _amounts)
        public
        onlyManager
    {
        _topupNative(_to, _amounts);
    }

    function topupNatives(
        address payable[] memory _to,
        uint256[] memory _amounts
    ) public onlyManager {
        require(_amounts.length == _to.length, "Invalid array length");
        for (uint256 i = 0; i < _to.length; i++) {
            topupNative(_to[i], _amounts[i]);
        }
    }

    function _topupToken(address _to, uint256 _amount) internal {
        if (block.number > tokenLimits[_to].validTill) {
            require(
                approvedAddresses[_to].token >= _amount,
                "Payout limits exceeded"
            );
            tokenLimits[_to].validTill =
                block.number +
                approvedAddresses[_to].blocksWindow;
            tokenLimits[_to].amount = approvedAddresses[_to].token - _amount;
        } else {
            require(
                tokenLimits[_to].amount >= _amount,
                "Payout limits exceeded"
            );
            tokenLimits[_to].amount -= _amount;
        }

        token.transfer(_to, _amount);
    }

    function topupToken(address _to, uint256 _amounts) public onlyManager {
        _topupToken(_to, _amounts);
    }

    function topupTokens(address[] memory _to, uint256[] memory _amounts)
        public
        onlyManager
    {
        require(_amounts.length == _to.length, "Invalid array length");
        for (uint256 i = 0; i < _amounts.length; i++) {
            _topupToken(_to[i], _amounts[i]);
        }
    }
}