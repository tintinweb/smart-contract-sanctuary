/**
 *Submitted for verification at Etherscan.io on 2021-09-02
*/

// SPDX-License-Identifier: NLPL
pragma solidity >=0.5.10;

contract median {
    function recover(uint256 val_, uint256 age_, uint8 v, bytes32 r, bytes32 s) internal view returns (address) {
        return ecrecover(
            keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(val_, age_, wat)))),
            v, r, s
        );
    }

    mapping(address => uint) public wards;

    uint128        val;
    uint32  public age;
    bytes32 public wat;
    uint256 public bar = 1;

    event LogMedianPrice(uint256 val, uint256 age);

    // Authorized oracles, set by an auth
    mapping(address => uint256) public feeds;

    // Permitted contracts, set by an auth
    mapping(address => uint256) public buds;

    // Mapping for at most 256 oracles
    mapping(uint8 => address) public slots;

    constructor(bytes32 wat_) {
        wat = wat_;
        wards[msg.sender] = 1;
    }

    function poke(
        uint256[] calldata val_, uint256[] calldata age_,
        uint8[] calldata v, bytes32[] calldata r, bytes32[] calldata s) external
    {
        require(val_.length == bar, "median/bar-too-low");

        uint256 bloom = 0;
        uint256 last = 0;
        uint256 zzz = age;

        for (uint i = 0; i < val_.length; i++) {
            // Validate the values were signed by an authorized oracle
            address signer = recover(val_[i], age_[i], v[i], r[i], s[i]);
            // Check that signer is an oracle
            require(feeds[signer] == 1, "median/invalid-oracle");
            // Price feed age greater than last medianizer age
            require(age_[i] > zzz, "median/stale-message");
            // Check for ordered values
            require(val_[i] >= last, "median/messages-not-in-order");
            last = val_[i];
            // Bloom filter for signer uniqueness
            uint8 sl = uint8(uint160(signer) >> 152);
            require((bloom >> sl) % 2 == 0, "median/oracle-already-signed");
            bloom += uint256(2) ** sl;
        }

        val = uint128(val_[val_.length >> 1]);
        age = uint32(block.timestamp);

        emit LogMedianPrice(val, age);
    }

    modifier toll {
        require(buds[msg.sender] == 1, "median/not-permitted");
        _;
    }

    function read() external view toll returns (uint256) {
        require(val > 0, "median/invalid-price");
        return val;
    }

    function peek() external view toll returns (uint256, bool) {
        return (val, val > 0);
    }

    modifier auth {
        require(wards[msg.sender] == 1, "median/not-authorized");
        _;
    }

    function rely(address usr) external auth {wards[usr] = 1;}

    function deny(address usr) external auth {wards[usr] = 0;}

    function lift(address[] calldata a) external auth {
        for (uint i = 0; i < a.length; i++) {
            require(a[i] != address(0), "median/no-oracle-0");
            uint8 s = uint8(uint160(a[i]) >> 152);
            require(slots[s] == address(0), "median/signer-already-exists");
            feeds[a[i]] = 1;
            slots[s] = a[i];
        }
    }

    function drop(address[] calldata a) external auth {
        for (uint i = 0; i < a.length; i++) {
            feeds[a[i]] = 0;
            slots[uint8(uint160(a[i]) >> 152)] = address(0);
        }
    }

    function setBar(uint256 bar_) external auth {
        require(bar_ > 0, "median/quorum-is-zero");
        require(bar_ % 2 != 0, "median/quorum-not-odd-number");
        bar = bar_;
    }

    function kiss(address a) external auth {
        require(a != address(0), "median/no-contract-0");
        buds[a] = 1;
    }

    function diss(address a) external auth {
        buds[a] = 0;
    }

    function kiss(address[] calldata a) external auth {
        for (uint i = 0; i < a.length; i++) {
            require(a[i] != address(0), "median/no-contract-0");
            buds[a[i]] = 1;
        }
    }

    function diss(address[] calldata a) external auth {
        for (uint i = 0; i < a.length; i++) {
            buds[a[i]] = 0;
        }
    }
}