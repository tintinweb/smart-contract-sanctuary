/**
 *Submitted for verification at BscScan.com on 2021-10-16
*/

pragma solidity >=0.7.0 <0.9.0;

// import "./access/Ownable.sol";
// import "./token/BEP20/IBEP20.sol";

// SPDX-License-Identifier: MIT
/**
 * @title RugSwap
 * @author Saad Sarwar
 */

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns ( bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
} 

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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


interface ZombieOnChainPrice {
    function usdToZmbe(uint amount) external view returns(uint);
}
 
contract RugSwap is Ownable{
    uint256 public totalUnlockedContracts = 0; // total unlocked contracts, also helpful for id in UnlockedContractsInfo (id = totalUnlockedContracts + 1)
    address public burnAddress = 0x000000000000000000000000000000000000dEaD; // Burn address
    address public treasury; // treasury address
    address public zombieTokenContractAddress;
    address public priceContract;
    uint256 public totalWhitelisted = 0;
    
    constructor (address _zombieTokenContractAddress, address _treasury, address _priceContract) {
        priceContract = _priceContract;
        treasury = _treasury;
        zombieTokenContractAddress = _zombieTokenContractAddress;
    }
    
    address[] public whiteList;
    
    function addToWhitelist (address ruggedContractAddress) public onlyOwner returns(bool) {
        // so an address doesn't get whitelisted twice or more.
        require(!isWhiteListed(ruggedContractAddress), "The token is already white listed.");
        whiteList.push(ruggedContractAddress);
        totalWhitelisted = totalWhitelisted + 1;
        return true;
    }
    
    // removes a given address from the whiteList without any holes because a new array is created and assigned to the whiteList.
    function removeFromWhitelist (address contractAddress) public onlyOwner returns(bool) {
        require(isWhiteListed(contractAddress), "The token is not white listed.");
        address[] memory newWhitelist = new address[](whiteList.length - 1);
        bool deleted = false;
        for (uint256 index = 0; index < whiteList.length; index++) {
            if (deleted) {
                newWhitelist[index - 1] = whiteList[index];
            } else {
                if (whiteList[index] != contractAddress) {
                    newWhitelist[index] = whiteList[index];
                } else {
                    deleted = true;
                }
            }
        }
        whiteList = newWhitelist;
        totalWhitelisted = totalWhitelisted - 1;
        return true;
    }
    
    function isWhiteListed(address contractAddress) public view returns(bool) {
        for (uint256 index = 0; index < whiteList.length; index++) {
            if (whiteList[index] == contractAddress) {
                return true;
            }
        }
        return false;
    }
    
    function burn(uint256 amount) internal {
        IBEP20(zombieTokenContractAddress).transferFrom(msg.sender, burnAddress, amount);
    }
    
    function toTreasury(uint256 amount) internal {
        IBEP20(zombieTokenContractAddress).transferFrom(msg.sender, treasury, amount);
    }
    
    // returns address just for the event to show the rugged token
    function ruggedTokenSwap(address _ruggedTokenAddress) private returns(bool){
        // transferring a rugged token from user wallet to this contractAddress, needs approval first.
        IBEP20(_ruggedTokenAddress).transferFrom(msg.sender, address(this), 10**IBEP20(_ruggedTokenAddress).decimals());
        // generating a random rugged token except the token which user provided.
        address[] memory newWhitelist = new address[](whiteList.length - 1);
        bool sameTokenFound = false;
        for (uint256 index = 0; index < whiteList.length; index++) {
            if (sameTokenFound) {
                newWhitelist[index - 1] = whiteList[index];
            } else {
                if (whiteList[index] != _ruggedTokenAddress) {
                    newWhitelist[index] = whiteList[index];
                } else {
                    sameTokenFound = true;
                }
            }
        }
        address randomTokenAddress;
        // handling an edge case, if whiteList has only two addresses then one of them will be omitted in above loop so returning the remaining one.
        if (newWhitelist.length < 2) {
            randomTokenAddress = newWhitelist[0];    
        } else {
            randomTokenAddress = newWhitelist[getRandomNum(newWhitelist.length)];
        }
        // transferring the random rugged token to the user. hopefully he finds it in his wallet ;). 
        IBEP20(randomTokenAddress).transfer(msg.sender, 10**IBEP20(randomTokenAddress).decimals());
        return true;
    }
    
    // function to withdraw tokens in case of v2.
    function withdrawTokens(address ruggedTokenAddress, uint256 _amount) public payable onlyOwner returns(bool result) {
        IBEP20(ruggedTokenAddress).transfer(msg.sender, _amount * 10**IBEP20(ruggedTokenAddress).decimals());
        return true;
    }
    
    // returns the amount of zombie tokens required for one BUSD
    function getAmount() public view returns(uint) {
        return ZombieOnChainPrice(priceContract).usdToZmbe(10**IBEP20(zombieTokenContractAddress).decimals());          
    }
    
    function rugSwap(address ruggedTokenAddress) public payable returns(bool result) {
        uint256 zombieAmount = getAmount();
        require(whiteList.length > 1, "Please add more tokens to whitelist.");
        require(isWhiteListed(ruggedTokenAddress), "Only whitelisted tokens are allowed.");
        require(IBEP20(zombieTokenContractAddress).balanceOf(msg.sender) >= zombieAmount, "Not enough balance.");
        require(IBEP20(ruggedTokenAddress).balanceOf(msg.sender) >= 10**IBEP20(ruggedTokenAddress).decimals(), "Rugged token balance not enough.");
        // burning half the amount of zombie tokens
        burn(zombieAmount / 2);
        // tranferring the other half to treasury
        toTreasury(zombieAmount / 2);
        ruggedTokenSwap(ruggedTokenAddress);
        totalUnlockedContracts = totalUnlockedContracts + 1;
        emit Swapped(msg.sender, zombieAmount, ruggedTokenAddress);
        return true;
    }
    
    uint nonce = 0;
    // generates a pseudo random number just to return a rugged token which doesn't have any value, totally predictable so not suitable for selecting any serious random number.
    function getRandomNum(uint256 length) internal returns(uint256) {
        nonce = nonce + 1;
        return uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, nonce))) % (length - 1);
    }
    
    // to check balance of the rugged tokens
    function balanceOf(address _ruggedTokenAddress) public view returns(uint) {
        return IBEP20(_ruggedTokenAddress).balanceOf(address(this)) / 10**IBEP20(_ruggedTokenAddress).decimals();
    }
    
    event Swapped(address indexed _from, uint _zombieAmount, address _ruggedTokenAddress);
    
}