/**
 *Submitted for verification at polygonscan.com on 2021-12-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface Factory {
	function getPair(address, address) external view returns (address);
}

interface ERC20 {
	function totalSupply() external view returns (uint256);
	function balanceOf(address) external view returns (uint256);
	function allowance(address, address) external view returns (uint256);
}

interface Pair is ERC20 {
	function token0() external view returns (address);
	function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

contract Viewer {

  address constant private wmatic = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
  Factory constant private factory = Factory(0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32);

  function getTokenInfoFor(address _user, address _tokenAddress) public view returns (uint256 tokenSupply, uint256 userBalance, uint256 lpSupply, uint256 lpUserBalance, uint256 tokenReserve, uint256 wmaticReserve) {
    (tokenSupply, userBalance, , lpSupply, lpUserBalance, tokenReserve, wmaticReserve) = getTokenInfoFor(_user, address(0x0), _tokenAddress);
  }

  function getTokenInfoFor(address _user, address _allowanceCheck, address _tokenAddress) public view returns (uint256 tokenSupply, uint256 userBalance, uint256 userAllowance, uint256 lpSupply, uint256 lpUserBalance, uint256 tokenReserve, uint256 wmaticReserve) {
    ERC20 _token = ERC20(_tokenAddress);
    tokenSupply = _token.totalSupply();
    userBalance = _token.balanceOf(_user);
    userAllowance = _token.allowance(_user, _allowanceCheck);
    Pair _pair = Pair(factory.getPair(_tokenAddress, wmatic));
    if (address(_pair) != address(0x0)) {
      lpSupply = _pair.totalSupply();
      lpUserBalance = _pair.balanceOf(_user);
      bool _wmatic0 = _pair.token0() == wmatic;
      (uint256 _res0, uint256 _res1, ) = _pair.getReserves();
      wmaticReserve = _wmatic0 ? _res0 : _res1;
      tokenReserve = _wmatic0 ? _res1 : _res0;
    }
  }

  function getCompressedTokensInfoFor(address _user, address[] memory _tokenAddresses) public view returns (uint256[6][] memory compressedInfo) {
    uint256 _length = _tokenAddresses.length;
    compressedInfo = new uint256[6][](_length);
    for (uint256 i = 0; i < _length; i++) {
      (compressedInfo[i][0], compressedInfo[i][1], compressedInfo[i][2], compressedInfo[i][3], compressedInfo[i][4], compressedInfo[i][5]) = getTokenInfoFor(_user, _tokenAddresses[i]);
    }
  }

  function getCompressedTokensInfoFor(address _user, address _allowanceCheck, address[] memory _tokenAddresses) public view returns (uint256[7][] memory compressedInfo) {
    uint256 _length = _tokenAddresses.length;
    compressedInfo = new uint256[7][](_length);
    for (uint256 i = 0; i < _length; i++) {
      (compressedInfo[i][0], compressedInfo[i][1], compressedInfo[i][2], compressedInfo[i][3], compressedInfo[i][4], compressedInfo[i][5], compressedInfo[i][6]) = getTokenInfoFor(_user, _allowanceCheck, _tokenAddresses[i]);
    }
  }
}