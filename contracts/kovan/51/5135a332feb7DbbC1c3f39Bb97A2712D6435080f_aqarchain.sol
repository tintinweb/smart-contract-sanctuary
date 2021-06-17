/**
 *Submitted for verification at Etherscan.io on 2021-06-17
*/

pragma solidity ^0.6.0;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}
// import ierc20 & safemath & non-standard
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

interface INonStandardERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256 balance);

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transfer` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    function transfer(address dst, uint256 amount) external;

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transferFrom` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external;

    function approve(address spender, uint256 amount)
        external
        returns (bool success);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );
}

abstract contract Context {
    function _msgSender() internal virtual view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal virtual view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract aqarchain is Ownable{
     using SafeMath for uint256;
     
     // Info of each user.
    struct UserInfo {
        string firstname;
        string lastname;
        string country;
        uint256 amount;    
        uint256 phase; 
        string aqarid;
        string modeofpayment;
    }
    
     IERC20 public token;
      mapping (address => UserInfo) public usermap;
      mapping (string => uint256) public amountmaptouser;
      uint256 public i=0;
      uint256 public seedprice = 4;
      uint256 public privateprice = 2857;
      uint256 public publicprice = 22;
      uint256 public seedamount;
      uint256 public privateamount;
      uint256 public publicamount;
      mapping(address=>bool) public isBlacklisted;
      
       IUniswapV2Router01 pancakerouter1;
    
     constructor(address _token) public {
        token = IERC20(_token);
          pancakerouter1 = IUniswapV2Router01(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
    }
      address[] private arr = [
        0xd0A1E359811322d97991E03f863a0C30C2cF029C, //WBNB
        0x07de306FF27a2B630B1141956844eB1552B956B5 //usdt
    ];

    function getBnbRate() public view returns (uint256) {
        uint256[] memory amounts = pancakerouter1.getAmountsOut(1e18, arr);
        return amounts[1];
    }
    function seedusdt(string calldata _first,string calldata _last,string calldata _country,string calldata _id, uint256 _amount)  external returns (uint aqarid){
        require(_amount!=0,"Enter some amount");
        require(isBlacklisted[msg.sender]!=true,"You have already purchased from this address");
        require(seedamount<=7000000000000000000000000,"seed round token sale completed");
        
        if(seedamount.add(_amount.mul(1e12).mul(seedprice))<=7000000000000000000000000){
        usermap[msg.sender]=UserInfo({firstname:_first,lastname:_last,country:_country,amount:_amount,phase:seedprice,aqarid:_id,modeofpayment:"usdt"});
        amountmaptouser[_id]=_amount.mul(1e12).mul(seedprice);
        doTransferIn(address(token), msg.sender, _amount);
        seedamount=seedamount.add(_amount.mul(1e12).mul(seedprice));
        isBlacklisted[msg.sender]=true;
        i++;
        }
        else{
            revert("seed round is over");
        }
    }
      function seedbnb(string calldata _first,string calldata _last,string calldata _country,string calldata _id) external payable {
        // user enter amount of ether which is then transfered into the smart contract and tokens to be given is saved in the mapping
        require(
            msg.value > 0,
            "the input bnb amount should be greater than zero"
        );
        require(isBlacklisted[msg.sender]!=true,"You have already purchased from this address");
        require(seedamount<=7000000000000000000000000,"seed round token sale completed");
      if(seedamount.add(msg.value.mul(1e12).mul(seedprice))<=7000000000000000000000000){
        usermap[msg.sender]=UserInfo({firstname:_first,lastname:_last,country:_country,amount:msg.value,phase:seedprice,aqarid:_id,modeofpayment:"BNB"});
        amountmaptouser[_id]=msg.value.mul(seedprice);
        seedamount=seedamount.add(msg.value.mul(getBnbRate()).mul(seedprice).div(1e18));
        isBlacklisted[msg.sender]=true;
        i++;
        }
        else{
            revert("seed round is over");
        }
    }
     function privateusdt(string calldata _first,string calldata _last,string calldata _country,string calldata _id, uint256 _amount)  external returns (uint aqarid){
        require(_amount!=0,"Enter some amount");
        require(isBlacklisted[msg.sender]!=true,"You have already purchased from this address");
        require(privateamount<=12000000000000000000000000,"private round token sale completed");
        
        if(privateamount.add(_amount.mul(1e12).mul(privateprice).div(1000))<=7000000000000000000000000){
        usermap[msg.sender]=UserInfo({firstname:_first,lastname:_last,country:_country,amount:_amount,phase:privateprice,aqarid:_id,modeofpayment:"usdt"});
        amountmaptouser[_id]=_amount.mul(1e12).mul(privateprice).div(1000);
        doTransferIn(address(token), msg.sender, _amount);
        privateamount=privateamount.add(_amount.mul(1e12).mul(privateprice).div(1000));
        isBlacklisted[msg.sender]=true;
        i++;
        }
        else{
            revert("private round is over");
        }
    }
      function privatebnb(string calldata _first,string calldata _last,string calldata _country,string calldata _id) external payable {
        // user enter amount of ether which is then transfered into the smart contract and tokens to be given is saved in the mapping
        require(
            msg.value > 0,
            "the input bnb amount should be greater than zero"
        );
        require(isBlacklisted[msg.sender]!=true,"You have already purchased from this address");
        require(privateamount<=12000000000000000000000000,"private round token sale completed");
      if(privateamount.add(msg.value.mul(1e12).mul(privateprice).div(1000))<=12000000000000000000000000){
        usermap[msg.sender]=UserInfo({firstname:_first,lastname:_last,country:_country,amount:msg.value,phase:privateprice,aqarid:_id,modeofpayment:"BNB"});
        amountmaptouser[_id]=msg.value.mul(privateprice).div(1000);
        privateamount=privateamount.add(msg.value.mul(getBnbRate()).mul(privateprice).div(1e18).div(1000));
        isBlacklisted[msg.sender]=true;
        i++;
        }
        else{
            revert("private round is over");
        }
    }
     function publicusdt(string calldata _first,string calldata _last,string calldata _country,string calldata _id, uint256 _amount)  external returns (uint aqarid){
        require(_amount!=0,"Enter some amount");
        require(isBlacklisted[msg.sender]!=true,"You have already purchased from this address");
        require(publicamount<=1000000000000000000000000,"public round token sale completed");
        
        if(publicamount.add(_amount.mul(1e12).mul(publicprice).div(10))<=1000000000000000000000000){
        usermap[msg.sender]=UserInfo({firstname:_first,lastname:_last,country:_country,amount:_amount,phase:publicprice,aqarid:_id,modeofpayment:"usdt"});
        amountmaptouser[_id]=_amount.mul(1e12).mul(publicprice).div(10);
        doTransferIn(address(token), msg.sender, _amount);
        publicamount=publicamount.add(_amount.mul(1e12).mul(publicprice).div(10));
        isBlacklisted[msg.sender]=true;
        i++;
        }
        else{
            revert("seed round is over");
        }
    }
    function publicbnb(string calldata _first,string calldata _last,string calldata _country,string calldata _id) external payable {
        // user enter amount of ether which is then transfered into the smart contract and tokens to be given is saved in the mapping
        require(
            msg.value > 0,
            "the input bnb amount should be greater than zero"
        );
        require(isBlacklisted[msg.sender]!=true,"You have already purchased from this address");
        require(privateamount<=1000000000000000000000000,"private round token sale completed");
      if(publicamount.add(msg.value.mul(1e12).mul(publicprice).div(10))<=1000000000000000000000000){
        usermap[msg.sender]=UserInfo({firstname:_first,lastname:_last,country:_country,amount:msg.value,phase:publicprice,aqarid:_id,modeofpayment:"BNB"});
        amountmaptouser[_id]=msg.value.mul(publicprice).div(10);
        publicamount=privateamount.add(msg.value.mul(getBnbRate()).mul(publicprice).div(1e18).div(10));
        isBlacklisted[msg.sender]=true;
        i++;
        }
        else{
            revert("private round is over");
        }
    }
    
    
     function getBnbBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function adminTransferBnbFund() external onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    function getContractTokenBalance(IERC20 _token)
        public
        view
        returns (uint256)
    {
        return _token.balanceOf(address(this));
    }

    function fundsWithdrawal(IERC20 _token, uint256 value) external onlyOwner {
        require(
            getContractTokenBalance(_token) >= value,
            "the contract doesnt have tokens"
        );
        
            return doTransferOut(address(_token), msg.sender, value);

    }
    
     function doTransferIn(
        address tokenAddress,
        address from,
        uint256 amount
    ) internal returns (uint256) {
        INonStandardERC20 _token = INonStandardERC20(tokenAddress);
        uint256 balanceBefore = IERC20(tokenAddress).balanceOf(address(this));
        _token.transferFrom(from, address(this), amount);

        bool success;
        assembly {
            switch returndatasize()
                case 0 {
                    // This is a non-standard ERC-20
                    success := not(0) // set success to true
                }
                case 32 {
                    // This is a compliant ERC-20
                    returndatacopy(0, 0, 32)
                    success := mload(0) // Set `success = returndata` of external call
                }
                default {
                    // This is an excessively non-compliant ERC-20, revert.
                    revert(0, 0)
                }
        }
        require(success, "TOKEN_TRANSFER_IN_FAILED");

        // Calculate the amount that was actually transferred
        uint256 balanceAfter = IERC20(tokenAddress).balanceOf(address(this));
        require(balanceAfter >= balanceBefore, "TOKEN_TRANSFER_IN_OVERFLOW");
        return balanceAfter-balanceBefore; // underflow already checked above, just subtract
    }

    /**
     * @dev Similar to EIP20 transfer, except it handles a False success from `transfer` and returns an explanatory
     *      error code rather than reverting. If caller has not called checked protocol's balance, this may revert due to
     *      insufficient cash held in this contract. If caller has checked protocol's balance prior to this call, and verified
     *      it is >= amount, this should not revert in normal conditions.
     *
     *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
     *            See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
     */
    function doTransferOut(
        address tokenAddress,
        address to,
        uint256 amount
    ) internal {
        INonStandardERC20 _token = INonStandardERC20(tokenAddress);
        _token.transfer(to, amount);

        bool success;
        assembly {
            switch returndatasize()
                case 0 {
                    // This is a non-standard ERC-20
                    success := not(0) // set success to true
                }
                case 32 {
                    // This is a complaint ERC-20
                    returndatacopy(0, 0, 32)
                    success := mload(0) // Set `success = returndata` of external call
                }
                default {
                    // This is an excessively non-compliant ERC-20, revert.
                    revert(0, 0)
                }
        }
        require(success, "TOKEN_TRANSFER_OUT_FAILED");
    }
}