/**
 *Submitted for verification at BscScan.com on 2021-12-10
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

abstract contract Context {
        // Empty internal constructor, to prevent people from mistakenly deploying
        // an instance of this contract, which should be used via inheritance.

        function _msgSender() internal view returns (address) {
                return msg.sender;
        }

        function _msgData() internal view returns (bytes memory) {
                this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
                return msg.data;
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
        constructor () {
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
        function renounceOwnership() public onlyOwner {
                emit OwnershipTransferred(_owner, address(0));
                _owner = address(0);
        }

        
        /**
        * @dev Transfers ownership of the contract to a new account (`newOwner`).
        * Can only be called by the current owner.
        */
        function transferOwnership(address newOwner) public onlyOwner {
                _transferOwnership(newOwner);
        }

        /**
        * @dev Transfers ownership of the contract to a new account (`newOwner`).
        */
        function _transferOwnership(address newOwner) internal {
                require(newOwner != address(0), "Ownable: new owner is the zero address");
                emit OwnershipTransferred(_owner, newOwner);
                _owner = newOwner;
        }
}
interface KeeperCompatibleInterface {
        /**
        * @notice method that is simulated by the keepers to see if any work actually
        * needs to be performed. This method does does not actually need to be
        * executable, and since it is only ever simulated it can consume lots of gas.
        * @dev To ensure that it is never called, you may want to add the
        * cannotExecute modifier from KeeperBase to your implementation of this
        * method.
        * @param checkData specified in the upkeep registration so it is always the
        * same for a registered upkeep. This can easilly be broken down into specific
        * arguments using `abi.decode`, so multiple upkeeps can be registered on the
        * same contract and easily differentiated by the contract.
        * @return upkeepNeeded boolean to indicate whether the keeper should call
        * performUpkeep or not.
        * @return performData bytes that the keeper should call performUpkeep with, if
        * upkeep is needed. If you would like to encode data to decode later, try
        * `abi.encode`.
        */
        function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);
        /**
        * @notice method that is actually executed by the keepers, via the registry.
        * The data returned by the checkUpkeep simulation will be passed into
        * this method to actually be executed.
        * @dev The input to this method should not be trusted, and the caller of the
        * method should not even be restricted to any single registry. Anyone should
        * be able call it, and the input should be validated, there is no guarantee
        * that the data passed in is the performData returned from checkUpkeep. This
        * could happen due to malicious keepers, racing keepers, or simply a state
        * change while the performUpkeep transaction is waiting for confirmation.
        * Always validate the data passed in.
        * @param performData is the data which was passed back from the checkData
        * simulation. If it is encoded, it can easily be decoded into other types by
        * calling `abi.decode`. This data should not be trusted, and should be
        * validated against the contract's current state.
        */
        function performUpkeep(bytes calldata performData) external;
}
interface IBEP20 {
        /**
         * @dev Returns the amount of tokens in existence.
        */
        function totalSupply() external view returns (uint256);

        /**
        * @dev Returns the token decimals.
        */
        function decimals() external view returns (uint8);

        /**
        * @dev Returns the token symbol.
        */
        function symbol() external view returns (string memory);

        /**
        * @dev Returns the token name.
        */
        function name() external view returns (string memory);

        /**
        * @dev Returns the bep token owner.
        */
        function getOwner() external view returns (address);

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
        function allowance(address _owner, address spender) external view returns (uint256);

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
interface IProcessFee {
        function distribution(IBEP20 _token) external;
}
contract DistributionUpkeep is KeeperCompatibleInterface, Ownable {
        uint256 public totalDistribution;
        mapping(uint256 => Distribution) public distributionOf; 

        struct Distribution {
                IProcessFee ProcessFeeContract;
                IBEP20[] tokens;
                bool status;
        }
        /**
        * Use an interval in seconds and a timestamp to slow execution of Upkeep
        */
        uint public immutable interval;
        uint public lastTimeStamp;
        constructor(uint updateInterval) {
                interval = updateInterval;
                lastTimeStamp = block.timestamp;
        }
        function addDistribution(IProcessFee _processFee, IBEP20[] memory _tokens) public onlyOwner
        {
                Distribution storage d = distributionOf[totalDistribution];
                d.ProcessFeeContract = _processFee;
                d.tokens = _tokens;
                d.status = true;
                totalDistribution += 1;
        }
        function updateDistribution(uint256 _id, IProcessFee _processFee, IBEP20[] memory _tokens, uint8 _status) public onlyOwner
        {
                Distribution storage d = distributionOf[_id];
                d.ProcessFeeContract = _processFee;
                d.tokens = _tokens;
                d.status = _status != 0;
        }

        function checkUpkeep(bytes calldata /* checkData */) external override returns (bool upkeepNeeded, bytes memory /* performData */) {
                upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
        }
        function performUpkeep(bytes calldata /* performData */) external override {
                lastTimeStamp = block.timestamp;
                for (uint256 idx = 0; idx < totalDistribution; idx++) {
                        Distribution memory d = distributionOf[totalDistribution];
                        if (d.status == true) {
                                for (uint256 jdx = 0; jdx < d.tokens.length; jdx++) {
                                        d.ProcessFeeContract.distribution(d.tokens[jdx]);
                                }
                        }
                }
        }
}