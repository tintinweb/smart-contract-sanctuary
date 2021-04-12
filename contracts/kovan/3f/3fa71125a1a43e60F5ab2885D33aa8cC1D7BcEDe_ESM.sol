/**
 *Submitted for verification at Etherscan.io on 2021-04-12
*/

pragma solidity >=0.5.12;

////// src/ESM.sol
/* pragma solidity >=0.5.12; */

interface GemLike {
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
}

interface EndLike {
    function cage() external;
}

contract ESM {
    GemLike public gem; // collateral
    EndLike public end; // cage module
    address public pit; // burner
    uint256 public min; // threshold
    uint256 public fired;

    mapping(address => uint256) public sum; // per-address balance
    uint256 public Sum; // total balance

    // --- Logs ---
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
            let mark := msize()                       // end of memory ensures zero
            mstore(0x40, add(mark, 288))              // update free memory pointer
            mstore(mark, 0x20)                        // bytes type data offset
            mstore(add(mark, 0x20), 224)              // bytes size (padded)
            calldatacopy(add(mark, 0x40), 0, 224)     // bytes payload
            log4(mark, 288,                           // calldata
                 shl(224, shr(224, calldataload(0))), // msg.sig
                 caller(),                            // msg.sender
                 calldataload(4),                     // arg1
                 calldataload(36)                     // arg2
                )
        }
    }

    constructor(address gem_, address end_, address pit_, uint256 min_) public {
        gem = GemLike(gem_);
        end = EndLike(end_);
        pit = pit_;
        min = min_;
    }

    // -- math --
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x + y;
        require(z >= x);
    }

    function fire() external note {
        require(fired == 0,  "esm/already-fired");
        require(Sum >= min,  "esm/min-not-reached");

        end.cage();

        fired = 1;
    }

    function join(uint256 wad) external note {
        require(fired == 0, "esm/already-fired");

        sum[msg.sender] = add(sum[msg.sender], wad);
        Sum = add(Sum, wad);

        require(gem.transferFrom(msg.sender, pit, wad), "esm/transfer-failed");
    }
}