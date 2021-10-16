pragma solidity ^0.7.4;
//The graveyard is a step above a simple burn address 
//It will serve the community by collecting a redistributing fees
//Oscillatig between 50-51%
import "./ERC20.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./Address.sol";

contract LazarusPit is Context, Ownable {
    using SafeMath for uint256;
    using Address for address;

    uint256 public lastRebalance;
    uint256 public immutable upperboundPercentage = 51;


    IERC20 public immutable token;

    event Rebalance(
        uint256 tokens
    );

    constructor (ERC20 _token) public {

        //get a handle on the token
        token = IERC20(_token);

        //a rebalance isn't necessary at launch
        lastRebalance =  block.timestamp;

    }

    function rebalance() external {   
            
        //we should rebalance when we get more than target percentage of the supply in the graveyard
        uint256 upperbound = token.totalSupply().mul(upperboundPercentage).div(100);
        uint256 target =  token.totalSupply().mul(50).div(100);
        uint256 balance = token.balanceOf(address(this));

        //airdrop the difference by sending back to the token contract which will 
        //split rewards and locked liquidity 
        if (balance > upperbound){
            uint256 airdrop = balance.sub(target);

            //send airdrop to token where it will be added to liquidity 
            token.transfer(address(token), airdrop);

            lastRebalance = block.timestamp;

            emit Rebalance(airdrop);
        }

            
    }

    function ready() external view returns (bool) {
            
        //we should rebalance when we get more than 55% of the supply in the graveyard
        uint256 upperbound = token.totalSupply().mul(upperboundPercentage).div(100);
        uint256 balance = token.balanceOf(address(this));

        //airdrop the difference by sending back to the token contract which will 
        //split rewards and locked liquidity 
        if (balance > upperbound){
            return true;
        }
        

        return false;
    }
}