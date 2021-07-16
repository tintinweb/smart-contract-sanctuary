//SourceUnit: staking.sol

pragma solidity >=0.5.0 <0.6.0;


contract ITRC20 {
    function balanceOf(address account) external view returns (uint){}
    function transfer(address recipient, uint amount) external returns (bool){}
    function allowance(address owner, address spender) external view returns (uint){}
    function approve(address spender, uint amount) external returns (bool){}
    function transferFrom(address sender, address recipient, uint amount) external returns (bool){}
    function decimals() public view returns (uint8) {}
}

contract staking  {
    using SafeMath for uint;
    uint CONST_MINT = 27778;
    ITRC20 public token;
    struct staker{
        bool exists;
        uint staked;
        uint refPayout;
        address payable referrer;
        address payable[] referrals;
        uint[] payments;
        uint[] times;
        uint claimed;
    }
    mapping(address => staker) user;
    address payable admin;
    address payable transferAddr;
    // address payable adminAddr,
    constructor(address payable adminAddr, address tokenaddr, address payable transf) public{
        token = ITRC20(tokenaddr);
        admin = adminAddr;
        user[admin].exists = true;
        transferAddr = transf;
    }
    
    function changeAdmin(address payable newAdmin) external{
        require (msg.sender==admin);
        admin = newAdmin;
        user[admin].exists = true;
    }
    function changeTransfer(address payable transf) external{
        require (msg.sender==admin);
        transferAddr = transf;
    }
    
    function stakeTrx(address payable ref) payable external{
        require(msg.sender !=  ref,"ref cannot be you");
        require(msg.value%100000000 == 0 && msg.value!=0, "multiple of 100");
        require(user[ref].exists, "ref not signed up");
        if(!user[msg.sender].exists){
            user[msg.sender].exists = true;
            user[msg.sender].referrer = ref;
            user[ref].referrals.push(msg.sender);
        }
        
        user[msg.sender].staked += msg.value;
        user[msg.sender].payments.push(msg.value);
        user[msg.sender].times.push(now);
        user[ref].refPayout += msg.value.div(10**7);
        admin.transfer((msg.value.mul(3)).div(20));
    }
    
    function staked(address userAddress) view external returns(uint){
        return user[userAddress].staked;
    }
    
    function minted(address addr) view public returns(uint){
        uint mintedAmt = 0;
        for(uint8 i=0; i<user[addr].payments.length;i++){
            mintedAmt += calcMinted((now.sub(user[addr].times[i])), user[addr].payments[i]);
        }
        return mintedAmt.add(user[addr].refPayout);
    }
    function claimAndWithdraw() external{
        claimint(msg.sender);
        msg.sender.transfer((user[msg.sender].staked.mul(17)).div(20));
        user[msg.sender].staked = 0;
        user[msg.sender].refPayout = 0;
        delete user[msg.sender].payments;
        delete user[msg.sender].times;
        delete user[msg.sender].claimed;
    }
    function futureEarnings(address userAddr, uint timeCheck) view external returns(uint){
        uint mintedAmt = 0;
        require(timeCheck>now);
        for(uint8 i=0; i<user[userAddr].payments.length;i++){
            mintedAmt += calcMinted((timeCheck.sub(user[userAddr].times[i])), user[userAddr].payments[i]);
        }
        return(mintedAmt);
    }
    function claimed(address addr) view external returns(uint){
        return user[addr].claimed;
    }
    function claimint(address payable _addr) internal{
        require(token.transferFrom(transferAddr, _addr, minted(msg.sender)), "Sending Failed");
    }
    function claim() external{
        require(token.transferFrom(transferAddr, msg.sender, (minted(msg.sender).sub(user[msg.sender].claimed))), "Sending Failed");
        user[msg.sender].claimed = minted(msg.sender);
    }
    function calcMinted(uint time, uint sunamt) view internal returns(uint){
        return (CONST_MINT.mul(time).mul(sunamt)).div(10**16); //returns 1, i.e. 0.0001 token for 1 hr at 100 trx. change to 10**12 for testing
    }
    function allStaked(address userAddr) view external returns(uint[] memory, uint[] memory){
        return(user[userAddr].times, user[msg.sender].payments);
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