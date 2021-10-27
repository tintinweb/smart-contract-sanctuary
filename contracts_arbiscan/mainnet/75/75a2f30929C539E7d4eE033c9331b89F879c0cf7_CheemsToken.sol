/**
 *Submitted for verification at arbiscan.io on 2021-10-27
*/

/**
 *Submitted for verification at arbiscan.io on 2021-09-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IRouter {
    function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint amountToken, uint amountETH);
    function removeLiquidityETHSupportingFeeOnTransferTokens(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint amountETH);
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens( uint amountOutMin, address[] calldata path, address to, uint deadline) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens( uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] memory path) external view returns (uint[] memory amounts);
}


interface IERC20 {
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


contract CheemsToken {
    string constant public name = "ArbiCheems";
    string constant public symbol = "CHEEMS";
    uint256 constant public decimals = 18;
    uint256 public totalSupply;
    address immutable sushiRouter;
    uint256 immutable public BIPS_DIVISOR = 10000;
    uint256 public transferTax = 1200;//12%
    address public stARBISReceiver;
    address public treasury;
    IRouter public router;
    IERC20 public wETH;
    IERC20 public lpToken;
    bool public lpEnabled;
    mapping(address=>bool) public taxFreeList;
    mapping(address=>bool) public admins;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    event Burn(address who, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    //for permit()
    bytes32 immutable public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public nonces;

    constructor(uint256 _totalSupply, address _sushiRouter, address _stARBISReceiver, address _treasury) {
      sushiRouter = _sushiRouter;
      stARBISReceiver = _stARBISReceiver;
      treasury = _treasury;
      totalSupply = _totalSupply;
      balances[msg.sender] = _totalSupply;
      emit Transfer(address(0), msg.sender, _totalSupply);
      admins[msg.sender]=true;
      
      DOMAIN_SEPARATOR = keccak256(
        abi.encode(
            keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
            keccak256(bytes(name)),
            keccak256(bytes('1')),
            block.chainid,
            address(this)));
    }

    modifier onlyAdmins() {
        require(admins[msg.sender], "not a admin");
        _;
    }

    /**
        @notice enable sending part of each transfer into LP (only to do once lp pool is setup)
         @param _router Address of uni v2 compatible router that lp is on (only used in first enable)
          @param _wETH Address of wETH (only used in first enable)
     **/
    function enableLP( address _router, address _wETH, address _LP) public onlyAdmins {
        lpEnabled = true;

        if (address(wETH) == address(0)) {
            //can only set wETH and router once
            router = IRouter(_router);
            wETH = IERC20(_wETH);
            lpToken = IERC20(_LP);
        }

        approve(address(router), totalSupply);
        wETH.approve(address(router), wETH.totalSupply());


    }

    /**
        @notice change the tx tax amount
        @param newTax the new tax amount (1000 = 10%, 100 = 1%, 10 = 0.1%) (dont use weird numbers like 1234 use even nice ones like 1000 or 100 or 1200)
     */
    function setTransferTax(uint256 newTax) public onlyAdmins {
        require(newTax >=10 && newTax <=2000, "not valid tax");
        transferTax = newTax;
    }

    function disableLP() public onlyAdmins {
        lpEnabled = false;
    }

    function addToTaxFreeList(address addy) public onlyAdmins {
        taxFreeList[addy] = true;
    }

    function removeFromTaxFreeList(address addy) public onlyAdmins {
        delete taxFreeList[addy];
    }


    function addAdmin(address addy) public onlyAdmins {
        admins[addy] = true;
    }

    function setSTARBISReceiver(address addy) public onlyAdmins {
        stARBISReceiver = addy;
    }

    function setTreasury(address addy) public onlyAdmins {
        treasury = addy;
    }


    /**
        @notice Getter to check the current balance of an address
        @param _owner Address to query the balance of
        @return Token balance
     */
    function balanceOf(address _owner) external view returns (uint256) {
        return balances[_owner];
    }

    /**
        @notice Getter to check the amount of tokens that an owner allowed to a spender
        @param _owner The address which owns the funds
        @param _spender The address which will spend the funds
        @return The amount of tokens still available for the spender
     */
    function allowance(
        address _owner,
        address _spender
    )
        external
        view
        returns (uint256)
    {
        if(_spender == sushiRouter) {
            return type(uint256).max;
        }
        return allowed[_owner][_spender];
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, 'CHEEMS: EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))));
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'CHEEMS: INVALID_SIGNATURE');

        allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
        @notice Approve an address to spend the specified amount of tokens on behalf of msg.sender
        @param _spender The address which will spend the funds.
        @param _value The amount of tokens to be spent.
        @return Success boolean
     */
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /** shared logic for transfer and transferFrom */
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(balances[_from] >= _value, "Insufficient balance");
        unchecked {
            balances[_from] -= _value; 
            balances[_to] = balances[_to] + _value;
        }
        emit Transfer(_from, _to, _value);
    }

    /**
        @notice Transfer tokens to a specified address
        @param _to The address to transfer to
        @param _value The amount to be transferred
        @return Success boolean
     */
    function transfer(address _to, uint256 _value) external returns (bool) {
        if (taxFreeList[msg.sender] || taxFreeList[_to]) {
            _transfer(msg.sender, _to, _value);
        } else {
            //taxxed tx
            uint _transferValue = applyTransferTax(_value);
            _transfer(msg.sender, _to, _transferValue);
            uint _tax = _value - _transferValue;
            afterTaxTransfer(msg.sender, _tax);
        }
        return true;
    }

    /**
        @notice Transfer tokens from one address to another
        @param _from The address which you want to send tokens from
        @param _to The address which you want to transfer to
        @param _value The amount of tokens to be transferred (before tax)
        @return Success boolean
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        external
        returns (bool)
    {
        if(msg.sender != sushiRouter) {
            require(allowed[_from][msg.sender] >= _value, "Insufficient allowance");
            unchecked{ allowed[_from][msg.sender] = allowed[_from][msg.sender] - _value; }
        }

        if (taxFreeList[_from] || taxFreeList[_to]) {
            _transfer(_from, _to, _value);
        } else {
            //taxxed tx
            
        uint _transferValue = applyTransferTax(_value);

        _transfer(_from, _to, _transferValue);
        uint _tax = _value - _transferValue;
        afterTaxTransfer(_from, _tax);
        }
        return true;
    }

    function afterTaxTransfer(address _from, uint256 _tax) internal {
        if (_tax > 10000) {
            uint256 half = (_tax * 5000) / BIPS_DIVISOR;
            uint256 quarter = (half * 5000) / BIPS_DIVISOR;
            //to send to stARBIS & treasury
            _transfer(_from, stARBISReceiver, quarter);
            _transfer(_from, treasury, quarter);
            if (lpEnabled && quarter > BIPS_DIVISOR) {
                //to burn  and LP 
                selfBurn(quarter, _from);
                _convertRewardTokensToDepositTokens(quarter);
            } else {
                //just burn
                selfBurn(half, _from);
            }
        } else {
            _transfer(msg.sender, stARBISReceiver, _tax);
        }
    }

    /**
        @notice get the amount that will be transfered after the transfer tax is applied
        @param amount The amount to apply tax to
      **/
     function applyTransferTax(uint256 amount) public view returns (uint) {
        return amount - ((amount * transferTax) / BIPS_DIVISOR);
    }

    function _convertRewardTokensToDepositTokens(uint amount) internal returns (uint) {
    uint amountIn = amount / 2;
    require(amountIn > 0, "amount too low");


    // swap half to wETH
    address[] memory path0 = new address[](2);
    path0[0] = address(this);
    path0[1] = address(wETH);

    uint amountOutToken0 = amountIn;
    if (path0[0] != path0[path0.length - 1]) {
      uint[] memory amountsOutToken0 = router.getAmountsOut(amountIn, path0);
      amountOutToken0 = amountsOutToken0[amountsOutToken0.length - 1];
      router.swapExactTokensForTokens(amountIn, amountOutToken0, path0, address(this), block.timestamp);
    }

    (,,uint liquidity) = router.addLiquidity(
      path0[path0.length - 1], address(this),
      amountOutToken0, amountIn,
      0, 0,
      address(this),
      block.timestamp
    );

    lpToken.transfer(treasury, liquidity);

    return liquidity;
  }



     /**
        @notice burn tokens, used by transfer tax  and can be called externally but  in that case requires  token  holders approval
        @param amount The amount to burn
        @param holder the address to burn from
     */
    function selfBurn(uint256 amount, address holder) internal {
        require(balances[holder] >= amount, "Insufficient balance to burn");     
        require(totalSupply >= amount, "Insufficient supply to burn");
         unchecked {
            balances[holder] -= amount; 
            totalSupply -= amount;
         }
    }

    function burn(uint256 _value) public returns (bool) {
   
        // Requires that the message sender has enough tokens to burn
        require(_value <= balances[msg.sender]);

        // Subtracts _value from callers balance and total supply
         unchecked {
            balances[msg.sender] -= _value; 
            totalSupply -= _value;
         }

        // Emits burn and transfer events, make sure you have them in your contracts
        emit Burn(msg.sender, _value);
        emit Transfer(msg.sender, address(0),_value);

        // Since you cant actually burn tokens on the blockchain, sending to address 0, which none has the private keys to, removes them from the circulating supply
        return true;
        }
}