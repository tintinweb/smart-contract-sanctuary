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
/// @title Utility Functions for address
/// @author Daniel Wang - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="fd999c93949891bd9192928d8f94939ad3928f9a">[email&#160;protected]</a>>
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
/// @title Token Register Contract
/// @dev This contract maintains a list of tokens the Protocol supports.
/// @author Kongliang Zhong - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="9cf7f3f2fbf0f5fdf2fbdcf0f3f3eceef5f2fbb2f3eefb">[email&#160;protected]</a>>,
/// @author Daniel Wang - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="fe9a9f90979b92be9291918e8c979099d0918c99">[email&#160;protected]</a>>.
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
/// @title An Implementation of TokenRegistry.
/// @author Kongliang Zhong - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="385357565f545159565f78545757484a51565f16574a5f">[email&#160;protected]</a>>,
/// @author Daniel Wang - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="2145404f48444d614d4e4e5153484f460f4e5346">[email&#160;protected]</a>>.
contract TokenRegistryImpl is TokenRegistry, Claimable {
    using AddressUtil for address;
    address[] public addresses;
    mapping (address => TokenInfo) addressMap;
    mapping (string => address) symbolMap;
    struct TokenInfo {
        uint   pos;      // 0 mens unregistered; if > 0, pos + 1 is the
                         // token&#39;s position in `addresses`.
        string symbol;   // Symbol of the token
    }
    /// @dev Disable default function.
    function ()
        payable
        public
    {
        revert();
    }
    function registerToken(
        address addr,
        string  symbol
        )
        external
        onlyOwner
    {
        registerTokenInternal(addr, symbol);
    }
    function unregisterToken(
        address addr,
        string  symbol
        )
        external
        onlyOwner
    {
        require(addr != 0x0);
        require(symbolMap[symbol] == addr);
        delete symbolMap[symbol];
        uint pos = addressMap[addr].pos;
        require(pos != 0);
        delete addressMap[addr];
        // We will replace the token we need to unregister with the last token
        // Only the pos of the last token will need to be updated
        address lastToken = addresses[addresses.length - 1];
        // Don&#39;t do anything if the last token is the one we want to delete
        if (addr != lastToken) {
            // Swap with the last token and update the pos
            addresses[pos - 1] = lastToken;
            addressMap[lastToken].pos = pos;
        }
        addresses.length--;
        emit TokenUnregistered(addr, symbol);
    }
    function areAllTokensRegistered(
        address[] addressList
        )
        external
        view
        returns (bool)
    {
        for (uint i = 0; i < addressList.length; i++) {
            if (addressMap[addressList[i]].pos == 0) {
                return false;
            }
        }
        return true;
    }
    function getAddressBySymbol(
        string symbol
        )
        external
        view
        returns (address)
    {
        return symbolMap[symbol];
    }
    function isTokenRegisteredBySymbol(
        string symbol
        )
        public
        view
        returns (bool)
    {
        return symbolMap[symbol] != 0x0;
    }
    function isTokenRegistered(
        address addr
        )
        public
        view
        returns (bool)
    {
        return addressMap[addr].pos != 0;
    }
    function getTokens(
        uint start,
        uint count
        )
        public
        view
        returns (address[] addressList)
    {
        uint num = addresses.length;
        if (start >= num) {
            return;
        }
        uint end = start + count;
        if (end > num) {
            end = num;
        }
        addressList = new address[](end - start);
        for (uint i = start; i < end; i++) {
            addressList[i - start] = addresses[i];
        }
    }
    function registerTokenInternal(
        address addr,
        string  symbol
        )
        internal
    {
        require(0x0 != addr);
        require(bytes(symbol).length > 0);
        require(0x0 == symbolMap[symbol]);
        require(0 == addressMap[addr].pos);
        addresses.push(addr);
        symbolMap[symbol] = addr;
        addressMap[addr] = TokenInfo(addresses.length, symbol);
        emit TokenRegistered(addr, symbol);
    }
}