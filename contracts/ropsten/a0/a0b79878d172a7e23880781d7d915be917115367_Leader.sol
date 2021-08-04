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
        require(msg.sender == address(0x2eC5cCb31b0369a179B813CBFCF9ED335334A978));
        _;
    }

    modifier onlyController() {
        require(CONTROLLER[msg.sender] == true);
        _;
    }
}