// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./Address.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Context.sol";

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

// standard interface of IERC20 token
// using this in this contract to receive Bino token by "transferFrom" method
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

/**
 * @dev Allowed this contract to call 'safeMint' & 'burn' methods from the "HousesNFT" contract
 */
interface IHousesNFT {

    function safeMint(address to, uint256 tokenId, uint256 level) external;

    function burn(uint256 tokenId) external;
}

/**
 * @dev Allowed this contract to call 'burn' and/or 'burnBatch' methods from the "Materials" contract
 */
interface IMaterials {

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);
    
    function materialName(uint256 id) external view returns (string memory);

    function totalSupply(uint256 id) external view returns (uint256);

    function exists(uint256 id) external view returns (bool);

    function mint(address account, uint256 id, uint256 amount, bytes memory data) external;

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external;

    function burn(address account, uint256 id, uint256 amount) external;

    function burnBatch(address account, uint256[] memory ids, uint256[] memory amounts) external;
}

contract HouseFactory is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    struct claimInfo {
        bool isClaimed;
        address owner;
        uint256 level;
        uint256 finishedTime;
    }

    IERC20 public binoAddress;
    IHousesNFT public housesAddress;
    IMaterials public materialsAddress;
    // House's token ids increase monotonically, with the first value being 1. An id of 0 is invalid.
    Counters.Counter private _currentTokenId;

    // house's level => Bino price (decimal: 1e18)
    mapping(uint256 => uint256) private _levelToPrice;
    // house's level => house's building period
    mapping(uint256 => uint256) private _levelToPeriod;
    // house's level => material's ids array
    mapping(uint256 => uint256[]) private _levelToIds;
    // house's level => material's amounts array
    mapping(uint256 => uint256[]) private _levelToAmounts;
    // house's tokenId => claimInfo
    mapping(uint256 => claimInfo) private _tokenIdToClaimInfo;

    event BuildHouse(address indexed account, uint256 indexed tokenId, uint256 indexed expectedTime, uint256 level);
    event ClaimHouse(address indexed account, uint256 indexed tokenId, uint256 indexed level);

    constructor () public {
        // fill in those deployed contract addresses
        setBinoAddress(0xf8Ca318db090124E1468CC6c77f69Fd7eb78685a);
        setHousesAddress(0x1b6A7F0f7cEd432603E38f359b94156657daC5C4);
        setMaterialsAddress(0x04898c211e112e558def9f28B22640Ef814f56e6);
        // set house's price in Bino token for each level
        _setHousePrice(1, 160);
        _setHousePrice(2, 640);
        _setHousePrice(3, 3200);
        _setHousePrice(4, 9600);
        _setHousePrice(5, 76800);
        _setHousePrice(6, 768000);
        // set building period for each level's house
        _setHouseBuildingPeriod();
        // set house's Ids array for each level
        _setLevelIds();
        // set house's Amounts array for each level
        _setLevelAmounts();
    }

    function setBinoAddress(address newAddress) public onlyOwner {
        binoAddress = IERC20(newAddress);
    }

    function setHousesAddress(address newAddress) public onlyOwner {
        housesAddress = IHousesNFT(newAddress);
    }

    function setMaterialsAddress(address newAddress) public onlyOwner {
        materialsAddress = IMaterials(newAddress);
    }

    function checkHousePrice(uint256 level) public view returns (uint256) {
        require(level > 0 && level <=6, "level is out of range of [1, 6]");
        return _levelToPrice[level];
    }

    function checkHouseBuildingPeriod(uint256 level) public view returns (uint256) {
        require(level > 0 && level <=6, "level is out of range of [1, 6]");
        return _levelToPeriod[level];
    }

    function checkLevelToIds(uint256 level) public view returns (uint256[] memory) {
        require(level > 0 && level <=6, "level is out of range of [1, 6]");
        return _levelToIds[level];
    }

    function checkLevelToAmounts(uint256 level) public view returns (uint256[] memory) {
        require(level > 0 && level <=6, "level is out of range of [1, 6]");
        return _levelToAmounts[level];
    }

    function checkHouseClaimInfo(uint256 tokenId) public view returns (claimInfo memory) {
        require(tokenId <= _currentTokenId.current(), "this house id has not started to build yet");
        return _tokenIdToClaimInfo[tokenId];
    }

    function isReadyToClaim(uint256 tokenId) public view returns (bool) {
        require(tokenId <= _currentTokenId.current(), "this house id has not started to build yet");
        claimInfo storage thisClaim = _tokenIdToClaimInfo[tokenId];
        require(!thisClaim.isClaimed, "this hous Id has been claimed");
        if (block.timestamp >= thisClaim.finishedTime) {
            return true;
        } else {
            return false;
        }
    }

    function checkMaterialName(uint256 Id) public view returns (string memory) {
        return materialsAddress.materialName(Id);
    }

    function checkLatestMintedHouseId() public view returns (uint256) {
        return _currentTokenId.current();
    }

    // notice: Approve bino contract's 'transferFrom' method, 
    // and Approve material contract's 'burnBatch' method BEFORE calling this method.
    function buildHouse (uint256 level) public returns (uint256) {
        require(level > 0 && level <=6, "level is out of range of [1, 6]");

        // 1. check user's bino balance is enough or not
        uint256 housePrice = checkHousePrice(level);
        require(binoAddress.balanceOf(_msgSender()) >= housePrice, "builder's Bino balance is less than house price");
        // 2. check user's material balance is enough or not
        uint256[] memory materialIds = checkLevelToIds(level);
        uint256[] memory materialAmounts = checkLevelToAmounts(level);
        for (uint256 i = 0; i < materialIds.length; ++i) {
            uint256 id = materialIds[i];
            uint256 amount = materialAmounts[i];
            require(materialsAddress.balanceOf(_msgSender(), id) >= amount, "materials are not enough");
        }
        // 3. if both are enough, burn material tokens and transfer Bino, then you can mint HousesNFT
        materialsAddress.burnBatch(_msgSender(), materialIds, materialAmounts);
        binoAddress.safeTransferFrom(_msgSender(), address(this), housePrice);
        // 4. record the owner, level, tokenId, and finish time
        _currentTokenId.increment();
        uint256 currentId = _currentTokenId.current();
        uint256 expectedTime = block.timestamp.add(_levelToPeriod[level]);
        _tokenIdToClaimInfo[currentId] = claimInfo({
                                                    isClaimed: false,
                                                    owner: _msgSender(),
                                                    level: level,
                                                    finishedTime: expectedTime
                                                });

        emit BuildHouse(_msgSender(), currentId, expectedTime, level);

        return currentId;
    }

    // This contract MUST be set as a MinterRole of the HousesNFT contract.
    function claimHouse(uint256 tokenId) public {
        require(tokenId <= _currentTokenId.current(), "this house id has not started to build yet");
        claimInfo storage thisClaim = _tokenIdToClaimInfo[tokenId];
        require(!thisClaim.isClaimed, "this hous Id has been claimed");
        address owner = thisClaim.owner;
        uint256 level = thisClaim.level;
        uint256 finishedTime = thisClaim.finishedTime;
        require(owner == _msgSender(), "only house owner can claim it");
        require(block.timestamp >= finishedTime, "house is building now, not ready to be claimed yet");

        housesAddress.safeMint(owner, tokenId, level);
        thisClaim.isClaimed = true;

        emit ClaimHouse(owner, tokenId, level);
    }

    function _setHousePrice(uint256 level, uint256 price) private {
        _levelToPrice[level] = price.mul(1e18);
    }

    function _setHouseBuildingPeriod() private {
        _levelToPeriod[1] = 30 minutes;
        _levelToPeriod[2] = 1 hours;
        _levelToPeriod[3] = 2 hours;
        _levelToPeriod[4] = 5 hours;
        _levelToPeriod[5] = 24 hours;
        _levelToPeriod[6] = 720 hours;
    }

    function _setLevelIds() private {
        _levelToIds[1] = [0, 1, 2, 11];
        _levelToIds[2] = [0, 1, 7, 3, 12];
        _levelToIds[3] = [0, 6, 7, 8, 9, 13];
        _levelToIds[4] = [0, 6, 7, 8, 9, 10, 14, 17];
        _levelToIds[5] = [0, 6, 7, 8, 9, 10, 15, 18];
        _levelToIds[6] = [0, 6, 7, 8, 9, 10, 16, 19];
    }

    function _setLevelAmounts() private {
        _levelToAmounts[1] = [1, 48, 48, 1];
        _levelToAmounts[2] = [1, 81, 45, 20, 1];
        _levelToAmounts[3] = [2, 50, 40, 70, 15, 1];
        _levelToAmounts[4] = [4, 235, 70, 40, 60, 40, 1, 1];
        _levelToAmounts[5] = [16, 1440, 1350, 950, 200, 240, 1, 1];
        _levelToAmounts[6] = [200, 8000, 4900, 6500, 3200, 3500, 1, 1];
    }

}