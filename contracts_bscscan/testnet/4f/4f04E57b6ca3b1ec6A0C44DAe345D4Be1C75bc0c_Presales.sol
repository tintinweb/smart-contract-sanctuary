// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @author ECIO Engineering Team
/// @title Pre-Sale Smart Contract
contract Presales is Ownable {
    
    uint256 private constant LOT1_LOT2 = 1;
    uint256 private constant LOT3 = 2;
    
    //maximum BUSD per account.
    uint256 private constant MAXIMUM_BUSD_PER_ACCOUNT  = 200000000000000000000;
    
    //BUSD token address.
    address private constant BUSD_TOKEN_ADDRESS =  0x2B2E131937845454b57920604977E0aBf43be58D;
   // address private constant BUSD_TOKEN_ADDRESS = 0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee; //Testnet
    //address private constant BUSD_TOKEN_ADDRESS = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56; //Maintest
    
    //lotsStartTime is start timestamp of each pre-sale lot.
    mapping(uint => uint) public lotsStartTime;
    
    //lotsEndTime is start timestamp of each pre-sale lot.
    mapping(uint => uint) public lotsEndTime;

    //lotsTokenPool is total token of each pre-sale lot.
    mapping(uint => uint) public lotsTokenPool;
    
    //accountBalances is user's balances BUSD Token.
    mapping(address => uint) public accountBalances;
    
    //accountLotId use to keep id of pre-sale lot.
    mapping(address => uint) public accountLotId;
    
    //lot's balances.
    mapping(uint => uint) public lotsBalances;
   
   //BuyPresale Event
    event BuyPresale(address indexed _from, uint _amount);
   
    
    //Validate the account has registered or not ? 
    modifier hasWhitelistRegistered(address _account){
        require(lotId(_account) != 0, "The account is not whitelist listed.");
        _;
    }
    
    //Validate start and end timestamp to allow users to access buying function.
    modifier isPresaleOpen(address _account){
        
       uint _lotId = accountLotId[_account];
       require(lotsStartTime[_lotId] !=0 && lotsEndTime[_lotId] !=0 ,"Pre-sale hasn't started.");
       require(lotsStartTime[_lotId] <= block.timestamp,"Pre-sale hasn't started.");
       require(lotsEndTime[_lotId] >= block.timestamp,"Pre-sale has closed.");
        _;
    }

    /**
    * @dev token pool number of lots. 
    */
    function tokenPoolPerLot(uint _lotId) public view returns(uint) {
        return lotsTokenPool[_lotId];
    }

 
    /**
    * @dev SetPresaleTime is function for setup pre-sale's timestamp.
    * @param _lotId lotId of pre-sale
    * @param _startTime start timestamp
    * @param _endTime end timestamp
    */
    function setPresaleTime(uint _lotId, uint _startTime, uint _endTime, uint _tokenPool) external onlyOwner {
        lotsStartTime[_lotId] = _startTime;
        lotsEndTime[_lotId]   = _endTime;
        lotsTokenPool[_lotId] = _tokenPool;
    }
    
    function moveTokenPoolFromLoT1Lot2ToLot3() public onlyOwner{
        lotsTokenPool[LOT3] = lotsTokenPool[LOT3] + lotsTokenPool[LOT1_LOT2];
        lotsTokenPool[LOT1_LOT2] = 0;
    }

    /**
    * @dev ImportWhitelist is function for manually import addresses that are allowed to buying. 
    */
    function importWhitelist(address[] memory _accounts, uint[] memory _lotIds) public onlyOwner {
        for(uint256 i = 0; i < _accounts.length; ++i){
            accountLotId[_accounts[i]] = _lotIds[i];
            accountBalances[_accounts[i]] = 0;
        }
    }

    /**
    * @dev Show account's lotId
    */
    function lotId(address _account) public view returns(uint){
        return accountLotId[_account];
    }

    function tokenAvailableForBuying(address _account) private view returns(uint) {
        return MAXIMUM_BUSD_PER_ACCOUNT - accountBalances[_account];
    }

    /**
    * @dev The number of tokens available for buying.
    */
    function tokenAvailable(address _account) public view returns(uint) {
        
        uint _lotId = lotId(_account);
        uint _available =  tokenAvailableForBuying(_account);
        
        if(_lotId == LOT1_LOT2){
            return _available;

        }else if(_lotId == LOT3){
            if(lotsTokenPool[_lotId] >= MAXIMUM_BUSD_PER_ACCOUNT){
                  return _available;
            }else{

                if(lotsTokenPool[_lotId] <= _available){
                    return lotsTokenPool[_lotId];
                }
            }
        }

        return 0;
    }


    /**
    * @dev a function for transfer BUSD token to this contract address and waiting for claim ECIO Token later.
    */
    function buyPresale(address _account, uint _amount) external hasWhitelistRegistered(_account) isPresaleOpen(_account) {
       
        require(_amount > 0, "Your amount is too small.");

        IERC20 _token = IERC20(BUSD_TOKEN_ADDRESS);
        uint _balance = _token.balanceOf(msg.sender);
        require(_balance >= _amount, "Your balance is insufficient.");


        uint _lotId = accountLotId[_account];
        uint _available = tokenAvailable(_account);
         
        require(_amount <= _available, "the token pool is insufficient.");
       
        //transfer token from user's account into this smart contract address.
        _token.transferFrom(msg.sender, address(this), _amount);
        
        //Increase user's balances.
        accountBalances[_account] = accountBalances[_account] + _amount;
        
        //Increase lot's balances.
        lotsBalances[_lotId] = lotsBalances[_lotId] + _amount;

       //Increase lot's TokenPool.
        lotsTokenPool[_lotId] = lotsTokenPool[_lotId] - _amount;
        
        emit BuyPresale(msg.sender, _amount);
    }
    

    /**
    * @dev ContractBalances is function to show Token balance in smart contract. 
    */
    function contractBalances(address _contractAddress) public view returns(uint)  {
        IERC20 _token = IERC20(_contractAddress);
        uint256 _balance = _token.balanceOf(address(this));
        return _balance;
    }
    

    /**
    * @dev Transfer is function to transfer token from contract to other account.
    */

    function transfer(address _contractAddress, address  _to, uint _amount) public onlyOwner {
        IERC20 _token = IERC20(_contractAddress);
        _token.transfer(_to, _amount);
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

