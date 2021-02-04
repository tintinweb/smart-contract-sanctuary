/**
 *Submitted for verification at Etherscan.io on 2021-02-04
*/

//SPDX-License-Identifier: UNLICENSED
//Check before deployment: Hardcoded token contract address, pair address

/*
Generic presale contract for ERC20 token.
Important: Set gas limit to 210000 if sending ether directly! It reserves much but consumes max 80%.

Presale allows buying specified ERC20 for rate mentioned in constructor.
Allowed amounts: 0.05 ETH to 0.5 ETH.
Presale ends once there is no supply left.
Once eth is sent to this presale contract sender gets their tokens, eth is wrapped and sent 
directly to the liquidity pool along with the same amount of tokens. The pool is synced 
to reflect new ratio right away and calculates token price correctly.
Neither ERC20 nor ETH goes to any wallet except token to buyer. Deployer will receive no ether 
from this presale.
This makes liquidity continuously inflating and keeping price near presale price ratio
by keeping either the presale or direct uniswap trade cheaper at every moment.
Once presale ends there is enough ether liquidity and the price can start going up!

*/

pragma solidity =0.7.6;

interface UNIV2Sync {
    function sync() external;
}

interface IERC {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function feeDistributor() external view returns (address);
}

interface IWETH {
    function deposit() external payable;
    function balanceOf(address _owner) external returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool);
    function withdraw(uint256 _amount) external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


contract ERC20Presale {
    using Address for address;

    address public token;
    address public pair;
    address public wethContract;
    uint256 public rate;
    uint256 public weiRaised;
    
    constructor() {
        rate = 5e9; //16.5M2e = 8 eth -> 2M2e = 2e8 = 1/5 e9 = 1e18 wei/5e9, 1M2e = 0.5
        weiRaised = 0;
        token = 0x8937041C8C52a78c25aa54051F6a9dAdA23D42A2; //mainnet
        pair = 0x76d629ebAD7fDf703Ed5923f41F20c472e8F23E3; //mainnet
        //wethContract = 0xc778417E063141139Fce010982780140Aa0cD5Ab; //ropsten
        wethContract = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; //mainnet
    }

    receive() external payable {
        buyTokens(msg.sender);
    }
    
    function buyTokens(address _beneficiary) public payable {
        require(msg.sender == tx.origin); //no automated arbitrage
        require(_beneficiary != address(0));
        require(msg.value >= 5e16 wei && msg.value <= 5e17 wei);
        uint256 tokens = msg.value/rate; 
        weiRaised+=msg.value;
        IERC(token).transfer(_beneficiary,tokens);
        IERC(token).transfer(pair,tokens);
        //Convert any ETH to WETH (always).
        uint256 amountETH = address(this).balance;
        if (amountETH > 0) {
            IWETH(wethContract).deposit{value : amountETH}();
        }
        uint256 amountWETH =  IWETH(wethContract).balanceOf(address(this));
        //Sends weth to pool
        if (amountWETH > 0) {
            IWETH(wethContract).transfer(pair, amountWETH);
        }
        UNIV2Sync(pair).sync(); //important to reflect updated price
    }
}