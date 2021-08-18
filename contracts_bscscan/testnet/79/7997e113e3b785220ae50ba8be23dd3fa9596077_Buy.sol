/**
 *Submitted for verification at BscScan.com on 2021-08-17
*/

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


//import the ERC20 interface

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface IPancakeRouter {
    //function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);  
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract Buy is Ownable {
    address private _token;
    //uint256 private _token_price;
    //uint256 private _token_decimal;
    uint256 private _amountOutMin;
    
    address private PANCAKE_V2_ROUTER = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    address private WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    address private BUSD = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7;
    address private USDT = 0x7ef95a0FEE0Dd31b22626fA2e10Ee6A223F8a684;
    address private USDC = 0x7ef95a0FEE0Dd31b22626fA2e10Ee6A223F8a684;

    function check_token_ido() external onlyOwner view virtual returns (address, uint256, address) {
        return (_token, _amountOutMin, PANCAKE_V2_ROUTER);
    }
    
    function update_token_ido(address _tokenContract, uint256 _tokenContract_amountOutMin) external onlyOwner {
        _token = _tokenContract;
        //_token_price = _tokenContract_price;
        //_token_decimal = _tokenContract_decimal;
        _amountOutMin = _tokenContract_amountOutMin;
    }
    
    function update_router(address _router) external onlyOwner {
        PANCAKE_V2_ROUTER = _router;
    }
    
    function withdrawToken(address _tokenContract) external onlyOwner {
        IERC20 tokenContract = IERC20(_tokenContract);
        
        // transfer the token from address of this contract
        // to address of the user (executing the withdrawToken() function)
        tokenContract.transfer(msg.sender, IERC20(_tokenContract).balanceOf(address(this)));
    }
    
    function swap(uint8 data) external {
        uint _amountIn;
        _amountIn = IERC20(WBNB).balanceOf(address(this));
        require(_amountIn > 0, "no balance");
        
        //uint _amountOutMin;
        //_amountOutMin = (_amountIn / _token_price) * _token_decimal; 

        //IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);
        IERC20(WBNB).approve(PANCAKE_V2_ROUTER, _amountIn);
        
        address[] memory path;
        if (data == 0){
            path = new address[](2);
            path[0] = WBNB;
            path[1] = _token;
        } else if (data == 1) {
            path = new address[](3);
            path[0] = WBNB;
            path[1] = BUSD;
            path[2] = _token;
        } else if (data == 2) {
            path = new address[](3);
            path[0] = WBNB;
            path[1] = USDT;
            path[2] = _token;
        } else {
            path = new address[](3);
            path[0] = WBNB;
            path[1] = USDC;
            path[2] = _token;
        }
        IPancakeRouter(PANCAKE_V2_ROUTER).swapExactTokensForTokens(_amountIn, _amountOutMin, path, owner(), block.timestamp);
    }
    
    //function approve() external {
    //    IERC20(WBNB).approve(PANCAKE_V2_ROUTER, 115792089237316195423570985008687907853269984665640564039457584007913129639935);
    //}
}