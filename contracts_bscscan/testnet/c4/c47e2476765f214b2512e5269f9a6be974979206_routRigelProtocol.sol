/**
 *Submitted for verification at BscScan.com on 2022-01-21
*/

// File: contracts\interface\rigelfutureExchangeInterface.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface rigelfutureExchangeInterface {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB, address aggregator) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}
interface IRGPRoutV1 {

    struct Order {
        uint256 side;    
        address ticker;   
        uint256 amount; 
        uint256 price;
        uint256 date;
        uint256 id; 
    }

    enum SIDE {
        buy,
        sell
    }

    function Factory() external view returns (address);
    function addLiquidity(address tokenA, address tokenB, address aggregator, uint256 amount, address _to) external returns(uint256 liquidity);
    function removeLiquidity(address tokenA, address tokenB, uint256 amount, address _to) external;
    function deposit( address tokenA, address tokenB, uint256 amount) external;
    function withdraw( address tokenA, address tokenB, uint256 amount) external;
    function fillOrder(
        address tokenA, address tokenB, 
        uint256 amount,
        uint256 price, uint256 _leverage, 
        SIDE _side,        
        bytes32 hash, bytes32 r, bytes32 vs
        ) external;
    function cancelOrder(address tokenA, address tokenB, uint256 _id) external;
    function getAmountOut(
        address tokenA, address tokenB,
        uint256 amount,
        uint256 _leverage, SIDE side
        ) external view returns(uint256 totalTradeable, uint256 liquidation, uint256 userGetProfit);
    function getUserPoolD(address tokenA, address tokenB, address _user, uint256 _orderID) external view returns(
        address order,
        uint256 amount, 
        uint256 filled,
        uint256 price,
        uint256 leverage, 
        uint256 liquidationPeriod, 
        uint256 profit, 
        uint256 side
    );
    function traderBalance(address tokenA, address tokenB, address _trader) external view returns(uint256 userBalance);
    function FLPRewards(address tokenA, address tokenB, address user) external view returns(uint256  reward);
    function getAllPoolReward(address tokenA, address tokenB) external view returns(uint256 _flp, uint256 _tresurer, uint256 _lp, uint256 _team, uint256 _llevP);
    function updateReward(address tokenA, address tokenB, uint256 _flp, uint256 _tresurer, uint256 _lp, uint256 _team) external;
    function orderCancelled(address tokenA, address tokenB, uint256 orderID) external view returns(bool);
    function orderFilled(address tokenA, address tokenB, uint256 orderID) external view returns(bool);
}

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IRGPfutureExchange {

    struct rewardPool {
        uint256 flp;
        uint256 rgpTresure;
        uint256 lp;
        uint256 team;
        uint256 lflp;
    }

    struct OrderPool {
        uint256 id;
        address sender;
        address order;
        uint256 amount;
        uint256 filled;
        uint256 price;
        uint256 leverage;
        uint256 liquidationPeriod;
        uint256 profit;
        uint256 side;
        bytes32 Hash;
        bytes32 r;
        bytes32 vs;
    }

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event transact(
        address indexed sender,
        address indexed to,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out
    );
    event marginTrader(address indexed magProvider, uint256 amount);
    event _lpReward(address indexed sender, uint256 _amt);
    event Cancel(
        uint256 id,
        address indexed user,
        address order,
        uint256 amount,
        uint256 filled,
        uint256 price,
        uint256 _leverage,
        uint256 side
    );

    event fulfilOrder(
        uint256 id,
        address indexed user,
        address order,
        uint256 amount,
        uint256 filled,
        uint256 price,
        uint256 _leverage,
        uint256 side
    );

    event _createLimitOrder(
        address indexed sender,
        address indexed order, 
        uint256 amount, 
        uint256 filled, 
        uint256 price,  
        uint256 _leverage, 
        uint256 side
        );
    event _updateReward(address indexed sender, uint256 _flp, uint256 _tresurer, uint256 _lp, uint256 _team);

    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint256 reserve);

    function mint( address _to, uint256 amount) external returns (uint liquidity);
    function burn( address _to, uint256 amount) external returns (uint liquidity);   

    function initialize(address, address, address, address) external;
    function updateTraderBalance(address _to, uint256 _amount, bool status) external;
    function fillOrder(address _user, address order, uint256 amount, uint256 price,  uint256 _leverage, uint256 side,  bytes32 hash, bytes32 r, bytes32 vs) external  
        returns (uint256 totalTradeable, uint256 liquidation, uint256 userGetProfit);
    function cancelOrder(uint256 _id, address _user) external;
    function createLimitOrder(uint256 _id, address _user, bytes32 _hash, bytes32 r, bytes32 vs) external;
    function lpReward(uint256 _amt, address _to) external;
    function withdrawReward(uint256 _amt, address _recipient, uint256 _point) external;
    function updateReward(uint256 _flp, uint256 _tresurer, uint256 _lp, uint256 _team) external;
    function lpShare(address _addr) external view returns(uint256);
    function getTrading(uint256 amount,uint256 _leverage, uint256 side) external view returns(uint256 totalTradeable, uint256 liquidation, uint256 userGetProfit);
    function getTraderBalance(address trader) external view returns(uint256 traderBalance);
    function currentReward() external view returns(uint256, uint256, uint256, uint256, uint256); 
    function orderCancelled(uint256 orderID) external view returns(bool);
    function orderFilled(uint256 orderID) external view returns(bool);
    function getOrderPool(address _user, uint256 _orderID) external view returns( uint256, uint256, uint256, uint256, uint256, uint256, uint256);
}
// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }

    function div(
    uint256 a,
    uint256 b
      )
        internal
        pure
        returns (
          uint256
        )
      {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    
        return c;
      }
}

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            //revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

contract RGPExchangeERC20 {
    using SafeMath for uint;
    using ECDSA for bytes32;
    using ECDSA for bytes;

    string public constant name = 'RGP Future Leverage Provider';
    string public constant symbol = 'FLP';
    uint8 public constant decimals = 18;
    uint  public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public nonces;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    constructor() {
        uint256 chainId = getChainID();
        
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
    }
    
    function getChainID() internal view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    function _mint(address to, uint value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        if (allowance[from][msg.sender] != 0) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function recover_r_vs(
        address owner,
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) public pure returns (address) {
        bytes32 getHash = hash.toEthSignedMessageHash();
        address recoveredAddress = getHash.recover(r, vs);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'Rigels Exchange: INVALID_SIGNATURE');
        return recoveredAddress;
    }

}

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

contract rigelfutureExchangePair is IRGPfutureExchange, RGPExchangeERC20 {
    using SafeMath  for uint256;
    AggregatorV3Interface internal priceFeed;
    address public factory;
    address public token0;
    address public token1;
    address private rigelTreasury;
    
    uint256 private constant LeverageRatio = 250000;
    uint256 private reserve;
    uint256 public nextOrderID;
    uint256 public FLPpercentage;
    uint256 public RGPTreasurerPausePercent;
    uint256 public LPPercent;
    uint256 public teamPercent;
    
    mapping(address => rewardPool) private lpRewards;  
    mapping(address => mapping(address => uint256)) private traderBalances;
    mapping(address => mapping(uint256 => uint256)) public lpCheck;   
    mapping(address => mapping(uint256 => OrderPool)) private  orderPool;
    mapping(uint256 => bool) public orderCancelled;
    mapping(uint256 => bool) public orderFilled;

    modifier tokenNotTradeable(address order) {
        require(order != token1, "cannot trade leverage Token");        
        require(order == token0, "Rigel: Token not paired");
        _;
    }

    constructor() {
        factory = _msgSender();
    }
    
    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function initialize(address _token0, address _token1, address aggregator, address _rigelTreasury) external {
        require(_msgSender() == factory, 'rigelfutureExchangeFactory: FORBIDDEN'); // sufficient check
        priceFeed = AggregatorV3Interface(aggregator);
        token0 = _token0;
        token1 = _token1;
        rigelTreasury = _rigelTreasury;
        FLPpercentage = 70E18;
        RGPTreasurerPausePercent = 15E18;
        LPPercent = 13E18;
        teamPercent = 2E18;
    }
    
    function getTraderBalance(address _trader) public view returns(uint256 traderBalance) {
        traderBalance = (traderBalances[token1][_trader]);
        return traderBalance;
    }    
    
    function updateTraderBalance( address _to, uint256 _amount, bool status) public {
        if(status == true) {
            RGPExchangeERC20(token1).transferFrom(_to, address(this), _amount);
            traderBalances[token1][_to] += _amount;
            emit marginTrader(_to, _amount);
        }  else {
            require(_amount <= traderBalances[token1][_to], "INSUFFICIENT_TRADING_AMOUNT");
            traderBalances[token1][_to] -= _amount;
            RGPExchangeERC20(token1).transfer(_to, _amount);
            emit marginTrader(_to, _amount);
        }
    }

    function getReserves() public view returns (uint256 reserve0) {
        return reserve;
    }
    
    function mint(address _to, uint256 amount) external returns (uint256 Leverage) {
        require(_to != address(0), "ERC20: mint to the zero address");
        Leverage = amount.div(LeverageRatio);
        require(Leverage > 0, 'RGP: INSUFFICIENT_Leverage_MINTED');
        reserve = reserve.add(amount);
        _mint(_to, Leverage);        
    }
    
    function burn(address _to, uint256 amount) external returns (uint256 _amount) {
        rewardPool memory rwdp = lpRewards[token0];
        require(_to != address(0), "ERC20: mint to the zero address");
        _amount = amount.mul(LeverageRatio);
        reserve = reserve.sub(_amount);
        _burn(address(this), amount);        
        if (rwdp.lflp != 0) {
            uint256 _withdrawableAmount = ((rwdp.lflp).div(totalSupply)).mul(amount); 
            RGPExchangeERC20(token1).transfer(_to, _withdrawableAmount);
        } else {
            RGPExchangeERC20(token1).transfer(_to, _amount); 
        }             
    } 
    
    function lpReward(uint256 _amt, address _to) external {
        rewardPool memory rwdp = lpRewards[token0];
        // get the withdrawable amount that an lp has on the pool
        uint256 withdrawableAmount = lpShare(_to);
        // check to be sure that lp cant withdraw 0 amount
        require(withdrawableAmount != 0, "RigelExchange: No Leverage reward");
        // check to make sure user has the amount to withdraw in the pool
        require(_amt <= withdrawableAmount, "RigelExchange: Insufficient funds");
        // get the amount that is currently stored on the pool to update lp provider data.
        uint256 share = rwdp.flp;
        // update the lp provider storage or current withdrawable amount.
        lpCheck[_to][_amt] = share;
        // transfer to lp provider
        RGPExchangeERC20(token1).transfer(_to, _amt);  
        emit _lpReward(_to, _amt);
    }

    function lpShare(address _addr) public view returns (uint256 _lpShare) {
        rewardPool memory rwdp = lpRewards[token0];
        // get the current share price for the Leverage provider
        uint256 share = rwdp.flp;
        // check the differences between when lp provider las withdrawn his share and the current amount on the lp
        uint256 dfShare = lpCheck[_addr][share];
        // get the pool balance of lp account
        uint256 poolBal = balanceOf[_addr];
        // calculate the share of lp provider
        if (dfShare != 0){
            _lpShare = ((dfShare.div(totalSupply)).mul(poolBal));
            return _lpShare;
        } else {
            _lpShare = share.div(totalSupply);
            return _lpShare.mul(poolBal);
        }        
    }

    function getTrading(uint256 amount, uint256 _leverage, uint256 side) public view returns(uint256 totalTradeable, uint256 liquidation, uint256 userGetProfit) {
        if (side != 0 && side != 1) {revert("Rigel: Side must either be 0 or 1");}
        uint256 tpt = 100E18;
        uint256 oneEth = 1E18;
        uint256 filled = getLatestPrice();

        if(side == 0) {
            // get user liquidation price  
            liquidation = filled.sub((filled.mul(_leverage)).div(tpt));
            // get user reward price
            userGetProfit = filled.add(filled.mul(_leverage).div(tpt));
            // user tradeable amount in X
            uint256 tradeable = (amount.mul(_leverage).sub(amount)).div(oneEth);
            // amount that user can trade
            totalTradeable = tradeable.add(amount.div(oneEth));            
            uint256 allowable_lev = (getReserves().mul(10E18).div(tpt));
            require(totalTradeable <= allowable_lev, "Rigel: Amount is greater than max allowable");
            
        } else if (side == 1){
            // get user liquidation price
            liquidation = filled.add((filled.mul(_leverage)).div(tpt));
            // get user reward price
            userGetProfit = filled.sub(filled.mul(_leverage).div(tpt));
            // user tradeable amount in X
            uint256 tradeable = (amount.mul(_leverage).sub(amount)).div(oneEth);
            // amount that user can trade
            totalTradeable = tradeable.add(amount.div(oneEth));            
            uint256 allowable_lev = (getReserves().mul(10E18).div(tpt));
            require(totalTradeable <= allowable_lev, "Rigel: Amount is greater than max allowable");
        }
        
        return (totalTradeable, liquidation, userGetProfit);
    }

    function getLatestPrice() public view returns (uint256 cprice) {
        (
            , 
            int256 price,
            ,
            ,
            
        ) = priceFeed.latestRoundData();
       if(price > 0)

       cprice = uint256(price);
       return cprice;
    }

    function fillOrder(
        address _user,
        address order, uint256 amount, 
        uint256 price,  
        uint256 _leverage, uint256 side,
        bytes32 _hash, bytes32 r, bytes32 vs) external tokenNotTradeable(order) 
        returns (uint256 totalTradeable, uint256 liquidation, uint256 userGetProfit) {
        if (side > 1) {revert("Rigel: Side must either be 0 or 1");}   
        uint256 totalLeverage = getReserves();        
        require(amount <= getTraderBalance(_user), "Rigel: INSUFFICIENT_TRADING_AMOUNT");               
        nextOrderID = nextOrderID.add(1);      
        if(side == 0) {
            (totalTradeable, liquidation, userGetProfit) = getTrading(amount, _leverage, side);  
            totalLeverage = totalLeverage.sub((totalTradeable.sub(amount)));
        } else if (side == 1){
            (totalTradeable, liquidation, userGetProfit) = getTrading(amount, _leverage, side);
            totalLeverage = totalLeverage.sub((totalTradeable.sub(amount)));      
        }        
        UpdateFillOrder(_user,  order, amount, price, _leverage, side, _hash, r, vs, liquidation, userGetProfit);
    }

    function UpdateFillOrder(address _user,
        address order, uint256 amount, 
        uint256 price,  
        uint256 _leverage, uint256 side,
        bytes32 _hash, bytes32 r, bytes32 vs, uint256 liquidation, uint256 userGetProfit) internal {
        uint256 filled = getLatestPrice();
        OrderPool storage _orderPool = orderPool[_user][nextOrderID]; 
        _orderPool.id = nextOrderID;
        _orderPool.sender = _user;
        _orderPool.order = order;
        _orderPool.amount = amount;
        _orderPool.filled = filled;
        _orderPool.price = price;
        _orderPool.leverage = _leverage;
        _orderPool.liquidationPeriod = liquidation;
        _orderPool.profit = userGetProfit;
        _orderPool.side = side;
        _orderPool.Hash = _hash;
        _orderPool.r = r;
        _orderPool.vs = vs;
        emit fulfilOrder(
            _orderPool.id,
            _orderPool.sender,
            _orderPool.order,
            _orderPool.amount,
            _orderPool.filled,
            _orderPool.price,
            _orderPool.leverage,
            _orderPool.side
            );
    }

    function cancelOrder(uint256 _id, address _user) external {
        OrderPool memory _orderPool = orderPool[_user][_id]; 
        require(address(_orderPool.sender) == _user);
        require(_orderPool.id == _id); // The order must exist
        orderCancelled[_id] = true;
        uint256 totalLeverage = getReserves();
        (uint256 totalTradeable, , ) = getTrading(_orderPool.amount, _orderPool.leverage, _orderPool.side);
        totalLeverage = totalLeverage.add((totalTradeable.sub(_orderPool.amount))); 
        emit Cancel(
            _id,
            _user,
            _orderPool.order,
            _orderPool.amount,
            _orderPool.filled,
            _orderPool.price,
            _orderPool.leverage,
            _orderPool.side
        );
    }
    
    function createLimitOrder(uint256 _id, address _user, bytes32 _hash, bytes32 r, bytes32 vs) external {
        uint256 totalLeverage = getReserves();   
        address trader = recover_r_vs(_user, _hash, r, vs);
        require(_id > 0 && _id <= nextOrderID, 'Error, wrong id');
        require(!orderFilled[_id], 'Error, order already filled');
        require(!orderCancelled[_id], 'Error, order already cancelled');
        OrderPool memory _orderPool = orderPool[trader][_id]; 
        orderFilled[_orderPool.id] = true;   
        require(traderBalances[token1][trader] >= _orderPool.amount, "Invalid trade amount.");
        if(_orderPool.side == 0) {
            (uint256 totalTradeable, , ) = getTrading(_orderPool.amount, _orderPool.leverage, _orderPool.side);
            if(_orderPool.price <= _orderPool.liquidationPeriod) {
                traderBalances[token1][trader] = traderBalances[token1][trader].sub(_orderPool.amount);
                dstLPRewards(_orderPool.amount);
            } else {
                addToFT(_orderPool.amount, trader);
            }
            totalLeverage = totalLeverage.add((totalTradeable.sub(_orderPool.amount)));                          
        } 
        else if (_orderPool.side == 1){ 
            (uint256 totalTradeable, ,) = getTrading(_orderPool.amount, _orderPool.leverage, _orderPool.side);
            if(_orderPool.price >= _orderPool.liquidationPeriod) {
                traderBalances[token1][trader] = traderBalances[token1][trader].sub(_orderPool.amount);
                dstLPRewards(_orderPool.amount);
            } else {
                addToFT(_orderPool.amount, trader);
            }
             totalLeverage = totalLeverage.add((totalTradeable.sub(_orderPool.amount)));
        }     
        emit _createLimitOrder(
            trader,
            _orderPool.order, 
            _orderPool.amount, 
            _orderPool.filled, 
            _orderPool.price,  
            _orderPool.leverage, 
            _orderPool.side
        );    
    }

    
    function getOrderPool(address _user, uint256 _orderID) 
        external 
        view 
        returns(
            uint256 amount, 
            uint256 filled,
            uint256 price,
            uint256 leverage, 
            uint256 liquidationPeriod, 
            uint256 profit, 
            uint256 side
            ) 
        {
        OrderPool memory _orderPool = orderPool[_user][_orderID];        
        return(
            _orderPool.amount,
            _orderPool.filled,
            _orderPool.price,
            _orderPool.leverage,
            _orderPool.liquidationPeriod,
            _orderPool.profit,
            _orderPool.side
        );
    }

    function addToFT(uint256 _amt, address _trader) internal {
        rewardPool storage rwdp = lpRewards[token0];
        uint256 traderReward = (_amt.sub(_amt.mul(3E18).div(100E18))); 
        traderBalances[token1][_trader] = traderBalances[token1][_trader].add(traderReward);        
        rwdp.lflp = rwdp.lflp.add(traderReward);
        if (rwdp.flp != 0) {
            if(rwdp.flp >= rwdp.lflp) {                
                rwdp.flp = rwdp.flp.sub(rwdp.lflp);
                rwdp.lflp = 0;
            }else {
                rwdp.lflp = rwdp.lflp.sub(rwdp.flp);
                rwdp.flp = 0;
            }
        }
    }

    function dstLPRewards(uint256 _amt) internal {
        rewardPool storage rwdp = lpRewards[token0];
        uint256 oneH = 100E18;        
        uint256 _lpP = _amt.mul(FLPpercentage).div(oneH);
        uint256 rgpTreas = _amt.mul(RGPTreasurerPausePercent).div(oneH);
        uint256 _team = _amt.mul(teamPercent).div(oneH);
        uint256 _lpProvider = _amt.mul(LPPercent).div(oneH);
        rwdp.flp = rwdp.flp.add(_lpP);
        rwdp.rgpTresure = rwdp.rgpTresure.add(rgpTreas);
        rwdp.lp = rwdp.lp.add(_lpProvider);
        rwdp.team = rwdp.team.add(_team);
    }

    function withdrawReward(uint256 _amt, address _recipient, uint256 _point) external {
        require(rigelTreasury == _msgSender(), "Rigel: You are not permitted to perform this operation");
        rewardPool storage rwdp = lpRewards[token0];
        if(_point == 0){
            uint256 _rewards = rwdp.rgpTresure;
            require(_rewards >= _amt, "Rigel: Cant withdraw above reward value");
            IERC20(token1).transfer(_recipient, _amt);
            rwdp.rgpTresure = rwdp.rgpTresure.sub(_amt);
        } else if (_point == 1) {
            uint256 _rewards = rwdp.lp;
            require(_rewards >= _amt, "Rigel: Cant withdraw above reward value");
            IERC20(token1).transfer(_recipient, _amt);
            rwdp.lp = rwdp.lp.sub(_amt);
        } else {
            uint256 _rewards = rwdp.team;
            require(_rewards >= _amt, "Rigel: Cant withdraw above reward value");
            IERC20(token1).transfer(_recipient, _amt);
            rwdp.team = rwdp.team.sub(_amt);
        }
    }

    function updateReward(uint256 _flp, uint256 _tresurer, uint256 _lp, uint256 _team) external {
        require(rigelTreasury == _msgSender(), "Rigel: You are not permitted to perform this operation");
        FLPpercentage = _flp;
        RGPTreasurerPausePercent = _tresurer;
        LPPercent = _lp;
        teamPercent = _team;   
        emit _updateReward(_msgSender(), _flp, _tresurer, _lp, _team);     
    }

    function currentReward() external view returns(uint256, uint256, uint256, uint256, uint256) {
        rewardPool memory pool = lpRewards[token0];
        return(pool.flp, pool.rgpTresure, pool.lp, pool.team, pool.lflp);
    }


}

contract routRigelProtocol is IRGPRoutV1{    
    address public Factory;
    address public owner;    

    uint256 public nextOrderID;
            
    constructor(address _factory) {
        owner = msg.sender;
        Factory = _factory;
    }  

    modifier tokenExist(address ticker) {
        require(ticker != address(0), "token doesnt exist");
        _;
    }  

    mapping(address => mapping(uint256 => Order[])) orderBook;
    
    // to add liquidity msg.sender need to approve router contract address from token B
    function addLiquidity(address tokenA, address tokenB, address aggregator, uint256 amount, address _to) external returns(uint256 liquidity) {
        // create the pair if it doesn't exist yet
        if (rigelfutureExchangeInterface(Factory).getPair(tokenA, tokenB) == address(0)) {
            rigelfutureExchangeInterface(Factory).createPair(tokenA, tokenB, aggregator);
        }
        address pair = rigelfutureExchangeInterface(Factory).getPair(tokenA, tokenB);
        RGPExchangeERC20(tokenB).transferFrom(msg.sender, pair, amount);
        IRGPfutureExchange(pair).mint(_to, amount);
        return liquidity;        
    }
    
    // to remove liquidity msg.sender need to approve flp token address (pair contract) not the router contract
    function removeLiquidity(address tokenA, address tokenB, uint256 amount, address _to) external {
        address pair = rigelfutureExchangeInterface(Factory).getPair(tokenA, tokenB);
        RGPExchangeERC20(pair).transferFrom(msg.sender, pair, amount );
        IRGPfutureExchange(pair).burn(_to, amount);
    }
    
    //approve flp token address before depositing funds
    function deposit(address tokenA, address tokenB, uint256 amount) external tokenExist(tokenB){
        address pair = rigelfutureExchangeInterface(Factory).getPair(tokenA, tokenB);
        IRGPfutureExchange(pair).updateTraderBalance(msg.sender, amount, true);
    }
    
    function withdraw( address tokenA, address tokenB, uint256 amount) external tokenExist(tokenA){
        address pair = rigelfutureExchangeInterface(Factory).getPair(tokenA, tokenB);
        IRGPfutureExchange(pair).updateTraderBalance(msg.sender, amount, false);
    }
    
    function fillOrder(
        address tokenA, address tokenB, 
        uint256 amount,
        uint256 price, uint256 _leverage, 
        SIDE _side,        
        bytes32 hash, bytes32 r, bytes32 vs
        ) external tokenExist(tokenA) {
        address pair = rigelfutureExchangeInterface(Factory).getPair(tokenA, tokenB);
        IRGPfutureExchange(pair).fillOrder(msg.sender, tokenA, amount, price, _leverage, uint256(_side), hash, r,vs);
        Order[] storage orders = orderBook[tokenA][uint256(_side)];
        orders.push(Order(
            uint256(_side),
            address(this),
            amount,
            price,
            block.timestamp,
            nextOrderID
        ));
        nextOrderID ++;
    }

    function cancelOrder(address tokenA, address tokenB, uint256 _id) external {
        address pair = rigelfutureExchangeInterface(Factory).getPair(tokenA, tokenB);
        IRGPfutureExchange(pair).cancelOrder(_id, msg.sender);
    }

    function createLimitOrder(
        address tokenA, 
        address tokenB, 
        uint256 _id, 
        address _user, 
        bytes32 _hash, 
        bytes32 r, 
        bytes32 vs) external{
        address pair = rigelfutureExchangeInterface(Factory).getPair(tokenA, tokenB);
        IRGPfutureExchange(pair).createLimitOrder(_id, _user, _hash, r, vs);
    }

    function updateReward(address tokenA, address tokenB, uint256 _flp, uint256 _tresurer, uint256 _lp, uint256 _team) external {
        address pair = rigelfutureExchangeInterface(Factory).getPair(tokenA, tokenB);
        IRGPfutureExchange(pair).updateReward(_flp, _tresurer, _lp, _team);
    }
    
    function getAmountOut(
        address tokenA, address tokenB,
        uint256 amount, 
        uint256 _leverage, SIDE side
        ) external view returns(uint256 totalTradeable, uint256 liquidation, uint256 userGetProfit) {
        address pair = rigelfutureExchangeInterface(Factory).getPair(tokenA, tokenB);
        (totalTradeable, liquidation, userGetProfit) = IRGPfutureExchange(pair).getTrading( amount, _leverage, uint256(side) );

        return (totalTradeable, liquidation, userGetProfit);
    }
    
    function traderBalance(address tokenA, address tokenB, address _trader) external view returns(uint256 userBalance) {
        address pair = rigelfutureExchangeInterface(Factory).getPair(tokenA, tokenB);
        userBalance = IRGPfutureExchange(pair).getTraderBalance(_trader);
        return userBalance;
    }

    function FLPRewards(address tokenA, address tokenB, address user) external view returns(uint256  reward) {
        address pair = rigelfutureExchangeInterface(Factory).getPair(tokenA, tokenB);
        reward = IRGPfutureExchange(pair).lpShare(user);
        return reward;
    }

    function getAllPoolReward(address tokenA, address tokenB) external view returns(uint256 _flp, uint256 _tresurer, uint256 _lp, uint256 _team, uint256 _llevP) {
        address pair = rigelfutureExchangeInterface(Factory).getPair(tokenA, tokenB);
        (_flp, _tresurer, _lp, _team, _llevP) = IRGPfutureExchange(pair).currentReward();
        return (_flp, _tresurer, _lp, _team, _llevP);
    }

    function getUserPoolD(address tokenA, address tokenB, address _user, uint256 _orderID) external view returns(
        address order,
        uint256 amount, 
        uint256 filled,
        uint256 price,
        uint256 leverage, 
        uint256 liquidationPeriod, 
        uint256 profit, 
        uint256 side
        ) 
    {
        address pair = rigelfutureExchangeInterface(Factory).getPair(tokenA, tokenB);
        
        // stack too deep.
        (amount, filled, price, leverage, liquidationPeriod, profit, side) 
        = IRGPfutureExchange(pair).getOrderPool(_user, _orderID);
        return (tokenB, amount, filled, price, leverage, liquidationPeriod, profit, side);
        
    }

    function orderCancelled(address tokenA, address tokenB, uint256 orderID) external view returns(bool cancelled) {
        address pair = rigelfutureExchangeInterface(Factory).getPair(tokenA, tokenB);
        cancelled = IRGPfutureExchange(pair).orderCancelled(orderID);
    }

    function orderFilled(address tokenA, address tokenB, uint256 orderID) external view returns(bool filled) {
        address pair = rigelfutureExchangeInterface(Factory).getPair(tokenA, tokenB);
        filled = IRGPfutureExchange(pair).orderFilled(orderID);
    }
    
}