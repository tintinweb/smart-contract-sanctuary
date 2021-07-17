/**
 *Submitted for verification at BscScan.com on 2021-07-17
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

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
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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

/**
* @author Nivesh <[email protected]>
*/
contract Escrow is Pausable, Ownable {
    // Contract statuses
    enum Statuses {
        Pending, // When the contract is created
        Completed, // When buyer completes it
        Cancelled, // When seller cancels the contact
        Paused // When seller puts it on HOLD
    }

    // seller wants to sell quantity item for amount currency to buyer
    struct Contract {
        uint256 id; // Contract id
        address creator; // Creator of the contract
        address buyer; // Member 2 of the contract
        address creatorInputToken; // What creator is giving
        address buyerInputToken; // What creator want in exchange
        uint256 creatorInputAmount; // How much the creator is giving
        uint256 buyerInputAmount; // How much the creator want in exchange
        Statuses status; // Current status of contract
        uint256 createdAt;
        uint256 updatedAt;
    }

    Contract[] contracts;
    uint256 public feePercentage;
    mapping(address => uint256) public fees;
    mapping(address => uint256[]) address_contract_ids; // Contract IDs associated with each address

    // Fired when a new contract is created
    event ContractCreated(Contract _contract);

    // Fired when a new contract is cancelled
    event ContractCancelled(Contract _contract);

    // Fired when a new contract is paused
    event ContractPaused(Contract _contract);

    // Fired when a new contract is unpaused
    event ContractUnpaused(Contract _contract);

    // Fired when a new contract is completed
    event ContractCompleted(
        Contract _contract,
        uint256 _creatorReceivedAmount,
        uint256 _buyerReceivedAmount,
        uint256 _serviceFeeForCreatorOutput,
        uint256 _serviceFeeForBuyerOutput
    );

    constructor(uint256 _feePercentage) {
        require(_feePercentage < 10000, "You should charge less than 100% :-)");

        feePercentage = _feePercentage; // 100 = 1%, 1 = 0.01%
    }

    /**
     * Only the creator of contract with this id
     */
    modifier onlyCreator(uint256 _id) {
        require(contracts[_id].creator == msg.sender, "Error: Only creator");
        _;
    }

    /**
     * Only buyer or if buyer is set to zero address for this id
     */
    modifier onlyBuyer(uint256 _id) {
        require(
            contracts[_id].buyer == msg.sender ||
                (contracts[_id].buyer == address(0) && contracts[_id].creator != msg.sender),
            "Error: Only buyer"
        );
        _;
    }

    /**
     * Only pending contracts
     */
    modifier onlyPending(uint256 _id) {
        require(contracts[_id].status == Statuses.Pending, "Error: Contract is not active.");
        _;
    }

    /**
     * Only paused contracts
     */
    modifier onlyPausedContract(uint256 _id) {
        require(contracts[_id].status == Statuses.Paused, "Error: Contract is not paused.");
        _;
    }

    /**
     * Only pending or paused contracts
     */
    modifier onlyPendingOrPaused(uint256 _id) {
        require(
            contracts[_id].status == Statuses.Pending || contracts[_id].status == Statuses.Paused,
            "Error: Contract is not pending or paused."
        );
        _;
    }

    // Disable the renounceOwnership function
    function renounceOwnership() public view override onlyOwner {
        revert("Disabled!");
    }

    /**
     * Pause contract
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * Unpause contract
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * Calculate fee
     */
    function calculateFee(uint256 _amount) public view returns (uint256) {
        if (feePercentage > 0 && (_amount / 10000) * 10000 == _amount) {
            return (_amount / 10000) * feePercentage;
        }

        return 0;
    }

    /**
     * Find contract by id
     */
    function find(uint256 _id) public view returns (Contract memory) {
        return contracts[_id];
    }

    /**
     * Create contract
     */
    function create(
        address _buyer,
        address _creatorInputToken,
        address _buyerInputToken,
        uint256 _createInputAmount,
        uint256 _buyerInputAmount
    ) public payable whenNotPaused returns (uint256) {
        require(_creatorInputToken != _buyerInputToken, "Error: Cannot create contract with same currencies.");
        require(msg.sender != _buyer, "Error: You cannot create contract with yourself.");

        // If creator is giving tokens
        if (_creatorInputToken != address(0)) {
            // Transfer _createInputAmount tokens to this contract (So we can later transfer to buyer upon completion)
            IERC20(_creatorInputToken).transferFrom(msg.sender, address(this), _createInputAmount);
        } else {
            // If creator is giving ether
            require(msg.value > 0, "Error: Please send some ether.");

            // _createInputAmount is now the amount of ether creator sent
            _createInputAmount = msg.value;
        }

        Contract memory _contract = Contract(
            contracts.length,
            msg.sender,
            _buyer,
            _creatorInputToken,
            _buyerInputToken,
            _createInputAmount,
            _buyerInputAmount,
            Statuses.Pending,
            block.timestamp,
            block.timestamp
        );

        contracts.push(_contract);

        address_contract_ids[_contract.creator].push(_contract.id);
        address_contract_ids[_contract.buyer].push(_contract.id);

        emit ContractCreated(_contract);

        return _contract.id;
    }

    /**
     * Pause contract
     */
    function pauseContract(uint256 _id) public onlyPending(_id) onlyCreator(_id) returns (bool) {
        Contract storage _contract = contracts[_id];
        _contract.status = Statuses.Paused;
        emit ContractPaused(_contract);
        return true;
    }

    /**
     * Unpause contract
     */
    function unpauseContract(uint256 _id) public onlyPausedContract(_id) onlyCreator(_id) returns (bool) {
        Contract storage _contract = contracts[_id];
        _contract.status = Statuses.Pending;
        emit ContractUnpaused(_contract);
        return true;
    }

    /**
     * Complete contract
     */
    function complete(uint256 _id) public payable onlyPending(_id) onlyBuyer(_id) returns (bool) {
        Contract storage _contract = contracts[_id];

        // If creator required ether
        // if buyer is giving ether
        if (_contract.buyerInputToken == address(0)) {
            require(msg.value >= _contract.buyerInputAmount, "Error: Incorrect amount.");

            // Mark order complete
            _contract.status = Statuses.Completed;
            _contract.buyer = msg.sender;
            _contract.updatedAt = block.timestamp;

            uint256 _serviceFeeForCreatorOutput = calculateFee(msg.value);
            uint256 _serviceFeeForBuyerOutput = calculateFee(_contract.creatorInputAmount);

            uint256 _creatorReceivedAmount = msg.value - _serviceFeeForCreatorOutput;
            uint256 _buyerReceivedAmount = _contract.creatorInputAmount - _serviceFeeForBuyerOutput;

            // Transfer eth to creator
            payable(_contract.creator).transfer(_creatorReceivedAmount);

            // Transfer tokens to buyer
            IERC20(_contract.creatorInputToken).transfer(_contract.buyer, _buyerReceivedAmount);

            // Service fees
            fees[_contract.buyerInputToken] += _serviceFeeForCreatorOutput;
            fees[_contract.creatorInputToken] += _serviceFeeForBuyerOutput;

            emit ContractCompleted(
                _contract,
                _creatorReceivedAmount,
                _buyerReceivedAmount,
                _serviceFeeForCreatorOutput,
                _serviceFeeForBuyerOutput
            );
        } else {
            // if seller required token
            // if buyer is giving token
            require(msg.value == 0, "Error: Please don't send any ETH.");

            // Transfer _contract.buyerInputAmount tokens to this contract (So we can later transfer to seller upon completion)
            IERC20(_contract.buyerInputToken).transferFrom(msg.sender, address(this), _contract.buyerInputAmount);

            _contract.status = Statuses.Completed;
            _contract.buyer = msg.sender;
            _contract.updatedAt = block.timestamp;

            uint256 _serviceFeeForCreatorOutput = calculateFee(_contract.buyerInputAmount);
            uint256 _serviceFeeForBuyerOutput = calculateFee(_contract.creatorInputAmount);

            uint256 _creatorReceivedAmount = _contract.buyerInputAmount - _serviceFeeForCreatorOutput;
            uint256 _buyerReceivedAmount = _contract.creatorInputAmount - _serviceFeeForBuyerOutput;

            IERC20(_contract.buyerInputToken).transfer(_contract.creator, _creatorReceivedAmount);

            // Transfer ether to buyer
            if (_contract.creatorInputToken == address(0)) {
                payable(_contract.buyer).transfer(_buyerReceivedAmount);
            } else {
                // Transfer tokens to buyer
                IERC20(_contract.creatorInputToken).transfer(_contract.buyer, _buyerReceivedAmount);
            }

            // Service fees
            fees[_contract.buyerInputToken] += _serviceFeeForCreatorOutput;
            fees[_contract.creatorInputToken] += _serviceFeeForBuyerOutput;

            emit ContractCompleted(
                _contract,
                _creatorReceivedAmount,
                _buyerReceivedAmount,
                _serviceFeeForCreatorOutput,
                _serviceFeeForBuyerOutput
            );
        }

        return true;
    }

    /**
     * Cancel contract
     */
    function cancel(uint256 _id) public onlyPendingOrPaused(_id) onlyCreator(_id) returns (bool) {
        Contract storage _contract = contracts[_id];

        _contract.status = Statuses.Cancelled;
        _contract.updatedAt = block.timestamp;

        // If seller sent ether
        if (_contract.creatorInputToken == address(0)) {
            payable(_contract.creator).transfer(_contract.creatorInputAmount);
        } else {
            IERC20(_contract.creatorInputToken).transfer(_contract.creator, _contract.creatorInputAmount);
        }

        emit ContractCancelled(_contract);

        return true;
    }

    /**
     * Withdraw fees
     */
    function withdrawFees(address _currency) public onlyOwner {
        uint256 _amount = fees[_currency];
        require(_amount > 0, "Nothing to withdraw!");

        fees[_currency] = 0;

        // Withdrawing ETH
        if (_currency == address(0)) {
            payable(owner()).transfer(_amount);
        } else {
            IERC20(_currency).transfer(owner(), _amount);
        }
    }

    /**
     * Count total contracts
     */
    function countContracts() public view returns (uint256) {
        return contracts.length;
    }

    /**
     * Paginate all contracts
     */
    function paginateContracts(uint256 _offset, uint256 _limit)
        public
        view
        returns (
            Contract[] memory _contracts,
            uint256 _nextOffset,
            uint256 _total
        )
    {
        _total = contracts.length;

        if (_limit == 0) {
            _limit = 1;
        }

        if (_limit > _total - _offset) {
            _limit = _total - _offset;
        }

        _contracts = new Contract[](_limit);

        for (uint256 _i = 0; _i < _limit; _i++) {
            _contracts[_i] = contracts[_offset + _i];
        }

        return (_contracts, _offset + _limit, _total);
    }

    /**
     * Count contracts for address
     */
    function countContractsOf(address _address) public view returns (uint256) {
        return address_contract_ids[_address].length;
    }

    /**
     * Paginate n contracts of address
     */
    function paginateContractsOf(
        address _address,
        uint256 _offset,
        uint256 _limit
    )
        public
        view
        returns (
            Contract[] memory _contracts,
            uint256 _nextOffset,
            uint256 _total
        )
    {
        uint256[] memory _contractIds = address_contract_ids[_address];

        _total = _contractIds.length;

        if (_limit == 0) {
            _limit = 1;
        }

        if (_limit > _total - _offset) {
            _limit = _total - _offset;
        }

        _contracts = new Contract[](_limit);

        for (uint256 _i = 0; _i < _limit; _i++) {
            _contracts[_i] = contracts[_contractIds[_offset + _i]];
        }

        return (_contracts, _offset + _limit, _total);
    }

    /**
     * Paginate contract ids of address
     */
    function paginateContractIdsOf(
        address _address,
        uint256 _offset,
        uint256 _limit
    )
        public
        view
        returns (
            uint256[] memory,
            uint256 _nextOffset,
            uint256 _total
        )
    {
        uint256[] memory _contractIds = address_contract_ids[_address];

        _total = _contractIds.length;

        if (_limit == 0) {
            _limit = 1;
        }

        if (_limit > _total - _offset) {
            _limit = _total - _offset;
        }

        uint256[] memory _ids = new uint256[](_limit);

        for (uint256 _i = 0; _i < _limit; _i++) {
            _ids[_i] = _contractIds[_offset + _i];
        }

        return (_ids, _offset + _limit, _total);
    }
}