/**
 *Submitted for verification at BscScan.com on 2021-10-26
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract MyDeFiTeam_Lottery {
    address public ownerAddress;
    
    address public lotteryWalletAddress;
    
    IERC20 public token_CAKE;
    using SafeMath for uint256;
    address erctoken_CAKE = address(0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82); //CAKE

    bool public started;
    uint256 public totalInvested_CAKE;
  
    constructor() {
        ownerAddress = msg.sender;
        token_CAKE = IERC20(erctoken_CAKE);
    }
    
    function invest(
        uint256 amountCAKE
    ) public {
        require(started, "Not started yet");
        require(lotteryWalletAddress != address(0), "missing lottery wallet");

        if( amountCAKE > 0){
            token_CAKE.transferFrom(msg.sender, lotteryWalletAddress, amountCAKE);
            totalInvested_CAKE = totalInvested_CAKE.add(amountCAKE);
        }
    }
    
    function setLotteryWallet(address value) external {
        require(msg.sender == ownerAddress);
        lotteryWalletAddress = value;
    }
    
    
   function start() external {
        require(msg.sender == ownerAddress);
        started = true;
    }
    
    function stop() external {
        require(msg.sender == ownerAddress);
        started = false;
    }
  
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}