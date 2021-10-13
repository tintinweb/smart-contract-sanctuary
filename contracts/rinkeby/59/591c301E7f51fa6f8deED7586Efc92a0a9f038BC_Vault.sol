/**
 *Submitted for verification at Etherscan.io on 2021-10-13
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function mint(address to, uint256 value) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function burn(uint256 value) external returns (bool);

    
}

pragma solidity 0.7.4;

// A library for performing overflow-safe math, courtesy of DappHub: https://github.com/dapphub/ds-math/blob/d0ef6d6a5f/src/math.sol
// Modified to include only the essentials
library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "MATH:: ADD_OVERFLOW");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "MATH:: SUB_UNDERFLOW");
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "MATH:: MUL_OVERFLOW");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "MATH:: DIVISION_BY_ZERO");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }


}

pragma solidity 0.7.4;

interface IVault {

    function initializeVault(address token0,address token1) external;

    function withdrawFunds(address token,address recipient,uint256 amount) external;

    function addPool() external;

    function depositFunds(address token,uint256 amount) external;
}


contract Vault is IVault {
    using SafeMath for uint256;


    struct poolBalance{
        uint256 tokenBalance0;
        uint256 tokenBalance1;
        address token0Address;
        address token1Address;
        bool isInitialzed;
    }

    mapping(address=>poolBalance) poolDetails;

    function initializeVault(address token0,address token1) override external{
        address sender = msg.sender;

        require(poolDetails[sender].token0Address==address(0),"Pool already Initialized");
        if(token0<token1){
            poolDetails[sender].token0Address = token0;
            poolDetails[sender].token1Address = token1;
        }
        else{
            poolDetails[sender].token0Address = token1;
            poolDetails[sender].token1Address = token0;
        }

        poolDetails[sender].tokenBalance0 = 0;
        poolDetails[sender].tokenBalance1 = 0;
        poolDetails[sender].isInitialzed = true;

    }


    function withdrawFunds(address token,address recipient,uint256 amount) override external {
        address sender = msg.sender;
        require(IERC20(token).balanceOf(address(this))>=amount,"Funds not present in Vault");
        require(poolDetails[sender].isInitialzed,"Only Factory and execute this function");
        require(token==poolDetails[sender].token0Address || token==poolDetails[sender].token1Address,"Invalid Token Requested");
        if(token==poolDetails[sender].token0Address){
            require(poolDetails[sender].tokenBalance0>=amount,"Amount exceeds balance in Vault");
            poolDetails[sender].tokenBalance0 = poolDetails[sender].tokenBalance0.sub(amount);
        }

        else{
            require(poolDetails[sender].tokenBalance1>=amount,"Amount exceeds balance in Vault");
            poolDetails[sender].tokenBalance1 = poolDetails[sender].tokenBalance1.sub(amount);
        }

        IERC20(token).transfer(recipient,amount);
    }

    function depositFunds(address token,uint256 amount) override external{
        address sender = msg.sender;
        require(poolDetails[sender].isInitialzed,"Only Initialized Pools");
        if(token==poolDetails[sender].token0Address){
            poolDetails[sender].tokenBalance0 = poolDetails[sender].tokenBalance0.add(amount);
        }

        else{
            poolDetails[sender].tokenBalance1 = poolDetails[sender].tokenBalance1.add(amount);
        }

        IERC20(token).transferFrom(sender,address(this),amount);

    }

    function addPool() override external{
        
    }

    



}