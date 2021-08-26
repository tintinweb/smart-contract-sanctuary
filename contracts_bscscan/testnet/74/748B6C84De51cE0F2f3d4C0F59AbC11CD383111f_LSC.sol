/**
 *Submitted for verification at BscScan.com on 2021-08-25
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }
}

contract Context {
    constructor() {}

    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (bytes32)
    {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set)
        internal
        view
        returns (bytes32[] memory)
    {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set)
        internal
        view
        returns (address[] memory)
    {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index)
        internal
        view
        returns (uint256)
    {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set)
        internal
        view
        returns (uint256[] memory)
    {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

interface IPancakeRouter01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IPancakeFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

//**********************************************************************************************
//******************************  Contract code starts here!  **********************************
//**********************************************************************************************

contract LSC is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    // Standard Mappings for IBEP20 Contract
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;

    mapping(address => bool) public whitelistFee;
    mapping(address => bool) public excludedFromStack;
    mapping(address => bool) public blacklistedPairs;

    // Pancakeswap Informations
    address public pancakeswapV2Pair;
    IPancakeRouter02 _pancakeswapV2Router;

    // Metadata
    uint256 public _totalSupply;
    uint8 _decimals;
    string internal _name;
    string internal _symbol;

    //Wallet Addresses Public
    address public _lottoWallet;
    address public _marketWallet;
    address public _pancakeRouterAddress;
    address public _gameWinner;

    //flags and functionality

    bool feesActive;
    bool inSwapAndLiquify;

    uint256 public gameTimer;
    uint256 public timerExpires;

    //Lottery Game Variables
    EnumerableSet.AddressSet private playerStack;

    uint256 public prize;
    uint256 internal _ticketPrice;
    uint256 internal _maxTickets;

    uint256 public _pancakeSwapSellFee = 19;
    uint256 private _pancakeLiqSellFee = 15;
    uint256 private _pancakeDisSellFee = 4;

    bool distributionState = true;

    bool public tradeEnabled = false;

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    constructor(address _routerAddress) {
        _decimals = 9;
        _name = "Lottoescape";
        _symbol = "LSC";

        //Set Game Variables
        prize = 10 * 10**uint256(9 + _decimals);
        _ticketPrice = 100000 * 10**uint256(_decimals);
        _maxTickets = 500000;

        //NEEDS to be changed to 24 hours
        gameTimer = 300 seconds;

        feesActive = true;

        _totalSupply = 10**uint256(_decimals + 15);
        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);

        _pancakeswapV2Router = IPancakeRouter02(_routerAddress);

        // Create a Pancake pair for this new token
        pancakeswapV2Pair = IPancakeFactory(_pancakeswapV2Router.factory())
            .createPair(address(this), _pancakeswapV2Router.WETH());

        whitelistFee[_msgSender()] = true;
        whitelistFee[address(this)] = true;

        excludedFromStack[_pancakeRouterAddress] = true;
        excludedFromStack[pancakeswapV2Pair] = true;

        blacklistedPairs[pancakeswapV2Pair] = true;
    }

    //*****************************************************************************
    //************************  Lotto Game Function calls  ************************
    //*****************************************************************************

    function startLotto() public onlyOwner {
        // Public access to the private function initiateGame()
        initiateGame();
    }

    function endGameEarly() public onlyOwner {
        timerExpires = block.timestamp;
        checkTimer();
    }

    function initiateGame() private {
        //Set a timer and start the game
        timerExpires = gameTimer.add(block.timestamp);
    }

    function checkTimer() internal {
        //if timer expired
        if (timerExpires <= block.timestamp) {
            //payout winners and start a new game
            address winner = drawWinner();
            _transfer(_lottoWallet, winner, prize);
        }

        //Reset timer and start a new match
        initiateGame();
    }

    function drawWinner() internal returns (address winner) {
        require(
            playerStack.length() > 0,
            "drawWinner: No ticket holders to pick from"
        );
        //get necessary information before continuing
        //total number of virtual valid tickets in the system
        uint256 totaltickets = sumTickets();
        //draw a random number to be processed
        //this number is from 0 to the total number of tickets issued
        uint256 winningValue = getRandomNumber(totaltickets);

        uint256 ticketsPerPlayer;
        //Step through all of the eligible accounts to determine who wins
        for (uint256 i; i < playerStack.length(); i++) {
            //fetch next ticket holder
            address playerAddress = playerStack.at(i);
            ticketsPerPlayer = getTickets(playerAddress);

            if (
                (ticketsPerPlayer > winningValue) ||
                (i + 1 == playerStack.length())
            ) {
                //player wins
                _gameWinner = playerAddress;
                return playerAddress;
            }
        }
    }

    function sumTickets() private returns (uint256) {
        uint256 totalTickets;
        uint256 val;
        for (uint256 i; i < playerStack.length(); i++) {
            val = getTickets(playerStack.at(i));
            totalTickets += val;
            if (val == 0) {
                //player has been nuked, rerun this value
                i--;
            }
        }

        return totalTickets;
    }

    function getTickets(address player) private returns (uint256) {
        //Return the number of entries for address player
        if (_balances[player] == 0) {
            //kick player from the stack and return 0
            playerStack.remove(player);
            return 0;
        } else {
            //Return ticket result for player
            uint256 tickets = _balances[player].div(_ticketPrice);
            if (tickets > _maxTickets) {
                tickets = _maxTickets;
            }
            return tickets;
        }
    }

    function addTokenHolder(address checkholder) private {
        //Currently this is only called by _transfer before the address recieves tokens
        //it will need to be updated if called elsewhere
        if (!excludedFromStack[checkholder]) {
            if (
                _balances[checkholder] >= 0 &&
                !playerStack.contains(checkholder)
            ) {
                playerStack.add(checkholder);
            }
        }
    }

    function getRandomNumber(uint256 maxValue) private view returns (uint256) {
        uint256 randomSpawn = uint256(
            keccak256(
                abi.encodePacked(block.difficulty, block.timestamp, maxValue)
            )
        );
        return randomSpawn % maxValue;
    }

    function setRouterAddress(address payable newRouter) public onlyOwner {
        //assign to state variable
        _pancakeRouterAddress = newRouter;

        //construct new swap pair
        _pancakeswapV2Router = IPancakeRouter02(_pancakeRouterAddress);
        pancakeswapV2Pair = IPancakeFactory(_pancakeswapV2Router.factory())
            .createPair(address(this), _pancakeswapV2Router.WETH());
    }

    function isInStack(address _address) external view returns (bool) {
        return playerStack.contains(_address);
    }

    receive() external payable {}

    //*****************************************************************************
    //***************************  Setters and Getters  ***************************
    //*****************************************************************************

    function modifyDistributionState(bool _flag) public onlyOwner {
        distributionState = _flag;
    }

    function modifyFees(bool _flag) public onlyOwner {
        feesActive = _flag;
    }

    function setGameTimer(uint256 newTimer) public onlyOwner {
        gameTimer = newTimer;
    }

    //*****************************************************************************
    //*********************  Contract IBEP20 Function calls  **********************
    //*****************************************************************************

    function setMarketWallet(address newWallet) public onlyOwner {
        //require(_balances[_marketWallet] == 0, "There are still funds in the current Market Wallet");
        _balances[_marketWallet] = 0;
        _marketWallet = newWallet;
        _transfer(
            _msgSender(),
            _marketWallet,
            10 * 10**uint256(12 + _decimals)
        );
        excludedFromStack[_marketWallet] = true;
    }

    function setLottoWallet(address newWallet) public onlyOwner {
        //require(_balances[_lottoWallet] == 0, "There are still funds in the current Market Wallet");
        _balances[_lottoWallet] = 0;
        _lottoWallet = newWallet;
        _transfer(_msgSender(), _lottoWallet, 20 * 10**uint256(12 + _decimals));
        excludedFromStack[_lottoWallet] = true;
    }

    function swapAndLiquify(uint256 amount) internal lockTheSwap {
        // Record the initialBalance of the token wallet
        uint256 half = amount.div(2);
        uint256 otherHalf = amount.sub(half);

        uint256 initialBalance = address(this).balance;

        // swap tokens and add BNB to contract wallet
        swapTokensForBNB(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // Determine how much BNB was added to the wallet
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // Send the other half of the tokens plus BNB to liquidity
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForBNB(uint256 amount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _pancakeswapV2Router.WETH();

        //always approve the transfer before doing it
        _approve(address(this), address(_pancakeswapV2Router), amount);

        // make the swap
        _pancakeswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                amount,
                0, // accept any amount of ETH
                path,
                address(this),
                block.timestamp
            );
    }

    //adds the liquidity as part of SwapAndLiquify
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) internal {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(_pancakeswapV2Router), tokenAmount);

        // add the liquidity
        _pancakeswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function setPancakeswapSellFee(uint256 liqFee, uint256 disFee)
        external
        onlyOwner
    {
        require((liqFee + disFee) <= 19, "Pancakeswap FEE too much");
        _pancakeSwapSellFee = (liqFee + disFee);
        _pancakeDisSellFee = disFee;
        _pancakeLiqSellFee = liqFee;
    }

    function whitelistFeeUser(address _address, bool _flag) external onlyOwner {
        whitelistFee[_address] = _flag;
    }

    function excludeFromStack(address _address, bool _flag) external onlyOwner {
        excludedFromStack[_address] = _flag;
    }

    function blacklistPair(address _pairAddress, bool _flag)
        external
        onlyOwner
    {
        blacklistedPairs[_pairAddress] = _flag;
    }

    //This function is always run before taxable transfers call to _transfer()
    function payoutFees(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        uint256 lotteryAmount = amount.mul(2).div(100);
        uint256 distributeAmount = amount.mul(2).div(100);
        uint256 liquidityAmount = amount.mul(2).div(100);
        uint256 marketAmount = amount.div(100);

        if (
            _pancakeSwapSellFee > 0 &&
            (sender != pancakeswapV2Pair && recipient == pancakeswapV2Pair)
        ) {
            distributeAmount = distributeAmount.add(
                amount.mul(_pancakeDisSellFee).div(100)
            );

            liquidityAmount = liquidityAmount.add(
                amount.mul(_pancakeLiqSellFee).div(100)
            );
        }

        if (_marketWallet != address(0))
            _transfer(sender, _marketWallet, marketAmount);
        if (_lottoWallet != address(0))
            _transfer(sender, _lottoWallet, lotteryAmount);

        // Now handle liquidity swap
        if (
            sender != pancakeswapV2Pair &&
            !inSwapAndLiquify &&
            sender != _msgSender()
        ) {
            _balances[address(this)] = _balances[address(this)].add(
                liquidityAmount
            );
            swapAndLiquify(liquidityAmount);
        }

        // Distribute to tokenHolders
        if (distributionState && playerStack.length() > 0) {
            uint256 disamount = distributeAmount.div(playerStack.length());
            for (uint256 i = 0; i < playerStack.length(); i++) {
                _transfer(sender, playerStack.at(i), disamount);
            }
        }
    }

    function airdrop(address recipient, uint256 amount) public onlyOwner {
        addTokenHolder(recipient);

        _transfer(_msgSender(), recipient, amount);
    }

    function enableTrading() external onlyOwner {
        tradeEnabled = true;
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        if (
            !whitelistFee[sender] &&
            (blacklistedPairs[sender] || blacklistedPairs[recipient])
        ) {
            require(tradeEnabled, "TRADE NOT ENABLED");
        }

        //added game functionality dependent on tokenHolders
        if (sender == pancakeswapV2Pair && amount > 0) {
            addTokenHolder(recipient);
        }

        uint256 transferFee = 0;
        //Pay fees just if the trading pair is blacklisted
        if (
            (!whitelistFee[sender] && feesActive) &&
            (blacklistedPairs[sender] || blacklistedPairs[recipient])
        ) {
            uint256 pancakeSellFee = 0;

            if (
                _pancakeSwapSellFee > 0 &&
                (sender != pancakeswapV2Pair && blacklistedPairs[recipient])
            ) {
                pancakeSellFee = _pancakeSwapSellFee;
            }

            payoutFees(sender, recipient, amount);

            transferFee = amount.mul(uint256(7).add(pancakeSellFee)).div(100);
        }

        _transfer(sender, recipient, amount.sub(transferFee));
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        //apply transfer fee to all transactions
        _balances[sender] = _balances[sender].sub(
            amount,
            "BEP20: transfer amount exceeds balance"
        );

        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    //*****************************************************************************
    //*********************  Standard IBEP20 Function calls  **********************
    //*****************************************************************************

    function getOwner() external view returns (address) {
        return owner();
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        external
        view
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        _transferStandard(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        _transferStandard(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "BEP20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function allowance(address owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "BEP20: decreased allowance below zero"
            )
        );
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}