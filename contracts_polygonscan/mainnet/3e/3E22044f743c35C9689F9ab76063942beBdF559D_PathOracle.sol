/**
 *Submitted for verification at polygonscan.com on 2021-08-24
*/

// Sources flattened with hardhat v2.4.1 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]
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
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/[email protected]

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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File contracts/DeFi/uniswapv2/interfaces/IUniswapV2Factory.sol

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeToSetter() external view returns (address);
    function migrator() external view returns (address);
    function weth() external view returns (address);
    function wbtc() external view returns (address);
    function gfi() external view returns (address);
    function earningsManager() external view returns (address);
    function feeManager() external view returns (address);
    function dustPan() external view returns (address);
    function governor() external view returns (address);
    function priceOracle() external view returns (address);
    function pathOracle() external view returns (address);
    function router() external view returns (address);
    function paused() external view returns (bool);
    function slippage() external view returns (uint);


    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeToSetter(address) external;
    function setMigrator(address) external;
}


// File contracts/core/PathOracle.sol


/**
* @dev OWNER SHOULD CALL alterPath(weth, wbtc) after deployment to set the final path properly
**/
contract PathOracle is Ownable {
    mapping(address => address) public pathMap;
    address[] public favoredAssets;
    address public factory;
    IUniswapV2Factory Factory;

    struct node{
        address token;
        bool notLeaf;
    }
    /**
    * @dev emitted when the owner manually alters a path
    * @param fromAsset the token address that is the input into pathMap
    * @param toAsset the token address that is the output from pathMap
    **/
    event pathAltered(address fromAsset, address toAsset);

    /**
    * @dev emitted when a new pair is created, and their addresses are added to pathMap
    * @param leaf the token address of the asset with no other addresses pointed to it(as of this event)
    * @param branch the token address of the asset which the leaf points to
    **/
    event pathAppended(address leaf, address branch);

    event FactoryChanged(address newFactory);

    constructor(address[] memory _favored) {
        require(favoredAssets.length <= 10, 'Gravity Finance: Favored Assets array too large');
        favoredAssets = _favored;
    }

    modifier onlyFactory() {
        require(msg.sender == factory, "Gravity Finance: FORBIDDEN");
        _;
    }

    function setFavored(address[] memory _favored) external onlyOwner{
        require(favoredAssets.length <= 10, 'Gravity Finance: Favored Assets array too large');
        favoredAssets = _favored;
    }

    /**
    * @dev called by owner to manually change the path mapping
    * @param fromAsset the token address used as the input for pathMap
    * @param toAsset the token address that is the output of pathMap
    **/
    function alterPath(address fromAsset, address toAsset) external onlyOwner {
        pathMap[fromAsset] = toAsset;
        emit pathAltered(fromAsset, toAsset);
    }

    /**
    * @dev view function used to get the output from pathMap if from is the input 
    * @param from the address you are going from
    * @return to the address from steps you to
    **/
    function stepPath(address from) public view returns(address to){
        to = pathMap[from];
    }

    /**
    * @dev called by owner to change the factory address
    * @param _address the new factory address
    **/
    function setFactory(address _address) external onlyOwner {
        factory = _address;
        Factory = IUniswapV2Factory(factory);
        emit FactoryChanged(factory);
    }

    /**
    * @dev called by newly created pairs, basically check if either of the pairs are in the favored list, or if they have a pair with a favored list asset
    * @param token0 address of the first token in the pair
    * @param token1 address of the second token in the pair
    **/
    function appendPath(address token0, address token1) external onlyFactory {
        bool inFavored = false;
        //First Check if either of the tokens are in the favored list
        for (uint i=0; i < favoredAssets.length; i++){
            if (token0 == favoredAssets[i]){
                pathMap[token1] = token0; //Swap token1 for token0
                inFavored = true;
                emit pathAppended(token1, token0);
                break;
            }

            else if (token1 == favoredAssets[i]){
                pathMap[token0] = token1; //Swap token0 for token1
                inFavored = true;
                emit pathAppended(token0, token1);
                break;
            }
        }
        //If neither of the tokens are in the favored list, then see if either of them have pairs with a token in the favored list
        if (!inFavored){
            for (uint i=0; i < favoredAssets.length; i++){
                if (Factory.getPair(token0, favoredAssets[i]) != address(0)){
                    pathMap[token1] = token0; //Swap token1 for token0
                    pathMap[token0] = favoredAssets[i];
                    emit pathAppended(token1, token0);
                    break;
                }

                else if (Factory.getPair(token1, favoredAssets[i]) != address(0)){
                    pathMap[token0] = token1; //Swap token0 for token1
                    pathMap[token1] = favoredAssets[i];
                    emit pathAppended(token0, token1);
                    break;
                }
            }
        }
    }
}