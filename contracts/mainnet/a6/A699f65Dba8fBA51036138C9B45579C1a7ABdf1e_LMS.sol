//  _               _     __  __                _____ _                  _ _             
// | |             | |   |  \/  |              / ____| |                | (_)            
// | |     __ _ ___| |_  | \  / | __ _ _ __   | (___ | |_ __ _ _ __   __| |_ _ __   __ _ 
// | |    / _` / __| __| | |\/| |/ _` | '_ \   \___ \| __/ _` | '_ \ / _` | | '_ \ / _` |
// | |___| (_| \__ \ |_  | |  | | (_| | | | |  ____) | || (_| | | | | (_| | | | | | (_| |
// |______\__,_|___/\__| |_|  |_|\__,_|_| |_| |_____/ \__\__,_|_| |_|\__,_|_|_| |_|\__, |
//                                                                                  __/ |
//                                                                                 |___/ 

/*
* Last Man Standing is an Erc20 battle royale game.
* 5% of tokens will be burned on every transaction, similar to a rebase, these coins are burned permanently.
* Small limited 10,000 supply(NO DECIMALS). Minimum 1 LMS burned per transaction. Maximum 10,000 transactions possible.
* As supply shrinks, the price increases, but when will you take profit?
* Upon reaching 1 supply, the coin can't be sold.
* Can you avoid being the last man standing?
* Tg: t.me/LastManStandingGame

**/

pragma solidity ^0.5.0;

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
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

  function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
    uint256 c = add(a,m);
    uint256 d = sub(c,1);
    return mul(div(d,m),m);
  }
}

contract ERC20Detailed is IERC20 {

  string private _name;
  string private _symbol;
  uint8 private _decimals;

  constructor(string memory name, string memory symbol, uint8 decimals) public {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }

  function name() public view returns(string memory) {
    return _name;
  }

  function symbol() public view returns(string memory) {
    return _symbol;
  }

  function decimals() public view returns(uint8) {
    return _decimals;
  }
}

contract LMS is ERC20Detailed {

  using SafeMath for uint256;
  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowed;

  string constant tokenName = "Last Man Standing";
  string constant tokenSymbol = "LMS";
  uint8  constant tokenDecimals = 0;
  uint256 _totalSupply = 10000;
  uint256 public basePercent = 100;

//  _               _     __  __                _____ _                  _ _             
// | |             | |   |  \/  |              / ____| |                | (_)            
// | |     __ _ ___| |_  | \  / | __ _ _ __   | (___ | |_ __ _ _ __   __| |_ _ __   __ _ 
// | |    / _` / __| __| | |\/| |/ _` | '_ \   \___ \| __/ _` | '_ \ / _` | | '_ \ / _` |
// | |___| (_| \__ \ |_  | |  | | (_| | | | |  ____) | || (_| | | | | (_| | | | | | (_| |
// |______\__,_|___/\__| |_|  |_|\__,_|_| |_| |_____/ \__\__,_|_| |_|\__,_|_|_| |_|\__, |
//                                                                                  __/ |
//  

  constructor() public payable ERC20Detailed(tokenName, tokenSymbol, tokenDecimals) {
    _mint(msg.sender, _totalSupply);
  }

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

  function allowance(address owner, address spender) public view returns (uint256) {
    return _allowed[owner][spender];
  }

  function findFivePercent(uint256 value) public view returns (uint256)  {
    uint256 roundValue = value.ceil(basePercent);
    uint256 fivePercent = roundValue.mul(basePercent).div(2000);
    return fivePercent;
  }

  function transfer(address to, uint256 value) public returns (bool) {
    require(value <= _balances[msg.sender]);
    require(to != address(0));

    uint256 tokensToBurn = findFivePercent(value);
    uint256 tokensToTransfer = value.sub(tokensToBurn);

    _balances[msg.sender] = _balances[msg.sender].sub(value);
    _balances[to] = _balances[to].add(tokensToTransfer);

    _totalSupply = _totalSupply.sub(tokensToBurn);

    emit Transfer(msg.sender, to, tokensToTransfer);
    emit Transfer(msg.sender, address(0), tokensToBurn);
    return true;
  }

  function multiTransfer(address[] memory receivers, uint256[] memory amounts) public {
    for (uint256 i = 0; i < receivers.length; i++) {
      transfer(receivers[i], amounts[i]);
    }
  }

  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  function transferFrom(address from, address to, uint256 value) public returns (bool) {
    require(value <= _balances[from]);
    require(value <= _allowed[from][msg.sender]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);

    uint256 tokensToBurn = findFivePercent(value);
    uint256 tokensToTransfer = value.sub(tokensToBurn);

    _balances[to] = _balances[to].add(tokensToTransfer);
    _totalSupply = _totalSupply.sub(tokensToBurn);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);

    emit Transfer(from, to, tokensToTransfer);
    emit Transfer(from, address(0), tokensToBurn);

    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  function _mint(address account, uint256 amount) internal {
    require(amount != 0);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

//  _               _     __  __                _____ _                  _ _             
// | |             | |   |  \/  |              / ____| |                | (_)            
// | |     __ _ ___| |_  | \  / | __ _ _ __   | (___ | |_ __ _ _ __   __| |_ _ __   __ _ 
// | |    / _` / __| __| | |\/| |/ _` | '_ \   \___ \| __/ _` | '_ \ / _` | | '_ \ / _` |
// | |___| (_| \__ \ |_  | |  | | (_| | | | |  ____) | || (_| | | | | (_| | | | | | (_| |
// |______\__,_|___/\__| |_|  |_|\__,_|_| |_| |_____/ \__\__,_|_| |_|\__,_|_|_| |_|\__, |
//                                                                                  __/ |
//  

  function burn(uint256 amount) external {
    _burn(msg.sender, amount);
  }

  function _burn(address account, uint256 amount) internal {
    require(amount != 0);
    require(amount <= _balances[account]);
    _totalSupply = _totalSupply.sub(amount);
    _balances[account] = _balances[account].sub(amount);
    emit Transfer(account, address(0), amount);
  }

  function burnFrom(address account, uint256 amount) external {
    require(amount <= _allowed[account][msg.sender]);
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(amount);
    _burn(account, amount);
  }
}

//* Still reading the contract? Well.. okay.. Uh... Here's Sonic?
//                             ...,?77??!~~~~!???77?<~.... 
//                        ..?7`                           `7!.. 
//                    .,=`          ..~7^`   I                  ?1. 
//       ........  ..^            ?`  ..?7!1 .               ...??7 
//      .        .7`        .,777.. .I.    . .!          .,7! 
//      ..     .?         .^      .l   ?i. . .`       .,^ 
//       b    .!        .= .?7???7~.     .>r .      .= 
//       .,.?4         , .^         1        `     4... 
//        J   ^         ,            5       `         ?<. 
//       .%.7;         .`     .,     .;                   .=. 
//       .+^ .,       .%      MML     F       .,             ?, 
//        P   ,,      J      .MMN     F        6               4. 
//        l    d,    ,       .MMM!   .t        ..               ,, 
//        ,    JMa..`         MMM`   .         .!                .; 
//         r   .M#            .M#   .%  .      .~                 ., 
//       dMMMNJ..!                 .P7!  .>    .         .         ,, 
//       .WMMMMMm  ?^..       ..,?! ..    ..   ,  Z7`        `?^..  ,, 
//          ?THB3       ?77?!        .Yr  .   .!   ?,              ?^C 
//            ?,                   .,^.` .%  .^      5. 
//              7,          .....?7     .^  ,`        ?. 
//                `<.                 .= .`'           1 
//                ....dn... ... ...,7..J=!7,           ., 
//             ..=     G.,7  ..,o..  .?    J.           F 
//           .J.  .^ ,,,t  ,^        ?^.  .^  `?~.      F 
//          r %J. $    5r J             ,r.1      .=.  .% 
//          r .77=?4.    ``,     l ., 1  .. <.       4., 
//          .$..    .X..   .n..  ., J. r .`  J.       `' 
//        .?`  .5        `` .%   .% .' L.'    t 
//        ,. ..1JL          .,   J .$.?`      . 
//                1.          .=` ` .J7??7<.. .; 
//                 JS..    ..^      L        7.: 
//                   `> ..       J.  4. 
//                   +   r `t   r ~=..G. 
//                    =   $  ,.  J 
//                    2   r   t  .; 
//              .,7!  r   t`7~..  j.. 
//              j   7~L...$=.?7r   r ;?1. 
//               8.      .=    j ..,^   .. 
//              r        G              . 
//            .,7,        j,           .>=. 
//         .J??,  `T....... %             .. 
//      ..^     <.  ~.    ,.             .D 
//    .?`        1   L     .7.........?Ti..l 
//   ,`           L  .    .%    .`!       `j, 
// .^             .  ..   .`   .^  .?7!?7+. 1 
//.`              .  .`..`7.  .^  ,`      .i.; 
//.7<..........~<<3?7!`    4. r  `          G% 
//                          J.` .!           % 
//                            JiJ           .` 
//                              .1.         J 
//                                 ?1.     .'         
//                                     7<..%