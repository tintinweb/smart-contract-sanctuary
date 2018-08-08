pragma solidity 0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
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
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

/**
 * @title EIP20/ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract EIP20 is ERC20 {
    string public name;
    uint8 public decimals;
    string public symbol;
}

interface NonCompliantEIP20 {
    function transfer(address _to, uint _value) external;
    function transferFrom(address _from, address _to, uint _value) external;
    function approve(address _spender, uint _value) external;
}

/**
 * @title EIP20/ERC20 wrapper that will support noncompliant ERC20s
 * @dev see https://github.com/ethereum/EIPs/issues/20
 * @dev see https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
 */
contract EIP20Wrapper {

    function eip20Transfer(
        address token,
        address to,
        uint256 value)
        internal
        returns (bool result) {

        NonCompliantEIP20(token).transfer(to, value);

        assembly {
            switch returndatasize()   
            case 0 {                        // non compliant ERC20
                result := not(0)            // result is true
            }
            case 32 {                       // compliant ERC20
                returndatacopy(0, 0, 32) 
                result := mload(0)          // result == returndata of external call
            }
            default {                       // not an not an ERC20 token
                revert(0, 0) 
            }
        }

        require(result, "eip20Transfer failed");
    }

    function eip20TransferFrom(
        address token,
        address from,
        address to,
        uint256 value)
        internal
        returns (bool result) {

        NonCompliantEIP20(token).transferFrom(from, to, value);

        assembly {
            switch returndatasize()   
            case 0 {                        // non compliant ERC20
                result := not(0)            // result is true
            }
            case 32 {                       // compliant ERC20
                returndatacopy(0, 0, 32) 
                result := mload(0)          // result == returndata of external call
            }
            default {                       // not an not an ERC20 token
                revert(0, 0) 
            }
        }

        require(result, "eip20TransferFrom failed");
    }

    function eip20Approve(
        address token,
        address spender,
        uint256 value)
        internal
        returns (bool result) {

        NonCompliantEIP20(token).approve(spender, value);

        assembly {
            switch returndatasize()   
            case 0 {                        // non compliant ERC20
                result := not(0)            // result is true
            }
            case 32 {                       // compliant ERC20
                returndatacopy(0, 0, 32) 
                result := mload(0)          // result == returndata of external call
            }
            default {                       // not an not an ERC20 token
                revert(0, 0) 
            }
        }

        require(result, "eip20Approve failed");
    }
}

// This provides a gatekeeping modifier for functions that can only be used by the bZx contract
// Since it inherits Ownable provides typical ownership functionality with a slight modification to the transferOwnership function
// Setting owner and bZxContractAddress to the same address is not supported.
contract BZxOwnable is Ownable {

    address public bZxContractAddress;

    event BZxOwnershipTransferred(address indexed previousBZxContract, address indexed newBZxContract);

    // modifier reverts if bZxContractAddress isn&#39;t set
    modifier onlyBZx() {
        require(msg.sender == bZxContractAddress, "only bZx contracts can call this function");
        _;
    }

    /**
    * @dev Allows the current owner to transfer the bZx contract owner to a new contract address
    * @param newBZxContractAddress The bZx contract address to transfer ownership to.
    */
    function transferBZxOwnership(address newBZxContractAddress) public onlyOwner {
        require(newBZxContractAddress != address(0) && newBZxContractAddress != owner, "transferBZxOwnership::unauthorized");
        emit BZxOwnershipTransferred(bZxContractAddress, newBZxContractAddress);
        bZxContractAddress = newBZxContractAddress;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    * This overrides transferOwnership in Ownable to prevent setting the new owner the same as the bZxContract
    */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0) && newOwner != bZxContractAddress, "transferOwnership::unauthorized");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

interface ExchangeInterface {
    event LogError(uint8 indexed errorId, bytes32 indexed orderHash);

    function fillOrder(
          address[5] orderAddresses,
          uint[6] orderValues,
          uint fillTakerTokenAmount,
          bool shouldThrowOnInsufficientBalanceOrAllowance,
          uint8 v,
          bytes32 r,
          bytes32 s)
          external
          returns (uint filledTakerTokenAmount);

    function fillOrdersUpTo(
        address[5][] orderAddresses,
        uint[6][] orderValues,
        uint fillTakerTokenAmount,
        bool shouldThrowOnInsufficientBalanceOrAllowance,
        uint8[] v,
        bytes32[] r,
        bytes32[] s)
        external
        returns (uint);

    function isValidSignature(
        address signer,
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s)
        external
        constant
        returns (bool);
}

contract BZxTo0x is EIP20Wrapper, BZxOwnable {
    using SafeMath for uint256;

    address public exchangeContract;
    address public zrxTokenContract;
    address public tokenTransferProxyContract;

    constructor(
        address _exchange, 
        address _zrxToken,
        address _proxy) 
        public 
    {
        exchangeContract = _exchange;
        zrxTokenContract = _zrxToken;
        tokenTransferProxyContract = _proxy;
    }

    function() 
        public {
        revert();
    }

   function take0xTrade(
        address trader,
        address vaultAddress,
        uint sourceTokenAmountToUse,
        bytes orderData0x, // 0x order arguments, converted to hex, padded to 32 bytes and concatenated
        bytes signature0x) // ECDSA of the 0x order
        public
        onlyBZx
        returns (
            address destTokenAddress,
            uint destTokenAmount,
            uint sourceTokenUsedAmount)
    {
        (address[5][] memory orderAddresses0x, uint[6][] memory orderValues0x) = getOrderValuesFromData(orderData0x);

        (sourceTokenUsedAmount, destTokenAmount) = _take0xTrade(
            trader,
            sourceTokenAmountToUse,
            orderAddresses0x,
            orderValues0x,
            signature0x);

        if (sourceTokenUsedAmount < sourceTokenAmountToUse) {
            // all sourceToken has to be traded
            revert("BZxTo0x::take0xTrade: sourceTokenUsedAmount < sourceTokenAmountToUse");
        }

        // transfer the destToken to the vault
        eip20Transfer(
            orderAddresses0x[0][2],
            vaultAddress,
            destTokenAmount);

        destTokenAddress = orderAddresses0x[0][2]; // makerToken (aka destTokenAddress)
    }

    function getOrderValuesFromData(
        bytes orderData0x)
        public
        pure
        returns (
            address[5][] orderAddresses,
            uint[6][] orderValues) 
    {
        address maker;
        address taker;
        address makerToken;
        address takerToken;
        address feeRecipient;
        uint makerTokenAmount;
        uint takerTokenAmount;
        uint makerFee;
        uint takerFee;
        uint expirationTimestampInSec;
        uint salt;
        orderAddresses = new address[5][](orderData0x.length/352);
        orderValues = new uint[6][](orderData0x.length/352);
        for (uint i = 0; i < orderData0x.length/352; i++) {
            assembly {
                maker := mload(add(orderData0x, add(mul(i, 352), 32)))
                taker := mload(add(orderData0x, add(mul(i, 352), 64)))
                makerToken := mload(add(orderData0x, add(mul(i, 352), 96)))
                takerToken := mload(add(orderData0x, add(mul(i, 352), 128)))
                feeRecipient := mload(add(orderData0x, add(mul(i, 352), 160)))
                makerTokenAmount := mload(add(orderData0x, add(mul(i, 352), 192)))
                takerTokenAmount := mload(add(orderData0x, add(mul(i, 352), 224)))
                makerFee := mload(add(orderData0x, add(mul(i, 352), 256)))
                takerFee := mload(add(orderData0x, add(mul(i, 352), 288)))
                expirationTimestampInSec := mload(add(orderData0x, add(mul(i, 352), 320)))
                salt := mload(add(orderData0x, add(mul(i, 352), 352)))
            }
            orderAddresses[i] = [
                maker,
                taker,
                makerToken,
                takerToken,
                feeRecipient
            ];
            orderValues[i] = [
                makerTokenAmount,
                takerTokenAmount,
                makerFee,
                takerFee,
                expirationTimestampInSec,
                salt
            ];
        }
    }

    /// @param signatures ECDSA signatures in raw bytes (rsv).
    function getSignatureParts(
        bytes signatures)
        public
        pure
        returns (
            uint8[] vs,
            bytes32[] rs,
            bytes32[] ss)
    {
        vs = new uint8[](signatures.length/65);
        rs = new bytes32[](signatures.length/65);
        ss = new bytes32[](signatures.length/65);
        for (uint i = 0; i < signatures.length/65; i++) {
            uint8 v;
            bytes32 r;
            bytes32 s;
            assembly {
                r := mload(add(signatures, add(mul(i, 65), 32)))
                s := mload(add(signatures, add(mul(i, 65), 64)))
                v := mload(add(signatures, add(mul(i, 65), 65)))
            }
            if (v < 27) {
                v = v + 27;
            }
            vs[i] = v;
            rs[i] = r;
            ss[i] = s;
        }
    }

    /// @dev Calculates partial value given a numerator and denominator.
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to calculate partial of.
    /// @return Partial value of target.
    function getPartialAmount(uint numerator, uint denominator, uint target)
        public
        pure
        returns (uint)
    {
        return SafeMath.div(SafeMath.mul(numerator, target), denominator);
    }

    function set0xExchange (
        address _exchange)
        public
        onlyOwner
    {
        exchangeContract = _exchange;
    }

    function setZRXToken (
        address _zrxToken)
        public
        onlyOwner
    {
        zrxTokenContract = _zrxToken;
    }

    function set0xTokenProxy (
        address _proxy)
        public
        onlyOwner
    {
        tokenTransferProxyContract = _proxy;
    }

    function approveFor (
        address token,
        address spender,
        uint value)
        public
        onlyOwner
        returns (bool)
    {
        eip20Approve(
            token,
            spender,
            value);

        return true;
    }

    function _take0xTrade(
        address trader,
        uint sourceTokenAmountToUse,
        address[5][] orderAddresses0x,
        uint[6][] orderValues0x,
        bytes signature)
        internal
        returns (uint sourceTokenUsedAmount, uint destTokenAmount) 
    {
        uint[3] memory summations; // takerTokenAmountTotal, makerTokenAmountTotal, zrxTokenAmount

        for (uint i = 0; i < orderAddresses0x.length; i++) {
            summations[0] += orderValues0x[0][1]; // takerTokenAmountTotal
            summations[1] += orderValues0x[0][0]; // makerTokenAmountTotal
            
            if (orderAddresses0x[i][4] != address(0) && // feeRecipient
                    orderValues0x[i][3] > 0 // takerFee
            ) {
                summations[2] += orderValues0x[i][3]; // zrxTokenAmount
            }
        }
        if (summations[2] > 0) {
            // The 0x TokenTransferProxy already has unlimited transfer allowance for ZRX from this contract (set during deployment of this contract)
            eip20TransferFrom(
                zrxTokenContract,
                trader,
                this,
                summations[2]);
        }

        (uint8[] memory v, bytes32[] memory r, bytes32[] memory s) = getSignatureParts(signature);

        // Increase the allowance for 0x Exchange Proxy to transfer the sourceToken needed for the 0x trade
        // orderAddresses0x[0][3] -> takerToken/sourceToken
        eip20Approve(
            orderAddresses0x[0][3],
            tokenTransferProxyContract,
            EIP20(orderAddresses0x[0][3]).allowance(this, tokenTransferProxyContract).add(sourceTokenAmountToUse));

        if (orderAddresses0x.length > 0) {
            sourceTokenUsedAmount = ExchangeInterface(exchangeContract).fillOrdersUpTo(
                orderAddresses0x,
                orderValues0x,
                sourceTokenAmountToUse,
                false, // shouldThrowOnInsufficientBalanceOrAllowance
                v,
                r,
                s);
        } else {
            sourceTokenUsedAmount = ExchangeInterface(exchangeContract).fillOrder(
                orderAddresses0x[0],
                orderValues0x[0],
                sourceTokenAmountToUse,
                false, // shouldThrowOnInsufficientBalanceOrAllowance
                v[0],
                r[0],
                s[0]);
        }

        destTokenAmount = getPartialAmount(
            sourceTokenUsedAmount,
            summations[0], // takerTokenAmountTotal (aka sourceTokenAmount)
            summations[1]  // makerTokenAmountTotal (aka destTokenAmount)
        );
    }
}