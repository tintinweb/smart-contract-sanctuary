pragma solidity ^0.6.4;

import "@pie-dao/proxy/contracts/PProxyPausable.sol";

import "../interfaces/IBFactory.sol";
import "../interfaces/IBPool.sol";
import "../interfaces/IERC20.sol";
import "../Ownable.sol";
import "../interfaces/IPV2SmartPool.sol";
import "../libraries/LibSafeApprove.sol";

contract PProxiedFactory is Ownable {
  using LibSafeApprove for IERC20;

  IBFactory public balancerFactory;
  address public smartPoolImplementation;
  mapping(address => bool) public isPool;
  address[] public pools;

  event SmartPoolCreated(address indexed poolAddress, string name, string symbol);

  function init(address _balancerFactory, address _implementation) public {
    require(smartPoolImplementation == address(0), "Already initialised");
    _setOwner(msg.sender);
    balancerFactory = IBFactory(_balancerFactory);

    smartPoolImplementation = _implementation;
  }

  function setImplementation(address _implementation) external onlyOwner {
    smartPoolImplementation = _implementation;
  }

  function newProxiedSmartPool(
    string memory _name,
    string memory _symbol,
    uint256 _initialSupply,
    address[] memory _tokens,
    uint256[] memory _amounts,
    uint256[] memory _weights,
    uint256 _cap
  ) public onlyOwner returns (address) {
    // Deploy proxy contract
    PProxyPausable proxy = new PProxyPausable();

    // Setup proxy
    proxy.setImplementation(smartPoolImplementation);
    proxy.setPauzer(msg.sender);
    proxy.setProxyOwner(msg.sender);

    // Setup balancer pool
    address balancerPoolAddress = balancerFactory.newBPool();
    IBPool bPool = IBPool(balancerPoolAddress);

    for (uint256 i = 0; i < _tokens.length; i++) {
      IERC20 token = IERC20(_tokens[i]);
      // Transfer tokens to this contract
      token.transferFrom(msg.sender, address(this), _amounts[i]);
      // Approve the balancer pool
      token.safeApprove(balancerPoolAddress, uint256(-1));
      // Bind tokens
      bPool.bind(_tokens[i], _amounts[i], _weights[i]);
    }
    bPool.setController(address(proxy));

    // Setup smart pool
    IPV2SmartPool smartPool = IPV2SmartPool(address(proxy));

    smartPool.init(balancerPoolAddress, _name, _symbol, _initialSupply);
    smartPool.setCap(_cap);
    smartPool.setPublicSwapSetter(msg.sender);
    smartPool.setTokenBinder(msg.sender);
    smartPool.setController(msg.sender);
    smartPool.approveTokens();

    isPool[address(smartPool)] = true;
    pools.push(address(smartPool));

    emit SmartPoolCreated(address(smartPool), _name, _symbol);

    smartPool.transfer(msg.sender, _initialSupply);

    return address(smartPool);
  }
}

pragma solidity ^0.6.2;

import "./PProxy.sol";

contract PProxyPausable is PProxy {

    bytes32 constant PAUSED_SLOT = keccak256(abi.encodePacked("PAUSED_SLOT"));
    bytes32 constant PAUZER_SLOT = keccak256(abi.encodePacked("PAUZER_SLOT"));

    constructor() PProxy() public {
        setAddress(PAUZER_SLOT, msg.sender);
    }

    modifier onlyPauzer() {
        require(msg.sender == readAddress(PAUZER_SLOT), "PProxyPausable.onlyPauzer: msg sender not pauzer");
        _;
    }

    modifier notPaused() {
        require(!readBool(PAUSED_SLOT), "PProxyPausable.notPaused: contract is paused");
        _;
    }

    function getPauzer() public view returns (address) {
        return readAddress(PAUZER_SLOT);
    }

    function setPauzer(address _newPauzer) public onlyProxyOwner{
        setAddress(PAUZER_SLOT, _newPauzer);
    }

    function renouncePauzer() public onlyPauzer {
        setAddress(PAUZER_SLOT, address(0));
    }

    function getPaused() public view returns (bool) {
        return readBool(PAUSED_SLOT);
    }

    function setPaused(bool _value) public onlyPauzer {
        setBool(PAUSED_SLOT, _value);
    }

    function internalFallback() internal virtual override notPaused {
        super.internalFallback();
    }

}

pragma solidity ^0.6.2;

import "./PProxyStorage.sol";

contract PProxy is PProxyStorage {

    bytes32 constant IMPLEMENTATION_SLOT = keccak256(abi.encodePacked("IMPLEMENTATION_SLOT"));
    bytes32 constant OWNER_SLOT = keccak256(abi.encodePacked("OWNER_SLOT"));

    modifier onlyProxyOwner() {
        require(msg.sender == readAddress(OWNER_SLOT), "PProxy.onlyProxyOwner: msg sender not owner");
        _;
    }

    constructor () public {
        setAddress(OWNER_SLOT, msg.sender);
    }

    function getProxyOwner() public view returns (address) {
       return readAddress(OWNER_SLOT);
    }

    function setProxyOwner(address _newOwner) onlyProxyOwner public {
        setAddress(OWNER_SLOT, _newOwner);
    }

    function getImplementation() public view returns (address) {
        return readAddress(IMPLEMENTATION_SLOT);
    }

    function setImplementation(address _newImplementation) onlyProxyOwner public {
        setAddress(IMPLEMENTATION_SLOT, _newImplementation);
    }


    fallback () external payable {
       return internalFallback();
    }

    function internalFallback() internal virtual {
        address contractAddr = readAddress(IMPLEMENTATION_SLOT);
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), contractAddr, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }

}

pragma solidity ^0.6.2;

contract PProxyStorage {

    function readString(bytes32 _key) public view returns(string memory) {
        return bytes32ToString(storageRead(_key));
    }

    function setString(bytes32 _key, string memory _value) internal {
        storageSet(_key, stringToBytes32(_value));
    }

    function readBool(bytes32 _key) public view returns(bool) {
        return storageRead(_key) == bytes32(uint256(1));
    }

    function setBool(bytes32 _key, bool _value) internal {
        if(_value) {
            storageSet(_key, bytes32(uint256(1)));
        } else {
            storageSet(_key, bytes32(uint256(0)));
        }
    }

    function readAddress(bytes32 _key) public view returns(address) {
        return bytes32ToAddress(storageRead(_key));
    }

    function setAddress(bytes32 _key, address _value) internal {
        storageSet(_key, addressToBytes32(_value));
    }

    function storageRead(bytes32 _key) public view returns(bytes32) {
        bytes32 value;
        //solium-disable-next-line security/no-inline-assembly
        assembly {
            value := sload(_key)
        }
        return value;
    }

    function storageSet(bytes32 _key, bytes32 _value) internal {
        // targetAddress = _address;  // No!
        bytes32 implAddressStorageKey = _key;
        //solium-disable-next-line security/no-inline-assembly
        assembly {
            sstore(implAddressStorageKey, _value)
        }
    }

    function bytes32ToAddress(bytes32 _value) public pure returns(address) {
        return address(uint160(uint256(_value)));
    }

    function addressToBytes32(address _value) public pure returns(bytes32) {
        return bytes32(uint256(_value));
    }

    function stringToBytes32(string memory _value) public pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(_value);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(_value, 32))
        }
    }

    function bytes32ToString(bytes32 _value) public pure returns (string memory) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint256 j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(_value) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (uint256 j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }
}

pragma solidity ^0.6.4;

interface IBFactory {
  function newBPool() external returns (address);
}

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is disstributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.6.4;

interface IBPool {
  function isBound(address token) external view returns (bool);

  function getBalance(address token) external view returns (uint256);

  function rebind(
    address token,
    uint256 balance,
    uint256 denorm
  ) external;

  function setSwapFee(uint256 swapFee) external;

  function setPublicSwap(bool _public) external;

  function bind(
    address token,
    uint256 balance,
    uint256 denorm
  ) external;

  function unbind(address token) external;

  function getDenormalizedWeight(address token) external view returns (uint256);

  function getTotalDenormalizedWeight() external view returns (uint256);

  function getCurrentTokens() external view returns (address[] memory);

  function setController(address manager) external;

  function isPublicSwap() external view returns (bool);

  function getSwapFee() external view returns (uint256);

  function gulp(address token) external;

  function calcPoolOutGivenSingleIn(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 poolSupply,
    uint256 totalWeight,
    uint256 tokenAmountIn,
    uint256 swapFee
  ) external pure returns (uint256 poolAmountOut);

  function calcSingleInGivenPoolOut(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 poolSupply,
    uint256 totalWeight,
    uint256 poolAmountOut,
    uint256 swapFee
  ) external pure returns (uint256 tokenAmountIn);

  function calcSingleOutGivenPoolIn(
    uint256 tokenBalanceOut,
    uint256 tokenWeightOut,
    uint256 poolSupply,
    uint256 totalWeight,
    uint256 poolAmountIn,
    uint256 swapFee
  ) external pure returns (uint256 tokenAmountOut);

  function calcPoolInGivenSingleOut(
    uint256 tokenBalanceOut,
    uint256 tokenWeightOut,
    uint256 poolSupply,
    uint256 totalWeight,
    uint256 tokenAmountOut,
    uint256 swapFee
  ) external pure returns (uint256 poolAmountIn);
}

pragma solidity ^0.6.4;

interface IERC20 {
  event Approval(address indexed _src, address indexed _dst, uint256 _amount);
  event Transfer(address indexed _src, address indexed _dst, uint256 _amount);

  function totalSupply() external view returns (uint256);

  function balanceOf(address _whom) external view returns (uint256);

  function allowance(address _src, address _dst) external view returns (uint256);

  function approve(address _dst, uint256 _amount) external returns (bool);

  function transfer(address _dst, uint256 _amount) external returns (bool);

  function transferFrom(
    address _src,
    address _dst,
    uint256 _amount
  ) external returns (bool);
}

pragma solidity 0.6.4;


import {OwnableStorage as OStorage} from "./storage/OwnableStorage.sol"; 

contract Ownable {
  event OwnerChanged(address indexed previousOwner, address indexed newOwner);

  modifier onlyOwner() {
    require(msg.sender == OStorage.load().owner, "Ownable.onlyOwner: msg.sender not owner");
    _;
  }

  /**
        @notice Transfer ownership to a new address
        @param _newOwner Address of the new owner
    */
  function transferOwnership(address _newOwner) external onlyOwner {
    _setOwner(_newOwner);
  }

  /**
        @notice Internal method to set the owner
        @param _newOwner Address of the new owner
    */
  function _setOwner(address _newOwner) internal {
    OStorage.StorageStruct storage s = OStorage.load();
    emit OwnerChanged(s.owner, _newOwner);
    s.owner = _newOwner;
  }

}

pragma solidity 0.6.4;

library OwnableStorage {
  bytes32 public constant oSlot = keccak256("Ownable.storage.location");
  struct StorageStruct {
    address owner;
  }

  /**
        @notice Load pool token storage
        @return s Storage pointer to the pool token struct
    */
  function load() internal pure returns (StorageStruct storage s) {
    bytes32 loc = oSlot;
    assembly {
      s_slot := loc
    }
  }
}

pragma experimental ABIEncoderV2;
pragma solidity ^0.6.4;

import "../interfaces/IERC20.sol";
import {PV2SmartPoolStorage as P2Storage} from "../storage/PV2SmartPoolStorage.sol";

interface IPV2SmartPool is IERC20 {
  /**
    @notice Initialise smart pool. Can only be called once
    @param _bPool Address of the underlying bPool
    @param _name Token name
    @param _symbol Token symbol (ticker)
    @param _initialSupply Initial token supply
  */
  function init(
    address _bPool,
    string calldata _name,
    string calldata _symbol,
    uint256 _initialSupply
  ) external;

  /**
    @notice Set the address that can set public swap enabled or disabled. 
    Can only be called by the controller
    @param _swapSetter Address of the new swapSetter
  */
  function setPublicSwapSetter(address _swapSetter) external;

  /**
    @notice Set the address that can bind, unbind and rebind tokens.
    Can only be called by the controller
    @param _tokenBinder Address of the new token binder
  */
  function setTokenBinder(address _tokenBinder) external;

  /**
    @notice Enable or disable trading on the underlying balancer pool.
    Can only be called by the public swap setter
    @param _public Wether public swap is enabled or not
  */
  function setPublicSwap(bool _public) external;

  /**
    @notice Set the swap fee. Can only be called by the controller
    @param _swapFee The new swap fee. 10**18 == 100%. Max 10%
  */
  function setSwapFee(uint256 _swapFee) external;

  /**
    @notice Set the totalSuppy cap. Can only be called by the controller
    @param _cap New cap
  */
  function setCap(uint256 _cap) external;

  /**
    @notice Set the annual fee. Can only be called by the controller
    @param _newFee new fee 10**18 == 100% per 365 days. Max 10%
  */
  function setAnnualFee(uint256 _newFee) external;

  /**
    @notice Charge the outstanding annual fee
  */
  function chargeOutstandingAnnualFee() external;

  /**
    @notice Set the address that receives the annual fee. Can only be called by the controller
  */
  function setFeeRecipient(address _newRecipient) external;

  /**
    @notice Set the controller address. Can only be called by the current address
    @param _controller Address of the new controller
  */
  function setController(address _controller) external;

  /**
    @notice Set the circuit breaker address. Can only be called by the controller
    @param _newCircuitBreaker Address of the new circuit breaker
  */
  function setCircuitBreaker(address _newCircuitBreaker) external;

  /**
    @notice Enable or disable joining and exiting
    @param _newValue enabled or not
  */
  function setJoinExitEnabled(bool _newValue) external;

  /**
    @notice Trip the circuit breaker which disabled exit, join and swaps
  */
  function tripCircuitBreaker() external;

  /**
    @notice Update the weight of a token. Can only be called by the controller
    @param _token Token to adjust the weight of
    @param _newWeight New denormalized weight
  */
  function updateWeight(address _token, uint256 _newWeight) external;

  /** 
    @notice Gradually adjust the weights of a token. Can only be called by the controller
    @param _newWeights Target weights
    @param _startBlock Block to start weight adjustment
    @param _endBlock Block to finish weight adjustment
  */
  function updateWeightsGradually(
    uint256[] calldata _newWeights,
    uint256 _startBlock,
    uint256 _endBlock
  ) external;

  /**
    @notice Poke the weight adjustment
  */
  function pokeWeights() external;

  /**
    @notice Apply the adding of a token. Can only be called by the controller
  */
  function applyAddToken() external;

  /** 
    @notice Commit a token to be added. Can only be called by the controller
    @param _token Address of the token to add
    @param _balance Amount of token to add
    @param _denormalizedWeight Denormalized weight
  */
  function commitAddToken(
    address _token,
    uint256 _balance,
    uint256 _denormalizedWeight
  ) external;

  /**
    @notice Remove a token from the smart pool. Can only be called by the controller
    @param _token Address of the token to remove
  */
  function removeToken(address _token) external;

  /**
    @notice Approve bPool to pull tokens from smart pool
  */
  function approveTokens() external;

  /** 
    @notice Mint pool tokens, locking underlying assets
    @param _amount Amount of pool tokens
  */
  function joinPool(uint256 _amount) external;

  /**
    @notice Mint pool tokens, locking underlying assets. With front running protection
    @param _amount Amount of pool tokens
    @param _maxAmountsIn Maximum amounts of underlying assets
  */
  function joinPool(uint256 _amount, uint256[] calldata _maxAmountsIn) external;

  /**
    @notice Burn pool tokens and redeem underlying assets
    @param _amount Amount of pool tokens to burn
  */
  function exitPool(uint256 _amount) external;

  /**
    @notice Burn pool tokens and redeem underlying assets. With front running protection
    @param _amount Amount of pool tokens to burn
    @param _minAmountsOut Minimum amounts of underlying assets
  */
  function exitPool(uint256 _amount, uint256[] calldata _minAmountsOut) external;

  /**
    @notice Join with a single asset, given amount of token in
    @param _token Address of the underlying token to deposit
    @param _amountIn Amount of underlying asset to deposit
    @param _minPoolAmountOut Minimum amount of pool tokens to receive
  */
  function joinswapExternAmountIn(
    address _token,
    uint256 _amountIn,
    uint256 _minPoolAmountOut
  ) external returns (uint256);

  /**
    @notice Join with a single asset, given amount pool out
    @param _token Address of the underlying token to deposit
    @param _amountOut Amount of pool token to mint
    @param _maxAmountIn Maximum amount of underlying asset
  */
  function joinswapPoolAmountOut(
    address _token,
    uint256 _amountOut,
    uint256 _maxAmountIn
  ) external returns (uint256 tokenAmountIn);

  /**
    @notice Exit with a single asset, given pool amount in
    @param _token Address of the underlying token to withdraw
    @param _poolAmountIn Amount of pool token to burn
    @param _minAmountOut Minimum amount of underlying asset to withdraw
  */
  function exitswapPoolAmountIn(
    address _token,
    uint256 _poolAmountIn,
    uint256 _minAmountOut
  ) external returns (uint256 tokenAmountOut);

  /**
    @notice Exit with a single asset, given token amount out
    @param _token Address of the underlying token to withdraw
    @param _tokenAmountOut Amount of underlying asset to withdraw
    @param _maxPoolAmountIn Maximimum pool amount to burn
  */
  function exitswapExternAmountOut(
    address _token,
    uint256 _tokenAmountOut,
    uint256 _maxPoolAmountIn
  ) external returns (uint256 poolAmountIn);

  /**
    @notice Exit pool, ignoring some tokens
    @param _amount Amount of pool tokens to burn
    @param _lossTokens Addresses of tokens to ignore
  */
  function exitPoolTakingloss(uint256 _amount, address[] calldata _lossTokens) external;

  /**
    @notice Bind(add) a token to the pool
    @param _token Address of the token to bind
    @param _balance Amount of token to bind
    @param _denorm Denormalised weight
  */
  function bind(
    address _token,
    uint256 _balance,
    uint256 _denorm
  ) external;

  /**
    @notice Rebind(adjust) a token's weight or amount
    @param _token Address of the token to rebind
    @param _balance New token amount
    @param _denorm New denormalised weight
  */
  function rebind(
    address _token,
    uint256 _balance,
    uint256 _denorm
  ) external;

  /**
    @notice Unbind(remove) a token from the smart pool
    @param _token Address of the token to unbind
  */
  function unbind(address _token) external;

  /**
    @notice Get the controller address
    @return Address of the controller
  */
  function getController() external view returns (address);

  /**
    @notice Get the public swap setter address
    @return Address of the public swap setter
  */
  function getPublicSwapSetter() external view returns (address);

  /**
    @notice Get the address of the token binder
    @return Token binder address
  */
  function getTokenBinder() external view returns (address);

  /**
    @notice Get the circuit breaker address
    @return Circuit breaker address
  */
  function getCircuitBreaker() external view returns (address);

  /**
    @notice Get if public trading is enabled or not
    @return Enabled or not
  */
  function isPublicSwap() external view returns (bool);

  /** 
    @notice Get the current tokens in the smart pool
    @return Addresses of the tokens in the smart pool
  */
  function getTokens() external view returns (address[] memory);

  /**
    @notice Get the totalSupply cap
    @return The totalSupply cap
  */
  function getCap() external view returns (uint256);

  /**
    @notice Get the annual fee
    @return the annual fee
  */
  function getAnnualFee() external view returns (uint256);

  /**
    @notice Get the address receiving the fees
    @return Fee recipient address
  */
  function getFeeRecipient() external view returns (address);

  /**
    @notice Get the denormalized weight of a token
    @param _token Address of the token
    @return The denormalised weight of the token
  */
  function getDenormalizedWeight(address _token) external view returns (uint256);

  /**
    @notice Get all denormalized weights
    @return weights Denormalized weights
  */
  function getDenormalizedWeights() external view returns (uint256[] memory weights);

  /**
    @notice Get the target weights
    @return weights Target weights
  */
  function getNewWeights() external view returns (uint256[] memory weights);

  /**
    @notice Get weights at start of weight adjustment
    @return weights Start weights
  */
  function getStartWeights() external view returns (uint256[] memory weights);

  /**
    @notice Get start block of weight adjustment
    @return Start block
  */
  function getStartBlock() external view returns (uint256);

  /**
    @notice Get end block of weight adjustment
    @return End block
  */
  function getEndBlock() external view returns (uint256);

  /**
    @notice Get new token being added
    @return New token
  */
  function getNewToken() external view returns (P2Storage.NewToken memory);

  /**
    @notice Get if joining and exiting is enabled
    @return Enabled or not
  */
  function getJoinExitEnabled() external view returns (bool);

  /**
    @notice Get the underlying Balancer pool address
    @return Address of the underlying Balancer pool
  */
  function getBPool() external view returns (address);

  /**
    @notice Get the swap fee
    @return Swap fee
  */
  function getSwapFee() external view returns (uint256);

  /**
    @notice Not supported
  */
  function finalizeSmartPool() external view;

  /**
    @notice Not supported
  */
  function createPool(uint256 initialSupply) external view;

  /**
    @notice Calculate the amount of underlying needed to mint a certain amount
    @return tokens Addresses of the underlying tokens
    @return amounts Amounts of the underlying tokens
  */
  function calcTokensForAmount(uint256 _amount)
    external
    view
    returns (address[] memory tokens, uint256[] memory amounts);

  /**
    @notice Calculate the amount of pool tokens out given underlying in
    @param _token Underlying asset to deposit
    @param _amount Amount of underlying asset to deposit
    @return Pool amount out
  */
  function calcPoolOutGivenSingleIn(address _token, uint256 _amount)
    external
    view
    returns (uint256);

  /**
    @notice Calculate underlying deposit amount given pool amount out
    @param _token Underlying token to deposit
    @param _amount Amount of pool out
    @return Underlying asset deposit amount
  */
  function calcSingleInGivenPoolOut(address _token, uint256 _amount)
    external
    view
    returns (uint256);

  /**
    @notice Calculate underlying amount out given pool amount in
    @param _token Address of the underlying token to withdraw
    @param _amount Pool amount to burn
    @return Amount of underlying to withdraw
  */
  function calcSingleOutGivenPoolIn(address _token, uint256 _amount)
    external
    view
    returns (uint256);

  /**
    @notice Calculate pool amount in given underlying input
    @param _token Address of the underlying token to withdraw
    @param _amount Underlying output amount
    @return Pool burn amount
  */
  function calcPoolInGivenSingleOut(address _token, uint256 _amount)
    external
    view
    returns (uint256);
}

pragma solidity ^0.6.4;

library PV2SmartPoolStorage {
  bytes32 public constant pasSlot = keccak256("PV2SmartPoolStorage.storage.location");

  struct StorageStruct {
    uint256 startBlock;
    uint256 endBlock;
    uint256[] startWeights;
    uint256[] newWeights;
    NewToken newToken;
    bool joinExitEnabled;
    uint256 annualFee;
    uint256 lastAnnualFeeClaimed;
    address feeRecipient;
    address circuitBreaker;
  }

  struct NewToken {
    address addr;
    bool isCommitted;
    uint256 balance;
    uint256 denorm;
    uint256 commitBlock;
  }

  function load() internal pure returns (StorageStruct storage s) {
    bytes32 loc = pasSlot;
    assembly {
      s_slot := loc
    }
  }
}

pragma solidity 0.6.4;

import "../interfaces/IERC20.sol";

library LibSafeApprove {
    function safeApprove(IERC20 _token, address _spender, uint256 _amount) internal {
        uint256 currentAllowance = _token.allowance(address(this), _spender);

        // Do nothing if allowance is already set to this value
        if(currentAllowance == _amount) {
            return;
        }

        // If approval is not zero reset it to zero first
        if(currentAllowance != 0) {
            _token.approve(_spender, 0);
        }

        // do the actual approval
        _token.approve(_spender, _amount);
    }
}

pragma solidity ^0.6.4;

import {PBasicSmartPoolStorage as PBStorage} from "../storage/PBasicSmartPoolStorage.sol";
import {PV2SmartPoolStorage as P2Storage} from "../storage/PV2SmartPoolStorage.sol";
import {PCTokenStorage as PCStorage} from "../storage/PCTokenStorage.sol";
import {LibConst as constants} from "./LibConst.sol";
import "./LibSafeApprove.sol";
import "./LibPoolToken.sol";
import "./Math.sol";

library LibAddRemoveToken {
  using Math for uint256;
  using LibSafeApprove for IERC20;

  function applyAddToken() external {
    P2Storage.StorageStruct storage ws = P2Storage.load();
    PBStorage.StorageStruct storage s = PBStorage.load();

    require(ws.newToken.isCommitted, "ERR_NO_TOKEN_COMMIT");

    uint256 totalSupply = PCStorage.load().totalSupply;

    uint256 poolShares = totalSupply.bmul(ws.newToken.denorm).bdiv(
      s.bPool.getTotalDenormalizedWeight()
    );

    ws.newToken.isCommitted = false;

    require(
      IERC20(ws.newToken.addr).transferFrom(msg.sender, address(this), ws.newToken.balance),
      "ERR_ERC20_FALSE"
    );

    // Cancel potential weight adjustment process.
    ws.startBlock = 0;

    // Approves bPool to pull from this controller
    IERC20(ws.newToken.addr).safeApprove(address(s.bPool), uint256(-1));
    s.bPool.bind(ws.newToken.addr, ws.newToken.balance, ws.newToken.denorm);
    LibPoolToken._mint(msg.sender, poolShares);
  }

  function commitAddToken(
    address _token,
    uint256 _balance,
    uint256 _denormalizedWeight
  ) external {
    P2Storage.StorageStruct storage ws = P2Storage.load();
    PBStorage.StorageStruct storage s = PBStorage.load();

    require(!s.bPool.isBound(_token), "ERR_IS_BOUND");
    require(_denormalizedWeight <= constants.MAX_WEIGHT, "ERR_WEIGHT_ABOVE_MAX");
    require(_denormalizedWeight >= constants.MIN_WEIGHT, "ERR_WEIGHT_BELOW_MIN");
    require(
      s.bPool.getTotalDenormalizedWeight().badd(_denormalizedWeight) <= constants.MAX_TOTAL_WEIGHT,
      "ERR_MAX_TOTAL_WEIGHT"
    );

    ws.newToken.addr = _token;
    ws.newToken.balance = _balance;
    ws.newToken.denorm = _denormalizedWeight;
    ws.newToken.commitBlock = block.number;
    ws.newToken.isCommitted = true;
  }

  function removeToken(address _token) external {
    P2Storage.StorageStruct storage ws = P2Storage.load();
    PBStorage.StorageStruct storage s = PBStorage.load();

    uint256 totalSupply = PCStorage.load().totalSupply;

    // poolShares = totalSupply * tokenWeight / totalWeight
    uint256 poolShares = totalSupply.bmul(s.bPool.getDenormalizedWeight(_token)).bdiv(
      s.bPool.getTotalDenormalizedWeight()
    );

    // this is what will be unbound from the pool
    // Have to get it before unbinding
    uint256 balance = s.bPool.getBalance(_token);

    // Cancel potential weight adjustment process.
    ws.startBlock = 0;

    // Unbind and get the tokens out of balancer pool
    s.bPool.unbind(_token);

    require(IERC20(_token).transfer(msg.sender, balance), "ERR_ERC20_FALSE");

    LibPoolToken._burn(msg.sender, poolShares);
  }
}

pragma solidity ^0.6.4;

import "../interfaces/IBPool.sol";

library PBasicSmartPoolStorage {
  bytes32 public constant pbsSlot = keccak256("PBasicSmartPool.storage.location");

  struct StorageStruct {
    IBPool bPool;
    address controller;
    address publicSwapSetter;
    address tokenBinder;
  }

  /**
        @notice Load PBasicPool storage
        @return s Pointer to the storage struct
    */
  function load() internal pure returns (StorageStruct storage s) {
    bytes32 loc = pbsSlot;
    assembly {
      s_slot := loc
    }
  }
}

pragma solidity 0.6.4;

library PCTokenStorage {
  bytes32 public constant ptSlot = keccak256("PCToken.storage.location");
  struct StorageStruct {
    string name;
    string symbol;
    uint256 totalSupply;
    mapping(address => uint256) balance;
    mapping(address => mapping(address => uint256)) allowance;
  }

  /**
        @notice Load pool token storage
        @return s Storage pointer to the pool token struct
    */
  function load() internal pure returns (StorageStruct storage s) {
    bytes32 loc = ptSlot;
    assembly {
      s_slot := loc
    }
  }
}

pragma solidity ^0.6.4;

library LibConst {
  uint256 internal constant MIN_WEIGHT = 10**18;
  uint256 internal constant MAX_WEIGHT = 10**18 * 50;
  uint256 internal constant MAX_TOTAL_WEIGHT = 10**18 * 50;
  uint256 internal constant MIN_BALANCE = (10**18) / (10**12);
}

pragma solidity ^0.6.4;

import {PCTokenStorage as PCStorage} from "../storage/PCTokenStorage.sol";
import "../libraries/Math.sol";
import "../interfaces/IERC20.sol";

library LibPoolToken {
  using Math for uint256;

  event Transfer(address indexed _src, address indexed _dst, uint256 _amount);

  function _mint(address _to, uint256 _amount) internal {
    PCStorage.StorageStruct storage s = PCStorage.load();
    s.balance[_to] = s.balance[_to].badd(_amount);
    s.totalSupply = s.totalSupply.badd(_amount);
    emit Transfer(address(0), _to, _amount);
  }

  function _burn(address _from, uint256 _amount) internal {
    PCStorage.StorageStruct storage s = PCStorage.load();
    require(s.balance[_from] >= _amount, "ERR_INSUFFICIENT_BAL");
    s.balance[_from] = s.balance[_from].bsub(_amount);
    s.totalSupply = s.totalSupply.bsub(_amount);
    emit Transfer(_from, address(0), _amount);
  }
}

pragma solidity ^0.6.4;

library Math {
  uint256 internal constant BONE = 10**18;
  uint256 internal constant MIN_BPOW_BASE = 1 wei;
  uint256 internal constant MAX_BPOW_BASE = (2 * BONE) - 1 wei;
  uint256 internal constant BPOW_PRECISION = BONE / 10**10;

  function btoi(uint256 a) internal pure returns (uint256) {
    return a / BONE;
  }

  // Add two numbers together checking for overflows
  function badd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "ERR_ADD_OVERFLOW");
    return c;
  }

  // subtract two numbers and return diffecerence when it underflows
  function bsubSign(uint256 a, uint256 b) internal pure returns (uint256, bool) {
    if (a >= b) {
      return (a - b, false);
    } else {
      return (b - a, true);
    }
  }

  // Subtract two numbers checking for underflows
  function bsub(uint256 a, uint256 b) internal pure returns (uint256) {
    (uint256 c, bool flag) = bsubSign(a, b);
    require(!flag, "ERR_SUB_UNDERFLOW");
    return c;
  }

  // Multiply two 18 decimals numbers
  function bmul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c0 = a * b;
    require(a == 0 || c0 / a == b, "ERR_MUL_OVERFLOW");
    uint256 c1 = c0 + (BONE / 2);
    require(c1 >= c0, "ERR_MUL_OVERFLOW");
    uint256 c2 = c1 / BONE;
    return c2;
  }

  // Overflow protected multiplication
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "Math: multiplication overflow");

    return c;
  }

  // Divide two 18 decimals numbers
  function bdiv(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "ERR_DIV_ZERO");
    uint256 c0 = a * BONE;
    require(a == 0 || c0 / a == BONE, "ERR_DIV_INTERNAL"); // bmul overflow
    uint256 c1 = c0 + (b / 2);
    require(c1 >= c0, "ERR_DIV_INTERNAL"); //  badd require
    uint256 c2 = c1 / b;
    return c2;
  }

  // Overflow protected division
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0, "Division by zero");
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  // DSMath.wpow
  function bpowi(uint256 a, uint256 n) internal pure returns (uint256) {
    uint256 z = n % 2 != 0 ? a : BONE;

    for (n /= 2; n != 0; n /= 2) {
      a = bmul(a, a);

      if (n % 2 != 0) {
        z = bmul(z, a);
      }
    }
    return z;
  }

  // Compute b^(e.w) by splitting it into (b^e)*(b^0.w).
  // Use `bpowi` for `b^e` and `bpowK` for k iterations
  // of approximation of b^0.w
  function bpow(uint256 base, uint256 exp) internal pure returns (uint256) {
    require(base >= MIN_BPOW_BASE, "ERR_BPOW_BASE_TOO_LOW");
    require(base <= MAX_BPOW_BASE, "ERR_BPOW_BASE_TOO_HIGH");

    uint256 whole = bfloor(exp);
    uint256 remain = bsub(exp, whole);

    uint256 wholePow = bpowi(base, btoi(whole));

    if (remain == 0) {
      return wholePow;
    }

    uint256 partialResult = bpowApprox(base, remain, BPOW_PRECISION);
    return bmul(wholePow, partialResult);
  }

  function bpowApprox(
    uint256 base,
    uint256 exp,
    uint256 precision
  ) internal pure returns (uint256) {
    // term 0:
    uint256 a = exp;
    (uint256 x, bool xneg) = bsubSign(base, BONE);
    uint256 term = BONE;
    uint256 sum = term;
    bool negative = false;

    // term(k) = numer / denom
    //         = (product(a - i - 1, i=1-->k) * x^k) / (k!)
    // each iteration, multiply previous term by (a-(k-1)) * x / k
    // continue until term is less than precision
    for (uint256 i = 1; term >= precision; i++) {
      uint256 bigK = i * BONE;
      (uint256 c, bool cneg) = bsubSign(a, bsub(bigK, BONE));
      term = bmul(term, bmul(c, x));
      term = bdiv(term, bigK);
      if (term == 0) break;

      if (xneg) negative = !negative;
      if (cneg) negative = !negative;
      if (negative) {
        sum = bsub(sum, term);
      } else {
        sum = badd(sum, term);
      }
    }

    return sum;
  }

  function bfloor(uint256 a) internal pure returns (uint256) {
    return btoi(a) * BONE;
  }
}

pragma solidity ^0.6.4;

import "./Math.sol";
import "./LibPoolToken.sol";
import {PV2SmartPoolStorage as P2Storage} from "../storage/PV2SmartPoolStorage.sol";
import {PCTokenStorage as PCStorage} from "../storage/PCTokenStorage.sol";

library LibFees {
  using Math for uint256;

  uint256 public constant MAX_ANNUAL_FEE = 1 ether / 10; // Max annual fee

  event AnnualFeeClaimed(uint256 amount);
  event AnnualFeeChanged(uint256 oldFee, uint256 newFee);
  event FeeRecipientChanged(address indexed oldRecipient, address indexed newRecipient);

  function calcOutstandingAnnualFee() internal view returns (uint256) {
    P2Storage.StorageStruct storage v2s = P2Storage.load();
    uint256 totalSupply = PCStorage.load().totalSupply;

    uint256 lastClaimed = v2s.lastAnnualFeeClaimed;

    if (lastClaimed == 0) {
      return 0;
    }

    uint256 timePassed = block.timestamp.bsub(lastClaimed);
    // TODO check this calc;
    return totalSupply.mul(v2s.annualFee).div(10**18).mul(timePassed).div(365 days);
  }

  function chargeOutstandingAnnualFee() internal {
    P2Storage.StorageStruct storage v2s = P2Storage.load();
    uint256 outstandingFee = calcOutstandingAnnualFee();

    if (outstandingFee == 0) {
      v2s.lastAnnualFeeClaimed = block.timestamp;
      return;
    }

    LibPoolToken._mint(v2s.feeRecipient, outstandingFee);

    v2s.lastAnnualFeeClaimed = block.timestamp;

    emit AnnualFeeClaimed(outstandingFee);
  }

  function setFeeRecipient(address _newRecipient) internal {
    emit FeeRecipientChanged(P2Storage.load().feeRecipient, _newRecipient);
    P2Storage.load().feeRecipient = _newRecipient;
  }

  function setAnnualFee(uint256 _newFee) internal {
    require(_newFee <= MAX_ANNUAL_FEE, "LibFees.setAnnualFee: Annual fee too high");
    // Charge fee when the fee changes
    chargeOutstandingAnnualFee();
    emit AnnualFeeChanged(P2Storage.load().annualFee, _newFee);
    P2Storage.load().annualFee = _newFee;
  }
}

pragma solidity 0.6.4;

import {PBasicSmartPoolStorage as PBStorage} from "../storage/PBasicSmartPoolStorage.sol";
import {PCTokenStorage as PCStorage} from "../storage/PCTokenStorage.sol";
import "./LibFees.sol";

import "./LibPoolToken.sol";
import "./LibUnderlying.sol";
import "./Math.sol";

library LibPoolEntryExit {
  using Math for uint256;

  event LOG_EXIT(address indexed caller, address indexed tokenOut, uint256 tokenAmountOut);
  event LOG_JOIN(address indexed caller, address indexed tokenIn, uint256 tokenAmountIn);
  event PoolExited(address indexed from, uint256 amount);
  event PoolExitedWithLoss(address indexed from, uint256 amount, address[] lossTokens);
  event PoolJoined(address indexed from, uint256 amount);

  modifier lockBPoolSwap() {
    IBPool bPool = PBStorage.load().bPool;
    if(bPool.isPublicSwap()) {
      // If public swap is enabled turn it of, execute function and turn it off again
      bPool.setPublicSwap(false);
      _;
      bPool.setPublicSwap(true);
    } else {
      // If public swap is not enabled just execute
      _;
    }
  }

  function exitPool(uint256 _amount) internal {
    IBPool bPool = PBStorage.load().bPool;
    uint256[] memory minAmountsOut = new uint256[](bPool.getCurrentTokens().length);
    _exitPool(_amount, minAmountsOut);
  }

  function exitPool(uint256 _amount, uint256[] calldata _minAmountsOut) external {
    _exitPool(_amount, _minAmountsOut);
  }

  function _exitPool(uint256 _amount, uint256[] memory _minAmountsOut) internal lockBPoolSwap {
    IBPool bPool = PBStorage.load().bPool;
    LibFees.chargeOutstandingAnnualFee();
    uint256 poolTotal = PCStorage.load().totalSupply;
    uint256 ratio = _amount.bdiv(poolTotal);
    require(ratio != 0);

    LibPoolToken._burn(msg.sender, _amount);

    address[] memory tokens = bPool.getCurrentTokens();

    for (uint256 i = 0; i < tokens.length; i++) {
      address token = tokens[i];
      uint256 balance = bPool.getBalance(token);
      uint256 tokenAmountOut = ratio.bmul(balance);

      require(
        tokenAmountOut >= _minAmountsOut[i],
        "LibPoolEntryExit.exitPool: Token amount out too small"
      );

      emit LOG_EXIT(msg.sender, token, tokenAmountOut);
      LibUnderlying._pushUnderlying(token, msg.sender, tokenAmountOut, balance);
    }
    emit PoolExited(msg.sender, _amount);
  }

  function exitswapPoolAmountIn(
    address _token,
    uint256 _poolAmountIn,
    uint256 _minAmountOut
  ) external lockBPoolSwap returns (uint256 tokenAmountOut) {
    IBPool bPool = PBStorage.load().bPool;
    LibFees.chargeOutstandingAnnualFee();
    require(bPool.isBound(_token), "LibPoolEntryExit.exitswapPoolAmountIn: Token Not Bound");

    tokenAmountOut = bPool.calcSingleOutGivenPoolIn(
      bPool.getBalance(_token),
      bPool.getDenormalizedWeight(_token),
      PCStorage.load().totalSupply,
      bPool.getTotalDenormalizedWeight(),
      _poolAmountIn,
      bPool.getSwapFee()
    );

    require(
      tokenAmountOut >= _minAmountOut,
      "LibPoolEntryExit.exitswapPoolAmountIn: Token Not Bound"
    );

    emit LOG_EXIT(msg.sender, _token, tokenAmountOut);

    LibPoolToken._burn(msg.sender, _poolAmountIn);

    emit PoolExited(msg.sender, tokenAmountOut);

    uint256 bal = bPool.getBalance(_token);
    LibUnderlying._pushUnderlying(_token, msg.sender, tokenAmountOut, bal);

    return tokenAmountOut;
  }

  function exitswapExternAmountOut(
    address _token,
    uint256 _tokenAmountOut,
    uint256 _maxPoolAmountIn
  ) external lockBPoolSwap returns (uint256 poolAmountIn) {
    IBPool bPool = PBStorage.load().bPool;
    LibFees.chargeOutstandingAnnualFee();
    require(bPool.isBound(_token), "LibPoolEntryExit.exitswapExternAmountOut: Token Not Bound");

    poolAmountIn = bPool.calcPoolInGivenSingleOut(
      bPool.getBalance(_token),
      bPool.getDenormalizedWeight(_token),
      PCStorage.load().totalSupply,
      bPool.getTotalDenormalizedWeight(),
      _tokenAmountOut,
      bPool.getSwapFee()
    );

    require(
      poolAmountIn <= _maxPoolAmountIn,
      "LibPoolEntryExit.exitswapExternAmountOut: pool amount in too large"
    );

    emit LOG_EXIT(msg.sender, _token, _tokenAmountOut);

    LibPoolToken._burn(msg.sender, poolAmountIn);

    emit PoolExited(msg.sender, _tokenAmountOut);

    uint256 bal = bPool.getBalance(_token);
    LibUnderlying._pushUnderlying(_token, msg.sender, _tokenAmountOut, bal);

    return poolAmountIn;
  }

  function exitPoolTakingloss(uint256 _amount, address[] calldata _lossTokens)
    external
    lockBPoolSwap
  {
    IBPool bPool = PBStorage.load().bPool;
    LibFees.chargeOutstandingAnnualFee();
    uint256 poolTotal = PCStorage.load().totalSupply;
    uint256 ratio = _amount.bdiv(poolTotal);
    require(ratio != 0);

    LibPoolToken._burn(msg.sender, _amount);

    address[] memory tokens = bPool.getCurrentTokens();

    for (uint256 i = 0; i < tokens.length; i++) {
      // If taking loss on token skip one iteration of the loop
      if (_contains(tokens[i], _lossTokens)) {
        continue;
      }
      address t = tokens[i];
      uint256 bal = bPool.getBalance(t);
      uint256 tAo = ratio.bmul(bal);
      emit LOG_EXIT(msg.sender, t, tAo);
      LibUnderlying._pushUnderlying(t, msg.sender, tAo, bal);
    }
    emit PoolExitedWithLoss(msg.sender, _amount, _lossTokens);
  }

  /**
        @notice Searches for an address in an array of addresses and returns if found
        @param _needle Address to look for
        @param _haystack Array to search
        @return If value is found
    */
  function _contains(address _needle, address[] memory _haystack) internal pure returns (bool) {
    for (uint256 i = 0; i < _haystack.length; i++) {
      if (_haystack[i] == _needle) {
        return true;
      }
    }
    return false;
  }

  function joinPool(uint256 _amount) external {
    IBPool bPool = PBStorage.load().bPool;
    uint256[] memory maxAmountsIn = new uint256[](bPool.getCurrentTokens().length);
    for (uint256 i = 0; i < maxAmountsIn.length; i++) {
      maxAmountsIn[i] = uint256(-1);
    }
    _joinPool(_amount, maxAmountsIn);
  }

  function joinPool(uint256 _amount, uint256[] calldata _maxAmountsIn) external {
    _joinPool(_amount, _maxAmountsIn);
  }

  function _joinPool(uint256 _amount, uint256[] memory _maxAmountsIn) internal lockBPoolSwap {
    IBPool bPool = PBStorage.load().bPool;
    LibFees.chargeOutstandingAnnualFee();
    uint256 poolTotal = PCStorage.load().totalSupply;
    uint256 ratio = _amount.bdiv(poolTotal);
    require(ratio != 0);

    address[] memory tokens = bPool.getCurrentTokens();

    for (uint256 i = 0; i < tokens.length; i++) {
      address t = tokens[i];
      uint256 bal = bPool.getBalance(t);
      uint256 tokenAmountIn = ratio.bmul(bal);
      require(
        tokenAmountIn <= _maxAmountsIn[i],
        "LibPoolEntryExit.joinPool: Token in amount too big"
      );
      emit LOG_JOIN(msg.sender, t, tokenAmountIn);
      LibUnderlying._pullUnderlying(t, msg.sender, tokenAmountIn, bal);
    }
    LibPoolToken._mint(msg.sender, _amount);
    emit PoolJoined(msg.sender, _amount);
  }

  function joinswapExternAmountIn(
    address _token,
    uint256 _amountIn,
    uint256 _minPoolAmountOut
  ) external lockBPoolSwap returns (uint256 poolAmountOut)  {
    IBPool bPool = PBStorage.load().bPool;
    LibFees.chargeOutstandingAnnualFee();
    require(bPool.isBound(_token), "LibPoolEntryExit.joinswapExternAmountIn: Token Not Bound");

    poolAmountOut = bPool.calcPoolOutGivenSingleIn(
      bPool.getBalance(_token),
      bPool.getDenormalizedWeight(_token),
      PCStorage.load().totalSupply,
      bPool.getTotalDenormalizedWeight(),
      _amountIn,
      bPool.getSwapFee()
    );

    require(
      poolAmountOut >= _minPoolAmountOut,
      "LibPoolEntryExit.joinswapExternAmountIn: Insufficient pool amount out"
    );

    emit LOG_JOIN(msg.sender, _token, _amountIn);

    LibPoolToken._mint(msg.sender, poolAmountOut);

    emit PoolJoined(msg.sender, poolAmountOut);

    uint256 bal = bPool.getBalance(_token);
    LibUnderlying._pullUnderlying(_token, msg.sender, _amountIn, bal);

    return poolAmountOut;
  }

  function joinswapPoolAmountOut(
    address _token,
    uint256 _amountOut,
    uint256 _maxAmountIn
  ) external lockBPoolSwap returns (uint256 tokenAmountIn) {
    IBPool bPool = PBStorage.load().bPool;
    LibFees.chargeOutstandingAnnualFee();
    require(bPool.isBound(_token), "LibPoolEntryExit.joinswapPoolAmountOut: Token Not Bound");

    tokenAmountIn = bPool.calcSingleInGivenPoolOut(
      bPool.getBalance(_token),
      bPool.getDenormalizedWeight(_token),
      PCStorage.load().totalSupply,
      bPool.getTotalDenormalizedWeight(),
      _amountOut,
      bPool.getSwapFee()
    );

    require(
      tokenAmountIn <= _maxAmountIn,
      "LibPoolEntryExit.joinswapPoolAmountOut: Token amount in too big"
    );

    emit LOG_JOIN(msg.sender, _token, tokenAmountIn);

    LibPoolToken._mint(msg.sender, _amountOut);

    emit PoolJoined(msg.sender, _amountOut);

    uint256 bal = bPool.getBalance(_token);
    LibUnderlying._pullUnderlying(_token, msg.sender, tokenAmountIn, bal);

    return tokenAmountIn;
  }
}

pragma solidity ^0.6.4;

import "../interfaces/IERC20.sol";
import "../interfaces/IBPool.sol";

import {PBasicSmartPoolStorage as PBStorage} from "../storage/PBasicSmartPoolStorage.sol";

import "./Math.sol";

library LibUnderlying {
  using Math for uint256;

  function _pullUnderlying(
    address _token,
    address _from,
    uint256 _amount,
    uint256 _tokenBalance
  ) internal {
    IBPool bPool = PBStorage.load().bPool;
    // Gets current Balance of token i, Bi, and weight of token i, Wi, from BPool.
    uint256 tokenWeight = bPool.getDenormalizedWeight(_token);

    require(
      IERC20(_token).transferFrom(_from, address(this), _amount),
      "LibUnderlying._pullUnderlying: transferFrom failed"
    );
    bPool.rebind(_token, _tokenBalance.badd(_amount), tokenWeight);
  }

  function _pushUnderlying(
    address _token,
    address _to,
    uint256 _amount,
    uint256 _tokenBalance
  ) internal {
    IBPool bPool = PBStorage.load().bPool;
    // Gets current Balance of token i, Bi, and weight of token i, Wi, from BPool.
    uint256 tokenWeight = bPool.getDenormalizedWeight(_token);
    bPool.rebind(_token, _tokenBalance.bsub(_amount), tokenWeight);

    require(
      IERC20(_token).transfer(_to, _amount),
      "LibUnderlying._pushUnderlying: transfer failed"
    );
  }
}

// modified version of
// https://github.com/balancer-labs/balancer-core/blob/master/contracts/BMath.sol

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.6.4;

import "./Math.sol";
import "./LibFees.sol";
import {PBasicSmartPoolStorage as PBStorage} from "../storage/PBasicSmartPoolStorage.sol";
import {PCTokenStorage as PCStorage} from "../storage/PCTokenStorage.sol";

library LibPoolMath {
  using Math for uint256;

  uint256 constant BONE = 1 * 10**18;
  uint256 constant EXIT_FEE = 0;

  /**********************************************************************************************
    // calcSpotPrice                                                                             //
    // sP = spotPrice                                                                            //
    // bI = tokenBalanceIn                ( bI / wI )         1                                  //
    // bO = tokenBalanceOut         sP =  -----------  *  ----------                             //
    // wI = tokenWeightIn                 ( bO / wO )     ( 1 - sF )                             //
    // wO = tokenWeightOut                                                                       //
    // sF = swapFee                                                                              //
    **********************************************************************************************/
  function calcSpotPrice(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 tokenBalanceOut,
    uint256 tokenWeightOut,
    uint256 swapFee
  ) internal pure returns (uint256 spotPrice) {
    uint256 numer = tokenBalanceIn.bdiv(tokenWeightIn);
    uint256 denom = tokenBalanceOut.bdiv(tokenWeightOut);
    uint256 ratio = numer.bdiv(denom);
    uint256 scale = BONE.bdiv(BONE.bsub(swapFee));
    return (spotPrice = ratio.bmul(scale));
  }

  /**********************************************************************************************
    // calcOutGivenIn                                                                            //
    // aO = tokenAmountOut                                                                       //
    // bO = tokenBalanceOut                                                                      //
    // bI = tokenBalanceIn              /      /            bI             \    (wI / wO) \      //
    // aI = tokenAmountIn    aO = bO * |  1 - | --------------------------  | ^            |     //
    // wI = tokenWeightIn               \      \ ( bI + ( aI * ( 1 - sF )) /              /      //
    // wO = tokenWeightOut                                                                       //
    // sF = swapFee                                                                              //
    **********************************************************************************************/
  function calcOutGivenIn(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 tokenBalanceOut,
    uint256 tokenWeightOut,
    uint256 tokenAmountIn,
    uint256 swapFee
  ) internal pure returns (uint256 tokenAmountOut) {
    uint256 weightRatio = tokenWeightIn.bdiv(tokenWeightOut);
    uint256 adjustedIn = BONE.bsub(swapFee);
    adjustedIn = tokenAmountIn.bmul(adjustedIn);
    uint256 y = tokenBalanceIn.bdiv(tokenBalanceIn.badd(adjustedIn));
    uint256 foo = y.bpow(weightRatio);
    uint256 bar = BONE.bsub(foo);
    tokenAmountOut = tokenBalanceOut.bmul(bar);
    return tokenAmountOut;
  }

  /**********************************************************************************************
    // calcInGivenOut                                                                            //
    // aI = tokenAmountIn                                                                        //
    // bO = tokenBalanceOut               /  /     bO      \    (wO / wI)      \                 //
    // bI = tokenBalanceIn          bI * |  | ------------  | ^            - 1  |                //
    // aO = tokenAmountOut    aI =        \  \ ( bO - aO ) /                   /                 //
    // wI = tokenWeightIn           --------------------------------------------                 //
    // wO = tokenWeightOut                          ( 1 - sF )                                   //
    // sF = swapFee                                                                              //
    **********************************************************************************************/
  function calcInGivenOut(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 tokenBalanceOut,
    uint256 tokenWeightOut,
    uint256 tokenAmountOut,
    uint256 swapFee
  ) internal pure returns (uint256 tokenAmountIn) {
    uint256 weightRatio = tokenWeightOut.bdiv(tokenWeightIn);
    uint256 diff = tokenBalanceOut.bsub(tokenAmountOut);
    uint256 y = tokenBalanceOut.bdiv(diff);
    uint256 foo = y.bpow(weightRatio);
    foo = foo.bsub(BONE);
    tokenAmountIn = BONE.bsub(swapFee);
    tokenAmountIn = tokenBalanceIn.bmul(foo).bdiv(tokenAmountIn);
    return tokenAmountIn;
  }

  /**********************************************************************************************
    // calcPoolOutGivenSingleIn                                                                  //
    // pAo = poolAmountOut         /                                              \              //
    // tAi = tokenAmountIn        ///      /     //    wI \      \\       \     wI \             //
    // wI = tokenWeightIn        //| tAi *| 1 - || 1 - --  | * sF || + tBi \    --  \            //
    // tW = totalWeight     pAo=||  \      \     \\    tW /      //         | ^ tW   | * pS - pS //
    // tBi = tokenBalanceIn      \\  ------------------------------------- /        /            //
    // pS = poolSupply            \\                    tBi               /        /             //
    // sF = swapFee                \                                              /              //
    **********************************************************************************************/
  function calcPoolOutGivenSingleIn(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 poolSupply,
    uint256 totalWeight,
    uint256 tokenAmountIn,
    uint256 swapFee
  ) internal pure returns (uint256 poolAmountOut) {
    // Charge the trading fee for the proportion of tokenAi
    ///  which is implicitly traded to the other pool tokens.
    // That proportion is (1- weightTokenIn)
    // tokenAiAfterFee = tAi * (1 - (1-weightTi) * poolFee);
    uint256 normalizedWeight = tokenWeightIn.bdiv(totalWeight);
    uint256 zaz = BONE.bsub(normalizedWeight).bmul(swapFee);
    uint256 tokenAmountInAfterFee = tokenAmountIn.bmul(BONE.bsub(zaz));

    uint256 newTokenBalanceIn = tokenBalanceIn.badd(tokenAmountInAfterFee);
    uint256 tokenInRatio = newTokenBalanceIn.bdiv(tokenBalanceIn);

    uint256 poolRatio = tokenInRatio.bpow(normalizedWeight);
    uint256 newPoolSupply = poolRatio.bmul(poolSupply);
    poolAmountOut = newPoolSupply.bsub(poolSupply);
    return poolAmountOut;
  }

  /**********************************************************************************************
    // calcSingleInGivenPoolOut                                                                  //
    // tAi = tokenAmountIn              //(pS + pAo)\     /    1    \\                           //
    // pS = poolSupply                 || ---------  | ^ | --------- || * bI - bI                //
    // pAo = poolAmountOut              \\    pS    /     \(wI / tW)//                           //
    // bI = balanceIn          tAi =  --------------------------------------------               //
    // wI = weightIn                              /      wI  \                                   //
    // tW = totalWeight                      1 - |  1 - ----  |  * sF                            //
    // sF = swapFee                               \      tW  /                                   //
    **********************************************************************************************/
  function calcSingleInGivenPoolOut(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 poolSupply,
    uint256 totalWeight,
    uint256 poolAmountOut,
    uint256 swapFee
  ) internal pure returns (uint256 tokenAmountIn) {
    uint256 normalizedWeight = tokenWeightIn.bdiv(totalWeight);
    uint256 newPoolSupply = poolSupply.badd(poolAmountOut);
    uint256 poolRatio = newPoolSupply.bdiv(poolSupply);

    //uint256 newBalTi = poolRatio^(1/weightTi) * balTi;
    uint256 boo = BONE.bdiv(normalizedWeight);
    uint256 tokenInRatio = poolRatio.bpow(boo);
    uint256 newTokenBalanceIn = tokenInRatio.bmul(tokenBalanceIn);
    uint256 tokenAmountInAfterFee = newTokenBalanceIn.bsub(tokenBalanceIn);
    // Do reverse order of fees charged in joinswap_ExternAmountIn, this way
    //     ``` pAo == joinswap_ExternAmountIn(Ti, joinswap_PoolAmountOut(pAo, Ti)) ```
    //uint256 tAi = tAiAfterFee / (1 - (1-weightTi) * swapFee) ;
    uint256 zar = BONE.bsub(normalizedWeight).bmul(swapFee);
    tokenAmountIn = tokenAmountInAfterFee.bdiv(BONE.bsub(zar));
    return tokenAmountIn;
  }

  /**********************************************************************************************
    // calcSingleOutGivenPoolIn                                                                  //
    // tAo = tokenAmountOut            /      /                                             \\   //
    // bO = tokenBalanceOut           /      // pS - (pAi * (1 - eF)) \     /    1    \      \\  //
    // pAi = poolAmountIn            | bO - || ----------------------- | ^ | --------- | * b0 || //
    // ps = poolSupply                \      \\          pS           /     \(wO / tW)/      //  //
    // wI = tokenWeightIn      tAo =   \      \                                             //   //
    // tW = totalWeight                    /     /      wO \       \                             //
    // sF = swapFee                    *  | 1 - |  1 - ---- | * sF  |                            //
    // eF = exitFee                        \     \      tW /       /                             //
    **********************************************************************************************/
  function calcSingleOutGivenPoolIn(
    uint256 tokenBalanceOut,
    uint256 tokenWeightOut,
    uint256 poolSupply,
    uint256 totalWeight,
    uint256 poolAmountIn,
    uint256 swapFee
  ) internal pure returns (uint256 tokenAmountOut) {
    uint256 normalizedWeight = tokenWeightOut.bdiv(totalWeight);
    // charge exit fee on the pool token side
    // pAiAfterExitFee = pAi*(1-exitFee)
    uint256 poolAmountInAfterExitFee = poolAmountIn.bmul(BONE.bsub(EXIT_FEE));
    uint256 newPoolSupply = poolSupply.bsub(poolAmountInAfterExitFee);
    uint256 poolRatio = newPoolSupply.bdiv(poolSupply);

    // newBalTo = poolRatio^(1/weightTo) * balTo;
    uint256 tokenOutRatio = poolRatio.bpow(BONE.bdiv(normalizedWeight));
    uint256 newTokenBalanceOut = tokenOutRatio.bmul(tokenBalanceOut);

    uint256 tokenAmountOutBeforeSwapFee = tokenBalanceOut.bsub(newTokenBalanceOut);

    // charge swap fee on the output token side
    //uint256 tAo = tAoBeforeSwapFee * (1 - (1-weightTo) * swapFee)
    uint256 zaz = BONE.bsub(normalizedWeight).bmul(swapFee);
    tokenAmountOut = tokenAmountOutBeforeSwapFee.bmul(BONE.bsub(zaz));
    return tokenAmountOut;
  }

  /**********************************************************************************************
    // calcPoolInGivenSingleOut                                                                  //
    // pAi = poolAmountIn               // /               tAo             \\     / wO \     \   //
    // bO = tokenBalanceOut            // | bO - -------------------------- |\   | ---- |     \  //
    // tAo = tokenAmountOut      pS - ||   \     1 - ((1 - (tO / tW)) * sF)/  | ^ \ tW /  * pS | //
    // ps = poolSupply                 \\ -----------------------------------/                /  //
    // wO = tokenWeightOut  pAi =       \\               bO                 /                /   //
    // tW = totalWeight           -------------------------------------------------------------  //
    // sF = swapFee                                        ( 1 - eF )                            //
    // eF = exitFee                                                                              //
    **********************************************************************************************/
  function calcPoolInGivenSingleOut(
    uint256 tokenBalanceOut,
    uint256 tokenWeightOut,
    uint256 poolSupply,
    uint256 totalWeight,
    uint256 tokenAmountOut,
    uint256 swapFee
  ) internal pure returns (uint256 poolAmountIn) {
    // charge swap fee on the output token side
    uint256 normalizedWeight = tokenWeightOut.bdiv(totalWeight);
    //uint256 tAoBeforeSwapFee = tAo / (1 - (1-weightTo) * swapFee) ;
    uint256 zoo = BONE.bsub(normalizedWeight);
    uint256 zar = zoo.bmul(swapFee);
    uint256 tokenAmountOutBeforeSwapFee = tokenAmountOut.bdiv(BONE.bsub(zar));

    uint256 newTokenBalanceOut = tokenBalanceOut.bsub(tokenAmountOutBeforeSwapFee);
    uint256 tokenOutRatio = newTokenBalanceOut.bdiv(tokenBalanceOut);

    //uint256 newPoolSupply = (ratioTo ^ weightTo) * poolSupply;
    uint256 poolRatio = tokenOutRatio.bpow(normalizedWeight);
    uint256 newPoolSupply = poolRatio.bmul(poolSupply);
    uint256 poolAmountInAfterExitFee = poolSupply.bsub(newPoolSupply);

    // charge exit fee on the pool token side
    // pAi = pAiAfterExitFee/(1-exitFee)
    poolAmountIn = poolAmountInAfterExitFee.bdiv(BONE.bsub(EXIT_FEE));
    return poolAmountIn;
  }

  // Wrapped public functions --------------------------------------------------------------------

  /**
        @notice Gets the underlying assets and amounts to mint specific pool shares.
        @param _amount Amount of pool shares to calculate the values for
        @return tokens The addresses of the tokens
        @return amounts The amounts of tokens needed to mint that amount of pool shares
    */
  function calcTokensForAmount(uint256 _amount)
    external
    view
    returns (address[] memory tokens, uint256[] memory amounts)
  {
    tokens = PBStorage.load().bPool.getCurrentTokens();
    amounts = new uint256[](tokens.length);
    uint256 ratio = _amount.bdiv(
      PCStorage.load().totalSupply.badd(LibFees.calcOutstandingAnnualFee())
    );

    for (uint256 i = 0; i < tokens.length; i++) {
      address t = tokens[i];
      uint256 bal = PBStorage.load().bPool.getBalance(t);
      uint256 amount = ratio.bmul(bal);
      amounts[i] = amount;
    }
  }

  /**
    @notice Calculate the amount of pool tokens out for a given amount in
    @param _token Address of the input token
    @param _amount Amount of input token
    @return Amount of pool token
  */
  function calcPoolOutGivenSingleIn(address _token, uint256 _amount)
    external
    view
    returns (uint256)
  {
    PBStorage.StorageStruct storage s = PBStorage.load();
    uint256 tokenBalanceIn = s.bPool.getBalance(_token);
    uint256 tokenWeightIn = s.bPool.getDenormalizedWeight(_token);
    uint256 poolSupply = PCStorage.load().totalSupply.badd(LibFees.calcOutstandingAnnualFee());
    uint256 totalWeight = s.bPool.getTotalDenormalizedWeight();
    uint256 swapFee = s.bPool.getSwapFee();

    return (
      LibPoolMath.calcPoolOutGivenSingleIn(
        tokenBalanceIn,
        tokenWeightIn,
        poolSupply,
        totalWeight,
        _amount,
        swapFee
      )
    );
  }

  /**
    @notice Calculate single in given pool out
    @param _token Address of the input token
    @param _amount Amount of pool out token
    @return Amount of token in
  */
  function calcSingleInGivenPoolOut(address _token, uint256 _amount)
    external
    view
    returns (uint256)
  {
    PBStorage.StorageStruct storage s = PBStorage.load();
    uint256 tokenBalanceIn = s.bPool.getBalance(_token);
    uint256 tokenWeightIn = s.bPool.getDenormalizedWeight(_token);
    uint256 poolSupply = PCStorage.load().totalSupply.badd(LibFees.calcOutstandingAnnualFee());
    uint256 totalWeight = s.bPool.getTotalDenormalizedWeight();
    uint256 swapFee = s.bPool.getSwapFee();

    return (
      LibPoolMath.calcSingleInGivenPoolOut(
        tokenBalanceIn,
        tokenWeightIn,
        poolSupply,
        totalWeight,
        _amount,
        swapFee
      )
    );
  }

  /**
    @notice Calculate single out given pool in
    @param _token Address of output token
    @param _amount Amount of pool in
    @return Amount of token in
  */
  function calcSingleOutGivenPoolIn(address _token, uint256 _amount)
    external
    view
    returns (uint256)
  {
    PBStorage.StorageStruct storage s = PBStorage.load();
    uint256 tokenBalanceOut = s.bPool.getBalance(_token);
    uint256 tokenWeightOut = s.bPool.getDenormalizedWeight(_token);
    uint256 poolSupply = PCStorage.load().totalSupply.badd(LibFees.calcOutstandingAnnualFee());
    uint256 totalWeight = s.bPool.getTotalDenormalizedWeight();
    uint256 swapFee = s.bPool.getSwapFee();

    return (
      LibPoolMath.calcSingleOutGivenPoolIn(
        tokenBalanceOut,
        tokenWeightOut,
        poolSupply,
        totalWeight,
        _amount,
        swapFee
      )
    );
  }

  /**
    @notice Calculate pool in given single token out
    @param _token Address of output token
    @param _amount Amount of output token
    @return Amount of pool in
  */
  function calcPoolInGivenSingleOut(address _token, uint256 _amount)
    external
    view
    returns (uint256)
  {
    PBStorage.StorageStruct storage s = PBStorage.load();
    uint256 tokenBalanceOut = s.bPool.getBalance(_token);
    uint256 tokenWeightOut = s.bPool.getDenormalizedWeight(_token);
    uint256 poolSupply = PCStorage.load().totalSupply.badd(LibFees.calcOutstandingAnnualFee());
    uint256 totalWeight = s.bPool.getTotalDenormalizedWeight();
    uint256 swapFee = s.bPool.getSwapFee();

    return (
      LibPoolMath.calcPoolInGivenSingleOut(
        tokenBalanceOut,
        tokenWeightOut,
        poolSupply,
        totalWeight,
        _amount,
        swapFee
      )
    );
  }
}

pragma solidity ^0.6.4;

import {PBasicSmartPoolStorage as PBStorage} from "../storage/PBasicSmartPoolStorage.sol";
import {PV2SmartPoolStorage as P2Storage} from "../storage/PV2SmartPoolStorage.sol";
import {PCTokenStorage as PCStorage} from "../storage/PCTokenStorage.sol";
import {LibConst as constants} from "./LibConst.sol";
import "./LibPoolToken.sol";
import "./Math.sol";

library LibWeights {
  using Math for uint256;

  function updateWeight(address _token, uint256 _newWeight) external {
    PBStorage.StorageStruct storage s = PBStorage.load();
    P2Storage.StorageStruct storage ws = P2Storage.load();

    require(_newWeight >= constants.MIN_WEIGHT, "ERR_MIN_WEIGHT");
    require(_newWeight <= constants.MAX_WEIGHT, "ERR_MAX_WEIGHT");

    uint256 currentWeight = s.bPool.getDenormalizedWeight(_token);
    uint256 currentBalance = s.bPool.getBalance(_token);
    uint256 poolShares;
    uint256 deltaBalance;
    uint256 deltaWeight;
    uint256 totalSupply = PCStorage.load().totalSupply;
    uint256 totalWeight = s.bPool.getTotalDenormalizedWeight();

    if (_newWeight < currentWeight) {
      // If weight goes down we need to pull tokens and burn pool shares
      require(
        totalWeight.badd(currentWeight.bsub(_newWeight)) <= constants.MAX_TOTAL_WEIGHT,
        "ERR_MAX_TOTAL_WEIGHT"
      );

      deltaWeight = currentWeight.bsub(_newWeight);

      poolShares = totalSupply.bmul(deltaWeight.bdiv(totalWeight));

      deltaBalance = currentBalance.bmul(deltaWeight.bdiv(currentWeight));

      // New balance cannot be lower than MIN_BALANCE
      require(currentBalance.bsub(deltaBalance) >= constants.MIN_BALANCE, "ERR_MIN_BALANCE");
      // First gets the tokens from this contract (Pool Controller) to msg.sender
      s.bPool.rebind(_token, currentBalance.bsub(deltaBalance), _newWeight);

      // Now with the tokens this contract can send them to msg.sender
      require(IERC20(_token).transfer(msg.sender, deltaBalance), "ERR_ERC20_FALSE");

      // Cancel potential weight adjustment process.
      ws.startBlock = 0;

      LibPoolToken._burn(msg.sender, poolShares);
    } else {
      // This means the controller will deposit tokens to keep the price.
      // They will be minted and given PCTokens
      require(
        totalWeight.badd(_newWeight.bsub(currentWeight)) <= constants.MAX_TOTAL_WEIGHT,
        "ERR_MAX_TOTAL_WEIGHT"
      );

      deltaWeight = _newWeight.bsub(currentWeight);
      poolShares = totalSupply.bmul(deltaWeight.bdiv(totalWeight));
      deltaBalance = currentBalance.bmul(deltaWeight.bdiv(currentWeight));

      // First gets the tokens from msg.sender to this contract (Pool Controller)
      require(
        IERC20(_token).transferFrom(msg.sender, address(this), deltaBalance),
        "TRANSFER_FAILED"
      );
      // Now with the tokens this contract can bind them to the pool it controls
      s.bPool.rebind(_token, currentBalance.badd(deltaBalance), _newWeight);

      // Cancel potential weight adjustment process.
      ws.startBlock = 0;

      LibPoolToken._mint(msg.sender, poolShares);
    }
  }

  function updateWeightsGradually(
    uint256[] calldata _newWeights,
    uint256 _startBlock,
    uint256 _endBlock
  ) external {
    PBStorage.StorageStruct storage s = PBStorage.load();
    P2Storage.StorageStruct storage ws = P2Storage.load();

    uint256 weightsSum = 0;
    address[] memory tokens = s.bPool.getCurrentTokens();
    // Check that endWeights are valid now to avoid reverting in a future pokeWeights call
    for (uint256 i = 0; i < tokens.length; i++) {
      require(_newWeights[i] <= constants.MAX_WEIGHT, "ERR_WEIGHT_ABOVE_MAX");
      require(_newWeights[i] >= constants.MIN_WEIGHT, "ERR_WEIGHT_BELOW_MIN");
      weightsSum = weightsSum.badd(_newWeights[i]);
    }
    require(weightsSum <= constants.MAX_TOTAL_WEIGHT, "ERR_MAX_TOTAL_WEIGHT");

    if (block.number > _startBlock) {
      // This means the weight update should start ASAP
      ws.startBlock = block.number;
    } else {
      ws.startBlock = _startBlock;
    }
    ws.endBlock = _endBlock;
    ws.newWeights = _newWeights;

    require(
      _endBlock > _startBlock,
      "PWeightControlledSmartPool.updateWeightsGradually: End block must be after start block"
    );

    delete ws.startWeights;

    for (uint256 i = 0; i < tokens.length; i++) {
      // startWeights are current weights
      ws.startWeights.push(s.bPool.getDenormalizedWeight(tokens[i]));
    }
  }

  function pokeWeights() external {
    PBStorage.StorageStruct storage s = PBStorage.load();
    P2Storage.StorageStruct storage ws = P2Storage.load();

    require(ws.startBlock != 0, "ERR_WEIGHT_ADJUSTMENT_FINISHED");
    require(block.number >= ws.startBlock, "ERR_CANT_POKE_YET");

    // This allows for pokes after endBlock that get weights to endWeights
    uint256 minBetweenEndBlockAndThisBlock;
    if (block.number > ws.endBlock) {
      minBetweenEndBlockAndThisBlock = ws.endBlock;
    } else {
      minBetweenEndBlockAndThisBlock = block.number;
    }

    uint256 blockPeriod = ws.endBlock.bsub(ws.startBlock);
    uint256 weightDelta;
    uint256 newWeight;
    address[] memory tokens = s.bPool.getCurrentTokens();
    for (uint256 i = 0; i < tokens.length; i++) {
      if (ws.startWeights[i] >= ws.newWeights[i]) {
        weightDelta = ws.startWeights[i].bsub(ws.newWeights[i]);
        newWeight = ws.startWeights[i].bsub(
          (minBetweenEndBlockAndThisBlock.bsub(ws.startBlock)).bmul(weightDelta.bdiv(blockPeriod))
        );
      } else {
        weightDelta = ws.newWeights[i].bsub(ws.startWeights[i]);
        newWeight = ws.startWeights[i].badd(
          (minBetweenEndBlockAndThisBlock.bsub(ws.startBlock)).bmul(weightDelta.bdiv(blockPeriod))
        );
      }
      s.bPool.rebind(tokens[i], s.bPool.getBalance(tokens[i]), newWeight);
    }

    if(minBetweenEndBlockAndThisBlock == ws.endBlock) {
      // All the weights are adjusted, adjustment finished.

      // save gas option: set this to max number instead of 0
      // And be able to remove ERR_WEIGHT_ADJUSTMENT_FINISHED check
      ws.startBlock = 0;
    }
  }
}

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.6.4;

import {PCTokenStorage as PCStorage} from "./storage/PCTokenStorage.sol";
import "./libraries/LibPoolToken.sol";
import "./libraries/Math.sol";
import "./interfaces/IERC20.sol";


// Highly opinionated token implementation
// Based on the balancer Implementation

contract PCToken is IERC20 {
  using Math for uint256;

  event Approval(address indexed _src, address indexed _dst, uint256 _amount);
  event Transfer(address indexed _src, address indexed _dst, uint256 _amount);

  uint8 public constant decimals = 18;

  function _mint(uint256 _amount) internal {
    LibPoolToken._mint(address(this), _amount);
  }

  function _burn(uint256 _amount) internal {
    LibPoolToken._burn(address(this), _amount);
  }

  function _move(
    address _src,
    address _dst,
    uint256 _amount
  ) internal {
    PCStorage.StorageStruct storage s = PCStorage.load();
    require(s.balance[_src] >= _amount, "ERR_INSUFFICIENT_BAL");
    s.balance[_src] = s.balance[_src].bsub(_amount);
    s.balance[_dst] = s.balance[_dst].badd(_amount);
    emit Transfer(_src, _dst, _amount);
  }

  function _push(address _to, uint256 _amount) internal {
    _move(address(this), _to, _amount);
  }

  function _pull(address _from, uint256 _amount) internal {
    _move(_from, address(this), _amount);
  }

  function allowance(address _src, address _dst) external override view returns (uint256) {
    return PCStorage.load().allowance[_src][_dst];
  }

  function balanceOf(address _whom) external override view returns (uint256) {
    return PCStorage.load().balance[_whom];
  }

  function totalSupply() public override view returns (uint256) {
    return PCStorage.load().totalSupply;
  }

  function name() external view returns (string memory) {
    return PCStorage.load().name;
  }

  function symbol() external view returns (string memory) {
    return PCStorage.load().symbol;
  }

  function approve(address _dst, uint256 _amount) external override returns (bool) {
    PCStorage.load().allowance[msg.sender][_dst] = _amount;
    emit Approval(msg.sender, _dst, _amount);
    return true;
  }

  function increaseApproval(address _dst, uint256 _amount) external returns (bool) {
    PCStorage.StorageStruct storage s = PCStorage.load();
    s.allowance[msg.sender][_dst] = s.allowance[msg.sender][_dst].badd(_amount);
    emit Approval(msg.sender, _dst, s.allowance[msg.sender][_dst]);
    return true;
  }

  function decreaseApproval(address _dst, uint256 _amount) external returns (bool) {
    PCStorage.StorageStruct storage s = PCStorage.load();
    uint256 oldValue = s.allowance[msg.sender][_dst];
    if (_amount > oldValue) {
      s.allowance[msg.sender][_dst] = 0;
    } else {
      s.allowance[msg.sender][_dst] = oldValue.bsub(_amount);
    }
    emit Approval(msg.sender, _dst, s.allowance[msg.sender][_dst]);
    return true;
  }

  function transfer(address _dst, uint256 _amount) external override returns (bool) {
    _move(msg.sender, _dst, _amount);
    return true;
  }

  function transferFrom(
    address _src,
    address _dst,
    uint256 _amount
  ) external override returns (bool) {
    PCStorage.StorageStruct storage s = PCStorage.load();
    require(
      msg.sender == _src || _amount <= s.allowance[_src][msg.sender],
      "ERR_PCTOKEN_BAD_CALLER"
    );
    _move(_src, _dst, _amount);
    if (msg.sender != _src && s.allowance[_src][msg.sender] != uint256(-1)) {
      s.allowance[_src][msg.sender] = s.allowance[_src][msg.sender].bsub(_amount);
      emit Approval(msg.sender, _dst, s.allowance[_src][msg.sender]);
    }
    return true;
  }
}

pragma solidity 0.6.4;

import {ReentryProtectionStorage as RPStorage} from "./storage/ReentryProtectionStorage.sol";

contract ReentryProtection {

  modifier noReentry {
    // Use counter to only write to storage once
    RPStorage.StorageStruct storage s = RPStorage.load();
    s.lockCounter++;
    uint256 lockValue = s.lockCounter;
    _;
    require(lockValue == s.lockCounter, "ReentryProtection.noReentry: reentry detected");
  }

}

pragma solidity 0.6.4;

library ReentryProtectionStorage {
  bytes32 public constant rpSlot = keccak256("ReentryProtection.storage.location");
  struct StorageStruct {
    uint256 lockCounter;
  }

  /**
        @notice Load pool token storage
        @return s Storage pointer to the pool token struct
    */
  function load() internal pure returns (StorageStruct storage s) {
    bytes32 loc = rpSlot;
    assembly {
      s_slot := loc
    }
  }
}

pragma experimental ABIEncoderV2;
pragma solidity 0.6.4;

import "../interfaces/IPV2SmartPool.sol";
import "../interfaces/IBPool.sol";
import "../PCToken.sol";
import "../ReentryProtection.sol";

import "../libraries/LibPoolToken.sol";
import "../libraries/LibAddRemoveToken.sol";
import "../libraries/LibPoolEntryExit.sol";
import "../libraries/LibPoolMath.sol";
import "../libraries/LibWeights.sol";
import "../libraries/LibSafeApprove.sol";

import {PBasicSmartPoolStorage as PBStorage} from "../storage/PBasicSmartPoolStorage.sol";
import {PCTokenStorage as PCStorage} from "../storage/PCTokenStorage.sol";
import {PCappedSmartPoolStorage as PCSStorage} from "../storage/PCappedSmartPoolStorage.sol";
import {PV2SmartPoolStorage as P2Storage} from "../storage/PV2SmartPoolStorage.sol";

contract PV2SmartPool is IPV2SmartPool, PCToken, ReentryProtection {
  using LibSafeApprove for IERC20;

  event TokensApproved();
  event ControllerChanged(address indexed previousController, address indexed newController);
  event PublicSwapSetterChanged(address indexed previousSetter, address indexed newSetter);
  event TokenBinderChanged(address indexed previousTokenBinder, address indexed newTokenBinder);
  event PublicSwapSet(address indexed setter, bool indexed value);
  event SwapFeeSet(address indexed setter, uint256 newFee);
  event CapChanged(address indexed setter, uint256 oldCap, uint256 newCap);
  event CircuitBreakerTripped();
  event JoinExitEnabledChanged(address indexed setter, bool oldValue, bool newValue);
  event CircuitBreakerChanged(
    address indexed _oldCircuitBreaker,
    address indexed _newCircuitBreaker
  );

  modifier ready() {
    require(address(PBStorage.load().bPool) != address(0), "PV2SmartPool.ready: not ready");
    _;
  }

  modifier onlyController() {
    require(
      msg.sender == PBStorage.load().controller,
      "PV2SmartPool.onlyController: not controller"
    );
    _;
  }

  modifier onlyPublicSwapSetter() {
    require(
      msg.sender == PBStorage.load().publicSwapSetter,
      "PV2SmartPool.onlyPublicSwapSetter: not public swap setter"
    );
    _;
  }

  modifier onlyTokenBinder() {
    require(
      msg.sender == PBStorage.load().tokenBinder,
      "PV2SmartPool.onlyTokenBinder: not token binder"
    );
    _;
  }

  modifier onlyPublicSwap() {
    require(
      PBStorage.load().bPool.isPublicSwap(),
      "PV2SmartPool.onlyPublicSwap: swapping not enabled"
    );
    _;
  }

  modifier onlyCircuitBreaker() {
    require(
      msg.sender == P2Storage.load().circuitBreaker,
      "PV2SmartPool.onlyCircuitBreaker: not circuit breaker"
    );
    _;
  }

  modifier onlyJoinExitEnabled() {
    require(
      P2Storage.load().joinExitEnabled,
      "PV2SmartPool.onlyJoinExitEnabled: join and exit not enabled"
    );
    _;
  }

  modifier withinCap() {
    _;
    require(totalSupply() < PCSStorage.load().cap, "PV2SmartPool.withinCap: Cap limit reached");
  }

  /**
        @notice Initialises the contract
        @param _bPool Address of the underlying balancer pool
        @param _name Name for the smart pool token
        @param _symbol Symbol for the smart pool token
        @param _initialSupply Initial token supply to mint
    */
  function init(
    address _bPool,
    string calldata _name,
    string calldata _symbol,
    uint256 _initialSupply
  ) external override {
    PBStorage.StorageStruct storage s = PBStorage.load();
    require(address(s.bPool) == address(0), "PV2SmartPool.init: already initialised");
    require(_bPool != address(0), "PV2SmartPool.init: _bPool cannot be 0x00....000");
    require(_initialSupply != 0, "PV2SmartPool.init: _initialSupply can not zero");
    s.bPool = IBPool(_bPool);
    s.controller = msg.sender;
    s.publicSwapSetter = msg.sender;
    s.tokenBinder = msg.sender;
    PCStorage.load().name = _name;
    PCStorage.load().symbol = _symbol;

    LibPoolToken._mint(msg.sender, _initialSupply);
  }

  /**
    @notice Sets approval to all tokens to the underlying balancer pool
    @dev It uses this function to save on gas in joinPool
  */
  function approveTokens() public override noReentry {
    IBPool bPool = PBStorage.load().bPool;
    address[] memory tokens = bPool.getCurrentTokens();
    for (uint256 i = 0; i < tokens.length; i++) {
      IERC20(tokens[i]).safeApprove(address(bPool), uint256(-1));
    }
    emit TokensApproved();
  }

  // POOL EXIT ------------------------------------------------

  /**
        @notice Burns pool shares and sends back the underlying assets leaving some in the pool
        @param _amount Amount of pool tokens to burn
        @param _lossTokens Tokens skipped on redemption
    */
  function exitPoolTakingloss(uint256 _amount, address[] calldata _lossTokens)
    external
    override
    ready
    noReentry
    onlyJoinExitEnabled
  {
    LibPoolEntryExit.exitPoolTakingloss(_amount, _lossTokens);
  }

  /**
        @notice Burns pool shares and sends back the underlying assets
        @param _amount Amount of pool tokens to burn
    */
  function exitPool(uint256 _amount) external override ready noReentry onlyJoinExitEnabled {
    LibPoolEntryExit.exitPool(_amount);
  }

  /**
    @notice Burn pool tokens and redeem underlying assets. With front running protection
    @param _amount Amount of pool tokens to burn
    @param _minAmountsOut Minimum amounts of underlying assets
  */
  function exitPool(uint256 _amount, uint256[] calldata _minAmountsOut)
    external
    override
    ready
    noReentry
    onlyJoinExitEnabled
  {
    LibPoolEntryExit.exitPool(_amount, _minAmountsOut);
  }

  /**
        @notice Exitswap single asset pool exit given pool amount in
        @param _token Address of exit token
        @param _poolAmountIn Amount of pool tokens sending to the pool
        @return tokenAmountOut amount of exit tokens being withdrawn
    */
  function exitswapPoolAmountIn(
    address _token,
    uint256 _poolAmountIn,
    uint256 _minAmountOut
  )
    external
    override
    ready
    noReentry
    onlyPublicSwap
    onlyJoinExitEnabled
    returns (uint256 tokenAmountOut)
  {
    return LibPoolEntryExit.exitswapPoolAmountIn(_token, _poolAmountIn, _minAmountOut);
  }

  /**
        @notice Exitswap single asset pool entry given token amount out
        @param _token Address of exit token
        @param _tokenAmountOut Amount of exit tokens
        @return poolAmountIn amount of pool tokens being deposited
    */
  function exitswapExternAmountOut(
    address _token,
    uint256 _tokenAmountOut,
    uint256 _maxPoolAmountIn
  )
    external
    override
    ready
    noReentry
    onlyPublicSwap
    onlyJoinExitEnabled
    returns (uint256 poolAmountIn)
  {
    return LibPoolEntryExit.exitswapExternAmountOut(_token, _tokenAmountOut, _maxPoolAmountIn);
  }

  // POOL ENTRY -----------------------------------------------
  /**
        @notice Takes underlying assets and mints smart pool tokens. Enforces the cap
        @param _amount Amount of pool tokens to mint
    */
  function joinPool(uint256 _amount)
    external
    override
    withinCap
    ready
    noReentry
    onlyJoinExitEnabled
  {
    LibPoolEntryExit.joinPool(_amount);
  }

  /**
      @notice Takes underlying assets and mints smart pool tokens.
      Enforces the cap. Allows you to specify the maximum amounts of underlying assets
      @param _amount Amount of pool tokens to mint
  */
  function joinPool(uint256 _amount, uint256[] calldata _maxAmountsIn)
    external
    override
    withinCap
    ready
    noReentry
    onlyJoinExitEnabled
  {
    LibPoolEntryExit.joinPool(_amount, _maxAmountsIn);
  }

  /**
        @notice Joinswap single asset pool entry given token amount in
        @param _token Address of entry token
        @param _amountIn Amount of entry tokens
        @return poolAmountOut
    */
  function joinswapExternAmountIn(
    address _token,
    uint256 _amountIn,
    uint256 _minPoolAmountOut
  )
    external
    override
    ready
    withinCap
    onlyPublicSwap
    noReentry
    onlyJoinExitEnabled
    returns (uint256 poolAmountOut)
  {
    return LibPoolEntryExit.joinswapExternAmountIn(_token, _amountIn, _minPoolAmountOut);
  }

  /**
        @notice Joinswap single asset pool entry given pool amount out
        @param _token Address of entry token
        @param _amountOut Amount of entry tokens to deposit into the pool
        @return tokenAmountIn
    */
  function joinswapPoolAmountOut(
    address _token,
    uint256 _amountOut,
    uint256 _maxAmountIn
  )
    external
    override
    ready
    withinCap
    onlyPublicSwap
    noReentry
    onlyJoinExitEnabled
    returns (uint256 tokenAmountIn)
  {
    return LibPoolEntryExit.joinswapPoolAmountOut(_token, _amountOut, _maxAmountIn);
  }

  // ADMIN FUNCTIONS ------------------------------------------

  /**
        @notice Bind a token to the underlying balancer pool. Can only be called by the token binder
        @param _token Token to bind
        @param _balance Amount to bind
        @param _denorm Denormalised weight
    */
  function bind(
    address _token,
    uint256 _balance,
    uint256 _denorm
  ) external override onlyTokenBinder noReentry {
    P2Storage.StorageStruct storage ws = P2Storage.load();
    IBPool bPool = PBStorage.load().bPool;
    IERC20 token = IERC20(_token);
    require(
      token.transferFrom(msg.sender, address(this), _balance),
      "PV2SmartPool.bind: transferFrom failed"
    );
    // Cancel potential weight adjustment process.
    ws.startBlock = 0;
    token.safeApprove(address(bPool), uint256(-1));
    bPool.bind(_token, _balance, _denorm);
  }

  /**
        @notice Rebind a token to the pool
        @param _token Token to bind
        @param _balance Amount to bind
        @param _denorm Denormalised weight
    */
  function rebind(
    address _token,
    uint256 _balance,
    uint256 _denorm
  ) external override onlyTokenBinder noReentry {
    P2Storage.StorageStruct storage ws = P2Storage.load();
    IBPool bPool = PBStorage.load().bPool;
    IERC20 token = IERC20(_token);

    // gulp old non acounted for token balance in the contract
    bPool.gulp(_token);

    uint256 oldBalance = token.balanceOf(address(bPool));
    // If tokens need to be pulled from msg.sender
    if (_balance > oldBalance) {
      require(
        token.transferFrom(msg.sender, address(this), _balance.bsub(oldBalance)),
        "PV2SmartPool.rebind: transferFrom failed"
      );
      token.safeApprove(address(bPool), uint256(-1));
    }

    bPool.rebind(_token, _balance, _denorm);
    // Cancel potential weight adjustment process.
    ws.startBlock = 0;
    // If any tokens are in this contract send them to msg.sender
    uint256 tokenBalance = token.balanceOf(address(this));
    if (tokenBalance > 0) {
      require(token.transfer(msg.sender, tokenBalance), "PV2SmartPool.rebind: transfer failed");
    }
  }

  /**
        @notice Unbind a token
        @param _token Token to unbind
    */
  function unbind(address _token) external override onlyTokenBinder noReentry {
    P2Storage.StorageStruct storage ws = P2Storage.load();
    IBPool bPool = PBStorage.load().bPool;
    IERC20 token = IERC20(_token);
    // unbind the token in the bPool
    bPool.unbind(_token);

    // Cancel potential weight adjustment process.
    ws.startBlock = 0;

    // If any tokens are in this contract send them to msg.sender
    uint256 tokenBalance = token.balanceOf(address(this));
    if (tokenBalance > 0) {
      require(token.transfer(msg.sender, tokenBalance), "PV2SmartPool.unbind: transfer failed");
    }
  }

  /**
        @notice Sets the controller address. Can only be set by the current controller
        @param _controller Address of the new controller
    */
  function setController(address _controller) external override onlyController noReentry {
    emit ControllerChanged(PBStorage.load().controller, _controller);
    PBStorage.load().controller = _controller;
  }

  /**
        @notice Sets public swap setter address. Can only be set by the controller
        @param _newPublicSwapSetter Address of the new public swap setter
    */
  function setPublicSwapSetter(address _newPublicSwapSetter)
    external
    override
    onlyController
    noReentry
  {
    emit PublicSwapSetterChanged(PBStorage.load().publicSwapSetter, _newPublicSwapSetter);
    PBStorage.load().publicSwapSetter = _newPublicSwapSetter;
  }

  /**
        @notice Sets the token binder address. Can only be set by the controller
        @param _newTokenBinder Address of the new token binder
    */
  function setTokenBinder(address _newTokenBinder) external override onlyController noReentry {
    emit TokenBinderChanged(PBStorage.load().tokenBinder, _newTokenBinder);
    PBStorage.load().tokenBinder = _newTokenBinder;
  }

  /**
        @notice Enables or disables public swapping on the underlying balancer pool.
                Can only be set by the controller.
        @param _public Public or not
    */
  function setPublicSwap(bool _public) external override onlyPublicSwapSetter noReentry {
    emit PublicSwapSet(msg.sender, _public);
    PBStorage.load().bPool.setPublicSwap(_public);
  }

  /**
        @notice Set the swap fee on the underlying balancer pool.
                Can only be called by the controller.
        @param _swapFee The new swap fee
    */
  function setSwapFee(uint256 _swapFee) external override onlyController noReentry {
    emit SwapFeeSet(msg.sender, _swapFee);
    PBStorage.load().bPool.setSwapFee(_swapFee);
  }

  /**
        @notice Set the maximum cap of the contract
        @param _cap New cap in wei
    */
  function setCap(uint256 _cap) external override onlyController noReentry {
    emit CapChanged(msg.sender, PCSStorage.load().cap, _cap);
    PCSStorage.load().cap = _cap;
  }

  /**
    @notice Enable or disable joining and exiting
    @param _newValue enabled or not
  */
  function setJoinExitEnabled(bool _newValue) external override onlyController noReentry {
    emit JoinExitEnabledChanged(msg.sender, P2Storage.load().joinExitEnabled, _newValue);
    P2Storage.load().joinExitEnabled = _newValue;
  }

  /**
    @notice Set the circuit breaker address. Can only be called by the controller
    @param _newCircuitBreaker Address of the new circuit breaker
  */
  function setCircuitBreaker(
    address _newCircuitBreaker
  ) external override onlyController noReentry {
    emit CircuitBreakerChanged(P2Storage.load().circuitBreaker, _newCircuitBreaker);
    P2Storage.load().circuitBreaker = _newCircuitBreaker;
  }

  /**
    @notice Set the annual fee. Can only be called by the controller
    @param _newFee new fee 10**18 == 100% per 365 days. Max 10%
  */
  function setAnnualFee(uint256 _newFee) external override onlyController noReentry {
    LibFees.setAnnualFee(_newFee);
  }

  /**
    @notice Charge the outstanding annual fee
  */
  function chargeOutstandingAnnualFee() external override noReentry {
    LibFees.chargeOutstandingAnnualFee();
  }

  /**
    @notice Set the address that receives the annual fee. Can only be called by the controller
  */
  function setFeeRecipient(address _newRecipient) external override onlyController noReentry {
    LibFees.setFeeRecipient(_newRecipient);
  }

  /**
    @notice Trip the circuit breaker which disabled exit, join and swaps
  */
  function tripCircuitBreaker() external override onlyCircuitBreaker {
    P2Storage.load().joinExitEnabled = false;
    PBStorage.load().bPool.setPublicSwap(false);
    emit CircuitBreakerTripped();
  }

  // TOKEN AND WEIGHT FUNCTIONS -------------------------------

  /**
    @notice Update the weight of a token. Can only be called by the controller
    @param _token Token to adjust the weight of
    @param _newWeight New denormalized weight
  */
  function updateWeight(address _token, uint256 _newWeight)
    external
    override
    noReentry
    onlyController
  {
    LibWeights.updateWeight(_token, _newWeight);
  }

  /**
    @notice Gradually adjust the weights of a token. Can only be called by the controller
    @param _newWeights Target weights
    @param _startBlock Block to start weight adjustment
    @param _endBlock Block to finish weight adjustment
  */
  function updateWeightsGradually(
    uint256[] calldata _newWeights,
    uint256 _startBlock,
    uint256 _endBlock
  ) external override noReentry onlyController {
    LibWeights.updateWeightsGradually(_newWeights, _startBlock, _endBlock);
  }

  /**
    @notice Poke the weight adjustment
  */
  function pokeWeights() external override noReentry {
    LibWeights.pokeWeights();
  }

  /**
    @notice Apply the adding of a token. Can only be called by the controller
  */
  function applyAddToken() external override noReentry onlyController {
    LibAddRemoveToken.applyAddToken();
  }

  /**
    @notice Commit a token to be added. Can only be called by the controller
    @param _token Address of the token to add
    @param _balance Amount of token to add
    @param _denormalizedWeight Denormalized weight
  */
  function commitAddToken(
    address _token,
    uint256 _balance,
    uint256 _denormalizedWeight
  ) external override noReentry onlyController {
    LibAddRemoveToken.commitAddToken(_token, _balance, _denormalizedWeight);
  }

  /**
    @notice Remove a token from the smart pool. Can only be called by the controller
    @param _token Address of the token to remove
  */
  function removeToken(address _token) external override noReentry onlyController {
    LibAddRemoveToken.removeToken(_token);
  }

  // VIEW FUNCTIONS -------------------------------------------

  /**
        @notice Gets the underlying assets and amounts to mint specific pool shares.
        @param _amount Amount of pool shares to calculate the values for
        @return tokens The addresses of the tokens
        @return amounts The amounts of tokens needed to mint that amount of pool shares
    */
  function calcTokensForAmount(uint256 _amount)
    external
    override
    view
    returns (address[] memory tokens, uint256[] memory amounts)
  {
    return LibPoolMath.calcTokensForAmount(_amount);
  }

  /**
    @notice Calculate the amount of pool tokens out for a given amount in
    @param _token Address of the input token
    @param _amount Amount of input token
    @return Amount of pool token
  */
  function calcPoolOutGivenSingleIn(address _token, uint256 _amount)
    external
    override
    view
    returns (uint256)
  {
    return LibPoolMath.calcPoolOutGivenSingleIn(_token, _amount);
  }

  /**
    @notice Calculate single in given pool out
    @param _token Address of the input token
    @param _amount Amount of pool out token
    @return Amount of token in
  */
  function calcSingleInGivenPoolOut(address _token, uint256 _amount)
    external
    override
    view
    returns (uint256)
  {
    return LibPoolMath.calcSingleInGivenPoolOut(_token, _amount);
  }

  /**
    @notice Calculate single out given pool in
    @param _token Address of output token
    @param _amount Amount of pool in
    @return Amount of token in
  */
  function calcSingleOutGivenPoolIn(address _token, uint256 _amount)
    external
    override
    view
    returns (uint256)
  {
    return LibPoolMath.calcSingleOutGivenPoolIn(_token, _amount);
  }

  /**
    @notice Calculate pool in given single token out
    @param _token Address of output token
    @param _amount Amount of output token
    @return Amount of pool in
  */
  function calcPoolInGivenSingleOut(address _token, uint256 _amount)
    external
    override
    view
    returns (uint256)
  {
    return LibPoolMath.calcPoolInGivenSingleOut(_token, _amount);
  }

  /**
    @notice Get the current tokens in the smart pool
    @return Addresses of the tokens in the smart pool
  */
  function getTokens() external override view returns (address[] memory) {
    return PBStorage.load().bPool.getCurrentTokens();
  }

  /**
    @notice Get the address of the controller
    @return The address of the pool
  */
  function getController() external override view returns (address) {
    return PBStorage.load().controller;
  }

  /**
    @notice Get the address of the public swap setter
    @return The public swap setter address
  */
  function getPublicSwapSetter() external override view returns (address) {
    return PBStorage.load().publicSwapSetter;
  }

  /**
    @notice Get the address of the token binder
    @return The token binder address
  */
  function getTokenBinder() external override view returns (address) {
    return PBStorage.load().tokenBinder;
  }

  /**
    @notice Get the address of the circuitBreaker
    @return The address of the circuitBreaker
  */
  function getCircuitBreaker() external override view returns (address) {
    return P2Storage.load().circuitBreaker;
  }

  /**
    @notice Get if public swapping is enabled
    @return If public swapping is enabled
  */
  function isPublicSwap() external override view returns (bool) {
    return PBStorage.load().bPool.isPublicSwap();
  }

  /**
    @notice Get the current cap
    @return The current cap in wei
  */
  function getCap() external override view returns (uint256) {
    return PCSStorage.load().cap;
  }

  function getAnnualFee() external override view returns (uint256) {
    return P2Storage.load().annualFee;
  }

  function getFeeRecipient() external override view returns (address) {
    return P2Storage.load().feeRecipient;
  }

  /**
    @notice Get the denormalized weight of a specific token in the underlying balancer pool
    @return the normalized weight of the token in uint
  */
  function getDenormalizedWeight(address _token) external override view returns (uint256) {
    return PBStorage.load().bPool.getDenormalizedWeight(_token);
  }

  /**
    @notice Get all denormalized weights
    @return weights Denormalized weights
  */
  function getDenormalizedWeights() external override view returns (uint256[] memory weights) {
    PBStorage.StorageStruct storage s = PBStorage.load();
    address[] memory tokens = s.bPool.getCurrentTokens();
    weights = new uint256[](tokens.length);
    for (uint256 i = 0; i < tokens.length; i++) {
      weights[i] = s.bPool.getDenormalizedWeight(tokens[i]);
    }
  }

  /**
    @notice Get the address of the underlying Balancer pool
    @return The address of the underlying balancer pool
  */
  function getBPool() external override view returns (address) {
    return address(PBStorage.load().bPool);
  }

  /**
    @notice Get the current swap fee
    @return The current swap fee
  */
  function getSwapFee() external override view returns (uint256) {
    return PBStorage.load().bPool.getSwapFee();
  }

  /**
    @notice Get the target weights
    @return weights Target weights
  */
  function getNewWeights() external override view returns (uint256[] memory weights) {
    return P2Storage.load().newWeights;
  }

  /**
    @notice Get weights at start of weight adjustment
    @return weights Start weights
  */
  function getStartWeights() external override view returns (uint256[] memory weights) {
    return P2Storage.load().startWeights;
  }

  /**
    @notice Get start block of weight adjustment
    @return Start block
  */
  function getStartBlock() external override view returns (uint256) {
    return P2Storage.load().startBlock;
  }

  /**
    @notice Get end block of weight adjustment
    @return End block
  */
  function getEndBlock() external override view returns (uint256) {
    return P2Storage.load().endBlock;
  }

  /**
    @notice Get new token being added
    @return New token
  */
  function getNewToken() external override view returns (P2Storage.NewToken memory) {
    return P2Storage.load().newToken;
  }

  /**
    @notice Get if joining and exiting is enabled
    @return Enabled or not
  */
  function getJoinExitEnabled() external override view returns (bool) {
    return P2Storage.load().joinExitEnabled;
  }

  // UNSUPORTED METHODS ---------------------------------------

  /**
    @notice Not Supported in PieDAO implementation of Balancer Smart Pools
  */
  function finalizeSmartPool() external override view {
    revert("PV2SmartPool.finalizeSmartPool: unsupported function");
  }

  /**
    @notice Not Supported in PieDAO implementation of Balancer Smart Pools
  */
  function createPool(uint256 initialSupply) external override view {
    revert("PV2SmartPool.createPool: unsupported function");
  }
}

pragma solidity ^0.6.4;

library PCappedSmartPoolStorage {
  bytes32 public constant pcsSlot = keccak256("PCappedSmartPool.storage.location");

  struct StorageStruct {
    uint256 cap;
  }

  /**
        @notice Load PBasicPool storage
        @return s Pointer to the storage struct
    */
  function load() internal pure returns (StorageStruct storage s) {
    bytes32 loc = pcsSlot;
    assembly {
      s_slot := loc
    }
  }
}

pragma solidity 0.6.4;

import "../libraries/LibSafeApprove.sol";
import "../interfaces/IERC20.sol";

contract TestLibSafeApprove {
    using LibSafeApprove for IERC20;

    function doubleApprovalUnsafe(address _token) external {
        IERC20 token = IERC20(_token);

        token.approve(msg.sender, 1337);
        token.approve(msg.sender, 42);
    }

    function doubleApprovalSafe(address _token) external {
        IERC20 token = IERC20(_token);

        token.safeApprove(msg.sender, 1337);
        token.safeApprove(msg.sender, 42);
    }
}

pragma solidity 0.6.4;

import "../PCToken.sol";

contract TestPCToken is PCToken {
  constructor(string memory _name, string memory _symbol) public {
    PCStorage.load().name = _name;
    PCStorage.load().symbol = _symbol;
  }

  function mint(address _to, uint256 _amount) external {
    _mint(_amount);
    _push(_to, _amount);
  }

  function burn(address _from, uint256 _amount) external {
    _pull(_from, _amount);
    _burn(_amount);
  }
}

pragma solidity 0.6.4;

import "../ReentryProtection.sol";

contract TestReentryProtection is ReentryProtection {
  // This should fail
  function test() external noReentry {
    reenter();
  }

  function reenter() public noReentry {
    // Do nothing
  }
}