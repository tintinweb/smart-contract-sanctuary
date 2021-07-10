/**
 *Submitted for verification at polygonscan.com on 2021-07-10
*/

// Improvements:
// - Collect the current price of the token (expensive)
// - Cache token info (name, symbol)
// - Add generic fallback function that simply takes the first bytes of the poolInfo and userInfo

struct Pool {
    string symbol;
    string name;
    address want;
    uint256 allocPoint;
    uint16 depFee;
    uint256 amount;
    uint256 total;
    bool isFallback;
    uint8 decimals;
}

interface IERC20 {
    function name() external view returns (string calldata);
    function symbol() external view returns (string calldata);
    function balanceOf(address user) external view returns (uint256);
    function decimals() external view returns (uint8);
}

interface Pair is IERC20 {
    function token0() external view returns (address);
    function token1() external view returns (address);
}

interface Masterchef {
    function poolInfo(uint256 pid) external view returns (address want, uint256 allocPoint, uint256 lastRewardBlock, uint256 accBELTPerShare,uint16 depFee);
    function userInfo(uint256 _pid, address _user) external view returns (uint256 shares, uint256 rewardDebt);
    function poolLength() external view returns (uint256);
}

contract MCChecker {
    // isStandardChef finds out if the poolInfo method is the standard one (panther uses a different one).
    function isStandardChef(Masterchef mc) public view returns (bool) {
        try mc.poolInfo(0) returns (address, uint256, uint256, uint256, uint16) {
            return true;
        } catch {
            return false;
        }
    }
    
}


contract Fetcher {
    MCChecker public checker;
    
    constructor() {
        checker = new MCChecker();
    }
    function fetchPools(address _masterchef, address user, uint256 start, uint256 limit) public view returns (Pool[] memory) {
        Masterchef mc = Masterchef(_masterchef);
        
        // get poolLength
        uint256 poolLength = 0;
        try mc.poolLength() returns (uint256 _poolLength) {
            poolLength = _poolLength;
        } catch {
            revert("E0 Address is not a masterchef");
        }
        
        // Reduce poolLength to what we can fetch
        if (start + limit < poolLength) {
            poolLength = start + limit;
        }
        
        Pool[] memory pools = new Pool[](poolLength);
        if(poolLength == 0 || start >= poolLength) {
            return pools;
        }
         // In case the masterchef implements the standard poolInfo
        if(isStandardChef(mc)) {
            for (uint256 pid = start; pid < poolLength; pid++) {
                 pools[pid - start] = getPoolStandard(mc, pid, user);
            }
        }else { // otherwise we fall back to a very generic low-level call implementation
            for (uint256 pid = start; pid < poolLength; pid++) {
                 pools[pid - start] = getPoolFallback(mc, pid, user);
            }
        }
        
        return pools;
    }
    
    function getPoolStandard(Masterchef mc, uint256 pid, address user) public view returns (Pool memory) {
         (address want, uint256 allocPoint,,,uint16 depFee) = mc.poolInfo(pid);
        // fetch token name and symbol
        (string memory name, string memory symbol, uint8 decimals) = getTokenDetails(want);
                
        (uint256 amount, ) = mc.userInfo(pid, user);
        return Pool({
            symbol: symbol,
            name: name,
            want: want,
            allocPoint: allocPoint,
            depFee: depFee,
            amount: amount,
            total: getTotal(address(mc), want),
            isFallback: false,
            decimals: decimals
        });
    }
    
    // Uses low-level calls and assume the first bytes returned are the pool address for poolInfo and the first bytes returned are the user amount for userInfo.
    function getPoolFallback(Masterchef mc, uint256 pid, address user) public view returns (Pool memory) {
        (bool success, bytes memory data) = address(mc).staticcall(abi.encodeWithSignature("poolInfo(uint256)", pid));
        require(success, "!fallback poolInfo failed");
        
        address want = getAddressFromBytes(data);
        (string memory name, string memory symbol, uint8 decimals) = getTokenDetails(want);
        
        uint256 amount = 0;
        (bool userSuccess, bytes memory userData) = address(mc).staticcall(abi.encodeWithSignature("userInfo(uint256,address)", pid, user));
        if (userSuccess) {
            amount = getUint32FromBytes(userData);
        }
        
        return Pool({
            symbol: symbol,
            name: name,
            want: want,
            allocPoint: 0,
            depFee: 0,
            amount: amount,
            total: getTotal(address(mc), want),
            isFallback: true,
            decimals: decimals
        });
    }
    
    function getTotal(address mc, address token) public view returns (uint256) {
        try IERC20(token).balanceOf(mc) returns (uint256 total) {
            return total;
        } catch {
            return 0;
        }
    }
    
    function getTokenDetails(address token) public view returns (string memory name, string memory symbol, uint8 decimals) {
         decimals = 18;
         try IERC20(token).decimals() returns (uint8 dec){
             decimals = dec;
         }catch{}
         
         // Try to return the underlying token details in case it's an LP pair
         try Pair(token).token0() returns (address token0) {
             try Pair(token).token1() returns (address token1) {
                 (, string memory symbol1) = getTokenName(token0);
                 (, string memory symbol2) = getTokenName(token1);
                 name = string(abi.encodePacked(symbol1, " / ", symbol2, " LP"));
                 symbol = string(abi.encodePacked(symbol1, " / ", symbol2));
                 
                 return (name, symbol, decimals);
             } catch {}
        } catch {}
        
        // Just return the token details if it's not an LP pair.
        (name, symbol) = getTokenName(token);
        return (name, symbol, decimals);
    }
    
    function getTokenName(address token) public view returns (string memory name, string memory symbol) {
        name = "UNKNOWN";
        symbol = "UNKNOWN";
        try IERC20(token).name() returns (string memory _name) {
            name = _name;
        } catch {}
        
        try IERC20(token).symbol() returns (string memory _symbol) {
            symbol = _symbol;
        } catch {}
        
        return (name, symbol);
    }
    
    // isStandardChef finds out if the poolInfo method is the standard one (panther uses a different one).
    function isStandardChef(Masterchef mc) public view returns (bool) {
        try checker.isStandardChef(mc) returns (bool isStandard) { // we need an extra layer as abi.decode errors are not caught by try-catch
            return isStandard;
        } catch {
            return false;
        }
    }
    
        
    // converts the return data to the first address found in it (pads 12 bytes because address only ocupies 20/32 bytes.)
    function getAddressFromBytes(bytes memory _address) public pure returns (address) {
        uint160 m = 0;
        uint8 b = 0;

        for (uint8 i = 12; i < 32; i++) {
            m *= 256;
            b = uint8(_address[i]);
            m += b;
        }
        return address(m);
    }
    
    // converts the return data to the first uint256 found in it
    function getUint32FromBytes(bytes memory _uint256) public pure returns (uint256) {
        uint256 m = 0;
        uint8 b = 0;

        for (uint8 i = 0; i < 32; i++) {
            m *= 256;
            b = uint8(_uint256[i]);
            m += b;
        }

        return m;
    }
}