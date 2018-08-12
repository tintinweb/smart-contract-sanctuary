pragma solidity ^0.4.16;

/**

 * Math operations with safety checks

 */

contract BaseSafeMath {


    /*

    standard uint256 functions

     */



    function add(uint256 a, uint256 b) internal pure

    returns (uint256) {

        uint256 c = a + b;

        assert(c >= a);

        return c;

    }


    function sub(uint256 a, uint256 b) internal pure

    returns (uint256) {

        assert(b <= a);

        return a - b;

    }


    function mul(uint256 a, uint256 b) internal pure

    returns (uint256) {

        uint256 c = a * b;

        assert(a == 0 || c / a == b);

        return c;

    }


    function div(uint256 a, uint256 b) internal pure

    returns (uint256) {

        uint256 c = a / b;

        return c;

    }


    function min(uint256 x, uint256 y) internal pure

    returns (uint256 z) {

        return x <= y ? x : y;

    }


    function max(uint256 x, uint256 y) internal pure

    returns (uint256 z) {

        return x >= y ? x : y;

    }



    /*

    uint128 functions

     */



    function madd(uint128 a, uint128 b) internal pure

    returns (uint128) {

        uint128 c = a + b;

        assert(c >= a);

        return c;

    }


    function msub(uint128 a, uint128 b) internal pure

    returns (uint128) {

        assert(b <= a);

        return a - b;

    }


    function mmul(uint128 a, uint128 b) internal pure

    returns (uint128) {

        uint128 c = a * b;

        assert(a == 0 || c / a == b);

        return c;

    }


    function mdiv(uint128 a, uint128 b) internal pure

    returns (uint128) {

        uint128 c = a / b;

        return c;

    }


    function mmin(uint128 x, uint128 y) internal pure

    returns (uint128 z) {

        return x <= y ? x : y;

    }


    function mmax(uint128 x, uint128 y) internal pure

    returns (uint128 z) {

        return x >= y ? x : y;

    }



    /*

    uint64 functions

     */



    function miadd(uint64 a, uint64 b) internal pure

    returns (uint64) {

        uint64 c = a + b;

        assert(c >= a);

        return c;

    }


    function misub(uint64 a, uint64 b) internal pure

    returns (uint64) {

        assert(b <= a);

        return a - b;

    }


    function mimul(uint64 a, uint64 b) internal pure

    returns (uint64) {

        uint64 c = a * b;

        assert(a == 0 || c / a == b);

        return c;

    }


    function midiv(uint64 a, uint64 b) internal pure

    returns (uint64) {

        uint64 c = a / b;

        return c;

    }


    function mimin(uint64 x, uint64 y) internal pure

    returns (uint64 z) {

        return x <= y ? x : y;

    }


    function mimax(uint64 x, uint64 y) internal pure

    returns (uint64 z) {

        return x >= y ? x : y;

    }


}


// Abstract contract for the full ERC 20 Token standard

// https://github.com/ethereum/EIPs/issues/20

contract BaseERC20 {

    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;

    // This creates an array with all balances
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal;

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public;

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` on behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public returns (bool success);

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success);

}


/**

 * @title Standard ERC20 token

 *

 * @dev Implementation of the basic standard token.

 * @dev https://github.com/ethereum/EIPs/issues/20

 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol

 */

interface tokenRecipient {function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public;}


contract LockUtils {
    // Advance mining
    address advance_mining = 0x5EDBe36c4c4a816f150959B445d5Ae1F33054a82;
    // community
    address community = 0xacF2e917E296547C0C476fDACf957111ca0307ce;
    // foundation_investment
    address foundation_investment = 0x9746079BEbcFfFf177818e23AedeC834ad0fb5f9;
    // mining
    address mining = 0xBB7d6f428E77f98069AE1E01964A9Ed6db3c5Fe5;
    // adviser
    address adviser = 0x0aE269Ae5F511786Fce5938c141DbF42e8A71E12;
    // unlock start time 2018-09-10
    uint256 unlock_time_0910 = 1536508800;
    // unlock start time 2018-10-10
    uint256 unlock_time_1010 = 1539100800;
    // unlock start time 2018-11-10
    uint256 unlock_time_1110 = 1541779200;
    // unlock start time 2018-12-10
    uint256 unlock_time_1210 = 1544371200;
    // unlock start time 2019-01-10
    uint256 unlock_time_0110 = 1547049600;
    // unlock start time 2019-02-10
    uint256 unlock_time_0210 = 1549728000;
    // unlock start time 2019-03-10
    uint256 unlock_time_0310 = 1552147200;
    // unlock start time 2019-04-10
    uint256 unlock_time_0410 = 1554825600;
    // unlock start time 2019-05-10
    uint256 unlock_time_0510 = 1557417600;
    // unlock start time 2019-06-10
    uint256 unlock_time_0610 = 1560096000;
    // unlock start time 2019-07-10
    uint256 unlock_time_0710 = 1562688000;
    // unlock start time 2019-08-10
    uint256 unlock_time_0810 = 1565366400;
    // unlock start time 2019-09-10
    uint256 unlock_time_end  = 1568044800;
    // 1 monthss
    uint256 time_months = 2678400;
    // xxx
    function getLockBalance(address account, uint8 decimals) internal view returns (uint256) {
        uint256 tempLock = 0;
        if (account == advance_mining) {
            if (now < unlock_time_0910) {
                tempLock = 735000000 * 10 ** uint256(decimals);
            } else if (now >= unlock_time_0910 && now < unlock_time_1210) {
                tempLock = 367500000 * 10 ** uint256(decimals);
            } else if (now >= unlock_time_1210 && now < unlock_time_0310) {
                tempLock = 183750000 * 10 ** uint256(decimals);
            }
        } else if (account == community) {
            if (now < unlock_time_0910) {
                tempLock = 18375000 * 6 * 10 ** uint256(decimals);
            } else if (now >= unlock_time_0910 && now < unlock_time_1010) {
                tempLock = 18375000 * 5 * 10 ** uint256(decimals);
            } else if (now >= unlock_time_1010 && now < unlock_time_1110) {
                tempLock = 18375000 * 4 * 10 ** uint256(decimals);
            } else if (now >= unlock_time_1110 && now < unlock_time_1210) {
                tempLock = 18375000 * 3 * 10 ** uint256(decimals);
            } else if (now >= unlock_time_1210 && now < unlock_time_0110) {
                tempLock = 18375000 * 2 * 10 ** uint256(decimals);
            } else if (now >= unlock_time_0110 && now < unlock_time_0210) {
                tempLock = 18375000 * 1 * 10 ** uint256(decimals);
            }
        } else if (account == foundation_investment) {
            if (now < unlock_time_0910) {
                tempLock = 18812500 * 12 * 10 ** uint256(decimals);
            } else if (now >= unlock_time_0910 && now < unlock_time_1010) {
                tempLock = 18812500 * 11 * 10 ** uint256(decimals);
            } else if (now >= unlock_time_1010 && now < unlock_time_1110) {
                tempLock = 18812500 * 10 * 10 ** uint256(decimals);
            } else if (now >= unlock_time_1110 && now < unlock_time_1210) {
                tempLock = 18812500 * 9 * 10 ** uint256(decimals);
            } else if (now >= unlock_time_1210 && now < unlock_time_0110) {
                tempLock = 18812500 * 8 * 10 ** uint256(decimals);
            } else if (now >= unlock_time_0110 && now < unlock_time_0210) {
                tempLock = 18812500 * 7 * 10 ** uint256(decimals);
            } else if (now >= unlock_time_0210 && now < unlock_time_0310) {
                tempLock = 18812500 * 6 * 10 ** uint256(decimals);
            } else if (now >= unlock_time_0310 && now < unlock_time_0410) {
                tempLock = 18812500 * 5 * 10 ** uint256(decimals);
            } else if (now >= unlock_time_0410 && now < unlock_time_0510) {
                tempLock = 18812500 * 4 * 10 ** uint256(decimals);
            } else if (now >= unlock_time_0510 && now < unlock_time_0610) {
                tempLock = 18812500 * 3 * 10 ** uint256(decimals);
            } else if (now >= unlock_time_0610 && now < unlock_time_0710) {
                tempLock = 18812500 * 2 * 10 ** uint256(decimals);
            } else if (now >= unlock_time_0710 && now < unlock_time_0810) {
                tempLock = 18812500 * 1 * 10 ** uint256(decimals);
            }
        } else if (account == mining) {
            if (now < unlock_time_0910) {
                tempLock = 840000000 * 10 ** uint256(decimals);
            }
        } else if (account == adviser) {
            if (now < unlock_time_0910) {
                tempLock = 15750000 * 12 * 10 ** uint256(decimals);
            } else if (now >= unlock_time_0910 && now < unlock_time_1010) {
                tempLock = 15750000 * 11 * 10 ** uint256(decimals);
            } else if (now >= unlock_time_1010 && now < unlock_time_1110) {
                tempLock = 15750000 * 10 * 10 ** uint256(decimals);
            } else if (now >= unlock_time_1110 && now < unlock_time_1210) {
                tempLock = 15750000 * 9 * 10 ** uint256(decimals);
            } else if (now >= unlock_time_1210 && now < unlock_time_0110) {
                tempLock = 15750000 * 8 * 10 ** uint256(decimals);
            } else if (now >= unlock_time_0110 && now < unlock_time_0210) {
                tempLock = 15750000 * 7 * 10 ** uint256(decimals);
            } else if (now >= unlock_time_0210 && now < unlock_time_0310) {
                tempLock = 15750000 * 6 * 10 ** uint256(decimals);
            } else if (now >= unlock_time_0310 && now < unlock_time_0410) {
                tempLock = 15750000 * 5 * 10 ** uint256(decimals);
            } else if (now >= unlock_time_0410 && now < unlock_time_0510) {
                tempLock = 15750000 * 4 * 10 ** uint256(decimals);
            } else if (now >= unlock_time_0510 && now < unlock_time_0610) {
                tempLock = 15750000 * 3 * 10 ** uint256(decimals);
            } else if (now >= unlock_time_0610 && now < unlock_time_0710) {
                tempLock = 15750000 * 2 * 10 ** uint256(decimals);
            } else if (now >= unlock_time_0710 && now < unlock_time_0810) {
                tempLock = 15750000 * 1 * 10 ** uint256(decimals);
            }
        }
        return tempLock;
    }
}

contract PDTToken is BaseERC20, BaseSafeMath, LockUtils {

    //The solidity created time
    

    function PDTToken() public {
        name = "Matrix World";
        symbol = "PDT";
        decimals = 18;
        totalSupply = 2100000000 * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        // balanceOf[0x5EDBe36c4c4a816f150959B445d5Ae1F33054a82] = 735000000 * 10 ** uint256(decimals);
        // balanceOf[0xacF2e917E296547C0C476fDACf957111ca0307ce] = 110250000 * 10 ** uint256(decimals);
        // balanceOf[0x9746079BEbcFfFf177818e23AedeC834ad0fb5f9] = 225750000 * 10 ** uint256(decimals);
        // balanceOf[0xBB7d6f428E77f98069AE1E01964A9Ed6db3c5Fe5] = 840000000 * 10 ** uint256(decimals);
        // balanceOf[0x0aE269Ae5F511786Fce5938c141DbF42e8A71E12] = 189000000 * 10 ** uint256(decimals);
    }

    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        // All transfer will check the available unlocked balance
        require((balanceOf[_from] - getLockBalance(_from, decimals)) >= _value);
        // Check balance
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require((balanceOf[_to] + _value) > balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }
    
    function lockBalanceOf(address _owner) public returns (uint256) {
        return getLockBalance(_owner, decimals);
    }

    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public
    returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
    public
    returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
}