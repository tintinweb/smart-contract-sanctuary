/**
 *Submitted for verification at Etherscan.io on 2021-07-05
*/

pragma solidity 0.6.10;


interface ERC20Like {
    function transfer(address to, uint qty) external;
    function approve(address spender, uint qty) external;
}

contract LUSDReserve {
    uint public ethToUsd;
    address public admin;
    ERC20Like public constant LUSD = ERC20Like(0x0b02b94638daa719290b5214825dA625af08A02F);
    
    constructor() public {
        admin = msg.sender;
    }
    
    function setEthToUsd(uint _ethToUsd) public {
        require(msg.sender == admin, "!admin");
        
        ethToUsd = _ethToUsd;
    }
    
    // kyber network reserve compatible function
    function trade(
        address /* srcToken */,
        uint256 /* srcAmount */,
        address /* destToken */,
        address payable destAddress,
        uint256 /* conversionRate */,
        bool /* validate */
    ) external payable returns (bool) {
        uint amount = msg.value * ethToUsd / 1e18;
        LUSD.transfer(destAddress, amount);
        
        return amount > 0;
    }

    function getConversionRate(
        address /* src */,
        address /* dest */,
        uint256 /* srcQty */,
        uint256 /* blockNumber */
    ) external view returns (uint256) {
        return ethToUsd;
    }

    receive() external payable {}    
}

interface BAMMLike {
    function getSwapEthAmount(uint lusdQty) external view returns(uint ethAmount, uint feeEthAmount);
    function swap(uint lusdAmount, address payable dest) external payable returns(uint);
}

interface KyberLike {
    function getExpectedRate(address src, address dest, uint qty) external view returns(uint256);
    function swapEtherToToken(address token, uint256 minConversionRate) external payable returns (uint256 destAmount);
}


contract Keeper {
  address public admin;
  address public lusd;
  address public bamm;
  address public kyber;
  uint public ethQty;
  
  constructor() public {
      admin = msg.sender;
  }
  
  function setParams(address _lusd, address _bamm, address _kyber, uint _ethQty) external {
      require(msg.sender == admin, "!admin");
      lusd = _lusd;
      bamm = _bamm;
      kyber = _kyber;
      ethQty = _ethQty;
  }
    
  function checkUpkeep(bytes calldata /*checkData*/) external view returns (bool upkeepNeeded, bytes memory /*performData*/) {
      uint kyberRate = KyberLike(kyber).getExpectedRate(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE, lusd, ethQty);
      uint kyberLusdQty = kyberRate * ethQty / 1e18;
      
      (uint bammQty, ) = BAMMLike(bamm).getSwapEthAmount(kyberLusdQty);
      
      upkeepNeeded = bammQty > ethQty * 101 / 100; // more than 1% arbitrage
  }
  
  function performUpkeep(bytes calldata /*performData*/) external {
      uint ethBalanceBefore = address(this).balance;
      
      // trade on kyber
      uint lusdQty = KyberLike(kyber).swapEtherToToken{value: ethQty}(lusd, 0);
      
      // swap on b.amm
      ERC20Like(lusd).approve(bamm, lusdQty);
      BAMMLike(bamm).swap(lusdQty, address(this));
      
      uint ethBalanceAfter = address(this).balance;
      
      require(ethBalanceAfter >= ethBalanceBefore, "!arb");
  }
  
  receive() external payable {}  
}