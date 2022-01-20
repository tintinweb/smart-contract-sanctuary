// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.5;

import '@otbswap/otbswap-core/contracts/interfaces/IOTBSwapFactory.sol';
import '@otbswap/otbswap-core/contracts/interfaces/IERC20.sol';
import '@otbswap/otbswap-periphery/contracts/interfaces/IOTBSwapRouter02.sol';
import '../libraries/OrderBookStorage.sol';
import '../libraries/LibDiamond.sol';
import '../libraries/Decimal.sol';

contract OTBOrderbookSetupFacet {
    using Decimal for uint256;

    address internal immutable factory;
    address internal immutable router;
    event PairCreated(string indexed tokenA, string indexed tokenB);

    constructor(address _factory, address _router) {
        factory = _factory;
        router = _router;
    }

    /**
     * @dev Return Address of pair of contract. tokenA and tokenB order is interchangeable.
     * Input: Address for tokenA and address for tokenB
     * Output: Boolean, Returns false if no pair exists, else true if pair exists.
     */
    function hasPair(address _tokenA, address _tokenB) internal view returns (bool) {
        if (IOTBSwapFactory(factory).getPair(_tokenA, _tokenB) == address(0)) {
            return false;
        }
        return true;
    }

    /**
     * @dev Return bytes32 name of pair of coins. Usually string concatenated value of symbols of token pairs.
     * Input: Address for tokenA and address for tokenB
     * Output: bytes32 name of pair (where one exists).
     */
    function getPair(address _tokenA, address _tokenB) external view returns (bytes32) {
        return getPairInternal(_tokenA, _tokenB);
    }

    function getPairInternal(address _tokenA, address _tokenB) internal view returns (bytes32 pairName) {
        if (hasPair(_tokenA, _tokenB)) {
            pairName = bytes32(abi.encodePacked(IERC20(_tokenA).symbol(), IERC20(_tokenB).symbol()));
        }
    }

    /**
     * @dev Returns the address of the nth pair (0-indexed) created through the Factory contract.
     * Input parameter begins at 0 for first created pair.
     */
    function allPairs(uint256 _index) external view returns (address) {
        return IOTBSwapFactory(factory).allPairs(_index);
    }

    /**
     * @dev Displays the current number of pairs created on the contract.
     */
    function allPairsLength() external view returns (uint256) {
        return IOTBSwapFactory(factory).allPairsLength();
    }

    /**
     * @dev Return feeTo address for DEX Orderbook.
     * By default feeTo address is set to Owner of the contract.
     */
    function feeTo() external view returns (address) {
        OrderBookStorage.OrderBook storage ds = OrderBookStorage.orderBookStruct();
        return ds.tradeFeeTo;
    }

    /**
     * @dev Return fee that the DEX charges per trade. Fee should be equivalent to 0.20% or 0.002.
     * As it is decimal value & system supports 8 decimal points so for 0.20 it would 20000000 as output.
     */
    function fee() external view returns (uint256) {
        OrderBookStorage.OrderBook storage ds = OrderBookStorage.orderBookStruct();
        return ds.tradeFee;
    }

    /**
     * @dev This method sets feeTo address for DEX Orderbook.
     * By default feeTo address is set to Owner of the contract.
     * Only Owner is allowed to change the address to any new address.
     */
    function setFeeTo(address _newfeeTo) external {
        LibDiamond.enforceIsContractOwner();
        require(_newfeeTo != address(0x0), 'Invalid wallet address');
        OrderBookStorage.OrderBook storage ds = OrderBookStorage.orderBookStruct();
        require(ds.tradeFeeTo != _newfeeTo, 'Must be different from current fee wallet');
        ds.tradeFeeTo = _newfeeTo;
    }

    /**
     * @dev This method sets fee that the DEX charges per trade. Fee should be equivalent to 0.20% or 0.002.
     * As it is decimal value & system supports 8 decimal points so for 0.20 it would 20000000 as input.
     */
    function setFee(uint256 _newfee) external {
        LibDiamond.enforceIsContractOwner();
        OrderBookStorage.OrderBook storage ds = OrderBookStorage.orderBookStruct();
        require(ds.tradeFee != _newfee, 'Must be different from current fee percent');
        ds.tradeFee = _newfee;
    }

    /**
     * @dev This method creates a pair for token and tokenB where a pair doesn't already exist.
     * tokenB is assigned as the quote token.
     * Emits PairCreated (see Events).
     */
    function createPair(address _tradedToken, address _txToken) external returns (address pair) {
        require(!hasPair(_tradedToken, _txToken), 'Pair already exists');
        pair = IOTBSwapFactory(factory).createPair(_tradedToken, _txToken);
        bytes32 _pairName = getPairInternal(_tradedToken, _txToken);
        OrderBookStorage.OrderBook storage ds = OrderBookStorage.orderBookStruct();
        ds.buyOrders[_pairName][OrderBookStorage.ORDER_ID_OFFSET] = OrderBookStorage.ORDER_ID_OFFSET;
        ds.sellOrders[_pairName][OrderBookStorage.ORDER_ID_OFFSET] = OrderBookStorage.ORDER_ID_OFFSET;
        emit PairCreated(IERC20(_tradedToken).symbol(), IERC20(_txToken).symbol());
    }

    /**
     * @dev Returns an array of offers for each pairName in order from highest to lowest.
     * Offers has property price and volume.
     */
    function getBuyOrders(bytes32 _pairName) external view returns (OrderBookStorage.UserOrder[] memory) {
        OrderBookStorage.OrderBook storage ds = OrderBookStorage.orderBookStruct();
        OrderBookStorage.UserOrder[] memory _userorders = new OrderBookStorage.UserOrder[](ds.buyOrdersLength);
        uint256 i = 0;
        uint256 _idxOrderid = findNextOrderId(
            OrderBookStorage.OrderType.BUY,
            _pairName,
            OrderBookStorage.ORDER_ID_OFFSET
        );
        while (_idxOrderid != OrderBookStorage.ORDER_ID_OFFSET) {
            _userorders[i] = ds.userOrders[_idxOrderid - OrderBookStorage.ORDER_ID_OFFSET];
            _idxOrderid = findNextOrderId(OrderBookStorage.OrderType.BUY, _pairName, _idxOrderid);
            i++;
        }
        return _userorders;
    }

    /**
     * @dev Returns an array of offers for each pairName in order from lowest to highest.
     * Offers has property price and volume.
     */
    function getSellOrders(bytes32 _pairName) external view returns (OrderBookStorage.UserOrder[] memory) {
        OrderBookStorage.OrderBook storage ds = OrderBookStorage.orderBookStruct();
        OrderBookStorage.UserOrder[] memory _userorders = new OrderBookStorage.UserOrder[](ds.sellOrdersLength);
        uint256 i = 0;
        uint256 _idxOrderid = findNextOrderId(
            OrderBookStorage.OrderType.SELL,
            _pairName,
            OrderBookStorage.ORDER_ID_OFFSET
        );
        while (_idxOrderid != OrderBookStorage.ORDER_ID_OFFSET) {
            _userorders[i] = ds.userOrders[_idxOrderid - OrderBookStorage.ORDER_ID_OFFSET];
            _idxOrderid = findNextOrderId(OrderBookStorage.OrderType.SELL, _pairName, _idxOrderid);
            i++;
        }
        return _userorders;
    }

    /**
     * @dev Returns an array of UserOrders. User orders are the current open orders that user has for that pair.
     * Offers has property price and volume.
     */
    function getUserOrders(bytes32 _pairName) public view returns (OrderBookStorage.UserOrder[] memory) {
        OrderBookStorage.OrderBook storage ds = OrderBookStorage.orderBookStruct();

        OrderBookStorage.UserOrder[] memory _userorders = new OrderBookStorage.UserOrder[](
            ds.sellOrdersLength + ds.buyOrdersLength
        );
        uint256 i = 0;
        uint256 _idxOrderid = findNextOrderId(
            OrderBookStorage.OrderType.BUY,
            _pairName,
            OrderBookStorage.ORDER_ID_OFFSET
        );
        while (_idxOrderid != OrderBookStorage.ORDER_ID_OFFSET) {
            _userorders[i] = ds.userOrders[_idxOrderid - OrderBookStorage.ORDER_ID_OFFSET];
            _idxOrderid = findNextOrderId(OrderBookStorage.OrderType.BUY, _pairName, _idxOrderid);
            i++;
        }
        _idxOrderid = findNextOrderId(OrderBookStorage.OrderType.SELL, _pairName, OrderBookStorage.ORDER_ID_OFFSET);
        while (_idxOrderid != OrderBookStorage.ORDER_ID_OFFSET) {
            _userorders[i] = ds.userOrders[_idxOrderid - OrderBookStorage.ORDER_ID_OFFSET];
            _idxOrderid = findNextOrderId(OrderBookStorage.OrderType.SELL, _pairName, _idxOrderid);
            i++;
        }
        return _userorders;
    }

    /**
     * @dev Returns an array of UserOrders. User orders are the current open orders for a specific user for given pair.
     * Offers has property price and volume.
     */
    function getUserOrders(address _user, bytes32 _pairName)
        external
        view
        returns (OrderBookStorage.UserOrder[] memory)
    {
        OrderBookStorage.UserOrder[] memory _allOpenOrders = getUserOrders(_pairName);
        uint256 count = 0;
        if (_allOpenOrders.length == 0) return _allOpenOrders;
        OrderBookStorage.UserOrder[] memory _allOpenOrdersForUser = new OrderBookStorage.UserOrder[](
            _allOpenOrders.length
        );
        for (uint256 i = 0; i < _allOpenOrders.length; i++) {
            if (_allOpenOrders[i].user == _user) {
                _allOpenOrdersForUser[count] = _allOpenOrders[i];
                count++;
            } else {
                assembly {
                    mstore(_allOpenOrdersForUser, sub(mload(_allOpenOrdersForUser), 1))
                }
            }
        }
        return _allOpenOrdersForUser;
    }

    function findNextOrderId(
        OrderBookStorage.OrderType _orderType,
        bytes32 _pairName,
        uint256 _orderId
    ) internal view returns (uint256 nextOrderId) {
        OrderBookStorage.OrderBook storage ds = OrderBookStorage.orderBookStruct();
        if (_orderType == OrderBookStorage.OrderType.BUY) {
            nextOrderId = ds.buyOrders[_pairName][_orderId];
        }
        if (_orderType == OrderBookStorage.OrderType.SELL) {
            nextOrderId = ds.sellOrders[_pairName][_orderId];
        }
    }

    function addToTokenBalance(address user, address tokenAddress, uint256 amount) internal {
        OrderBookStorage.OrderBook storage ds = OrderBookStorage.orderBookStruct();
        uint256 userBal = ds.userBalances[user][tokenAddress];
        require(userBal + amount >= userBal, 'Amount must be positive. ');
        ds.userBalances[user][tokenAddress] += amount;
    }

    function minusFromTokenBalance(address user, address tokenAddress, uint256 amount) internal {
        OrderBookStorage.OrderBook storage ds = OrderBookStorage.orderBookStruct();
        uint256 userBal = ds.userBalances[user][tokenAddress];
        require(userBal - amount <= userBal, 'Amount must be positive. ');
        require(userBal - amount >= 0, 'Insufficient balance. ');
        ds.userBalances[user][tokenAddress] -= amount;
    }

    /**
     * @dev This method deposits a specified amount to the specified ERC20 token to the contract.
     * tokenAddress is the specified token
     *
     */
    function depositERC20(uint256 amount, address tokenAddress) external {
        require(IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount), 'Deposit failed. ');
        addToTokenBalance(msg.sender, tokenAddress, amount);
    }

    /**
     * @dev This method withdraws a specified ERC20 token amount to the user from the contract.
     * tokenAddress is the specified token
     *
     */
    function withdrawERC20(uint256 amount, address tokenAddress) external {
        require(IERC20(tokenAddress).transfer(msg.sender, amount), 'Withdraw failed. ');
        minusFromTokenBalance(msg.sender, tokenAddress, amount);
    }

    /**
     * @dev This method deposits ETH to the contract.
     *
     */
    function depositETH() external payable {
        addToTokenBalance(msg.sender, IOTBSwapRouter02(router).WETH(), msg.value);
    }

    /**
     * @dev This method withdraws ETH amount to the user from the contract.
     *
     */
    function withdrawETH(uint256 amount) external {
        payable(msg.sender).transfer(amount);
        minusFromTokenBalance(msg.sender, IOTBSwapRouter02(router).WETH(), amount);
    }

    /**
     * @dev This method shows the user's ERC20 token balances
     *
     */
    function getTokenBalance(address user, address tokenAddress) external view returns (uint256) {
        OrderBookStorage.OrderBook storage ds = OrderBookStorage.orderBookStruct();
        uint256 userBal = ds.userBalances[user][tokenAddress];
        return userBal;
    }
}

pragma solidity >=0.6.2;

import './IOTBSwapRouter01.sol';

interface IOTBSwapRouter02 is IOTBSwapRouter01 {
    /*function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    */
}

pragma solidity >=0.6.2;

interface IOTBSwapRouter01 {
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
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.5.0;

interface IOTBSwapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.5;

library OrderBookStorage {
    enum OrderType{BUY, SELL}
    enum OrderStatus{COMPLETED, PENDING, CANCELLED}
    enum MatchStatus{FULL, PARTIAL, NO}
    uint constant internal ORDER_ID_OFFSET = 1000;

    struct UserOrder {
        uint orderId;
        uint amount;
        uint amountFulfilled;
        uint price;
        bytes32 pairName;
        address[] path;
        uint maxFee;
        OrderType orderType;
        address user;
        OrderStatus orderStatus;
        uint timestamp;
        uint8 isMarketMaker;
        uint8 isMarketTaker;
    }

    struct OrderBook {
        //User Orders Array containing both Buy & Sell orders
        UserOrder[] userOrders;
        //Map containing pair name => mapping of UserOrder pointer to the next UserOrder pointer in sorted order
        mapping(bytes32 => mapping(uint => uint)) buyOrders;
        uint buyOrdersLength;
        //Map containing pair name => mapping of UserOrder pointer to the next UserOrder pointer in sorted order
        mapping(bytes32 => mapping(uint => uint)) sellOrders;
        uint sellOrdersLength;
        uint tradeFee;
        address tradeFeeTo;
        // balance of user for each token. 
        mapping(address => mapping(address => uint256)) userBalances;
    }

    // Returns the struct from a specified position in contract storage
    // ds is short for DiamondStorage
    function orderBookStruct() internal pure returns(OrderBook storage ds) {
        // Specifies a random position from a hash of a string
        bytes32 storagePosition = keccak256("OrderBook.storage.OrderBookStorage");
        // Set the position of our struct in contract storage
        assembly {
            ds.slot := storagePosition
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.5;

import "../interfaces/IDiamondCut.sol";

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.otborderbook.storage");

    struct DiamondStorage {
        // maps function selectors to the facets that execute the functions.
        // and maps the selectors to their position in the selectorSlots array.
        // func selector => address facet, selector position
        mapping(bytes4 => bytes32) facets;
        // array of slots of function selectors.
        // each slot holds 8 function selectors.
        mapping(uint256 => bytes32) selectorSlots;
        // The number of function selectors in selectorSlots
        uint16 selectorCount;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    bytes32 constant CLEAR_ADDRESS_MASK = bytes32(uint256(0xffffffffffffffffffffffff));
    bytes32 constant CLEAR_SELECTOR_MASK = bytes32(uint256(0xffffffff << 224));

    // Internal function version of diamondCut
    // This code is almost the same as the external diamondCut,
    // except it is using 'Facet[] memory _diamondCut' instead of
    // 'Facet[] calldata _diamondCut'.
    // The code is duplicated to prevent copying calldata to memory which
    // causes an error for a two dimensional array.
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        DiamondStorage storage ds = diamondStorage();
        uint256 originalSelectorCount = ds.selectorCount;
        uint256 selectorCount = originalSelectorCount;
        bytes32 selectorSlot;
        // Check if last selector slot is not full
        if (selectorCount & 7 > 0) {
            // get last selectorSlot
            selectorSlot = ds.selectorSlots[selectorCount >> 3];
        }
        // loop through diamond cut
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            (selectorCount, selectorSlot) = addReplaceRemoveFacetSelectors(
                selectorCount,
                selectorSlot,
                _diamondCut[facetIndex].facetAddress,
                _diamondCut[facetIndex].action,
                _diamondCut[facetIndex].functionSelectors
            );
        }
        if (selectorCount != originalSelectorCount) {
            ds.selectorCount = uint16(selectorCount);
        }
        // If last selector slot is not full
        if (selectorCount & 7 > 0) {
            ds.selectorSlots[selectorCount >> 3] = selectorSlot;
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addReplaceRemoveFacetSelectors(
        uint256 _selectorCount,
        bytes32 _selectorSlot,
        address _newFacetAddress,
        IDiamondCut.FacetCutAction _action,
        bytes4[] memory _selectors
    ) internal returns (uint256, bytes32) {
        DiamondStorage storage ds = diamondStorage();
        require(_selectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        if (_action == IDiamondCut.FacetCutAction.Add) {
            enforceHasContractCode(_newFacetAddress, "LibDiamondCut: Add facet has no code");
            for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {
                bytes4 selector = _selectors[selectorIndex];
                bytes32 oldFacet = ds.facets[selector];
                require(address(bytes20(oldFacet)) == address(0), "LibDiamondCut: Can't add function that already exists");
                // add facet for selector
                ds.facets[selector] = bytes20(_newFacetAddress) | bytes32(_selectorCount);
                uint256 selectorInSlotPosition = (_selectorCount & 7) << 5;
                // clear selector position in slot and add selector
                _selectorSlot = (_selectorSlot & ~(CLEAR_SELECTOR_MASK >> selectorInSlotPosition)) | (bytes32(selector) >> selectorInSlotPosition);
                // if slot is full then write it to storage
                if (selectorInSlotPosition == 224) {
                    ds.selectorSlots[_selectorCount >> 3] = _selectorSlot;
                    _selectorSlot = 0;
                }
                _selectorCount++;
            }
        } else if (_action == IDiamondCut.FacetCutAction.Replace) {
            enforceHasContractCode(_newFacetAddress, "LibDiamondCut: Replace facet has no code");
            for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {
                bytes4 selector = _selectors[selectorIndex];
                bytes32 oldFacet = ds.facets[selector];
                address oldFacetAddress = address(bytes20(oldFacet));
                // only useful if immutable functions exist
                require(oldFacetAddress != address(this), "LibDiamondCut: Can't replace immutable function");
                require(oldFacetAddress != _newFacetAddress, "LibDiamondCut: Can't replace function with same function");
                require(oldFacetAddress != address(0), "LibDiamondCut: Can't replace function that doesn't exist");
                // replace old facet address
                ds.facets[selector] = (oldFacet & CLEAR_ADDRESS_MASK) | bytes20(_newFacetAddress);
            }
        } else if (_action == IDiamondCut.FacetCutAction.Remove) {
            require(_newFacetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
            uint256 selectorSlotCount = _selectorCount >> 3;
            uint256 selectorInSlotIndex = _selectorCount & 7;
            for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {
                if (_selectorSlot == 0) {
                    // get last selectorSlot
                    selectorSlotCount--;
                    _selectorSlot = ds.selectorSlots[selectorSlotCount];
                    selectorInSlotIndex = 7;
                } else {
                    selectorInSlotIndex--;
                }
                bytes4 lastSelector;
                uint256 oldSelectorsSlotCount;
                uint256 oldSelectorInSlotPosition;
                // adding a block here prevents stack too deep error
                {
                    bytes4 selector = _selectors[selectorIndex];
                    bytes32 oldFacet = ds.facets[selector];
                    require(address(bytes20(oldFacet)) != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
                    // only useful if immutable functions exist
                    require(address(bytes20(oldFacet)) != address(this), "LibDiamondCut: Can't remove immutable function");
                    // replace selector with last selector in ds.facets
                    // gets the last selector
                    lastSelector = bytes4(_selectorSlot << (selectorInSlotIndex << 5));
                    if (lastSelector != selector) {
                        // update last selector slot position info
                        ds.facets[lastSelector] = (oldFacet & CLEAR_ADDRESS_MASK) | bytes20(ds.facets[lastSelector]);
                    }
                    delete ds.facets[selector];
                    uint256 oldSelectorCount = uint16(uint256(oldFacet));
                    oldSelectorsSlotCount = oldSelectorCount >> 3;
                    oldSelectorInSlotPosition = (oldSelectorCount & 7) << 5;
                }
                if (oldSelectorsSlotCount != selectorSlotCount) {
                    bytes32 oldSelectorSlot = ds.selectorSlots[oldSelectorsSlotCount];
                    // clears the selector we are deleting and puts the last selector in its place.
                    oldSelectorSlot =
                        (oldSelectorSlot & ~(CLEAR_SELECTOR_MASK >> oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                    // update storage with the modified slot
                    ds.selectorSlots[oldSelectorsSlotCount] = oldSelectorSlot;
                } else {
                    // clears the selector we are deleting and puts the last selector in its place.
                    _selectorSlot =
                        (_selectorSlot & ~(CLEAR_SELECTOR_MASK >> oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                }
                if (selectorInSlotIndex == 0) {
                    delete ds.selectorSlots[selectorSlotCount];
                    _selectorSlot = 0;
                }
            }
            _selectorCount = selectorSlotCount * 8 + selectorInSlotIndex;
        } else {
            revert("LibDiamondCut: Incorrect FacetCutAction");
        }
        return (_selectorCount, _selectorSlot);
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

import './SafeMath.sol';

library Decimal {
    using SafeMath for uint;
    uint8 public constant decimals = 18;
    /**
     * @dev This method represents number of digits after decimal point supported
     */
    function multiplier() internal pure returns(uint) {
        return 10**decimals;
    }
    /**
     * @dev This method returns integer part of solidity decimal
     */
    function integer(uint _value) internal pure returns (uint) {
        return (_value / multiplier()) * multiplier(); // Can't overflow
    }
    /**
     * @dev This method returns fractional part of solidity decimal
     */
    function fractional(uint _value) internal pure returns (uint) {
        return _value.sub(integer(_value));
    }
    /**
     * @dev This method separates out solidity decimal to integral & fraction parts
     */
    function decimalFrom(uint _value) internal pure returns(uint, uint) {
        return ((_value / multiplier()), fractional(_value));
    }
    /**
     * @dev This method converts integral & fraction parts into solidity decimal
     */
    function decimalTo(uint _integral, uint _fractional) public pure returns(uint) {
        //return _integral.mul(multiplier()).add(_fractional.mul(multiplier()) / calculateFractionMultiplier(_fractional));
        return _integral.mul(multiplier()).add(_fractional);
    }

    function calculateFractionMultiplier(uint number) internal pure returns(uint) {
        uint fractionMultiplier = 1;
        while (number != 0) {
            number /= 10;
            fractionMultiplier = fractionMultiplier.mul(10);
        }
        return fractionMultiplier;
    }
    /**
     * @dev This method adds solidity decimal with integer value
     */
    function uintAddition(uint _value, uint x) internal pure returns(uint) {
        return _value.add(x.mul(multiplier()));
    }
    /**
     * @dev This method adds solidity decimal with solidity decimal
     * Assumption both the decimals conatains same decimal multiplier
     */
    function decimalAddition(uint _value, uint x) internal pure returns(uint) {
        return _value.add(x);
    }
    /**
     * @dev This method adds solidity decimal with integer value
     */
    function uintSubtraction(uint _value, uint x) internal pure returns(uint) {
        return _value.sub(x.mul(multiplier()));
    }
    /**
     * @dev This method adds solidity decimal with solidity decimal
     * Assumption both the decimals conatains same decimal multiplier
     */
    function decimalSubtraction(uint _value, uint x) internal pure returns(uint) {
        return _value.sub(x);
    }
    /**
     * @dev This method multiplies solidity decimal with integer value
     */
    function uintMultiply(uint _value, uint x) internal pure returns(uint) {
        return _value.mul(x);
    }
    /**
     * @dev This method multiplies solidity decimal with solidity decimal
     * Assumption both the decimals conatains same decimal multiplier
     */
    function decimalMultiply(uint _value, uint y) internal pure returns (uint) {
        if (_value == 0 || y == 0) return 0;

        // Separate into integer and fractional parts
        // x = x1 + x2, y = y1 + y2
        uint x1 = integer(_value);
        uint x2 = fractional(_value);
        uint y1 = integer(y);
        uint y2 = fractional(y);

        // (x1 + x2) * (y1 + y2) = (x1 * y1) + (x1 * y2) + (x2 * y1) + (x2 * y2)
        uint x1y1 = x1.mul(y1);
        uint x2y1 = x2.mul(y1);
        uint x1y2 = x1.mul(y2);
        uint x2y2 = x2.mul(y2);

        return (x1y1.add(x2y1).add(x1y2).add(x2y2)) / multiplier();
    }

    function reciprocal(uint x) internal pure returns (uint) {
        assert(x != 0);
        return multiplier() * multiplier() / x;
    }
    /**
     * @dev This method divides solidity decimal with solidity decimal
     * Assumption both the decimals conatains same decimal multiplier
     */
    function decimalDivide(uint _value, uint y) internal pure returns (uint) {
        assert(y != 0);
        return decimalMultiply(_value, reciprocal(y));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.5;

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}