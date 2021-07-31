/**
 *Submitted for verification at Etherscan.io on 2021-07-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

interface ENS {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

interface ERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function mint(address to, uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}

contract Mapping {

    uint256 public lastTimeExecuted = block.timestamp;
    address public THIRM = 0xb526FD41360c98929006f3bDcBd16d55dE4b0069;

    mapping(string => address) private addressMap;

    function nftOwner() public view returns (address) {
        return ENS(0x57f1887a8BF19b14fC0dF6Fd9B2acc9Af147eA85).ownerOf(77518759032194629606678436102314512673279501256913318464318261388698786067419);
    }

    function getBurnAmount() public view returns (uint256) {
        uint256 burnAmount = (ERC20(THIRM).totalSupply() / 100000000) * 6;
        return burnAmount;
    }
    
     function toMint() public view returns (uint256) {
        uint256 toMintint = block.timestamp - lastTimeExecuted;
        return toMintint * 200000000000000;
    }

    function getAddressMap(string memory _coinAddress) public view returns (address) {
        return addressMap[_coinAddress];
    }

    function setAddressMap(string memory _coinaddress) external {
        require(addressMap[_coinaddress] == address(0), "Address already mapped");

        require(getBurnAmount() <= ERC20(THIRM).balanceOf(msg.sender),"No balance");
        require(getBurnAmount() <= ERC20(THIRM).allowance(msg.sender, address(this)), "No allowance");

        ERC20(THIRM).burnFrom(msg.sender, getBurnAmount());
        addressMap[_coinaddress] = msg.sender;
        
        if(toMint() > ERC20(THIRM).totalSupply()/200){
        ERC20(THIRM).mint(nftOwner(), toMint());
        lastTimeExecuted = block.timestamp;
        }

    }

    function run() external {
        ERC20(THIRM).mint(nftOwner(), toMint());
        lastTimeExecuted = block.timestamp;
    }
}