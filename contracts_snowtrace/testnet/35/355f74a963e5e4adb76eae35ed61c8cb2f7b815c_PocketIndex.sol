/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-15
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

// pragma solidity >=0.6.2;

interface ITraderJoeRouter01 {
    function factory() external pure returns (address);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

interface ITraderJoeRouter02 is ITraderJoeRouter01 {
}

// pragma solidity >=0.5.0;

interface ITraderJoeFactory {
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

interface IERC20Extended {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
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
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

contract PocketIndex {
    using SafeMath for uint256;

    address routerAddress;
    IERC20Extended public baseTokenAddress;
    address owner;
    ITraderJoeRouter02 router;
    
    uint256 public lastBuyTime;
    uint256 public managementFee;
    uint256 public performanceFee;
    uint256 public totalBulkBuys;

    event NewAssetAdded(address contractAddress, uint256 timestamp);
    
    struct Asset {
        address contractAddress; // asset address
        uint256 balance; // current total balance
    }

    struct UserBalance {
        uint256 usdtBalance;
        mapping (address => uint256) balances;
    }

    mapping (address => UserBalance) userBalances;

    Asset[] assets;
    address[] nextBuyers;
    
    constructor() {
        routerAddress = 0x7E3411B04766089cFaa52DB688855356A12f05D1;
        baseTokenAddress = IERC20Extended(0x08a978a0399465621e667C49CD54CC874DC064Eb);
        router = ITraderJoeRouter02(routerAddress);
        owner = msg.sender;
        addAsset(0x2542250239e4800B89e47A813cD2B478822b2385);
        addAsset(0xaA4a71E82dB082b9B16d4df90b0443D83941BEC4);
        addAsset(0xeFf581Ca1f9B49F49A183cD4f25F69776FA0EbF4);
        addAsset(0xD38a71E2021105fB8eFF71378B5f74abA8C4738F);
        addAsset(0x5C9796c4BcDc48B935421661002d7f3e9E3b822a);
        addAsset(0x299D57d6f674814893B8b34EB635e3add5Fab1F7);
        addAsset(0xf672c3cDD3C143C05Aada34f50d4ad519558994F);
        addAsset(0xEdDEB2ff49830f3aa30Fee2F7FaBC5136845304a);
        totalBulkBuys = 0;
        performanceFee = 1;
        managementFee = 1;
    }

    // Add to asset array
    function addAsset(address _contractAddress) public {
        assets.push(Asset(_contractAddress, 0));
        emit NewAssetAdded(_contractAddress, block.timestamp);
    }

    // Get current asset array
    function getAllAssets() public view returns (Asset[] memory) {
        return assets;
    }

    // Bulk buy function that buys for everyone who pitched in money
    function bulkBuy() public {
        // Should only be interacted with by the owner
        require(msg.sender == owner, "Can't be interacted");

        // Must have some usdts
        require(baseTokenAddress.balanceOf(address(this)) > 0, "Don't have anything");
        
        // Approve balance to router
        baseTokenAddress.approve(routerAddress, baseTokenAddress.balanceOf(address(this)));

        // Divide total balance into 10
        uint256 equalBalance = baseTokenAddress.balanceOf(address(this)).mul(10).div(100);

        // Set current time
        lastBuyTime = block.timestamp;

        // Note current balances of all assets

        uint256[] memory currentBalances = new uint256[](assets.length);
        uint totalAssets = assets.length;

        for (uint j = 0; j < totalAssets; j++) {
            // Get the amount of tokens the contract has
            currentBalances[j] = IERC20Extended(assets[j].contractAddress).balanceOf(address(this));
        }
        
        // Loop and buy each asset
        for (uint i = 0; i < totalAssets; i++) {
            address[] memory path = new address[](2);
            path[1] = assets[i].contractAddress;
            path[0] = address(baseTokenAddress);
            router.swapExactTokensForTokens(
                equalBalance,
                0,
                path,
                address(this),
                block.timestamp
            );
        }

        // Loop and buy each asset for each user
        uint totalBuyers = nextBuyers.length;

        // Each buyer
        for (uint i = 0; i < totalBuyers; i++) {
            // Each asset
            for (uint j = 0; j < totalAssets; j++) {
                // Get the amount of tokens the user has
                uint256 assetBalanceOfContract = IERC20Extended(assets[j].contractAddress).balanceOf(address(this)).sub(currentBalances[j]);

                userBalances[nextBuyers[i]].balances[assets[j].contractAddress] += assetBalanceOfContract.mul(userBalances[nextBuyers[i]].usdtBalance).div(100);
            }
            // Empty usdt balance
            userBalances[nextBuyers[i]].usdtBalance = 0;
        }

        // Empty next buyers array
        nextBuyers = new address[](0);

        // Add to total buys
        totalBulkBuys++;
    }

    // Sell a user's balance and give him back his usdts
    function disolvePosition() public {
        require(msg.sender == owner, "Can't be interacted");
        uint256 balanceBeforeSell = baseTokenAddress.balanceOf(address(this));

        uint totalAssets = assets.length;
        
        // Loop and sell each asset
        for (uint i = 0; i < totalAssets; i++) {
            address[] memory path = new address[](2);
            path[0] = assets[i].contractAddress;
            path[1] = address(baseTokenAddress);
            uint256 userBalance = userBalances[msg.sender].balances[assets[i].contractAddress];
            router.swapExactTokensForTokens(
                userBalance,
                0,
                path,
                address(this),
                block.timestamp
            );
        }

        uint256 userUSDTBalance = baseTokenAddress.balanceOf(address(this)).sub(balanceBeforeSell);
        uint256 _managementFee = userUSDTBalance.mul(managementFee).div(1000);
        uint256 _performanceFee = userUSDTBalance.mul(performanceFee).div(1000);
        baseTokenAddress.transfer(msg.sender, userUSDTBalance.sub(_managementFee).sub(_performanceFee));

        // Loop and set asset balances to 0
        for (uint i = 0; i < totalAssets; i++) {
            userBalances[msg.sender].balances[assets[i].contractAddress] = 0;
        }
    }

    // New user pitches amount to bulk buy
    function pitchAmount(uint256 amount) public {
        require(baseTokenAddress.balanceOf(msg.sender) >= amount, "Don't have enough amount in e.USDT");
        
        // Transfer the amount to the smart contract
        baseTokenAddress.transferFrom(msg.sender, address(this), amount);

        // Increment user USDT balance
        userBalances[msg.sender].usdtBalance += amount;

        // Add to next buyers array
        if (!buyerAlreadyAdded(msg.sender)) {
            nextBuyers.push(msg.sender);
        }
    }

    // Get user's USDT balance
    function getUSDTBalance(address user) public view returns (uint256) {
        return userBalances[user].usdtBalance;
    }

    // Withdraw from user's USDT balance
    function withdrawUSDTBalance(address user, uint256 amount) public {
        require (userBalances[user].usdtBalance > 0, "Don't have anything to withdraw");
        require (amount >= userBalances[user].usdtBalance, "Don't have enough amount to withdraw");
        baseTokenAddress.transfer(user, amount);
    }

    // Get user's balance for all assets
    function getBalances(address user) public view returns (uint256[] memory) {
        uint totalAssets = assets.length;
        uint256[] memory balances = new uint256[](totalAssets);
        for (uint j = 0; j < totalAssets; j++) {
            balances[j] = userBalances[address(user)].balances[assets[j].contractAddress];
        }
        return balances;
    }

    // Get user's balance for a specific asset
    function getBalance(address user, address _contractAddress) public view returns (uint256) {
        return userBalances[address(user)].balances[_contractAddress];
    }

    // Get last buy time
    function getLastBuyTime() public view returns (uint256) {
        return lastBuyTime;
    }

    // Get next buyers array
    function getNextBuyers() public view returns (address[] memory) {
        return nextBuyers;
    }

    // Get total amount of assets
    function getTotalAssets() public view returns (uint) {
        return assets.length;
    }

    // Get total amount of assets
    function getTotalBuyers() public view returns (uint) {
        return nextBuyers.length;
    }

    // Get total amount invested in a specific asset
    function getTotalInvestedForAsset(address _contractAddress) public view returns (uint256) {
        return IERC20Extended(_contractAddress).balanceOf(address(this));
    }

    // PRIVATE FUNCTIONS

    // See if user is already added to nextBuyers array
    function buyerAlreadyAdded (address buyer) internal view returns (bool) {
        uint totalBuyers = nextBuyers.length;
        for (uint i = 0; i < totalBuyers; i++) {
            if (nextBuyers[i] == buyer) {
                return true;
            }
        }
        return false;
    }
}