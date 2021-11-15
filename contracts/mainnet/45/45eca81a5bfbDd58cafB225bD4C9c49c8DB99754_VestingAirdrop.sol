//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.0 <=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IVesting.sol";
import "./interfaces/IAirdrop.sol";

contract VestingAirdrop is Ownable, IAirdrop {
    IERC20 public token;
    
    bytes32 public root;
    IVesting public vesting;
    uint256 public vestingAmount;
    uint256 public vestingDuration;
    uint256 public vestingCliff;

    mapping (address => bool) public claimed;

    event Claim(address _recipient, uint256 amount);

    constructor(
        address _token,
        address _owner,
        bytes32 _root,
        address _vesting,
        uint256 _vestingAmount,
        uint256 _vestingCliff,
        uint256 _vestingDuration)
    public {
        token = IERC20(_token);
        root = _root;
        vesting = IVesting(_vesting);
        vestingAmount = _vestingAmount;
        vestingCliff = _vestingCliff;
        vestingDuration = _vestingDuration;
        transferOwnership(_owner);
    }

    /**
     * @notice Modifies the underlying set for the Merkle tree. It is an error
     *          to call this function with an incorrect size or root hash.
     * @param _root The new Merkle root hash
     * @dev Only the owner of the contract can modify the Merkle set.
     *
     */
    function setMerkleSet(
        bytes32 _root
    ) external override onlyOwner() {
        root = _root;
    }

    /**
     * @notice Deposits tokens into the airdrop contract
     * @param amount The quantity of ERC20 tokens to deposit
     *
     */
    function deposit(uint256 amount) external override {
        /* bounds check deposit amount */
        require(amount > 0, "ADP: Zero deposit");

        /* transfer tokens to airdrop contract */
        bool transferResult = token.transferFrom(
            msg.sender,
            address(this),
            amount
        );

        /* handle failure */
        require(transferResult, "ADP: ERC20 transfer failed");
    }

    /**
     * @notice Withdraws the allocated quantity of tokens to the caller
     * @param proof The proof of membership of the Merkle tree
     * @param amount The number of tokens the caller is claiming
     * @dev Marks caller as claimed if proof checking succeeds and emits the
     *      `Claim` event.
     *
     */
    function withdraw(
        bytes32[] calldata proof,
        uint256 amount
    ) external override {
        /* check for multiple claims */
        require(!claimed[msg.sender], "ADP: Already claimed");

        /* check the caller's Merkle proof */
        bool proofResult = checkProof(proof, hash(msg.sender, amount));

        /* handle proof checking failure */
        require(proofResult, "ADP: Invalid proof");

        /* mark caller as claimed */
        claimed[msg.sender] = true;

        /* transfer tokens from airdrop contract to caller */
        bool transferResult = token.transfer(msg.sender, amount);

        /* handle failure */
        require(transferResult, "ADP: ERC20 transfer failed");

        /* Send tokens to vesting */
        token.transfer(address(vesting), vestingAmount);

        /* Set vesting for the user */
        vesting.setVestingSchedule(
            msg.sender,
            vestingAmount,
            false,
            vestingCliff,
            vestingDuration
        );

        /* emit appropriate event */
        emit Claim(msg.sender, amount);
    }

    /**
     * @notice Withdraws all tokens currently held by the airdrop contract
     * @dev Only the owner of the airdrop contract can call this method
     *
     */
    function bail() external override onlyOwner() {
        /* retrieve current token balance of the airdrop contract */
        uint256 tokenBalance = token.balanceOf(address(this));

        /* transfer all tokens in the airdrop contract to the owner */
        bool transferResult = token.transfer(msg.sender, tokenBalance);

        require(transferResult, "ADP: ERC20 transfer failed");
    }

    function cancelVestingSchedule(address account, uint256 scheduleId) external onlyOwner() {
        vesting.cancelVesting(account, scheduleId);
    }

    function withdrawFromVesting(uint256 amount) external onlyOwner() {
        vesting.withdraw(amount);
    }

    /**
    * @notice helper function for anyone to validate if a given proof is valid given a claimer and amount 
    */
    function validClaim(bytes32[] calldata proof, address claimer, uint amount) public view returns(bool) {
        return checkProof(proof, hash(claimer, amount));
    }

    /**
     * @notice Verifies a membership proof using another leaf node of the Merkle
     *          tree
     * @param proof The Merkle hash of the relevant data block
     * @param claimantHash The Merkle hash the caller is looking to prove is a
     *          member of the Merkle set
     *
     */
    function checkProof(
        bytes32[] calldata proof,
        bytes32 claimantHash
    ) internal view returns (bool) {
        bytes32 currElem = 0;
        bytes32 currHash = claimantHash;

        for(uint256 i=0;i<proof.length;i++) {
            currElem = proof[i];

            /* alternate what order we concatenate in */
            if (currElem < currHash) {
                currHash = keccak256(abi.encodePacked(currHash, currElem));
            } else {
                currHash = keccak256(abi.encodePacked(currElem, currHash));
            }
        }
        
        return currHash == root;
    }

    function logBase2(uint256 n) internal pure returns (uint256) {
        uint256 res = 0;

        if (n >= 2**128) { n >>= 128; res += 128; }
        if (n >= 2**64) { n >>= 64; res += 64; }
        if (n >= 2**32) { n >>= 32; res += 32; }
        if (n >= 2**16) { n >>= 16; res += 16; }
        if (n >= 2**8) { n >>= 8; res += 8; }
        if (n >= 2**4) { n >>= 4; res += 4; }
        if (n >= 2**2) { n >>= 2; res += 2; }
        if (n >= 2**1) { /* n >>= 1; */ res += 1; }

        return res;
    }

    /**
     * @notice Generates the Merkle hash given address and amount
     * @param recipient The address of the recipient
     * @param amount The quantity of tokens the recipient is entitled to
     * @return The Merkle hash of the leaf node needed to prove membership
     *
     */
    function hash(
        address recipient,
        uint256 amount
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(recipient, amount));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../GSN/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/**
* Tracer vesting interface. See https://github.com/tracer-protocol/tracer-dao
*/
interface IVesting {
    /**
     * @notice Sets up a vesting schedule for a set user
     * @dev adds a new Schedule to the schedules mapping
     * @param account the account that a vesting schedule is being set up for. Will be able to claim tokens after
     *                the cliff period.
     * @param amount the amount of tokens being vested for the user.
     * @param isFixed a flag for if the vesting schedule is fixed or not. Fixed vesting schedules can't be cancelled.
     */
    function setVestingSchedule(
        address account,
        uint256 amount,
        bool isFixed,
        uint256 cliffWeeks,
        uint256 vestingWeeks
    ) external;

    /**
     * @notice allows users to claim vested tokens if the cliff time has passed
     */
    function claim(uint256 vestingId) external;

    /**
     * @notice Allows a vesting schedule to be cancelled.
     * @dev Any outstanding tokens are returned to the system.
     * @param account the account of the user whos vesting schedule is being cancelled.
     */
    function cancelVesting(address account, uint256 proposalId) external;

    /**
     * @notice returns the total amount and total claimed amount of a users vesting schedule.
     * @param account the user to retrieve the vesting schedule for.
     */
    function getVesting(address account, uint256 proposalId)
        external
        view
        returns (uint256, uint256);

    /**
     * @notice calculates the amount of tokens to distribute to an account at any instance in time, based off some
     *         total claimable amount.
     * @param amount the total outstanding amount to be claimed for this vesting schedule
     * @param currentTime the current timestamp
     * @param startTime the timestamp this vesting schedule started
     * @param endTime the timestamp this vesting schedule ends
     */
    function calcDistribution(
        uint256 amount,
        uint256 currentTime,
        uint256 startTime,
        uint256 endTime
    ) external pure returns (uint256);

    /**
    * @notice Withdraws TCR tokens from the contract.
    * @dev blocks withdrawing locked tokens.
    */
    function withdraw(uint amount) external;
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.0 <=0.8.0;

interface IAirdrop {
    function setMerkleSet(bytes32 _root) external;
    function deposit(uint256 amount) external;
    function withdraw(bytes32[] calldata proof, uint256 amount) external;
    function bail() external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

