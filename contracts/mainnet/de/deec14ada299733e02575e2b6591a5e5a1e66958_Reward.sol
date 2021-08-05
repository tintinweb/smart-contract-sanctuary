/**
 *Submitted for verification at Etherscan.io on 2020-11-28
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.6.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
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

contract RewardOwner is Context {
    address internal _molStakerContract;
    address internal _lavaStakerContract;

    constructor (address molStakerContract, address lavaStakerContract) internal {
        _molStakerContract = molStakerContract;
        _lavaStakerContract = lavaStakerContract;
    }
    
    modifier onlyMOLStakerContract() {
        require(_msgSender() == _molStakerContract, "RewardOwner: caller is not the MOLStaker contract");
        _;
    }
    
    modifier onlyLAVAStakerContract() {
        require(_msgSender() == _lavaStakerContract, "RewardOwner: caller is not the LAVAStaker contract");
        _;
    }
}

abstract contract MOLContract {
    function balanceOf(address account) external view virtual returns (uint256);
    function transfer(address recipient, uint256 amount) external virtual returns (bool);
}

abstract contract LAVAContract {
    function balanceOf(address account) external view virtual returns (uint256);
    function transfer(address recipient, uint256 amount) external virtual returns (bool);
}

interface IUniswapV2ERC20 {
    function balanceOf(address owner) external view returns (uint);
    function transfer(address to, uint value) external returns (bool);
}


contract Reward is RewardOwner {
    using SafeMath for uint256;

    LAVAContract private _lavaContract;     // lava contract
    address private _lavaUniV2Pair;         // lava uniswap-eth v2 pair

    constructor (LAVAContract lavaContract, address lavaUniV2Pair, address molStakerContract, address lavaStakerContract) RewardOwner(molStakerContract, lavaStakerContract) public {
        _lavaContract = lavaContract;
        _lavaUniV2Pair = lavaUniV2Pair;
    }
    
    function MOLStakerContract() external view returns (address) {
        return _molStakerContract;
    }
    
    function LAVAStakerContract() external view returns (address) {
        return _lavaStakerContract;
    }
    
    function getLavaBalance() external view returns (uint256) {
        return _lavaContract.balanceOf(address(this));
    }
    
    function getLavaUNIv2Balance() external view returns (uint256) {
        return IUniswapV2ERC20(_lavaUniV2Pair).balanceOf(address(this));
    }
    
    function giveLavaReward(address recipient, uint256 amount) external onlyMOLStakerContract returns (bool) {
        return _lavaContract.transfer(recipient, amount);
    }
    
    function giveLavaUNIv2Reward(address recipient, uint256 amount) external onlyLAVAStakerContract returns (bool) {
        return IUniswapV2ERC20(_lavaUniV2Pair).transfer(recipient, amount);
    }
}