/**
 *Submitted for verification at polygonscan.com on 2021-10-18
*/

// File: polycrystal-on-chain-stats/contracts/libraries/Babylonian.sol



pragma solidity >=0.8.0;

// computes square roots using the babylonian method
// https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
library Babylonian {
    // credit for this implementation goes to
    // https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol#L687
    function sqrt(uint256 x) internal pure returns (uint256) {
        unchecked { //impossible for any of this to overflow
            if (x == 0) return 0;
            // this block is equivalent to r = uint256(1) << (BitMath.mostSignificantBit(x) / 2);
            // however that code costs significantly more gas
            uint256 xx = x;
            uint256 r = 1;
            if (xx >= 0x100000000000000000000000000000000) {
                xx >>= 128;
                r <<= 64;
            }
            if (xx >= 0x10000000000000000) {
                xx >>= 64;
                r <<= 32;
            }
            if (xx >= 0x100000000) {
                xx >>= 32;
                r <<= 16;
            }
            if (xx >= 0x10000) {
                xx >>= 16;
                r <<= 8;
            }
            if (xx >= 0x100) {
                xx >>= 8;
                r <<= 4;
            }
            if (xx >= 0x10) {
                xx >>= 4;
                r <<= 2;
            }
            if (xx >= 0x8) {
                r <<= 1;
            }
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1; // Seven iterations should be enough
            uint256 r1 = x / r;
            return (r < r1 ? r : r1);
        }
    }
}

// File: polycrystal-on-chain-stats/contracts/libraries/FullMath.sol


pragma solidity ^0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }
        unchecked {
            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            uint256 twos = (type(uint256).max - denominator + 1) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }
    
            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;
    
            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256
    
            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

// File: polycrystal-on-chain-stats/contracts/interfaces/IUniPair.sol



pragma solidity ^0.8.0;

interface IUniPair {
    
    function kLast() external view returns (uint);
    function getReserves() external view returns (uint112, uint112, uint32);
    function totalSupply() external view returns (uint256);
}
// File: polycrystal-on-chain-stats/contracts/interfaces/IStrategy.sol



pragma solidity >=0.6.12;

// For interacting with our own strategy
interface IStrategy {
    // Want address
    function wantAddress() external view returns (address);
    
    // Total want tokens managed by strategy
    function wantLockedTotal() external view returns (uint256);

    // Sum of all shares of users to wantLockedTotal
    function sharesTotal() external view returns (uint256);

    // Main want token compounding function
    function earn() external;
    
    // Main want token compounding function
    function earn(address compounder) external;

    // Transfer want tokens autoFarm -> strategy
    function deposit(address _from, address _to, uint256 _wantLocked, uint256 _wantAmt) external returns (uint256);

    // Transfer want tokens strategy -> vaultChef
    function withdraw(address _from, address _to, uint256 _wantLocked, uint256 _wantAmt) external returns (uint256);
    
    //Call before depositing
    function _beforeDeposit(address _from, address _to) external;
    
    function paused() external returns (bool);
    
    //for fees
    function setAddresses(address _rewardAddress, address _withdrawFeeAddress, address _buyBackAddress) external;
    
    function burnedAmount() external view returns (uint256);
    
    function lastEarnBlock() external view returns (uint256);
}
// File: polycrystal-on-chain-stats/contracts/LapisLazuli.sol



pragma solidity ^0.8.0;

/*
Join us at Crystl.Finance!
 █▀▀ █▀▀█ █░░█ █▀▀ ▀▀█▀▀ █░░ 
 █░░ █▄▄▀ █▄▄█ ▀▀█ ░░█░░ █░░ 
 ▀▀▀ ▀░▀▀ ▄▄▄█ ▀▀▀ ░░▀░░ ▀▀▀
*/





contract LapisLazuli {
    
    address constant DEV_ADDRESS = 0x0894417Dfc569328617FC25DCD6f0B5F4B0eb323; 
    uint16 constant BLOCKS_PER_BLOCKHOUR = 1800;
    
    enum SubjectType { NULL, LP, STRATEGY, STRATEGY_BURN }
    
    struct SampleData {
        SubjectType sType;
        uint40 firstBlockhour;
        uint40 lastBlockhour;
        mapping (uint40 => SampleHour) hourly;
    }
    struct SampleHour {
        uint240 ratio;
        uint16 tick;
        uint128 wantLocked;
        uint128 burnedAmount;
    }
    
    event HourlyData(address indexed subject, uint40 indexed hour, uint240 ratio);
    
    mapping(address => SampleData) subjects;
    
    mapping(address => address[]) watchlist; //watchlist[user][i]
    mapping(address => mapping(address => bool)) watched; //watched[user][subject]
    struct WatchlistInfo {
        address[] list;
        uint spot;
        mapping(address => bool) isWatched;
    }
    mapping (address => WatchlistInfo) userWatch;
    
    function getData(address _subject) external view returns (uint40 firstBlockhour, SampleHour memory _begin, uint40 lastBlockhour, SampleHour memory _finish) {
        SampleData storage subject = subjects[_subject];
        return getData(_subject, subject.firstBlockhour, subject.lastBlockhour);
    }
    function getData(address _subject, uint40 _start, uint40 _end) public view returns (uint40 start, SampleHour memory _begin, uint40 end, SampleHour memory _finish) {
        SampleData storage subject = subjects[_subject];
        start = _start;
        end = _end;
        
        mapping (uint40 => SampleHour) storage hourly = subject.hourly;
        _begin = hourly[_start];
        _finish = hourly[_end];
    }
    function watch(address[] memory _subjects) public {
        for (uint i; i < _subjects.length; i++) {
            bool success = update(_subjects[i]);
            if (success && !watched[msg.sender][_subjects[i]]) {
                watched[msg.sender][_subjects[i]] = true;
                watchlist[msg.sender].push() = _subjects[i];
            }
        }
    }
    function clearWatchlist() external {
        for (uint i; i < watchlist[msg.sender].length; i++) {
            watched[msg.sender][watchlist[msg.sender][i]] = false;
        }
        delete watchlist[msg.sender];
    }
    function updateWatched() public {
        for (uint i; i < watchlist[msg.sender].length; i++) {
            update(watchlist[msg.sender][i]);
        }
    }
    function update(address subject) public returns (bool success) {
        SampleData storage data = subjects[subject];
        
        //Initialize subject if not already
        if (data.sType == SubjectType.NULL) {
            
            try IStrategy(subject).wantLockedTotal() returns (uint) {
                try IStrategy(subject).burnedAmount() returns (uint) {
                    data.sType = SubjectType.STRATEGY_BURN;
                } catch {
                    data.sType = SubjectType.STRATEGY;
                }
            } catch {
                try IUniPair(subject).kLast() returns (uint) {
                    data.sType = SubjectType.LP;
                } catch {
                    return false;
                }
            }
            
            uint40 __hour = currentBlockhour();
            data.firstBlockhour = __hour;
            data.lastBlockhour = __hour;
        }
        uint240 ratio;
        uint128 _wantLocked;
        uint128 _burnedAmount;
        if (data.sType == SubjectType.LP) {
            ratio = getrootKtoSupplyRatio(IUniPair(subject));
        } else { // must be a strategy at this point
            if (data.sType == SubjectType.STRATEGY_BURN) {
                (ratio, _wantLocked, _burnedAmount) = getStrategyData(IStrategy(subject), true);
            } else {
                (ratio, _wantLocked,) = getStrategyData(IStrategy(subject), true);
            }
                
        }
        (uint40 _hour, uint16 _tick) = currentBHBT();

        if (data.lastBlockhour + 1 == _hour) { // close previous hour before starting new one
            SampleHour storage oldHourly = data.hourly[_hour - 1];
            SampleHour storage newHourly = data.hourly[_hour];
            
            uint16 span = uint16(block.number - BHBTtoBlockNumber(_hour - 1, oldHourly.tick));
            int240 change = int240(ratio) - int240(oldHourly.ratio);
            
            uint16 oldSpan = span - _tick;
            
            oldHourly.ratio = uint240(int240(oldHourly.ratio) + int240(change * int240(uint240(oldSpan)) / int240(uint240(span))));
            oldHourly.tick = BLOCKS_PER_BLOCKHOUR;
            emit HourlyData(subject, _hour - 1, oldHourly.ratio);
            data.lastBlockhour = _hour;
            
            uint16 oldWeight = _tick / 2;
            uint16 newWeight = _tick - oldWeight;
            newHourly.ratio = (oldHourly.ratio * oldWeight + ratio * newWeight) / _tick;
            newHourly.tick = _tick;
        } else if (data.lastBlockhour == _hour) {
            SampleHour storage hourly = data.hourly[_hour];
            if (hourly.ratio == 0) {
                hourly.ratio = ratio;
                hourly.tick = _tick;
            } else if (hourly.tick != _tick) { // once per block
                uint16 span = _tick - hourly.tick;
                uint16 oldWeight = hourly.tick + span / 2;
                uint16 newWeight = _tick - oldWeight;
                hourly.ratio = (hourly.ratio * oldWeight + ratio * newWeight) / _tick;
                hourly.tick = _tick;
                //no weighted average thing here yet
                hourly.wantLocked = _wantLocked;
                hourly.burnedAmount = _burnedAmount;
                
            }
            return true;
        }

    }
    
    function getrootKtoSupplyRatio(IUniPair lpToken) public view returns (uint240 ratio) {
        
        (uint reserve0, uint reserve1,) = lpToken.getReserves();
        uint rootK = Babylonian.sqrt(reserve0 * reserve1);
        return uint240(FullMath.mulDiv(rootK, 2**128, lpToken.totalSupply())); //rootK per token in UQ112x128
    }
    
    function getTokenToShareRatio(IStrategy strat) public view returns (uint240 ratio) {
        
        uint tokens = strat.wantLockedTotal();
        uint shares = strat.sharesTotal();
        return uint240(FullMath.mulDiv(tokens, 2**128, shares)); //tokens per share in UQ112x128 format
    }
    
    function getStrategyData(IStrategy strat, bool burned) public view returns (uint240 ratio, uint128 wantLocked, uint128 burnedAmount) {
        
        uint _wantLocked = strat.wantLockedTotal();
        uint shares = strat.sharesTotal();
        ratio =  uint240(FullMath.mulDiv(wantLocked, 2**128, shares)); //tokens per share in UQ112x128 format
        
        while (_wantLocked > type(uint128).max) _wantLocked /= 256;
        wantLocked = uint128(_wantLocked);
        
        if (burned) {
            uint _burnedAmount = strat.burnedAmount();
            while (_burnedAmount > type(uint128).max) _burnedAmount /= 256;
            burnedAmount = uint128(_burnedAmount);
        }
    }
    
    function currentBHBT() public view returns (uint40, uint16) {
        return (currentBlockhour(), currentBlocktick());
    }
    
    function currentBlockhour() public view returns (uint40) {
        return uint40(block.number / BLOCKS_PER_BLOCKHOUR);
    }
    //"Blockticks" are Blockhour:Blocktick in the same sense as HH:MM
    function currentBlocktick() public view returns (uint16) {
        return uint16(block.number % BLOCKS_PER_BLOCKHOUR);
    }
    function BHBTtoBlockNumber(uint40 blockhour, uint16 blocktick) public pure returns (uint48 blockNumber) {
        return uint48(blockhour * BLOCKS_PER_BLOCKHOUR + blocktick);
    }
}
// File: polycrystal-on-chain-stats/contracts/StrategyLapisLazuli.sol


pragma solidity ^0.8.4;


interface IVaultHealer {
    function poolLength() external view returns (uint);
    function poolInfo(uint n) external view returns (address, address);
    function owner() external view returns (address);
}

contract StrategyLapisLazuli is LapisLazuli {

    mapping(address => mapping(IVaultHealer => uint)) vhScanDepth; //number of pools known
    
    //pausable on an address basis;
    mapping(address => bool) _paused;
    
    modifier auth(address target) {
        require(msg.sender == target || isOwnedBySender(target), "unauthorized");
        _;
    }
    //for vaulthealer compatibility
    function approve(address,uint) external pure returns (bool) { return true; }
    function allowance(address,address) external pure returns (uint) { return 0; }
    function wantAddress() external view returns (address) { return address(this); }
    
    function earn(address) external {
        updateWatched();
        scanVaultHealer(IVaultHealer(msg.sender));
    }
    function scanVaultHealer(IVaultHealer vaultHealer) public {
        uint scanNext = vhScanDepth[msg.sender][vaultHealer];
        uint len = vaultHealer.poolLength();
        if (len > scanNext) {
            address[] memory targets = new address[]((len - scanNext) * 2);
        
            for (uint i = scanNext; i < len; i++) {
                (targets[2*i], targets[2*i + 1]) = vaultHealer.poolInfo(i);
            }
            watch(targets);
            vhScanDepth[msg.sender][vaultHealer] = len;
        }
    }
    
    //pause-related
    function pause(address vaultHealer) external auth(vaultHealer) {
        require(!_paused[vaultHealer], "already paused");
        _paused[vaultHealer] = true;
    }
    function unpause(address vaultHealer) external auth(vaultHealer) {
        require(_paused[vaultHealer], "already unpaused");
        _paused[vaultHealer] = false;
    }
    function paused(address vaultHealer) external view returns (bool) {
        return _paused[vaultHealer];
    }
    function paused() public view returns (bool) {
        return _paused[msg.sender];
    }
    function isOwnedBySender(address vaultHealer) private view returns (bool) {
        try IVaultHealer(vaultHealer).owner() returns (address _owner) {
            if (_owner == msg.sender) return true;
            return false;
        } catch {
            return false;
        }
    }
    //disabled functions
    function nonTokenStrategyRevert() private pure {
        revert("Strategy does not handle tokens");
    }
    function deposit(address, uint256) external pure { nonTokenStrategyRevert(); }
    function withdraw(address, uint256) external pure { nonTokenStrategyRevert(); }
    function wantLockedTotal() external pure { nonTokenStrategyRevert(); }
    function sharesTotal() external pure { nonTokenStrategyRevert(); }
}