/**
 *Submitted for verification at Etherscan.io on 2021-08-04
*/

// SPDX-License-Identifier: MIT

// THIRM PROTOCOL Leader

pragma solidity ^0.8.3;

interface ENS {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

interface ERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function mint(address to, uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}

contract Leader {
    mapping(string => ERC20) public TOKEN;
    mapping(address => bool) public CONTROLLER;

    function nftOwner() public view returns (address) {
        return
            ENS(0x57f1887a8BF19b14fC0dF6Fd9B2acc9Af147eA85).ownerOf(
                77518759032194629606678436102314512673279501256913318464318261388698786067419
            );
    }

    function tokentotalSupply(string memory _coin)
        public
        view
        returns (uint256)
    {
        return TOKEN[_coin].totalSupply();
    }

    function tokenBurn(
        string memory _coin,
        address _userAddress,
        uint256 _amount
    ) external onlyController {
        require(_amount <= TOKEN[_coin].balanceOf(_userAddress), "no balance");

        TOKEN[_coin].burnFrom(_userAddress, _amount);
    }

    function tokenMint(
        string memory _coin,
        address _userAddress,
        uint256 _amount
    ) external onlyController {
        TOKEN[_coin].mint(_userAddress, _amount);
    }

    function controllerControl(address _addr, bool _yn) external onlyOwner {
        CONTROLLER[_addr] = _yn;
    }

    function Init(string memory _coin, address _token) external onlyOwner {
        TOKEN[_coin] = ERC20(_token);
    }

    modifier onlyOwner() {
        require(msg.sender == nftOwner());
        _;
    }

    modifier onlyController() {
        require(CONTROLLER[msg.sender] == true);
        _;
    }
}