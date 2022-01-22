// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "../interfaces/IFeeManager.sol";
import "../libs/Ownable.sol";


/**
 * @title Centralised Fee Manager
 *
 * @notice A fee manager contract designed for dApps organisations to coordinate meta transactions pricing centrally
 *
 * @dev implements a default fee multiplier
 * @dev owners can set token specific fee multipliers
 * @dev owners can set fee multipliers specific to a given user of a token
 * @dev owners can remove fee multiplier settings, and instead have a given query return it's parent value
 * @dev hierarchy of fee multipliers : default --> token --> tokenUser 
 * 
 * @dev owners can allow tokens
 *
 */
contract CentralisedFeeManager is IFeeManager,Ownable{
    
    uint16 bp;

    mapping(address => uint16) tokenBP;

    mapping(address => mapping(address => uint16)) tokenUserBP;

    mapping(address => bool) tokenExempt;

    mapping(address => mapping(address => bool)) tokenUserExempt;

    mapping(address => bool) allowedTokens;

    mapping(address => address) tokenPriceFeed;

    constructor(address _owner, uint16 _bp) public Ownable(_owner){
        require(_owner != address(0), "Owner Address cannot be 0");
        bp = _bp;
    }

    /**
     * @dev uses if statements to query the hierarchy (default --> token --> tokenUser) from bottom to top 
     * @dev goes up one level if current level's value = 0 and it is not exempt
     *
     * @param user : the address of the user that is requesting a meta transaction
     * @param token : the token that the user will be paying the fee in 
     *
     * @return basisPoints : the fee multiplier expressed in basis points (1.0000 = 10000 basis points)
     */
    function getFeeMultiplier(address user, address token) external override view returns (uint16 basisPoints){
        basisPoints = tokenUserBP[token][user];
        if (basisPoints == 0){
            if (!tokenUserExempt[token][user]){
                basisPoints = tokenBP[token];
                if (basisPoints == 0){
                    if(!tokenExempt[token]){
                        basisPoints = bp;
                    }
                }
            }
        }
    }

    function setDefaultFeeMultiplier(uint16 _bp) external onlyOwner{
        bp = _bp;
    }

    function setDefaultTokenFeeMultiplier(address token, uint16 _bp) external onlyOwner{
        tokenBP[token] = _bp;
        if (_bp == 0){
            tokenExempt[token] = true;
        }
    }

    function removeDefaultTokenFeeMultiplier(address token) external onlyOwner{
        tokenBP[token] = 0;
        tokenExempt[token] = false;
    }

    function setUserTokenFeeMultiplier(address token, address user, uint16 _bp) external onlyOwner{
        tokenUserBP[token][user] = _bp;
        if (_bp == 0){
            tokenUserExempt[token][user] = true;
        }
    }

    function removeUserTokenFeeMultiplier(address token, address user) external onlyOwner{
        tokenUserBP[token][user] = 0;
        tokenUserExempt[token][user] = false;
    }

    function getTokenAllowed(address token) external override view returns (bool allowed){
        allowed = allowedTokens[token];
    }

    function setTokenAllowed(address token, bool allowed) external onlyOwner{
        allowedTokens[token] = allowed;
    }

    function getPriceFeedAddress(address token) external view returns (address priceFeed){
        priceFeed = tokenPriceFeed[token];
    }

    function setPriceFeedAddress(address token, address priceFeed) external onlyOwner {
        tokenPriceFeed[token] = priceFeed;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IFeeManager{
    function getFeeMultiplier(address user, address token) external view returns (uint16 basisPoints); //setting max multiplier at 6.5536
    function getTokenAllowed(address token) external view returns (bool allowed);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor(address owner) public {
        _owner = owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(
            isOwner(),
            "Only contract owner is allowed to perform this operation"
        );
        _;
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}