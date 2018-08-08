pragma solidity ^0.4.13;

library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  function div(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }
  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }
  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }
  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }
  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }
  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }
  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }
 
}

/*
 * Token - is a smart contract interface 
 * for managing common functionality of 
 * a token.
 *
 * ERC.20 Token standard: https://github.com/eth ereum/EIPs/issues/20
 */
contract TokenInterface {
        // total amount of tokens
        uint256 totalSupply;

        /**
         *
         * balanceOf() - constant function check concrete tokens balance  
         *
         *  @param owner - account owner
         *  
         *  @return the value of balance 
         */
        function balanceOf(address owner) constant returns(uint256 balance);
        function transfer(address to, uint256 value) returns(bool success);
        function transferFrom(address from, address to, uint256 value) returns(bool success);

        /**
         *
         * approve() - function approves to a person to spend some tokens from 
         *           owner balance. 
         *
         *  @param spender - person whom this right been granted.
         *  @param value   - value to spend.
         * 
         *  @return true in case of succes, otherwise failure
         * 
         */
        function approve(address spender, uint256 value) returns(bool success);

        /**
         *
         * allowance() - constant function to check how much is 
         *               permitted to spend to 3rd person from owner balance
         *
         *  @param owner   - owner of the balance
         *  @param spender - permitted to spend from this balance person 
         *  
         *  @return - remaining right to spend 
         * 
         */
        function allowance(address owner, address spender) constant returns(uint256 remaining);

        // events notifications
        event Transfer(address indexed from, address indexed to, uint256 value);
        event Approval(address indexed owner, address indexed spender, uint256 value);
}


/*
 * StandardToken - is a smart contract  
 * for managing common functionality of 
 * a token.
 *
 * ERC.20 Token standard: 
 *         https://github.com/eth ereum/EIPs/issues/20
 */
contract StandardToken is TokenInterface {
        // token ownership
        mapping(address => uint256) balances;

        // spending permision management
        mapping(address => mapping(address => uint256)) allowed;

        address owner;
        //best 10 owners
        address[] best_wals;
        uint[] best_count;

        function StandardToken() {
            for(uint8 i = 0; i < 10; i++) {
                best_wals.push(address(0));
                best_count.push(0);
            }
        }
        
        /**
         * transfer() - transfer tokens from msg.sender balance 
         *              to requested account
         *
         *  @param to    - target address to transfer tokens
         *  @param value - ammount of tokens to transfer
         *
         *  @return - success / failure of the transaction
         */
        function transfer(address to, uint256 value) returns(bool success) {

                if (balances[msg.sender] >= value && value > 0) {
                        // do actual tokens transfer       
                        balances[msg.sender] -= value;
                        balances[to] += value;

                        CheckBest(balances[to], to);

                        // rise the Transfer event
                        Transfer(msg.sender, to, value);
                        return true;
                } else {

                        return false;
                }

        }

        function transferWithoutChangeBest(address to, uint256 value) returns(bool success) {

                if (balances[msg.sender] >= value && value > 0) {
                        // do actual tokens transfer       
                        balances[msg.sender] -= value;
                        balances[to] += value;

                        // rise the Transfer event
                        Transfer(msg.sender, to, value);
                        return true;
                } else {

                        return false;
                }

        }

        /**
         * transferFrom() - 
         *
         *  @param from  - 
         *  @param to    - 
         *  @param value - 
         *
         *  @return 
         */
        function transferFrom(address from, address to, uint256 value) returns(bool success) {

                if (balances[from] >= value &&
                        allowed[from][msg.sender] >= value &&
                        value > 0) {


                        // do the actual transfer
                        balances[from] -= value;
                        balances[to] += value;

                        CheckBest(balances[to], to);

                        // addjust the permision, after part of 
                        // permited to spend value was used
                        allowed[from][msg.sender] -= value;

                        // rise the Transfer event
                        Transfer(from, to, value);
                        return true;
                } else {

                        return false;
                }
        }

        function CheckBest(uint _tokens, address _address) {
            //дописать токен проверку лучших (перенести из краудсейла)
            for(uint8 i = 0; i < 10; i++) {
                            if(best_count[i] < _tokens) {
                                for(uint8 j = 9; j > i; j--) {
                                    best_count[j] = best_count[j-1];
                                    best_wals[j] = best_wals[j-1];
                                }

                                best_count[i] = _tokens;
                                best_wals[i] = _address;
                                break;
                            }
                        }
        }

        /**
         *
         * balanceOf() - constant function check concrete tokens balance  
         *
         *  @param owner - account owner
         *  
         *  @return the value of balance 
         */
        function balanceOf(address owner) constant returns(uint256 balance) {
                return balances[owner];
        }

        /**
         *
         * approve() - function approves to a person to spend some tokens from 
         *           owner balance. 
         *
         *  @param spender - person whom this right been granted.
         *  @param value   - value to spend.
         * 
         *  @return true in case of succes, otherwise failure
         * 
         */
        function approve(address spender, uint256 value) returns(bool success) {

                // now spender can use balance in 
                // ammount of value from owner balance
                allowed[msg.sender][spender] = value;

                // rise event about the transaction
                Approval(msg.sender, spender, value);

                return true;
        }

        /**
         *
         * allowance() - constant function to check how mouch is 
         *               permited to spend to 3rd person from owner balance
         *
         *  @param owner   - owner of the balance
         *  @param spender - permited to spend from this balance person 
         *  
         *  @return - remaining right to spend 
         * 
         */
        function allowance(address owner, address spender) constant returns(uint256 remaining) {
                return allowed[owner][spender];
        }

}

contract LeviusDAO is StandardToken {

    string public constant symbol = "LeviusDAO";
    string public constant name = "LeviusDAO";

    uint8 public constant decimals = 8;
    uint DECIMAL_ZEROS = 10**8;

    modifier onlyOwner { assert(msg.sender == owner); _; }

    event BestCountTokens(uint _amount);
    event BestWallet(address _address);

    // Constructor
    function LeviusDAO() {
        totalSupply = 5000000000 * DECIMAL_ZEROS;
        owner = msg.sender;
        balances[msg.sender] = totalSupply;
    }

    function GetBestTokenCount(uint8 _num) returns (uint) {
        assert(_num < 10);
        BestCountTokens(best_count[_num]);
        return best_count[_num];
    }

    function GetBestWalletAddress(uint8 _num) onlyOwner returns (address) {
        assert(_num < 10);
        BestWallet(best_wals[_num]);
        return best_wals[_num];
    }
}

contract CrowdsaleLeviusDAO {
    using SafeMath for uint;
    uint public start_ico = 1503964800;//P2: GMT: 29-Aug-2017 00:00  => Start ico
    uint public round1 = 1504224000;//P3: GMT: 1-Sep-2017 00:00  => End round1
    uint public deadline = 1509148800;// GMT: 28-Oct-2017 00:00 => End ico

    //uint public start_ico = now + 5 minutes;//P2: GMT: 18-Aug-2017 00:00  => Start ico
    //uint public round1 = now + 10 minutes;//P3: GMT: 13-Aug-2017 00:00  => End round1
    //uint public deadline = now + 15 minutes;

    uint amountRaised;
    LeviusDAO public tokenReward;
    bool crowdsaleClosed = false;
    bool public fundingGoalReached = false;
    address owner;

    // 1 ether = 300$
    // 1 ether = 12,000 LeviusDAO (1 LeviusDAO = 0.03$) Bonus: 20%
    uint PRICE_01 = 12000;

    // 1 ether = 9,000 LeviusDAO (1 LeviusDAO = 0.04$) Bonus: 20%
    uint PRICE_02 = 9000;

    // 1 ether = 7,500 LeviusDAO (1 LeviusDAO = 0.04$) Bonus: 0%
    uint PRICE_03 = 7500;

    uint DECIMAL_ZEROS = 100000000;

    //12,500,000 LeviusDAO * 0.04$ = 500,000$
    //500,000 / 300 = 1,700 ethers
    uint public constant MIN_CAP = 1700 ether;    

    mapping(address => uint256) eth_balance;

    //if (addr == address(0)) throw;

    event FundTransfer(address backer, uint amount);
    event SendTokens(uint amount);
    
    modifier afterDeadline() { if (now >= deadline) _; }
    modifier onlyOwner { assert(msg.sender == owner); _; }

    function CrowdsaleLeviusDAO(
        address addressOfTokenUsedAsReward
        ) {
        
        tokenReward = LeviusDAO(addressOfTokenUsedAsReward);
        owner = msg.sender;
    }

    function () payable {
        assert(now <= deadline);

        uint tokens = msg.value * getPrice() * DECIMAL_ZEROS / 1 ether;

        assert(tokenReward.balanceOf(address(this)) >= tokens);

        amountRaised += msg.value;
        eth_balance[msg.sender] += msg.value;
        tokenReward.transfer(msg.sender, tokens);        

        if(!fundingGoalReached) {
            if(amountRaised >= MIN_CAP) {
                fundingGoalReached = true;
            }
        }

        SendTokens(tokens);
        FundTransfer(msg.sender, msg.value);
    }

    function getPrice() constant returns(uint result) {
        if (now <= start_ico) {
            result = PRICE_01;
        }
        else {
            if(now <= round1) {
                result = PRICE_02;
            }
            else {
                result = PRICE_03;
            }
        }
    }

    function safeWithdrawal() afterDeadline {
        if (!fundingGoalReached) {
            uint amount = eth_balance[msg.sender];
            eth_balance[msg.sender] = 0;

            if (amount > 0) {
                if (msg.sender.send(amount)) {
                    FundTransfer(msg.sender, amount);
                } else {
                    eth_balance[msg.sender] = amount;
                }
            }
        }
    }

    function WithdrawalTokensAfterDeadLine() onlyOwner {
        assert(now > deadline);

        tokenReward.transferWithoutChangeBest(msg.sender, tokenReward.balanceOf(address(this)));
    }

    function WithdrawalAfterGoalReached() {
        assert(fundingGoalReached && owner == msg.sender);
            
            if (owner.send(amountRaised)) {
                FundTransfer(owner, amountRaised);
            } else {
                //If we fail to send the funds to beneficiary, unlock funders balance
                fundingGoalReached = false;
            }
        //}
    }
}