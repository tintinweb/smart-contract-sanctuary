pragma solidity 0.4.25;

/*
* https://www.eth2x.fund/
*
* Eth2x - Ethereum Fund
*
* Maximum profit - 200%
*
* Distributions of funds:
* Payments to investors - 90%
* Project marketing - 10%
*
* [✓] Up to 100 eth / 1 % daily
* [✓] From 200-300 eth / 2% daily
* [✓] From 300-400 eth / 3% daily
* [✓] From 400-500 eth / 4% daily
* [✓] From 500 eth / 5% daily
*
* [✓] Referral bouns - 2%
* [✓] Referral cashback - 3%
*/

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        if(a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns(uint256) {
        require(b != 0);
        return a % b;
    }
}

contract Eth2x {
    using SafeMath for uint;

    struct Investor {
        uint invested;
        uint payouts;
        uint first_invest;
        uint last_payout;
        address referrer;
    }

    uint constant public COMMISSION = 10;
    uint constant public WITHDRAW = 50;
    uint constant public REFBONUS = 2;
    uint constant public CASHBACK = 3;
    uint constant public MULTIPLICATION = 2;

    address public beneficiary = 0x3368e0A06D0Ae1b826B5171Ced8C7c94D785f9E5;

    mapping(address => Investor) public investors;

    event AddInvestor(address indexed holder);

    event Payout(address indexed holder, uint amount);
    event Deposit(address indexed holder, uint amount, address referrer);
    event RefBonus(address indexed from, address indexed to, uint amount);
    event CashBack(address indexed holder, uint amount);
    event Withdraw(address indexed holder, uint amount);

    function bonusSize() view public returns(uint) {
        uint b = address(this).balance;

        if(b >= 500 ether) return 5;
        if(b >= 400 ether) return 4;
        if(b >= 300 ether) return 3;
        if(b >= 200 ether) return 2;
        return 1;
    }

    function payoutSize(address _to) view public returns(uint) {
        uint max = investors[_to].invested.mul(MULTIPLICATION);
        if(investors[_to].invested == 0 || investors[_to].payouts >= max) return 0;

        uint payout = investors[_to].invested.mul(bonusSize()).div(100).mul(block.timestamp.sub(investors[_to].last_payout)).div(1 days);
        return investors[_to].payouts.add(payout) > max ? max.sub(investors[_to].payouts) : payout;
    }

    function withdrawSize(address _to) view public returns(uint) {
        uint max = investors[_to].invested.div(100).mul(WITHDRAW);
        if(investors[_to].invested == 0 || investors[_to].payouts >= max) return 0;

        return max.sub(investors[_to].payouts);
    }

    function bytesToAddress(bytes bys) pure private returns(address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }

    function() payable external {
        if(investors[msg.sender].invested > 0) {
            uint payout = payoutSize(msg.sender);

            require(msg.value > 0 || payout > 0, "No payouts");

            if(payout > 0) {
                investors[msg.sender].last_payout = block.timestamp;
                investors[msg.sender].payouts = investors[msg.sender].payouts.add(payout);

                msg.sender.transfer(payout);

                emit Payout(msg.sender, payout);
            }

            if(investors[msg.sender].payouts >= investors[msg.sender].invested.mul(MULTIPLICATION)) {
                delete investors[msg.sender];

                emit Withdraw(msg.sender, 0);
            }
        }

        if(msg.value == 0.00000007 ether) {
            require(investors[msg.sender].invested > 0, "You have not invested anything yet");

            uint amount = withdrawSize(msg.sender);

            require(amount > 0, "You have nothing to withdraw");
            
            msg.sender.transfer(amount);

            delete investors[msg.sender];
            
            emit Withdraw(msg.sender, amount);
        }
        else if(msg.value > 0) {
            require(msg.value >= 0.01 ether, "Minimum investment amount 0.01 ether");

            investors[msg.sender].last_payout = block.timestamp;
            investors[msg.sender].invested = investors[msg.sender].invested.add(msg.value);

            beneficiary.transfer(msg.value.mul(COMMISSION).div(100));

            if(investors[msg.sender].first_invest == 0) {
                investors[msg.sender].first_invest = block.timestamp;

                if(msg.data.length > 0) {
                    address ref = bytesToAddress(msg.data);

                    if(ref != msg.sender && investors[ref].invested > 0 && msg.value >= 1 ether) {
                        investors[msg.sender].referrer = ref;

                        uint ref_bonus = msg.value.mul(REFBONUS).div(100);
                        ref.transfer(ref_bonus);

                        emit RefBonus(msg.sender, ref, ref_bonus);

                        uint cashback_bonus = msg.value.mul(CASHBACK).div(100);
                        msg.sender.transfer(cashback_bonus);

                        emit CashBack(msg.sender, cashback_bonus);
                    }
                }
                emit AddInvestor(msg.sender);
            }

            emit Deposit(msg.sender, msg.value, investors[msg.sender].referrer);
        }
    }
}