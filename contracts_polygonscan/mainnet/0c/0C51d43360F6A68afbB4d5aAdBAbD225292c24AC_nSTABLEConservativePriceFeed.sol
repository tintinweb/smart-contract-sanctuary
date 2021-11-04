/**
 *Submitted for verification at polygonscan.com on 2021-11-04
*/

// File: IERC20.sol

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    
    function decimals() external view returns (uint8);
    
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
// File: nStablePriceFeed.sol



pragma solidity 0.8.1;

interface IBasketFacet {
    function getTokens() external view returns (address[] memory);
}

interface IKashiLendingLogic {
    function exchangeRateView(address _kaToken) external view returns(uint256);
}

interface IFeed {
    function decimals() external view returns (uint8);
    function latestAnswer() external view returns (uint);
}

interface IAAVE {
    function exchangeRateStored() external view returns (uint);
}

interface IlendingRegistry {
    function wrappedToProtocol(address _wraped) external view returns (bytes32);
    function wrappedToUnderlying(address _wraped) external view returns (address);
}

pragma solidity ^0.8.1;

contract nSTABLEConservativePriceFeed {
    
    uint8 decimal = 8;
    address public lendingRegistry = 0xc94BC5C62C53E88d67C3874f5E8f91c6a99656ca;
    address public kashiLendingLogic = 0x58aFFd9251e7147d46eb8614893dA2B37AdfcB28;
    address public nest = 0x2Bb2eF50c53E406c80875663C2A2e5592F8a3ccc;
    //The token amounts available for 1e18 nSTABLE
    address[] public underlyingToken; 
    mapping (address => uint) public tokenRatios;
    mapping (address => address) public oracles;
    
    string public symbol   = "nSTABLE";
    uint8  public decimals = 18;

    function latestAnswer() external view returns (uint){
        uint price = 0;
        
        for(uint i = 0; i < underlyingToken.length; i++){
            address wrapped = underlyingToken[i];
            
            address underlying = IlendingRegistry(lendingRegistry).wrappedToUnderlying(wrapped);
            //if true we need to get underlying amount and address
            if(underlying != address(0)) {
                //If KashiLending
                if(IlendingRegistry(lendingRegistry).wrappedToProtocol(wrapped) == bytes32(0x000000000000000000000000d3f07ea86ddf7baebefd49731d7bbd207fedc53b)){
                    ((tokenRatios[wrapped] * IKashiLendingLogic(kashiLendingLogic).exchangeRateView(wrapped) / 1e18 * IFeed(oracles[underlying]).latestAnswer()) / 1e8);
                }
                //If AAVE
                price += ((tokenRatios[wrapped] * IFeed(oracles[underlying]).latestAnswer()) / 1e8);
            }
            else{
                price += ((tokenRatios[wrapped] * IFeed(oracles[wrapped]).latestAnswer()) / 1e8);
            }
        }
        return(price);
    }
    
    function getUnderlyingTokens(address _token) external view returns(uint){
        return(IFeed(oracles[_token]).latestAnswer());
    }

    function setDecimals(uint8 _decimal) external{
        decimal = _decimal;
    }
    
    function snapshot() external{
        address[] memory tokens = IBasketFacet(nest).getTokens();
        
        for(uint i = 0; i < tokens.length; i++){
            address _token = tokens[i];
            uint8 digits = 18 - IERC20(_token).decimals();
            if(digits > 0){
                tokenRatios[_token] = ((IERC20(_token).balanceOf(nest) * (10 ** digits)) * 1e18) / IERC20(nest).totalSupply();
            }
            else{
                tokenRatios[_token] = (IERC20(_token).balanceOf(nest) * 1e18) / IERC20(nest).totalSupply();
            }
        }
        
        underlyingToken = tokens;
    }
    
    function setPriceFeed(address _asset, address _chainLinkFeed) external {
        require(_asset != address(0) && _chainLinkFeed != address(0));
        oracles[_asset] = _chainLinkFeed;
    }
}