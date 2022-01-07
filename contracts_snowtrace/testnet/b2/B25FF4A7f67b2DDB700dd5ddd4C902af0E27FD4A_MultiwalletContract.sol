//Arkius Public Benefit Corporation Privileged & Confidential
// SPDX-License-Identifier: None
pragma solidity 0.8.0;
import './interfaces/IArkiusAttentionSeekerToken.sol';
import './interfaces/IERC20.sol';
import './interfaces/IEntity.sol';
import './utils/Ownable.sol';

/**
 * @dev This contract is for the Multiwallet.
 *  It keeps record of the available rewards for everyone,
 *  which can be checked and claimed when available.
 */
contract MultiwalletContract is Ownable {

    //Enum for Recipients as in Marketplace.
    enum Recipients { member, certifier, attentionSeeker, treasury, devfund, arkiusPBCLicense }

    /// @dev mapping from Recipient Type => Recipient's Address => Recipient's multiwallet balance.
    mapping(Recipients => mapping(address => uint256)) private _multiwallet;

    /// @dev mapping from Recipient Type => Recipient's Address => Recipient's claimable balance.
    mapping(Recipients => mapping(address => uint256)) private _claim;

    /// @dev mapping from Address  => Permission to access functions (true/false).
    mapping(address => bool) private _acccessibleBy;

    /**
     * @dev Arkius Governance Token interface instance
     *
     * Used to call a function from TokenContract
     * which is used to transfer the token from the account of caller
     */
    IERC20 private _arkiusGovernanceToken;
    
    event Multiwallet(address indexed add, uint256 indexed value);
    
    event UpdateCampaignContract(address indexed campaign);
    
    event UpdateTokenContract(address indexed tokenContract);
    
    event MultiwalletTransfer(address indexed sender, address indexed recipient, uint256 indexed value);
    
    event Demultiwallet(address indexed sender, uint256 indexed value);
    
    event Unmultiwallet(address indexed recipient, uint256 indexed value);
    
    event Claim(address indexed sender, uint256 indexed value);
    
    event SetAllowance(address indexed allowed, bool value);

    address private _campaignContract;

    modifier onlyAllowed(){
        require(_acccessibleBy[_msgSender()] == true, "Caller is not allowed to access.");
        _;
    }

    /**
     * @dev Constructor to initialize AkiusGovernanceTokenAddress and owner address
     *
     * @param arkiusTokenAddress Address of the GovernanceToken Contract
     */
    constructor(IERC20 arkiusTokenAddress, address multisigAddress) Ownable(multisigAddress) {
        require(address(arkiusTokenAddress) != address(0), "Invalid Token address.");
        require(multisigAddress != address(0), "Invalid mulisig address.");
        _arkiusGovernanceToken = arkiusTokenAddress;
    }

    /**
     * @dev Function to add values in multiwallet for Member, Certifier and AttentionSeeker
     *
     * @param mAddress Address of the person in whose multiwallet amount is to be added.
     * @param mType    RecipientType of the person..
     * @param amount   Amount to be added to multiwallet.
     */
    function multiwallet(address mAddress, Recipients mType, uint256 amount) external onlyAllowed {
        _multiwallet[mType][mAddress] = _multiwallet[mType][mAddress] + amount;
        emit Multiwallet(mAddress, amount);
    }

    function setCampaignContract(address campaign) public onlyOwner {
        require(campaign != address(0), "Invalid address.");
        _campaignContract = campaign;
        _acccessibleBy[campaign] = true;
        emit UpdateCampaignContract(campaign);
    }

    function setGovernanceToken(IERC20 govTokenAddress) public onlyOwner {
        require(address(govTokenAddress) != address(0), "Invalid address.");
        _arkiusGovernanceToken = govTokenAddress;
        emit UpdateTokenContract(address(govTokenAddress));
    }

    /**
     * @dev Function to transfer amount within multiwallet and make it claimable.
     *
     * @param fromAddress Address of the person from whom multiwallet amount is to be transferred.
     * @param fromType    Recipient Type of the person from whom multiwallet amount is to be transferred.
     * @param toAddress   Address of the person from whom multiwallet amount is to be transferred.
     * @param toType      Recipient Type of the person from whom multiwallet amount is to be transferred.
     * @param amount      Amount to be deMultiwalleted.
     */
    function multiwalletTransfer(address fromAddress, Recipients fromType, address toAddress, Recipients toType, uint256 amount) external onlyAllowed {
        _multiwallet[fromType][fromAddress] = _multiwallet[fromType][fromAddress] - amount;
        _claim[toType][toAddress]  = _claim[toType][toAddress] + amount;
        emit MultiwalletTransfer(fromAddress, toAddress, amount);
    }

    /**
     * @dev Function to make amount claimable in multiwallet.
     *
     * @param mAddress Address of the person whose multiwallet is to be updated.
     * @param mType    Recipient Type of the person.
     * @param amount   Amount to be deMultiwalleted(made claimable).
     */
    function deMultiwallet(address mAddress, Recipients mType, uint256 amount) external onlyAllowed {
        _multiwallet[mType][mAddress] = _multiwallet[mType][mAddress] - amount;
        _claim[mType][mAddress] = _claim[mType][mAddress] + amount;
        emit Demultiwallet(mAddress, amount);
    }

    /**
     * @dev Function to directly transfer back amount, instead of making it claimable.
     *
     * @param mAddress Address of the person whose multiwallet is to be updated.
     * @param mType    Recipient Type of the person.
     * @param amount   Amount to be deMultiwalleted(made claimable).
     */
    function unMultiwallet(address mAddress, Recipients mType, uint256 amount) external onlyAllowed {
        _multiwallet[mType][mAddress] = _multiwallet[mType][mAddress] - amount;
        _arkiusGovernanceToken.transfer(mAddress, amount);
        emit Unmultiwallet(mAddress, amount);
    }

    /**
     * @dev Function to transfer claimable amount to Recipient who calls this function.
     */
    function claim(Recipients recipientType) external {
        _arkiusGovernanceToken.transferUnlock(_msgSender(), _claim[recipientType][_msgSender()]);
        emit Claim(_msgSender(), _claim[recipientType][_msgSender()]);
        _claim[recipientType][_msgSender()] = 0;
    }

    function setAllowance(address allow, bool value) external onlyOwner {
        require(address(allow) != address(0), "Invalid address.");
        _acccessibleBy[allow] = value;
        emit SetAllowance(allow, value);
    }

    function accessibleBy(address add) public view returns(bool) {
        return _acccessibleBy[add];
    }

    function multiwalletBalance(Recipients recipient, address add) public view returns(uint256) {
        return _multiwallet[recipient][add];
    }

    function claimableBalance(Recipients recipient, address add) public view returns(uint256) {
        return _claim[recipient][add];
    }

    function campaignContract() public view returns(address) {
        return _campaignContract;
    }

    function governanceTokenAddress() public view returns(IERC20) {
        return _arkiusGovernanceToken;
    }
}

//SPDX-License-Identifier:None
pragma solidity ^0.8.0;

interface IArkiusAttentionSeekerToken {
    function attentionSeekerIdOf(address owner) external view returns (uint256);

    function burn(address owner, uint256 value) external;
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

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
     * @dev Returns the amount of locked tokens owned by `account`.
     */
    function lockedBalanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`, and unlocks it.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferUnlock(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance. The amount is also unlocked.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFromUnlock(address sender, address recipient, uint256 amount) external returns (bool);
    
    /**
     * @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     * Emits a {Transfer} event with `from` set to the zero address.
     */
    function mint(address account, uint256 amount) external;

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     */
    function burn(address account, uint256 amount) external;

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

//SPDX-License-Identifier:None
pragma solidity ^0.8.0;
pragma abicoder v2;

interface IEntity {
    enum IEntityType {product, company, campaign}
    
    struct ReturnEntity{
            uint256     id;
            address     creator;
            IEntityType entityType;
            string      title;
            string      description;
            string      metadata;
    }

    function createEntity(uint256       id,
                          string memory title,
                          IEntityType   types,
                          string memory description,
                          string memory metadata,
                          address attentionSeekerAddress) external;

    function getEntity(uint256 id) external view returns(ReturnEntity memory);

    function entityExist(uint256 id) external view returns(bool);

    function deleteEntity(uint256 id, address attentionSeekerAddress) external;

    function editEntity(uint256       id,
                        string memory title,
                        string memory description,
                        string memory metadata,
                        address attentionSeekerAddress) external;
                }

//SPDX-License-Identifier:None
pragma solidity 0.8.0;

import './Context.sol';

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;
    address private _nominatedOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnershipNominated(address indexed previousOwner, address indexed newOwner);
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor (address multisig) {
        _owner = multisig;
        emit OwnershipTransferred(address(0), multisig);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view returns (address) {
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
    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Nominate new Owner of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function nominateNewOwner(address newOwner) external onlyOwner {
        _nominatedOwner = newOwner;
        emit OwnershipNominated(_owner,newOwner);
    }

    /**
     * @dev Nominated Owner can accept the Ownership of the contract.
     * Can only be called by the nominated owner.
     */
    function acceptOwnership() external {
        require(msg.sender == _nominatedOwner, "Ownable: You must be nominated before you can accept ownership");
        emit OwnershipTransferred(_owner, _nominatedOwner);
        _owner = _nominatedOwner;
        _nominatedOwner = address(0);
    }
}

//SPDX-License-Identifier:None
pragma solidity 0.8.0;

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

    /// Empty constructor, to prevent people from mistakenly deploying
    /// an instance of this contract, which should be used via inheritance.

    constructor () { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {

        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}