pragma solidity ^0.4.21;

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
library SafeERC20 {
    function safeTransfer(ERC20 token, address to, uint256 value) internal {
        assert(token.transfer(to, value));
    }
    function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal{
        assert(token.transferFrom(from, to, value));
    }
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract TOSPrivateIncentiveContract {
    using SafeERC20 for ERC20;
    using SafeMath for uint;
    string public constant name = "TOSPrivateIncentiveContract";
    uint[6] public unlockePercentages = [
        15,  //15%
        35,   //20%
        50,   //15%
        65,   //15%
        80,   //15%
        100   //20%
    ];

    uint256 public unlocked = 0;
    uint256 public totalLockAmount = 0; 

    address public constant beneficiary = 0xbd9d16f47F061D9c6b1C82cb46f33F0aC3dcFB87;
    ERC20 public constant tosToken = ERC20(0xFb5a551374B656C6e39787B1D3A03fEAb7f3a98E);
    uint256 public constant UNLOCKSTART               = 1541347200; //2018/11/5 0:0:0
    uint256 public constant UNLOCKINTERVAL            = 30 days; // 30 days
    

    function TOSPrivateIncentiveContract() public {}
    function unlock() public {

        uint256 num = now.sub(UNLOCKSTART).div(UNLOCKINTERVAL);
        if (totalLockAmount == 0) {
            totalLockAmount = tosToken.balanceOf(this);
        }

        if (num >= unlockePercentages.length.sub(1)) {
            tosToken.safeTransfer(beneficiary, tosToken.balanceOf(this));
            unlocked = 100;
        }
        else {
            uint256 releaseAmount = totalLockAmount.mul(unlockePercentages[num].sub(unlocked)).div(100);
            tosToken.safeTransfer(beneficiary, releaseAmount);
            unlocked = unlockePercentages[num];
        }
    }
}