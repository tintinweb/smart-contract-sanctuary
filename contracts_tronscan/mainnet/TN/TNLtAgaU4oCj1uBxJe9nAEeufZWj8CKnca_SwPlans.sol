//SourceUnit: AddressPayable.sol

pragma solidity ^0.5.16;
// We can define a library for explicitly converting ``address``
// to ``address payable`` as a workaround.
library AddressPayable {

    //do not consistent to return true/false from the transfer
    //TODO: Replace in deloy script
    address constant USDTAddr = 0xa614f803B6FD780986A42c78Ec9c7f77e6DeD13C;

    function makePayable(address x) internal pure returns (address payable) {
        return address(uint160(x));
    }

    function isContract(address x) internal view returns (bool) {
        uint size;
        assembly {
            size := extcodesize(x)
        }
        return size > 0;
    }

    function isValid(address x) internal pure returns (bool){
        return address(x) != address(0);
    }

    function invokeAndCheckSuccess(address _addr, bytes memory _calldata)
    private
    returns (bool)
    {
        bool ret;
        assembly {
            let ptr := mload(0x40)    // free memory pointer

            let success := call(
            gas, // forward all gas
            _addr, // address
            0, // no value
            add(_calldata, 0x20), // calldata start
            mload(_calldata), // calldata length
            ptr, // write output over free memory
            0x20                  // uint256 return
            )

            if gt(success, 0) {
            // Check number of bytes returned from last function call
                switch returndatasize

                // No bytes returned: assume success
                case 0 {
                    ret := 1
                }

                // 32 bytes returned: check if non-zero
                case 0x20 {
                // Only return success if returned data was true
                // Already have output in ptr
                    ret := eq(mload(ptr), 1)
                }

                // Not sure what was returned: don't mark as success
                default {}
            }
        }
        return ret;
    }


    function staticInvoke(address _addr, bytes memory _calldata)
        private
        view
        returns (bool, uint256)
    {
        bool success;
        uint256 ret;
        assembly {
            let ptr := mload(0x40)    // free memory pointer

            success := staticcall(
                gas,                  // forward all gas
                _addr,                // address
                add(_calldata, 0x20), // calldata start
                mload(_calldata),     // calldata length
                ptr,                  // write output over free memory
                0x20                  // uint256 return
            )

            if gt(success, 0) {
                ret := mload(ptr)
            }
        }
        return (success, ret);
    }

    function safeApprove(address token, address to, uint value) internal returns (bool){
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        return (success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function safeTransfer(address token, address to, uint value) internal returns (bool){
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        if (token == USDTAddr) {
            return success;
        }
        return (success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal returns (bool){
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        return (success && (data.length == 0 || abi.decode(data, (bool))));
    }
}


//SourceUnit: Context.sol

pragma solidity ^0.5.10;

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
    constructor () internal {}
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    function _txOrigin() internal view returns (address payable) {
        return tx.origin;
    }
}


//SourceUnit: IJustSwap.sol

pragma solidity ^0.5.16;

interface IJustswapFactory {

    event NewExchange(address indexed token, address indexed exchange);

    function initializeFactory(address template) external;

    function createExchange(address token) external returns (address payable);

    function getExchange(address token) external view returns (address payable);

    function getToken(address token) external view returns (address);

    function getTokenWihId(uint256 token_id) external view returns (address);

}

interface IJustSwapExchange {

    // Trigger the event in trxToTokenSwapInput and trxToTokenSwapOutput
    event TokenPurchase(address indexed buyer, uint256 indexed trx_sold, uint256 indexed tokens_bought);


    // Trigger the event in tokenToTrxSwapInput, tokenToTrxSwapOutput, trxToTokenSwapInput and trxToTokenSwapOutput
    event TrxPurchase(address indexed buyer, uint256 indexed tokens_sold, uint256 indexed trx_bought);


    // Sell TRX (fixed amount) to buy token
    function trxToTokenSwapInput(uint256 min_tokens, uint256 deadline) external payable
    returns (uint256);


    // Sell TRX to buy token (fixed amount)
    function trxToTokenSwapOutput(uint256 tokens_bought, uint256 deadline) external
    payable returns (uint256);


    // Sell token to buy TRX (token is in a fixed amount)
    function tokenToTrxSwapInput(uint256 tokens_sold, uint256 min_trx, uint256 deadline) external returns (uint256);


    // Sell token to buy TRX (fixed amount)
    function tokenToTrxSwapOutput(uint256 trx_bought, uint256 max_tokens, uint256
        deadline) external returns (uint256);


    // Sell token1 and buy token2 (token1 is in a fixd amount). Since TRX functions as intermediary, both token1 and token2 need to have exchange addresses.
    function tokenToTokenSwapInput(uint256 tokens_sold, uint256 min_tokens_bought,
        uint256 min_trx_bought, uint256 deadline, address token_addr) external returns (uint256);

    // Sell token1 and buy token2 (token2 is in a fixd amount).
    function tokenToTokenSwapOutput(uint256 tokens_bought, uint256 max_tokens_sold,
        uint256 max_trx_sold, uint256 deadline, address token_addr) external returns (uint256);

    // Sell token1 and buy token2 (token1 is in a fixd amount).Then, transfer the purchased token2 to the recipient's address
    function tokenToTokenTransferInput(uint256 tokens_sold, uint256 min_tokens_bought,
        uint256 min_trx_bought, uint256 deadline, address recipient, address token_addr) external returns (uint256);

    //To know the amount of TRC20 token available for purchase through the amount of TRX sold
    function getTrxToTokenInputPrice(uint256 trx_sold) external view returns (uint256);

    //To know the amount of TRX to be paid through the amount of TRC20 token bought
    function getTrxToTokenOutputPrice(uint256 tokens_bought) external view returns (uint256);

    //To know the amount of TRX available for purchase through the amount of TRC20 token sold
    function getTokenToTrxInputPrice(uint256 tokens_sold) external view returns (uint256);

    //To know the amount of TRC20 token to be paid through the amount of TRX bought
    function getTokenToTrxOutputPrice(uint256 trx_bought) external view returns (uint256);


}


interface IJustswapExchangeC1 {

    event TokenPurchase(address indexed buyer, uint256 indexed trx_sold, uint256 indexed tokens_bought);
    event TrxPurchase(address indexed buyer, uint256 indexed tokens_sold, uint256 indexed trx_bought);
    event AddLiquidity(address indexed provider, uint256 indexed trx_amount, uint256 indexed token_amount);
    event RemoveLiquidity(address indexed provider, uint256 indexed trx_amount, uint256 indexed token_amount);

    /**
      * @dev Pricing function for converting between TRX && Tokens.
      * @param input_amount Amount of TRX or Tokens being sold.
      * @param input_reserve Amount of TRX or Tokens (input type) in exchange reserves.
      * @param output_reserve Amount of TRX or Tokens (output type) in exchange reserves.
      * @return Amount of TRX or Tokens bought.
      */
    function getInputPrice(uint256 input_amount, uint256 input_reserve, uint256 output_reserve) external view returns (uint256);

    /**
      * @dev Pricing function for converting between TRX && Tokens.
      * @param output_amount Amount of TRX or Tokens being bought.
      * @param input_reserve Amount of TRX or Tokens (input type) in exchange reserves.
      * @param output_reserve Amount of TRX or Tokens (output type) in exchange reserves.
      * @return Amount of TRX or Tokens sold.
      */
    function getOutputPrice(uint256 output_amount, uint256 input_reserve, uint256 output_reserve) external view returns (uint256);


    /**
     * @notice Convert TRX to Tokens.
     * @dev User specifies exact input (msg.value) && minimum output.
     * @param min_tokens Minimum Tokens bought.
     * @param deadline Time after which this transaction can no longer be executed.
     * @return Amount of Tokens bought.
     */
    function trxToTokenSwapInput(uint256 min_tokens, uint256 deadline) external payable returns (uint256);

    /**
     * @notice Convert TRX to Tokens && transfers Tokens to recipient.
     * @dev User specifies exact input (msg.value) && minimum output
     * @param min_tokens Minimum Tokens bought.
     * @param deadline Time after which this transaction can no longer be executed.
     * @param recipient The address that receives output Tokens.
     * @return  Amount of Tokens bought.
     */
    function trxToTokenTransferInput(uint256 min_tokens, uint256 deadline, address recipient) external payable returns (uint256);


    /**
     * @notice Convert TRX to Tokens.
     * @dev User specifies maximum input (msg.value) && exact output.
     * @param tokens_bought Amount of tokens bought.
     * @param deadline Time after which this transaction can no longer be executed.
     * @return Amount of TRX sold.
     */
    function trxToTokenSwapOutput(uint256 tokens_bought, uint256 deadline) external payable returns (uint256);
    /**
     * @notice Convert TRX to Tokens && transfers Tokens to recipient.
     * @dev User specifies maximum input (msg.value) && exact output.
     * @param tokens_bought Amount of tokens bought.
     * @param deadline Time after which this transaction can no longer be executed.
     * @param recipient The address that receives output Tokens.
     * @return Amount of TRX sold.
     */
    function trxToTokenTransferOutput(uint256 tokens_bought, uint256 deadline, address recipient) external payable returns (uint256);

    /**
     * @notice Convert Tokens to TRX.
     * @dev User specifies exact input && minimum output.
     * @param tokens_sold Amount of Tokens sold.
     * @param min_trx Minimum TRX purchased.
     * @param deadline Time after which this transaction can no longer be executed.
     * @return Amount of TRX bought.
     */
    function tokenToTrxSwapInput(uint256 tokens_sold, uint256 min_trx, uint256 deadline) external returns (uint256);

    /**
     * @notice Convert Tokens to TRX && transfers TRX to recipient.
     * @dev User specifies exact input && minimum output.
     * @param tokens_sold Amount of Tokens sold.
     * @param min_trx Minimum TRX purchased.
     * @param deadline Time after which this transaction can no longer be executed.
     * @param recipient The address that receives output TRX.
     * @return  Amount of TRX bought.
     */
    function tokenToTrxTransferInput(uint256 tokens_sold, uint256 min_trx, uint256 deadline, address recipient) external returns (uint256);

    /**
     * @notice Convert Tokens to TRX.
     * @dev User specifies maximum input && exact output.
     * @param trx_bought Amount of TRX purchased.
     * @param max_tokens Maximum Tokens sold.
     * @param deadline Time after which this transaction can no longer be executed.
     * @return Amount of Tokens sold.
     */
    function tokenToTrxSwapOutput(uint256 trx_bought, uint256 max_tokens, uint256 deadline) external returns (uint256);

    /**
     * @notice Convert Tokens to TRX && transfers TRX to recipient.
     * @dev User specifies maximum input && exact output.
     * @param trx_bought Amount of TRX purchased.
     * @param max_tokens Maximum Tokens sold.
     * @param deadline Time after which this transaction can no longer be executed.
     * @param recipient The address that receives output TRX.
     * @return Amount of Tokens sold.
     */
    function tokenToTrxTransferOutput(uint256 trx_bought, uint256 max_tokens, uint256 deadline, address recipient) external returns (uint256);

    /**
     * @notice Convert Tokens (token) to Tokens (token_addr).
     * @dev User specifies exact input && minimum output.
     * @param tokens_sold Amount of Tokens sold.
     * @param min_tokens_bought Minimum Tokens (token_addr) purchased.
     * @param min_trx_bought Minimum TRX purchased as intermediary.
     * @param deadline Time after which this transaction can no longer be executed.
     * @param token_addr The address of the token being purchased.
     * @return Amount of Tokens (token_addr) bought.
     */
    function tokenToTokenSwapInput(
        uint256 tokens_sold,
        uint256 min_tokens_bought,
        uint256 min_trx_bought,
        uint256 deadline,
        address token_addr)
    external returns (uint256);

    /**
     * @notice Convert Tokens (token) to Tokens (token_addr) && transfers
     *         Tokens (token_addr) to recipient.
     * @dev User specifies exact input && minimum output.
     * @param tokens_sold Amount of Tokens sold.
     * @param min_tokens_bought Minimum Tokens (token_addr) purchased.
     * @param min_trx_bought Minimum TRX purchased as intermediary.
     * @param deadline Time after which this transaction can no longer be executed.
     * @param recipient The address that receives output TRX.
     * @param token_addr The address of the token being purchased.
     * @return Amount of Tokens (token_addr) bought.
     */
    function tokenToTokenTransferInput(
        uint256 tokens_sold,
        uint256 min_tokens_bought,
        uint256 min_trx_bought,
        uint256 deadline,
        address recipient,
        address token_addr)
    external returns (uint256);


    /**
     * @notice Convert Tokens (token) to Tokens (token_addr).
     * @dev User specifies maximum input && exact output.
     * @param tokens_bought Amount of Tokens (token_addr) bought.
     * @param max_tokens_sold Maximum Tokens (token) sold.
     * @param max_trx_sold Maximum TRX purchased as intermediary.
     * @param deadline Time after which this transaction can no longer be executed.
     * @param token_addr The address of the token being purchased.
     * @return Amount of Tokens (token) sold.
     */
    function tokenToTokenSwapOutput(
        uint256 tokens_bought,
        uint256 max_tokens_sold,
        uint256 max_trx_sold,
        uint256 deadline,
        address token_addr)
    external returns (uint256);

    /**
     * @notice Convert Tokens (token) to Tokens (token_addr) && transfers
     *         Tokens (token_addr) to recipient.
     * @dev User specifies maximum input && exact output.
     * @param tokens_bought Amount of Tokens (token_addr) bought.
     * @param max_tokens_sold Maximum Tokens (token) sold.
     * @param max_trx_sold Maximum TRX purchased as intermediary.
     * @param deadline Time after which this transaction can no longer be executed.
     * @param recipient The address that receives output TRX.
     * @param token_addr The address of the token being purchased.
     * @return Amount of Tokens (token) sold.
     */
    function tokenToTokenTransferOutput(
        uint256 tokens_bought,
        uint256 max_tokens_sold,
        uint256 max_trx_sold,
        uint256 deadline,
        address recipient,
        address token_addr)
    external returns (uint256);

    /**
     * @notice Convert Tokens (token) to Tokens (exchange_addr.token).
     * @dev Allows trades through contracts that were not deployed from the same factory.
     * @dev User specifies exact input && minimum output.
     * @param tokens_sold Amount of Tokens sold.
     * @param min_tokens_bought Minimum Tokens (token_addr) purchased.
     * @param min_trx_bought Minimum TRX purchased as intermediary.
     * @param deadline Time after which this transaction can no longer be executed.
     * @param exchange_addr The address of the exchange for the token being purchased.
     * @return Amount of Tokens (exchange_addr.token) bought.
     */
    function tokenToExchangeSwapInput(
        uint256 tokens_sold,
        uint256 min_tokens_bought,
        uint256 min_trx_bought,
        uint256 deadline,
        address exchange_addr)
    external returns (uint256);

    /**
     * @notice Convert Tokens (token) to Tokens (exchange_addr.token) && transfers
     *         Tokens (exchange_addr.token) to recipient.
     * @dev Allows trades through contracts that were not deployed from the same factory.
     * @dev User specifies exact input && minimum output.
     * @param tokens_sold Amount of Tokens sold.
     * @param min_tokens_bought Minimum Tokens (token_addr) purchased.
     * @param min_trx_bought Minimum TRX purchased as intermediary.
     * @param deadline Time after which this transaction can no longer be executed.
     * @param recipient The address that receives output TRX.
     * @param exchange_addr The address of the exchange for the token being purchased.
     * @return Amount of Tokens (exchange_addr.token) bought.
     */
    function tokenToExchangeTransferInput(
        uint256 tokens_sold,
        uint256 min_tokens_bought,
        uint256 min_trx_bought,
        uint256 deadline,
        address recipient,
        address exchange_addr)
    external returns (uint256);

    /**
     * @notice Convert Tokens (token) to Tokens (exchange_addr.token).
     * @dev Allows trades through contracts that were not deployed from the same factory.
     * @dev User specifies maximum input && exact output.
     * @param tokens_bought Amount of Tokens (token_addr) bought.
     * @param max_tokens_sold Maximum Tokens (token) sold.
     * @param max_trx_sold Maximum TRX purchased as intermediary.
     * @param deadline Time after which this transaction can no longer be executed.
     * @param exchange_addr The address of the exchange for the token being purchased.
     * @return Amount of Tokens (token) sold.
     */
    function tokenToExchangeSwapOutput(
        uint256 tokens_bought,
        uint256 max_tokens_sold,
        uint256 max_trx_sold,
        uint256 deadline,
        address exchange_addr)
    external returns (uint256);

    /**
     * @notice Convert Tokens (token) to Tokens (exchange_addr.token) && transfers
     *         Tokens (exchange_addr.token) to recipient.
     * @dev Allows trades through contracts that were not deployed from the same factory.
     * @dev User specifies maximum input && exact output.
     * @param tokens_bought Amount of Tokens (token_addr) bought.
     * @param max_tokens_sold Maximum Tokens (token) sold.
     * @param max_trx_sold Maximum TRX purchased as intermediary.
     * @param deadline Time after which this transaction can no longer be executed.
     * @param recipient The address that receives output TRX.
     * @param exchange_addr The address of the exchange for the token being purchased.
     * @return Amount of Tokens (token) sold.
     */
    function tokenToExchangeTransferOutput(
        uint256 tokens_bought,
        uint256 max_tokens_sold,
        uint256 max_trx_sold,
        uint256 deadline,
        address recipient,
        address exchange_addr)
    external returns (uint256);


    /***********************************|
    |         Getter Functions          |
    |__________________________________*/

    /**
     * @notice external price function for TRX to Token trades with an exact input.
     * @param trx_sold Amount of TRX sold.
     * @return Amount of Tokens that can be bought with input TRX.
     */
    function getTrxToTokenInputPrice(uint256 trx_sold) external view returns (uint256);

    /**
     * @notice external price function for TRX to Token trades with an exact output.
     * @param tokens_bought Amount of Tokens bought.
     * @return Amount of TRX needed to buy output Tokens.
     */
    function getTrxToTokenOutputPrice(uint256 tokens_bought) external view returns (uint256);

    /**
     * @notice external price function for Token to TRX trades with an exact input.
     * @param tokens_sold Amount of Tokens sold.
     * @return Amount of TRX that can be bought with input Tokens.
     */
    function getTokenToTrxInputPrice(uint256 tokens_sold) external view returns (uint256);

    /**
     * @notice external price function for Token to TRX trades with an exact output.
     * @param trx_bought Amount of output TRX.
     * @return Amount of Tokens needed to buy output TRX.
     */
    function getTokenToTrxOutputPrice(uint256 trx_bought) external view returns (uint256);

    /**
     * @return Address of Token that is sold on this exchange.
     */
    function tokenAddress() external view returns (address);

    /**
     * @return Address of factory that created this exchange.
     */
    function factoryAddress() external view returns (address);


    /***********************************|
    |        Liquidity Functions        |
    |__________________________________*/

    /**
     * @notice Deposit TRX && Tokens (token) at current ratio to mint UNI tokens.
     * @dev min_liquidity does nothing when total UNI supply is 0.
     * @param min_liquidity Minimum number of UNI sender will mint if total UNI supply is greater than 0.
     * @param max_tokens Maximum number of tokens deposited. Deposits max amount if total UNI supply is 0.
     * @param deadline Time after which this transaction can no longer be executed.
     * @return The amount of UNI minted.
     */
    function addLiquidity(uint256 min_liquidity, uint256 max_tokens, uint256 deadline) external payable returns (uint256);

    /**
     * @dev Burn UNI tokens to withdraw TRX && Tokens at current ratio.
     * @param amount Amount of UNI burned.
     * @param min_trx Minimum TRX withdrawn.
     * @param min_tokens Minimum Tokens withdrawn.
     * @param deadline Time after which this transaction can no longer be executed.
     * @return The amount of TRX && Tokens withdrawn.
     */
    function removeLiquidity(uint256 amount, uint256 min_trx, uint256 min_tokens, uint256 deadline) external returns (uint256, uint256);
}




//SourceUnit: IPriceOracle.sol

pragma solidity ^0.5.16;

interface IPriceOracle {


    function getRate(address _oracleAddress) external returns (uint256[2] memory coin_info);

    function getCoinInfo(address tokenAddress) external view returns (
        uint256 price,
        uint256 update_time
    );





    /*
    Only set for the USDT price for the
    token address for 6 decimals
    */
    function updateUSDPrice(
        address token_address,
        uint256 pricecode
    ) external;
}



//SourceUnit: Ownable.sol

pragma solidity ^0.5.10;

import "./Context.sol";
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


//SourceUnit: PhiPhiIslands.sol

pragma solidity ^0.5.16;

import "./Roles.sol";
import "./Ownable.sol";
import "./SafeMathLib.sol";


contract PhiPhiIslands is Ownable {
    using Roles for Roles.Role;

    Roles.Role private _whitelistAdmins;
    Roles.Role private _locker;
    Roles.Role private _gov;

    constructor () internal {
        _whitelistAdmins.add(_msgSender());
    }

    modifier onlyWhitelistAdmin() {
        require(isWhitelistAdmin(_msgSender()) || isOwner(), "WhitelistAdminRole: caller does not have the WhitelistAdmin role");
        _;
    }

    function isWhitelistAdmin(address account) public view returns (bool) {
        return _whitelistAdmins.has(account) || isOwner();
    }

    function addWhitelistAdmin(address account) public onlyOwner {
        _whitelistAdmins.add(account);
    }

    function removeWhitelistAdmin(address account) public onlyOwner {
        _whitelistAdmins.remove(account);
    }

    modifier onlyGovernor(){
        require(isGov(_msgSender()) || isOwner(), "Governer: caller does not have the WhitelistAdmin role");
        _;
    }

    function isGov(address account) public view returns (bool) {
        return _gov.has(account) || isOwner();
    }

    function addGov(address account) public onlyOwner {
        _gov.add(account);
    }

    function removeGov(address account) public onlyOwner {
        _gov.remove(account);
    }


    modifier onlyLocker() {
        require(isLocker(_msgSender()) || isOwner(), "Locker only: caller does not have the WhitelistAdmin role");
        _;
    }

    function isLocker(address account) public view returns (bool) {
        return _locker.has(account) || isOwner();
    }

    function addLocker(address account) public onlyOwner {
        _locker.add(account);
    }

    function removeLocker(address account) public onlyOwner {
        _locker.remove(account);
    }


    uint8 internal locked = 0;

    event traillock(uint8 value);

    function isLocked() public view returns (bool){
        return locked == 1;
    }

    function aliveTest() internal {
        locked = 0;
        emit traillock(locked);
    }

    function endTest() internal {
        locked = 1;
        emit traillock(locked);
    }

    function lock() external onlyLocker {
        endTest();
    }

    function unlock() external onlyLocker {
        aliveTest();
    }

    modifier onlyUnlocked(){
        require(locked == 0, "contract is already finalized");
        _;
    }

}

//SourceUnit: Roles.sol

pragma solidity ^0.5.10;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}


//SourceUnit: SafeMathLib.sol

pragma solidity ^0.5.16;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMathLib {
    uint256 constant public MAX_UINT256 =
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    function trxcoin(uint256 a) internal pure returns (uint256) {
        assert(a > 0);
        uint256 c = a * 1000000;
        assert(a == 0 || c / a == 1000000);
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
        return ((a + m - 1) / m) * m;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "mod zero");
        return a % b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? b : a;
    }

    function sq(uint256 x) internal pure returns (uint256)
    {
        return (mul(x, x));
    }

    function sqrt(uint256 x) internal pure returns (uint256 y)
    {
        uint256 z = ((add(x, 1)) / 2);
        y = x;
        while (z < y)
        {
            y = z;
            z = ((add((x / z), z)) / 2);
        }
    }

    function pwr(uint256 x, uint256 y) internal pure returns (uint256)
    {
        if (x == 0) return (0);
        else if (y == 0) return (1);
        else {
            uint256 z = x;
            for (uint256 i = 1; i < y; i++) z = mul(z, x);
            return (z);
        }
    }

    function safeAdd(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assert(MAX_UINT256 - y > x);
        return x + y;
    }

    function safeSub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assert(y < x);
        return x - y;
    }

    function safeMul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        if (y == 0) return 0;
        assert(MAX_UINT256 / y > x);
        return x * y;
    }
}


//SourceUnit: SwPlans.sol

pragma solidity ^0.5.16;

import "./PhiPhiIslands.sol";

contract SwPlans is PhiPhiIslands {

    uint32 internal plan_id_sys = 10;
    mapping(address => uint32) check_plan_id;
    mapping(uint32 => address) check_plan_address;
    mapping(address => bool) tokens;


    event Err(uint errocode);
    constructor () public payable{
    }

    function definePlan(address token) public onlyWhitelistAdmin {
        if (!tokens[token]) {
            tokens[token] = true;
            check_plan_id[token] = plan_id_sys;
            check_plan_address[plan_id_sys] = token;
            plan_id_sys++;
        } else {
            emit Err(10001);
        }
    }

    function SearchPlanAddressById(uint32 k) public view returns (address){
        return check_plan_address[k];
    }

    function SearchPlanIdByAddress(address k) public view returns (uint32){
        return check_plan_id[k];
    }

    function totalPlans() public view returns (uint){
        return plan_id_sys - 10;
    }

}


//SourceUnit: TrxTool.sol

pragma solidity ^0.5.16;
import "./AddressPayable.sol";
import "./SafeMathLib.sol";

contract TrxTool {
    using SafeMathLib for *;
    using AddressPayable for address;
    uint256 constant trx_coin = 1000000; //1 trx

    function sendMoneyToUser(address receivable, uint money) internal {
        if (money > 0) {
            receivable.makePayable().transfer(money);
        }
    }

    function compareStr(string memory src, string memory src_compared) public pure returns (bool) {
        if (keccak256(abi.encodePacked(src)) == keccak256(abi.encodePacked(src_compared))) {
            return true;
        }
        return false;
    }

    function TrxHexToAddress(uint256 f) internal pure returns (address) {
        return address(uint256(f));
    }

    function validate_input_trx(uint trx_amount) internal pure returns (bool){
        return trx_amount >= trx_coin;
    }

    function validate_integer_trx(uint trx_amount) internal pure returns (bool){
        return trx_amount == trx_amount.div(trx_coin).mul(trx_coin);
    }


    function validate_invitation_code(string memory code) internal pure returns (bool){
        return !compareStr(code, "") && bytes(code).length == 5;
    }

    function _msgSenderReceivable() internal view returns (address) {
        return address(uint160(msg.sender));
    }

}