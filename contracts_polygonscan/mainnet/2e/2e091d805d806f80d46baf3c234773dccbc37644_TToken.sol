/**
 *Submitted for verification at polygonscan.com on 2021-08-31
*/

pragma solidity 0.7.6;

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
// Test Token
contract TToken {
  string private _name;
  string private _symbol;
  uint8 private _decimals;

  address private _owner;

  uint256 internal _totalSupply;

  mapping(address => uint256) private _balance;
  mapping(address => mapping(address => uint256)) private _allowance;

  modifier _onlyOwner_() {
    require(msg.sender == _owner, "ERR_NOT_OWNER");
    _;
  }

  event Approval(address indexed src, address indexed dst, uint256 amt);
  event Transfer(address indexed src, address indexed dst, uint256 amt);

  // Math
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    require((c = a + b) >= a);
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
    require((c = a - b) <= a);
  }

  constructor(
    string memory name,
    string memory symbol,
    uint256 amt
  ) public {
    _name = name;
    _symbol = symbol;
    _decimals = 18;
    _owner = msg.sender;
    _mint(msg.sender, amt);
  }

  function name() public view returns (string memory) {
    return _name;
  }

  function symbol() public view returns (string memory) {
    return _symbol;
  }

  function decimals() public view returns (uint8) {
    return _decimals;
  }

  function _move(
    address src,
    address dst,
    uint256 amt
  ) internal {
    require(_balance[src] >= amt, "!bal");
    _balance[src] = sub(_balance[src], amt);
    _balance[dst] = add(_balance[dst], amt);
    emit Transfer(src, dst, amt);
  }

  function _push(address to, uint256 amt) internal {
    _move(address(this), to, amt);
  }

  function _pull(address from, uint256 amt) internal {
    _move(from, address(this), amt);
  }

  function _mint(address dst, uint256 amt) internal {
    _balance[dst] = add(_balance[dst], amt);
    _totalSupply = add(_totalSupply, amt);
    emit Transfer(address(0), dst, amt);
  }

  function allowance(address src, address dst) external view returns (uint256) {
    return _allowance[src][dst];
  }

  function balanceOf(address whom) external view returns (uint256) {
    return _balance[whom];
  }

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function approve(address dst, uint256 amt) external returns (bool) {
    _allowance[msg.sender][dst] = amt;
    emit Approval(msg.sender, dst, amt);
    return true;
  }

  function mint(address dst, uint256 amt) public returns (bool) {
    _mint(dst, amt);
    return true;
  }

  function burn(uint256 amt) public returns (bool) {
    require(_balance[address(this)] >= amt, "!bal");
    _balance[address(this)] = sub(_balance[address(this)], amt);
    _totalSupply = sub(_totalSupply, amt);
    emit Transfer(address(this), address(0), amt);
    return true;
  }

  function transfer(address dst, uint256 amt) external returns (bool) {
    _move(msg.sender, dst, amt);
    return true;
  }

  function transferFrom(
    address src,
    address dst,
    uint256 amt
  ) external returns (bool) {
    require(msg.sender == src || amt <= _allowance[src][msg.sender], "!spender");
    _move(src, dst, amt);
    if (msg.sender != src && _allowance[src][msg.sender] != uint256(-1)) {
      _allowance[src][msg.sender] = sub(_allowance[src][msg.sender], amt);
      emit Approval(msg.sender, dst, _allowance[src][msg.sender]);
    }
    return true;
  }

  function minterCap(address src) public view returns (uint256) {
    return uint256(~0);
  }

  function cap() public view returns (uint256) {
    return uint256(~0);
  }
}