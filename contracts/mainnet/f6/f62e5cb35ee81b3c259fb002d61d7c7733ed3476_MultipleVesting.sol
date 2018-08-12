pragma solidity ^0.4.21;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function Ownable() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

contract ERC20Token {
    function mintTokens(address _atAddress, uint256 _amount) public;

}

contract MultipleVesting is Ownable {
    using SafeMath for uint256;

    struct Grant {
        uint256 start;
        uint256 cliff;
        uint256 duration;
        uint256 value;
        uint256 transferred;
        bool revocable;
    }

    mapping (address => Grant) public grants;
    mapping (uint256 => address) public indexedGrants;
    uint256 public index;
    uint256 public totalVesting;
    ERC20Token token;

    event NewGrant(address indexed _address, uint256 _value);
    event UnlockGrant(address indexed _holder, uint256 _value);
    event RevokeGrant(address indexed _holder, uint256 _refund);

    function setToken(address _token) public onlyOwner {
        token = ERC20Token(_token);
    }

    /**
     * @dev Allows the current owner to add new grant
     * @param _address Address of grant
     * @param _start Start time of vesting in timestamp
     * @param _cliff Cliff in timestamp
     * @param _duration End of vesting in timestamp
     * @param _value Number of tokens to be vested
     * @param _revocable Can grant be revoked
     */
    function newGrant(address _address, uint256 _start, uint256 _cliff, uint256 _duration, uint256 _value, bool _revocable) public onlyOwner {
        if(grants[_address].value == 0) {
            indexedGrants[index] = _address;
            index = index.add(1);
        }
        grants[_address] = Grant({
            start: _start,
            cliff: _cliff,
            duration: _duration,
            value: _value,
            transferred: 0,
            revocable: _revocable
            });

        totalVesting = totalVesting.add(_value);
        emit NewGrant(_address, _value);
    }

    /**
     * @dev Allows the curretn owner to revoke grant
     * @param _grant Address of grant to be revoked
     */
    function revoke(address _grant) public onlyOwner {
        Grant storage grant = grants[_grant];
        require(grant.revocable);

        uint256 refund = grant.value.sub(grant.transferred);

        // Remove the grant.
        delete grants[_grant];
        totalVesting = totalVesting.sub(refund);

        token.mintTokens(msg.sender, refund);
        emit RevokeGrant(_grant, refund);
    }

    /**
     * @dev Number of veset token for _holder on _time
     * @param _holder Address of holder
     * @param _time Timestamp of time to check for vest amount
     */
    function vestedTokens(address _holder, uint256 _time) public constant returns (uint256) {
        Grant storage grant = grants[_holder];
        if (grant.value == 0) {
            return 0;
        }

        return calculateVestedTokens(grant, _time);
    }

    /**
     * @dev Calculate amount of vested tokens
     * @param _grant Grant to calculate for
     * @param _time Timestamp of time to check for
     */
    function calculateVestedTokens(Grant _grant, uint256 _time) private pure returns (uint256) {
        // If we&#39;re before the cliff, then nothing is vested.
        if (_time < _grant.cliff) {
            return 0;
        }

        // If we&#39;re after the end of the vesting period - everything is vested;
        if (_time >= _grant.duration) {
            return _grant.value;
        }

        // Interpolate all vested tokens: vestedTokens = tokens/// (time - start) / (end - start)
        return _grant.value.mul(_time.sub(_grant.start)).div(_grant.duration.sub(_grant.start));
    }

    /**
     * @dev Distribute tokens to grants
     */
    function vest() public onlyOwner {
        for(uint16 i = 0; i < index; i++) {
            Grant storage grant = grants[indexedGrants[i]];
            if(grant.value == 0) continue;
            uint256 vested = calculateVestedTokens(grant, now);
            if (vested == 0) {
                continue;
            }

            // Make sure the holder doesn&#39;t transfer more than what he already has.
            uint256 transferable = vested.sub(grant.transferred);
            if (transferable == 0) {
                continue;
            }

            grant.transferred = grant.transferred.add(transferable);
            totalVesting = totalVesting.sub(transferable);
            token.mintTokens(indexedGrants[i], transferable);

            emit UnlockGrant(msg.sender, transferable);
        }
    }

    function unlockVestedTokens() public {
        Grant storage grant = grants[msg.sender];
        require(grant.value != 0);

        // Get the total amount of vested tokens, acccording to grant.
        uint256 vested = calculateVestedTokens(grant, now);
        if (vested == 0) {
            return;
        }

        // Make sure the holder doesn&#39;t transfer more than what he already has.
        uint256 transferable = vested.sub(grant.transferred);
        if (transferable == 0) {
            return;
        }

        grant.transferred = grant.transferred.add(transferable);
        totalVesting = totalVesting.sub(transferable);
        token.mintTokens(msg.sender, transferable);

        emit UnlockGrant(msg.sender, transferable);
    }
}