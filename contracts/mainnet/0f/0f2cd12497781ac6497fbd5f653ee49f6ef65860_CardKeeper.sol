/**
 *Submitted for verification at Etherscan.io on 2021-03-13
*/

/**
 *Submitted for verification at Etherscan.io on 2020-10-18
*/

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface RMU {
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes calldata _data) external;
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external;
    function setApprovalForAll(address _operator, bool _approved) external;
    function isApprovedForAll(address _owner, address _operator) external view returns (bool isOperator);
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);
    function mintBatch(address user, uint256[] calldata ids, uint256[] calldata amounts) external;
    function burn(
        address _account,
        uint256 _id,
        uint256 _amount
    ) external;
}

interface Toshicash {
    function totalSupply() external view returns (uint256);
    function totalClaimed() external view returns (uint256);
    function addClaimed(uint256 _amount) external;
    function setClaimed(uint256 _amount) external;
    function transfer(address receiver, uint numTokens) external returns (bool);
    function transferFrom(address owner, address buyer, uint numTokens) external returns (bool);
    function balanceOf(address owner) external view returns (uint256);
    function mint(address _to, uint256 _amount) external;
    function burn(address _account, uint256 value) external;
}


/**
 *  This contract was forked from Rope's VendingMachine contract:
 *  https://etherscan.io/address/0x4c842514fb55323acc51aa575ec4b7d1be1e0694#code
 *
 *  All code attribution goes to Rope and the Rope development team:
 *  https://rope.lol
 */

contract CardKeeper is Ownable {
    using SafeMath for uint256;

    struct CardSet {
        uint256[] cardIds;
        uint256 toshicashPerDayPerCard;
    }

    RMU public ropeMaker;
    Toshicash public toshicash;

    uint256[] public cardSetList;
    uint256 public highestCardId;
    mapping (uint256 => CardSet) public cardSets;
    mapping (uint256 => uint256) public cardToSetMap;

    mapping (address => mapping(uint256 => uint256)) public userCards;
    mapping (address => uint256) public userLastUpdate;
    
    mapping(uint256 => mapping(address => UserInfoERC1155)) public userInfoERC1155;
    mapping(uint256 => uint256) public eRC1155MultiplierIds;
    mapping(address => ERC1155MultiplierUserInfo) public userMultiplier;

    event Stake(address indexed user, uint256[] cardIds,  uint256[] amounts);
    event Unstake(address indexed user, uint256[] cardIds,  uint256[] amounts);
    event Harvest(address indexed user, uint256 amount);
    

        struct UserInfoERC1155 {
        uint256 amountInPool;
        
        /*
         *  At any point in time, the amount of ToshiCoin earned by a user waiting to be claimed is:
         *
         *    Pending claim = (user.amountInPool * pool.coinsEarnedPerToken) - user.coinsReceivedToDate
         *
         *  Whenever a user deposits or withdraws tokens to a pool, the following occurs:
         *   1. The pool's `coinsEarnedPerToken` is rebalanced to account for the new shares in the pool.
         *   2. The `lastRewardBlock` is updated to the latest block.
         *   3. The user receives the pending claim sent to their address.
         *   4. The user's `amountInPool` and `coinsReceivedToDate` get updated for this pool.
         */
    }
        struct ERC1155Multiplier {
        uint256 id;
        uint256 percentBoost;
       
    }
    struct ERC1155MultiplierUserInfo {
        uint256 multiplier;
        uint256 total;
       
    }

    ERC1155Multiplier[] public eRC1155Multiplier;


    constructor(RMU _ropeMakerAddr, Toshicash _toshicashAddr) public {
        ropeMaker = _ropeMakerAddr;
        toshicash = _toshicashAddr;

    }

    // Utility function to check if a value is inside an array
    function _isInArray(uint256 _value, uint256[] memory _array) internal pure returns(bool) {
        uint256 length = _array.length;
        for (uint256 i = 0; i < length; ++i) {
            if (_array[i] == _value) {
                return true;
            }
        }

        return false;
    }

    // Index of the value in the return array is the cardId, value is whether card is staked or not
    function getCardsStakedOfAddress(address _user) public view returns(uint256[] memory) {
        uint256[] memory cardsStaked = new uint256[](highestCardId + 1);

        for (uint256 i = 0; i < highestCardId + 1; ++i) {
            cardsStaked[i] = userCards[_user][i];
        }

        return cardsStaked;
    }

    // Returns the list of cardIds which are part of a set
    function getCardIdListOfSet(uint256 _setId) external view returns(uint256[] memory) {
        return cardSets[_setId].cardIds;
    }


    function addCardSet(uint256 _setId, uint256[] memory _cardIds, uint256 _toshicashPerDayPerCard) public onlyOwner {
       

        uint256 length = _cardIds.length;
        for (uint256 i = 0; i < length; ++i) {
            uint256 cardId = _cardIds[i];

            if (cardId > highestCardId) {
                highestCardId = cardId;
            }

            // Check all cards to assign arent already part of another set
            require(cardToSetMap[cardId] == 0, "Card already assigned to a set");

            // Assign to set
            cardToSetMap[cardId] = _setId;
        }

        if (_isInArray(_setId, cardSetList) == false) {
            cardSetList.push(_setId);
        }

        cardSets[_setId] = CardSet({
            cardIds: _cardIds,
            toshicashPerDayPerCard: _toshicashPerDayPerCard
        });
    }



    // Returns the total toshicash pending for a given address
    // Can include the bonus from toshicashBooster or not
    function totalPendingToshicashOfAddress(address _user, bool _includeToshicashBooster) public view returns (uint256) {
        uint256 totalToshicashPerDay = 0;

        uint256 length = cardSetList.length;
        for (uint256 i = 0; i < length; ++i) {
            uint256 setId = cardSetList[i];
            CardSet storage set = cardSets[setId];

            uint256 cardLength = set.cardIds.length;

            uint256 setToshicashPerDay = 0;
            for (uint256 j = 0; j < cardLength; ++j) {


                setToshicashPerDay = setToshicashPerDay.add(set.toshicashPerDayPerCard.mul(userCards[_user][set.cardIds[j]]));
            }


            totalToshicashPerDay = totalToshicashPerDay.add(setToshicashPerDay);
        }

        // Apply toshicashBooster bonus
        if (_includeToshicashBooster) {
            uint256 toAdd = 0;
            totalToshicashPerDay = totalToshicashPerDay.add(toAdd);
        }

        uint256 lastUpdate = userLastUpdate[_user];
        uint256 blockTime = block.timestamp;
        return blockTime.sub(lastUpdate).mul(totalToshicashPerDay.div(86400));
    }


    //////////////////////////////
    //////////////////////////////
    //////////////////////////////

    // Set manually the highestCardId, in case there has been a mistake while adding a set
    // (This value is used to know the range in which iterate to get the list of staked cards for an address)
    function setHighestCardId(uint256 _highestId) public onlyOwner {
        require(_highestId > 0);
        highestCardId = _highestId;
    }




    // Set the toshicashPerDayPerCard value for a list of sets
    function setToshicashRateOfSets(uint256[] memory _setIds, uint256[] memory _toshicashPerDayPerCard) public onlyOwner {
        require(_setIds.length == _toshicashPerDayPerCard.length, "_setId and _toshicashPerDayPerCard have different length");

        for (uint256 i = 0; i < _setIds.length; ++i) {
            require(cardSets[_setIds[i]].cardIds.length > 0, "Set is empty");
            cardSets[_setIds[i]].toshicashPerDayPerCard = _toshicashPerDayPerCard[i];
        }
    }


    function harvest() public {
        ERC1155MultiplierUserInfo storage multiplier = userMultiplier[msg.sender];
        uint256 pendingToshicash = totalPendingToshicashOfAddress(msg.sender, true);
        userLastUpdate[msg.sender] = block.timestamp;
        pendingToshicash = pendingToshicash.add( pendingToshicash.mul(multiplier.multiplier).div( 100));
        if (pendingToshicash > 0) {
            toshicash.mint(msg.sender, pendingToshicash);
        }

        emit Harvest(msg.sender, pendingToshicash);
    }

    function stake(uint256[] memory _cardIds, uint256[] memory _cardAmounts) public {
        require(_cardIds.length > 0, "_cardIds array empty");

        harvest();

        for (uint256 i = 0; i < _cardIds.length; ++i) {

            require(cardToSetMap[_cardIds[i]] != 0, "Card is not part of any set");
        }

        
        ropeMaker.mintBatch(address(this), _cardIds, _cardAmounts);

        for (uint256 i = 0; i < _cardIds.length; ++i) {
            userCards[msg.sender][_cardIds[i]] = userCards[msg.sender][_cardIds[i]].add(_cardAmounts[i]);
            ropeMaker.burn(msg.sender, _cardIds[i], _cardAmounts[i]);
        }

        emit Stake(msg.sender, _cardIds, _cardAmounts);
    }


    function unstake(uint256[] memory _cardIds, uint256[] memory _cardAmounts) public {
        require(_cardIds.length > 0, "_cardIds array empty");

        harvest();

        for (uint256 i = 0; i < _cardIds.length; ++i) {
            require(userCards[msg.sender][_cardIds[i]] >= _cardAmounts[i], "Card not staked");
            userCards[msg.sender][_cardIds[i]] = userCards[msg.sender][_cardIds[i]].sub(_cardAmounts[i]);
            ropeMaker.burn(address(this), _cardIds[i], _cardAmounts[i]);
        }

        
        ropeMaker.mintBatch(msg.sender, _cardIds, _cardAmounts);
        

        emit Unstake(msg.sender, _cardIds, _cardAmounts);
    }

    // Withdraw without rewards
    function emergencyUnstake(uint256[] memory _cardIds, uint256[] memory _cardAmounts) public {
        userLastUpdate[msg.sender] = block.timestamp;

        uint256 length = _cardIds.length;
        for (uint256 i = 0; i < length; ++i) {
            uint256 cardId = _cardIds[i];

            require(userCards[msg.sender][cardId] >= _cardAmounts[i], "Card not staked");
            userCards[msg.sender][cardId] = userCards[msg.sender][cardId].sub(_cardAmounts[i]);
        }

        ropeMaker.safeBatchTransferFrom(address(this), msg.sender, _cardIds, _cardAmounts, "");
    }

    function userMultiplierValue(address user) public view returns (uint256) {

        return userMultiplier[msg.sender].multiplier;
    }
    
    function userERC155StakedTotal(address user) public view returns (uint256) {

        return userMultiplier[msg.sender].total;
    }
    function addERC1155Multiplier(uint256 _id, uint256 _percentBoost) public onlyOwner {
        require(
            eRC1155MultiplierIds[_id] == 0,
            "ToshiCashFarm: Cannot add duplicate Toshimon ERC1155"
        );

        eRC1155Multiplier.push(
            ERC1155Multiplier({
                id:_id,
                percentBoost: _percentBoost
            })
        );

        eRC1155MultiplierIds[_id] = 1;
    }
      /**
     * @dev Deposit tokens into a pool and claim pending reward.
     */
    function depositERC1155(uint256 poolId, uint256 quantity) public {

        ERC1155Multiplier storage erc1155 = eRC1155Multiplier[poolId];
        UserInfoERC1155 storage user = userInfoERC1155[poolId][msg.sender];
        ERC1155MultiplierUserInfo storage multiplier = userMultiplier[msg.sender];
         uint256[] memory cardid = new uint256[](1);
         uint256[] memory cardamount = new uint256[](1);
        cardid[0] = erc1155.id;
        cardamount[0] = quantity;

         
        harvest();
        
        ropeMaker.burn(msg.sender, erc1155.id, quantity);


        
        ropeMaker.mintBatch(address(this), cardid, cardamount);
        
        
        user.amountInPool = user.amountInPool.add(quantity);
        multiplier.multiplier = multiplier.multiplier.add(erc1155.percentBoost.mul(quantity));
        multiplier.total = multiplier.total.add(erc1155.percentBoost.mul(quantity));
        if(multiplier.multiplier > 100){
            multiplier.multiplier = 100;
        }

    }
      /**
     * @dev Deposit tokens into a pool and claim pending reward.
     */
    function withdrawERC1155(uint256 poolId, uint256 quantity) public {

        ERC1155Multiplier storage erc1155 = eRC1155Multiplier[poolId];
        UserInfoERC1155 storage user = userInfoERC1155[poolId][msg.sender];
        ERC1155MultiplierUserInfo storage multiplier = userMultiplier[msg.sender];
        
        
        require(
            user.amountInPool >= quantity,
            "ToshiCoinFarm: User does not have enough NFTS to withdraw from this pool"
        );
        harvest();
        
        user.amountInPool = user.amountInPool.sub(quantity);
        
        
        multiplier.total = multiplier.total.sub(erc1155.percentBoost.mul(quantity));
        multiplier.multiplier = multiplier.total.mul(quantity);
        if(multiplier.multiplier > 100){
            multiplier.multiplier = 100;
        }
        
        ropeMaker.burn(address(this), erc1155.id, quantity);
         uint256[] memory cardid = new uint256[](1);
         uint256[] memory cardamount = new uint256[](1);
        cardid[0] = erc1155.id;
        cardamount[0] = quantity;

        
        ropeMaker.mintBatch(msg.sender, cardid, cardamount);
        


    }



    /////////
    /////////
    /////////

    /**
     * @notice Handle the receipt of a single ERC1155 token type
     * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated
     * This function MAY throw to revert and reject the transfer
     * Return of other amount than the magic value MUST result in the transaction being reverted
     * Note: The token contract address is always the message sender
     * @param _operator  The address which called the `safeTransferFrom` function
     * @param _from      The address which previously owned the token
     * @param _id        The id of the token being transferred
     * @param _amount    The amount of tokens being transferred
     * @param _data      Additional data with no specified format
     * @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     */
    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _amount, bytes calldata _data) external returns(bytes4) {
        return 0xf23a6e61;
    }

    /**
     * @notice Handle the receipt of multiple ERC1155 token types
     * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated
     * This function MAY throw to revert and reject the transfer
     * Return of other amount than the magic value WILL result in the transaction being reverted
     * Note: The token contract address is always the message sender
     * @param _operator  The address which called the `safeBatchTransferFrom` function
     * @param _from      The address which previously owned the token
     * @param _ids       An array containing ids of each token being transferred
     * @param _amounts   An array containing amounts of each token being transferred
     * @param _data      Additional data with no specified format
     * @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     */
    function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external returns(bytes4) {
        return 0xbc197c81;
    }

    /**
     * @notice Indicates whether a contract implements the `ERC1155TokenReceiver` functions and so can accept ERC1155 token types.
     * @param  interfaceID The ERC-165 interface ID that is queried for support.s
     * @dev This function MUST return true if it implements the ERC1155TokenReceiver interface and ERC-165 interface.
     *      This function MUST NOT consume more than 5,000 gas.
     * @return Wheter ERC-165 or ERC1155TokenReceiver interfaces are supported.
     */
    function supportsInterface(bytes4 interfaceID) external view returns (bool) {
        return  interfaceID == 0x01ffc9a7 ||    // ERC-165 support (i.e. `bytes4(keccak256('supportsInterface(bytes4)'))`).
        interfaceID == 0x4e2312e0;      // ERC-1155 `ERC1155TokenReceiver` support (i.e. `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")) ^ bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`).
    }
}