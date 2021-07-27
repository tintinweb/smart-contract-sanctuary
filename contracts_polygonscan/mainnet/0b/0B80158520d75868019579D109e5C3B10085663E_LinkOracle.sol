/**
 *Submitted for verification at polygonscan.com on 2021-07-26
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.6.0;

contract LibNote {
    event LogNote(
        bytes4   indexed  sig,
        address  indexed  usr,
        bytes32  indexed  arg1,
        bytes32  indexed  arg2,
        bytes             data
    ) anonymous;

    modifier note {
        _;
        assembly {
            // log an 'anonymous' event with a constant 6 words of calldata
            // and four indexed topics: selector, caller, arg1 and arg2
            let mark := msize()                         // end of memory ensures zero
            mstore(0x40, add(mark, 288))              // update free memory pointer
            mstore(mark, 0x20)                        // bytes type data offset
            mstore(add(mark, 0x20), 224)              // bytes size (padded)
            calldatacopy(add(mark, 0x40), 0, 224)     // bytes payload
            log4(mark, 288,                           // calldata
                 shl(224, shr(224, calldataload(0))), // msg.sig
                 caller(),                              // msg.sender
                 calldataload(4),                     // arg1
                 calldataload(36)                     // arg2
                )
        }
    }
}

// https://github.com/smartcontractkit/chainlink/blob/master/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol
interface AggregatorV3Interface {
    function latestRoundData() external view returns (uint80 _roundId, int256 _answer, uint256 _startedAt, uint256 _updatedAt, uint80 _answeredInRound);
}

contract LinkOracle is LibNote {

    // --- Auth ---
    mapping (address => uint256) public wards;
    function rely(address _usr) external auth { wards[_usr] = 1;  }
    function deny(address _usr) external auth { wards[_usr] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "LINKOracle/not-authorized");
        _;
    }

    // --- Math ---
    uint constant ONE = 10 ** 27;

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    address public immutable src;     // Price source
    uint256 public immutable factor;  // Price multiplier

    // --- Whitelisting ---
    mapping (address => uint256) public bud;
    modifier toll { require(bud[msg.sender] == 1, "LINKOracle/contract-not-whitelisted"); _; }

    constructor (address _src, uint8 _dec) public {
        require(_src  != address(0), "LINKOracle/invalid-src-address");
        require(_dec  <=         18, "LINKOracle/invalid-dec-places");
        wards[msg.sender] = 1;
        src  = _src;
        factor = 10 ** (18 - uint256(_dec));
    }

    function read() external view toll returns (uint256) {
        (,int256 price,,,) = AggregatorV3Interface(src).latestRoundData();
        require(price > 0, "LINKOracle/invalid-price-feed");
        return mul(uint256(price), factor);
    }

    function peek() external view toll returns (uint256,bool) {
        (,int256 price,,,) = AggregatorV3Interface(src).latestRoundData();
        return (mul(uint256(price), factor), price > 0);
    }

    function kiss(address a) external note auth {
        require(a != address(0), "LINKOracle/no-contract-0");
        bud[a] = 1;
    }

    function diss(address a) external note auth {
        bud[a] = 0;
    }

    function kiss(address[] calldata a) external note auth {
        for(uint i = 0; i < a.length; i++) {
            require(a[i] != address(0), "LINKOracle/no-contract-0");
            bud[a[i]] = 1;
        }
    }

    function diss(address[] calldata a) external note auth {
        for(uint i = 0; i < a.length; i++) {
            bud[a[i]] = 0;
        }
    }
}