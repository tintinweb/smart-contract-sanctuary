/**
 *Submitted for verification at Etherscan.io on 2021-10-15
*/

// SPDX-License-Identifier: UNLICENSED
//pragma solidity 0.8.0;
pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;


// --- Observations ---
struct UniswapObservation {
    uint timestamp;
    uint price0Cumulative;
    uint price1Cumulative;
}

abstract contract ConverterFeedLike_1 {
    function getResultWithValidity() virtual external view returns (uint256,bool);
}

interface IRaiMedianizer {
    function lastUpdateTime() external view returns (uint256);
    function periodSize() external view returns (uint256);
    function converterFeed() external view returns (ConverterFeedLike_1);
    function uniswapObservations() external view returns (UniswapObservation[] memory);
    function updateResult(address feeReceiver) external;
}

interface IConverterFeed {
    function getResultWithValidity() external view returns  (uint256, bool);
}

interface IResolver {
    function checker()
        external
        view
        returns (bool canExec, bytes memory execPayload);
}

contract GebMath {
    uint256 public constant RAY = 10 ** 27;
    uint256 public constant WAD = 10 ** 18;

    function ray(uint x) public pure returns (uint z) {
        z = multiply(x, 10 ** 9);
    }
    function rad(uint x) public pure returns (uint z) {
        z = multiply(x, 10 ** 27);
    }
    function minimum(uint x, uint y) public pure returns (uint z) {
        z = (x <= y) ? x : y;
    }
    function addition(uint x, uint y) public pure returns (uint z) {
        z = x + y;
        require(z >= x, "uint-uint-add-overflow");
    }
    function subtract(uint x, uint y) public pure returns (uint z) {
        z = x - y;
        require(z <= x, "uint-uint-sub-underflow");
    }
    function multiply(uint x, uint y) public pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "uint-uint-mul-overflow");
    }
    function rmultiply(uint x, uint y) public pure returns (uint z) {
        z = multiply(x, y) / RAY;
    }
    function rdivide(uint x, uint y) public pure returns (uint z) {
        z = multiply(x, RAY) / y;
    }
    function wdivide(uint x, uint y) public pure returns (uint z) {
        z = multiply(x, WAD) / y;
    }
    function wmultiply(uint x, uint y) public pure returns (uint z) {
        z = multiply(x, y) / WAD;
    }
    function rpower(uint x, uint n, uint base) public pure returns (uint z) {
        assembly {
            switch x case 0 {switch n case 0 {z := base} default {z := 0}}
            default {
                switch mod(n, 2) case 0 { z := base } default { z := x }
                let half := div(base, 2)  // for rounding.
                for { n := div(n, 2) } n { n := div(n,2) } {
                    let xx := mul(x, x)
                    if iszero(eq(div(xx, x), x)) { revert(0,0) }
                    let xxRound := add(xx, half)
                    if lt(xxRound, xx) { revert(0,0) }
                    x := div(xxRound, base)
                    if mod(n,2) {
                        let zx := mul(z, x)
                        if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
                        let zxRound := add(zx, half)
                        if lt(zxRound, zx) { revert(0,0) }
                        z := div(zxRound, base)
                    }
                }
            }
        }
    }
}

contract RAIMedianizerResolver is IResolver, GebMath {
    
    
    
    // --- Auth ---
    mapping (address => uint) public authorizedAccounts;
    
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) virtual external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) virtual external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "RAIMedianizerActionProxy/account-not-authorized");
        _;
    }
    
    // --- Variables ---
    address public raiMedianizer;

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event ModifyParameters(
      bytes32 parameter,
      address addr
    );
    
    event ModifyParameters(
      bytes32 parameter,
      uint16 val
    );
    
    constructor(address _raiMedianizer) public {
        raiMedianizer = _raiMedianizer;
        authorizedAccounts[msg.sender] = 1;
    }
    
    // --- Administration ---
    /*
    * @notice Change the addresses of contracts that this wrapper is connected to
    * @param parameter The contract whose address is changed
    * @param addr The new contract address
    */
    function modifyParameters(bytes32 parameter, address addr) external isAuthorized {
        require(addr != address(0), "RAIMedianizerActionProxy/null-addr");
        if (parameter == "raimedianizer") {
          raiMedianizer = addr;
        }
        else revert("RAIMedianizerActionProxy/modify-unrecognized-param");
        
        emit ModifyParameters(
          parameter,
          addr
        );
    }
    
    function checker() external view override returns (bool canExec, bytes memory execPayload) {
        canExec = true;
        
        execPayload = abi.encodeWithSelector(IRaiMedianizer.updateResult.selector, address(0));
        
        uint256 lastUpdateTime = IRaiMedianizer(raiMedianizer).lastUpdateTime();
        uint256 periodSize = IRaiMedianizer(raiMedianizer).periodSize();
        uint256 timeElapsedSinceLatest = subtract(now, lastUpdateTime);
        
        // We only want to commit updates once per period (i.e. windowSize / granularity)
        if (timeElapsedSinceLatest < periodSize) {
            return (false, execPayload);
        } 
        
        ConverterFeedLike_1 converterFeed = IRaiMedianizer(raiMedianizer).converterFeed();
        (, bool valid) = converterFeed.getResultWithValidity();
        
        if (!valid) {
            return (false, execPayload);
        }
    }
}