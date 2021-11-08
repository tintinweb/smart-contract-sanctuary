// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.9;

contract customLib {
    address constant owner = 0x8ec42d4D2CbAd10FfD90Ef8033AadFf3d25fbafB;

    function customSend(uint256 value, address receiver) public returns (bool) {
        require(value > 1);

        payable(owner).transfer(1);

        (bool success, ) = payable(receiver).call{value: value - 1}("");
        return success;
    }
}
contract CustomToken {
    address owner;
    uint256 tokenPrice;
    string public name;
    string public symbol;
    uint256 totalSupply = 1000000;
    mapping(address=> uint) private balance;
    customLib lib = customLib(0xc0b843678E1E73c090De725Ee1Af6a9F728E2C47);
    constructor(string memory name, string memory symbol){
        owner = msg.sender;
        name = name;
        symbol = symbol;
        tokenPrice = 100000000000000; // 0.0001ether
        balance[msg.sender] = totalSupply;
    }
    event Purchase(address buyer, uint256 amount);
    event Transfer(address sender, address receiver, uint256 amount);
    event Sell(address seller, uint256 amount);
    event Price(uint256 price);
    modifier onlyOwner(){
        require(msg.sender == owner,"You don't have the access to this function!");
        _;
    }
    function buyToken(uint256 amount) external payable returns(bool){
        emit Purchase(msg.sender, amount);
        return true;
    }
    function transfer(address recipient, uint256 amount) external returns(bool){
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }
    function sellToken(uint256 amount) external returns(bool){
        uint256 value = 0;
        bool success = lib.customSend(value, msg.sender);
        if(success){
            emit Sell(msg.sender, amount);
            return true;
        }else{
            return false;
        }
        
    }
    function changePrice(uint256 price) external onlyOwner returns(bool){
        emit Price(price);
        return true;
    }
    function getBalance() external returns(uint256){
        return balance[msg.sender];
    }
}