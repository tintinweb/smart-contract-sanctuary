/// auth.sol -- widely-used access control pattern for Ethereum

// Copyright (C) 2015, 2016, 2017  DappHub, LLC

// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND (express or implied).

pragma solidity ^0.4.13;

contract Authority {
    function canCall(address src, address dst, bytes4 sig) constant returns (bool);
}

contract AuthEvents {
    event LogSetAuthority (address indexed authority);
    event LogSetOwner     (address indexed owner);
    event UnauthorizedAccess (address caller, bytes4 sig);
}

contract Auth is AuthEvents {
    Authority  public  authority;
    address public owner;

    function Auth() {
        owner = msg.sender;
        LogSetOwner(msg.sender);
    }

    function setOwner(address owner_) auth {
        owner = owner_;
        LogSetOwner(owner);
    }

    function setAuthority(Authority authority_) auth {
        authority = authority_;
        LogSetAuthority(authority);
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig));
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner && authority == Authority(0)) {
            /*the owner has privileges only as long as no Authority has been defined*/
            return true;
        } else if (authority == Authority(0)) {
            UnauthorizedAccess(src, sig);
            return false;
        } else {
            return authority.canCall(src, this, sig);
        }
    }
}
/*
   Copyright 2017 DappHub, LLC

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

// Token standard API
// https://github.com/ethereum/EIPs/issues/20

contract ERC20Events {
    event Transfer( address indexed from, address indexed to, uint value);
    event Approval( address indexed owner, address indexed spender, uint value);
}

contract ERC20 is ERC20Events{
    function totalSupply() constant returns (uint supply);
    function balanceOf( address who ) constant returns (uint value);
    function allowance( address owner, address spender ) constant returns (uint _allowance);

    function transfer( address to, uint value) returns (bool ok);
    function transferFrom( address from, address to, uint value) returns (bool ok);
    function approve( address spender, uint value ) returns (bool ok);

}
/// math.sol -- mixin for inline numerical wizardry

// Copyright (C) 2015, 2016, 2017  DappHub, LLC

// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND (express or implied).

contract Math {
    
    /*
    standard uint256 functions
     */

    function add(uint256 x, uint256 y) constant internal returns (uint256 z) {
        require((z = x + y) >= x);
    }

    function sub(uint256 x, uint256 y) constant internal returns (uint256 z) {
        require((z = x - y) <= x);
    }

    function mul(uint256 x, uint256 y) constant internal returns (uint256 z) {
        z = x * y;
        require(z == 0 || z >= (x > y ? x : y));
    }

    function div(uint256 x, uint256 y) constant internal returns (uint256 z) {
        require(y > 0);
        z = x / y;
    }

    function min(uint256 x, uint256 y) constant internal returns (uint256 z) {
        return x <= y ? x : y;
    }
    function max(uint256 x, uint256 y) constant internal returns (uint256 z) {
        return x >= y ? x : y;
    }

    /*
    uint128 functions (h is for half)
     */


    function hadd(uint128 x, uint128 y) constant internal returns (uint128 z) {
        require((z = x + y) >= x);
    }

    function hsub(uint128 x, uint128 y) constant internal returns (uint128 z) {
        require((z = x - y) <= x);
    }

    function hmul(uint128 x, uint128 y) constant internal returns (uint128 z) {
        require((z = x * y) >= x);
    }

    function hdiv(uint128 x, uint128 y) constant internal returns (uint128 z) {
        require(y > 0);
        z = x / y;
    }

    function hmin(uint128 x, uint128 y) constant internal returns (uint128 z) {
        return x <= y ? x : y;
    }
    function hmax(uint128 x, uint128 y) constant internal returns (uint128 z) {
        return x >= y ? x : y;
    }


    /*
    int256 functions
     */

    function imin(int256 x, int256 y) constant internal returns (int256 z) {
        return x <= y ? x : y;
    }
    function imax(int256 x, int256 y) constant internal returns (int256 z) {
        return x >= y ? x : y;
    }

    /*
    WAD math
     */

    uint128 constant WAD = 10 ** 18;

    function wadd(uint128 x, uint128 y) constant internal returns (uint128) {
        return hadd(x, y);
    }

    function wsub(uint128 x, uint128 y) constant internal returns (uint128) {
        return hsub(x, y);
    }

    function wmul(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = cast((uint256(x) * y + WAD / 2) / WAD);
    }

    function wdiv(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = cast((uint256(x) * WAD + y / 2) / y);
    }

    function wmin(uint128 x, uint128 y) constant internal returns (uint128) {
        return hmin(x, y);
    }
    function wmax(uint128 x, uint128 y) constant internal returns (uint128) {
        return hmax(x, y);
    }

    /*
    RAY math
     */

    uint128 constant RAY = 10 ** 27;

    function radd(uint128 x, uint128 y) constant internal returns (uint128) {
        return hadd(x, y);
    }

    function rsub(uint128 x, uint128 y) constant internal returns (uint128) {
        return hsub(x, y);
    }

    function rmul(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = cast((uint256(x) * y + RAY / 2) / RAY);
    }

    function rdiv(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = cast((uint256(x) * RAY + y / 2) / y);
    }

    function rpow(uint128 x, uint64 n) constant internal returns (uint128 z) {
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

    function rmin(uint128 x, uint128 y) constant internal returns (uint128) {
        return hmin(x, y);
    }
    function rmax(uint128 x, uint128 y) constant internal returns (uint128) {
        return hmax(x, y);
    }

    function cast(uint256 x) constant internal returns (uint128 z) {
        require((z = uint128(x)) == x);
    }

}

contract Migrations {
  address public owner;
  uint public last_completed_migration;

  modifier restricted() {
    if (msg.sender == owner) _;
  }

  function Migrations() {
    owner = msg.sender;
  }

  function setCompleted(uint completed) restricted {
    last_completed_migration = completed;
  }

  function upgrade(address new_address) restricted {
    Migrations upgraded = Migrations(new_address);
    upgraded.setCompleted(last_completed_migration);
  }
}
/// note.sol -- the `note&#39; modifier, for logging calls as events

// Copyright (C) 2017  DappHub, LLC
//
// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND (express or implied).


contract Note {
    event LogNote(
        bytes4   indexed sig,
        address  indexed guy,
        bytes32  indexed foo,
        bytes32  indexed bar,
        uint wad,
        bytes fax
    ) anonymous;

    modifier note {
        bytes32 foo;
        bytes32 bar;

        assembly {
        foo := calldataload(4)
        bar := calldataload(36)
        }

        LogNote(msg.sig, msg.sender, foo, bar, msg.value, msg.data);

        _;
    }
}
/// stop.sol -- mixin for enable/disable functionality

// Copyright (C) 2017  DappHub, LLC

// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND (express or implied).


contract Stoppable is Auth, Note {

    bool public stopped;

    modifier stoppable {
        require (!stopped);
        _;
    }
    function stop() auth note {
        stopped = true;
    }
    function start() auth note {
        stopped = false;
    }

}// token.sol -- ERC20 implementation with minting and burning

// Copyright (C) 2015, 2016, 2017  DappHub, LLC

// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND (express or implied).


contract Token is ERC20, Stoppable {

    bytes32 public symbol;    
    string public name; // Optional token name
    uint256 public decimals = 18; // standard token precision. override to customize
    TokenLogic public logic;

    function Token(string name_, bytes32 symbol_) {
        name = name_;
        symbol = symbol_;
    }

    function setLogic(TokenLogic logic_) auth note returns(bool){
        logic = logic_;
        return true;
    }

    function setOwner(address owner_) auth {
        uint wad = balanceOf(owner);
        logic.transfer(owner, owner_, wad);
        Transfer(owner, owner_, wad);
        logic.setOwner(owner_);
        super.setOwner(owner_);
    }


    function totalSupply() constant returns (uint256){
        return logic.totalSupply();
    }

    function balanceOf( address who ) constant returns (uint value) {
        return logic.balanceOf(who);
    }

    function allowance( address owner, address spender ) constant returns (uint _allowance) {
        return logic.allowance(owner, spender);
    }

    function transfer(address dst, uint wad) stoppable note returns (bool) {
        bool retVal = logic.transfer(msg.sender, dst, wad);
        Transfer(msg.sender, dst, wad);
        return retVal;
    }
    
    function transferFrom(address src, address dst, uint wad) stoppable note returns (bool) {
        bool retVal = logic.transferFrom(src, dst, wad);
        Transfer(src, dst, wad);
        return retVal;
    }

    function approve(address guy, uint wad) stoppable note returns (bool) {
        return logic.approve(msg.sender, guy, wad);
    }

    function push(address dst, uint128 wad) returns (bool) {
        return transfer(dst, wad);
    }

    function pull(address src, uint128 wad) returns (bool) {
        return transferFrom(src, msg.sender, wad);
    }

    function mint(uint128 wad) auth stoppable note {
        logic.mint(wad);
        Transfer(this, msg.sender, wad);
    }

    function burn(uint128 wad) auth stoppable note {
        logic.burn(msg.sender, wad);
    }

    function setName(string name_) auth {
        name = name_;
    }

    function setSymbol(bytes32 symbol_) auth {
        symbol = symbol_;
    }

    function () payable {
        require(msg.value > 0);
        uint wad = logic.handlePayment(msg.sender, msg.value);
        Transfer(this, msg.sender, wad);
    }

/*special functions for ICO*/
    function transferEth(address dst, uint wad) {
        require(msg.sender == address(logic));
        require(wad < this.balance);
        dst.transfer(wad);
    }

/*this function is called from logic to trigger the correct event upon receiving ETH*/
    function triggerTansferEvent(address src,  address dst, uint wad) {
        require(msg.sender == address(logic));
        Transfer(src, dst, wad);
    }

    function payout(address dst) auth {
        require(dst != address(0));
        dst.transfer(this.balance);
    }

}

contract TokenData is Auth {
    uint256 public supply;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public approvals;
    address token;

    modifier tokenOnly {
        assert(msg.sender == token);
        _;
    }

    function TokenData(address token_, uint supply_, address owner_) {
        token = token_;
        supply = supply_;
        owner = owner_;
        balances[owner] = supply;
    }

    function setOwner(address owner_) tokenOnly {
        owner = owner_;
        LogSetOwner(owner);
    }

    function setToken(address token_) auth {
        token = token_;
    }

    function setSupply(uint supply_) tokenOnly {
        supply = supply_;
    }

    function setBalances(address guy, uint balance) tokenOnly {
        balances[guy] = balance;
    }

    function setApprovals(address src, address guy, uint wad) tokenOnly {
        approvals[src][guy] = wad;
    }

}/// base.sol -- basic ERC20 implementation

// Copyright (C) 2015, 2016, 2017  DappHub, LLC

// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND (express or implied).

contract TokenLogic is ERC20Events, Math, Stoppable {

    TokenData public data;
    Token public token;
    uint public tokensPerWei=300;
    uint public icoStart=1503756000; // = Aug 26 2017 2pm GMT
    uint public icoEnd;   //1504188000 = Aug 31 2017 2pm GMT
    uint public icoSale; //the number of tokens sold during the ICO
    uint public maxIco = 90000000000000000000000000; // the maximum number of tokens sold during ICO

    address[] contributors;

    function TokenLogic(Token token_, TokenData data_, uint icoStart_, uint icoHours_) {
        require(token_ != Token(0x0));

        if(data_ == address(0x0)) {
            data = new TokenData(this, 120000000000000000000000000, msg.sender);
        } else {
            data = data_;
        }
        token = token_;
        icoStart = icoStart_;
        icoEnd = icoStart + icoHours_ * 3600;
    }

    modifier tokenOnly {
        assert(msg.sender == address(token) || msg.sender == address(this));
        _;
    }

    function contributorCount() constant returns(uint) {
        return contributors.length;
    }

    function setOwner(address owner_) tokenOnly {
        owner = owner_;
        LogSetOwner(owner);
        data.setOwner(owner);
    }

    function setToken(Token token_) auth {
        token = token_;
    }

    function setIcoStart(uint icoStart_, uint icoHours_) auth {
        icoStart = icoStart_;
        icoEnd = icoStart + icoHours_ * 3600;
    }

    function setTokensPerWei(uint tokensPerWei_) auth {
        require(tokensPerWei_ > 0);
        tokensPerWei = tokensPerWei_;
    }

    function totalSupply() constant returns (uint256) {
        return data.supply();
    }

    function balanceOf(address src) constant returns (uint256) {
        return data.balances(src);
    }

    function allowance(address src, address guy) constant returns (uint256) {
        return data.approvals(src, guy);
    }
    
    function transfer(address src, address dst, uint wad) tokenOnly returns (bool) {
        require(balanceOf(src) >= wad);
        
        data.setBalances(src, sub(data.balances(src), wad));
        data.setBalances(dst, add(data.balances(dst), wad));
        
        return true;
    }
    
    function transferFrom(address src, address dst, uint wad) tokenOnly returns (bool) {
        require(data.balances(src) >= wad);
        require(data.approvals(src, dst) >= wad);
        
        data.setApprovals(src, dst, sub(data.approvals(src, dst), wad));
        data.setBalances(src, sub(data.balances(src), wad));
        data.setBalances(dst, add(data.balances(dst), wad));
        
        return true;
    }
    
    function approve(address src, address guy, uint256 wad) tokenOnly returns (bool) {

        data.setApprovals(src, guy, wad);
        
        Approval(src, guy, wad);
        
        return true;
    }

    function mint(uint128 wad) tokenOnly {
        data.setBalances(data.owner(), add(data.balances(data.owner()), wad));
        data.setSupply(add(data.supply(), wad));
    }

    function burn(address src, uint128 wad) tokenOnly {
        data.setBalances(src, sub(data.balances(src), wad));
        data.setSupply(sub(data.supply(), wad));
    }

    function returnIcoInvestments(uint contributorIndex) auth {
        /*this can only be done after the ICO close date and if less than 20mio tokens were sold*/
        require(now > icoEnd && icoSale < 20000000000000000000000000);

        address src = contributors[contributorIndex];
        require(src != address(0));

        uint srcBalance = balanceOf(src);

        /*transfer the sent ETH amount minus a 5 finney (0.005 ETH ~ 1USD) tax to pay for Gas*/
        token.transferEth(src, sub(div(srcBalance, tokensPerWei), 5 finney));

        /*give back the tokens*/
        data.setBalances(src, sub(data.balances(src), srcBalance));
        data.setBalances(owner, add(data.balances(owner), srcBalance));
        token.triggerTansferEvent(src, owner, srcBalance);

        /*reset the address after the transfer to avoid errors*/
        contributors[contributorIndex] = address(0);
    }

    function handlePayment(address src, uint eth) tokenOnly returns (uint){
        require(eth > 0);
        /*the time stamp has to be between the start and end times of the ICO*/
        require(now >= icoStart && now <= icoEnd);
        /*no more than 90 mio tokens shall be sold in the ICO*/
        require(icoSale < maxIco);

        uint tokenAmount = mul(tokensPerWei, eth);
//first 10 hours
        if(now < icoStart + (10 * 3600)) {
            tokenAmount = tokenAmount * 125 / 100;
        }
//10 to 34 hours
        else if(now < icoStart + (34 * 3600)) {
            tokenAmount = tokenAmount * 115 / 100;
        }
//34 to 58 hours
        else if(now < icoStart + (58 * 3600)) {
            tokenAmount = tokenAmount * 105 / 100;
        }

        icoSale += tokenAmount;
        if(icoSale > maxIco) {
            uint excess = sub(icoSale, maxIco);
            tokenAmount = sub(tokenAmount, excess);
            token.transferEth(src, div(excess, tokensPerWei));
            icoSale = maxIco;
        }

        require(balanceOf(owner) >= tokenAmount);

        data.setBalances(owner, sub(data.balances(owner), tokenAmount));
        data.setBalances(src, add(data.balances(src), tokenAmount));
        contributors.push(src);

        token.triggerTansferEvent(owner, src, tokenAmount);

        return tokenAmount;
    }
}