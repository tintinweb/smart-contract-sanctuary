/**
 *Submitted for verification at BscScan.com on 2021-09-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        
        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;

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

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract Whitelisted is Ownable {
    mapping(address => bool) public whitelist;
    mapping(address => bool) public provider;
  

    // Only whitelisted
    modifier onlyWhitelisted {
        require(isWhitelisted(msg.sender));
        _;
    }
  
    function whitelistAddresses (address[] memory _purchaser) public onlyOwner {
        for (uint i = 0; i < _purchaser.length; i++) {
            whitelist[_purchaser[i]] = true;
        }
    }
    
    // Delete purchaser from whitelist
    function deleteFromWhitelist(address _purchaser) public onlyOwner {
        whitelist[_purchaser] = false;
    }
   
    // Check if purchaser is whitelisted : return true or false
    function isWhitelisted(address _purchaser) public view returns (bool){
        return whitelist[_purchaser] == true ? true : false;
    }
}

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor ()  {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }
    
    // sends ETH or an erc20 token
    function safeTransferBaseToken(address token, address payable to, uint value, bool isERC20) internal {
        if (!isERC20) {
            to.transfer(value);
        } else {
            (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
            require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
        }
    }
}

interface Router {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

// Presale contract is setup by the ShibaNova team, thereby being the 'owner' of the contract. ShibaNova collects 1% of the BNB raised and project tokens deposited as a fee.
// The 'payee' is the wallet belonging to the project owner requesting the presale. They are responsible for depositing the project token.
// The presale is setup with a start block and end block to determine the duration of the presale.
// The first stage of the presale is for whitelisted Nova/sNova holders to be able to buy first, usually 30 minutes. 
// Once the presale has finished (either through selling out or time ending), ShibaNova will send the 'addLiquidity' function,
// which creates and locks the LP, sends the fee to ShibaNova, allows purchasers to claim their tokens and allows project wallet to collect bnb.


// review start and end time change functions for needed restrictions. change startblock to 'starttime' to avoid confusion

contract Presale is Ownable, Whitelisted, ReentrancyGuard {
    using Address for address payable;
    
    event Swap(address indexed user, uint256 inAmount, uint256 owedAmount);
    event Claim(address indexed user, uint256 amount);
    event PayeeTransferred(address indexed previousPayee, address indexed newPayee);
    event NewSwapRate (uint256 indexed previousRate, uint256 newSwapRate);
    event NewMaxBuy (uint256 indexed previousMaxBuy, uint256 newMaxBuy);
    event EmergencyWithdrawn(address indexed user, uint256 amount);

    IERC20 public token;
    address public Payee; // wallet that recieves the bnb and liquidity
    address public WBNB = 0x098EB370050069D026aa77ed6bDB034F29c6Dbd0; // 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd; // 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c, 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd
    address public sNova = 0x2F5032c21fd4B21b96b7866eAeEBc4d056b10F8a; // 0xb79927bA8D1dF7B9c2199f3307Ddf6B263eBa6A3; // 0x0c0bf2bD544566A11f59dC70a8F43659ac2FE7c2, 0xb79927bA8D1dF7B9c2199f3307Ddf6B263eBa6A3
    address public nova = 0x2F53766D16f4f3234410a973A595cB2977fCc712; // 0x7cc3F3945351F1Bc3b57836d90af3D7dCD0bEF9c; // 0x56E344bE9A7a7A1d27C854628483Efd67c11214F, 0x7cc3F3945351F1Bc3b57836d90af3D7dCD0bEF9c
    address public novaFactory = 0x90e215970A5BE07F94e6F9DeDB562a56c6DE4F84; // 0x1723f701B8940Fa18Af0D5BB963b45EE57C499e6; // 0x251912dE998ec91DFDf67EfBe032d6f4aB5EC485, 0x1723f701B8940Fa18Af0D5BB963b45EE57C499e6
    address public novaRouter = 0x8c39C0F54A099A95e103af139b97a75f5B4f2981; // 0xA58ebc8d0D2f1d7F07656A3FbE6e2E51ae767ae9; // 0xeb17Dd35e47B1a41ba4D86B3506ec1f9b680b56a, 0xA58ebc8d0D2f1d7F07656A3FbE6e2E51ae767ae9
    address public feeManager = 0x04446B9a346A8b699F5719Bb336a9C57de9dD95e; // 0x641bE13ce540384E14586906900518204090D0da; // address for NovaPad fee
    
    bool public canClaim = false;
    bool public presaleFailed = false;

    uint256 public swapRate; // tokens per bnb
    uint256 public totalSold;
    uint256 public startBlock; //set as a block timestamp   
    uint256 public endBlock; // set as a block timestamp
    uint256 public novaStage = 1800; //1800 = 30 minutes for nova/snova holders to buy first
    uint256 public lockPeriod = 2592000; //time to lock liquidity 2592000 = 30 days
    uint256 public unlockTime; //time liquidity can be withdrawn
    uint256 public liqPercent; //amount of tokens used for liquidity div 100
    uint256 public fee = 1; // launchpad fee div 100
    
    uint256 public maxBuy; // 2000000000000000000 = 2 bnb
    uint256 public minBuy = 100000000000000000; // .1 bnb 100000000000000000
    uint256 public minSNova = 100000000000000000000; // 100 sNova 100000000000000000000
    uint256 public minNova = 500000000000000000000; // 500 Nova 500000000000000000000
   
    constructor (
    address _paymentWallet, 
    IERC20 _token, 
    uint256 _swapRate, 
    uint256 _maxBuy,  
    uint256 _starttime,
    uint256 _endtime,
    uint256 _liqPercent) {
        token = _token; 
        Payee = _paymentWallet;
        swapRate = _swapRate;
        maxBuy = _maxBuy;
        startBlock = _starttime;
        endBlock = _endtime;
        liqPercent = _liqPercent;
    }
    
    mapping (address => uint256) public spent;
    mapping (address => uint256) public owed;

    function swap() public payable onlyWhitelisted nonReentrant{
        uint256 quota = token.balanceOf(address(this)) - (fee/100) * (100 - liqPercent) / 100; // tokens available for purchase = total deposited mins 1% usage fee and liquidityPercent
        uint256 outAmount = msg.value * swapRate;
    
        require(block.timestamp >= startBlock && 
                block.timestamp < endBlock, 'Presale not Active');

        if (block.timestamp < startBlock + novaStage ) {
            require(IERC20(sNova).balanceOf(msg.sender) >= minSNova ||
            IERC20(nova).balanceOf(msg.sender) >= minNova, 'Must have sufficient Nova/sNova during Nova stage');
        }

        require(msg.value >= minBuy, 'Must meet minimum purchase amount');
        require(totalSold + outAmount <= quota, 'Hard Cap Reached');
        require(spent[msg.sender] + msg.value <= maxBuy, 'Reached Max Buy');

        totalSold += outAmount;
        
        
        spent[msg.sender] = spent[msg.sender] + msg.value;
        
        owed[msg.sender] = owed[msg.sender] + outAmount;

        emit Swap(msg.sender, msg.value, outAmount);
    }

    function claim() external onlyWhitelisted nonReentrant {
        uint256 quota = token.balanceOf(address(this));

        require(canClaim == true, 'Claim not started');
        require(owed[msg.sender] <= quota, 'Insufficient Tokens');

        uint256 amount = owed[msg.sender];
        owed[msg.sender] = 0;
        IERC20(token).transfer (msg.sender, amount);

        emit Claim(msg.sender, amount);
    }
    //still need to work on this
    function addLiquidity (uint256 num) external onlyOwner nonReentrant {
        
        uint256 feeBNB;
        uint256 tokenLiquidity;
        uint256 bnbLiquidity;
        uint256 deadline;
        uint256 feeToken;
        
        if(num == 1){
        require(block.timestamp > endBlock, 'Presale has not ended');
        require(canClaim != true, 'Liquidity already added');
        require(presaleFailed != true, 'Presale has been Failed');
        }
        
        if(num == 2){
        // fees for usage that go to feeManager
         feeBNB = totalSold / swapRate * fee / 100;
         feeToken = token.balanceOf(address(this)) * fee / 100;
        }
        
        if(num == 3){
         bnbLiquidity = ((totalSold / swapRate) - feeBNB) * liqPercent / 100;
         tokenLiquidity = totalSold * liqPercent / 100;
        }
        
        if(num == 4){
        TransferHelper.safeApprove(address(token), address(novaRouter), tokenLiquidity);
        }
        
        if(num == 5){
         deadline = block.timestamp + 300;
        }
        
        if(num == 6){
        Router(novaRouter).addLiquidityETH{value: bnbLiquidity};
        }
        
        if(num == 7){
        (address(token), tokenLiquidity, 0, 0, address(this), deadline);
        }
        
        if(num == 8){
        unlockTime = block.timestamp + lockPeriod;
        }
        
        if(num == 9){
        TransferHelper.safeTransfer(address(token), address(feeManager), feeToken);
        }
        
        if(num == 10){
        payable(feeManager).sendValue(feeBNB);
        }
        
        if(num == 11){
        setClaim(true);
        }
    }

    // generally unlock time will be 1 month
    function widthdrawLiquidity () external nonReentrant {
        require (msg.sender == address(Payee), 'You do not own the liquidity');
        require (block.timestamp > unlockTime, 'Liquidity is still locked');
        address liqPair = Factory(novaFactory).getPair(address(WBNB), address(token));
        uint256 liqAmount = IERC20(liqPair).balanceOf(address(this));
        TransferHelper.safeTransfer(address(liqPair), address(Payee), liqAmount);

    }

    // can only end presale early, not extend.
    function updateEnd(uint256 newEnd) public onlyOwner { 
        require(newEnd < endBlock, 'Cannot extend presale after it has ended');
        endBlock = newEnd;
    }

    function setClaim (bool _canClaim) internal returns (bool) {
        canClaim = _canClaim;
        return true;
    }

    function setSwapRate(uint256 newRate) public onlyOwner {
        require(block.timestamp < startBlock); //cannot modify after presale starts
        emit NewSwapRate(swapRate, newRate);
        swapRate = newRate;       
    }
    
    function setMaxBuy(uint256 newMax) public onlyOwner {
        emit NewMaxBuy(maxBuy, newMax);
        maxBuy = newMax;
    }
    
    function transferPayee(address newPayee) public onlyOwner {
        require(newPayee != address(0));
        emit PayeeTransferred(Payee, newPayee);
        Payee = newPayee;
    }

   function withdrawBNB() external nonReentrant{
       require(canClaim == true, 'Liquidity not added');
       require(msg.sender == address(Payee), 'You cannot withdraw BNB');
        payable(msg.sender).sendValue(address(this).balance);
    }
    
    // failsafe for everyone to withdraw their BNB if an issue arrises, project tokens cannot be withdrawn
    function failPresale() public onlyOwner {
        require(canClaim != true, 'Cannot fail presale once liquidity is created');
        presaleFailed = true;
    }
    
    function emergencyWithdraw () external nonReentrant {
        require(presaleFailed == true, 'Presale not failed');
        uint256 amount = spent[msg.sender];
        spent[msg.sender] = 0;
        payable(msg.sender).sendValue(amount);
        emit EmergencyWithdrawn (msg.sender, amount);
    }

}