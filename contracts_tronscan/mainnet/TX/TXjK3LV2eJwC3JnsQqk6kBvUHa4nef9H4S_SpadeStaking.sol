//SourceUnit: stakingnew.sol

pragma solidity >=0.5.0 <0.6.0;


contract ITRC20 {
    function balanceOf(address account) external view returns (uint){}
    function transfer(address recipient, uint amount) external returns (bool){}
    function allowance(address owner, address spender) external view returns (uint){}
    function approve(address spender, uint amount) external returns (bool){}
    function transferFrom(address sender, address recipient, uint amount) external returns (bool){}
    function decimals() public view returns (uint8) {}
}

contract SpadeStaking  {
    using SafeMath for uint;
    uint CONST_MINT = 158548960;
    ITRC20 public token;
    uint minTime = 259200;
    struct staker{
        bool exists;
        uint staked;
        uint[] payments;
        uint[] times;
        uint claimed;
        uint lastClaimedTime;
    }
    mapping(address => staker) user;
    address payable admin;
    constructor(/*address payable adminAddr, */address tokenaddr) public{
        token = ITRC20(tokenaddr);
        // admin = adminAddr;
        admin = msg.sender;
        user[admin].exists = true;
    }
    
    function removeTokens(uint amount) external{
        require(msg.sender==admin);
        token.transfer(admin, amount);
    }
    
    function changeAdmin(address payable newAdmin) external{
        require (msg.sender==admin);
        admin = newAdmin;
        user[admin].exists = true;
    }
    
    function stakeToken(uint amount) external{
        require(token.transferFrom(msg.sender, address(this), amount));
        user[msg.sender].exists = true;
        
        user[msg.sender].staked += amount;
        user[msg.sender].payments.push(amount);
        user[msg.sender].times.push(now);
        user[msg.sender].lastClaimedTime = now;
    }
    
    function staked(address userAddress) view external returns(uint){
        return user[userAddress].staked;
    }
    
    function minted(address addr) view public returns(uint){
        uint mintedAmt = 0;
        for(uint16 i=0; i<user[addr].payments.length;i++){
            mintedAmt += calcMinted((now.sub(user[addr].times[i])), user[addr].payments[i]);
        }
        return mintedAmt;
    }
    function claimAndWithdraw() external{
        require(token.transfer(msg.sender, minted(msg.sender).sub(user[msg.sender].claimed).add(user[msg.sender].staked)), "Sending Failed");
        require(isClaimable(msg.sender), "Minimum unstake time not reached");
        user[msg.sender].staked = 0;
        delete user[msg.sender].payments;
        delete user[msg.sender].times;
        delete user[msg.sender].claimed;
        user[msg.sender].lastClaimedTime = now;
    }
    function claimed(address addr) view external returns(uint){
        return user[addr].claimed;
    }
    function claim() external{
        require(isClaimable(msg.sender), "Minimum unstake time not reached");
        require(token.transfer(msg.sender, (minted(msg.sender).sub(user[msg.sender].claimed))), "Sending Failed");
        user[msg.sender].claimed = minted(msg.sender);
        user[msg.sender].lastClaimedTime = now;
    }
    function calcMinted(uint time, uint amountOfTokens) view internal returns(uint){
        return (CONST_MINT.mul(time).mul(amountOfTokens)).div(10**17);
    }
    function allStaked(address userAddr) view external returns(uint[] memory, uint[] memory){
        return(user[userAddr].times, user[msg.sender].payments);
    }
    function isClaimable(address userAddr) view public returns(bool){
        if (now>user[userAddr].lastClaimedTime+minTime){
            return true;
        }else{
            return false;
        }
    }
    
}




//---------------------------SAFE MATH STARTS HERE ---------------------------
library SafeMath {
  function mul(uint a, uint b) internal pure  returns (uint) {
    uint c = a * b;
    require(a == 0 || c / a == b);
    return c;
  }
  function div(uint a, uint b) internal pure returns (uint) {
    require(b > 0);
    uint c = a / b;
    require(a == b * c + a % b);
    return c;
  }
  function sub(uint a, uint b) internal pure returns (uint) {
    require(b <= a);
    return a - b;
  }
  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    require(c >= a);
    return c;
  }
  function max64(uint64 a, uint64 b) internal  pure returns (uint64) {
    return a >= b ? a : b;
  }
  function min64(uint64 a, uint64 b) internal  pure returns (uint64) {
    return a < b ? a : b;
  }
  function max256(uint256 a, uint256 b) internal  pure returns (uint256) {
    return a >= b ? a : b;
  }
  function min256(uint256 a, uint256 b) internal  pure returns (uint256) {
    return a < b ? a : b;
  }
}


// contract Token {
//     function transferFrom(address from, address to, uint256 value) public returns (bool){}

//     function transfer(address to, uint256 value) public returns (bool){}

//     function balanceOf(address who) public view returns (uint256){}

//     function burn(uint256 _value) public {}
// }