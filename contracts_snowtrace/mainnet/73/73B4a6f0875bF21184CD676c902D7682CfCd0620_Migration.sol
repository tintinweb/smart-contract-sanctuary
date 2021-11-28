/**
 *Submitted for verification at snowtrace.io on 2021-11-27
*/

pragma solidity >=0.8.0;

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


contract Migration is Ownable {

    IERC20 public immutable oldToken;
    IERC20 public immutable newToken;

    uint256 public factor1;
    uint256 public factor2;
    uint256 public factor3;

    uint256 public timestamp1;
    uint256 public timestamp2;
    uint256 public timestamp3;
    uint256 public timestamp4;

    bool public blockBots;
    bool public migratingEnabled;

    constructor(address _oldToken, address _newToken) {
        oldToken = IERC20(_oldToken);
        newToken = IERC20(_newToken);
        factor1 = 100;
        factor2 = 80;
        factor3 = 70;

        timestamp1 = block.timestamp;
        timestamp2 = block.timestamp + 600 seconds;
        timestamp3 = block.timestamp + 1200 seconds;
        timestamp4 = block.timestamp + 1800 seconds;

        blockBots = true;
        migratingEnabled = true;
    }

    function MIGRATE(uint256 _amount) external {
        if (blockBots) {
            require(msg.sender == tx.origin, "You are contract");
        }

        require (migratingEnabled, "migrating is disabled ");

        address _user = msg.sender;

        if (block.timestamp >= timestamp1 && block.timestamp < timestamp2) {
            migrate1(_user, _amount);
        }

        else if (block.timestamp >= timestamp2 && block.timestamp < timestamp3) {
            migrate2(_user, _amount);
        }

        else if (block.timestamp >= timestamp3 && block.timestamp < timestamp4) {
            migrate3(_user, _amount);
        }

        else {
            revert();
        }
    }

    function migrate1(address user, uint256 amount) internal {
        require(oldToken.balanceOf(user) >= amount, "You do not have enough tokens");
        require(newToken.balanceOf(address(this)) >= amount, "Contract does not have enough tokens");
        require(oldToken.transferFrom(user, address(this), amount), "transfer failed");
        newToken.transfer(user, amount * (factor1 / 100));
    }

    function migrate2(address user, uint256 amount) internal {
        require(oldToken.balanceOf(user) >= amount, "You do not have enough tokens");
        require(newToken.balanceOf(address(this)) >= amount, "Contract does not have enough tokens");
        require(oldToken.transferFrom(user, address(this), amount), "transfer failed");
        newToken.transfer(user, amount * (factor2 / 100));
    }

    function migrate3(address user, uint256 amount) internal {
        require(oldToken.balanceOf(user) >= amount, "You do not have enough tokens");
        require(newToken.balanceOf(address(this)) >= amount, "Contract does not have enough tokens");
        require(oldToken.transferFrom(user, address(this), amount), "transfer failed");
        newToken.transfer(user, amount * (factor3 / 100));
    }

    function withdrawNew() external onlyOwner {
        newToken.transfer(owner(), newToken.balanceOf(address(this)));
    }

    function withdrawOld() external onlyOwner {
        oldToken.transfer(owner(), oldToken.balanceOf(address(this)));
    }

    function setFactor1(uint256 _factor) external onlyOwner {
       factor1 = _factor;
    }

    function setFactor2(uint256 _factor) external onlyOwner {
       factor2 = _factor;
    }

    function setFactor3(uint256 _factor) external onlyOwner {
       factor3 = _factor;
    }

    function setTimestamp1(uint256 _timestamp) external onlyOwner {
       timestamp1 = _timestamp;
    }

    function setTimestamp2(uint256 _timestamp) external onlyOwner {
       timestamp2 = _timestamp;
    }

    function setTimestamp3(uint256 _timestamp) external onlyOwner {
       timestamp3 = _timestamp;
    }

    function setTimestamp4(uint256 _timestamp) external onlyOwner {
       timestamp4 = _timestamp;
    }

    function setBlockBots(bool onoff) external onlyOwner {
       blockBots = onoff;
    }

    function setMigratingEnabled(bool onoff) external onlyOwner {
       migratingEnabled = onoff;
    }

    function withdrawTokens(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
    }

    function getStage(uint256 currrentBlockTimestamp) public view returns (string memory stage) {
        if (currrentBlockTimestamp >= timestamp1 && currrentBlockTimestamp < timestamp2) {
            return "1";
        }

        else if (currrentBlockTimestamp >= timestamp2 && currrentBlockTimestamp < timestamp3) {
            return "2";
        }

        else if (currrentBlockTimestamp >= timestamp3 && currrentBlockTimestamp < timestamp4) {
            return "3";
        }
    }
}