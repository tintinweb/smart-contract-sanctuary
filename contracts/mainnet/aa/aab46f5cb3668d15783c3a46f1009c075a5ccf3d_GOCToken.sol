pragma solidity ^0.4.21;

/**
 * Math operations with safety checks
 */
library SafeMath {
    function mul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20Basic {
    uint public totalSupply;
    function balanceOf(address who) public view returns (uint);
    function transfer(address to, uint value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
}




/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances. 
 */
contract BasicToken is ERC20Basic {
    using SafeMath for uint;

    mapping(address => uint) balances;

    /**
     * @dev Fix for the ERC20 short address attack.
     */
    modifier onlyPayloadSize(uint size) {
        if(msg.data.length < size + 4) {
            revert();
        }
        _;
    }

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint _value) public onlyPayloadSize(2 * 32) returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of. 
    * @return An uint representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }

}




/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint);
    function transferFrom(address from, address to, uint value) public returns (bool);
    function approve(address spender, uint value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint value);
}




/**
 * @title Standard ERC20 token
 *
 * @dev Implemantation of the basic standart token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is BasicToken, ERC20 {

    mapping (address => mapping (address => uint)) allowed;


    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint the amout of tokens to be transfered
     */
    function transferFrom(address _from, address _to, uint _value) public onlyPayloadSize(3 * 32) returns (bool) {
        uint _allowance = allowed[_from][msg.sender];

        // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
        // if (_value > _allowance) revert();

        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Aprove the passed address to spend the specified amount of tokens on beahlf of msg.sender.
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint _value) public returns (bool) {

        // To change the approve amount you first have to reduce the addresses`
        //    allowance to zero by calling `approve(_spender, 0)` if it is not
        //    already 0 to mitigate the race condition described here:
        //    https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) revert();

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens than an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint specifing the amount of tokens still avaible for the spender.
     */
    function allowance(address _owner, address _spender) public view returns (uint remaining) {
        return allowed[_owner][_spender];
    }

}


/**
 * @title LimitedTransferToken
 * @dev LimitedTransferToken defines the generic interface and the implementation to limit token 
 * transferability for different events. It is intended to be used as a base class for other token 
 * contracts. 
 * LimitedTransferToken has been designed to allow for different limiting factors,
 * this can be achieved by recursively calling super.transferableTokens() until the base class is 
 * hit. For example:
 *         function transferableTokens(address holder, uint time, uint number) constant public returns (uint256) {
 *             return min256(unlockedTokens, super.transferableTokens(holder, time, number));
 *         }
 * A working example is VestedToken.sol:
 * https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/token/VestedToken.sol
 */

contract LimitedTransferToken is ERC20 {

    /**
     * @dev Checks whether it can transfer or otherwise throws.
     */
    modifier canTransfer(address _sender, uint _value) {
        if (_value > transferableTokens(_sender, now, block.number)) revert();
        _;
    }

    /**
     * @dev Checks modifier and allows transfer if tokens are not locked.
     * @param _to The address that will recieve the tokens.
     * @param _value The amount of tokens to be transferred.
     */
    function transfer(address _to, uint _value) public canTransfer(msg.sender, _value) returns (bool) {
        return super.transfer(_to, _value);
    }

    /**
    * @dev Checks modifier and allows transfer if tokens are not locked.
    * @param _from The address that will send the tokens.
    * @param _to The address that will recieve the tokens.
    * @param _value The amount of tokens to be transferred.
    */
    function transferFrom(address _from, address _to, uint _value) public canTransfer(_from, _value) returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    /**
     * @dev Default transferable tokens function returns all tokens for a holder (no limit).
     * @dev Overwriting transferableTokens(address holder, uint time, uint number) is the way to provide the 
     * specific logic for limiting token transferability for a holder over time or number.
     */
    function transferableTokens(address holder, uint /* time */, uint /* number */) view public returns (uint256) {
        return balanceOf(holder);
    }
}


/**
 * @title Vested token
 * @dev Tokens that can be vested for a group of addresses.
 */
contract VestedToken is StandardToken, LimitedTransferToken {

    uint256 MAX_GRANTS_PER_ADDRESS = 20;

    struct TokenGrant {
        address granter;         // 20 bytes
        uint256 value;             // 32 bytes
        uint start;
        uint cliff;
        uint vesting;                // 3 * 8 = 24 bytes
        bool revokable;
        bool burnsOnRevoke;    // 2 * 1 = 2 bits? or 2 bytes?
        bool timeOrNumber;
    } // total 78 bytes = 3 sstore per operation (32 per sstore)

    mapping (address => TokenGrant[]) public grants;

    event NewTokenGrant(address indexed from, address indexed to, uint256 value, uint256 grantId);

    /**
     * @dev Grant tokens to a specified address
     * @param _to address The address which the tokens will be granted to.
     * @param _value uint256 The amount of tokens to be granted.
     * @param _start uint64 Time of the beginning of the grant.
     * @param _cliff uint64 Time of the cliff period.
     * @param _vesting uint64 The vesting period.
     */
    function grantVestedTokens(
        address _to,
        uint256 _value,
        uint _start,
        uint _cliff,
        uint _vesting,
        bool _revokable,
        bool _burnsOnRevoke,
        bool _timeOrNumber
    ) public returns (bool) {

        // Check for date inconsistencies that may cause unexpected behavior
        if (_cliff < _start || _vesting < _cliff) {
            revert();
        }

        // To prevent a user being spammed and have his balance locked (out of gas attack when calculating vesting).
        if (tokenGrantsCount(_to) > MAX_GRANTS_PER_ADDRESS) revert();

        uint count = grants[_to].push(
            TokenGrant(
                _revokable ? msg.sender : 0, // avoid storing an extra 20 bytes when it is non-revokable
                _value,
                _start,
                _cliff,
                _vesting,
                _revokable,
                _burnsOnRevoke,
                _timeOrNumber
            )
        );

        transfer(_to, _value);

        emit NewTokenGrant(msg.sender, _to, _value, count - 1);
        return true;
    }

    /**
     * @dev Revoke the grant of tokens of a specifed address.
     * @param _holder The address which will have its tokens revoked.
     * @param _grantId The id of the token grant.
     */
    function revokeTokenGrant(address _holder, uint _grantId) public returns (bool) {
        TokenGrant storage grant = grants[_holder][_grantId];

        if (!grant.revokable) { // Check if grant was revokable
            revert();
        }

        if (grant.granter != msg.sender) { // Only granter can revoke it
            revert();
        }

        address receiver = grant.burnsOnRevoke ? 0xdead : msg.sender;

        uint256 nonVested = nonVestedTokens(grant, now, block.number);

        // remove grant from array
        delete grants[_holder][_grantId];
        grants[_holder][_grantId] = grants[_holder][grants[_holder].length.sub(1)];
        grants[_holder].length -= 1;

        balances[receiver] = balances[receiver].add(nonVested);
        balances[_holder] = balances[_holder].sub(nonVested);

        emit Transfer(_holder, receiver, nonVested);
        return true;
    }


    /**
     * @dev Calculate the total amount of transferable tokens of a holder at a given time
     * @param holder address The address of the holder
     * @param time uint The specific time.
     * @return An uint representing a holder&#39;s total amount of transferable tokens.
     */
    function transferableTokens(address holder, uint time, uint number) view public returns (uint256) {
        uint256 grantIndex = tokenGrantsCount(holder);

        if (grantIndex == 0) return balanceOf(holder); // shortcut for holder without grants

        // Iterate through all the grants the holder has, and add all non-vested tokens
        uint256 nonVested = 0;
        for (uint256 i = 0; i < grantIndex; i++) {
            nonVested = SafeMath.add(nonVested, nonVestedTokens(grants[holder][i], time, number));
        }

        // Balance - totalNonVested is the amount of tokens a holder can transfer at any given time
        uint256 vestedTransferable = SafeMath.sub(balanceOf(holder), nonVested);

        // Return the minimum of how many vested can transfer and other value
        // in case there are other limiting transferability factors (default is balanceOf)
        return SafeMath.min256(vestedTransferable, super.transferableTokens(holder, time, number));
    }

    /**
     * @dev Check the amount of grants that an address has.
     * @param _holder The holder of the grants.
     * @return A uint representing the total amount of grants.
     */
    function tokenGrantsCount(address _holder) public view returns (uint index) {
        return grants[_holder].length;
    }

    /**
     * @dev Calculate amount of vested tokens at a specifc time.
     * @param tokens uint256 The amount of tokens grantted.
     * @param time uint64 The time to be checked
     * @param start uint64 A time representing the begining of the grant
     * @param cliff uint64 The cliff period.
     * @param vesting uint64 The vesting period.
     * @return An uint representing the amount of vested tokensof a specif grant.
    *  transferableTokens
    *   |                         _/--------   vestedTokens rect
    *   |                       _/
    *   |                     _/
    *   |                   _/
    *   |                 _/
    *   |                /
    *   |              .|
    *   |            .  |
    *   |          .    |
    *   |        .      |
    *   |      .        |
    *   |    .          |
    *   +===+===========+---------+----------> time
    *      Start       Clift    Vesting
    */
    function calculateVestedTokensTime(
        uint256 tokens,
        uint256 time,
        uint256 start,
        uint256 cliff,
        uint256 vesting) public pure returns (uint256) {
        // Shortcuts for before cliff and after vesting cases.
        if (time < cliff) return 0;
        if (time >= vesting) return tokens;

        // Interpolate all vested tokens.
        // As before cliff the shortcut returns 0, we can use just calculate a value
        // in the vesting rect (as shown in above&#39;s figure)

        // vestedTokens = tokens * (time - start) / (vesting - start)
        uint256 vestedTokens = SafeMath.div(SafeMath.mul(tokens, SafeMath.sub(time, start)), SafeMath.sub(vesting, start));

        return vestedTokens;
    }

    function calculateVestedTokensNumber(
        uint256 tokens,
        uint256 number,
        uint256 start,
        uint256 cliff,
        uint256 vesting) public pure returns (uint256) {
        // Shortcuts for before cliff and after vesting cases.
        if (number < cliff) return 0;
        if (number >= vesting) return tokens;

        // Interpolate all vested tokens.
        // As before cliff the shortcut returns 0, we can use just calculate a value
        // in the vesting rect (as shown in above&#39;s figure)

        // vestedTokens = tokens * (number - start) / (vesting - start)
        uint256 vestedTokens = SafeMath.div(SafeMath.mul(tokens, SafeMath.sub(number, start)), SafeMath.sub(vesting, start));

        return vestedTokens;
    }

    function calculateVestedTokens(
        bool timeOrNumber,
        uint256 tokens,
        uint256 time,
        uint256 number,
        uint256 start,
        uint256 cliff,
        uint256 vesting) public pure returns (uint256) {
        if (timeOrNumber) {
            return calculateVestedTokensTime(
                tokens,
                time,
                start,
                cliff,
                vesting
            );
        } else {
            return calculateVestedTokensNumber(
                tokens,
                number,
                start,
                cliff,
                vesting
            );
        }
    }

    /**
     * @dev Get all information about a specifc grant.
     * @param _holder The address which will have its tokens revoked.
     * @param _grantId The id of the token grant.
     * @return Returns all the values that represent a TokenGrant(address, value, start, cliff,
     * revokability, burnsOnRevoke, and vesting) plus the vested value at the current time.
     */
    function tokenGrant(address _holder, uint _grantId) public view 
        returns (address granter, uint256 value, uint256 vested, uint start, uint cliff, uint vesting, bool revokable, bool burnsOnRevoke, bool timeOrNumber) {
        TokenGrant storage grant = grants[_holder][_grantId];

        granter = grant.granter;
        value = grant.value;
        start = grant.start;
        cliff = grant.cliff;
        vesting = grant.vesting;
        revokable = grant.revokable;
        burnsOnRevoke = grant.burnsOnRevoke;
        timeOrNumber = grant.timeOrNumber;

        vested = vestedTokens(grant, now, block.number);
    }

    /**
     * @dev Get the amount of vested tokens at a specific time.
     * @param grant TokenGrant The grant to be checked.
     * @param time The time to be checked
     * @return An uint representing the amount of vested tokens of a specific grant at a specific time.
     */
    function vestedTokens(TokenGrant grant, uint time, uint number) private pure returns (uint256) {
        return calculateVestedTokens(
            grant.timeOrNumber,
            grant.value,
            uint256(time),
            uint256(number),
            uint256(grant.start),
            uint256(grant.cliff),
            uint256(grant.vesting)
        );
    }

    /**
     * @dev Calculate the amount of non vested tokens at a specific time.
     * @param grant TokenGrant The grant to be checked.
     * @param time uint64 The time to be checked
     * @return An uint representing the amount of non vested tokens of a specifc grant on the 
     * passed time frame.
     */
    function nonVestedTokens(TokenGrant grant, uint time, uint number) private pure returns (uint256) {
        return grant.value.sub(vestedTokens(grant, time, number));
    }

    /**
     * @dev Calculate the date when the holder can trasfer all its tokens
     * @param holder address The address of the holder
     * @return An uint representing the date of the last transferable tokens.
     */
    function lastTokenIsTransferableDate(address holder) view public returns (uint date) {
        date = now;
        uint256 grantIndex = grants[holder].length;
        for (uint256 i = 0; i < grantIndex; i++) {
            if (grants[holder][i].timeOrNumber) {
                date = SafeMath.max256(grants[holder][i].vesting, date);
            }
        }
    }
    function lastTokenIsTransferableNumber(address holder) view public returns (uint number) {
        number = block.number;
        uint256 grantIndex = grants[holder].length;
        for (uint256 i = 0; i < grantIndex; i++) {
            if (!grants[holder][i].timeOrNumber) {
                number = SafeMath.max256(grants[holder][i].vesting, number);
            }
        }
    }
}

// QUESTIONS FOR AUDITORS:
// - Considering we inherit from VestedToken, how much does that hit at our gas price?

// vesting: 365 days, 365 days / 1 vesting


contract GOCToken is VestedToken {
    //FIELDS
    string public name = "Global Optimal Chain";
    string public symbol = "GOC";
    uint public decimals = 18;
    uint public INITIAL_SUPPLY = 20 * 100000000 * 1 ether;
    uint public iTime;
    uint public iBlock;

    // Initialization contract grants msg.sender all of existing tokens.
    function GOCToken() public {
        totalSupply = INITIAL_SUPPLY;
        iTime = now;
        iBlock = block.number;

        address toAddress = msg.sender;
        balances[toAddress] = totalSupply;

        grantVestedTokens(toAddress, totalSupply.div(100).mul(30), iTime, iTime, iTime, false, false, true);

        grantVestedTokens(toAddress, totalSupply.div(100).mul(30), iTime, iTime + 365 days, iTime + 365 days, false, false, true);

        grantVestedTokens(toAddress, totalSupply.div(100).mul(20), iTime + 1095 days, iTime + 1095 days, iTime + 1245 days, false, false, true);
        
        uint startMine = uint(1054080) + block.number;// 1054080 = (183 * 24 * 60 * 60 / 15)
        uint finishMine = uint(210240000) + block.number;// 210240000 = (100 * 365 * 24 * 60 * 60 / 15)
        grantVestedTokens(toAddress, totalSupply.div(100).mul(20), startMine, startMine, finishMine, false, false, false);
    }

    // Transfer amount of tokens from sender account to recipient.
    function transfer(address _to, uint _value) public returns (bool) {
        // no-op, allow even during crowdsale, in order to work around using grantVestedTokens() while in crowdsale
        if (_to == msg.sender) return false;
        return super.transfer(_to, _value);
    }

    // Transfer amount of tokens from a specified address to a recipient.
    // Transfer amount of tokens from sender account to recipient.
    function transferFrom(address _from, address _to, uint _value) public returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function currentTransferableTokens(address holder) view public returns (uint256) {
        return transferableTokens(holder, now, block.number);
    }
}