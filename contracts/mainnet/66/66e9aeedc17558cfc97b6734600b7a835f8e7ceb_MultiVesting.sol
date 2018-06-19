pragma solidity ^0.4.18;
/**
 * Changes by https://www.docademic.com/
 */

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

contract Destroyable is Ownable{
    /**
     * @notice Allows to destroy the contract and return the tokens to the owner.
     */
    function destroy() public onlyOwner{
        selfdestruct(owner);
    }
}

interface Token {
    function transfer(address _to, uint256 _value) public;

    function balanceOf(address who) public returns (uint256);
}

contract MultiVesting is Ownable, Destroyable {
    using SafeMath for uint256;

    // beneficiary of tokens
    struct Beneficiary {
        uint256 released;
        uint256 vested;
        uint256 start;
        uint256 cliff;
        uint256 duration;
        bool revoked;
        bool revocable;
        bool isBeneficiary;
    }

    event Released(address _beneficiary, uint256 amount);
    event Revoked(address _beneficiary);
    event NewBeneficiary(address _beneficiary);
    event BeneficiaryDestroyed(address _beneficiary);


    mapping(address => Beneficiary) public beneficiaries;
    Token public token;
    uint256 public totalVested;
    uint256 public totalReleased;

    /*
     *  Modifiers
     */
    modifier isNotBeneficiary(address _beneficiary) {
        require(!beneficiaries[_beneficiary].isBeneficiary);
        _;
    }
    modifier isBeneficiary(address _beneficiary) {
        require(beneficiaries[_beneficiary].isBeneficiary);
        _;
    }

    modifier wasRevoked(address _beneficiary) {
        require(beneficiaries[_beneficiary].revoked);
        _;
    }

    modifier wasNotRevoked(address _beneficiary) {
        require(!beneficiaries[_beneficiary].revoked);
        _;
    }

    /**
     * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
     * beneficiary, gradually in a linear fashion until _start + _duration. By then all
     * of the balance will have vested.
     * @param _token address of the token of vested tokens
     */
    function MultiVesting(address _token) public {
        require(_token != address(0));
        token = Token(_token);
    }

    function() payable public {
        release(msg.sender);
    }

    /**
     * @notice Transfers vested tokens to beneficiary (alternative to fallback function).
     */
    function release() public {
        release(msg.sender);
    }

    /**
     * @notice Transfers vested tokens to beneficiary.
     * @param _beneficiary Beneficiary address
     */
    function release(address _beneficiary) private
    isBeneficiary(_beneficiary)
    {
        Beneficiary storage beneficiary = beneficiaries[_beneficiary];

        uint256 unreleased = releasableAmount(_beneficiary);

        require(unreleased > 0);

        beneficiary.released = beneficiary.released.add(unreleased);

        totalReleased = totalReleased.add(unreleased);

        token.transfer(_beneficiary, unreleased);

        if((beneficiary.vested - beneficiary.released) == 0){
            beneficiary.isBeneficiary = false;
        }

        Released(_beneficiary, unreleased);
    }

    /**
     * @notice Allows the owner to transfers vested tokens to beneficiary.
     * @param _beneficiary Beneficiary address
     */
    function releaseTo(address _beneficiary) public onlyOwner {
        release(_beneficiary);
    }

    /**
     * @dev Add new beneficiary to start vesting
     * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
     * @param _start time in seconds which the tokens will vest
     * @param _cliff time in seconds of the cliff in which tokens will begin to vest
     * @param _duration duration in seconds of the period in which the tokens will vest
     * @param _revocable whether the vesting is revocable or not
     */
    function addBeneficiary(address _beneficiary, uint256 _vested, uint256 _start, uint256 _cliff, uint256 _duration, bool _revocable)
    onlyOwner
    isNotBeneficiary(_beneficiary)
    public {
        require(_beneficiary != address(0));
        require(_cliff >= _start);
        require(token.balanceOf(this) >= totalVested.sub(totalReleased).add(_vested));
        beneficiaries[_beneficiary] = Beneficiary({
            released : 0,
            vested : _vested,
            start : _start,
            cliff : _cliff,
            duration : _duration,
            revoked : false,
            revocable : _revocable,
            isBeneficiary : true
            });
        totalVested = totalVested.add(_vested);
        NewBeneficiary(_beneficiary);
    }

    /**
     * @notice Allows the owner to revoke the vesting. Tokens already vested
     * remain in the contract, the rest are returned to the owner.
     * @param _beneficiary Beneficiary address
     */
    function revoke(address _beneficiary) public onlyOwner {
        Beneficiary storage beneficiary = beneficiaries[_beneficiary];
        require(beneficiary.revocable);
        require(!beneficiary.revoked);

        uint256 balance = beneficiary.vested.sub(beneficiary.released);

        uint256 unreleased = releasableAmount(_beneficiary);
        uint256 refund = balance.sub(unreleased);

        token.transfer(owner, refund);

        totalReleased = totalReleased.add(refund);

        beneficiary.revoked = true;
        beneficiary.released = beneficiary.released.add(refund);

        Revoked(_beneficiary);
    }

    /**
     * @notice Allows the owner to destroy a beneficiary. Remain tokens are returned to the owner.
     * @param _beneficiary Beneficiary address
     */
    function destroyBeneficiary(address _beneficiary) public onlyOwner {
        Beneficiary storage beneficiary = beneficiaries[_beneficiary];

        uint256 balance = beneficiary.vested.sub(beneficiary.released);

        token.transfer(owner, balance);

        totalReleased = totalReleased.add(balance);

        beneficiary.isBeneficiary = false;
        beneficiary.released = beneficiary.released.add(balance);

        BeneficiaryDestroyed(_beneficiary);
    }

    /**
     * @dev Calculates the amount that has already vested but hasn&#39;t been released yet.
     * @param _beneficiary Beneficiary address
     */
    function releasableAmount(address _beneficiary) public view returns (uint256) {
        return vestedAmount(_beneficiary).sub(beneficiaries[_beneficiary].released);
    }

    /**
     * @dev Calculates the amount that has already vested.
     * @param _beneficiary Beneficiary address
     */
    function vestedAmount(address _beneficiary) public view returns (uint256) {
        Beneficiary storage beneficiary = beneficiaries[_beneficiary];
        uint256 totalBalance = beneficiary.vested;

        if (now < beneficiary.cliff) {
            return 0;
        } else if (now >= beneficiary.start.add(beneficiary.duration) || beneficiary.revoked) {
            return totalBalance;
        } else {
            return totalBalance.mul(now.sub(beneficiary.start)).div(beneficiary.duration);
        }
    }

    /**
     * @notice Allows the owner to flush the eth.
     */
    function flushEth() public onlyOwner {
        owner.transfer(this.balance);
    }

    /**
     * @notice Allows the owner to destroy the contract and return the tokens to the owner.
     */
    function destroy() public onlyOwner {
        token.transfer(owner, token.balanceOf(this));
        selfdestruct(owner);
    }
}