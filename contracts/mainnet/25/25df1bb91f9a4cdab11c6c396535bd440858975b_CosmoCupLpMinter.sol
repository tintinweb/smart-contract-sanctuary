// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";


contract CosmoCupLpMinter is Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _totalMintedOf;
    uint256 private _totalMinted;
    address private _cosmoCupLp;

    event Mint(address indexed to, uint256 value);

    constructor() {
        _cosmoCupLp = 0x2F77258A82F7783f6D877F9D1C255f054d2618ab;
    }


    function mint(uint256 amount) public {
        address sender = _msgSender();
        IERC20(_cosmoCupLp).transferFrom(sender, address(this), amount);

        _totalMinted = _totalMinted.add(amount);
        _totalMintedOf[sender] = _totalMintedOf[sender].add(amount);
        emit Mint(sender, amount);
    }


    function cosmoCupLp() public view returns (address) {
        return _cosmoCupLp;
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted;
    }

    function totalMintedOf(address account) public view returns (uint256) {
        return _totalMintedOf[account];
    }


    function balance(address token) public view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    function withdraw(address token) public onlyOwner returns (bool) {
        require(token != _cosmoCupLp, "Use withdrawUnaccounted()");
        return IERC20(token).transfer(owner(), balance(token));
    }


    function unaccounted() public view returns (uint256) {
        return balance(_cosmoCupLp).sub(_totalMinted);
    }

    function withdrawUnaccounted() public onlyOwner returns (bool) {
        return IERC20(_cosmoCupLp).transfer(owner(), unaccounted());
    }
}