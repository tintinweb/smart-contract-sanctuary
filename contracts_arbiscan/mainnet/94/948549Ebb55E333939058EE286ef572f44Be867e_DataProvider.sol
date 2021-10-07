/**
 *Submitted for verification at arbiscan.io on 2021-09-23
*/

pragma solidity 0.8.4;


// 
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

// 
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

//
interface IOperatorAccessControl {
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

    function isOperator(address account) external view returns (bool);

    function addOperator(address account) external;

    function revokeOperator(address account) external;
}

//
contract OperatorAccessControl is IOperatorAccessControl, Ownable {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    function hasRole(bytes32 role, address account)
        public
        view
        override
        returns (bool)
    {
        return _roles[role].members[account];
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    modifier isOperatorOrOwner() {
        address _sender = _msgSender();
        require(
            isOperator(_sender) || owner() == _sender,
            "OperatorAccessControl: caller is not operator or owner"
        );
        _;
    }

    modifier onlyOperator() {
        require(
            isOperator(_msgSender()),
            "OperatorAccessControl: caller is not operator"
        );
        _;
    }

    function isOperator(address account) public view override returns (bool) {
        return hasRole(OPERATOR_ROLE, account);
    }

    function addOperator(address account) public override onlyOwner {
        _grantRole(OPERATOR_ROLE, account);
    }

    function revokeOperator(address account) public override onlyOwner {
        _revokeRole(OPERATOR_ROLE, account);
    }
}

//
/**
 * @title UtilLib
 *
 * @author PandaFarm
 */
library UtilLib {

    /**
    * @dev returns the address used within the protocol to identify
    * @return the address assigned to Main
     */
    function mainAddress() internal pure returns(address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    }

}

//
/**
* @title DataProvider contract
* @author PandaFarm
**/
contract DataProvider is OperatorAccessControl {

    //Erc20 contract address of the platform
    address private tokenBambooAddress;
    //Erc20 contract address of the
    address private tokenBambooShootAddress;
    //NFT contract address of the panda
    address private nftPandaAddress;
    //NFT contract address of the land
    address private nftLandAddress;
    //Incentive mining contract
    address private gameMiningRewardAddress;
    //Incentive mining contract
    address private oracleAddress;
    //Platform Fee Address
    address private platformFeeAddress;

    event DataProviderAddressUpdated(address indexed _addr, uint256 _type);

    function setGameMiningRewardAddress(address _addr) public isOperatorOrOwner {
        gameMiningRewardAddress = _addr;
        emit DataProviderAddressUpdated(_addr, 1);
    }

    function getGameMiningRewardAddress() public view returns (address) {
        return gameMiningRewardAddress;
    }

    function setTokenBambooAddress(address _addr) public isOperatorOrOwner {
        tokenBambooAddress = _addr;
        emit DataProviderAddressUpdated(_addr, 2);
    }

    function getTokenBambooAddress() public view returns (address) {
        return tokenBambooAddress;
    }

    function setTokenBambooShootAddress(address _addr) public isOperatorOrOwner {
        tokenBambooShootAddress = _addr;
        emit DataProviderAddressUpdated(_addr, 3);
    }

    function getTokenBambooShootAddress() public view returns (address) {
        return tokenBambooShootAddress;
    }

    function setNftPandaAddress(address _addr) public isOperatorOrOwner {
        nftPandaAddress = _addr;
        emit DataProviderAddressUpdated(_addr, 4);
    }

    function getNftPandaAddress() public view returns (address) {
        return nftPandaAddress;
    }


    function setNftLandAddress(address _addr) public isOperatorOrOwner {
        nftLandAddress = _addr;
        emit DataProviderAddressUpdated(_addr, 5);
    }

    function getNftLandAddress() public view returns (address) {
        return nftLandAddress;
    }

    function setOracleAddress(address _addr) public isOperatorOrOwner {
        oracleAddress = _addr;
        emit DataProviderAddressUpdated(_addr, 6);
    }

    function getOracleAddress() public view returns (address) {
        return oracleAddress;
    }

    function setPlatformFeeAddress(address _addr) public isOperatorOrOwner {
        platformFeeAddress = _addr;
        emit DataProviderAddressUpdated(_addr, 7);
    }

    function getPlatformFeeAddress() public view returns (address) {
        return platformFeeAddress;
    }

}