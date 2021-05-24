// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

interface IMarsBaseOtc {
    enum OrderTypeInfo {error, buyType, sellType}

    struct OrderInfo {
        address owner;
        address token;
        uint256 amountOfToken;
        uint256 expirationDate;
        uint16 discount; // 10 is 1%, max value 1'000
        bool isCancelled;
        bool isSwapped;
        bool isManual;
        OrderTypeInfo orderType;
    }
    struct OrdersBidInfo {
        address investor;
        address investedToken;
        uint256 amountInvested;
    }
    struct BrokerInfo {
        address broker;
        uint256 percents;
    }

    function createOrder(
        bytes32 _id,
        address _token,
        uint256 _amountOfToken,
        uint256 _expirationDate,
        address _ownerBroker,
        uint256 _ownerBrokerPerc,
        address _usersBroker,
        uint256 _usersBrokerPerc,
        uint16 _discount,
        OrderTypeInfo orderType,
        bool _isManual
    ) external;

    function orderDeposit(
        bytes32 _id,
        address _token,
        uint256 _amount
    ) external payable;

    function cancel(bytes32 _id) external;

    function makeSwap(bytes32 _id, OrdersBidInfo[] memory distribution)
        external;

    function makeSwapOrderOwner(bytes32 _id, uint256 orderIndex) external;

    function cancelBid(bytes32 _id, uint256 bidIndex) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "openzeppelin-solidity/contracts/utils/ReentrancyGuard.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

import "./IMarsBaseOtc.sol";
import "./Vault.sol";

contract MarsBaseOtc is Ownable, IMarsBaseOtc, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeMath for uint16;
    using SafeMath for uint8;

    uint256 public constant BROKERS_DENOMINATOR = 10000;

    Vault public vault;

    // public mappings
    // White list of liquidity tokens
    mapping(address => bool) public isAddressInWhiteList;
    // Info about bids
    mapping(bytes32 => OrderInfo) public orders;
    mapping(bytes32 => BrokerInfo) public ownerBroker;
    mapping(bytes32 => BrokerInfo) public usersBroker;
    mapping(bytes32 => OrdersBidInfo[]) public ordersBid;
    mapping(bytes32 => OrdersBidInfo[]) public ordersOwnerBid;

    // modifiers
    modifier onlyWhenVaultDefined() {
        require(
            address(vault) != address(0),
            "101"
        );
        _;
    }
    modifier onlyWhenOrderExists(bytes32 _id) {
        require(
            orders[_id].owner != address(0),
            "102"
        );
        _;
    }
    modifier onlyOrderOwner(bytes32 _id) {
        require(
            orders[_id].owner == _msgSender(),
            "103"
        );
        _;
    }

    event OrderCreated(
        bytes32 id,
        address owner,
        address token,
        uint256 amountOfToken,
        uint256 expiratinDate,
        uint16 discount,
        OrderTypeInfo typeOrder,
        bool isManual
    );

    event BuyOrderDeposit(
        bytes32 _id,
        address _token,
        address _from,
        uint256 _amount
    );

    event SellOrderDeposit(
        bytes32 _id,
        address _token,
        address _from,
        uint256 _amount
    );

    event OrderSwapped(bytes32 id);

    event OrderCancelled(bytes32 id);

    constructor() {}

    function tokenFallback(
        address,
        uint256,
        bytes calldata
    ) external {}

    function createOrder(
        bytes32 _id,
        address _token,
        uint256 _amountOfToken,
        uint256 _expirationDate,
        address _ownerBroker,
        uint256 _ownerBrokerPerc,
        address _usersBroker,
        uint256 _usersBrokerPerc,
        uint16 _discount,
        OrderTypeInfo typeOrder,
        bool _isManual
    ) external override nonReentrant onlyWhenVaultDefined {
        require(
            orders[_id].owner == address(0),
            "201"
        );
        require(_amountOfToken > 0, "202");
        require(_discount < 1000, "203");
        require(
            typeOrder != OrderTypeInfo.error,
            "204"
        );
        require(
            _expirationDate > block.timestamp,
            "205"
        );

        orders[_id].owner = msg.sender;
        orders[_id].token = _token;
        orders[_id].amountOfToken = _amountOfToken;
        orders[_id].expirationDate = _expirationDate;
        orders[_id].discount = _discount;
        orders[_id].orderType = typeOrder;
        orders[_id].isManual = _isManual;

        if (_ownerBroker != address(0)) {
            require(
                _ownerBrokerPerc > 0 && _ownerBrokerPerc < BROKERS_DENOMINATOR,
                "206"
            );
            ownerBroker[_id].broker = _ownerBroker;
            ownerBroker[_id].percents = _ownerBrokerPerc;
        }

        if (_usersBroker != address(0)) {
            require(
                _usersBrokerPerc > 0 && _usersBrokerPerc < BROKERS_DENOMINATOR,
                "207"
            );
            usersBroker[_id].broker = _usersBroker;
            usersBroker[_id].percents = _usersBrokerPerc;
        }

        emit OrderCreated(
            _id,
            msg.sender,
            _token,
            _amountOfToken,
            _expirationDate,
            _discount,
            typeOrder,
            _isManual
        );
    }

    function orderDeposit(
        bytes32 _id,
        address _token,
        uint256 _amount
    )
        external
        payable
        override
        nonReentrant
        onlyWhenVaultDefined
        onlyWhenOrderExists(_id)
    {
        require(
            orders[_id].isCancelled == false,
            "301"
        );
        require(
            orders[_id].isSwapped == false,
            "302"
        );
        require(
            block.timestamp <= orders[_id].expirationDate,
            "303"
        );
        if (_token == address(0)) {
            require(
                msg.value == _amount,
                "304"
            );
            address(vault).transfer(msg.value);
        } else {
            require(msg.value == 0, "305");
            uint256 allowance =
                IERC20(_token).allowance(msg.sender, address(this));
            require(
                _amount <= allowance,
                "306"
            );
            require(
                IERC20(_token).transferFrom(
                    msg.sender,
                    address(vault),
                    _amount
                ),
                "307"
            );
        }
        if (orders[_id].orderType == OrderTypeInfo.buyType)
            _buyOrderDeposit(_id, _token, msg.sender, _amount);
        else if (orders[_id].orderType == OrderTypeInfo.sellType)
            _sellOrderDeposit(_id, _token, msg.sender, _amount);
    }

    function cancel(bytes32 _id)
        external
        override
        nonReentrant
        onlyWhenVaultDefined
        onlyWhenOrderExists(_id)
    {
        require(
            orders[_id].isCancelled == false,
            "401"
        );
        require(
            orders[_id].isSwapped == false,
            "402"
        );

        address caller = _msgSender();
        require(
            caller == orders[_id].owner || caller == owner(),
            "403"
        );

        _cancel(_id);

        emit OrderCancelled(_id);
    }

    function makeSwap(bytes32 _id, OrdersBidInfo[] memory distribution)
        external
        override
        nonReentrant
        onlyOwner
        onlyWhenVaultDefined
        onlyWhenOrderExists(_id)
    {
        OrderInfo memory order = orders[_id];
        orders[_id].isSwapped = true;
        require(
            order.isCancelled == false,
            "501"
        );
        require(
            order.isSwapped == false,
            "502"
        );
        require(order.isManual == false, "503");
        require(
            block.timestamp <= order.expirationDate,
            "504"
        );
        require(distribution.length > 0, "505");

        address[] memory ownerTokensInvested;
        uint256[] memory ownerAmountsInvested;
        (ownerTokensInvested, ownerAmountsInvested) = getOrderOwnerInvestments(
            _id
        );

        address[] memory usersTokensInvested;
        uint256[] memory usersAmountsInvested;
        (usersTokensInvested, usersAmountsInvested) = getOrderUserInvestments(
            _id,
            address(0)
        );
        require(
            usersTokensInvested.length > 0,
            "506"
        );
        require(
            ownerTokensInvested.length > 0,
            "507"
        );

        address[] memory orderInvestors = getInvestors(_id);

        uint256 i;
        uint256 ind;
        BrokerInfo memory brInfo;
        uint256 toBroker;
        uint256 toUser;
        for (i = 0; i < distribution.length; i = i.add(1)) {
            if (distribution[i].amountInvested == 0) continue;
            if (distribution[i].investor != order.owner) {
                ind = _findAddress(
                    orderInvestors,
                    distribution[i].investor,
                    orderInvestors.length
                );
                require(
                    ind < orderInvestors.length,
                    "508"
                );
                brInfo = usersBroker[_id];
            } else {
                brInfo = ownerBroker[_id];
            }
            ind = _findAddress(
                ownerTokensInvested,
                distribution[i].investedToken,
                ownerTokensInvested.length
            );
            if (ind >= ownerTokensInvested.length) {
                ind = _findAddress(
                    usersTokensInvested,
                    distribution[i].investedToken,
                    usersTokensInvested.length
                );
                require(
                    ind < usersTokensInvested.length,
                    "509"
                );
                require(
                    usersAmountsInvested[ind] >= distribution[i].amountInvested,
                    "510"
                );
                usersAmountsInvested[ind] = usersAmountsInvested[ind].sub(
                    distribution[i].amountInvested
                );
            } else {
                require(
                    ownerAmountsInvested[ind] >= distribution[i].amountInvested,
                    "511"
                );
                ownerAmountsInvested[ind] = ownerAmountsInvested[ind].sub(
                    distribution[i].amountInvested
                );
            }
            (toBroker, toUser) = _calculateToBrokerToUser(
                distribution[i].amountInvested,
                brInfo.percents
            );
            vault.withdrawForTwo(
                distribution[i].investedToken,
                distribution[i].investor,
                toUser,
                brInfo.broker,
                toBroker
            );
        }

        brInfo = ownerBroker[_id];
        for (i = 0; i < usersTokensInvested.length; i = i.add(1)) {
            if (usersAmountsInvested[i] == 0) continue;
            (toBroker, toUser) = _calculateToBrokerToUser(
                usersAmountsInvested[i],
                brInfo.percents
            );
            vault.withdrawForTwo(
                usersTokensInvested[i],
                brInfo.broker,
                toBroker,
                order.owner,
                toUser
            );
            usersAmountsInvested[i] = 0;
        }

        for (i = 0; i < ownerTokensInvested.length; i = i.add(1)) {
            require(
                ownerAmountsInvested[i] == 0,
                "512"
            );
        }
        for (i = 0; i < usersTokensInvested.length; i = i.add(1)) {
            require(
                usersAmountsInvested[i] == 0,
                "513"
            );
        }

        emit OrderSwapped(_id);
    }

    function makeSwapOrderOwner(bytes32 _id, uint256 orderIndex)
        external
        override
        nonReentrant
        onlyOrderOwner(_id)
        onlyWhenVaultDefined
        onlyWhenOrderExists(_id)
    {
        require(
            orders[_id].isCancelled == false,
            "601"
        );
        require(
            orders[_id].isSwapped == false,
            "602"
        );
        require(
            orders[_id].isManual == true,
            "603"
        );
        require(
            block.timestamp <= orders[_id].expirationDate,
            "604"
        );
        uint256 len = ordersBid[_id].length;
        require(len > 0, "605");
        require(orderIndex < len, "606");

        uint256 toBroker;
        uint256 toUser;
        (toBroker, toUser) = _calculateToBrokerToUser(
            ordersBid[_id][orderIndex].amountInvested,
            ownerBroker[_id].percents
        );
        vault.withdrawForTwo(
            ordersBid[_id][orderIndex].investedToken,
            orders[_id].owner,
            toUser,
            ownerBroker[_id].broker,
            toBroker
        );

        uint256 i;
        for (i = 0; i < len; i = i.add(1)) {
            if (i == orderIndex) continue;
            vault.withdraw(
                ordersBid[_id][i].investedToken,
                ordersBid[_id][i].investor,
                ordersBid[_id][i].amountInvested
            );
        }

        len = ordersOwnerBid[_id].length;
        for (i = 0; i < len; i = i.add(1)) {
            (toBroker, toUser) = _calculateToBrokerToUser(
                ordersOwnerBid[_id][i].amountInvested,
                usersBroker[_id].percents
            );
            vault.withdrawForTwo(
                ordersOwnerBid[_id][i].investedToken,
                ordersBid[_id][orderIndex].investor,
                toUser,
                usersBroker[_id].broker,
                toBroker
            );
        }

        orders[_id].isSwapped = true;

        emit OrderSwapped(_id);
    }

    function cancelBid(bytes32 _id, uint256 bidIndex)
        external
        override
        nonReentrant
        onlyWhenVaultDefined
        onlyWhenOrderExists(_id)
    {
        uint256 len;
        OrdersBidInfo memory bidRead;
        OrdersBidInfo[] storage bidArrWrite;
        address sender = _msgSender();

        if (orders[_id].owner == sender) {
            bidArrWrite = ordersOwnerBid[_id];
        } else {
            bidArrWrite = ordersBid[_id];
        }
        bidRead = bidArrWrite[bidIndex];
        len = bidArrWrite.length;

        require(bidIndex < len, "701");
        require(
            bidRead.investor == sender,
            "702"
        );
        vault.withdraw(
            bidRead.investedToken,
            bidRead.investor,
            bidRead.amountInvested
        );

        if (bidIndex < len - 1) bidArrWrite[bidIndex] = bidArrWrite[len - 1];

        bidArrWrite.pop();
    }

    function changeBid(
        bytes32 _id,
        uint256 bidIndex,
        uint256 newValue
    ) external nonReentrant onlyWhenVaultDefined onlyWhenOrderExists(_id) {
        require(newValue > 0, "801");

        uint256 len;
        OrdersBidInfo memory bidRead;
        OrdersBidInfo[] storage bidArrWrite;
        address sender = _msgSender();

        if (orders[_id].owner == sender) {
            bidArrWrite = ordersOwnerBid[_id];
        } else {
            bidArrWrite = ordersBid[_id];
        }
        bidRead = bidArrWrite[bidIndex];
        len = bidArrWrite.length;

        require(bidIndex < len, "802");
        require(
            bidRead.investor == sender,
            "803"
        );

        require(
            bidRead.amountInvested != newValue,
            "804"
        );
        if (bidRead.amountInvested < newValue) {
            require(
                IERC20(bidRead.investedToken).transferFrom(
                    sender,
                    address(vault),
                    newValue.sub(bidRead.amountInvested)
                ),
                "805"
            );
            bidArrWrite[bidIndex].amountInvested = newValue;
        } else if (bidRead.amountInvested > newValue) {
            vault.withdraw(
                bidRead.investedToken,
                bidRead.investor,
                bidRead.amountInvested.sub(newValue)
            );
            bidArrWrite[bidIndex].amountInvested = newValue;
        }
    }

    function contractTimestamp() external view returns (uint256) {
        return block.timestamp;
    }

    function setVault(Vault _vault) external onlyOwner {
        vault = _vault;
    }

    function setDiscount(bytes32 _id, uint16 newDiscount)
        external
        onlyOrderOwner(_id)
        onlyWhenOrderExists(_id)
    {
        orders[_id].discount = newDiscount;
    }

    function setAmountOfToken(bytes32 _id, uint256 newAmountOfToken)
        external
        onlyOrderOwner(_id)
        onlyWhenOrderExists(_id)
    {
        orders[_id].amountOfToken = newAmountOfToken;
    }

    function addWhiteList(address newToken) external onlyOwner {
        isAddressInWhiteList[newToken] = true;
    }

    function deleteFromWhiteList(address tokenToDelete) external onlyOwner {
        isAddressInWhiteList[tokenToDelete] = false;
    }

    // view functions
    function createKey(address _owner) external view returns (bytes32 result) {
        uint256 creationTime = block.timestamp;
        result = 0x0000000000000000000000000000000000000000000000000000000000000000;
        assembly {
            result := or(result, mul(_owner, 0x1000000000000000000000000))
            result := or(result, and(creationTime, 0xffffffffffffffffffffffff))
        }
    }

    function ordersBidLen(bytes32 id) external view returns (uint256) {
        return ordersBid[id].length;
    }

    function ordersOwnerBidLen(bytes32 id) external view returns (uint256) {
        return ordersOwnerBid[id].length;
    }

    function getOrderOwnerInvestments(bytes32 id)
        public
        view
        returns (address[] memory tokens, uint256[] memory amount)
    {
        return _getUserInvestments(ordersOwnerBid[id], orders[id].owner);
    }

    function getOrderUserInvestments(bytes32 id, address user)
        public
        view
        returns (address[] memory tokens, uint256[] memory amount)
    {
        return _getUserInvestments(ordersBid[id], user);
    }

    function getInvestors(bytes32 id)
        public
        view
        returns (address[] memory investors)
    {
        OrdersBidInfo[] storage bids = ordersBid[id];
        uint256 len = bids.length;
        investors = new address[](len);
        uint256 count = 0;
        for (uint256 i = 0; i < len; i = i.add(1)) {
            uint256 ind = _findAddress(investors, bids[i].investor, count);
            require(ind <= count, "MarsBaseOtc: Internal error getInvestors");
            if (ind == count) {
                investors[count] = bids[i].investor;
                count = count.add(1);
            }
        }
        uint256 delta = len.sub(count);
        if (delta > 0) {
            // decrease len of arrays tokens and amount
            // https://ethereum.stackexchange.com/questions/51891/how-to-pop-from-decrease-the-length-of-a-memory-array-in-solidity
            assembly {
                mstore(investors, sub(mload(investors), delta))
            }
        }
    }

    // private functions
    function _buyOrderDeposit(
        bytes32 _id,
        address _token,
        address _from,
        uint256 _amount
    ) private {
        OrdersBidInfo memory ownersBid =
            OrdersBidInfo({
                investor: _from,
                investedToken: _token,
                amountInvested: _amount
            });

        if (_from == orders[_id].owner) {
            require(
                isAddressInWhiteList[_token] == true,
                "308"
            );
            ordersOwnerBid[_id].push(ownersBid);
        } else {
            require(_token == orders[_id].token, "309");
            ordersBid[_id].push(ownersBid);
        }

        emit BuyOrderDeposit(_id, _token, _from, _amount);
    }

    function _sellOrderDeposit(
        bytes32 _id,
        address _token,
        address _from,
        uint256 _amount
    ) private {
        OrdersBidInfo memory ownersBid =
            OrdersBidInfo({
                investor: _from,
                investedToken: _token,
                amountInvested: _amount
            });

        if (_from == orders[_id].owner) {
            require(_token == orders[_id].token, "310");
            ordersOwnerBid[_id].push(ownersBid);
        } else {
            require(
                isAddressInWhiteList[_token] == true,
                "311"
            );
            ordersBid[_id].push(ownersBid);
        }

        emit SellOrderDeposit(_id, _token, _from, _amount);
    }

    function _cancel(bytes32 _id)
        private
        onlyWhenVaultDefined
        onlyWhenOrderExists(_id)
    {
        address[] memory tokens;
        uint256[] memory investments;
        (tokens, investments) = getOrderOwnerInvestments(_id);
        uint256 len = tokens.length;
        uint256 i;
        for (i = 0; i < len; i = i.add(1)) {
            vault.withdraw(tokens[i], orders[_id].owner, investments[i]);
        }

        address[] memory investors = getInvestors(_id);
        len = investors.length;
        uint256 len2;
        uint256 j;
        for (i = 0; i < len; i = i.add(1)) {
            (tokens, investments) = getOrderUserInvestments(_id, investors[i]);
            len2 = tokens.length;
            for (j = 0; j < len2; j = j.add(1)) {
                vault.withdraw(tokens[j], investors[i], investments[j]);
            }
        }

        orders[_id].isCancelled = true;
    }

    function _getUserInvestments(OrdersBidInfo[] storage bids, address user)
        private
        view
        returns (address[] memory tokens, uint256[] memory amount)
    {
        uint256 len = bids.length;
        tokens = new address[](len);
        amount = new uint256[](len);
        uint256 count = 0;
        for (uint256 i = 0; i < len; i = i.add(1)) {
            if (user == address(0) || bids[i].investor == user) {
                uint256 ind =
                    _findAddress(tokens, bids[i].investedToken, count);
                if (ind < count) {
                    amount[ind] = amount[ind].add(bids[i].amountInvested);
                } else {
                    tokens[count] = bids[i].investedToken;
                    amount[count] = bids[i].amountInvested;
                    count = count.add(1);
                }
            }
        }
        uint256 delta = len.sub(count);
        if (delta > 0) {
            // decrease len of arrays tokens and amount
            // https://ethereum.stackexchange.com/questions/51891/how-to-pop-from-decrease-the-length-of-a-memory-array-in-solidity
            assembly {
                mstore(tokens, sub(mload(tokens), delta))
            }
            assembly {
                mstore(amount, sub(mload(amount), delta))
            }
        }
    }

    function _findAddress(
        address[] memory array,
        address toFind,
        uint256 len
    ) private pure returns (uint256 i) {
        require(array.length >= len, "MarsBaseOtc: Wrong len argument");
        for (i = 0; i < len; i = i.add(1)) {
            if (array[i] == toFind) return i;
        }
    }

    function _calculateToBrokerToUser(uint256 amount, uint256 brokerPerc)
        private
        pure
        returns (uint256 toBroker, uint256 toUser)
    {
        toBroker = amount.mul(brokerPerc).div(BROKERS_DENOMINATOR);
        toUser = amount.sub(toBroker);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

contract Vault is Ownable {
    address public marsBaseOtc;

    modifier onlyMarsBaseOtc() {
        require(msg.sender == marsBaseOtc);
        _;
    }

    receive() external payable {}

    function tokenFallback(
        address,
        uint256,
        bytes calldata
    ) external {}

    function setMarsBaseOtc(address _marsBaseOtc) external onlyOwner {
        require(
            _marsBaseOtc != address(0),
            "Vault: MarsBaseOtc is zero address"
        );
        marsBaseOtc = _marsBaseOtc;
    }

    function withdraw(
        address _token,
        address _receiver,
        uint256 _amount
    ) external onlyMarsBaseOtc {
        require(
            _receiver != address(0),
            "901"
        );
        if (_token == address(0)) {
            payable(_receiver).transfer(_amount);
        } else {
            require(
                IERC20(_token).transfer(_receiver, _amount),
                "901"
            );
        }
    }

    function withdrawForTwo(
        address _token,
        address _receiver1,
        uint256 _amount1,
        address _receiver2,
        uint256 _amount2
    ) external onlyMarsBaseOtc {
        if (_token == address(0)) {
            if (_receiver1 != address(0) && _amount1 > 0)
                payable(_receiver1).transfer(_amount1);
            if (_receiver2 != address(0) && _amount2 > 0)
                payable(_receiver2).transfer(_amount2);
        } else {
            if (_receiver1 != address(0) && _amount1 > 0) {
                require(
                    IERC20(_token).transfer(_receiver1, _amount1),
                    "901"
                );
            }
            if (_receiver2 != address(0) && _amount2 > 0) {
                require(
                    IERC20(_token).transfer(_receiver2, _amount2),
                    "901"
                );
            }
        }
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

pragma solidity >=0.6.0 <0.8.0;

import "../GSN/Context.sol";
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

    constructor () internal {
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

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 999999
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}