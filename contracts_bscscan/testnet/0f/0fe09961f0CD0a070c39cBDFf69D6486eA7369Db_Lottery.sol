// SPDX-License-Identifier: MIT

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
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

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
pragma solidity 0.8.0;

import "./0-context.sol";

/**
 * @dev The contract has an owner address, and provides basic authorization control whitch
 * simplifies the implementation of user permissions. This contract is based on the source code at:
 * https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/ownership/Ownable.sol
 */
contract Ownable is Context
{

  /**
   * @dev Error constants.
   */
  string public constant NOT_CURRENT_OWNER = "018001";
  string public constant CANNOT_TRANSFER_TO_ZERO_ADDRESS = "018002";

  /**
   * @dev Current owner address.
   */
  address public owner;

  /**
   * @dev An event which is triggered when the owner is changed.
   * @param previousOwner The address of the previous owner.
   * @param newOwner The address of the new owner.
   */
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The constructor sets the original `owner` of the contract to the sender account.
   */
  constructor()
  {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner()
  {
    require(msg.sender == owner, NOT_CURRENT_OWNER);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(
    address _newOwner
  )
    public
    virtual
    onlyOwner
  {
    require(_newOwner != address(0), CANNOT_TRANSFER_TO_ZERO_ADDRESS);
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./0-ierc20.sol";
import "./0-ownable.sol";


interface ILotteryPetNft {
    function adventureMint(uint level, uint quantity) external;
    function createdTokenCount() external view returns (uint256);
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        external;
}

contract LotteryStorage is Ownable {
    struct AccountDetail {
        uint consecutiveFailCount;
    }

    address public lotteryAddress;

    function setLottery(address _lotteryAddress) public onlyOwner {
        lotteryAddress = _lotteryAddress;
    }

    mapping(address => AccountDetail) public accountDetails;

    function set(address account, AccountDetail memory accountDetail) public {
        require(_msgSender() == lotteryAddress, "ONLY_LOTTERY_ADDRESS");
        accountDetails[account] = accountDetail;
    }

    function get(address account) public view returns(AccountDetail memory) {
        return accountDetails[account];
    }
}

contract Lottery is Ownable {
    uint public budget;
    IERC20 public erc20;
    LotteryRandomizer public lotteryRandomizer;
    LotteryStorage public lotteryStorage;
    ILotteryPetNft public lotteryPetNft;

    constructor(IERC20 _erc20, LotteryRandomizer _lotteryRandomizer, LotteryStorage _lotteryStorage, ILotteryPetNft _lotteryPetNft) {
        erc20 = _erc20;
        lotteryRandomizer = _lotteryRandomizer;
        lotteryStorage = _lotteryStorage;
        lotteryPetNft = _lotteryPetNft;
    }

    function setLotteryRandomizer(LotteryRandomizer _lotteryRandomizer) public onlyOwner {
        lotteryRandomizer = _lotteryRandomizer;
    }

    uint public ticketPrice = 700 gwei;

    function setTicketPrice(uint newTicketPrice) public onlyOwner {
        ticketPrice = newTicketPrice;
    }

    function setBudget(uint newBudget) public onlyOwner {
        budget = newBudget;
    }

    bool public isGameActive = true;

    function setIsGameActive(bool newIsGameActive) public onlyOwner {
        isGameActive = newIsGameActive;
    }

    function play() public {
        require(isGameActive, "GAME_INACTIVED");
        uint256 currentTicketPrice = ticketPrice;
        erc20.transferFrom(_msgSender(), address(this), currentTicketPrice);
        uint256 petLevel = lotteryRandomizer.getPetLevel();

        uint256 currentBudget = budget;
        if (petLevel == 0) {
            return onLose(currentTicketPrice, currentBudget);
        }

        onWin(currentTicketPrice, petLevel, currentBudget);
    }

    function setMaxConsecutiveFailCount(uint newMaxConsecutiveFailCount) public onlyOwner {
        maxConsecutiveFailCount = newMaxConsecutiveFailCount;
    }

    uint256 public maxConsecutiveFailCount = 10;

    event Lose(address account, uint256 currentTicketPrice);
    event ConsolationPrize(address account, uint256 value);

    function onLose(uint256 currentTicketPrice, uint256 currentBudget) internal {
        emit Lose(_msgSender(), currentTicketPrice);
        LotteryStorage.AccountDetail memory accountDetail = lotteryStorage.get(_msgSender());
        bool shouldResetFailCount = accountDetail.consecutiveFailCount == maxConsecutiveFailCount - 1;

        if (shouldResetFailCount) {
            uint256 prize = currentTicketPrice * 3;
            uint256 newFailCount = 0;
            budget = currentBudget - prize;
            lotteryStorage.set(_msgSender(), LotteryStorage.AccountDetail(newFailCount));
            emit ConsolationPrize(_msgSender(), prize);
            erc20.transfer(_msgSender(), prize);
            return;
        }
        
        budget = currentBudget + currentTicketPrice;
        lotteryStorage.set(_msgSender(), LotteryStorage.AccountDetail(
            accountDetail.consecutiveFailCount + 1
        ));
    }

    uint256[] public PET_PRICES = [
        0,
        3571 gwei,
        7500 gwei,
        15803 gwei,
        33414 gwei,
        70922 gwei,
        151140 gwei,
        323478 gwei,
        695502 gwei,
        1502687 gwei,
        3263563 gwei,
        7127118 gwei,
        15656249 gwei,
        34607907 gwei,
        77010177 gwei,
        172578613 gwei,
        386745997 gwei,
        866691785 gwei,
        1942242856 gwei,
        4352536135 gwei
    ];

    function setPetPrices(uint256[19] memory newPrices) public onlyOwner {
        for (uint256 index = 0; index < newPrices.length; index++) {
            PET_PRICES[index + 1] = newPrices[index];
        }
    }

    event Win(address account, uint256 currentTicketPrice, uint256 petLevel);

    function onWin(uint256 currentTicketPrice, uint256 petLevel, uint256 currentBudget) internal {
        uint256 petPrice = PET_PRICES[petLevel];

        bool shouldReceivePetLevelExactly = petPrice < currentBudget + petPrice / 100 * 20;
        if (shouldReceivePetLevelExactly) {
            uint256 newFailCount = 0;
            budget = currentBudget > petPrice ? currentBudget - petPrice : 0;
            lotteryStorage.set(_msgSender(), LotteryStorage.AccountDetail(newFailCount));
            emit Win(_msgSender(), currentTicketPrice, petLevel);
            uint256 petQuantity = 1;
            lotteryPetNft.adventureMint(petLevel, petQuantity);
            uint256 newPetId = lotteryPetNft.createdTokenCount();
            lotteryPetNft.safeTransferFrom(address(this), _msgSender(), newPetId);
        } else {
            uint256 adjustedLevel = 1;
            uint256 newFailCount = 0;
            budget = getNewBudget(currentBudget);
            lotteryStorage.set(_msgSender(), LotteryStorage.AccountDetail(newFailCount));
            emit Win(_msgSender(), currentTicketPrice, adjustedLevel);
            uint256 petQuantity = 1;
            lotteryPetNft.adventureMint(adjustedLevel, petQuantity);
            uint256 newPetId = lotteryPetNft.createdTokenCount();
            lotteryPetNft.safeTransferFrom(address(this), _msgSender(), newPetId);
        }
    }

    function getNewBudget(uint256 currentBudget) internal view returns(uint256) {
        if (currentBudget >= PET_PRICES[11]) return currentBudget / 2;
        if (currentBudget >= PET_PRICES[4]) return currentBudget * 2 / 3;
        return 0;
    }

    function ownerWithdrawCoin() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function ownerWithdrawToken(uint256 amount, IERC20 anyErc20) public onlyOwner {
        anyErc20.transfer(owner, amount);
    }
}

contract LotteryRandomizer is Ownable {
    uint256[20] public WIN_RATES = [
        95000000, 2500000, 1250000,
        625000,  312500,  156250,
        78125,   39063,   19531,
        9766,    4883,    2441,
        1221,     610,     381,
        229,
        0,
        0,
        0,
        0
    ];

    function setWinRates(uint256[20] memory winRates) public onlyOwner {
        for (uint256 index = 0; index < winRates.length; index++) {
            WIN_RATES[index] = winRates[index];
        }
    }

    function getPetLevel() public view returns(uint256) {
        uint256 random = getRandom() % 1e8;

        uint256 length = WIN_RATES.length;
        for (uint256 index = 0; index < length; index++) {
            uint256 rate = WIN_RATES[index];
            if (random <= rate) return index;
            random = random - rate;
        }
        return length - 1;
    }

    function getRandom() public view returns(uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, tx.origin)));
    }
}

/*
Deployment:

- Deploy LotteryStorage
- Deploy LotteryRandomizer
- Deploy Lottery
- Set Lottery in LotteryStorage
- Set adventure address in PetNFT
*/