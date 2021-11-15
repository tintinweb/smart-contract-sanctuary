/*
User Wallet

SPDX-License-Identifier: MIT
*/
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract UserWallet {
    mapping (address => bool) public _admin;
    address payable public _owner;
    event AuthorizedModule(address indexed module, bool value);
    event Invoked(address indexed module, address indexed target, uint indexed value, bytes data);
    constructor (address _module, address payable owner) public {
        _admin[address(_module)] = true; // ALready our deployed admin smart contract
        _admin[address(owner)] = true;
        _owner = owner;
        emit AuthorizedModule(address(_module), _admin[address(_module)]);
    }
 
    fallback()
        payable
        external
    {
        _owner.transfer(msg.value);
    }
    function updateAdmin(address adminAddress,bool status) public authorize {
        _admin[adminAddress] = status;
    }
    
    function updateOwner(address payable newOwner) public authorize {
        _owner = newOwner;
    }
    modifier authorize() {
        if(_admin[msg.sender]) {
            _;
        }
        else {
            revert('EUW: Not Authorized');
        }
    }
    function withdrawalERC20 (
        address contractAddress,
        address receiverAddress,
        uint256  contractAmountToWithdrawal
    )
        public
        authorize
        returns (bool)
    {
        require(IERC20(contractAddress).balanceOf(address(this)) >= contractAmountToWithdrawal,'EUW: Insufficient Balance');
        require(IERC20(contractAddress).transfer(receiverAddress,contractAmountToWithdrawal),'EUW: Transfer Error');
        return true;
    }
    
    function withdrawalETH(address payable receiverAddress, uint256  ethAmountToWithdrawal) public authorize returns(bool) {
        receiverAddress.transfer(ethAmountToWithdrawal);
    }
}

/*
User Wallet Factory

SPDX-License-Identifier: MIT
*/
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./UserWallet.sol";



contract UserWalletFactory is Ownable {
    mapping (address => bool) public _admin;
    
    //platform specific constant required to generate address
    string constant ACCOUNT_SALT_MSG_PREFIX = "SALTV1.0";
    
    // The hash of the wallet contract
    bytes32 public contractCodeHash;
    
    // The code of the wallet contract
    bytes public contractCode;
    
    event WalletCreated(address indexed _wallet, address indexed _owner);
    
    constructor () public {
        //get the contract code for dynamically deploying new wallets
        contractCode = type(UserWallet).creationCode;
        
        contractCode = abi.encodePacked(contractCode, abi.encode(address(this), msg.sender));
        //create contract code hash
        contractCodeHash = keccak256(contractCode);
    }
    function updateAdmin(address adminAddress,bool status) public authorize {
        _admin[adminAddress] = status;
    }
    modifier authorize() {
            if(owner() == msg.sender || _admin[msg.sender]) {
                _;
            }
            else {
                revert('EUW: Not Authorized');
            }
        }
        
    //withdrawal from smart contract when limit increase in case of multiple contract need to withdraw
    function withdrawalETH (
        address payable receiverAddress,
        address payable[] memory allUserContractAddressesAsSender,
        uint256  contractAmountToWithdrawal)
        public authorize
    {
        uint256 amountWithdrawalSuccessfully = 0;
        for(uint8 i = 0;i < allUserContractAddressesAsSender.length; i++)
        {
            if(amountWithdrawalSuccessfully >= contractAmountToWithdrawal){
                break;
            }
            uint256 balanceOfContract = address(allUserContractAddressesAsSender[i]).balance;
            uint256 amountToWithdrawalNow = 0;
            if((amountWithdrawalSuccessfully + balanceOfContract) <= contractAmountToWithdrawal) {
                amountToWithdrawalNow = balanceOfContract;
                amountWithdrawalSuccessfully += balanceOfContract;
            }else{
                amountToWithdrawalNow = (contractAmountToWithdrawal - amountWithdrawalSuccessfully);
                amountWithdrawalSuccessfully += amountToWithdrawalNow;
            }
            UserWallet(allUserContractAddressesAsSender[i]).withdrawalETH(receiverAddress,amountToWithdrawalNow);
        }
    }
    //withdrawal from smart contract when limit increase in case of multiple contract need to withdraw
    function withdrawalERC20 (
        address payable erc20Contract,
        address receiverAddress,
        address payable[] memory allUserContractAddressesAsSender,
        uint256  contractAmountToWithdrawal)
        public authorize
    {
        uint256 amountWithdrawalSuccessfully = 0;
        for(uint8 i = 0;i < allUserContractAddressesAsSender.length; i++)
        {
            if(amountWithdrawalSuccessfully >= contractAmountToWithdrawal){
                break;
            }
            uint256 balanceOfContract = IERC20(erc20Contract).balanceOf(allUserContractAddressesAsSender[i]);
            uint256 amountToWithdrawalNow = 0;
            if((amountWithdrawalSuccessfully + balanceOfContract) <= contractAmountToWithdrawal) {
                amountToWithdrawalNow = balanceOfContract;
                amountWithdrawalSuccessfully += balanceOfContract;
            }else{
                amountToWithdrawalNow = (contractAmountToWithdrawal - amountWithdrawalSuccessfully);
                amountWithdrawalSuccessfully += amountToWithdrawalNow;
            }
            UserWallet(allUserContractAddressesAsSender[i]).withdrawalERC20(erc20Contract,receiverAddress,amountToWithdrawalNow);
        }
    }
    
    
      function deploy(bytes32 salt) external authorize returns (address) {
        address payable addr;
        bytes memory bytecode  = contractCode;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
        
        emit WalletCreated(addr, msg.sender);
        require(addr != address(0), "Create2: Failed on deploy");
        return addr;
    }
    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt) public view returns (address) {
        return computeAddress(salt, contractCodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash, address deployer) internal pure returns (address) {
        bytes32 _data = keccak256(
            abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash)
        );
        return address(uint256(_data));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
contract Ownable is Context {
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

pragma solidity ^0.6.0;

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

