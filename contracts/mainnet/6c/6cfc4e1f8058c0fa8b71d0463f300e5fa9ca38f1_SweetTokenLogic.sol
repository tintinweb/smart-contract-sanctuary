// Copyright (c) 2017 Sweetbridge Stiftung (Sweetbridge Foundation)
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

/// math.sol -- mixin for inline numerical wizardry

// Copyright (C) 2015, 2016, 2017  DappHub, LLC

// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND (express or implied).

pragma solidity ^0.4.17;


library Math {

    // standard uint256 functions
    function add(uint256 x, uint256 y) pure internal returns (uint256 z) {
        require((z = x + y) >= x);
    }

    function sub(uint256 x, uint256 y) pure internal returns (uint256 z) {
        require((z = x - y) <= x);
    }

    function mul(uint256 x, uint256 y) pure internal returns (uint256 z) {
        z = x * y;
        require((z == 0 && (x == 0 || y == 0)) || z >= (x > y ? x : y));
    }

    //division by zero is ignored and returns zero
    function div(uint256 x, uint256 y) pure internal returns (uint256 z) {
        z = y > 0 ? x / y : 0;
    }

    function min(uint256 x, uint256 y) pure internal returns (uint256 z) {
        return x <= y ? x : y;
    }

    function max(uint256 x, uint256 y) pure internal returns (uint256 z) {
        return x >= y ? x : y;
    }

    /*
    uint128 functions (h is for half)
     */

    function hadd(uint128 x, uint128 y) pure internal returns (uint128 z) {
        require((z = x + y) >= x);
    }

    function hsub(uint128 x, uint128 y) pure internal returns (uint128 z) {
        require((z = x - y) <= x);
    }

    function hmul(uint128 x, uint128 y) pure internal returns (uint128 z) {
        require((z = x * y) >= x);
    }

    function hdiv(uint128 x, uint128 y) pure internal returns (uint128 z) {
        require(y > 0);
        z = x / y;
    }

    function hmin(uint128 x, uint128 y) pure internal returns (uint128 z) {
        return x <= y ? x : y;
    }

    function hmax(uint128 x, uint128 y) pure internal returns (uint128 z) {
        return x >= y ? x : y;
    }

    /*
    int256 functions
     */

    function imin(int256 x, int256 y) pure internal returns (int256 z) {
        return x <= y ? x : y;
    }

    function imax(int256 x, int256 y) pure internal returns (int256 z) {
        return x >= y ? x : y;
    }

    /*
    WAD math
     */

    uint128 constant WAD = 10 ** 18;

    function wadd(uint128 x, uint128 y) pure internal returns (uint128) {
        return hadd(x, y);
    }

    function wsub(uint128 x, uint128 y) pure internal returns (uint128) {
        return hsub(x, y);
    }

    function wmul(uint128 x, uint128 y) pure internal returns (uint128 z) {
        z = cast((uint256(x) * y + WAD / 2) / WAD);
    }

    function wdiv(uint128 x, uint128 y) pure internal returns (uint128 z) {
        z = cast((uint256(x) * WAD + y / 2) / y);
    }

    function wmin(uint128 x, uint128 y) pure internal returns (uint128) {
        return hmin(x, y);
    }

    function wmax(uint128 x, uint128 y) pure internal returns (uint128) {
        return hmax(x, y);
    }

    /*
    RAY math
     */

    uint128 constant RAY = 10 ** 27;

    function radd(uint128 x, uint128 y) pure internal returns (uint128) {
        return hadd(x, y);
    }

    function rsub(uint128 x, uint128 y) pure internal returns (uint128) {
        return hsub(x, y);
    }

    function rmul(uint128 x, uint128 y) pure internal returns (uint128 z) {
        z = cast((uint256(x) * y + RAY / 2) / RAY);
    }

    function rdiv(uint128 x, uint128 y) pure internal returns (uint128 z) {
        z = cast((uint256(x) * RAY + y / 2) / y);
    }

    function rpow(uint128 x, uint64 n) pure internal returns (uint128 z) {
        // This famous algorithm is called "exponentiation by squaring"
        // and calculates x^n with x as fixed-point and n as regular unsigned.
        //
        // It&#39;s O(log n), instead of O(n) for naive repeated multiplication.
        //
        // These facts are why it works:
        //
        //  If n is even, then x^n = (x^2)^(n/2).
        //  If n is odd,  then x^n = x * x^(n-1),
        //   and applying the equation for even x gives
        //    x^n = x * (x^2)^((n-1) / 2).
        //
        //  Also, EVM division is flooring and
        //    floor[(n-1) / 2] = floor[n / 2].

        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }

    function rmin(uint128 x, uint128 y) pure internal returns (uint128) {
        return hmin(x, y);
    }

    function rmax(uint128 x, uint128 y) pure internal returns (uint128) {
        return hmax(x, y);
    }

    function cast(uint256 x) pure internal returns (uint128 z) {
        require((z = uint128(x)) == x);
    }
}

contract OwnedEvents {
    event LogSetOwner (address newOwner);
}


contract Owned is OwnedEvents {
    address public owner;

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function setOwner(address owner_) public onlyOwner {
        owner = owner_;
        LogSetOwner(owner);
    }

}

interface SecuredWithRolesI {
    function hasRole(string roleName) public view returns (bool);
    function senderHasRole(string roleName) public view returns (bool);
    function contractHash() public view returns (bytes32);
}


contract SecuredWithRoles is Owned {
    RolesI public roles;
    bytes32 public contractHash;
    bool public stopped = false;

    function SecuredWithRoles(string contractName_, address roles_) public {
        contractHash = keccak256(contractName_);
        roles = RolesI(roles_);
    }

    modifier stoppable() {
        require(!stopped);
        _;
    }

    modifier onlyRole(string role) {
        require(senderHasRole(role));
        _;
    }

    modifier roleOrOwner(string role) {
        require(msg.sender == owner || senderHasRole(role));
        _;
    }

    // returns true if the role has been defined for the contract
    function hasRole(string roleName) public view returns (bool) {
        return roles.knownRoleNames(contractHash, keccak256(roleName));
    }

    function senderHasRole(string roleName) public view returns (bool) {
        return hasRole(roleName) && roles.roleList(contractHash, keccak256(roleName), msg.sender);
    }

    function stop() public roleOrOwner("stopper") {
        stopped = true;
    }

    function restart() public roleOrOwner("restarter") {
        stopped = false;
    }

    function setRolesContract(address roles_) public onlyOwner {
        // it must not be possible to change the roles contract on the roles contract itself
        require(this != address(roles));
        roles = RolesI(roles_);
    }

}


interface RolesI {
    function knownRoleNames(bytes32 contractHash, bytes32 nameHash) public view returns (bool);
    function roleList(bytes32 contractHash, bytes32 nameHash, address member) public view returns (bool);

    function addContractRole(bytes32 ctrct, string roleName) public;
    function removeContractRole(bytes32 ctrct, string roleName) public;
    function grantUserRole(bytes32 ctrct, string roleName, address user) public;
    function revokeUserRole(bytes32 ctrct, string roleName, address user) public;
}


contract RolesEvents {
    event LogRoleAdded(bytes32 contractHash, string roleName);
    event LogRoleRemoved(bytes32 contractHash, string roleName);
    event LogRoleGranted(bytes32 contractHash, string roleName, address user);
    event LogRoleRevoked(bytes32 contractHash, string roleName, address user);
}


contract Roles is RolesEvents, SecuredWithRoles {
    // mapping is contract -> role -> sender_address -> boolean
    mapping(bytes32 => mapping (bytes32 => mapping (address => bool))) public roleList;
    // the intention is
    mapping (bytes32 => mapping (bytes32 => bool)) public knownRoleNames;

    function Roles() SecuredWithRoles("RolesRepository", this) public {}

    function addContractRole(bytes32 ctrct, string roleName) public roleOrOwner("admin") {
        require(!knownRoleNames[ctrct][keccak256(roleName)]);
        knownRoleNames[ctrct][keccak256(roleName)] = true;
        LogRoleAdded(ctrct, roleName);
    }

    function removeContractRole(bytes32 ctrct, string roleName) public roleOrOwner("admin") {
        require(knownRoleNames[ctrct][keccak256(roleName)]);
        delete knownRoleNames[ctrct][keccak256(roleName)];
        LogRoleRemoved(ctrct, roleName);
    }

    function grantUserRole(bytes32 ctrct, string roleName, address user) public roleOrOwner("admin") {
        require(knownRoleNames[ctrct][keccak256(roleName)]);
        roleList[ctrct][keccak256(roleName)][user] = true;
        LogRoleGranted(ctrct, roleName, user);
    }

    function revokeUserRole(bytes32 ctrct, string roleName, address user) public roleOrOwner("admin") {
        delete roleList[ctrct][keccak256(roleName)][user];
        LogRoleRevoked(ctrct, roleName, user);
    }

}

// Token standard API
// https://github.com/ethereum/EIPs/issues/20
contract ERC20Events {
    event Transfer( address indexed from, address indexed to, uint256 value);
    event Approval( address indexed owner, address indexed spender, uint256 value);
}


contract ERC20 is ERC20Events {
    function totalSupply() public view returns (uint256 supply);
    function balanceOf( address who ) public  view returns (uint256 value);
    function allowance( address owner, address spender ) public view returns (uint256 _allowance);

    function transfer( address to, uint256 value) public returns (bool ok);
    function transferFrom( address from, address to, uint256 value) public returns (bool ok);
    function approve( address spender, uint256 value ) public returns (bool ok);

}

contract TokenData is Owned {
    uint256 public supply;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public approvals;
    address logic;

    modifier onlyLogic {
        assert(msg.sender == logic);
        _;
    }

    function TokenData(address logic_, address owner_) public {
        logic = logic_;
        owner = owner_;
        balances[owner] = supply;
    }

    function setTokenLogic(address logic_) public onlyLogic {
        logic = logic_;
    }

    function setSupply(uint256 supply_) public onlyLogic {
        supply = supply_;
    }

    function setBalances(address guy, uint256 balance) public onlyLogic {
        balances[guy] = balance;
    }

    function setApprovals(address src, address guy, uint256 wad) public onlyLogic {
        approvals[src][guy] = wad;
    }


}

interface TokenI {
    function totalSupply() public view returns (uint256 supply);
    function balanceOf( address who ) public  view returns (uint256 value);
    function allowance( address owner, address spender ) public view returns (uint256 _allowance);

    function triggerTransfer(address src, address dst, uint256 wad);
    function transfer( address to, uint256 value) public returns (bool ok);
    function transferFrom( address from, address to, uint256 value) public returns (bool ok);
    function approve( address spender, uint256 value ) public returns (bool ok);

    function mintFor(address recipient, uint256 wad) public;
}

interface TokenLogicI {
    // we have slightly different interface then ERC20, because
    function totalSupply() public view returns (uint256 supply);
    function balanceOf( address who ) public view returns (uint256 value);
    function allowance( address owner, address spender ) public view returns (uint256 _allowance);
    function transferFrom( address from, address to, uint256 value) public returns (bool ok);
    // this two functions are different from ERC20. ERC20 assumes that msg.sender is the owner,
    // but because logic contract is behind a proxy we need to add an owner parameter.
    function transfer( address owner, address to, uint256 value) public returns (bool ok);
    function approve( address owner, address spender, uint256 value ) public returns (bool ok);

    function setToken(address token_) public;
    function mintFor(address dest, uint256 wad) public;
    function burn(address src, uint256 wad) public;
}


contract TokenLogicEvents {
    event WhiteListAddition(bytes32 listName);
    event AdditionToWhiteList(bytes32 listName, address guy);
    event WhiteListRemoval(bytes32 listName);
    event RemovalFromWhiteList(bytes32 listName, address guy);
}


contract TokenLogic is TokenLogicEvents, TokenLogicI, SecuredWithRoles {

    TokenData public data;
    Token public token;     // facade: Token.sol:Token

    /* White lists are used to restrict who can transact with whom.
     * Since we can&#39;t iterate over the mapping we need to store the keys separaterly in the
     *   listNames
     */
    bytes32[] public listNames;
    mapping (address => mapping (bytes32 => bool)) public whiteLists;
    // by default there is no need for white listing addresses, anyone can transact freely
    bool public freeTransfer = true;

    function TokenLogic(
        address token_,
        address tokenData_,
        address rolesContract) public SecuredWithRoles("TokenLogic", rolesContract)
    {
        require(token_ != address(0x0));
        require(rolesContract != address(0x0));

        token = Token(token_);
        if (tokenData_ == address(0x0)) {
            data = new TokenData(this, msg.sender);
        } else {
            data = TokenData(tokenData_);
        }
    }

    modifier tokenOnly {
        assert(msg.sender == address(token));
        _;
    }

    /* check that freeTransfer is true or that the owner is involved or both sender and recipient are in the same whitelist*/
    modifier canTransfer(address src, address dst) {
        require(freeTransfer || src == owner || dst == owner || sameWhiteList(src, dst));
        _;
    }

    function sameWhiteList(address src, address dst) internal view returns(bool) {
        for(uint8 i = 0; i < listNames.length; i++) {
            bytes32 listName = listNames[i];
            if(whiteLists[src][listName] && whiteLists[dst][listName]) {
                return true;
            }
        }
        return false;
    }

    function listNamesLen() public view returns (uint256) {
        return listNames.length;
    }

    function listExists(bytes32 listName) public view returns (bool) {
        var (, ok) = indexOf(listName);
        return ok;
    }

    function indexOf(bytes32 listName) public view returns (uint8, bool) {
        for(uint8 i = 0; i < listNames.length; i++) {
            if(listNames[i] == listName) {
                return (i, true);
            }
        }
        return (0, false);
    }

    function replaceLogic(address newLogic) public onlyOwner {
        token.setLogic(TokenLogicI(newLogic));
        data.setTokenLogic(newLogic);
        selfdestruct(owner);
    }

    /* creating a removeWhiteList would be too onerous. Therefore it does not exist*/
    function addWhiteList(bytes32 listName) public onlyRole("admin") {
        require(! listExists(listName));
        require(listNames.length < 256);
        listNames.push(listName);
        WhiteListAddition(listName);
    }

    function removeWhiteList(bytes32 listName) public onlyRole("admin") {
        var (i, ok) = indexOf(listName);
        require(ok);
        if(i < listNames.length - 1) {
            listNames[i] = listNames[listNames.length - 1];
        }
        delete listNames[listNames.length - 1];
        --listNames.length;
        WhiteListRemoval(listName);
    }

    function addToWhiteList(bytes32 listName, address guy) public onlyRole("userManager") {
        require(listExists(listName));

        whiteLists[guy][listName] = true;
        AdditionToWhiteList(listName, guy);
    }

    function removeFromWhiteList(bytes32 listName, address guy) public onlyRole("userManager") {
        require(listExists(listName));

        whiteLists[guy][listName] = false;
        RemovalFromWhiteList(listName, guy);
    }

    function setFreeTransfer(bool isFree) public onlyOwner {
        freeTransfer = isFree;
    }

    function setToken(address token_) public onlyOwner {
        token = Token(token_);
    }

    function totalSupply() public view returns (uint256) {
        return data.supply();
    }

    function balanceOf(address src) public view returns (uint256) {
        return data.balances(src);
    }

    function allowance(address src, address spender) public view returns (uint256) {
        return data.approvals(src, spender);
    }

    function transfer(address src, address dst, uint256 wad) public tokenOnly canTransfer(src, dst)  returns (bool) {
        // balance check is not needed because sub(a, b) will throw if a<b
        data.setBalances(src, Math.sub(data.balances(src), wad));
        data.setBalances(dst, Math.add(data.balances(dst), wad));

        return true;
    }

    function transferFrom(address src, address dst, uint256 wad) public tokenOnly canTransfer(src, dst)  returns (bool) {
        // balance and approval check is not needed because sub(a, b) will throw if a<b
        data.setApprovals(src, dst, Math.sub(data.approvals(src, dst), wad));
        data.setBalances(src, Math.sub(data.balances(src), wad));
        data.setBalances(dst, Math.add(data.balances(dst), wad));

        return true;
    }

    function approve(address src, address dst, uint256 wad) public tokenOnly returns (bool) {
        data.setApprovals(src, dst, wad);
        return true;
    }

    function mintFor(address dst, uint256 wad) public tokenOnly {
        data.setBalances(dst, Math.add(data.balances(dst), wad));
        data.setSupply(Math.add(data.supply(), wad));
    }

    function burn(address src, uint256 wad) public tokenOnly {
        data.setBalances(src, Math.sub(data.balances(src), wad));
        data.setSupply(Math.sub(data.supply(), wad));
    }
}

contract TokenEvents {
    event LogBurn(address indexed src, uint256 wad);
    event LogMint(address indexed src, uint256 wad);
    event LogLogicReplaced(address newLogic);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Contract that will work with ERC223 tokens.
 */
interface ERC223ReceivingContract {
    /**
     * @dev Standard ERC223 function that will handle incoming token transfers.
     *
     * @param src  Token sender address.
     * @param wad  Amount of tokens.
     * @param _data  Transaction metadata.
     */
    function tokenFallback(address src, uint wad, bytes _data) public;
}

contract Token is TokenI, SecuredWithRoles, TokenEvents {
    string public symbol;
    string public name; // Optional token name
    uint8 public decimals = 18; // standard token precision. override to customize
    TokenLogicI public logic;

    function Token(string name_, string symbol_, address rolesContract) public SecuredWithRoles(name_, rolesContract) {
        // you can&#39;t create logic here, because this contract would be the owner.
        name = name_;
        symbol = symbol_;
    }

    modifier logicOnly {
        require(address(logic) == address(0x0) || address(logic) == msg.sender);
        _;
    }

    function totalSupply() public view returns (uint256) {
        return logic.totalSupply();
    }

    function balanceOf( address who ) public view returns (uint256 value) {
        return logic.balanceOf(who);
    }

    function allowance(address owner, address spender ) public view returns (uint256 _allowance) {
        return logic.allowance(owner, spender);
    }

    function triggerTransfer(address src, address dst, uint256 wad) logicOnly {
        Transfer(src, dst, wad);
    }

    function setLogic(address logic_) public logicOnly {
        assert(logic_ != address(0));
        logic = TokenLogicI(logic_);
        LogLogicReplaced(logic);
    }

    /**
     * @dev Transfer the specified amount of tokens to the specified address.
     *      Invokes the `tokenFallback` function if the recipient is a contract.
     *      The token transfer fails if the recipient is a contract
     *      but does not implement the `tokenFallback` function
     *      or the fallback function to receive funds.
     */
    function transfer(address dst, uint256 wad) public stoppable returns (bool) {
        bool retVal = logic.transfer(msg.sender, dst, wad);
        if (retVal) {
            uint codeLength;
            assembly {
            // Retrieve the size of the code on target address, this needs assembly .
                codeLength := extcodesize(dst)
            }
            if (codeLength>0) {
                ERC223ReceivingContract receiver = ERC223ReceivingContract(dst);
                bytes memory empty;
                receiver.tokenFallback(msg.sender, wad, empty);
            }

            Transfer(msg.sender, dst, wad);
        }
        return retVal;
    }

    function transferFrom(address src, address dst, uint256 wad) public stoppable returns (bool) {
        bool retVal = logic.transferFrom(src, dst, wad);
        if (retVal) {
            uint codeLength;
            assembly {
            // Retrieve the size of the code on target address, this needs assembly .
                codeLength := extcodesize(dst)
            }
            if (codeLength>0) {
                ERC223ReceivingContract receiver = ERC223ReceivingContract(dst);
                bytes memory empty;
                receiver.tokenFallback(src, wad, empty);
            }

            Transfer(src, dst, wad);
        }
        return retVal;
    }

    function approve(address guy, uint256 wad) public stoppable returns (bool) {
        bool ok = logic.approve(msg.sender, guy, wad);
        if (ok)
            Approval(msg.sender, guy, wad);
        return ok;
    }

    function pull(address src, uint256 wad) public stoppable returns (bool) {
        return transferFrom(src, msg.sender, wad);
    }

    function mintFor(address recipient, uint256 wad) public stoppable onlyRole("minter") {
        logic.mintFor(recipient, wad);
        LogMint(recipient, wad);
        Transfer(address(0x0), recipient, wad);
    }

    function burn(uint256 wad) public stoppable {
        logic.burn(msg.sender, wad);
        LogBurn(msg.sender, wad);
    }

    function setName(string name_) public roleOrOwner("admin") {
        name = name_;
    }
}

contract SweetTokenLogic is TokenLogic {

    function SweetTokenLogic(
        address token_,
        address tokenData_,
        address rolesContract,
        address[] initialWallets,
        uint256[] initialBalances)
    TokenLogic(token_, tokenData_, rolesContract) public
    {
        if (tokenData_ == address(0x0)) {
            uint256 totalSupply;
            require(initialBalances.length == initialWallets.length);
            for (uint256 i = 0; i < initialWallets.length; i++) {
                data.setBalances(initialWallets[i], initialBalances[i]);
                token.triggerTransfer(address(0x0), initialWallets[i], initialBalances[i]);
                totalSupply = Math.add(totalSupply, initialBalances[i]);
            }
            data.setSupply(totalSupply);
        }
    }

    function mintFor(address, uint256) public tokenOnly {
        // no more SweetTokens can be minted after the initial mint
        assert(false);
    }

    function burn(address, uint256) public tokenOnly {
        // burning is not possible
        assert(false);
    }
}