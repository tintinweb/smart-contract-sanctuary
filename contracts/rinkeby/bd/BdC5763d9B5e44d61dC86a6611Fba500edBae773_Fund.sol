//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
  @title A fundraising contract
  @author Onur the Scammer
  A contract which has multiple pools to raise funds.
  Each pool has owner which gets the funds at the end.
*/
contract Fund is Ownable {
    /// Constant name for the contract
    string public name = "FundRaise v1.0";

    /// Overall funds in this contract ever collected
    uint256 public totalFundsCollected;

    /// Overall funds in active pools
    uint256 public totalActiveFunds;

    /**
      An enum that stores the state of the pool.
      @param INACTIVE pool is not been created.
      @param ACTIVE pool has been created.
      @param COMPLETED pool has been finalised. 
    */
    enum FundState {
        INACTIVE,
        ACTIVE,
        COMPLETED
    }

    /** 
      A struct which stores information about the funds.
      @param state whether the pool is active.
      @param amounts external address to funded amount.
      @param funders the iteratable collection of addresses.
      @param fundOwner the owner of the funds in that pool.
      @param totalFundedAmount the total collected funds.
    */
    struct FundRaise {
        FundState state;
        mapping(address => uint256) amounts;
        address[] funders;
        address fundOwner;
        uint256 totalFundedAmount;
    }

    /// A mapping for storing pools to FundRaise
    mapping(uint256 => FundRaise) public fundRaises;

    /// A variable that stores the current index of the new pool
    uint256 public fundIndex;

    /**
        A modifier that checks if the pool id is valid.
        @param _poolId ID of the pool.
     */
    modifier onlyValidPool(uint256 _poolId) {
        // Since pool with address(0) cannot exist
        require(
            fundRaises[_poolId].fundOwner != address(0),
            "This pool does NOT exists!"
        );
        _;
    }

    /// An event that is emitted after funding a pool
    event FundEvent(uint256 poolId, address indexed _from, uint256 _value);

    /// An event that is emitted after finishing a pool
    event FinishFundPoolEvent(
        uint256 poolId,
        address indexed _to,
        uint256 _value
    );

    /// An event that is emitted after chaging owner of a pool
    event FundOwnerChangeEvent(
        uint256 poolId,
        address indexed _from,
        address indexed _to
    );

    /** 
      Deploys to network.
      @param _owner asdfasdf
    */
    constructor(address _owner) {
        require(_owner != address(0), "Owner adress cannot be zero!");
        transferOwnership(_owner);
    }

    /** 
      A function that creates a funding pool.
      @param _fundOwner owner of the funds in the pool.
    */
    function createFundPool(address _fundOwner) external onlyOwner {
        require(_fundOwner != address(0), "Fund owner adress cannot be zero!");
        fundRaises[fundIndex++].fundOwner = _fundOwner;
    }

    /** 
      A function that launches the pool.
      @param _poolId pool ID to launch.
    */
    function launchFundPool(uint256 _poolId)
        external
        onlyOwner
        onlyValidPool(_poolId)
    {
        require(
            fundRaises[_poolId].state == FundState.INACTIVE,
            "Fund state has to be inactive to launch!"
        );
        fundRaises[_poolId].state = FundState.ACTIVE;
    }

    /** 
      A function that finishes the pool.
      @param _poolId pool ID to finish.
    */
    function finishFundPool(uint256 _poolId)
        external
        onlyOwner
        onlyValidPool(_poolId)
    {
        require(
            fundRaises[_poolId].state == FundState.ACTIVE,
            "Fund state is not active!"
        );
        FundRaise storage fundRaise = fundRaises[_poolId];
        uint256 totalFundedAmount = fundRaise.totalFundedAmount;
        fundRaise.totalFundedAmount = 0;
        fundRaise.state = FundState.COMPLETED;
        totalActiveFunds -= totalFundedAmount;
        payable(fundRaise.fundOwner).transfer(totalFundedAmount);
        emit FinishFundPoolEvent(
            _poolId,
            fundRaise.fundOwner,
            totalFundedAmount
        );
    }

    /** 
      A function that changes the owner of the funding pool.
      @param _poolId pool ID to change the owner of.
      @param _newFundOwner address of the new owner.
    */
    function changeFundOwner(uint256 _poolId, address _newFundOwner)
        external
        onlyOwner
        onlyValidPool(_poolId)
    {
        require(
            _newFundOwner != address(0),
            "Fund owner adress cannot be zero!"
        );
        FundRaise storage fundRaise = fundRaises[_poolId];
        address oldFundOwner = fundRaise.fundOwner;
        fundRaise.fundOwner = _newFundOwner;
        emit FundOwnerChangeEvent(_poolId, oldFundOwner, _newFundOwner);
    }

    /** 
      A function that is used to fund the pool.
      @param _poolId pool ID to fund.
    */
    function fund(uint256 _poolId) external payable onlyValidPool(_poolId) {
        require(
            fundRaises[_poolId].state == FundState.ACTIVE,
            "Fund state is not active!"
        );
        FundRaise storage fundRaise = fundRaises[_poolId];
        if (fundRaise.amounts[msg.sender] == 0) {
            fundRaise.funders.push(msg.sender);
        }
        fundRaise.amounts[msg.sender] += msg.value;
        fundRaise.totalFundedAmount += msg.value;
        totalActiveFunds += msg.value;
        totalFundsCollected += msg.value;
        emit FundEvent(_poolId, msg.sender, msg.value);
    }

    /** 
      A function that return pool information.
      @param _poolId pool ID to get information from.
      @return pool information as return value.
    */
    function getPoolInfo(uint256 _poolId)
        external
        view
        onlyValidPool(_poolId)
        returns (
            FundState,
            address[] memory,
            address,
            uint256
        )
    {
        FundRaise storage fundRaise = fundRaises[_poolId];
        return (
            fundRaise.state,
            fundRaise.funders,
            fundRaise.fundOwner,
            fundRaise.totalFundedAmount
        );
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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