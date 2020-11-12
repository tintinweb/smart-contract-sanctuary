pragma solidity ^0.4.24;

contract Left {
  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public totalSupply;
  mapping (address => uint256) public balanceOf;

  string public author;
  uint256 internal PPT;

  uint public voteSession;
  uint256 public pennyRate;

  mapping (uint => mapping (bool => uint256)) public upVote;
  mapping (address => mapping (uint => mapping (bool => uint256))) public votes;

  address constant PROJECT = 0x537ca62B4c232af1ef82294BE771B824cCc078Ff;
  address constant UPVOTE = 0xaf6F22ccB2358857fa31F0B393482a81280B92A5;
  address constant DOWNVOTE = 0x0F64C8026569413747a235fBdDb1F25464077BB3;

  event Transfer (address indexed from, address indexed to, uint256 value);

  constructor () public {
    author = "ASINERUM INTERNATIONAL";
    name = "ETHEREUM VOTABLE TOKEN 2";
    symbol = "LEFT";
    decimals = 18;
    PPT = 10**18;
    pennyRate = PPT;
  }

  function w2p (uint256 value)
  internal view returns (uint256) {
    return value*pennyRate/PPT;
  }

  function p2w (uint256 value)
  internal view returns (uint256) {
    return value*PPT/pennyRate;
  }

  function adjust ()
  internal {
    if (upVote[voteSession][true]>totalSupply/2) {
      pennyRate = pennyRate*(100+2)/100;
      voteSession += 1;
    } else if (upVote[voteSession][false]>totalSupply/2) {
      pennyRate = pennyRate*(100-2)/100;
      voteSession += 1;
    }
  }

  function adjust (address from, uint256 value, bool add)
  internal {
    if (add) balanceOf[from] += value;
    else balanceOf[from] -= value;
    if (votes[from][voteSession][true]>0) {
      upVote[voteSession][true] =
      upVote[voteSession][true] - votes[from][voteSession][true] + balanceOf[from];
      votes[from][voteSession][true] = balanceOf[from];
    } else if (votes[from][voteSession][false]>0) {
      upVote[voteSession][false] =
      upVote[voteSession][false] - votes[from][voteSession][false] + balanceOf[from];
      votes[from][voteSession][false] = balanceOf[from];
    }
    adjust ();
  }

  function move (address from, address to, uint256 value)
  internal {
    require (value<=balanceOf[from]);
    require (balanceOf[to]+value>balanceOf[to]);
    uint256 sum = balanceOf[from]+balanceOf[to];
    adjust (from, value, false);
    adjust (to, value, true);
    assert (balanceOf[from]+balanceOf[to]==sum);
    emit Transfer (from, to, value);
  }

  function mint (address to, uint256 value)
  internal {
    require (balanceOf[to]+value>balanceOf[to]);
    uint256 dif = totalSupply-balanceOf[to];
    totalSupply += value;
    adjust (to, value, true);
    assert (totalSupply-balanceOf[to]==dif);
  }

  function burn (address from, uint256 value)
  internal {
    require (value<=balanceOf[from]);
    uint256 dif = totalSupply-balanceOf[from];
    totalSupply -= value;
    adjust (from, value, false);
    assert (totalSupply-balanceOf[from]==dif);
  }

  function () public payable {
    download ();
  }

  function download () public payable returns (bool success) {
    require (msg.value>0, "#input");
    mint (msg.sender, w2p(msg.value));
    mint (PROJECT, msg.value/1000);
    return true;
  }

  function upload (uint256 value) public returns (bool success) {
    require (value>0, "#input");
    burn (msg.sender, value);
    msg.sender.transfer (p2w(value));
    return true;
  }

  function clear () public returns (bool success) {
    require (balanceOf[msg.sender]>0, "#balance");
    if (p2w(balanceOf[msg.sender])<=address(this).balance) upload (balanceOf[msg.sender]);
    else upload (w2p(address(this).balance));
    return true;
  }

  function burn (uint256 value) public returns (bool success) {
    burn (msg.sender, value);
    return true;
  }

  function transfer (address to, uint256 value) public returns (bool success) {
    if (to==address(this)) upload (value);
    else if (to==UPVOTE) vote (true);
    else if (to==DOWNVOTE) vote (false);
    else move (msg.sender, to, value);
    return true;
  }

  function vote (bool upvote) public returns (bool success) {
    require (balanceOf[msg.sender]>0);
    upVote[voteSession][upvote] =
    upVote[voteSession][upvote] - votes[msg.sender][voteSession][upvote] + balanceOf[msg.sender];
    votes[msg.sender][voteSession][upvote] = balanceOf[msg.sender];
    if (votes[msg.sender][voteSession][!upvote]>0) {
      upVote[voteSession][!upvote] =
      upVote[voteSession][!upvote] - votes[msg.sender][voteSession][!upvote];
      votes[msg.sender][voteSession][!upvote] = 0;
    }
    adjust ();
    return true;
  }

  function status (address ua) public view returns (
  uint256 rate,
  uint256 supply,
  uint256 ethFund,
  uint256[2] allVotes,
  uint256[2] userVotes,
  uint256[2] userFund) {
    rate = pennyRate;
    supply = totalSupply;
    ethFund = address(this).balance;
    allVotes[0] = upVote[voteSession][true];
    allVotes[1] = upVote[voteSession][false];
    userVotes[0] = votes[ua][voteSession][true];
    userVotes[1] = votes[ua][voteSession][false];
    userFund[0] = address(ua).balance;
    userFund[1] = balanceOf[address(ua)];
  }

  // MARKETPLACE

  mapping (uint => Market) public markets;
  struct Market {
    bool buytoken;
    address maker;
    uint256 value;
    uint256 ppe;
    uint time; }

  event Sale (uint refno, bool indexed buy, address indexed maker, uint256 indexed ppe, uint time);
  event Get (uint indexed refno, address indexed taker, uint256 value); //<Sale>

  function ethered (uint256 value)
  internal view returns (bool) {
    require (msg.value*value==0&&msg.value+value>0, "#values");
    require (value<=totalSupply, "#value");
    return msg.value>0?true:false;
  }

  function post (uint refno, uint256 value, uint256 ppe, uint time) public payable returns (bool success) {
    require (markets[refno].maker==0x0, "#refno");
    require (ppe>0&&ppe<totalSupply, "#rate");
    require (time==0||time>now, "#time");
    Market memory mi;
    mi.buytoken = ethered (value);
    mi.value = msg.value+value;
    mi.maker = msg.sender;
    mi.time = time;
    mi.ppe = ppe;
    markets[refno] = mi;
    if (!mi.buytoken) move (msg.sender, address(this), value);
    emit Sale (refno, mi.buytoken, mi.maker, mi.ppe, mi.time);
    return true;
  }

  function unpost (uint refno) public returns (bool success) {
    Market storage mi = markets[refno];
    require (mi.value>0, "#data");
    require (mi.maker==msg.sender, "#user");
    require (mi.time==0||mi.time<now, "#time");
    if (mi.buytoken) mi.maker.transfer (mi.value);
    else move (address(this), mi.maker, mi.value);
    mi.value = 0;
    return true;
  }

  function acquire (uint refno, uint256 value) public payable returns (bool success) {
    bool buytoken = ethered (value);
    Market storage mi = markets[refno];
    require (mi.maker!=0x0, "#refno");
    require (mi.value>0&&mi.ppe>0, "#data");
    require (mi.time==0||mi.time>=now, "#time");
    require (mi.buytoken==!buytoken, "#request");
    uint256 pre = mi.value;
    uint256 remit;
    if (buytoken) {
      remit = msg.value*mi.ppe/PPT;
      require (remit>0&&remit<=mi.value, "#volume");
      move (address(this), msg.sender, remit);
      mi.maker.transfer (msg.value);
    } else {
      remit = value*PPT/mi.ppe;
      require (remit>0&&remit<=mi.value, "#volume");
      move (msg.sender, mi.maker, value);
      msg.sender.transfer (remit);
    }
    mi.value -= remit;
    assert (mi.value+remit==pre);
    emit Get (refno, msg.sender, remit);
    return true;
  }
}