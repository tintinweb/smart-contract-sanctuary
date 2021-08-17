//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "./utils/Ownable.sol";
import "./interfaces/IBEP20.sol";
import "./interfaces/IVeraPad.sol";
import "./interfaces/IOracle.sol";

contract VeraSwapIDO is IVeraPad, Ownable {
	address public vrapToken;
    address private oracle;
 
	uint256 public standardFee = 20 * 10**18; // In VRAP
	uint256 public premiumFee = 50 * 10**18; // In VRAP

	mapping(uint256 => Project) public projects;
	uint256 projectCounter;

	constructor(address _vrapAddress, address _admin,address _oracle) {
		vrapToken = _vrapAddress;
        oracle = _oracle;
		transferOwnership(_admin);
	}

	modifier condition(bool _condition, string memory message) {
		require(_condition, message);
		_;
	}


	function createProject(
		address settlementAddress,
		bytes calldata ipfsHash,
		uint256 startDate,
		uint256 endDate,
		bool isPremium,
		address contractAddress,
		uint256 costPerToken,
		address projectWallet
	)
		external
		virtual
		override
		condition(startDate < endDate, "Error:Invalid timestamps")
		condition(
			startDate > block.timestamp + 5 minutes,
			"Error:Invalid StartDate"
		)
		returns (bool)
	{
		uint256 fee;
		projectCounter += 1;
		Project storage project = projects[projectCounter];
		project.projectId = projectCounter;
		project.ipfsHash = ipfsHash;
		project.startDate = startDate;
		project.endDate = endDate;
		project.isPremium = isPremium;
		project.settlementAddress = settlementAddress;
		project.projectWallet = projectWallet;

		if (isPremium) {
			project.isApproved = false;
			project.isPremium = true;
			fee = premiumFee;
		} else {
			project.isApproved = true;
			project.isPremium = false;
			fee = standardFee;
		}

		project.contractAddress = contractAddress;
		project.costPerToken = costPerToken;

		require(
			IBEP20(vrapToken).allowance(_msgSender(), address(this)) >= fee,
			"Error:Insufficient allowance for fee"
		);

		IBEP20(vrapToken).transferFrom(_msgSender(), owner(), fee);

		emit ProjectCreated(
			project.projectId,
			contractAddress,
			project.ipfsHash,
            _msgSender()
		);
		return true;
	}

	function _setSettlementAddress(uint256 projectId, address newAddress)
		external
		virtual
		override
		returns (bool)
	{
		Project storage project = projects[projectId];
		require(
			project.projectWallet == _msgSender(),
			"Error:Allowed only from ProjectWallet"
		);
		project.settlementAddress = newAddress;
		return true;
	}

	function depositTokens(uint256 projectId, uint256 amount)
		external
		virtual
		override
		returns (bool)
	{
		Project storage project = projects[projectId];
		require(
			project.projectWallet == _msgSender(),
			"Error:Deposit only from ProjectWallet"
		);
		require(
			IBEP20(project.contractAddress).balanceOf(_msgSender()) >= amount,
			"Error:Insufficient balance"
		);
		require(
			IBEP20(project.contractAddress).allowance(
				_msgSender(),
				address(this)
			) >= amount,
			"Error:Insufficient allowance"
		);
		IBEP20(project.contractAddress).transferFrom(
			_msgSender(),
			address(this),
			amount
		);
    emit TokensDeposited(project.projectId, amount);
		return true;
	}

	function emergencyWithdraw(uint256 projectId, uint256 amount)
		external
		virtual
		override
		returns (bool)
	{
		Project storage project = projects[projectId];
		require(
			project.projectWallet == _msgSender() || _msgSender() == owner(),
			"Error:Allowed only from ProjectWallet/Admin"
		);
		IBEP20(project.contractAddress).transfer(_msgSender(), amount);

        emit TokensWithdrawn(project.projectId, amount, _msgSender());
		return true;
	}

 

	function buyTokens(uint256 projectId, uint256 amount)
		external
		virtual
		override
		returns (bool)
	{
		Project storage project = projects[projectId];
		require(project.isApproved, "Error:Project not yet approved");
		require(
			project.startDate < block.timestamp,
			"Error:Sale not yet started"
		);
		require(project.endDate > block.timestamp, "Error:Sale ended");
        uint256 vrapPrice = IOracle(oracle).vrapPrice();
 		uint256 totalCostInVrap = (project.costPerToken / vrapPrice) * amount;
		require(
			IBEP20(vrapToken).balanceOf(_msgSender()) >= totalCostInVrap,
			"Error:Insufficient balance"
		);
		require(
			IBEP20(vrapToken).allowance(_msgSender(), address(this)) >=
				totalCostInVrap,
			"Error:Insufficient allowance"
		);
		require(
			IBEP20(project.contractAddress).balanceOf(address(this)) >= amount,
			"Error:Insufficient tokens in the pool"
		);

		IBEP20(vrapToken).transferFrom(
			_msgSender(),
			project.settlementAddress,
			totalCostInVrap
		);
		IBEP20(project.contractAddress).transfer(_msgSender(), amount);
		emit TokensBought(projectId, amount, totalCostInVrap, _msgSender());
		return true;
	}

	function _setStandardFee(uint256 _standardFee)
		external
		virtual
		override
		onlyOwner
		condition(_standardFee >= 0, "Error:Fee must be positive")
		returns (bool)
	{
		standardFee = _standardFee;
		emit StandardFeeUpdated(_standardFee);
		return true;
	}

	function _setPremiumFee(uint256 _premiumFee)
		external
		virtual
		override
		onlyOwner
		condition(_premiumFee >= 0, "Error:Fee must be positive")
		returns (bool)
	{
		premiumFee = _premiumFee;
		emit PremiumFeeUpdated(_premiumFee);
		return true;
	}
 

	function approveProject(uint256 projectId)
		external
		virtual
		override
		onlyOwner
		returns (bool)
	{
		Project storage project = projects[projectId];
		project.isApproved = true;
		emit ProjectApproved(projectId);
		return true;
	}

	function removeProject(uint256 projectId)
		external
		virtual
		override
		onlyOwner
		returns (bool)
	{
		Project storage project = projects[projectId];
		project.isApproved = false;
		emit ProjectRemoved(projectId);
		return true;
	}
    	function _setVrapToken(address _vrapTokenAddress)
		external
		virtual
		override
		onlyOwner
		returns (bool)
	{
		vrapToken = _vrapTokenAddress;
        emit VrapTokenUpdated(_vrapTokenAddress);
		return true;
	}

   
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Context.sol";

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

	event OwnershipTransferred(
		address indexed previousOwner,
		address indexed newOwner
	);

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
		require(
			newOwner != address(0),
			"Ownable: new owner is the zero address"
		);
		_setOwner(newOwner);
	}

	function _setOwner(address newOwner) private {
		address oldOwner = _owner;
		_owner = newOwner;
		emit OwnershipTransferred(oldOwner, newOwner);
	}
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.4;

interface IBEP20 {
	/**
	 * @dev returns the name of the token
	 */
	function name() external view returns (string memory);

	/**
	 * @dev returns the symbol of the token
	 */
	function symbol() external view returns (string memory);

	/**
	 * @dev returns the decimal places of a token
	 */
	function decimals() external view returns (uint8);

	/**
	 * @dev returns the total tokens in existence
	 */
	function totalSupply() external view returns (uint256);

	/**
	 * @dev returns the tokens owned by `account`.
	 */
	function balanceOf(address account) external view returns (uint256);

	/**
	 * @dev transfers the `amount` of tokens from caller's account
	 * to the `recipient` account.
	 *
	 * returns boolean value indicating the operation status.
	 *
	 * Emits a {Transfer} event
	 */
	function transfer(address recipient, uint256 amount)
		external
		returns (bool);

	/**
	 * @dev returns the remaining number of tokens the `spender' can spend
	 * on behalf of the owner.
	 *
	 * This value changes when {approve} or {transferFrom} is executed.
	 */
	function allowance(address owner, address spender)
		external
		view
		returns (uint256);

	/**
	 * @dev sets `amount` as the `allowance` of the `spender`.
	 *
	 * returns a boolean value indicating the operation status.
	 */
	function approve(address spender, uint256 amount) external returns (bool);

	/**
	 * @dev transfers the `amount` on behalf of `spender` to the `recipient` account.
	 *
	 * returns a boolean indicating the operation status.
	 *
	 * Emits a {Transfer} event.
	 */
	function transferFrom(
		address spender,
		address recipient,
		uint256 amount
	) external returns (bool);

	/**
	 * @dev Emitted from tokens are moved from one account('from') to another account ('to)
	 */
	event Transfer(address indexed from, address indexed to, uint256 value);

	/**
	 * @dev Emitted when allowance of a `spender` is set by the `owner`
	 */
	event Approval(
		address indexed owner,
		address indexed spender,
		uint256 value
	);
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

interface IVeraPad {
	struct Project {
		uint256 projectId;
		bytes ipfsHash;
		address settlementAddress;
		uint256 startDate;
		uint256 endDate;
		bool isPremium;
		bool isApproved;
		address contractAddress;
		uint256 costPerToken;
		address projectWallet;
	}

	event ProjectCreated(
		uint256 projectId,
		address indexed contractAddress,
		bytes ipfsHash,
        address indexed createdBy
	);
	event StandardFeeUpdated(uint256 newStandardFee);

	event PremiumFeeUpdated(uint256 newPremiumFee);

    event VrapTokenUpdated(address indexed vrapTokenAddress);

	event ProjectApproved(uint256 projectId);

	event ProjectRemoved(uint256 projectId);

	event TokensDeposited(uint256 projectId, uint256 amount);

    event TokensWithdrawn(uint256 projectId, uint256 amount, address indexed recipient);

	event TokensBought(
		uint256 projectId,
		uint256 amount,
		uint256 totalCostInVrap,
		address indexed buyer
	);


	/**
	 * @notice Used to list a project
	 * If the `isPremium` flag is set to true, then admin should approve it for listing.
	 */
	function createProject(
		address settlementAddress,
		bytes calldata ipfsHash,
		uint256 startDate,
		uint256 endDate,
		bool isPremium,
		address contractAddress,
		uint256 costPerToken,
		address projectWallet
	) external returns (bool);

	/**
	 * @notice This method can be only called by the project owner to change the settlement wallet
	 */
	function _setSettlementAddress(uint256 projectId, address newAddress)
		external
		returns (bool);

	/**
	 * @notice The project owner should deposit tokens in this contract for sale
	 */
	function depositTokens(uint256 projectId, uint256 amount)
		external
		returns (bool);

	/**
	 * @notice The project owner can withdraw tokens from this contract.
	 */
	function emergencyWithdraw(uint256 projectId, uint256 amount)
		external
		returns (bool);

 
	/**
	 * @notice Anyone should be able to buy tokens from the approved projects.
	 * The purchase amount is automatically settled to the settlement address.
	 */
	function buyTokens(uint256 projectId, uint256 amount)
		external
		returns (bool);

  
	/**
	 * @notice Used by the admin to change the standardFee in Vrap
	 */
	function _setStandardFee(uint256 _standardFee) external returns (bool);
 	
     /**
	 * @notice Used to change the vrapToken address by admin
	 */
	function _setVrapToken(address _vrapTokenAddress) external returns (bool);

	/**
	 * @notice Used by the admin to change the premiumFee in Vrap
	 */
	function _setPremiumFee(uint256 _premiumFee) external returns (bool);

	/**
	 * @notice Admin only method used to approve a project
	 */
	function approveProject(uint256 projectId) external returns (bool);

	/**
	 * @notice Admin only method used to remove a project
	 */
	function removeProject(uint256 projectId) external returns (bool);
}

pragma solidity ^0.8.4;

interface IOracle {
    function vrapPrice() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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
		return msg.data;
	}
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}