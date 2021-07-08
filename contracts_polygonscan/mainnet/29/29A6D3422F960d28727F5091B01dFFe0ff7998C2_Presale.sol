pragma solidity ^0.6.12;

import "./PenToken.sol";
import "./IQuickSwap.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Address.sol";

contract Presale is Context, Ownable {
    using SafeMath for uint256;
    using Address for address;
    
    PenToken public penToken;
    uint256 internal _tokenDecimals = 18;
    uint256 internal totalRewards = 0;
    uint256 internal START_TIME;
    uint256 internal VALID_TILL;
    uint256 internal immutable TOKENS_FOR_PRESALE = 15_000 * 10**_tokenDecimals;
    uint256 internal immutable TOKENS_FOR_LIQUIDITY = 13_000 * 10**_tokenDecimals;
    uint256 internal immutable TEAM_TOKENS = 3_000 * 10**_tokenDecimals;
    uint256 internal immutable SOFT_CAP = 0; 
    uint256 internal immutable PRESALE_RATIO = 1 * 10**18; // For 1 MATIC you'll receive __PRESALE_RATIO__ PRF
    address internal QUICKSWAP_ROUTER_ADDRESS = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff ;
    IQuickSwap internal quick_router;
    address internal dead = 0x000000000000000000000000000000000000dEaD;
    
    address[] public participants;
    mapping (address => uint256) public balances;
    
    
    constructor (PenToken _penToken, uint256 _startTime) public {
        penToken = _penToken;
        quick_router = IQuickSwap(QUICKSWAP_ROUTER_ADDRESS);
        START_TIME = _startTime;
        VALID_TILL = _startTime + 3 * 24 * 60 * 60;
    }
    
    function _startTime() public view returns (uint256) {
        return START_TIME;
    }
    
    function _totalRewards() public view returns (uint256) {
        return totalRewards;
    }

    function _getReward(address participant) internal view returns (uint256) {
        return (uint256) ( balances[participant].mul(PRESALE_RATIO).div(10**18));
    }
    
    function endPresale() public returns (bool) {
        require((block.timestamp > VALID_TILL || totalRewards >= TOKENS_FOR_PRESALE), "Presale is not over yet");
        require(address(this).balance > 0, "Presale is completed");
        
        if(address(this).balance < SOFT_CAP) { // Returns MATIC to senders
            for(uint256 i = 0; i < participants.length; i++){
                if (balances[participants[i]] > 0){
                    payable(participants[i]).transfer(balances[participants[i]]);
                    balances[participants[i]] = 0;
                }
            }
        } else { // Otherwise, add liquidity to router and burn LP
            require(penToken.approve(QUICKSWAP_ROUTER_ADDRESS, TOKENS_FOR_LIQUIDITY), 'Approve failed');
            for(uint256 i = 0; i < participants.length; i++) { // send tokens to participants
                uint256 _payoutAmount = _getReward(participants[i]);
                uint256 _tokensRemaining = penToken.balanceOf( address(this) );
                if( _tokensRemaining > 0 && _payoutAmount > 0 && _payoutAmount <= _tokensRemaining) {
                    if(penToken.transfer(
                        participants[i], 
                        _payoutAmount
                        )){ balances[participants[i]] = 0; }
                        
                } else  {
                    if (_payoutAmount > 0) {
                        payable(participants[i]).transfer( balances[participants[i]] );
                        balances[participants[i]] = 0;
                    }
                }
            }
            uint256 _liqidity = totalRewards.mul(TOKENS_FOR_LIQUIDITY.mul(1000).div(TOKENS_FOR_PRESALE)).div(1000);
            quick_router.addLiquidityETH{value: address(this).balance}(
                address(penToken), //token
                _liqidity, // amountTokenDesired
                0, // amountTokenMin
                address(this).balance, // amountETHMin
                address(0), // to => liquidity tokens are locked forever by sending them to dead address
                block.timestamp + 120 // deadline
            );
            penToken.transfer(owner(), TEAM_TOKENS);
            penToken.transfer(dead, penToken.balanceOf( address(this) )); // And burn remaining tokens
        }
        
        return true;
    }
    
    receive () payable external {
        uint256 _time = block.timestamp;
        require(msg.value >= 5 * 10**18, "Minimum purchase is 5 matic");
        require(_time >= START_TIME, "Presale does not started");
        require(_time <= VALID_TILL, "Presale is over");
        address sender = _msgSender();
        if(balances[sender] == 0) {
            participants.push(sender);
        }
        balances[sender] = balances[sender].add(msg.value);
        totalRewards = totalRewards.add( msg.value.mul(PRESALE_RATIO).div(10**18) );
    }
}