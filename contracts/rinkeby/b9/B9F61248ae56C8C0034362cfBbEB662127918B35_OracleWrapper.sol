// SPDX-License-Identifier: UNLICENCED
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/access/Ownable.sol";
import "contracts/interfaces/Oracleinterface.sol";
import "contracts/interfaces/TellorInterface.sol";
import "contracts/interfaces/UniswapInterface.sol";
import "contracts/interfaces/TokenDecimalsInterface.sol";



contract OracleWrapper is Ownable{
    
    bool isInitialized;
    address public tellerContractAddress;
    address public UniswapV2Router02;
    address public usdtContractAddress;
    address public rootNode;

    struct coinDetails {
        address coinAddress;
        uint8   oracleType;
        uint88  id;
    }

    mapping( address => coinDetails) public coin;  
  
    modifier onlyOwnerAccess() {
        require(msg.sender == rootNode,"OracleWrapperV0 : Only owner has the access");
        _;
    }

   
   function initialize(address root,address _tellerContractAddress,address _UniswapV2Router02,address _usdtContractAddress) public {
        require(!isInitialized,"OracleWrapperV0 : Already initialized");
        rootNode = root;
        tellerContractAddress = _tellerContractAddress;
        UniswapV2Router02 = _UniswapV2Router02;
        usdtContractAddress  =_usdtContractAddress;
        isInitialized = true;
    }
    
    function setOracleAddresses (address _coinAddress, address _oracleAddress, uint8 _oracleType, uint88 _id) public onlyOwnerAccess {
        require((_oracleType == 1) || (_oracleType == 2) || (_oracleType == 3), "OracleWrapperV0: Invalid oracleType");
        require(_coinAddress != address(0), "OracleWrapperV0 : Zero address");
        coin[_coinAddress].coinAddress = _oracleAddress;
        coin[_coinAddress].oracleType = _oracleType;
        if(_oracleType == 3) {
            coin[_coinAddress].id = _id;
        }
    }
  
    function getPrice(address _coinAddress) external view returns (uint256){
        require((coin[_coinAddress].oracleType != uint8(0)), "OracleWrapperV0 : No oracle type");

        if(coin[_coinAddress].oracleType  == 1){
            OracleInterface oObj = OracleInterface(coin[_coinAddress].coinAddress);
            return uint256(oObj.latestAnswer());
        }
        else if(coin[_coinAddress].oracleType == 2){
            tellorInterface tObj = tellorInterface(tellerContractAddress);
            uint256 actualFiatPrice;
            bool statusTellor;
            (actualFiatPrice,statusTellor) = tObj.getLastNewValueById(coin[_coinAddress].id);
            return uint256(actualFiatPrice);
        }
        else{
            uniswapInterface uObj = uniswapInterface(UniswapV2Router02);
            address[] memory path = new address[](2);
            path[0] = coin[_coinAddress].coinAddress;
            path[1] = usdtContractAddress;
            uint[] memory values=uObj.getAmountsOut(10**(Token(coin[_coinAddress].coinAddress).decimals()),path);
            uint256 usdtDecimals=Token(usdtContractAddress).decimals();
            return uint256((values[1]*10**8)/(10**usdtDecimals));
        }
        
    }
    
    function updateUniswapV2Router02(address _UniswapV2Router02) external onlyOwnerAccess{
        UniswapV2Router02=_UniswapV2Router02;
    }

    function updateUSDTContractAddress(address _usdtContractAddress) external onlyOwnerAccess{
        usdtContractAddress=_usdtContractAddress;
    }

    function updateTellerContractAddress(address newAddress) public onlyOwnerAccess{
        tellerContractAddress = newAddress;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: UNLICENCED

pragma solidity ^0.8.0;

interface OracleInterface{
    function latestAnswer() external view returns (int256);
}

// SPDX-License-Identifier: UNLICENCED

pragma solidity ^0.8.0;

interface tellorInterface{
    function getLastNewValueById(uint _requestId) external view returns(uint,bool);
}

// SPDX-License-Identifier: UNLICENCED

pragma solidity ^0.8.0;

interface uniswapInterface{
    function getAmountsOut(uint amountIn, address[] memory path)external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: UNLICENCED

pragma solidity ^0.8.0;

interface Token{
    function decimals() external view returns(uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

