// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./VOYCEVote.sol";

contract VOYCEVoteFactory is Ownable {
    address voceVoteImplementation;
    IERC20 voyceToken;
    
    VOYCEVote[] public voyceVotes;

    event FactorySettingsModified(address voyceToken, address voceVoteImplementation);
    event VOYCEVoteCreated(address voyceVoteAddress);

    constructor() {}

    function setFactorySettings(address voyceToken_, address voceVoteImplementation_)
        external
        onlyOwner
    {
        require(voyceToken_ != address(0), "voyceToken_: zero address");
        require(
            voceVoteImplementation_ != address(0),
            "voceVoteImplementation_: zero address"
        );
        voyceToken = IERC20(voyceToken_);
        voceVoteImplementation = voceVoteImplementation_;

        emit FactorySettingsModified(voyceToken_, voceVoteImplementation_);
    }

    function createPoll(
        uint256 startTime,
        uint256 endTime,
        uint256 quorum
    ) external onlyOwner returns (address voyceVoteAddress) {
        VOYCEVote voyceVote = VOYCEVote(Clones.clone(voceVoteImplementation));
        voyceVote.initialize(startTime, endTime, quorum, voyceToken);

        voyceVotes.push(voyceVote);

        voyceVoteAddress = address(voyceVote);

        emit VOYCEVoteCreated(voyceVoteAddress);
    }

    function getVOYCEVotesLength() external view returns (uint256) {
        return voyceVotes.length;
    }

    function fetch(uint256 startIndex, uint256 length)
        external
        view
        returns (address[] memory result, uint256 resultLength)
    {
        result = new address[](length);
        for (uint256 i = startIndex; i < length && i < voyceVotes.length; i++) {
            address poll = address(voyceVotes[i]);
            if (poll != address(0)) {
                resultLength++;
                result[i] = poll;
            } else break;
        }
    }

    function fetchReverse(uint256 startIndex, uint256 length)
        external
        view
        returns (address[] memory result, uint256 resultLength)
    {
        result = new address[](length);
        startIndex = startIndex > voyceVotes.length - 1 ? voyceVotes.length - 1 : startIndex;
        for (int256 i = int256(startIndex); i >= 0; i--) {
            address poll = address(voyceVotes[uint256(i)]);
            if (poll != address(0)) {
                result[resultLength++] = poll;
            } else break;
        }
    }

    function getVOYCEVoteDetails(address voyceVoteAddress)
        external
        view
        returns (
            address[] memory addresses,
            uint256[] memory uints,
            bool[] memory bools,
            string[] memory strings,
            string[] memory charityNames
        )
    {
        return VOYCEVote(voyceVoteAddress).getDetails();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VOYCEVote is Ownable {
    uint256 public startTime;
    uint256 public endTime;
    uint256 public quorum;
    bool public executed;
    bool public canceled;
    string public cancelationReason;

    uint256 public castedVotes;
    uint256 public amountToHold = 1e18; // at least 1 token

    struct CharityOption {
        string charityName;
    }

    CharityOption[] public options;

    mapping(bytes32 => bool) private charityExists;
    mapping(int32 => uint256) public votesPerOption;
    mapping(address => bool) public hasVoted;
    mapping(address => int32) public userVote;
    mapping(address => uint256) voterIndex;

    address[] voters;

    IERC20 public tokenToHold;

    bool initialized;
    modifier initializer() {
        require(!initialized, "VOYCEVote: already initialized");
        initialized = true;
        _;
    }

    event Proposed(address indexed proposedBy, string charityName);
    event VoteCasted(address indexed from, int32 indexed optionId);
    event Unvoted(address indexed from);
    event Executed(uint256 indexed executedOn);
    event Canceled(string reason);
    event AmountToHoldModified(uint256 oldValue, uint256 newValue);

    constructor() {}

    function initialize(
        uint256 startTime_,
        uint256 endTime_,
        uint256 quorum_,
        IERC20 tokenToHold_
    ) external initializer {
        require(startTime_ > block.timestamp, "wrong starting block");
        require(endTime_ > startTime_, "wrong end block");
        startTime = startTime_;
        endTime = endTime_;
        quorum = quorum_;
        tokenToHold = tokenToHold_;
        // transfer ownership to factory owner
        _transferOwnership(Ownable(msg.sender).owner());
    }

    function nominateCharity(string memory charityName) external onlyOwner {
        bytes32 hash = keccak256(abi.encodePacked(charityName));
        require(!charityExists[hash], "charity already exists");
        require(block.timestamp < startTime, "Poll already started");
        charityExists[hash] = true;
        options.push(CharityOption(charityName));
        emit Proposed(msg.sender, charityName);
    }

    function castVote(int32 optionId) external {
        require(block.timestamp >= startTime, "Poll is not open yet");
        require(block.timestamp < endTime, "Poll is already close");
        require(!hasVoted[msg.sender], "vote already casted");
        require(
            tokenToHold.balanceOf(msg.sender) >= amountToHold,
            "amountToHold not met"
        );
        hasVoted[msg.sender] = true;
        userVote[msg.sender] = int32(optionId);
        votesPerOption[optionId]++;
        castedVotes++;
        voters.push(msg.sender);
        voterIndex[msg.sender] = voters.length - 1;
        emit VoteCasted(msg.sender, optionId);
    }

    function unVote() external {
        require(block.timestamp >= startTime, "Poll is not open yet");
        require(block.timestamp < endTime, "Poll is already close");
        require(hasVoted[msg.sender], "not voted yet");
        require(
            tokenToHold.balanceOf(msg.sender) >= amountToHold,
            "amountToHold not met"
        );
        int32 optionId = userVote[msg.sender];
        hasVoted[msg.sender] = false;
        userVote[msg.sender] = -1;
        votesPerOption[optionId]--;
        castedVotes--;
        voters[voterIndex[msg.sender]] = voters[voters.length - 1];
        voterIndex[voters[voters.length - 1]] = voterIndex[msg.sender];
        delete voters[voters.length - 1];

        emit Unvoted(msg.sender);
    }

    function execute() external onlyOwner {
        require(block.timestamp >= endTime, "Poll is not close yet");
        require(quorum == 0 || castedVotes >= quorum, "quorum not reached");
        require(!canceled, "already canceled");
        executed = true;
        emit Executed(block.number);
    }

    function cancel(string memory reason) external onlyOwner {
        require(bytes(reason).length > 0, "empty reason");
        require(!executed, "already executed");
        canceled = true;
        cancelationReason = reason;
        emit Canceled(reason);
    }

    function setAmountToHold(uint256 amountToHold_) external onlyOwner {
        require(amountToHold_ > 0, "amountToHold_ is zero");
        emit AmountToHoldModified(amountToHold, amountToHold_);
        amountToHold = amountToHold_;
    }

    function getVoters() external view returns (address[] memory) {
        return voters;
    }

    function getCharityNames()
        public
        view
        returns (string[] memory charityNames)
    {
        charityNames = new string[](options.length);
        for (uint32 optionId = 0; optionId < charityNames.length; optionId++) {
            charityNames[optionId] = options[optionId].charityName;
        }
    }

    function isOpen() public view returns (bool) {
        return block.timestamp >= startTime && block.timestamp < endTime;
    }

    function isClosed() public view returns (bool) {
        return block.timestamp >= endTime;
    }

    function getDetails()
        external
        view
        returns (
            address[] memory addresses,
            uint256[] memory uints,
            bool[] memory bools,
            string[] memory strings,
            string[] memory charityNames
        )
    {
        addresses = new address[](1);
        addresses[0] = address(tokenToHold);

        uints = new uint256[](5);
        uints[0] = startTime;
        uints[1] = endTime;
        uints[2] = quorum;
        uints[3] = castedVotes;
        uints[4] = amountToHold;

        bools = new bool[](4);
        bools[0] = executed;
        bools[1] = canceled;
        bools[2] = isOpen();
        bools[3] = isClosed();

        strings = new string[](1);
        strings[0] = cancelationReason;

        charityNames = getCharityNames();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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