/*
  Copyright 2017 Loopring Project Ltd (Loopring Foundation).
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
  http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/
pragma solidity 0.4.21;
/// @title Utility Functions for uint
/// @author Daniel Wang - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="4226232c2b272e022e2d2d32302b2c256c2d3025">[email&#160;protected]</a>>
library MathUint {
    function mul(
        uint a,
        uint b
        )
        internal
        pure
        returns (uint c)
    {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function sub(
        uint a,
        uint b
        )
        internal
        pure
        returns (uint)
    {
        require(b <= a);
        return a - b;
    }
    function add(
        uint a,
        uint b
        )
        internal
        pure
        returns (uint c)
    {
        c = a + b;
        require(c >= a);
    }
    function tolerantSub(
        uint a,
        uint b
        )
        internal
        pure
        returns (uint c)
    {
        return (a >= b) ? a - b : 0;
    }
    /// @dev calculate the square of Coefficient of Variation (CV)
    /// https://en.wikipedia.org/wiki/Coefficient_of_variation
    function cvsquare(
        uint[] arr,
        uint scale
        )
        internal
        pure
        returns (uint)
    {
        uint len = arr.length;
        require(len > 1);
        require(scale > 0);
        uint avg = 0;
        for (uint i = 0; i < len; i++) {
            avg = add(avg, arr[i]);
        }
        avg = avg / len;
        if (avg == 0) {
            return 0;
        }
        uint cvs = 0;
        uint s;
        uint item;
        for (i = 0; i < len; i++) {
            item = arr[i];
            s = item > avg ? item - avg : avg - item;
            cvs = add(cvs, mul(s, s));
        }
        return ((mul(mul(cvs, scale), scale) / avg) / avg) / (len - 1);
    }
}
/*
  Copyright 2017 Loopring Project Ltd (Loopring Foundation).
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
  http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/
/// @title Utility Functions for address
/// @author Daniel Wang - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="7e1a1f10171b123e1211110e0c17101950110c19">[email&#160;protected]</a>>
library AddressUtil {
    function isContract(
        address addr
        )
        internal
        view
        returns (bool)
    {
        if (addr == 0x0) {
            return false;
        } else {
            uint size;
            assembly { size := extcodesize(addr) }
            return size > 0;
        }
    }
}
/*
  Copyright 2017 Loopring Project Ltd (Loopring Foundation).
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
  http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/
/*
  Copyright 2017 Loopring Project Ltd (Loopring Foundation).
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
  http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/
/// @title ERC20 Token Interface
/// @dev see https://github.com/ethereum/EIPs/issues/20
/// @author Daniel Wang - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="1f7b7e71767a735f7370706f6d76717831706d78">[email&#160;protected]</a>>
contract ERC20 {
    function balanceOf(
        address who
        )
        view
        public
        returns (uint256);
    function allowance(
        address owner,
        address spender
        )
        view
        public
        returns (uint256);
    function transfer(
        address to,
        uint256 value
        )
        public
        returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 value
        )
        public
        returns (bool);
    function approve(
        address spender,
        uint256 value
        )
        public
        returns (bool);
}
/*
  Copyright 2017 Loopring Project Ltd (Loopring Foundation).
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
  http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/
/// @title Loopring Token Exchange Protocol Contract Interface
/// @author Daniel Wang - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="6307020d0a060f230f0c0c13110a0d044d0c1104">[email&#160;protected]</a>>
/// @author Kongliang Zhong - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="2c4743424b40454d424b6c4043435c5e45424b02435e4b">[email&#160;protected]</a>>
contract LoopringProtocol {
    uint8   public constant MARGIN_SPLIT_PERCENTAGE_BASE = 100;
    /// @dev Event to emit if a ring is successfully mined.
    /// _amountsList is an array of:
    /// [_amountS, _amountB, _lrcReward, _lrcFee, splitS, splitB].
    event RingMined(
        uint            _ringIndex,
        bytes32 indexed _ringHash,
        address         _miner,
        bytes32[]       _orderInfoList
    );
    event OrderCancelled(
        bytes32 indexed _orderHash,
        uint            _amountCancelled
    );
    event AllOrdersCancelled(
        address indexed _address,
        uint            _cutoff
    );
    event OrdersCancelled(
        address indexed _address,
        address         _token1,
        address         _token2,
        uint            _cutoff
    );
    /// @dev Cancel a order. cancel amount(amountS or amountB) can be specified
    ///      in orderValues.
    /// @param addresses          owner, tokenS, tokenB, wallet, authAddr
    /// @param orderValues        amountS, amountB, validSince (second),
    ///                           validUntil (second), lrcFee, and cancelAmount.
    /// @param buyNoMoreThanAmountB -
    ///                           This indicates when a order should be considered
    ///                           as &#39;completely filled&#39;.
    /// @param marginSplitPercentage -
    ///                           Percentage of margin split to share with miner.
    /// @param v                  Order ECDSA signature parameter v.
    /// @param r                  Order ECDSA signature parameters r.
    /// @param s                  Order ECDSA signature parameters s.
    function cancelOrder(
        address[5] addresses,
        uint[6]    orderValues,
        bool       buyNoMoreThanAmountB,
        uint8      marginSplitPercentage,
        uint8      v,
        bytes32    r,
        bytes32    s
        )
        external;
    /// @dev   Set a cutoff timestamp to invalidate all orders whose timestamp
    ///        is smaller than or equal to the new value of the address&#39;s cutoff
    ///        timestamp, for a specific trading pair.
    /// @param cutoff The cutoff timestamp, will default to `block.timestamp`
    ///        if it is 0.
    function cancelAllOrdersByTradingPair(
        address token1,
        address token2,
        uint cutoff
        )
        external;
    /// @dev   Set a cutoff timestamp to invalidate all orders whose timestamp
    ///        is smaller than or equal to the new value of the address&#39;s cutoff
    ///        timestamp.
    /// @param cutoff The cutoff timestamp, will default to `block.timestamp`
    ///        if it is 0.
    function cancelAllOrders(
        uint cutoff
        )
        external;
    /// @dev Submit a order-ring for validation and settlement.
    /// @param addressList  List of each order&#39;s owner, tokenS, wallet, authAddr.
    ///                     Note that next order&#39;s `tokenS` equals this order&#39;s
    ///                     `tokenB`.
    /// @param uintArgsList List of uint-type arguments in this order:
    ///                     amountS, amountB, validSince (second),
    ///                     validUntil (second), lrcFee, and rateAmountS.
    /// @param uint8ArgsList -
    ///                     List of unit8-type arguments, in this order:
    ///                     marginSplitPercentageList.
    /// @param buyNoMoreThanAmountBList -
    ///                     This indicates when a order should be considered
    /// @param vList        List of v for each order. This list is 1-larger than
    ///                     the previous lists, with the last element being the
    ///                     v value of the ring signature.
    /// @param rList        List of r for each order. This list is 1-larger than
    ///                     the previous lists, with the last element being the
    ///                     r value of the ring signature.
    /// @param sList        List of s for each order. This list is 1-larger than
    ///                     the previous lists, with the last element being the
    ///                     s value of the ring signature.
    /// @param miner        Miner address.
    /// @param feeSelections -
    ///                     Bits to indicate fee selections. `1` represents margin
    ///                     split and `0` represents LRC as fee.
    function submitRing(
        address[4][]    addressList,
        uint[6][]       uintArgsList,
        uint8[1][]      uint8ArgsList,
        bool[]          buyNoMoreThanAmountBList,
        uint8[]         vList,
        bytes32[]       rList,
        bytes32[]       sList,
        address         miner,
        uint16          feeSelections
        )
        public;
}
/*
  Copyright 2017 Loopring Project Ltd (Loopring Foundation).
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
  http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/
/// @title Token Register Contract
/// @dev This contract maintains a list of tokens the Protocol supports.
/// @author Kongliang Zhong - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="94fffbfaf3f8fdf5faf3d4f8fbfbe4e6fdfaf3bafbe6f3">[email&#160;protected]</a>>,
/// @author Daniel Wang - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="9efafff0f7fbf2def2f1f1eeecf7f0f9b0f1ecf9">[email&#160;protected]</a>>.
contract TokenRegistry {
    event TokenRegistered(
        address indexed addr,
        string          symbol
    );
    event TokenUnregistered(
        address indexed addr,
        string          symbol
    );
    function registerToken(
        address addr,
        string  symbol
        )
        external;
    function registerMintedToken(
        address addr,
        string  symbol
        )
        external;
    function unregisterToken(
        address addr,
        string  symbol
        )
        external;
    function areAllTokensRegistered(
        address[] addressList
        )
        external
        view
        returns (bool);
    function getAddressBySymbol(
        string symbol
        )
        external
        view
        returns (address);
    function isTokenRegisteredBySymbol(
        string symbol
        )
        public
        view
        returns (bool);
    function isTokenRegistered(
        address addr
        )
        public
        view
        returns (bool);
    function getTokens(
        uint start,
        uint count
        )
        public
        view
        returns (address[] addressList);
}
/*
  Copyright 2017 Loopring Project Ltd (Loopring Foundation).
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
  http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/
/// @title TokenTransferDelegate
/// @dev Acts as a middle man to transfer ERC20 tokens on behalf of different
/// versions of Loopring protocol to avoid ERC20 re-authorization.
/// @author Daniel Wang - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="ff9b9e91969a93bf9390908f8d969198d1908d98">[email&#160;protected]</a>>.
contract TokenTransferDelegate {
    event AddressAuthorized(
        address indexed addr,
        uint32          number
    );
    event AddressDeauthorized(
        address indexed addr,
        uint32          number
    );
    // The following map is used to keep trace of order fill and cancellation
    // history.
    mapping (bytes32 => uint) public cancelledOrFilled;
    // This map is used to keep trace of order&#39;s cancellation history.
    mapping (bytes32 => uint) public cancelled;
    // A map from address to its cutoff timestamp.
    mapping (address => uint) public cutoffs;
    // A map from address to its trading-pair cutoff timestamp.
    mapping (address => mapping (bytes20 => uint)) public tradingPairCutoffs;
    /// @dev Add a Loopring protocol address.
    /// @param addr A loopring protocol address.
    function authorizeAddress(
        address addr
        )
        external;
    /// @dev Remove a Loopring protocol address.
    /// @param addr A loopring protocol address.
    function deauthorizeAddress(
        address addr
        )
        external;
    function getLatestAuthorizedAddresses(
        uint max
        )
        external
        view
        returns (address[] addresses);
    /// @dev Invoke ERC20 transferFrom method.
    /// @param token Address of token to transfer.
    /// @param from Address to transfer token from.
    /// @param to Address to transfer token to.
    /// @param value Amount of token to transfer.
    function transferToken(
        address token,
        address from,
        address to,
        uint    value
        )
        external;
    function batchTransferToken(
        address lrcTokenAddress,
        address minerFeeRecipient,
        uint8 walletSplitPercentage,
        bytes32[] batch
        )
        external;
    function isAddressAuthorized(
        address addr
        )
        public
        view
        returns (bool);
    function addCancelled(bytes32 orderHash, uint cancelAmount)
        external;
    function addCancelledOrFilled(bytes32 orderHash, uint cancelOrFillAmount)
        public;
    function batchAddCancelledOrFilled(bytes32[] batch)
        public;
    function setCutoffs(uint t)
        external;
    function setTradingPairCutoffs(bytes20 tokenPair, uint t)
        external;
    function checkCutoffsBatch(address[] owners, bytes20[] tradingPairs, uint[] validSince)
        external
        view;
    function suspend() external;
    function resume() external;
    function kill() external;
}
/// @title An Implementation of LoopringProtocol.
/// @author Daniel Wang - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="cca8ada2a5a9a08ca0a3a3bcbea5a2abe2a3beab">[email&#160;protected]</a>>,
/// @author Kongliang Zhong - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="3f5450515853565e51587f5350504f4d56515811504d58">[email&#160;protected]</a>>
///
/// Recognized contributing developers from the community:
///     https://github.com/Brechtpd
///     https://github.com/rainydio
///     https://github.com/BenjaminPrice
///     https://github.com/jonasshen
///     https://github.com/Hephyrius
contract LoopringProtocolImpl is LoopringProtocol {
    using AddressUtil   for address;
    using MathUint      for uint;
    address public constant lrcTokenAddress             = 0xEF68e7C694F40c8202821eDF525dE3782458639f;
    address public constant tokenRegistryAddress        = 0xAbe12e3548fDb334D11fcc962c413d91Ef12233F;
    address public constant delegateAddress             = 0x17233e07c67d086464fD408148c3ABB56245FA64;
    uint64  public  ringIndex                   = 0;
    uint8   public constant walletSplitPercentage       = 20;
    // Exchange rate (rate) is the amount to sell or sold divided by the amount
    // to buy or bought.
    //
    // Rate ratio is the ratio between executed rate and an order&#39;s original
    // rate.
    //
    // To require all orders&#39; rate ratios to have coefficient ofvariation (CV)
    // smaller than 2.5%, for an example , rateRatioCVSThreshold should be:
    //     `(0.025 * RATE_RATIO_SCALE)^2` or 62500.
    uint    public constant rateRatioCVSThreshold        = 62500;
    uint    public constant MAX_RING_SIZE       = 16;
    uint    public constant RATE_RATIO_SCALE    = 10000;
    /// @param orderHash    The order&#39;s hash
    /// @param feeSelection -
    ///                     A miner-supplied value indicating if LRC (value = 0)
    ///                     or margin split is choosen by the miner (value = 1).
    ///                     We may support more fee model in the future.
    /// @param rateS        Sell Exchange rate provided by miner.
    /// @param rateB        Buy Exchange rate provided by miner.
    /// @param fillAmountS  Amount of tokenS to sell, calculated by protocol.
    /// @param lrcReward    The amount of LRC paid by miner to order owner in
    ///                     exchange for margin split.
    /// @param lrcFeeState  The amount of LR paid by order owner to miner.
    /// @param splitS      TokenS paid to miner.
    /// @param splitB      TokenB paid to miner.
    struct OrderState {
        address owner;
        address tokenS;
        address tokenB;
        address wallet;
        address authAddr;
        uint    validSince;
        uint    validUntil;
        uint    amountS;
        uint    amountB;
        uint    lrcFee;
        bool    buyNoMoreThanAmountB;
        bool    marginSplitAsFee;
        bytes32 orderHash;
        uint8   marginSplitPercentage;
        uint    rateS;
        uint    rateB;
        uint    fillAmountS;
        uint    lrcReward;
        uint    lrcFeeState;
        uint    splitS;
        uint    splitB;
    }
    /// @dev A struct to capture parameters passed to submitRing method and
    ///      various of other variables used across the submitRing core logics.
    struct RingParams {
        uint8[]       vList;
        bytes32[]     rList;
        bytes32[]     sList;
        address       miner;
        uint16        feeSelections;
        uint          ringSize;         // computed
        bytes32       ringHash;         // computed
    }
    /// @dev Disable default function.
    function ()
        payable
        public
    {
        revert();
    }
    function cancelOrder(
        address[5] addresses,
        uint[6]    orderValues,
        bool       buyNoMoreThanAmountB,
        uint8      marginSplitPercentage,
        uint8      v,
        bytes32    r,
        bytes32    s
        )
        external
    {
        uint cancelAmount = orderValues[5];
        require(cancelAmount > 0); // "amount to cancel is zero");
        OrderState memory order = OrderState(
            addresses[0],
            addresses[1],
            addresses[2],
            addresses[3],
            addresses[4],
            orderValues[2],
            orderValues[3],
            orderValues[0],
            orderValues[1],
            orderValues[4],
            buyNoMoreThanAmountB,
            false,
            0x0,
            marginSplitPercentage,
            0,
            0,
            0,
            0,
            0,
            0,
            0
        );
        require(msg.sender == order.owner); // "cancelOrder not submitted by order owner");
        bytes32 orderHash = calculateOrderHash(order);
        verifySignature(
            order.owner,
            orderHash,
            v,
            r,
            s
        );
        TokenTransferDelegate delegate = TokenTransferDelegate(delegateAddress);
        delegate.addCancelled(orderHash, cancelAmount);
        delegate.addCancelledOrFilled(orderHash, cancelAmount);
        emit OrderCancelled(orderHash, cancelAmount);
    }
    function cancelAllOrdersByTradingPair(
        address token1,
        address token2,
        uint    cutoff
        )
        external
    {
        uint t = (cutoff == 0 || cutoff >= block.timestamp) ? block.timestamp : cutoff;
        bytes20 tokenPair = bytes20(token1) ^ bytes20(token2);
        TokenTransferDelegate delegate = TokenTransferDelegate(delegateAddress);
        require(delegate.tradingPairCutoffs(msg.sender, tokenPair) < t);
        // "attempted to set cutoff to a smaller value"
        delegate.setTradingPairCutoffs(tokenPair, t);
        emit OrdersCancelled(
            msg.sender,
            token1,
            token2,
            t
        );
    }
    function cancelAllOrders(
        uint cutoff
        )
        external
    {
        uint t = (cutoff == 0 || cutoff >= block.timestamp) ? block.timestamp : cutoff;
        TokenTransferDelegate delegate = TokenTransferDelegate(delegateAddress);
        require(delegate.cutoffs(msg.sender) < t); // "attempted to set cutoff to a smaller value"
        delegate.setCutoffs(t);
        emit AllOrdersCancelled(msg.sender, t);
    }
    function submitRing(
        address[4][]  addressList,
        uint[6][]     uintArgsList,
        uint8[1][]    uint8ArgsList,
        bool[]        buyNoMoreThanAmountBList,
        uint8[]       vList,
        bytes32[]     rList,
        bytes32[]     sList,
        address       miner,
        uint16        feeSelections
        )
        public
    {
        // Check if the highest bit of ringIndex is &#39;1&#39;.
        require((ringIndex >> 63) == 0); // "attempted to re-ent submitRing function");
        // Set the highest bit of ringIndex to &#39;1&#39;.
        uint64 _ringIndex = ringIndex;
        ringIndex |= (1 << 63);
        RingParams memory params = RingParams(
            vList,
            rList,
            sList,
            miner,
            feeSelections,
            addressList.length,
            0x0 // ringHash
        );
        verifyInputDataIntegrity(
            params,
            addressList,
            uintArgsList,
            uint8ArgsList,
            buyNoMoreThanAmountBList
        );
        // Assemble input data into structs so we can pass them to other functions.
        // This method also calculates ringHash, therefore it must be called before
        // calling `verifyRingSignatures`.
        TokenTransferDelegate delegate = TokenTransferDelegate(delegateAddress);
        OrderState[] memory orders = assembleOrders(
            params,
            delegate,
            addressList,
            uintArgsList,
            uint8ArgsList,
            buyNoMoreThanAmountBList
        );
        verifyRingSignatures(params, orders);
        verifyTokensRegistered(params, orders);
        handleRing(_ringIndex, params, orders, delegate);
        ringIndex = _ringIndex + 1;
    }
    /// @dev Validate a ring.
    function verifyRingHasNoSubRing(
        uint          ringSize,
        OrderState[]  orders
        )
        private
        pure
    {
        // Check the ring has no sub-ring.
        for (uint i = 0; i < ringSize - 1; i++) {
            address tokenS = orders[i].tokenS;
            for (uint j = i + 1; j < ringSize; j++) {
                require(tokenS != orders[j].tokenS); // "found sub-ring");
            }
        }
    }
    /// @dev Verify the ringHash has been signed with each order&#39;s auth private
    ///      keys as well as the miner&#39;s private key.
    function verifyRingSignatures(
        RingParams params,
        OrderState[] orders
        )
        private
        pure
    {
        uint j;
        for (uint i = 0; i < params.ringSize; i++) {
            j = i + params.ringSize;
            verifySignature(
                orders[i].authAddr,
                params.ringHash,
                params.vList[j],
                params.rList[j],
                params.sList[j]
            );
        }
    }
    function verifyTokensRegistered(
        RingParams params,
        OrderState[] orders
        )
        private
        view
    {
        // Extract the token addresses
        address[] memory tokens = new address[](params.ringSize);
        for (uint i = 0; i < params.ringSize; i++) {
            tokens[i] = orders[i].tokenS;
        }
        // Test all token addresses at once
        require(
            TokenRegistry(tokenRegistryAddress).areAllTokensRegistered(tokens)
        ); // "token not registered");
    }
    function handleRing(
        uint64       _ringIndex,
        RingParams   params,
        OrderState[] orders,
        TokenTransferDelegate delegate
        )
        private
    {
        address _lrcTokenAddress = lrcTokenAddress;
        // Do the hard work.
        verifyRingHasNoSubRing(params.ringSize, orders);
        // Exchange rates calculation are performed by ring-miners as solidity
        // cannot get power-of-1/n operation, therefore we have to verify
        // these rates are correct.
        verifyMinerSuppliedFillRates(params.ringSize, orders);
        // Scale down each order independently by substracting amount-filled and
        // amount-cancelled. Order owner&#39;s current balance and allowance are
        // not taken into consideration in these operations.
        scaleRingBasedOnHistoricalRecords(delegate, params.ringSize, orders);
        // Based on the already verified exchange rate provided by ring-miners,
        // we can furthur scale down orders based on token balance and allowance,
        // then find the smallest order of the ring, then calculate each order&#39;s
        // `fillAmountS`.
        calculateRingFillAmount(params.ringSize, orders);
        // Calculate each order&#39;s `lrcFee` and `lrcRewrard` and splict how much
        // of `fillAmountS` shall be paid to matching order or miner as margin
        // split.
        calculateRingFees(
            delegate,
            params.ringSize,
            orders,
            params.miner,
            _lrcTokenAddress
        );
        /// Make transfers.
        bytes32[] memory orderInfoList = settleRing(
            delegate,
            params.ringSize,
            orders,
            params.miner,
            _lrcTokenAddress
        );
        emit RingMined(
            _ringIndex,
            params.ringHash,
            params.miner,
            orderInfoList
        );
    }
    function settleRing(
        TokenTransferDelegate delegate,
        uint          ringSize,
        OrderState[]  orders,
        address       miner,
        address       _lrcTokenAddress
        )
        private
        returns (bytes32[] memory orderInfoList)
    {
        bytes32[] memory batch = new bytes32[](ringSize * 7); // ringSize * (owner + tokenS + 4 amounts + wallet)
        bytes32[] memory historyBatch = new bytes32[](ringSize * 2); // ringSize * (orderhash, fillAmount)
        orderInfoList = new bytes32[](ringSize * 7);
        uint p = 0;
        uint q = 0;
        uint r = 0;
        uint prevSplitB = orders[ringSize - 1].splitB;
        for (uint i = 0; i < ringSize; i++) {
            OrderState memory state = orders[i];
            uint nextFillAmountS = orders[(i + 1) % ringSize].fillAmountS;
            // Store owner and tokenS of every order
            batch[p++] = bytes32(state.owner);
            batch[p++] = bytes32(state.tokenS);
            // Store all amounts
            batch[p++] = bytes32(state.fillAmountS.sub(prevSplitB));
            batch[p++] = bytes32(prevSplitB.add(state.splitS));
            batch[p++] = bytes32(state.lrcReward);
            batch[p++] = bytes32(state.lrcFeeState);
            batch[p++] = bytes32(state.wallet);
            historyBatch[r++] = state.orderHash;
            historyBatch[r++] = bytes32(
                state.buyNoMoreThanAmountB ? nextFillAmountS : state.fillAmountS);
            orderInfoList[q++] = bytes32(state.orderHash);
            orderInfoList[q++] = bytes32(state.owner);
            orderInfoList[q++] = bytes32(state.tokenS);
            orderInfoList[q++] = bytes32(state.fillAmountS);
            orderInfoList[q++] = bytes32(state.lrcReward);
            orderInfoList[q++] = bytes32(
                state.lrcFeeState > 0 ? int(state.lrcFeeState) : -int(state.lrcReward)
            );
            orderInfoList[q++] = bytes32(
                state.splitS > 0 ? int(state.splitS) : -int(state.splitB)
            );
            prevSplitB = state.splitB;
        }
        // Update fill records
        delegate.batchAddCancelledOrFilled(historyBatch);
        // Do all transactions
        delegate.batchTransferToken(
            _lrcTokenAddress,
            miner,
            walletSplitPercentage,
            batch
        );
    }
    /// @dev Verify miner has calculte the rates correctly.
    function verifyMinerSuppliedFillRates(
        uint         ringSize,
        OrderState[] orders
        )
        private
        pure
    {
        uint[] memory rateRatios = new uint[](ringSize);
        uint _rateRatioScale = RATE_RATIO_SCALE;
        for (uint i = 0; i < ringSize; i++) {
            uint s1b0 = orders[i].rateS.mul(orders[i].amountB);
            uint s0b1 = orders[i].amountS.mul(orders[i].rateB);
            require(s1b0 <= s0b1); // "miner supplied exchange rate provides invalid discount");
            rateRatios[i] = _rateRatioScale.mul(s1b0) / s0b1;
        }
        uint cvs = MathUint.cvsquare(rateRatios, _rateRatioScale);
        require(cvs <= rateRatioCVSThreshold);
        // "miner supplied exchange rate is not evenly discounted");
    }
    /// @dev Calculate each order&#39;s fee or LRC reward.
    function calculateRingFees(
        TokenTransferDelegate delegate,
        uint            ringSize,
        OrderState[]    orders,
        address         miner,
        address         _lrcTokenAddress
        )
        private
        view
    {
        bool checkedMinerLrcSpendable = false;
        uint minerLrcSpendable = 0;
        uint8 _marginSplitPercentageBase = MARGIN_SPLIT_PERCENTAGE_BASE;
        uint nextFillAmountS;
        for (uint i = 0; i < ringSize; i++) {
            OrderState memory state = orders[i];
            uint lrcReceiable = 0;
            if (state.lrcFeeState == 0) {
                // When an order&#39;s LRC fee is 0 or smaller than the specified fee,
                // we help miner automatically select margin-split.
                state.marginSplitAsFee = true;
                state.marginSplitPercentage = _marginSplitPercentageBase;
            } else {
                uint lrcSpendable = getSpendable(
                    delegate,
                    _lrcTokenAddress,
                    state.owner
                );
                // If the order is selling LRC, we need to calculate how much LRC
                // is left that can be used as fee.
                if (state.tokenS == _lrcTokenAddress) {
                    lrcSpendable = lrcSpendable.sub(state.fillAmountS);
                }
                // If the order is buyign LRC, it will has more to pay as fee.
                if (state.tokenB == _lrcTokenAddress) {
                    nextFillAmountS = orders[(i + 1) % ringSize].fillAmountS;
                    lrcReceiable = nextFillAmountS;
                }
                uint lrcTotal = lrcSpendable.add(lrcReceiable);
                // If order doesn&#39;t have enough LRC, set margin split to 100%.
                if (lrcTotal < state.lrcFeeState) {
                    state.lrcFeeState = lrcTotal;
                    state.marginSplitPercentage = _marginSplitPercentageBase;
                }
                if (state.lrcFeeState == 0) {
                    state.marginSplitAsFee = true;
                }
            }
            if (!state.marginSplitAsFee) {
                if (lrcReceiable > 0) {
                    if (lrcReceiable >= state.lrcFeeState) {
                        state.splitB = state.lrcFeeState;
                        state.lrcFeeState = 0;
                    } else {
                        state.splitB = lrcReceiable;
                        state.lrcFeeState = state.lrcFeeState.sub(lrcReceiable);
                    }
                }
            } else {
                // Only check the available miner balance when absolutely needed
                if (!checkedMinerLrcSpendable && minerLrcSpendable < state.lrcFeeState) {
                    checkedMinerLrcSpendable = true;
                    minerLrcSpendable = getSpendable(delegate, _lrcTokenAddress, miner);
                }
                // Only calculate split when miner has enough LRC;
                // otherwise all splits are 0.
                if (minerLrcSpendable >= state.lrcFeeState) {
                    nextFillAmountS = orders[(i + 1) % ringSize].fillAmountS;
                    uint split;
                    if (state.buyNoMoreThanAmountB) {
                        split = (nextFillAmountS.mul(
                            state.amountS
                        ) / state.amountB).sub(
                            state.fillAmountS
                        );
                    } else {
                        split = nextFillAmountS.sub(
                            state.fillAmountS.mul(
                                state.amountB
                            ) / state.amountS
                        );
                    }
                    if (state.marginSplitPercentage != _marginSplitPercentageBase) {
                        split = split.mul(
                            state.marginSplitPercentage
                        ) / _marginSplitPercentageBase;
                    }
                    if (state.buyNoMoreThanAmountB) {
                        state.splitS = split;
                    } else {
                        state.splitB = split;
                    }
                    // This implicits order with smaller index in the ring will
                    // be paid LRC reward first, so the orders in the ring does
                    // mater.
                    if (split > 0) {
                        minerLrcSpendable = minerLrcSpendable.sub(state.lrcFeeState);
                        state.lrcReward = state.lrcFeeState;
                    }
                }
                state.lrcFeeState = 0;
            }
        }
    }
    /// @dev Calculate each order&#39;s fill amount.
    function calculateRingFillAmount(
        uint          ringSize,
        OrderState[]  orders
        )
        private
        pure
    {
        uint smallestIdx = 0;
        uint i;
        uint j;
        for (i = 0; i < ringSize; i++) {
            j = (i + 1) % ringSize;
            smallestIdx = calculateOrderFillAmount(
                orders[i],
                orders[j],
                i,
                j,
                smallestIdx
            );
        }
        for (i = 0; i < smallestIdx; i++) {
            calculateOrderFillAmount(
                orders[i],
                orders[(i + 1) % ringSize],
                0,               // Not needed
                0,               // Not needed
                0                // Not needed
            );
        }
    }
    /// @return The smallest order&#39;s index.
    function calculateOrderFillAmount(
        OrderState state,
        OrderState next,
        uint       i,
        uint       j,
        uint       smallestIdx
        )
        private
        pure
        returns (uint newSmallestIdx)
    {
        // Default to the same smallest index
        newSmallestIdx = smallestIdx;
        uint fillAmountB = state.fillAmountS.mul(
            state.rateB
        ) / state.rateS;
        if (state.buyNoMoreThanAmountB) {
            if (fillAmountB > state.amountB) {
                fillAmountB = state.amountB;
                state.fillAmountS = fillAmountB.mul(
                    state.rateS
                ) / state.rateB;
                require(state.fillAmountS > 0);
                newSmallestIdx = i;
            }
            state.lrcFeeState = state.lrcFee.mul(
                fillAmountB
            ) / state.amountB;
        } else {
            state.lrcFeeState = state.lrcFee.mul(
                state.fillAmountS
            ) / state.amountS;
        }
        if (fillAmountB <= next.fillAmountS) {
            next.fillAmountS = fillAmountB;
        } else {
            newSmallestIdx = j;
        }
    }
    /// @dev Scale down all orders based on historical fill or cancellation
    ///      stats but key the order&#39;s original exchange rate.
    function scaleRingBasedOnHistoricalRecords(
        TokenTransferDelegate delegate,
        uint ringSize,
        OrderState[] orders
        )
        private
        view
    {
        for (uint i = 0; i < ringSize; i++) {
            OrderState memory state = orders[i];
            uint amount;
            if (state.buyNoMoreThanAmountB) {
                amount = state.amountB.tolerantSub(
                    delegate.cancelledOrFilled(state.orderHash)
                );
                state.amountS = amount.mul(state.amountS) / state.amountB;
                state.lrcFee = amount.mul(state.lrcFee) / state.amountB;
                state.amountB = amount;
            } else {
                amount = state.amountS.tolerantSub(
                    delegate.cancelledOrFilled(state.orderHash)
                );
                state.amountB = amount.mul(state.amountB) / state.amountS;
                state.lrcFee = amount.mul(state.lrcFee) / state.amountS;
                state.amountS = amount;
            }
            require(state.amountS > 0); // "amountS is zero");
            require(state.amountB > 0); // "amountB is zero");
            uint availableAmountS = getSpendable(delegate, state.tokenS, state.owner);
            require(availableAmountS > 0); // "order spendable amountS is zero");
            state.fillAmountS = (
                state.amountS < availableAmountS ?
                state.amountS : availableAmountS
            );
            require(state.fillAmountS > 0);
        }
    }
    /// @return Amount of ERC20 token that can be spent by this contract.
    function getSpendable(
        TokenTransferDelegate delegate,
        address tokenAddress,
        address tokenOwner
        )
        private
        view
        returns (uint)
    {
        ERC20 token = ERC20(tokenAddress);
        uint allowance = token.allowance(
            tokenOwner,
            address(delegate)
        );
        uint balance = token.balanceOf(tokenOwner);
        return (allowance < balance ? allowance : balance);
    }
    /// @dev verify input data&#39;s basic integrity.
    function verifyInputDataIntegrity(
        RingParams params,
        address[4][]  addressList,
        uint[6][]     uintArgsList,
        uint8[1][]    uint8ArgsList,
        bool[]        buyNoMoreThanAmountBList
        )
        private
        pure
    {
        require(params.miner != 0x0);
        require(params.ringSize == addressList.length);
        require(params.ringSize == uintArgsList.length);
        require(params.ringSize == uint8ArgsList.length);
        require(params.ringSize == buyNoMoreThanAmountBList.length);
        // Validate ring-mining related arguments.
        for (uint i = 0; i < params.ringSize; i++) {
            require(uintArgsList[i][5] > 0); // "order rateAmountS is zero");
        }
        //Check ring size
        require(params.ringSize > 1 && params.ringSize <= MAX_RING_SIZE); // "invalid ring size");
        uint sigSize = params.ringSize << 1;
        require(sigSize == params.vList.length);
        require(sigSize == params.rList.length);
        require(sigSize == params.sList.length);
    }
    /// @dev        assmble order parameters into Order struct.
    /// @return     A list of orders.
    function assembleOrders(
        RingParams params,
        TokenTransferDelegate delegate,
        address[4][]  addressList,
        uint[6][]     uintArgsList,
        uint8[1][]    uint8ArgsList,
        bool[]        buyNoMoreThanAmountBList
        )
        private
        view
        returns (OrderState[] memory orders)
    {
        orders = new OrderState[](params.ringSize);
        for (uint i = 0; i < params.ringSize; i++) {
            uint[6] memory uintArgs = uintArgsList[i];
            bool marginSplitAsFee = (params.feeSelections & (uint16(1) << i)) > 0;
            orders[i] = OrderState(
                addressList[i][0],
                addressList[i][1],
                addressList[(i + 1) % params.ringSize][1],
                addressList[i][2],
                addressList[i][3],
                uintArgs[2],
                uintArgs[3],
                uintArgs[0],
                uintArgs[1],
                uintArgs[4],
                buyNoMoreThanAmountBList[i],
                marginSplitAsFee,
                bytes32(0),
                uint8ArgsList[i][0],
                uintArgs[5],
                uintArgs[1],
                0,   // fillAmountS
                0,   // lrcReward
                0,   // lrcFee
                0,   // splitS
                0    // splitB
            );
            validateOrder(orders[i]);
            bytes32 orderHash = calculateOrderHash(orders[i]);
            orders[i].orderHash = orderHash;
            verifySignature(
                orders[i].owner,
                orderHash,
                params.vList[i],
                params.rList[i],
                params.sList[i]
            );
            params.ringHash ^= orderHash;
        }
        validateOrdersCutoffs(orders, delegate);
        params.ringHash = keccak256(
            params.ringHash,
            params.miner,
            params.feeSelections
        );
    }
    /// @dev validate order&#39;s parameters are OK.
    function validateOrder(
        OrderState order
        )
        private
        view
    {
        require(order.owner != 0x0); // invalid order owner
        require(order.tokenS != 0x0); // invalid order tokenS
        require(order.tokenB != 0x0); // invalid order tokenB
        require(order.amountS != 0); // invalid order amountS
        require(order.amountB != 0); // invalid order amountB
        require(order.marginSplitPercentage <= MARGIN_SPLIT_PERCENTAGE_BASE);
        // invalid order marginSplitPercentage
        require(order.validSince <= block.timestamp); // order is too early to match
        require(order.validUntil > block.timestamp); // order is expired
    }
    function validateOrdersCutoffs(OrderState[] orders, TokenTransferDelegate delegate)
        private
        view
    {
        address[] memory owners = new address[](orders.length);
        bytes20[] memory tradingPairs = new bytes20[](orders.length);
        uint[] memory validSinceTimes = new uint[](orders.length);
        for (uint i = 0; i < orders.length; i++) {
            owners[i] = orders[i].owner;
            tradingPairs[i] = bytes20(orders[i].tokenS) ^ bytes20(orders[i].tokenB);
            validSinceTimes[i] = orders[i].validSince;
        }
        delegate.checkCutoffsBatch(owners, tradingPairs, validSinceTimes);
    }
    /// @dev Get the Keccak-256 hash of order with specified parameters.
    function calculateOrderHash(
        OrderState order
        )
        private
        pure
        returns (bytes32)
    {
        return keccak256(
            delegateAddress,
            order.owner,
            order.tokenS,
            order.tokenB,
            order.wallet,
            order.authAddr,
            order.amountS,
            order.amountB,
            order.validSince,
            order.validUntil,
            order.lrcFee,
            order.buyNoMoreThanAmountB,
            order.marginSplitPercentage
        );
    }
    /// @dev Verify signer&#39;s signature.
    function verifySignature(
        address signer,
        bytes32 hash,
        uint8   v,
        bytes32 r,
        bytes32 s
        )
        private
        pure
    {
        require(
            signer == ecrecover(
                keccak256("\x19Ethereum Signed Message:\n32", hash),
                v,
                r,
                s
            )
        ); // "invalid signature");
    }
    function getTradingPairCutoffs(
        address orderOwner,
        address token1,
        address token2
        )
        public
        view
        returns (uint)
    {
        bytes20 tokenPair = bytes20(token1) ^ bytes20(token2);
        TokenTransferDelegate delegate = TokenTransferDelegate(delegateAddress);
        return delegate.tradingPairCutoffs(orderOwner, tokenPair);
    }
}