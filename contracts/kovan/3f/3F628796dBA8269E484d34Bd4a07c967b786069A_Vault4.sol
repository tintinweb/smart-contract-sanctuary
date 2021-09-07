// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./Dai.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// @title  Collateralized Vault
// @notice Deposit Eth - Borrow Dai - Repay Dai - Withdraw Eth
contract Vault4 {
    Dai public token;
    AggregatorV3Interface internal priceFeed;

    address public owner;

    mapping(address => uint256) public deposits; // Stored in eth
    mapping(address => uint256) public loans; // Stored in dai

    //@notice The eth/dai exchange rate from oracle
    uint256 public exchangeRate;

    event Deposit(uint256 wad);
    event Withdraw(uint256 wad);
    event Borrow(uint256 wad);
    event Repay(uint256 wad);
    event Liquidate(address guy, uint256 loanDaiAmt, uint256 depositEthAmt);

    // @dev Deploy with address of Dai Stablecoin token
    constructor(Dai _token, address _oracleAddress) {
        token = _token;
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(_oracleAddress);
    }

    //@notice Function used to get dai/eth exchange from price feed and convert eth to dai
    //@param wad amount to apply exchange rate to
    //@param update If true, will fetch exchange rate from oracle
    function applyExchangeRate(uint256 _ethValue) internal view returns (uint256 _resultDai) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        require(answer > 0, "Amount > 0 required");
        uint256 _currentRate = uint256(answer);
        _resultDai = _ethValue * _currentRate;
        require(_resultDai / _currentRate == _ethValue, "Overflow");
        return _resultDai;
    }

    //@notice Function used to deposit eth
    function deposit() external payable {
        require(msg.value > 0, "Amount > 0 required");
        deposits[msg.sender] += msg.value;
        emit Deposit(msg.value);
    }

    //@notice Function used to withdraw eth
    function withdraw(uint256 _ethWad) external {
        require(_ethWad > 0, "Amount > 0 required");
        uint256 _deposit = deposits[msg.sender];
        require(_deposit > 0, "Insufficient balance");
        uint256 _depositDaiValue = applyExchangeRate(_deposit);
        uint256 _withdrawDaiValue = applyExchangeRate(_ethWad);
        require((_depositDaiValue - loans[msg.sender]) >= _withdrawDaiValue, "Insufficient balance");
        deposits[msg.sender] -= _ethWad;
        payable(msg.sender).transfer(_ethWad);
        emit Withdraw(_ethWad);
    }

    //@notice Function used to borrow dai collateralized by eth deposit
    function borrow(uint256 _daiWad) external {
        require(_daiWad > 0, "Amount > 0 required");
        uint256 _depositEthValue = deposits[msg.sender];
        require(_depositEthValue > 0, "Insufficient collateral1");
        uint256 _depositDaiValue = applyExchangeRate(_depositEthValue);

        require((loans[msg.sender] + _daiWad) <= _depositDaiValue, "Insufficient collateral2");
        loans[msg.sender] += _daiWad;
        token.push(msg.sender, _daiWad);
        emit Borrow(_daiWad);
    }

    //@notice Function used to pay down dai loans
    function repay(uint256 _daiWad) external {
        require(_daiWad > 0, "Amount > 0 required");
        require(_daiWad <= loans[msg.sender], "Amount > loaned");
        loans[msg.sender] -= _daiWad;
        token.pull(msg.sender, _daiWad);
        emit Repay(_daiWad);
    }

    //@notice Function used to liquidate
    function liquidate(address guy) external {
        uint256 _depositEth = deposits[guy];
        require(_depositEth > 0, "No deposit");
        uint256 _loanDai = loans[guy];
        require(_loanDai > 0, "No loan");
        uint256 _depositDaiValue = applyExchangeRate(_depositEth);
        require(_loanDai > _depositDaiValue, "Loan safe");
        delete loans[guy];
        delete deposits[guy];
        emit Liquidate(guy, _loanDai, _depositEth);
    }
}

/**
 *Submitted for verification at Etherscan.io on 2019-11-14
 */

// hevm: flattened sources of /nix/store/8xb41r4qd0cjb63wcrxf1qmfg88p0961-dss-6fd7de0/src/dai.sol
pragma solidity >=0.8.4;

////// /nix/store/8xb41r4qd0cjb63wcrxf1qmfg88p0961-dss-6fd7de0/src/lib.sol
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

/* pragma solidity 0.5.12; */

// contract LibNote {
//     event LogNote(
//         bytes4   indexed  sig,
//         address  indexed  usr,
//         bytes32  indexed  arg1,
//         bytes32  indexed  arg2,
//         bytes             data
//     ) anonymous;

//     modifier note {
//         _;
//         assembly {
//             // log an 'anonymous' event with a constant 6 words of calldata
//             // and four indexed topics: selector, caller, arg1 and arg2
//             let mark := msize()                         // end of memory ensures zero
//             mstore(0x40, add(mark, 288))              // update free memory pointer
//             mstore(mark, 0x20)                        // bytes type data offset
//             mstore(add(mark, 0x20), 224)              // bytes size (padded)
//             calldatacopy(add(mark, 0x40), 0, 224)     // bytes payload
//             log4(mark, 288,                           // calldata
//                  shl(224, shr(224, calldataload(0))), // msg.sig
//                  caller(),                              // msg.sender
//                  calldataload(4),                     // arg1
//                  calldataload(36)                     // arg2
//                 )
//         }
//     }
// }

////// /nix/store/8xb41r4qd0cjb63wcrxf1qmfg88p0961-dss-6fd7de0/src/dai.sol
// Copyright (C) 2017, 2018, 2019 dbrock, rain, mrchico

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

/* pragma solidity 0.5.12; */

/* import "./lib.sol"; */

contract Dai {
    // --- Auth ---
    mapping(address => uint256) public wards;

    function rely(address guy) external auth {
        wards[guy] = 1;
    }

    function deny(address guy) external auth {
        wards[guy] = 0;
    }

    modifier auth() {
        require(wards[msg.sender] == 1, "Dai/not-authorized");
        _;
    }

    // --- ERC20 Data ---
    string public constant name = "Dai Stablecoin";
    string public constant symbol = "DAI";
    string public constant version = "1";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public nonces;

    event Approval(address indexed src, address indexed guy, uint256 wad);
    event Transfer(address indexed src, address indexed dst, uint256 wad);

    // --- Math ---
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    // --- EIP712 niceties ---
    bytes32 public DOMAIN_SEPARATOR;
    // bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address holder,address spender,uint256 nonce,uint256 expiry,bool allowed)");
    bytes32 public constant PERMIT_TYPEHASH = 0xea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb;

    constructor(uint256 chainId_) {
        wards[msg.sender] = 1;
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                chainId_,
                address(this)
            )
        );
    }

    // --- Token ---
    function transfer(address dst, uint256 wad) external returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) public returns (bool) {
        require(balanceOf[src] >= wad, "Dai/insufficient-balance");
        if (src != msg.sender && allowance[src][msg.sender] != uint256(256)) {
            require(allowance[src][msg.sender] >= wad, "Dai/insufficient-allowance");
            allowance[src][msg.sender] = sub(allowance[src][msg.sender], wad);
        }
        balanceOf[src] = sub(balanceOf[src], wad);
        balanceOf[dst] = add(balanceOf[dst], wad);
        emit Transfer(src, dst, wad);
        return true;
    }

    function mint(address usr, uint256 wad) external auth {
        balanceOf[usr] = add(balanceOf[usr], wad);
        totalSupply = add(totalSupply, wad);
        emit Transfer(address(0), usr, wad);
    }

    function burn(address usr, uint256 wad) external {
        require(balanceOf[usr] >= wad, "Dai/insufficient-balance");
        if (usr != msg.sender && allowance[usr][msg.sender] != uint256(256)) {
            require(allowance[usr][msg.sender] >= wad, "Dai/insufficient-allowance");
            allowance[usr][msg.sender] = sub(allowance[usr][msg.sender], wad);
        }
        balanceOf[usr] = sub(balanceOf[usr], wad);
        totalSupply = sub(totalSupply, wad);
        emit Transfer(usr, address(0), wad);
    }

    function approve(address usr, uint256 wad) external returns (bool) {
        allowance[msg.sender][usr] = wad;
        emit Approval(msg.sender, usr, wad);
        return true;
    }

    // --- Alias ---
    function push(address usr, uint256 wad) external {
        transferFrom(msg.sender, usr, wad);
    }

    function pull(address usr, uint256 wad) external {
        transferFrom(usr, msg.sender, wad);
    }

    function move(
        address src,
        address dst,
        uint256 wad
    ) external {
        transferFrom(src, dst, wad);
    }

    // --- Approve by signature ---
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, holder, spender, nonce, expiry, allowed))
            )
        );

        require(holder != address(0), "Dai/invalid-address-0");
        require(holder == ecrecover(digest, v, r, s), "Dai/invalid-permit");
        require(nonce == nonces[holder]++, "Dai/invalid-nonce");
        uint256 wad = allowed ? uint256(256) : 0;
        allowance[holder][spender] = wad;
        emit Approval(holder, spender, wad);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

{
  "metadata": {
    "bytecodeHash": "none"
  },
  "optimizer": {
    "enabled": true,
    "runs": 800
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}