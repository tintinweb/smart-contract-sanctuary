/**
 *Submitted for verification at BscScan.com on 2021-08-28
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.6.0;

contract DSNote {
    event LogNote(
        bytes4   indexed  sig,
        address  indexed  guy,
        bytes32  indexed  foo,
        bytes32  indexed  bar,
        uint256           wad,
        bytes             fax
    ) anonymous;

    modifier note {
        bytes32 foo;
        bytes32 bar;
        uint256 wad;

        assembly {
            foo := calldataload(4)
            bar := calldataload(36)
            wad := callvalue()
        }

        _;

        emit LogNote(msg.sig, msg.sender, foo, bar, wad, msg.data);
    }
}

interface PipLike {
    function peek() external view returns (bytes32, bool);
    function read() external view returns (bytes32);
}

// https://github.com/smartcontractkit/chainlink/blob/master/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol
interface AggregatorV3Interface {
    function decimals() external view returns (uint8 _decimals);
    function latestRoundData() external view returns (uint80 _roundId, int256 _answer, uint256 _startedAt, uint256 _updatedAt, uint80 _answeredInRound);
}

contract LinkOracle is DSNote, PipLike {

    // --- Auth ---
    mapping (address => uint256) public wards;
    function rely(address _usr) external note auth { wards[_usr] = 1;  }
    function deny(address _usr) external note auth { wards[_usr] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "LinkOracle/not-authorized");
        _;
    }

    // --- Math ---
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    address public immutable src;     // Price source
    uint256 public immutable factor;  // Price multiplier

    // --- Whitelisting ---
    mapping (address => uint256) public bud;
    modifier toll { require(bud[msg.sender] == 1, "LinkOracle/contract-not-whitelisted"); _; }

    constructor (address _src) public {
        require(_src  != address(0), "LinkOracle/invalid-src-address");
        uint8 _dec = AggregatorV3Interface(_src).decimals();
        require(_dec  <=         18, "LinkOracle/invalid-dec-places");
        wards[msg.sender] = 1;
        src  = _src;
        factor = 10 ** (18 - uint256(_dec));
    }

    function read() external view override toll returns (bytes32) {
        (,int256 price,,,) = AggregatorV3Interface(src).latestRoundData();
        require(price > 0, "LinkOracle/invalid-price-feed");
        return bytes32(mul(uint256(price), factor));
    }

    function peek() external view override toll returns (bytes32,bool) {
        (,int256 price,,,) = AggregatorV3Interface(src).latestRoundData();
        return (bytes32(mul(uint256(price), factor)), price > 0);
    }

    function kiss(address a) external note auth {
        require(a != address(0), "LinkOracle/no-contract-0");
        bud[a] = 1;
    }

    function diss(address a) external note auth {
        bud[a] = 0;
    }

    function kiss(address[] calldata a) external note auth {
        for(uint i = 0; i < a.length; i++) {
            require(a[i] != address(0), "LinkOracle/no-contract-0");
            bud[a[i]] = 1;
        }
    }

    function diss(address[] calldata a) external note auth {
        for(uint i = 0; i < a.length; i++) {
            bud[a[i]] = 0;
        }
    }
}