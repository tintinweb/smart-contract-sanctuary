/**
 *Submitted for verification at BscScan.com on 2021-12-20
*/

// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.7;

interface ERC20 {
    function balanceOf(address who) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

contract Ownable {
    address owner;
    constructor() public {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "address is null");
        owner = newOwner;
    }
}

contract DnaBoxReseller is Ownable {
    struct User{
        bool isReseller;
        bool isBuyer;
        address ref;
        uint refAmount;
        uint amount;
        uint buyAmount;
        uint rewardNeedsCount;
    }
    mapping(address => User) users;
    address[] resellers;
    uint price;

    ERC20 buyToken;
    ERC20 sellToken;

    bool needReward = true;
    uint rewardNeeds = 1;
    uint rewardAmount = 1;
    ERC20 rewardToken;

    function buy(address ref, uint amount) public returns(bool) {
        require((users[ref].isReseller ||
                users[ref].isBuyer ||
                users[msg.sender].isBuyer ||
                users[msg.sender].isReseller), "ref need be reseller or buyer");
        require(amount > 0, "amount need great than zero");
        uint buyAmount = amount * price;
        require(buyToken.balanceOf(msg.sender) >= buyAmount, "insufficient buyToken balance");
        require(buyToken.allowance(msg.sender, address(this)) >= buyAmount, "insufficient buyToken allowed");

        buyToken.transferFrom(msg.sender, address(this), buyAmount);
        sellToken.transfer(msg.sender, amount);

        users[msg.sender].amount += amount;
        if(users[msg.sender].isBuyer == false && users[msg.sender].isReseller == false){
            users[msg.sender].isBuyer = true;
            users[msg.sender].ref = ref;
        }

        if(users[msg.sender].isReseller == false){
            address _ref = users[msg.sender].ref;

            //ref reward
            users[_ref].rewardNeedsCount += amount;
            if(needReward && (users[_ref].rewardNeedsCount >= rewardNeeds * 10 ** 18)){
                rewardToken.transfer(_ref, rewardAmount * 10 ** 18);
            }

            while(true){
                if(users[_ref].isReseller){
                    users[_ref].refAmount += amount;
                    break;
                }
                _ref = users[_ref].ref;
            }
        }

        return true;
    }

    function query_account(address addr) public view returns(uint, uint, uint, bool, bool){
        return (
            buyToken.balanceOf(addr),
            buyToken.allowance(addr, address(this)),
            sellToken.balanceOf(addr),
            users[addr].isReseller,
            users[addr].isBuyer
        );
    }

    function query_userinfo(address addr) public view returns(bool, bool, uint, uint, address, address){
        return (
            users[addr].isReseller,
            users[addr].isBuyer,
            users[addr].amount,
            users[addr].refAmount,
            users[addr].ref,
            query_root_reseller(addr)
        );
    }

    function query_reseller(uint index) public view returns(uint, uint){
        require(index < resellers.length, "index out of range");
        address addr = resellers[index];
        return (
            users[addr].amount,
            users[addr].refAmount
        );
    }

    function query_root_reseller(address addr) public view returns(address){
        require((users[addr].isReseller || users[addr].isBuyer), "addr need be reseller or buyer");
        address _ref = addr;

        while(true){
            if(users[_ref].isReseller){
                break;
            }
            if(users[_ref].isBuyer){
                _ref = users[_ref].ref;
            }
        }

        return _ref;
    }

    function query_resellers_count() public view returns(uint){
        return resellers.length;
    }

    function query_price() public view returns(uint){
        return price;
    }

    function sys_set_price(uint _price) public onlyOwner returns(bool) {
        require(_price > 0, "price need great than zero");
        price = _price;
        return true;
    }

    function sys_set_buyToken(address _buy_token_addr) public onlyOwner returns(bool) {
        require(_buy_token_addr != address(0), "address is null");
        buyToken = ERC20(_buy_token_addr);
        return true;
    }
    function sys_set_sellToken(address _sell_token_addr) public onlyOwner returns(bool) {
        require(_sell_token_addr != address(0), "address is null");
        sellToken = ERC20(_sell_token_addr);
        return true;
    }

    function sys_set_reseller(address _reseller_addr) public onlyOwner returns(bool) {
        require(_reseller_addr != address(0), "address is null");
        users[_reseller_addr].isReseller = true;
        resellers.push(_reseller_addr);
        return true;
    }

    function sys_set_needReward(bool _needReward) public onlyOwner returns(bool) {
        needReward = _needReward;
        return true;
    }

    function sys_set_rewardToken(address _rewardToken_addr) public onlyOwner returns(bool) {
        require(_rewardToken_addr != address(0), "address is null");
        rewardToken = ERC20(_rewardToken_addr);
        return true;
    }

    function sys_set_rewardAmount(uint _rewardAmount) public onlyOwner returns(bool) {
        require(_rewardAmount > 0, "rewardAmount need great than zero");
        rewardAmount = _rewardAmount;
        return true;
    }

    function sys_set_rewardNeeds(uint _rewardNeeds) public onlyOwner returns(bool) {
        require(_rewardNeeds > 0, "rewardNeeds need great than zero");
        rewardNeeds = _rewardNeeds;
        return true;
    }

    function sys_transfer_token(address _token_addr, address _receive_addr) public onlyOwner returns(bool) {
        require(_token_addr != address(0), "address is null");
        require(_receive_addr != address(0), "address is null");

        ERC20 token = ERC20(_token_addr);
        token.transfer(_receive_addr, token.balanceOf(address(this)));
        return true;
    }
}