/**
 *Submitted for verification at Etherscan.io on 2021-12-24
*/

// File: my/BindBox/MathX128.sol



pragma solidity ^0.8.0;

library MathX128 {
    uint constant x128=(1<<128)-1;
    
    uint constant oneX128=(1<<128);
    
    function mulX128(uint l, uint r) internal pure returns(uint result) {
        uint l_high=l>>128;
        uint r_high=r>>128;
        uint l_low=(l&x128);
        uint r_low=(r&x128);
        result=((l_high*r_high)<<128) + (l_high*r_low) + (r_high*l_low) + ((l_low*r_low)>>128);
    }
    
    function mulUint(uint l,uint r) internal pure returns(uint result) {
        result=(l*r)>>128;
    }
    
    function toPercentage(uint numberX128,uint decimal) internal pure returns(uint result) {
        numberX128*=100;
        if(decimal>0){
            numberX128*=10**decimal;
        }
        return numberX128>>128;
    }
    
    function toX128(uint percentage,uint decimal) internal pure returns(uint result) {
        uint divisor=100;
        if(decimal>0)
            divisor*=10**decimal;
        return oneX128*percentage/divisor;
    }
}
// File: @openzeppelin/[email protected]/token/ERC20/IERC20.sol



pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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

// File: my/BindBox/NewCowLib.sol



pragma solidity ^0.8.0;


library NewCowLib {
    
    function transferFrom(IERC20 erc20,address from,address to,uint value) internal {
        if(from==address(this)){
            bool success = erc20.transfer(to,value);
            require(success,'transfer error');
        } else{
            bool success = erc20.transferFrom(from,to,value);
            require(success,'transfer error');
        }
    }
    
    function random(bytes32 salt) view internal returns(uint res,bytes32 nonce) {
        nonce=keccak256(abi.encode(
            block.number,
            block.timestamp,
            block.coinbase,
            msg.sender,
            keccak256(msg.data),
            tx.origin,
            tx.gasprice,
            salt
        ));
        res=(uint)(nonce);
        res=res>>128;
    }
}
// File: my/BindBox/IBindBoxParam.sol



pragma solidity ^0.8.0;


interface IBindBoxParam {
    function reward(uint amount,uint probabilityX128,uint level) external view returns (uint);

    function newUserToken() external view returns (IERC20 token,uint amount);

    function newUserRewardToken(uint switchProbabilityX128,uint rewardProbabilityX128) external view returns (IERC20 token, uint amount);
}
// File: @openzeppelin/[email protected]/utils/Context.sol



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

// File: @openzeppelin/[email protected]/access/Ownable.sol



pragma solidity ^0.8.0;


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

// File: my/BindBox/param/BindBoxParam.sol


pragma solidity ^0.8.0;






contract BindBoxParam is IBindBoxParam,Ownable {
    uint public usdtMin;
    uint public usdtMax;
    uint public btcMin;
    uint public btcMax;
    address public btc;
    address public usdt;
    uint public n;
    string public note;
    mapping(uint=>uint) public levelN;

    using MathX128 for uint;


    constructor(address _btc,address _usdt) {
        btc=_btc;
        usdt=_usdt;
        usdtMin=6*(10**6);
        usdtMax=10*(10**6);
        btcMin=usdtMin*100/57615;
        btcMax=usdtMax*100/57615;
        n=MathX128.oneX128*8/10;
    }
    
    function reward(uint amount,uint probabilityX128,uint level) external view returns (uint award) {
        uint tempN=levelN[level];
        if(tempN==0){
            tempN=n;
        }
        uint x=((tempN*2-MathX128.oneX128)*level-MathX128.oneX128)/(level*level-1);
        (uint randomX128,)=NewCowLib.random(keccak256(abi.encode(amount,probabilityX128,level,x)));
        if(x>probabilityX128){//大于价格的概率
            award=randomX128.mulUint(amount*(level-1))+amount;
        } else {
            award=randomX128.mulUint(amount-(amount/level))+(amount/level);
        }
    }

    function newUserToken() external view returns (IERC20 token,uint amount) {
        token=IERC20(usdt);
        amount=usdtMin;
    }

    function newUserRewardToken(uint switchProbabilityX128,uint rewardProbabilityX128) external view returns (IERC20 token, uint amount) {
        uint minn;
        uint maxx;
        if(switchProbabilityX128.mulUint(20)==0){
            token=IERC20(btc);
            minn=btcMin;
            maxx=btcMax;
        }else{
            token=IERC20(usdt);
            minn=usdtMin;
            maxx=usdtMax;
        }
        amount=rewardProbabilityX128.mulUint(maxx-minn)+minn;
    }

    function updateN(uint _n) external onlyOwner {
        n=_n;
    }

    function updateLevelN(uint level,uint _n) external onlyOwner {
        levelN[level]=_n;
    }

    function updateNote(string calldata _note) external onlyOwner {
        note=_note;
    }

    function updateParam(uint _usdtMin,uint _usdtMax,uint _btcMin,uint _btcMax) external onlyOwner {
        usdtMin=_usdtMin;
        usdtMax=_usdtMax;
        btcMin=_btcMin;
        btcMax=_btcMax;
    }

    function percentageToX128(uint percentage,uint decimal) public pure returns(uint) {
        return MathX128.toX128(percentage,decimal);
    }

    function X128ToPercentage(uint numberX128,uint decimal) public pure returns(uint) {
        return MathX128.toPercentage(numberX128,decimal);
    }
}