/**
 *Submitted for verification at BscScan.com on 2022-01-08
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IBEP20 {
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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


contract StableDAOPresale is Ownable {
    event Invest( address indexed buyer, uint buyAmount, uint amount);
    event AddToken( address indexed buyer, address tokenAddress, uint startTime,uint endTime,uint amount);

    IBEP20 public token;
    AggregatorV3Interface public priceFeed;

    struct tokens{
        address tokenAddress;
        uint startTime;
        uint endTime;
        uint totalAmount;
        bool tokenStatus;
    }
    mapping(address => tokens)public tokenDetails;
    uint public price;
    uint[2] public total; //0- total raised, 1- total sold
    uint256 public limit = 500e18;
    constructor() {
         // mainnet
        // priceFeed = AggregatorV3Interface(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE);

        // testnet
        priceFeed = AggregatorV3Interface(0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526);
    }

   function addToken(address tokenAdd, uint startTime,uint endTime,uint256 amount) public onlyOwner{
        require(startTime > block.timestamp,"Start Time is Invalid");
        require(endTime > startTime,"End Time is Invalid");
        require(!tokenDetails[tokenAdd].tokenStatus,"Token Already added");
        
        tokenDetails[tokenAdd].tokenAddress = tokenAdd;
        tokenDetails[tokenAdd].startTime = startTime;
        tokenDetails[tokenAdd].endTime = endTime;
        tokenDetails[tokenAdd].totalAmount += amount;
        tokenDetails[tokenAdd].tokenStatus = true;
        IBEP20(tokenAdd).transferFrom(_msgSender(),address(this),amount);
        emit AddToken(_msgSender(),tokenAdd,startTime,endTime,amount);
    }

     function UpdateToken(address tokenAdd, uint startTime,uint endTime,uint256 amount) public onlyOwner{
            require(tokenDetails[tokenAdd].tokenStatus,"Token Not added Value");
            tokenDetails[tokenAdd].startTime = startTime;
            tokenDetails[tokenAdd].endTime = endTime;
            tokenDetails[tokenAdd].totalAmount += amount;
            IBEP20(tokenAdd).transferFrom(_msgSender(),address(this),amount);
     }
    
    receive() external payable {
        revert("No receive calls");
    }

    function setPrice(uint256 value) external onlyOwner {
        price = value;
    }

    function setLimit(uint256 value) external onlyOwner {
        limit = value;
    }

     function invest(address tokenAdd) external payable {
        require(price > 0,"Token Price is not Set");
        require(tokenDetails[tokenAdd].tokenStatus,"Token Not added");
        require(tokenDetails[tokenAdd].startTime < block.timestamp,"Token is Not Started");
        require(tokenDetails[tokenAdd].endTime > block.timestamp,"Token is End");
        require(msg.value > 0,"Invalid Value");

        uint value = cal(msg.value);
        require(value <= limit ,"Token Limit Exceed");
        require(IBEP20(tokenAdd).balanceOf(address(this)) >= value,"Token Transfer Failed");

        total[0] += msg.value;
        total[1] += value;
        tokenDetails[tokenAdd].totalAmount -= value;

        IBEP20(tokenAdd).transfer(msg.sender, value);
        emit Invest( msg.sender, msg.value, value);
    }


    function cal( uint amount) public view returns (uint) {
        uint256 usdPrice = getPrice() / 1e8;
        uint256 bnbPrice = usdPrice * amount;
        return price*bnbPrice/1e18;
    }

    function getPrice() public view returns (uint256) {
        (,int prices,,,) = priceFeed.latestRoundData();
        return uint256(prices);
    }

    function failcase( address tokenAdd, uint amount) external onlyOwner{
        address self = address(this);
        if(tokenAdd == address(0)) {
            require(self.balance >= amount);
            require(payable(owner()).send(amount));
        }
        else {
            require(IBEP20(tokenAdd).balanceOf(self) >= amount);
            require(IBEP20(tokenAdd).transfer(owner(),amount));
        }
    }
}