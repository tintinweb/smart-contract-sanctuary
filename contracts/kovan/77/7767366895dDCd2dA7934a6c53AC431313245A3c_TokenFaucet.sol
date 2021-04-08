/**
 *Submitted for verification at Etherscan.io on 2021-04-08
*/

pragma solidity >=0.5.0;


interface ERC20Like {
    function balanceOf(address) external view returns (uint256);
    function transfer(address,uint256) external; // return bool?
}

contract TokenFaucet {


    mapping (address => mapping (address => bool)) public done;
    
    uint256 public USDTbalance=0;
    uint256 public USDCbalance=0;
    uint256 public WBTCbalance=0;


    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }


     function getUSDT() external {
        require(!done[msg.sender][address(0xF054942D6Ab6F07FC58aCD473E24A3283E080Af5)], "token-faucet: already used faucet");
        require(ERC20Like(0xF054942D6Ab6F07FC58aCD473E24A3283E080Af5).balanceOf(address(this)) >= USDTbalance, "token-faucet: not enough balance");
        done[msg.sender][address(0xF054942D6Ab6F07FC58aCD473E24A3283E080Af5)] = true;
        ERC20Like(0xF054942D6Ab6F07FC58aCD473E24A3283E080Af5).transfer(msg.sender,50000000000);
         USDTbalance=ERC20Like(0xF054942D6Ab6F07FC58aCD473E24A3283E080Af5).balanceOf(address(this));
    }
    
      function getWBTC() external {
           require(!done[msg.sender][0x7b15e33AE379320247F1Cc32AEEE2461934Aa478], "token-faucet: already used faucet");
        require(ERC20Like(0x7b15e33AE379320247F1Cc32AEEE2461934Aa478).balanceOf(address(this)) >= USDTbalance, "token-faucet: not enough balance");
        done[msg.sender][address(0x7b15e33AE379320247F1Cc32AEEE2461934Aa478)] = true;
        ERC20Like(address(0x7b15e33AE379320247F1Cc32AEEE2461934Aa478)).transfer(msg.sender,100000);
         WBTCbalance=ERC20Like(0x7b15e33AE379320247F1Cc32AEEE2461934Aa478).balanceOf(address(this));
    }
    
     function getUSDC() external {
        require(!done[msg.sender][address(0xBF08047691986fB9DD5F5285aF83f887e57af2d2)], "token-faucet: already used faucet");
        require(ERC20Like(0xBF08047691986fB9DD5F5285aF83f887e57af2d2).balanceOf(address(this)) >= USDTbalance, "token-faucet: not enough balance");
        done[msg.sender][address(0xBF08047691986fB9DD5F5285aF83f887e57af2d2)] = true;
        ERC20Like(0xBF08047691986fB9DD5F5285aF83f887e57af2d2).transfer(msg.sender,50000000000);
       USDCbalance=ERC20Like(0xBF08047691986fB9DD5F5285aF83f887e57af2d2).balanceOf(address(this));
         
    }

  
}