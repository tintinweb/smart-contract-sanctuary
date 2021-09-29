// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

//  _ __   ___  __ _ _ __ ______ _ _ __  
// | '_ \ / _ \/ _` | '__|_  / _` | '_ \ 
// | |_) |  __/ (_| | |   / / (_| | |_) |
// | .__/ \___|\__,_|_|  /___\__,_| .__/ 
// | |                            | |    
// |_|                            |_|    

// https://pearzap.com/

import "./ReentrancyGuard.sol";
import "./GambleBase.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract MoneyWheel is GambleBase, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public token;

    uint256[52] public wheel = [50,1,3,1,5,1,3,1,10,3,1,5,1,20,1,3,1,3,1,5,1,10,1,3,5,1,0,1,3,1,5,1,3,1,10,5,1,3,1,20,1,3,1,5,1,3,1,5,1,10,3,1];

    mapping(address => BetResult) public lastResult;

    uint256 private _minBet = 1 ether;
    uint256 private _maxPercWin = 1000; // Percentage points

    uint256 public burnPerc = 1000; // Percentage points
    address public burnAddress = 0x000000000000000000000000000000000000dEaD;
    
    struct BetResult {
        uint256 spin;
        uint256 multiplier;
        uint256 reward;
    }

    event Result(address indexed account, uint256 spin, uint256 multiplier, uint256 reward);

    constructor(IERC20 _token) public {
        token = _token;
    }

    function minBet() public view returns(uint256) {
        return _minBet;
    }

    function maxBet() public view returns(uint256) {
        return budget()
            .mul(_maxPercWin).div(10000)
            .div(50);
    }

    function budget() public view returns(uint256) {
        return token.balanceOf(address(this));
    }

    function setMaxPercWin(uint256 _perc) public onlyOwner {
        require(_perc <= 10000, "use percentage points");
        _maxPercWin = _perc;
    }

    function setBurnPerc(uint256 _perc) public onlyOwner {
        require(_perc <= 10000, "use percentage points");
        burnPerc = _perc;
    }

    function setBurnAddress(address _burnAddress) public onlyOwner {
        require(_burnAddress != address(0), "Real null, not allowed");
        burnAddress = _burnAddress;
    }

    function setMinBet(uint256 _value) public onlyOwner {
        _minBet = _value;
    }

    function withdraw(uint256 _amount) public onlyOwner {
        require(budget() >= _amount, "Insufficient funds");
        token.safeTransfer(msg.sender, _amount);
    }

    function _spin() internal view returns (uint256) {
        return rand().mul(52).div(1000);
    }
    
    function _betRange(uint256 _amount) internal view {
        require(_amount == 0 || (_amount >= minBet() && _amount <= maxBet()), 'bet out of range');
    }

    function bet(uint256 _1, uint256 _3, uint256 _5, uint256 _10, uint256 _20, uint256 _50) public noContract nonReentrant {
        _betRange(_1); _betRange(_3); _betRange(_5); _betRange(_10); _betRange(_20); _betRange(_50); 
        
        uint256 spin; uint256 multiplier; uint256 reward;
        
        // Pull Funds
        uint256 betTotal = _1+_3+_5+_10+_20+_50;
        token.safeTransferFrom(msg.sender, address(this), betTotal);

        // Spin it!
        spin = _spin();
        multiplier = wheel[spin];
        
        if (multiplier > 0) {
            uint256 winningBet;
            
            if (multiplier == 1) {
                winningBet = _1;
            }

            if (multiplier == 3) {
                winningBet = _3;
            }

            if (multiplier == 5) {
                winningBet = _5;
            }

            if (multiplier == 10) {
                winningBet = _10;
            }

            if (multiplier == 20) {
                winningBet = _20;
            }

            if (multiplier == 50) {
                winningBet = _50;
            }

            reward = winningBet.mul(multiplier.add(1));
        }

        if (betTotal > reward && burnPerc > 0) {
            uint256 burnAmount = betTotal.sub(reward).mul(burnPerc).div(10000);
            token.safeTransfer(burnAddress, burnAmount);
        }
        
        token.safeTransfer(msg.sender, reward);

        lastResult[msg.sender] = BetResult({
            spin: spin,
            multiplier: multiplier,
            reward: reward
        });
        emit Result(msg.sender, spin, multiplier, reward);
    }
}