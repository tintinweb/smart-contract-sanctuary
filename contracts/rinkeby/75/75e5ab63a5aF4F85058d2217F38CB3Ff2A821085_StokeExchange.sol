pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";

interface I_Token{
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
}

interface I_Agregator{
    function decimals() external view returns (uint8);
    function latestRoundData() external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

contract StokeExchange is Ownable{
    struct StockExchangeElement{
        address agregator;
        address payable purse;
        address admin;
    }

    struct TokenInfo {
        address token;
        string symbol;
        string name;
    }

    address[] private tokensList;
    mapping(address => StockExchangeElement) private stockExchangeElements;

    event AddToken(address indexed _token, address _agregator, address _purse, address admin);
    event RemoveToken(address indexed _token, address admin);
    event BuyToken(address indexed _token, address indexed _buyer, uint256 _ethAmount, uint256 _tokenAmount);

    function getTokensListLength() public view returns(uint256){
        return tokensList.length;
    }

    function getTokenInfo(uint256 _idx) public view returns(address token, string memory symbol, string memory name){
        require(_idx<tokensList.length, "Wrong index!");
        address _token = tokensList[_idx];
        token = _token;
        symbol = I_Token(token).symbol();
        name = I_Token(token).name();
    }

    function getTokenPrice(address _token) public view returns(uint256 price, uint256 decimals){
        require(_token != address(0), "Token address is zero!");
        StockExchangeElement storage _element = stockExchangeElements[_token];
        require(_element.agregator != address(0), "Token not found!");
        ( , int256 _price, , , ) = I_Agregator(_element.agregator).latestRoundData();
        price = uint256(_price);
        decimals = uint256(I_Agregator(_element.agregator).decimals());  
    }

    function getTokensList() public view returns(TokenInfo[] memory){
        TokenInfo[] memory _list;
        StockExchangeElement storage _element;
        for(uint256 i=0; i<tokensList.length; i++){
            _element = stockExchangeElements[tokensList[i]];
            _list[i]=TokenInfo(tokensList[i], I_Token(tokensList[i]).symbol(), I_Token(tokensList[i]).name());
        }
        return _list;
    }

    function addToken(address _token, address _agregator, address payable _purse, address _admin) public {
        require(_token != address(0), "Token address is zero!");
        require(_agregator != address(0), "Agregator address is zero!");
        require(_purse != address(0), "Purse address is zero!");
        require(_admin != address(0), "Admin address is zero!");
        string memory _symbol = I_Token(_token).symbol();
        require(bytes(_symbol).length>0, "No token symbol!");
        require(stockExchangeElements[_token].agregator == address(0), "This token is present!");

        stockExchangeElements[_token] = StockExchangeElement(_agregator, _purse, _admin);
        tokensList.push(_token);

        emit AddToken(_token, _agregator, _purse, _admin);
    }

    function _remove(address _token) private{ 
        require(_token != address(0), "Token address is zero!");
        delete stockExchangeElements[_token];
        uint _length = tokensList.length;
        for(uint256 i = 0; i < _length; i++) {
            if(tokensList[i] == _token) {
                tokensList[i] = tokensList[_length-1];
                tokensList.pop();
                return;
            }
        }
    }

    function removeToken(address _token) public {
        require(_token != address(0), "Token address is zero!");
        StockExchangeElement storage _element = stockExchangeElements[_token];
        require(_element.agregator != address(0), "Token not found!");
        require(msg.sender==_element.admin, "You are not admin of this element!");
        address _admin = _element.admin;
        _remove(_token);
        I_Token(_token).transfer(_admin, I_Token(_token).balanceOf(address(this)));
        emit RemoveToken(_token, msg.sender);
    }

    function buyTokens(address _token) public payable{
        require(_token != address(0), "Token address is zero!");
        StockExchangeElement storage _element = stockExchangeElements[_token];
        (uint256 _price, uint256 _decimals) = getTokenPrice(_token);
        uint256 _numberTokens = (msg.value * _price) / (10**_decimals);
        if(I_Token(_token).balanceOf(address(this)) < _numberTokens)
        {
            (bool sent, bytes memory data) = msg.sender.call{value: msg.value}("Sorry, there is not enough tokens to buy");
            return;
        }
        _element.purse.transfer(msg.value);
        I_Token(_token).transfer(msg.sender, _numberTokens);
        emit BuyToken(_token, msg.sender, msg.value, _numberTokens);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}