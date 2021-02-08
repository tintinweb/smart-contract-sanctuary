pragma solidity ^0.5.0;

import "./DappToken.sol";
import "./SyfiToken.sol";

contract TokenFarm {
    string public name = "Dapp Token Farm";
    address public owner;
    DappToken public dappToken;
    SyfiToken public syfiToken;

    address[] public stakers;
    mapping(address => uint) public stakingBalance;
    mapping(address => bool) public hasStaked;
    mapping(address => bool) public isStaking;

    constructor(DappToken _dappToken, SyfiToken _syfiToken) public {
        dappToken = _dappToken;
        syfiToken = _syfiToken;
        owner = msg.sender;
    }

    function stakeTokens(uint _amount) public {
        // Require amount greater than 0
        require(_amount > 0, "amount cannot be 0");

        // Trasnfer 2yfi tokens to this contract for staking
        syfiToken.transferFrom(msg.sender, address(this), _amount);

        // Update staking balance
        stakingBalance[msg.sender] = stakingBalance[msg.sender] + _amount;

        // Add user to stakers array *only* if they haven't staked already
        if(!hasStaked[msg.sender]) {
            stakers.push(msg.sender);
        }

        // Update staking status
        isStaking[msg.sender] = true;
        hasStaked[msg.sender] = true;
    }

    // Unstaking Tokens (Withdraw)
    function unstakeTokens() public {
        // Fetch staking balance
        uint balance = stakingBalance[msg.sender];

        // Require amount greater than 0
        require(balance > 0, "staking balance cannot be 0");

        // Transfer 2yfi tokens to from contract  
        syfiToken.transfer(msg.sender, balance);

        // Reset staking balance
        stakingBalance[msg.sender] = 0;

        // Update staking status
        isStaking[msg.sender] = false;
    }

    // Issuing Tokens staking one
    function issueTokensbig() public {
        // Issue tokens to all stakers
        for (uint i=0; i<stakers.length; i++) {
            address recipient = stakers[i];
            uint balance = stakingBalance[recipient];
            if(balance > 249000000000000000000) {
                syfiToken.transfer(recipient, balance = 1000000000000000000);
            }
        }
    }

    // Issuing Tokens staking two
    function issueTokensbigs() public {
        // Issue tokens to all stakers
        for (uint i=0; i<stakers.length; i++) {
            address recipient = stakers[i];
            uint balance = stakingBalance[recipient];
            if(balance > 249000000000000000000) {
                syfiToken.transfer(recipient, balance = 500000000000000000);
            }
        }
    }

    // Issuing Tokens staking three
    function issueTokenspoin() public {
        // Issue tokens to all stakers
        for (uint i=0; i<stakers.length; i++) {
            address recipient = stakers[i];
            uint balance = stakingBalance[recipient];
            if(balance > 99000000000000000000) {
                syfiToken.transfer(recipient, balance = 500000000000000000);
            }
        }
    }

    // Issuing Tokens staking four
    function issueTokenspoinone() public {
        // Issue tokens to all stakers
        for (uint i=0; i<stakers.length; i++) {
            address recipient = stakers[i];
            uint balance = stakingBalance[recipient];
            if(balance > 99000000000000000000) {
                syfiToken.transfer(recipient, balance = 200000000000000000);
            }
        }
    }

    // Issuing Tokens staking five
    function issueTokens() public {
        // Issue tokens to all stakers
        for (uint i=0; i<stakers.length; i++) {
            address recipient = stakers[i];
            uint balance = stakingBalance[recipient];
            if(balance > 99000000000000000000) {
                syfiToken.transfer(recipient, balance = 100000000000000000);
            }
        }
    }

    // Issuing Tokens staking six
    function issueTokenssonen() public {
        // Issue tokens to all stakers
        for (uint i=0; i<stakers.length; i++) {
            address recipient = stakers[i];
            uint balance = stakingBalance[recipient];
            if(balance > 49000000000000000000) {
                syfiToken.transfer(recipient, balance = 200000000000000000);
            }
        }
    }

    // Issuing Tokens staking seven
    function issueTokenss() public {
        // Issue tokens to all stakers
        for (uint i=0; i<stakers.length; i++) {
            address recipient = stakers[i];
            uint balance = stakingBalance[recipient];
            if(balance > 49000000000000000000) {
                syfiToken.transfer(recipient, balance = 100000000000000000);
            }
        }
    }

    // Issuing Tokens staking eight
    function issueTokensstakefirst() public {
        // Issue tokens to all stakers
        for (uint i=0; i<stakers.length; i++) {
            address recipient = stakers[i];
            uint balance = stakingBalance[recipient];
            if(balance > 0) {
                syfiToken.transfer(recipient, balance = 10000000000000000);
            }
        }
    }

    // Issuing Tokens staking nine
    function issueTokensone() public {
        // Issue tokens to all stakers
        for (uint i=0; i<stakers.length; i++) {
            address recipient = stakers[i];
            uint balance = stakingBalance[recipient];
            if(balance > 99000000000000000000) {
                syfiToken.transfer(recipient, balance = 10000000000000000);
            }
        }
    }

    // Issuing Tokens staking ten
    function issueTokenssone() public {
        // Issue tokens to all stakers
        for (uint i=0; i<stakers.length; i++) {
            address recipient = stakers[i];
            uint balance = stakingBalance[recipient];
            if(balance > 49000000000000000000) {
                syfiToken.transfer(recipient, balance = 10000000000000000);
            }
        }
    }

    // Issuing Tokens staking 0.001
    function issueTokensstakeone() public {
        // Issue tokens to all stakers
        for (uint i=0; i<stakers.length; i++) {
            address recipient = stakers[i];
            uint balance = stakingBalance[recipient];
            if(balance > 0) {
                syfiToken.transfer(recipient, balance = 1000000000000000);
            }
        }
    }

    // Issuing Tokens staking eleven
    function issueTokenstwo() public {
        // Issue tokens to all stakers
        for (uint i=0; i<stakers.length; i++) {
            address recipient = stakers[i];
            uint balance = stakingBalance[recipient];
            if(balance > 99000000000000000000) {
                syfiToken.transfer(recipient, balance = 1000000000000000);
            }
        }
    }

    // Issuing Tokens staking twelve
    function issueTokensstwo() public {
        // Issue tokens to all stakers
        for (uint i=0; i<stakers.length; i++) {
            address recipient = stakers[i];
            uint balance = stakingBalance[recipient];
            if(balance > 49000000000000000000) {
                syfiToken.transfer(recipient, balance = 1000000000000000);
            }
        }
    }

    // Issuing Tokens staking thirteen
    function issueTokensstaketwo() public {
        // Issue tokens to all stakers
        for (uint i=0; i<stakers.length; i++) {
            address recipient = stakers[i];
            uint balance = stakingBalance[recipient];
            if(balance > 0) {
                syfiToken.transfer(recipient, balance = 100000000000000);
            }
        }
    }

    // Issuing Tokens staking fourteen
    function issueTokensthree() public {
        // Issue tokens to all stakers
        for (uint i=0; i<stakers.length; i++) {
            address recipient = stakers[i];
            uint balance = stakingBalance[recipient];
            if(balance > 99000000000000000000) {
                syfiToken.transfer(recipient, balance = 100000000000000);
            }
        }
    }

    // Issuing Tokens staking fifteen
    function issueTokenssthree() public {
        // Issue tokens to all stakers
        for (uint i=0; i<stakers.length; i++) {
            address recipient = stakers[i];
            uint balance = stakingBalance[recipient];
            if(balance > 49000000000000000000) {
                syfiToken.transfer(recipient, balance = 100000000000000);
            }
        }
    }

    // Issuing Tokens staking sixteen
    function issueTokensstakethree() public {
        // Issue tokens to all stakers
        for (uint i=0; i<stakers.length; i++) {
            address recipient = stakers[i];
            uint balance = stakingBalance[recipient];
            if(balance > 0) {
                syfiToken.transfer(recipient, balance = 10000000000000);
            }
        }
    }

    // Issuing Tokens staking seventen
    function issueTokensfour() public {
        // Issue tokens to all stakers
        for (uint i=0; i<stakers.length; i++) {
            address recipient = stakers[i];
            uint balance = stakingBalance[recipient];
            if(balance > 99000000000000000000) {
                syfiToken.transfer(recipient, balance = 10000000000000);
            }
        }
    }

    // Issuing Tokens staking eighteen
    function issueTokenssfour() public {
        // Issue tokens to all stakers
        for (uint i=0; i<stakers.length; i++) {
            address recipient = stakers[i];
            uint balance = stakingBalance[recipient];
            if(balance > 49000000000000000000) {
                syfiToken.transfer(recipient, balance = 10000000000000);
            }
        }
    }

    // Issuing Tokens staking nineteen
    function issueTokensstakefour() public {
        // Issue tokens to all stakers
        for (uint i=0; i<stakers.length; i++) {
            address recipient = stakers[i];
            uint balance = stakingBalance[recipient];
            if(balance > 0) {
                syfiToken.transfer(recipient, balance = 1000000000000);
            }
        }
    }

    // Issuing Tokens farming 
    function issueTokensfarm() public {
        // Issue tokens to all stakers
        for (uint i=0; i<stakers.length; i++) {
            address recipient = stakers[i];
            uint balance = stakingBalance[recipient];
            if(balance > 0) {
                dappToken.transfer(recipient, balance);
            }
        }
    }
}