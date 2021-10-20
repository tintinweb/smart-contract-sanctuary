// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract NPXSXEMigration {
    event Migrate (uint256 migrateIndex, address indexed _from, address _to, uint256 value);

    string public name = "NPXSXEM Migration";
    address public npxsxemToken;
    IERC20 public purseToken;
    uint256 public constant validDuration = 91 days;
    uint256 public endMigration;
    address public owner;
    bool public isMigrationStart;

    uint256 public migrateIndex = 0;
    mapping(uint256 => MigratorInfo) public migration;  //index->times
    mapping(address => bool) public isOwner;
    mapping(address => uint256[]) public addressMigrator;
    mapping(uint256 => uint256[11]) public airdropped;
    mapping(address => uint256) public migratorAmount;
    mapping(address => uint256) public airdropAmount;

    struct MigratorInfo {
        uint256 migrateIndex;
        address migrator;
        address to;
        uint256 migrateBalance;
    }

    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    constructor(address _npxsxemToken, IERC20 _purseToken) {
        isOwner[msg.sender] = true;
        owner = msg.sender;
        npxsxemToken = _npxsxemToken;
        purseToken = _purseToken;
    }

    function migrateNPXSXEM(address _to, uint256 _amount) public {
        require(isMigrationStart == true, "Migration is false");
        uint256 remainingAmount = purseToken.balanceOf(address(this));
        require(block.timestamp <= endMigration, "Migration window over");
        require(_amount > 0, "0 amount");
        require(remainingAmount >= _amount, "Not enough balance");

        uint256 transferAmount = (_amount * 12) / 100;
        IERC20(npxsxemToken).transferFrom(msg.sender, address(this), _amount);

        migration[migrateIndex] = MigratorInfo(migrateIndex, msg.sender, _to, _amount);
        addressMigrator[msg.sender].push(migrateIndex);
        migratorAmount[msg.sender] = migratorAmount[msg.sender] + _amount;
        airdropAmount[msg.sender] = airdropAmount[msg.sender] + transferAmount;

        purseToken.transfer(_to, transferAmount);

        emit Migrate(migrateIndex, msg.sender, _to, _amount);
        migrateIndex += 1;
    }

    function startMigration(bool check, uint256 _startMigrate) public onlyOwner {
        if (check) {
            endMigration = _startMigrate + validDuration;
            isMigrationStart = true;
        } else {
            isMigrationStart = false;
        }
    }

    function updateEndMigration(uint256 _endMigration) public onlyOwner {
        endMigration = _endMigration;
    }

    function airDrop(uint256 start, uint256 end, uint256 airdropIndex) public onlyOwner {
        require(start < end && end <= migrateIndex, "Invalid start or end");
        require(airdropIndex < 11 && airdropIndex >= 0, "index less than 0 or greater than 11");
        for (uint256 i = start; i < end; i++) {
            if (airdropped[i][airdropIndex] == 0) {
                address migrator = migration[i].migrator;
                address recipient = migration[i].to;
                uint256 amount = migration[i].migrateBalance * 8 / 100;
                airdropped[i][airdropIndex] = block.number;
                airdropAmount[migrator] = airdropAmount[migrator] + amount;
                purseToken.transfer(recipient, amount);
            }
        }
    }

    function migratedCount(address addr) public view returns (uint256){
        return addressMigrator[addr].length;
    }

    function migrateState(uint256 index) public view returns (uint256[11] memory){
        return airdropped[index];
    }

    function returnPurseToken(address _to) public onlyOwner {
        require(_to != address(0), "send to the zero address");
        uint256 remainingAmount = purseToken.balanceOf(address(this));
        purseToken.transfer(_to, remainingAmount);
    }

    function returnAnyToken(address token, uint256 amount, address _to) public onlyOwner {
        require(_to != address(0), "send to the zero address");
        IERC20(token).transfer(_to, amount);
    }

    function updateOwner(address _owner) public onlyOwner {
        require(_owner != address(0), "not valid address");
        require(_owner != owner, "same owner address");
        isOwner[_owner] = true;
        owner = _owner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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