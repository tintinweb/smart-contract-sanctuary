// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "../interfaces/IChest.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import {IMetaxyNFT} from '../interfaces/IMetaxyNFT.sol';

contract MetaxyNFTSale is IChest, Ownable, VRFConsumerBase {
    bytes32 private s_keyHash;
    uint256 private s_fee;
    mapping(bytes32 => address) private s_rollers;
    mapping(address => uint256) private s_results;

    event DiceRolled(bytes32 indexed requestId, address indexed roller);
    event DiceLanded(bytes32 indexed requestId, uint256 indexed result);

    event BuyAChest(address buyer, string chestName, uint256 price);

    address public mxy721;

    using SafeERC20 for IERC20;
    // Token BUSD
    IERC20 private constant BUSD =
        IERC20(0x8301F2213c0eeD49a7E28Ae4c3e91722919B8B47);

    uint16 private constant COMMON_CHEST = 0;
    uint16 private constant DELUXE_CHEST = 1;
    uint16 private constant CTR_HOLDER = 0;
    uint16 private constant WINNER_LIST = 1;
    uint16 private constant USER_AFTER_R1 = 2;
    uint256 private constant ROLL_IN_PROGRESS = 42;
    uint256 public constant TOTAL_SUPPLY_COMMON_CHEST = 1365;
    uint256 public constant TOTAL_SUPPLY_DELUXE_CHEST = 880;
    uint256 public constant AMOUNT_NFT_PER_CHEST = 4;

    mapping(uint16 => uint16) rankLengh;
    mapping(uint16 => uint16[]) chestRank;
    // 0: CTR Holder, 1: Winner List, 2: User after R1
    mapping(uint16 => mapping(uint16 => uint16)) public amountChestCanBuy;
    mapping(address => mapping(uint16 => bool)) public isBuy;
    mapping(uint16 => uint256) public chestPrice;
    // Mapping from Id to rank
    mapping(uint256 => uint16) public rankOf;
    // current genesis token id, default: 0, the first token will have ID of 1
    uint256 public currentId;
    // Handle length of array
    mapping (uint16 => uint16) arrLength;
    mapping (uint16 => uint16) virtualLength;
    mapping (uint16 => uint16) nftRemaining;

    using Counters for Counters.Counter;
    mapping(uint16 => Counters.Counter) public _totalClaimedChestCounter;
    mapping(address => mapping(uint16 => uint16)) _claimedChest;

    mapping(address => bool) winnerAddr;
    mapping(address => bool) ctrHolderAddr;

    uint256 public startR1Timestamp;
    uint256 public endR1Timestamp;
    uint256 public startR2Timestamp;

    constructor(
        address _mxy721,
        // uint256 _startR1Timestamp,
        // uint256 _endR1Timestamp,
        // uint256 _startR2Timestamp,
        address vrfCoordinator,
        address link,
        bytes32 _keyHash,
        uint256 _fee
    ) VRFConsumerBase(vrfCoordinator, link) {
        s_keyHash = _keyHash;
        s_fee = _fee;
        chestPrice[COMMON_CHEST] = 125 ether;
        chestPrice[DELUXE_CHEST] = 225 ether;
        // startR1Timestamp = _startR1Timestamp;
        // endR1Timestamp = _endR1Timestamp;
        // startR2Timestamp = _startR2Timestamp;
        mxy721 = _mxy721;

        // CTR Holder on R1
        amountChestCanBuy[CTR_HOLDER][COMMON_CHEST] = 2;
        amountChestCanBuy[CTR_HOLDER][DELUXE_CHEST] = 2;
        // Winner list on R1
        amountChestCanBuy[WINNER_LIST][COMMON_CHEST] = 2;
        amountChestCanBuy[WINNER_LIST][DELUXE_CHEST] = 1;
        // User after R1
        amountChestCanBuy[USER_AFTER_R1][COMMON_CHEST] = 1;
        amountChestCanBuy[USER_AFTER_R1][DELUXE_CHEST] = 1;

        // Set chest rank
        chestRank[COMMON_CHEST] = [
            3,
            4,
            5,
            6,
            7,
            8,
            9,
            10,
            11,
            12,
            13,
            14,
            15,
            16,
            17,
            18,
            19,
            20,
            21,
            22
        ];
        arrLength[COMMON_CHEST] = uint16(chestRank[COMMON_CHEST].length);
        nftRemaining[COMMON_CHEST] = uint16(TOTAL_SUPPLY_COMMON_CHEST * AMOUNT_NFT_PER_CHEST);
        chestRank[DELUXE_CHEST] = [
            7,
            8,
            9,
            10,
            11,
            12,
            13,
            14,
            15,
            16,
            17,
            18,
            19,
            20,
            21,
            22,
            23,
            24
        ];
        arrLength[DELUXE_CHEST] = uint16(chestRank[DELUXE_CHEST].length);
        nftRemaining[DELUXE_CHEST] = uint16(TOTAL_SUPPLY_DELUXE_CHEST * AMOUNT_NFT_PER_CHEST);

        // Set rank length
        rankLengh[3] = 1000;
        rankLengh[4] = 765;
        rankLengh[5] = 555;
        rankLengh[6] = 555;
        rankLengh[7] = 553;
        rankLengh[8] = 552;
        rankLengh[9] = 510;
        rankLengh[10] = 450;
        rankLengh[11] = 450;
        rankLengh[12] = 390;
        rankLengh[13] = 390;
        rankLengh[14] = 375;
        rankLengh[15] = 360;
        rankLengh[16] = 375;
        rankLengh[17] = 300;
        rankLengh[18] = 300;
        rankLengh[19] = 300;
        rankLengh[20] = 240;
        rankLengh[21] = 168;
        rankLengh[22] = 168;
        rankLengh[23] = 135;
        rankLengh[24] = 89;
        rankLengh[2] = 1020;
    }

    function winnerlistAddress(address[] memory users) external onlyOwner {
        for (uint256 i = 0; i < users.length; i++) {
            winnerAddr[users[i]] = true;
        }
    }

    function ctrHolderlistAddress(address[] memory users) external onlyOwner {
        for (uint256 i = 0; i < users.length; i++) {
            ctrHolderAddr[users[i]] = true;
        }
    }

    function isInWinnerList(address users) external view returns (bool) {
        return winnerAddr[users];
    }

    function isInCtrHolderList(address users) external view returns (bool) {
        return ctrHolderAddr[users];
    }

    function getTotalClaimedChest(uint16 chestType)
        external
        view
        returns (uint256)
    {
        return _totalClaimedChestCounter[chestType].current();
    }

    function totalClaimedChestOf(address user, uint16 chestType)
        external
        view
        returns (uint256)
    {
        return _claimedChest[user][chestType];
    }

    function setChestPrice(uint16 chestType, uint256 chestPrice_)
        external
        override
        onlyOwner
    {
        chestPrice[chestType] = chestPrice_;
    }

    function setTimeRound(
        uint256 startR1Timestamp_,
        uint256 endR1Timestamp_,
        uint256 startR2Timestamp_
    ) external onlyOwner {
        require(
            (startR1Timestamp < endR1Timestamp) &&
                (endR1Timestamp < startR2Timestamp),
            "MetaxyNFTSale: Invalid data"
        );
        startR1Timestamp = startR1Timestamp_;
        endR1Timestamp = endR1Timestamp_;
        startR2Timestamp = startR2Timestamp_;
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        s_results[s_rollers[requestId]] = randomness;
        emit DiceLanded(requestId, randomness);
    }

    function expand(uint256 randomValue, uint256 n)
        private
        pure
        returns (uint256[] memory expandedValues)
    {
        expandedValues = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            expandedValues[i] = uint256(keccak256(abi.encode(randomValue, i)));
        }
        return expandedValues;
    }

    function getRandNumInRage(uint256 randomValue, uint256 mod)
        private
        pure
        returns (uint256)
    {
        return randomValue % mod;
    }

    function removeRankFromPool(uint16 chestType, uint index) private {
        if (index >= chestRank[chestType].length) return;
        for (uint i = index; i < chestRank[chestType].length - 1; i++){
            chestRank[chestType][i] = chestRank[chestType][i + 1];
        }
        chestRank[chestType].pop();
        arrLength[chestType]--;
    }

    /**
     * @notice Requests randomness
     * @dev Warning: if the VRF response is delayed, avoid calling requestRandomness repeatedly
     * as that would give miners/VRF operators latitude about which VRF response arrives first.
     * @dev You must review your implementation details with extreme care.
     *
     * @param chestType type of chest
     */
    function buyChest(uint16 chestType)
        external
        override
        returns (bytes32 requestId)
    {
        require(chestType < 2, "MetaxyNFTSale: Wrong chest type");
        // uint256 timestamp = block.timestamp;
        // if (chestType == COMMON_CHEST) {
        //     require(
        //         _totalClaimedChestCounter[chestType].current() <
        //             TOTAL_SUPPLY_COMMON_CHEST,
        //         "MetaxyNFTSale: Common chest currently out of stock"
        //     );
        // }
        // if (chestType == DELUXE_CHEST) {
        //     require(
        //         _totalClaimedChestCounter[chestType].current() <
        //             TOTAL_SUPPLY_DELUXE_CHEST,
        //         "MetaxyNFTSale: Deluxe chest currently out of stock"
        //     );
        // }

        // if (timestamp >= startR1Timestamp && timestamp <= endR1Timestamp) {
        //     if (isInCtrHolderList(msg.sender)) {
        //         require(
        //             _claimedChest[msg.sender][chestType] <
        //                 amountChestCanBuy[CTR_HOLDER][chestType],
        //             "MetaxyNFTSale: You have purchased more than the specified quantity"
        //         );
        //     } else if (isInWinnerList(msg.sender)) {
        //         require(
        //             _claimedChest[msg.sender][chestType] <
        //                 amountChestCanBuy[WINNER_LIST][chestType],
        //             "MetaxyNFTSale: You have purchased more than the specified quantity"
        //         );
        //     } else {
        //         revert("MetaxyNFTSale: Your address is not in white list");
        //     }
        // } else if (timestamp < startR2Timestamp) {
        //     revert("MetaxyNFTSale: Not right time");
        // } else {
        //     require(
        //         _claimedChest[msg.sender][chestType] <
        //             amountChestCanBuy[USER_AFTER_R1][chestType],
        //         "MetaxyNFTSale: You have purchased more than the specified quantity"
        //     );
        // }

        require(
            nftRemaining[chestType] >= AMOUNT_NFT_PER_CHEST,
            "MetaxyNFTSale: Run out of id"
        );
        require(
            isBuy[msg.sender][chestType] == false,
            "MetaxyNFTSale: Need to claim chest before buy a new one"
        );

        require(
            BUSD.balanceOf(msg.sender) >= chestPrice[chestType],
            "MetaxyNFTSale: BUSD insufficient balance"
        );

        BUSD.safeTransferFrom(msg.sender, address(this), chestPrice[chestType]);
        require(
            LINK.balanceOf(address(this)) >= s_fee,
            "MetaFighterNFTChest: Not enough LINK to pay fee"
        );
        requestId = requestRandomness(s_keyHash, s_fee);
        s_rollers[requestId] = msg.sender;
        s_results[msg.sender] = ROLL_IN_PROGRESS;
        isBuy[msg.sender][chestType] = true;

        _totalClaimedChestCounter[chestType].increment();

        if (nftRemaining[chestType] >= AMOUNT_NFT_PER_CHEST)
            nftRemaining[chestType] = uint16(nftRemaining[chestType] - AMOUNT_NFT_PER_CHEST);

        string memory chestName;
        if (chestType == COMMON_CHEST) chestName = "Common Chest";
        if (chestType == DELUXE_CHEST) chestName = "Deluxe Chest";

        emit BuyAChest(msg.sender, chestName, chestPrice[chestType]);
        emit DiceRolled(requestId, msg.sender);
    }

    function mintAirdrop(address to, uint256 amount) external onlyOwner {
        // Airdrop rank E+
        require(rankLengh[2] >= amount, "MetaxyNFTSale: Run out of id");
        IMetaxyNFT(mxy721).mintGenesis(amount, to, 0);
        uint256 startId = currentId;
        currentId += amount;
        for (uint256 i = 1; i <= amount; i++) {
            rankOf[startId + i] = 2;
        }
        rankLengh[2] = uint16(rankLengh[2] - amount);
    }

    function isReadyClaimChest(address user, bytes32 requestId) external view returns(bool) {
        if (s_rollers[requestId] == user && s_results[user] != ROLL_IN_PROGRESS) {
            return true;
        }
        return false;
    }

    function claimChest(uint16 chestType) external override {

        require(
            isBuy[msg.sender][chestType],
            "MetaFighterNFTChest: Need to buy chest first"
        );
        require(
            s_results[msg.sender] != ROLL_IN_PROGRESS,
            "MetaFighterNFTChest: Roll in progress"
        );

        uint256 startId = currentId;
        currentId += AMOUNT_NFT_PER_CHEST;
        uint256[] memory rands = expand(s_results[msg.sender], AMOUNT_NFT_PER_CHEST);

        uint16 virtualLengthTemp = 0;
        // Update virtual length
        for (uint256 k = 0; k < chestRank[chestType].length; k++) {
            virtualLengthTemp += rankLengh[chestRank[chestType][k++]];
        }
        virtualLength[chestType] = virtualLengthTemp;
        
        for (uint256 i = 1; i <= AMOUNT_NFT_PER_CHEST; i++) {
            uint256 selectedLength = getRandNumInRage(rands[i - 1], virtualLength[chestType]);
            uint256 chestRankIndex;
            uint256 concatLength = 0;
            for (uint256 l = 0; l < chestRank[chestType].length; l++) {
                concatLength += rankLengh[chestRank[chestType][l]];
                if (concatLength >= selectedLength) {
                    chestRankIndex = l;
                    break;
                }
            }
            uint16 rankLenghIndex = chestRank[chestType][chestRankIndex];
            // Mapping id with rank
            rankOf[startId + i] = rankLenghIndex;
            // Minus rankLengh
            if (rankLengh[rankLenghIndex] > 0)
                rankLengh[rankLenghIndex]--;
            // If rankLengh = 0, remove rank from chestRank
            if (rankLengh[rankLenghIndex] == 0)
                removeRankFromPool(chestType, rankLenghIndex);
            // Minus virtual length
            if (virtualLength[chestType] > 0)
                virtualLength[chestType]--;
        }
        IMetaxyNFT(mxy721).mintGenesis(AMOUNT_NFT_PER_CHEST, msg.sender, chestPrice[chestType] / AMOUNT_NFT_PER_CHEST);
        _claimedChest[msg.sender][chestType] += 1;
        isBuy[msg.sender][chestType] = false;
    }

    function ownerWithdraw(uint256 amount, address payable recipient)
        external
        override
        onlyOwner
    {
        BUSD.safeTransfer(recipient, amount);
    }

    function withdrawLINK(address to, uint256 value) external onlyOwner {
        require(
            LINK.transfer(to, value),
            "MetaFighterNFTChest: Not enough LINK"
        );
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface IChest {
    function setChestPrice(uint16 chestType, uint256 chestPrice_) external;

    function buyChest(uint16 chestType) external returns (bytes32 requestId);

    function claimChest(uint16 chestType) external;

    function ownerWithdraw(uint256 amount, address payable recipient) external;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
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
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/LinkTokenInterface.sol";

import "./VRFRequestIDBase.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {
  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 private constant USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(bytes32 _keyHash, uint256 _fee) internal returns (bytes32 requestId) {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface internal immutable LINK;
  address private immutable vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 => uint256) /* keyHash */ /* nonce */
    private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(address _vrfCoordinator, address _link) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IMetaxyNFT is IERC721Enumerable {

    /**
     * @dev Call to mint new genesis tokens, only by Genesis Minter
     * @param amount amount of genesis tokens to mint
     * @param to recipient of genesis tokens
     */
    function mintGenesis(
        uint256 amount,
        address to,
        uint256 unitPrice
    ) external;

    /**
     * @dev Return the current genesis minter address
     */
    function genesisMinter() external view returns (address);

    /**
     * @dev Return the store front URI
     */
    function contractURI() external view returns (string memory);

    /**
     * @dev Return the current genesis token id, default 0, the first token has id of 1
     */
    function currentId() external view returns (uint256);

    /**
     * @dev Return the base Metaxy URI for tokens
     */
    function baseMetaxyURI() external view returns (string memory);
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VRFRequestIDBase {
  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  ) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}