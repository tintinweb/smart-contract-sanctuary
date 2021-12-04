// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;

//The burn pit is a step above a simple burn address 
//It will serve the community by collecting a redistributing fees
//Oscillating between 50-51%

import "./ERC20.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./Address.sol";

contract BurnPit is Context, Ownable {
    using SafeMath for uint256;
    using Address for address;

    uint256 public lastRebalance;
    uint256 public lowerboundPercentage = 50;
    uint256 public upperboundPercentage = 51;

    IERC20 public immutable token;

    event Rebalance(uint256 tokens);

    constructor (ERC20 _token) {

        //get a handle on the token
        token = IERC20(_token);

        //a rebalance isn't necessary at launch
        lastRebalance =  block.timestamp;
    }

    function rebalance() external {
            
        //we should rebalance when we get more than target percentage of the supply in the graveyard
        uint256 upper = token.totalSupply().mul(upperboundPercentage).div(100);
        uint256 lower = token.totalSupply().mul(lowerboundPercentage).div(100);
        uint256 total = token.balanceOf(address(this));

        //airdrop the difference by sending back to the token contract which will 
        //split rewards and locked liquidity 
        if (total > upper){
            uint256 airdrop = total.sub(lower);

            //send airdrop to token where it will be added to liquidity 
            token.transfer(address(token), airdrop);
            
            lastRebalance = block.timestamp;

            emit Rebalance(airdrop);
        }
    }

    function ready() external view returns (bool) {
        uint256 upper = token.totalSupply().mul(upperboundPercentage).div(100);
        uint256 total = token.balanceOf(address(this));

        //airdrop the difference by sending back to the token 
        // contract which will split rewards and locked liquidity 
        if (total > upper){
            return true;
        }

        return false;
    }
}