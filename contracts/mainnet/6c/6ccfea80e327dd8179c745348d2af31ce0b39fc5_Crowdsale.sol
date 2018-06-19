pragma solidity ^0.4.16;

interface token {
    function transfer(address receiver, uint amount) public;
}

contract Crowdsale {
    address public beneficiary;
    uint public price;
    bool crowdsaleClosed = false;
    token public tokenReward;
    mapping(address => uint256) public balanceOf;

    event FundTransfer(address backer, uint amount, bool isContribution);

    /**
     * Constrctor function
     *
     * Setup the owner
     */
    function Crowdsale () public {
        beneficiary = 0x1e19E36928bA65184669d8A7e7A37d8B061B9022;
        price = 0.00058 * 1 ether;
        tokenReward = token(0xe8EF8d9d9Ff515720A62d2E2f14f3b5b677C6670);
    }

    /**
     * Fallback function
     *
     * The function without name is the default function that is called whenever anyone sends funds to a contract
     */
    function () public payable {
        require(!crowdsaleClosed);
        uint amount = msg.value;
        balanceOf[msg.sender] += amount;
        tokenReward.transfer(msg.sender, (amount  * 1 ether) / price);
        FundTransfer(msg.sender, amount, true);
    }
    
    function changePrice(uint newprice) public {
         if (beneficiary == msg.sender) {
             price = newprice;
         }
    }

    function safeWithdrawal(uint amount) public {

        if (beneficiary == msg.sender) {
            if (beneficiary.send(amount)) {
                FundTransfer(beneficiary, amount, false);
            }
        }
    }
    
    function safeTokenWithdrawal(uint amount) public {
         if (beneficiary == msg.sender) {
             tokenReward.transfer(msg.sender, amount);
        }
    }
    
     function crowdsaleStop() public {
         if (beneficiary == msg.sender) {
            crowdsaleClosed = true;
        }
    }
    
    function crowdsaleStart() public {
         if (beneficiary == msg.sender) {
            crowdsaleClosed = false;
        }
    }
}