pragma solidity ^0.4.23;


contract TokenSwap{
    mapping (address=>address) internal _swapMap;
    event NBAIRegister (address ERC20Wallet, address NBAIWallet);

    constructor() public{
    }

    function register(address NBAIWallet) public{
        require(_swapMap[msg.sender] == address(0));
        _swapMap[msg.sender] = NBAIWallet;
        emit NBAIRegister(msg.sender, NBAIWallet);
    }

    function getNBAIWallet (address ERC20Wallet) constant public returns (address){
        return _swapMap[ERC20Wallet];
    }
}