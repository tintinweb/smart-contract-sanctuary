/**
 *Submitted for verification at Etherscan.io on 2021-12-22
*/

pragma solidity ^0.4.17;

contract BridgeSwap{
    address owner = msg.sender;
    uint minAmount = 0.3 ether;
    uint fee = 0.01 ether;
    bool internal locked;
    struct UserLockInfo{
        string stxAddress;
        uint tvl;
        uint latestValueLocked;
    }
    mapping(address => UserLockInfo) public usersInfo;
    
    event deposit(string _to, uint amount);

    modifier onlyOwner {
      require(msg.sender == owner);
      _;
   }

    modifier reentranceGuard{
        require(!locked);
        locked = true;
        _;
        locked = false;
    }

    function lock(string _to) public  payable {
        require((msg.value-fee) > minAmount);
        bool success = owner.send(fee);
        require(success);
        uint tvl = usersInfo[msg.sender].tvl + msg.value-fee;
        usersInfo[msg.sender] = UserLockInfo(_to, tvl, msg.value-fee);
        deposit(_to, (msg.value-fee));
    }

    function release(address _to, uint _amount) public payable onlyOwner reentranceGuard{
        require(usersInfo[_to].tvl >= _amount);
        require(_to.send(_amount));
        usersInfo[_to].tvl -= _amount;
    }

    function setFee(uint newFee) public onlyOwner{
        fee = newFee;
    }
    
    function setMinAmount(uint newMinAmount) public onlyOwner{
        minAmount = newMinAmount;
    }

    function getBalance() public view returns (uint){
        return address(this).balance;
    }
}