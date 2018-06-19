/*
 * CollateralMonitor
 *
 * This contract reports aggregated issuance
 * and collateralisation statistics for the 
 * Havven stablecoin system.
 * 
 * Author: Anton Jurisevic
 * Date: 14/06/2018
 * Version: nUSDa 1.0
 */

pragma solidity ^0.4.24;


contract Havven {
    uint public price;
    uint public issuanceRatio;
    mapping(address => uint) public nominsIssued;
    function balanceOf(address account) public view returns (uint);
    function totalSupply() public view returns (uint);
    function availableHavvens(address account) public view returns (uint);
}

contract Nomin {
    function totalSupply() public view returns (uint);
}

contract HavvenEscrow {
    function balanceOf(address account) public view returns (uint);
}

/**
 * @title Safely manipulate unsigned fixed-point decimals at a given precision level.
 * @dev Functions accepting uints in this contract and derived contracts
 * are taken to be such fixed point decimals (including fiat, ether, and nomin quantities).
 */
contract SafeDecimalMath {

    /* Number of decimal places in the representation. */
    uint8 public constant decimals = 18;

    /* The number representing 1.0. */
    uint public constant UNIT = 10 ** uint(decimals);

    /**
     * @return True iff adding x and y will not overflow.
     */
    function addIsSafe(uint x, uint y)
        pure
        internal
        returns (bool)
    {
        return x + y >= y;
    }

    /**
     * @return The result of adding x and y, throwing an exception in case of overflow.
     */
    function safeAdd(uint x, uint y)
        pure
        internal
        returns (uint)
    {
        require(x + y >= y);
        return x + y;
    }

    /**
     * @return True iff subtracting y from x will not overflow in the negative direction.
     */
    function subIsSafe(uint x, uint y)
        pure
        internal
        returns (bool)
    {
        return y <= x;
    }

    /**
     * @return The result of subtracting y from x, throwing an exception in case of overflow.
     */
    function safeSub(uint x, uint y)
        pure
        internal
        returns (uint)
    {
        require(y <= x);
        return x - y;
    }

    /**
     * @return True iff multiplying x and y would not overflow.
     */
    function mulIsSafe(uint x, uint y)
        pure
        internal
        returns (bool)
    {
        if (x == 0) {
            return true;
        }
        return (x * y) / x == y;
    }

    /**
     * @return The result of multiplying x and y, throwing an exception in case of overflow.
     */
    function safeMul(uint x, uint y)
        pure
        internal
        returns (uint)
    {
        if (x == 0) {
            return 0;
        }
        uint p = x * y;
        require(p / x == y);
        return p;
    }

    /**
     * @return The result of multiplying x and y, interpreting the operands as fixed-point
     * decimals. Throws an exception in case of overflow.
     * 
     * @dev A unit factor is divided out after the product of x and y is evaluated,
     * so that product must be less than 2**256.
     * Incidentally, the internal division always rounds down: one could have rounded to the nearest integer,
     * but then one would be spending a significant fraction of a cent (of order a microether
     * at present gas prices) in order to save less than one part in 0.5 * 10^18 per operation, if the operands
     * contain small enough fractional components. It would also marginally diminish the 
     * domain this function is defined upon. 
     */
    function safeMul_dec(uint x, uint y)
        pure
        internal
        returns (uint)
    {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        return safeMul(x, y) / UNIT;

    }

    /**
     * @return True iff the denominator of x/y is nonzero.
     */
    function divIsSafe(uint x, uint y)
        pure
        internal
        returns (bool)
    {
        return y != 0;
    }

    /**
     * @return The result of dividing x by y, throwing an exception if the divisor is zero.
     */
    function safeDiv(uint x, uint y)
        pure
        internal
        returns (uint)
    {
        /* Although a 0 denominator already throws an exception,
         * it is equivalent to a THROW operation, which consumes all gas.
         * A require statement emits REVERT instead, which remits remaining gas. */
        require(y != 0);
        return x / y;
    }

    /**
     * @return The result of dividing x by y, interpreting the operands as fixed point decimal numbers.
     * @dev Throws an exception in case of overflow or zero divisor; x must be less than 2^256 / UNIT.
     * Internal rounding is downward: a similar caveat holds as with safeDecMul().
     */
    function safeDiv_dec(uint x, uint y)
        pure
        internal
        returns (uint)
    {
        /* Reintroduce the UNIT factor that will be divided out by y. */
        return safeDiv(safeMul(x, UNIT), y);
    }

    /**
     * @dev Convert an unsigned integer to a unsigned fixed-point decimal.
     * Throw an exception if the result would be out of range.
     */
    function intToDec(uint i)
        pure
        internal
        returns (uint)
    {
        return safeMul(i, UNIT);
    }

    function min(uint a, uint b) 
        pure
        internal
        returns (uint)
    {
        return a < b ? a : b;
    }

    function max(uint a, uint b) 
        pure
        internal
        returns (uint)
    {
        return a > b ? a : b;
    }
}

/**
 * @title A contract with an owner.
 * @notice Contract ownership can be transferred by first nominating the new owner,
 * who must then accept the ownership, which prevents accidental incorrect ownership transfers.
 */
contract Owned {
    address public owner;
    address public nominatedOwner;

    /**
     * @dev Owned Constructor
     */
    constructor(address _owner)
        public
    {
        require(_owner != address(0));
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    /**
     * @notice Nominate a new owner of this contract.
     * @dev Only the current owner may nominate a new owner.
     */
    function nominateNewOwner(address _owner)
        external
        onlyOwner
    {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    /**
     * @notice Accept the nomination to be owner.
     */
    function acceptOwnership()
        external
        onlyNominatedOwner
    {
        owner = nominatedOwner;
        nominatedOwner = address(0);
        emit OwnerChanged(owner, nominatedOwner);
    }

    modifier onlyOwner
    {
        require(msg.sender == owner);
        _;
    }

    modifier onlyNominatedOwner
    {
        require(msg.sender == nominatedOwner);
        _;
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}


/*
 * The CollateralMonitor queries and reports information
 * about collateralisation levels of the network.
 */
contract CollateralMonitor is Owned, SafeDecimalMath {
    
    Havven havven;
    Nomin nomin;
    HavvenEscrow escrow;

    address[] issuers;
    uint maxIssuers = 10;

    constructor(Havven _havven, Nomin _nomin, HavvenEscrow _escrow)
        Owned(msg.sender)
        public
    {
        havven = _havven;
        nomin = _nomin;
        escrow = _escrow;
    }

    function setHavven(Havven _havven)
        onlyOwner
        external
    {
        havven = _havven;
    }

    function setNomin(Nomin _nomin)
         onlyOwner
         external
    {
        nomin = _nomin;
    }

    function setEscrow(HavvenEscrow _escrow)
        onlyOwner
        external
    {
        escrow = _escrow;
    }

    function setMaxIssuers(uint newMax)
        onlyOwner
        external
    {
        maxIssuers = newMax;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyNominatedOwner {
        require(msg.sender == nominatedOwner);
        _;
    }

    function pushIssuer(address issuer)
        onlyOwner
        public
    {
        for (uint i = 0; i < issuers.length; i++) {
            require(issuers[i] != issuer);
        }
        issuers.push(issuer);
    }

    function pushIssuers(address[] newIssuers)
        onlyOwner
        external
    {
        for (uint i = 0; i < issuers.length; i++) {
            pushIssuer(newIssuers[i]);
        }
    }

    function deleteIssuer(uint index)
        onlyOwner
        external
    {
        uint length = issuers.length;
        require(index < length);
        issuers[index] = issuers[length - 1];
        delete issuers[length - 1];
    }

    function resizeIssuersArray(uint size)
        onlyOwner
        external
    {
        issuers.length = size;
    }


    /**********************************\
      collateral()

      Reports the collateral available 
      for issuance of a given issuer.
    \**********************************/

    function collateral(address account)
        public
        view
        returns (uint)
    {
        return safeAdd(havven.balanceOf(account), escrow.balanceOf(account));
    }


    /**********************************\
      totalIssuingCollateral()

      Reports the collateral available 
      for issuance of all issuers.
    \**********************************/

    function _limitedTotalIssuingCollateral(uint sumLimit)
        internal
        view
        returns (uint)
    {
        uint sum;
        uint limit = min(sumLimit, issuers.length);
        for (uint i = 0; i < limit; i++) {
            sum += collateral(issuers[i]);
        } 
        return sum;
    }

    function totalIssuingCollateral()
        public
        view
        returns (uint)
    {
        return _limitedTotalIssuingCollateral(issuers.length);
    }

    function totalIssuingCollateral_limitedSum()
        public
        view
        returns (uint)
    {
        return _limitedTotalIssuingCollateral(maxIssuers);
    } 



    /********************************\
      collateralisation()
    
      Reports the collateralisation
      ratio of one account, assuming
      a nomin price of one dollar.
    \********************************/

    function collateralisation(address account)
        public
        view
        returns (uint)
    {
        safeDiv_dec(safeMul_dec(collateral(account), havven.price()), 
                    havven.nominsIssued(account));
    }


    /********************************\
      totalIssuerCollateralisation()
    
      Reports the collateralisation
      ratio of all issuers, assuming
      a nomin price of one dollar.
    \********************************/

    function totalIssuerCollateralisation()
        public
        view
        returns (uint)
    {
        safeDiv_dec(safeMul_dec(totalIssuingCollateral(), havven.price()),
                    nomin.totalSupply());
    }


    /********************************\
      totalNetworkCollateralisation()
    
      Reports the collateralisation
      ratio of the entire network,
      assuming a nomin price of one
      dollar, and that havvens can
      flow from non-issuer to issuer
      accounts.
    \********************************/

    function totalNetworkCollateralisation()
        public
        view
        returns (uint)
    {
        safeDiv_dec(safeMul_dec(havven.totalSupply(), havven.price()),
                    nomin.totalSupply());
    }


    /**************************************\
      totalIssuanceDebt()

      Reports the the (unbounded) number
      of havvens that would be locked by
      all issued nomins, if the collateral
      backing them was unlimited.
    \**************************************/

    function totalIssuanceDebt()
        public
        view
        returns (uint)
    {
        return safeDiv_dec(nomin.totalSupply(),
                           safeMul_dec(havven.issuanceRatio(), havven.price()));
    }

    function totalIssuanceDebt_limitedSum()
        public
        view
        returns (uint)
    {
        uint sum;
        uint limit = min(maxIssuers, issuers.length);
        for (uint i = 0; i < limit; i++) {
            sum += havven.nominsIssued(issuers[i]);
        }
        return safeDiv_dec(sum,
                           safeMul_dec(havven.issuanceRatio(), havven.price()));
    }


    /*************************************\
      totalLockedHavvens()

      Reports the the number of havvens
      locked by all issued nomins.
      This is capped by the actual number
      of havvens in circulation.
    \*************************************/

    function totalLockedHavvens()
        public
        view
        returns (uint)
    {
        return min(totalIssuanceDebt(), totalIssuingCollateral());
    }

    function totalLockedHavvens_limitedSum()
        public
        view
        returns (uint)
    { 
        return min(totalIssuanceDebt_limitedSum(), totalIssuingCollateral());
    }


    /****************************************************\
      totalLockedHavvens_byAvailableHavvens_limitedSum()
      
      Should be equivalent to
      totalLockedHavvens_limitedSum() but it uses an
      alternate computation method.
    \****************************************************/

    function totalLockedHavvens_byAvailableHavvens_limitedSum()
        public
        view
        returns (uint)
    {
        uint sum;
        uint limit = min(maxIssuers, issuers.length);
        for (uint i = 0; i < limit; i++) {
            address issuer = issuers[i];
            sum += safeSub(collateral(issuer), havven.availableHavvens(issuer));
        }
        return sum;
    }
}