pragma solidity ^0.4.24;

contract ETHCOOLMain {

    using SafeMath for uint;

    struct Deposit {
        address user;
        uint amount;
    }

    address public owner;
    uint public main_balance;
    uint public next;

    mapping (address => uint) public user_balances;
    mapping (address => address) public user_referrals;
    
    Deposit[] public deposits;
    
    constructor() public {
        owner = msg.sender;
        user_referrals[owner] = owner;
        main_balance = 0;
        next = 0;
    }

    function publicGetBalance(address user) view public returns (uint) {
        return user_balances[user];
    }

    function publicGetStatus() view public returns (uint, uint, uint) {
        return (main_balance, next, deposits.length);
    }

    function publicGetDeposit(uint index) view public returns (address, address, uint) {
        return (deposits[index].user, user_referrals[deposits[index].user], deposits[index].amount);
    }

    function userWithdraw() public {
        userPayout();
        
        if (user_balances[msg.sender] > 0) {
            uint amount = user_balances[msg.sender];
            user_balances[msg.sender] = 0;
            msg.sender.transfer(amount);
        }
    }

    function userDeposit(address referral) public payable {
        if (msg.value > 0) {
            if(user_referrals[msg.sender] == address(0)) {
                user_referrals[msg.sender] = (referral != address(0) && referral != msg.sender) ? referral : owner;
            }

            Deposit memory deposit = Deposit(msg.sender, msg.value);
            deposits.push(deposit);

            uint referral_cut = msg.value.div(100);
            uint owner_cut = msg.value.mul(4).div(100);
            user_balances[user_referrals[msg.sender]] = user_balances[user_referrals[msg.sender]].add(referral_cut);
            user_balances[owner] = user_balances[owner].add(owner_cut);
            main_balance = main_balance.add(msg.value).sub(referral_cut).sub(owner_cut);
        }

        userPayout();
    }

    function userReinvest() public {
        if (user_balances[msg.sender] > 0) {
            Deposit memory deposit = Deposit(msg.sender, user_balances[msg.sender]);
            deposits.push(deposit);

            uint owner_cut = user_balances[msg.sender].mul(5).div(100);
            user_balances[owner] = user_balances[owner].add(owner_cut);
            main_balance = main_balance.add(user_balances[msg.sender]).sub(owner_cut);
            user_balances[msg.sender] = 0;
        }

        userPayout();
    }

    function userPayout() public {
        if (next < deposits.length) {
            uint next_payout = deposits[next].amount.mul(120).div(100);
            if (main_balance >= next_payout) {
                user_balances[deposits[next].user] = user_balances[deposits[next].user].add(next_payout);
                main_balance = main_balance.sub(next_payout);
                next = next.add(1);
            }
        }
    }

    function contractBoost(uint share) public payable {
        if (msg.value > 0) {
            uint owner_cut = msg.value.mul(share).div(100);
            user_balances[owner] = user_balances[owner].add(owner_cut);
            main_balance = main_balance.add(msg.value).sub(owner_cut);
        }
    }
}

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}