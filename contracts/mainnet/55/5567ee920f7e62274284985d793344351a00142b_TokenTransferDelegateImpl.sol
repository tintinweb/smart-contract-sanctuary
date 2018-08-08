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
/// @author Daniel Wang - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="3450555a5d515874585b5b44465d5a531a5b4653">[email&#160;protected]</a>>
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
            avg += arr[i];
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
            cvs += mul(s, s);
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
/// @title Ownable
/// @dev The Ownable contract has an owner address, and provides basic
///      authorization control functions, this simplifies the implementation of
///      "user permissions".
contract Ownable {
    address public owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    /// @dev The Ownable constructor sets the original `owner` of the contract
    ///      to the sender.
    function Ownable()
        public
    {
        owner = msg.sender;
    }
    /// @dev Throws if called by any account other than the owner.
    modifier onlyOwner()
    {
        require(msg.sender == owner);
        _;
    }
    /// @dev Allows the current owner to transfer control of the contract to a
    ///      newOwner.
    /// @param newOwner The address to transfer ownership to.
    function transferOwnership(
        address newOwner
        )
        onlyOwner
        public
    {
        require(newOwner != 0x0);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}
/// @title Claimable
/// @dev Extension for the Ownable contract, where the ownership needs
///      to be claimed. This allows the new owner to accept the transfer.
contract Claimable is Ownable {
    address public pendingOwner;
    /// @dev Modifier throws if called by any account other than the pendingOwner.
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner);
        _;
    }
    /// @dev Allows the current owner to set the pendingOwner address.
    /// @param newOwner The address to transfer ownership to.
    function transferOwnership(
        address newOwner
        )
        onlyOwner
        public
    {
        require(newOwner != 0x0 && newOwner != owner);
        pendingOwner = newOwner;
    }
    /// @dev Allows the pendingOwner address to finalize the transfer.
    function claimOwnership()
        onlyPendingOwner
        public
    {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = 0x0;
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
/// @title ERC20 Token Interface
/// @dev see https://github.com/ethereum/EIPs/issues/20
/// @author Daniel Wang - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="1571747b7c707955797a7a65677c7b723b7a6772">[email&#160;protected]</a>>
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
/// @title TokenTransferDelegate
/// @dev Acts as a middle man to transfer ERC20 tokens on behalf of different
/// versions of Loopring protocol to avoid ERC20 re-authorization.
/// @author Daniel Wang - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="6c080d020509002c0003031c1e05020b42031e0b">[email&#160;protected]</a>>.
contract TokenTransferDelegate {
    event AddressAuthorized(address indexed addr, uint32 number);
    event AddressDeauthorized(address indexed addr, uint32 number);
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
        external;
    function setCutoffs(uint t)
        external;
    function setTradingPairCutoffs(bytes20 tokenPair, uint t)
        external;
    function checkCutoffsBatch(address[] owners, bytes20[] tradingPairs, uint[] validSince)
        external
        view;
}
/// @title An Implementation of TokenTransferDelegate.
/// @author Daniel Wang - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="fd999c93949891bd9192928d8f94939ad3928f9a">[email&#160;protected]</a>>.
contract TokenTransferDelegateImpl is TokenTransferDelegate, Claimable {
    using MathUint for uint;
    struct AddressInfo {
        address previous;
        uint32  index;
        bool    authorized;
    }
    mapping(address => AddressInfo) public addressInfos;
    address public latestAddress;
    modifier onlyAuthorized()
    {
        require(addressInfos[msg.sender].authorized);
        _;
    }
    /// @dev Disable default function.
    function ()
        payable
        public
    {
        revert();
    }
    function authorizeAddress(
        address addr
        )
        onlyOwner
        external
    {
        AddressInfo storage addrInfo = addressInfos[addr];
        if (addrInfo.index != 0) { // existing
            if (addrInfo.authorized == false) { // re-authorize
                addrInfo.authorized = true;
                emit AddressAuthorized(addr, addrInfo.index);
            }
        } else {
            address prev = latestAddress;
            if (prev == 0x0) {
                addrInfo.index = 1;
                addrInfo.authorized = true;
            } else {
                addrInfo.previous = prev;
                addrInfo.index = addressInfos[prev].index + 1;
            }
            addrInfo.authorized = true;
            latestAddress = addr;
            emit AddressAuthorized(addr, addrInfo.index);
        }
    }
    function deauthorizeAddress(
        address addr
        )
        onlyOwner
        external
    {
        uint32 index = addressInfos[addr].index;
        if (index != 0) {
            addressInfos[addr].authorized = false;
            emit AddressDeauthorized(addr, index);
        }
    }
    function getLatestAuthorizedAddresses(
        uint max
        )
        external
        view
        returns (address[] addresses)
    {
        addresses = new address[](max);
        address addr = latestAddress;
        AddressInfo memory addrInfo;
        uint count = 0;
        while (addr != 0x0 && count < max) {
            addrInfo = addressInfos[addr];
            if (addrInfo.index == 0) {
                break;
            }
            addresses[count++] = addr;
            addr = addrInfo.previous;
        }
    }
    function transferToken(
        address token,
        address from,
        address to,
        uint    value
        )
        onlyAuthorized
        external
    {
        if (value > 0 && from != to && to != 0x0) {
            require(
                ERC20(token).transferFrom(from, to, value)
            );
        }
    }
    function batchTransferToken(
        address lrcTokenAddress,
        address minerFeeRecipient,
        uint8 walletSplitPercentage,
        bytes32[] batch
        )
        onlyAuthorized
        external
    {
        uint len = batch.length;
        require(len % 7 == 0);
        require(walletSplitPercentage > 0 && walletSplitPercentage < 100);
        ERC20 lrc = ERC20(lrcTokenAddress);
        for (uint i = 0; i < len; i += 7) {
            address owner = address(batch[i]);
            address prevOwner = address(batch[(i + len - 7) % len]);
            // Pay token to previous order, or to miner as previous order&#39;s
            // margin split or/and this order&#39;s margin split.
            ERC20 token = ERC20(address(batch[i + 1]));
            // Here batch[i + 2] has been checked not to be 0.
            if (owner != prevOwner) {
                require(
                    token.transferFrom(
                        owner,
                        prevOwner,
                        uint(batch[i + 2])
                    )
                );
            }
            // Miner pays LRx fee to order owner
            uint lrcReward = uint(batch[i + 4]);
            if (lrcReward != 0 && minerFeeRecipient != owner) {
                require(
                    lrc.transferFrom(
                        minerFeeRecipient,
                        owner,
                        lrcReward
                    )
                );
            }
            // Split margin-split income between miner and wallet
            splitPayFee(
                token,
                uint(batch[i + 3]),
                owner,
                minerFeeRecipient,
                address(batch[i + 6]),
                walletSplitPercentage
            );
            // Split LRx fee income between miner and wallet
            splitPayFee(
                lrc,
                uint(batch[i + 5]),
                owner,
                minerFeeRecipient,
                address(batch[i + 6]),
                walletSplitPercentage
            );
        }
    }
    function isAddressAuthorized(
        address addr
        )
        public
        view
        returns (bool)
    {
        return addressInfos[addr].authorized;
    }
    function splitPayFee(
        ERC20   token,
        uint    fee,
        address owner,
        address minerFeeRecipient,
        address walletFeeRecipient,
        uint    walletSplitPercentage
        )
        internal
    {
        if (fee == 0) {
            return;
        }
        uint walletFee = (walletFeeRecipient == 0x0) ? 0 : fee.mul(walletSplitPercentage) / 100;
        uint minerFee = fee - walletFee;
        if (walletFee > 0 && walletFeeRecipient != owner) {
            require(
                token.transferFrom(
                    owner,
                    walletFeeRecipient,
                    walletFee
                )
            );
        }
        if (minerFee > 0 && minerFeeRecipient != 0x0 && minerFeeRecipient != owner) {
            require(
                token.transferFrom(
                    owner,
                    minerFeeRecipient,
                    minerFee
                )
            );
        }
    }
    function addCancelled(bytes32 orderHash, uint cancelAmount)
        onlyAuthorized
        external
    {
        cancelled[orderHash] = cancelled[orderHash].add(cancelAmount);
    }
    function addCancelledOrFilled(bytes32 orderHash, uint cancelOrFillAmount)
        onlyAuthorized
        external
    {
        cancelledOrFilled[orderHash] = cancelledOrFilled[orderHash].add(cancelOrFillAmount);
    }
    function setCutoffs(uint t)
        onlyAuthorized
        external
    {
        cutoffs[tx.origin] = t;
    }
    function setTradingPairCutoffs(bytes20 tokenPair, uint t)
        onlyAuthorized
        external
    {
        tradingPairCutoffs[tx.origin][tokenPair] = t;
    }
    function checkCutoffsBatch(address[] owners, bytes20[] tradingPairs, uint[] validSince)
        external
        view
    {
        uint len = owners.length;
        require(len == tradingPairs.length);
        require(len == validSince.length);
        for(uint i = 0; i < len; i++) {
            require(validSince[i] > tradingPairCutoffs[owners[i]][tradingPairs[i]]);  // order trading pair is cut off
            require(validSince[i] > cutoffs[owners[i]]);                              // order is cut off
        }
    }
}