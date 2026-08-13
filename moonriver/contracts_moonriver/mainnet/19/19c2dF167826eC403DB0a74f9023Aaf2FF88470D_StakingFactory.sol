/**
 *Submitted for verification at moonriver.moonscan.io on 2022-05-30
*/

// File: utils/libraries/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// File: utils/libraries/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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
// File: ISuiteManager.sol

pragma solidity ^0.8.4;

interface ISuiteManager {
    function feeReceiver() external view returns (address payable);
    function feeToken() external view returns (address);
    function serviceFee(address _contract) external view returns(uint256);
    function transactionFee(address _contract) external view returns(uint256);
    function authorizedAmms(address _router) external view returns(bool);
    function exemptAddresses(address _contract) external view returns(bool);
    function allAmms(uint256 _index) external view returns(address);
    function contractList(uint256 _index) external view returns(address);
    function feesCollected(address _token, address _contract) external view returns(uint256);
    function setFeeToken(address _feeToken) external;
    function setServiceFee(address _contract, uint256 _serviceFee) external;
    function setTransactionFee(address _contract, uint256 _transactionFee) external;
    function enableAmm(address _router) external;
    function disableAmm(address _router) external;
    function updateContractList(uint256 _index, address _contract) external;
    function collectFee() external payable;
}
// File: StakingFactory/deployers/IStakingDeployer.sol

pragma solidity ^0.8.4;

interface IStakingDeployer {
    event CreateStaking(address token, uint256 dripRate, address managerAddress);

    function factory() external returns (address);
    function deploy(bytes calldata arguments, address suiteManager) external returns (address token);
}
// File: StakingFactory/IStakingFactory.sol


pragma solidity ^0.8.4;

interface IStakingFactory {
    
    event feeReceiverChanged(address indexed previousFeeReceiver, address indexed newFeeReceiver);
    
    function managerAddress() external view returns(address);
    function feeToken() external view returns (address);
    function serviceFee() external view returns (uint256);
    function contractCreator(address _token) external view returns  (address);
    function contractsBy(address _owner, uint256 _index) external view returns  (address);
    function allContracts(uint256 _index) external view returns (address);
    function allDeployers(uint256 _index) external view returns (address);
    function contractsByLength(address _owner) external view returns (uint256);
    function allContractsLength() external view returns (uint256);
    function allDeployersLength() external view returns (uint256);
    function addDeployer(address _address) external;
    function removeDeployer(address _address) external;
    function checkDeployer(address _deployer) external view returns (bool);
    function createStaking(address _tokenModel, bytes calldata _arguments) external payable returns (address);
}

// File: StakingFactory/StakingFactory.sol

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;





contract StakingFactory is IStakingFactory, Ownable {

    ISuiteManager private suiteManager;

    //staking contract [address] => creator [address]
    mapping(address => address) public override contractCreator;

    //creator [address] => all staking contract by the creator [ address[] ]
    mapping(address => address[]) public override contractsBy;

    //staking deployer contract [address] => enabled [uint8]
    mapping(address => uint8) private _deployers;

    //all staking contracts created using this contract
    address[] public override allContracts;

    //all deployers ever added to this contract, including disabled ones
    address[] public override allDeployers;

    constructor(address _managerAddress) {
        suiteManager = ISuiteManager(_managerAddress);
    }

    function contractsByLength(address _owner) external view override returns (uint256 length_) {
        length_ = contractsBy[_owner].length;
        return length_;
    }
    
    function allContractsLength() external view override returns (uint256 length_) {
        length_ = allContracts.length;
        return length_;
    }

    function allDeployersLength() external view override returns (uint256 length_) {
        length_ = allDeployers.length;
        return length_;
    }

    function feeToken() external view override returns (address token_) {
        token_ = suiteManager.feeToken();
        return token_;
    }

    function serviceFee() external view override returns (uint256 serviceFee_) {
        serviceFee_ = suiteManager.serviceFee(address(this));
        return serviceFee_;
    }

    function managerAddress() external view override returns (address managerAddress_) {
        managerAddress_ = address(suiteManager);
        return managerAddress_;
    }

    function checkDeployer(address _deployer) external view override returns (bool enabled_){
        if(_deployers[_deployer] == 2) enabled_ = true;
        else enabled_ = false;
        return enabled_;
    }

    function addDeployer(address _address) external override onlyOwner {
        require(_deployers[_address] != 2, "ERROR: Deployer already enabled");
        //0 means the deployer has never been enabled before, so its not in the allDeployers array yet
        if(_deployers[_address] == 0) {
            allDeployers.push(_address);
        }
        _deployers[_address] = 2;
    }

    function removeDeployer(address _address) external override onlyOwner {
        require(_deployers[_address] == 2, "ERROR: Deployer not enabled");
        _deployers[_address] = 1;
    }

    function createStaking(address _deployer, bytes calldata _arguments) external payable override returns (address address_) {
        require(_deployers[_deployer] == 2, "ERROR: Staking model not found or not active");

        //collects the service fee
        suiteManager.collectFee{value: msg.value}();

        //deploy the staking contract
        address_ = address(IStakingDeployer(_deployer).deploy(_arguments, address(suiteManager)));

        //populate the statistics
        contractCreator[address_] = tx.origin;
        contractsBy[tx.origin].push(address_);

        return address_;
    }
}