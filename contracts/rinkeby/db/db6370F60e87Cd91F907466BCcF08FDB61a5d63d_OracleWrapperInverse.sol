// SPDX-License-Identifier: UNLICENCED
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/access/Ownable.sol";

interface OracleInterface{
    function latestAnswer() external view returns (int256);
}

interface tellorInterface{
    function getLastNewValueById(uint _requestId) external view returns(uint,bool);
}

interface uniswapInterface{
    function getAmountsOut(uint amountIn, address[] memory path)external view returns (uint[] memory amounts);
}
interface Token{
    function decimals() external view returns(uint256);
}
contract OracleWrapperInverse is Ownable{
    
    bool isInitialized;
    address public tellerContractAddress = 0x0Ba45A8b5d5575935B8158a88C631E9F9C95a2e5;
    address public UniswapV2Router02 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public usdtContractAddress = 0xBbf126a88DE8c993BFe67c46Bb333a2eC71bC3fF;
    struct TellorInfo{
        uint256 id;
        uint256 tellorPSR;
    }
    uint256 tellorId=1;
    mapping(string=>address) public typeOneMapping;  // chainlink
    string[] typeOneArray;
    mapping(string=> TellorInfo) public typeTwomapping; // tellor
    string[] typeTwoArray;
    mapping(string=> address) public typeThreemapping; // uniswap
    string[] typeThreeArray;
    address public rootNode;
   
   function initialize(address root,address _tellerContractAddress,address _UniswapV2Router02,address _usdtContractAddress) public {
        require(!isInitialized,"Already initialized");
        rootNode = root;
        tellerContractAddress = _tellerContractAddress;
        UniswapV2Router02=_UniswapV2Router02;
        usdtContractAddress=_usdtContractAddress;
        isInitialized = true;
    }

    modifier onlyOwnerAccess() {
    require(msg.sender == rootNode,"OZV0: Only owner has the access");
    _;
  }

    function updateTellerContractAddress(address newAddress) public onlyOwnerAccess{
        tellerContractAddress = newAddress;
    }
    
    function addTypeOneMapping(string memory currencySymbol, address chainlinkAddress) external onlyOwnerAccess{
        typeOneMapping[currencySymbol]=chainlinkAddress;
        if(!checkAddressIfExists(typeOneArray,currencySymbol)){
            typeOneArray.push(currencySymbol);
        }
    }
    
    function addTypeTwoMapping(string memory currencySymbol, uint256 tellorPSR) external onlyOwnerAccess{
        TellorInfo memory tInfo= TellorInfo({
            id:tellorId,
            tellorPSR:tellorPSR
        });
        typeTwomapping[currencySymbol]=tInfo;
        tellorId++;
        if(!checkAddressIfExists(typeTwoArray,currencySymbol)){
            typeTwoArray.push(currencySymbol);
        }
    }
    
    function addTypeThreeMapping(string memory currencySymbol, address tokenContractAddress) external onlyOwnerAccess{
        typeThreemapping[currencySymbol]=tokenContractAddress;
        if(!checkAddressIfExists(typeThreeArray,currencySymbol)){
            typeThreeArray.push(currencySymbol);
        }
    }
    function checkAddressIfExists(string[] memory arr, string memory currencySymbol) internal pure returns(bool){
        for(uint256 i=0;i<arr.length;i++){
            if((keccak256(abi.encodePacked(arr[i]))) == (keccak256(abi.encodePacked(currencySymbol)))){
                return true;
            }
        }
        return false;
    }
    function getPrice(string memory currencySymbol,
        uint256 oracleType) external view returns (uint256){
        //oracletype 1 - chainlink and  for teller --2, uniswap---3
        if(oracleType == 1){
            require(typeOneMapping[currencySymbol]!=address(0), "please enter valid currency");
            OracleInterface oObj = OracleInterface(typeOneMapping[currencySymbol]);
            return uint256(oObj.latestAnswer());
        }
        else if(oracleType ==2){
            require(typeTwomapping[currencySymbol].id!=0, "please enter valid currency");
            tellorInterface tObj = tellorInterface(tellerContractAddress);
            uint256 actualFiatPrice;
            bool statusTellor;
            (actualFiatPrice,statusTellor) = tObj.getLastNewValueById(typeTwomapping[currencySymbol].tellorPSR);
            return uint256(actualFiatPrice);
        }else{
            require(typeThreemapping[currencySymbol]!=address(0), "please enter valid currency");
            uniswapInterface uObj = uniswapInterface(UniswapV2Router02);
            address[] memory path = new address[](2);
            path[0] = typeThreemapping[currencySymbol];
            path[1] = usdtContractAddress;
            uint[] memory values=uObj.getAmountsOut(10**(Token(typeThreemapping[currencySymbol]).decimals()),path);
            uint256 usdtDecimals=Token(usdtContractAddress).decimals();
            return uint256((values[1]*10**8)/(10**usdtDecimals));
        }
    }
    
    function getTypeOneArray() external view returns(string[] memory){
        return typeOneArray;
    }
    
    function getTypeTwoArray() external view returns(string[] memory){
        return typeTwoArray;
    }
    function getTypeThreeArray() external view returns(string[] memory){
        return typeThreeArray;
    }
    function updateUniswapV2Router02(address _UniswapV2Router02) external onlyOwnerAccess{
        UniswapV2Router02=_UniswapV2Router02;
    }
    function updateUSDTContractAddress(address _usdtContractAddress) external onlyOwnerAccess{
        usdtContractAddress=_usdtContractAddress;
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

