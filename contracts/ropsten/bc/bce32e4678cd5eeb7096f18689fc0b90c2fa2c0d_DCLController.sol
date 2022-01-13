/**
 *Submitted for verification at Etherscan.io on 2022-01-13
*/

// File: openzeppelin-solidity/contracts/GSN/Context.sol

pragma solidity ^0.5.0;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
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

// File: openzeppelin-solidity/contracts/utils/Address.sol

pragma solidity ^0.5.5;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// File: contracts/interfaces/IENSRegistry.sol

pragma solidity ^0.5.15;

/**
 * @title EnsRegistry
 * @dev Extract of the interface for ENS Registry
*/
contract IENSRegistry {
    function setOwner(bytes32 node, address owner) public;
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) public;
    function setResolver(bytes32 node, address resolver) public;
    function owner(bytes32 node) public view returns (address);
    function resolver(bytes32 node) public view returns (address);
}

// File: contracts/interfaces/IDCLRegistrar.sol

pragma solidity ^0.5.15;

contract IDCLRegistrar {
    /**
	 * @dev Allows to create a subdomain (e.g. "nacho.dcl.eth"), set its resolver, owner and target address
	 * @param _subdomain - subdomain  (e.g. "nacho")
	 * @param _beneficiary - address that will become owner of this new subdomain
	 */
    function register(string calldata _subdomain, address _beneficiary) external;

     /**
	 * @dev Re-claim the ownership of a subdomain (e.g. "nacho").
     * @notice After a subdomain is transferred by this contract, the owner in the ENS registry contract
     * is still the old owner. Therefore, the owner should call `reclaim` to update the owner of the subdomain.
	 * @param _tokenId - erc721 token id which represents the node (subdomain).
     * @param _owner - new owner.
     */
    function reclaim(uint256 _tokenId, address _owner) external;

    /**
     * @dev Transfer a name to a new owner.
     * @param _from - current owner of the node.
     * @param _to - new owner of the node.
     * @param _id - node id.
     */
    function transferFrom(address _from, address _to, uint256 _id) public;

    /**
	 * @dev Check whether a name is available to be registered or not
	 * @param _labelhash - hash of the name to check
     * @return whether the name is available or not
     */
    function available(bytes32 _labelhash) public view returns (bool);

}

// File: openzeppelin-eth/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.2;

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/interfaces/IERC20Token.sol

pragma solidity ^0.5.15;


contract IERC20Token is IERC20{
    function balanceOf(address from) public view returns (uint256);
    function transferFrom(address from, address to, uint tokens) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);
    function burn(uint256 amount) public;
}

// File: contracts/ens/DCLController.sol

pragma solidity ^0.5.15;






contract DCLController is Ownable {
    using Address for address;

    // Price of each name
    uint256 constant public PRICE = 100 ether;

    // Accepted ERC20 token
    IERC20Token public acceptedToken;
    // DCL Registrar
    IDCLRegistrar public registrar;

    // Price of each name
    uint256 public maxGasPrice = 20000000000; // 20 gwei

    // Emitted when a name is bought
    event NameBought(address indexed _caller, address indexed _beneficiary, uint256 _price, string _name);

    // Emitted when the max gas price is changed
    event MaxGasPriceChanged(uint256 indexed _oldMaxGasPrice, uint256 indexed _newMaxGasPrice);

    /**
	 * @dev Constructor of the contract
     * @param _acceptedToken - address of the accepted token
     * @param _registrar - address of the DCL registrar contract
	 */
    constructor(IERC20Token _acceptedToken, IDCLRegistrar _registrar) public {
        require(address(_acceptedToken).isContract(), "Accepted token should be a contract");
        require(address(_registrar).isContract(), "Registrar should be a contract");

        // Accepted token
        acceptedToken = _acceptedToken;
        // DCL registrar
        registrar = _registrar;
    }

    /**
	 * @dev Register a name
     * @param _name - name to be registered
	 * @param _beneficiary - owner of the name
	 */
    function register(string memory _name, address _beneficiary) public {
        // Check gas price
        require(tx.gasprice <= maxGasPrice, "Maximum gas price allowed exceeded");
        // Check for valid beneficiary
        require(_beneficiary != address(0), "Invalid beneficiary");

        // Check if the name is valid
        _requireNameValid(_name);
        // Check if the sender has at least `price` and the contract has allowance to use on its behalf
        _requireBalance(msg.sender);

        // Register the name
        registrar.register(_name, _beneficiary);
        // Debit `price` from sender
        acceptedToken.transferFrom(msg.sender, address(this), PRICE);
        // Burn it
        acceptedToken.burn(PRICE);
        // Log
        emit NameBought(msg.sender, _beneficiary, PRICE, _name);
    }

    /**
     * @dev Update max gas price
     * @param _maxGasPrice - new max gas price to be used
     */
    function updateMaxGasPrice(uint256 _maxGasPrice) external onlyOwner {
        require(_maxGasPrice != maxGasPrice, "Max gas price should be different");
        require(
            _maxGasPrice >= 1000000000,
            "Max gas price should be greater than or equal to 1 gwei"
        );

        emit MaxGasPriceChanged(maxGasPrice, _maxGasPrice);

        maxGasPrice = _maxGasPrice;
    }

    /**
     * @dev Validate if a user has balance and the contract has enough allowance
     * to use user's accepted token on his belhalf
     * @param _user - address of the user
     */
    function _requireBalance(address _user) internal view {
        require(
            acceptedToken.balanceOf(_user) >= PRICE,
            "Insufficient funds"
        );
        require(
            acceptedToken.allowance(_user, address(this)) >= PRICE,
            "The contract is not authorized to use the accepted token on sender behalf"
        );
    }

    /**
    * @dev Validate a nane
    * @notice that only a-z is allowed
    * @param _name - string for the name
    */
    function _requireNameValid(string memory _name) internal pure {
        bytes memory tempName = bytes(_name);
        require(
            tempName.length >= 2 && tempName.length <= 15,
            "Name should be greather than or equal to 2 and less than or equal to 15"
        );
        for(uint256 i = 0; i < tempName.length; i++) {
            require(_isLetter(tempName[i]) || _isNumber(tempName[i]), "Invalid Character");
        }
    }

    function _isLetter(bytes1 _char) internal pure returns (bool) {
        return (_char >= 0x41 && _char <= 0x5A) || (_char >= 0x61 && _char <= 0x7A);
    }

    function _isNumber(bytes1 _char) internal pure returns (bool) {
        return (_char >= 0x30 && _char <= 0x39);
    }

}