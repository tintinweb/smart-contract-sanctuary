pragma solidity ^0.4.21;


/**
 * An interface providing the necessary Beercoin functionality
 */
interface Beercoin {
    function transfer(address _to, uint256 _amount) external;
    function balanceOf(address _owner) external view returns (uint256);
    function decimals() external pure returns (uint8);
}


/**
 * A contract that defines owner and guardians of the ICO
 */
contract GuardedBeercoinICO {
    address public owner;

    address public constant guardian1 = 0x7d54aD7DA2DE1FD3241e1c5e8B5Ac9ACF435070A;
    address public constant guardian2 = 0x065a6D3c1986E608354A8e7626923816734fc468;
    address public constant guardian3 = 0x1c387D6FDCEF351Fc0aF5c7cE6970274489b244B;

    address public guardian1Vote = 0x0;
    address public guardian2Vote = 0x0;
    address public guardian3Vote = 0x0;

    /**
     * Restrict to the owner only
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * Restrict to guardians only
     */
    modifier onlyGuardian() {
        require(msg.sender == guardian1 || msg.sender == guardian2 || msg.sender == guardian3);
        _;
    }

    /**
     * Construct the GuardedBeercoinICO contract
     * and make the sender the owner
     */
    function GuardedBeercoinICO() public {
        owner = msg.sender;
    }

    /**
     * Declare a new owner
     *
     * @param newOwner the new owner&#39;s address
     */
    function setOwner(address newOwner) onlyGuardian public {
        if (msg.sender == guardian1) {
            if (newOwner == guardian2Vote || newOwner == guardian3Vote) {
                owner = newOwner;
                guardian1Vote = 0x0;
                guardian2Vote = 0x0;
                guardian3Vote = 0x0;
            } else {
                guardian1Vote = newOwner;
            }
        } else if (msg.sender == guardian2) {
            if (newOwner == guardian1Vote || newOwner == guardian3Vote) {
                owner = newOwner;
                guardian1Vote = 0x0;
                guardian2Vote = 0x0;
                guardian3Vote = 0x0;
            } else {
                guardian2Vote = newOwner;
            }
        } else if (msg.sender == guardian3) {
            if (newOwner == guardian1Vote || newOwner == guardian2Vote) {
                owner = newOwner;
                guardian1Vote = 0x0;
                guardian2Vote = 0x0;
                guardian3Vote = 0x0;
            } else {
                guardian3Vote = newOwner;
            }
        }
    }
}


/**
 * A contract that defines the Beercoin ICO
 */
contract BeercoinICO is GuardedBeercoinICO {
    Beercoin internal beercoin = Beercoin(0x7367A68039d4704f30BfBF6d948020C3B07DFC59);

    uint public constant price = 0.000006 ether;
    uint public constant softCap = 48 ether;
    uint public constant begin = 1526637600; // 2018-05-18 12:00:00 (UTC+01:00)
    uint public constant end = 1530395999;   // 2018-06-30 23:59:59 (UTC+01:00)
    
    event FundTransfer(address backer, uint amount, bool isContribution);
   
    mapping(address => uint256) public balanceOf;
    uint public soldBeercoins = 0;
    uint public raisedEther = 0 ether;

    bool public paused = false;

    /**
     * Restrict to the time when the ICO is open
     */
    modifier isOpen {
        require(now >= begin && now <= end && !paused);
        _;
    }

    /**
     * Restrict to the state of enough Ether being gathered
     */
    modifier goalReached {
        require(raisedEther >= softCap);
        _;
    }

    /**
     * Restrict to the state of not enough Ether
     * being gathered after the time is up
     */
    modifier goalNotReached {
        require(raisedEther < softCap && now > end);
        _;
    }

    /**
     * Transfer Beercoins to a user who sent Ether to this contract
     */
    function() payable isOpen public {
        uint etherAmount = msg.value;
        balanceOf[msg.sender] += etherAmount;

        uint beercoinAmount = (etherAmount * 10**uint(beercoin.decimals())) / price;
        beercoin.transfer(msg.sender, beercoinAmount);

        soldBeercoins += beercoinAmount;        
        raisedEther += etherAmount;
        emit FundTransfer(msg.sender, etherAmount, true);
    }

    /**
     * Transfer Beercoins to a user who purchased via other payment methods
     *
     * @param to the address of the recipient
     * @param beercoinAmount the amount of Beercoins to send
     */
    function transfer(address to, uint beercoinAmount) isOpen onlyOwner public {        
        beercoin.transfer(to, beercoinAmount);

        uint etherAmount = beercoinAmount * price;        
        raisedEther += etherAmount;

        emit FundTransfer(msg.sender, etherAmount, true);
    }

    /**
     * Withdraw the sender&#39;s contributed Ether in case the goal has not been reached
     */
    function withdraw() goalNotReached public {
        uint amount = balanceOf[msg.sender];
        require(amount > 0);

        balanceOf[msg.sender] = 0;
        msg.sender.transfer(amount);

        emit FundTransfer(msg.sender, amount, false);
    }

    /**
     * Withdraw the contributed Ether stored in this contract
     * if the funding goal has been reached.
     */
    function claimFunds() onlyOwner goalReached public {
        uint etherAmount = address(this).balance;
        owner.transfer(etherAmount);

        emit FundTransfer(owner, etherAmount, false);
    }

    /**
     * Withdraw the remaining Beercoins in this contract
     */
    function claimBeercoins() onlyOwner public {
        uint beercoinAmount = beercoin.balanceOf(address(this));
        beercoin.transfer(owner, beercoinAmount);
    }

    /**
     * Pause the token sale
     */
    function pause() onlyOwner public {
        paused = true;
    }

    /**
     * Resume the token sale
     */
    function resume() onlyOwner public {
        paused = false;
    }
}