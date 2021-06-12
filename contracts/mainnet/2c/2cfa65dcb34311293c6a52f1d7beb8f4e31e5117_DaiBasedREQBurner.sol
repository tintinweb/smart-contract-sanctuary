/**
 *Submitted for verification at Etherscan.io on 2021-06-11
*/

pragma solidity ^0.5.17;

contract Context {
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @title Contract for  allowing  removal of global supply of locked mintable erc20 tokens by converted from DAI using uniswap v2 router contract
 * @author Request Network
 */ 
 
 
interface IUniswapV2Router02 {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}


interface IERC20 {
    function balanceOf(address _owner) external view returns (uint balance);
    function approve(address _spender, uint _value) external returns (bool success);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

/*interface*/ contract IBurnableErc20 is IERC20 {
    function burn(uint value) external;
}


/** @title DaiBasedREQBurner
 * @notice A contract to burn REQ tokens from DAI.
 * @dev All DAIs sent to this contract can only be exchanged for REQs that are then burnt, using Uniswap.
 */
contract DaiBasedREQBurner is Ownable {

    address constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant REQ_ADDRESS = 0x8f8221aFbB33998d8584A2B05749bA73c37a938a;

    address constant LOCKED_TOKEN_ADDRESS = DAI_ADDRESS;
    address constant BURNABLE_TOKEN_ADDRESS = REQ_ADDRESS;
    // swap router used to convert LOCKED into BURNABLE tokens
    IUniswapV2Router02 public swapRouter;

    /**
     * @notice Constructor of the DAI based REQ burner
     * @param _swapRouterAddress address of the uniswap token router (which follow the same method signature ).
     */
    constructor(address _swapRouterAddress) public {
        require(_swapRouterAddress != address(0), "The swap router address should not be 0");
        swapRouter = IUniswapV2Router02(_swapRouterAddress);
    }

    /// @dev gives the permission to uniswap to accept the swapping of the BURNABLE token 
    function approveRouterToSpend() public {
        uint256 max = 2**256 - 1;
        IERC20 dai = IERC20(LOCKED_TOKEN_ADDRESS);
        dai.approve(address(swapRouter), max);
    }


    ///@dev the main function to be executed
    ///@param _minReqBurnt  REQ token needed to be burned.
    ///@param _deadline  maximum timestamp to accept the trade from the router
    function burn(uint _minReqBurnt, uint256 _deadline)
        external
        returns(uint)
    {
        IERC20 dai = IERC20(LOCKED_TOKEN_ADDRESS);
        IBurnableErc20 req = IBurnableErc20(BURNABLE_TOKEN_ADDRESS);
        uint daiToConvert = dai.balanceOf(address(this));

        if (_deadline == 0) {
            _deadline = block.timestamp + 1000;
        }

        // 1 step swapping path (only works if there is a sufficient liquidity behind the router)
        address[] memory path = new address[](2);
        path[0] = LOCKED_TOKEN_ADDRESS;
        path[1] = BURNABLE_TOKEN_ADDRESS;

        // Do the swap and get the amount of REQ purchased
        uint reqToBurn = swapRouter.swapExactTokensForTokens(
          daiToConvert,
          _minReqBurnt,
          path,
          address(this),
          _deadline
        )[1];

        // Burn all the purchased REQ and return this amount
        req.burn(reqToBurn);
        return reqToBurn;
    }
}