// SPDX-License-Identifier: MIT
// import "hardhat/console.sol";



pragma solidity ^0.8.0;

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


pragma solidity ^0.8.0;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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


pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
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

    constructor() {
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

pragma solidity ^0.8.5;
pragma abicoder v2;

//interface for CrashGame
interface ICrashGame {
    //
}


interface IrETH {
    function deductLoss(address player, uint256 rawAmount) external returns (bool);
    function addProfit(address player, uint256 rawAmount) external returns (bool);
    function mint(address dst, uint256 rawAmount) external;
    function burn(address src, uint256 rawAmount) external;
}


interface IhETH {
    function mint(address dst, uint256 rawAmount) external;
    function burn(address src, uint256 rawAmount) external;
    function totalSupply() external view returns (uint256);
}

contract CrashBank is ReentrancyGuard, Ownable {
    /* ========== STATE VARIABLES ========== */
    address public crashGameAddress;
    address public rETHAddress;
    address public hETHAddress;

    //percentage of house profits that go to protocol
    uint256 public protocolFee; //in % eg. 10, 25, 30

    ICrashGame private crashGame;
    IrETH private rETH;
    IhETH private hETH;

    //mapping(address => uint256) public userBalances;
    uint256 public houseBalance;

    uint32 public lastGameNumber;

    event GameResolved(uint32 gameNumber, string gameHash);

    constructor(address _crashGameAddress, address _rETHAddress, address _hETHAddress, uint256 _protocolFee, uint32 _lastGameNumber) {
        crashGameAddress = _crashGameAddress;
        rETHAddress = _rETHAddress;
        hETHAddress = _hETHAddress;
        protocolFee = _protocolFee;

        crashGame = ICrashGame(crashGameAddress);
        rETH = IrETH(rETHAddress);
        hETH = IhETH(hETHAddress);

        lastGameNumber = _lastGameNumber; //start at 0 by default
        houseBalance = 0;
    }

    /* ========== USER INTERACTIONS ========== */

    //flows: 
    // player - deposit/withdraw
    // house - deposit/withdraw 
    // admin - resolve game, update params, pause

    function depositrETH() external payable nonReentrant {
        uint256 amount = msg.value;
        rETH.mint(msg.sender, amount);
    }

    function redeemrETH(uint256 amount) external nonReentrant {
        rETH.burn(msg.sender, amount);
        address payable sender = payable(address(msg.sender));
        Address.sendValue(sender, amount);
    }

    // IMPORTANT: accrued profits need to be tracked in order to make sure that
    // fees don't get eaten 
    function deposithETH() external payable nonReentrant {
        //mint hETH based on pricePerShare = ICrashBank(minter).houseBalance / self.totalSupply;
        uint256 pricePerShare;
        if (hETH.totalSupply() == 0) {
            pricePerShare = 1e18;
        }
        else {
            pricePerShare = (houseBalance*1e18) / hETH.totalSupply();
        }
        //eg if houseBalance is 1500 wei and total supply is 1000
        // pricePerShare is 1.5e18 
        uint256 sharesToMint = 1e18*msg.value / pricePerShare;
        //1 eth would yield 1e18/1.5e1=0.66666 hETH
        houseBalance += msg.value;
        // console.log('CrashBank::depositehETH:msg.value:', msg.value);
        // console.log('CrashBank::depositehETH:housebalance:', houseBalance);
        // console.log('CrashBank::depositehETH:pricePerShare:', pricePerShare);
        // console.log('CrashBank::depositehETH:sharesToMint:', sharesToMint);
        hETH.mint(msg.sender, sharesToMint);
    }

    function redeemhETH(uint256 amount) external nonReentrant {
        //TOOD: add admin fee withdrawal
        uint256 pricePerShare = (houseBalance*1e18) / hETH.totalSupply();
        uint256 ethToReturn = (amount * pricePerShare) / 1e18;
        address payable sender = payable(address(msg.sender));
        hETH.burn(msg.sender, amount);

        //deducting protocol fees before returning amount to player
        uint256 amountToReturn = amount * (100 - protocolFee) /100; //if pF is 25%, amountToReturn will be 75% of total amount.
        houseBalance -= amountToReturn;
        
        // ethToReturn adjusted for protcol fees
        ethToReturn = (100-protocolFee) * ethToReturn /100;

        // console.log('CrashBank::redeemhETH:housebalance:', houseBalance/1e18);
        // console.log('CrashBank::redeemhETH:pricePerShare:', pricePerShare/1e18);
        // console.log('CrashBank::redeemhETH:ethToReturn:', ethToReturn);
        
        Address.sendValue(sender, ethToReturn);
    }

    /* ========== ADMIN FUNCTIONS ========== */

    function withdrawProtocolFee() external nonReentrant onlyOwner {
        protocolFee = 0;

    }

    function setProtocolFee(uint256 _fee) external nonReentrant onlyOwner {
        require(protocolFee >= 0 && protocolFee <= 100, "Valid value for Protocol fees is from 0 to 100");
        protocolFee = _fee;
    }

    function sign(int256 x) internal pure returns (int8) {
        // unchecked {
        //     return int8(((0 < x) ? 1 : 0) - ((x < 0) ? 1 : 0 ));
        // }  
        if( x < 0) return 0;
        else return 1; 
    }

    /** @notice Update players' and house balances after a game 
     */
    function resolveGame(uint32 gameNumber, string memory gameHash, 
        address[] memory players, int256[] memory deltas) external nonReentrant {
        require(msg.sender == crashGameAddress, "Only CrashGame can resolve a game");
        require(gameNumber == lastGameNumber + 1, "Game number out of sequence");
        // require(deltas[0] < 0, "Only +ive values required");
        // console.log('===> ResolvingGame: number:', gameNumber);
        // iterate through the arrays of players and deltas
        for (uint i = 0; i < players.length; i++ ) {
            int256 delta = deltas[i];
            uint256 abs_delta;
            // console.log('=> delta:');
            // console.logInt(int256(delta/1e18));
            int mask = delta >> 256 * 8 - 1;
            // console.log('=> mask:', uint256(mask));
            abs_delta = uint256(delta + mask) ^ uint256(mask);
            
            if (sign(delta) == 1) {
                abs_delta = abs_delta * (100 - protocolFee) /100;
                // console.log('=> abs_delta:',abs_delta/1e18);
                require(abs_delta <= houseBalance/10, "CrashBank:resolveGame:houseBalance is low, can't resolve game");
                //increase player's rETH balance
                // console.log("=> Adding profit +++++++");
                rETH.addProfit(players[i], abs_delta);
                houseBalance -= abs_delta;
                //decrease house balance by same amount
            }
            else { 
                // console.log('=> abs_delta:',abs_delta/1e18);
                // console.log("=> Deducting Losss -------");
                //decrease player's rETH balance
                rETH.deductLoss(players[i], abs_delta);
                houseBalance += abs_delta;
                //increase house balance
            }
            

        }

        lastGameNumber = lastGameNumber + 1;
        emit GameResolved(gameNumber, gameHash);
    }
}

