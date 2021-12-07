/**
 *Submitted for verification at polygonscan.com on 2021-12-07
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IChef {

    function poolLength() external view returns (uint256);
    function lpToken(uint256) external view returns (address);
}
interface IToken {
    function totalSupply() external view returns (uint256);
    function token0() external view returns (address);
    function token1() external view returns (address);
}

contract RamsayScope {

    function chefInfo(address contestant) external view returns (uint poolLength, string memory signature, address[] memory wantTokens, address[] memory tokens0, address[] memory tokens1) {

        try IChef(contestant).poolLength() returns (uint _len) {
            require(_len > 0, "This chef is RAW");
            poolLength = _len;
        } catch {
            poolLength = 1;
        }

        wantTokens = new address[](poolLength);
        tokens0 = new address[](poolLength);
        tokens1 = new address[](poolLength);
        bool success;
        bytes memory data;

        if (poolLength == 1) {
            signature = "poolInfo()";
            (success, data) = contestant.staticcall(abi.encodeWithSignature(signature));
            if (success) {
                (address token,) = abi.decode(data,(address,bytes));
                (success, tokens0[0], tokens1[0]) = tokenInfo(token);
                if (success) {
                    wantTokens[0] = token;
                    return (poolLength, signature, wantTokens, tokens0, tokens1);
                }
            }
            signature = "stakingToken()";
            (success, data) = contestant.staticcall(abi.encodeWithSignature(signature));
            if (success) {
                address token = abi.decode(data,(address));
                (success, tokens0[0], tokens1[0]) = tokenInfo(token);
                if (success) {
                    wantTokens[0] = token;
                    return (poolLength, signature, wantTokens, tokens0, tokens1);
                }
            }
            signature = "lpToken()";
            (success, data) = contestant.staticcall(abi.encodeWithSignature(signature));
            if (success) {
                address token = abi.decode(data,(address));
                (success, tokens0[0], tokens1[0]) = tokenInfo(token);
                if (success) {
                    wantTokens[0] = token;
                    return (poolLength, signature, wantTokens, tokens0, tokens1);
                }
            }
        }

        signature = "lpToken(uint256)";
        (success, data) = contestant.staticcall(abi.encodeWithSignature(signature,0));
        if (success) {
            (address token,) = abi.decode(data,(address,bytes));
            (success, tokens0[0], tokens1[0]) = tokenInfo(token);
            if (success) {
                wantTokens[0] = token;
                for (uint i = 1; i < poolLength; i++) {
                    (success, data) = contestant.staticcall(abi.encodeWithSignature(signature,0));
                    if (!success) continue;
                    (success, tokens0[0], tokens1[0]) = tokenInfo(token);
                    if (success) wantTokens[i] = token;
                }
                return(poolLength, signature, wantTokens, tokens0, tokens1);
            }
        }
        signature = "poolInfo(uint256)";
        (success, data) = contestant.staticcall(abi.encodeWithSignature(signature,0));
        if (success) {
            (address token,) = abi.decode(data,(address,bytes));
            (success, tokens0[0], tokens1[0]) = tokenInfo(token);
            if (success) {
                wantTokens[0] = token;
                for (uint i = 1; i < poolLength; i++) {
                    (success, data) = contestant.staticcall(abi.encodeWithSignature(signature,0));
                    if (!success) continue;
                    (success, tokens0[0], tokens1[0]) = tokenInfo(token);
                    if (success) wantTokens[i] = token;
                }
                return(poolLength, signature, wantTokens, tokens0, tokens1);
            }
        }


    }

    function tokenInfo(address _token) public view returns (bool isToken, address token0, address token1) {

        
        try IToken(_token).token0() returns (address _token0) {
            try IToken(_token).token1() returns (address _token1) {
                return (true, _token0, _token1);
            } catch {}
        } catch {}

        try IToken(_token).totalSupply() returns (uint256) {
            return (true, address(0), address(0));
        } catch {}

        return (false, address(0), address(0));
    }


// "poolInfo()"
//        
   //     "poolInfo(uint256)"
  //      "rewardsToken()"
     //   "stakingToken()"
    
}