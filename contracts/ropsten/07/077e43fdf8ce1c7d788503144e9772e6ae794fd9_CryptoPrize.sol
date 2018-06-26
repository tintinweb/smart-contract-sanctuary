pragma solidity ^0.4.23;

/*
    CryptoPrize(uint256 _budget, uint256 _startYum, address _token_address)   // this will unlock the prize and send yum to user
  @author Yumerium Ltd
*/
contract YUM {
    function transfer(address _to, uint256 _value) public;
}


contract CryptoPrize {
    uint256 public budget;
    uint256 public totalUnlocked;
    uint256 public startYum;
    uint256 public count;
    address public creator;
    YUM public Token;

    event UnlockPrize(address to, uint256 amount);
    event CalcNextPrize(uint256 count, uint256 amount);

    constructor(uint256 _budget, uint256 _startYum, address _token_address) public {
        count = 0;
        creator = msg.sender;
        budget = _budget;
        startYum = _startYum;
        Token = YUM(_token_address);
    }

    function calcNextPrize() public returns (uint256) {
        uint256 amount = startYum / (count + 1);
        emit CalcNextPrize(count, amount);
        count++;
        return amount;
    }
    
    function sendyum(address to) external {
        require(msg.sender==creator);
        
        uint256 amount = calcNextPrize();
        uint256 total = totalUnlocked + amount;
        
        require(total<=budget);
        
        totalUnlocked = total;
        
        Token.transfer(to, amount);
        emit UnlockPrize(to, amount);
    }

    // change creator address
    function changeCreator(address _creator) external {
        require(msg.sender==creator);
        creator = _creator;
    }

    // change creator address
    function changeYumAddress(address _token_address) external {
        require(msg.sender==creator);
        Token = YUM(_token_address);
    }

}