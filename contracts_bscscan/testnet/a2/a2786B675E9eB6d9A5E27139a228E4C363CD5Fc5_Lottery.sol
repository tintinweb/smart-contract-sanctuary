// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import './Random.sol';

// interface IBNBPrice {
//     function GetBNBPrice() external view returns(uint);
//     function GetBNBAmountFromUSDTAmount(uint USDTAmount) external view returns(uint);
//     function GetUSDTAmountFromBNBAmount(uint BNBAmount) external view returns(uint);
// }

interface ISkill{
    struct SkillInfo{
        uint8 x1;
        uint8 x2;
        uint8 x3;
        uint8 y1;
        uint8 y2;
        uint8 y3;
    }
    function mint(address recipient, uint skillIndex, uint8 skillQuality,
        SkillInfo memory skillInfo) external;
    
    function safeTransferFrom(
         address from, address to, uint256 tokenId
     ) external;
}

interface IHero{
    struct HeroInfo{
        uint8 HPbase;
        uint8 ATKbase;
        uint8 DEFbase;
        uint8 LUKbase;
    }

    function mint(
        address recipient, uint heroIndex, HeroInfo memory heroInfo
    ) external;

     function safeTransferFrom(
         address from, address to, uint256 tokenId
     ) external;
}

interface IChest{
    function mint(address recipient, uint chestIndex, uint amount) external;
}

contract SellTime is Ownable, Random{

    using SafeERC20 for IERC20;
    using SafeMath for uint;

    address public wallet = 0xEC4dDD0C76AAf2278387726482127F87781473A0;
    uint public lotterySellStartTime = 1641484800;//1643990400
    uint public lotterySellEndTime = 1644163200; //1644163200
  
    function setLotterySellTime(
        uint _lotterySellStartTime,
        uint _lotterySellEndTime
    ) external onlyOwner{
        require(_lotterySellEndTime > _lotterySellStartTime,
            "EndTime should be greater than StartTime"
        );
        lotterySellStartTime = _lotterySellStartTime;
        lotterySellEndTime = _lotterySellEndTime;
    }

    modifier lotterySellTime(){
        require(now > lotterySellStartTime && lotterySellEndTime > now,
            "SellTime: Not in sale time"
        );
        _;
    }
}

interface ILottery2 {
    //change to Lottery
    event GetHero(address buyer, uint time, uint heroIndex);
    event GetChest(address buyer, uint time, uint chestIndex);
    event GetSkill(address buyer, uint time, uint skillIndex);
    event GetBNB(address buyer, uint time, uint amount);
    event Lottery(address buyer, uint time);
}

contract Lottery is Pausable, SellTime, ILottery2{

    using Counters for Counters.Counter;

    mapping(address => bool) _buyer;

    mapping (uint => Counters.Counter) sellAmount;
    mapping (uint => uint) tokenId;

    //Contracts
    IHero public heroContract;
    IChest public chestContract;
    ISkill public skillContract;
    IERC20 public usdtContract = IERC20(0x55d398326f99059fF775485246999027B3197955);
    // IBNBPrice public bnbPriceContract = IBNBPrice(0x52D3Ec80C702530D6f862Ce4bA1d20D9A7620315);
    
    uint private _lotteryPriceForUSDT = 1e18; //decimal = 18

    receive () payable external{

    }

    function getLotteryPriceForUSDT() public view returns(uint){
        return _lotteryPriceForUSDT;
    }

    function setLotteryPriceForUSDT(uint amount) external onlyOwner {
         _lotteryPriceForUSDT = amount * 1e18;
    }

    function isBuyer(address user) external view returns(bool){
        return _buyer[user];
    }

    function totalSellAmount() external view returns(uint){
        return sellAmount[0].current();
    }

    function setTokenId(uint index, uint _tokenId) external onlyOwner{
        tokenId[index] = _tokenId;
    }

    function lotteryByUsdt() external whenNotPaused lotterySellTime{
        // usdtContract.safeTransferFrom(
        //     msg.sender,
        //     wallet, 
        //     getLotteryPriceForUSDT()
        // );
        _lottery();
        emit Lottery(msg.sender, now);
    }

//_lottery
    function _lottery()  private{
        _buyer[msg.sender] = true;

        // check probability
        sellAmount[0].increment();
        uint randomNumber = _getRandomNumber() % 1000;
        if(randomNumber <= 902){
            if(sellAmount[2].current() < 50){
                sellAmount[2].increment();
                _mintChest(msg.sender,7);
            }else{_mintSkill(msg.sender);}
}
        // }else if(randomNumber > 902 && randomNumber <= 912){
        //     if(sellAmount[1].current() < 10){
        //         sellAmount[1].increment();
        //         (msg.sender).transfer(0.02 ether);
        //         emit GetBNB(msg.sender, now, 0.02 ether);
        //     }else{_mintSkill(msg.sender);}
        // }else if(randomNumber > 912 && randomNumber <= 937){
        //     if(sellAmount[2].current() < 50){
        //         sellAmount[2].increment();
        //         _mintChest(msg.sender,7);
        //     }else{_mintSkill(msg.sender);}
        // }else if(randomNumber > 937 && randomNumber <= 962){
        //     if(sellAmount[3].current() < 50){
        //         sellAmount[3].increment();
        //         _mintChest(msg.sender,2);
        //     }else{_mintSkill(msg.sender);}
        // }else if(randomNumber > 962 && randomNumber <= 965){
        //     if(sellAmount[4].current() < 10){
        //         sellAmount[4].increment();
        //         _mintChest(msg.sender,11);
        //     }else{_mintSkill(msg.sender);}
        // }else if(randomNumber > 965 && randomNumber <= 970){
        //     if(sellAmount[5].current() < 10){
        //         sellAmount[5].increment();
        //         _mintChest(msg.sender,1);
        //     }else{_mintSkill(msg.sender);}
        // }else if(randomNumber > 970 && randomNumber <= 995){
        //     if(sellAmount[6].current() < 50){
        //         sellAmount[6].increment();
        //         _mintHero(msg.sender,903); 
        //         emit GetHero(msg.sender, now, 1);
        //     }else{_mintSkill(msg.sender);}
        // }else if(randomNumber > 995 && randomNumber <= 996){
        //     if(sellAmount[7].current() < 1){
        //         sellAmount[7].increment();
        //         heroContract.safeTransferFrom(
        //             address(this),
        //             msg.sender,
        //             tokenId[0]   
        //         );
        //         emit GetHero(msg.sender, now, 200);
        //     }else{_mintSkill(msg.sender);}
        // }else if(randomNumber > 996 && randomNumber <= 997){
        //     if(sellAmount[8].current() < 1){
        //         sellAmount[8].increment();
        //         heroContract.safeTransferFrom(
        //             address(this),
        //             msg.sender,
        //             tokenId[1]   
        //         );
        //         emit GetHero(msg.sender, now, 200);
        //     }else{_mintSkill(msg.sender);}
        // }else if(randomNumber > 997 && randomNumber <= 998){
        //     if(sellAmount[9].current() < 1){
        //         sellAmount[9].increment();
        //         heroContract.safeTransferFrom(
        //             address(this),
        //             msg.sender,
        //             tokenId[2]   
        //         );
        //         emit GetHero(msg.sender, now, 300);
        //     }else{_mintSkill(msg.sender);}
        // }else if(randomNumber > 998 && randomNumber <= 999){
        //     if(sellAmount[10].current() < 1){
        //         sellAmount[10].increment();
        //         skillContract.safeTransferFrom(
        //             address(this),
        //             msg.sender,
        //             tokenId[3]   
        //         );
        //         emit GetSkill(msg.sender, now, 500);
        //     }else{_mintSkill(msg.sender);}
        // }
    }

//_mint

    function _mintHero(address to, uint heroIndex) private{
        
        bytes32 seed = keccak256(abi.encodePacked("NFTs Battle", now, msg.sender));
        
        uint hpInit = (uint8(seed[0]) * 16 + uint8(seed[1]));
        uint atkInit = (uint8(seed[2]) * 16 + uint8(seed[3]));
        uint defInit = (uint8(seed[4]) * 16 + uint8(seed[5]));
        uint lukInit = (uint8(seed[6]) * 16 + uint8(seed[7]));

        uint normalization = hpInit.add(atkInit).add(defInit).add(lukInit);
        
        IHero.HeroInfo memory heroInfo = IHero.HeroInfo({
            HPbase: uint8(hpInit.mul(100).div(normalization)),
            ATKbase: uint8(atkInit.mul(100).div(normalization)),
            DEFbase: uint8(defInit.mul(100).div(normalization)),
            LUKbase: uint8(lukInit.mul(100).div(normalization))
        });

        heroContract.mint(to, heroIndex, heroInfo);
    }

    function _mintSkill(address to) private{
        
        bytes32 seed = keccak256(abi.encodePacked("NFTs Battle", now, msg.sender));
        uint16[10] memory skills = [2, 3, 4, 101, 104, 201, 204, 301, 304, 401];
        uint skillIdex = skills[_getRandomNumber() % 10];
        ISkill.SkillInfo memory skillInfo = ISkill.SkillInfo({
            x1: uint8(seed[0]) * 16 + uint8(seed[1]),
            x2: uint8(seed[2]) * 16 + uint8(seed[3]),
            x3: uint8(seed[4]) * 16 + uint8(seed[5]),
            y1: uint8(seed[6]) * 16 + uint8(seed[7]),
            y2: uint8(seed[8]) * 16 + uint8(seed[9]),
            y3: uint8(seed[10]) * 16 + uint8(seed[11])
        });

        skillContract.mint(to, skillIdex, 1, skillInfo);
        emit GetSkill(msg.sender, now, skillIdex);
    }

    function _mintChest(address to, uint chestIndex) private{
        chestContract.mint(to, chestIndex, 1);
        emit GetChest(msg.sender, now, chestIndex);
    }

//onlyOwner
    function setPuase() external onlyOwner{
        _pause();
    }

    function setUnpuase() external onlyOwner{
        _unpause();
    }

    function setUsdtContract(IERC20 _usdtContract) external onlyOwner{
        usdtContract = _usdtContract;
    }

    function setHeroContract(IHero _heroContract) external onlyOwner{
        heroContract = _heroContract;
    }

    function setChestContract(IChest _chestContract) external onlyOwner{
        chestContract = _chestContract;
    }

    function setSkillContract(ISkill _skillContract) external onlyOwner{
        skillContract = _skillContract;
    }

    function setWallet(address _wallet) external onlyOwner{
        wallet = _wallet;
    }

    function withdraw() external onlyOwner{
        payable(wallet).transfer(address(this).balance);
        usdtContract.transfer(wallet, usdtContract.balanceOf(address(this)));
    }

    function withdrawBNB(uint amount) external onlyOwner{
        payable(wallet).transfer(address(this).balance);
        (msg.sender).transfer(amount *  0.001 ether);
    }

    function withdrawSkill() external onlyOwner{
        skillContract.safeTransferFrom(
            address(this),
            msg.sender,
            tokenId[3]   
        );
    }

    function withdrawHero(uint index) external onlyOwner{
        heroContract.safeTransferFrom(
            address(this),
            msg.sender,
            tokenId[index]   
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract Random {
 
    uint256 internal randomSeed;
    
    function _getRandomNumber() internal returns (uint){
        _updateRamdomSeed();
        return uint(keccak256(abi.encodePacked(
            randomSeed, now, msg.sender
        )));
    }

    function _updateRamdomSeed() private {
        randomSeed++;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../math/SafeMath.sol";

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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