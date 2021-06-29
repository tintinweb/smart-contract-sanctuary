/**
 *Submitted for verification at Etherscan.io on 2021-06-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;


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
        // solhint-disable-next-line no-inline-assembly
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
        // solhint-disable-next-line no-inline-assembly
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
    function predictDeterministicAddress(address implementation, bytes32 salt, address deployer) internal pure returns (address predicted) {
        // solhint-disable-next-line no-inline-assembly
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
    function predictDeterministicAddress(address implementation, bytes32 salt) internal view returns (address predicted) {
        return predictDeterministicAddress(implementation, salt, address(this));
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



/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


contract Governance is ReentrancyGuard {

	uint constant public governance_challenging_period = 10 days;
	uint constant public governance_freeze_period = 30 days;

	address public votingTokenAddress;
	address public governedContractAddress;

	mapping(address => uint) public balances;

	VotedValue[] public votedValues;
	mapping(string => VotedValue) public votedValuesMap;


	constructor(address _governedContractAddress, address _votingTokenAddress){
		init(_governedContractAddress, _votingTokenAddress);
	}

	function init(address _governedContractAddress, address _votingTokenAddress) public {
		require(governedContractAddress == address(0), "governance already initialized");
		governedContractAddress = _governedContractAddress;
		votingTokenAddress = _votingTokenAddress;
	}

	function addressBelongsToGovernance(address addr) public view returns (bool) {
		for (uint i = 0; i < votedValues.length; i++)
			if (address(votedValues[i]) == addr)
				return true;
		return false;
	}

	function isUntiedFromAllVotes(address addr) public view returns (bool) {
		for (uint i = 0; i < votedValues.length; i++)
			if (votedValues[i].hasVote(addr))
				return false;
		return true;
	}

	function addVotedValue(string memory name, VotedValue votedValue) external {
		require(msg.sender == governedContractAddress, "not authorized");
		votedValues.push(votedValue);
		votedValuesMap[name] = votedValue;
	}


	// deposit

	function deposit(uint amount) payable external {
		deposit(msg.sender, amount);
	}

	function deposit(address from, uint amount) nonReentrant payable public {
		require(from == msg.sender || addressBelongsToGovernance(msg.sender), "not allowed");
		if (votingTokenAddress == address(0))
			require(msg.value == amount, "wrong amount received");
		else {
			require(msg.value == 0, "don't send ETH");
			require(IERC20(votingTokenAddress).transferFrom(from, address(this), amount), "failed to pull gov deposit");
		}
		balances[from] += amount;
	}


	// withdrawal functions

	function withdraw() external {
		withdraw(balances[msg.sender]);
	}

	function withdraw(uint amount) nonReentrant public {
		require(amount > 0, "zero withdrawal requested");
		require(amount <= balances[msg.sender], "not enough balance");
		require(isUntiedFromAllVotes(msg.sender), "some votes not removed yet");
		balances[msg.sender] -= amount;
		if (votingTokenAddress == address(0))
			payable(msg.sender).transfer(amount);
		else
			require(IERC20(votingTokenAddress).transfer(msg.sender, amount), "failed to withdraw gov deposit");
	}
}


abstract contract VotedValue is ReentrancyGuard {
	Governance public governance;
	uint public challenging_period_start_ts;
	mapping(address => bool) public hasVote;

	constructor(Governance _governance){
		governance = _governance;
	}

	function checkVoteChangeLock() view public {
		require(challenging_period_start_ts + governance.governance_challenging_period() + governance.governance_freeze_period() < block.timestamp, "you cannot change your vote yet");
	}

	function checkChallengingPeriodExpiry() view public {
		require(block.timestamp > challenging_period_start_ts + governance.governance_challenging_period(), "challenging period not expired yet");
	}
}


contract VotedValueUint is VotedValue {

	function(uint) external validationCallback;
	function(uint) external commitCallback;

	uint public leader;
	uint public current_value;

	mapping(address => uint) public choices;
	mapping(uint => uint) public votesByValue;
	mapping(uint => mapping(address => uint)) public votesByValueAddress;

	constructor() VotedValue(Governance(address(0))) {}

	// constructor(Governance _governance, uint initial_value, function(uint) external _validationCallback, function(uint) external _commitCallback) VotedValue(_governance) {
	// 	leader = initial_value;
	// 	current_value = initial_value;
	// 	validationCallback = _validationCallback;
	// 	commitCallback = _commitCallback;
	// }

	function init(Governance _governance, uint initial_value, function(uint) external _validationCallback, function(uint) external _commitCallback) external {
		require(address(governance) == address(0), "already initialized");
		governance = _governance;
		leader = initial_value;
		current_value = initial_value;
		validationCallback = _validationCallback;
		commitCallback = _commitCallback;
	}

	function vote(uint value) nonReentrant external {
		_vote(value);
	}

	function voteAndDeposit(uint value, uint amount) nonReentrant payable external {
		governance.deposit{value: msg.value}(msg.sender, amount);
		_vote(value);
	}

	function _vote(uint value) private {
		validationCallback(value);
		uint prev_choice = choices[msg.sender];
		bool hadVote = hasVote[msg.sender];
		if (prev_choice == leader)
			checkVoteChangeLock();

		// first, remove votes from the previous choice
		if (hadVote)
			removeVote(prev_choice);

		// then, add them to the new choice
		uint balance = governance.balances(msg.sender);
		require(balance > 0, "no balance");
		votesByValue[value] += balance;
		votesByValueAddress[value][msg.sender] = balance;
		choices[msg.sender] = value;
		hasVote[msg.sender] = true;

		// check if the leader has just changed
		if (votesByValue[value] > votesByValue[leader]){
			leader = value;
			challenging_period_start_ts = block.timestamp;
		}
	}

	function unvote() external {
		if (!hasVote[msg.sender])
			return;
		uint prev_choice = choices[msg.sender];
		if (prev_choice == leader)
			checkVoteChangeLock();
		
		removeVote(prev_choice);
		delete choices[msg.sender];
		delete hasVote[msg.sender];
	}

	function removeVote(uint value) internal {
		votesByValue[value] -= votesByValueAddress[value][msg.sender];
		votesByValueAddress[value][msg.sender] = 0;
	}

	function commit() nonReentrant external {
		require(leader != current_value, "already equal to leader");
		checkChallengingPeriodExpiry();
		current_value = leader;
		commitCallback(leader);
	}
}



contract VotedValueUintArray is VotedValue {

	function(uint[] memory) external validationCallback;
	function(uint[] memory) external commitCallback;

	uint[] public leader;
	uint[] public current_value;

	mapping(address => uint[]) public choices;
	mapping(bytes32 => uint) public votesByValue;
	mapping(bytes32 => mapping(address => uint)) public votesByValueAddress;

	constructor() VotedValue(Governance(address(0))) {}

	// constructor(Governance _governance, uint[] memory initial_value, function(uint[] memory) external _validationCallback, function(uint[] memory) external _commitCallback) VotedValue(_governance) {
	// 	leader = initial_value;
	// 	current_value = initial_value;
	// 	validationCallback = _validationCallback;
	// 	commitCallback = _commitCallback;
	// }

	function init(Governance _governance, uint[] memory initial_value, function(uint[] memory) external _validationCallback, function(uint[] memory) external _commitCallback) external {
		require(address(governance) == address(0), "already initialized");
		governance = _governance;
		leader = initial_value;
		current_value = initial_value;
		validationCallback = _validationCallback;
		commitCallback = _commitCallback;
	}

	function equal(uint[] memory a1, uint[] memory a2) public pure returns (bool) {
		if (a1.length != a2.length)
			return false;
		for (uint i = 0; i < a1.length; i++)
			if (a1[i] != a2[i])
				return false;
		return true;
	}

	function getKey(uint[] memory a) public pure returns (bytes32){
		return keccak256(abi.encodePacked(a));
	}

	function vote(uint[] memory value) nonReentrant external {
		_vote(value);
	}

	function voteAndDeposit(uint[] memory value, uint amount) nonReentrant payable external {
		governance.deposit{value: msg.value}(msg.sender, amount);
		_vote(value);
	}

	function _vote(uint[] memory value) private {
		validationCallback(value);
		uint[] storage prev_choice = choices[msg.sender];
		bool hadVote = hasVote[msg.sender];
		if (equal(prev_choice, leader))
			checkVoteChangeLock();

		// remove one's vote from the previous choice first
		if (hadVote)
			removeVote(prev_choice);

		// then, add it to the new choice, if any
		bytes32 key = getKey(value);
		uint balance = governance.balances(msg.sender);
		require(balance > 0, "no balance");
		votesByValue[key] += balance;
		votesByValueAddress[key][msg.sender] = balance;
		choices[msg.sender] = value;
		hasVote[msg.sender] = true;

		// check if the leader has just changed
		if (votesByValue[key] > votesByValue[getKey(leader)]){
			leader = value;
			challenging_period_start_ts = block.timestamp;
		}
	}

	function unvote() external {
		if (!hasVote[msg.sender])
			return;
		uint[] storage prev_choice = choices[msg.sender];
		if (equal(prev_choice, leader))
			checkVoteChangeLock();
		
		removeVote(prev_choice);
		delete choices[msg.sender];
		delete hasVote[msg.sender];
	}

	function removeVote(uint[] memory value) internal {
		bytes32 key = getKey(value);
		votesByValue[key] -= votesByValueAddress[key][msg.sender];
		votesByValueAddress[key][msg.sender] = 0;
	}

	function commit() nonReentrant external {
		require(!equal(leader, current_value), "already equal to leader");
		checkChallengingPeriodExpiry();
		current_value = leader;
		commitCallback(leader);
	}
}



contract VotedValueAddress is VotedValue {

	function(address) external validationCallback;
	function(address) external commitCallback;

	address public leader;
	address public current_value;

	// mapping(who => value)
	mapping(address => address) public choices;

	// mapping(value => votes)
	mapping(address => uint) public votesByValue;

	// mapping(value => mapping(who => votes))
	mapping(address => mapping(address => uint)) public votesByValueAddress;

	constructor() VotedValue(Governance(address(0))) {}

	// constructor(Governance _governance, address initial_value, function(address) external _validationCallback, function(address) external _commitCallback) VotedValue(_governance) {
	// 	leader = initial_value;
	// 	current_value = initial_value;
	// 	validationCallback = _validationCallback;
	// 	commitCallback = _commitCallback;
	// }

	function init(Governance _governance, address initial_value, function(address) external _validationCallback, function(address) external _commitCallback) external {
		require(address(governance) == address(0), "already initialized");
		governance = _governance;
		leader = initial_value;
		current_value = initial_value;
		validationCallback = _validationCallback;
		commitCallback = _commitCallback;
	}

	function vote(address value) nonReentrant external {
		_vote(value);
	}

	function voteAndDeposit(address value, uint amount) nonReentrant payable external {
		governance.deposit{value: msg.value}(msg.sender, amount);
		_vote(value);
	}

	function _vote(address value) private {
		validationCallback(value);
		address prev_choice = choices[msg.sender];
		bool hadVote = hasVote[msg.sender];
		if (prev_choice == leader)
			checkVoteChangeLock();

		// first, remove votes from the previous choice
		if (hadVote)
			removeVote(prev_choice);

		// then, add them to the new choice
		uint balance = governance.balances(msg.sender);
		require(balance > 0, "no balance");
		votesByValue[value] += balance;
		votesByValueAddress[value][msg.sender] = balance;
		choices[msg.sender] = value;
		hasVote[msg.sender] = true;

		// check if the leader has just changed
		if (votesByValue[value] > votesByValue[leader]){
			leader = value;
			challenging_period_start_ts = block.timestamp;
		}
	}

	function unvote() external {
		if (!hasVote[msg.sender])
			return;
		address prev_choice = choices[msg.sender];
		if (prev_choice == leader)
			checkVoteChangeLock();
		
		removeVote(prev_choice);
		delete choices[msg.sender];
		delete hasVote[msg.sender];
	}

	function removeVote(address value) internal {
		votesByValue[value] -= votesByValueAddress[value][msg.sender];
		votesByValueAddress[value][msg.sender] = 0;
	}

	function commit() nonReentrant external {
		require(leader != current_value, "already equal to leader");
		checkChallengingPeriodExpiry();
		current_value = leader;
		commitCallback(leader);
	}
}


contract VotedValueFactory {

	address public votedValueUintMaster;
	address public votedValueUintArrayMaster;
	address public votedValueAddressMaster;

	constructor(address _votedValueUintMaster, address _votedValueUintArrayMaster, address _votedValueAddressMaster) {
		votedValueUintMaster = _votedValueUintMaster;
		votedValueUintArrayMaster = _votedValueUintArrayMaster;
		votedValueAddressMaster = _votedValueAddressMaster;
	}


	function createVotedValueUint(Governance governance, uint initial_value, function(uint) external validationCallback, function(uint) external commitCallback) external returns (VotedValueUint) {
		VotedValueUint vv = VotedValueUint(Clones.clone(votedValueUintMaster));
		vv.init(governance, initial_value, validationCallback, commitCallback);
		return vv;
	}

	function createVotedValueUintArray(Governance governance, uint[] memory initial_value, function(uint[] memory) external validationCallback, function(uint[] memory) external commitCallback) external returns (VotedValueUintArray) {
		VotedValueUintArray vv = VotedValueUintArray(Clones.clone(votedValueUintArrayMaster));
		vv.init(governance, initial_value, validationCallback, commitCallback);
		return vv;
	}

	function createVotedValueAddress(Governance governance, address initial_value, function(address) external validationCallback, function(address) external commitCallback) external returns (VotedValueAddress) {
		VotedValueAddress vv = VotedValueAddress(Clones.clone(votedValueAddressMaster));
		vv.init(governance, initial_value, validationCallback, commitCallback);
		return vv;
	}

}