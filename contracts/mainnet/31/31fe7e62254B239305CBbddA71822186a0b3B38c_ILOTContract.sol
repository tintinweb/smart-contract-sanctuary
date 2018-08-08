pragma solidity ^0.4.19;

/******************************************************************************

ILOT - An Interest-paying ERC20 token and Ethereum lottery.

Visit us at https://ILOT.io/

ERC20 Compatible Token
Decimal places: 18
Symbol: ILOT

*******************************************************************************

Copyright (C) 2018 ILOT.io

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

-----

If you use this code on your own contracts, please credit the website https://ILOT.io/ - Thank you!

-----

////////////////
/B/S/B/J/M/A/F/
//////////////
////PEACE////
////////////

*/

interface tokenRecipient { function receiveApproval(address _from, uint _value, address _token, bytes _extraData) public; }

contract ILOTContract {

    string public name = "ILOT Interest-Paying Lottery Token";
    string public symbol = "ILOT";
    
    /*
        We&#39;ve hardcoded our official website into the blockchain!
        Please do not send ETH to scams/clones/copies. 
        The website indicated below is the only official ILOT website.
    */
    string public site_url = "https://ILOT.io/";

    bytes32 private current_jackpot_hash = "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF";
    uint8 public decimals = 18;
    uint public totalSupply = 0; // No pre-minted amount.
    uint public interestRate = 15; // 1.5% fixed monthly interest = 15 / 1000
    uint tokensPerEthereum = 147000; // 147k tokens per ETH
    uint public jackpotDifficulty = 6;
    address public owner;

    function ILOTContract() public {
        owner = msg.sender;
    }

    mapping (address => uint) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;
    mapping (address => uint) public depositTotal; // total ETH deposited per address
    mapping (address => uint) public lastBlockInterestPaid;

    /*
        Declare ILOT events.
    */
    event Transfer(address indexed from, address indexed to, uint bhtc_value);
    event Burn(address indexed from, uint bhtc_value);
    event GameResult(address player, uint zeroes);
    event BonusPaid(address to, uint bhtc_value);
    event InterestPaid(address to, uint bhtc_value);
    event Jackpot(address winner, uint eth_amount);

    uint maintenanceDebt;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    /*
        Return an addresse&#39;s current unpaid interest amount in ILOT.
    */
    function getInterest(address _to) public view returns (uint interest) {

        if (lastBlockInterestPaid[_to] > 0) {
            interest = ((block.number - lastBlockInterestPaid[_to]) * balanceOf[_to] * interestRate) / (86400000);
        } else {
            interest = 0;
        }

        return interest;
    }

    /*
        Allows users to check their current deposit bonus amount.
        Formula: 1% bonus over lifetime ETH deposit history
        depositTotal is denominated in ETH
    */
    function getBonus(address _to) public view returns (uint interest) {
        return ((depositTotal[_to] * tokensPerEthereum) / 100);
    }

    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        /*
            Owed interest is paid before transfers/withdrawals.
            Users may be able to withdraw/transfer more than they publicly see.
            Use getInterest(ETHEREUM_ADDRESS) to check how much interests
            will be paid before transfers or future deposits.
        */
        payInterest(_from);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint _value) public {
        _transfer(msg.sender, _to, _value);
    }

    function setUrl(string u) public onlyOwner {
        site_url = u;
    }

    function getUrl() public view returns (string) {
        return site_url;
    }

    /*
        Difficulty adjustment.
    */
    function setDifficulty(uint z) public onlyOwner {
        jackpotDifficulty = z;
    }

    /*
        Get current difficulty.
        Returns number of zeroes currently required.
    */
    function getDifficulty() public view returns (uint) {
        return jackpotDifficulty;
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint _value) public
    returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    function approveAndCall(address _spender, uint _value, bytes _extraData)
    public
    returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    function chown(address to) public onlyOwner { owner = to; }

    function burn(uint _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender&#39;s allowance
        totalSupply -= _value;                              // Update totalSupply
        Burn(_from, _value);
        return true;
    }

    /*
        Pays interest on available funds.
    */
    function payInterest(address _to) private {

        uint interest = getInterest(_to);

        if (interest > 0) {
            require( (balanceOf[_to] + interest) > balanceOf[_to]);
            // pay interest
            balanceOf[msg.sender] += interest;
            totalSupply += interest;
            Transfer(this, msg.sender, interest);
            InterestPaid(_to, interest);
        }

        lastBlockInterestPaid[_to] = block.number;

    }

    /*
        Pays a 1% bonus over lifetime deposits made to this address.
        Does not carry over if you change Ethereum addresses.
    */
    function payBonus(address _to) private {
        if (depositTotal[_to] > 0) {
            uint bonus = getBonus(_to);
            if (bonus > 0) {
                require( (balanceOf[_to] + bonus) > balanceOf[_to]);
                balanceOf[_to] +=  bonus;
                totalSupply += bonus;
                Transfer(this, _to, bonus);
                BonusPaid(_to, bonus);
            }
        }
    }

    function hashDifficulty(bytes32 hash) public pure returns(uint) {
        uint diff = 0;

        for (uint i=0;i<32;i++) {
            if (hash[i] == 0) {
                diff++;
            } else {
                return diff;
            }
        }

        return diff;
    }

    /*
        Credit to user @eth from StackExchange at:
        https://ethereum.stackexchange.com/questions/8346/convert-address-to-string
        License for addressToString(): CC BY-SA 3.0
    */
    function addressToString(address x) private pure returns (string) {
        bytes memory b = new bytes(20);
        for (uint i = 0; i < 20; i++)
            b[i] = byte(uint8(uint(x) / (2**(8*(19 - i)))));
        return string(b);
    }

    /*
        Performs token exchange and runs the lottery routine.

    */
    function () public payable {

        /*
            Owner cannot play lottery.
        */
        if (msg.sender == owner) {
            return;
        }

        if (msg.value > 0) {

            /*
                Maintenance fee 2%
            */
            uint mfee = (2 * msg.value) / 100;

            /*
                If the contract does not have sufficient balance to pay mfee,
                it will add mfee to maintenanceDebt and will not transfer it
                at this time. During a later transaction, if the fee is enough,
                the previous debt is transferred and zeroed out.
            */
            if (address(this).balance >= mfee) {
                if (address(this).balance >= (mfee + maintenanceDebt) ) {
                    // there&#39;s enough to cover previous debt
                    owner.transfer(mfee + maintenanceDebt);
                    maintenanceDebt = 0;
                } else {
                    // enough to pay fee but not previous debts
                    owner.transfer(mfee);
                }

            } else {
                maintenanceDebt += mfee;
            }

            /*
                Convert ETH to ILOT at tokensPerEthereum rate.
            */
            uint tokenAmount = tokensPerEthereum * msg.value;
            if (tokenAmount > 0) {
                require( (balanceOf[msg.sender] + tokenAmount) > balanceOf[msg.sender]);

                /*
                    Pay fidelity bonus.
                */
                payBonus(msg.sender);

                /*
                    Pay interests on previous balance.
                */
                payInterest(msg.sender);

                /*
                    Update balance.
                */
                balanceOf[msg.sender] += tokenAmount;
                totalSupply += tokenAmount;
                Transfer(this, msg.sender, tokenAmount);

                /*
                    Add total after paying bonus.
                    This deposit will count towards the next deposit bonus.
                */
                depositTotal[msg.sender] += msg.value;

                string memory ats = addressToString(msg.sender);

                /*
                    Perform lottery routine.
                */
                current_jackpot_hash = keccak256(current_jackpot_hash, ats, block.coinbase, block.number, block.timestamp);
                uint diffx = hashDifficulty(current_jackpot_hash);

                if (diffx >= jackpotDifficulty) {
                    /*

                        ********************
                        ****  JACKPOT!  ****
                        ********************

                        Winner receives the entire contract balance.
                        Jackpot event makes the result public.

                    */
                    Jackpot(msg.sender, address(this).balance);
                    msg.sender.transfer(address(this).balance);
                }

                /*
                    Make the game result public for transparency.
                */
                GameResult(msg.sender, diffx);

            }
        }
    }

}