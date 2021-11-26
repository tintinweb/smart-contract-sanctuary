/**
 *Submitted for verification at snowtrace.io on 2021-11-26
*/

pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
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
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract migration is Ownable {

    IERC20 public immutable oldToken;
    IERC20 public immutable newToken;
    uint256 public factor;

    constructor(address _oldToken, address _newToken) {
        oldToken = IERC20(_oldToken);
        newToken = IERC20(_newToken);
        factor = 500;
    }

    function migrate(uint256 amount) public {
        require(newToken.balanceOf(address(this)) >= amount, "Contract does not have enough tokens");
        address user = _msgSender();
        oldToken.transferFrom(user, address(this), amount);
        newToken.transfer(user, amount * (factor / 100));
    }

    function withdrawNew() external onlyOwner {
        newToken.transfer(owner(), newToken.balanceOf(address(this)));
    }

    function withdrawOld() external onlyOwner {
        oldToken.transfer(owner(), oldToken.balanceOf(address(this)));
    }

    function setFactor(uint256 _factor) external onlyOwner {
       factor = _factor;
    }
}