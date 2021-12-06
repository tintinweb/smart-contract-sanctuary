// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";


contract LuckyShibaGameRunner is Ownable { 

    struct LuckyFigureModel {
        uint256 figure;
        uint32 a;
        uint32 b;
        uint32 c;
    }
    // {period: lucky figures}
    mapping(string => LuckyFigureModel) private _allLuckyFigures;


    bool private _disabled;

    uint256 private _feeRate;

    uint256 public uintPrice;

    constructor() {
        _disabled = false;
        _feeRate = 60;
 
        uint256 placeDecimals = 10 ** 18;
        uintPrice = 2 * placeDecimals; // 2 MATIC or 0.005 BNB
    }

    function isDisabled() public view returns (bool)  {
        return _disabled;
    }

    function setDisable(bool flag) public onlyOwner {
        _disabled = flag;
    } 

    function adjustFee(uint256 feeRate) public onlyOwner {
        _feeRate = feeRate;
    }

    function setUintPrice(uint256 price) public onlyOwner {
        uintPrice = price;
    }

    function decimals() public pure returns (uint256) {
        return 18;
    }
    









    /******************    First Step: Buy Ticket     ********************/

    // { period: { ticket: address list } }
    mapping(string => mapping(uint256 => address[])) private _ticketRecord;

    // {period: ticket list}
    mapping(string => uint256[]) private _tickets;

    event BuyEvent(string period, uint256 ticket, address buyer, uint256 amount);

    function buy(string memory period, uint256 ticket) public payable {  
        require(isDisabled() == false, "Buying ticket has stopped!");
        require(ticket <= 999, "The ticket must be in range of 000-999");

        // if it's on Polygon Network
        require(msg.value == uintPrice, "Only 2 MATIC for a ticket!");

        // if it's on Binance Smart Chain
        // require(msg.value != 0.005 * placeDecimals, "Only 0.005 BNB for a ticket!");

        _ticketRecord[period][ticket].push(_msgSender());

        // check for duplicated ticket
        if (!_ifTicketExists(period, ticket)) {
            _tickets[period].push(ticket);
        }

        emit BuyEvent(period, ticket, _msgSender(), msg.value);
    }

    function queryAllAddresses(string memory period, uint256 ticket) public view returns (address[] memory) {
        return _ticketRecord[period][ticket];
    }

    function queryAllTickets(string memory period) public view returns (uint256[] memory) {
        return _tickets[period];
    }

    // function _stringEqual(string memory a, string memory b) internal pure returns (bool) {
    //     return keccak256(abi.encode(a)) == keccak256(abi.encode(b));
    // }

    function _ifTicketExists(string memory period, uint256 ticket) internal view returns (bool) {
        for (uint256 i = 0; i < _tickets[period].length; i++) {
            if (_tickets[period][i] == ticket) {
                return true;
            }
        }
        return false;
    }









    /******************    Second Step: Choose 3 people to generate Ticket     ********************/

    struct ThreePeopleToRandomizeFigureModel {
        address addr1;
        uint256 num1;

        address addr2;
        uint256 num2;

        address addr3;
        uint256 num3;
    } 
    mapping(string => ThreePeopleToRandomizeFigureModel) private _3peopleToRandomizeFigureMapping;

    // {period: 3 people to randomly generate 3 numbers}
    mapping(string => address[]) private _3peopleAddressList;

    function addPeopleToRandomizeFigureList(string memory period, address[] memory toList) public onlyOwner {
        require(toList.length == 3, "Only allowing 3 addresses to randomly generate figures!");
        _3peopleAddressList[period] = toList;

        (uint256 figure, uint256 a, uint256 b, uint256 c) = getRandomSeed(period);
        _3peopleToRandomizeFigureMapping[period] = ThreePeopleToRandomizeFigureModel(toList[0], a, toList[1], b, toList[2], c);
    }

    function get3peopleToRandomizeFigureList(string memory period) public view returns (address[] memory) {
        return _3peopleAddressList[period];
    }

    function generateRandomFigure(string memory period, uint256 number) public view returns (uint256) {
        bool _found = false; 
        address[] memory addrs = _3peopleAddressList[period];
        for (uint256 i = 0; i < addrs.length; i++) {
            if (addrs[i] == _msgSender()) {
                _found = true; 
                break;
            }
        }
        require(_found, "You're not allowed to generate the randomly figure, perhaps you will be chosen in next round game.");

        LuckyFigureModel memory rsModel = _allLuckyFigures[period];

        uint256 currentNumber = 0;

        ThreePeopleToRandomizeFigureModel memory model = _3peopleToRandomizeFigureMapping[period];
        if (model.addr1 == address(0x0) && model.num1 == 0) {
            model.addr1 = _msgSender();
            model.num1 = number;
            currentNumber = rsModel.a;
        } else if (model.addr2 == address(0x0) && model.num2 == 0) {
            model.addr2 = _msgSender();
            model.num2 = number;
            currentNumber = rsModel.b;
        } else if (model.addr3 == address(0x0) && model.num3 == 0) {
            model.addr3 = _msgSender();
            model.num3 = number;
            currentNumber = rsModel.c;
        }
        // _3peopleToRandomizeFigureMapping[period] = model;

        return currentNumber;
    }
    
    function fetchRandomFigures(string memory period) public view returns (address, uint256, address, uint256, address, uint256) {
        ThreePeopleToRandomizeFigureModel memory model = _3peopleToRandomizeFigureMapping[period];
        return (model.addr1, model.num1, model.addr2, model.num2, model.addr3, model.num3);
    }

    function generateRandomSeed(string memory p, uint256 rs, uint32 a, uint32 b, uint32 c) public onlyOwner { 
        _allLuckyFigures[p] = LuckyFigureModel(rs, a, b, c);
    }

    function getRandomSeed(string memory p) public view returns (uint256, uint256, uint256, uint256) {
        LuckyFigureModel memory m = _allLuckyFigures[p];
        return (m.figure, m.a, m.b, m.c);
    }










    /******************    Third Step: Distribute Rewards     ********************/

    event SendRewardEvent(string period, uint256 ticket, uint256 singleIncome, address[] addresses);

    function sendReward(string memory period) public onlyOwner {
        uint256 number = _allLuckyFigures[period].figure;
        // require(number > 0, "The random number hasnot set up yet!"); Probably the lucky number is 000

        address[] memory addrs = _ticketRecord[period][number];
        require(addrs.length > 0, "No addresses were found!");

        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficient Balance!");
        
        // The amount of rewards to every winner
        uint256 toEveryWinnerBal = (balance * _feeRate) / 100 / addrs.length;
        require(toEveryWinnerBal > 0, "Insufficient Balance to Every Winners!");

        // to platform
        // uint256 toThePlatform = balance * 0.3;

        // distribute to every winner
        for (uint256 i = 0; i < addrs.length; i++) {
            payable(addrs[i]).transfer(toEveryWinnerBal); 
        }

        emit SendRewardEvent(period, number, toEveryWinnerBal, addrs);
    }






    function settleCoin(address to) public onlyOwner {   
        uint256 total = address(this).balance;
        require(total > 0, "Coin balance is insufficient!");
        payable(to).transfer(total); 
    }   

    function settleToken(address tokenAddress, address to) public onlyOwner {   
        uint256 total = IERC20(tokenAddress).balanceOf(address(this));
        require(total > 0, "Token balance is insufficient!");
        require(IERC20(tokenAddress).transfer(to, total), "Failed to settle account the balance."); 
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