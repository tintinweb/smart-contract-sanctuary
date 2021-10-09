/**
 *Submitted for verification at BscScan.com on 2021-10-09
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-28
 */

pragma solidity ^0.4.26;

contract BEP20 {
    function totalSupply() public constant returns (uint256);

    function balanceOf(address tokenOwner)
        public
        constant
        returns (uint256 balance);

    function allowance(address tokenOwner, address spender)
        public
        constant
        returns (uint256 remaining);

    function transfer(address to, uint256 tokens) public returns (bool success);

    function approve(address spender, uint256 tokens)
        public
        returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(
        address indexed tokenOwner,
        address indexed spender,
        uint256 tokens
    );
}

contract USDTFACTORY {
    address USDT = 0x55d398326f99059fF775485246999027B3197955;
    uint256 public BANKNOTES_TO_COMPOUND_PRINTERS = 864000; // for final version should be seconds in a day
    uint256 PSN = 10000;
    uint256 PSNH = 5000;
    uint256 DEV_FEES = 5;
    uint256 REF_FEES = 10;
    bool public initialized = false;
    address public ceoAddress;
    address public ceoAddress2;
    mapping(address => uint256) public compounderyPrinters;
    mapping(address => uint256) public claimedBanknotes;
    mapping(address => uint256) public lastCompound;
    mapping(address => address) public referrals;
    uint256 public marketBanknotes;

    constructor() public {
        ceoAddress = address(0xF115813dAc5Ce1700cdAA07d01575b1a1AdAb9A9);
        ceoAddress2 = address(0x89bF4017e56eBa703c337292053959CfAA01E646);
    }

    function compoundBanknotes(address ref) public {
        require(initialized);
        if (ref == msg.sender) {
            ref = 0;
        }
        if (referrals[msg.sender] == 0 && referrals[msg.sender] != msg.sender) {
            referrals[msg.sender] = ref;
        }
        uint256 banknotesUsed = getMyBanknotes();
        uint256 newPrinters = SafeMath.div(
            banknotesUsed,
            BANKNOTES_TO_COMPOUND_PRINTERS
        );
        compounderyPrinters[msg.sender] = SafeMath.add(
            compounderyPrinters[msg.sender],
            newPrinters
        );
        claimedBanknotes[msg.sender] = 0;
        lastCompound[msg.sender] = now;

        //send referral banknotes
        claimedBanknotes[referrals[msg.sender]] = SafeMath.add(
            claimedBanknotes[referrals[msg.sender]],
            SafeMath.div(banknotesUsed, REF_FEES)
        );

        //boost market to nerf miners hoarding
        marketBanknotes = SafeMath.add(
            marketBanknotes,
            SafeMath.div(banknotesUsed, 5)
        );
    }

    function sellBanknotes() public {
        require(initialized);
        uint256 hasBanknotes = getMyBanknotes();
        uint256 banknoteValue = calculateBanknoteSell(hasBanknotes);
        uint256 fee = devFee(banknoteValue);
        uint256 fee2 = fee / 2;
        claimedBanknotes[msg.sender] = 0;
        lastCompound[msg.sender] = now;
        marketBanknotes = SafeMath.add(marketBanknotes, hasBanknotes);
        BEP20(USDT).transfer(ceoAddress, fee);
        BEP20(USDT).transfer(ceoAddress2, fee2);
        BEP20(USDT).transfer(
            address(msg.sender),
            SafeMath.sub(banknoteValue, fee)
        );
    }

    function buyBanknotes(address ref, uint256 amount) public {
        require(initialized);

        BEP20(USDT).transferFrom(address(msg.sender), address(this), amount);

        uint256 balance = BEP20(USDT).balanceOf(address(this));
        uint256 banknotesBought = calculateBanknoteBuy(
            amount,
            SafeMath.sub(balance, amount)
        );
        banknotesBought = SafeMath.sub(
            banknotesBought,
            devFee(banknotesBought)
        );
        uint256 fee = devFee(amount);
        uint256 fee2 = SafeMath.div(fee, 2);
        BEP20(USDT).transfer(ceoAddress, fee2);
        BEP20(USDT).transfer(ceoAddress2, fee2);
        claimedBanknotes[msg.sender] = SafeMath.add(
            claimedBanknotes[msg.sender],
            banknotesBought
        );
        compoundBanknotes(ref);
    }

    function calculateTrade(
        uint256 rt,
        uint256 rs,
        uint256 bs
    ) public view returns (uint256) {
        return
            SafeMath.div(
                SafeMath.mul(PSN, bs),
                SafeMath.add(
                    PSNH,
                    SafeMath.div(
                        SafeMath.add(
                            SafeMath.mul(PSN, rs),
                            SafeMath.mul(PSNH, rt)
                        ),
                        rt
                    )
                )
            );
    }

    function calculateBanknoteSell(uint256 banknotes)
        public
        view
        returns (uint256)
    {
        return
            calculateTrade(
                banknotes,
                marketBanknotes,
                BEP20(USDT).balanceOf(address(this))
            );
    }

    function calculateBanknoteBuy(uint256 usdt, uint256 contractBalance)
        public
        view
        returns (uint256)
    {
        return calculateTrade(usdt, contractBalance, marketBanknotes);
    }

    function calculateBanknoteBuySimple(uint256 usdt)
        public
        view
        returns (uint256)
    {
        return calculateBanknoteBuy(usdt, BEP20(USDT).balanceOf(address(this)));
    }

    function devFee(uint256 amount) public view returns (uint256) {
        return SafeMath.div(SafeMath.mul(amount, DEV_FEES), 100);
    }

    function seedMarket(uint256 amount) public {
        BEP20(USDT).transferFrom(address(msg.sender), address(this), amount);
        require(marketBanknotes == 0);
        initialized = true;
        marketBanknotes = 86400000000;
    }

    function getBalance() public view returns (uint256) {
        return BEP20(USDT).balanceOf(address(this));
    }

    function getMyPrinters() public view returns (uint256) {
        return compounderyPrinters[msg.sender];
    }

    function getMyBanknotes() public view returns (uint256) {
        return
            SafeMath.add(
                claimedBanknotes[msg.sender],
                getBanknotesSinceLastCompound(msg.sender)
            );
    }

    function getBanknotesSinceLastCompound(address adr)
        public
        view
        returns (uint256)
    {
        uint256 secondsPassed = min(
            BANKNOTES_TO_COMPOUND_PRINTERS,
            SafeMath.sub(now, lastCompound[adr])
        );
        return SafeMath.mul(secondsPassed, compounderyPrinters[adr]);
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}

library SafeMath {
    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
     * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}