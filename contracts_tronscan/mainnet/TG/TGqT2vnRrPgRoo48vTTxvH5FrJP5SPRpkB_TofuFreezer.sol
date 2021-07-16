//SourceUnit: ITRC20.sol

pragma solidity >=0.5.0;

interface ITRC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}


//SourceUnit: SafeMath128.sol

pragma solidity ^0.5.0;

library SafeMath128 {
    function add(uint128 a, uint128 b) internal pure returns (uint128) {
        uint128 c = a + b;
        require(c >= a, "SafeMath128: addition overflow");

        return c;
    }

    function sub(uint128 a, uint128 b) internal pure returns (uint128) {
        return sub(a, b, "SafeMath128: subtraction overflow");
    }

    function sub(uint128 a, uint128 b, string memory errorMessage) internal pure returns (uint128) {
        require(b <= a, errorMessage);
        uint128 c = a - b;

        return c;
    }

    function mul(uint128 a, uint128 b) internal pure returns (uint128) {
        // optimization
        if (a == 0) {
            return 0;
        }

        uint128 c = a * b;
        require(c / a == b, "SafeMath128: multiplication overflow");

        return c;
    }

    function div(uint128 a, uint128 b) internal pure returns (uint128) {
        return div(a, b, "SafeMath128: division by zero");
    }

    function div(uint128 a, uint128 b, string memory errorMessage) internal pure returns (uint128) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint128 c = a / b;

        return c;
    }

    function mod(uint128 a, uint128 b) internal pure returns (uint128) {
        return mod(a, b, "SafeMath128: modulo by zero");
    }

    function mod(uint128 a, uint128 b, string memory errorMessage) internal pure returns (uint128) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


//SourceUnit: TRC20FreezerOps.sol

pragma solidity ^0.5.14;

import './ITRC20.sol';

interface TRC20FreezerOps {

    function token() external view returns (ITRC20);
    function freezeDuration() external view returns (uint64);

    /**
     * @dev Sets private variable for freeze duration making sanity checks beforehand.
     *
     * Can only be accessed by contract owner.
    */
    function setFreezeDuration(uint64 argFreezeDuration) external; // throws 'Forbidden', 'Too big', 'Too small'

    /**
     * @dev Withdraws APPROVED amount of serviced token from member, deposits it to this contract's address and freezes it.
    */
    function freeze(uint128 amount) external; // throws 'Withdrawal exception', 'Too much frozen for user', 'Max members reached'

    /**
     * @dev Checks if freeze is in effect and if not transfers `amount` back to member.
     * Withdraws 'all or nothing' regarding current freezed amount.
     * Returns how many funds remaining in other freezes.
    */
    function unfreeze(uint128 amount) external
        returns(uint128 remainingStakesValue); // throws 'No frozen amount', 'Freeze in effect', 'Token exception'

    /**
     * @dev Checks if freeze is in effect for all freezed funds (checks max expiry) and if not transfers `amount` back to member.
     * Withdraws 'all or nothing' regarding all freezed funds.
    */
    function unfreezeAll() external; // throws 'No frozen amount', 'Freeze in effect', 'Token exception'

    /**
     * @dev Returns records of frozen funds for member. Returns zero length array if no freezes.
     * Array elements are uint256 numbers in which 2 uint128 numbers are packed: first is frozen amount, second is expiryTimestamp.
    */
    function listFrozenRecords(address member) external view returns(uint64[] memory expiryTimestamps, uint128[] memory amounts);

    /**
     * @dev Returns total amount of frozen tokens for member. If no such funds returns 0.
    */
    function balanceOf(address member) external view returns(uint128);

    /**
     * @dev Returns expiry timestamp for member's longest freeze. If no such freezes returns 0.
    */
    function getMaxExpiry(address member) external view returns(uint64);

    event TokensFrozen(address indexed member, uint128 amount, uint64 expiryTimestamp);
    event TokensUnfrozen(address indexed member, uint128 amount);

}


//SourceUnit: TofuFreezer.sol

pragma solidity ^0.5.14;

import './ITRC20.sol';
import './SafeMath128.sol';
import './TRC20FreezerOps.sol';

contract TofuFreezer is TRC20FreezerOps {
    using SafeMath128 for uint128;

    uint32 constant public MAX_DURATION = 365 days;
    uint8 constant public MAX_FREEZES_PER_USER = 255;

    address private owner;

    ITRC20 public token;
    uint64 public freezeDuration;

    mapping (address => FreezesRecord) private freezeLedger;

    struct FreezeLog {
        uint128 amount;
        uint64 expiryTimestamp;
    }

    struct FreezesRecord {
        uint64 maxExpiryTs;
        uint128 totalAmount;
        FreezeLog[] logs;
    }

    constructor(ITRC20 argToken, uint64 argFreezeDuration) public {
        require(argFreezeDuration > 0 && argFreezeDuration <= MAX_DURATION,
            "Stake duration out of bounds: (0, MAX_DURATION]");
        token = argToken;
        freezeDuration = argFreezeDuration;
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner,
            "Forbidden");
        _;
    }

    function setFreezeDuration(uint64 argFreezeDuration) public onlyOwner {
        require(argFreezeDuration > 0,
            "Too small: 0");
        require(argFreezeDuration < MAX_DURATION,
            "Too big: MAX_DURATION");
        freezeDuration = argFreezeDuration;
    }

    function freeze(uint128 amount) public {
        address member = msg.sender;
        FreezesRecord storage record = freezeLedger[member];
        FreezeLog[] storage logs = record.logs;
        require(logs.length < MAX_FREEZES_PER_USER,
            "Too much frozen for user: MAX_FREEZES_PER_USER");

        bool success = token.transferFrom(member, address(this), amount);
        require(success,
            "Withdrawal exception");

        uint64 expiry = freezeDuration + uint64(block.timestamp);

        logs.push(FreezeLog(amount, expiry));

        record.totalAmount += amount;
        if (record.maxExpiryTs < expiry) {
            record.maxExpiryTs = expiry;
        }
        //freezeLedger[client] = record; // try remove this line

        emit TokensFrozen(member, amount, expiry);
    }

    function unfreeze(uint128 amount) public returns(uint128 remainingFrozenValue) {
        address member = msg.sender;
        FreezesRecord storage rec = freezeLedger[member];
        FreezeLog[] storage logs = rec.logs;
        uint64 size = uint64(logs.length);
        require(size > 0,
            "No frozen amount");

        uint64 nowTs = uint64(block.timestamp);
        bool notFound = true;
        for (uint64 i = 0; i < size; i++) {
            FreezeLog storage l = logs[i];

            if (l.expiryTimestamp <= nowTs && l.amount == amount) {
                // these expired so we can return them
                uint64 s = size - 1;
                if (i < s) {
                    logs[i] = logs[s];
                }
                logs.pop();

                notFound = false;
                break;
            }
        }

        if (notFound) {
            revert("Freeze in effect");
        }

        if (size - 1 /*we removed exactly one element*/ == 0) {
            // array is empty hence no frozen funds left therefore let's 'remove' it from ledger (i.e. nullify everything)
            removeRecord(rec);
            remainingFrozenValue = 0;
        }
        else {
            rec.totalAmount -= amount;
            remainingFrozenValue = rec.totalAmount;
        }

        withdraw(member, amount);
    }

    function unfreezeAll() public {
        address member = msg.sender;
        FreezesRecord storage rec = freezeLedger[member];
        require(rec.maxExpiryTs > 0,
            "No frozen amount");
        require(rec.maxExpiryTs <= block.timestamp,
            "Freeze in effect");
        withdraw(member, rec.totalAmount);
        removeRecord(rec);
        rec.logs.length = 0;
    }

    function removeRecord(FreezesRecord storage rec) private {
        rec.maxExpiryTs = 0;
        rec.totalAmount = 0;
    }

    function withdraw(address member, uint128 amount) private {
        bool withdrawalSuccess = token.transfer(member, amount);
        require(withdrawalSuccess,
            "Token exception");

        emit TokensUnfrozen(member, amount);
    }

    function listFrozenRecords(address member) public view returns(uint64[] memory expiryTimestamps, uint128[] memory amounts) {
        FreezeLog[] storage logs = freezeLedger[member].logs;

        uint64 size = uint64(logs.length);
        expiryTimestamps = new uint64[](size);
        amounts = new uint128[](size);

        if (size > 0) {
            for (uint64 i = 0; i < size; i++) {
                FreezeLog storage l = logs[i];
                expiryTimestamps[i] = l.expiryTimestamp;
                amounts[i] = l.amount;
            }
        }
    }

    function balanceOf(address member) public view returns(uint128) {
        return freezeLedger[member].totalAmount;
    }

    function getMaxExpiry(address member) public view returns(uint64) {
        return freezeLedger[member].maxExpiryTs;
    }

}