/**
 *Submitted for verification at BscScan.com on 2021-07-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

//-----------------------------------------------------------------------------//
//                             Name : MultiPad                                 //
//                           Symbol : MPAD                                     //
//                     Total Supply : 100,000,000                              //
//                  Company Reserve : 25,000,000                               //
//          Marketing and ecosystem : 20,000,000                               //
//                             Team : 20,000,000                               //
//                        Liquidity : 10,000,000                               //
//                    IDO fundraise : 15,000,000                               //
//       Partners & Early Investors : 10,000,000                               //
//-----------------------------------------------------------------------------//

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IBEP20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error.
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b,"Invalid values");
        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0,"Invalid values");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a,"Invalid values");
        uint256 c = a - b;
        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a,"Invalid values");
        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0,"Invalid values");
        return a % b;
    }
}
interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity >=0.6.2;


library Utils {
    using SafeMath for uint256;

    function random(uint256 from, uint256 to, uint256 salty) private view returns (uint256) {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp + block.difficulty +
                    ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)) +
                    block.gaslimit +
                    ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (now)) +
                    block.number +
                    salty
                )
            )
        );
        return seed.mod(to - from) + from;
    }

    function isLotteryWon(uint256 salty, uint256 winningDoubleRewardPercentage) private view returns (bool) {
        uint256 luckyNumber = random(0, 100, salty);
        uint256 winPercentage = winningDoubleRewardPercentage;
        return luckyNumber <= winPercentage;
    }

    function calculateBNBReward(
        uint256 _tTotal,
        uint256 currentBalance,
        uint256 currentBNBPool,
        uint256 winningDoubleRewardPercentage,
        uint256 totalSupply,
        address ofAddress
    ) public view returns (uint256) {
        uint256 bnbPool = currentBNBPool;

        // calculate reward to send
        bool isLotteryWonOnClaim = isLotteryWon(currentBalance, winningDoubleRewardPercentage);
        uint256 multiplier = 100;

        if (isLotteryWonOnClaim) {
            multiplier = random(150, 200, currentBalance);
        }

        // now calculate reward
        uint256 reward = bnbPool.mul(multiplier).mul(currentBalance).div(100).div(totalSupply);

        return reward;
    }

    function calculateTopUpClaim(
        uint256 currentRecipientBalance,
        uint256 basedRewardCycleBlock,
        uint256 threshHoldTopUpRate,
        uint256 amount
    ) public returns (uint256) {
        if (currentRecipientBalance == 0) {
            return block.timestamp + basedRewardCycleBlock;
        }
        else {
            uint256 rate = amount.mul(100).div(currentRecipientBalance);

            if (uint256(rate) >= threshHoldTopUpRate) {
                uint256 incurCycleBlock = basedRewardCycleBlock.mul(uint256(rate)).div(100);

                if (incurCycleBlock >= basedRewardCycleBlock) {
                    incurCycleBlock = basedRewardCycleBlock;
                }

                return incurCycleBlock;
            }

            return 0;
        }
    }

    function swapTokensForEth(
        address routerAddress,
        uint256 tokenAmount
    ) public {
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(routerAddress);

        // generate the pancake pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeRouter.WETH();

        // make the swap
        pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp
        );
    }

    function swapETHForTokens(
        address routerAddress,
        address recipient,
        uint256 ethAmount
    ) public {
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(routerAddress);

        // generate the pancake pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = pancakeRouter.WETH();
        path[1] = address(this);

        // make the swap
        pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}(
            0, // accept any amount of BNB
            path,
            address(recipient),
            block.timestamp + 360
        );
    }

    function addLiquidity(
        address routerAddress,
        address owner,
        uint256 tokenAmount,
        uint256 ethAmount
    ) public {
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(routerAddress);

        // add the liquidity
        pancakeRouter.addLiquidityETH{value : ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner,
            block.timestamp + 360
        );
    }
}



contract MultiPad is IBEP20 {
    
    using SafeMath for uint256;
    
    //variable declaration
    address private _owner;
    string private _name;
    string private _symbol;
    uint8 private _decimals = 18;
    uint256 private _totalSupply;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;
    
    // Special business use case variables
    mapping (address => bool) _whitelistedAddress;
    mapping (address => uint256) _lockingTimeForSale;
    mapping (address => uint256) _recordSale;
    mapping (address => bool) _addressLocked;
    mapping (address => uint256) _finalSoldAmount;
    mapping (address => mapping(uint256 => bool)) reEntrance;
    
    address[] private _whitelistedUserAddresses;
    uint256 private saleStartTime;
    uint256 private saleEndTime;
    uint256 private saleMinimumAmount;
    uint256 private saleMaximumAmount;
    uint256 private saleId = 0;
    uint256 private tokenPrice;
    uint256 private deploymentTime; 
    uint256 private decimalBalancer = 1000000000;
    uint256 private ReserveAmount = 25000000*(10**uint256(_decimals));
    uint256 private MarketingAmount = 20000000*(10**uint256(_decimals));
    uint256 private Team1Amount = 18000000*(10**uint256(_decimals));
    uint256 private Team2Amount = 2000000*(10**uint256(_decimals));
    uint256 private LiquidityAmount = 10000000*(10**uint256(_decimals));
    uint256 private IDOAmount = 15000000*(10**uint256(_decimals));
    uint256 private PartnersAmount = 10000000*(10**uint256(_decimals));
    bool whitelistFlag = true;
    address private Reserve = 0xfcE75ef6753A8DD25c427C05598AABE69C01240F;
    address private Marketing = 0x7a51EceA47a55F388F6f723EBd080A7B777b9c6F;
    address private Team1 = 0xEe83715c1dbFD1363F2aA230A0AFfe076234CE28;
    address private Team2 = 0xEe83715c1dbFD1363F2aA230A0AFfe076234CE28;
    address private Liquidity = 0xaDF20cF44Ef922A3c1Da2EE60ff72eE414930E94;
    address private IDO = 0x3f72CB11e371EF521F53E23165D9F432E631Bf54;
    address private Partners = 0x3f72CB11e371EF521F53E23165D9F432E631Bf54;
    

    constructor (string memory name, string memory symbol, uint256 totalSupply, address owner) public {
        _name = name;
        _symbol = symbol; 
        _totalSupply = totalSupply*(10**uint256(_decimals));
        _balances[owner] = _totalSupply;
        _owner = owner;
        _addressLocked[Reserve] = true;
        _addressLocked[Marketing] = true;
        _addressLocked[Team1] = true;
        _addressLocked[Liquidity] = true;
        _addressLocked[Partners] = true;
         deploymentTime =  block.timestamp;
         initiateValues();
    }
    
    function initiateValues() internal {
        _transfer(_owner,Reserve,ReserveAmount);
        _transfer(_owner,Marketing,MarketingAmount);
        _transfer(_owner,Team1,Team1Amount); 
        _transfer(_owner,Team2,Team2Amount);
        _transfer(_owner,Liquidity,LiquidityAmount);       
        _transfer(_owner,IDO,IDOAmount);
        _transfer(_owner,Partners,PartnersAmount);
    }


    /* ----------------------------------------------------------------------------
     * View only functions
     * ----------------------------------------------------------------------------
     */

    /**
     * @return the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @return the symbol of the token.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Total number of tokens in existence.
     */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @return the number of decimals of the token.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    
    /**
     * @dev Gets the balance of the specified address.
     * @param owner The address to query the balance of.
     * @return A uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address owner) public override view returns (uint256) {
        return _balances[owner];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowed[owner][spender];
    }

    /* ----------------------------------------------------------------------------
     * Transfer, allow and burn functions
     * ----------------------------------------------------------------------------
     */

    /**
     * @dev Transfer token to a specified address.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function transfer(address to, uint256 value) public override checkLockedAddresses(msg.sender) returns (bool) {
            _transfer(msg.sender, to, value);
            return true;
    }

    /**
     * @dev Transfer tokens from one address to another.
     * Note that while this function emits an Approval event, this is not required as per the specification,
     * and other compliant implementations may not emit the event.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 value) public override checkLockedAddresses(from) returns (bool) {
             _transfer(from, to, value);
             _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
             return true;
    }

     /**
      * @dev Airdrop function to airdrop tokens. Best works upto 50 addresses in one time. Maximum limit is 200 addresses in one time.
      * @param _addresses array of address in serial order
      * @param _amount amount in serial order with respect to address array
      */
      function airdropByOwner(address[] memory _addresses, uint256[] memory _amount) public onlyOwner returns (bool){
          require(_addresses.length == _amount.length,"Invalid Array");
          uint256 count = _addresses.length;
          uint256 airdropcount = 0;
          for (uint256 i = 0; i < count; i++){
               _transfer(msg.sender, _addresses[i], _amount[i]);
               airdropcount = airdropcount + 1;
          }
          return true;
      }

    /**
     * @dev Transfer token for a specified addresses.
     * @param from The address to transfer from.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0),"Invalid to address");
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) public override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Approve an address to spend another addresses' tokens.
     * @param owner The address that owns the tokens.
     * @param spender The address that will spend the tokens.
     * @param value The number of tokens that can be spent.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0),"Invalid address");
        require(owner != address(0),"Invalid address");
        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when _allowed[msg.sender][spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when _allowed[msg.sender][spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account.
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0),"Invalid account");
        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Burns a specific amount of tokens.
     * @param value The amount of token to be burned.
     */
    function burn(uint256 value) public onlyOwner{
        _burn(msg.sender, value);
    }
    
    /*----------------------------------------------------------------------------
     * Functions for owner
     *----------------------------------------------------------------------------
    */

    /**
    * @dev get address of smart contract owner
    * @return address of owner
    */
    function getowner() public view returns (address) {
        return _owner;
    }

    /**
    * @dev modifier to check if the message sender is owner
    */
    modifier onlyOwner() {
        require(isOwner(),"You are not authenticate to make this transfer");
        _;
    }

    /**
     * @dev Internal function for modifier
     */
    function isOwner() internal view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Transfer ownership of the smart contract. For owner only
     * @return request status
      */
    function transferOwnership(address newOwner) public onlyOwner returns (bool){
        _owner = newOwner;
        return true;
    }

    /* ----------------------------------------------------------------------------
     *  Functions for Additional Business Logic For Owner Functions
     * ----------------------------------------------------------------------------
     */
     
     /**
     * @dev Whitelist Addresses for further transactions
     * @param _userAddresses  Array of user addresses
     */
     function whitelistUserAdress(address[] calldata _userAddresses) external onlyOwner returns(bool){
         uint256 count = _userAddresses.length;
          for (uint256 i = 0; i < count; i++){
               _whitelistedUserAddresses.push(_userAddresses[i]);
               _whitelistedAddress[_userAddresses[i]] = true;
          }
         return true;
     }
     
     /**
     * @dev get the list of whitelisted addresses
     */
     function getWhitelistUserAdress() public view returns(address[] memory){
         return _whitelistedUserAddresses;
     }
     
     /**
     * @dev Set sale parameters for users to buy new tokens
     * @param _startTime Start time of the sale
     * @param _endTime End time of the sale
     * @param _minimumAmount Minimum accepted amount
     * @param _maximumAmount Maximum accepted amount
     */
     function setSaleParameter(
         uint256 _startTime,
         uint256 _endTime,
         uint256 _minimumAmount,
         uint256 _maximumAmount,
         bool _whitelistFlag
         ) external onlyOwner returns(bool){
          saleStartTime = _startTime;
          saleEndTime = _endTime;
          saleMinimumAmount = _minimumAmount;
          saleMaximumAmount = _maximumAmount;
          saleId = saleId + 1;
          whitelistFlag = _whitelistFlag;
         return true;
     }
     
     /**
     * @dev Get Sale Details Description
     */
     function getSaleParameter() external view returns(
         uint256 _startTime,
         uint256 _endTime,
         uint256 _minimumAmount,
         uint256 _maximumAmount,
         uint256 _saleId
         ){
          _startTime  =  saleStartTime;
          _endTime = saleEndTime;
          _minimumAmount = saleMinimumAmount;
          _maximumAmount = saleMaximumAmount;
          _saleId = saleId;
     }
     
     /**
     * @dev Owner can set token price
     * @param _tokenPrice price of 1 Token
     */
     function setTokenPrice(
         uint256 _tokenPrice
         ) external onlyOwner returns(bool){
          tokenPrice = _tokenPrice;
         return true;
     }
     
     /**
     * @dev Get token price
     */
     function getTokenPrice() external view returns(uint256){
          return tokenPrice;
     }
     
     
    /* ----------------------------------------------------------------------------
     *  Functions for Additional Business Logic For Users 
     * ----------------------------------------------------------------------------
     */    
     
    modifier checkSaleValidations(address _userAddress, uint256 _value){
     if(whitelistFlag == true){    
     require(_whitelistedAddress[_userAddress] == true, "Address not Whitelisted" );
     }
     require(saleStartTime < block.timestamp , "Sale not started");
     require(saleEndTime > block.timestamp, "Sale Ended");
     require(_value > saleMinimumAmount && _value < saleMaximumAmount, "Amount not appropriate");
     require(_value.mul(tokenPrice) <= saleMaximumAmount , "Amount Exceeded Maximum Purchaseable Amount");
     require(_value.mul(tokenPrice) >= saleMinimumAmount , "Amount is not sufficient for this round");
        _;
    }
    
    /*
     * @dev Get Purchaseable amount
     */
      function getPurchaseableTokens() external view returns(uint256){
         return balanceOf(IDO);
     }
    
    /*
     * @dev Buy New tokens from the sale
     */
     function buyTokens() payable external checkSaleValidations(msg.sender, msg.value) returns(bool){
         _trasferInLockingState(msg.sender, msg.value);
         return true;
     }
     
     /*
      * @dev Internal function to achieve 
      */
     function _trasferInLockingState(
         address _userAddress,
         uint256 _amountTransfer
         ) internal returns(bool){
        _lockingTimeForSale[_userAddress] = block.timestamp;
        uint256 earnedTokens = _recordSale[_userAddress].add((_amountTransfer.mul(tokenPrice)).div(decimalBalancer));
        _recordSale[_userAddress] = earnedTokens;
        _finalSoldAmount[_userAddress] = earnedTokens;
         return true;
     }
     
    //function to withdraw purchased tokens
    function claimPurchasedTokens(uint256 _lockNumber) external validateClaim(msg.sender,_lockNumber) returns (bool){
        _transfer(IDO,msg.sender,_finalSoldAmount[msg.sender].div(4));
        _recordSale[msg.sender] = _recordSale[msg.sender].sub(_finalSoldAmount[msg.sender].div(4));
        reEntrance[msg.sender][_lockNumber] = true;
    }
    
    //validate claim tokens
    modifier validateClaim(address _userAddress, uint256 _lockNumber)
    {
        require(_recordSale[_userAddress] > 0, "Not sufficient purchase Balance");
        require(_lockNumber == 1 || _lockNumber == 2 || _lockNumber == 3 || _lockNumber == 4 || _lockNumber == 5, "Invalid Lock Number");
        if(block.timestamp > saleEndTime && block.timestamp < saleEndTime +1209600 && _lockNumber == 1){
            require(reEntrance[_userAddress][_lockNumber] != true, "Insufficient Unlocked Tokens");
        }
        if(block.timestamp > saleEndTime + 1209600 && block.timestamp < saleEndTime +2419200){
            require(reEntrance[_userAddress][_lockNumber] != true , "Insufficient Unlocked Tokens");
        }
        if(block.timestamp > saleEndTime + 2419200 && block.timestamp < saleEndTime +3628800){
            require(reEntrance[_userAddress][_lockNumber] != true ,  "Insufficient Unlocked Tokens");
        }
        if(block.timestamp > saleEndTime + 3628800 && block.timestamp < saleEndTime +4838400){
            require(reEntrance[_userAddress][_lockNumber] != true,  "Insufficient Unlocked Tokens");
        }
        else{
           require(block.timestamp > saleEndTime + 4838400 && _lockNumber == 5, "Fully unlock not reached");
        }
        _;
    }
    
    //function to check if the user is whitelisted or not 
    function checkWhitelistedAdddress(address _userAddress) view external returns(bool){
        require(_userAddress != address(0), "addresses should not be 0");
        return _whitelistedAddress[_userAddress];
    }
    
    
    modifier checkLockedAddresses(address _lockedAddresses){
           require(_addressLocked[_lockedAddresses] != true, "Locking Address");
       _;
    }
    
    function withdrawSpecialLocked(address _toAddress, uint256 _amount) checkLockingRoles(msg.sender, _amount) external returns(bool){
        require(msg.sender == Team1 || msg.sender == Team2 || msg.sender == Partners || msg.sender == Liquidity , "Only for Special Addresses");
        require(_amount != 0, "amount should not be 0");
       _transfer(msg.sender, _toAddress, _amount);
    }
    
    //To withdraw all bnb from smart contract to user admin address 
    function withdrawBNB(uint256 _amount) external onlyOwner returns(bool){
        msg.sender.transfer(_amount);
        return true;
    }
    
    //Check Contract Balance 
    function checkContractBnbBalance() external view returns(uint256){
        return address(this).balance;
    }
    
    function getUserTokensBy(address _userAddress) public view returns(uint256 _div1, uint256 _div2, uint256 _div3, uint256 _div4){
        uint256 division = _finalSoldAmount[_userAddress].div(4);
        _div1 = division;
        _div2 = division;
        _div3 = division;
        _div4 = division;
        if(reEntrance[_userAddress][1] == true){
            _div1 = 0;
        }
        if(reEntrance[_userAddress][2] == true){
            _div2 = 0;
        }
        if(reEntrance[_userAddress][3] == true){
            _div3 = 0;
        }
        if(reEntrance[_userAddress][4] == true){
            _div4 = 0;
        }
        return(_div1,_div2,_div3,_div4);
    }
    
    //check contract balance 
    function checkContractBNBBalance() public view returns(uint256 _bal){
        return address(this).balance;
    }
    
    //check contract block.timestamp time 
    function checkContractTime() public view returns(uint256){
        return block.timestamp;
    }
   
    // to check locked tokens for marketing address, Reserve, Partners, Liquidity and Team  
    modifier checkLockingRoles(address _add, uint256 _amountRequested){
       if(_add == Reserve){
           require(block.timestamp > deploymentTime+31556926, "Tokens are locked for 1 years from TGE");
         }
       if(_add == Marketing){
           if(block.timestamp > deploymentTime && block.timestamp < deploymentTime + 2629743){                                                   // First month from the deployment & 10%
              require(MarketingAmount.sub(_amountRequested) >= 18000000000000000000, "Amount exceded lock 1");
           }
           if(block.timestamp > deploymentTime + 2629743 && block.timestamp < deploymentTime + 5259486){                                         // Second month from the deployment & 10%
               require(MarketingAmount.sub(_amountRequested) >= 16000000000000000000, "Amount exceded lock 2");
           }
           if(block.timestamp > deploymentTime + 5259486 && block.timestamp < deploymentTime + 7889229){                                         // Third month from the deployment & 10%
               require(MarketingAmount.sub(_amountRequested) >= 14000000000000000000, "Amount exceded lock 3");
           }
           if(block.timestamp > deploymentTime + 7889229 && block.timestamp < deploymentTime + 10518972){                                        // Fourth month from the deployment & 10%
               require(MarketingAmount.sub(_amountRequested) >= 12000000000000000000, "Amount exceded lock 4");
           }
           if(block.timestamp > deploymentTime + 10518972 && block.timestamp < deploymentTime + 13148715){                                       // Fifth month from the deployment & 10%
               require(MarketingAmount.sub(_amountRequested) >= 10000000000000000000, "Amount exceded lock 5");
           }
           if(block.timestamp > deploymentTime + 13148715 && block.timestamp < deploymentTime + 15778458){                                       // Sixth month from the deployment & 10%
               require(MarketingAmount.sub(_amountRequested) >= 8000000000000000000, "Amount exceded lock 6");
           }
           if(block.timestamp > deploymentTime + 15778458 && block.timestamp < deploymentTime + 18408201){                                       // Seventh month from the deployment & 10% 
               require(MarketingAmount.sub(_amountRequested) >= 6000000000000000000, "Amount exceded lock 7");
           }
           if(block.timestamp > deploymentTime + 18408201 && block.timestamp < deploymentTime + 21037944){                                       // Eighth month from the deployment & 10%
               require(MarketingAmount.sub(_amountRequested) >= 4000000000000000000, "Amount exceded lock 8");
           }
           if(block.timestamp > deploymentTime + 21037944 && block.timestamp < deploymentTime + 23667687){                                       // Ninth month from the deployment & 10%
               require(MarketingAmount.sub(_amountRequested) >= 2000000000000000000, "Amount exceded lock 9");
           }
         }
       if(_add == Team1){
           if(block.timestamp > deploymentTime + 15778458 && block.timestamp < deploymentTime + 2629743){                                        // Sixth to Seventh Month
               require(Team1Amount.sub(_amountRequested) >= 1620000000000000000000000, "Amount exceded lock 1");
           }
            if(block.timestamp > deploymentTime + 2629743 && block.timestamp < deploymentTime + 21037944){                                        // Seventh to Eighth Month
               require(Team1Amount.sub(_amountRequested) >= 1440000000000000000000000, "Amount exceded lock 2");
           }
            if(block.timestamp > deploymentTime + 21037944 && block.timestamp < deploymentTime + 23667687){                                        // Eighth to Ninth Month
               require(Team1Amount.sub(_amountRequested) >= 1260000000000000000000000, "Amount exceded lock 3");
           }
            if(block.timestamp > deploymentTime + 23667687 && block.timestamp < deploymentTime + 26297430){                                        // Ninth to Tenth Month
               require(Team1Amount.sub(_amountRequested) >= 1080000000000000000000000, "Amount exceded lock 4");
           }
            if(block.timestamp > deploymentTime + 26297430 && block.timestamp < deploymentTime + 28927173){                                        // Tenth to Eleventh Month
               require(Team1Amount.sub(_amountRequested) >= 900000000000000000000000, "Amount exceded lock 5");
           }
            if(block.timestamp > deploymentTime + 28927173 && block.timestamp < deploymentTime + 31556916){                                        // Eleventh to Twelveth Month
               require(Team1Amount.sub(_amountRequested) >= 720000000000000000000000, "Amount exceded lock 6");
           }
            if(block.timestamp > deploymentTime + 31556916 && block.timestamp < deploymentTime + 34186659){                                        // Twelveth to Thirteenth Month
               require(Team1Amount.sub(_amountRequested) >= 540000000000000000000000, "Amount exceded lock 7");
           }
            if(block.timestamp > deploymentTime + 34186659 && block.timestamp < deploymentTime + 36816402){                                        // Thirteenth to Fourteenth Month
               require(Team1Amount.sub(_amountRequested) >= 360000000000000000000000, "Amount exceded lock 8");
           }
            if(block.timestamp > deploymentTime + 36816402 && block.timestamp < deploymentTime + 39446145){                                        // Fourteenth to Fifteenth Month
               require(Team1Amount.sub(_amountRequested) >= 180000000000000000000000, "Amount exceded lock 9");
           }
         }
          if(_add == Team2){   
           if(block.timestamp > deploymentTime + 15778458 && block.timestamp < deploymentTime + 2629743){                                          // Sixth to Seventh Month
               require(Team2Amount.sub(_amountRequested) >= 1800000000000000000000000, "Amount exceded lock 1");
           }
            if(block.timestamp > deploymentTime + 2629743 && block.timestamp < deploymentTime + 21037944){                                         // Seventh to Eighth Month
               require(Team2Amount.sub(_amountRequested) >= 1600000000000000000000000, "Amount exceded lock 2");
           }
            if(block.timestamp > deploymentTime + 21037944 && block.timestamp < deploymentTime + 23667687){                                        // Eighth to Ninth Month
               require(Team2Amount.sub(_amountRequested) >= 1400000000000000000000000, "Amount exceded lock 3");
           }
            if(block.timestamp > deploymentTime + 23667687 && block.timestamp < deploymentTime + 26297430){                                        // Ninth to Tenth Month
               require(Team2Amount.sub(_amountRequested) >= 1200000000000000000000000, "Amount exceded lock 4");
           }
            if(block.timestamp > deploymentTime + 26297430 && block.timestamp < deploymentTime + 28927173){                                        // Tenth to Eleventh Month
               require(Team2Amount.sub(_amountRequested) >= 1000000000000000000000000, "Amount exceded lock 5");
           }
            if(block.timestamp > deploymentTime + 28927173 && block.timestamp < deploymentTime + 31556916){                                        // Eleventh to Twelveth Month
               require(Team2Amount.sub(_amountRequested) >= 800000000000000000000000, "Amount exceded lock 6");
           }
            if(block.timestamp > deploymentTime + 31556916 && block.timestamp < deploymentTime + 34186659){                                        // Twelveth to Thirteenth Month
               require(Team2Amount.sub(_amountRequested) >= 600000000000000000000000, "Amount exceded lock 7");
           }
            if(block.timestamp > deploymentTime + 34186659 && block.timestamp < deploymentTime + 36816402){                                        // Thirteenth to Fourteenth Month
               require(Team2Amount.sub(_amountRequested) >= 400000000000000000000000, "Amount exceded lock 8");
           }
            if(block.timestamp > deploymentTime + 36816402 && block.timestamp < deploymentTime + 39446145){                                        // Fourteenth to Fifteenth Month
               require(Team2Amount.sub(_amountRequested) >= 200000000000000000000000, "Amount exceded lock 9");
           }
         }
         if(_add == Partners){ 
            if(block.timestamp > deploymentTime && block.timestamp < deploymentTime + 1209600){                                                     //One to Four week
               require(PartnersAmount.sub(_amountRequested) >= 8000000000000000000000000, "Amount exceded lock 1");
           }
            if(block.timestamp > deploymentTime + 1209600 && block.timestamp < deploymentTime + 2419200){                                           //Four to Six week
               require(PartnersAmount.sub(_amountRequested) >= 6000000000000000000000000, "Amount exceded lock 2");
           }
            if(block.timestamp > deploymentTime + 2419200 && block.timestamp < deploymentTime + 3628800){                                           //Six to Eighth week
               require(PartnersAmount.sub(_amountRequested) >= 4000000000000000000000000, "Amount exceded lock 3");
           }
            if(block.timestamp > deploymentTime + 3628800 && block.timestamp < deploymentTime + 4838400){                                            //Eighth to Tenth week
               require(PartnersAmount.sub(_amountRequested) >= 2000000000000000000000000, "Amount exceded lock 4");
           }
         }
         if(_add == Liquidity){
             if(block.timestamp > deploymentTime && block.timestamp < deploymentTime + 2629743){                                                     //One to Two Month
               require(LiquidityAmount.sub(_amountRequested) >= 8000000000000000000000000, "Amount exceded lock 1");
           }
            if(block.timestamp > deploymentTime + 2629743 && block.timestamp < deploymentTime + 5259486){                                            //Two to Three week
               require(LiquidityAmount.sub(_amountRequested) >= 6000000000000000000000000, "Amount exceded lock 2");
           }
            if(block.timestamp > deploymentTime + 5259486 && block.timestamp < deploymentTime + 7889229){                                            //Three to Four week
               require(LiquidityAmount.sub(_amountRequested) >= 4000000000000000000000000, "Amount exceded lock 3");
           }
            if(block.timestamp > deploymentTime + 7889229 && block.timestamp < deploymentTime + 6048000){                                            //Four to Fifth week
               require(LiquidityAmount.sub(_amountRequested) >= 2000000000000000000000000, "Amount exceded lock 4");
           }
         }
        _;
     }
}