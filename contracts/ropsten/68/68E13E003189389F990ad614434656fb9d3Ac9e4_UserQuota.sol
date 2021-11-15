pragma solidity ^0.8.0;

import "../Ownable.sol";

interface IQuota {
    function getUserQuota(address user) external view returns (int256);
}

contract UserQuota is Ownable, IQuota {
    mapping(address => uint256) userQuota;
    uint256 quota = 100 * 10**6; //100u
    event SetQuota(address user, uint256 amount);

    function setUserQuota(address[] memory users, uint256[] memory quotas)
        external
        onlyOwner
    {
        require(users.length == quotas.length, "PARAMS_LENGTH_NOT_MATCH");
        for (uint256 i = 0; i < users.length; i++) {
            require(users[i] != address(0), "USER_INVALID");
            userQuota[users[i]] = quotas[i];
            emit SetQuota(users[i], quotas[i]);
        }
    }

    function setUserQuota(address[] memory users) external onlyOwner {
        require(quota != 0, "QUOTA_IS_ZERO");
        for (uint256 i = 0; i < users.length; i++) {
            require(users[i] != address(0), "USER_INVALID");
            userQuota[users[i]] = quota;
            emit SetQuota(users[i], quota);
        }
    }

    function getUserQuota(address user)
        external
        view
        override
        returns (int256)
    {
        return int256(userQuota[user]);
    }

    function setQuota(uint256 _quota) external onlyOwner {
        require(_quota != 0, "QUOTA_IS_ZERO");
        quota = _quota;
    }

    function getQuota() external view returns (uint256) {
        return quota;
    }
}

pragma solidity >=0.8.0;

abstract contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

